package app.handlive.android.core.transport.tls

import app.handlive.android.core.crypto.keystore.SecretStore
import java.io.File

/** PKCS#12 và mật khẩu của nó, dạng lưu bền. */
class StoredTlsIdentity(
    val pkcs12: ByteArray,
    val password: CharArray,
)

/**
 * Nơi lưu khóa TLS (0.6.1). Bản Android: [SecretStoreTlsIdentityStorage] với `SecretStore` gắn `hl_master`
 * trong Android Keystore ([AndroidTlsIdentityStorage]); test JVM: [InMemoryTlsIdentityStorage].
 */
interface TlsIdentityStorage {
    fun read(): StoredTlsIdentity?

    fun write(identity: StoredTlsIdentity)
}

/** Giữ trong bộ nhớ tiến trình — dùng cho test JVM, mất khi tiến trình kết thúc. */
class InMemoryTlsIdentityStorage : TlsIdentityStorage {
    @Volatile private var stored: StoredTlsIdentity? = null

    override fun read(): StoredTlsIdentity? = stored

    override fun write(identity: StoredTlsIdentity) {
        stored = identity
    }
}

/**
 * Mật khẩu PKCS#12 nằm trong [secrets] (trên Android: bọc bởi `hl_master` trong Keystore); bản thân PKCS#12
 * (đã mã hóa bằng mật khẩu đó) nằm trong [pkcs12File]. Ghi file qua tệp tạm rồi đổi tên để không để lại nửa file.
 */
class SecretStoreTlsIdentityStorage(
    private val secrets: SecretStore,
    private val pkcs12File: File,
) : TlsIdentityStorage {
    override fun read(): StoredTlsIdentity? {
        val password = secrets.get(PASSWORD_SECRET)
        return if (password != null && pkcs12File.isFile) {
            StoredTlsIdentity(pkcs12File.readBytes(), password.toString(Charsets.UTF_8).toCharArray())
        } else {
            null
        }
    }

    override fun write(identity: StoredTlsIdentity) {
        val temp = File(pkcs12File.parentFile, "${pkcs12File.name}.tmp")
        temp.writeBytes(identity.pkcs12)
        check(temp.renameTo(pkcs12File)) { "cannot replace TLS keystore file" }
        secrets.put(PASSWORD_SECRET, String(identity.password).toByteArray(Charsets.UTF_8))
    }

    companion object {
        const val PASSWORD_SECRET = "tls_pkcs12_password"
    }
}

/** Nạp khóa TLS đã lưu; lần chạy đầu (hoặc dữ liệu hỏng) thì sinh mới và lưu lại. */
object TlsIdentityProvider {
    fun loadOrCreate(storage: TlsIdentityStorage): TlsIdentity {
        storage.read()?.let { stored ->
            runCatching { TlsIdentity.fromPkcs12(stored.pkcs12, stored.password) }.onSuccess { return it }
        }
        val identity = TlsIdentity.generate()
        storage.write(StoredTlsIdentity(identity.toPkcs12(), identity.password()))
        return identity
    }
}
