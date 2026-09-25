# Xin quyền

Mục này quy định mỗi quyền được xin lúc nào, với câu giải thích nào, và giao diện khi bị từ chối. Mỗi quyền gắn với một tính năng; thiếu quyền của tính năng này không làm hỏng tính năng khác.

Nguồn HIG: https://developer.apple.com/design/human-interface-guidelines/privacy#Requesting-permission · https://developer.apple.com/design/human-interface-guidelines/privacy#Pre-alert-screens-windows-or-views

## Quy tắc

- Xin khi người dùng sắp dùng tính năng; thiết lập ban đầu chỉ xin quyền cần để app chạy; mỗi lần một tính năng.
- `PermissionPrimer` hiện ngay trước hộp thoại hệ thống khi hộp thoại chưa đủ ngữ cảnh: tiêu đề, một–hai câu nói lợi ích và dữ liệu đi đâu, đúng một nút "Tiếp tục" mở hộp thoại. Không "Bỏ qua", không "Hủy", không nút đóng, không nhãn giống "Cho phép".
- Android luôn có primer: hộp thoại runtime không cho app thêm chữ, primer là lời giải thích duy nhất.
- Purpose string trên Apple: một câu chủ động, cụ thể, có dấu chấm, bắt đầu bằng "HandLive".
- Không hỏi lại tự động sau khi bị từ chối; không thưởng, không dọa để đổi lấy quyền.

## Bảng quyền

| Quyền | Nền tảng | Lúc xin | Primer | Purpose string hoặc quyền hệ thống |
|---|---|---|---|---|
| Thông báo | macOS, iOS | Thiết lập ban đầu | "Báo khi có tin nhắn và cuộc gọi" | Không có purpose string; `requestAuthorization(options: [.alert, .sound, .badge])`. Time-sensitive đi theo entitlement, không xin riêng |
| Mạng cục bộ | iOS, macOS 15+ | Thiết lập ban đầu | "Tìm điện thoại trong mạng Wi-Fi" | `NSLocalNetworkUsageDescription`: "HandLive tìm điện thoại Android của bạn trong mạng Wi-Fi để kết nối trực tiếp, không qua Internet." |
| Thông báo | Android 13+ | Thiết lập ban đầu | "Thông báo cho bạn biết trạng thái kết nối và để bạn xác nhận yêu cầu từ Mac, ví dụ bật camera." | `POST_NOTIFICATIONS` |
| Chạy nền | Android | Thiết lập ban đầu | "Để Mac và iPhone luôn tới được điện thoại, HandLive cần chạy nền mà không bị hệ thống ngắt." | Hộp thoại miễn tối ưu pin |
| Camera (quét QR) | Android | Chạm "Quét mã QR" | Đề xuất: "HandLive dùng camera để quét mã QR trên Mac, iPhone hoặc iPad." | `CAMERA`; từ chối thì dùng "Nhập mã PIN" |
| SMS | Android | Thẻ tính năng sau lần ghép đầu, hoặc khi bật "Tin nhắn SMS" | "Để xem và trả lời SMS trên Mac hoặc iPhone, HandLive cần đọc và gửi SMS, đọc danh bạ để hiện tên người gửi và đọc trạng thái điện thoại để chọn SIM." | `READ_SMS`, `SEND_SMS`, `READ_CONTACTS`, `READ_PHONE_STATE` |
| Cuộc gọi | Android | Như SMS, khi bật "Cuộc gọi" | Đề xuất: "Để báo cuộc gọi đến và cho bạn trả lời, từ chối trên Mac, HandLive cần đọc trạng thái điện thoại, nhật ký cuộc gọi và danh bạ." | `READ_PHONE_STATE`, `READ_CALL_LOG`, `ANSWER_PHONE_CALLS`, `READ_CONTACTS` |
| Tự gửi bảng nhớ tạm | Android | Bật "Tự gửi khi sao chép" | `ConsentSheet` (CLIP-01 trường 2) | Dịch vụ trong Cài đặt › Hỗ trợ tiếp cận |
| Bluetooth, micro | macOS | Bật "Nghe gọi trên Mac", ngay sau `ConsentSheet` | "Kết nối Bluetooth với điện thoại" | `NSBluetoothAlwaysUsageDescription`: "HandLive dùng Bluetooth để nhận âm thanh cuộc gọi từ điện thoại của bạn." · `NSMicrophoneUsageDescription` (đề xuất): "HandLive dùng micro để bạn nói trong cuộc gọi chuyển từ điện thoại." |
| Thiết bị ở gần | Android 12+ | Bật "Nghe gọi trên Mac" trên điện thoại | Đề xuất: "Để chuyển âm thanh cuộc gọi sang Mac, HandLive cần kết nối Bluetooth với Mac." | `BLUETOOTH_CONNECT` (Android 10–11 cấp lúc cài) |
| Trạng thái Tập trung | macOS | Bật "Đổ chuông trên Mac" | Không cần | `NSFocusStatusUsageDescription` (đề xuất): "HandLive xem bạn có đang bật Tập trung để không đổ chuông lúc đó." Chưa cho phép thì không đổ chuông |
| Camera | macOS | Bật "Dùng điện thoại làm webcam" (CAM-01 bước 3) | Danh sách kiểm tra của CAM-01 | `NSCameraUsageDescription`: "HandLive đưa hình từ điện thoại vào camera ảo HandLive Camera." |
| Camera, micro | Android | Bật "Dùng điện thoại làm webcam" trên điện thoại (thường ngay sau khi Mac bật) | "Dùng camera cho cuộc họp trên Mac" | `CAMERA`, `RECORD_AUDIO` |

iPhone và iPad không xin quyền camera (chỉ hiện QR) và không xin quyền dán (`PasteButton`).

Không phải hộp thoại quyền, chỉ hướng dẫn kèm nút mở đúng trang: Camera Extension (CAM-01 trường 5), driver micro ảo (CAM-01 trường 8), Dán từ ứng dụng khác trên macOS 15.4+ (C10), mục đăng nhập cần duyệt (`SMAppService.openSystemSettingsLoginItems()`), quyền Shizuku (AUDIO-01 bước 10).

## Khi bị từ chối

- Tính năng vẫn bật nhưng chưa dùng được. Dòng của nó trong Cài đặt có lý do màu `text-orange` và một nút: Mac "Mở Cài đặt hệ thống", iOS và Android "Mở cài đặt".
- Đích mở: Mac `x-apple.systempreferences:com.apple.preference.security?Privacy_Bluetooth` và các trang tương ứng; iOS `UIApplication.openSettingsURLString`, `openNotificationSettingsURLString`; Android `ACTION_APPLICATION_DETAILS_SETTINGS`, `ACTION_APP_NOTIFICATION_SETTINGS`, `ACTION_ACCESSIBILITY_SETTINGS`.
- Android không báo từ chối vĩnh viễn: suy từ `perm.requested` và `shouldShowRequestPermissionRationale` (Android 11+ tự chặn sau hai lần). Khi đó không gọi hộp thoại nữa mà hiện "Mở cài đặt".
- Mac và iPhone thấy quyền còn thiếu trên điện thoại (`permissions_missing`) ở trang Thiết bị, ví dụ "Thiếu quyền SMS trên điện thoại"; điện thoại đăng thông báo gợi ý tối đa một lần mỗi tính năng mỗi 24 h (SET-01 trường 17).

## Riêng Android

- Hộp thoại runtime là giao diện hệ thống: không vẽ lại, không che. Hệ thống gộp theo nhóm: SMS, Danh bạ, Điện thoại, Nhật ký cuộc gọi, Camera, Micro, Thiết bị ở gần.
- Hỗ trợ tiếp cận đi qua `ConsentSheet` toàn màn; chỉ sau "Đồng ý" mới mở Cài đặt › Hỗ trợ tiếp cận. Công bố nói trước về toast của hệ thống "HandLive đã dán từ bộ nhớ đệm" (Android 12+).
- Bản cài ngoài Google Play trên Android 13+: trước khi mở Hỗ trợ tiếp cận, hướng dẫn "Chế độ cài đặt bị hạn chế": Cài đặt › Ứng dụng › HandLive › ⋮ › "Cho phép chế độ cài đặt bị hạn chế" (SET-01 API 6).

## Hai lựa chọn: chỉ ở ConsentSheet

| Công bố | Nền tảng | Lựa chọn | Ghi lại |
|---|---|---|---|
| Nghe gọi trên Mac (`call-audio-v1`) | macOS | "Hủy" (trái) · "Đồng ý" (phải, mặc định, không tô đỏ) | `consent_record` |
| Tự gửi khi sao chép (CLIP-01 trường 3) | Android | "Gửi thủ công" · "Đồng ý" (tài liệu chi tiết ghi "Không, tôi sẽ gửi thủ công"; nút nên bắt đầu bằng động từ) | `clip.a11y_consent_at` |

Không chọn sẵn. Đổi nội dung công bố thì tăng phiên bản văn bản và hỏi lại.

## Điểm lệch

- Đã đồng bộ với tài liệu chi tiết (25/09/2026): SET-03 trường 14 chỉ còn "Tiếp tục" (quyết định 11).
- Đã đồng bộ với tài liệu chi tiết (25/09/2026): AUDIO-01 xin quyền micro cùng lúc với Bluetooth (API 3), `NSMicrophoneUsageDescription` khai ở SET-03; AUDIO-02 E7 và AUDIO-04 điều kiện 6 nói rõ khi bị từ chối thì chỉ nghe.
- Đã đồng bộ với tài liệu chi tiết (25/09/2026): CALL-01 API 5 và SET-03 khai `NSFocusStatusUsageDescription`. Còn cần đồng bộ: các câu ghi "Đề xuất" cho Android đưa vào SET-01 API 2.
- Đã đồng bộ với tài liệu chi tiết (25/09/2026): SET-03 bước 7 chỉ nói cuộc gọi đến dùng mức nhạy cảm thời gian "để đến kịp lúc"; Mac tôn trọng Tập trung (quyết định 10).
- Đã đồng bộ với tài liệu chi tiết (25/09/2026): tài liệu chi tiết viết "Quyền riêng tư & Bảo mật" theo bản tiếng Việt của Apple; kế hoạch triển khai có việc đối chiếu tên mục hệ thống trên máy thật. Dấu kiểu Apple đã áp cho tài liệu chi tiết.

## Nên và không nên

| Nên | Không nên |
|---|---|
| Nói lợi ích và dữ liệu đi đâu trong một–hai câu | Viết "để có trải nghiệm tốt hơn" |
| Để người dùng trả lời trong hộp thoại hệ thống | Thêm nút "Để sau" trên màn giải thích |
| Giữ tính năng khác chạy khi một quyền bị từ chối | Chặn cả app vì thiếu một quyền |
