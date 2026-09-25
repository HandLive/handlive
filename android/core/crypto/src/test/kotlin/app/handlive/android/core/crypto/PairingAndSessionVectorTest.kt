package app.handlive.android.core.crypto

import app.handlive.android.core.crypto.derivation.PairingKeyDerivation
import app.handlive.android.core.crypto.derivation.PeerRole
import app.handlive.android.core.crypto.derivation.SessionHandshakeDerivation
import app.handlive.android.core.crypto.derivation.SessionKeys
import app.handlive.android.core.crypto.derivation.SessionRekeyDerivation
import app.handlive.android.core.crypto.primitives.HmacSha256
import app.handlive.android.core.crypto.primitives.X25519Keys
import app.handlive.android.core.protocol.encoding.Base64Codecs
import app.handlive.android.core.protocol.envelope.PlaintextCodec
import app.handlive.android.core.protocol.session.SessionHelloData
import app.handlive.android.core.protocol.session.SessionWelcomeData
import app.handlive.android.core.protocol.testing.Hex
import app.handlive.android.core.protocol.testing.SharedTestVectors
import app.handlive.android.core.protocol.testing.bool
import app.handlive.android.core.protocol.testing.hex
import app.handlive.android.core.protocol.testing.str
import kotlinx.serialization.json.JsonObject
import org.junit.Assert.assertArrayEquals
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Test
import java.security.MessageDigest

/** pair-prk.json (0.6.2), session-handshake.json và session-rekey.json (0.6.3). */
class PairingAndSessionVectorTest {
    private fun sha256(bytes: ByteArray) = MessageDigest.getInstance("SHA-256").digest(bytes)

    @Test
    fun pairPrkVectorsFromBothSides() {
        val vectors = SharedTestVectors.vectors("pair-prk.json")
        for (v in vectors) {
            val name = v.str("name")
            val client = v.str("client_device_id")
            val android = v.str("android_device_id")
            assertArrayEquals(
                name,
                v.hex("dh_shared"),
                X25519Keys.sharedSecret(v.hex("client_ik_dh_priv"), v.hex("android_ik_dh_pub")),
            )
            assertArrayEquals(name, v.hex("salt_input"), PairingKeyDerivation.saltInput(client, android))
            assertArrayEquals(name, v.hex("salt"), PairingKeyDerivation.salt(android, client))
            assertEquals(
                name,
                v.bool("client_id_is_smaller"),
                v.hex("salt_input").copyOf(16).contentEquals(Hex.decode(client.replace("-", ""))),
            )
            assertEquals(name, v.str("info"), PairingKeyDerivation.INFO)
            val fromClient =
                PairingKeyDerivation.prk(
                    v.hex("client_ik_dh_priv"),
                    v.hex("android_ik_dh_pub"),
                    v.hex("pairing_secret"),
                    client,
                    android,
                )
            val fromAndroid =
                PairingKeyDerivation.prk(
                    v.hex("android_ik_dh_priv"),
                    v.hex("client_ik_dh_pub"),
                    v.hex("pairing_secret"),
                    android,
                    client,
                )
            assertArrayEquals(name, v.hex("prk"), fromClient)
            assertArrayEquals(name, v.hex("prk"), fromAndroid)
        }
        assertEquals(setOf(true, false), vectors.map { it.bool("client_id_is_smaller") }.toSet())
    }

    @Test
    fun sessionHandshakeVectors() {
        val vectors = SharedTestVectors.vectors("session-handshake.json")
        for (v in vectors) {
            checkHandshake(v)
            checkWireFields(v)
        }
        assertEquals(2, vectors.size)
    }

    private fun checkHandshake(v: JsonObject) {
        val name = v.str("name")
        val kAuth = SessionHandshakeDerivation.kAuth(v.hex("prk"))
        assertArrayEquals(name, v.hex("k_auth"), kAuth)
        assertArrayEquals(name, v.hex("client_eph_pub"), X25519Keys.publicFromPrivate(v.hex("client_eph_priv")))
        assertArrayEquals(name, v.hex("server_eph_pub"), X25519Keys.publicFromPrivate(v.hex("server_eph_priv")))
        val t1 =
            SessionHandshakeDerivation.t1(
                v.str("pair_id"),
                v.str("client_device_id"),
                v.hex("client_eph_pub"),
                v.hex("client_nonce"),
            )
        assertArrayEquals(name, v.hex("t1"), t1)
        assertEquals(SessionHandshakeDerivation.T1_SIZE, t1.size)
        assertArrayEquals(name, v.hex("hello_mac"), SessionHandshakeDerivation.mac(kAuth, t1))
        val t2 =
            SessionHandshakeDerivation.t2(
                t1,
                v.str("server_device_id"),
                v.hex("server_eph_pub"),
                v.hex("server_nonce"),
            )
        assertArrayEquals(name, v.hex("t2"), t2)
        assertEquals(SessionHandshakeDerivation.T2_SIZE, t2.size)
        assertArrayEquals(name, v.hex("welcome_mac"), SessionHandshakeDerivation.mac(kAuth, t2))
        assertArrayEquals(
            name,
            v.hex("eph_shared"),
            X25519Keys.sharedSecret(v.hex("client_eph_priv"), v.hex("server_eph_pub")),
        )
        assertArrayEquals(name, v.hex("secret_salt"), sha256(t2))
        val client =
            SessionHandshakeDerivation.sessionKeys(
                v.hex("client_eph_priv"),
                v.hex("server_eph_pub"),
                v.hex("prk"),
                t2,
            )
        val server =
            SessionHandshakeDerivation.sessionKeys(
                v.hex("server_eph_priv"),
                v.hex("client_eph_pub"),
                v.hex("prk"),
                t2,
            )
        assertArrayEquals(name, v.hex("secret"), client.secret)
        assertArrayEquals(name, v.hex("secret"), server.secret)
        assertArrayEquals(name, v.hex("k_c2s"), client.sendKey(PeerRole.CLIENT))
        assertArrayEquals(name, v.hex("k_c2s"), server.receiveKey(PeerRole.SERVER))
        assertArrayEquals(name, v.hex("k_s2c"), server.sendKey(PeerRole.SERVER))
    }

    /** Trường b64u trong plaintext trên wire khớp giá trị byte của vector. */
    private fun checkWireFields(v: JsonObject) {
        val name = v.str("name")
        val hello = PlaintextCodec.decodeOp(v.str("hello_plaintext").toByteArray(), SessionHelloData.serializer()).data
        assertArrayEquals(name, v.hex("client_eph_pub"), Base64Codecs.decodeB64u(hello.eph, 32))
        assertArrayEquals(name, v.hex("client_nonce"), Base64Codecs.decodeB64u(hello.nonce, 32))
        assertArrayEquals(name, v.hex("hello_mac"), Base64Codecs.decodeB64u(hello.mac, 32))
        val welcome =
            PlaintextCodec
                .decodeOp(
                    v.str("welcome_plaintext").toByteArray(),
                    SessionWelcomeData.serializer(),
                ).data
        assertArrayEquals(name, v.hex("server_eph_pub"), Base64Codecs.decodeB64u(welcome.eph, 32))
        assertArrayEquals(name, v.hex("server_nonce"), Base64Codecs.decodeB64u(welcome.nonce, 32))
        assertArrayEquals(name, v.hex("welcome_mac"), Base64Codecs.decodeB64u(welcome.mac, 32))
    }

    @Test
    fun sessionHandshakeInvalidMacsRejected() {
        val invalid = SharedTestVectors.invalidVectors("session-handshake.json")
        for (v in invalid) {
            assertFalse(v.str("name"), HmacSha256.verify(v.hex("key"), v.hex("message"), v.hex("mac")))
        }
        assertEquals(4, invalid.size)
    }

    @Test
    fun sessionRekeyVectors() {
        val vectors = SharedTestVectors.vectors("session-rekey.json")
        for (v in vectors) {
            val name = v.str("name")
            assertEquals(name, v.str("info"), SessionRekeyDerivation.INFO)
            val shared = X25519Keys.sharedSecret(v.hex("initiator_eph_priv"), v.hex("responder_eph_pub"))
            assertArrayEquals(name, v.hex("eph_shared"), shared)
            assertArrayEquals(name, v.hex("ikm"), shared + v.hex("secret_old"))
            assertArrayEquals(name, v.hex("salt"), sha256(v.hex("initiator_nonce") + v.hex("responder_nonce")))
            val previous = SessionKeys(v.hex("secret_old"))
            val initiator =
                SessionRekeyDerivation.rekey(
                    previous,
                    v.hex("initiator_eph_priv"),
                    v.hex("responder_eph_pub"),
                    v.hex("initiator_nonce"),
                    v.hex("responder_nonce"),
                )
            val responder =
                SessionRekeyDerivation.rekey(
                    previous,
                    v.hex("responder_eph_priv"),
                    v.hex("initiator_eph_pub"),
                    v.hex("initiator_nonce"),
                    v.hex("responder_nonce"),
                )
            assertArrayEquals(name, v.hex("secret_new"), initiator.secret)
            assertArrayEquals(name, v.hex("secret_new"), responder.secret)
            assertArrayEquals(name, v.hex("k_c2s"), initiator.kC2s)
            assertArrayEquals(name, v.hex("k_s2c"), initiator.kS2c)
        }
        // Epoch 2 nối từ epoch 1: secret_old của epoch 2 = secret_new của epoch 1.
        assertEquals(vectors[0].str("secret_new"), vectors[1].str("secret_old"))
    }
}
