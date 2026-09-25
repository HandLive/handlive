package app.handlive.android.core.crypto

import app.handlive.android.core.crypto.message.EnvelopeCipher
import app.handlive.android.core.crypto.primitives.XChaCha20Poly1305Aead
import app.handlive.android.core.protocol.ack.Ack
import app.handlive.android.core.protocol.encoding.Base64Codecs
import app.handlive.android.core.protocol.envelope.EnvelopeCodec
import app.handlive.android.core.protocol.envelope.EnvelopeHeader
import app.handlive.android.core.protocol.envelope.Payload
import app.handlive.android.core.protocol.envelope.PlaintextCodec
import app.handlive.android.core.protocol.id.UuidV7Generator
import app.handlive.android.core.protocol.testing.Hex
import app.handlive.android.core.protocol.testing.SharedTestVectors
import app.handlive.android.core.protocol.testing.str
import app.handlive.android.core.protocol.testing.strOrNull
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.JsonPrimitive
import kotlinx.serialization.json.buildJsonArray
import kotlinx.serialization.json.buildJsonObject

/**
 * Sinh envelope-roundtrip.json: vài envelope do Kotlin mã hóa bằng khóa cố định của envelope.json
 * (k_c2s / k_s2c của session-handshake cặp 1), cùng định dạng envelope.json để Apple giải mã được.
 */
object EnvelopeRoundtripFixture {
    private class Message(
        val name: String,
        val direction: String,
        val type: String,
        val plaintext: String,
    )

    fun build(): JsonObject {
        val ids = UuidV7Generator()
        val keys = SharedTestVectors.vectors("envelope.json").filter { it.strOrNull("key") != null }
        val keyByDirection = keys.associateBy { it.str("direction") }
        val ts = System.currentTimeMillis()
        val messages = messages(ids, ts)
        return buildJsonObject {
            put("description", JsonPrimitive(DESCRIPTION))
            put("source", JsonPrimitive("android/core/crypto EnvelopeRoundtripTest (HL_WRITE_ROUNDTRIP=1)"))
            put(
                "vectors",
                buildJsonArray {
                    messages.forEachIndexed { index, message ->
                        val keyVector = keyByDirection.getValue(message.direction)
                        add(vector(message, keyVector, ids.next(), ts + index))
                    }
                },
            )
        }
    }

    private fun messages(
        ids: UuidV7Generator,
        ts: Long,
    ): List<Message> {
        val clip =
            Payload(
                "push",
                buildJsonObject {
                    put("clip_id", JsonPrimitive(ids.next()))
                    put("kind", JsonPrimitive("text"))
                    put("mime", JsonPrimitive("text/plain"))
                    put("text", JsonPrimitive("Xin chào từ Android — mã đơn: HL-0042 ✓"))
                    put("sensitive", JsonPrimitive(false))
                    put("origin_ts", JsonPrimitive(ts - 3))
                    put("source", JsonPrimitive("auto"))
                    put(
                        "origin_device_id",
                        JsonPrimitive(SharedTestVectors.vectors("device-id.json")[1].str("device_id")),
                    )
                },
            )
        val ack = Ack.success(ids.next(), buildJsonObject { put("seq", JsonPrimitive(7)) })
        val ping = Payload("ping", buildJsonObject { put("seq", JsonPrimitive(7)) })
        return listOf(
            Message(
                "Kotlin clipboard push Android→Mac",
                "s2c",
                "clipboard",
                PlaintextCodec.encodePayload(clip).decodeToString(),
            ),
            Message("Kotlin ack ok Android→Mac", "s2c", "ack", PlaintextCodec.encodeAck(ack).decodeToString()),
            Message("Kotlin ping Mac→Android", "c2s", "ping", PlaintextCodec.encodePayload(ping).decodeToString()),
        )
    }

    private fun vector(
        message: Message,
        keyVector: JsonObject,
        id: String,
        ts: Long,
    ): JsonObject {
        val key = Hex.decode(keyVector.str("key"))
        val envelope = EnvelopeCipher.seal(key, EnvelopeHeader(message.type, id, ts), message.plaintext.toByteArray())
        val sealed = Base64Codecs.decodeB64(envelope.payload)
        val nonceEnd = XChaCha20Poly1305Aead.NONCE_SIZE
        val tagStart = sealed.size - XChaCha20Poly1305Aead.TAG_SIZE
        return buildJsonObject {
            put("name", JsonPrimitive(message.name))
            put("encrypted", JsonPrimitive(true))
            put("direction", JsonPrimitive(message.direction))
            put("key", JsonPrimitive(keyVector.str("key")))
            put("key_source", JsonPrimitive(keyVector.str("key_source")))
            put("v", JsonPrimitive(envelope.v))
            put("type", JsonPrimitive(envelope.type))
            put("id", JsonPrimitive(envelope.id))
            put("ts", JsonPrimitive(envelope.ts))
            put("aad", JsonPrimitive(envelope.aad().decodeToString()))
            put("aad_hex", JsonPrimitive(Hex.encode(envelope.aad())))
            put("plaintext", JsonPrimitive(message.plaintext))
            put("nonce", JsonPrimitive(Hex.encode(sealed.copyOfRange(0, nonceEnd))))
            put("ciphertext", JsonPrimitive(Hex.encode(sealed.copyOfRange(nonceEnd, tagStart))))
            put("tag", JsonPrimitive(Hex.encode(sealed.copyOfRange(tagStart, sealed.size))))
            put("payload_b64", JsonPrimitive(envelope.payload))
            put("envelope", JsonPrimitive(EnvelopeCodec.encode(envelope)))
        }
    }

    private const val DESCRIPTION =
        "Envelope do Android (Kotlin, Tink XChaCha20-Poly1305) mã hóa bằng khóa cố định của envelope.json; " +
            "cùng định dạng envelope.json. Apple giải mã và so plaintext để chứng minh liên thông Kotlin → Swift."
}
