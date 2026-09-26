[English](02-ios-ipados.md) | Tiếng Việt

# iOS và iPadOS

HandLive trên iPhone và iPad nhận bảng nhớ tạm, tin nhắn và thông tin cuộc gọi từ điện thoại
Android; không nghe gọi. Mục này quy định thanh tab, danh sách, sheet, cách gửi bảng nhớ tạm, thông
báo, iPad, iPhone Duo, giới hạn chạy nền và bản dự phòng cho iOS 16.

Nguồn HIG: https://developer.apple.com/design/human-interface-guidelines/designing-for-ios ·
https://developer.apple.com/design/human-interface-guidelines/designing-for-ipados ·
https://developer.apple.com/design/human-interface-guidelines/tab-bars ·
https://developer.apple.com/design/human-interface-guidelines/sheets ·
https://developer.apple.com/design/human-interface-guidelines/designing-for-iphone-duo

## Thanh tab

| Tab | SF Symbol | Nội dung | Huy hiệu |
|---|---|---|---|
| Bảng nhớ tạm | `doc.on.clipboard.fill` | `PasteCard` | — |
| Tin nhắn | `message.fill` | `ThreadRow`, lọc "Tất cả / Chưa đọc" | Số hội thoại chưa đọc |
| Cuộc gọi | `phone.fill` | Nhật ký CALL-04 | Cuộc gọi nhỡ chưa xem |
| Cài đặt | `gearshape.fill` | `GroupedList` (mục Cài đặt) | — |

- iOS 26+: thanh tab kính nổi ở đáy, của hệ thống; không tự vẽ nền dưới thanh. iOS 16–17: `TabView`
  với `.tabItem`; iOS 18+: `Tab`.
- Biểu tượng bản đặc, tab đang chọn màu `accent`, huy hiệu màu `badge`.
- Thanh tab chỉ để điều hướng; hành động như "Tin nhắn mới" (`square.and.pencil`) nằm trên toolbar.
- Không ẩn, không vô hiệu tab khi tính năng tắt hay chưa ghép nối; tab nói lý do và bước tiếp theo
  ngay trong nội dung.

## Màn và danh sách

- Màn gốc của mỗi tab có large title ("Bảng nhớ tạm", "Tin nhắn", "Cuộc gọi", "Cài đặt"), co lại khi
  cuộn (`NavigationStack`). Tiêu đề điều hướng dùng font hệ thống; Be Vietnam Pro chỉ cho tiêu đề
  thương hiệu (màn chào, ghép nối, trạng thái trống).
- Cài đặt: `List` `.insetGrouped`; trên iOS 16–18 đặt `.textCase(nil)` cho header để tiếng Việt
  không bị viết hoa toàn bộ. Tin nhắn và Cuộc gọi: `List` thường.
- Tìm trong Tin nhắn bằng `searchable` ngay trên danh sách. Vuốt trái một hội thoại để "Đánh dấu đã
  đọc".
- Quay lại bằng nút chuẩn ở đầu thanh và vuốt từ mép trái; không tự vẽ nút quay lại.
- Vùng chạm ≥ `size-hit-ios`; lề `margin-compact` (iPhone), `margin-regular` (iPad) khi dựng view
  riêng, còn lại theo `layoutMargins` của hệ thống.

## Sheet

| Sheet | Detent | Nút |
|---|---|---|
| Ghép nối (`PairingCard`) | large | "Hủy" ở đầu toolbar; ghép xong tự đóng |
| Tin nhắn mới | Chỉ large (khung soạn) | "Hủy" ở đầu toolbar; gửi bằng nút gửi trong ô soạn |

- Theo HIG cập nhật 24/3/2026: sheet một màn đặt "Hủy" ở đầu, "Xong" ở cuối toolbar; "Xong" luôn đi
  cùng "Hủy" hoặc "Quay lại"; không bao giờ đủ cả ba. Nhiều bước: bước đầu "Hủy" và "Xong" (chưa
  dùng được), bước giữa "Quay lại" và "Xong" (chưa dùng được), bước cuối "Quay lại" và "Xong".
- Sheet đổi được cỡ thì có grabber (`.presentationDragIndicator(.visible)`,
  `.presentationDetents([.medium, .large])` — iOS 16). Vuốt xuống để đóng; đang có bản nháp tin nhắn
  thì hỏi bằng action sheet.
- iPad: kiểu form sheet. Mỗi lúc một sheet.

## Bảng nhớ tạm (CLIP-04)

- Gửi: `PasteButton` (SwiftUI) hoặc `UIPasteControl` trên thẻ gửi của `PasteCard`; một lần chạm là
  gửi, không có hộp thoại "Cho phép dán". App không đọc `UIPasteboard` bằng code; chỉ đọc
  `changeCount`, `hasStrings`, `hasImages`, `hasURLs` để hiện gợi ý.
- Nhận: chỉ khi app đang mở và có phiên; ghi bằng `setItems(_:options:)` với `.localOnly` (không lan
  qua Universal Clipboard) và `.expirationDate` theo `clip.auto_clear_s`.
- Chưa kết nối: nút Dán vô hiệu, dòng "Chưa kết nối với điện thoại". Gửi xong: HUD `Feedback` "Đã
  gửi tới Pixel 8 của Lan" và rung `success`.

## Ghép nối và thông báo

- iPhone, iPad hiện mã QR để điện thoại Android quét; app iOS không xin quyền camera.
- Tin SMS mới: thông báo liên lạc (`INSendMessageIntent`) với "Trả lời" và "Đánh dấu đã đọc";
  Notification Service Extension giải mã khi máy đang mở khóa, máy khóa thì chỉ hiện "Tin nhắn SMS
  mới".
- Cuộc gọi đến: thông báo liên lạc (`INStartCallIntent`) mức time-sensitive, chỉ có "Từ chối"; không
  dùng PushKit, CallKit (C7); iPhone không trả lời hộ được.
- App đang mở thì không có thông báo: cuộc gọi đến hiện banner trong app (CALL-01 bước 8). Huy hiệu
  biểu tượng app là số hội thoại chưa đọc.

## iPad

- Tin nhắn dùng `NavigationSplitView`: danh sách và hội thoại cạnh nhau ở regular width, một cột ở
  compact (Split View hẹp, Slide Over).
- iPadOS 18+: thanh tab gần đỉnh màn hình, `.tabViewStyle(.sidebarAdaptable)` cho phép chuyển thành
  thanh bên; iPadOS 16–17: `TabView` thường.
- Chế độ cửa sổ (iPadOS 26+): nút điều khiển cửa sổ nằm ở đầu toolbar, nên không đặt nút sát mép đầu
  toolbar.
- Bàn phím ngoài: ⌘N tin nhắn mới, ⌘F tìm, Return gửi. Menu HandLive › Cài đặt mở trang của app
  trong Cài đặt hệ thống; cài đặt trong app là mục riêng ngay bên dưới.
- Bảng nhớ tạm chạy như nhau ở Split View và Stage Manager khi cửa sổ HandLive đang ở phía trước.

## iPhone Duo

- Bố cục theo size class: màn ngoài compact width, màn trong regular width. Không chiều rộng cố
  định, không bố cục riêng cho từng tư thế.
- Dùng thanh tab và toolbar của hệ thống để hệ thống tự đưa thanh sang cạnh dọc; không ghi đè vị trí
  thanh.
- Mỗi nút toolbar có cả tiêu đề và symbol (`Label`); trên trục dọc, quay lại hoặc đóng ở trên cùng,
  rồi tới hành động chính.
- Màn trong hiện danh sách và hội thoại cạnh nhau; màn ngoài một cột, cùng chức năng.
- Alert, sheet, split view tự tránh camera và nếp gập; view tự dựng mới cần `ReservedRegion` (iOS
  27.1, đang beta).

## Giới hạn nền tảng

- Không đọc bảng nhớ tạm khi chạy nền. Vào nền thì đóng phiên; quay lại thì kết nối lại và nhận clip
  mới nhất nếu còn trong 120 s.
- Khi app đóng, SMS và cuộc gọi tới qua APNs và Notification Service Extension; không có nội dung
  khi máy khóa.
- Không nghe gọi (Apple không mở vai trò Hands-Free), không có camera ảo.

## Bản dự phòng cho iOS 16

| Tính năng | Từ | Trên iOS 16 |
|---|---|---|
| `PasteButton`, `NavigationSplitView`, `presentationDetents`, `presentationDragIndicator` | 16 | Dùng được |
| `ContentUnavailableView`, `.sensoryFeedback`, `symbolEffect`, TipKit | 17 | Trạng thái trống tự dựng; `UINotificationFeedbackGenerator`; không hiệu ứng, không mẹo |
| `Tab`, `.sidebarAdaptable` | 18 | `TabView` với `.tabItem` |
| `glassEffect(_:in:)`, `.glassProminent`, `ConcentricRectangle` | 26 | `.regularMaterial`, `.borderedProminent`, góc `radius-*` |

Chữ theo text style và Dynamic Type; kiểm ở cỡ AX5. Ở cỡ trợ năng, `ThreadRow` và `DeviceRow` xếp
dọc thay vì cắt chữ. Tiêu đề thương hiệu dùng `Font.custom(_:size:relativeTo:)`.

## Điểm lệch

- Đã đồng bộ với tài liệu chi tiết (25/09/2026): CALL-01 API 6 — I-NSE dựng `INStartCallIntent` và
  `content.updating(from:)` để thành thông báo liên lạc (quyết định 15).
- Đã đồng bộ với tài liệu chi tiết (25/09/2026): CLIP-04 trường 1 "Gửi sang <tên điện thoại>";
  SET-03 trường 11 bỏ câu về quyền dán.
- Tài liệu chi tiết viết "Huỷ"; ở đây viết kiểu Apple "Hủy".

## Nên và không nên

| Nên | Không nên |
|---|---|
| Gửi bảng nhớ tạm bằng nút Dán của hệ thống | Đọc bảng nhớ tạm khi mở app |
| Để thanh tab luôn hiện, kể cả khi tab trống | Ẩn tab Cuộc gọi khi tính năng tắt |
| Dùng size class và component chuẩn | Dựng bố cục riêng cho từng kiểu iPhone |
