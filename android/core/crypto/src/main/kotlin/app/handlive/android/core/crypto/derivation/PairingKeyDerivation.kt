package app.handlive.android.core.crypto.derivation

import app.handlive.android.core.crypto.primitives.HkdfSha256
import app.handlive.android.core.crypto.primitives.X25519Keys
import app.handlive.android.core.protocol.id.UuidBytes
import java.security.MessageDigest

/**
 * `PRK` của cặp ghép nối (0.6.2): HKDF-SHA256(ikm = X25519(ik_dh mình, ik_dh đối phương) ‖ `pairing_secret`,
 * salt = SHA-256(device_id nhỏ hơn ‖ device_id lớn hơn, mỗi id 16 byte, so byte không dấu),
 * info = "handlive/v1/pair", L = 32).
 */
object PairingKeyDerivation {
    const val INFO = "handlive/v1/pair"

    fun prk(
        ownDhPrivateKey: ByteArray,
        peerDhPublicKey: ByteArray,
        pairingSecret: ByteArray,
        ownDeviceId: String,
        peerDeviceId: String,
    ): ByteArray {
        val dhShared = X25519Keys.sharedSecret(ownDhPrivateKey, peerDhPublicKey)
        return prkFromShared(dhShared, pairingSecret, ownDeviceId, peerDeviceId)
    }

    fun prkFromShared(
        dhShared: ByteArray,
        pairingSecret: ByteArray,
        deviceIdA: String,
        deviceIdB: String,
    ): ByteArray = HkdfSha256.derive(ikm = dhShared + pairingSecret, salt = salt(deviceIdA, deviceIdB), info = INFO)

    fun saltInput(
        deviceIdA: String,
        deviceIdB: String,
    ): ByteArray {
        val a = UuidBytes.toBytes(deviceIdA)
        val b = UuidBytes.toBytes(deviceIdB)
        return if (compareUnsigned(a, b) <= 0) a + b else b + a
    }

    fun salt(
        deviceIdA: String,
        deviceIdB: String,
    ): ByteArray = MessageDigest.getInstance("SHA-256").digest(saltInput(deviceIdA, deviceIdB))

    private fun compareUnsigned(
        a: ByteArray,
        b: ByteArray,
    ): Int {
        for (i in a.indices) {
            val diff = a[i].toUByte().compareTo(b[i].toUByte())
            if (diff != 0) return diff
        }
        return 0
    }
}
