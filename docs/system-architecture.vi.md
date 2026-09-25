[English](system-architecture.md) | Tiếng Việt

# HandLive — System Architecture

> **Nguồn chân lý:** `plans/20260924-definitive-architecture/plan.md` (đọc §13 D9–D12 trước). File
> này là bản tóm tắt điều hướng; khi có xung đột, plan gốc thắng. Thiết kế chi tiết từng chức năng:
> `docs/detailed-design/`.

## 1. Triết lý

WebSocket là kênh truyền chính cho *mọi* dữ liệu. Bluetooth HFP chỉ làm một việc: relay audio cuộc
gọi cellular sang macOS (Android 10+ chặn call-audio capture qua API công khai — HFP là con đường
duy nhất đã chứng minh). Mỗi feature độc lập: một feature hỏng không kéo theo feature khác.

## 2. Sơ đồ

```
ANDROID (Audio Gateway role)
  Clipboard / SMS / Call control / Camera+Mic ──▶ Ktor WebSocket server (+ mDNS)
  Call audio ──▶ BT HFP AG + SCO
        │ TLS/WSS (XChaCha20 E2E)          │ SCO audio (mã hóa liên kết BT — D11)
        ▼                                  ▼
   LAN / Cloud Relay (Rust)          BT direct link (~10m)
        │                                  │
   ┌────┴─────┬──────────┐                 ▼
  iOS       iPadOS      macOS (Hands-Free role: WS client + BT HFP HF)
 (WS only) (WS only)   clipboard + SMS + call + audio + virtual cam/mic
```

## 3. Thành phần & vai trò

- **Android** — Audio Gateway (AG) bằng stack Bluetooth chuẩn. Ktor WS server, Camera2+MediaCodec,
  `TelecomManager` + `TelephonyCallback` (không dùng `InCallService` — D9), Shizuku (tùy chọn) cho
  đường âm thanh Opus/WS (D10), Tink crypto, libopus (JNI). Chạy Foreground Service
  (`FOREGROUND_SERVICE_CONNECTED_DEVICE`, Android 14+).
- **macOS** — Hands-Free (HF). `URLSessionWebSocketTask` + Bonjour, `IOBluetoothHandsFreeDevice`,
  `AUVoiceProcessingIO` (AEC), CryptoKit, CMIOExtension (virtual camera) + AudioServerPlugin
  (virtual mic), VideoToolbox.
- **iOS/iPadOS** — WS client + APNs alert + Notification Service Extension (metadata display; không
  PushKit/CallKit — detailed design C7). Clipboard + SMS + call metadata.
- **Cloud relay** — Rust/Actix-web, zero-knowledge: chỉ relay encrypted blob, không decrypt/log
  payload; metadata tối thiểu (device_id hashed, timestamp, size); auto-xóa sau 30 ngày.

## 4. Transport layer

| Feature | Transport chính | Fallback | Latency mục tiêu |
|---------|-----------------|----------|------------------|
| Clipboard text | WebSocket LAN | Cloud relay | <50ms |
| Clipboard image | WS LAN (chunked 64KB) | Cloud relay | <2s / 5MB |
| SMS | WebSocket LAN | Cloud relay | <200ms |
| Call metadata | WebSocket LAN | Cloud relay | <200ms |
| Call audio | BT HFP SCO (mSBC 16kHz) | Opus/WS LAN → Opus/relay | <40ms BT, <150ms WS |
| Notifications | WebSocket LAN | APNs/FCM | <500ms |
| Camera/mic video | WiFi WS binary (kênh RIÊNG) | USB ADB-forward (boost) | <120ms / <70ms |

## 5. Protocol

**Envelope (JSON, plaintext):** `{v, type, id (uuid-v7), ts (ms), payload (base64 encrypted)}`.
`type` ∈ `clipboard|sms|call_event|call_audio|pair|ack|ping|capability`.

**Audio binary frame** (không JSON-wrap để giảm overhead):
`[0x48 0x4C][version:1B][seq:4B][timestamp:4B][encrypted_opus_frame:NB]`.

**Pairing (QR):** macOS/iOS tạo X25519 keypair + 32-byte secret → QR `handlive://pair?pk=…&ps=…&d=…`
→ Android scan → ECDH + HKDF-SHA256 derive session key → HMAC verify. Fallback: 6-digit PIN +
Argon2id.

**Capability negotiation:** mỗi device gửi `type:"capability"` khi kết nối; feature chỉ bật khi *cả
hai* hỗ trợ.

**Conflict resolution:** clipboard last-writer-wins theo `ts`; nếu |Δts|<500ms → giữ local + gửi
`conflict`. SMS: optimistic send + retry.

## 6. Security

- Transport: TLS 1.3 (LAN self-signed pinned / cloud Let's Encrypt pinned); BT SSP P-256.
- App E2E: XChaCha20-Poly1305 (256-bit, 24-byte nonce) mọi payload.
- Key exchange: X25519 ECDH + HKDF-SHA256; forward secrecy ratchet mỗi 24h / 10k messages.
- Key storage: Android Keystore (StrongBox), macOS/iOS Keychain (`…WhenUnlockedThisDeviceOnly`).
- **Audio:** đường HFP chỉ có mã hóa liên kết Bluetooth — ứng dụng không chạm được khung SCO của
  cuộc gọi di động (D11), rủi ro KNOB/BIAS được công bố khi bật tính năng; đường Opus/WS mã hóa hai
  lớp TLS + E2E.

## 7. Call audio

Primary: HFP SCO với AT commands chuẩn (HFP 1.8) — `ATA` answer, `AT+CHUP` hangup, `AT+CHLD=2` hold,
`AT+VTS` DTMF; Android gửi `+CLIP` /`+CIEV`. Echo cancel qua `AUVoiceProcessingIO` (macOS) +
`VOICE_COMMUNICATION` source (Android).

Fallback: Opus 16kHz mono 32kbps 20ms frame qua WS binary; adaptive jitter buffer 40–120ms. Chạy qua
Shizuku (uid shell): Android 10 không khả thi, Android 11+ thu được trên một số máy, chèn giọng chỉ
Android 13+ và chưa kiểm chứng (D10). Phát hiện HFP conflict qua
`getProfileConnectionState(HEADSET)`. Điều khiển cuộc gọi qua Wi-Fi dùng API công khai (trả lời/từ
chối/kết thúc); giữ máy/DTMF/tắt tiếng qua lệnh HFP (D9).

## 8. Camera/mic (Phase 5)

Android Camera2→Surface→MediaCodec (H.264 HW, Constrained Baseline, low-latency flags) + AudioRecord
48kHz→libopus. macOS VideoToolbox decode → IOSurface zero-copy → CMIOExtension source stream; audio
Opus→PCM→AudioServerPlugin ring buffer. IPC: video qua CMIOExtension sink (zero-copy), audio theo mô
hình loopback của BlackHole (M-APP phát vào thiết bị ra ẩn, driver chuyển sang thiết bị vào
"HandLive Microphone" qua ring buffer chung — thay POSIX shm, xem `docs/detailed-design/README.md`
C8). Chi tiết IPC: `plans/20260924-ipc-research/plan.md`.

## 9. Risk register

Xem mục 9 & 10.8 trong plan gốc: R1 IOBluetooth deprecate, R2 `BluetoothHeadsetClient` khóa, R3 Play
Store SMS, R4 Opus latency, R5 OEM fragmentation, R6 CMIOExtension compat, R7 MediaCodec
fragmentation, R8 AudioServerPlugin signing. Mọi BT-HFP call phải nằm sau abstraction
(`CallAudioRelay`) để fallback/migration.
