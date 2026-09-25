import SwiftUI

/// Chỉ báo liên kết giữa hai máy (`StatusIndicator/README.md`): biểu tượng tô màu trạng thái đi kèm chữ,
/// không bao giờ chỉ có chấm màu. VoiceOver đọc cả câu, ví dụ "Đã kết nối qua Wi-Fi với Pixel 8 của Lan".
public struct StatusIndicator: View {
    public enum Variant: Sendable {
        /// Biểu tượng màu + chữ `secondary-label`.
        case inline
        /// Viên cho đầu popover, cửa sổ: nền `tertiary-system-fill`, chữ `label`, nhãn ngắn.
        case pill
    }

    private let status: HLConnectionStatus
    private let deviceName: String?
    private let variant: Variant

    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.colorSchemeContrast) private var contrast
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.accessibilityDifferentiateWithoutColor) private var differentiateWithoutColor

    public init(_ status: HLConnectionStatus, deviceName: String? = nil, variant: Variant = .inline) {
        self.status = status
        self.deviceName = deviceName
        self.variant = variant
    }

    public var body: some View {
        HStack(spacing: variant == .pill ? HLSpacing.space4 : HLSpacing.space8) {
            indicator
            Text(variant == .pill ? status.shortText : status.text)
                .foregroundStyle(variant == .pill ? Color.primary : Color.secondary)
        }
        .padding(.horizontal, variant == .pill ? HLSpacing.space8 : 0)
        .padding(.vertical, variant == .pill ? HLSpacing.space4 : 0)
        .background {
            if variant == .pill { Capsule().fill(color(.tertiarySystemFill)) }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(status.accessibilityText(deviceName: deviceName)))
    }

    @ViewBuilder
    private var indicator: some View {
        let tint = color(status.colorToken)
        if differentiateWithoutColor {
            Image(systemName: status.differentiateWithoutColorSymbolName).foregroundStyle(tint)
        } else if let symbol = status.symbolName {
            Image(systemName: symbol).foregroundStyle(tint)
        } else if status.pulses && !reduceMotion {
            // Nhịp `duration-pulse` chỉ cho "Đang kết nối…" và "Đang phát camera"; Giảm chuyển động thì đứng yên.
            TimelineView(.animation(minimumInterval: 1.0 / 30)) { context in
                dot(tint).opacity(Self.pulseOpacity(at: context.date))
            }
        } else {
            dot(tint)
        }
    }

    private func dot(_ tint: Color) -> some View {
        Circle().fill(tint).frame(width: HLSpacing.space8, height: HLSpacing.space8)
    }

    /// Độ mờ dao động 1 → 0.35 → 1 trong một chu kỳ `HLDuration.pulse`.
    nonisolated static func pulseOpacity(at date: Date) -> Double {
        let phase = date.timeIntervalSinceReferenceDate.truncatingRemainder(dividingBy: HLDuration.pulse)
            / HLDuration.pulse
        return 0.35 + 0.65 * (0.5 + 0.5 * cos(2 * Double.pi * phase))
    }

    private func color(_ token: HLColorToken) -> Color {
        token.resolved(colorScheme: colorScheme, contrast: contrast)
    }
}

/// Mẫu xem trước: đủ các trạng thái trong README, cả dạng viên.
struct StatusIndicatorPreviewGallery: View {
    private let statuses: [HLConnectionStatus] = [
        .connectedWiFi, .connectedInternet, .usb, .connecting, .phoneOffline(lastSeen: "14:05"),
        .networkLost, .needsRepair, .cameraStreaming,
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: HLSpacing.space8) {
            ForEach(statuses, id: \.self) { StatusIndicator($0, deviceName: "Pixel 8 của Lan") }
            StatusIndicator(.connectedWiFi, deviceName: "Pixel 8 của Lan", variant: .pill)
        }
    }
}

#if !HL_COMMAND_LINE_TOOLS_ONLY
#Preview("Sáng") { StatusIndicatorPreviewGallery().hlPreviewAppearance(.light) }
#Preview("Tối") { StatusIndicatorPreviewGallery().hlPreviewAppearance(.dark) }
#Preview("Sáng · tương phản cao") { StatusIndicatorPreviewGallery().hlPreviewAppearance(.lightHighContrast) }
#Preview("Tối · tương phản cao") { StatusIndicatorPreviewGallery().hlPreviewAppearance(.darkHighContrast) }
#endif
