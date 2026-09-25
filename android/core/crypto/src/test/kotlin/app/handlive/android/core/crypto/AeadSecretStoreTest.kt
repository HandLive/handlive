package app.handlive.android.core.crypto

import app.handlive.android.core.crypto.keystore.AeadSecretStore
import app.handlive.android.core.crypto.keystore.SecretBlobBackend
import com.google.crypto.tink.Aead
import com.google.crypto.tink.KeysetHandle
import com.google.crypto.tink.RegistryConfiguration
import com.google.crypto.tink.aead.AeadConfig
import com.google.crypto.tink.aead.PredefinedAeadParameters
import org.junit.Assert.assertArrayEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNull
import org.junit.Assert.assertThrows
import org.junit.Test
import java.security.GeneralSecurityException

/** Phần thuần JVM của kho bí mật: keyset Tink trong bộ nhớ thay cho keyset bọc bởi `hl_master`. */
class AeadSecretStoreTest {
    private class MemoryBackend : SecretBlobBackend {
        val blobs = mutableMapOf<String, ByteArray>()

        override fun read(name: String) = blobs[name]

        override fun write(
            name: String,
            blob: ByteArray,
        ) {
            blobs[name] = blob
        }

        override fun remove(name: String) {
            blobs.remove(name)
        }
    }

    private val backend = MemoryBackend()
    private val store = AeadSecretStore(newAead(), backend)
    private val secret = ByteArray(32) { it.toByte() }

    private fun newAead(): Aead {
        AeadConfig.register()
        return KeysetHandle
            .generateNew(PredefinedAeadParameters.AES256_GCM)
            .getPrimitive(RegistryConfiguration.get(), Aead::class.java)
    }

    @Test
    fun storesOnlyCiphertextAndRoundTrips() {
        store.put("ik_sig", secret)
        assertFalse(
            backend.blobs
                .getValue("ik_sig")
                .toList()
                .windowed(secret.size)
                .any { it == secret.toList() },
        )
        assertArrayEquals(secret, store.get("ik_sig"))
        store.delete("ik_sig")
        assertNull(store.get("ik_sig"))
    }

    @Test
    fun tamperedOrSwappedBlobRejected() {
        store.put("ik_sig", secret)
        store.put("ik_dh", secret.reversedArray())
        backend.blobs["ik_dh"] = backend.blobs.getValue("ik_sig")
        assertThrows(GeneralSecurityException::class.java) { store.get("ik_dh") }
        val tampered =
            backend.blobs
                .getValue(
                    "ik_sig",
                ).copyOf()
                .also { it[it.size - 1] = (it[it.size - 1] + 1).toByte() }
        backend.blobs["ik_sig"] = tampered
        assertThrows(GeneralSecurityException::class.java) { store.get("ik_sig") }
        assertThrows(GeneralSecurityException::class.java) { AeadSecretStore(newAead(), backend).get("ik_dh") }
    }
}
