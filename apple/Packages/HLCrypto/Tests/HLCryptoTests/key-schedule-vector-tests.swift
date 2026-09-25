import Foundation
import HLProtocol
import Testing
@testable import HLCrypto

/// PRK (0.6.2), bắt tay phiên, rekey, K_stream và MAC HLSTREAM1 (0.6.3 bước 1–8).
@Suite("Vector lịch khóa phiên")
struct KeyScheduleVectorTests {
    @Test("PRK của cặp: tính từ phía client và phía Android đều khớp")
    func pairPRK() throws {
        for vector in try VectorFile("pair-prk.json").vectors {
            let clientId = try vector.string("client_device_id"), androidId = try vector.string("android_device_id")
            #expect(Hex.encode(try PairingKeyDerivation.salt(deviceIdA: clientId, deviceIdB: androidId))
                    == (try vector.string("salt")))
            let fromClient = try PairingKeyDerivation.prk(
                ownDHPrivateKey: try vector.hex("client_ik_dh_priv"), peerDHPublicKey: try vector.hex("android_ik_dh_pub"),
                pairingSecret: try vector.hex("pairing_secret"), ownDeviceId: clientId, peerDeviceId: androidId)
            let fromAndroid = try PairingKeyDerivation.prk(
                ownDHPrivateKey: try vector.hex("android_ik_dh_priv"), peerDHPublicKey: try vector.hex("client_ik_dh_pub"),
                pairingSecret: try vector.hex("pairing_secret"), ownDeviceId: androidId, peerDeviceId: clientId)
            #expect(Hex.encode(fromClient) == (try vector.string("prk")))
            #expect(fromAndroid == fromClient)
        }
    }

    @Test("Bắt tay: K_auth, T1, T2, MAC hello/welcome, secret, k_c2s, k_s2c")
    func sessionHandshake() throws {
        for vector in try VectorFile("session-handshake.json").vectors {
            let prk = try vector.hex("prk")
            let kAuth = try SessionHandshakeCrypto.authKey(prk: prk)
            #expect(Hex.encode(kAuth) == (try vector.string("k_auth")))
            let t1 = try SessionHandshakeCrypto.helloTranscript(
                pairId: try vector.string("pair_id"), clientDeviceId: try vector.string("client_device_id"),
                clientEph: try vector.hex("client_eph_pub"), clientNonce: try vector.hex("client_nonce"))
            #expect(t1.count == 106)
            #expect(Hex.encode(t1) == (try vector.string("t1")))
            #expect(Hex.encode(HMACSHA256.mac(key: kAuth, message: t1)) == (try vector.string("hello_mac")))
            let t2 = try SessionHandshakeCrypto.welcomeTranscript(
                helloTranscript: t1, serverDeviceId: try vector.string("server_device_id"),
                serverEph: try vector.hex("server_eph_pub"), serverNonce: try vector.hex("server_nonce"))
            #expect(t2.count == 198)
            #expect(Hex.encode(t2) == (try vector.string("t2")))
            #expect(HMACSHA256.verify(try vector.hex("welcome_mac"), key: kAuth, message: t2))
            #expect(Hex.encode(HMACSHA256.sha256(t2)) == (try vector.string("secret_salt")))

            let shared = try X25519.sharedSecret(privateKey: try vector.hex("client_eph_priv"),
                                                 peerPublicKey: try vector.hex("server_eph_pub"))
            #expect(Hex.encode(shared) == (try vector.string("eph_shared")))
            let keys = try SessionHandshakeCrypto.sessionKeys(ephemeralShared: shared, prk: prk, welcomeTranscript: t2)
            #expect(Hex.encode(keys.secret) == (try vector.string("secret")))
            #expect(Hex.encode(keys.clientToServer) == (try vector.string("k_c2s")))
            #expect(Hex.encode(keys.serverToClient) == (try vector.string("k_s2c")))
        }
    }

    @Test("MAC sai hoặc thông điệp bị sửa bị từ chối (session-handshake, stream-keys)",
          arguments: ["session-handshake.json", "stream-keys.json"])
    func invalidMacs(file: String) throws {
        let invalid = try VectorFile(file).invalidVectors
        #expect(!invalid.isEmpty)
        for vector in invalid {
            #expect(!HMACSHA256.verify(try vector.hex("mac"), key: try vector.hex("key"), message: try vector.hex("message")),
                    "\(vector.label)")
        }
    }

    @Test("Rekey epoch 1 (client khởi tạo) và epoch 2 (server khởi tạo), nối chuỗi")
    func rekey() throws {
        var previous: SessionKeys?
        for vector in try VectorFile("session-rekey.json").vectors {
            let old = try SessionKeys(secret: try vector.hex("secret_old"))
            if let previous { #expect(previous == old) }
            let shared = try X25519.sharedSecret(privateKey: try vector.hex("initiator_eph_priv"),
                                                 peerPublicKey: try vector.hex("responder_eph_pub"))
            #expect(Hex.encode(shared) == (try vector.string("eph_shared")))
            let next = try old.rekeyed(ephemeralShared: shared, initiatorNonce: try vector.hex("initiator_nonce"),
                                       responderNonce: try vector.hex("responder_nonce"))
            #expect(Hex.encode(next.secret) == (try vector.string("secret_new")))
            #expect(Hex.encode(next.clientToServer) == (try vector.string("k_c2s")))
            #expect(Hex.encode(next.serverToClient) == (try vector.string("k_s2c")))
            let request = try Payload.parse(Data(try vector.string("request_plaintext").utf8))
                .decodeData(as: SessionRekeyData.self)
            #expect(Int64(request.epoch) == (try vector.int("epoch")))
            #expect(try Base64Coding.decodeB64u(request.eph) == (try vector.hex("initiator_eph_pub")))
            previous = next
        }
    }

    @Test("K_stream, MAC HLSTREAM1 hello/welcome cho camera và call-audio")
    func streamKeys() throws {
        for vector in try VectorFile("stream-keys.json").vectors {
            let channel = try #require(StreamChannel(rawValue: try vector.string("channel")))
            let sessionId = try vector.string("session_id")
            #expect(StreamKeys.info(channel: channel, sessionId: sessionId) == (try vector.string("info")))
            let keys = try StreamKeys(handshakeSecret: try vector.hex("secret"), channel: channel, sessionId: sessionId)
            #expect(Hex.encode(keys.auth + keys.clientToServer + keys.serverToClient) == (try vector.string("k_stream")))
            let hello = try StreamKeys.helloMessage(sessionId: sessionId, clientNonce: try vector.hex("nonce_c"))
            #expect(Hex.encode(hello) == (try vector.string("hello_message")))
            #expect(Hex.encode(HMACSHA256.mac(key: keys.auth, message: hello)) == (try vector.string("hello_mac")))
            let welcome = try StreamKeys.welcomeMessage(sessionId: sessionId, clientNonce: try vector.hex("nonce_c"),
                                                        serverNonce: try vector.hex("nonce_s"))
            #expect(Hex.encode(welcome) == (try vector.string("welcome_message")))
            #expect(HMACSHA256.verify(try vector.hex("welcome_mac"), key: keys.auth, message: welcome))
        }
    }
}
