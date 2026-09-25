package app.handlive.android.core.protocol.session

import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

/** Tên `op` của `type = session` (0.7.1). */
object SessionOp {
    const val HELLO = "hello"
    const val WELCOME = "welcome"
    const val ERROR = "error"
    const val REKEY = "rekey"
    const val BYE = "bye"
}

/** Phiên bản giao thức hiện tại (`protocol` trong `session/hello`, `capability/hello`). */
const val PROTOCOL_VERSION = 1

/** `session/hello` C→S (0.6.3 bước 1); `eph`, `nonce`, `mac` là b64u 32 byte. Payload chưa mã hóa. */
@Serializable
data class SessionHelloData(
    val protocol: Int,
    @SerialName("pair_id") val pairId: String,
    @SerialName("device_id") val deviceId: String,
    val eph: String,
    val nonce: String,
    val mac: String,
)

/** `session/welcome` S→C (0.6.3 bước 2). Payload chưa mã hóa. */
@Serializable
data class SessionWelcomeData(
    @SerialName("device_id") val deviceId: String,
    val eph: String,
    val nonce: String,
    val mac: String,
)

/**
 * `session/error` S→C: `code` ∈ {AUTH_FAILED, PAIR_UNKNOWN, PAIR_REVOKED, UNSUPPORTED_VERSION, RATE_LIMITED};
 * `min_protocol` chỉ có khi `code = UNSUPPORTED_VERSION`.
 */
@Serializable
data class SessionErrorData(
    val code: String,
    val message: String,
    @SerialName("min_protocol") val minProtocol: Int? = null,
)

/** `session/rekey` (0.6.3 bước 6) và `data` của ack tương ứng: `{epoch, eph, nonce}`. */
@Serializable
data class SessionRekeyData(
    val epoch: Int,
    val eph: String,
    val nonce: String,
)

/** `session/bye`: `reason` ∈ {revoked, shutdown, replaced, update}. */
@Serializable
data class SessionByeData(
    val reason: String,
)
