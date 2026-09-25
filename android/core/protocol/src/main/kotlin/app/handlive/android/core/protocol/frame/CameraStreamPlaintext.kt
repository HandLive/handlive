package app.handlive.android.core.protocol.frame

import app.handlive.android.core.protocol.ErrorCode
import app.handlive.android.core.protocol.ProtocolException
import java.nio.ByteBuffer

/**
 * Plaintext của khung HL trên `/v1/stream/camera` (0.5.2):
 * `track`(1) ‖ `flags`(1) ‖ `pts_us` int64 BE ‖ dữ liệu.
 */
class CameraStreamPlaintext(
    val track: Int,
    val flags: Int,
    val ptsUs: Long,
    val data: ByteArray,
) {
    fun encode(): ByteArray =
        ByteBuffer
            .allocate(HEADER_SIZE + data.size)
            .put(track.toByte())
            .put(flags.toByte())
            .putLong(ptsUs)
            .put(data)
            .array()

    companion object {
        const val TRACK_VIDEO_H264 = 0x01
        const val TRACK_AUDIO_OPUS = 0x02
        const val FLAG_KEYFRAME = 0x01
        const val FLAG_CODEC_CONFIG = 0x02
        const val FLAG_DISCONTINUITY = 0x04
        const val HEADER_SIZE = 10
        private const val BYTE_MASK = 0xff

        fun decode(plaintext: ByteArray): CameraStreamPlaintext {
            if (plaintext.size < HEADER_SIZE) {
                throw ProtocolException(ErrorCode.BAD_REQUEST, "camera plaintext too short")
            }
            val buffer = ByteBuffer.wrap(plaintext)
            val track = buffer.get().toInt() and BYTE_MASK
            val flags = buffer.get().toInt() and BYTE_MASK
            val ptsUs = buffer.getLong()
            return CameraStreamPlaintext(track, flags, ptsUs, plaintext.copyOfRange(HEADER_SIZE, plaintext.size))
        }
    }
}
