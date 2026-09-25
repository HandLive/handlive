package app.handlive.android.core.transport

import app.handlive.android.core.protocol.capability.CapabilityData
import app.handlive.android.core.protocol.capability.CapabilityOp
import app.handlive.android.core.protocol.capability.SmsFeature
import app.handlive.android.core.protocol.envelope.MessageType
import app.handlive.android.core.protocol.envelope.Payload
import app.handlive.android.core.protocol.envelope.PlaintextCodec
import app.handlive.android.core.transport.capability.Feature
import app.handlive.android.core.transport.server.ControlConnectionState
import app.handlive.android.core.transport.testing.LoopbackServerFixture
import app.handlive.android.core.transport.testing.LoopbackServerFixture.Companion.ANDROID_CAPABILITY
import app.handlive.android.core.transport.testing.LoopbackServerFixture.Companion.MAC_CAPABILITY
import app.handlive.android.core.transport.testing.TestClientChannel
import app.handlive.android.core.transport.testing.TestClientPeer
import app.handlive.android.core.transport.testing.pinnedWebSocketClient
import io.ktor.client.plugins.websocket.DefaultClientWebSocketSession
import io.ktor.client.plugins.websocket.webSocket
import io.ktor.websocket.Frame
import io.ktor.websocket.readText
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.runBlocking
import kotlinx.coroutines.withTimeout
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.JsonPrimitive
import org.junit.After
import org.junit.Assert.assertArrayEquals
import org.junit.Assert.assertEquals
import org.junit.Test

/** Bắt tay thật qua loopback: TLS 1.3 + ghim, `session/hello|welcome`, `capability/hello` đã mã hóa (CONN-01). */
class ControlChannelHandshakeTest {
    private val fixture = LoopbackServerFixture()
    private val client = pinnedWebSocketClient(fixture.tls.certificateSha256())

    @After
    fun tearDown() {
        client.close()
        fixture.close()
    }

    @Test
    fun bothSidesDeriveSameKeysAndExchangeEncryptedCapabilityHello() =
        runBlocking {
            val peer = fixture.addPair()
            client.webSocket(fixture.url) {
                val channel = handshake(peer)
                val (envelope, plaintext) = channel.receive()
                assertEquals(MessageType.CAPABILITY.wire, envelope.type)
                val serverCapability = PlaintextCodec.decodeOp(plaintext, CapabilityData.serializer())
                assertEquals(CapabilityOp.HELLO, serverCapability.op)
                assertEquals(ANDROID_CAPABILITY, serverCapability.data)
                channel.send(
                    MessageType.CAPABILITY.wire,
                    CapabilityOp.HELLO,
                    CapabilityData.serializer(),
                    MAC_CAPABILITY,
                )

                val session = fixture.awaitSession()
                assertArrayEquals(channel.cipher.keys.kC2s, session.channel.cipher.keys.kC2s)
                assertArrayEquals(channel.cipher.keys.kS2c, session.channel.cipher.keys.kS2c)
                assertEquals(peer.pairId, session.pairId)
                assertEquals(ControlConnectionState.ESTABLISHED, session.state.value)
                assertEquals(MAC_CAPABILITY, session.peerCapability.value)
            }
        }

    @Test
    fun featureIsEffectiveOnlyWhenBothSidesEnableItAndAndroidHasPermission() =
        runBlocking {
            val peer = fixture.addPair()
            client.webSocket(fixture.url) {
                val channel = handshake(peer)
                channel.receive()
                channel.send(
                    MessageType.CAPABILITY.wire,
                    CapabilityOp.HELLO,
                    CapabilityData.serializer(),
                    MAC_CAPABILITY,
                )
                val session = fixture.awaitSession()
                // sms: Mac tắt; camera: Android thiếu CAMERA; relay: Android tắt; call: READ_CALL_LOG chỉ hạ caller_id.
                assertEquals(setOf(Feature.CLIPBOARD, Feature.CALL), session.effectiveFeatures.value)

                // capability/update là ảnh chụp đầy đủ: bên nhận thay toàn bộ, không gộp.
                val update =
                    MAC_CAPABILITY.copy(
                        features = MAC_CAPABILITY.features.copy(sms = SmsFeature(enabled = true)),
                    )
                channel.send(MessageType.CAPABILITY.wire, CapabilityOp.UPDATE, CapabilityData.serializer(), update)
                val expected = setOf(Feature.CLIPBOARD, Feature.CALL, Feature.SMS)
                withTimeout(WAIT_MILLIS) { session.effectiveFeatures.first { it == expected } }
                assertEquals(update, session.peerCapability.value)
            }
        }

    @Test
    fun applicationEnvelopesAreDecryptedAndDeliveredInBothDirections() =
        runBlocking {
            val peer = fixture.addPair()
            client.webSocket(fixture.url) {
                val channel = handshake(peer)
                channel.receive()
                channel.send(
                    MessageType.CAPABILITY.wire,
                    CapabilityOp.HELLO,
                    CapabilityData.serializer(),
                    MAC_CAPABILITY,
                )
                val session = fixture.awaitSession()

                val push = Payload("push", JsonObject(mapOf("text" to JsonPrimitive("Xin chào"))))
                val id = channel.sendPlaintext(MessageType.CLIPBOARD.wire, PlaintextCodec.encodePayload(push))
                val inbound = withTimeout(WAIT_MILLIS) { session.inbound.receive() }
                assertEquals(MessageType.CLIPBOARD.wire, inbound.type)
                assertEquals(id, inbound.id)
                assertEquals(push, PlaintextCodec.decodePayload(inbound.plaintext))

                session.send(MessageType.SMS, PlaintextCodec.encodePayload(push))
                val (envelope, plaintext) = channel.receive()
                assertEquals(MessageType.SMS.wire, envelope.type)
                assertEquals(push, PlaintextCodec.decodePayload(plaintext))
            }
        }

    private suspend fun DefaultClientWebSocketSession.handshake(peer: TestClientPeer): TestClientChannel {
        val (hello, state) = peer.hello()
        send(Frame.Text(hello))
        val keys = peer.acceptWelcome((incoming.receive() as Frame.Text).readText(), state)
        return TestClientChannel(this, keys, peer.ids)
    }

    private companion object {
        const val WAIT_MILLIS = 5_000L
    }
}
