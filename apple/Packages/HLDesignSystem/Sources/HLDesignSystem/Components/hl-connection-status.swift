import Foundation

/// Trạng thái liên kết giữa hai máy, theo bảng của `StatusIndicator/README.md` (chữ lấy nguyên văn).
public enum HLConnectionStatus: Hashable, Sendable {
    case connectedWiFi
    case connectedInternet
    case usb
    case connecting
    /// Điện thoại ngoại tuyến; `lastSeen` là giờ đã định dạng theo locale, ví dụ "14:05".
    case phoneOffline(lastSeen: String?)
    case networkLost
    case needsRepair
    case cameraStreaming

    /// Chữ hiển thị đầy đủ.
    public var text: String {
        switch self {
        case .connectedWiFi: "Đã kết nối qua Wi-Fi"
        case .connectedInternet: "Đã kết nối qua Internet"
        case .usb: "Đang dùng USB"
        case .connecting: "Đang kết nối…"
        case .phoneOffline(let lastSeen?): "Điện thoại ngoại tuyến · lần cuối \(lastSeen)"
        case .phoneOffline(nil): "Điện thoại ngoại tuyến"
        case .networkLost: "Mất kết nối"
        case .needsRepair: "Cần ghép nối lại"
        case .cameraStreaming: "Đang phát camera"
        }
    }

    /// Nhãn ngắn cho dạng viên: chỉ Wi-Fi có nhãn ngắn "LAN".
    public var shortText: String {
        self == .connectedWiFi ? "LAN" : text
    }

    /// Câu VoiceOver đọc: "Đã kết nối qua Wi-Fi với Pixel 8 của Lan".
    public func accessibilityText(deviceName: String?) -> String {
        guard let deviceName, !deviceName.isEmpty else { return text }
        switch self {
        case .connectedWiFi, .connectedInternet, .usb: return "\(text) với \(deviceName)"
        default: return text
        }
    }

    /// SF Symbol; `nil` khi trạng thái dùng chấm nhấp nháy.
    public var symbolName: String? {
        switch self {
        case .connectedWiFi: "wifi"
        case .connectedInternet: "globe"
        case .usb: "cable.connector"
        case .phoneOffline: "antenna.radiowaves.left.and.right.slash"
        case .networkLost: "wifi.slash"
        case .needsRepair: "exclamationmark.triangle.fill"
        case .connecting, .cameraStreaming: nil
        }
    }

    /// Biểu tượng có hình thay chấm khi bật Phân biệt không dùng màu (01-mau-sac.md).
    public var differentiateWithoutColorSymbolName: String {
        switch self {
        case .connecting: "ellipsis.circle.fill"
        case .cameraStreaming: "record.circle"
        default: symbolName ?? "circle.fill"
        }
    }

    /// Chấm nhấp nháy (tắt khi bật Giảm chuyển động).
    public var pulses: Bool { self == .connecting || self == .cameraStreaming }

    public var colorToken: HLColorToken {
        switch self {
        case .connectedWiFi, .connectedInternet, .usb, .cameraStreaming: .statusConnected
        case .connecting: .statusConnecting
        case .phoneOffline, .networkLost: .statusOffline
        case .needsRepair: .statusError
        }
    }
}
