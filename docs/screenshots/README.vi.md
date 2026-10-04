[English](README.md) | Tiếng Việt

# Ảnh màn hình

Các màn hình của ứng dụng HandLive tính đến 27/09/2026 (Phase 3 đang làm, android `e495907`, apple `2edd00c`; danh sách Tin nhắn trên iPhone và Tin nhắn mới trên cả hai nền tảng: apple `2fd87b3`). Mỗi màn có bản tiếng Anh và tiếng Việt: tên file kết thúc bằng `.en.png` hoặc `.vi.png`. Mọi tên, số điện thoại và thiết bị đều là giả (+1 201 555 01xx, "E2E Test Mac").

Ba màn chào được chụp lại ngày 04/10/2026 với biểu tượng thương hiệu (android `41f13c3`, apple `8ecd350`).

## Android

Ứng dụng thật trên emulator Android 15, ghép nối với Mac giả của `shared/tools/e2e`. Ứng dụng Android không có màn SMS hay cuộc gọi: SMS và cuộc gọi hiện trên Mac và iPhone, cuộc gọi đến trên điện thoại dùng trình quay số của Android.

| | | | |
|---|---|---|---|
| <img src="android/01-welcome.vi.png" alt="Chào mừng: mã hóa đầu cuối, không cần tài khoản." width="200"> | <img src="android/02-sms-permission-primer.vi.png" alt="HandLive giải thích vì sao cần quyền SMS trước khi Android hỏi." width="200"> | <img src="android/03-pair-a-device.vi.png" alt="Ghép nối với Mac hoặc iPhone bằng mã QR hoặc mã PIN." width="200"> | <img src="android/04-devices-connected.vi.png" alt="Mac đã ghép nối, đang kết nối qua Wi-Fi." width="200"> |
| Chào mừng: mã hóa đầu cuối, không cần tài khoản. | HandLive giải thích vì sao cần quyền SMS trước khi Android hỏi. | Ghép nối với Mac hoặc iPhone bằng mã QR hoặc mã PIN. | Mac đã ghép nối, đang kết nối qua Wi-Fi. |
| <img src="android/05-device-details.vi.png" alt="Kiểu máy, lần kết nối gần nhất, tính năng và mã an toàn." width="200"> | <img src="android/07-auto-send-consent.vi.png" alt="Dịch vụ Hỗ trợ tiếp cận làm gì trước khi bật tự gửi bảng nhớ tạm." width="200"> | <img src="android/08-settings.vi.png" alt="Cài đặt bảng nhớ tạm, SMS, cuộc gọi và kết nối qua Internet." width="200"> |  |
| Kiểu máy, lần kết nối gần nhất, tính năng và mã an toàn. | Dịch vụ Hỗ trợ tiếp cận làm gì trước khi bật tự gửi bảng nhớ tạm. | Cài đặt bảng nhớ tạm, SMS, cuộc gọi và kết nối qua Internet. |  |

<img src="android/06-service-notification.vi.png" alt="Thông báo dịch vụ trên Android: đã kết nối với Mac, có nút Gửi bảng nhớ tạm." width="540">

Thông báo dịch vụ trên Android: đã kết nối với Mac, có nút Gửi bảng nhớ tạm.

## iPhone và iPad

View `HLiOSUI` thật trong một app dựng riêng để chụp, chạy trên iOS 27 Simulator, dữ liệu mẫu ghi qua các store thật. Ảnh không chụp từ máy đã ghép nối với điện thoại thật.

| | | | |
|---|---|---|---|
| <img src="ios/01-welcome.vi.png" alt="Lần chạy đầu: HandLive làm gì và bảo vệ dữ liệu ra sao." width="200"> | <img src="ios/02-pairing-qr.vi.png" alt="Ghép nối với điện thoại Android bằng mã QR hoặc mã PIN." width="200"> | <img src="ios/03-clipboard.vi.png" alt="Chạm Dán để gửi; nội dung mới nhất từ điện thoại sẵn sàng để sao chép." width="200"> | <img src="ios/04-sms-conversation.vi.png" alt="Đọc và trả lời tin nhắn SMS của điện thoại." width="200"> |
| Lần chạy đầu: HandLive làm gì và bảo vệ dữ liệu ra sao. | Ghép nối với điện thoại Android bằng mã QR hoặc mã PIN. | Chạm Dán để gửi; nội dung mới nhất từ điện thoại sẵn sàng để sao chép. | Đọc và trả lời tin nhắn SMS của điện thoại. |
| <img src="ios/05-calls.vi.png" alt="Nhật ký cuộc gọi của điện thoại, cuộc gọi nhỡ màu đỏ." width="200"> | <img src="ios/06-incoming-call-banner.vi.png" alt="Cuộc gọi đến hiện biểu ngữ kèm nút Từ chối." width="200"> | <img src="ios/07-settings.vi.png" alt="Bật hoặc tắt riêng từng tính năng." width="200"> | <img src="ios/08-phone-details.vi.png" alt="Điện thoại đã ghép nối: kết nối, tính năng, mã an toàn, hủy ghép nối." width="200"> |
| Nhật ký cuộc gọi của điện thoại, cuộc gọi nhỡ màu đỏ. | Cuộc gọi đến hiện biểu ngữ kèm nút Từ chối. | Bật hoặc tắt riêng từng tính năng. | Điện thoại đã ghép nối: kết nối, tính năng, mã an toàn, hủy ghép nối. |
| <img src="ios/10-messages-list.vi.png" alt="Danh sách hội thoại với bộ lọc Tất cả / Chưa đọc; hội thoại chưa đọc có dấu chấm." width="200"> | <img src="ios/11-new-message.vi.png" alt="Tin nhắn mới: gõ số điện thoại sau Đến:." width="200"> |  |  |
| Danh sách hội thoại với bộ lọc Tất cả / Chưa đọc; hội thoại chưa đọc có dấu chấm. | Tin nhắn mới: gõ số điện thoại sau Đến:. |  |  |

## Mac

Cửa sổ và view `HLMacUI` thật trong một app dựng riêng trên macOS 27, dữ liệu mẫu; mỗi cửa sổ tự chụp chính nó. Chưa có menu trên thanh menu: menu chỉ tồn tại khi đang mở, và phiên chụp không có quyền ghi màn hình.

| | |
|---|---|
| <img src="macos/01-welcome.vi.png" alt="Lần chạy đầu: mở khi đăng nhập và biểu tượng trên thanh menu." width="400"> | <img src="macos/02-pairing-qr.vi.png" alt="Quét mã QR bằng HandLive trên điện thoại Android, hoặc dùng mã PIN." width="400"> |
| Lần chạy đầu: mở khi đăng nhập và biểu tượng trên thanh menu. | Quét mã QR bằng HandLive trên điện thoại Android, hoặc dùng mã PIN. |
| <img src="macos/03-messages-window.vi.png" alt="Hội thoại SMS và nhật ký cuộc gọi trong một cửa sổ." width="400"> | <img src="macos/04-incoming-call-panel.vi.png" alt="Bảng nổi khi có cuộc gọi đến: Trả lời, Từ chối hoặc Bỏ qua." width="400"> |
| Hội thoại SMS và nhật ký cuộc gọi trong một cửa sổ. | Bảng nổi khi có cuộc gọi đến: Trả lời, Từ chối hoặc Bỏ qua. |
| <img src="macos/05-new-message.vi.png" alt="Tin nhắn mới trong cửa sổ Tin nhắn." width="400"> |  |
| Tin nhắn mới trong cửa sổ Tin nhắn. |  |

## Chế độ tối và iPad

| | | |
|---|---|---|
| <img src="android/05-device-details-dark.en.png" alt="Android: chi tiết thiết bị" width="200"> | <img src="ios/04-sms-conversation-dark.en.png" alt="iPhone: hội thoại" width="200"> | <img src="ios/09-ipad-messages.en.png" alt="iPad: danh sách hội thoại và nội dung cạnh nhau" width="400"> |
| Android: chi tiết thiết bị | iPhone: hội thoại | iPad: danh sách hội thoại và nội dung cạnh nhau |

## Lỗi giao diện thấy khi chụp

- Ghép nối trên Android: nếu Mac kết nối khi người dùng còn đang gõ PIN, điện thoại chuyển sang Đang ghép nối… và không gõ PIN được nữa (PAIR-01 A3–A4).

Cập nhật: chạy lại cùng các bước trên bản build mới và thay file cùng tên.
