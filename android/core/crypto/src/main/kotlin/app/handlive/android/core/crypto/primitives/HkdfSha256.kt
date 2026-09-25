package app.handlive.android.core.crypto.primitives

import javax.crypto.Mac
import javax.crypto.spec.SecretKeySpec

/**
 * HKDF-SHA256 (RFC 5869). Tách [extract]/[expand] để kiểm cả `prk` của vector; salt rỗng ≡ 32 byte 0
 * (0.6.3 bước 8: HKDF không ghi salt thì salt rỗng; không ghi L thì L = 32).
 */
object HkdfSha256 {
    const val HASH_SIZE = 32
    private const val MAX_BLOCKS = 255

    fun extract(
        salt: ByteArray,
        ikm: ByteArray,
    ): ByteArray = HmacSha256.mac(if (salt.isEmpty()) ByteArray(HASH_SIZE) else salt, ikm)

    fun expand(
        prk: ByteArray,
        info: ByteArray,
        length: Int,
    ): ByteArray {
        require(length in 1..MAX_BLOCKS * HASH_SIZE) { "invalid HKDF length" }
        val mac = Mac.getInstance(HmacSha256.ALGORITHM).apply { init(SecretKeySpec(prk, HmacSha256.ALGORITHM)) }
        val out = ByteArray(length)
        var previous = ByteArray(0)
        var offset = 0
        var counter = 1
        while (offset < length) {
            mac.update(previous)
            mac.update(info)
            mac.update(counter.toByte())
            previous = mac.doFinal()
            val take = minOf(previous.size, length - offset)
            previous.copyInto(out, offset, 0, take)
            offset += take
            counter++
        }
        return out
    }

    fun derive(
        ikm: ByteArray,
        salt: ByteArray = ByteArray(0),
        info: String,
        length: Int = HASH_SIZE,
    ): ByteArray = expand(extract(salt, ikm), info.toByteArray(Charsets.UTF_8), length)
}
