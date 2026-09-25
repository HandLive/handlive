package app.handlive.android.core.crypto.keystore

import com.google.crypto.tink.Aead

/**
 * [SecretStore] bọc từng bí mật bằng Tink [Aead]; associated data gắn tên mục nên không tráo blob giữa hai tên được.
 * Trên Android, [aead] đến từ keyset Tink được khóa `hl_master` trong Android Keystore bọc lại
 * ([AndroidKeystoreSecretStore]); phần này thuần JVM nên test được không cần thiết bị.
 */
class AeadSecretStore(
    private val aead: Aead,
    private val backend: SecretBlobBackend,
) : SecretStore {
    override fun put(
        name: String,
        secret: ByteArray,
    ) {
        backend.write(name, aead.encrypt(secret, associatedData(name)))
    }

    /** Blob bị sửa hoặc bị tráo → `GeneralSecurityException` (không trả dữ liệu sai). */
    override fun get(name: String): ByteArray? = backend.read(name)?.let { aead.decrypt(it, associatedData(name)) }

    override fun delete(name: String) {
        backend.remove(name)
    }

    private fun associatedData(name: String): ByteArray = "$AD_PREFIX$name".toByteArray(Charsets.UTF_8)

    private companion object {
        const val AD_PREFIX = "handlive/v1/secret/"
    }
}
