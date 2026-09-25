package app.handlive.android.core.transport

import app.handlive.android.core.protocol.ProtocolJson
import app.handlive.android.core.protocol.ack.Ack
import app.handlive.android.core.protocol.capability.CapabilityData
import app.handlive.android.core.protocol.capability.CapabilityOp
import app.handlive.android.core.protocol.envelope.MessageType
import app.handlive.android.core.protocol.envelope.Payload
import app.handlive.android.core.protocol.envelope.PlaintextCodec
import app.handlive.android.core.protocol.session.SessionByeData
import app.handlive.android.core.protocol.session.SessionOp
import app.handlive.android.core.protocol.session.SessionRekeyData
import app.handlive.android.core.transport.server.ControlConnectionState
import app.handlive.android.core.transport.session.RekeyRequestResult
import app.handlive.android.core.transport.session.SessionRekeyCoordinator
import app.handlive.android.core.transport.testing.LoopbackServerFixture
import app.handlive.android.core.transport.testing.LoopbackServerFixture.Companion.MAC_CAPABILITY
import app.handlive.android.core.transport.testing.TestClientChannel
import app.handlive.android.core.transport.testing.TestClientPeer
import app.handlive.android.core.transport.testing.pinnedWebSocketClient
import io.ktor.client.HttpClient
import io.ktor.client.plugins.websocket.webSocketSession
import io.ktor.websocket.Frame
import io.ktor.websocket.close
import io.ktor.websocket.readText
import kotlinx.coroutines.runBlocking
import kotlinx.coroutines.withTimeout
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.jsonObject
import org.junit.After
import org.junit.Assert.assertArrayEquals
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test

/** Rekey trên phiên thật (0.6.3 bước 6, CONN-02 API 3) và thay phiên cũ của cùng cặp (0.4.1, CONN-01 bước 7). */
class ControlChannelRekeyAndReplaceTest {
    private val fixture = LoopbackServerFixture(rekeyAfterEnvelopes = REKEY_AFTER)
    private val client = pinnedWebSocketClient(fixture.tls.certificateSha256())
    private val ping = PlaintextCodec.encodePayload(Payload("push", JsonObject(emptyMap())))

    @After
    fun tearDown() {
        client.close()
        fixture.close()
    }

    @Test
    fun clientInitiatedRekeySwitchesBothSidesToEpochOneKeys() =
        runBlocking {
            val peer = fixture.addPair()
            val channel = connect(client, peer)
            val session = fixture.awaitSession()
            val rekey = SessionRekeyCoordinator(peer.deviceId, peer.serverDeviceId, channel.cipher)
            val requestId = peer.ids.next()
            channel.send(
                MessageType.SESSION.wire,
                SessionOp.REKEY,
                SessionRekeyData.serializer(),
                rekey.start(requestId),
                requestId,
            )

            val (ackEnvelope, ackPlaintext) = channel.receive()
            assertEquals(MessageType.ACK.wire, ackEnvelope.type)
            val ack = PlaintextCodec.decodeAck(ackPlaintext)
            assertEquals(requestId, ack.re)
            val response = ProtocolJson.decodeFromJsonElement(SessionRekeyData.serializer(), ack.data!!)
            assertTrue(rekey.onAck(ack.re, response))

            // Envelope mã hóa bằng khóa epoch 1 được S giải mã; S trả lời bằng khóa epoch 1.
            channel.sendPlaintext(MessageType.CLIPBOARD.wire, ping)
            withTimeout(WAIT_MILLIS) { session.inbound.receive() }
            assertEquals(1, session.channel.cipher.epoch)
            assertArrayEquals(channel.cipher.keys.secret, session.channel.cipher.keys.secret)
            session.send(MessageType.CLIPBOARD, ping)
            assertEquals(MessageType.CLIPBOARD.wire, channel.receive().first.type)
            channel.socket.close()
        }

    @Test
    fun serverInitiatesRekeyAfterEnvelopeThresholdAndSwitchesOnAck() =
        runBlocking {
            val peer = fixture.addPair()
            val channel = connect(client, peer)
            val session = fixture.awaitSession()
            // S đã nhận capability/hello (1); thêm 2 envelope → chạm ngưỡng 3 ở chiều nhận.
            repeat(REKEY_AFTER.toInt() - 1) { channel.sendPlaintext(MessageType.CLIPBOARD.wire, ping) }

            val (requestEnvelope, requestPlaintext) = channel.receive()
            assertEquals(MessageType.SESSION.wire, requestEnvelope.type)
            val request = PlaintextCodec.decodeOp(requestPlaintext, SessionRekeyData.serializer())
            assertEquals(SessionOp.REKEY, request.op)
            assertEquals(1, request.data.epoch)

            val rekey = SessionRekeyCoordinator(peer.deviceId, peer.serverDeviceId, channel.cipher)
            val result = rekey.onRequest(request.data) as RekeyRequestResult.Respond
            val data = ProtocolJson.encodeToJsonElement(SessionRekeyData.serializer(), result.ackData).jsonObject
            val ack = Ack.success(requestEnvelope.id, data)
            channel.sendPlaintext(MessageType.ACK.wire, PlaintextCodec.encodeAck(ack))
            channel.cipher.install(result.newKeys, result.epoch)

            channel.sendPlaintext(MessageType.CLIPBOARD.wire, ping)
            // Hai envelope trước rekey + một envelope sau rekey đều tới mô-đun tính năng.
            repeat(REKEY_AFTER.toInt()) { withTimeout(WAIT_MILLIS) { session.inbound.receive() } }
            assertEquals(1, session.channel.cipher.epoch)
            assertArrayEquals(channel.cipher.keys.secret, session.channel.cipher.keys.secret)
            channel.socket.close()
        }

    @Test
    fun newSessionOfSamePairReplacesOldOneWithByeAnd4409() =
        runBlocking {
            val peer = fixture.addPair()
            val first = connect(client, peer)
            val firstSession = fixture.awaitSession()
            val second = connect(client, peer)
            val secondSession = fixture.awaitSession()

            val (byeEnvelope, byePlaintext) = first.receive()
            assertEquals(MessageType.SESSION.wire, byeEnvelope.type)
            val bye = PlaintextCodec.decodeOp(byePlaintext, SessionByeData.serializer())
            assertEquals(SessionOp.BYE, bye.op)
            assertEquals("replaced", bye.data.reason)
            val reason = withTimeout(WAIT_MILLIS) { first.socket.closeReason.await() }
            assertEquals(WsCloseCode.REPLACED, reason?.code)
            assertEquals(ControlConnectionState.CLOSED, firstSession.state.value)
            assertEquals(secondSession, fixture.server.sessions.get(peer.pairId))
            second.socket.close()
        }

    /** Mở `/v1/ctl`, bắt tay và trao `capability/hello` hai chiều; trả kênh phía C. */
    private suspend fun connect(
        http: HttpClient,
        peer: TestClientPeer,
    ): TestClientChannel {
        val socket = http.webSocketSession(fixture.url)
        val (hello, state) = peer.hello()
        socket.send(Frame.Text(hello))
        val keys = peer.acceptWelcome((socket.incoming.receive() as Frame.Text).readText(), state)
        val channel = TestClientChannel(socket, keys, peer.ids)
        channel.receive()
        channel.send(MessageType.CAPABILITY.wire, CapabilityOp.HELLO, CapabilityData.serializer(), MAC_CAPABILITY)
        return channel
    }

    private companion object {
        const val REKEY_AFTER = 3L
        const val WAIT_MILLIS = 5_000L
    }
}
