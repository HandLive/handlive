# Nghiên cứu Virtual Camera & Virtual Microphone trên macOS

> **Ngày:** 2026-09-24
> **Trạng thái:** Hoàn thành
> **Mục đích:** Nghiên cứu kỹ thuật để tích hợp virtual camera và virtual microphone vào HandLive — cho phép stream camera/mic từ Android sang macOS, hiển thị như thiết bị ảo trong Zoom, Meet, FaceTime, OBS, v.v.

---

## 1. Virtual Camera — CMIOExtension (macOS 12.3+)

### 1.1 Tổng quan

`CMIOExtension` là API chính thức của Apple (từ WWDC 2022) thay thế cho legacy `CoreMediaIO DAL Plugin`. Đây là **System Extension** chạy trong process riêng biệt, được macOS quản lý, không load code vào process của app khác (an toàn hơn DAL plugin).

**Framework:** `CoreMediaIO` (import `CoreMediaIO`)

### 1.2 Kiến trúc — 3 lớp chính

```
CMIOExtensionProvider (gốc)
  └── CMIOExtensionDevice (thiết bị camera ảo)
        ├── CMIOExtensionStream (source — output cho apps tiêu thụ)
        └── CMIOExtensionStream (sink — input từ app cung cấp frame)
```

| Class/Protocol | Vai trò |
|---|---|
| `CMIOExtensionProviderSource` | Protocol — quản lý capabilities, client connections. Tạo `CMIOExtensionProvider` |
| `CMIOExtensionDeviceSource` | Protocol — quản lý properties ảnh hưởng toàn bộ camera device |
| `CMIOExtensionStreamSource` | Protocol — quản lý stream: frame rate, pixel format, độ phân giải |
| `CMIOExtensionProvider` | Class — gốc của extension, gọi `startService(provider:)` trong `main.swift` |
| `CMIOExtensionDevice` | Class — đại diện thiết bị camera ảo, quản lý streams |
| `CMIOExtensionStream` | Class — stream video, có 2 hướng: `.source` (output) và `.sink` (input) |

### 1.3 Entry Point — `main.swift`

```swift
import CoreMediaIO
import Foundation

let provider = CMIOExtensionProvider(
    source: MyProviderSource(),
    clientQueue: nil
)

CMIOExtensionProvider.startService(provider: provider)

CFRunLoopRun()
```

Extension target trong Xcode: **System Extension** (không phải App Extension thường).

### 1.4 Source Stream vs Sink Stream

| | Source Stream | Sink Stream |
|---|---|---|
| **Hướng** | Extension → Apps tiêu thụ (Zoom, FaceTime...) | App chủ → Extension |
| **Ai dùng** | Mọi app muốn dùng camera ảo | Chỉ app container (HandLive) |
| **API** | `stream.send(sampleBuffer, ...)` | `consumeSampleBuffer(from:)` + `notifyScheduledOutputChanged()` |
| **Mục đích** | Cung cấp video frames cho consumer | Nhận video frames từ app cung cấp |

**Luồng HandLive:**
```
Android Camera → WebSocket → macOS HandLive app
  → decode H.264/MJPEG → CVPixelBuffer
  → gửi qua Sink Stream (hoặc IPC) → Extension
  → Extension forward ra Source Stream
  → Zoom/Meet/FaceTime nhận frames
```

### 1.5 Pixel Format

| Format | Constant | Ghi chú |
|---|---|---|
| BGRA 32-bit | `kCVPixelFormatType_32BGRA` | Dễ dùng nhất, tương thích rộng |
| NV12 (4:2:0) | `kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange` | Hiệu quả hơn, OBS dùng format này |
| YUYV (4:2:2) | `kCVPixelFormatType_422YpCbCr8_yuvs` | USB camera thường dùng |

**Khuyến nghị cho HandLive:** Dùng NV12 nếu Android gửi H.264 (VideoToolbox decode ra NV12 native). Dùng BGRA nếu Android gửi MJPEG/raw.

### 1.6 Frame Delivery

```swift
// Trong extension, khi nhận frame từ sink hoặc IPC:
func deliverFrame(_ pixelBuffer: CVPixelBuffer, timestamp: CMTime) {
    let formatDescription = CMVideoFormatDescription(imageBuffer: pixelBuffer)

    var timing = CMSampleTimingInfo(
        duration: CMTime(value: 1, timescale: 30), // 30fps
        presentationTimeStamp: timestamp,
        decodeTimeStamp: .invalid
    )

    let sampleBuffer = try! CMSampleBuffer(
        imageBuffer: pixelBuffer,
        formatDescription: formatDescription,
        sampleTiming: timing
    )

    sourceStream.send(
        sampleBuffer,
        discontinuity: [],
        hostTimeInNanoseconds: UInt64(timestamp.seconds * 1_000_000_000)
    )
}
```

**Timer-based vs Event-driven:**
- Timer-based: `DispatchSourceTimer` fire mỗi 1/30s hoặc 1/60s → phù hợp khi tự generate frame
- Event-driven: forward frame ngay khi nhận từ sink/IPC → phù hợp HandLive (forward video từ Android)

### 1.7 Info.plist (Extension target)

```xml
<key>NSExtension</key>
<dict>
    <key>NSExtensionPointIdentifier</key>
    <string>com.apple.cmio.extension-provider</string>
    <key>NSExtensionPrincipalClass</key>
    <string>$(PRODUCT_MODULE_NAME).ExtensionProviderSource</string>
</dict>
<key>NSCameraUsageDescription</key>
<string>HandLive Virtual Camera</string>
```

### 1.8 Entitlements

**App (container) entitlements:**
```xml
<key>com.apple.developer.system-extension.install</key>
<true/>
<key>com.apple.security.application-groups</key>
<array>
    <string>group.com.handlive.app</string>
</array>
<key>NSCameraUsageDescription</key>
<string>Access camera for HandLive</string>
```

**Extension entitlements:**
```xml
<key>com.apple.security.application-groups</key>
<array>
    <string>group.com.handlive.app</string>
</array>
```

### 1.9 Activation Flow

```swift
// Trong app container:
import SystemExtensions

let request = OSSystemExtensionRequest.activationRequest(
    forExtensionWithIdentifier: "com.handlive.app.camera-extension",
    queue: .main
)
request.delegate = self
OSSystemExtensionManager.shared.submitRequest(request)
```

User sẽ thấy System dialog "HandLive muốn cài System Extension" → cần vào System Settings > Privacy & Security > cho phép.

### 1.10 So sánh với Legacy DAL Plugin

| | CMIOExtension (mới) | DAL Plugin (cũ) |
|---|---|---|
| **macOS** | 12.3+ (ổn định từ 14+) | 10.x - 14 (deprecated) |
| **Process** | Chạy riêng, sandbox | Load vào process app khác |
| **Bảo mật** | Signed, notarized, system-approved | Bất kỳ code nào đều load được |
| **FaceTime** | Hoạt động | KHÔNG hoạt động (từ macOS 12.3+) |
| **App Store** | Có thể | Không |
| **Trạng thái** | Tương lai | Deprecated từ macOS 12.3, bị xóa bỏ dần |

**OBS Virtual Camera:** OBS đã migrate sang CMIOExtension từ OBS 30.0+ cho macOS 13+. Trước đó dùng DAL plugin. Implementation của OBS dùng `IOSurface` cho zero-copy frame sharing giữa OBS process và extension.

---

## 2. Virtual Microphone — AudioServerPlugin (Core Audio HAL)

### 2.1 Tổng quan

Không có tương đương `CMIOExtension` cho audio. Apple vẫn dùng **AudioServerPlugin** (Core Audio HAL plugin) — đây là API từ macOS 10.x nhưng VẪN HOẠT ĐỘNG và KHÔNG deprecated (tính đến macOS 15).

**Framework:** `CoreAudio` (`AudioServerPlugIn.h`)

Plugin chạy trong process `coreaudiod` (Core Audio daemon), KHÔNG phải process của app.

### 2.2 Kiến trúc AudioServerPlugin

```
AudioServerPlugInDriverInterface (vtable)
  ├── Plugin Object (kAudioObjectPlugInObject)
  │     └── Device Object (kAudioDeviceClassID)
  │           ├── Stream Object (kAudioStreamClassID) — input stream
  │           ├── Stream Object (kAudioStreamClassID) — output stream (optional)
  │           ├── Volume Control (kAudioVolumeControlClassID)
  │           └── Mute Control (kAudioMuteControlClassID)
```

### 2.3 AudioDriverPlugIn vs AudioServerPlugIn

| | AudioDriverPlugIn (cũ) | AudioServerPlugIn (hiện tại) |
|---|---|---|
| **Chạy trong** | Process của client app | Process `coreaudiod` |
| **Trạng thái** | Deprecated | Active, được khuyến nghị |
| **Stability** | Bug crash app | Bug crash coreaudiod (tự restart) |
| **API** | CFPlugin-based | C vtable (`AudioServerPlugInDriverInterface`) |

### 2.4 Entry Point

```c
// BlackHole-style entry point
void* BlackHole_Create(
    CFAllocatorRef allocator,
    CFUUIDRef requestedTypeUUID
) {
    if (CFEqual(requestedTypeUUID, kAudioServerPlugInTypeUUID)) {
        // Return pointer to AudioServerPlugInDriverInterface vtable
        return &gAudioServerPlugInDriverInterface;
    }
    return NULL;
}
```

**vtable gồm các hàm chính:**

| Hàm | Vai trò |
|---|---|
| `Initialize` | Khởi tạo driver, nhận host interface |
| `CreateDevice` | Tạo audio device |
| `GetPropertyData` / `SetPropertyData` | Get/set properties cho mọi AudioObject |
| `StartIO` / `StopIO` | Bắt đầu/dừng I/O |
| `GetZeroTimeStamp` | Cung cấp timestamp cho clock sync |
| `DoIOOperation` / `BeginIOOperation` / `EndIOOperation` | Read/write audio data |

### 2.5 Feeding Audio Data — Ring Buffer Pattern

```
┌──────────────────────────────────────────────┐
│ HandLive App Process                          │
│                                               │
│  WebSocket → Opus Decode → PCM samples        │
│     ↓                                         │
│  Ghi vào Shared Memory Ring Buffer            │
└────────────────┬─────────────────────────────┘
                 │ Shared Memory / Mach IPC
┌────────────────▼─────────────────────────────┐
│ coreaudiod Process (chạy AudioServerPlugin)   │
│                                               │
│  DoIOOperation() → đọc từ Ring Buffer         │
│     ↓                                         │
│  Cung cấp samples cho Zoom/Meet/FaceTime      │
└──────────────────────────────────────────────┘
```

**Cách BlackHole làm:** BlackHole dùng ring buffer nội bộ trong cùng process coreaudiod. App output ghi vào ring buffer, app input đọc từ cùng ring buffer → zero latency loopback. Cho HandLive, cần IPC từ app process sang coreaudiod process.

### 2.6 AudioStreamBasicDescription cho Virtual Mic

```c
AudioStreamBasicDescription asbd = {
    .mSampleRate        = 48000.0,      // hoặc 44100.0
    .mFormatID          = kAudioFormatLinearPCM,
    .mFormatFlags       = kAudioFormatFlagIsFloat
                        | kAudioFormatFlagIsPacked
                        | kAudioFormatFlagIsNonInterleaved,
    .mBytesPerPacket    = 4,            // 32-bit float
    .mFramesPerPacket   = 1,
    .mBytesPerFrame     = 4,
    .mChannelsPerFrame  = 1,            // mono cho mic
    .mBitsPerChannel    = 32,
};
```

**Khuyến nghị cho HandLive:**
- Sample rate: 48000 Hz (chuẩn cho video conferencing)
- Channels: 1 (mono) — đủ cho microphone
- Bit depth: 32-bit float (macOS Core Audio native format)
- Buffer size: 512 hoặc 256 samples (10.7ms hoặc 5.3ms tại 48kHz)

### 2.7 Hiển thị trong System Settings

Có. AudioServerPlugin tạo device xuất hiện trong:
- System Settings > Sound > Input (chọn làm microphone)
- Audio MIDI Setup (chi tiết hơn)
- Mọi app chọn audio input: Zoom, Teams, Chrome, Safari, FaceTime, OBS

### 2.8 libASPL — Thư viện hỗ trợ

[libASPL](https://github.com/gavv/libASPL) là C++17 library bọc AudioServerPlugin API:

```cpp
// Ví dụ tạo virtual device với libASPL
auto context = std::make_shared<aspl::Context>();

auto device = std::make_shared<aspl::Device>(context, "HandLive Mic");
device->SetSampleRate(48000);
device->SetChannelCount(1);

auto plugin = std::make_shared<aspl::Plugin>(context);
plugin->AddDevice(device);

auto driver = std::make_shared<aspl::Driver>(context, plugin);
```

**Ưu điểm libASPL:** Không cần viết property dispatch thủ công (~2000 LOC trong BlackHole.c). Dùng C++ types thay vì CoreFoundation. Có sẵn volume/mute controls.

### 2.9 Cài đặt Plugin

```
/Library/Audio/Plug-Ins/HAL/HandLiveMic.driver/
  Contents/
    Info.plist
    MacOS/
      HandLiveMic (binary)
```

Sau khi copy, restart coreaudiod:
```bash
sudo launchctl kickstart -kp system/com.apple.audio.coreaudiod
```

**Không cần kernel extension.** AudioServerPlugin là userspace plugin.

### 2.10 Dual Output — Virtual Mic + Call Audio

Có thể. HandLive app nhận audio từ Android qua WebSocket:

```
Android Audio → WebSocket → HandLive macOS App → Opus Decode → PCM
   ├── Ghi vào shared memory → AudioServerPlugin → Virtual Mic
   │     → Zoom/Meet dùng làm microphone input
   └── Ghi vào AVAudioEngine → Speaker output
         → User nghe trực tiếp (call audio feature hiện tại)
```

App tách PCM stream ra 2 đường: một đường feed virtual mic, một đường play qua speaker. Không conflict vì audio data chỉ cần copy sang 2 destinations.

---

## 3. IPC giữa App chính và Extensions

### 3.1 Cho Virtual Camera (CMIOExtension)

#### Phương án 1: Sink Stream (khuyến nghị cho đơn giản)

CMIOExtension có built-in mechanism: **Sink Stream**.

```
HandLive App → CMIOExtensionStream (sink direction) → Extension
Extension → CMIOExtensionStream (source direction) → Zoom/Meet
```

- App container dùng CoreMediaIO client API gửi `CMSampleBuffer` vào sink stream
- Extension nhận qua `consumeSampleBuffer(from:)`, forward ra source stream
- **Không cần IPC thủ công** — Apple quản lý communication

**Nhược điểm:** Sink stream chỉ available cho **container app** (app cùng bundle). Nếu cần app khác gửi frame → phải dùng IPC khác.

#### Phương án 2: IOSurface + Mach Ports (khuyến nghị cho hiệu năng)

```swift
// Trong app (sender):
let surface = IOSurface(properties: [
    .width: 1920,
    .height: 1080,
    .bytesPerElement: 4,
    .pixelFormat: kCVPixelFormatType_32BGRA
] as [IOSurfacePropertyKey: Any])!

// Lock, ghi pixel data
surface.lock(options: [], seed: nil)
memcpy(surface.baseAddress, frameData, frameSize)
surface.unlock(options: [], seed: nil)

// Gửi IOSurface ID qua Mach port hoặc App Group UserDefaults
let surfaceID = surface.surfaceID  // UInt32
```

```swift
// Trong extension (receiver):
let surface = IOSurface(machPort: machPort)
// hoặc
let surface = IOSurfaceLookup(surfaceID)

// Tạo CVPixelBuffer từ IOSurface (zero-copy!)
var pixelBuffer: CVPixelBuffer?
CVPixelBufferCreateWithIOSurface(nil, surface, nil, &pixelBuffer)
```

**Zero-copy:** Cả 2 process map cùng physical memory pages. Không copy data, chỉ truyền surface ID (4 bytes).

**OBS dùng cách này:** IOSurface cho zero-copy frame sharing giữa OBS process và camera extension.

#### Phương án 3: App Group + UserDefaults (cho metadata)

```swift
// Shared UserDefaults qua App Group
let defaults = UserDefaults(suiteName: "group.com.handlive.app")
defaults?.set(surfaceID, forKey: "currentSurfaceID")
defaults?.set(true, forKey: "isStreaming")
```

Chỉ dùng cho metadata nhỏ (streaming state, frame rate, resolution). KHÔNG dùng cho video frames.

#### Phương án 4: CFMessagePort

```swift
// App tạo local port
let port = CFMessagePortCreateLocal(nil, 
    "com.handlive.camera.port" as CFString,
    messageCallback, nil, nil)

// Extension kết nối
let remote = CFMessagePortCreateRemote(nil, 
    "com.handlive.camera.port" as CFString)

// Gửi data (nhỏ — surfaceID, không phải frame data)
CFMessagePortSendRequest(remote, 0, data, 1.0, 1.0, nil, nil)
```

**Lưu ý:** CFMessagePort có thể không hoạt động trong sandbox nghiêm ngặt. XPC từ app đến CMIOExtension hiện **KHÔNG** được hỗ trợ chính thức (theo Apple Developer Forums).

### 3.2 Cho Virtual Microphone (AudioServerPlugin)

AudioServerPlugin chạy trong `coreaudiod`, cần IPC từ HandLive app.

#### Phương án 1: Shared Memory Ring Buffer (khuyến nghị)

```
┌─────────────────────────────────────────────────┐
│          Shared Memory Layout                    │
│                                                  │
│  [Header: 64 bytes]                              │
│    write_pos: UInt64 (atomic)                    │
│    read_pos: UInt64 (atomic)                     │
│    sample_rate: UInt32                           │
│    channels: UInt32                              │
│    is_active: Bool                               │
│    buffer_size: UInt32                           │
│                                                  │
│  [Ring Buffer: N bytes]                          │
│    Float32 samples, circular                     │
│                                                  │
└─────────────────────────────────────────────────┘
```

```c
// Tạo shared memory (POSIX)
int fd = shm_open("/handlive_audio", O_CREAT | O_RDWR, 0644);
ftruncate(fd, BUFFER_SIZE);
void* ptr = mmap(NULL, BUFFER_SIZE, PROT_READ | PROT_WRITE, MAP_SHARED, fd, 0);
```

**App (writer):**
```c
// Ghi PCM samples vào ring buffer
atomic_store(&header->write_pos, new_write_pos);
memcpy(buffer + (write_pos % ring_size), samples, sample_count * sizeof(float));
```

**Plugin trong coreaudiod (reader) — DoIOOperation:**
```c
static OSStatus DoIOOperation(
    AudioServerPlugInDriverRef driver,
    AudioObjectID deviceID,
    AudioObjectID streamID,
    UInt32 clientID,
    UInt32 operationID,
    UInt32 ioBufferFrameSize,
    const AudioServerPlugInIOCycleInfo* ioCycleInfo,
    void* ioMainBuffer,
    void* ioSecondaryBuffer
) {
    if (operationID == kAudioServerPlugInIOOperationReadInput) {
        // Đọc từ shared memory ring buffer
        UInt32 write_pos = atomic_load(&header->write_pos);
        memcpy(ioMainBuffer, ring_buffer + (read_pos % ring_size),
               ioBufferFrameSize * sizeof(float));
        atomic_store(&header->read_pos, new_read_pos);
    }
    return kAudioHardwareNoError;
}
```

#### Phương án 2: Mach Ports (thấp hơn nhưng phức tạp hơn)

Dùng `mach_msg()` gửi audio buffers. Latency rất thấp (~microseconds) nhưng API phức tạp. Ít project dùng cho audio IPC.

### 3.3 So sánh Latency các phương pháp IPC

| Phương pháp | Latency | Throughput | Phù hợp cho |
|---|---|---|---|
| **IOSurface** | ~0 (zero-copy) | Rất cao | Video frames |
| **Shared Memory (mmap)** | ~0 (zero-copy) | Rất cao | Audio samples |
| **Mach Ports** | ~1-10μs | Trung bình | Signaling, nhỏ data |
| **CFMessagePort** | ~10-100μs | Thấp | Control messages |
| **XPC** | ~100μs-1ms | Trung bình | Structured data |
| **App Group UserDefaults** | ~1-10ms | Rất thấp | Metadata, flags |
| **Unix Domain Socket** | ~10-50μs | Trung bình | Audio streaming (fallback) |

### 3.4 Sandboxing

| Component | Sandbox | Hạn chế |
|---|---|---|
| **HandLive app** | App Sandbox (nếu App Store) | Cần entitlements cho network, camera |
| **CMIOExtension** | System Extension sandbox | Hạn chế filesystem, cần App Group cho shared data |
| **AudioServerPlugin** | coreaudiod sandbox | Chỉ đọc bundle + system libs. KHÔNG truy cập user files |

**Quan trọng:** AudioServerPlugin trong coreaudiod bị sandbox rất nghiêm ngặt:
- Chỉ đọc files trong plugin bundle
- Chỉ đọc system libraries
- Không truy cập user documents, network, hay filesystem tùy ý
- Shared memory (POSIX shm) hoạt động vì là kernel-managed

---

## 4. Ma trận Tương thích

### 4.1 CMIOExtension — macOS Version Support

| macOS | Trạng thái CMIOExtension | Ghi chú |
|---|---|---|
| 12.3 (Monterey) | Introduced | API mới, có thể có bugs |
| 13.0 (Ventura) | Ổn định hơn | OBS bắt đầu hỗ trợ. Hỗ trợ hardware camera trong extension |
| 14.0 (Sonoma) | **Ổn định, khuyến nghị tối thiểu** | API shape ổn định. DAL plugin bắt đầu bị loại bỏ |
| 15.0 (Sequoia) | Mature | Continuity Camera dùng CMIOExtension |
| 16.0+ | Tiêu chuẩn | DAL plugin không còn được hỗ trợ |

**Khuyến nghị cho HandLive:** Target macOS 14+ (Sonoma). Phù hợp với kiến trúc hiện tại (macOS 13+) và tránh API instability của 12.3/13.

### 4.2 Virtual Camera — App Compatibility

| App | CMIOExtension | DAL Plugin (legacy) | Ghi chú |
|---|---|---|---|
| **FaceTime** | Hoạt động | KHÔNG (từ 12.3+) | Chỉ CMIOExtension |
| **Zoom** | Hoạt động | Hoạt động | Cả 2 |
| **Google Meet (Chrome)** | Hoạt động | Hoạt động | WebRTC enumerate devices |
| **Microsoft Teams** | Hoạt động | Hoạt động | Cả 2 |
| **Safari** | Hoạt động | KHÔNG (từ 12.3+) | Chỉ CMIOExtension |
| **OBS Studio** | Hoạt động | Hoạt động | OBS tự dùng CMIOExtension cho output |
| **QuickTime Player** | Hoạt động | KHÔNG (từ 12.3+) | Chỉ CMIOExtension |
| **PhotoBooth** | Hoạt động | KHÔNG (từ 12.3+) | Chỉ CMIOExtension |
| **Discord** | Hoạt động | Hoạt động | Cả 2 |

**Kết luận:** CMIOExtension hoạt động với TẤT CẢ apps. Legacy DAL plugin bị block bởi Apple apps (FaceTime, Safari, QuickTime). Không có app nào block virtual camera kiểu CMIOExtension — đây là API chính thức của Apple, Continuity Camera cũng dùng.

### 4.3 Virtual Microphone — App Compatibility

AudioServerPlugin tạo device ở system level → **mọi app** nhìn thấy nó:

| App | Hoạt động | Ghi chú |
|---|---|---|
| **FaceTime** | Có | Chọn trong audio input |
| **Zoom** | Có | Chọn trong microphone settings |
| **Google Meet** | Có | Chrome enumerate qua Web Audio API |
| **Teams** | Có | Chọn trong audio settings |
| **Safari** | Có | WebRTC getUserMedia |
| **OBS** | Có | Chọn trong audio input |
| **GarageBand/Logic** | Có | Core Audio device |
| **System Settings** | Có | Xuất hiện trong Sound > Input |

**Không có app nào block virtual audio devices.** BlackHole, Soundflower đều hoạt động universal.

### 4.4 Signing & Distribution

| Yêu cầu | Virtual Camera (CMIOExtension) | Virtual Mic (AudioServerPlugin) |
|---|---|---|
| **Code Signing** | Bắt buộc (Developer ID hoặc App Store) | Bắt buộc (Developer ID) |
| **Notarization** | Bắt buộc | Bắt buộc |
| **App Store** | **Có thể** (System Extension entitlement) | **KHÔNG** (HAL plugin cài ngoài sandbox) |
| **Developer ID** | Có thể | Có thể |
| **System approval** | User phải cho phép trong System Settings | Không cần approval (chỉ cần install) |
| **Entitlement đặc biệt** | `com.apple.developer.system-extension.install` | Không |

**App Store distribution:**
- Virtual Camera: Có thể ship qua App Store (cần xin System Extension entitlement từ Apple)
- Virtual Microphone: KHÔNG thể ship qua App Store (HAL plugin phải cài vào `/Library/Audio/Plug-Ins/HAL/`)
- **Giải pháp:** Ship app qua Developer ID (direct download) với cả 2 components. Hoặc ship app qua App Store + installer riêng cho HAL plugin.

---

## 5. Kiến trúc tổng hợp cho HandLive

### 5.1 Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                    Android Phone                                 │
│                                                                  │
│  Camera Preview → H.264 Encode → ┐                              │
│  Microphone → Opus Encode ──────→ ├→ WebSocket Server (Ktor)    │
│                                   │                              │
└───────────────────────────────────┼──────────────────────────────┘
                                    │ WSS (E2E encrypted)
                                    │
┌───────────────────────────────────▼──────────────────────────────┐
│                    macOS HandLive App                             │
│                                                                  │
│  WebSocket Client ─→ Decrypt ─→ ┐                               │
│                                  ├→ VideoToolbox H.264 Decode    │
│                                  │    → CVPixelBuffer            │
│                                  │    → IOSurface (zero-copy)    │
│                                  │    → CMIOExtension Sink       │
│                                  │                               │
│                                  ├→ Opus Decode → PCM Float32   │
│                                  │    → Shared Memory Ring Buf   │
│                                  │    → AudioServerPlugin        │
│                                  │                               │
│                                  └→ AVAudioEngine (speaker out) │
│                                      (call audio, hiện tại)     │
└──────┬──────────────────────────────────────────┬───────────────┘
       │                                          │
       │ IOSurface / Sink Stream                  │ POSIX Shared Memory
       │                                          │
┌──────▼──────────────────────┐  ┌────────────────▼───────────────┐
│  CMIOExtension Process       │  │  coreaudiod Process            │
│  (System Extension)          │  │  (AudioServerPlugin)           │
│                              │  │                                │
│  Source Stream ──→ Consumer  │  │  DoIOOperation ──→ Consumer    │
│  "HandLive Camera"           │  │  "HandLive Microphone"         │
└──────────────────────────────┘  └────────────────────────────────┘
       │                                          │
       ▼                                          ▼
  Zoom, FaceTime, Meet,                    Zoom, FaceTime, Meet,
  OBS, Safari, Chrome...                   OBS, Safari, Chrome...
```

### 5.2 Latency Budget

```
Android Camera capture:     ~16ms (60fps) hoặc ~33ms (30fps)
H.264 encode:               ~5-10ms (hardware)
WebSocket LAN transfer:     ~1-5ms
E2E decrypt:                ~0.1ms
VideoToolbox H.264 decode:  ~3-5ms (hardware)
IOSurface write:            ~0 (zero-copy)
CMIOExtension read+send:    ~0.5ms
──────────────────────────────────────
Total camera latency:       ~25-55ms (rất tốt)

Android Mic capture:        ~20ms (Opus frame)
Opus encode:                ~2-3ms
WebSocket transfer:         ~1-5ms
Opus decode:                ~2-3ms
Shared memory write:        ~0 (zero-copy)
AudioServerPlugin read:     ~5-10ms (buffer size)
──────────────────────────────────────
Total mic latency:          ~30-40ms (chấp nhận cho realtime)
```

### 5.3 Effort Estimate bổ sung

| Component | Effort | Ghi chú |
|---|---|---|
| CMIOExtension implementation | 2-3 tuần | Xcode target mới, sink/source streams |
| IOSurface IPC layer | 1-2 tuần | Frame sharing, synchronization |
| AudioServerPlugin (dùng libASPL) | 2-3 tuần | Virtual mic device, ring buffer |
| Shared memory audio IPC | 1 tuần | POSIX shm, ring buffer, sync |
| Android camera capture + encode | 2-3 tuần | Camera2 API, MediaCodec H.264 |
| Android mic capture + Opus | 1 tuần | Đã có phần lớn từ call audio |
| WebSocket video/audio stream | 1-2 tuần | Binary frames, flow control |
| Installer/activation flow | 1 tuần | System Extension approval, HAL install |
| Testing + compatibility | 2 tuần | FaceTime, Zoom, Meet, Chrome, OBS |
| **Tổng** | **~3-4 person-months** | Có thể làm song song với Phase hiện tại |

---

## 6. Tham khảo quan trọng

### Mã nguồn mở

| Project | URL | Dùng cho |
|---|---|---|
| OBS Virtual Camera | https://github.com/obsproject/obs-studio/pull/7777 | CMIOExtension + IOSurface reference |
| ldenoue/cameraextension | https://github.com/ldenoue/cameraextension | Sink/Source stream sample |
| Celluloid | https://github.com/whyisjake/Celluloid | CMIOExtension + Core Image filters |
| BlackHole | https://github.com/ExistentialAudio/BlackHole | AudioServerPlugin reference |
| libASPL | https://github.com/gavv/libASPL | C++ wrapper cho AudioServerPlugin |
| Roc VAD | https://github.com/roc-streaming/roc-vad | libASPL real-world usage |
| BackgroundMusic | https://github.com/kyleneideck/BackgroundMusic | AudioServerPlugin complex example |

### Apple Documentation

| Resource | URL |
|---|---|
| WWDC22: Create camera extensions with Core Media IO | https://developer.apple.com/videos/play/wwdc2022/10022/ |
| CMIOExtension documentation | https://developer.apple.com/documentation/coremediaio/creating_a_camera_extension_with_core_media_i_o |
| AudioServerPlugIn.h header | https://github.com/phracker/MacOSX-SDKs (xem header) |
| IOSurface documentation | https://developer.apple.com/documentation/iosurface |

### Bài viết kỹ thuật

| Bài viết | URL |
|---|---|
| Core Media IO Camera Extensions Part 1-3 | https://theoffcuts.org/posts/core-media-io-camera-extensions-part-one/ |
| IOSurface in depth: zero-copy | https://www.macinternals.app/en/blog/iosurface-in-depth |

---

## 7. Câu hỏi mở

1. **App Store vs Developer ID:** AudioServerPlugin KHÔNG ship được qua App Store. Quyết định: ship toàn bộ qua Developer ID (đơn giản hơn) hay ship app qua App Store + installer riêng cho audio plugin?

2. **Android camera resolution/format:** Cần xác định resolution mặc định (720p? 1080p?) và codec (H.264 Baseline? Main? MJPEG fallback?). Ảnh hưởng đến latency và CPU usage.

3. **Nhiều consumer đồng thời:** Khi cả Zoom VÀ OBS muốn dùng HandLive Camera cùng lúc, CMIOExtension có support multiple clients không? (Có — Apple quản lý việc này, source stream broadcast cho mọi consumer.)

4. **Audio format negotiation:** Nếu Zoom yêu cầu 44100Hz nhưng HandLive cung cấp 48000Hz, ai làm resampling? (Core Audio HAL tự resample giữa device format và client format.)

5. **Khi Android disconnect:** Virtual camera hiển thị gì? Options: blank đen, ảnh "No Signal", frame cuối cùng frozen. Virtual mic: output silence (zero samples).
