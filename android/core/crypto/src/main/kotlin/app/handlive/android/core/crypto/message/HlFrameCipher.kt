package app.handlive.android.core.crypto.message

import app.handlive.android.core.crypto.primitives.SecureRandomBytes
import app.handlive.android.core.crypto.primitives.XChaCha20Poly1305Aead
import app.handlive.android.core.protocol.ErrorCode
import app.handlive.android.core.protocol.ProtocolException
import app.handlive.android.core.protocol.frame.HlFrame
import java.security.GeneralSecurityException

/** Mã hóa khung HL (0.5.2): phần `encrypted` = `nonce ‖ ciphertext ‖ tag`, AAD = 11 byte đầu khung. */
object HlFrameCipher {
    fun seal(
        key: ByteArray,
        seq: UInt,
        ts: UInt,
        plaintext: ByteArray,
        nonce: ByteArray = SecureRandomBytes.next(XChaCha20Poly1305Aead.NONCE_SIZE),
    ): HlFrame = HlFrame(seq, ts, XChaCha20Poly1305Aead.seal(key, plaintext, HlFrame.header(seq, ts), nonce))

    fun open(
        key: ByteArray,
        frame: HlFrame,
    ): ByteArray =
        try {
            XChaCha20Poly1305Aead.open(key, frame.encrypted, frame.header)
        } catch (e: GeneralSecurityException) {
            throw ProtocolException(ErrorCode.DECRYPT_FAILED, "HL frame decryption failed", e)
        }
}
