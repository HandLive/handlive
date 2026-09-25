package app.handlive.android.core.protocol

import app.handlive.android.core.protocol.envelope.EnvelopeCodec
import app.handlive.android.core.protocol.envelope.PlaintextCodec
import app.handlive.android.core.protocol.session.SessionHelloData
import app.handlive.android.core.protocol.session.SessionOp
import app.handlive.android.core.protocol.session.SessionRekeyData
import app.handlive.android.core.protocol.session.SessionWelcomeData
import app.handlive.android.core.protocol.stream.StreamHandshakeData
import app.handlive.android.core.protocol.stream.StreamOp
import app.handlive.android.core.protocol.testing.SharedTestVectors
import app.handlive.android.core.protocol.testing.str
import kotlinx.serialization.KSerializer
import org.junit.Assert.assertEquals
import org.junit.Test

/** Model có kiểu của session/stream đọc plaintext trong vector rồi ghi lại đúng từng byte. */
class TypedMessageVectorTest {
    private fun <T> assertRoundTrip(
        plaintext: String,
        op: String,
        serializer: KSerializer<T>,
    ) {
        val decoded = PlaintextCodec.decodeOp(plaintext.toByteArray(), serializer)
        assertEquals(op, decoded.op)
        assertEquals(plaintext, PlaintextCodec.encodeOp(decoded.op, serializer, decoded.data).toString(Charsets.UTF_8))
    }

    @Test
    fun sessionHandshakePlaintexts() {
        for (vector in SharedTestVectors.vectors("session-handshake.json")) {
            assertRoundTrip(vector.str("hello_plaintext"), SessionOp.HELLO, SessionHelloData.serializer())
            assertRoundTrip(vector.str("welcome_plaintext"), SessionOp.WELCOME, SessionWelcomeData.serializer())
            val hello = EnvelopeCodec.decode(vector.str("hello_envelope"))
            assertEquals("session", hello.type)
            assertEquals(vector.str("hello_plaintext"), EnvelopeCodec.readUnencryptedPayload(hello))
            val welcome = EnvelopeCodec.decode(vector.str("welcome_envelope"))
            assertEquals(vector.str("welcome_plaintext"), EnvelopeCodec.readUnencryptedPayload(welcome))
        }
    }

    @Test
    fun sessionRekeyPlaintexts() {
        for (vector in SharedTestVectors.vectors("session-rekey.json")) {
            assertRoundTrip(vector.str("request_plaintext"), SessionOp.REKEY, SessionRekeyData.serializer())
            val ackData = vector.str("ack_data")
            val decoded = ProtocolJson.decodeFromString(SessionRekeyData.serializer(), ackData)
            assertEquals(ackData, ProtocolJson.encodeToString(SessionRekeyData.serializer(), decoded))
        }
    }

    @Test
    fun streamHandshakePlaintexts() {
        for (vector in SharedTestVectors.vectors("stream-keys.json")) {
            assertRoundTrip(
                vector.str("stream_hello_plaintext"),
                StreamOp.STREAM_HELLO,
                StreamHandshakeData.serializer(),
            )
            assertRoundTrip(
                vector.str("stream_welcome_plaintext"),
                StreamOp.STREAM_WELCOME,
                StreamHandshakeData.serializer(),
            )
            val hello = EnvelopeCodec.decode(vector.str("stream_hello_envelope"))
            assertEquals(vector.str("envelope_type"), hello.type)
            assertEquals(vector.str("stream_hello_plaintext"), EnvelopeCodec.readUnencryptedPayload(hello))
            val welcome = EnvelopeCodec.decode(vector.str("stream_welcome_envelope"))
            assertEquals(vector.str("stream_welcome_plaintext"), EnvelopeCodec.readUnencryptedPayload(welcome))
        }
    }
}
