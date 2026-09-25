package app.handlive.android.core.transport.server

import app.handlive.android.core.crypto.derivation.PeerRole
import app.handlive.android.core.crypto.derivation.SessionKeys
import app.handlive.android.core.protocol.capability.CapabilityData
import app.handlive.android.core.protocol.capability.CapabilityOp
import app.handlive.android.core.protocol.envelope.MessageType
import app.handlive.android.core.protocol.envelope.PlaintextCodec
import app.handlive.android.core.protocol.session.SessionByeData
import app.handlive.android.core.protocol.session.SessionOp
import app.handlive.android.core.transport.WsCloseCode
import app.handlive.android.core.transport.capability.EffectiveFeatures
import app.handlive.android.core.transport.capability.Feature
import app.handlive.android.core.transport.session.SessionCipher
import app.handlive.android.core.transport.session.SessionRekeyCoordinator
import io.ktor.websocket.CloseReason
import io.ktor.websocket.WebSocketSession
import io.ktor.websocket.close
import kotlinx.coroutines.channels.Channel
import kotlinx.coroutines.channels.ReceiveChannel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import java.util.concurrent.atomic.AtomicBoolean

/** Envelope ứng dụng đã giải mã, giao cho mô-đun tính năng (clipboard, SMS…). Không log [plaintext]. */
class InboundEnvelope(
    val type: String,
    val id: String,
    val ts: Long,
    val plaintext: ByteArray,
)

/**
 * Một phiên `/v1/ctl` với một client đã ghép nối. Mọi envelope mã hóa bằng khóa theo chiều gửi; `session` và
 * `capability` xử lý trong tầng này, các `type` khác chuyển qua [inbound]. Rekey tự khởi tạo khi đạt `REKEY_AFTER`.
 */
class ControlSession internal constructor(
    val pairId: String,
    val peerDeviceId: String,
    private val socket: WebSocketSession,
    keys: SessionKeys,
    private val config: ControlServerConfig,
) {
    internal val channel: EncryptedEnvelopeChannel =
        SessionCipher(keys, PeerRole.SERVER, config.options.clock, config.options.rekeyAfterEnvelopes).let { cipher ->
            EncryptedEnvelopeChannel(
                socket,
                cipher,
                SessionRekeyCoordinator(config.localDeviceId, peerDeviceId, cipher),
                config.options.clock,
            ) { close(WsCloseCode.INTERNAL, "rekey timeout") }
        }
    private val inboundChannel = Channel<InboundEnvelope>(Channel.BUFFERED)
    private val stateFlow = MutableStateFlow(ControlConnectionState.AWAITING_CAPABILITY)
    private val peerCapabilityFlow = MutableStateFlow<CapabilityData?>(null)
    private val effectiveFlow = MutableStateFlow<Set<Feature>>(emptySet())
    private val closing = AtomicBoolean(false)

    val state: StateFlow<ControlConnectionState> = stateFlow.asStateFlow()
    val peerCapability: StateFlow<CapabilityData?> = peerCapabilityFlow.asStateFlow()

    /** Tính năng hiệu lực hiện tại (0.7.2); mô-đun tính năng chỉ chạy khi có tên mình trong tập này. */
    val effectiveFeatures: StateFlow<Set<Feature>> = effectiveFlow.asStateFlow()
    val inbound: ReceiveChannel<InboundEnvelope> = inboundChannel

    /** Gửi một envelope ứng dụng đã mã hóa; trả `id` của envelope. */
    suspend fun send(
        type: MessageType,
        plaintext: ByteArray,
    ): String = channel.send(type.wire, plaintext)

    /** Gửi `capability/update` (ảnh chụp đầy đủ) khi cấu hình Android đổi, và tính lại tính năng hiệu lực. */
    suspend fun sendCapabilityUpdate() {
        val local = config.localCapability()
        channel.send(MessageType.CAPABILITY.wire, capabilityPlaintext(CapabilityOp.UPDATE, local))
        peerCapabilityFlow.value?.let { effectiveFlow.value = EffectiveFeatures.compute(local, it) }
    }

    /** `session/bye` rồi đóng 1000 (CONN-02 API 4). */
    suspend fun bye(reason: String) {
        channel.send(MessageType.SESSION.wire, byePlaintext(reason))
        close(WsCloseCode.NORMAL, reason)
    }

    suspend fun close(
        code: Short,
        message: String,
    ) {
        if (!closing.compareAndSet(false, true)) return
        markClosed()
        socket.close(CloseReason(code, message))
    }

    /** Phiên mới của cùng cặp đã bắt tay xong: `session/bye {reason: replaced}` rồi đóng 4409 (CONN-01 bước 7). */
    internal suspend fun replaced() {
        runCatching { channel.send(MessageType.SESSION.wire, byePlaintext(BYE_REPLACED)) }
        close(WsCloseCode.REPLACED, BYE_REPLACED)
    }

    internal suspend fun sendCapabilityHello() {
        channel.send(MessageType.CAPABILITY.wire, capabilityPlaintext(CapabilityOp.HELLO, config.localCapability()))
    }

    internal fun applyPeerCapability(peer: CapabilityData) {
        peerCapabilityFlow.value = peer
        effectiveFlow.value = EffectiveFeatures.compute(config.localCapability(), peer)
    }

    internal fun markEstablished() {
        stateFlow.value = ControlConnectionState.ESTABLISHED
    }

    internal fun markClosed() {
        stateFlow.value = ControlConnectionState.CLOSED
        inboundChannel.close()
    }

    internal suspend fun deliver(message: InboundEnvelope) = inboundChannel.send(message)

    private companion object {
        const val BYE_REPLACED = "replaced"
    }
}

private fun capabilityPlaintext(
    op: String,
    data: CapabilityData,
) = PlaintextCodec.encodeOp(op, CapabilityData.serializer(), data)

private fun byePlaintext(reason: String) =
    PlaintextCodec.encodeOp(SessionOp.BYE, SessionByeData.serializer(), SessionByeData(reason))
