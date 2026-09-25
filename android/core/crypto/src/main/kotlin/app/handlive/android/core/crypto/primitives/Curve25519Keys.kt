package app.handlive.android.core.crypto.primitives

import com.google.crypto.tink.subtle.Ed25519Sign
import com.google.crypto.tink.subtle.Ed25519Verify
import com.google.crypto.tink.subtle.X25519
import java.security.GeneralSecurityException

/** X25519 (RFC 7748) cho `ik_dh` và khóa tạm `eph`; Tink tự clamp scalar. */
object X25519Keys {
    const val KEY_SIZE = 32

    fun generatePrivateKey(): ByteArray = X25519.generatePrivateKey()

    fun publicFromPrivate(privateKey: ByteArray): ByteArray = X25519.publicFromPrivate(privateKey)

    /** Tink từ chối điểm bậc thấp (bí mật chung toàn 0) bằng `InvalidKeyException`. */
    fun sharedSecret(
        privateKey: ByteArray,
        peerPublicKey: ByteArray,
    ): ByteArray = X25519.computeSharedSecret(privateKey, peerPublicKey)
}

/** Ed25519 (RFC 8032) cho `ik_sig`: khóa bí mật lưu dạng seed 32 byte. */
object Ed25519Keys {
    const val SEED_SIZE = 32

    fun generateSeed(): ByteArray = SecureRandomBytes.next(SEED_SIZE)

    fun publicFromSeed(seed: ByteArray): ByteArray = Ed25519Sign.KeyPair.newKeyPairFromSeed(seed).publicKey

    fun sign(
        seed: ByteArray,
        message: ByteArray,
    ): ByteArray = Ed25519Sign(seed).sign(message)

    fun verify(
        publicKey: ByteArray,
        message: ByteArray,
        signature: ByteArray,
    ): Boolean =
        try {
            Ed25519Verify(publicKey).verify(signature, message)
            true
        } catch (_: GeneralSecurityException) {
            false
        }
}
