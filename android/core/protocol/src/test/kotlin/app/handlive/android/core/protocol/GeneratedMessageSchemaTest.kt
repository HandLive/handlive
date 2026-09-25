package app.handlive.android.core.protocol

import app.handlive.android.core.protocol.ack.Ack
import app.handlive.android.core.protocol.encoding.Base64Codecs
import app.handlive.android.core.protocol.envelope.Envelope
import app.handlive.android.core.protocol.envelope.EnvelopeCodec
import app.handlive.android.core.protocol.envelope.MessageType
import app.handlive.android.core.protocol.envelope.PlaintextCodec
import app.handlive.android.core.protocol.id.UuidV7Generator
import app.handlive.android.core.protocol.session.PROTOCOL_VERSION
import app.handlive.android.core.protocol.session.SessionByeData
import app.handlive.android.core.protocol.session.SessionErrorData
import app.handlive.android.core.protocol.session.SessionHelloData
import app.handlive.android.core.protocol.session.SessionOp
import app.handlive.android.core.protocol.session.SessionRekeyData
import app.handlive.android.core.protocol.session.SessionWelcomeData
import app.handlive.android.core.protocol.testing.SharedTestVectors
import app.handlive.android.core.protocol.testing.str
import kotlinx.serialization.json.JsonPrimitive
import kotlinx.serialization.json.buildJsonObject
import org.junit.Assert.assertTrue
import org.junit.Test
import java.security.SecureRandom
import java.util.UUID

/** Tin do Kotlin sinh ra phải qua JSON Schema S0.2 (`shared/schemas`). */
class GeneratedMessageSchemaTest {
    private val ids = UuidV7Generator()
    private val random = SecureRandom()
    private val clientDeviceId = SharedTestVectors.vectors("device-id.json")[0].str("device_id")
    private val serverDeviceId = SharedTestVectors.vectors("device-id.json")[1].str("device_id")

    private fun b64u32(): String = Base64Codecs.encodeB64u(ByteArray(32).also(random::nextBytes))

    private fun text(bytes: ByteArray) = bytes.toString(Charsets.UTF_8)

    @Test
    fun envelopesOfEveryType() {
        for (type in MessageType.entries) {
            val sealed = ByteArray(64).also(random::nextBytes)
            val envelope =
                Envelope(
                    Envelope.VERSION,
                    type.wire,
                    ids.next(),
                    System.currentTimeMillis(),
                    Base64Codecs.encodeB64(sealed),
                )
            JsonSchemaValidation.assertValid("envelope.schema.json", EnvelopeCodec.encode(envelope))
        }
    }

    @Test
    fun acksForSuccessAndEveryErrorCode() {
        val data = buildJsonObject { put("count", JsonPrimitive(3)) }
        JsonSchemaValidation.assertValid(
            "ack.schema.json",
            text(PlaintextCodec.encodeAck(Ack.success(ids.next(), data))),
        )
        JsonSchemaValidation.assertValid("ack.schema.json", text(PlaintextCodec.encodeAck(Ack.success(ids.next()))))
        for (code in ErrorCode.entries) {
            val details = buildJsonObject { put("reason", JsonPrimitive("state")) }
            val ack = Ack.failure(ids.next(), code, "Lỗi", details)
            JsonSchemaValidation.assertValid("ack.schema.json", text(PlaintextCodec.encodeAck(ack)))
        }
    }

    @Test
    fun sessionOps() {
        val hello =
            SessionHelloData(
                PROTOCOL_VERSION,
                UUID.randomUUID().toString(),
                clientDeviceId,
                b64u32(),
                b64u32(),
                b64u32(),
            )
        valid("session-hello", PlaintextCodec.encodeOp(SessionOp.HELLO, SessionHelloData.serializer(), hello))
        val welcome = SessionWelcomeData(serverDeviceId, b64u32(), b64u32(), b64u32())
        valid("session-welcome", PlaintextCodec.encodeOp(SessionOp.WELCOME, SessionWelcomeData.serializer(), welcome))
        val versionError = SessionErrorData(ErrorCode.UNSUPPORTED_VERSION.name, "Cần cập nhật", minProtocol = 2)
        valid("session-error", PlaintextCodec.encodeOp(SessionOp.ERROR, SessionErrorData.serializer(), versionError))
        val authError = SessionErrorData(ErrorCode.AUTH_FAILED.name, "Sai MAC")
        valid("session-error", PlaintextCodec.encodeOp(SessionOp.ERROR, SessionErrorData.serializer(), authError))
        val rekey = SessionRekeyData(1, b64u32(), b64u32())
        valid("session-rekey", PlaintextCodec.encodeOp(SessionOp.REKEY, SessionRekeyData.serializer(), rekey))
        val ackData =
            ProtocolJson.encodeToJsonElement(
                SessionRekeyData.serializer(),
                SessionRekeyData(1, b64u32(), b64u32()),
            )
        val rekeyAck = Ack.success(ids.next(), ackData as kotlinx.serialization.json.JsonObject)
        JsonSchemaValidation.assertValid(
            "session-rekey.schema.json#/\$defs/ack",
            text(PlaintextCodec.encodeAck(rekeyAck)),
        )
        for (reason in listOf("revoked", "shutdown", "replaced", "update")) {
            valid(
                "session-bye",
                PlaintextCodec.encodeOp(SessionOp.BYE, SessionByeData.serializer(), SessionByeData(reason)),
            )
        }
    }

    @Test
    fun capabilityOps() {
        for ((op, data) in CapabilitySamples.all()) {
            val schema = if (op == "hello") "capability-hello" else "capability-update"
            valid(
                schema,
                PlaintextCodec.encodeOp(
                    op,
                    app.handlive.android.core.protocol.capability.CapabilityData
                        .serializer(),
                    data,
                ),
            )
        }
    }

    @Test
    fun validatorRejectsViolations() {
        val badError = SessionErrorData(ErrorCode.AUTH_FAILED.name, "x", minProtocol = 2)
        val errors =
            JsonSchemaValidation.errors(
                "session-error.schema.json",
                text(PlaintextCodec.encodeOp("error", SessionErrorData.serializer(), badError)),
            )
        assertTrue(errors.isNotEmpty())
        assertTrue(
            JsonSchemaValidation.errors("ack.schema.json", "{\"re\":\"${ids.next()}\",\"ok\":true}").isNotEmpty(),
        )
        assertTrue(
            JsonSchemaValidation
                .errors(
                    "envelope.schema.json",
                    "{\"v\":1,\"type\":\"x\",\"id\":\"a\",\"ts\":1,\"payload\":\"AAAA\"}",
                ).isNotEmpty(),
        )
    }

    private fun valid(
        schema: String,
        plaintext: ByteArray,
    ) = JsonSchemaValidation.assertValid("$schema.schema.json", text(plaintext))
}
