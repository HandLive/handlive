// Tệp sinh tự động bởi Scripts/generate-design-tokens.py từ shared/design-tokens/tokens.json.
// Không sửa tay: sửa tokens.json rồi chạy lại script (kiểm bằng --check).
import SwiftUI

/// Token màu của HandLive, mỗi token có đủ 4 giao diện.
public enum HLColorToken: String, CaseIterable, Sendable {
    /// Màu nhấn HandLive — xanh lá Mộc (Mộc sinh Hỏa). AccentColor của app: chữ liên kết, biểu tượng đang chọn, dấu chưa đọc. Chữ đạt 4.5:1 trên mọi nền hệ thống.
    case accent = "accent"
    /// Nền nút chính (prominent) và bong bóng tin mình gửi. Chữ trên nền này dùng on-accent (≥ 4.5:1).
    case accentFill = "accent-fill"
    /// Chữ và biểu tượng trên accent-fill.
    case onAccent = "on-accent"
    /// Nền nhạt cho vùng được chọn, huy hiệu trạng thái nhấn nhẹ. Không đặt chữ accent lên nền này ở cỡ dưới 13 pt.
    case accentTint = "accent-tint"
    /// Đỏ son — màu nhận diện (Hỏa, màu bản mệnh): chữ HandLive, biểu tượng app, màn chào. Không dùng cho nút hay trạng thái để khỏi lẫn với màu hủy/xóa.
    case brandFire = "brand-fire"
    /// Đỏ than — mảng màu sâu của thương hiệu (thay cho đen, vì Thủy khắc Hỏa). Dùng cho khối lớn ở bìa, lớp nền icon app.
    case brandEmber = "brand-ember"
    /// Cam lửa — điểm sáng trong gradient thương hiệu và minh họa. Không làm màu chữ.
    case brandFlame = "brand-flame"
    /// Hồng đào — nền nhạt của khoảnh khắc thương hiệu (màn chào, màn ghép nối) ở lớp nội dung.
    case brandGlow = "brand-glow"
    /// systemRed — Từ chối, Kết thúc, xóa, lỗi. Làm chữ nhỏ thì dùng text-red.
    case systemRed = "system-red"
    /// systemOrange — đang kết nối, cần chú ý. Làm chữ nhỏ thì dùng text-orange.
    case systemOrange = "system-orange"
    /// systemYellow — hiếm dùng (Hỏa sinh Thổ); chỉ cho cảnh báo nhẹ trong minh họa.
    case systemYellow = "system-yellow"
    /// systemGreen — đã kết nối, công tắc bật (mặc định của iOS). Làm chữ nhỏ thì dùng text-green.
    case systemGreen = "system-green"
    /// systemPink — màu Hỏa cho avatar chữ cái và minh họa.
    case systemPink = "system-pink"
    /// systemPurple — màu Hỏa cho avatar chữ cái và minh họa.
    case systemPurple = "system-purple"
    /// systemBrown — avatar chữ cái; dùng ít (Thổ).
    case systemBrown = "system-brown"
    /// systemGray — ngoại tuyến, biểu tượng phụ.
    case systemGray = "system-gray"
    /// systemGray2 — biểu tượng mờ, viền control phụ.
    case systemGray2 = "system-gray-2"
    /// systemGray3 — viền, rãnh thanh trượt.
    case systemGray3 = "system-gray-3"
    /// systemGray4 — nền nút tròn trung tính.
    case systemGray4 = "system-gray-4"
    /// systemGray5 — nền bong bóng tin đến, rãnh segmented.
    case systemGray5 = "system-gray-5"
    /// systemGray6 — nền nhóm, ô nhập.
    case systemGray6 = "system-gray-6"
    /// Chữ đỏ cỡ nhỏ: "Gửi lỗi", nút chữ Hủy ghép nối. Đậm hơn biến thể tương phản cao của systemRed để đạt 4.5:1 cả trên nền xám của cửa sổ Mac.
    case textRed = "text-red"
    /// Chữ cam cỡ nhỏ: lý do tính năng chưa dùng được, trạng thái cần chú ý.
    case textOrange = "text-orange"
    /// Chữ xanh lá cỡ nhỏ khi cần nói "Đã kết nối" bằng màu.
    case textGreen = "text-green"
    /// label / labelColor — chữ chính.
    case label = "label"
    /// secondaryLabel — chữ phụ. Bản web/Android đậm hơn giá trị gốc 60% của Apple để đạt 4.5:1 trên nền nhóm; trên Apple dùng .secondary.
    case secondaryLabel = "secondary-label"
    /// tertiaryLabel — chữ gợi ý, mục không khả dụng. Không dùng cho thông tin cần đọc.
    case tertiaryLabel = "tertiary-label"
    /// quaternaryLabel — dấu mờ, trang trí.
    case quaternaryLabel = "quaternary-label"
    /// placeholderText — chữ giữ chỗ trong ô nhập.
    case placeholderText = "placeholder-text"
    /// link — chữ liên kết (thay màu xanh dương mặc định của Apple bằng accent).
    case link = "link"
    /// separator — đường phân cách nhìn xuyên được.
    case separator = "separator"
    /// opaqueSeparator — đường phân cách đặc.
    case opaqueSeparator = "opaque-separator"
    /// systemBackground — nền màn hình iOS/Android.
    case systemBackground = "system-background"
    /// secondarySystemBackground — nền nhóm bên trong.
    case secondarySystemBackground = "secondary-system-background"
    /// tertiarySystemBackground — nền nhóm lồng trong nhóm.
    case tertiarySystemBackground = "tertiary-system-background"
    /// systemGroupedBackground — nền màn danh sách nhóm (Cài đặt).
    case systemGroupedBackground = "system-grouped-background"
    /// secondarySystemGroupedBackground — nền ô trong danh sách nhóm.
    case secondarySystemGroupedBackground = "secondary-system-grouped-background"
    /// tertiarySystemGroupedBackground — nền phần tử trong ô.
    case tertiarySystemGroupedBackground = "tertiary-system-grouped-background"
    /// systemFill — nền control mỏng (rãnh công tắc tắt).
    case systemFill = "system-fill"
    /// secondarySystemFill — nền control vừa.
    case secondarySystemFill = "secondary-system-fill"
    /// tertiarySystemFill — nền ô nhập, nút tròn trung tính.
    case tertiarySystemFill = "tertiary-system-fill"
    /// quaternarySystemFill — nền rất nhẹ cho vùng lớn.
    case quaternarySystemFill = "quaternary-system-fill"
    /// Mô phỏng NSColor.windowBackgroundColor trong preview; app Mac gọi API.
    case windowBackground = "window-background"
    /// Mô phỏng NSColor.controlBackgroundColor (nền danh sách, bảng) trong preview.
    case controlBackground = "control-background"
    /// Nền kính mô phỏng Liquid Glass regular. Tương phản cao: gần đục (giống Reduce Transparency).
    case glassFill = "glass-fill"
    /// Viền sáng của kính. Tương phản cao: viền đậm để tách khối.
    case glassStroke = "glass-stroke"
    /// Vệt sáng mép trên của kính (inset 1px).
    case glassHighlight = "glass-highlight"
    /// Lớp tối 35% dưới kính clear khi nội dung phía sau sáng (theo HIG Materials).
    case glassDim = "glass-dim"
    /// Lớp mờ phía sau sheet và alert.
    case scrim = "scrim"
    /// Chấm và biểu tượng "Đã kết nối".
    case statusConnected = "status-connected"
    /// Chấm và biểu tượng "Đang kết nối", "Cần chú ý".
    case statusConnecting = "status-connecting"
    /// Chấm và biểu tượng "Ngoại tuyến".
    case statusOffline = "status-offline"
    /// Chấm và biểu tượng lỗi, "Cần ghép nối lại".
    case statusError = "status-error"
    /// Nền nút Trả lời. Biểu tượng trắng đạt ≥ 3:1 (systemGreen gốc chỉ 2.2:1).
    case callAcceptFill = "call-accept-fill"
    /// Nền nút Từ chối, Kết thúc, nút phá hủy dạng đặc. Chữ trắng ≥ 4.5:1.
    case callDeclineFill = "call-decline-fill"
    /// Biểu tượng và chữ trên call-accept-fill, call-decline-fill.
    case onCallFill = "on-call-fill"
    /// Chữ của nút phá hủy dạng chữ (role destructive).
    case destructiveText = "destructive-text"
    /// Chấm chưa đọc trong danh sách hội thoại.
    case unread = "unread"
    /// Huy hiệu số trên tab và biểu tượng app (quy ước của Apple).
    case badge = "badge"
    /// Bong bóng SMS mình gửi (xanh lá như tin SMS của Apple, đậm hơn để chữ trắng đạt 4.5:1).
    case bubbleOutgoing = "bubble-outgoing"
    /// Chữ trong bong bóng mình gửi.
    case onBubbleOutgoing = "on-bubble-outgoing"
    /// Bong bóng tin đến.
    case bubbleIncoming = "bubble-incoming"
    /// Vòng focus bàn phím cho control tự dựng (control hệ thống giữ focus ring của hệ thống).
    case focusRing = "focus-ring"
    /// Điểm của mã QR — luôn đen trên trắng ở mọi giao diện.
    case qrInk = "qr-ink"
    /// Nền của mã QR.
    case qrPaper = "qr-paper"
    /// Nền khung camera và khung quét.
    case videoBackground = "video-background"
    /// Chữ và biểu tượng trên khung camera.
    case onVideo = "on-video"
    /// Chỉ dùng trong preview: nền màn hình Mac phía sau kính.
    case previewDesktop = "preview-desktop"

    /// Giá trị hex theo tokens.json cho Sáng, Tối, Sáng · tương phản cao, Tối · tương phản cao.
    public var palette: HLColorPalette {
        switch self {
        case .accent: return HLColorPalette(light: HLRGBA(0x19, 0x79, 0x34, 0xFF), dark: HLRGBA(0x3D, 0xDC, 0x6C, 0xFF), lightHighContrast: HLRGBA(0x14, 0x6B, 0x2E, 0xFF), darkHighContrast: HLRGBA(0x5B, 0xE5, 0x84, 0xFF))
        case .accentFill: return HLColorPalette(light: HLRGBA(0x19, 0x79, 0x34, 0xFF), dark: HLRGBA(0x23, 0x86, 0x36, 0xFF), lightHighContrast: HLRGBA(0x14, 0x6B, 0x2E, 0xFF), darkHighContrast: HLRGBA(0x19, 0x79, 0x34, 0xFF))
        case .onAccent: return HLColorPalette(light: HLRGBA(0xFF, 0xFF, 0xFF, 0xFF), dark: HLRGBA(0xFF, 0xFF, 0xFF, 0xFF), lightHighContrast: HLRGBA(0xFF, 0xFF, 0xFF, 0xFF), darkHighContrast: HLRGBA(0xFF, 0xFF, 0xFF, 0xFF))
        case .accentTint: return HLColorPalette(light: HLRGBA(0x19, 0x79, 0x34, 0x1F), dark: HLRGBA(0x3D, 0xDC, 0x6C, 0x29), lightHighContrast: HLRGBA(0x14, 0x6B, 0x2E, 0x2E), darkHighContrast: HLRGBA(0x5B, 0xE5, 0x84, 0x33))
        case .brandFire: return HLColorPalette(light: HLRGBA(0xD2, 0x38, 0x1F, 0xFF), dark: HLRGBA(0xFF, 0x6B, 0x4A, 0xFF), lightHighContrast: HLRGBA(0xB0, 0x2A, 0x14, 0xFF), darkHighContrast: HLRGBA(0xFF, 0x8A, 0x6E, 0xFF))
        case .brandEmber: return HLColorPalette(light: HLRGBA(0x8A, 0x22, 0x10, 0xFF), dark: HLRGBA(0xB4, 0x3A, 0x20, 0xFF), lightHighContrast: HLRGBA(0x6E, 0x1A, 0x0B, 0xFF), darkHighContrast: HLRGBA(0xC9, 0x47, 0x2B, 0xFF))
        case .brandFlame: return HLColorPalette(light: HLRGBA(0xF0, 0x7A, 0x1A, 0xFF), dark: HLRGBA(0xFF, 0x9A, 0x3D, 0xFF), lightHighContrast: HLRGBA(0xD8, 0x68, 0x0E, 0xFF), darkHighContrast: HLRGBA(0xFF, 0xAD, 0x5C, 0xFF))
        case .brandGlow: return HLColorPalette(light: HLRGBA(0xFD, 0xE9, 0xE2, 0xFF), dark: HLRGBA(0x3B, 0x1A, 0x12, 0xFF), lightHighContrast: HLRGBA(0xFB, 0xDC, 0xCF, 0xFF), darkHighContrast: HLRGBA(0x4A, 0x20, 0x16, 0xFF))
        case .systemRed: return HLColorPalette(light: HLRGBA(0xFF, 0x38, 0x3C, 0xFF), dark: HLRGBA(0xFF, 0x42, 0x45, 0xFF), lightHighContrast: HLRGBA(0xE9, 0x15, 0x2D, 0xFF), darkHighContrast: HLRGBA(0xFF, 0x61, 0x65, 0xFF))
        case .systemOrange: return HLColorPalette(light: HLRGBA(0xFF, 0x8D, 0x28, 0xFF), dark: HLRGBA(0xFF, 0x92, 0x30, 0xFF), lightHighContrast: HLRGBA(0xC5, 0x53, 0x00, 0xFF), darkHighContrast: HLRGBA(0xFF, 0xA0, 0x56, 0xFF))
        case .systemYellow: return HLColorPalette(light: HLRGBA(0xFF, 0xCC, 0x00, 0xFF), dark: HLRGBA(0xFF, 0xD6, 0x00, 0xFF), lightHighContrast: HLRGBA(0xA1, 0x6A, 0x00, 0xFF), darkHighContrast: HLRGBA(0xFE, 0xDF, 0x43, 0xFF))
        case .systemGreen: return HLColorPalette(light: HLRGBA(0x34, 0xC7, 0x59, 0xFF), dark: HLRGBA(0x30, 0xD1, 0x58, 0xFF), lightHighContrast: HLRGBA(0x00, 0x89, 0x32, 0xFF), darkHighContrast: HLRGBA(0x4A, 0xD9, 0x68, 0xFF))
        case .systemPink: return HLColorPalette(light: HLRGBA(0xFF, 0x2D, 0x55, 0xFF), dark: HLRGBA(0xFF, 0x37, 0x5F, 0xFF), lightHighContrast: HLRGBA(0xE7, 0x12, 0x4D, 0xFF), darkHighContrast: HLRGBA(0xFF, 0x8A, 0xC4, 0xFF))
        case .systemPurple: return HLColorPalette(light: HLRGBA(0xCB, 0x30, 0xE0, 0xFF), dark: HLRGBA(0xDB, 0x34, 0xF2, 0xFF), lightHighContrast: HLRGBA(0xB0, 0x2F, 0xC2, 0xFF), darkHighContrast: HLRGBA(0xEA, 0x8D, 0xFF, 0xFF))
        case .systemBrown: return HLColorPalette(light: HLRGBA(0xAC, 0x7F, 0x5E, 0xFF), dark: HLRGBA(0xB7, 0x8A, 0x66, 0xFF), lightHighContrast: HLRGBA(0x95, 0x6D, 0x51, 0xFF), darkHighContrast: HLRGBA(0xDB, 0xA6, 0x79, 0xFF))
        case .systemGray: return HLColorPalette(light: HLRGBA(0x8E, 0x8E, 0x93, 0xFF), dark: HLRGBA(0x8E, 0x8E, 0x93, 0xFF), lightHighContrast: HLRGBA(0x6C, 0x6C, 0x70, 0xFF), darkHighContrast: HLRGBA(0xAE, 0xAE, 0xB2, 0xFF))
        case .systemGray2: return HLColorPalette(light: HLRGBA(0xAE, 0xAE, 0xB2, 0xFF), dark: HLRGBA(0x63, 0x63, 0x66, 0xFF), lightHighContrast: HLRGBA(0x8E, 0x8E, 0x93, 0xFF), darkHighContrast: HLRGBA(0x7C, 0x7C, 0x80, 0xFF))
        case .systemGray3: return HLColorPalette(light: HLRGBA(0xC7, 0xC7, 0xCC, 0xFF), dark: HLRGBA(0x48, 0x48, 0x4A, 0xFF), lightHighContrast: HLRGBA(0xAE, 0xAE, 0xB2, 0xFF), darkHighContrast: HLRGBA(0x54, 0x54, 0x56, 0xFF))
        case .systemGray4: return HLColorPalette(light: HLRGBA(0xD1, 0xD1, 0xD6, 0xFF), dark: HLRGBA(0x3A, 0x3A, 0x3C, 0xFF), lightHighContrast: HLRGBA(0xBC, 0xBC, 0xC0, 0xFF), darkHighContrast: HLRGBA(0x44, 0x44, 0x46, 0xFF))
        case .systemGray5: return HLColorPalette(light: HLRGBA(0xE5, 0xE5, 0xEA, 0xFF), dark: HLRGBA(0x2C, 0x2C, 0x2E, 0xFF), lightHighContrast: HLRGBA(0xD8, 0xD8, 0xDC, 0xFF), darkHighContrast: HLRGBA(0x36, 0x36, 0x38, 0xFF))
        case .systemGray6: return HLColorPalette(light: HLRGBA(0xF2, 0xF2, 0xF7, 0xFF), dark: HLRGBA(0x1C, 0x1C, 0x1E, 0xFF), lightHighContrast: HLRGBA(0xEB, 0xEB, 0xF0, 0xFF), darkHighContrast: HLRGBA(0x24, 0x24, 0x26, 0xFF))
        case .textRed: return HLColorPalette(light: HLRGBA(0xD2, 0x13, 0x28, 0xFF), dark: HLRGBA(0xFF, 0x61, 0x65, 0xFF), lightHighContrast: HLRGBA(0xC4, 0x0E, 0x25, 0xFF), darkHighContrast: HLRGBA(0xFF, 0x8C, 0x8E, 0xFF))
        case .textOrange: return HLColorPalette(light: HLRGBA(0xAF, 0x4A, 0x00, 0xFF), dark: HLRGBA(0xFF, 0xA0, 0x56, 0xFF), lightHighContrast: HLRGBA(0xA3, 0x44, 0x00, 0xFF), darkHighContrast: HLRGBA(0xFF, 0xB9, 0x87, 0xFF))
        case .textGreen: return HLColorPalette(light: HLRGBA(0x00, 0x7A, 0x2C, 0xFF), dark: HLRGBA(0x4A, 0xD9, 0x68, 0xFF), lightHighContrast: HLRGBA(0x00, 0x6E, 0x28, 0xFF), darkHighContrast: HLRGBA(0x7A, 0xE4, 0x92, 0xFF))
        case .label: return HLColorPalette(light: HLRGBA(0x00, 0x00, 0x00, 0xFF), dark: HLRGBA(0xFF, 0xFF, 0xFF, 0xFF), lightHighContrast: HLRGBA(0x00, 0x00, 0x00, 0xFF), darkHighContrast: HLRGBA(0xFF, 0xFF, 0xFF, 0xFF))
        case .secondaryLabel: return HLColorPalette(light: HLRGBA(0x3C, 0x3C, 0x43, 0xBF), dark: HLRGBA(0xEB, 0xEB, 0xF5, 0x99), lightHighContrast: HLRGBA(0x3C, 0x3C, 0x43, 0xE0), darkHighContrast: HLRGBA(0xEB, 0xEB, 0xF5, 0xCC))
        case .tertiaryLabel: return HLColorPalette(light: HLRGBA(0x3C, 0x3C, 0x43, 0x4D), dark: HLRGBA(0xEB, 0xEB, 0xF5, 0x4D), lightHighContrast: HLRGBA(0x3C, 0x3C, 0x43, 0x80), darkHighContrast: HLRGBA(0xEB, 0xEB, 0xF5, 0x80))
        case .quaternaryLabel: return HLColorPalette(light: HLRGBA(0x3C, 0x3C, 0x43, 0x2E), dark: HLRGBA(0xEB, 0xEB, 0xF5, 0x2E), lightHighContrast: HLRGBA(0x3C, 0x3C, 0x43, 0x52), darkHighContrast: HLRGBA(0xEB, 0xEB, 0xF5, 0x52))
        case .placeholderText: return HLColorPalette(light: HLRGBA(0x3C, 0x3C, 0x43, 0x4D), dark: HLRGBA(0xEB, 0xEB, 0xF5, 0x4D), lightHighContrast: HLRGBA(0x3C, 0x3C, 0x43, 0x80), darkHighContrast: HLRGBA(0xEB, 0xEB, 0xF5, 0x80))
        case .link: return HLColorPalette(light: HLRGBA(0x19, 0x79, 0x34, 0xFF), dark: HLRGBA(0x3D, 0xDC, 0x6C, 0xFF), lightHighContrast: HLRGBA(0x14, 0x6B, 0x2E, 0xFF), darkHighContrast: HLRGBA(0x5B, 0xE5, 0x84, 0xFF))
        case .separator: return HLColorPalette(light: HLRGBA(0x3C, 0x3C, 0x43, 0x4A), dark: HLRGBA(0x54, 0x54, 0x58, 0x99), lightHighContrast: HLRGBA(0x3C, 0x3C, 0x43, 0x73), darkHighContrast: HLRGBA(0x54, 0x54, 0x58, 0xCC))
        case .opaqueSeparator: return HLColorPalette(light: HLRGBA(0xC6, 0xC6, 0xC8, 0xFF), dark: HLRGBA(0x38, 0x38, 0x3A, 0xFF), lightHighContrast: HLRGBA(0xA8, 0xA8, 0xAC, 0xFF), darkHighContrast: HLRGBA(0x5A, 0x5A, 0x5E, 0xFF))
        case .systemBackground: return HLColorPalette(light: HLRGBA(0xFF, 0xFF, 0xFF, 0xFF), dark: HLRGBA(0x00, 0x00, 0x00, 0xFF), lightHighContrast: HLRGBA(0xFF, 0xFF, 0xFF, 0xFF), darkHighContrast: HLRGBA(0x00, 0x00, 0x00, 0xFF))
        case .secondarySystemBackground: return HLColorPalette(light: HLRGBA(0xF2, 0xF2, 0xF7, 0xFF), dark: HLRGBA(0x1C, 0x1C, 0x1E, 0xFF), lightHighContrast: HLRGBA(0xEB, 0xEB, 0xF0, 0xFF), darkHighContrast: HLRGBA(0x24, 0x24, 0x26, 0xFF))
        case .tertiarySystemBackground: return HLColorPalette(light: HLRGBA(0xFF, 0xFF, 0xFF, 0xFF), dark: HLRGBA(0x2C, 0x2C, 0x2E, 0xFF), lightHighContrast: HLRGBA(0xFF, 0xFF, 0xFF, 0xFF), darkHighContrast: HLRGBA(0x36, 0x36, 0x38, 0xFF))
        case .systemGroupedBackground: return HLColorPalette(light: HLRGBA(0xF2, 0xF2, 0xF7, 0xFF), dark: HLRGBA(0x00, 0x00, 0x00, 0xFF), lightHighContrast: HLRGBA(0xEB, 0xEB, 0xF0, 0xFF), darkHighContrast: HLRGBA(0x00, 0x00, 0x00, 0xFF))
        case .secondarySystemGroupedBackground: return HLColorPalette(light: HLRGBA(0xFF, 0xFF, 0xFF, 0xFF), dark: HLRGBA(0x1C, 0x1C, 0x1E, 0xFF), lightHighContrast: HLRGBA(0xFF, 0xFF, 0xFF, 0xFF), darkHighContrast: HLRGBA(0x24, 0x24, 0x26, 0xFF))
        case .tertiarySystemGroupedBackground: return HLColorPalette(light: HLRGBA(0xF2, 0xF2, 0xF7, 0xFF), dark: HLRGBA(0x2C, 0x2C, 0x2E, 0xFF), lightHighContrast: HLRGBA(0xEB, 0xEB, 0xF0, 0xFF), darkHighContrast: HLRGBA(0x36, 0x36, 0x38, 0xFF))
        case .systemFill: return HLColorPalette(light: HLRGBA(0x78, 0x78, 0x80, 0x33), dark: HLRGBA(0x78, 0x78, 0x80, 0x5C), lightHighContrast: HLRGBA(0x78, 0x78, 0x80, 0x4D), darkHighContrast: HLRGBA(0x78, 0x78, 0x80, 0x80))
        case .secondarySystemFill: return HLColorPalette(light: HLRGBA(0x78, 0x78, 0x80, 0x29), dark: HLRGBA(0x78, 0x78, 0x80, 0x52), lightHighContrast: HLRGBA(0x78, 0x78, 0x80, 0x3D), darkHighContrast: HLRGBA(0x78, 0x78, 0x80, 0x70))
        case .tertiarySystemFill: return HLColorPalette(light: HLRGBA(0x76, 0x76, 0x80, 0x1F), dark: HLRGBA(0x76, 0x76, 0x80, 0x3D), lightHighContrast: HLRGBA(0x76, 0x76, 0x80, 0x2E), darkHighContrast: HLRGBA(0x76, 0x76, 0x80, 0x57))
        case .quaternarySystemFill: return HLColorPalette(light: HLRGBA(0x74, 0x74, 0x80, 0x14), dark: HLRGBA(0x76, 0x76, 0x80, 0x2E), lightHighContrast: HLRGBA(0x74, 0x74, 0x80, 0x1F), darkHighContrast: HLRGBA(0x76, 0x76, 0x80, 0x42))
        case .windowBackground: return HLColorPalette(light: HLRGBA(0xEC, 0xEC, 0xEC, 0xFF), dark: HLRGBA(0x28, 0x28, 0x28, 0xFF), lightHighContrast: HLRGBA(0xE3, 0xE3, 0xE3, 0xFF), darkHighContrast: HLRGBA(0x1C, 0x1C, 0x1C, 0xFF))
        case .controlBackground: return HLColorPalette(light: HLRGBA(0xFF, 0xFF, 0xFF, 0xFF), dark: HLRGBA(0x1E, 0x1E, 0x1E, 0xFF), lightHighContrast: HLRGBA(0xFF, 0xFF, 0xFF, 0xFF), darkHighContrast: HLRGBA(0x14, 0x14, 0x14, 0xFF))
        case .glassFill: return HLColorPalette(light: HLRGBA(0xFF, 0xFF, 0xFF, 0xB8), dark: HLRGBA(0x26, 0x26, 0x28, 0xB8), lightHighContrast: HLRGBA(0xFF, 0xFF, 0xFF, 0xEB), darkHighContrast: HLRGBA(0x1C, 0x1C, 0x1E, 0xEB))
        case .glassStroke: return HLColorPalette(light: HLRGBA(0xFF, 0xFF, 0xFF, 0x8C), dark: HLRGBA(0xFF, 0xFF, 0xFF, 0x24), lightHighContrast: HLRGBA(0x3C, 0x3C, 0x43, 0x59), darkHighContrast: HLRGBA(0xFF, 0xFF, 0xFF, 0x66))
        case .glassHighlight: return HLColorPalette(light: HLRGBA(0xFF, 0xFF, 0xFF, 0xD9), dark: HLRGBA(0xFF, 0xFF, 0xFF, 0x33), lightHighContrast: HLRGBA(0xFF, 0xFF, 0xFF, 0xD9), darkHighContrast: HLRGBA(0xFF, 0xFF, 0xFF, 0x4D))
        case .glassDim: return HLColorPalette(light: HLRGBA(0x00, 0x00, 0x00, 0x59), dark: HLRGBA(0x00, 0x00, 0x00, 0x59), lightHighContrast: HLRGBA(0x00, 0x00, 0x00, 0x59), darkHighContrast: HLRGBA(0x00, 0x00, 0x00, 0x59))
        case .scrim: return HLColorPalette(light: HLRGBA(0x00, 0x00, 0x00, 0x33), dark: HLRGBA(0x00, 0x00, 0x00, 0x7A), lightHighContrast: HLRGBA(0x00, 0x00, 0x00, 0x4D), darkHighContrast: HLRGBA(0x00, 0x00, 0x00, 0x99))
        case .statusConnected: return HLColorPalette(light: HLRGBA(0x34, 0xC7, 0x59, 0xFF), dark: HLRGBA(0x30, 0xD1, 0x58, 0xFF), lightHighContrast: HLRGBA(0x00, 0x89, 0x32, 0xFF), darkHighContrast: HLRGBA(0x4A, 0xD9, 0x68, 0xFF))
        case .statusConnecting: return HLColorPalette(light: HLRGBA(0xFF, 0x8D, 0x28, 0xFF), dark: HLRGBA(0xFF, 0x92, 0x30, 0xFF), lightHighContrast: HLRGBA(0xC5, 0x53, 0x00, 0xFF), darkHighContrast: HLRGBA(0xFF, 0xA0, 0x56, 0xFF))
        case .statusOffline: return HLColorPalette(light: HLRGBA(0x8E, 0x8E, 0x93, 0xFF), dark: HLRGBA(0x8E, 0x8E, 0x93, 0xFF), lightHighContrast: HLRGBA(0x6C, 0x6C, 0x70, 0xFF), darkHighContrast: HLRGBA(0xAE, 0xAE, 0xB2, 0xFF))
        case .statusError: return HLColorPalette(light: HLRGBA(0xFF, 0x38, 0x3C, 0xFF), dark: HLRGBA(0xFF, 0x42, 0x45, 0xFF), lightHighContrast: HLRGBA(0xE9, 0x15, 0x2D, 0xFF), darkHighContrast: HLRGBA(0xFF, 0x61, 0x65, 0xFF))
        case .callAcceptFill: return HLColorPalette(light: HLRGBA(0x1C, 0x94, 0x40, 0xFF), dark: HLRGBA(0x1F, 0x9D, 0x45, 0xFF), lightHighContrast: HLRGBA(0x00, 0x89, 0x32, 0xFF), darkHighContrast: HLRGBA(0x1A, 0x8F, 0x3C, 0xFF))
        case .callDeclineFill: return HLColorPalette(light: HLRGBA(0xE9, 0x15, 0x2D, 0xFF), dark: HLRGBA(0xD8, 0x18, 0x2D, 0xFF), lightHighContrast: HLRGBA(0xC4, 0x0E, 0x25, 0xFF), darkHighContrast: HLRGBA(0xD8, 0x18, 0x2D, 0xFF))
        case .onCallFill: return HLColorPalette(light: HLRGBA(0xFF, 0xFF, 0xFF, 0xFF), dark: HLRGBA(0xFF, 0xFF, 0xFF, 0xFF), lightHighContrast: HLRGBA(0xFF, 0xFF, 0xFF, 0xFF), darkHighContrast: HLRGBA(0xFF, 0xFF, 0xFF, 0xFF))
        case .destructiveText: return HLColorPalette(light: HLRGBA(0xD2, 0x13, 0x28, 0xFF), dark: HLRGBA(0xFF, 0x61, 0x65, 0xFF), lightHighContrast: HLRGBA(0xC4, 0x0E, 0x25, 0xFF), darkHighContrast: HLRGBA(0xFF, 0x8C, 0x8E, 0xFF))
        case .unread: return HLColorPalette(light: HLRGBA(0x19, 0x79, 0x34, 0xFF), dark: HLRGBA(0x3D, 0xDC, 0x6C, 0xFF), lightHighContrast: HLRGBA(0x14, 0x6B, 0x2E, 0xFF), darkHighContrast: HLRGBA(0x5B, 0xE5, 0x84, 0xFF))
        case .badge: return HLColorPalette(light: HLRGBA(0xFF, 0x38, 0x3C, 0xFF), dark: HLRGBA(0xFF, 0x42, 0x45, 0xFF), lightHighContrast: HLRGBA(0xE9, 0x15, 0x2D, 0xFF), darkHighContrast: HLRGBA(0xFF, 0x61, 0x65, 0xFF))
        case .bubbleOutgoing: return HLColorPalette(light: HLRGBA(0x19, 0x79, 0x34, 0xFF), dark: HLRGBA(0x23, 0x86, 0x36, 0xFF), lightHighContrast: HLRGBA(0x14, 0x6B, 0x2E, 0xFF), darkHighContrast: HLRGBA(0x19, 0x79, 0x34, 0xFF))
        case .onBubbleOutgoing: return HLColorPalette(light: HLRGBA(0xFF, 0xFF, 0xFF, 0xFF), dark: HLRGBA(0xFF, 0xFF, 0xFF, 0xFF), lightHighContrast: HLRGBA(0xFF, 0xFF, 0xFF, 0xFF), darkHighContrast: HLRGBA(0xFF, 0xFF, 0xFF, 0xFF))
        case .bubbleIncoming: return HLColorPalette(light: HLRGBA(0xE9, 0xE9, 0xEB, 0xFF), dark: HLRGBA(0x26, 0x26, 0x28, 0xFF), lightHighContrast: HLRGBA(0xDC, 0xDC, 0xE0, 0xFF), darkHighContrast: HLRGBA(0x30, 0x30, 0x34, 0xFF))
        case .focusRing: return HLColorPalette(light: HLRGBA(0x19, 0x79, 0x34, 0xFF), dark: HLRGBA(0x3D, 0xDC, 0x6C, 0xFF), lightHighContrast: HLRGBA(0x14, 0x6B, 0x2E, 0xFF), darkHighContrast: HLRGBA(0x5B, 0xE5, 0x84, 0xFF))
        case .qrInk: return HLColorPalette(light: HLRGBA(0x00, 0x00, 0x00, 0xFF), dark: HLRGBA(0x00, 0x00, 0x00, 0xFF), lightHighContrast: HLRGBA(0x00, 0x00, 0x00, 0xFF), darkHighContrast: HLRGBA(0x00, 0x00, 0x00, 0xFF))
        case .qrPaper: return HLColorPalette(light: HLRGBA(0xFF, 0xFF, 0xFF, 0xFF), dark: HLRGBA(0xFF, 0xFF, 0xFF, 0xFF), lightHighContrast: HLRGBA(0xFF, 0xFF, 0xFF, 0xFF), darkHighContrast: HLRGBA(0xFF, 0xFF, 0xFF, 0xFF))
        case .videoBackground: return HLColorPalette(light: HLRGBA(0x00, 0x00, 0x00, 0xFF), dark: HLRGBA(0x00, 0x00, 0x00, 0xFF), lightHighContrast: HLRGBA(0x00, 0x00, 0x00, 0xFF), darkHighContrast: HLRGBA(0x00, 0x00, 0x00, 0xFF))
        case .onVideo: return HLColorPalette(light: HLRGBA(0xFF, 0xFF, 0xFF, 0xFF), dark: HLRGBA(0xFF, 0xFF, 0xFF, 0xFF), lightHighContrast: HLRGBA(0xFF, 0xFF, 0xFF, 0xFF), darkHighContrast: HLRGBA(0xFF, 0xFF, 0xFF, 0xFF))
        case .previewDesktop: return HLColorPalette(light: HLRGBA(0xE9, 0xDD, 0xD6, 0xFF), dark: HLRGBA(0x1F, 0x17, 0x14, 0xFF), lightHighContrast: HLRGBA(0xE9, 0xDD, 0xD6, 0xFF), darkHighContrast: HLRGBA(0x1F, 0x17, 0x14, 0xFF))
        }
    }

    /// Màu hệ thống thay cho hex (01-mau-sac.md: không hard-code màu hệ thống trên Apple).
    public var systemColor: Color? {
        switch self {
        case .systemRed, .statusError, .badge: return Color.red
        case .systemOrange, .statusConnecting: return Color.orange
        case .systemYellow: return Color.yellow
        case .systemGreen, .statusConnected: return Color.green
        case .systemPink: return Color.pink
        case .systemPurple: return Color.purple
        case .systemBrown: return Color.brown
        case .systemGray, .statusOffline: return Color.gray
        case .label: return Color.primary
        case .secondaryLabel: return Color.secondary
        default: return nil
        }
    }
}
