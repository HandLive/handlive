package app.handlive.android.core.protocol.clipboard

import app.handlive.android.core.protocol.ErrorCode
import app.handlive.android.core.protocol.ProtocolException
import app.handlive.android.core.protocol.ProtocolJson
import app.handlive.android.core.protocol.envelope.OpPayload
import app.handlive.android.core.protocol.protocolRequire
import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable
import kotlinx.serialization.SerializationException
import java.nio.ByteBuffer

/**
 * Plaintext nhị phân của `clipboard` op `chunk` (0.5.1 ngoại lệ 2), tránh base64 hai lần:
 * `hdr_len` uint16 BE ‖ JSON `{"op":"chunk","data":{"transfer_id","index"}}` ‖ bytes của khối.
 */
class ClipboardChunkPlaintext(
    val transferId: String,
    val index: Int,
    val chunk: ByteArray,
) {
    init {
        require(chunk.size <= CHUNK_SIZE) { "chunk exceeds CHUNK_SIZE" }
    }

    fun encode(): ByteArray {
        val header =
            ProtocolJson
                .encodeToString(HEADER_SERIALIZER, OpPayload(OP, ChunkHeader(transferId, index)))
                .toByteArray(Charsets.UTF_8)
        return ByteBuffer
            .allocate(HDR_LEN_SIZE + header.size + chunk.size)
            .putShort(header.size.toShort())
            .put(header)
            .put(chunk)
            .array()
    }

    @Serializable
    private data class ChunkHeader(
        @SerialName("transfer_id") val transferId: String,
        val index: Int,
    )

    companion object {
        const val OP = "chunk"

        /** `CHUNK_SIZE` (0.10): 64 KiB trước mã hóa. */
        const val CHUNK_SIZE = 64 * 1024
        private const val HDR_LEN_SIZE = 2
        private const val UINT16_MASK = 0xffff
        private const val MALFORMED = "malformed chunk plaintext"
        private val HEADER_SERIALIZER = OpPayload.serializer(ChunkHeader.serializer())

        fun decode(plaintext: ByteArray): ClipboardChunkPlaintext {
            protocolRequire(plaintext.size >= HDR_LEN_SIZE, ErrorCode.BAD_REQUEST, MALFORMED)
            val hdrLen = ByteBuffer.wrap(plaintext).getShort().toInt() and UINT16_MASK
            protocolRequire(plaintext.size >= HDR_LEN_SIZE + hdrLen, ErrorCode.BAD_REQUEST, MALFORMED)
            val headerJson = plaintext.copyOfRange(HDR_LEN_SIZE, HDR_LEN_SIZE + hdrLen).toString(Charsets.UTF_8)
            val header =
                try {
                    ProtocolJson.decodeFromString(HEADER_SERIALIZER, headerJson)
                } catch (e: SerializationException) {
                    throw ProtocolException(ErrorCode.BAD_REQUEST, MALFORMED, e)
                }
            protocolRequire(header.op == OP, ErrorCode.BAD_REQUEST, MALFORMED)
            val chunk = plaintext.copyOfRange(HDR_LEN_SIZE + hdrLen, plaintext.size)
            protocolRequire(chunk.size <= CHUNK_SIZE, ErrorCode.PAYLOAD_TOO_LARGE, "chunk too large")
            return ClipboardChunkPlaintext(header.data.transferId, header.data.index, chunk)
        }
    }
}
