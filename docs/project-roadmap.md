# HandLive — Roadmap

> **Nguồn:** `plans/20260924-definitive-architecture/plan.md` mục 8 & 11. **Kế hoạch triển khai** (thẻ việc cho agent, Phase 0 khung và dùng chung, cổng, ma trận máy): `plans/20260925-implementation/plan.md`.

Xây **theo thứ tự** — mỗi phase là một sản phẩm dùng được, phase sau phụ thuộc hạ tầng phase trước (WebSocket + pairing + crypto từ Phase 1 dùng lại cho tất cả).

## Phase 1 — Clipboard Sync (MVP)

Android FG service + Ktor WS server + mDNS (`NsdManager`/`NWBrowser`) + QR pairing + XChaCha20 E2E ↔ macOS menu-bar app. Text + image (chunked), auto-clear 60s, capability negotiation.
**Đo:** text <50ms LAN, ảnh 5MB <2s, reconnect <3s. **Effort:** ~3.5 pm.

## Phase 2 — SMS Bridge

Android SMS receiver + sender, macOS/iOS chat UI, history sync (50 msg/contact), **app iOS** (clipboard+SMS), **cloud relay** Rust cho ngoài LAN, APNs/FCM push.
**Đo:** notification <500ms, reply confirmed <2s. **Effort:** ~4 pm.

## Phase 3 — Call Metadata + Control

Android dùng API Telecom công khai (`TelephonyCallback`, `acceptRingingCall`/`endCall` — không `InCallService`, D9), macOS floating `NSPanel` kèm thông báo liên lạc, answer/reject qua Wi-Fi; hold/DTMF/mute qua HFP ở Phase 4; call history; iOS metadata display.
**Đo:** incoming notification <200ms, answer <500ms E2E. **Effort:** ~3 pm.

## Phase 4 — Call Audio Relay

**Bắt đầu bằng spike HFP 1 tuần.** BT HFP AG↔HF + SCO routing + `AUVoiceProcessingIO` AEC, Opus/WS fallback (E2E hai lớp), adaptive jitter buffer, HFP conflict detection; đường HFP dựa vào mã hóa liên kết Bluetooth (D11); disclosure UI (legal).
**Đo:** MOS ≥3.5 BT / ≥3.0 WS; echo return loss >40dB. **Effort:** ~6 pm.

## Phase 5 — Camera & Mic Virtual Devices

**Bắt đầu bằng spike CMIOExtension 1 tuần.** Android Camera2+MediaCodec pipeline + WiFi video channel + USB auto-detect + adaptive quality (thermal). macOS CMIOExtension + VideoToolbox decode + AudioServerPlugin + PKG installer.
**Đo:** latency <120ms WiFi / <70ms USB. **Effort:** ~5.5 pm.

## Effort tổng

~22 person-months. Team 2 người ~11 tháng; team 3 người ~7.5 tháng. MVP (P1) ~2 tháng/2 người; usable (P1+P2) ~4 tháng/2 người.

| Phase | Android | macOS | iOS | Server | Test | Tổng |
|-------|:-------:|:-----:|:---:|:------:|:----:|:----:|
| P1 | 1.5 | 1.5 | — | — | 0.5 | 3.5 |
| P2 | 1 | 0.5 | 1 | 1 | 0.5 | 4 |
| P3 | 1 | 1 | 0.5 | — | 0.5 | 3 |
| P4 | 2 | 2 | — | 0.5 | 1.5 | 6 |
| P5 | 2 | 2.5 | — | — | 1 | 5.5 |
