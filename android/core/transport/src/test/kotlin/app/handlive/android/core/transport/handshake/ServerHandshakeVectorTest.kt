package app.handlive.android.core.transport.handshake

import app.handlive.android.core.protocol.ErrorCode
import app.handlive.android.core.protocol.encoding.Base64Codecs
import app.handlive.android.core.protocol.envelope.EnvelopeCodec
import app.handlive.android.core.protocol.envelope.PlaintextCodec
import app.handlive.android.core.protocol.id.UuidV7Generator
import app.handlive.android.core.protocol.session.SessionHelloData
import app.handlive.android.core.protocol.session.SessionOp
import app.handlive.android.core.protocol.testing.SharedTestVectors
import app.handlive.android.core.protocol.testing.hex
import app.handlive.android.core.protocol.testing.str
import app.handlive.android.core.transport.WsCloseCode
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.JsonPrimitive
import org.junit.Assert.assertArrayEquals
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test

/**
 * Phía S tất định theo `shared/test-vectors/session-handshake.json`: cùng khóa tạm và nonce của vector thì
 * `welcome` và `k_c2s`/`k_s2c` phải trùng từng byte với Swift/Rust.
 */
class ServerHandshakeVectorTest {
    private val vectors = SharedTestVectors.vectors("session-handshake.json")

    @Test
    fun welcomeAndSessionKeysMatchVectorByteForByte() {
        for (vector in vectors) {
            val outcome = handshakeFor(vector).respond(helloEnvelope(vector))
            assertTrue(vector.str("name"), outcome is HandshakeOutcome.Accepted)
            outcome as HandshakeOutcome.Accepted
            assertEquals(vector.str("welcome_plaintext"), EnvelopeCodec.readUnencryptedPayload(outcome.welcome))
            assertArrayEquals(vector.hex("k_c2s"), outcome.keys.kC2s)
            assertArrayEquals(vector.hex("k_s2c"), outcome.keys.kS2c)
        }
    }

    @Test
    fun wrongPrkMeansMacMismatchAndAuthFailed() {
        val vector = vectors.first()
        val handshake =
            ServerHandshake(
                localDeviceId = vector.str("server_device_id"),
                pairs = { PairRecord(it, vector.str("client_device_id"), ByteArray(PRK_SIZE), revoked = false) },
            )
        val outcome = handshake.respond(helloEnvelope(vector)) as HandshakeOutcome.Rejected
        assertEquals(ErrorCode.AUTH_FAILED, outcome.code)
        assertEquals(WsCloseCode.AUTH_FAILED, outcome.closeCode)
    }

    @Test
    fun tamperedHelloNonceBreaksMac() {
        val vector = vectors.first()
        val hello = PlaintextCodec.decodeOp(vector.str("hello_plaintext").toByteArray(), SessionHelloData.serializer())
        val nonce = Base64Codecs.decodeB64u(hello.data.nonce).also { it[0] = (it[0].toInt() xor 1).toByte() }
        val tampered = hello.data.copy(nonce = Base64Codecs.encodeB64u(nonce))
        val text =
            EnvelopeCodec.encode(
                HandshakeEnvelopes.build(IDS.next(), 0, SessionOp.HELLO, SessionHelloData.serializer(), tampered),
            )
        val outcome = handshakeFor(vector).respond(text) as HandshakeOutcome.Rejected
        assertEquals(ErrorCode.AUTH_FAILED, outcome.code)
        assertEquals(WsCloseCode.AUTH_FAILED, outcome.closeCode)
    }

    private fun handshakeFor(vector: JsonObject) =
        ServerHandshake(
            localDeviceId = vector.str("server_device_id"),
            pairs = { pairId ->
                PairRecord(pairId, vector.str("client_device_id"), vector.hex("prk"), revoked = false)
                    .takeIf { pairId == vector.str("pair_id") }
            },
            ephemeralPrivateKey = { vector.hex("server_eph_priv") },
            nonce = { vector.hex("server_nonce") },
        )

    /** `hello_envelope` trong vector có thể là chuỗi wire hoặc object JSON. */
    private fun helloEnvelope(vector: JsonObject): String =
        when (val element = vector.getValue("hello_envelope")) {
            is JsonPrimitive -> element.content
            else -> element.toString()
        }

    private companion object {
        const val PRK_SIZE = 32
        val IDS = UuidV7Generator()
    }
}
