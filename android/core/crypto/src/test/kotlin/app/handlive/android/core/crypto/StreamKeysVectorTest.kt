package app.handlive.android.core.crypto

import app.handlive.android.core.crypto.derivation.StreamChannel
import app.handlive.android.core.crypto.derivation.StreamKeyDerivation
import app.handlive.android.core.protocol.encoding.Base64Codecs
import app.handlive.android.core.protocol.envelope.PlaintextCodec
import app.handlive.android.core.protocol.stream.StreamHandshakeData
import app.handlive.android.core.protocol.testing.SharedTestVectors
import app.handlive.android.core.protocol.testing.hex
import app.handlive.android.core.protocol.testing.int
import app.handlive.android.core.protocol.testing.str
import org.junit.Assert.assertArrayEquals
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

/** stream-keys.json: `K_stream` và MAC `HLSTREAM1` (0.6.3 bước 7–8). */
class StreamKeysVectorTest {
    @Test
    fun streamKeyAndMacVectors() {
        val vectors = SharedTestVectors.vectors("stream-keys.json")
        for (v in vectors) {
            val name = v.str("name")
            val channel = StreamChannel.entries.single { it.path == v.str("channel") }
            val sessionId = v.str("session_id")
            assertEquals(name, v.str("info"), StreamKeyDerivation.info(channel, sessionId))
            assertEquals(name, StreamKeyDerivation.LENGTH, v.int("length"))
            val keys = StreamKeyDerivation.streamKeys(v.hex("secret"), channel, sessionId)
            assertArrayEquals(name, v.hex("k_stream"), keys.kAuth + keys.kC2s + keys.kS2c)
            assertArrayEquals(name, v.hex("k_auth"), keys.kAuth)
            assertArrayEquals(name, v.hex("k_c2s"), keys.kC2s)
            assertArrayEquals(name, v.hex("k_s2c"), keys.kS2c)
            val hello = StreamKeyDerivation.helloMessage(sessionId, v.hex("nonce_c"))
            assertArrayEquals(name, v.hex("hello_message"), hello)
            assertArrayEquals(name, v.hex("hello_mac"), StreamKeyDerivation.mac(keys.kAuth, hello))
            val welcome = StreamKeyDerivation.welcomeMessage(sessionId, v.hex("nonce_c"), v.hex("nonce_s"))
            assertArrayEquals(name, v.hex("welcome_message"), welcome)
            assertArrayEquals(name, v.hex("welcome_mac"), StreamKeyDerivation.mac(keys.kAuth, welcome))
            assertTrue(name, StreamKeyDerivation.verifyMac(keys.kAuth, welcome, v.hex("welcome_mac")))
            val helloData =
                PlaintextCodec
                    .decodeOp(
                        v.str("stream_hello_plaintext").toByteArray(),
                        StreamHandshakeData.serializer(),
                    ).data
            assertEquals(name, sessionId, helloData.sessionId)
            assertArrayEquals(name, v.hex("nonce_c"), Base64Codecs.decodeB64u(helloData.nonce, 32))
            assertArrayEquals(name, v.hex("hello_mac"), Base64Codecs.decodeB64u(helloData.mac, 32))
            val welcomeData =
                PlaintextCodec
                    .decodeOp(
                        v.str("stream_welcome_plaintext").toByteArray(),
                        StreamHandshakeData.serializer(),
                    ).data
            assertArrayEquals(name, v.hex("nonce_s"), Base64Codecs.decodeB64u(welcomeData.nonce, 32))
            assertArrayEquals(name, v.hex("welcome_mac"), Base64Codecs.decodeB64u(welcomeData.mac, 32))
        }
        assertEquals(StreamChannel.entries.map { it.path }.toSet(), vectors.map { it.str("channel") }.toSet())
    }

    @Test
    fun invalidStreamMacsRejected() {
        val invalid = SharedTestVectors.invalidVectors("stream-keys.json")
        for (v in invalid) {
            assertFalse(v.str("name"), StreamKeyDerivation.verifyMac(v.hex("key"), v.hex("message"), v.hex("mac")))
        }
        assertEquals(3, invalid.size)
    }
}
