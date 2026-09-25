package app.handlive.android.core.protocol

import app.handlive.android.core.protocol.frame.CameraStreamPlaintext
import app.handlive.android.core.protocol.frame.HlFrame
import app.handlive.android.core.protocol.testing.SharedTestVectors
import app.handlive.android.core.protocol.testing.hex
import app.handlive.android.core.protocol.testing.int
import app.handlive.android.core.protocol.testing.long
import app.handlive.android.core.protocol.testing.str
import org.junit.Assert.assertArrayEquals
import org.junit.Assert.assertEquals
import org.junit.Assert.assertThrows
import org.junit.Test

/** Bố cục khung HL (0.5.2) theo hl-frame.json; phần mã hóa kiểm ở core:crypto. */
class HlFrameVectorTest {
    private val vectors = SharedTestVectors.vectors("hl-frame.json")

    @Test
    fun headerAndFrameLayoutMatchVectors() {
        for (vector in vectors) {
            val name = vector.str("name")
            val seq = vector.long("seq").toUInt()
            val ts = vector.long("ts").toUInt()
            assertArrayEquals(name, vector.hex("header"), HlFrame.header(seq, ts))
            val encrypted = vector.hex("encrypted_part")
            assertArrayEquals(name, vector.hex("nonce") + vector.hex("ciphertext") + vector.hex("tag"), encrypted)
            assertArrayEquals(name, vector.hex("frame"), HlFrame(seq, ts, encrypted).encode())
            val decoded = HlFrame.decode(vector.hex("frame"))
            assertEquals(name, seq, decoded.seq)
            assertEquals(name, ts, decoded.ts)
            assertArrayEquals(name, encrypted, decoded.encrypted)
        }
        assertEquals(4, vectors.size)
    }

    @Test
    fun cameraPlaintextMatchesVectors() {
        val camera = vectors.filter { it.str("channel") == "camera" }
        assertEquals(2, camera.size)
        for (vector in camera) {
            val plaintext =
                CameraStreamPlaintext(
                    vector.int("track"),
                    vector.int("flags"),
                    vector.long("pts_us"),
                    vector.hex("data"),
                )
            assertArrayEquals(vector.str("name"), vector.hex("plaintext"), plaintext.encode())
            val decoded = CameraStreamPlaintext.decode(vector.hex("plaintext"))
            assertEquals(vector.int("track"), decoded.track)
            assertEquals(vector.int("flags"), decoded.flags)
            assertEquals(vector.long("pts_us"), decoded.ptsUs)
            assertArrayEquals(vector.hex("data"), decoded.data)
        }
    }

    @Test
    fun malformedFramesRejected() {
        val frame = vectors.first().hex("frame")
        val badMagic = frame.copyOf().also { it[0] = 0x00 }
        val badVersion = frame.copyOf().also { it[2] = 0x02 }
        assertEquals(
            ErrorCode.BAD_REQUEST,
            assertThrows(ProtocolException::class.java) { HlFrame.decode(badMagic) }.code,
        )
        assertEquals(
            ErrorCode.UNSUPPORTED_VERSION,
            assertThrows(ProtocolException::class.java) { HlFrame.decode(badVersion) }.code,
        )
        val short = frame.copyOf(HlFrame.HEADER_SIZE + HlFrame.MIN_ENCRYPTED_SIZE - 1)
        assertEquals(ErrorCode.BAD_REQUEST, assertThrows(ProtocolException::class.java) { HlFrame.decode(short) }.code)
    }
}
