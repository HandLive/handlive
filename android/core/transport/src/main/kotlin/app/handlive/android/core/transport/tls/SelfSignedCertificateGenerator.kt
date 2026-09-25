package app.handlive.android.core.transport.tls

import app.handlive.android.core.crypto.primitives.SecureRandomBytes
import java.io.ByteArrayOutputStream
import java.security.KeyPair
import java.security.KeyPairGenerator
import java.security.Signature
import java.security.cert.CertificateFactory
import java.security.cert.X509Certificate
import java.security.spec.ECGenParameterSpec
import java.time.Instant
import java.time.ZoneOffset
import java.time.format.DateTimeFormatter
import java.time.temporal.ChronoUnit

/**
 * Chứng chỉ TLS tự ký ECDSA P-256 + SHA-256, hạn 20 năm (0.4.1). Client ghim SHA-256 của DER nên chứng chỉ
 * không cần tên miền hay phần mở rộng; tên chủ thể cố định để không lộ tên máy. Tự ghi DER X.509 v3 tối giản
 * vì JCA không có API dựng chứng chỉ và Android không kèm BouncyCastle công khai.
 */
object SelfSignedCertificateGenerator {
    const val VALIDITY_YEARS = 20L
    const val SUBJECT_CN = "HandLive"
    private const val SIGNATURE_ALGORITHM = "SHA256withECDSA"
    private const val CURVE = "secp256r1"
    private const val SERIAL_BYTES = 16
    private const val UTC_TIME_LAST_YEAR = 2049
    private const val SERIAL_TOP_BYTE_MASK = 0x3f
    private const val SERIAL_TOP_BYTE_FLOOR = 0x40

    fun generate(now: Instant = Instant.now()): Pair<KeyPair, X509Certificate> {
        val keyPair =
            KeyPairGenerator.getInstance("EC").run {
                initialize(ECGenParameterSpec(CURVE))
                generateKeyPair()
            }
        val notBefore = now.minus(1, ChronoUnit.DAYS).truncatedTo(ChronoUnit.SECONDS)
        val notAfter =
            now
                .atOffset(
                    ZoneOffset.UTC,
                ).plusYears(VALIDITY_YEARS)
                .toInstant()
                .truncatedTo(ChronoUnit.SECONDS)
        val tbs = tbsCertificate(keyPair, notBefore, notAfter)
        val signature =
            Signature.getInstance(SIGNATURE_ALGORITHM).run {
                initSign(keyPair.private)
                update(tbs)
                sign()
            }
        val der = Der.sequence(tbs, ECDSA_WITH_SHA256, Der.bitString(signature))
        val certificate =
            CertificateFactory.getInstance("X.509").generateCertificate(der.inputStream()) as X509Certificate
        return keyPair to certificate
    }

    private fun tbsCertificate(
        keyPair: KeyPair,
        notBefore: Instant,
        notAfter: Instant,
    ): ByteArray {
        val name = Der.sequence(Der.set(Der.sequence(OID_COMMON_NAME, Der.utf8String(SUBJECT_CN))))
        return Der.sequence(
            VERSION_3,
            Der.integer(serialNumber()),
            ECDSA_WITH_SHA256,
            name,
            Der.sequence(time(notBefore), time(notAfter)),
            name,
            // SubjectPublicKeyInfo của JCA đã là DER chuẩn (id-ecPublicKey + prime256v1).
            keyPair.public.encoded,
        )
    }

    /** Số dương, byte đầu khác 0 để mã hóa INTEGER tối giản. */
    private fun serialNumber(): ByteArray =
        SecureRandomBytes.next(SERIAL_BYTES).also {
            it[0] = ((it[0].toInt() and SERIAL_TOP_BYTE_MASK) or SERIAL_TOP_BYTE_FLOOR).toByte()
        }

    /** RFC 5280 §4.1.2.5: UTCTime đến hết năm 2049, GeneralizedTime từ 2050. */
    private fun time(instant: Instant): ByteArray {
        val utc = instant.atOffset(ZoneOffset.UTC)
        return if (utc.year <= UTC_TIME_LAST_YEAR) {
            Der.element(Der.TAG_UTC_TIME, utc.format(UTC_TIME).toByteArray(Charsets.US_ASCII))
        } else {
            Der.element(Der.TAG_GENERALIZED_TIME, utc.format(GENERALIZED_TIME).toByteArray(Charsets.US_ASCII))
        }
    }

    private val UTC_TIME = DateTimeFormatter.ofPattern("yyMMddHHmmss'Z'")
    private val GENERALIZED_TIME = DateTimeFormatter.ofPattern("yyyyMMddHHmmss'Z'")

    /** `[0] EXPLICIT INTEGER 2` (v3). */
    private val VERSION_3 = "a003020102".hexToByteArray()

    /** AlgorithmIdentifier ecdsa-with-SHA256 (1.2.840.10045.4.3.2), không có tham số (RFC 5758 §3.2). */
    private val ECDSA_WITH_SHA256 =
        Der.sequence("06082a8648ce3d040302".hexToByteArray())

    /** OID commonName 2.5.4.3. */
    private val OID_COMMON_NAME = "0603550403".hexToByteArray()
}

/** Bộ ghi DER tối thiểu cho [SelfSignedCertificateGenerator]. */
private object Der {
    const val TAG_UTC_TIME = 0x17
    const val TAG_GENERALIZED_TIME = 0x18
    private const val TAG_INTEGER = 0x02
    private const val TAG_BIT_STRING = 0x03
    private const val TAG_UTF8_STRING = 0x0c
    private const val TAG_SEQUENCE = 0x30
    private const val TAG_SET = 0x31
    private const val SHORT_LENGTH_MAX = 0x7f
    private const val LONG_LENGTH_FLAG = 0x80
    private const val BYTE_BITS = 8
    private const val BYTE_MASK = 0xff

    fun sequence(vararg parts: ByteArray): ByteArray = element(TAG_SEQUENCE, concat(parts))

    fun set(vararg parts: ByteArray): ByteArray = element(TAG_SET, concat(parts))

    fun integer(positiveMinimal: ByteArray): ByteArray = element(TAG_INTEGER, positiveMinimal)

    fun utf8String(text: String): ByteArray = element(TAG_UTF8_STRING, text.toByteArray(Charsets.UTF_8))

    /** BIT STRING không có bit thừa (byte đầu = 0). */
    fun bitString(bytes: ByteArray): ByteArray = element(TAG_BIT_STRING, byteArrayOf(0) + bytes)

    fun element(
        tag: Int,
        content: ByteArray,
    ): ByteArray = byteArrayOf(tag.toByte()) + length(content.size) + content

    private fun length(size: Int): ByteArray {
        if (size <= SHORT_LENGTH_MAX) return byteArrayOf(size.toByte())
        val bytes = ArrayList<Byte>()
        var rest = size
        while (rest > 0) {
            bytes.add(0, (rest and BYTE_MASK).toByte())
            rest = rest ushr BYTE_BITS
        }
        return byteArrayOf((LONG_LENGTH_FLAG or bytes.size).toByte()) + bytes.toByteArray()
    }

    private fun concat(parts: Array<out ByteArray>): ByteArray =
        ByteArrayOutputStream().apply { parts.forEach(::write) }.toByteArray()
}
