package app.handlive.android.core.transport.session

import app.handlive.android.core.crypto.derivation.PeerRole
import app.handlive.android.core.crypto.derivation.SessionKeys
import app.handlive.android.core.crypto.primitives.SecureRandomBytes
import app.handlive.android.core.protocol.ErrorCode
import app.handlive.android.core.protocol.ProtocolException
import app.handlive.android.core.protocol.envelope.EnvelopeHeader
import app.handlive.android.core.protocol.id.UuidV7Generator
import org.junit.Assert.assertArrayEquals
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNull
import org.junit.Assert.assertThrows
import org.junit.Assert.assertTrue
import org.junit.Test

/** Rekey hai vai trong bộ nhớ (0.6.3 bước 6, CONN-02 API 3): đổi khóa, va chạm, epoch sai, khóa cũ 30 s. */
class SessionRekeyCoordinatorTest {
    private val ids = UuidV7Generator()
    private val initial = SessionKeys(SecureRandomBytes.next(SessionKeys.SECRET_SIZE))
    private var now = 1_000_000L
    private val clientCipher = SessionCipher(initial, PeerRole.CLIENT, { now })
    private val serverCipher = SessionCipher(initial, PeerRole.SERVER, { now })
    private val client = SessionRekeyCoordinator(LOWER_ID, HIGHER_ID, clientCipher)
    private val server = SessionRekeyCoordinator(HIGHER_ID, LOWER_ID, serverCipher)

    @Test
    fun responderAndInitiatorDeriveSameEpochOneKeys() {
        val requestId = ids.next()
        val result = server.onRequest(client.start(requestId)) as RekeyRequestResult.Respond
        serverCipher.install(result.newKeys, result.epoch)
        assertTrue(client.onAck(requestId, result.ackData))
        assertEquals(1, clientCipher.epoch)
        assertEquals(1, serverCipher.epoch)
        assertArrayEquals(clientCipher.keys.secret, serverCipher.keys.secret)
        assertNull(client.pendingRequestId)
    }

    @Test
    fun onCollisionLowerDeviceIdWinsAndOtherSideAcks() {
        val clientRequest = client.start(ids.next())
        val serverRequest = server.start(ids.next())
        // Client có device_id nhỏ hơn: bỏ qua yêu cầu của server; server hủy yêu cầu của mình và trả ack.
        assertEquals(RekeyRequestResult.IgnoreCollision, client.onRequest(serverRequest))
        assertTrue(server.onRequest(clientRequest) is RekeyRequestResult.Respond)
        assertNull(server.pendingRequestId)
    }

    @Test
    fun requestWithWrongEpochIsInvalid() {
        val request = client.start(ids.next()).copy(epoch = 5)
        assertEquals(RekeyRequestResult.Invalid, server.onRequest(request))
    }

    @Test
    fun ackForUnknownRequestIsRejected() {
        val result = server.onRequest(client.start(ids.next())) as RekeyRequestResult.Respond
        assertFalse(client.onAck(ids.next(), result.ackData))
    }

    @Test
    fun previousReceiveKeyStaysValidForGraceThenExpires() {
        val inFlight = clientCipher.seal(EnvelopeHeader("clipboard", ids.next(), now), byteArrayOf(1))
        val requestId = ids.next()
        val result = server.onRequest(client.start(requestId)) as RekeyRequestResult.Respond
        serverCipher.install(result.newKeys, result.epoch)
        assertArrayEquals(byteArrayOf(1), serverCipher.open(inFlight))

        now += 30_001
        val error = assertThrows(ProtocolException::class.java) { serverCipher.open(inFlight) }
        assertEquals(ErrorCode.DECRYPT_FAILED, error.code)
    }

    @Test
    fun rekeyIsDueAfterEnvelopeCountOrAge() {
        val cipher = SessionCipher(initial, PeerRole.SERVER, { now }, rekeyAfterEnvelopes = 2)
        assertFalse(cipher.rekeyDue())
        repeat(2) { cipher.seal(EnvelopeHeader("ping", ids.next(), now), byteArrayOf()) }
        assertTrue(cipher.rekeyDue())

        val aged = SessionCipher(initial, PeerRole.SERVER, { now })
        now += 24 * 3_600_000L
        assertTrue(aged.rekeyDue())
    }

    private companion object {
        const val LOWER_ID = "0192f3c1-7c1e-8a55-9d0b-3f4c2a1b9e10"
        const val HIGHER_ID = "f192f3c1-7c1e-8a55-9d0b-3f4c2a1b9e10"
    }
}
