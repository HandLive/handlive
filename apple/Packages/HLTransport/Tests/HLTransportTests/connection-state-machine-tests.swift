import Testing
@testable import HLTransport

@Suite("Máy trạng thái kết nối 0.11")
struct ConnectionStateMachineTests {
    struct Edge: Sendable, CustomTestStringConvertible {
        let from: ConnectionState
        let event: ConnectionEvent
        let to: ConnectionState
        var testDescription: String { "\(from) --\(event)--> \(to)" }
    }

    /// Đúng từng cạnh của lưu đồ 0.11.
    static let edges: [Edge] = [
        Edge(from: .idle, event: .pairedAndNetworkAvailable, to: .discovering),
        Edge(from: .discovering, event: .lanInstanceFound, to: .connectingLAN),
        Edge(from: .connectingLAN, event: .tlsPinVerified, to: .handshaking(.lan)),
        Edge(from: .connectingLAN, event: .tlsPinMismatch, to: .discovering),
        Edge(from: .handshaking(.lan), event: .handshakeSucceeded, to: .connected(.lan)),
        Edge(from: .handshaking(.relay), event: .handshakeSucceeded, to: .connected(.relay)),
        Edge(from: .handshaking(.lan), event: .handshakeFailed, to: .backoff),
        Edge(from: .discovering, event: .lanDiscoveryGraceElapsed(relayEnabled: true), to: .connectingRelay),
        Edge(from: .connectingRelay, event: .relayConnectedPeerOffline, to: .waitingPeer),
        Edge(from: .waitingPeer, event: .peerOnline, to: .handshaking(.relay)),
        Edge(from: .connectingRelay, event: .peerOnline, to: .handshaking(.relay)),
        Edge(from: .connected(.lan), event: .connectionLost, to: .backoff),
        Edge(from: .connected(.relay), event: .lanAvailable, to: .connectingLAN),
        Edge(from: .backoff, event: .backoffElapsed, to: .discovering),
        Edge(from: .backoff, event: .networkChanged, to: .discovering),
        Edge(from: .connected(.lan), event: .unpaired, to: .idle)
    ]

    @Test("Mọi cạnh của lưu đồ", arguments: edges)
    func edge(_ edge: Edge) {
        var machine = ConnectionStateMachine(state: edge.from)
        let changed = machine.handle(edge.event)
        #expect(changed)
        #expect(machine.state == edge.to)
    }

    @Test("Sự kiện không có cạnh bị bỏ qua, giữ nguyên trạng thái")
    func ignoredEvents() {
        let ignored: [(ConnectionState, ConnectionEvent)] = [
            (.idle, .handshakeSucceeded),
            (.discovering, .lanDiscoveryGraceElapsed(relayEnabled: false)),
            (.connected(.lan), .lanAvailable),
            (.waitingPeer, .connectionLost),
            (.backoff, .peerOnline)
        ]
        for (state, event) in ignored {
            var machine = ConnectionStateMachine(state: state)
            let changed = machine.handle(event)
            #expect(!changed)
            #expect(machine.state == state)
        }
    }

    @Test("Kịch bản: relay khi không thấy LAN, rồi nâng cấp lên LAN")
    func relayThenLanUpgrade() {
        var machine = ConnectionStateMachine()
        let events: [ConnectionEvent] = [
            .pairedAndNetworkAvailable, .lanDiscoveryGraceElapsed(relayEnabled: true), .relayConnectedPeerOffline,
            .peerOnline, .handshakeSucceeded, .lanAvailable, .tlsPinVerified, .handshakeSucceeded
        ]
        var statuses: [ConnectionStatus] = []
        for event in events {
            let changed = machine.handle(event)
            #expect(changed)
            statuses.append(ConnectionStatus(machine.state))
        }
        #expect(machine.state == .connected(.lan))
        #expect(statuses.contains(.phoneOffline))
        #expect(statuses.contains(.connected(.relay)))
    }

    @Test("Trạng thái hiển thị PAIR-02")
    func displayStatus() {
        #expect(ConnectionStatus(.idle).text == "Mất kết nối")
        #expect(ConnectionStatus(.backoff).text == "Mất kết nối")
        #expect(ConnectionStatus(.handshaking(.relay)).text == "Đang kết nối…")
        #expect(ConnectionStatus(.connectingRelay).text == "Đang kết nối…")
        #expect(ConnectionStatus(.waitingPeer).text == "Điện thoại ngoại tuyến")
        #expect(ConnectionStatus(.connected(.lan)).text == "Đã kết nối (LAN)")
        #expect(ConnectionStatus(.connected(.relay)).text == "Đã kết nối (qua Internet)")
    }

    @Test("RECONNECT_BACKOFF 0,5 → 30 s, jitter ±20 %, reset")
    func backoff() {
        var backoff = ReconnectBackoff()
        let delays = (0..<9).map { _ in backoff.nextDelay(unitRandom: 0) }
        #expect(delays == [0.5, 1, 2, 4, 8, 16, 30, 30, 30])
        let high = backoff.nextDelay(unitRandom: 1)
        let low = backoff.nextDelay(unitRandom: -1)
        #expect(high == 36)
        #expect(low == 24)
        backoff.reset()
        let first = backoff.nextDelay(unitRandom: 0)
        #expect(first == 0.5)
        for _ in 0..<50 {
            let delay = backoff.nextDelay()
            #expect(delay >= 0.4 && delay <= 36)
        }
    }
}
