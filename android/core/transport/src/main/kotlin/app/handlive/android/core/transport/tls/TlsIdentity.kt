package app.handlive.android.core.transport.tls

import app.handlive.android.core.crypto.primitives.SecureRandomBytes
import app.handlive.android.core.protocol.encoding.Base64Codecs
import java.io.ByteArrayOutputStream
import java.security.KeyStore
import java.security.MessageDigest
import java.security.cert.X509Certificate

/**
 * Khóa TLS của A-SVC (0.6.1): ECDSA P-256 + chứng chỉ tự ký, lưu dạng PKCS#12. [keyStore] đưa thẳng cho
 * `sslConnector` của Ktor; [certificateSha256] là giá trị client ghim (`tls_sha256`, trao lúc ghép nối).
 */
class TlsIdentity(
    val keyStore: KeyStore,
    private val password: CharArray,
) {
    /** Bản sao mới mỗi lần: Ktor xóa trắng mảng mật khẩu sau khi dùng. */
    fun password(): CharArray = password.copyOf()

    val certificate: X509Certificate get() = keyStore.getCertificate(ALIAS) as X509Certificate

    /** SHA-256 trên DER của chứng chỉ (0.4.1: client ghim giá trị này, không kiểm hostname). */
    fun certificateSha256(): ByteArray = MessageDigest.getInstance("SHA-256").digest(certificate.encoded)

    fun toPkcs12(): ByteArray = ByteArrayOutputStream().also { keyStore.store(it, password) }.toByteArray()

    companion object {
        const val ALIAS = "handlive-tls"
        private const val KEYSTORE_TYPE = "PKCS12"
        private const val PASSWORD_BYTES = 32

        /** Sinh khóa và chứng chỉ mới cùng mật khẩu PKCS#12 ngẫu nhiên (b64u của 32 byte). */
        fun generate(): TlsIdentity {
            val (keyPair, certificate) = SelfSignedCertificateGenerator.generate()
            val password = Base64Codecs.encodeB64u(SecureRandomBytes.next(PASSWORD_BYTES)).toCharArray()
            val keyStore =
                KeyStore.getInstance(KEYSTORE_TYPE).apply {
                    load(null, null)
                    setKeyEntry(ALIAS, keyPair.private, password, arrayOf(certificate))
                }
            return TlsIdentity(keyStore, password)
        }

        fun fromPkcs12(
            pkcs12: ByteArray,
            password: CharArray,
        ): TlsIdentity {
            val keyStore = KeyStore.getInstance(KEYSTORE_TYPE).apply { load(pkcs12.inputStream(), password) }
            check(keyStore.isKeyEntry(ALIAS)) { "TLS key entry missing" }
            return TlsIdentity(keyStore, password)
        }
    }
}
