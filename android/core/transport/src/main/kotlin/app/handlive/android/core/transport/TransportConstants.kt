package app.handlive.android.core.transport

import kotlin.time.Duration
import kotlin.time.Duration.Companion.hours
import kotlin.time.Duration.Companion.seconds

/** Hằng số của kênh `/v1/ctl` (0.4.1, 0.6.3, 0.10). */
object TransportConstants {
    const val CTL_PATH = "/v1/ctl"

    /** `CTL_PORT` 47800; cổng bận thì thử lần lượt 47801–47809 (0.4.1). */
    const val CTL_PORT = 47800
    const val CTL_PORT_LAST_FALLBACK = 47809
    val CTL_PORTS: List<Int> = (CTL_PORT..CTL_PORT_LAST_FALLBACK).toList()

    val HANDSHAKE_TIMEOUT: Duration = 5.seconds
    val REQUEST_TIMEOUT: Duration = 10.seconds

    /** `REKEY_AFTER`: 24 h hoặc 10 000 envelope một chiều. */
    val REKEY_AFTER_AGE: Duration = 24.hours
    const val REKEY_AFTER_ENVELOPES = 10_000L

    /** Khóa nhận cũ giữ thêm 30 s sau rekey cho envelope đang bay (0.6.3 bước 6). */
    val OLD_KEY_GRACE: Duration = 30.seconds

    /** `nonce` và `eph` trong bắt tay và rekey: 32 byte. */
    const val NONCE_SIZE = 32
}

/** Mã đóng WebSocket (0.8.3). */
object WsCloseCode {
    const val NORMAL: Short = 1000
    const val BAD_REQUEST: Short = 4400
    const val AUTH_FAILED: Short = 4401
    const val PAIR_REVOKED: Short = 4403
    const val HANDSHAKE_TIMEOUT: Short = 4408
    const val REPLACED: Short = 4409
    const val UNSUPPORTED_VERSION: Short = 4426
    const val INTERNAL: Short = 4500
}
