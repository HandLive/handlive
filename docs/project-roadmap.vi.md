[English](project-roadmap.md) | Tiếng Việt

# HandLive: Lộ trình

> Nguồn: `plans/20260924-definitive-architecture/plan.md`, mục 8 và 11. Thẻ việc, Phase 0, cổng kiểm và ma trận máy nằm ở `plans/20260925-implementation/plan.md`. **Bảng tiến độ sống:** [`README.vi.md`](../README.vi.md#lộ-trình-và-tiến-độ) của hub (phải cập nhật mỗi khi hoàn thành một công việc cụ thể).

HandLive đưa các tính năng native riêng trong từng hệ sinh thái, như Handoff trên Apple, lên Android. Lộ trình dưới đây xây **theo thứ tự**. Mỗi phase là một phần dùng được. Phase sau đứng trên hạ tầng phase trước. WebSocket, ghép cặp và mã hóa từ Phase 1 dùng lại cho mọi phase sau. Một ngoại lệ về thứ tự (quyết định của chủ dự án, 28/09/2026): Phase 5 và 6 làm trước khi Phase 4 hoàn tất, vì Phase 4 chờ spike Bluetooth rảnh tay của cổng G4 trên phần cứng thật.

## Tiến độ tóm tắt (05/10/2026)

**Tag mới nhất:** [`v0.1.0-beta.2`](https://github.com/HandLive/handlive/releases/tag/v0.1.0-beta.2) (beta thứ hai, bản đầu tiên có tệp cài đặt). Bảng sống: [`README.vi.md`](../README.vi.md#lộ-trình-và-tiến-độ).

| Phase | Mã trên `main` | Cổng / điểm nghẽn |
|-------|----------------|-------------------|
| 0 | Xong | G0 xong |
| 1 | Xong (26/09/2026) | G1 mở; ghép S25↔Mac ổn định (30/09/2026); đã sửa ghép đôi một phía sau khi đặt lại khóa (04/10/2026); item ảnh kèm chữ bên cạnh URI, báo mất quyền URI và e2e ảnh điện thoại → Mac (05/10/2026); clip chữ mang kèm HTML (05/10/2026) |
| 2 | Xong (27/09/2026) | G2 mở; kiểm relay / APNs / FCM thật còn mở |
| 3 | Xong (28/09/2026) | Kiểm máy thật còn mở |
| 4 | Spike trên `main` (`HFPSpike`, merge 30/09/2026) | G4: cần ghép BT điện thoại + cuộc gọi thật |
| 5 | Spike trên `main` (`CameraSpike`, merge 30/09/2026) | G5: cần Apple Developer trả phí |
| 6 | Probe spike trên `main` (Apple+Android merge 30/09/2026); chưa mở thẻ sản phẩm | G6: quyết định trình duyệt; hàng Firefox/Edge/Brave |

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

## Phase 6. Duyệt web tiếp (đề xuất)

**Bắt đầu bằng spike G6 (3–5 ngày).** Trang web đang mở trên một thiết bị được xem tiếp trên thiết bị khác: Android sang Mac, Android sang iPhone và iPad (khi ứng dụng đang mở), Mac sang Android. Android đọc thanh địa chỉ của trình duyệt ở foreground qua một dịch vụ Hỗ trợ tiếp cận riêng, giới hạn ở các trình duyệt được hỗ trợ, sau màn hình công bố, mặc định tắt. Mac đọc tab trước nhất qua Apple Events, với quyền Tự động hóa cho từng trình duyệt. Mac hiện trang trong menu, Android hiện thông báo im lặng, iPhone và iPad hiện banner; người dùng mở bằng một lần bấm hoặc chạm. Tab riêng tư không bao giờ được gửi và trang không bao giờ được lưu. Chỉ dựa trên hạ tầng Phase 1 (phiên, mã hóa, capability), nên không phụ thuộc Phase 4 và 5; theo quyết định của chủ dự án ngày 28/09/2026, phase này làm xong trước khi Phase 4 hoàn tất. Thiết kế chi tiết: nhóm 9, WEB-01 tới WEB-05, quyết định C21.
**Cổng G6:** thanh địa chỉ và nhận biết ẩn danh trên Android cho Chrome, Samsung Internet, Firefox, Edge và Brave trên Android 10 và 15, kèm chi phí pin của dịch vụ; Apple Events cho Safari, Chrome và Arc trên macOS 13 và 26, cửa sổ riêng tư của Safari, TCC với bản Developer ID; chính sách Hỗ trợ tiếp cận hiện hành của Play. Đạt hoặc không đạt theo từng trình duyệt. **Công:** khoảng 1.5 person-month (Android 3 tuần, macOS 2 tuần, iOS nửa tuần, test 1 tuần, spike 1 tuần).

## Phase 7. Kết nối mọi nơi (đề xuất)

**Bắt đầu sau các cổng G4, G5 và G6, bằng spike G7 (khoảng một tuần).** Sau lần ghép đôi QR đầu tiên, điện thoại và Mac tự kết nối khi không chung mạng — cả hai offline, hoặc điện thoại dùng dữ liệu di động còn Mac dùng Wi-Fi công cộng — và không máy nào phải rời hay đổi Wi-Fi hiện tại. Một liên kết Bluetooth (BLE hoặc cổ điển, chọn theo G7) chở kênh điều khiển; một làn dữ liệu lớn mới chở ảnh qua LAN, Wi-Fi Direct (chỉ khi Wi-Fi của Mac đang rảnh), relay hoặc Bluetooth; ghép đôi lần đầu cũng chạy được khi offline qua BLE; HandLive tự khởi động ghép đôi Bluetooth cổ điển cho HFP và Mac chỉ tự xác nhận khi mã đã được kiểm đầu-cuối. Mọi đường Bluetooth đều có bảo mật ngoài bắt tay phiên (lớp bảo mật link, chính sách admission). Plan: `plans/20260925-implementation/phase-07-ket-noi-moi-noi.vi.md`.
**Đo:** văn bản dưới 50 ms trên LAN và trong 200 ms qua Bluetooth; ảnh 5 MB trong 2 s trên LAN, ảnh đầu khi offline trong 10 s; không máy nào bị đổi Wi-Fi. **Công:** ước lượng sau G7.

## Công tổng

Khoảng 22 person-month cho Phase 1 tới 5; Phase 6 thêm khoảng 1.5. Hai người làm khoảng 11 tháng. Ba người làm khoảng 7.5 tháng. MVP (Phase 1) khoảng 2 tháng với hai người. Dùng được clipboard và SMS (Phase 1 cùng Phase 2) khoảng 4 tháng với hai người.

| Phase | Android | macOS | iOS | Server | Test | Tổng |
|-------|:-------:|:-----:|:---:|:------:|:----:|:----:|
| P1 | 1.5 | 1.5 | — | — | 0.5 | 3.5 |
| P2 | 1 | 0.5 | 1 | 1 | 0.5 | 4 |
| P3 | 1 | 1 | 0.5 | — | 0.5 | 3 |
| P4 | 2 | 2 | — | 0.5 | 1.5 | 6 |
| P5 | 2 | 2.5 | — | — | 1 | 5.5 |
| P6 | 0.6 | 0.4 | 0.1 | — | 0.4 | 1.5 |
