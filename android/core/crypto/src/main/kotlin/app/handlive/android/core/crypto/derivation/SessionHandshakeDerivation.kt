package app.handlive.android.core.crypto.derivation

import app.handlive.android.core.crypto.primitives.HkdfSha256
import app.handlive.android.core.crypto.primitives.HmacSha256
import app.handlive.android.core.crypto.primitives.X25519Keys
import app.handlive.android.core.protocol.id.UuidBytes
import java.security.MessageDigest

/**
 * Bắt tay phiên `/v1/ctl` (0.6.3 bước 1–3, mã hóa byte theo bước 8):
 * `T1` = "HL1|hello|" ‖ pair_id(16) ‖ device_id C(16) ‖ eph C(32) ‖ nonce C(32) = 106 byte;
 * `T2` = "HL1|welcome|" ‖ T1 ‖ device_id S(16) ‖ eph S(32) ‖ nonce S(32) = 198 byte.
 */
object SessionHandshakeDerivation {
    const val K_AUTH_INFO = "handlive/v1/session-auth"
    const val SESSION_INFO = "handlive/v1/session"
    const val T1_SIZE = 106
    const val T2_SIZE = 198
    private const val FIELD_SIZE = 32
    private val HELLO_LABEL = "HL1|hello|".toByteArray(Charsets.US_ASCII)
    private val WELCOME_LABEL = "HL1|welcome|".toByteArray(Charsets.US_ASCII)

    /** `K_auth` = HKDF(PRK, salt rỗng, info "handlive/v1/session-auth", L = 32). */
    fun kAuth(prk: ByteArray): ByteArray = HkdfSha256.derive(ikm = prk, info = K_AUTH_INFO)

    fun t1(
        pairId: String,
        clientDeviceId: String,
        clientEph: ByteArray,
        clientNonce: ByteArray,
    ): ByteArray {
        requireField(clientEph, clientNonce)
        return HELLO_LABEL + UuidBytes.toBytes(pairId) + UuidBytes.toBytes(clientDeviceId) + clientEph + clientNonce
    }

    fun t2(
        t1: ByteArray,
        serverDeviceId: String,
        serverEph: ByteArray,
        serverNonce: ByteArray,
    ): ByteArray {
        require(t1.size == T1_SIZE) { "T1 must be $T1_SIZE bytes" }
        requireField(serverEph, serverNonce)
        return WELCOME_LABEL + t1 + UuidBytes.toBytes(serverDeviceId) + serverEph + serverNonce
    }

    /** `mac` của hello = HMAC(K_auth, T1); của welcome = HMAC(K_auth, T2). */
    fun mac(
        kAuth: ByteArray,
        transcript: ByteArray,
    ): ByteArray = HmacSha256.mac(kAuth, transcript)

    fun verifyMac(
        kAuth: ByteArray,
        transcript: ByteArray,
        mac: ByteArray,
    ): Boolean = HmacSha256.verify(kAuth, transcript, mac)

    /**
     * `secret` = HKDF(ikm = X25519(eph mình, eph đối phương) ‖ PRK, salt = SHA-256(T2),
     * info "handlive/v1/session", L = 64).
     */
    fun sessionKeys(
        ownEphPrivateKey: ByteArray,
        peerEphPublicKey: ByteArray,
        prk: ByteArray,
        t2: ByteArray,
    ): SessionKeys = sessionKeysFromShared(X25519Keys.sharedSecret(ownEphPrivateKey, peerEphPublicKey), prk, t2)

    fun sessionKeysFromShared(
        ephShared: ByteArray,
        prk: ByteArray,
        t2: ByteArray,
    ): SessionKeys {
        val salt = MessageDigest.getInstance("SHA-256").digest(t2)
        return SessionKeys(HkdfSha256.derive(ephShared + prk, salt, SESSION_INFO, SessionKeys.SECRET_SIZE))
    }

    private fun requireField(
        eph: ByteArray,
        nonce: ByteArray,
    ) {
        require(eph.size == FIELD_SIZE && nonce.size == FIELD_SIZE) { "eph and nonce must be $FIELD_SIZE bytes" }
    }
}
