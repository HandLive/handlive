# HandLive — Product Definition & Requirements

> **Ngày:** 2026-09-24 · **Trạng thái:** Pre-implementation

## 1. Vấn đề

Người dùng Android không có trải nghiệm liền mạch giữa điện thoại và máy tính như Apple Continuity hay Microsoft Phone Link (Android↔Windows). HandLive lấp khoảng trống này cho **Android ↔ macOS/iOS**, tập trung vào ba luồng bị thiếu nhất: audio cuộc gọi, camera/mic, và đồng bộ dữ liệu thời gian thực — tất cả với E2E encryption.

## 2. Mục tiêu

- Đồng bộ clipboard 2 chiều, độ trễ text <50ms LAN.
- Nhận/gửi SMS từ macOS và iOS.
- Nhận, điều khiển, và **nghe/nói cuộc gọi** ngay trên macOS.
- Dùng camera + mic của Android như thiết bị ảo trong Zoom/Meet/FaceTime/OBS.
- Bảo mật E2E không thể tắt; không có server nào đọc được nội dung.

## 3. Phi mục tiêu (Non-goals)

- Call audio relay trên iOS (Apple không có public HFP HF API) — iOS chỉ clipboard + SMS + call metadata.
- Ghi âm cuộc gọi — chỉ relay realtime, không lưu.
- Stream media/nhạc chất lượng cao qua HFP (kênh này mono 8/16kHz).

## 4. Người dùng mục tiêu

Mass-market (không phải chỉ dev). Hệ quả thiết kế then chốt: **zero-config, hoàn toàn không dây** là mặc định. Mọi thứ đòi hỏi setup ADB/USB/Shizuku chỉ là tùy chọn "boost" cho power user, không bao giờ bắt buộc để dùng tính năng cốt lõi.

## 5. Ràng buộc & nền tảng

| Nền tảng | Yêu cầu tối thiểu |
|----------|-------------------|
| Android | minSdk 29 (Android 10), targetSdk 35 |
| macOS | 13+ |
| iOS/iPadOS | 16+ |
| Cloud relay | Rust/Actix-web, tự host VPS ban đầu |

## 6. Quyết định sản phẩm đã chốt

Xem đầy đủ mục 12 (D1–D8) trong `plans/20260924-definitive-architecture/plan.md`. Tóm tắt:

- **D1:** Call audio dùng dual-path — spike HFP 1 tuần; fail → Opus/WS permanent.
- **D2:** Disclosure-first cho call relay (two-party consent), không block ship chờ legal.
- **D3:** `BluetoothHeadsetClient` @SystemApi + Shizuku ngay; monitor CompanionDeviceManager.
- **D4:** Clipboard background dùng Accessibility Service (Plan B: Notification Listener).
- **D5:** Cloud relay self-host 1 VPS; migrate managed khi >500 concurrent users.
- **D6:** CMIOExtension spike tuần 1 Phase 5.
- **D7:** AudioServerPlugin phân phối qua PKG notarized + Homebrew cask.
- **D8:** USB boost qua ADB + wizard; UVC native để dành v2.

## 7. Chỉ số thành công (đo được)

- Clipboard text <50ms LAN; ảnh 5MB <2s; reconnect <3s.
- SMS notification lên macOS <500ms; reply confirmed <2s.
- Incoming call notification <200ms; answer latency <500ms E2E.
- Call audio MOS ≥3.5 (BT) / ≥3.0 (WebSocket); echo return loss >40dB.
- Camera/mic latency <120ms WiFi / <70ms USB.

## Câu hỏi mở

- Cấu trúc repo mono-repo hay tách theo nền tảng (chưa quyết) — ảnh hưởng build tooling.
- Legal review wording cho disclosure call-audio (thuê luật sư, song song dev).
