package app.handlive.android.core.protocol.envelope

import app.handlive.android.core.protocol.ErrorCode
import app.handlive.android.core.protocol.ProtocolException
import app.handlive.android.core.protocol.ProtocolJson
import app.handlive.android.core.protocol.ack.Ack
import kotlinx.serialization.KSerializer
import kotlinx.serialization.SerializationException

/** Plaintext JSON của payload (trước mã hóa/sau giải mã) ↔ model; lỗi cấu trúc → `BAD_REQUEST`. */
object PlaintextCodec {
    fun encodePayload(payload: Payload): ByteArray = encode(Payload.serializer(), payload)

    fun <T> encodeOp(
        op: String,
        dataSerializer: KSerializer<T>,
        data: T,
    ): ByteArray = encode(OpPayload.serializer(dataSerializer), OpPayload(op, data))

    fun encodeAck(ack: Ack): ByteArray = encode(Ack.serializer(), ack)

    fun decodePayload(plaintext: ByteArray): Payload = decode(Payload.serializer(), plaintext)

    fun <T> decodeOp(
        plaintext: ByteArray,
        dataSerializer: KSerializer<T>,
    ): OpPayload<T> = decode(OpPayload.serializer(dataSerializer), plaintext)

    fun decodeAck(plaintext: ByteArray): Ack = decode(Ack.serializer(), plaintext)

    private fun <T> encode(
        serializer: KSerializer<T>,
        value: T,
    ): ByteArray = ProtocolJson.encodeToString(serializer, value).toByteArray(Charsets.UTF_8)

    private fun <T> decode(
        serializer: KSerializer<T>,
        plaintext: ByteArray,
    ): T =
        try {
            ProtocolJson.decodeFromString(serializer, plaintext.toString(Charsets.UTF_8))
        } catch (e: SerializationException) {
            throw ProtocolException(ErrorCode.BAD_REQUEST, "malformed plaintext", e)
        } catch (e: IllegalArgumentException) {
            throw ProtocolException(ErrorCode.BAD_REQUEST, "malformed plaintext", e)
        }
}
