# Kiến trúc "Bluetooth-Native" — HandLive

> Đề xuất kiến trúc cho ứng dụng Android đồng bộ clipboard, SMS và cuộc gọi (bao gồm audio) sang
> macOS và iOS.

**Ngày:** 2026-09-24  
**Trạng thái:** Đề xuất

---

## 1. Tổng quan kiến trúc

Kiến trúc xoay quanh Bluetooth làm kênh truyền chính. Lý do: Android 10+ chặn hoàn toàn truy cập
audio cuộc gọi cellular qua API công khai — Bluetooth HFP (Hands-Free Profile) là cách duy nhất đã
được chứng minh (Microsoft Phone Link dùng cách này). Vì Bluetooth HFP đã bắt buộc cho call audio,
ta tận dụng luôn Bluetooth cho clipboard và SMS thay vì phụ thuộc mạng.

**Luồng tổng thể:**

```
Android (AG role)
  ├── SCO channel ──────→ macOS (HF role): call audio, bidirectional
  ├── RFCOMM/SPP channel ─→ macOS: clipboard, SMS, call metadata
  └── WebSocket (fallback) ─→ iOS: clipboard, SMS only (không có call audio)
```

Android đóng vai Audio Gateway (AG). macOS đóng vai Hands-Free (HF) qua
`IOBluetoothHandsFreeDevice`. iOS không thể nhận HFP call audio (không có public API), chỉ nhận
clipboard/SMS qua WebSocket LAN.

---

## 2. Component Breakdown

### 2.1 Android App (Kotlin, minSdk 29)

| Module | API/Thư viện | Chức năng |
|--------|-------------|-----------|
| `bt-hfp-gateway` | `BluetoothHeadsetClient` (system API), `BluetoothAdapter`, `BluetoothSocket` | Quản lý HFP AG role, mở SCO link cho audio |
| `bt-data-channel` | `BluetoothSocket` (RFCOMM/SPP UUID) | Truyền clipboard, SMS, call metadata qua RFCOMM |
| `clipboard-monitor` | `ClipboardManager.OnPrimaryClipChangedListener` | Phát hiện thay đổi clipboard, gửi qua RFCOMM |
| `sms-bridge` | `BroadcastReceiver` (SMS_RECEIVED), `ContentResolver` (Telephony.Sms) | Nhận SMS mới, đọc lịch sử, gửi SMS |
| `call-controller` | `TelecomManager`, `InCallService` (Android 10+) | Điều khiển cuộc gọi: answer, reject, hold, DTMF |
| `ws-server` | Ktor/OkHttp WebSocket | Fallback cho iOS, mDNS broadcast qua `NsdManager` |
| `crypto` | Tink (Google) — `XChaCha20Poly1305`, `X25519` | Mã hóa E2E trên RFCOMM và WebSocket |

**Quyền đặc biệt:** `BIND_INCALL_SERVICE` (cuộc gọi), `READ_SMS` /`SEND_SMS` cần Play Store
Permissions Declaration Form với lý do "cross-device sync". `BLUETOOTH_CONNECT`, `BLUETOOTH_SCAN`
(runtime permissions Android 12+).

### 2.2 macOS App (Swift, AppKit, macOS 12+)

| Module | API/Thư viện | Chức năng |
|--------|-------------|-----------|
| `bt-hfp-client` | `IOBluetoothHandsFreeDevice`, `IOBluetoothRFCOMMChannel` | Kết nối HFP HF role, nhận SCO audio |
| `bt-data-client` | `IOBluetoothRFCOMMChannel` (SPP UUID) | Nhận clipboard, SMS qua RFCOMM |
| `audio-engine` | `AUVoiceProcessingIO` (AudioUnit), `AVAudioEngine` | Echo cancellation, mic capture, speaker output |
| `call-ui` | Custom `NSPanel` (floating, always-on-top) | Hiển thị cuộc gọi: caller ID, accept/reject, dialpad |
| `clipboard-sync` | `NSPasteboard.general`, `NSPasteboard.changeCount` polling | Đồng bộ 2 chiều |
| `sms-ui` | SwiftUI `NSWindow` | Hiển thị và trả lời SMS |
| `crypto` | `CryptoKit` — `Curve25519`, `ChaChaPoly` | Mã hóa E2E |

**Lưu ý:** CallKit KHÔNG khả dụng trên macOS native (chỉ có trên Catalyst/iOS). Call UI phải tự xây
bằng `NSPanel` với level `.floating`.

### 2.3 iOS App (Swift, SwiftUI, iOS 16+)

| Module | API/Thư viện |
|--------|-------------|
| `ws-client` | `URLSessionWebSocketTask`, `NWBrowser` (Bonjour/mDNS discovery) |
| `clipboard-sync` | `UIPasteboard.general` (foreground only, iOS 16+ paste confirmation) |
| `sms-ui` | SwiftUI views |
| `push-relay` | APNs (nhận notification khi app background) |

**Giới hạn:** iOS không thể nhận BT HFP call audio — không có public API cho HFP HF role. Chỉ hỗ trợ
clipboard + SMS. Cuộc gọi chỉ hiển thị metadata (caller ID, duration), không relay audio.

### 2.4 Server (Optional, Go/Rust)

Chỉ cần khi muốn relay ngoài LAN. Chức năng: TURN-like relay cho WebSocket, push notification proxy
(FCM/APNs), device registry. Không xử lý mã hóa — E2E giữa devices.

---

## 3. Transport Layer

| Feature | Kênh chính | Kênh fallback | Dung lượng |
|---------|-----------|---------------|------------|
| **Call audio** | BT SCO (mSBC: 16kHz/16bit mono, 64kbps) | Không có fallback | Realtime, ~40ms latency |
| **Call metadata** | BT RFCOMM | WebSocket LAN | JSON, <1KB/event |
| **Clipboard text** | BT RFCOMM | WebSocket LAN | <1MB, chunked 4KB frames |
| **Clipboard image** | WebSocket LAN (BT quá chậm cho ảnh lớn) | Cloud relay | <10MB, chunked 64KB frames |
| **SMS** | BT RFCOMM | WebSocket LAN | JSON, <10KB/message |

**SCO audio flow:**
1. Android `InCallService` phát hiện cuộc gọi → gửi AT command `+CIEV` qua HFP
2. macOS `IOBluetoothHandsFreeDevice` nhận indicator → mở SCO link
3. Audio bidirectional: Android mic ↔ macOS speaker, macOS mic ↔ Android earpiece
4. macOS `AUVoiceProcessingIO` xử lý echo cancellation realtime

---

## 4. Protocol Design

### 4.1 RFCOMM Data Protocol

```
[Header: 4 bytes][Type: 1 byte][Length: 4 bytes][Payload: N bytes][HMAC: 16 bytes]
```

- **Header:** Magic bytes `0x484C4956` ("HLIV")
- **Type:** `0x01` clipboard, `0x02` SMS, `0x03` call event, `0x04` pairing, `0x05` ack, `0x06` ping
- **Length:** uint32 big-endian
- **Payload:** Encrypted (XChaCha20-Poly1305), nội dung là JSON hoặc binary tùy type
- **HMAC:** Poly1305 tag (đã bao gồm trong AEAD output)

### 4.2 Handshake & Pairing

1. BT pairing chuẩn (SSP — Secure Simple Pairing, MITM protection)
2. App-level pairing: Android hiển thị 6-digit code, user nhập trên macOS
3. Từ code → `PBKDF2-SHA256(code, device_ids, 100000 iterations)` → shared secret
4. X25519 key exchange qua RFCOMM, verify bằng shared secret
5. Derive session key: `HKDF-SHA256(shared_secret, x25519_shared, "handlive-v1")`
6. Lưu long-term key vào Android Keystore / macOS Keychain

### 4.3 Call Control (AT Commands)

Tận dụng AT commands chuẩn HFP 1.8:
- `AT+CHUP` — reject/hangup
- `ATA` — answer
- `AT+BLDN` — redial
- `AT+CLCC` — query call list
- `+CLIP` — caller ID indication

---

## 5. Security Model

| Lớp | Cơ chế |
|-----|--------|
| Bluetooth link | SSP (P-256 ECDH), encryption mode 3 |
| App transport | XChaCha20-Poly1305 (Tink/CryptoKit), 256-bit session key |
| Key exchange | X25519 ECDH + PBKDF2 verification |
| Key storage | Android Keystore (hardware-backed), macOS Keychain, iOS Keychain |
| SMS content | Encrypted at rest trên macOS (Core Data + SQLCipher hoặc encrypted container) |
| Clipboard | Không lưu trữ — chỉ transit. Auto-clear sau 60s trên receiver |

**Threat model:** Kẻ tấn công cần (1) ở trong BT range ~10m, (2) phá SSP pairing, VÀ (3) phá
XChaCha20-Poly1305. Dual-layer encryption tạo defense-in-depth.

---

## 6. Ưu điểm

1. **Zero network dependency cho core features** — Clipboard, SMS, call audio đều hoạt động offline,
   không cần WiFi/internet. Phù hợp môi trường mạng kém.
2. **Latency thấp cho call audio** — BT SCO ~40ms, rất dưới ngưỡng ITU-T G.114 (150ms). Trải nghiệm
   gọi tự nhiên.
3. **Bảo mật mạnh** — Dual-layer encryption (BT SSP + app-level XChaCha20). Dữ liệu không đi qua
   server nào. Không có cloud dependency = không có attack surface trên server.
4. **Proven approach** — Microsoft Phone Link đã chứng minh BT HFP hoạt động tốt cho call relay trên
   Windows. Kiến trúc này áp dụng cùng nguyên lý cho macOS.
5. **Đơn giản hóa infra** — Không cần maintain server cho core flow. Server chỉ optional cho push
   notifications và relay ngoài LAN. Giảm chi phí vận hành.

---

## 7. Nhược điểm

1. **iOS bị cắt xén nghiêm trọng** — Không thể relay call audio sang iOS (Apple không expose HFP HF
   API). iOS chỉ nhận clipboard + SMS, biến nó thành "citizen hạng hai".
2. **Phạm vi vật lý giới hạn** — BT range ~10m (thực tế 5-7m trong nhà). Ra khỏi phạm vi thì mất kết
   nối hoàn toàn cho call audio. WebSocket fallback chỉ cứu được clipboard/SMS.
3. **HFP audio chất lượng thấp** — Mono 8/16kHz (CVSD/mSBC), tương đương chất lượng điện thoại cũ.
   Không thể stream nhạc hay media chất lượng cao qua kênh này.
4. **Phức tạp BT stack** — `IOBluetoothHandsFreeDevice` trên macOS thiếu tài liệu, API cũ
   (Objective-C bridge). Bluetooth trên Android cũng nổi tiếng fragmented giữa các OEM. Debug khó.
5. **Single connection** — HFP chỉ cho phép 1 HF device tại một thời điểm. Không thể đồng thời relay
   call audio sang cả macOS VÀ tai nghe BT của user.

---

## 8. Rủi ro kỹ thuật

### R1: `BluetoothHeadsetClient` là hidden API trên Android

API này thuộc `@SystemApi` — chỉ system apps hoặc apps ký bằng platform key mới truy cập được. Giải
pháp: dùng Shizuku (ADB-level permission grant) hoặc yêu cầu user cài qua ADB.
**Nếu Google khóa luôn path này → dự án chết.**

**Giảm thiểu:** Nghiên cứu sâu AIDL `IBluetoothHeadsetClient` qua reflection. Theo dõi thay đổi
trong AOSP mỗi Android release. Chuẩn bị fallback dùng companion device profile
(`CompanionDeviceManager`).

### R2: `IOBluetoothHandsFreeDevice` bị deprecate hoặc sandbox

Apple đang dần siết sandbox và chuyển sang DriverKit. Nếu macOS version tương lai deprecate
IOBluetooth framework → mất khả năng HFP trên macOS.

**Giảm thiểu:** Wrap toàn bộ IOBluetooth calls trong abstraction layer. Theo dõi WWDC hàng năm.
Chuẩn bị plan B dùng CoreBluetooth BLE + custom audio protocol (chất lượng kém hơn).

### R3: Play Store rejection cho SMS permissions

Google rất nghiêm với `READ_SMS` /`SEND_SMS`. Permission Declaration Form có thể bị từ chối nếu
reviewer không chấp nhận use case "cross-device sync".

**Giảm thiểu:** Chuẩn bị documentation chi tiết cho reviewer. Có plan B: distribute qua sideload
(APK trực tiếp), F-Droid, hoặc dùng Notification Listener thay vì đọc SMS trực tiếp (mất khả năng
gửi SMS).

---

## 9. Effort Estimate

| Component | Effort | Ghi chú |
|-----------|--------|---------|
| Android BT HFP Gateway + RFCOMM | 3 person-months | Phần khó nhất: hidden API, OEM fragmentation |
| Android clipboard + SMS + call control | 1.5 person-months | Straightforward nhưng cần xử lý permissions |
| macOS BT HFP Client + audio engine | 3 person-months | IOBluetooth thiếu docs, AUVoiceProcessingIO setup phức tạp |
| macOS UI (call panel, SMS, clipboard) | 1.5 person-months | SwiftUI + custom NSPanel |
| iOS app (WebSocket, clipboard, SMS UI) | 1.5 person-months | Đơn giản nhất vì scope giới hạn |
| Protocol + crypto + pairing flow | 1 person-months | Dùng thư viện có sẵn (Tink, CryptoKit) |
| Server relay (optional) | 1 person-month | Chỉ cần nếu muốn hoạt động ngoài LAN |
| Testing + OEM compatibility | 2 person-months | BT testing cần nhiều thiết bị thật |
| **Tổng** | **~14.5 person-months** | ~5 tháng với team 3 người |

**MVP (chỉ macOS + Android, không iOS, không server):** ~8 person-months → 4 tháng với 2 người.
