package app.handlive.android.core.crypto.primitives

import com.google.crypto.tink.aead.internal.InsecureNonceXChaCha20Poly1305
import java.security.GeneralSecurityException

/**
 * XChaCha20-Poly1305 (draft-irtf-cfrg-xchacha-03) qua Tink, đầu ra `nonce(24) ‖ ciphertext ‖ tag(16)` (0.5.1).
 *
 * Dùng `InsecureNonceXChaCha20Poly1305` của Tink (cùng lõi với `subtle.XChaCha20Poly1305`) vì cần nhận nonce
 * từ ngoài để test vector khớp từng byte. Chữ "Insecure" chỉ nghĩa là bên gọi phải tự lo nonce không lặp:
 * [seal] mặc định sinh 24 byte ngẫu nhiên bằng [SecureRandomBytes] — xác suất trùng không đáng kể với nonce 192 bit.
 */
object XChaCha20Poly1305Aead {
    const val KEY_SIZE = 32
    const val NONCE_SIZE = 24
    const val TAG_SIZE = 16

    fun seal(
        key: ByteArray,
        plaintext: ByteArray,
        aad: ByteArray,
        nonce: ByteArray = SecureRandomBytes.next(NONCE_SIZE),
    ): ByteArray {
        require(key.size == KEY_SIZE) { "key must be $KEY_SIZE bytes" }
        require(nonce.size == NONCE_SIZE) { "nonce must be $NONCE_SIZE bytes" }
        return nonce + InsecureNonceXChaCha20Poly1305(key).encrypt(nonce, plaintext, aad)
    }

    /** Mở `nonce ‖ ciphertext ‖ tag`; sai khóa, tag, AAD hoặc quá ngắn → [GeneralSecurityException]. */
    fun open(
        key: ByteArray,
        sealed: ByteArray,
        aad: ByteArray,
    ): ByteArray {
        require(key.size == KEY_SIZE) { "key must be $KEY_SIZE bytes" }
        if (sealed.size < NONCE_SIZE + TAG_SIZE) throw GeneralSecurityException("sealed payload too short")
        val nonce = sealed.copyOfRange(0, NONCE_SIZE)
        val ciphertext = sealed.copyOfRange(NONCE_SIZE, sealed.size)
        return InsecureNonceXChaCha20Poly1305(key).decrypt(nonce, ciphertext, aad)
    }
}
