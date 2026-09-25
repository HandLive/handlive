package app.handlive.android.core.transport.handshake

import app.handlive.android.core.crypto.derivation.SessionHandshakeDerivation
import app.handlive.android.core.crypto.derivation.SessionKeys
import app.handlive.android.core.crypto.primitives.SecureRandomBytes
import app.handlive.android.core.crypto.primitives.X25519Keys
import app.handlive.android.core.protocol.ErrorCode
import app.handlive.android.core.protocol.ProtocolException
import app.handlive.android.core.protocol.ProtocolJson
import app.handlive.android.core.protocol.encoding.Base64Codecs
import app.handlive.android.core.protocol.envelope.Envelope
import app.handlive.android.core.protocol.envelope.EnvelopeCodec
import app.handlive.android.core.protocol.envelope.MessageType
import app.handlive.android.core.protocol.envelope.PlaintextCodec
import app.handlive.android.core.protocol.id.UuidBytes
import app.handlive.android.core.protocol.id.UuidV7Generator
import app.handlive.android.core.protocol.protocolRequire
import app.handlive.android.core.protocol.session.PROTOCOL_VERSION
import app.handlive.android.core.protocol.session.SessionErrorData
import app.handlive.android.core.protocol.session.SessionHelloData
import app.handlive.android.core.protocol.session.SessionOp
import app.handlive.android.core.protocol.session.SessionWelcomeData
import app.handlive.android.core.transport.TransportConstants.NONCE_SIZE
import app.handlive.android.core.transport.WsCloseCode
import kotlinx.serialization.SerializationException
import kotlinx.serialization.json.JsonPrimitive
import kotlinx.serialization.json.intOrNull
import java.security.GeneralSecurityException

/** Kết quả xử lý `session/hello` ở S. */
sealed interface HandshakeOutcome {
    /** Gửi [welcome]; khóa phiên đã sẵn sàng, chờ envelope mã hóa đầu tiên (`capability/hello`). */
    class Accepted(
        val welcome: Envelope,
        val pair: PairRecord,
        val keys: SessionKeys,
    ) : HandshakeOutcome

    /** Gửi [error] (nếu có — `BAD_REQUEST` không có `session/error`) rồi đóng [closeCode]. */
    class Rejected(
        val code: ErrorCode,
        val closeCode: Short,
        val error: Envelope?,
    ) : HandshakeOutcome
}

/**
 * Phía S của bắt tay `/v1/ctl` (0.6.3 bước 1–3, 8; CONN-01 API 4–6). Thứ tự kiểm (CONN-01 API 4):
 * `protocol` (khác major → 4426) → cặp tồn tại (`PAIR_UNKNOWN`, 4401) → chưa thu hồi (4403) → `device_id` khớp
 * → `mac` (hằng thời gian). Khóa tạm `eph` sinh mới mỗi lần welcome nên hello bị phát lại không cho phiên dùng được.
 */
class ServerHandshake(
    private val localDeviceId: String,
    private val pairs: PairRegistry,
    private val ids: UuidV7Generator = UuidV7Generator(),
    private val clock: () -> Long = System::currentTimeMillis,
    private val ephemeralPrivateKey: () -> ByteArray = X25519Keys::generatePrivateKey,
    private val nonce: () -> ByteArray = { SecureRandomBytes.next(NONCE_SIZE) },
) {
    fun respond(helloText: String): HandshakeOutcome =
        try {
            respondChecked(helloText)
        } catch (e: ProtocolException) {
            if (e.code == ErrorCode.UNSUPPORTED_VERSION) unsupportedVersion() else badRequest()
        }

    private fun respondChecked(helloText: String): HandshakeOutcome {
        val hello = parseHello(helloText)
        val pair = pairs.find(hello.pairId)
        return rejectionFor(hello, pair) ?: welcome(checkNotNull(pair), hello)
    }

    /** `session/hello` đã kiểm cấu trúc; `eph`, `mac` đã giải b64u, `t1` ghép byte thô (0.6.3 bước 8). */
    private class ParsedHello(
        val pairId: String,
        val deviceId: String,
        val eph: ByteArray,
        val mac: ByteArray,
        val t1: ByteArray,
    )

    /** Sai cấu trúc → `BAD_REQUEST`; `protocol` khác → `UNSUPPORTED_VERSION` (kiểm trước khi đọc trường khác). */
    private fun parseHello(helloText: String): ParsedHello {
        val envelope = EnvelopeCodec.decode(helloText)
        protocolRequire(envelope.type == MessageType.SESSION.wire, ErrorCode.BAD_REQUEST, "not a session envelope")
        val payload = PlaintextCodec.decodePayload(EnvelopeCodec.readUnencryptedPayload(envelope).toByteArray())
        protocolRequire(payload.op == SessionOp.HELLO, ErrorCode.BAD_REQUEST, "not session/hello")
        val protocol = (payload.data["protocol"] as? JsonPrimitive)?.intOrNull
        protocolRequire(protocol != null, ErrorCode.BAD_REQUEST, "missing protocol")
        protocolRequire(protocol == PROTOCOL_VERSION, ErrorCode.UNSUPPORTED_VERSION, "unsupported protocol")
        val hello = decodeHello(payload.data)
        protocolRequire(
            UuidBytes.isCanonical(hello.pairId) && UuidBytes.isCanonical(hello.deviceId),
            ErrorCode.BAD_REQUEST,
            "invalid uuid",
        )
        val eph = Base64Codecs.decodeB64u(hello.eph, X25519Keys.KEY_SIZE)
        val clientNonce = Base64Codecs.decodeB64u(hello.nonce, NONCE_SIZE)
        val mac = Base64Codecs.decodeB64u(hello.mac, NONCE_SIZE)
        val t1 = SessionHandshakeDerivation.t1(hello.pairId, hello.deviceId, eph, clientNonce)
        return ParsedHello(hello.pairId, hello.deviceId, eph, mac, t1)
    }

    /** Thứ tự CONN-01 API 4 sau `protocol`: cặp tồn tại → chưa thu hồi → `device_id` khớp → `mac` hằng thời gian. */
    private fun rejectionFor(
        hello: ParsedHello,
        pair: PairRecord?,
    ): HandshakeOutcome.Rejected? =
        when {
            pair == null -> {
                reject(ErrorCode.PAIR_UNKNOWN, WsCloseCode.AUTH_FAILED)
            }

            pair.revoked -> {
                reject(ErrorCode.PAIR_REVOKED, WsCloseCode.PAIR_REVOKED)
            }

            pair.peerDeviceId != hello.deviceId -> {
                reject(ErrorCode.AUTH_FAILED, WsCloseCode.AUTH_FAILED)
            }

            !SessionHandshakeDerivation.verifyMac(SessionHandshakeDerivation.kAuth(pair.prk), hello.t1, hello.mac) -> {
                reject(ErrorCode.AUTH_FAILED, WsCloseCode.AUTH_FAILED)
            }

            else -> {
                null
            }
        }

    private fun welcome(
        pair: PairRecord,
        hello: ParsedHello,
    ): HandshakeOutcome {
        val kAuth = SessionHandshakeDerivation.kAuth(pair.prk)
        val ephPrivate = ephemeralPrivateKey()
        val ephPublic = X25519Keys.publicFromPrivate(ephPrivate)
        val serverNonce = nonce()
        val t2 = SessionHandshakeDerivation.t2(hello.t1, localDeviceId, ephPublic, serverNonce)
        val keys =
            try {
                SessionHandshakeDerivation.sessionKeys(ephPrivate, hello.eph, pair.prk, t2)
            } catch (_: GeneralSecurityException) {
                // `eph` của client là điểm bậc thấp: MAC đúng nhưng không dẫn ra được khóa an toàn.
                return reject(ErrorCode.AUTH_FAILED, WsCloseCode.AUTH_FAILED)
            }
        val data =
            SessionWelcomeData(
                deviceId = localDeviceId,
                eph = Base64Codecs.encodeB64u(ephPublic),
                nonce = Base64Codecs.encodeB64u(serverNonce),
                mac = Base64Codecs.encodeB64u(SessionHandshakeDerivation.mac(kAuth, t2)),
            )
        val envelope =
            HandshakeEnvelopes.build(ids.next(), clock(), SessionOp.WELCOME, SessionWelcomeData.serializer(), data)
        return HandshakeOutcome.Accepted(envelope, pair, keys)
    }

    private fun decodeHello(data: kotlinx.serialization.json.JsonObject): SessionHelloData =
        try {
            ProtocolJson.decodeFromJsonElement(SessionHelloData.serializer(), data)
        } catch (e: SerializationException) {
            throw ProtocolException(ErrorCode.BAD_REQUEST, "malformed session/hello", e)
        } catch (e: IllegalArgumentException) {
            throw ProtocolException(ErrorCode.BAD_REQUEST, "malformed session/hello", e)
        }

    private fun badRequest() = HandshakeOutcome.Rejected(ErrorCode.BAD_REQUEST, WsCloseCode.BAD_REQUEST, null)

    private fun unsupportedVersion() =
        reject(ErrorCode.UNSUPPORTED_VERSION, WsCloseCode.UNSUPPORTED_VERSION, minProtocol = PROTOCOL_VERSION)

    private fun reject(
        code: ErrorCode,
        closeCode: Short,
        minProtocol: Int? = null,
    ): HandshakeOutcome.Rejected {
        val data = SessionErrorData(code.name, ERROR_MESSAGES.getValue(code), minProtocol)
        val envelope =
            HandshakeEnvelopes.build(
                ids.next(),
                clock(),
                SessionOp.ERROR,
                SessionErrorData.serializer(),
                data,
            )
        return HandshakeOutcome.Rejected(code, closeCode, envelope)
    }

    private companion object {
        /** Câu chữ của `session/error.message` (CONN-01 API 6); không chứa dữ liệu của đối phương. */
        val ERROR_MESSAGES =
            mapOf(
                ErrorCode.AUTH_FAILED to "Không xác thực được thiết bị",
                ErrorCode.PAIR_UNKNOWN to "Thiết bị chưa được ghép nối",
                ErrorCode.PAIR_REVOKED to "Cặp ghép nối đã bị thu hồi",
                ErrorCode.UNSUPPORTED_VERSION to "Phiên bản giao thức không được hỗ trợ",
            )
    }
}
