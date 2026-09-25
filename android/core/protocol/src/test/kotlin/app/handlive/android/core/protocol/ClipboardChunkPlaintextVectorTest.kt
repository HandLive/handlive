package app.handlive.android.core.protocol

import app.handlive.android.core.protocol.clipboard.ClipboardChunkPlaintext
import app.handlive.android.core.protocol.testing.SharedTestVectors
import app.handlive.android.core.protocol.testing.hex
import app.handlive.android.core.protocol.testing.int
import app.handlive.android.core.protocol.testing.str
import org.junit.Assert.assertArrayEquals
import org.junit.Assert.assertEquals
import org.junit.Assert.assertThrows
import org.junit.Test

/** Plaintext nhị phân `clipboard/chunk` (0.5.1 ngoại lệ 2) theo clipboard-chunk.json. */
class ClipboardChunkPlaintextVectorTest {
    @Test
    fun encodeAndDecodeMatchVectors() {
        val vectors = SharedTestVectors.vectors("clipboard-chunk.json")
        assertEquals(2, vectors.size)
        for (vector in vectors) {
            val name = vector.str("name")
            val plaintext =
                ClipboardChunkPlaintext(vector.str("transfer_id"), vector.int("index"), vector.hex("chunk_data"))
            val encoded = plaintext.encode()
            assertArrayEquals(name, vector.hex("plaintext_hex"), encoded)
            assertEquals(name, 0, encoded[0].toInt())
            assertEquals(name, vector.int("hdr_len"), vector.str("header_json").toByteArray().size)
            val decoded = ClipboardChunkPlaintext.decode(encoded)
            assertEquals(name, vector.str("transfer_id"), decoded.transferId)
            assertEquals(name, vector.int("index"), decoded.index)
            assertArrayEquals(name, vector.hex("chunk_data"), decoded.chunk)
        }
    }

    @Test
    fun truncatedOrForeignHeaderRejected() {
        val encoded = SharedTestVectors.vectors("clipboard-chunk.json").first().hex("plaintext_hex")
        assertThrows(ProtocolException::class.java) { ClipboardChunkPlaintext.decode(encoded.copyOf(10)) }
        val foreign =
            encoded
                .toString(
                    Charsets.ISO_8859_1,
                ).replace("\"chunk\"", "\"push!\"")
                .toByteArray(Charsets.ISO_8859_1)
        assertThrows(ProtocolException::class.java) { ClipboardChunkPlaintext.decode(foreign) }
    }
}
