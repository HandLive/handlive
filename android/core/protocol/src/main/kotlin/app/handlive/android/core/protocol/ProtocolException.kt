package app.handlive.android.core.protocol

/**
 * Lỗi giao thức mang mã lỗi ứng dụng (0.8.1) để tầng gọi trả `ack` lỗi hoặc đóng phiên đúng mã.
 * Thông điệp chỉ mô tả cấu trúc (độ dài, trường thiếu) — không bao giờ chứa nội dung người dùng.
 */
class ProtocolException(
    val code: ErrorCode,
    message: String,
    cause: Throwable? = null,
) : Exception(message, cause)

/** Kiểm điều kiện đầu vào từ đối phương; sai → [ProtocolException] với [code]. */
fun protocolRequire(
    condition: Boolean,
    code: ErrorCode,
    message: String,
) {
    if (!condition) throw ProtocolException(code, message)
}
