package app.handlive.android.core.crypto.derivation

import app.handlive.android.core.protocol.id.UuidBytes
import java.security.MessageDigest

/**
 * `device_id` tự chứng thực (0.2): UUIDv8 = 16 byte đầu của SHA-256(`ik_sig_pub`),
 * đặt 4 bit version = 8 (byte 6) và 2 bit variant = `10` (byte 8).
 */
object DeviceIdDerivation {
    private const val VERSION_BYTE = 6
    private const val VARIANT_BYTE = 8
    private const val LOW_NIBBLE = 0x0f
    private const val VERSION_8 = 0x80
    private const val VARIANT_MASK = 0x3f
    private const val VARIANT_RFC = 0x80

    fun deviceIdBytes(signingPublicKey: ByteArray): ByteArray {
        val bytes = MessageDigest.getInstance("SHA-256").digest(signingPublicKey).copyOf(UuidBytes.SIZE)
        bytes[VERSION_BYTE] = ((bytes[VERSION_BYTE].toInt() and LOW_NIBBLE) or VERSION_8).toByte()
        bytes[VARIANT_BYTE] = ((bytes[VARIANT_BYTE].toInt() and VARIANT_MASK) or VARIANT_RFC).toByte()
        return bytes
    }

    fun deviceId(signingPublicKey: ByteArray): String = UuidBytes.fromBytes(deviceIdBytes(signingPublicKey))

    /** Kiểm một `device_id` nhận được có đúng là của khóa công khai kèm theo không (C4). */
    fun matches(
        deviceId: String,
        signingPublicKey: ByteArray,
    ): Boolean = deviceId(signingPublicKey) == deviceId
}
