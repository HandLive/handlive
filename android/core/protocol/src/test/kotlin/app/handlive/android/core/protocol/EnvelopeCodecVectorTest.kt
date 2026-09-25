package app.handlive.android.core.protocol

import app.handlive.android.core.protocol.encoding.Base64Codecs
import app.handlive.android.core.protocol.envelope.Envelope
import app.handlive.android.core.protocol.envelope.EnvelopeCodec
import app.handlive.android.core.protocol.testing.SharedTestVectors
import app.handlive.android.core.protocol.testing.bool
import app.handlive.android.core.protocol.testing.hex
import app.handlive.android.core.protocol.testing.int
import app.handlive.android.core.protocol.testing.long
import app.handlive.android.core.protocol.testing.str
import app.handlive.android.core.protocol.testing.strOrNull
import org.junit.Assert.assertArrayEquals
import org.junit.Assert.assertEquals
import org.junit.Assert.assertThrows
import org.junit.Test

/** Envelope của envelope.json, ack.json, clipboard-chunk.json: parse → ghi lại phải trùng từng byte. */
class EnvelopeCodecVectorTest {
    private val files = listOf("envelope.json", "ack.json", "clipboard-chunk.json")

    @Test
    fun positiveVectorsRoundTripByteExact() {
        var count = 0
        for (file in files) {
            for (vector in SharedTestVectors.vectors(file)) {
                val name = "$file / ${vector.str("name")}"
                val envelope = EnvelopeCodec.decode(vector.str("envelope"))
                assertEquals(name, vector.int("v"), envelope.v)
                assertEquals(name, vector.str("type"), envelope.type)
                assertEquals(name, vector.str("id"), envelope.id)
                assertEquals(name, vector.long("ts"), envelope.ts)
                assertEquals(name, vector.str("payload_b64"), envelope.payload)
                assertEquals(name, vector.str("envelope"), EnvelopeCodec.encode(envelope))
                checkPayload(name, vector, envelope)
                count++
            }
        }
        assertEquals(10, count)
    }

    private fun checkPayload(
        name: String,
        vector: kotlinx.serialization.json.JsonObject,
        envelope: Envelope,
    ) {
        val encrypted = vector["encrypted"]?.let { vector.bool("encrypted") } ?: true
        if (encrypted) {
            assertEquals(
                name,
                vector.str("aad"),
                Envelope.aadString(envelope.v, envelope.type, envelope.id, envelope.ts),
            )
            assertArrayEquals(name, vector.hex("aad_hex"), envelope.aad())
            val sealed = vector.hex("nonce") + vector.hex("ciphertext") + vector.hex("tag")
            assertArrayEquals(name, sealed, Base64Codecs.decodeB64(envelope.payload))
        } else {
            assertEquals(name, null, vector.strOrNull("key"))
            assertEquals(name, vector.str("plaintext"), EnvelopeCodec.readUnencryptedPayload(envelope))
            assertEquals(name, vector.str("payload_b64"), EnvelopeCodec.unencryptedPayload(vector.str("plaintext")))
        }
    }

    @Test
    fun envelopeAtLimitAcceptedAndAboveRejected() {
        val skeleton = EnvelopeCodec.encode(Envelope(1, "clipboard", ID, 1L, ""))
        val atLimit = Envelope(1, "clipboard", ID, 1L, "A".repeat(Envelope.MAX_BYTES - skeleton.length))
        assertEquals(Envelope.MAX_BYTES, EnvelopeCodec.encode(atLimit).length)
        val over = atLimit.copy(payload = atLimit.payload + "AAAA")
        val encodeError = assertThrows(ProtocolException::class.java) { EnvelopeCodec.encode(over) }
        assertEquals(ErrorCode.PAYLOAD_TOO_LARGE, encodeError.code)
        val oversized = EnvelopeCodec.encode(atLimit).replace("\"payload\":\"", "\"payload\":\"AAAA")
        val decodeError = assertThrows(ProtocolException::class.java) { EnvelopeCodec.decode(oversized) }
        assertEquals(ErrorCode.PAYLOAD_TOO_LARGE, decodeError.code)
    }

    @Test
    fun structuralErrorsMapToSpecCodes() {
        val base = EnvelopeCodec.encode(Envelope(1, "sms", ID, 1L, "AAAA"))
        assertCode(ErrorCode.UNSUPPORTED_VERSION, base.replace("\"v\":1", "\"v\":2"))
        assertCode(ErrorCode.BAD_REQUEST, base.replace(ID, "0192f3e8-1b2c-4d3f-8a01-5a6b7c8d9e10"))
        assertCode(ErrorCode.BAD_REQUEST, base.replace("\"AAAA\"", "\"AAA\""))
        assertCode(ErrorCode.BAD_REQUEST, base.replace("\"ts\":1", "\"ts\":-1"))
        assertCode(ErrorCode.BAD_REQUEST, "{\"v\":1}")
        assertCode(ErrorCode.BAD_REQUEST, "not json")
    }

    private fun assertCode(
        code: ErrorCode,
        text: String,
    ) {
        assertEquals(code, assertThrows(ProtocolException::class.java) { EnvelopeCodec.decode(text) }.code)
    }

    private companion object {
        const val ID = "0192f3e8-1b2c-7d3f-8a01-5a6b7c8d9e10"
    }
}
