# HandLive — System Architecture

> **Nguồn chân lý:** `plans/20260924-definitive-architecture/plan.md`. File này là bản tóm tắt điều hướng; khi có xung đột, plan gốc thắng.

## 1. Triết lý

WebSocket là kênh truyền chính cho *mọi* dữ liệu. Bluetooth HFP chỉ làm một việc: relay audio cuộc gọi cellular sang macOS (Android 10+ chặn call-audio capture qua API công khai — HFP là con đường duy nhất đã chứng minh). Mỗi feature độc lập: một feature hỏng không kéo theo feature khác.

## 2. Sơ đồ

```
ANDROID (Audio Gateway role)
  Clipboard / SMS / Call control / Camera+Mic ──▶ Ktor WebSocket server (+ mDNS)
  Call audio ──▶ BT HFP AG + SCO
        │ TLS/WSS (XChaCha20 E2E)          │ SCO audio (+ app-level E2E)
        ▼                                  ▼
   LAN / Cloud Relay (Rust)          BT direct link (~10m)
        │                                  │
   ┌────┴─────┬──────────┐                 ▼
  iOS       iPadOS      macOS (Hands-Free role: WS client + BT HFP HF)
 (WS only) (WS only)   clipboard + SMS + call + audio + virtual cam/mic
```

## 3. Thành phần & vai trò

- **Android** — Audio Gateway (AG). Ktor WS server, Camera2+MediaCodec, `InCallService`/`TelecomManager`, `BluetoothHeadsetClient` (@SystemApi qua Shizuku), Tink crypto, libopus (JNI). Chạy Foreground Service (`FOREGROUND_SERVICE_CONNECTED_DEVICE`, Android 14+).
- **macOS** — Hands-Free (HF). `URLSessionWebSocketTask` + Bonjour, `IOBluetoothHandsFreeDevice`, `AUVoiceProcessingIO` (AEC), CryptoKit, CMIOExtension (virtual camera) + AudioServerPlugin (virtual mic), VideoToolbox.
- **iOS/iPadOS** — WS client + APNs/PushKit (metadata display, không ring). Clipboard + SMS + call metadata.
- **Cloud relay** — Rust/Actix-web, zero-knowledge: chỉ relay encrypted blob, không decrypt/log payload; metadata tối thiểu (device_id hashed, timestamp, size); auto-xóa sau 30 ngày.

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

**Envelope (JSON, plaintext):** `{v, type, id (uuid-v7), ts (ms), payload (base64 encrypted)}`. `type` ∈ `clipboard|sms|call_event|call_audio|pair|ack|ping|capability`.

**Audio binary frame** (không JSON-wrap để giảm overhead): `[0x48 0x4C][version:1B][seq:4B][timestamp:4B][encrypted_opus_frame:NB]`.

**Pairing (QR):** macOS/iOS tạo X25519 keypair + 32-byte secret → QR `handlive://pair?pk=…&ps=…&d=…` → Android scan → ECDH + HKDF-SHA256 derive session key → HMAC verify. Fallback: 6-digit PIN + Argon2id.

**Capability negotiation:** mỗi device gửi `type:"capability"` khi kết nối; feature chỉ bật khi *cả hai* hỗ trợ.

**Conflict resolution:** clipboard last-writer-wins theo `ts`; nếu |Δts|<500ms → giữ local + gửi `conflict`. SMS: optimistic send + retry.

## 6. Security

- Transport: TLS 1.3 (LAN self-signed pinned / cloud Let's Encrypt pinned); BT SSP P-256.
- App E2E: XChaCha20-Poly1305 (256-bit, 24-byte nonce) mọi payload.
- Key exchange: X25519 ECDH + HKDF-SHA256; forward secrecy ratchet mỗi 24h / 10k messages.
- Key storage: Android Keystore (StrongBox), macOS/iOS Keychain (`…WhenUnlockedThisDeviceOnly`).
- **Audio dual-layer bắt buộc:** BT link SSP + app-level E2E mỗi SCO frame (BT link crypto đã bị crack — KNOB/BIAS).

## 7. Call audio

Primary: HFP SCO với AT commands chuẩn (HFP 1.8) — `ATA` answer, `AT+CHUP` hangup, `AT+CHLD=2` hold, `AT+VTS` DTMF; Android gửi `+CLIP`/`+CIEV`. Echo cancel qua `AUVoiceProcessingIO` (macOS) + `VOICE_COMMUNICATION` source (Android).

Fallback: Opus 16kHz mono 32kbps 20ms frame qua WS binary; adaptive jitter buffer 40–120ms. Phát hiện HFP conflict qua `getProfileConnectionState(HEADSET)`.

## 8. Camera/mic (Phase 5)

Android Camera2→Surface→MediaCodec (H.264 HW, Constrained Baseline, low-latency flags) + AudioRecord 48kHz→libopus. macOS VideoToolbox decode → IOSurface zero-copy → CMIOExtension source stream; audio Opus→PCM→AudioServerPlugin ring buffer. IPC: video qua CMIOExtension sink (zero-copy), audio qua POSIX shm ring buffer. Chi tiết IPC: `plans/20260924-ipc-research/plan.md`.

## 9. Risk register

Xem mục 9 & 10.8 trong plan gốc: R1 IOBluetooth deprecate, R2 `BluetoothHeadsetClient` khóa, R3 Play Store SMS, R4 Opus latency, R5 OEM fragmentation, R6 CMIOExtension compat, R7 MediaCodec fragmentation, R8 AudioServerPlugin signing. Mọi BT-HFP call phải nằm sau abstraction (`CallAudioRelay`) để fallback/migration.
