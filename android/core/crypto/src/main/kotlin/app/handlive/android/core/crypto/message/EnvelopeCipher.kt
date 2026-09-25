package app.handlive.android.core.crypto.message

import app.handlive.android.core.crypto.primitives.SecureRandomBytes
import app.handlive.android.core.crypto.primitives.XChaCha20Poly1305Aead
import app.handlive.android.core.protocol.ErrorCode
import app.handlive.android.core.protocol.ProtocolException
import app.handlive.android.core.protocol.encoding.Base64Codecs
import app.handlive.android.core.protocol.envelope.Envelope
import app.handlive.android.core.protocol.envelope.EnvelopeHeader
import java.security.GeneralSecurityException

/**
 * Mã hóa payload envelope (0.5.1): `payload` = b64(`nonce(24) ‖ ciphertext ‖ tag(16)`),
 * AAD = UTF-8 của `"<v>|<type>|<id>|<ts>"` dựng từ chính các trường của envelope.
 */
object EnvelopeCipher {
    /** [nonce] chỉ truyền vào khi kiểm test vector; mặc định sinh ngẫu nhiên 24 byte. */
    fun seal(
        key: ByteArray,
        header: EnvelopeHeader,
        plaintext: ByteArray,
        nonce: ByteArray = SecureRandomBytes.next(XChaCha20Poly1305Aead.NONCE_SIZE),
    ): Envelope {
        val sealed = XChaCha20Poly1305Aead.seal(key, plaintext, header.aad(), nonce)
        return header.withPayload(Base64Codecs.encodeB64(sealed))
    }

    /** Giải mã; tag/AAD sai, payload ngắn hơn 40 byte → [ProtocolException] `DECRYPT_FAILED`. */
    fun open(
        key: ByteArray,
        envelope: Envelope,
    ): ByteArray {
        val sealed = Base64Codecs.decodeB64(envelope.payload)
        return try {
            XChaCha20Poly1305Aead.open(key, sealed, envelope.aad())
        } catch (e: GeneralSecurityException) {
            throw ProtocolException(ErrorCode.DECRYPT_FAILED, "envelope decryption failed", e)
        }
    }
}
