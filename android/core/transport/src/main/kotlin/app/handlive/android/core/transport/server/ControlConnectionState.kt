package app.handlive.android.core.transport.server

/**
 * Trạng thái một kết nối `/v1/ctl` phía S (Android). Máy trạng thái 0.11 là của client (khám phá, backoff,
 * relay); S chỉ nhận kết nối nên chỉ có vòng đời bắt tay của từng kết nối:
 *
 * ```
 * AWAITING_HELLO --hello hợp lệ, gửi welcome + capability/hello--> AWAITING_CAPABILITY
 * AWAITING_CAPABILITY --nhận capability/hello giải mã được--> ESTABLISHED
 * mọi trạng thái --lỗi / quá HANDSHAKE_TIMEOUT / bye / bị thay (4409)--> CLOSED
 * ```
 */
enum class ControlConnectionState {
    AWAITING_HELLO,
    AWAITING_CAPABILITY,
    ESTABLISHED,
    CLOSED,
}
