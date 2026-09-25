package app.handlive.android.core.transport.tls

import android.content.Context
import app.handlive.android.core.crypto.keystore.AndroidKeystoreSecretStore
import java.io.File

/**
 * Bản Android của [TlsIdentityStorage]: mật khẩu PKCS#12 bọc bởi `hl_master` (Android Keystore, 0.2),
 * PKCS#12 lưu trong `noBackupFilesDir` (không sao lưu, vì mật khẩu gắn với Keystore của máy).
 */
object AndroidTlsIdentityStorage {
    private const val PKCS12_FILE = "handlive-tls.p12"

    fun create(context: Context): TlsIdentityStorage =
        SecretStoreTlsIdentityStorage(
            AndroidKeystoreSecretStore.create(context),
            File(context.noBackupFilesDir, PKCS12_FILE),
        )
}
