English | [Tiếng Việt](system-architecture.vi.md)

# HandLive — System Architecture

> **Source of truth:** `plans/20260924-definitive-architecture/plan.md` (read §13 D9–D12 first). This
> file is a navigation summary; when the two conflict, the original plan wins. Detailed design of each
> function: `docs/detailed-design/`.

## 1. Philosophy

WebSocket is the primary transport for *all* data. Bluetooth HFP does one thing only: relaying
cellular call audio to macOS (Android 10+ blocks call-audio capture through public APIs — HFP is the
only proven path). Every feature is independent: one broken feature does not drag another down.

## 2. Diagram

```
ANDROID (Audio Gateway role)
  Clipboard / SMS / Call control / Camera+Mic ──▶ Ktor WebSocket server (+ mDNS)
  Call audio ──▶ BT HFP AG + SCO
        │ TLS/WSS (XChaCha20 E2E)          │ SCO audio (BT link encryption — D11)
        ▼                                  ▼
   LAN / Cloud Relay (Rust)          BT direct link (~10m)
        │                                  │
   ┌────┴─────┬──────────┐                 ▼
  iOS       iPadOS      macOS (Hands-Free role: WS client + BT HFP HF)
 (WS only) (WS only)   clipboard + SMS + call + audio + virtual cam/mic
```

## 3. Components & roles

- **Android** — Audio Gateway (AG) through the stock Bluetooth stack. Ktor WS server, Camera2+MediaCodec,
  `TelecomManager` + `TelephonyCallback` (no `InCallService` — D9), Shizuku (optional) for the
  Opus/WS audio path (D10), Tink crypto, libopus (JNI). Runs a Foreground Service
  (`FOREGROUND_SERVICE_CONNECTED_DEVICE`, Android 14+).
- **macOS** — Hands-Free (HF). `URLSessionWebSocketTask` + Bonjour, `IOBluetoothHandsFreeDevice`,
  `AUVoiceProcessingIO` (AEC), CryptoKit, CMIOExtension (virtual camera) + AudioServerPlugin
  (virtual mic), VideoToolbox.
- **iOS/iPadOS** — WS client + APNs alert + Notification Service Extension (metadata display; no
  PushKit/CallKit — detailed design C7). Clipboard + SMS + call metadata.
- **Cloud relay** — Rust/Actix-web, zero-knowledge: only relays encrypted blobs, never decrypts/logs
  payloads; minimal metadata (hashed device_id, timestamp, size); auto-deleted after 30 days.

## 4. Transport layer

| Feature | Primary transport | Fallback | Target latency |
|---------|-------------------|----------|----------------|
| Clipboard text | WebSocket LAN | Cloud relay | <50ms |
| Clipboard image | WS LAN (chunked 64KB) | Cloud relay | <2s / 5MB |
| SMS | WebSocket LAN | Cloud relay | <200ms |
| Call metadata | WebSocket LAN | Cloud relay | <200ms |
| Call audio | BT HFP SCO (mSBC 16kHz) | Opus/WS LAN → Opus/relay | <40ms BT, <150ms WS |
| Notifications | WebSocket LAN | APNs/FCM | <500ms |
| Camera/mic video | WiFi WS binary (SEPARATE channel) | USB ADB-forward (boost) | <120ms / <70ms |

## 5. Protocol

**Envelope (JSON, plaintext):** `{v, type, id (uuid-v7), ts (ms), payload (base64 encrypted)}`.
`type` ∈ `clipboard|sms|call_event|call_audio|pair|ack|ping|capability`.

**Audio binary frame** (not JSON-wrapped, to cut overhead):
`[0x48 0x4C][version:1B][seq:4B][timestamp:4B][encrypted_opus_frame:NB]`.

**Pairing (QR):** macOS/iOS generates an X25519 keypair + 32-byte secret → QR `handlive://pair?pk=…&ps=…&d=…`
→ Android scans → ECDH + HKDF-SHA256 derive the session key → HMAC verify. Fallback: 6-digit PIN +
Argon2id.

**Capability negotiation:** each device sends `type:"capability"` on connect; a feature turns on only
when *both* support it.

**Conflict resolution:** clipboard last-writer-wins by `ts`; if |Δts|<500ms → keep local + send
`conflict`. SMS: optimistic send + retry.

## 6. Security

- Transport: TLS 1.3 (LAN self-signed pinned / cloud Let's Encrypt pinned); BT SSP P-256.
- App E2E: XChaCha20-Poly1305 (256-bit, 24-byte nonce) on every payload.
- Key exchange: X25519 ECDH + HKDF-SHA256; forward secrecy ratchet every 24h / 10k messages.
- Key storage: Android Keystore (StrongBox), macOS/iOS Keychain (`…WhenUnlockedThisDeviceOnly`).
- **Audio:** the HFP path has Bluetooth link encryption only — apps cannot touch the SCO frames of
  cellular calls (D11), and the KNOB/BIAS risk is disclosed when the feature is turned on; the
  Opus/WS path is encrypted in two layers, TLS + E2E.

## 7. Call audio

Primary: HFP SCO with standard AT commands (HFP 1.8) — `ATA` answer, `AT+CHUP` hangup, `AT+CHLD=2` hold,
`AT+VTS` DTMF; Android sends `+CLIP` /`+CIEV`. Echo cancel via `AUVoiceProcessingIO` (macOS) +
the `VOICE_COMMUNICATION` source (Android).

Fallback: Opus 16kHz mono 32kbps 20ms frames over WS binary; adaptive jitter buffer 40–120ms. Runs
through Shizuku (shell uid): not feasible on Android 10, capture works on some Android 11+ devices,
voice injection only on Android 13+ and not yet verified (D10). HFP conflicts detected via
`getProfileConnectionState(HEADSET)`. Call control over Wi-Fi uses public APIs (answer/decline/end);
hold/DTMF/mute go through HFP commands (D9).

## 8. Camera/mic (Phase 5)

Android Camera2→Surface→MediaCodec (H.264 HW, Constrained Baseline, low-latency flags) + AudioRecord
48kHz→libopus. macOS VideoToolbox decode → IOSurface zero-copy → CMIOExtension source stream; audio
Opus→PCM→AudioServerPlugin ring buffer. IPC: video through the CMIOExtension sink (zero-copy), audio
following BlackHole's loopback model (M-APP plays into a hidden output device, the driver passes it to
the "HandLive Microphone" input device through a shared ring buffer — instead of POSIX shm, see
`docs/detailed-design/README.md` C8). IPC details: `plans/20260924-ipc-research/plan.md`.

## 9. Risk register

See sections 9 & 10.8 in the original plan: R1 IOBluetooth deprecation, R2 `BluetoothHeadsetClient`
locked down, R3 Play Store SMS, R4 Opus latency, R5 OEM fragmentation, R6 CMIOExtension compat, R7
MediaCodec fragmentation, R8 AudioServerPlugin signing. Every BT-HFP call must sit behind an
abstraction (`CallAudioRelay`) for fallback/migration.
