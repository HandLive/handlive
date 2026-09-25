package app.handlive.android.core.transport.tls

import app.handlive.android.core.crypto.keystore.SecretStore
import org.junit.Assert.assertArrayEquals
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Rule
import org.junit.Test
import org.junit.rules.TemporaryFolder
import java.security.interfaces.ECPublicKey
import java.time.Instant
import java.time.ZoneOffset

/** Khóa TLS (0.4.1, 0.6.1): ECDSA P-256 tự ký 20 năm, PKCS#12 với mật khẩu nằm trong kho bí mật. */
class TlsIdentityTest {
    @get:Rule
    val folder = TemporaryFolder()

    @Test
    fun generatedCertificateIsSelfSignedEcdsaP256ValidForTwentyYears() {
        val now = Instant.now()
        val certificate = TlsIdentity.generate().certificate
        assertEquals("SHA256withECDSA", certificate.sigAlgName)
        assertEquals(3, certificate.version)
        val key = certificate.publicKey as ECPublicKey
        assertEquals(P256_FIELD_BITS, key.params.curve.field.fieldSize)
        certificate.verify(key)
        certificate.checkValidity()
        val expiresYear =
            certificate.notAfter
                .toInstant()
                .atOffset(ZoneOffset.UTC)
                .year
        assertEquals(now.atOffset(ZoneOffset.UTC).year + VALIDITY_YEARS, expiresYear)
        assertEquals(certificate.subjectX500Principal, certificate.issuerX500Principal)
    }

    @Test
    fun secretStoreStorageReloadsSameIdentityAndKeepsPasswordOutOfFile() {
        val secrets = MapSecretStore()
        val file = folder.root.resolve("tls.p12")
        val first = TlsIdentityProvider.loadOrCreate(SecretStoreTlsIdentityStorage(secrets, file))
        val second = TlsIdentityProvider.loadOrCreate(SecretStoreTlsIdentityStorage(secrets, file))
        assertArrayEquals(first.certificateSha256(), second.certificateSha256())

        val password = checkNotNull(secrets.get(SecretStoreTlsIdentityStorage.PASSWORD_SECRET))
        assertFalse(String(file.readBytes(), Charsets.ISO_8859_1).contains(String(password, Charsets.UTF_8)))
    }

    @Test
    fun lostPasswordRegeneratesIdentity() {
        val secrets = MapSecretStore()
        val file = folder.root.resolve("tls.p12")
        val first = TlsIdentityProvider.loadOrCreate(SecretStoreTlsIdentityStorage(secrets, file))
        secrets.put(SecretStoreTlsIdentityStorage.PASSWORD_SECRET, "wrong".toByteArray())
        val second = TlsIdentityProvider.loadOrCreate(SecretStoreTlsIdentityStorage(secrets, file))
        assertFalse(first.certificateSha256().contentEquals(second.certificateSha256()))
    }

    @Test
    fun inMemoryStorageKeepsIdentityForProcessLifetime() {
        val storage = InMemoryTlsIdentityStorage()
        val first = TlsIdentityProvider.loadOrCreate(storage)
        assertTrue(
            first.certificateSha256().contentEquals(TlsIdentityProvider.loadOrCreate(storage).certificateSha256()),
        )
    }

    /** Kho bí mật trong bộ nhớ; bản Android là `AndroidKeystoreSecretStore` (khóa `hl_master`). */
    private class MapSecretStore : SecretStore {
        private val values = HashMap<String, ByteArray>()

        override fun put(
            name: String,
            secret: ByteArray,
        ) {
            values[name] = secret.copyOf()
        }

        override fun get(name: String): ByteArray? = values[name]?.copyOf()

        override fun delete(name: String) {
            values.remove(name)
        }
    }

    private companion object {
        const val P256_FIELD_BITS = 256
        const val VALIDITY_YEARS = 20
    }
}
