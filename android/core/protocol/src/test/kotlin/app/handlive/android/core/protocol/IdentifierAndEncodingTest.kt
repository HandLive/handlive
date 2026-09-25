package app.handlive.android.core.protocol

import app.handlive.android.core.protocol.encoding.Base64Codecs
import app.handlive.android.core.protocol.envelope.EnvelopeCodec
import app.handlive.android.core.protocol.id.UuidBytes
import app.handlive.android.core.protocol.id.UuidV7Generator
import org.junit.Assert.assertArrayEquals
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNotEquals
import org.junit.Assert.assertThrows
import org.junit.Assert.assertTrue
import org.junit.Test

/** UUIDv7 (0.2), uuid ↔ 16 byte, b64/b64u chuẩn tắc (0.3). */
class IdentifierAndEncodingTest {
    @Test
    fun uuidV7CarriesTimestampVersionAndVariant() {
        val millis = 0x0192f3e81b2cL
        val generator = UuidV7Generator(clock = { millis })
        val first = generator.next()
        val second = generator.next()
        assertTrue(first, EnvelopeCodec.isUuidV7(first))
        assertTrue(first.startsWith("0192f3e8-1b2c-7"))
        assertNotEquals(first, second)
    }

    @Test
    fun uuidBytesRoundTrip() {
        val uuid = "0192f3e8-1b2c-7d3f-8a01-5a6b7c8d9e10"
        val bytes = UuidBytes.toBytes(uuid)
        assertEquals(16, bytes.size)
        assertEquals(uuid, UuidBytes.fromBytes(bytes))
        assertThrows(ProtocolException::class.java) { UuidBytes.toBytes(uuid.uppercase()) }
        assertThrows(ProtocolException::class.java) { UuidBytes.toBytes(uuid.replace("-", "")) }
    }

    @Test
    fun base64VariantsAreStrict() {
        val bytes = byteArrayOf(-5, -1, 0x10)
        assertEquals("+/8Q", Base64Codecs.encodeB64(bytes))
        assertEquals("-_8Q", Base64Codecs.encodeB64u(bytes))
        assertArrayEquals(bytes, Base64Codecs.decodeB64("+/8Q"))
        assertArrayEquals(bytes, Base64Codecs.decodeB64u("-_8Q"))
        assertArrayEquals(byteArrayOf(1), Base64Codecs.decodeB64("AQ=="))
        assertThrows(ProtocolException::class.java) { Base64Codecs.decodeB64("AQ") }
        assertThrows(ProtocolException::class.java) { Base64Codecs.decodeB64("AR==") }
        assertThrows(ProtocolException::class.java) { Base64Codecs.decodeB64u("AQ==") }
        assertThrows(ProtocolException::class.java) { Base64Codecs.decodeB64u("+/8Q") }
        assertThrows(ProtocolException::class.java) { Base64Codecs.decodeB64u("-_8Q", 32) }
    }
}
