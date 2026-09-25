package app.handlive.android.core.crypto.primitives

import javax.crypto.Mac
import javax.crypto.spec.SecretKeySpec

/** HMAC-SHA256 và so sánh MAC hằng thời gian (0.6.3 bước 2). */
object HmacSha256 {
    const val ALGORITHM = "HmacSHA256"

    fun mac(
        key: ByteArray,
        message: ByteArray,
    ): ByteArray =
        Mac.getInstance(ALGORITHM).run {
            init(SecretKeySpec(key, ALGORITHM))
            doFinal(message)
        }

    /** `true` khi `mac` = HMAC(key, message); không rò thời gian theo vị trí byte khác nhau. */
    fun verify(
        key: ByteArray,
        message: ByteArray,
        mac: ByteArray,
    ): Boolean = constantTimeEquals(mac(key, message), mac)

    fun constantTimeEquals(
        a: ByteArray,
        b: ByteArray,
    ): Boolean {
        if (a.size != b.size) return false
        var diff = 0
        for (i in a.indices) diff = diff or (a[i].toInt() xor b[i].toInt())
        return diff == 0
    }
}
