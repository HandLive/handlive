import Foundation
import HLCrypto
import HLProtocol
import Testing
@testable import HLTransport

@Suite("Bắt tay phía client (0.6.3) theo session-handshake.json")
struct ClientSessionHandshakeTests {
    private func makeHandshake(_ vector: [String: Any]) throws -> ClientSessionHandshake {
        let context = PairContext(pairId: try vector.string("pair_id"),
                                  clientDeviceId: try vector.string("client_device_id"),
                                  serverDeviceId: try vector.string("server_device_id"), prk: try vector.hex("prk"))
        return try ClientSessionHandshake(context: context, ephemeralPrivateKey: try vector.hex("client_eph_priv"),
                                          nonce: try vector.hex("client_nonce"))
    }

    @Test("hello khớp vector, welcome của vector cho đúng k_c2s/k_s2c")
    func vectorHandshake() throws {
        for vector in try VectorFile("session-handshake.json").vectors {
            let handshake = try makeHandshake(vector)
            let expectedHello = try Envelope.parse(Data(try vector.string("hello_envelope").utf8))
            let hello = try handshake.helloEnvelope(id: expectedHello.id, ts: expectedHello.ts)
            #expect(hello.type == .session)
            #expect(try Payload.parse(hello.payloadBytes) == (try Payload.parse(expectedHello.payloadBytes)))

            let welcome = try Envelope.parse(Data(try vector.string("welcome_envelope").utf8))
            let keys = try handshake.handleResponse(welcome)
            #expect(Hex.encode(keys.clientToServer) == (try vector.string("k_c2s")))
            #expect(Hex.encode(keys.serverToClient) == (try vector.string("k_s2c")))
        }
    }

    @Test("welcome sai MAC → authFailed; sai device_id → deviceMismatch; session/error → rejected")
    func rejectsBadWelcome() throws {
        let vector = try VectorFile("session-handshake.json").vectors[0]
        let handshake = try makeHandshake(vector)
        let welcome = try Payload.parse(Envelope.parse(Data(try vector.string("welcome_envelope").utf8)).payloadBytes)
            .decodeData(as: SessionWelcomeData.self)

        let badMac = SessionWelcomeData(deviceId: welcome.deviceId, eph: welcome.eph, nonce: welcome.nonce,
                                        mac: Base64Coding.encodeB64u(Data(repeating: 0, count: 32)))
        #expect(throws: HandshakeFailure.authFailed) { try handshake.handleResponse(envelope(op: "welcome", badMac)) }

        let otherNonce = SessionWelcomeData(deviceId: welcome.deviceId, eph: welcome.eph,
                                            nonce: Base64Coding.encodeB64u(Data(repeating: 1, count: 32)), mac: welcome.mac)
        #expect(throws: HandshakeFailure.authFailed) { try handshake.handleResponse(envelope(op: "welcome", otherNonce)) }

        let otherDevice = SessionWelcomeData(deviceId: try vector.string("client_device_id"), eph: welcome.eph,
                                             nonce: welcome.nonce, mac: welcome.mac)
        #expect(throws: HandshakeFailure.deviceMismatch) {
            try handshake.handleResponse(envelope(op: "welcome", otherDevice))
        }

        let error = SessionErrorData(code: .pairRevoked, message: "Cặp đã bị thu hồi")
        #expect(throws: HandshakeFailure.rejected(error)) { try handshake.handleResponse(envelope(op: "error", error)) }

        let bye = SessionByeData(reason: .shutdown)
        #expect(throws: HandshakeFailure.unexpectedMessage) { try handshake.handleResponse(envelope(op: "bye", bye)) }
    }

    @Test("Khóa ngẫu nhiên: server mô phỏng trả welcome, hai phía cùng khóa, capability/hello mã hóa được")
    func randomHandshakeWithSimulatedServer() throws {
        let prk = Data(repeating: 0x42, count: 32)
        let context = PairContext(pairId: "3f2b1c4d-5e6f-4a7b-8c9d-0e1f2a3b4c5d",
                                  clientDeviceId: "21fe31df-a154-8261-a26b-f854046fd227",
                                  serverDeviceId: "39f713d0-a644-853f-8452-9421b9f51b9b", prk: prk)
        let client = try ClientSessionHandshake(context: context)
        let hello = try Payload.parse(client.helloEnvelope().payloadBytes).decodeData(as: SessionHelloData.self)

        // Phía server (Android) tính lại bằng HLCrypto.
        let kAuth = try SessionHandshakeCrypto.authKey(prk: prk)
        let t1 = try SessionHandshakeCrypto.helloTranscript(
            pairId: hello.pairId, clientDeviceId: hello.deviceId,
            clientEph: Base64Coding.decodeB64u(hello.eph), clientNonce: Base64Coding.decodeB64u(hello.nonce))
        #expect(HMACSHA256.verify(try Base64Coding.decodeB64u(hello.mac), key: kAuth, message: t1))
        let serverPriv = X25519.generatePrivateKey()
        let serverPub = try X25519.publicKey(privateKey: serverPriv)
        let serverNonce = SessionHandshakeCrypto.randomNonce()
        let t2 = try SessionHandshakeCrypto.welcomeTranscript(helloTranscript: t1, serverDeviceId: context.serverDeviceId,
                                                              serverEph: serverPub, serverNonce: serverNonce)
        let welcome = SessionWelcomeData(deviceId: context.serverDeviceId, eph: Base64Coding.encodeB64u(serverPub),
                                         nonce: Base64Coding.encodeB64u(serverNonce),
                                         mac: Base64Coding.encodeB64u(HMACSHA256.mac(key: kAuth, message: t2)))
        let serverShared = try X25519.sharedSecret(privateKey: serverPriv,
                                                   peerPublicKey: Base64Coding.decodeB64u(hello.eph))
        let serverKeys = try SessionHandshakeCrypto.sessionKeys(ephemeralShared: serverShared, prk: prk,
                                                                welcomeTranscript: t2)

        let clientKeys = try client.handleResponse(envelope(op: "welcome", welcome))
        #expect(clientKeys == serverKeys)

        let capability = CapabilityData(appVersion: "0.0.1 (1)", platform: .macos, osVersion: "13.0", model: "Mac",
                                        features: Features(clipboard: ClipboardFeature(enabled: true, autoSend: true)))
        let plaintext = try TypedPayload(op: CapabilityOp.hello.rawValue, data: capability).encoded()
        let sealed = try EnvelopeCipher.seal(type: .capability, plaintext: plaintext, key: clientKeys.clientToServer)
        #expect(try EnvelopeCipher.open(Envelope.parse(sealed.wireData()), key: serverKeys.clientToServer) == plaintext)
    }

    private func envelope<Body: Codable & Sendable & Equatable>(op: String, _ data: Body) throws -> Envelope {
        Envelope(type: .session, plainPayload: try TypedPayload(op: op, data: data).encoded())
    }
}
