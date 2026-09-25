# Vật liệu

HandLive dùng Liquid Glass cho lớp điều khiển nổi trên nội dung và vật liệu chuẩn cho lớp nội dung. Mục này nói kính dùng ở đâu, dự phòng thế nào cho bản hệ điều hành cũ và Android, và phản ứng ra sao với Giảm độ trong suốt.

Nguồn HIG: https://developer.apple.com/design/human-interface-guidelines/materials

## Hai lớp

| Lớp | Vật liệu | Thành phần HandLive |
|---|---|---|
| Lớp chức năng: điều khiển, điều hướng | Liquid Glass | `MenuBarMenu`, `CallPanel`, thanh tab iOS, nút nổi, `Feedback` dạng HUD |
| Lớp nội dung | Vật liệu chuẩn, nền hệ thống | `GroupedList`, `ThreadRow`, `MessageBubble`, `PairingCard`, `PasteCard`, `Onboarding`, `CameraPreview` |

- Không dùng Liquid Glass trong lớp nội dung. Ngoại lệ do hệ thống: thanh trượt, công tắc hóa kính khi đang kéo.
- Không chồng kính lên kính. Không đặt nền đặc hay bán trong suốt dưới control kính; để nội dung cuộn xuống dưới và dùng scroll edge effect kiểu `automatic`.
- Dùng tiết chế: control hệ thống tự có kính; chỉ tự áp kính cho control tự dựng quan trọng nhất.

## Liquid Glass: regular và clear

| Biến thể | Tính chất | HandLive dùng |
|---|---|---|
| `regular` | Làm mờ và chỉnh độ sáng nội dung phía sau để chữ luôn đọc được | Mặc định: `MenuBarMenu`, `CallPanel`, thanh tab, `Feedback` |
| `clear` | Rất trong, ưu tiên cho thấy nội dung phía sau | Chỉ nút nổi trên `CameraPreview` (đổi camera, tắt micro). Hình phía sau sáng thì thêm lớp tối 35% `glass-dim` |

- Tô màu kính: chỉ tô nền của một hành động chính (`.buttonStyle(.glassProminent)`, `Glass.tint(_:)`), không tô chữ hay biểu tượng. Nút Trả lời, Từ chối trên `CallPanel` là nền đặc mang nghĩa (`call-accept-fill`, `call-decline-fill`), không tính là kính tô màu.
- Kính nhỏ (thanh tab, nút nổi) tự chuyển sáng hoặc tối theo nội dung bên dưới; chữ và symbol trên kính đơn sắc.
- Gom các nút kính gần nhau vào `GlassEffectContainer` để hệ thống vẽ gộp và morph.

## Kính ở đâu, theo phiên bản

| Nơi | macOS 26+, iOS 26+ | macOS 13–15, iOS 16–18 | Android |
|---|---|---|---|
| `MenuBarMenu` | Menu hệ thống, tự có kính | Menu hệ thống, vật liệu `.menu` do hệ thống vẽ | Không có |
| `CallPanel` | `NSGlassEffectView` | `NSVisualEffectView` `.popover`, blending `.behindWindow` | Không có |
| Thanh tab iOS | `TabView` hệ thống | `TabView` hệ thống | Thanh tab nổi tự dựng |
| Nút nổi | `.buttonStyle(.glass)` hoặc `glassEffect(_:in:)` | `.regularMaterial` hình tròn | `glass-fill` + làm mờ |
| `Feedback` dạng HUD | `glassEffect(.regular, in:)` | macOS `NSVisualEffectView` `.hudWindow`; iOS `.regularMaterial` | `glass-fill` + làm mờ |
| Nút trên `CameraPreview` | `Glass.clear` + `glass-dim` | `.ultraThinMaterial` + `glass-dim` | `glass-dim` + `glass-stroke` |

Build bằng SDK 27: control hệ thống tự thành kính trên bản 26 trở lên; `UIDesignRequiresCompatibility` bị bỏ qua, không dùng để né Liquid Glass.

## Vật liệu chuẩn

- Chọn vật liệu theo mục đích, không theo màu nhìn thấy. Vật liệu dày cho chữ và chi tiết mảnh; vật liệu mỏng giữ ngữ cảnh phía sau.
- iOS, iPadOS: `.ultraThinMaterial`, `.thinMaterial`, `.regularMaterial` (mặc định), `.thickMaterial`.
- macOS: `NSVisualEffectView.Material` theo vai trò: `.menu`, `.popover`, `.hudWindow`, `.sidebar`, `.sheet`, `.windowBackground`, `.contentBackground`. Blending `.behindWindow` cho panel và HUD nổi trên màn hình; `.withinWindow` cho lớp bên trong cửa sổ.
- Chữ trên vật liệu dùng màu vibrant: SwiftUI `.foregroundStyle(.secondary)` tự có vibrancy; UIKit `UIVibrancyEffectStyle` từ `.label` đến `.quaternaryLabel`. Không dùng mức quaternary trên `.thinMaterial`, `.ultraThinMaterial`.
- Cửa sổ Mac không active thì mất vibrancy; chữ vẫn phải đọc được.

## Token kính cho Android và preview

Apple không dùng các token này; hệ thống tự vẽ kính, bóng và vệt sáng.

| Token | Sáng / Tối | Tương phản cao | Dùng cho |
|---|---|---|---|
| `glass-fill` | Trắng 72% / #262628 72% | Gần đục (92%) | Nền kính regular |
| `glass-stroke` | Trắng 55% / trắng 14% | Viền đậm hơn | Viền 1 px tách khối |
| `glass-highlight` | Trắng 85% / trắng 20% | Trắng 85% / trắng 30% | Vệt sáng mép trên, inset 1 px |
| `glass-dim` | Đen 35% | Như nhau | Lớp tối dưới kính clear khi hình sáng |
| `shadow-glass` | 0 8 24 và 0 1 3 | Đậm hơn | Bóng của kính nổi |

- Android API 31+: làm mờ lớp nội dung phía sau bằng `RenderEffect.createBlurEffect`, phủ `glass-fill`, viền `glass-stroke`, vệt `glass-highlight`, bóng `shadow-glass`.
- Android API 29–30 (chưa có `RenderEffect`): nền đục, tức `glass-fill` bỏ alpha, giữ viền và bóng.

## Giảm độ trong suốt và tương phản cao

- Apple: kính và vật liệu hệ thống tự thành gần đục khi bật Giảm độ trong suốt; Tăng độ tương phản làm viền rõ hơn. Từ bản 26, người dùng còn chọn kiểu kính ưa thích trong Cài đặt.
- Vật liệu tự dựng đọc `accessibilityReduceTransparency` (SwiftUI) hoặc `NSWorkspace.shared.accessibilityDisplayShouldReduceTransparency`, rồi dùng nền đục `secondary-system-background` (iOS) hoặc `window-background` (macOS).
- Android: bộ `-hc` làm `glass-fill` gần đục (92%), viền đậm; API 29–30 luôn đục.

## API

| Nền tảng | API |
|---|---|
| SwiftUI 26+ | `glassEffect(_:in:)`, `Glass` (`regular`, `clear`, `tint(_:)`, `interactive(_:)`), `GlassEffectContainer`, `.buttonStyle(.glass)`, `.buttonStyle(.glassProminent)` |
| AppKit 26+ | `NSGlassEffectView`, `NSButton.BezelStyle.glass` |
| UIKit 26+ | `UIGlassEffect`, `UIButton.Configuration.glass()`, `.prominentGlass()` |
| Bản cũ | SwiftUI `Material`; AppKit `NSVisualEffectView` |
| Android | `RenderEffect` (API 31+), token `glass-*`, `shadow-glass` |

## Nên và không nên

| Nên | Không nên |
|---|---|
| Kính cho menu, panel, thanh tab, nút nổi | Kính cho danh sách, bong bóng tin, thẻ ghép nối |
| `clear` chỉ trên hình camera | `clear` trên nền có chữ |
| Tô nền một nút chính trên kính | Tô chữ hoặc symbol trên kính |
| Nền đục khi bật Giảm độ trong suốt | Giữ lớp mờ khi người dùng đã giảm độ trong suốt |
