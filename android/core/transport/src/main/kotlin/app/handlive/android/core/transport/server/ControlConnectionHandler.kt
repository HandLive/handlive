package app.handlive.android.core.transport.server

import app.handlive.android.core.protocol.ErrorCode
import app.handlive.android.core.protocol.ProtocolException
import app.handlive.android.core.protocol.envelope.EnvelopeCodec
import app.handlive.android.core.protocol.id.UuidV7Generator
import app.handlive.android.core.transport.WsCloseCode
import app.handlive.android.core.transport.handshake.HandshakeOutcome
import app.handlive.android.core.transport.handshake.ServerHandshake
import io.ktor.websocket.CloseReason
import io.ktor.websocket.Frame
import io.ktor.websocket.WebSocketSession
import io.ktor.websocket.close
import io.ktor.websocket.readText
import kotlinx.coroutines.channels.ClosedReceiveChannelException
import kotlinx.coroutines.withTimeoutOrNull

/**
 * Vòng đời một kết nối `/v1/ctl` phía S: bắt tay (0.6.3 bước 1–5) trong `HANDSHAKE_TIMEOUT`, rồi vòng nhận
 * envelope mã hóa. Không log payload hay plaintext; lỗi chỉ lộ ra qua mã đóng WebSocket (0.8.3).
 */
internal class ControlConnectionHandler(
    private val config: ControlServerConfig,
    private val registry: ActiveSessionRegistry,
) {
    private val handshake =
        ServerHandshake(config.localDeviceId, config.pairs, UuidV7Generator(config.options.clock), config.options.clock)

    suspend fun handle(socket: WebSocketSession) {
        val result = withTimeoutOrNull(config.options.handshakeTimeout) { establish(socket) }
        when (result) {
            null -> socket.close(CloseReason(WsCloseCode.HANDSHAKE_TIMEOUT, "handshake timeout"))
            is Result.Closed -> result.reason?.let { socket.close(it) }
            is Result.Established -> serve(socket, result.session)
        }
    }

    private suspend fun serve(
        socket: WebSocketSession,
        session: ControlSession,
    ) {
        registry.replace(session)?.replaced()
        config.onSessionEstablished(session)
        try {
            var close: CloseReason? = null
            val frames = socket.incoming.iterator()
            while (close == null && frames.hasNext()) close = handleFrame(session, frames.next())
            close?.let { session.close(it.code, it.message) }
        } finally {
            session.markClosed()
            registry.remove(session)
        }
    }

    private sealed interface Result {
        class Established(
            val session: ControlSession,
        ) : Result

        class Closed(
            val reason: CloseReason?,
        ) : Result
    }

    /** `session/hello` → `welcome` + `capability/hello` của S; hoặc `session/error` rồi đóng. */
    private suspend fun establish(socket: WebSocketSession): Result {
        val helloText = receiveText(socket) ?: return Result.Closed(badRequestOrGone(socket))
        return when (val outcome = handshake.respond(helloText)) {
            is HandshakeOutcome.Rejected -> {
                outcome.error?.let { socket.send(Frame.Text(EnvelopeCodec.encode(it))) }
                Result.Closed(CloseReason(outcome.closeCode, outcome.code.name))
            }

            is HandshakeOutcome.Accepted -> {
                socket.send(Frame.Text(EnvelopeCodec.encode(outcome.welcome)))
                val session =
                    ControlSession(outcome.pair.pairId, outcome.pair.peerDeviceId, socket, outcome.keys, config)
                session.sendCapabilityHello()
                confirmKeys(socket, session)
            }
        }
    }

    /** Envelope mã hóa đầu tiên của C phải là `capability/hello` giải mã được (0.6.3 bước 4, CONN-01 API 5). */
    private suspend fun confirmKeys(
        socket: WebSocketSession,
        session: ControlSession,
    ): Result {
        val text = receiveText(socket) ?: return Result.Closed(badRequestOrGone(socket))
        val close =
            try {
                firstCapabilityClose(session, text)
            } catch (e: ProtocolException) {
                // Không giải mã được → khóa không khớp → 4401.
                val code = if (e.code == ErrorCode.DECRYPT_FAILED) WsCloseCode.AUTH_FAILED else WsCloseCode.BAD_REQUEST
                CloseReason(code, e.code.name)
            }
        return close?.let(Result::Closed) ?: Result.Established(session.also { it.markEstablished() })
    }

    private suspend fun firstCapabilityClose(
        session: ControlSession,
        text: String,
    ): CloseReason? {
        val envelope = EnvelopeCodec.decode(text)
        val plaintext = session.channel.open(envelope)
        val (capability, close) =
            if (ControlSessionDispatcher.isCapabilityHello(envelope, plaintext)) {
                ControlSessionDispatcher.capabilityOrClose(plaintext)
            } else {
                null to BAD_REQUEST
            }
        capability?.let(session::applyPeerCapability)
        return close ?: BAD_REQUEST.takeIf { capability == null }
    }

    private suspend fun handleFrame(
        session: ControlSession,
        frame: Frame,
    ): CloseReason? {
        if (frame !is Frame.Text) return BAD_REQUEST
        return try {
            val envelope = EnvelopeCodec.decode(frame.readText())
            val plaintext = session.channel.open(envelope)
            ControlSessionDispatcher.dispatch(session, envelope, plaintext).also {
                if (it == null) session.channel.startRekeyIfDue()
            }
        } catch (e: ProtocolException) {
            // `DECRYPT_FAILED` sau bắt tay → 4400, client kết nối lại (CONN-02 E5).
            CloseReason(WsCloseCode.BAD_REQUEST, e.code.name)
        }
    }

    /** `null` khi client đã đóng hoặc gửi frame nhị phân (sai giao thức trên `/v1/ctl`). */
    private suspend fun receiveText(socket: WebSocketSession): String? =
        try {
            (socket.incoming.receive() as? Frame.Text)?.readText()
        } catch (_: ClosedReceiveChannelException) {
            null
        }

    private fun badRequestOrGone(socket: WebSocketSession): CloseReason? =
        if (socket.incoming.isClosedForReceive) null else BAD_REQUEST

    private companion object {
        val BAD_REQUEST = CloseReason(WsCloseCode.BAD_REQUEST, "BAD_REQUEST")
    }
}
