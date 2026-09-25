package app.handlive.android.core.crypto

import app.handlive.android.core.crypto.message.EnvelopeCipher
import app.handlive.android.core.crypto.message.HlFrameCipher
import app.handlive.android.core.protocol.ErrorCode
import app.handlive.android.core.protocol.ProtocolException
import app.handlive.android.core.protocol.clipboard.ClipboardChunkPlaintext
import app.handlive.android.core.protocol.envelope.EnvelopeCodec
import app.handlive.android.core.protocol.envelope.EnvelopeHeader
import app.handlive.android.core.protocol.envelope.PlaintextCodec
import app.handlive.android.core.protocol.frame.HlFrame
import app.handlive.android.core.protocol.testing.SharedTestVectors
import app.handlive.android.core.protocol.testing.bool
import app.handlive.android.core.protocol.testing.hex
import app.handlive.android.core.protocol.testing.int
import app.handlive.android.core.protocol.testing.long
import app.handlive.android.core.protocol.testing.str
import kotlinx.serialization.json.JsonObject
import org.junit.Assert.assertArrayEquals
import org.junit.Assert.assertEquals
import org.junit.Assert.assertThrows
import org.junit.Test

/** envelope.json, ack.json, clipboard-chunk.json, hl-frame.json: mã hóa khớp từng byte, vector âm bị từ chối. */
class MessageCipherVectorTest {
    private fun plaintextBytes(v: JsonObject): ByteArray =
        if (v.containsKey("plaintext_hex")) v.hex("plaintext_hex") else v.str("plaintext").toByteArray()

    private val envelopeFiles = listOf("envelope.json", "ack.json", "clipboard-chunk.json")

    @Test
    fun encryptedEnvelopeVectors() {
        val encrypted =
            envelopeFiles.flatMap { file ->
                SharedTestVectors
                    .vectors(file)
                    .filter {
                        it["encrypted"]?.let { _ ->
                            it.bool("encrypted")
                        } != false
                    }.map {
                        file to
                            it
                    }
            }
        for ((file, v) in encrypted) {
            val name = "$file / ${v.str("name")}"
            val header = EnvelopeHeader(v.str("type"), v.str("id"), v.long("ts"))
            val sealed = EnvelopeCipher.seal(v.hex("key"), header, plaintextBytes(v), v.hex("nonce"))
            assertEquals(name, v.int("v"), sealed.v)
            assertEquals(name, v.str("envelope"), EnvelopeCodec.encode(sealed))
            val opened = EnvelopeCipher.open(v.hex("key"), EnvelopeCodec.decode(v.str("envelope")))
            assertArrayEquals(name, plaintextBytes(v), opened)
            checkDecodedPlaintext(file, v, opened)
        }
        assertEquals(8, encrypted.size)
    }

    private fun checkDecodedPlaintext(
        file: String,
        v: JsonObject,
        opened: ByteArray,
    ) {
        when (file) {
            "ack.json" -> {
                val ack = PlaintextCodec.decodeAck(opened)
                assertEquals(v.str("re"), ack.re)
                assertEquals(v.bool("ok"), ack.ok)
            }

            "clipboard-chunk.json" -> {
                val chunk = ClipboardChunkPlaintext.decode(opened)
                assertEquals(v.str("transfer_id"), chunk.transferId)
                assertArrayEquals(v.hex("chunk_data"), chunk.chunk)
            }

            else -> {
                PlaintextCodec.decodePayload(opened)
            }
        }
    }

    @Test
    fun invalidEnvelopesRejected() {
        var count = 0
        for (file in envelopeFiles) {
            for (v in SharedTestVectors.invalidVectors(file)) {
                val error =
                    assertThrows(v.str("name"), ProtocolException::class.java) {
                        EnvelopeCipher.open(v.hex("key"), EnvelopeCodec.decode(v.str("envelope")))
                    }
                assertEquals(v.str("name"), ErrorCode.DECRYPT_FAILED, error.code)
                count++
            }
        }
        assertEquals(9, count)
    }

    @Test
    fun hlFrameVectors() {
        for (v in SharedTestVectors.vectors("hl-frame.json")) {
            val name = v.str("name")
            val frame =
                HlFrameCipher.seal(
                    v.hex("key"),
                    v.long("seq").toUInt(),
                    v.long("ts").toUInt(),
                    v.hex("plaintext"),
                    v.hex("nonce"),
                )
            assertArrayEquals(name, v.hex("frame"), frame.encode())
            assertArrayEquals(
                name,
                v.hex("plaintext"),
                HlFrameCipher.open(v.hex("key"), HlFrame.decode(v.hex("frame"))),
            )
        }
        val invalid = SharedTestVectors.invalidVectors("hl-frame.json")
        for (v in invalid) {
            val error =
                assertThrows(v.str("name"), ProtocolException::class.java) {
                    HlFrameCipher.open(v.hex("key"), HlFrame.decode(v.hex("frame")))
                }
            assertEquals(ErrorCode.DECRYPT_FAILED, error.code)
        }
        assertEquals(2, invalid.size)
    }
}
