package app.handlive.android.core.transport.server

import app.handlive.android.core.protocol.ErrorCode
import app.handlive.android.core.protocol.ProtocolException
import app.handlive.android.core.protocol.ProtocolJson
import app.handlive.android.core.protocol.capability.CapabilityData
import app.handlive.android.core.protocol.capability.CapabilityOp
import app.handlive.android.core.protocol.envelope.Envelope
import app.handlive.android.core.protocol.envelope.MessageType
import app.handlive.android.core.protocol.envelope.PlaintextCodec
import app.handlive.android.core.protocol.session.PROTOCOL_VERSION
import app.handlive.android.core.protocol.session.SessionOp
import app.handlive.android.core.protocol.session.SessionRekeyData
import app.handlive.android.core.transport.WsCloseCode
import io.ktor.websocket.CloseReason
import kotlinx.serialization.KSerializer
import kotlinx.serialization.SerializationException
import kotlinx.serialization.json.JsonObject

/**
 * Xử lý một envelope đã giải mã của phiên: `capability` (0.7.2), `session` (`rekey`, `bye`), `ack` của rekey;
 * mọi thứ khác chuyển cho mô-đun tính năng qua [ControlSession.inbound]. Trả [CloseReason] khi phải đóng phiên.
 */
internal object ControlSessionDispatcher {
    suspend fun dispatch(
        session: ControlSession,
        envelope: Envelope,
        plaintext: ByteArray,
    ): CloseReason? =
        try {
            when (MessageType.fromWire(envelope.type)) {
                MessageType.CAPABILITY -> onCapability(session, plaintext)
                MessageType.SESSION -> onSession(session, envelope, plaintext)
                MessageType.ACK -> onAck(session, envelope, plaintext)
                else -> deliver(session, envelope, plaintext)
            }
        } catch (_: ProtocolException) {
            CloseReason(WsCloseCode.BAD_REQUEST, "bad request")
        }

    /** `capability/hello|update`: ảnh chụp đầy đủ thay bản cũ; `protocol` khác major → 4426. */
    fun capabilityOrClose(plaintext: ByteArray): Pair<CapabilityData?, CloseReason?> {
        val capability =
            PlaintextCodec
                .decodePayload(plaintext)
                .takeIf { it.op == CapabilityOp.HELLO || it.op == CapabilityOp.UPDATE }
                ?.let { decode(CapabilityData.serializer(), it.data) }
        return when {
            capability == null -> null to null
            capability.protocol != PROTOCOL_VERSION -> null to CloseReason(WsCloseCode.UNSUPPORTED_VERSION, "protocol")
            else -> capability to null
        }
    }

    /** Envelope mã hóa đầu tiên của client phải là `capability/hello` (0.6.3 bước 4). */
    fun isCapabilityHello(
        envelope: Envelope,
        plaintext: ByteArray,
    ): Boolean =
        envelope.type == MessageType.CAPABILITY.wire && PlaintextCodec.decodePayload(plaintext).op == CapabilityOp.HELLO

    private fun onCapability(
        session: ControlSession,
        plaintext: ByteArray,
    ): CloseReason? {
        val (capability, close) = capabilityOrClose(plaintext)
        capability?.let(session::applyPeerCapability)
        return close
    }

    private suspend fun onSession(
        session: ControlSession,
        envelope: Envelope,
        plaintext: ByteArray,
    ): CloseReason? {
        val payload = PlaintextCodec.decodePayload(plaintext)
        return when (payload.op) {
            SessionOp.REKEY -> {
                session.channel.onRekeyRequest(envelope.id, decode(SessionRekeyData.serializer(), payload.data))
                null
            }

            SessionOp.BYE -> {
                CloseReason(WsCloseCode.NORMAL, "bye")
            }

            // hello/welcome/error chỉ hợp lệ lúc bắt tay; op lạ của sự kiện thì bỏ qua (0.5.1 quy tắc 3).
            else -> {
                null
            }
        }
    }

    private suspend fun onAck(
        session: ControlSession,
        envelope: Envelope,
        plaintext: ByteArray,
    ): CloseReason? {
        val ack = PlaintextCodec.decodeAck(plaintext)
        if (ack.re != session.channel.rekey.pendingRequestId) return deliver(session, envelope, plaintext)
        val data = ack.data?.takeIf { ack.ok }
        val switched = data != null && session.channel.onRekeyAck(ack.re, decode(SessionRekeyData.serializer(), data))
        return if (switched) null else CloseReason(WsCloseCode.INTERNAL, "rekey failed")
    }

    private suspend fun deliver(
        session: ControlSession,
        envelope: Envelope,
        plaintext: ByteArray,
    ): CloseReason? {
        session.deliver(InboundEnvelope(envelope.type, envelope.id, envelope.ts, plaintext))
        return null
    }

    private fun <T> decode(
        serializer: KSerializer<T>,
        data: JsonObject,
    ): T =
        try {
            ProtocolJson.decodeFromJsonElement(serializer, data)
        } catch (e: SerializationException) {
            throw ProtocolException(ErrorCode.BAD_REQUEST, "malformed data", e)
        } catch (e: IllegalArgumentException) {
            throw ProtocolException(ErrorCode.BAD_REQUEST, "malformed data", e)
        }
}
