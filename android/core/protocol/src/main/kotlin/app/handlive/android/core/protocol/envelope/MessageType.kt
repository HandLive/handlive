package app.handlive.android.core.protocol.envelope

/** Giá trị `type` của envelope (0.7.1): tập đã chốt cộng `session`, `camera`. */
enum class MessageType(
    val wire: String,
) {
    CLIPBOARD("clipboard"),
    SMS("sms"),
    CALL_EVENT("call_event"),
    CALL_AUDIO("call_audio"),
    PAIR("pair"),
    ACK("ack"),
    PING("ping"),
    CAPABILITY("capability"),
    SESSION("session"),
    CAMERA("camera"),
    ;

    companion object {
        /** `type` lạ từ đối phương → `null` để tầng trên trả `UNSUPPORTED_TYPE` (0.5.1 quy tắc 3). */
        fun fromWire(wire: String): MessageType? = entries.firstOrNull { it.wire == wire }
    }
}
