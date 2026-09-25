package app.handlive.android.core.protocol.envelope

import app.handlive.android.core.protocol.ErrorCode
import app.handlive.android.core.protocol.ProtocolException
import app.handlive.android.core.protocol.ProtocolJson
import app.handlive.android.core.protocol.encoding.Base64Codecs
import app.handlive.android.core.protocol.id.UuidBytes
import app.handlive.android.core.protocol.protocolRequire
import kotlinx.serialization.SerializationException

/** Mã hóa/giải mã envelope ↔ chuỗi wire, kiểm cấu trúc và giới hạn 256 KiB (0.5.1). */
object EnvelopeCodec {
    private const val UUID_VERSION_INDEX = 14
    private const val UUID_VARIANT_INDEX = 19
    private const val VARIANTS = "89ab"

    fun encode(envelope: Envelope): String {
        val text = ProtocolJson.encodeToString(Envelope.serializer(), envelope)
        checkSize(text)
        return text
    }

    fun decode(text: String): Envelope {
        checkSize(text)
        val envelope =
            try {
                ProtocolJson.decodeFromString(Envelope.serializer(), text)
            } catch (e: SerializationException) {
                throw ProtocolException(ErrorCode.BAD_REQUEST, "malformed envelope", e)
            } catch (e: IllegalArgumentException) {
                throw ProtocolException(ErrorCode.BAD_REQUEST, "malformed envelope", e)
            }
        validate(envelope)
        return envelope
    }

    /** Payload của tin bắt tay (0.5.1 ngoại lệ 1): b64 của JSON chưa mã hóa. */
    fun unencryptedPayload(plaintextJson: String): String =
        Base64Codecs.encodeB64(plaintextJson.toByteArray(Charsets.UTF_8))

    fun readUnencryptedPayload(envelope: Envelope): String =
        Base64Codecs.decodeB64(envelope.payload).toString(Charsets.UTF_8)

    private fun validate(envelope: Envelope) {
        protocolRequire(envelope.v == Envelope.VERSION, ErrorCode.UNSUPPORTED_VERSION, "unsupported envelope version")
        protocolRequire(isUuidV7(envelope.id), ErrorCode.BAD_REQUEST, "id is not a UUIDv7")
        protocolRequire(envelope.ts >= 0, ErrorCode.BAD_REQUEST, "negative ts")
        Base64Codecs.decodeB64(envelope.payload)
    }

    fun isUuidV7(id: String): Boolean =
        UuidBytes.isCanonical(id) && id[UUID_VERSION_INDEX] == '7' && id[UUID_VARIANT_INDEX] in VARIANTS

    private fun checkSize(text: String) {
        // Mỗi ký tự UTF-16 chiếm ≥ 1 byte UTF-8, nên chuỗi dài hơn giới hạn chắc chắn quá cỡ.
        val fits = text.length <= Envelope.MAX_BYTES && text.toByteArray(Charsets.UTF_8).size <= Envelope.MAX_BYTES
        protocolRequire(fits, ErrorCode.PAYLOAD_TOO_LARGE, "envelope exceeds ${Envelope.MAX_BYTES} bytes")
    }
}
