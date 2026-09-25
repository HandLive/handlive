package app.handlive.android.core.protocol.stream

import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

/** Tên `op` của tin mở kênh stream (`type` = `camera` hoặc `call_audio`, 0.6.3 bước 7). */
object StreamOp {
    const val STREAM_HELLO = "stream_hello"
    const val STREAM_WELCOME = "stream_welcome"
}

/** `data` của `stream_hello` / `stream_welcome`: `{session_id, nonce, mac}`; payload chưa mã hóa. */
@Serializable
data class StreamHandshakeData(
    @SerialName("session_id") val sessionId: String,
    val nonce: String,
    val mac: String,
)
