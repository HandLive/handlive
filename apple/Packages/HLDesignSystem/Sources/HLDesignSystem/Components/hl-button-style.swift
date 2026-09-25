import SwiftUI

/// Kiểu nút theo `docs/design-system/components/Button/README.md`: dùng kiểu nút của hệ thống,
/// tô bằng token. Vai trò (chính, hủy, phá hủy) đặt trên `Button(role:)` và `.keyboardShortcut`.
public enum HLButtonStyle: Sendable, CaseIterable {
    /// Hành động chính của màn, tối đa một: `.borderedProminent` (từ 26: `.glassProminent`), `accent-fill`.
    case prominent
    /// Hành động phụ cạnh nút chính: `.bordered` (từ 26: `.glass`).
    case glass
    /// Nên thấy nhưng không phải chính ("Mở cài đặt"): `.bordered` + `.tint(.accentColor)`.
    case tinted
    /// Liên kết, lệnh phụ trong câu: `.borderless`, màu nhấn.
    case plain
    /// Hủy ghép nối, xóa lịch sử: `.bordered`, chữ `destructive-text`. Gọi kèm `Button(role: .destructive)`.
    case destructive
}

extension View {
    /// `Button("Ghép nối") { … }.hlButtonStyle(.prominent)`.
    public func hlButtonStyle(_ style: HLButtonStyle) -> some View {
        modifier(HLButtonStyleModifier(style: style))
    }
}

private struct HLButtonStyleModifier: ViewModifier {
    let style: HLButtonStyle
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.colorSchemeContrast) private var contrast

    func body(content: Content) -> some View {
        styled(content).platformSizing(prominent: style == .prominent)
    }

    @ViewBuilder
    private func styled(_ content: Content) -> some View {
        switch style {
        case .prominent:
            #if os(macOS)
            // macOS: nút chính theo Màu nhấn người dùng chọn (01-mau-sac.md: không ép xanh lá);
            // khi người dùng để "Nhiều màu", hệ thống lấy AccentColor = accent.
            prominentBase(content)
            #else
            prominentBase(content).tint(token(.accentFill))
            #endif
        case .glass:
            glassBase(content)
        case .tinted:
            content.buttonStyle(.bordered).tint(.accentColor)
        case .plain:
            content.buttonStyle(.borderless).foregroundStyle(Color.accentColor)
        case .destructive:
            content.buttonStyle(.bordered).foregroundStyle(token(.destructiveText))
        }
    }

    @ViewBuilder
    private func prominentBase(_ content: Content) -> some View {
        #if compiler(>=6.2)
        if #available(macOS 26, iOS 26, *) {
            content.buttonStyle(.glassProminent)
        } else {
            content.buttonStyle(.borderedProminent)
        }
        #else
        content.buttonStyle(.borderedProminent)
        #endif
    }

    @ViewBuilder
    private func glassBase(_ content: Content) -> some View {
        #if compiler(>=6.2)
        if #available(macOS 26, iOS 26, *) {
            content.buttonStyle(.glass)
        } else {
            content.buttonStyle(.bordered)
        }
        #else
        content.buttonStyle(.bordered)
        #endif
    }

    private func token(_ token: HLColorToken) -> Color {
        token.resolved(colorScheme: colorScheme, contrast: contrast)
    }
}

private extension View {
    /// iOS/iPadOS: capsule, nút chính `.large` (cao 50 pt). macOS giữ `.regular` của form và sheet;
    /// nút cuối cửa sổ chào tự đặt `.controlSize(.large)`.
    @ViewBuilder
    func platformSizing(prominent: Bool) -> some View {
        #if os(iOS)
        buttonBorderShape(.capsule).controlSize(prominent ? .large : .regular)
        #else
        self
        #endif
    }
}

/// Mẫu xem trước: nhãn lấy nguyên văn từ Button/README.md.
struct HLButtonStylePreviewGallery: View {
    var body: some View {
        VStack(alignment: .leading, spacing: HLSpacing.space12) {
            Button("Ghép nối") {}.hlButtonStyle(.prominent)
            Button("Cài đặt…") {}.hlButtonStyle(.glass)
            Button("Mở cài đặt") {}.hlButtonStyle(.tinted)
            Button("Gửi bảng nhớ tạm") {}.hlButtonStyle(.plain)
            Button("Hủy ghép nối", role: .destructive) {}.hlButtonStyle(.destructive)
            // Đang xử lý: đổi nhãn sang tiến trình, kèm ProgressView nhỏ, không đổi cỡ nút.
            Button {} label: {
                HStack(spacing: HLSpacing.space8) {
                    ProgressView().controlSize(.small)
                    Text("Đang ghép nối…")
                }
            }
            .hlButtonStyle(.prominent)
        }
    }
}

#if !HL_COMMAND_LINE_TOOLS_ONLY
#Preview("Sáng") { HLButtonStylePreviewGallery().hlPreviewAppearance(.light) }
#Preview("Tối") { HLButtonStylePreviewGallery().hlPreviewAppearance(.dark) }
#Preview("Sáng · tương phản cao") { HLButtonStylePreviewGallery().hlPreviewAppearance(.lightHighContrast) }
#Preview("Tối · tương phản cao") { HLButtonStylePreviewGallery().hlPreviewAppearance(.darkHighContrast) }
#endif
