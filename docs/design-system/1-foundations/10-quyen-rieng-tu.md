# Quyền riêng tư

HandLive xin quyền đúng lúc người dùng cần tính năng, nói rõ dữ liệu đi đâu, và không có cách tắt mã hóa đầu-cuối. Mục này liệt kê quyền theo nền tảng, câu giải thích quyền (purpose string), quy tắc màn giải thích trước khi xin quyền và cách xử lý nội dung nhạy cảm.

Nguồn HIG: https://developer.apple.com/design/human-interface-guidelines/privacy

## Nguyên tắc

- Chỉ xin quyền cho tính năng người dùng bật hoặc đang dùng. Lúc thiết lập chỉ hỏi quyền cốt lõi: thông báo và mạng cục bộ.
- Nói rõ dữ liệu đi đâu: chỉ giữa các thiết bị đã ghép; máy chủ Kết nối qua Internet chỉ chuyển dữ liệu đã mã hóa, không đọc được nội dung. Không cần tài khoản.
- Một quyền bị từ chối chỉ làm tính năng đó không dùng được; tính năng khác vẫn chạy.
- Khai báo nhãn quyền riêng tư trên App Store (iOS) và mục An toàn dữ liệu trên Google Play.

## macOS

| Quyền | Khi hỏi | Purpose string |
|---|---|---|
| Thông báo | `Onboarding`, sau màn giải thích | Không có, hộp thoại của hệ thống |
| Mạng cục bộ (macOS 15+) | `Onboarding`, lần duyệt Bonjour đầu tiên | `NSLocalNetworkUsageDescription`: "HandLive tìm điện thoại Android của bạn trong mạng Wi-Fi để kết nối trực tiếp, không qua Internet." |
| Bluetooth | Bật "Nghe gọi trên Mac", sau `ConsentSheet` | `NSBluetoothAlwaysUsageDescription`, đề xuất: "HandLive dùng Bluetooth để nghe và nói cuộc gọi của điện thoại trên Mac." |
| Micro | Ngay sau Bluetooth, cùng luồng | `NSMicrophoneUsageDescription`, đề xuất: "HandLive dùng micro của Mac để người ở đầu dây bên kia nghe được bạn." |
| Camera | Bật "Dùng điện thoại làm webcam" | `NSCameraUsageDescription`: "HandLive đưa hình từ điện thoại vào camera ảo HandLive Camera." |
| Duyệt tiện ích camera | Cùng luồng webcam, khi hệ thống cần người dùng duyệt | Không có; HandLive chỉ đường tới đúng trang trong Cài đặt hệ thống |
| Driver micro ảo | Cùng luồng webcam, khi cần tiếng | Nói trước: macOS sẽ hỏi mật khẩu quản trị, âm thanh ngắt khoảng 1–2 giây |
| Dán từ ứng dụng khác (macOS 15.4+) | Không có API để xin | Hướng dẫn: Cài đặt hệ thống › Quyền riêng tư & Bảo mật › Dán từ ứng dụng khác |

- Đã đồng bộ với tài liệu chi tiết (25/09/2026): AUDIO-01 API 3 xin quyền micro, `NSMicrophoneUsageDescription` khai ở SET-03; AUDIO-02 E7 khi bị từ chối.
- Đã đồng bộ với tài liệu chi tiết (25/09/2026): purpose string Bluetooth trong AUDIO-01 API 3 nói cả nghe và nói: "HandLive kết nối Bluetooth với điện thoại của bạn để nghe và nói cuộc gọi trên Mac."

## iOS và iPadOS

| Quyền | Khi hỏi | Ghi chú |
|---|---|---|
| Thông báo, kèm mức nhạy cảm thời gian | `Onboarding` | Cuộc gọi đến là thông báo time-sensitive |
| Mạng cục bộ | `Onboarding` | Cùng purpose string với macOS |

- Không xin camera (điện thoại Android quét mã QR hiện trên iPhone, iPad), Bluetooth hay micro.
- Dán chỉ qua `PasteButton`, là thao tác của người dùng, nên iOS không hỏi quyền dán. Đã đồng bộ với tài liệu chi tiết (25/09/2026): SET-03 trường 11 đã bỏ câu về quyền dán.

## Android

Hộp thoại xin quyền là của Android, giữ nguyên. Mỗi lần xin chỉ gồm quyền của một tính năng.

| Tính năng | Quyền | Khi hỏi |
|---|---|---|
| Chung | `POST_NOTIFICATIONS` (Android 13+) | Lần chạy đầu |
| Ghép nối | `CAMERA` | Khi mở màn quét mã QR |
| Tin nhắn | `READ_SMS`, `SEND_SMS`, `READ_CONTACTS`, `READ_PHONE_STATE` | Khi bật Tin nhắn |
| Cuộc gọi | `READ_PHONE_STATE`, `READ_CALL_LOG`, `ANSWER_PHONE_CALLS`, `READ_CONTACTS` | Khi bật Cuộc gọi |
| Nghe gọi trên Mac | `BLUETOOTH_CONNECT` (Android 12+); Shizuku cho đường dự phòng | Khi tính năng được bật |
| Webcam | `CAMERA`, `RECORD_AUDIO` | Khi bật Dùng điện thoại làm webcam |
| Tự gửi bảng nhớ tạm | Dịch vụ Hỗ trợ tiếp cận | Sau `ConsentSheet` |

Quyền đã bị từ chối hẳn (Android không hiện lại hộp thoại): nút "Mở Cài đặt" tới trang thông tin ứng dụng; không gọi hộp thoại liên tục.

## Purpose string

- Một câu hoàn chỉnh, chủ động, sentence case, có dấu chấm; chủ ngữ là "HandLive"; nói làm gì và để làm gì.
- Cụ thể: "HandLive tìm điện thoại Android của bạn trong mạng Wi-Fi để kết nối trực tiếp." Không mơ hồ: "HandLive cần quyền này để hoạt động tốt hơn."
- Không mệnh lệnh ("Hãy cho phép…"), không hứa điều app không làm.

## Màn giải thích trước khi xin quyền

- Đúng một nút "Tiếp tục"; chọn nút này là mở hộp thoại của hệ thống. Không "Bỏ qua", "Hủy", "Để sau" hay nút đóng; người dùng từ chối ngay trong hộp thoại hệ thống. Nút của HandLive không ghi "Cho phép".
- Không mô phỏng hộp thoại hệ thống, không mũi tên chỉ vào nút "Cho phép", không thưởng để người dùng đồng ý: App Review từ chối các màn như vậy.
- Đã đồng bộ với tài liệu chi tiết (25/09/2026): SET-03 trường 14 chỉ còn "Tiếp tục".
- Ngoại lệ: công bố cần đồng ý pháp lý (`ConsentSheet`) có hai lựa chọn.
  - Nghe gọi trên Mac (bản công bố `call-audio-v1`): "Hủy" và "Đồng ý"; "Đồng ý" là nút mặc định, không tô đỏ.
  - Hỗ trợ tiếp cận trên Android (tự gửi bảng nhớ tạm): "Đồng ý" và "Gửi thủ công".
- Bị từ chối: tính năng hiện lý do bằng chữ `text-orange` và nút "Mở Cài đặt"; không hỏi lại khi người dùng chưa chủ động bật lại.

## Mã hóa đầu-cuối

- Luôn bật, không có công tắc tắt, không có mục mã hóa trong Cài đặt.
- Nói một câu trong `Onboarding`: "Dữ liệu được mã hóa đầu-cuối, chỉ đi giữa các thiết bị của bạn; máy chủ không đọc được nội dung. Không cần tài khoản."
- Chi tiết thiết bị có "Mã an toàn" (8 ký tự) để người dùng đối chiếu hai máy nếu muốn.
- Âm thanh cuộc gọi qua Bluetooth chỉ có mã hóa liên kết Bluetooth; `ConsentSheet` nói rõ điều này. Đường Wi-Fi vẫn mã hóa đầu-cuối.

## Bảng nhớ tạm nhạy cảm

- "Chặn nội dung nhạy cảm" bật mặc định trên Android và Mac: nội dung được đánh dấu nhạy cảm (`EXTRA_IS_SENSITIVE`; `org.nspasteboard.ConcealedType`, `TransientType`, `AutoGeneratedType`) hoặc có dãy số giống số thẻ thì không gửi. Thông báo "Đã chặn nội dung nhạy cảm" có nút "Vẫn gửi" (hiệu lực 120 s) và không hiện nội dung.
- Nội dung gửi bằng "Vẫn gửi" được đánh dấu nhạy cảm ở bên nhận để trình quản lý bảng nhớ tạm không lưu.
- iPhone, iPad: không tự đọc bảng nhớ tạm, chỉ gửi khi người dùng chạm nút Dán. Nội dung nhận được chỉ nằm trên máy này (`.localOnly`, không lan qua Universal Clipboard) và hết hạn theo "Tự xóa bảng nhớ tạm đã nhận".
- Không ghi log nội dung bảng nhớ tạm, tin nhắn hay số điện thoại.

## Nội dung tin nhắn trong thông báo

- Tùy chọn "Hiện nội dung trong thông báo" (Cài đặt › Tin nhắn trên Mac, iPhone, iPad), mặc định bật. Tắt thì thông báo chỉ ghi "Tin nhắn SMS mới".
- Khi máy khóa hoặc người dùng ẩn bản xem trước trong cài đặt hệ thống, hiện chữ giữ chỗ "Tin nhắn SMS mới" (`hiddenPreviewsBodyPlaceholder`).
- Nội dung đi qua dịch vụ push luôn chung chung; nội dung thật được giải mã trên máy.

## Nên và không nên

| Nên | Không nên |
|---|---|
| Xin Bluetooth khi bật Nghe gọi trên Mac | Xin mọi quyền lúc mở app lần đầu |
| Một nút "Tiếp tục" trên màn giải thích | Thêm "Bỏ qua" để né hộp thoại hệ thống |
| Câu giải thích cụ thể, có dấu chấm | "Cần quyền để trải nghiệm tốt hơn" |
| Nói rõ giới hạn của Bluetooth | Công tắc tắt mã hóa |
