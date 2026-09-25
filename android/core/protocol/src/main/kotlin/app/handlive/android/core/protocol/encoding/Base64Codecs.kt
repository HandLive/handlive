package app.handlive.android.core.protocol.encoding

import app.handlive.android.core.protocol.ErrorCode
import app.handlive.android.core.protocol.ProtocolException
import java.util.Base64

/** `b64` (RFC 4648 §4, có padding) và `b64u` (RFC 4648 §5, không padding) theo 0.3; chỉ nhận dạng chuẩn tắc. */
object Base64Codecs {
    private val b64Encoder = Base64.getEncoder()
    private val b64Decoder = Base64.getDecoder()
    private val b64uEncoder = Base64.getUrlEncoder().withoutPadding()
    private val b64uDecoder = Base64.getUrlDecoder()

    fun encodeB64(bytes: ByteArray): String = b64Encoder.encodeToString(bytes)

    fun encodeB64u(bytes: ByteArray): String = b64uEncoder.encodeToString(bytes)

    /** Giải `b64`; từ chối ký tự lạ, thiếu padding hoặc bit thừa khác 0 (không chuẩn tắc). */
    fun decodeB64(text: String): ByteArray = decodeCanonical(text, b64Decoder::decode, ::encodeB64, "b64")

    /** Giải `b64u`; từ chối padding `=` và dạng không chuẩn tắc. */
    fun decodeB64u(text: String): ByteArray {
        if (text.contains('=')) throw invalid("b64u")
        return decodeCanonical(text, b64uDecoder::decode, ::encodeB64u, "b64u")
    }

    /** Giải `b64u` và kiểm đúng [length] byte (ví dụ `eph`, `nonce`, `mac` = 32 byte). */
    fun decodeB64u(
        text: String,
        length: Int,
    ): ByteArray {
        val bytes = decodeB64u(text)
        if (bytes.size != length) throw invalid("b64u")
        return bytes
    }

    private fun decodeCanonical(
        text: String,
        decode: (String) -> ByteArray,
        encode: (ByteArray) -> String,
        kind: String,
    ): ByteArray {
        val bytes =
            try {
                decode(text)
            } catch (e: IllegalArgumentException) {
                throw invalid(kind, e)
            }
        if (encode(bytes) != text) throw invalid(kind)
        return bytes
    }

    private fun invalid(
        kind: String,
        cause: Throwable? = null,
    ) = ProtocolException(ErrorCode.BAD_REQUEST, "invalid $kind", cause)
}
