package app.handlive.android.core.protocol.ack

import app.handlive.android.core.protocol.ErrorCode
import kotlinx.serialization.Serializable
import kotlinx.serialization.json.JsonObject

/**
 * Plaintext của envelope `type = ack` (0.5.1):
 * thành công `{"re","ok":true,"data":{}}`, thất bại `{"re","ok":false,"error":{code,message,details?}}`.
 */
@Serializable
data class Ack(
    val re: String,
    val ok: Boolean,
    val data: JsonObject? = null,
    val error: AckError? = null,
) {
    init {
        require(if (ok) data != null && error == null else error != null && data == null) {
            "ack ok=true needs data only; ok=false needs error only"
        }
    }

    companion object {
        fun success(
            re: String,
            data: JsonObject = JsonObject(emptyMap()),
        ) = Ack(re = re, ok = true, data = data)

        fun failure(
            re: String,
            code: ErrorCode,
            message: String,
            details: JsonObject? = null,
        ) = Ack(re = re, ok = false, error = AckError(code.name, message, details))
    }
}

/** `ack.error`; `code` giữ dạng chuỗi để nhận cả mã mới hơn — dùng [errorCode] khi cần enum. */
@Serializable
data class AckError(
    val code: String,
    val message: String,
    val details: JsonObject? = null,
) {
    val errorCode: ErrorCode? get() = ErrorCode.fromWire(code)
}
