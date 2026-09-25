package app.handlive.android.core.crypto.keystore

/**
 * Kho bí mật cục bộ (0.6.1): `ik_sig` seed, `ik_dh`, `PRK` của từng cặp (`prk_enc`)…
 * Giá trị luôn được mã hóa trước khi chạm bộ nhớ bền; tên chỉ là nhãn, không bí mật.
 */
interface SecretStore {
    fun put(
        name: String,
        secret: ByteArray,
    )

    fun get(name: String): ByteArray?

    fun delete(name: String)
}

/** Nơi lưu blob đã mã hóa (SharedPreferences trên Android, bộ nhớ trong test JVM). */
interface SecretBlobBackend {
    fun read(name: String): ByteArray?

    fun write(
        name: String,
        blob: ByteArray,
    )

    fun remove(name: String)
}
