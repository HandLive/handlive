package app.handlive.android.core.protocol.id

import java.security.SecureRandom

/**
 * UUIDv7 (RFC 9562 §5.7) cho `id` envelope và các định danh theo chức năng (0.2):
 * 48 bit mili-giây Unix ‖ version 7 ‖ 12 bit ngẫu nhiên ‖ variant `10` ‖ 62 bit ngẫu nhiên.
 */
class UuidV7Generator(
    private val clock: () -> Long = System::currentTimeMillis,
    private val random: SecureRandom = SecureRandom(),
) {
    fun next(): String {
        val bytes = ByteArray(UuidBytes.SIZE)
        random.nextBytes(bytes)
        val millis = clock()
        require(millis in 0..MAX_TIMESTAMP) { "timestamp out of 48-bit range" }
        for (i in 0 until TIMESTAMP_BYTES) {
            bytes[i] = (millis ushr (BITS_PER_BYTE * (TIMESTAMP_BYTES - 1 - i))).toByte()
        }
        bytes[VERSION_BYTE] = ((bytes[VERSION_BYTE].toInt() and LOW_NIBBLE) or VERSION_7).toByte()
        bytes[VARIANT_BYTE] = ((bytes[VARIANT_BYTE].toInt() and VARIANT_MASK) or VARIANT_RFC).toByte()
        return UuidBytes.fromBytes(bytes)
    }

    private companion object {
        const val TIMESTAMP_BYTES = 6
        const val BITS_PER_BYTE = 8
        const val MAX_TIMESTAMP = (1L shl 48) - 1
        const val VERSION_BYTE = 6
        const val VARIANT_BYTE = 8
        const val LOW_NIBBLE = 0x0f
        const val VERSION_7 = 0x70
        const val VARIANT_MASK = 0x3f
        const val VARIANT_RFC = 0x80
    }
}
