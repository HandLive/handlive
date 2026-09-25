/// Máy trạng thái kết nối của client Mac/iOS (00-common-specs 0.11). Chỉ logic, không mạng:
/// lớp mạng (Phase 1) phát `ConnectionEvent`, máy trạng thái quyết định chuyển trạng thái.
public enum ConnectionRoute: Equatable, Sendable {
    case lan
    case relay
}

public enum ConnectionState: Equatable, Sendable {
    case idle
    case discovering
    case connectingLAN
    case connectingRelay
    case waitingPeer
    case handshaking(ConnectionRoute)
    case connected(ConnectionRoute)
    case backoff
}

/// Sự kiện ứng với nhãn cạnh trong lưu đồ 0.11.
public enum ConnectionEvent: Equatable, Sendable {
    /// Có ≥ 1 cặp và có mạng.
    case pairedAndNetworkAvailable
    /// Thấy instance mDNS có hint khớp.
    case lanInstanceFound
    /// TLS OK và ghim chứng chỉ khớp.
    case tlsPinVerified
    /// `TLS_PIN_MISMATCH`: bỏ instance, tìm tiếp.
    case tlsPinMismatch
    /// `welcome` hợp lệ + đã trao `capability`.
    case handshakeSucceeded
    /// Lỗi bắt tay hoặc đóng 4408.
    case handshakeFailed
    /// Quá `LAN_DISCOVERY_GRACE`; chỉ sang relay khi `relay.enabled`.
    case lanDiscoveryGraceElapsed(relayEnabled: Bool)
    /// Relay OK nhưng đối phương offline.
    case relayConnectedPeerOffline
    /// `presence` online.
    case peerOnline
    case connectionLost
    /// Đang qua relay và thấy LAN (nâng cấp).
    case lanAvailable
    case backoffElapsed
    case networkChanged
    /// Hủy ghép nối.
    case unpaired
}

public struct ConnectionStateMachine: Sendable {
    public private(set) var state: ConnectionState

    public init(state: ConnectionState = .idle) {
        self.state = state
    }

    /// Áp sự kiện; trả `true` nếu chuyển trạng thái. Sự kiện không có cạnh trong 0.11 bị bỏ qua.
    @discardableResult
    public mutating func handle(_ event: ConnectionEvent) -> Bool {
        guard let next = Self.transition(from: state, on: event) else { return false }
        state = next
        return true
    }

    // swiftlint:disable:next cyclomatic_complexity
    public static func transition(from state: ConnectionState, on event: ConnectionEvent) -> ConnectionState? {
        switch (state, event) {
        case (.idle, .pairedAndNetworkAvailable): return .discovering
        case (.discovering, .lanInstanceFound): return .connectingLAN
        case (.discovering, .lanDiscoveryGraceElapsed(relayEnabled: true)): return .connectingRelay
        case (.connectingLAN, .tlsPinVerified): return .handshaking(.lan)
        case (.connectingLAN, .tlsPinMismatch): return .discovering
        case (.connectingRelay, .relayConnectedPeerOffline): return .waitingPeer
        case (.connectingRelay, .peerOnline), (.waitingPeer, .peerOnline): return .handshaking(.relay)
        case (.handshaking(let route), .handshakeSucceeded): return .connected(route)
        case (.handshaking, .handshakeFailed): return .backoff
        case (.connected, .connectionLost): return .backoff
        case (.connected(.relay), .lanAvailable): return .connectingLAN
        case (.connected, .unpaired): return .idle
        case (.backoff, .backoffElapsed), (.backoff, .networkChanged): return .discovering
        default: return nil
        }
    }
}

/// Trạng thái hiển thị cho người dùng (PAIR-02, 0.11).
public enum ConnectionStatus: Equatable, Sendable {
    case disconnected
    case connecting
    case phoneOffline
    case connected(ConnectionRoute)

    public init(_ state: ConnectionState) {
        switch state {
        case .idle, .backoff: self = .disconnected
        case .discovering, .connectingLAN, .connectingRelay, .handshaking: self = .connecting
        case .waitingPeer: self = .phoneOffline
        case .connected(let route): self = .connected(route)
        }
    }

    /// Câu chữ theo 0.11.
    public var text: String {
        switch self {
        case .disconnected: return "Mất kết nối"
        case .connecting: return "Đang kết nối…"
        case .phoneOffline: return "Điện thoại ngoại tuyến"
        case .connected(.lan): return "Đã kết nối (LAN)"
        case .connected(.relay): return "Đã kết nối (qua Internet)"
        }
    }
}
