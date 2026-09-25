package app.handlive.android.core.transport.session

import app.handlive.android.core.crypto.derivation.SessionKeys
import app.handlive.android.core.crypto.derivation.SessionRekeyDerivation
import app.handlive.android.core.crypto.primitives.SecureRandomBytes
import app.handlive.android.core.crypto.primitives.X25519Keys
import app.handlive.android.core.protocol.ProtocolException
import app.handlive.android.core.protocol.encoding.Base64Codecs
import app.handlive.android.core.protocol.id.UuidBytes
import app.handlive.android.core.protocol.session.SessionRekeyData
import app.handlive.android.core.transport.TransportConstants.NONCE_SIZE
import java.security.GeneralSecurityException

/** Phản ứng với `session/rekey` của đối phương. */
sealed interface RekeyRequestResult {
    /** Gửi `ack` chứa [ackData] bằng khóa hiện tại, xong mới `install(newKeys, epoch)` (0.6.3 bước 6). */
    class Respond(
        val ackData: SessionRekeyData,
        val newKeys: SessionKeys,
        val epoch: Int,
    ) : RekeyRequestResult

    /** Hai bên cùng khởi tạo và bên mình thắng: bỏ qua, chờ đối phương `ack` yêu cầu của mình (CONN-02 API 3). */
    data object IgnoreCollision : RekeyRequestResult

    /** `epoch` hoặc khóa tạm không hợp lệ → `ack` lỗi `BAD_REQUEST`. */
    data object Invalid : RekeyRequestResult
}

/**
 * Rekey (0.6.3 bước 6, 8; CONN-02 API 3) cho cả hai vai: bên khởi tạo gửi `{epoch, eph, nonce}`, bên nhận trả
 * `ack` chứa `{epoch, eph, nonce}` của mình. shared = X25519(eph khởi tạo, eph nhận); salt = SHA-256(nonce khởi tạo
 * ‖ nonce nhận); khóa mới chia theo vai C/S. Không an toàn đa luồng: dùng cùng khóa tuần tự với [cipher].
 */
class SessionRekeyCoordinator(
    private val localDeviceId: String,
    private val peerDeviceId: String,
    private val cipher: SessionCipher,
    private val ephemeralPrivateKey: () -> ByteArray = X25519Keys::generatePrivateKey,
    private val nonce: () -> ByteArray = { SecureRandomBytes.next(NONCE_SIZE) },
) {
    private class Pending(
        val requestId: String,
        val epoch: Int,
        val ephPrivate: ByteArray,
        val nonce: ByteArray,
    )

    private var pending: Pending? = null

    /** `id` của envelope `session/rekey` mình đã gửi và đang chờ `ack`, nếu có. */
    val pendingRequestId: String? get() = pending?.requestId

    /** Bắt đầu rekey; bên gọi gửi `data` trong envelope có `id` = [requestId]. */
    fun start(requestId: String): SessionRekeyData {
        check(pending == null) { "rekey already in progress" }
        val ephPrivate = ephemeralPrivateKey()
        val ownNonce = nonce()
        val epoch = cipher.epoch + 1
        pending = Pending(requestId, epoch, ephPrivate, ownNonce)
        return data(epoch, ephPrivate, ownNonce)
    }

    fun onRequest(request: SessionRekeyData): RekeyRequestResult {
        if (pending != null && localWinsCollision()) return RekeyRequestResult.IgnoreCollision
        pending = null
        val ephPrivate = ephemeralPrivateKey()
        val ownNonce = nonce()
        val newKeys =
            request
                .takeIf { it.epoch == cipher.epoch + 1 }
                ?.let { deriveOrNull(ephPrivate, it) { peerNonce -> peerNonce to ownNonce } }
        return newKeys?.let { RekeyRequestResult.Respond(data(request.epoch, ephPrivate, ownNonce), it, request.epoch) }
            ?: RekeyRequestResult.Invalid
    }

    /**
     * `ack` thành công cho yêu cầu [re]: đổi khóa ngay. Trả `false` khi không khớp yêu cầu đang chờ hoặc dữ liệu sai
     * (bên gọi đóng phiên — CONN-02 E4).
     */
    fun onAck(
        re: String,
        response: SessionRekeyData,
    ): Boolean {
        val request = pending?.takeIf { it.requestId == re } ?: return false
        pending = null
        val newKeys =
            response
                .takeIf { it.epoch == request.epoch }
                ?.let { deriveOrNull(request.ephPrivate, it) { peerNonce -> request.nonce to peerNonce } }
        newKeys?.let { cipher.install(it, request.epoch) }
        return newKeys != null
    }

    /** [orderNonces] nhận `nonce` của đối phương, trả (nonce bên khởi tạo, nonce bên nhận). Dữ liệu sai → `null`. */
    private fun deriveOrNull(
        ownEphPrivate: ByteArray,
        peer: SessionRekeyData,
        orderNonces: (ByteArray) -> Pair<ByteArray, ByteArray>,
    ): SessionKeys? =
        try {
            val peerEph = Base64Codecs.decodeB64u(peer.eph, X25519Keys.KEY_SIZE)
            val (initiatorNonce, responderNonce) = orderNonces(Base64Codecs.decodeB64u(peer.nonce, NONCE_SIZE))
            SessionRekeyDerivation.rekey(cipher.keys, ownEphPrivate, peerEph, initiatorNonce, responderNonce)
        } catch (_: ProtocolException) {
            null
        } catch (_: GeneralSecurityException) {
            // Khóa tạm của đối phương là điểm bậc thấp.
            null
        }

    /** Bên có `device_id` nhỏ hơn (16 byte, không dấu) thắng khi hai bên cùng khởi tạo. */
    private fun localWinsCollision(): Boolean =
        compareUnsigned(UuidBytes.toBytes(localDeviceId), UuidBytes.toBytes(peerDeviceId)) < 0

    private fun compareUnsigned(
        a: ByteArray,
        b: ByteArray,
    ): Int = a.indices.firstOrNull { a[it] != b[it] }?.let { a[it].toUByte().compareTo(b[it].toUByte()) } ?: 0

    private fun data(
        epoch: Int,
        ephPrivate: ByteArray,
        ownNonce: ByteArray,
    ) = SessionRekeyData(
        epoch = epoch,
        eph = Base64Codecs.encodeB64u(X25519Keys.publicFromPrivate(ephPrivate)),
        nonce = Base64Codecs.encodeB64u(ownNonce),
    )
}
