import Foundation
import Testing
@testable import HLDesignSystem

@Suite("StatusIndicator")
struct StatusIndicatorTests {
    @Test("Chữ lấy nguyên văn StatusIndicator/README.md")
    func textsMatchDocumentation() {
        #expect(HLConnectionStatus.connectedWiFi.text == "Đã kết nối qua Wi-Fi")
        #expect(HLConnectionStatus.connectedWiFi.shortText == "LAN")
        #expect(HLConnectionStatus.connectedInternet.text == "Đã kết nối qua Internet")
        #expect(HLConnectionStatus.usb.text == "Đang dùng USB")
        #expect(HLConnectionStatus.connecting.text == "Đang kết nối…")
        #expect(HLConnectionStatus.phoneOffline(lastSeen: "14:05").text == "Điện thoại ngoại tuyến · lần cuối 14:05")
        #expect(HLConnectionStatus.networkLost.text == "Mất kết nối")
        #expect(HLConnectionStatus.needsRepair.text == "Cần ghép nối lại")
        #expect(HLConnectionStatus.cameraStreaming.text == "Đang phát camera")
    }

    @Test("VoiceOver đọc câu đầy đủ kèm tên thiết bị")
    func accessibilityTextIncludesDevice() {
        #expect(HLConnectionStatus.connectedWiFi.accessibilityText(deviceName: "Pixel 8 của Lan")
            == "Đã kết nối qua Wi-Fi với Pixel 8 của Lan")
        #expect(HLConnectionStatus.networkLost.accessibilityText(deviceName: "Pixel 8 của Lan") == "Mất kết nối")
    }

    @Test("Ngoại tuyến là xám, đỏ chỉ khi phải làm gì đó; chỉ hai trạng thái nhấp nháy")
    func colorsAndPulse() {
        #expect(HLConnectionStatus.phoneOffline(lastSeen: nil).colorToken == .statusOffline)
        #expect(HLConnectionStatus.networkLost.colorToken == .statusOffline)
        #expect(HLConnectionStatus.needsRepair.colorToken == .statusError)
        #expect(HLConnectionStatus.connecting.colorToken == .statusConnecting)
        let pulsing: [HLConnectionStatus] = [.connecting, .cameraStreaming]
        #expect(pulsing.allSatisfy { $0.pulses })
        #expect(!HLConnectionStatus.connectedWiFi.pulses)
        let opacity = StatusIndicator.pulseOpacity(at: Date(timeIntervalSinceReferenceDate: 0))
        #expect(abs(opacity - 1) < 0.0001)
    }
}
