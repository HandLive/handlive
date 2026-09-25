[English](project-roadmap.md) | Tiếng Việt

# HandLive: Lộ trình

> Nguồn: `plans/20260924-definitive-architecture/plan.md`, mục 8 và 11. Thẻ việc, Phase 0, cổng kiểm và ma trận máy nằm ở `plans/20260925-implementation/plan.md`.

Xây **theo thứ tự**. Mỗi phase là một phần dùng được. Phase sau đứng trên hạ tầng của phase trước. WebSocket, ghép cặp và mã hóa từ Phase 1 dùng lại cho mọi phase sau.

## Phase 1. Đồng bộ clipboard (MVP)

Android chạy foreground service, máy chủ WebSocket bằng Ktor, tìm máy trong mạng qua mDNS (`NsdManager` trên Android, `NWBrowser` trên Apple), ghép cặp QR, mã hóa XChaCha20. macOS là ứng dụng trên thanh menu. Có văn bản và ảnh (chia mảnh), tự xóa sau 60 giây, hai máy thỏa thuận tính năng khi kết nối.
**Đo:** văn bản dưới 50 ms trong mạng nội bộ, ảnh 5 MB dưới 2 giây, kết nối lại dưới 3 giây. **Công:** khoảng 3.5 person-month.

## Phase 2. Cầu nối SMS

Android nhận và gửi SMS. macOS và iOS có màn hình hội thoại, đồng bộ 50 tin gần nhất mỗi liên hệ. Thêm **ứng dụng iOS** (clipboard và SMS), **cloud relay** viết bằng Rust cho máy ở ngoài mạng nội bộ, thông báo đẩy APNs và FCM.
**Đo:** thông báo dưới 500 ms, xác nhận trả lời dưới 2 giây. **Công:** khoảng 4 person-month.

## Phase 3. Thông tin và điều khiển cuộc gọi

Android dùng API Telecom công khai: `TelephonyCallback`, `acceptRingingCall`, `endCall`. Không dùng `InCallService` (quyết định D9). macOS hiện bảng nổi `NSPanel` và thông báo liên lạc. Nghe hoặc từ chối đi qua Wi-Fi. Giữ máy, DTMF và tắt tiếng qua HFP để ở Phase 4. Có lịch sử cuộc gọi. iOS hiện thông tin cuộc gọi.
**Đo:** thông báo cuộc gọi đến dưới 200 ms, nghe máy dưới 500 ms từ đầu đến cuối. **Công:** khoảng 3 person-month.

## Phase 4. Âm thanh cuộc gọi

**Bắt đầu bằng một tuần thử HFP.** Bluetooth HFP (điện thoại là AG, Mac là HF), định tuyến SCO, khử tiếng vang bằng `AUVoiceProcessingIO`. Dự phòng Opus qua WebSocket, mã hóa hai lớp, bộ đệm jitter thích ứng, phát hiện khi tai nghe đang chiếm HFP. Đường HFP dựa vào mã hóa liên kết Bluetooth (D11). Có màn hình công bố trước khi bật (yêu cầu pháp lý).
**Đo:** MOS từ 3.5 với Bluetooth, từ 3.0 với WebSocket. Echo return loss trên 40 dB. **Công:** khoảng 6 person-month.

## Phase 5. Camera và mic ảo

**Bắt đầu bằng một tuần thử CMIOExtension.** Android lấy hình bằng Camera2, nén bằng MediaCodec, gửi qua Wi-Fi, tự nhận cáp USB, hạ chất lượng khi máy nóng. macOS giải mã bằng VideoToolbox, đưa hình ra CMIOExtension, đưa tiếng ra AudioServerPlugin, cài bằng PKG.
**Đo:** trễ dưới 120 ms qua Wi-Fi, dưới 70 ms qua USB. **Công:** khoảng 5.5 person-month.

## Công tổng

Khoảng 22 person-month. Hai người làm khoảng 11 tháng. Ba người làm khoảng 7.5 tháng. MVP (Phase 1) khoảng 2 tháng với hai người. Dùng được clipboard và SMS (Phase 1 cùng Phase 2) khoảng 4 tháng với hai người.

| Phase | Android | macOS | iOS | Server | Test | Tổng |
|-------|:-------:|:-----:|:---:|:------:|:----:|:----:|
| P1 | 1.5 | 1.5 | — | — | 0.5 | 3.5 |
| P2 | 1 | 0.5 | 1 | 1 | 0.5 | 4 |
| P3 | 1 | 1 | 0.5 | — | 0.5 | 3 |
| P4 | 2 | 2 | — | 0.5 | 1.5 | 6 |
| P5 | 2 | 2.5 | — | — | 1 | 5.5 |
