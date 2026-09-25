# Android

App Android dựng lại ngôn ngữ của Apple bằng Jetpack Compose — như Apple làm Apple Music cho Android — với token, chữ Inter và biểu tượng Material Symbols Rounded. Phần do Android quản lý giữ kiểu Android. Khi quy ước Apple chạm vào thông báo, hộp thoại quyền, cử chỉ quay lại, thanh hệ thống, vùng chạm hay TalkBack, quy tắc Android thắng.

Nguồn HIG (quy ước Apple được mang sang): https://developer.apple.com/design/human-interface-guidelines/tab-bars · https://developer.apple.com/design/human-interface-guidelines/lists-and-tables · https://developer.apple.com/design/human-interface-guidelines/toggles · https://developer.apple.com/design/human-interface-guidelines/sheets · https://developer.apple.com/design/human-interface-guidelines/alerts

## Theme

- `HandLiveTheme` đọc token và cung cấp qua `CompositionLocal` (màu, chữ, khoảng cách, góc bo, bóng). Component `HL*` chỉ đọc từ đây.
- Không dùng Material dynamic color (Android 12+) và không lấy màu, chữ từ `MaterialTheme`: màu trạng thái và AccentColor phải giống Mac, iPhone.
- Trên Android, giá trị hex trong token là màu thật (Apple thì gọi API hệ thống).
- Giao diện Tối theo hệ thống (`isSystemInDarkTheme()`), không có công tắc trong app. Tương phản cao khi `UiModeManager.getContrast()` ≥ 0.5 (Android 14+) thì dùng bộ `-hc`.

## Chữ và biểu tượng

- Inter đóng gói trong app (`res/font`, giấy phép OFL), cùng thang cỡ iOS tính bằng sp (`android-*`): Body 17 sp, nhỏ nhất 11 sp, tracking theo token. Be Vietnam Pro cho `brand-large-title`, `brand-title`, `wordmark`; Roboto Mono cho `code-pin`; `timer` bật `fontFeatureSettings = "tnum"`.
- Phóng chữ tới 200% (Android 14 phóng phi tuyến): không khóa cỡ, không cố định chiều cao dòng chữ. Chữ đậm của hệ thống: `Configuration.fontWeightAdjustment` (Android 12+).
- Material Symbols Rounded (Apache 2.0), weight 400, bản rỗng; tab đang chọn dùng bản đặc (`FILL` 1). Tên đối chiếu với SF Symbol theo bảng ở mục Biểu tượng, ví dụ `chevron.forward` ↔ `chevron_right`, `checkmark.circle.fill` ↔ `check_circle`.

## Thành phần dựng theo kiểu Apple

| Thành phần | Compose | Quy cách |
|---|---|---|
| Danh sách nhóm | `HLGroupedList` (`LazyColumn`) | Nền `system-grouped-background`, nhóm `secondary-system-grouped-background` bo `radius-sheet`, dòng ≥ 56 dp, header sentence case, chú thích dưới nhóm |
| Công tắc | `HLSwitch` 51×31 dp | Bật `system-green`, tắt `system-fill`, núm trắng; cả dòng là vùng chạm (`Role.Switch`) |
| Segmented | `HLSegmented` | Rãnh `tertiary-system-fill`, đoạn chọn `tertiary-system-background`, nhóm cao 48 dp |
| Nút | `HLButton` capsule | Nút chính `accent-fill` + `on-accent`, cao 50 dp; nhấn thì tối đi 8%, không gợn sóng |
| Sheet | Sheet có grabber | Góc `radius-sheet`, hai mức cao (vừa, lớn), vuốt xuống để đóng |
| Alert, action sheet | `HLAlert`, `HLActionSheet` | Như Apple: "Hủy" bên trái hoặc dưới cùng; không dùng `AlertDialog` của Material |
| Thanh tab | Kính nổi ở đáy | Capsule `radius-capsule`, `glass-fill` + làm mờ `RenderEffect` (API 31+), viền `glass-stroke`, bóng `shadow-glass`; API 29–30 nền đục, tương phản cao gần đục |
| Tiêu đề lớn | Large title co lại khi cuộn | `android-large-title` 34 sp; cuộn thì thu thành tiêu đề giữa `android-headline` ở thanh trên |
| Phản hồi | HUD `Feedback` | Kính ở đỉnh màn ~1,5 giây kèm rung |

## Điều hướng

- Thanh tab hai mục: "Thiết bị" (Mac, iPhone, iPad đã ghép — `DeviceRow`, PAIR-02) và "Cài đặt" (SET-02). Không có tab Bảng nhớ tạm: gửi thủ công bằng ô Cài đặt nhanh, nút trên thông báo hoặc bảng chia sẻ.
- Màn con: chevron `chevron_left` ở góc trên trái kèm tên màn trước, như iOS. Nút và cử chỉ quay lại của hệ thống luôn dùng được; predictive back (Android 14+) bằng `PredictiveBackHandler`, khai `android:enableOnBackInvokedCallback="true"`.
- Không đặt control trong vùng cử chỉ quay lại ở hai mép (`WindowInsets.systemGestures`).

## Giữ nguyên kiểu Android

| Phần | Cách làm |
|---|---|
| Thông báo | `NotificationCompat` với kênh `hl_service`, `camera_request`, `camera_live`, `camera_alert` (mục Thông báo) |
| Hộp thoại quyền runtime | Của hệ thống, không vẽ lại; `PermissionPrimer` đứng trước (mục Xin quyền) |
| Ô Cài đặt nhanh | `TileService`, nhãn "Gửi bảng nhớ tạm", dòng phụ "Tới MacBook của Lan", "Tới 2 thiết bị" hoặc "Chưa kết nối"; API 34+ gọi `startActivityAndCollapse(PendingIntent)` |
| Bảng chia sẻ | Đích "Gửi tới thiết bị (HandLive)", chỉ nhận `text/plain` |
| Toast | Kết quả gửi khi app không hiện ("Đã gửi tới MacBook của Lan"); toast "HandLive đã dán từ bộ nhớ đệm" (Android 12+) do hệ thống hiện, không tắt được |
| Hỗ trợ tiếp cận | Trang Cài đặt › Hỗ trợ tiếp cận của hệ thống; HandLive chỉ dẫn tới sau `ConsentSheet` |
| Thanh trạng thái, thanh điều hướng | Edge-to-edge: `enableEdgeToEdge()`, đệm theo `WindowInsets.safeDrawing` |
| Splash | `SplashScreen` của hệ thống (Android 12+) trên `system-background`, không thêm chữ |
| Chỉ báo camera, micro đang dùng | Của hệ thống |

## Trợ năng và cảm giác

- Vùng chạm ≥ 48 dp (`size-hit-android`) thay cho 44 pt của iOS; khoảng cách giữa hai vùng chạm ≥ 8 dp.
- TalkBack: mỗi control tự dựng có nhãn, `role` và `stateDescription` ("Bật", "Tắt"); gộp dòng bằng `semantics(mergeDescendants = true)`; trạng thái kết nối là live region; tiêu đề màn đánh dấu `heading()`.
- Tắt hiệu ứng: `ValueAnimator.areAnimatorsEnabled()` là `false` thì bỏ chuyển động, chỉ đổi trạng thái (token `duration-*`).
- Rung qua `View.performHapticFeedback`: `CONFIRM`, `REJECT` (API 30+); `TOGGLE_ON`, `TOGGLE_OFF` (API 34+); API 29 dùng `CONTEXT_CLICK`. Tôn trọng cài đặt rung của hệ thống.

## Giấy phép

- Không dùng SF Pro, SF Mono, SF Symbols hay UI Kit của Apple trong app Android, kể cả để dựng mock-up Android; không dùng biểu tượng hay hình phần cứng của Apple.
- Inter, Be Vietnam Pro (OFL), Roboto Mono, Material Symbols Rounded (Apache 2.0) đóng gói trong app; ghi trong màn giấy phép mã nguồn mở.

## Phiên bản (minSdk 29, targetSdk 35)

| Từ | Ảnh hưởng tới giao diện |
|---|---|
| API 29 (Android 10) | Không đọc bảng nhớ tạm khi chạy nền; kính là nền đục; không có đường âm thanh Opus/WS |
| API 30 (11) | Rung `CONFIRM`, `REJECT`; Opus/WS qua Shizuku có thể dùng trên một số máy |
| API 31 (12) | Làm mờ `RenderEffect`; quyền `BLUETOOTH_CONNECT`; splash của hệ thống; toast khi đọc bảng nhớ tạm; chặn mở activity gián tiếp từ thông báo |
| API 33 (13) | Quyền `POST_NOTIFICATIONS`; chế độ cài đặt bị hạn chế với bản cài ngoài Google Play; overlay xem trước khi ghi bảng nhớ tạm |
| API 34 (14) | Predictive back; phóng chữ phi tuyến tới 200%; `getContrast()`; rung `TOGGLE_ON`; người dùng vuốt bỏ được thông báo dịch vụ |
| API 35 (15) | Edge-to-edge bắt buộc với targetSdk 35 |

## Điểm lệch

- Đã đồng bộ với tài liệu chi tiết (25/09/2026): CLIP-01 trường 4–5 "Gửi bảng nhớ tạm".
- Đã đồng bộ với tài liệu chi tiết (25/09/2026): SET-01 trường 6 dùng "Tiếp tục".
- Tài liệu chi tiết viết "Huỷ"; ở đây viết kiểu Apple "Hủy".

## Nên và không nên

| Nên | Không nên |
|---|---|
| Dựng control theo quy cách Apple bằng token | Dùng Material 3 hay dynamic color cho giao diện của HandLive |
| Để thông báo, hộp thoại quyền, cử chỉ quay lại là của Android | Vẽ lại thông báo hay hộp thoại quyền theo kiểu iOS |
| Giữ vùng chạm 48 dp dù hình vẽ nhỏ hơn | Thu vùng chạm về 44 dp cho giống iPhone |
