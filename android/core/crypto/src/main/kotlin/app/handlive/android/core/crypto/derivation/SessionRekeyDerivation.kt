package app.handlive.android.core.crypto.derivation

import app.handlive.android.core.crypto.primitives.HkdfSha256
import app.handlive.android.core.crypto.primitives.X25519Keys
import java.security.MessageDigest

/**
 * Rekey (0.6.3 bước 6, 8): ikm = X25519(eph bên khởi tạo, eph bên nhận) ‖ `secret` cũ,
 * salt = SHA-256(nonce bên khởi tạo ‖ nonce bên nhận), info "handlive/v1/rekey", L = 64.
 * Kết quả chia `k_c2s` ‖ `k_s2c` theo vai C/S và thay `secret` cho lần rekey sau; `epoch` không vào KDF.
 */
object SessionRekeyDerivation {
    const val INFO = "handlive/v1/rekey"

    fun rekey(
        previous: SessionKeys,
        ownEphPrivateKey: ByteArray,
        peerEphPublicKey: ByteArray,
        initiatorNonce: ByteArray,
        responderNonce: ByteArray,
    ): SessionKeys =
        rekeyFromShared(
            previous.secret,
            X25519Keys.sharedSecret(ownEphPrivateKey, peerEphPublicKey),
            initiatorNonce,
            responderNonce,
        )

    fun rekeyFromShared(
        previousSecret: ByteArray,
        ephShared: ByteArray,
        initiatorNonce: ByteArray,
        responderNonce: ByteArray,
    ): SessionKeys {
        val salt = MessageDigest.getInstance("SHA-256").digest(initiatorNonce + responderNonce)
        return SessionKeys(HkdfSha256.derive(ephShared + previousSecret, salt, INFO, SessionKeys.SECRET_SIZE))
    }
}
