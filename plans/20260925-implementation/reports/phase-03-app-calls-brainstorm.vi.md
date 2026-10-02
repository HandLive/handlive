---
type: brainstorm-report
date: 2026-10-01
status: approved-design
branch: feat/phase-03-app-calls
---

# Brainstorm: cuộc gọi của app khác (Telegram, Zalo, WhatsApp…) trên Mac

Bản tiếng Anh (bản chuẩn): `phase-03-app-calls-brainstorm.md`.

## 1. Vấn đề

Ngày 2026-10-01, chủ dự án đang ngồi ở Mac thì có cuộc gọi Telegram đổ chuông trên S25, nhưng HandLive không hiện gì.
Lý do:
- Phase 3 chỉ thấy cuộc gọi di động: CALL-01…04 đọc trạng thái gộp của telephony và không dùng `InCallService`
  (quyết định C12).
- App VoIP chạy cuộc gọi tự quản, nên Telephony API công khai không thấy.

Mục tiêu: thấy ai gọi từ bất kỳ app gọi điện nào và xử lý ngay trên Mac — kể cả **nghe và nói chuyện trên Mac** —
giống "Calls on Other Devices" của iPhone.

## 2. Bằng chứng thu được trên S25 (Android 16, One UI) + Mac này (macOS 27), với Telegram

| Kiểm tra | Kết quả |
|---|---|
| Liên kết HFP Mac (HF) ↔ S25 | Kết nối service-level trong 0,8–1,2 s, sau khi làm mới cache SDP trên Mac |
| Cuộc gọi Telegram qua HFP | **Không được báo** (không có `+CIEV call/callsetup`; `AT+CLCC` lỗi trên điện thoại) |
| Âm thanh Telegram | Ở lại loa trong của điện thoại. Telegram không cho chọn Bluetooth dù AudioService có liệt kê Mac là `bt_sco`; điện thoại không thử mở SCO |
| Thông báo cuộc gọi đến của Telegram | **`CallStyle`**: `category=call`, `android.callType=1`, `android.callPerson`, `android.declineIntent` (broadcast), `android.answerIntent` (mở activity) |
| App khác thu âm thanh VoIP | Không thể (Android chặn thu `VOICE_COMMUNICATION`) → Opus/WS không chở được âm thanh cuộc gọi app |

## 3. Các hướng

| Hướng | Kết luận |
|---|---|
| **A. NotificationListenerService đọc thông báo `CallStyle`**, bấm nút qua chính PendingIntent của thông báo | **Được chọn** — một cơ chế cho mọi app đăng `CallStyle`; giữ nguyên C12 |
| B. `InCallService` qua vai trò "watch" của CompanionDeviceManager | Loại — đảo ngược C12, rủi ro chính sách Play |
| C. Dựa vào app bản Mac của từng hãng | Loại — không có trải nghiệm HandLive thống nhất |

## 4. Thiết kế đã duyệt (v1, chỉ Mac)

**Android (A-CALL):**
- Một `NotificationListenerService` mới trong `feature/call`, chỉ xử lý thông báo có `category=call` hoặc extras kiểu
  `CallStyle`. Mọi thông báo khác bị bỏ ngay; không lưu, không ghi log.
- Mỗi khóa thông báo giữ một ngữ cảnh cuộc gọi app:
  - package và tên app;
  - tên người gọi (`callPerson` hoặc tiêu đề);
  - trạng thái theo `callType` (1 = đổ chuông, 2 = đang gọi); kết thúc khi thông báo bị gỡ.
- Thực hiện nút bằng cách gửi đúng intent của app:
  - từ chối → `declineIntent`;
  - nghe → `answerIntent` (mở activity từ nền, gửi kèm tùy chọn cho phép mở activity từ nền; dự kiến Accessibility
    service của HandLive giúp được miễn hạn chế — cần spike);
  - kết thúc → `hangUpIntent`.

**Âm thanh trên Mac** (nghe với `audio = mac`):
- Sau khi nghe máy, A-CALL yêu cầu Android đưa âm thanh liên lạc sang thiết bị Bluetooth HFP là Mac
  (`AudioManager.setCommunicationDevice`); Mac phát qua stack HFP.
- Phụ thuộc hai điều kiện:
  1. spike chứng minh Android nhận yêu cầu của HandLive trong lúc Telegram đang giữ cuộc gọi;
  2. đường âm thanh HFP của Mac ở Phase 4 chạy được (G4: SCO chưa thử được vì không có SIM).
- Nếu không đạt thì vẫn nghe máy, âm thanh ở điện thoại, và panel trên Mac ghi rõ điều đó.

**Giao thức:**
- Thêm op mới `call_event/app_call` (S→C, schema riêng), chỉ gửi tới client có capability
  `features.call.app_calls = true`.
- Không đụng `call_event/state`: schema của nó có `additionalProperties: false`, nên giữ nguyên để client Phase 3 đã
  phát hành vẫn tương thích.
- Nút bấm dùng lại `call_event/action` (`answer` kèm `audio`, `reject`, `end`), phân biệt theo `call_id` của cuộc gọi
  app; thêm một mã lỗi cho trường hợp "thông báo không có nút đó".
- Khóa cài đặt `call.app_calls`. Luồng thiết lập trên Android xin quyền "Truy cập thông báo", có màn hình giải thích
  quyền riêng tư (SET-01/SET-02).

**Mac (M-APP):** dùng lại panel cuộc gọi đến và panel đang gọi, kèm tên app. Có các nút Nghe (âm thanh trên Mac khi
có HFP và chuyển tuyến được), Từ chối, Kết thúc.

## 5. Tiêu chí nghiệm thu (LAN, phân vị 95)

| # | Tiêu chí |
|---|---|
| AC1 | Panel trên Mac hiện ≤ 200 ms sau khi app đăng thông báo cuộc gọi, có tên app và tên người gọi |
| AC2 | Từ chối hoặc Kết thúc từ Mac có hiệu lực trên điện thoại ≤ 500 ms |
| AC3 | Nghe từ Mac làm điện thoại bắt máy ≤ 1 s |
| AC4 | Khi có HFP và spike đạt: âm thanh trên Mac ≤ 1,5 s sau khi bấm Nghe; nếu không thì âm thanh ở điện thoại và panel ghi rõ |
| AC5 | Không thông báo nào khác rời điện thoại; log không bao giờ chứa tên hay số |
| AC6 | Thiếu quyền Truy cập thông báo thì tính năng tắt và có giải thích; tính năng cuộc gọi di động không bị ảnh hưởng |

Relay: cố gắng tốt nhất. Ngoài phạm vi: iPhone/iPad, gọi đi từ Mac, nhật ký cuộc gọi app, cuộc gọi video; Zalo và
WhatsApp kiểm sau (hiện chủ dự án chỉ có Telegram).

## 6. Thứ tự làm

1. **Spike (S25 + Telegram, chủ dự án gọi thử):**
   - listener thấy các thông báo `CallStyle`;
   - từ chối/nghe/kết thúc gửi được từ nền;
   - gọi `setCommunicationDevice` sang Mac trong lúc đang nghe Telegram, với `HFPSpike` đang kết nối (SCO có mở không,
     Mac có nhận âm thanh không);
   - đo thời gian cho AC1–AC4.
2. Spec: CALL-05 trong `06-call-control` (+ `.vi.md`), `00-common-specs` (op, capability, lỗi, cài đặt, chuỗi).
3. `shared`: schema cho `call_event/app_call`, cập nhật capability và action, chuỗi giao diện.
4. Android, rồi Mac; viết test trước cho bộ đọc thông báo, bộ phát nút và phần chặn theo capability.
5. E2e trên thiết bị thật với Telegram; G4/Phase 4 quyết định phần âm thanh trên Mac.

## 7. Rủi ro

- Không mở được activity từ nền cho `answerIntent` → dùng một trampoline của HandLive hoặc lời nhắc toàn màn hình; đo
  ở spike.
- App không dùng `CallStyle` → lùi về `category=call` + tên nút; nếu vẫn không được thì không hỗ trợ (liệt kê theo
  app).
- Android bỏ qua yêu cầu chuyển thiết bị liên lạc của HandLive → cuộc gọi app không có âm thanh trên Mac (phương án lùi
  của AC4).
- Truy cập thông báo là quyền rộng → lọc chặt, có lời giải thích, có văn bản khai báo cho Play.

## Câu hỏi còn mở

1. Android 16 có nhận `setCommunicationDevice` từ app không phải chủ cuộc gọi, trong lúc app khác đang gọi không?
   (spike)
2. Gửi `answerIntent` của Telegram từ HandLive khi đang chạy nền có mở được màn hình cuộc gọi trên điện thoại đang khóa
   không? (spike)
3. Cấu trúc `CallStyle` của Zalo/WhatsApp (kiểm sau, trên thiết bị của chủ dự án).
