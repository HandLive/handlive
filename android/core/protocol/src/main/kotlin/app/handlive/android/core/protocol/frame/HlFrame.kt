package app.handlive.android.core.protocol.frame

import app.handlive.android.core.protocol.ErrorCode
import app.handlive.android.core.protocol.protocolRequire
import java.nio.ByteBuffer

/**
 * Khung nhị phân HL trên các kênh `/v1/stream/<kênh>` (0.5.2):
 * `magic 0x48 0x4C` ‖ `ver 0x01` ‖ `seq` uint32 BE ‖ `ts` uint32 BE ‖ `encrypted` (nonce ‖ ciphertext ‖ tag).
 * 11 byte đầu ([header]) là AAD của phần mã hóa.
 */
class HlFrame(
    val seq: UInt,
    val ts: UInt,
    val encrypted: ByteArray,
) {
    val header: ByteArray get() = header(seq, ts)

    fun encode(): ByteArray = header + encrypted

    companion object {
        const val MAGIC_0: Byte = 0x48
        const val MAGIC_1: Byte = 0x4C
        const val VERSION: Byte = 0x01
        const val HEADER_SIZE = 11

        /** nonce(24) + tag(16): phần mã hóa ngắn hơn thì chắc chắn không hợp lệ. */
        const val MIN_ENCRYPTED_SIZE = 40

        fun header(
            seq: UInt,
            ts: UInt,
        ): ByteArray =
            ByteBuffer
                .allocate(HEADER_SIZE)
                .put(MAGIC_0)
                .put(MAGIC_1)
                .put(VERSION)
                .putInt(seq.toInt())
                .putInt(ts.toInt())
                .array()

        fun decode(frame: ByteArray): HlFrame {
            protocolRequire(frame.size >= HEADER_SIZE + MIN_ENCRYPTED_SIZE, ErrorCode.BAD_REQUEST, "HL frame too short")
            val buffer = ByteBuffer.wrap(frame)
            val magicOk = buffer.get() == MAGIC_0 && buffer.get() == MAGIC_1
            protocolRequire(magicOk, ErrorCode.BAD_REQUEST, "bad HL magic")
            protocolRequire(buffer.get() == VERSION, ErrorCode.UNSUPPORTED_VERSION, "unsupported HL frame version")
            val seq = buffer.getInt().toUInt()
            val ts = buffer.getInt().toUInt()
            return HlFrame(seq, ts, frame.copyOfRange(HEADER_SIZE, frame.size))
        }
    }
}
