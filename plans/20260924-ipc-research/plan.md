# IPC Research: macOS App-to-Extension Communication

> **Ngày:** 2026-09-24
> **Trạng thái:** Hoàn tất nghiên cứu
> **Mục đích:** Nghiên cứu phương pháp IPC cho HandLive macOS app giao tiếp với CMIOExtension (virtual camera) và AudioServerPlugin (virtual microphone)

---

## 1. Tổng quan IPC Methods trên macOS

### 1.1 XPC Services

**Cơ chế:** Message-based IPC dựa trên Mach messages, quản lý lifecycle qua launchd.

- API: `xpc_connection_create()`, `xpc_connection_send_message()`, `NSXPCConnection`
- Data types hỗ trợ: Data, Boolean, Double, String, Int, Date, UUID, Array, Dictionary
- IOSurface có thể gửi qua NSXPCConnection (macOS 10.12+) hoặc `IOSurfaceCreateXPCObject()`
- Sandbox-compatible: services chạy với quyền tối thiểu mặc định
- Latency: message queuing + dispatch lên runtime-managed queues

**Hạn chế cho CMIOExtension:** CMIOExtension chạy dưới user `_cmiodalassistants`, main app chạy dưới GUI user => XPC endpoints không truy cập được lẫn nhau. `CMIOExtensionMachServiceName` là cơ chế loading của hệ thống, KHÔNG phải endpoint XPC cho app dùng. Apple KHÔNG recommend XPC cho CMIOExtension IPC.

### 1.2 Mach Ports

**Cơ chế:** Kernel-maintained message queues, nền tảng cho mọi IPC trên macOS.

- API: `mach_msg_send()`, `mach_msg_receive()`
- Wrappers: `CFMachPort`/`NSMachPort`, `CFMessagePort`/`NSMessagePort`
- Latency: thấp nhất trong các phương pháp message-passing
- Có thể truyền port rights (send right, receive right) giữa processes
- IOSurface handle có thể gửi qua Mach IPC

**CFMessagePort:**
```c
CFMessagePortRef localPort = CFMessagePortCreateLocal(
    nil, CFSTR("com.example.app.port"), Callback, nil, nil);
CFMessagePortSendRequest(remotePort, messageID, data, timeout, timeout, NULL, NULL);
```
- Synchronous one-to-one communication
- Sandboxing: hạn chế — CMIOExtension không thể register global mach services

### 1.3 Shared Memory (POSIX shm)

**Cơ chế:** `shm_open()` + `mmap()` tạo vùng nhớ dùng chung giữa processes.

- System V IPC (`shmget`) bị chặn bởi App Sandbox — Apple recommend POSIX shm thay thế
- Sandbox-compatible qua App Groups: `shm_open()` với tên nhóm app group
- **Lưu ý:** Tên app group phải ngắn khi dùng với `shm_open()` (báo cáo từ developer)
- Permissions: tạo với `umask(0)` cho `0666` để cho phép cross-user access
- Phù hợp cho audio ring buffer (throughput cao, latency thấp)

**Giới hạn với CMIOExtension:** App Groups KHÔNG hoạt động giữa main app và CMIOExtension vì chạy dưới user accounts khác nhau (`_cmiodalassistants` vs GUI user). POSIX shm vẫn khả thi nếu tạo với permissions mở (`0666`).

### 1.4 IOSurface (Zero-copy Video Frame Sharing)

**Cơ chế:** Kernel-backed shared memory dành riêng cho media frames, zero-copy giữa processes.

**API chính:**
- `IOSurfaceCreate(properties)` — tạo surface mới, kernel allocate pages qua `IOMallocPageable`
- `IOSurfaceGetBaseAddress(surface)` — map surface vào CPU virtual memory
- `IOSurfaceGetID(surface)` — lấy globally unique handle ID
- `IOSurfaceLookup(surfaceID)` — process khác look up surface bằng ID
- `IOSurfaceGetBaseAddressOfPlane(surface, plane)` — truy cập individual planes (YUV)
- `IOSurfaceGetBytesPerRowOfPlane(surface, plane)` — stride info

**Zero-copy mechanism:**
- Process A tạo IOSurface => kernel allocate physical pages
- Handle ID gửi qua Mach IPC/XPC tới Process B
- Process B gọi `IOSurfaceLookup(id)` => cùng physical pages mapped vào address space khác
- **Performance:** gửi handle 4K frame ~10 microseconds vs memcpy ~3 milliseconds

**Passing IOSurface giữa processes:**
```objc
// Qua XPC (macOS 10.12+)
IOSurfaceRef surface = CVPixelBufferGetIOSurface(pixelBuffer);
[remoteProxy sendIOSurface:(__bridge_transfer IOSurface *)surface];

// Qua XPC object
xpc_object_t xpcSurface = IOSurfaceCreateXPCObject(surface);
// receiver:
IOSurfaceRef surface = IOSurfaceLookupFromXPCObject(xpcObj);
```

**Thread safety — Lock domains:**
- CPU read: multiple readers, no writers
- CPU write: exclusive access
- GPU read: multiple readers
- GPU write: exclusive access
- Locks tự động trigger cache flush operations khi transition

**Multi-plane pixel formats:**
- YUV420: Y plane (full-res 8-bit) + CbCr plane (half-width 16-bit interleaved)
- Mỗi plane có pointer, stride, pixel format riêng
- Không có overhead per-plane allocation

**Reference counting:** Span processes. Surface chỉ destroy khi last reference drop.
**Wired memory:** Active surfaces không bị VM compression/swap.

### 1.5 Memory-mapped Files

**Cơ chế:** `mmap()` trên file hệ thống hoặc `/dev/shm`.

- Đơn giản, portable
- Cần filesystem path mà cả hai process đều truy cập được
- Không zero-copy cho GPU/video — IOSurface tốt hơn
- Phù hợp cho configuration data, small payloads

### 1.6 Unix Domain Sockets

**Cơ chế:** Stream/datagram communication qua filesystem path.

- API: standard BSD socket API
- Latency thấp (kernel bypass network stack)
- Bidirectional, connection-oriented (SOCK_STREAM) hoặc connectionless (SOCK_DGRAM)
- **CMIOExtension hỗ trợ TCP sockets trên unprivileged ports (1024-65535)**

### 1.7 Distributed Notifications

**Cơ chế:** System-wide pub-sub qua `CFNotificationCenterGetDistributedCenter()` / `DistributedNotificationCenter`.

- Broadcast-based, không đảm bảo delivery order
- **Latency unbounded** — không phù hợp cho realtime
- Payload nhỏ (dictionary)
- **KHÔNG hoạt động từ CMIOExtension** (sandboxing chặn)
- Chỉ phù hợp cho signaling events đơn giản

---

## 2. IOSurface Chi tiết

### 2.1 Kernel Architecture

```
Process A                    Kernel                      Process B
───────────                 ──────                     ───────────
IOSurfaceCreate()  ──→  IOSurfaceRoot user client
                         │
                         ├─ IOMallocPageable (alloc pages)
                         ├─ IOMemoryDescriptor (kernel abstraction)
                         ├─ Globally unique handle ID
                         │
                    ◄── handle returned
                         │
    [send handle via Mach/XPC]  ──────────────────→
                         │
                    IOSurfaceLookup(id)
                         ├─ Same physical pages
                         ├─ Different virtual address
                         └─ Reference count++
```

### 2.2 Tạo IOSurface cho Video Frames

```swift
let properties: [String: Any] = [
    kIOSurfaceWidth as String: 1920,
    kIOSurfaceHeight as String: 1080,
    kIOSurfaceBytesPerRow as String: 1920 * 4,
    kIOSurfaceBytesPerElement as String: 4,
    kIOSurfacePixelFormat as String: kCVPixelFormatType_32BGRA
]
let surface = IOSurfaceCreate(properties as CFDictionary)!
let surfaceID = IOSurfaceGetID(surface)  // uint32_t, globally unique
```

### 2.3 Receiver Look Up

```swift
// Process B
let surface = IOSurfaceLookup(surfaceID)  // same physical memory
IOSurfaceLock(surface, .readOnly, nil)
let baseAddress = IOSurfaceGetBaseAddress(surface)
// ... read pixel data ...
IOSurfaceUnlock(surface, .readOnly, nil)
```

### 2.4 Tạo CVPixelBuffer từ IOSurface

```swift
var pixelBuffer: CVPixelBuffer?
CVPixelBufferCreateWithIOSurface(
    kCFAllocatorDefault,
    surface,
    nil,
    &pixelBuffer
)
// pixelBuffer wraps IOSurface — zero-copy
```

### 2.5 Performance

| Operation | Thời gian |
|-----------|----------|
| Gửi IOSurface handle (Mach IPC) | ~10 μs |
| memcpy 4K frame (8.3 MB) | ~3 ms |
| **Tiết kiệm** | **~300x** |

---

## 3. CMIOExtension (Camera Extension) IPC

### 3.1 Kiến trúc

CMIOExtension chạy trong process riêng dưới user `_cmiodalassistants` (KHÔNG phải GUI user).

**Sandbox restrictions:**
- KHÔNG thể fork/exec child processes
- KHÔNG thể truy cập Window Server
- KHÔNG thể kết nối foreground user account
- KHÔNG thể register global Mach services
- ĐƯỢC phép: USB, Bluetooth, WiFi (client), Firewire, own container, /tmp
- ĐƯỢC phép: TCP socket trên unprivileged ports (1024-65535)

**DistributedNotificationCenter:** KHÔNG hoạt động từ extension.
**Process.run():** KHÔNG được phép.
**App Groups:** KHÔNG hoạt động (user accounts khác nhau).

### 3.2 Apple Recommended IPC: Sink Streams

Apple (Quinn "The Eskimo!") recommend chia IPC thành 2 kênh:

**A. Video frame input — Sink Stream:**

Extension publish một sink stream (output device). Main app:
1. Tìm extension device qua CoreMediaIO C APIs
2. Kết nối tới sink stream
3. Enqueue sample buffers qua sink queue

```c
// App side — tìm sink stream
// Iterate từ kCMIOObjectSystemObject, tìm device với matching deviceUID
CMIOStreamID sinkStreamID = /* found via CMIOHardwareObject queries */;
CMSimpleQueueRef queue = NULL;
CMIOStreamCopyBufferQueue(sinkStreamID, &queue);

// Enqueue sample buffer
CMSimpleQueueEnqueue(queue, sampleBuffer);
```

```swift
// Extension side — nhận frames từ sink, forward tới source
self._streamSink.stream.consumeSampleBuffer(buf, ...) { error in
    // Forward to source stream cho apps (Zoom, FaceTime...)
    self._streamSource.stream.send(buf!, ...)
}
```

**Cơ chế bên dưới:** Framework tự handle IPC layer, optimize performance. Sample buffers có thể chứa IOSurface-backed CVPixelBuffer => zero-copy potential.

**B. Command & Control — Custom Properties:**

Dùng custom properties trên CMIOExtensionProviderSource cho low-bandwidth communication (start/stop, settings).

```
Property Address = {Selector (4cc), Scope, Element}
Naming convention: 4cc_{Selector}_{Scope}_{Element}
```

**Quan trọng:** AVFoundation KHÔNG hỗ trợ custom properties. Phải dùng CoreMedia IO C API trực tiếp.

### 3.3 Alternative: TCP Socket (confirmed hoạt động)

- Enable "Network" trong Sandbox Signing & Capabilities
- Extension listen TCP trên unprivileged port
- App connect tới localhost:port
- Phù hợp cho command/control, không tối ưu cho video frames

### 3.4 Thực tế từ các dự án

| Dự án | IPC Method | Ghi chú |
|--------|-----------|---------|
| Celluloid | Sink streams + Darwin notifications | "Sink streams is the correct approach" |
| LemurCam | XPC + Darwin notifications + shared memory | 4-process architecture phức tạp |
| ldenoue/cameraextension | Sink/Source stream loopback | No XPC, no shared memory |
| SimulatorCamera | CMIOExtension sink stream | IOSurface frames |

### 3.5 Kết luận cho HandLive

**Recommended:** Sink Stream pattern.
1. CMIOExtension publish sink stream + source stream
2. Main app (nhận video qua WebSocket) decode frames thành CVPixelBuffer
3. App enqueue CVPixelBuffer vào sink stream qua CoreMediaIO C API
4. Extension `consumeSampleBuffer` → forward tới source stream
5. Zoom/FaceTime/etc nhận frames từ source stream

**Ưu điểm:**
- Apple-sanctioned, documented trong WWDC22
- Framework handle IPC layer và performance optimization
- Zero-copy khi dùng IOSurface-backed pixel buffers
- Không cần workaround sandbox restrictions

---

## 4. AudioServerPlugin (Audio HAL) IPC

### 4.1 Kiến trúc

AudioServerPlugin (.driver bundle) được load bởi `coreaudiod` daemon process.

```
Install: /Library/Audio/Plug-Ins/HAL/<Name>.driver
Restart: sudo launchctl kickstart -kp system/com.apple.audio.coreaudiod
```

Plugin chạy TRONG `coreaudiod` process => mọi code trong plugin phải realtime-safe.

**Apple guidance (2025):** Cho virtual audio device, tiếp tục dùng AudioServerPlugin. AudioDriverKit (dext) cho hardware drivers.

### 4.2 IPC Patterns

#### Pattern A: Mirror Device (No IPC) — BlackHole, OpenConnct

Ring buffer nằm hoàn toàn trong driver process memory.

```
App ──[AUHAL output]──→ Sink Device (hidden)
                              │
                         Ring Buffer (16,384 frames)
                         mach_absolute_time() modulo
                              │
                         Mic Device (visible) ──→ Zoom/Teams
```

- App render audio vào sink device qua standard AUHAL output unit
- Mic device đọc từ cùng ring buffer
- Cả hai devices derive position từ `mach_absolute_time()` modulo ring length
- **KHÔNG CÓ IPC** giữa app và driver — cả hai đi qua standard CoreAudio API
- Lock-free SPSC (Single Producer Single Consumer)
- Ring size: 16,384 frames, power-of-two, sample-indexed

**Ưu điểm:** Đơn giản, zero latency, không cần IPC mechanism.
**Nhược điểm:** App phải output audio qua AUHAL — không thể inject raw PCM trực tiếp.

#### Pattern B: POSIX Shared Memory Ring — Soundboard

Driver (trong coreaudiod) tạo POSIX shared-memory region. App attach vào.

```
App ──[shm_open + mmap]──→ Shared Memory Ring ←──[RingOwner]── Driver (coreaudiod)
```

- Driver tạo shared-memory với `umask(0)` cho permissions `0666`
- App discover ring qua custom HAL properties
- App claims session, writes audio vào ring
- Driver reads từ ring trong IO cycle

**Protocol:**
1. App query device custom HAL property để lấy shm name/size
2. App `shm_open()` + `mmap()` region
3. App write PCM samples vào ring
4. Driver read trong `OnReadClientInput` callback

**Thread safety:**
- Per-lane SPSC rings (lock-free)
- High-QoS mix timer coordinates reads
- vDSP-based mixing

**Ưu điểm:** App có thể inject raw PCM trực tiếp, không cần AUHAL.
**Nhược điểm:** Phức tạp hơn, cần quản lý shared memory lifecycle.

#### Pattern C: Mach Semaphores + Shared Memory — JackRouter

```
JACK Server ──[shared memory]──→ Audio Buffers ←── AudioServerPlugin
                  │
             Mach semaphores (synchronization)
```

- Shared memory cho audio buffers
- Mach semaphores cho synchronization giữa server và clients
- Semaphore-based activation chains: client A run → signal client B
- Preserves synchronous graph activation, no additional latency

### 4.3 libASPL — C++17 Wrapper

Thư viện giúp tạo AudioServerPlugin dễ hơn.

**Key classes:**
- `aspl::Driver` — entry point
- `aspl::Plugin` — root audio object
- `aspl::Device` — virtual device
- `aspl::Stream` — audio data flow
- `aspl::VolumeControl`, `aspl::MuteControl`

**Handler interfaces:**
- `IORequestHandler::OnReadClientInput()` — realtime, read data from device to client
- `IORequestHandler::OnWriteMixedOutput()` — realtime, write mixed data to device

**Realtime safety:** Atomics + double buffering + lock-free algorithms.
- `aspl::DoubleBuffer` — blocking setter, non-blocking lock-free getter

### 4.4 Kết luận cho HandLive

**Recommended: Pattern B (POSIX Shared Memory Ring)**

Lý do:
- HandLive nhận audio qua WebSocket, decode Opus → raw PCM
- Cần inject PCM trực tiếp vào virtual mic — Pattern A (mirror device) yêu cầu AUHAL output, thêm overhead
- Pattern B cho phép app write PCM trực tiếp vào shared ring
- Driver (trong coreaudiod) đọc từ ring khi apps yêu cầu audio input

**Implementation plan:**
1. AudioServerPlugin (C/C++) tạo POSIX shm ring buffer
2. Expose shm name/config qua custom HAL properties
3. Main app discover driver, `shm_open()` + `mmap()` ring
4. App write decoded audio (Opus→PCM) vào ring buffer
5. Driver đọc từ ring trong IO callback, deliver cho Zoom/FaceTime

**Alternative:** Pattern A cũng khả thi. App decode Opus→PCM, output qua AUHAL tới hidden sink device. Driver forward từ sink ring tới visible mic device. Đơn giản hơn nhưng thêm một layer CoreAudio.

---

## 5. So sánh Latency

### 5.1 Video Frames

| Method | Latency | Throughput | Ghi chú |
|--------|---------|-----------|---------|
| IOSurface (zero-copy) | ~10 μs | Unlimited (shared memory) | Tối ưu nhất cho video |
| CMIOExtension Sink Stream | Framework-managed, low | High | Bên dưới có thể dùng IOSurface |
| memcpy 4K frame | ~3 ms | ~2.7 GB/s | 300x chậm hơn IOSurface handle passing |
| XPC + data copy | ~100 μs - 1 ms | Moderate | Overhead serialization |
| TCP socket | ~50-200 μs | Moderate | Kernel buffer copies |

### 5.2 Audio Samples

| Method | Latency | Ghi chú |
|--------|---------|---------|
| Shared memory ring (POSIX shm) | <1 μs read/write | Lock-free SPSC, tối ưu nhất |
| Mirror device (AUHAL loopback) | 0 additional | mach_absolute_time() sync, no IPC |
| Mach semaphore + shm | ~5-10 μs | Semaphore signal overhead |
| XPC message | ~50-100 μs | Không phù hợp cho realtime audio |
| TCP socket | ~50-200 μs | Không phù hợp cho realtime audio |

### 5.3 Practical Numbers

- BlackHole/OpenConnct: **"zero additional latency"** — mirror device pattern
- Soundboard: shared memory ring, latency dominated by buffer size (typically 5-20ms depending on IO buffer size)
- JackRouter: "synchronous graph activation and no additional latency"
- CMIOExtension sink stream: framework-optimized, latency comparable to real camera input

---

## 6. Sandboxing Considerations

### 6.1 CMIOExtension Sandbox

| Capability | Trạng thái |
|-----------|-----------|
| TCP sockets (unprivileged ports) | Allowed |
| USB, Bluetooth, WiFi (client) | Allowed |
| Own container, /tmp | Allowed |
| Fork/exec child processes | BLOCKED |
| Window Server access | BLOCKED |
| Global Mach service registration | BLOCKED |
| DistributedNotificationCenter | BLOCKED |
| App Group containers (shared with GUI app) | DOES NOT WORK (different users) |
| POSIX shm (with open permissions) | Possible (needs testing) |

### 6.2 AudioServerPlugin Sandbox

AudioServerPlugin chạy TRONG coreaudiod (system daemon).

- IPC allowed: semaphores, shared memory
- Older docs: "AudioServerPlugIn may not communicate with other processes" — nhưng thực tế nhiều plugin (Soundboard, JackRouter) dùng shm/Mach semaphores thành công
- Custom HAL properties: mechanism chính để app discover driver capabilities
- POSIX shm: tạo bởi driver trong coreaudiod, permissions `0666` cho phép app access

### 6.3 App Sandbox (Main App)

| IPC Method | App Sandbox | Ghi chú |
|-----------|------------|---------|
| System V IPC (shmget) | BLOCKED | `deny(1) ipc-sysv-shm` |
| POSIX shm (shm_open) | Allowed via App Groups | Tên group phải ngắn |
| XPC Services | Fully supported | Default: maximum restrictions |
| Mach ports | Limited | System-level mechanism |
| CFMessagePort | Moderate | Depends on configuration |
| TCP sockets | Allowed | With network entitlement |
| IOSurface | Allowed | Via XPC serialization |

### 6.4 Entitlements Cần thiết

**Main App:**
```xml
<key>com.apple.security.app-sandbox</key><true/>
<key>com.apple.security.application-groups</key>
<array><string>$(TeamIdentifierPrefix)com.handlive.app</string></array>
<key>com.apple.security.network.client</key><true/>
<key>com.apple.developer.system-extension.install</key><true/>
```

**CMIOExtension:**
```xml
<key>com.apple.security.app-sandbox</key><true/>
<key>com.apple.security.application-groups</key>
<array><string>$(TeamIdentifierPrefix)com.handlive.app</string></array>
<key>NSCameraUsageDescription</key><string>...</string>
<key>CMIOExtensionMachServiceName</key>
<string>$(TeamIdentifierPrefix)com.handlive.camera</string>
```

### 6.5 Distribution Differences

| | App Store | Developer ID | Direct |
|---|-----------|-------------|--------|
| App Sandbox | Required | Optional | Optional |
| System Extension | Requires approval | Works with notarization | Works |
| AudioServerPlugin | NOT on App Store | Installer package | Direct install |
| Hardened Runtime | Required | Required for notarization | Optional |

**AudioServerPlugin distribution:** KHÔNG thể đưa lên App Store. Phải distribute qua installer package (.pkg) cài vào `/Library/Audio/Plug-Ins/HAL/`.

---

## 7. Recommended Architecture cho HandLive

### 7.1 Virtual Camera (CMIOExtension)

```
WebSocket ──→ Main App ──[Sink Stream]──→ CMIOExtension ──[Source Stream]──→ Zoom/FaceTime
                │
                ├─ Decode H.264/VP8 → CVPixelBuffer (IOSurface-backed)
                ├─ Find extension device via CoreMediaIO C API
                ├─ CMIOStreamCopyBufferQueue(sinkStreamID)
                └─ CMSimpleQueueEnqueue(queue, sampleBuffer)
```

**IPC:** CMIOExtension Sink Stream (Apple-recommended)
**Frame sharing:** IOSurface-backed CVPixelBuffer qua sink stream => zero-copy potential
**Control:** Custom HAL properties cho settings

### 7.2 Virtual Microphone (AudioServerPlugin)

```
WebSocket ──→ Main App ──[shm_open + mmap]──→ Ring Buffer ←── AudioServerPlugin (coreaudiod)
                │                                                    │
                ├─ Decode Opus → PCM 16kHz/48kHz                     ├─ Read from ring
                ├─ Discover driver via custom HAL property           ├─ Deliver to clients
                └─ Write PCM vào shared ring                         └─ Zoom/FaceTime input
```

**IPC:** POSIX shared memory ring buffer
**Synchronization:** Lock-free SPSC, mach_absolute_time() based indexing
**Discovery:** Custom HAL property expose shm name + config
**Realtime safety:** Driver code C11 only, no allocations, no locks, no ObjC runtime

### 7.3 Tổng kết IPC cho HandLive

| Component | IPC Method | Lý do |
|-----------|-----------|-------|
| Video → Virtual Camera | Sink Stream (CMIOExtension) | Apple-recommended, sandbox-compatible, framework-optimized |
| Audio → Virtual Mic | POSIX shm ring buffer | Direct PCM injection, lowest latency, proven pattern (Soundboard) |
| Camera control/settings | Custom HAL properties | Low-bandwidth, built into CoreMediaIO |
| Audio control/settings | Custom HAL properties | Built into CoreAudio HAL API |
| Camera lifecycle | Darwin notifications (app→extension) | Signaling only, no data |

---

## Sources

- [IOSurface in depth — Mac Internals](https://www.macinternals.app/en/blog/iosurface-in-depth)
- [WWDC22: Create camera extensions with Core Media IO](https://developer.apple.com/videos/play/wwdc2022/10022/)
- [Apple Developer Forums: CMIOExtension IPC](https://developer.apple.com/forums/thread/706184)
- [Apple Developer Forums: Shared file access Camera Extension](https://developer.apple.com/forums/thread/731710)
- [Apple Developer Forums: CMIO Extension DistributedNotificationCenter](https://developer.apple.com/forums/thread/742513)
- [Apple Developer Forums: Shared Memory and App Sandbox](https://developer.apple.com/forums/thread/719897)
- [Core Media IO Camera Extensions Part 1 — The Offcuts](https://theoffcuts.org/posts/core-media-io-camera-extensions-part-one/)
- [Celluloid Virtual Camera — Jake Spurlock](https://jakespurlock.com/2025/12/celluloid-a-virtual-camera-app-for-macos/)
- [LemurCam Architecture — DeepWiki](https://deepwiki.com/steelbrain/LemurCam)
- [ldenoue/cameraextension — DeepWiki](https://deepwiki.com/ldenoue/cameraextension)
- [libASPL — GitHub](https://github.com/gavv/libASPL)
- [Soundboard Architecture](https://github.com/BorisVanin/soundboard/blob/main/docs/architecture.md)
- [OpenConnct — GitHub](https://github.com/trsdn/OpenConnct)
- [JackRouter AudioServerPlugin](https://github.com/jackaudio/jack-router/blob/main/macOS/docs/JackRouter-AudioServerPlugin.md)
- [BlackHole — Existential Audio](https://existential.audio/blackhole/)
- [IPC Benchmarking macOS](https://blog.antoniofrighetto.com/ipc.html)
- [Inter-Process Communication — NSHipster](https://nshipster.com/inter-process-communication/)
- [IPC on Mac OS X — SlideShare](https://www.slideshare.net/slideshow/ipc-on-mac-osx/39649434)
