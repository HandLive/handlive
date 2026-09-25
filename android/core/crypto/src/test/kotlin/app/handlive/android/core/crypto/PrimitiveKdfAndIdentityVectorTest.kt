package app.handlive.android.core.crypto

import app.handlive.android.core.crypto.derivation.DeviceIdDerivation
import app.handlive.android.core.crypto.primitives.Ed25519Keys
import app.handlive.android.core.crypto.primitives.HkdfSha256
import app.handlive.android.core.crypto.primitives.X25519Keys
import app.handlive.android.core.protocol.testing.Hex
import app.handlive.android.core.protocol.testing.SharedTestVectors
import app.handlive.android.core.protocol.testing.hex
import app.handlive.android.core.protocol.testing.int
import app.handlive.android.core.protocol.testing.str
import org.junit.Assert.assertArrayEquals
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test
import java.security.MessageDigest

/** x25519.json, hkdf-sha256.json, device-id.json và chữ ký Ed25519. */
class PrimitiveKdfAndIdentityVectorTest {
    private val basePoint = "09" + "00".repeat(31)

    @Test
    fun x25519Vectors() {
        val vectors = SharedTestVectors.vectors("x25519.json")
        for (v in vectors) {
            val output =
                if (v.str("u") == basePoint) {
                    X25519Keys.publicFromPrivate(v.hex("scalar"))
                } else {
                    X25519Keys.sharedSecret(v.hex("scalar"), v.hex("u"))
                }
            assertEquals(v.str("name"), v.str("output"), Hex.encode(output))
        }
        assertEquals(6, vectors.size)
    }

    @Test
    fun hkdfVectors() {
        val vectors = SharedTestVectors.vectors("hkdf-sha256.json")
        for (v in vectors) {
            val prk = HkdfSha256.extract(v.hex("salt"), v.hex("ikm"))
            assertEquals(v.str("name"), v.str("prk"), Hex.encode(prk))
            assertEquals(
                v.str("name"),
                v.str("okm"),
                Hex.encode(HkdfSha256.expand(prk, v.hex("info"), v.int("length"))),
            )
        }
        assertEquals(3, vectors.size)
    }

    @Test
    fun deviceIdFromSigningKeyVectors() {
        val vectors = SharedTestVectors.vectors("device-id.json")
        for (v in vectors) {
            val name = v.str("name")
            val publicKey = Ed25519Keys.publicFromSeed(v.hex("ik_sig_seed"))
            assertArrayEquals(name, v.hex("ik_sig_pub"), publicKey)
            assertArrayEquals(name, v.hex("sha256"), MessageDigest.getInstance("SHA-256").digest(publicKey))
            assertArrayEquals(name, v.hex("device_id_bytes"), DeviceIdDerivation.deviceIdBytes(publicKey))
            assertEquals(name, v.str("device_id"), DeviceIdDerivation.deviceId(publicKey))
            assertTrue(name, DeviceIdDerivation.matches(v.str("device_id"), publicKey))
        }
        assertEquals(3, vectors.size)
        assertFalse(DeviceIdDerivation.matches(vectors[0].str("device_id"), vectors[1].hex("ik_sig_pub")))
    }

    @Test
    fun ed25519SignatureMatchesRfc8032Test1AndVerifies() {
        val seed = SharedTestVectors.vectors("device-id.json")[0].hex("ik_sig_seed")
        val signature = Ed25519Keys.sign(seed, ByteArray(0))
        assertEquals(RFC8032_TEST1_SIGNATURE, Hex.encode(signature))
        val publicKey = Ed25519Keys.publicFromSeed(seed)
        assertTrue(Ed25519Keys.verify(publicKey, ByteArray(0), signature))
        assertFalse(Ed25519Keys.verify(publicKey, byteArrayOf(1), signature))
    }

    private companion object {
        /** RFC 8032 §7.1 TEST 1: chữ ký của thông điệp rỗng với seed 9d61b19d… */
        const val RFC8032_TEST1_SIGNATURE =
            "e5564300c360ac729086e2cc806e828a84877f1eb8e5d974d873e06522490155" +
                "5fb8821590a33bacc61e39701cf9b46bd25bf5f0595bbe24655141438e7a100b"
    }
}
