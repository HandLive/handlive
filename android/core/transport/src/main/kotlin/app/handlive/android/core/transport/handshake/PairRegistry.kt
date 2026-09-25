package app.handlive.android.core.transport.handshake

/**
 * Cặp ghép nối phía Android, đủ cho bắt tay (CONN-01 bước 7: `SELECT pair_id, peer_device_id, prk_enc, revoked_at`).
 * [prk] đã giải mã khỏi `prk_enc`.
 */
class PairRecord(
    val pairId: String,
    val peerDeviceId: String,
    val prk: ByteArray,
    val revoked: Boolean,
)

/** Tra cặp theo `pair_id`; bản thật đọc Room `paired_device` (Phase 1). */
fun interface PairRegistry {
    fun find(pairId: String): PairRecord?
}
