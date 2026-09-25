package app.handlive.android.core.crypto.keystore

import android.content.Context
import android.content.SharedPreferences
import android.security.keystore.KeyGenParameterSpec
import android.security.keystore.KeyProperties
import android.security.keystore.StrongBoxUnavailableException
import com.google.crypto.tink.Aead
import com.google.crypto.tink.KeyTemplate
import com.google.crypto.tink.RegistryConfiguration
import com.google.crypto.tink.aead.AeadConfig
import com.google.crypto.tink.aead.PredefinedAeadParameters
import com.google.crypto.tink.integration.android.AndroidKeysetManager
import java.security.KeyStore
import java.util.Base64
import javax.crypto.KeyGenerator

/**
 * Cài đặt Android của [SecretStore] (0.2, 0.6.1): khóa chủ `hl_master` AES-256-GCM trong Android Keystore
 * (StrongBox nếu có) bọc keyset Tink AES256-GCM; keyset đó mã hóa từng bí mật lưu trong SharedPreferences riêng.
 */
object AndroidKeystoreSecretStore {
    const val MASTER_KEY_ALIAS = "hl_master"
    private const val ANDROID_KEYSTORE = "AndroidKeyStore"
    private const val MASTER_KEY_URI = "android-keystore://$MASTER_KEY_ALIAS"
    private const val KEYSET_NAME = "hl_secret_keyset"
    private const val KEYSET_PREFS = "handlive_keyset"
    private const val SECRETS_PREFS = "handlive_secrets"
    private const val AES_KEY_BITS = 256

    fun create(context: Context): SecretStore {
        AeadConfig.register()
        ensureMasterKey()
        val aead =
            AndroidKeysetManager
                .Builder()
                .withSharedPref(context, KEYSET_NAME, KEYSET_PREFS)
                .withKeyTemplate(KeyTemplate.createFrom(PredefinedAeadParameters.AES256_GCM))
                .withMasterKeyUri(MASTER_KEY_URI)
                .build()
                .keysetHandle
                .getPrimitive(RegistryConfiguration.get(), Aead::class.java)
        val prefs = context.getSharedPreferences(SECRETS_PREFS, Context.MODE_PRIVATE)
        return AeadSecretStore(aead, SharedPreferencesBlobBackend(prefs))
    }

    /** Tạo `hl_master` nếu chưa có; thử StrongBox trước, máy không có thì dùng TEE. */
    private fun ensureMasterKey() {
        val keyStore = KeyStore.getInstance(ANDROID_KEYSTORE).apply { load(null) }
        if (keyStore.containsAlias(MASTER_KEY_ALIAS)) return
        try {
            generateMasterKey(strongBox = true)
        } catch (_: StrongBoxUnavailableException) {
            generateMasterKey(strongBox = false)
        }
    }

    private fun generateMasterKey(strongBox: Boolean) {
        val spec =
            KeyGenParameterSpec
                .Builder(MASTER_KEY_ALIAS, KeyProperties.PURPOSE_ENCRYPT or KeyProperties.PURPOSE_DECRYPT)
                .setBlockModes(KeyProperties.BLOCK_MODE_GCM)
                .setEncryptionPaddings(KeyProperties.ENCRYPTION_PADDING_NONE)
                .setKeySize(AES_KEY_BITS)
                .setIsStrongBoxBacked(strongBox)
                .build()
        KeyGenerator.getInstance(KeyProperties.KEY_ALGORITHM_AES, ANDROID_KEYSTORE).run {
            init(spec)
            generateKey()
        }
    }

    private class SharedPreferencesBlobBackend(
        private val prefs: SharedPreferences,
    ) : SecretBlobBackend {
        override fun read(name: String): ByteArray? =
            prefs.getString(name, null)?.let { Base64.getDecoder().decode(it) }

        override fun write(
            name: String,
            blob: ByteArray,
        ) {
            check(
                prefs.edit().putString(name, Base64.getEncoder().encodeToString(blob)).commit(),
            ) { "secret write failed" }
        }

        override fun remove(name: String) {
            check(prefs.edit().remove(name).commit()) { "secret delete failed" }
        }
    }
}
