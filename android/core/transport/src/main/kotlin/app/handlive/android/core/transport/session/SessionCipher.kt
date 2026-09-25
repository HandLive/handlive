package app.handlive.android.core.transport.session

import app.handlive.android.core.crypto.derivation.PeerRole
import app.handlive.android.core.crypto.derivation.SessionKeys
import app.handlive.android.core.crypto.message.EnvelopeCipher
import app.handlive.android.core.protocol.ProtocolException
import app.handlive.android.core.protocol.envelope.Envelope
import app.handlive.android.core.protocol.envelope.EnvelopeHeader
import app.handlive.android.core.transport.TransportConstants
import kotlin.time.Duration

/**
 * Trạng thái khóa của một phiên `/v1/ctl` theo vai [role]: khóa gửi/nhận theo chiều (0.6.3 bước 3–4),
 * thế hệ khóa `epoch`, bộ đếm envelope mỗi chiều và tuổi khóa cho ngưỡng `REKEY_AFTER`. Sau rekey, khóa nhận cũ
 * còn dùng được trong `OLD_KEY_GRACE` cho envelope đang bay. Không an toàn đa luồng: bên gọi tự tuần tự hóa.
 */
class SessionCipher(
    initialKeys: SessionKeys,
    val role: PeerRole,
    private val clock: () -> Long = System::currentTimeMillis,
    private val rekeyAfterEnvelopes: Long = TransportConstants.REKEY_AFTER_ENVELOPES,
    private val rekeyAfterAge: Duration = TransportConstants.REKEY_AFTER_AGE,
    private val oldKeyGrace: Duration = TransportConstants.OLD_KEY_GRACE,
) {
    var keys: SessionKeys = initialKeys
        private set

    /** Thế hệ khóa hiện tại: 0 sau bắt tay, tăng 1 mỗi lần rekey. */
    var epoch: Int = 0
        private set

    var sentCount: Long = 0
        private set

    var receivedCount: Long = 0
        private set

    private var keysSince: Long = clock()
    private var previousReceiveKey: ByteArray? = null
    private var previousKeyExpiresAt: Long = 0

    /** Mã hóa bằng khóa gửi hiện tại. */
    fun seal(
        header: EnvelopeHeader,
        plaintext: ByteArray,
    ): Envelope = EnvelopeCipher.seal(keys.sendKey(role), header, plaintext).also { sentCount++ }

    /** Giải mã bằng khóa nhận hiện tại, rồi khóa cũ nếu còn hạn; không được → `DECRYPT_FAILED`. */
    fun open(envelope: Envelope): ByteArray {
        val plaintext =
            try {
                EnvelopeCipher.open(keys.receiveKey(role), envelope)
            } catch (e: ProtocolException) {
                val previous = previousReceiveKey?.takeIf { clock() < previousKeyExpiresAt } ?: throw e
                EnvelopeCipher.open(previous, envelope)
            }
        receivedCount++
        return plaintext
    }

    /** Đạt ngưỡng 24 h hoặc 10 000 envelope ở một chiều (0.6.3 bước 6). */
    fun rekeyDue(): Boolean =
        sentCount >= rekeyAfterEnvelopes ||
            receivedCount >= rekeyAfterEnvelopes ||
            clock() - keysSince >= rekeyAfterAge.inWholeMilliseconds

    /** Chuyển sang khóa của [newEpoch]; giữ khóa nhận cũ thêm `OLD_KEY_GRACE`, đếm lại từ 0. */
    fun install(
        newKeys: SessionKeys,
        newEpoch: Int,
    ) {
        previousReceiveKey = keys.receiveKey(role)
        previousKeyExpiresAt = clock() + oldKeyGrace.inWholeMilliseconds
        keys = newKeys
        epoch = newEpoch
        sentCount = 0
        receivedCount = 0
        keysSince = clock()
    }
}
