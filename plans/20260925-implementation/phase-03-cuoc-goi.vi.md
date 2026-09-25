[English](phase-03-cuoc-goi.md) | Tiếng Việt

# Phase 3 — Thông tin và điều khiển cuộc gọi

**Mục tiêu:** Mac và iPhone/iPad biết ai đang gọi; Mac trả lời, từ chối, từ chối kèm tin nhắn, kết
thúc qua Wi-Fi; nhật ký cuộc gọi và cuộc gọi nhỡ đồng bộ. Giữ máy, DTMF, tắt tiếng để Phase 4 (HFP).

## Ngữ cảnh

- Chức năng lá: `06-call-control.md` CALL-01 (kể cả API 7 thông báo liên lạc trên Mac), CALL-02,
  CALL-03 (phần qua WebSocket), CALL-04.
- Design system: thành phần `CallPanel`, `Notification`, `MenuBarMenu`;
  `2-patterns/03-thong-bao.md`; `3-platforms/01-macos.md` (Tập trung, phím tắt).
- Quyết định: D9/C12 (API Telecom công khai, không `InCallService`), C19 (Tập trung → không panel;
  panel là lệch có chủ đích so với HIG).

## Yêu cầu và tiêu chí đo

- `call_event/state` tới Mac < 200 ms trong LAN; trả lời < 500 ms đầu-cuối.
- Không đổ chuông khi chưa đọc được trạng thái Tập trung; Tập trung bật → chỉ thông báo liên lạc.
- Không log số điện thoại, tên.

## Thẻ việc

| Mã | Việc | Đầu ra | Tiêu chí chấp nhận |
|----|------|--------|--------------------|
| A3.1 [android] | `TelephonyCallback`/`PhoneStateListener` + broadcast `PHONE_STATE`, ngữ cảnh `call_id`, tra tên `PhoneLookup` (cache LRU), `controls` theo quyền, `call_event/state` cho từng phiên (CALL-01); `acceptRingingCall`/`endCall` (CALL-02, CALL-03 E2 `CALL_HFP_REQUIRED`); nhật ký `CallLog` (CALL-04) | `android/feature/call` | Số đến sau lượt `RINGING` đầu vẫn gửi lại (E10); hai SIM có nhãn; test giả lập Telephony |
| A3.2 [android] | Push `call_incoming` và `call_missed` qua relay cho iPhone (CALL-01 bước 5, CALL-04 API 5); mở relay chờ lệnh từ chối | `android/feature/call` | Push trong < 300 ms sau khi có số |
| M3.1 [macOS] | `CallPanel`: `NSPanel` non-activating nổi trên mọi Space, trạng thái đổ chuông/đang gọi/kết thúc, phím Return/⌘⌫/Esc, chuông `NSSound` theo `call.ringtone`, `INFocusStatusCenter` (`NSFocusStatusUsageDescription`), VoiceOver | `apple/macOS/HandLive` | Panel < 300 ms sau `RINGING`; Tập trung bật → không panel, không chuông |
| M3.2 [macOS] | Thông báo liên lạc `INStartCallIntent` (CALL-01 API 7): passive khi có panel, time-sensitive khi Tập trung; hành động "Trả lời", "Từ chối"; gỡ khi `state` đổi; cuộc gọi nhỡ với "Nhắn tin" (CALL-04 API 6) | app | Không hiện hai lớp cho một cuộc gọi; hành động chạy không cần mở cửa sổ |
| M3.3 [macOS] | Từ chối kèm tin nhắn (mẫu `call.quick_replies`, CALL-02 API 5), mục Cuộc gọi trong thanh bên cửa sổ Tin nhắn (CALL-04), cài đặt pane Cuộc gọi, mục cuộc gọi trong menu thanh menu khi "Bỏ qua" | app | Chuỗi và vị trí nút theo `CallPanel` README |
| I3.1 [iOS] | Thông báo cuộc gọi đến: I-NSE dựng `INStartCallIntent`, danh mục `HL_CALL_INCOMING` với "Từ chối" (CALL-02 B), banner trong app khi đang mở; tab Cuộc gọi với nhật ký và cuộc gọi nhỡ | `apple/iOS` | Từ chối từ thông báo tới điện thoại < 2 s qua relay; máy khóa hiện nội dung chung |
| T3.1 [test] | Bench trễ `RINGING → panel` và `answer → OFFHOOK`; kịch bản cuộc gọi chờ (E9), hai SIM, Tập trung bật | `tools/bench/`, `reports/` | Đạt mục tiêu trên Pixel và Samsung |

## Kiểm thử

- Đơn vị: máy trạng thái ngữ cảnh cuộc gọi (`ringing → offhook → idle`, `waiting`), tính `controls`,
  chống trùng `call_id`.
- Tay: cuộc gọi thật giữa hai SIM; AirPods đang nối (không ảnh hưởng ở phase này).

## Rủi ro và quay lui

- `acceptRingingCall` /`endCall` đã deprecated từ API 29 nhưng vẫn hoạt động; nếu OEM chặn → chỉ còn
  từ chối/kết thúc qua HFP (Phase 4), ghi vào deployment-guide theo máy.
- Thiếu `READ_CALL_LOG` (Play từ chối) → "Không rõ số" (E2), vẫn dùng được.
