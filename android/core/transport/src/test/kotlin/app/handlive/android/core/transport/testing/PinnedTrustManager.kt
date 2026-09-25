package app.handlive.android.core.transport.testing

import app.handlive.android.core.crypto.primitives.HmacSha256
import io.ktor.client.HttpClient
import io.ktor.client.engine.java.Java
import io.ktor.client.plugins.websocket.WebSockets
import java.net.Socket
import java.security.MessageDigest
import java.security.cert.CertificateException
import java.security.cert.X509Certificate
import javax.net.ssl.SSLContext
import javax.net.ssl.SSLEngine
import javax.net.ssl.X509ExtendedTrustManager

/**
 * Client đóng vai C (Mac/iOS) trong test: tin chứng chỉ máy chủ chỉ khi SHA-256 của DER khớp ghim
 * (`tls_sha256`, 0.4.1), không kiểm hostname — giống delegate `URLSession` của M-APP (CONN-01 API 3).
 */
class PinnedTrustManager(
    private val pinSha256: ByteArray,
) : X509ExtendedTrustManager() {
    override fun checkServerTrusted(
        chain: Array<out X509Certificate>,
        authType: String,
    ) {
        val leaf = chain.firstOrNull() ?: throw CertificateException("empty chain")
        val actual = MessageDigest.getInstance("SHA-256").digest(leaf.encoded)
        if (!HmacSha256.constantTimeEquals(actual, pinSha256)) throw CertificateException("TLS_PIN_MISMATCH")
    }

    override fun checkServerTrusted(
        chain: Array<out X509Certificate>,
        authType: String,
        socket: Socket?,
    ) = checkServerTrusted(chain, authType)

    override fun checkServerTrusted(
        chain: Array<out X509Certificate>,
        authType: String,
        engine: SSLEngine?,
    ) = checkServerTrusted(chain, authType)

    override fun checkClientTrusted(
        chain: Array<out X509Certificate>,
        authType: String,
    ) = throw CertificateException("client certificates are not used")

    override fun checkClientTrusted(
        chain: Array<out X509Certificate>,
        authType: String,
        socket: Socket?,
    ) = checkClientTrusted(chain, authType)

    override fun checkClientTrusted(
        chain: Array<out X509Certificate>,
        authType: String,
        engine: SSLEngine?,
    ) = checkClientTrusted(chain, authType)

    override fun getAcceptedIssuers(): Array<X509Certificate> = emptyArray()
}

fun pinnedSslContext(
    pinSha256: ByteArray,
    protocol: String = "TLSv1.3",
): SSLContext = SSLContext.getInstance(protocol).apply { init(null, arrayOf(PinnedTrustManager(pinSha256)), null) }

/** Ktor client (engine Java, hỗ trợ TLS 1.3) với ghim chứng chỉ. */
fun pinnedWebSocketClient(pinSha256: ByteArray): HttpClient =
    HttpClient(Java) {
        engine {
            config { sslContext(pinnedSslContext(pinSha256)) }
        }
        install(WebSockets)
    }
