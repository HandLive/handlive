package app.handlive.android.core.crypto

import app.handlive.android.core.crypto.message.EnvelopeCipher
import app.handlive.android.core.protocol.encoding.Base64Codecs
import app.handlive.android.core.protocol.envelope.EnvelopeCodec
import app.handlive.android.core.protocol.testing.SharedTestVectors
import app.handlive.android.core.protocol.testing.hex
import app.handlive.android.core.protocol.testing.str
import kotlinx.serialization.ExperimentalSerializationApi
import kotlinx.serialization.json.Json
import kotlinx.serialization.json.JsonObject
import org.junit.Assert.assertArrayEquals
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Assume.assumeTrue
import org.junit.Test
import java.io.File

/**
 * Liên nền tảng (Phase 0 "Kiểm thử"): Android ghi envelope-roundtrip.json khi chạy với `HL_WRITE_ROUNDTRIP=1`
 * (test thường không ghi để khỏi làm bẩn cây), rồi luôn giải mã lại file đó; nếu có envelope-roundtrip-apple.json
 * (agent Apple ghi) thì giải mã và kiểm plaintext.
 */
class EnvelopeRoundtripTest {
    @OptIn(ExperimentalSerializationApi::class)
    private val prettyJson =
        Json {
            prettyPrint = true
            prettyPrintIndent = "  "
        }

    @Test
    fun androidRoundtripFile() {
        val file = File(SharedTestVectors.vectorsDir, ANDROID_FILE)
        if (System.getenv("HL_WRITE_ROUNDTRIP") == "1") {
            file.writeText(prettyJson.encodeToString(JsonObject.serializer(), EnvelopeRoundtripFixture.build()) + "\n")
        }
        assumeTrue("$ANDROID_FILE chưa có — chạy HL_WRITE_ROUNDTRIP=1 để sinh", file.exists())
        verifyFile(ANDROID_FILE)
    }

    @Test
    fun appleRoundtripFile() {
        assumeTrue(
            "$APPLE_FILE chưa có (agent Apple chưa ghi)",
            File(SharedTestVectors.vectorsDir, APPLE_FILE).exists(),
        )
        verifyFile(APPLE_FILE)
    }

    private fun verifyFile(name: String) {
        val vectors = SharedTestVectors.vectors(name)
        assertTrue("$name: cần ≥ 2 vector", vectors.size >= 2)
        for (v in vectors) {
            val label = "$name / ${v.str("name")}"
            val envelope = EnvelopeCodec.decode(v.str("envelope"))
            assertEquals(label, v.str("type"), envelope.type)
            assertEquals(label, v.str("aad"), envelope.aad().decodeToString())
            assertArrayEquals(
                label,
                v.hex("nonce") + v.hex("ciphertext") + v.hex("tag"),
                Base64Codecs.decodeB64(envelope.payload),
            )
            val plaintext = EnvelopeCipher.open(v.hex("key"), envelope)
            assertEquals(label, v.str("plaintext"), plaintext.decodeToString())
        }
    }

    companion object {
        const val ANDROID_FILE = "envelope-roundtrip.json"
        const val APPLE_FILE = "envelope-roundtrip-apple.json"
    }
}
