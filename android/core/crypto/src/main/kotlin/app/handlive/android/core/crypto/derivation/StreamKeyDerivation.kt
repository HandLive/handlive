package app.handlive.android.core.crypto.derivation

import app.handlive.android.core.crypto.primitives.HkdfSha256
import app.handlive.android.core.crypto.primitives.HmacSha256
import app.handlive.android.core.protocol.id.UuidBytes

/** Kênh stream có khóa riêng (0.6.3 bước 7). */
enum class StreamChannel(
    val path: String,
) {
    CAMERA("camera"),
    CALL_AUDIO("call-audio"),
}

/** `K_stream` 96 byte = `k_auth`(32) ‖ `k_c2s`(32) ‖ `k_s2c`(32). */
class StreamKeys(
    val kAuth: ByteArray,
    val kC2s: ByteArray,
    val kS2c: ByteArray,
) {
    fun sendKey(role: PeerRole): ByteArray = if (role == PeerRole.CLIENT) kC2s else kS2c

    fun receiveKey(role: PeerRole): ByteArray = if (role == PeerRole.CLIENT) kS2c else kC2s
}

/**
 * `K_stream` = HKDF(`secret` epoch 0, salt rỗng, info "handlive/v1/stream/<kênh>/<session_id>", L = 96);
 * MAC hello = HMAC(k_auth, "HLSTREAM1|" ‖ session_id(16) ‖ nonce_c(32));
 * MAC welcome = HMAC(k_auth, "HLSTREAM1|welcome|" ‖ session_id(16) ‖ nonce_c(32) ‖ nonce_s(32)).
 */
object StreamKeyDerivation {
    const val LENGTH = 96
    private const val KEY_SIZE = 32
    private const val NONCE_SIZE = 32
    private val HELLO_LABEL = "HLSTREAM1|".toByteArray(Charsets.US_ASCII)
    private val WELCOME_LABEL = "HLSTREAM1|welcome|".toByteArray(Charsets.US_ASCII)

    fun info(
        channel: StreamChannel,
        sessionId: String,
    ): String {
        require(UuidBytes.isCanonical(sessionId)) { "session_id must be a lowercase uuid" }
        return "handlive/v1/stream/${channel.path}/$sessionId"
    }

    fun streamKeys(
        handshakeSecret: ByteArray,
        channel: StreamChannel,
        sessionId: String,
    ): StreamKeys {
        val okm = HkdfSha256.derive(ikm = handshakeSecret, info = info(channel, sessionId), length = LENGTH)
        return StreamKeys(
            okm.copyOfRange(0, KEY_SIZE),
            okm.copyOfRange(KEY_SIZE, 2 * KEY_SIZE),
            okm.copyOfRange(2 * KEY_SIZE, LENGTH),
        )
    }

    fun helloMessage(
        sessionId: String,
        nonceC: ByteArray,
    ): ByteArray {
        require(nonceC.size == NONCE_SIZE) { "nonce must be $NONCE_SIZE bytes" }
        return HELLO_LABEL + UuidBytes.toBytes(sessionId) + nonceC
    }

    fun welcomeMessage(
        sessionId: String,
        nonceC: ByteArray,
        nonceS: ByteArray,
    ): ByteArray {
        require(nonceC.size == NONCE_SIZE && nonceS.size == NONCE_SIZE) { "nonce must be $NONCE_SIZE bytes" }
        return WELCOME_LABEL + UuidBytes.toBytes(sessionId) + nonceC + nonceS
    }

    fun mac(
        kAuth: ByteArray,
        message: ByteArray,
    ): ByteArray = HmacSha256.mac(kAuth, message)

    fun verifyMac(
        kAuth: ByteArray,
        message: ByteArray,
        mac: ByteArray,
    ): Boolean = HmacSha256.verify(kAuth, message, mac)
}
