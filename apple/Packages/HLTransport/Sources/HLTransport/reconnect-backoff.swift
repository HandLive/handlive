/// `RECONNECT_BACKOFF` (0.10): 0,5 → 1 → 2 → 4 → 8 → 16 → 30 s, jitter ±20 %; về 0 khi thành công.
public struct ReconnectBackoff: Sendable {
    public static let steps: [Double] = [0.5, 1, 2, 4, 8, 16, 30]
    public static let jitter = 0.2

    public private(set) var attempt = 0

    public init() {}

    /// Thời gian chờ (giây) cho lần thử kế tiếp. `unitRandom` ∈ [-1, 1] (tiêm được để test).
    public mutating func nextDelay(unitRandom: Double = Double.random(in: -1...1)) -> Double {
        let base = Self.steps[min(attempt, Self.steps.count - 1)]
        attempt += 1
        return base * (1 + Self.jitter * max(-1, min(1, unitRandom)))
    }

    public mutating func reset() {
        attempt = 0
    }
}
