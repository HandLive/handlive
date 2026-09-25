package app.handlive.android.core.transport.server

import java.util.concurrent.ConcurrentHashMap

/** Mỗi cặp chỉ có một phiên `/v1/ctl` tại một thời điểm (0.4.1); phiên mới bắt tay xong thay phiên cũ. */
class ActiveSessionRegistry {
    private val sessions = ConcurrentHashMap<String, ControlSession>()

    fun get(pairId: String): ControlSession? = sessions[pairId]

    fun all(): List<ControlSession> = sessions.values.toList()

    /** Đặt [session] làm phiên hiện tại của cặp; trả phiên cũ (nếu có) để đóng 4409. */
    internal fun replace(session: ControlSession): ControlSession? = sessions.put(session.pairId, session)

    /** Chỉ gỡ khi [session] vẫn là phiên hiện tại (phiên đã bị thay thì không xóa phiên mới). */
    internal fun remove(session: ControlSession) {
        sessions.remove(session.pairId, session)
    }
}
