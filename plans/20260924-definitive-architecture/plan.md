# HandLive — Kiến trúc Quyết định

> **Tên:** Network-First Modular Architecture  
> **Tagline:** "WebSocket cho dữ liệu, Bluetooth cho giọng nói"  
> **Ngày:** 2026-09-24  
> **Trạng thái:** Quyết định cuối cùng  
> **Cơ sở:** Tổng hợp từ 3 đề xuất (A: Bluetooth-Native, B: Network-First, C: Plugin-Hybrid) qua 3 vòng phản biện (Technical Feasibility, Security & Privacy, UX & Reliability)

---

## 1. Triết lý thiết kế

WebSocket làm kênh truyền chính cho mọi dữ liệu (clipboard, SMS, call metadata, notifications). Bluetooth HFP chỉ dùng cho một việc duy nhất: relay audio cuộc gọi sang macOS — vì đây là cách duy nhất đã chứng minh hiệu quả trên Android 10+. Khi HFP không khả dụng (user đang dùng AirPods, ngoài BT range), fallback sang Opus codec qua WebSocket với latency chấp nhận được (~100-150ms). Mỗi feature hoạt động độc lập — clipboard hỏng không kéo theo SMS chết.

---

## 2. Sơ đồ tổng quan

```
┌─────────────────────────────────────────────────────────────────────┐
│                        ANDROID (AG role)                            │
│                                                                     │
│  ┌────────────┐ ┌─────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐│
│  │ Clipboard  │ │ SMS     │ │ Call     │ │ Call     │ │ Camera   ││
│  │ Monitor    │ │ Bridge  │ │ Control  │ │ Audio    │ │ + Mic    ││
│  └─────┬──────┘ └────┬────┘ └────┬─────┘ └────┬─────┘ └────┬─────┘│
│        │             │           │             │            │      │
│  ┌─────▼─────────────▼───────────▼──────┐ ┌────▼────┐ ┌─────▼────┐│
│  │    WebSocket Server (Ktor)           │ │BT HFP  │ │Camera2  ││
│  │    mDNS broadcast (NsdManager)       │ │AG+SCO  │ │MediaCodec││
│  └──────────────┬───────────────────────┘ └────┬────┘ └─────┬────┘│
│                 │                                      │            │
└─────────────────┼──────────────────────────────────────┼────────────┘
                  │ TLS/WSS                              │ SCO audio
                  │ (XChaCha20-Poly1305 E2E)             │ (+ app E2E)
                  │                                      │
        ┌─────────▼──────────┐                 ┌─────────▼──────────┐
        │   LAN / Cloud      │                 │  BT direct link    │
        │   Relay (Rust)     │                 │  (~10m range)      │
        └─────────┬──────────┘                 └─────────┬──────────┘
                  │                                      │
     ┌────────────┼─────────────────┐                    │
     │            │                 │                    │
┌────▼────┐ ┌────▼────┐      ┌─────▼────────────────────▼─────┐
│  iOS    │ │  iPadOS  │      │          macOS (HF role)       │
│ WS only │ │ WS only  │      │  WebSocket client + BT HFP    │
│ clip+SMS│ │ clip+SMS  │      │  clip + SMS + call + audio    │
└─────────┘ └──────────┘      └────────────────────────────────┘

Fallback khi BT HFP không khả dụng:
  Android ──[Opus/WebSocket]──→ macOS (latency ~100-150ms)
```

---

## 3. Các thành phần

### 3.1 Android App (Kotlin, minSdk 29, targetSdk 35)

| Module | API/Thư viện | Chức năng |
|--------|-------------|-----------|
| `clipboard-monitor` | `ClipboardManager.OnPrimaryClipChangedListener` | Detect clipboard change, gửi qua WebSocket. Foreground service với persistent notification |
| `sms-bridge` | `BroadcastReceiver` (`SMS_RECEIVED`), `ContentResolver` (`Telephony.Sms`), `SmsManager` | Nhận/gửi SMS, đọc history |
| `call-controller` | `TelecomManager`, `InCallService` (Android 10+) | Answer, reject, hold, DTMF. Gửi call metadata qua WebSocket |
| `audio-capture` | `AudioRecord` (SCO source), `MediaCodec` (Opus encoder) | Capture call audio từ SCO, encode Opus cho WebSocket fallback |
| `bt-hfp-manager` | `BluetoothAdapter`, `BluetoothHeadsetClient` (@SystemApi qua Shizuku) | Quản lý HFP AG role, mở SCO link |
| `ws-server` | Ktor 3.x WebSocket server | Serve tất cả data channels. mDNS via `NsdManager` |
| `crypto` | Tink 1.14+ (`XChaCha20Poly1305`, `X25519`) | E2E encryption mọi payload |
| `capability-negotiator` | Custom protocol handler | Trao đổi feature set khi kết nối, version negotiation |

**Foreground Service:** Chạy dạng `FOREGROUND_SERVICE_CONNECTED_DEVICE` (Android 14+). Notification hiển thị trạng thái kết nối.

**Clipboard background access (Android 10+):** Foreground-only là mặc định. Power users có thể dùng Shizuku (`INTERACT_ACROSS_USERS_FULL` grant) hoặc Accessibility Service (backup, UX kém hơn). MVP: chỉ foreground.

### 3.2 macOS App (Swift 6, AppKit, macOS 13+)

| Module | API/Thư viện | Chức năng |
|--------|-------------|-----------|
| `ws-client` | `URLSessionWebSocketTask`, `NWBrowser` (Bonjour) | Kết nối WebSocket tới Android, auto-discovery LAN |
| `bt-hfp-client` | `IOBluetoothHandsFreeDevice`, `IOBluetoothDevice` | HFP HF role, nhận SCO audio |
| `audio-engine` | `AUVoiceProcessingIO`, `AVAudioEngine` | Echo cancellation, mic capture, speaker output. Opus decode cho WS fallback |
| `call-ui` | Custom `NSPanel` (level `.floating`, `styleMask: [.titled, .closable]`) | Floating call panel: caller ID, accept/reject, mute, dialpad |
| `clipboard-sync` | `NSPasteboard.general`, polling `changeCount` mỗi 500ms | Bidirectional sync |
| `sms-ui` | SwiftUI `NSWindow` | Chat-style SMS view, reply |
| `notification-center` | `UNUserNotificationCenter` | Native macOS notifications cho incoming call, SMS |
| `crypto` | CryptoKit (`Curve25519`, `ChaChaPoly`) | E2E decryption/encryption |

**Opus codec:** libopus 1.5+ linked via Swift Package Manager hoặc C bridge. Decode Opus frames từ WebSocket khi HFP không khả dụng.

### 3.3 iOS App (Swift 6, SwiftUI, iOS 16+)

| Module | API/Thư viện | Chức năng |
|--------|-------------|-----------|
| `ws-client` | `URLSessionWebSocketTask`, `NWBrowser` | WebSocket tới Android |
| `clipboard-sync` | `UIPasteboard.general` (foreground, iOS 16+ paste confirmation banner) |  Đồng bộ clipboard |
| `sms-ui` | SwiftUI views | Hiển thị/trả lời SMS |
| `call-metadata-ui` | SwiftUI views | Hiển thị caller ID, duration — KHÔNG có audio |
| `push-handler` | APNs + `PushKit` (`PKPushTypeVoIP` chỉ cho metadata display, KHÔNG ring) | Background notification khi app suspended |
| `crypto` | CryptoKit | E2E |

**Giới hạn iOS rõ ràng:** Không có call audio relay. Apple không expose HFP HF role API. `CallKit` trên iOS yêu cầu VoIP provider, không phù hợp cho relay. Chấp nhận iOS là "notification + clipboard + SMS device".

### 3.4 Cloud Relay Server (Rust, Actix-web 4)

| Module | Crate | Chức năng |
|--------|-------|-----------|
| `relay-ws` | `actix-web`, `actix-ws` | WebSocket relay khi devices ngoài LAN |
| `auth` | `jsonwebtoken`, `argon2` | Device authentication, session tokens |
| `push-proxy` | `a]2` (FCM), `apns2` (APNs) | Push notifications |
| `store` | `sqlx` + PostgreSQL | Device registry, session metadata (KHÔNG lưu message content) |

**Zero-knowledge:** Server chỉ relay encrypted blobs. Không decrypt, không log payload. Metadata tối thiểu: device_id (hashed), timestamp, message_size. Tự động xóa session data sau 30 ngày.

---

## 4. Transport Layer

| Feature | Transport chính | Fallback 1 | Fallback 2 | Latency mục tiêu |
|---------|----------------|------------|------------|-------------------|
| **Clipboard text** | WebSocket LAN | Cloud relay | — | <50ms |
| **Clipboard image** | WebSocket LAN (chunked 64KB) | Cloud relay | — | <2s cho 5MB |
| **SMS nhận/gửi** | WebSocket LAN | Cloud relay | — | <200ms |
| **Call metadata** | WebSocket LAN | Cloud relay | — | <200ms |
| **Call audio** | BT HFP SCO (mSBC 16kHz) | Opus/WebSocket LAN | Opus/Cloud relay | <40ms (BT), <150ms (WS) |
| **Notifications** | WebSocket LAN | APNs/FCM push | — | <500ms |

**Fallback chain cho call audio:** Khi user có AirPods/headset đang chiếm HFP slot hoặc ngoài BT range:
1. Android capture audio qua `AudioRecord(MediaRecorder.AudioSource.VOICE_COMMUNICATION)`
2. Encode Opus 16kHz mono, 32kbps, frame size 20ms
3. Gửi qua WebSocket LAN (hoặc cloud relay nếu ngoài LAN)
4. macOS decode Opus, play qua `AVAudioEngine`, mic capture ngược lại

---

## 5. Protocol

### 5.1 Message Format (JSON-based, dễ debug)

```json
{
  "v": 1,
  "type": "clipboard|sms|call_event|call_audio|pair|ack|ping|capability",
  "id": "uuid-v7",
  "ts": 1727136000000,
  "payload": "<base64 encrypted blob>"
}
```

Envelope là plaintext JSON. `payload` là XChaCha20-Poly1305 encrypted. Cho call audio, `type: "call_audio"` với payload là encrypted Opus frames, gửi dạng WebSocket binary frame (không JSON wrap) để giảm overhead.

Binary audio frame format:
```
[0x48 0x4C][version: 1B][seq: 4B][timestamp: 4B][encrypted_opus_frame: NB]
```

### 5.2 Pairing Flow (QR Code)

```
1. macOS/iOS generate X25519 keypair + random 32-byte pairing_secret
2. Encode vào QR code: handlive://pair?pk=<base64url>&ps=<base64url>&d=<device_name>
3. Android scan QR → extract public_key + pairing_secret
4. Android generate X25519 keypair
5. ECDH: shared = X25519(android_private, macos_public)
6. Session key = HKDF-SHA256(
     ikm = shared || pairing_secret,
     salt = SHA256(android_device_id || macos_device_id),
     info = "handlive-session-v1",
     len = 32
   )
7. Android gửi {android_public_key, HMAC(session_key, "verify")} qua WebSocket
8. macOS verify HMAC → pairing hoàn tất
9. Lưu long-term identity keys vào Android Keystore / macOS Keychain / iOS Keychain
```

**Ưu điểm so với 6-digit PIN:** 256-bit entropy (vs ~20-bit), không thể brute-force, xác thực implicit qua camera.

### 5.3 Capability Negotiation

Khi kết nối, mỗi device gửi message `type: "capability"`:
```json
{
  "features": ["clipboard", "sms", "call_meta", "call_audio_hfp", "call_audio_opus"],
  "protocol_version": 1,
  "max_clipboard_size": 10485760,
  "opus_config": {"sample_rate": 16000, "channels": 1, "bitrate": 32000}
}
```

Devices chỉ kích hoạt features mà CẢ HAI hỗ trợ. iOS gửi không có `call_audio_*` → macOS biết không stream audio cho iOS.

### 5.4 Conflict Resolution

**Clipboard:** Last-writer-wins dựa trên `ts` (UTC milliseconds). Nếu `|ts_a - ts_b| < 500ms` → giữ bản local, gửi `conflict` event cho user quyết định.

**SMS reply:** Optimistic send. Nếu Android báo gửi thất bại → hiển thị retry trên macOS/iOS.

---

## 6. Security

### 6.1 Encryption Stack

| Lớp | Thuật toán | Mục đích |
|-----|-----------|----------|
| Transport (LAN) | TLS 1.3 (self-signed cert, pinned) | Chống passive sniffing LAN |
| Transport (Cloud) | TLS 1.3 (Let's Encrypt, cert pinning) | Server ↔ device channel |
| Transport (BT) | SSP P-256 ECDH, Encryption Mode 3 | BT link-level |
| App E2E | XChaCha20-Poly1305, 256-bit key, 24-byte nonce | Mã hóa mọi payload, kể cả BT audio |
| Key exchange | X25519 ECDH + HKDF-SHA256 | Session key derivation |
| Key derivation (PIN fallback) | Argon2id (t=3, m=65536, p=4) | Khi không có QR, derive key từ PIN |
| Forward secrecy | Ratchet mỗi 24h hoặc 10,000 messages | Compromise 1 key không lộ history |
| Key storage | Android Keystore (StrongBox khi có), macOS/iOS Keychain (`kSecAttrAccessibleWhenUnlockedThisDeviceOnly`) | Hardware-backed khi khả dụng |

**Dual-layer cho BT audio (bắt buộc):** BT link encryption (SSP) chỉ là lớp 1. App-level XChaCha20-Poly1305 encrypt mỗi SCO frame trước khi truyền. Lý do: BT link encryption đã bị crack nhiều lần (KNOB attack, BIAS attack). Voice data CẦN app-level E2E.

### 6.2 Threat Model

| Mối đe dọa | Giảm thiểu |
|-------------|------------|
| LAN sniffing | TLS 1.3 + app E2E. Attacker chỉ thấy encrypted blobs |
| BT eavesdropping (KNOB/BIAS) | App-level E2E trên SCO. BT link chỉ là bonus layer |
| Cloud relay compromise | Zero-knowledge: server chỉ relay blobs, không có key |
| Stolen device | Key trong Keystore/Keychain, yêu cầu biometric/passcode. Remote unpair qua cloud |
| MITM khi pairing | QR code transfer public key out-of-band. 6-digit PIN fallback dùng Argon2id |
| Clipboard leak | Auto-clear sau 60s trên receiver. Sensitive clipboard detect (regex credit card, password manager patterns) → không sync, chỉ notify |

### 6.3 Pháp lý

Call audio relay giữa devices CỦA CÙNG MỘT USER (tương tự Microsoft Phone Link, Apple Continuity) — rủi ro pháp lý thấp hơn relay cho bên thứ ba. Tuy nhiên: hiển thị disclosure rõ ràng khi bật call audio relay. Cần legal review cho các bang two-party consent (California, Florida, Illinois...). Không ghi âm — chỉ relay realtime.

---

## 7. Call Audio Architecture

### 7.1 Primary Path: BT HFP

```
Cuộc gọi đến
  → Android InCallService detect CALL_STATE_RINGING
  → Gửi call_event {type: "incoming", number: "+84...", name: "..."} qua WebSocket
  → macOS hiển thị NSPanel floating notification
  → User nhấn Accept trên macOS
  → macOS gửi call_event {type: "answer"} qua WebSocket
  → Android InCallService.answer()
  → Android route audio sang BT SCO (BluetoothHeadsetClient.connectAudio())
  → SCO bidirectional: Android mic ↔ macOS speaker, macOS mic ↔ Android earpiece
  → macOS AUVoiceProcessingIO xử lý echo cancellation
  → Khi hangup: close SCO, gửi call_event {type: "ended", duration: 125}
```

**AT Commands mapping (HFP 1.8):**

| Action | AT Command | Gửi bởi |
|--------|-----------|---------|
| Answer | `ATA` | macOS (HF) |
| Reject/Hangup | `AT+CHUP` | macOS (HF) |
| Hold + Accept | `AT+CHLD=2` | macOS (HF) |
| DTMF | `AT+VTS=<digit>` | macOS (HF) |
| Query calls | `AT+CLCC` | macOS (HF) |
| Caller ID | `+CLIP: "+84...",145` | Android (AG) |
| Call status | `+CIEV: (call,1)` | Android (AG) |

### 7.2 Fallback Path: Opus over WebSocket

Khi HFP không khả dụng (AirPods chiếm slot, ngoài BT range, user chọn WS mode):

```
Android:
  AudioRecord(VOICE_COMMUNICATION, 16000Hz, MONO, PCM_16BIT)
  → buffer 320 samples (20ms frame)
  → Opus encode (libopus, 32kbps CBR, complexity 5)
  → XChaCha20-Poly1305 encrypt
  → WebSocket binary frame gửi đi (mỗi 20ms)

macOS:
  WebSocket binary frame nhận
  → Decrypt
  → Opus decode
  → AVAudioEngine output (buffer 60ms = 3 frames để chống jitter)
  → AUVoiceProcessingIO echo cancellation
  → Mic capture → Opus encode → encrypt → gửi ngược Android
```

**Jitter buffer:** Adaptive, 40-120ms. Bắt đầu 60ms, tăng/giảm theo network jitter measurement (running standard deviation of inter-arrival times).

**Phát hiện HFP conflict:** `BluetoothAdapter.getProfileConnectionState(BluetoothProfile.HEADSET)` — nếu đã có device khác kết nối HFP → tự động chuyển Opus/WebSocket, thông báo user.

### 7.3 Echo Cancellation

macOS: `AUVoiceProcessingIO` (AudioUnit component type `kAudioUnitType_Output`, subtype `kAudioUnitSubType_VoiceProcessingIO`) xử lý AEC, noise suppression, AGC tự động. Đây là cùng engine FaceTime dùng.

Android: `AudioRecord` với `MediaRecorder.AudioSource.VOICE_COMMUNICATION` tự động bật AEC phía Android.

---

## 8. Phân đoạn phát triển

### Phase 1: Clipboard Sync (MVP)
**Mục tiêu:** Android ↔ macOS clipboard đồng bộ qua WebSocket LAN  
**Deliverables:**
- Android foreground service + WebSocket server (Ktor)
- mDNS discovery (`NsdManager` / `NWBrowser`)
- QR code pairing + XChaCha20-Poly1305 E2E
- macOS menu bar app + clipboard polling
- Text + image clipboard sync, chunked transfer
- Auto-clear clipboard sau 60s
- Capability negotiation protocol

**Kết quả đo được:** Clipboard text sync <50ms LAN, image <2s cho 5MB. Reconnect tự động <3s.

### Phase 2: SMS Bridge
**Mục tiêu:** Nhận/gửi SMS từ macOS và iOS  
**Deliverables:**
- Android SMS receiver (`BroadcastReceiver`) + sender (`SmsManager`)
- macOS/iOS SMS UI (SwiftUI chat view)
- SMS history sync (last 50 messages per contact)
- iOS app (clipboard + SMS, WebSocket)
- Cloud relay server (Rust/Actix-web) cho ngoài LAN
- APNs/FCM push notifications

**Kết quả đo được:** SMS notification trên macOS <500ms từ lúc Android nhận. Reply delivery confirmed <2s.

### Phase 3: Call Metadata + Control
**Mục tiêu:** Nhận/quản lý cuộc gọi từ macOS  
**Deliverables:**
- Android `InCallService` integration
- macOS floating call panel (`NSPanel`)
- Answer/reject/hold/DTMF từ macOS
- Call history sync
- iOS call metadata display (caller ID, duration, không audio)

**Kết quả đo được:** Incoming call notification trên macOS <200ms. Answer latency <500ms end-to-end.

### Phase 4: Call Audio Relay
**Mục tiêu:** Nghe/nói cuộc gọi từ macOS  
**Deliverables:**
- BT HFP AG ↔ HF implementation (Android ↔ macOS)
- SCO audio routing + AUVoiceProcessingIO echo cancellation
- Opus/WebSocket fallback khi HFP unavailable
- Adaptive jitter buffer
- HFP conflict detection + automatic fallback
- App-level E2E encryption cho audio (bắt buộc)
- Dual-layer encryption verification tests

**Kết quả đo được:** Call audio MOS score >=3.5 (BT), >=3.0 (WebSocket). Echo cancellation: echo return loss >40dB.

---

## 9. Risk Register

### R1: `IOBluetoothHandsFreeDevice` bị deprecate (Impact: Critical)
**Xác suất:** Trung bình (Apple đang dần chuyển sang DriverKit)  
**Giảm thiểu:** Wrap mọi IOBluetooth calls trong protocol abstraction. Monitor WWDC hàng năm.  
**Plan B:** CoreBluetooth BLE + custom GATT service + Opus stream. Chất lượng kém hơn SCO nhưng không phụ thuộc IOBluetooth legacy. Latency ước tính ~200-300ms — vẫn dùng được cho voice.  
**Plan C:** Nếu cả IOBluetooth lẫn BLE custom đều fail → call audio chỉ qua Opus/WebSocket (đã có sẵn từ fallback path). Mất zero-network advantage nhưng feature vẫn hoạt động.

### R2: `BluetoothHeadsetClient` @SystemApi bị khoá (Impact: Critical)
**Xác suất:** Thấp-Trung bình (Microsoft Phone Link cũng dùng, Google khó khoá hoàn toàn)  
**Giảm thiểu:** Dùng Shizuku (ADB-level permission). Monitor AOSP changes mỗi Android beta.  
**Plan B:** `CompanionDeviceManager` API (Android 12+) — Google đang mở rộng API này. Nếu Google thêm call audio relay vào CDM → migrate.  
**Plan C:** Opus/WebSocket fallback là permanent path — call audio vẫn hoạt động không cần BT HFP, chỉ tăng latency ~100ms.

### R3: Play Store reject SMS permissions (Impact: High)
**Xác suất:** Trung bình (Google nghiêm với SMS)  
**Giảm thiểu:** Chuẩn bị Permission Declaration Form chi tiết: video demo, use case documentation, privacy policy.  
**Plan B:** Notification Listener Service — đọc SMS notifications thay vì SMS trực tiếp. Mất `SEND_SMS` nhưng giữ được nhận SMS.  
**Plan C:** Distribute qua F-Droid + direct APK. Mất Play Store reach nhưng không bị hạn chế permissions.

### R4: Opus/WebSocket call audio latency vượt ngưỡng chấp nhận (Impact: Medium)
**Xác suất:** Thấp (LAN <10ms RTT, Opus encode/decode ~5ms)  
**Giảm thiểu:** Adaptive jitter buffer. Opus `OPUS_APPLICATION_VOIP` mode. Frame size 20ms, không lớn hơn.  
**Plan B:** Nếu LAN latency OK nhưng cloud relay quá chậm → deploy edge servers tại các region chính (SEA, US). Hoặc dùng TURN relay (coturn) thay vì custom relay.

### R5: Android OEM fragmentation (BT stack khác nhau) (Impact: Medium)
**Xác suất:** Cao (đặc biệt Samsung, Xiaomi, OPPO)  
**Giảm thiểu:** Test matrix: Samsung Galaxy S/A series, Pixel, Xiaomi Redmi, OPPO. Minimum 6 devices.  
**Plan B:** OEM-specific workarounds wrapped trong strategy pattern. `BtAdapterStrategy` interface với `SamsungBtAdapter`, `PixelBtAdapter`, `GenericBtAdapter` implementations. Feature flags per OEM.

---

## 10. Camera & Microphone Streaming (Phase 5)

### 10.1 Tổng quan

Biến Android thành webcam + microphone cho macOS — xuất hiện trong Zoom, Google Meet, FaceTime, OBS như camera/mic thật. Mô hình đã chứng minh bởi DroidCam (~95-130ms), Camo (~50-70ms), scrcpy (~35-70ms).

**Triết lý:** WiFi là primary — hoàn toàn không dây, zero-config. USB chỉ là optional boost tự kích hoạt khi cắm cáp (giảm latency, sạc pin đồng thời). Video dùng kênh WebSocket riêng, không chia sẻ với control channel (clipboard/SMS).

```
┌──────────────────────────────────────────────────────────────────┐
│                        ANDROID                                    │
│                                                                    │
│  Camera2 ──Surface──▸ MediaCodec (H.264 HW) ──NALUs──▸ ┐        │
│                                                          │        │
│  AudioRecord (48kHz) ──▸ libopus (JNI) ──Opus frames──▸ ├──TCP──▸│
│                                                          │        │
│  XChaCha20 E2E encrypt ◀────────────────────────────────┘        │
└──────────────────┬───────────────────────────────────────────────┘
                   │ ADB forward (USB) hoặc WebSocket (WiFi)
                   ▼
┌──────────────────────────────────────────────────────────────────┐
│                        macOS                                      │
│                                                                    │
│  ┌─────────────────┐    IOSurface     ┌─────────────────────────┐│
│  │ VideoToolbox     │──zero-copy──▸   │ CMIOExtension           ││
│  │ VTDecompress     │                  │ (Camera Extension)      ││
│  │ H.264 HW decode  │                  │ Source/Sink stream      ││
│  └─────────────────┘                  └──────────┬──────────────┘│
│                                                   ▼               │
│  ┌─────────────────┐                  Zoom, FaceTime, Meet,      │
│  │ AudioServerPlugin│                  OBS, Safari, Chrome...    │
│  │ (HAL plug-in)    │                                             │
│  │ Virtual Mic      │                                             │
│  └─────────────────┘                                              │
└──────────────────────────────────────────────────────────────────┘
```

### 10.2 Android: Capture & Encode

| Module | API | Chi tiết |
|--------|-----|---------|
| `camera-capture` | Camera2 + Surface mode | Zero-copy: Camera2 → Surface → MediaCodec. `TEMPLATE_RECORD`. `CONTROL_AE_TARGET_FPS_RANGE` = [30,30] |
| `video-encoder` | MediaCodec HW (`video/avc`) | H.264 Constrained Baseline, Level 3.1 (720p) / 4.0 (1080p). `COLOR_FormatSurface`. `BITRATE_MODE_CBR` |
| `audio-capture` | AudioRecord 48kHz PCM16 mono | `CAMCORDER` source. `setPerformanceMode(LOW_LATENCY)` (API 26+) |
| `audio-encoder` | libopus via JNI | 32kbps, frame 10ms, `RESTRICTED_LOWDELAY`. Algorithmic delay ~13ms |
| `stream-service` | ForegroundService `camera\|microphone` | Android 14+ bắt buộc. Notification persistent |
| `adaptive-quality` | `PowerManager.getThermalHeadroom()` | Headroom ≥0.7 → giảm resolution/fps. `setParameters(PARAMETER_KEY_VIDEO_BITRATE)` dynamic |

**Cấu hình MediaCodec low-latency:**
- `KEY_PRIORITY` = 0 (realtime) — API 23+
- `KEY_LATENCY` = 1 (max 1 frame hold) — API 26+
- `PARAMETER_KEY_LOW_LATENCY` = 1 — API 30+
- `KEY_I_FRAME_INTERVAL` = 2 (IDR mỗi 2s qua USB, 1s qua WiFi)
- Force IDR on-demand khi client mới connect hoặc detect lỗi decode

**Resolution ladder (auto-negotiate):**

| Mức | Resolution | FPS | Bitrate CBR | Data/giờ |
|-----|-----------|-----|-------------|----------|
| Low | 480p | 30 | 1.0 Mbps | ~0.5 GB |
| Medium | 720p | 30 | 2.5 Mbps | ~1.1 GB |
| High | 1080p | 30 | 4.5 Mbps | ~2.0 GB |

### 10.3 macOS: Decode & Virtual Devices

**Virtual Camera — CMIOExtension (macOS 12.3+, ổn định từ 14.2+):**
- `CMIOExtensionProviderSource` + `CMIOExtensionDeviceSource` + `CMIOExtensionStreamSource`
- Source/Sink topology: main app push `CMSampleBuffer` vào sink stream → extension forward ra source stream
- IOSurface-backed `CVPixelBuffer` cho zero-copy
- Pixel format: `kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange` (NV12)
- Tương thích: FaceTime, Zoom, Teams, Meet (Chrome), Safari, OBS, Slack. Discord/Webex cần workaround re-codesign
- Distribution: App Store compatible (system extension trong app bundle)

**Video Decode — VideoToolbox:**
- `VTDecompressionSession` HW decode H.264
- `kVTVideoDecoderSpecification_EnableHardwareAcceleratedVideoDecoder: true`
- Output: IOSurface-backed `CVPixelBuffer` → `CMSampleBufferCreateForImageBuffer()` → feed CMIOExtension
- Latency decode: ~3ms (Apple Silicon, Baseline H.264 no B-frames)

**Virtual Microphone — AudioServerPlugin:**
- HAL plugin (.driver bundle) tại `/Library/Audio/Plug-Ins/HAL/`
- Xuất hiện trong System Preferences > Sound > Input
- 48kHz, mono, 512-sample buffer (~10.7ms latency)
- Developer ID signed (bắt buộc)
- Tham khảo: BlackHole, BackgroundMusic
- Opus decode → PCM → feed vào virtual audio device ring buffer

**IPC (main app ↔ extensions):**
- Video: CMIOExtension sink stream (IOSurface zero-copy, ~0ms overhead)
- Audio: SharedMemory ring buffer trong App Group container
- Control: CMIOExtension custom properties (low-bandwidth)

### 10.4 Transport

| Transport | Latency E2E | Throughput | Ưu điểm | Nhược điểm |
|-----------|------------|-----------|---------|-----------|
| **WiFi WebSocket** | ~80-120ms | 20-50 MB/s (LAN) | Không dây, zero-config, dùng infra có sẵn | Jitter, chia sẻ bandwidth |
| **USB (ADB forward)** | ~45-55ms | ~11 MiB/s (88 Mbps) | Latency thấp nhất, sạc pin, ổn định | Cần dây, USB debugging |
| **WiFi UDP raw** | ~60-90ms | Tương tự | Không head-of-line blocking | Phải tự xây reliability |

**Quyết định:** WiFi WebSocket binary frames là primary — kết nối RIÊNG cho video/audio, không chia sẻ với control channel (clipboard/SMS). Hoàn toàn không dây, zero-config, dùng mDNS discovery có sẵn.

**USB auto-boost (optional):** Khi user cắm cáp USB, hệ thống tự detect và chuyển sang ADB forward TCP (latency ~45ms thay vì ~100ms). Khi rút cáp → tự fallback về WiFi, không gián đoạn stream.

**Auto-detect USB:** macOS IOKit `IOServiceAddMatchingNotification` filter Android vendor/product ID. Khi detect → kiểm tra ADB available → `adb forward tcp:PORT tcp:PORT` → chuyển transport. Không yêu cầu user bật USB debugging trước — chỉ prompt khi cắm cáp lần đầu nếu ADB chưa bật.

### 10.5 Latency Budget (720p30)

**WiFi (primary):**

| Giai đoạn | Thời gian |
|-----------|----------|
| Camera sensor capture | ~24 ms |
| MediaCodec HW encode (surface, low-latency) | ~8-15 ms |
| WiFi WebSocket transport (LAN) | ~5-15 ms |
| VideoToolbox HW decode | ~3 ms |
| IOSurface → CMIOExtension | ~0 ms (zero-copy) |
| **Tổng WiFi** | **~40-57 ms (LAN tốt), ~80-120 ms (LAN trung bình)** |

**USB (auto-boost khi cắm cáp):**

| Giai đoạn | Thời gian |
|-----------|----------|
| Camera sensor capture | ~24 ms |
| MediaCodec HW encode (surface, low-latency) | ~8-15 ms |
| ADB USB transport | <1 ms |
| VideoToolbox HW decode | ~3 ms |
| IOSurface → CMIOExtension | ~0 ms (zero-copy) |
| **Tổng USB** | **~35-55 ms** |

So sánh: Continuity Camera (Apple) ~30-50ms, Camo ~50-70ms, DroidCam ~95-130ms. HandLive target: **<120ms WiFi (primary), <70ms USB (khi cắm cáp)**.

### 10.6 Battery & Thermal

- Camera + H.264 HW encode: ~0.5-1.5W. Pin 4000mAh: ~2-3 giờ liên tục (720p30 WiFi)
- USB cắm → sạc đồng thời, kéo dài vô hạn (nhưng thermal throttle sau 30-60 phút 1080p)
- Chiến lược adaptive:
  - `PowerManager.getThermalHeadroom()` ≥0.7 → giảm xuống 480p hoặc 20fps
  - Battery <20% → tự giảm resolution + thông báo user
  - Rear camera nóng hơn front camera ~15-20% (sensor lớn hơn)

### 10.7 Encryption

Video frames encrypt bằng XChaCha20-Poly1305 như mọi payload khác. Trên USB LAN, overhead encrypt ~0.1ms/frame cho 720p — negligible. Không có option tắt encryption — bảo mật nhất quán toàn hệ thống.

### 10.8 Rủi ro Phase 5

**R6: CMIOExtension compatibility issues (Impact: Medium)**
- macOS 14.5 bug: daemon không restart sau upgrade extension → cần reboot
- Discord/Webex block virtual cameras mặc định
- **Plan B:** Fallback OBS Virtual Camera plugin nếu HandLive extension gặp vấn đề

**R7: MediaCodec HW encoder fragmentation (Impact: Medium)**
- Một số budget SoC cho H.264 kém chất lượng hoặc không hỗ trợ low-latency flags
- **Plan B:** Software encode (libx264 via JNI) cho devices có HW encoder kém. Tốn pin hơn nhưng nhất quán

**R8: AudioServerPlugin ký bằng Developer ID (Impact: Low)**
- Bắt buộc ký Developer ID — ad-hoc bị reject
- User phải approve trong System Settings > Login Items & Extensions
- **Mitigation:** First-run wizard hướng dẫn user approve

---

## 11. Effort Estimate

| Phase | Scope | Android | macOS | iOS | Server | Test | Tổng |
|-------|-------|---------|-------|-----|--------|------|------|
| **P1: Clipboard** | WS + mDNS + QR pair + crypto + clipboard | 1.5 pm | 1.5 pm | — | — | 0.5 pm | **3.5 pm** |
| **P2: SMS** | SMS bridge + chat UI + cloud relay + push | 1 pm | 0.5 pm | 1 pm | 1 pm | 0.5 pm | **4 pm** |
| **P3: Call Meta** | InCallService + call panel + control | 1 pm | 1 pm | 0.5 pm | — | 0.5 pm | **3 pm** |
| **P4: Call Audio** | HFP + SCO + Opus fallback + AEC | 2 pm | 2 pm | — | 0.5 pm | 1.5 pm | **6 pm** |
| **P5: Camera/Mic** | Camera2 + MediaCodec + CMIOExtension + AudioServerPlugin | 2 pm | 2.5 pm | — | — | 1 pm | **5.5 pm** |
| **Tổng** | | **7.5 pm** | **7.5 pm** | **1.5 pm** | **1.5 pm** | **4 pm** | **22 pm** |

**Với team 2 người:** ~11 tháng (P1→P5 tuần tự, một số task song song).  
**Với team 3 người:** ~7.5 tháng.  
**MVP (P1 only):** ~2 tháng với 2 người.  
**Usable product (P1+P2):** ~4 tháng với 2 người.  
**Full product (P1-P5):** ~7.5 tháng với 3 người.

**P5 breakdown:** Android Camera2+MediaCodec pipeline (1pm) + WiFi video channel + USB auto-detect (0.5pm) + adaptive quality (0.5pm) | macOS CMIOExtension (1pm) + VideoToolbox decode (0.5pm) + AudioServerPlugin (0.5pm) + PKG installer (0.5pm) | Testing OEM matrix + app compatibility (1pm).

---

## 12. Quyết định đã xác nhận

Tất cả câu hỏi mở đã được giải quyết. Dưới đây là quyết định cuối cùng cho từng mục.

### D1: IOBluetoothHandsFreeDevice — Spike + Dual-path

**Quyết định:** Spike 1 tuần đầu Phase 4. Nếu SCO routing fail trên macOS 15+ → chuyển sang Opus/WebSocket permanent (đã có sẵn từ fallback path, chỉ cần promote thành primary). Không block Phase 1-3.

**Lý do:** Dual-path architecture cho phép fail-safe. Opus/WS fallback đã được thiết kế sẵn, latency ~100-150ms vẫn chấp nhận được cho call audio. Spike chỉ mất 1 tuần = rủi ro thấp.

**Hành động:** Task đầu tiên của Phase 4 = spike. Pass/fail quyết định path ngay.

### D2: Legal — Disclosure-first, ship song song

**Quyết định:** Implement disclosure flow TRƯỚC khi bật call audio relay. Flow: lần đầu bật call relay → dialog thông báo "Cuộc gọi sẽ được relay qua thiết bị này" → user confirm → ghi log consent timestamp. Không cần delay ship cho legal review — disclosure đủ cơ sở tự bảo vệ.

**Lý do:** Two-party consent (California, Illinois) yêu cầu "all parties aware", không yêu cầu "all parties consent". Disclosure rõ ràng + user opt-in đủ cho hầu hết jurisdictions. Nếu cần thêm, thêm disclaimer "User chịu trách nhiệm thông báo bên kia" trong settings.

**Hành động:** Phase 4 bao gồm disclosure UI. Thuê luật sư review wording trước khi ship — không block development.

### D3: CompanionDeviceManager — Monitor, không chờ

**Quyết định:** Dùng `BluetoothHeadsetClient` @SystemApi + Shizuku ngay. Monitor CDM evolution mỗi Android release. Migration path sẵn nếu Google thêm call audio API vào CDM.

**Lý do:** CDM hiện tại (Android 15) chưa có call audio relay API. Chờ = vô thời hạn. `BluetoothHeadsetClient` + Shizuku đã proven bởi Microsoft Phone Link. Wrap trong abstraction layer để migration CDM sau này là 1-2 tuần effort.

**Hành động:** Implement `BluetoothHeadsetClient` path. Abstraction interface `CallAudioRelay` với 2 impl: `HfpCallAudioRelay` (hiện tại), `CdmCallAudioRelay` (future). Check CDM changelog mỗi Android beta release.

### D4: Clipboard background — Accessibility Service

**Quyết định:** Accessibility Service cho Phase 1. Notification Listener Service làm Plan B nếu Play Store reject.

**Lý do:** Target user = mass-market, không phải dev. Shizuku yêu cầu ADB setup ban đầu — đây là barrier lớn cho phần lớn user, đặc biệt khi triết lý app là "hoàn toàn không dây, zero-config". Accessibility Service không cần setup đặc biệt, chỉ cần user bật trong Settings. Play Store rejection risk thấp nếu declare đúng purpose ("cross-device clipboard sync") và chỉ dùng quyền tối thiểu. Samsung, Xiaomi clipboard managers dùng cùng approach.

**Hành động:** Implement `AccessibilityClipboardService`. Prepare `NotificationListenerClipboardService` sẵn. Play Store Permissions Declaration Form nộp sớm P1 milestone 2 để biết kết quả trước khi ship.

### D5: Cloud relay — Self-host VPS, migrate khi scale

**Quyết định:** Self-host trên 1 VPS (Hetzner/OVH, ~$20/tháng) cho Phase 2. Chuyển sang managed (fly.io/Railway) khi >500 concurrent users.

**Lý do:** Bandwidth cost thấp ở scale nhỏ: 100 concurrent calls × 32kbps Opus = ~12GB/giờ ≈ $50/tháng. Commodity VPS 20TB bandwidth/tháng = đủ cho ~1000 users. Server code = Rust/Actix-web stateless → dễ scale horizontal. Managed service quá đắt cho giai đoạn đầu ($0.10-0.15/GB bandwidth).

**Hành động:** Deploy Rust relay server trên 1 VPS. Docker + systemd. Auto-scaling script: monitor CPU/bandwidth → alert khi >70% → thêm VPS. Migrate managed khi revenue justify.

### D6: CMIOExtension — Spike tuần 1 Phase 5

**Quyết định:** Spike 1 tuần đầu Phase 5: build minimal Source+Sink extension, test với FaceTime/Zoom/Meet/OBS. Discord/Webex: document workaround, không block ship.

**Lý do:** OBS Studio đã ship CMIOExtension production trên macOS 12.3+. Camo cũng dùng cùng stack. Codebase reference đầy đủ (OBS 5 Swift files). Risk thực sự chỉ là compatibility edge cases (Discord re-codesign, macOS minor version bugs). 1 tuần spike đủ để validate.

**Hành động:** Spike deliverable = working extension hiện camera placeholder trong FaceTime + Zoom + Meet. Pass → continue P5. Fail (nếu macOS API thay đổi breaking) → evaluate DAL plugin legacy path hoặc OBS Virtual Camera piggyback.

### D7: AudioServerPlugin distribution — PKG notarized + Homebrew

**Quyết định:** PKG installer (signed + notarized) tích hợp trong macOS app. App detect plugin chưa cài → prompt → run embedded PKG → `killall -9 coreaudiod`. Song song distribute Homebrew cask.

**Lý do:** Mac App Store không thể cài vào `/Library/Audio/Plug-Ins/HAL/` (sandbox restriction). BlackHole, Loopback (Rogue Amoeba), Camo đều dùng PKG installer — proven path. Privileged helper (`SMAppService.register`) cho auto-install seamless. Homebrew cask cho tech-savvy users (1 command install).

**Hành động:** 
- macOS app embed `.pkg` trong Resources
- First-run: detect plugin missing → show dialog "Cần cài virtual microphone driver" → run `SMJobBless` privileged helper → copy plugin + restart coreaudiod
- `brew install --cask handlive` auto-install cả app + plugin
- Notarize: `xcrun notarytool submit` + `stapler staple`

### D8: USB boost — ADB với wizard, UVC future

**Quyết định:** ADB port forwarding cho version 1. In-app wizard hướng dẫn bật USB Debugging khi user cắm cáp lần đầu. UVC native (Android 14 QPR1+ `UvcDevice` API) evaluate cho version 2.

**Lý do:** WiFi là mặc định — user không bao giờ cần USB để dùng app. USB boost là optional cho power users muốn latency thấp hơn. ADB setup một lần, wizard step-by-step với screenshot giảm barrier. UVC hấp dẫn (zero-setup, native) nhưng: chỉ Android 14 QPR1+ (tỉ lệ thấp 2026), API mới chưa proven ở quy mô, và không hỗ trợ audio — phải vẫn dùng WiFi cho mic.

**Hành động:**
- Detect USB via IOKit → show "Bạn muốn tăng tốc kết nối?" → wizard 3 bước (Settings → Developer Options → USB Debugging)
- Sau setup lần đầu: auto-detect + auto-switch, không hỏi lại
- Roadmap v2: evaluate UVC + AOA combo (video qua UVC, audio qua AOA bulk transfer)
