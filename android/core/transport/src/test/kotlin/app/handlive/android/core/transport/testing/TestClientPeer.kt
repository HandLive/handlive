package app.handlive.android.core.transport.testing

import app.handlive.android.core.crypto.derivation.PeerRole
import app.handlive.android.core.crypto.derivation.SessionHandshakeDerivation
import app.handlive.android.core.crypto.derivation.SessionKeys
import app.handlive.android.core.crypto.primitives.SecureRandomBytes
import app.handlive.android.core.crypto.primitives.X25519Keys
import app.handlive.android.core.protocol.encoding.Base64Codecs
import app.handlive.android.core.protocol.envelope.Envelope
import app.handlive.android.core.protocol.envelope.EnvelopeCodec
import app.handlive.android.core.protocol.envelope.EnvelopeHeader
import app.handlive.android.core.protocol.envelope.PlaintextCodec
import app.handlive.android.core.protocol.id.UuidV7Generator
import app.handlive.android.core.protocol.session.PROTOCOL_VERSION
import app.handlive.android.core.protocol.session.SessionHelloData
import app.handlive.android.core.protocol.session.SessionOp
import app.handlive.android.core.protocol.session.SessionWelcomeData
import app.handlive.android.core.transport.handshake.HandshakeEnvelopes
import app.handlive.android.core.transport.session.SessionCipher
import io.ktor.websocket.DefaultWebSocketSession
import io.ktor.websocket.Frame
import io.ktor.websocket.readText
import kotlinx.serialization.KSerializer
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue

/** Phía C của bắt tay `/v1/ctl` (0.6.3 bước 1, 3) cho test — Android thật không bao giờ đóng vai C. */
class TestClientPeer(
    val pairId: String,
    val deviceId: String,
    val prk: ByteArray,
    val serverDeviceId: String,
) {
    val ids = UuidV7Generator()

    class HelloState(
        val ephPrivate: ByteArray,
        val nonce: ByteArray,
        val t1: ByteArray,
    )

    /** Dựng `session/hello`; các tham số ghi đè để tạo hello sai cho test âm. */
    fun hello(
        protocol: Int = PROTOCOL_VERSION,
        helloPairId: String = pairId,
        helloDeviceId: String = deviceId,
        macKey: ByteArray = prk,
    ): Pair<String, HelloState> {
        val ephPrivate = X25519Keys.generatePrivateKey()
        val eph = X25519Keys.publicFromPrivate(ephPrivate)
        val nonce = SecureRandomBytes.next(NONCE_SIZE)
        val t1 = SessionHandshakeDerivation.t1(helloPairId, helloDeviceId, eph, nonce)
        val mac = SessionHandshakeDerivation.mac(SessionHandshakeDerivation.kAuth(macKey), t1)
        val data =
            SessionHelloData(
                protocol,
                helloPairId,
                helloDeviceId,
                Base64Codecs.encodeB64u(eph),
                Base64Codecs.encodeB64u(nonce),
                Base64Codecs.encodeB64u(mac),
            )
        val envelope =
            HandshakeEnvelopes.build(
                ids.next(),
                System.currentTimeMillis(),
                SessionOp.HELLO,
                SessionHelloData.serializer(),
                data,
            )
        return EnvelopeCodec.encode(envelope) to HelloState(ephPrivate, nonce, t1)
    }

    /** Kiểm `welcome` (mac, `device_id`) như M-APP (CONN-01 API 5) rồi dẫn ra khóa phiên. */
    fun acceptWelcome(
        welcomeText: String,
        state: HelloState,
    ): SessionKeys {
        val payload = HandshakeEnvelopes.read(EnvelopeCodec.decode(welcomeText), SessionWelcomeData.serializer())
        assertEquals(SessionOp.WELCOME, payload.op)
        val welcome = payload.data
        assertEquals(serverDeviceId, welcome.deviceId)
        val serverEph = Base64Codecs.decodeB64u(welcome.eph, X25519Keys.KEY_SIZE)
        val serverNonce = Base64Codecs.decodeB64u(welcome.nonce, NONCE_SIZE)
        val t2 = SessionHandshakeDerivation.t2(state.t1, welcome.deviceId, serverEph, serverNonce)
        val kAuth = SessionHandshakeDerivation.kAuth(prk)
        assertTrue(
            "welcome mac",
            SessionHandshakeDerivation.verifyMac(kAuth, t2, Base64Codecs.decodeB64u(welcome.mac, NONCE_SIZE)),
        )
        return SessionHandshakeDerivation.sessionKeys(state.ephPrivate, serverEph, prk, t2)
    }

    private companion object {
        const val NONCE_SIZE = 32
    }
}

/** Kênh đã bắt tay phía C: mã hóa bằng `k_c2s`, giải mã bằng `k_s2c`. */
class TestClientChannel(
    val socket: DefaultWebSocketSession,
    keys: SessionKeys,
    private val ids: UuidV7Generator,
) {
    val cipher = SessionCipher(keys, PeerRole.CLIENT)

    suspend fun <T> send(
        type: String,
        op: String,
        serializer: KSerializer<T>,
        data: T,
        id: String = ids.next(),
    ): String = sendPlaintext(type, PlaintextCodec.encodeOp(op, serializer, data), id)

    suspend fun sendPlaintext(
        type: String,
        plaintext: ByteArray,
        id: String = ids.next(),
    ): String {
        val envelope = cipher.seal(EnvelopeHeader(type, id, System.currentTimeMillis()), plaintext)
        socket.send(Frame.Text(EnvelopeCodec.encode(envelope)))
        return id
    }

    /** Envelope mã hóa kế tiếp từ S cùng plaintext đã giải mã. */
    suspend fun receive(): Pair<Envelope, ByteArray> {
        val envelope = EnvelopeCodec.decode((socket.incoming.receive() as Frame.Text).readText())
        return envelope to cipher.open(envelope)
    }
}
