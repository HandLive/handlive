package app.handlive.android.core.crypto

import java.nio.ByteBuffer
import java.nio.ByteOrder

/**
 * HChaCha20 (draft-irtf-cfrg-xchacha-03 §2.2) cài theo đặc tả, chỉ dùng trong test: kiểm hchacha20.json và
 * chứng minh XChaCha20 của Tink = HChaCha20 + ChaCha20-Poly1305 nonce 12 byte — đúng cấu trúc phía Apple dùng.
 */
object HChaCha20Reference {
    private val CONSTANTS = intArrayOf(0x61707865, 0x3320646e, 0x79622d32, 0x6b206574)
    private const val KEY_WORDS = 8
    private const val NONCE_WORDS = 4
    private const val DOUBLE_ROUNDS = 10

    fun subkey(
        key: ByteArray,
        nonce16: ByteArray,
    ): ByteArray {
        require(key.size == KEY_WORDS * 4 && nonce16.size == NONCE_WORDS * 4)
        val s = IntArray(16)
        CONSTANTS.copyInto(s)
        words(key).copyInto(s, 4)
        words(nonce16).copyInto(s, 12)
        repeat(DOUBLE_ROUNDS) {
            quarter(s, 0, 4, 8, 12)
            quarter(s, 1, 5, 9, 13)
            quarter(s, 2, 6, 10, 14)
            quarter(s, 3, 7, 11, 15)
            quarter(s, 0, 5, 10, 15)
            quarter(s, 1, 6, 11, 12)
            quarter(s, 2, 7, 8, 13)
            quarter(s, 3, 4, 9, 14)
        }
        val out = ByteBuffer.allocate(32).order(ByteOrder.LITTLE_ENDIAN)
        for (i in 0..3) out.putInt(s[i])
        for (i in 12..15) out.putInt(s[i])
        return out.array()
    }

    private fun words(bytes: ByteArray): IntArray {
        val buffer = ByteBuffer.wrap(bytes).order(ByteOrder.LITTLE_ENDIAN)
        return IntArray(bytes.size / 4) { buffer.getInt() }
    }

    private fun quarter(
        s: IntArray,
        a: Int,
        b: Int,
        c: Int,
        d: Int,
    ) {
        s[a] += s[b]
        s[d] = (s[d] xor s[a]).rotateLeft(16)
        s[c] += s[d]
        s[b] = (s[b] xor s[c]).rotateLeft(12)
        s[a] += s[b]
        s[d] = (s[d] xor s[a]).rotateLeft(8)
        s[c] += s[d]
        s[b] = (s[b] xor s[c]).rotateLeft(7)
    }
}
