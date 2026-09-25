package app.handlive.android.core.transport.server

import app.handlive.android.core.protocol.ErrorCode
import app.handlive.android.core.protocol.ProtocolJson
import app.handlive.android.core.protocol.ack.Ack
import app.handlive.android.core.protocol.envelope.Envelope
import app.handlive.android.core.protocol.envelope.EnvelopeCodec
import app.handlive.android.core.protocol.envelope.EnvelopeHeader
import app.handlive.android.core.protocol.envelope.MessageType
import app.handlive.android.core.protocol.envelope.PlaintextCodec
import app.handlive.android.core.protocol.id.UuidV7Generator
import app.handlive.android.core.protocol.session.SessionOp
import app.handlive.android.core.protocol.session.SessionRekeyData
import app.handlive.android.core.transport.TransportConstants
import app.handlive.android.core.transport.session.RekeyRequestResult
import app.handlive.android.core.transport.session.SessionCipher
import app.handlive.android.core.transport.session.SessionRekeyCoordinator
import io.ktor.websocket.Frame
import io.ktor.websocket.WebSocketSession
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch
import kotlinx.coroutines.sync.Mutex
import kotlinx.coroutines.sync.withLock
import kotlinx.serialization.json.jsonObject

/**
 * Lớp mã hóa của một phiên đã bắt tay: mọi thao tác trên khóa (mã hóa, giải mã, rekey) đi qua cùng một [lock]
 * để bộ đếm, `epoch` và thời điểm đổi khóa nhất quán giữa luồng gửi và vòng nhận.
 */
internal class EncryptedEnvelopeChannel(
    private val socket: WebSocketSession,
    val cipher: SessionCipher,
    val rekey: SessionRekeyCoordinator,
    private val clock: () -> Long,
    /** Rekey không có `ack` trong `REQUEST_TIMEOUT` → đóng phiên (CONN-02 E4). */
    private val onRekeyTimeout: suspend () -> Unit,
) {
    private val lock = Mutex()
    private val ids = UuidV7Generator(clock)

    suspend fun open(envelope: Envelope): ByteArray = lock.withLock { cipher.open(envelope) }

    /** Mã hóa và gửi; nếu đến ngưỡng rekey và chưa có rekey đang chờ thì gửi `session/rekey` trước. */
    suspend fun send(
        type: String,
        plaintext: ByteArray,
    ): String =
        lock.withLock {
            startRekeyIfDueLocked()
            ids.next().also { writeLocked(type, plaintext, it) }
        }

    suspend fun startRekeyIfDue() = lock.withLock { startRekeyIfDueLocked() }

    /** `session/rekey` của đối phương: trả `ack` bằng khóa cũ rồi mới đổi khóa (0.6.3 bước 6). */
    suspend fun onRekeyRequest(
        requestId: String,
        request: SessionRekeyData,
    ) = lock.withLock {
        when (val result = rekey.onRequest(request)) {
            is RekeyRequestResult.Respond -> {
                val data = ProtocolJson.encodeToJsonElement(SessionRekeyData.serializer(), result.ackData).jsonObject
                writeLocked(MessageType.ACK.wire, PlaintextCodec.encodeAck(Ack.success(requestId, data)), ids.next())
                cipher.install(result.newKeys, result.epoch)
            }

            RekeyRequestResult.IgnoreCollision -> {
                Unit
            }

            RekeyRequestResult.Invalid -> {
                val ack = Ack.failure(requestId, ErrorCode.BAD_REQUEST, "invalid rekey")
                writeLocked(MessageType.ACK.wire, PlaintextCodec.encodeAck(ack), ids.next())
            }
        }
    }

    /** `ack` của yêu cầu rekey mình gửi: đổi khóa ngay; `false` → bên gọi đóng phiên (CONN-02 E4). */
    suspend fun onRekeyAck(
        re: String,
        response: SessionRekeyData,
    ): Boolean = lock.withLock { rekey.onAck(re, response) }

    private suspend fun startRekeyIfDueLocked() {
        if (!cipher.rekeyDue() || rekey.pendingRequestId != null) return
        val requestId = ids.next()
        val data = rekey.start(requestId)
        writeLocked(
            MessageType.SESSION.wire,
            PlaintextCodec.encodeOp(SessionOp.REKEY, SessionRekeyData.serializer(), data),
            requestId,
        )
        socket.launch {
            delay(TransportConstants.REQUEST_TIMEOUT)
            if (rekey.pendingRequestId == requestId) onRekeyTimeout()
        }
    }

    private suspend fun writeLocked(
        type: String,
        plaintext: ByteArray,
        id: String,
    ) {
        val envelope = cipher.seal(EnvelopeHeader(type, id, clock()), plaintext)
        socket.send(Frame.Text(EnvelopeCodec.encode(envelope)))
    }
}
