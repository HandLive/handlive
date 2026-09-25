package app.handlive.android.core.transport

import app.handlive.android.core.crypto.derivation.SessionKeys
import app.handlive.android.core.crypto.primitives.SecureRandomBytes
import app.handlive.android.core.protocol.ErrorCode
import app.handlive.android.core.protocol.capability.CapabilityData
import app.handlive.android.core.protocol.capability.CapabilityOp
import app.handlive.android.core.protocol.envelope.EnvelopeCodec
import app.handlive.android.core.protocol.envelope.MessageType
import app.handlive.android.core.protocol.session.SessionErrorData
import app.handlive.android.core.protocol.session.SessionOp
import app.handlive.android.core.transport.handshake.HandshakeEnvelopes
import app.handlive.android.core.transport.testing.LoopbackServerFixture
import app.handlive.android.core.transport.testing.LoopbackServerFixture.Companion.MAC_CAPABILITY
import app.handlive.android.core.transport.testing.TestClientChannel
import app.handlive.android.core.transport.testing.pinnedSslContext
import app.handlive.android.core.transport.testing.pinnedWebSocketClient
import io.ktor.client.plugins.websocket.webSocket
import io.ktor.websocket.CloseReason
import io.ktor.websocket.Frame
import io.ktor.websocket.readText
import kotlinx.coroutines.runBlocking
import org.junit.After
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Assert.assertThrows
import org.junit.Assert.assertTrue
import org.junit.Test
import java.util.UUID
import javax.net.ssl.SSLException
import javax.net.ssl.SSLSocket

/** Từ chối bắt tay đúng op `session/error` và mã đóng (0.8.3, CONN-01 API 4–6). */
class ControlChannelRejectionTest {
    private val fixture = LoopbackServerFixture()
    private val client = pinnedWebSocketClient(fixture.tls.certificateSha256())

    @After
    fun tearDown() {
        client.close()
        fixture.close()
    }

    @Test
    fun wrongMacIsRejectedWithAuthFailedAnd4401() {
        val peer = fixture.addPair()
        val (hello) = peer.hello(macKey = SecureRandomBytes.next(PRK_SIZE))
        assertRejected(hello, ErrorCode.AUTH_FAILED, WsCloseCode.AUTH_FAILED)
    }

    @Test
    fun unknownPairIsRejectedWithPairUnknownAnd4401() {
        val peer = fixture.addPair()
        val (hello) = peer.hello(helloPairId = UUID.randomUUID().toString())
        assertRejected(hello, ErrorCode.PAIR_UNKNOWN, WsCloseCode.AUTH_FAILED)
    }

    @Test
    fun revokedPairIsRejectedWithPairRevokedAnd4403() {
        val peer = fixture.addPair(revoked = true)
        val (hello) = peer.hello()
        assertRejected(hello, ErrorCode.PAIR_REVOKED, WsCloseCode.PAIR_REVOKED)
    }

    @Test
    fun differentProtocolMajorIsRejectedWith4426BeforeAnyPairCheck() {
        // Cặp lạ và mac sai: `protocol` vẫn được kiểm trước tiên.
        val peer = fixture.addPair()
        val (hello) = peer.hello(protocol = 2, helloPairId = UUID.randomUUID().toString())
        val error = assertRejected(hello, ErrorCode.UNSUPPORTED_VERSION, WsCloseCode.UNSUPPORTED_VERSION)
        assertEquals(1, error?.minProtocol)
    }

    @Test
    fun deviceIdOfAnotherDeviceIsRejectedWithAuthFailedAnd4401() {
        val peer = fixture.addPair()
        val (hello) = peer.hello(helloDeviceId = fixture.addPair().deviceId)
        assertRejected(hello, ErrorCode.AUTH_FAILED, WsCloseCode.AUTH_FAILED)
    }

    @Test
    fun malformedHelloIsClosedWith4400WithoutSessionError() {
        val (error, reason) = exchange("""{"v":1,"type":"session"}""")
        assertNull(error)
        assertEquals(WsCloseCode.BAD_REQUEST, reason?.code)
    }

    @Test
    fun silentClientIsClosedWith4408AfterHandshakeTimeout() =
        runBlocking {
            val started = System.nanoTime()
            var reason: CloseReason? = null
            client.webSocket(fixture.url) { reason = closeReason.await() }
            val elapsedMillis = (System.nanoTime() - started) / NANOS_PER_MILLI
            assertEquals(WsCloseCode.HANDSHAKE_TIMEOUT, reason?.code)
            assertTrue(
                "closed after ${elapsedMillis}ms",
                elapsedMillis >= TransportConstants.HANDSHAKE_TIMEOUT.inWholeMilliseconds - SLACK_MILLIS,
            )
        }

    @Test
    fun firstEncryptedEnvelopeUnderWrongKeyIsClosedWith4401() =
        runBlocking {
            val peer = fixture.addPair()
            var reason: CloseReason? = null
            client.webSocket(fixture.url) {
                val (hello, state) = peer.hello()
                send(Frame.Text(hello))
                peer.acceptWelcome((incoming.receive() as Frame.Text).readText(), state)
                val wrongKeys = SessionKeys(SecureRandomBytes.next(SessionKeys.SECRET_SIZE))
                TestClientChannel(this, wrongKeys, peer.ids)
                    .send(MessageType.CAPABILITY.wire, CapabilityOp.HELLO, CapabilityData.serializer(), MAC_CAPABILITY)
                reason = closeReason.await()
            }
            assertEquals(WsCloseCode.AUTH_FAILED, reason?.code)
        }

    @Test
    fun certificateThatDoesNotMatchPinIsRefusedByClient() {
        val wrongPin = pinnedWebSocketClient(SecureRandomBytes.next(PRK_SIZE))
        val result = runCatching { runBlocking { wrongPin.webSocket(fixture.url) { } } }
        wrongPin.close()
        assertTrue("TLS must fail on pin mismatch", result.isFailure)
    }

    @Test
    fun tls12ClientIsRefused() {
        val factory = pinnedSslContext(fixture.tls.certificateSha256(), "TLSv1.2").socketFactory
        (factory.createSocket("127.0.0.1", fixture.port) as SSLSocket).use { socket ->
            socket.enabledProtocols = arrayOf("TLSv1.2")
            assertThrows(SSLException::class.java) { socket.startHandshake() }
        }
    }

    private fun assertRejected(
        hello: String,
        code: ErrorCode,
        closeCode: Short,
    ): SessionErrorData? {
        val (error, reason) = exchange(hello)
        assertEquals(code.name, error?.code)
        assertEquals(closeCode, reason?.code)
        return error
    }

    /** Gửi một tin, gom `session/error` (nếu có) và mã đóng. */
    private fun exchange(text: String): Pair<SessionErrorData?, CloseReason?> =
        runBlocking {
            var error: SessionErrorData? = null
            var reason: CloseReason? = null
            client.webSocket(fixture.url) {
                send(Frame.Text(text))
                for (frame in incoming) {
                    val payload =
                        HandshakeEnvelopes.read(
                            EnvelopeCodec.decode((frame as Frame.Text).readText()),
                            SessionErrorData.serializer(),
                        )
                    assertEquals(SessionOp.ERROR, payload.op)
                    error = payload.data
                }
                reason = closeReason.await()
            }
            error to reason
        }

    private companion object {
        const val PRK_SIZE = 32
        const val NANOS_PER_MILLI = 1_000_000L
        const val SLACK_MILLIS = 200L
    }
}
