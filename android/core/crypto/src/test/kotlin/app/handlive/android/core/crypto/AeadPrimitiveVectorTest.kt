package app.handlive.android.core.crypto

import app.handlive.android.core.crypto.primitives.XChaCha20Poly1305Aead
import app.handlive.android.core.protocol.testing.Hex
import app.handlive.android.core.protocol.testing.SharedTestVectors
import app.handlive.android.core.protocol.testing.hex
import app.handlive.android.core.protocol.testing.str
import com.google.crypto.tink.aead.internal.InsecureNonceChaCha20Poly1305
import org.junit.Assert.assertArrayEquals
import org.junit.Assert.assertEquals
import org.junit.Assert.assertThrows
import org.junit.Test
import java.security.GeneralSecurityException

/** xchacha20-poly1305.json, hchacha20.json, chacha20-poly1305.json: vector dương khớp byte, vector âm bị từ chối. */
class AeadPrimitiveVectorTest {
    @Test
    fun xchacha20Poly1305Vectors() {
        val vectors = SharedTestVectors.vectors("xchacha20-poly1305.json")
        for (v in vectors) {
            val name = v.str("name")
            val sealed = XChaCha20Poly1305Aead.seal(v.hex("key"), v.hex("plaintext"), v.hex("aad"), v.hex("nonce"))
            assertArrayEquals(name, v.hex("nonce") + v.hex("ciphertext") + v.hex("tag"), sealed)
            assertArrayEquals(name, v.hex("plaintext"), XChaCha20Poly1305Aead.open(v.hex("key"), sealed, v.hex("aad")))
            // Cấu trúc phía Apple: HChaCha20(key, nonce[0:16]) + ChaCha20-Poly1305 nonce 00000000 ‖ nonce[16:24].
            val subkey = HChaCha20Reference.subkey(v.hex("key"), v.hex("nonce").copyOf(16))
            assertArrayEquals(name, v.hex("hchacha20_subkey"), subkey)
            val chachaNonce = ByteArray(4) + v.hex("nonce").copyOfRange(16, 24)
            assertArrayEquals(name, v.hex("chacha20_nonce"), chachaNonce)
            val viaChaCha = InsecureNonceChaCha20Poly1305(subkey).encrypt(chachaNonce, v.hex("plaintext"), v.hex("aad"))
            assertArrayEquals(name, v.hex("ciphertext") + v.hex("tag"), viaChaCha)
        }
        assertEquals(3, vectors.size)
    }

    @Test
    fun xchacha20Poly1305InvalidVectorsRejected() {
        val invalid = SharedTestVectors.invalidVectors("xchacha20-poly1305.json")
        for (v in invalid) {
            val sealed = v.hex("nonce") + v.hex("ciphertext") + v.hex("tag")
            assertThrows(v.str("name"), GeneralSecurityException::class.java) {
                XChaCha20Poly1305Aead.open(v.hex("key"), sealed, v.hex("aad"))
            }
        }
        assertEquals(4, invalid.size)
    }

    @Test
    fun hchacha20Vectors() {
        val vectors = SharedTestVectors.vectors("hchacha20.json")
        for (v in vectors) {
            assertEquals(
                v.str("name"),
                v.str("subkey"),
                Hex.encode(HChaCha20Reference.subkey(v.hex("key"), v.hex("nonce"))),
            )
        }
        assertEquals(3, vectors.size)
    }

    @Test
    fun chacha20Poly1305Vectors() {
        for (v in SharedTestVectors.vectors("chacha20-poly1305.json")) {
            val cipher = InsecureNonceChaCha20Poly1305(v.hex("key"))
            val sealed = cipher.encrypt(v.hex("nonce"), v.hex("plaintext"), v.hex("aad"))
            assertArrayEquals(v.str("name"), v.hex("ciphertext") + v.hex("tag"), sealed)
            assertArrayEquals(v.str("name"), v.hex("plaintext"), cipher.decrypt(v.hex("nonce"), sealed, v.hex("aad")))
        }
        val invalid = SharedTestVectors.invalidVectors("chacha20-poly1305.json")
        for (v in invalid) {
            assertThrows(v.str("name"), GeneralSecurityException::class.java) {
                InsecureNonceChaCha20Poly1305(
                    v.hex("key"),
                ).decrypt(v.hex("nonce"), v.hex("ciphertext") + v.hex("tag"), v.hex("aad"))
            }
        }
        assertEquals(4, invalid.size)
    }
}
