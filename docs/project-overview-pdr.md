# HandLive: Định nghĩa sản phẩm

> **Ngày:** 2026-09-24. **Trạng thái:** chưa triển khai tính năng người dùng.

## 1. Vấn đề

Người dùng Android không có sự liền mạch giữa điện thoại và máy tính như Apple Continuity, hay như Microsoft Phone Link giữa Android và Windows. HandLive lấp chỗ trống đó cho **Android với macOS và iOS**. Trọng tâm là ba luồng còn thiếu: âm thanh cuộc gọi, camera và mic, đồng bộ dữ liệu ngay lúc phát sinh. Mọi luồng đều mã hóa đầu-cuối.

## 2. Mục tiêu

- Đồng bộ clipboard hai chiều. Văn bản trễ dưới 50 ms trong mạng nội bộ.
- Nhận và gửi SMS từ macOS và iOS.
- Nhận cuộc gọi, điều khiển, rồi **nghe và nói** ngay trên macOS.
- Dùng camera và mic Android như thiết bị ảo trong Zoom, Meet, FaceTime, OBS.
- Mã hóa đầu-cuối luôn bật. Không máy chủ nào đọc được nội dung.

## 3. Ngoài phạm vi

- Không chuyển âm thanh cuộc gọi lên iOS. Apple không mở API HFP phía tai nghe. iOS chỉ có clipboard, SMS và thông tin cuộc gọi.
- Không ghi âm cuộc gọi. Hệ thống chỉ chuyển âm thanh lúc đang gọi, không lưu.
- Không phát nhạc chất lượng cao qua HFP. Kênh này là mono, 8 hoặc 16 kHz.

## 4. Người dùng

Người dùng phổ thông, không chỉ lập trình viên. Mặc định là **dùng được ngay, không dây, không cấu hình thêm**. ADB, cáp USB và Shizuku chỉ là lối tăng tốc cho người muốn tinh chỉnh. Tính năng cốt lõi không phụ thuộc các lối đó.

## 5. Nền tảng

| Nền tảng | Yêu cầu tối thiểu |
|----------|-------------------|
| Android | minSdk 29 (Android 10), targetSdk 35 |
| macOS | 13+ |
| iOS/iPadOS | 16+ |
| Cloud relay | Rust/Actix-web, tự host một VPS lúc đầu |

## 6. Quyết định đã chốt

Đủ ở mục 12 (D1 đến D8) trong `plans/20260924-definitive-architecture/plan.md`. Tóm tắt:

- **D1:** Âm thanh cuộc gọi có hai đường. Thử HFP một tuần. Nếu không đi được, chuyển hẳn sang Opus qua WebSocket.
- **D2:** Nói rõ với người dùng trước khi chuyển âm thanh cuộc gọi (hai bên cùng biết). Việc này không chặn lịch phát hành để chờ kết luận pháp lý.
- **D3:** Dùng `BluetoothHeadsetClient` (SystemApi) cùng Shizuku ngay. Theo dõi CompanionDeviceManager.
- **D4:** Clipboard chạy nền qua Accessibility Service. Dự phòng: gửi thủ công bằng nút trên thông báo, ô Cài đặt nhanh, hoặc Chia sẻ (C15).
- **D5:** Cloud relay tự host một VPS. Chuyển sang dịch vụ có người vận hành khi quá 500 người dùng cùng lúc.
- **D6:** Thử CMIOExtension trong tuần đầu của Phase 5.
- **D7:** Phân phối AudioServerPlugin bằng PKG đã notarized và Homebrew cask.
- **D8:** Tăng tốc USB qua ADB, có hướng dẫn từng bước. UVC native để dành cho v2.
- **D9 đến D12** (bổ sung 2026-09-24, plan §13): điều khiển cuộc gọi bằng API công khai. Giữ máy, DTMF và tắt tiếng đi qua HFP, không dùng `InCallService`. Giữ Opus/WebSocket cùng Shizuku, kèm giới hạn đã ghi. Âm thanh HFP dựa vào mã hóa Bluetooth. Clipboard mặc định dùng Accessibility, vẫn có đường gửi thủ công.

## 7. Chỉ số thành công

- Clipboard: văn bản dưới 50 ms trong mạng nội bộ, ảnh 5 MB dưới 2 giây, kết nối lại dưới 3 giây.
- SMS: thông báo lên macOS dưới 500 ms, xác nhận trả lời dưới 2 giây.
- Cuộc gọi: thông báo cuộc gọi đến dưới 200 ms, thời gian nghe máy dưới 500 ms tính từ đầu đến cuối.
- Âm thanh: MOS từ 3.5 với Bluetooth, từ 3.0 với WebSocket. Echo return loss trên 40 dB.
- Camera và mic: trễ dưới 120 ms qua Wi-Fi, dưới 70 ms qua USB.

## Câu hỏi còn mở

- Cấu trúc kho đã chốt: năm kho trong một workspace (hub, android, apple, relay, shared). Xem README.
- Câu chữ công bố khi chuyển âm thanh cuộc gọi còn cần luật sư rà. Việc này chạy song song với lập trình.
