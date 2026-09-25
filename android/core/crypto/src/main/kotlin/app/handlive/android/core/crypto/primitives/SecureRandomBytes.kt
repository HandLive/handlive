package app.handlive.android.core.crypto.primitives

import java.security.SecureRandom

/** Nguồn byte ngẫu nhiên an toàn mật mã dùng chung (nonce, khóa tạm). */
object SecureRandomBytes {
    private val random = SecureRandom()

    fun next(size: Int): ByteArray = ByteArray(size).also(random::nextBytes)
}
