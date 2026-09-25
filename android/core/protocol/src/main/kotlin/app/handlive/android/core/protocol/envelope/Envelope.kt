package app.handlive.android.core.protocol.envelope

import kotlinx.serialization.Serializable

/**
 * Envelope JSON trên WS text frame (0.5.1): `{v, type, id, ts, payload}`.
 * `type` giữ dạng chuỗi để nhận được cả nhóm tin chưa biết; dùng [MessageType.fromWire] khi cần enum.
 * `payload` là b64 của `nonce(24) ‖ ciphertext ‖ tag(16)`, hoặc của JSON chưa mã hóa với tin bắt tay.
 */
@Serializable
data class Envelope(
    val v: Int,
    val type: String,
    val id: String,
    val ts: Long,
    val payload: String,
) {
    /** AAD của XChaCha20-Poly1305 = UTF-8 của `"<v>|<type>|<id>|<ts>"`. */
    fun aad(): ByteArray = aadString(v, type, id, ts).toByteArray(Charsets.UTF_8)

    companion object {
        const val VERSION = 1

        /** Giới hạn cứng của một envelope (0.5.1 quy tắc 4). */
        const val MAX_BYTES = 256 * 1024

        fun aadString(
            v: Int,
            type: String,
            id: String,
            ts: Long,
        ): String = "$v|$type|$id|$ts"
    }
}
