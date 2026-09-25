[English](07-chuyen-dong.md) | Tiếng Việt

# Chuyển động và xúc giác

Chuyển động trong HandLive chỉ để báo việc đang diễn ra và chỉ ra chỗ vừa thay đổi; xúc giác chỉ xác
nhận kết quả quan trọng trên iPhone và Android. Mục này quy định spring, thời lượng, các chuyển động
được phép và cách tôn trọng Giảm chuyển động.

Nguồn HIG: https://developer.apple.com/design/human-interface-guidelines/motion ·
https://developer.apple.com/design/human-interface-guidelines/playing-haptics

## Nguyên tắc

- Có mục đích, không trang trí. Chuyển động không bao giờ là cách duy nhất để báo thông tin: luôn có
  chữ hoặc biểu tượng đi kèm.
- Không thêm chuyển động cho thao tác lặp nhiều lần, như gửi tin hay bật tắt trong danh sách.
- Không bắt người dùng chờ animation: thao tác tiếp theo được nhận ngay, animation bị cắt ngang.
- Phản hồi khớp cử chỉ: mở bằng vuốt lên thì đóng bằng vuốt xuống.
- Control hệ thống đã có chuyển động và tự theo Giảm chuyển động; ưu tiên control hệ thống.

## Spring trên Apple

| Kiểu | macOS 14+, iOS 17+ | macOS 13, iOS 16 | Dùng cho |
|---|---|---|---|
| Không nảy | `.smooth` | `.spring(response: 0.5, dampingFraction: 1)` | Sheet, `CallPanel`, đổi bố cục |
| Nhanh, nảy rất nhẹ | `.snappy` | `.spring(response: 0.5, dampingFraction: 0.85)` | Đổi trạng thái nhỏ trong view tự dựng |
| Nảy | `.bouncy` | — | Không dùng |

Liquid Glass tự có chuyển động (morph giữa các nút trong `GlassEffectContainer`, phản hồi chạm mạnh
hơn trackpad); không thêm hiệu ứng riêng lên kính.

## Thời lượng cho Android và web

| Token | Giá trị | Dùng cho | Compose |
|---|---|---|---|
| `duration-quick` | 150 ms | Nhấn, hover, đổi màu | `tween(150)` |
| `duration-standard` | 250 ms | Công tắc, segmented, đổi trạng thái | `tween(250)` |
| `duration-emphasized` | 400 ms | Sheet, panel, chuyển màn | `tween(400)` |
| `duration-pulse` | 1500 ms | Nhịp chấm Đang kết nối, Đang phát camera | `infiniteRepeatable(tween(1500), RepeatMode.Reverse)` |

- Khi không cần thời lượng cố định, dùng `spring(dampingRatio = Spring.DampingRatioNoBouncy)` cho
  gần cảm giác spring của Apple.
- Cử chỉ quay lại và predictive back là của Android: giữ nguyên, không tự dựng lại.

## Chuyển động HandLive dùng

| Chuyển động | Mô tả | Khi bật Giảm chuyển động |
|---|---|---|
| Nhịp Đang kết nối | Chấm `status-connecting` mờ rồi rõ theo `duration-pulse`; biểu tượng thanh menu chạy variable color. Dừng khi đã kết nối hoặc lỗi | Chấm và biểu tượng đứng yên, chữ "Đang kết nối…" giữ nguyên |
| Nhịp Đang phát camera | Chấm cạnh chữ "Đang phát" trên `CameraPreview`, cùng nhịp | Chấm đứng yên |
| Biểu tượng thanh menu | Gửi bảng nhớ tạm xong, biểu tượng chuyển sang `checkmark` bằng Magic Replace, giữ khoảng 1 giây rồi trở lại. Magic Replace là kiểu mặc định của Replace từ macOS 15; với hai symbol khác họ, hệ thống tự lùi về kiểu thay thường. Đổi giữa có và không `.slash` cũng dùng hiệu ứng này | Đổi ngay, không animation |
| Sheet, `CallPanel` xuất hiện | Sheet dùng chuyển động hệ thống. `CallPanel` trượt nhẹ vào từ góc trên bên phải và hiện dần, như thông báo | Chỉ hiện dần |
| Đổi trạng thái | Chấm và chữ trạng thái đổi trong `duration-standard` | Đổi ngay |

- Đổi symbol: SwiftUI `.contentTransition(.symbolEffect(.replace))`, AppKit
  `NSImageView.setSymbolImage(_:contentTransition:)` (macOS 14, iOS 17). macOS 14 chạy Replace
  thường; macOS 13 đổi ảnh ngay.
- Không dùng: chuyển động nền, parallax, pháo giấy, nhấp nháy, phóng theo chiều sâu, animate độ mờ
  (blur), animation lặp khi không có việc đang diễn ra.

## Giảm chuyển động

| Nền tảng | Đọc cài đặt |
|---|---|
| SwiftUI | `@Environment(\.accessibilityReduceMotion)` |
| UIKit | `UIAccessibility.isReduceMotionEnabled` |
| AppKit | `NSWorkspace.shared.accessibilityDisplayShouldReduceMotion` |
| Android | `Settings.Global.ANIMATOR_DURATION_SCALE` bằng 0 (người dùng tắt ảnh động trong Hỗ trợ tiếp cận) |

Khi bật, theo HIG: bỏ animation tự chạy và lặp lại; siết spring cho hết nảy; chuyển cảnh trượt hay
phóng thay bằng hiện dần; không animate độ mờ; chuyển động bám theo tay vẫn giữ. Trạng thái vẫn đổi
đầy đủ, chỉ bỏ phần chuyển động.

## Không tự đóng theo giờ

- `CallPanel` đóng khi cuộc gọi kết thúc, không theo giờ. `Alert`, `ConsentSheet` và mọi thông báo
  lỗi có nút chỉ đóng khi người dùng chọn.
- Chỉ báo xác nhận không có nút (`checkmark` trên thanh menu, `Feedback` dạng HUD "Đã gửi") được tự
  trở lại sau khoảng 1 giây (thanh menu) hoặc 1,5 giây (HUD), vì không chứa hành động và không phải
  nơi duy nhất có thông tin đó.
- Cần nút (Thử lại, Vẫn gửi) thì dùng thông báo hoặc dòng trạng thái, không dùng HUD tự ẩn.

## Xúc giác

| Sự kiện | iOS | Android API 30+ | Android API 29 |
|---|---|---|---|
| Thành công: gửi bảng nhớ tạm bằng `PasteButton`, ghép nối xong | `UINotificationFeedbackGenerator` `.success` | `HapticFeedbackConstants.CONFIRM` | `VIRTUAL_KEY` |
| Cần chú ý: chưa kết nối, sẽ gửi khi kết nối lại | `.warning` | Không rung | Không rung |
| Lỗi: gửi không thành công, mã PIN không đúng | `.error` | `HapticFeedbackConstants.REJECT` | `LONG_PRESS` |

- iOS 17+ có thể dùng `.sensoryFeedback(.success, trigger:)`; iOS 16 dùng
  `UINotificationFeedbackGenerator`, gọi `prepare()` trước.
- Android: `View.performHapticFeedback` tôn trọng cài đặt rung của hệ thống;
  `HapticFeedbackConstantsCompat` của AndroidX Core tự lùi về hằng số cũ trên API 29.
- macOS: HandLive không phát xúc giác; trackpad Force Touch dành cho phản hồi khi căn chỉnh, kéo
  thả.
- Xúc giác luôn đi cùng thay đổi nhìn thấy được. Không rung cho mỗi tin gửi đi. Không tự rung khi có
  cuộc gọi đến: thông báo của hệ thống lo chuông và rung.

## Nên và không nên

| Nên | Không nên |
|---|---|
| Nhịp chậm cho việc đang diễn ra | Nhấp nháy để gây chú ý |
| Hiện dần thay trượt khi bật Giảm chuyển động | Bỏ luôn việc đổi trạng thái |
| Rung một lần khi ghép nối xong | Rung cho mỗi thao tác |
| Đóng `CallPanel` khi cuộc gọi kết thúc | Tự đóng `CallPanel` sau vài giây |
