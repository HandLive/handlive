package app.handlive.android.core.crypto.derivation

/** Vai trong kết nối thiết bị–thiết bị (0.1): máy khách C = Mac/iOS, máy chủ S = Android. */
enum class PeerRole { CLIENT, SERVER }

/**
 * Khóa phiên `/v1/ctl`: `secret` 64 byte chia `k_c2s` ‖ `k_s2c`; `secret` còn là đầu vào của rekey kế tiếp
 * và (ở epoch 0) của `K_stream`.
 */
class SessionKeys(
    val secret: ByteArray,
) {
    init {
        require(secret.size == SECRET_SIZE) { "session secret must be $SECRET_SIZE bytes" }
    }

    val kC2s: ByteArray get() = secret.copyOfRange(0, KEY_SIZE)
    val kS2c: ByteArray get() = secret.copyOfRange(KEY_SIZE, SECRET_SIZE)

    fun sendKey(role: PeerRole): ByteArray = if (role == PeerRole.CLIENT) kC2s else kS2c

    fun receiveKey(role: PeerRole): ByteArray = if (role == PeerRole.CLIENT) kS2c else kC2s

    companion object {
        const val KEY_SIZE = 32
        const val SECRET_SIZE = 64
    }
}
