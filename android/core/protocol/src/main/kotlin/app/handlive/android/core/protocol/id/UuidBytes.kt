package app.handlive.android.core.protocol.id

import app.handlive.android.core.protocol.ErrorCode
import app.handlive.android.core.protocol.protocolRequire
import java.nio.ByteBuffer
import java.util.UUID

/** Chuyển uuid dạng 36 ký tự chữ thường (0.3) ↔ 16 byte, dùng khi ghép byte thô cho MAC/KDF (0.6.3 bước 8). */
object UuidBytes {
    const val SIZE = 16
    private val CANONICAL = Regex("^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$")

    fun isCanonical(uuid: String): Boolean = CANONICAL.matches(uuid)

    /** Chỉ nhận dạng chuẩn tắc; `UUID.fromString` dễ dãi hơn nên phải kiểm regex trước. */
    fun toBytes(uuid: String): ByteArray {
        protocolRequire(isCanonical(uuid), ErrorCode.BAD_REQUEST, "invalid uuid")
        val value = UUID.fromString(uuid)
        return ByteBuffer
            .allocate(SIZE)
            .putLong(value.mostSignificantBits)
            .putLong(value.leastSignificantBits)
            .array()
    }

    /** `UUID.toString()` luôn cho dạng 36 ký tự chữ thường. */
    fun fromBytes(bytes: ByteArray): String {
        require(bytes.size == SIZE) { "uuid must be $SIZE bytes" }
        val buffer = ByteBuffer.wrap(bytes)
        return UUID(buffer.getLong(), buffer.getLong()).toString()
    }
}
