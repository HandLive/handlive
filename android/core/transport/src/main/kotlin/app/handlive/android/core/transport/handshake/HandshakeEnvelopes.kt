package app.handlive.android.core.transport.handshake

import app.handlive.android.core.protocol.envelope.Envelope
import app.handlive.android.core.protocol.envelope.EnvelopeCodec
import app.handlive.android.core.protocol.envelope.MessageType
import app.handlive.android.core.protocol.envelope.OpPayload
import app.handlive.android.core.protocol.envelope.PlaintextCodec
import kotlinx.serialization.KSerializer

/** Envelope bắt tay `session/hello|welcome|error`: payload = b64 của JSON chưa mã hóa (0.5.1 ngoại lệ 1). */
internal object HandshakeEnvelopes {
    fun <T> build(
        id: String,
        ts: Long,
        op: String,
        serializer: KSerializer<T>,
        data: T,
    ): Envelope {
        val json = PlaintextCodec.encodeOp(op, serializer, data).toString(Charsets.UTF_8)
        return Envelope(Envelope.VERSION, MessageType.SESSION.wire, id, ts, EnvelopeCodec.unencryptedPayload(json))
    }

    /** Payload sai b64 hoặc sai cấu trúc → `ProtocolException(BAD_REQUEST)`. */
    fun <T> read(
        envelope: Envelope,
        serializer: KSerializer<T>,
    ): OpPayload<T> =
        PlaintextCodec.decodeOp(EnvelopeCodec.readUnencryptedPayload(envelope).toByteArray(Charsets.UTF_8), serializer)
}
