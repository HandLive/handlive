# Phase 7 — spike G7: BLE L2CAP between an S25 and a Mac

Question (`plans/20260925-implementation/phase-07-ket-noi-moi-noi.md`, gate G7): does BLE L2CAP CoC
(`listenUsingInsecureL2capChannel` ↔ `CBPeripheral.openL2CAPChannel`, no bonding, no HFP, no relay) meet AC1
(Bluetooth ≤ 200 ms on an established link, also while a bulk transfer runs), AC2 (reconnect ≤ 3 s, `bt_seen`/
`bt_lost`) and AC6 (background behavior feeding into the ≤ 15 s pairing budget) between a Samsung Galaxy S25 and a
Mac? **No bearer meets AC1 on an established link → stop Phase 7**, so this spike is the gate for everything else
in the file.

## Status: gate closed 2026-10-28 — bearer is BLE L2CAP CoC + D7.1; Phase 7 continues; supplementary numbers pending

- **Gate closed (2026-10-28).** The owner ran `run-spike.sh` directly in a terminal over several sessions that day
  (Lần 1 to 5b below). AC1 is met on an established, idle link (Lần 2: one-way est. p50 91.72 / p95 133.97 ms), so
  the stop condition ("no bearer meets AC1 on an established link → stop Phase 7") did **not** trigger.
- **Bearer:** BLE L2CAP CoC (insecure) plus an app-layer link-security layer (D7.1), with 4 mandatory conditions
  (see "Kết luận bearer"): (1) control-before-bulk priority, (2) rebuild the L2CAP server and advertiser on
  `STATE_ON`, (3) accept the Doze latency or trade in a minimal GATT server for priority, (4) bound the frame
  length. Conditions 1, 2 and 4 are now in product code (`core:transport`/`feature:connection`, topic "Viết code
  Phase 7", closed by decision #3285): `BluetoothLinkScheduler` (1), `BluetoothLinkLifecycle`/
  `BluetoothAdvertising` (2), `BtRecordCodec.requireWithinBound`/`requireValidTransportRlen` (4). Condition 3 is a
  product trade-off, not a code change.
- **Supplementary numbers pending:** more reconnect rounds for a real p95 (n=3 today), Mac sleep/wake, out of range,
  and the AC6 QR-pairing flow itself. They need more S25 + Mac time (see "Chưa đo"/"What's needed next") and do not
  reopen the bearer choice.

The agent still cannot build or run the probes itself:

1. **`adb`**: `could not install *smartsocket* listener: Operation not permitted` — the sandbox will not let a
   process bind a local TCP port, at all, even after the owner granted `Bash(adb *)` and then `Bash(*)`. Those
   grants govern which commands may run, not what the OS sandbox lets a running process do.
2. **Gradle** (`./gradlew -p tools/ble-spike assembleDebug`, and the raw `gradle` binary with `GRADLE_USER_HOME`
   redirected into a writable dir to dodge the same lock-file permission problem in `~/.gradle`): fails for the
   same reason one level up — `FileLockContentionHandler` needs a local port for its own cross-process lock
   coordination. `Could not create service of type FileLockContentionHandler … java.net.SocketException:
   Operation not permitted`.
3. **`swift build`**: fails differently but for a related reason — compiling `Package.swift` shells out through
   `sandbox-exec`, and this sandbox refuses to let a sandboxed process apply a second, nested sandbox:
   `sandbox-exec: sandbox_apply: Operation not permitted`.

None of these are fixable by this agent; they are OS-level Seatbelt restrictions the owner would have to change.
Given that, the probes below were written to match the exact working patterns of the repo's other standalone
spikes (`tools/web-spike`, `tools/fake-call-app`, `Tools/HFPSpike`) as closely as possible, and reviewed by
re-reading every file against the Android/CoreBluetooth APIs by hand, since the usual `assembleDebug`/`swift build`
verification loop was not available this session. **Build verification is still owed** — see "What's needed next".

## Prepared (2026-10-28)

### Android probe — `handlive-android/tools/ble-spike/`

- **Standalone build:** own `settings.gradle.kts` reusing `gradle/libs.versions.toml` (AGP 9.4.1, Kotlin 2.4.20),
  not in the root build or CI. Package `app.handlive.spike.ble`, `minSdk 29` (L2CAP CoC needs API 29),
  `targetSdk 35`. Build: `./gradlew -p tools/ble-spike assembleDebug`.
- **BLE peripheral, `connectedDevice` foreground service** (`BleSpikeService`): advertises a fixed service UUID
  (`0000feed-0000-1000-8000-00805f9b34fb`, spike-only, Bluetooth Base UUID pattern so it encodes as a compact
  16-bit UUID and fits the 31-byte legacy advertising payload — see `BleSpikeService.kt`) with the dynamic L2CAP
  PSM as 2 little-endian bytes of advertisement service data (no GATT server stood up — the L2CAP server socket from
  `listenUsingInsecureL2capChannel` is independent of GATT); accepts one channel at a time, re-advertises and
  re-accepts after every disconnect. A 30 s heartbeat log is the proof point for AC6 (screen off 10 min / Doze):
  if `HLBLESPIKE heartbeat` keeps ticking on `adb logcat` while the S25 screen is off, advertising/accept survived.
- **Protocol** (`SpikeProtocol.kt`, mirrored in the Apple probe): 4-byte big-endian length, 1 type byte, payload.
  `PING`→`PONG` for latency; `BULK_START`(8-byte total)/`BULK_DATA`*/`BULK_END`→`BULK_ACK` for throughput, with the
  server able to answer a `PING` at any point mid-bulk-transfer (frames are typed, so the client can interleave
  one PING between two BULK_DATA frames without a second channel).
- **Control:** `adb shell am start -n app.handlive.spike.ble/.CommandActivity --es cmd <start|stop>` (adb entry
  point pattern copied from `tools/fake-call-app`'s `CommandActivity`).
- **Runbook:** `tools/ble-spike/README.md` (build, install, runtime permission grants, adb commands, event list,
  and what this spike does not cover — RFCOMM, Wi-Fi Direct, link encryption, see below).

### macOS probe — `handlive-apple/Tools/BLESpike/`

- **SwiftPM executable**, no app bundle, Info.plist embedded in the binary like `HFPSpike` (so macOS can prompt
  for Bluetooth access run from a terminal). Links `CoreBluetooth` only. Build: `swift build -c release`.
- **Central** (`SpikeCentral`): scans for the fixed service UUID, reads the PSM out of
  `CBAdvertisementDataServiceDataKey`, connects, opens the L2CAP channel (`openL2CAPChannel`, never triggers
  pairing). `FramedChannel` wraps the channel's `InputStream`/`OutputStream` (Foundation `Stream`, not a raw
  socket) with the same length-prefixed framing as the Android side.
- **Measurement sequence** (`Measurements.swift`, `MeasurementRunner.run`): 30 baseline PINGs → 1 MB bulk transfer
  with a PING interleaved every ~10 % of the transfer → 5 MB the same way → a human-driven `bt_lost`/`bt_seen`
  reconnection loop (default 3 rounds; the probe prints a prompt and waits for the peer to disappear and come
  back — phone Bluetooth off, out of range, or Mac sleep/wake — rather than forcing the disconnect itself, so the
  numbers reflect the real scenarios AC2 cites).
- **Methodology already decided (see `README.md`/`README.vi.md` for the full text)**, because the brief asks for
  "ghi số thật, kèm cách đo":
  - **Latency** is measured as a PING/PONG round trip (`rtt_ms`); there is no shared clock between the two
    machines for a true one-way number, so the probe reports half the RTT as the one-way estimate and that is
    what should be compared against AC1's 200 ms, not the raw RTT.
  - **Throughput** is the sender's own `BULK_START` → all `BULK_DATA` → `BULK_END` → received `BULK_ACK` elapsed
    time, which includes one final round trip, not pure transfer time.
  - **Latency "while transferring"** is PINGs interleaved on the *same* L2CAP stream as the bulk data (a channel
    has exactly one stream each way) — not a true parallel measurement; the report must say so next to the
    numbers, not just show them.
  - **Reconnection**: `bt_lost` = this process's `didDisconnectPeripheral`; `bt_seen` = the next successful
    `didOpen` L2CAP channel after a fresh scan; record the cause (Bluetooth off / out of range / Mac sleep) per
    round since AC2 may behave differently by cause.
- **`state` subcommand**: prints `CBManager.state` and exits — this is the check the team asked for in case
  CoreBluetooth reports `poweredOff` or `unauthorized` on this Mac. **Not run yet** (blocked on the `swift build`
  sandbox failure above); run it first, before anything else, once build access is unblocked.

### One-shot runner — `handlive-android/tools/ble-spike/run-spike.sh`

Chains build → install → grant the Nearby-devices/notification runtime permissions → start the Android service →
build the macOS probe → run the full measurement sequence → stop the service → pull `adb logcat -s HLBLESPIKE`.
Written because every step needs `adb` or local-port-binding `gradle`/`swift build`, none of which this agent's
sandbox allows; it is meant to be run directly in a normal terminal (`tools/ble-spike/run-spike.sh [rounds]
[out-dir]`), not through the agent. Usage is also in the Android README.

### Scan-response layout, task #187 (2026-10-28) — code sẵn sàng, **chưa đo riêng theo quyết định của sếp (#3309)**

Theo #3291 (Minh2), trước khi chốt vector service data cho A7.1/M7.1 cần thử layout quảng bá thật của 0.4.5 trên
S25 + Mac — UUID 128-bit đã chiếm 21/31 byte của gói quảng bá, nên service data phải nằm ở scan response (29 byte).
Cả hai bên đã có chế độ đo riêng, tách khỏi luồng PING/BULK hiện có (không đụng `SpikeProtocol.SERVICE_UUID`
16-bit đang dùng cho các "Lần" đo ở trên):

- **Android** (`BleSpikeService.kt`): `adb shell am start -n app.handlive.spike.ble/.CommandActivity --es cmd
  start --es layout scanresp` chuyển sang layout `BT_SERVICE_UUID` thật
  (`3b3a01f9-ab27-44a8-bb68-b9b11a488bdb`, hằng số mới `SpikeProtocol.SERVICE_UUID_128`): gói quảng bá chỉ có
  Flags (3, platform tự thêm) + Complete list 128-bit Service UUID (18) = 21 byte; scan response là một AD Service
  Data 128-bit = header+UUID (18) + `ver`(1) ‖ `psm`(2) ‖ 2 hint giả 4-byte-0 (8) = 29 byte, đúng công thức bảng
  0.4.5 (18 + 3 + 4×2, `BT_ADV_MAX_HINTS`=2). Hint thật (HMAC-SHA256) là việc của A7.1, spike này chỉ test khung.
  Event mới `advertise_layout` ghi layout đang dùng; `advertise_start_success`/`advertise_start_failure` (sẵn có)
  trả lời câu "có báo ADVERTISE_FAILED không".
- **Mac** (`ScanResponseProbe.swift`, lệnh mới `BLESpike scanresp --rounds <n> --log <file>`): quét riêng theo UUID
  128-bit, đo thời gian từ lúc bắt đầu quét tới lần đầu thấy `CBAdvertisementDataServiceDataKey` cho UUID đó, lặp
  mặc định 10 lần, không mở kết nối L2CAP. **Lưu ý đọc số**: CoreBluetooth trả về service data đã bóc UUID + header
  AD, nên `service_data_bytes` log được sẽ là 11 (`ver`+`psm`+2 hint), không phải 29 — cộng 18 vào thì ra đúng tổng
  scan response 29 byte của bảng spec; đừng đọc "11 byte" thành "Mac không nhận đủ 29 byte".
- **`run-spike.sh --scanresp [rounds=10] [out-dir]`**: build/install/grant như các mode khác, bật layout
  `scanresp`, đo 10 vòng màn hình sáng (`mac-scanresp-screenon.jsonl`), tắt màn hình S25 (`KEYCODE_SLEEP`) rồi đo
  tiếp 10 vòng (`mac-scanresp-screenoff.jsonl`), luôn đánh thức lại màn hình trước khi thoát (cả khi lỗi giữa
  chừng, cờ `SCANRESP_SCREEN_OFF` trong `cleanup()`).
- **Build verification**: `swiftc -typecheck` (bỏ qua bước build manifest của `swift build` — chính bước đó mới
  bị sandbox chặn `sandbox_apply`, xem "Status" đầu file) chạy sạch trên toàn bộ `Sources/BLESpike/*.swift`, 0 lỗi
  — chỉ warning Sendable-closure đã có sẵn trong code cũ, không phải do thay đổi lần này. Phía Kotlin vẫn chặn bởi
  cùng giới hạn sandbox đã ghi ở "Status" (Gradle cần bind port) — đã soát tay theo đúng chữ ký API Android
  (`BluetoothLeAdvertiser.startAdvertising(settings, advertiseData, scanResponse, callback)`, overload có thật từ
  API 21) và tính tay byte budget (khớp bảng 0.4.5, xem trên).
- **Không chạy đo riêng**: sếp quyết không cần (#3309) — code giữ nguyên trong ble-spike. Scan response chưa đo
  riêng; kiểm khi A7.1b/M7.1c chạy trên S25 + Mac.

## Measurements against AC1 / AC2 / AC6

### Lần 1 (trước khi tối ưu) — 2026-10-28 10:44, chạy thật trên S25 + Mac

Nguồn: `reports/assets/ble-g7/mac-run.jsonl`, `run.log` (không có `android-HLBLESPIKE.log` cho lần này — script bị
harness dừng ở ~600 s trước khi tới bước `trap cleanup EXIT` kéo log Android). Đây là số liệu **trước** các thay
đổi rút gọn bài đo của task #165 (xem "Ghi nhận & thay đổi #165" ngay dưới bảng).

| Scenario | Metric | Target | S25 ↔ Mac | Notes |
|---|---|---|---|---|
| 1 KB, established link, idle | latency p50 / p95 (one-way est.) | AC1 ≤ 200 ms | **149.76 / 179.38 ms** | n=30; đạt AC1 nhưng sát ngưỡng (xem nhận xét) |
| 1 KB, during 1 MB transfer | latency p50 / p95 (one-way est.) | AC1 ≤ 200 ms | **7725.3 / 7768.4 ms** | n=8; không đạt AC1 — xếp hàng FIFO sau dữ liệu bulk đang gửi, chưa có kênh ưu tiên (D7.1) |
| 1 KB, during 5 MB transfer | latency p50 / p95 (one-way est.) | AC1 ≤ 200 ms | ~19814.6 / ~33584.4 ms (tính tay) | n=9, bài chưa hoàn tất — tính trực tiếp từ 9 mẫu `bulk_5mb_in_flight_ping` trong log trước khi bị dừng |
| 1 MB transfer | throughput | — (informational) | **7.45 KB/s** (0.00745 MB/s), 134.19 s | thấp hơn nhiều so với L2CAP CoC thường đạt (50–100+ KB/s) |
| 5 MB transfer | throughput | — (informational) | **chưa xong**: 4,571,136/5,000,000 byte (91 %) ở ~564 s link time khi harness dừng lệnh ở 600 s wall-clock | ở tốc độ 7.45 KB/s, 5 MB đầy đủ cần ~671 s |
| Reconnect, Bluetooth off/on | bt_lost → bt_seen | AC2 ≤ 3 s | — | chưa tới được — bài 5 MB chưa xong nên `reconnectLoop` chưa chạy |
| Reconnect, out of range | bt_lost → bt_seen | AC2 ≤ 3 s | — | chưa tới được, lý do như trên |
| Reconnect, Mac sleep/wake | bt_lost → bt_seen | AC2 ≤ 3 s | — | chưa tới được, lý do như trên |
| S25 screen off 10 min / Doze | advertising + accept still running | AC6 (feeds the pairing budget) | — | pending, read from `HLBLESPIKE heartbeat` |

**Nghi vấn nguyên nhân (chưa kết luận bearer):** RTT baseline dao động 150–330 ms ở 6 ping đầu rồi ổn định rất đều
quanh ~300 ms từ seq 6 trở đi (ví dụ seq14–17: 299.52/299.89/299.51/299.58 ms — sát nhau tới 2 số lẻ, không giống
jitter ngẫu nhiên). Khớp với giả thuyết: kiến trúc dùng `BluetoothSocket` qua `listenUsingInsecureL2capChannel`
(L2CAP CoC thuần, không dựng GATT server), nên **Android không có API công khai nào để yêu cầu connection interval
nhanh hơn** — `BluetoothGatt.requestConnectionPriority()` chỉ tồn tại trên kết nối GATT, không áp dụng cho
L2CAP socket thuần (đã ghi chú tại `BleSpikeService.kt:244-249`). Link có thể đã "rơi" về một connection interval
tiết kiệm năng lượng (~300 ms) ngay sau khi kết nối ổn định, do không bên nào yêu cầu giữ interval nhanh. Số
throughput 1 MB (7.45 KB/s) khớp chính xác với cách chia nhóm trong code đo: mỗi nhóm "7 chunk × 16 KB = 114688
byte" giữa hai lần ping mất đều ~15.27 s (log `bulk_1mb_in_flight_ping`, các mốc `bytes_sent` cách nhau đúng
114688 với `t_ms` cách nhau đúng ~15270 ms) — tốc độ ổn định tuyến tính như vậy cho thấy thời gian bị quyết định
bởi tốc độ truyền thật của link, không phải do code đo chủ động sleep/poll. Ping chậm trong lúc truyền bulk
(7.7–33.6 s one-way) là hệ quả FIFO đã biết (một stream duy nhất, ping phải đợi hết bulk đã enqueue trước nó —
thuộc thiết kế D7.1, không phải lỗi của bài đo).

**Lỗi thật đã tìm và sửa trong code thử (không phải nguyên nhân chính của các số trên, nhưng là race condition có
thật):** `FramedChannel.swift` — `send()` được gọi từ `Task` của Swift Concurrency (không ràng buộc vào main
thread), còn `pendingWrite` và các `Stream` lại được `schedule(in: .main, forMode: .default)`; gọi `send()` từ một
luồng khác đồng thời với `flushIfPossible()` (được gọi lại từ callback `.hasSpaceAvailable` trên main thread) tạo
race trên cùng biến `pendingWrite` (kiểu `Data`, không an toàn khi đọc/ghi đồng thời). Đã sửa bằng cách đưa toàn bộ
việc ghi `pendingWrite` + stream vào `DispatchQueue.main.async` (`FramedChannel.swift:25-31`). Sửa này không đổi
số đo (đường ghi thật vẫn phải chờ sự kiện `.hasSpaceAvailable` trên main thread mới thực sự đẩy byte đi), chỉ
loại bỏ hành vi không xác định/khả năng hỏng khung dữ liệu.

**Chưa kết luận bearer** — bảng vẫn thiếu reconnect (3 dòng) và AC6; số liệu latency/throughput ở trên nghiêng
mạnh về nghi vấn "đặc tính connection interval của L2CAP CoC thuần", không phải lỗi logic trong bài đo, nhưng cần
chạy lại với bài đo đã rút gọn (xem dưới) để có đủ reconnect + AC6 trước khi quyết định dừng hay tiếp tục Phase 7.

### Lần 2 (sau khi sửa race) — 2026-10-28 11:07, chạy thật trên S25 + Mac

Nguồn: `reports/assets/ble-g7/mac-run.jsonl`, `run.log`, `android-HLBLESPIKE.log` (lần này script chạy xong, mã
thoát 0 — khác lần 1, kéo được log Android). Đây là số liệu **sau** các thay đổi của #165 (gate 5 MB, bỏ race
condition `FramedChannel.swift`, timeout từng bước/từng vòng).

| Scenario | Metric | Target | S25 ↔ Mac | Notes |
|---|---|---|---|---|
| 1 KB, established link, idle | latency p50 / p95 (one-way est.) | AC1 ≤ 200 ms | **91.72 / 133.97 ms** | n=30; đạt AC1 rõ, không còn sát ngưỡng như Lần 1 |
| 1 KB, during 1 MB transfer | latency p50 / p95 (one-way est.) | AC1 ≤ 200 ms | **4395.8 / 4769.3 ms** | n=8; không đạt AC1 — vẫn hệ quả FIFO một stream (D7.1), như Lần 1 |
| 1 MB transfer | throughput | — (informational) | **12.92 KB/s** (0.012925 MB/s), 77.37 s | gần gấp đôi Lần 1 (7.45 KB/s), vẫn dưới ngưỡng gate 40 KB/s |
| 5 MB transfer | throughput | — (informational) | **bị bỏ qua đúng thiết kế**: `skipped_5mb`, lý do ghi trong log "bulk_1mb throughput 12.92 KB/s below 40 KB/s gate" | gate #165 hoạt động đúng |
| Reconnect, do script tự tắt/bật Bluetooth | bt_lost → bt_seen | AC2 ≤ 3 s | — | **cả 3 vòng `reconnect_round_timeout stage=bt_lost`** (45 s/vòng) — không ai tắt Bluetooth trên điện thoại, không phải lỗi code; đây là lý do có task #166 |
| S25 screen off 10 min / Doze | advertising + accept still running | AC6 (feeds the pairing budget) | — | pending, read from `HLBLESPIKE heartbeat` |

**So với Lần 1:** latency rảnh tay cải thiện rõ (one-way p50 149.76→91.72 ms, p95 179.38→133.97 ms — từ "sát
ngưỡng" sang "đạt rõ"); throughput 1 MB tăng từ 7.45 lên 12.92 KB/s (~+73 %). Không thể quy hết cải thiện này cho
riêng bản sửa race condition ở `FramedChannel.swift` — hai lần đo cách nhau ~23 phút, điều kiện RF (RSSI đo được
-53 dBm ở Lần 2 so với -54 dBm ở Lần 1, gần như nhau nhưng không chứng minh được còn yếu tố nào khác không đổi,
n=1 mỗi cấu hình) có thể cũng góp phần; chỉ ghi nhận số đo tăng lên, chưa kết luận nguyên nhân chính xác. Thời
gian kết nối ban đầu (`connected`) lại **chậm hơn** Lần 1 (3.38 s so với 0.95 s) — biến động giữa các lần, không
đủ dữ liệu để nói đây là xu hướng. Bài kết nối lại vẫn **chưa đo được số thật** ở cả hai lần — Lần 1 vì bài 5 MB
chưa xong nên chưa chạy tới `reconnectLoop`, Lần 2 vì `reconnectLoop` đã chạy nhưng không có ai tắt/bật Bluetooth
trên điện thoại (bài đo gốc là con người chủ động, và không ai được báo cần làm việc đó) — xem #166 ngay dưới.

### Ghi nhận & thay đổi #165 (rút gọn bài đo xuống dưới 540 s)

- `handlive-apple/Tools/BLESpike/Sources/BLESpike/Measurements.swift`: bài 5 MB giờ chỉ chạy khi throughput 1 MB
  ≥ 40 KB/s (`fiveMbThresholdKBps`); dưới ngưỡng thì ghi event `skipped_5mb` kèm lý do và bỏ qua — ở tốc độ đo
  được lần này (7.45 KB/s), 5 MB sẽ bị bỏ qua. Khi 5 MB có chạy, không còn PING xen giữa (dùng kết quả PING-trong-
  lúc-truyền của bài 1 MB làm đại diện, vì bản chất nghẽn giống nhau). Mỗi bước (`ping_baseline`, `bulk_1mb`,
  `bulk_5mb` khi có chạy) có timeout riêng (`withStepTimeout`, 60/240/150 s) — hết giờ thì ghi `step_timeout` và
  thoát tiến trình, giống cách `connectOnce` đã làm từ #156. Vòng kết nối lại (`reconnectLoop`) có timeout riêng
  cho từng vòng, áp cho **cả hai nửa** của vòng: chờ `bt_lost` (tối đa 45 s) và quét kết nối lại cho `bt_seen`
  (tối đa 45 s, qua `connectWithRoundTimeout` — xem mục sửa sau review của Huy ngay dưới). Hết giờ ở nửa nào thì
  ghi `reconnect_round_timeout` kèm `stage` ("bt_lost" hoặc "bt_seen") và qua vòng kế tiếp, không dừng cả bài, vì
  đây là bước con người chủ động (tắt/mở Bluetooth) — không nên mất hết số liệu đã đo nếu một vòng người làm chậm.
- **Sửa sau review của Huy**: `reconnectLoop` ban đầu chỉ bọc timeout cho nửa chờ `bt_lost`; nửa `bt_seen` vẫn gọi
  `connectAndTimestamp()` → `connectOnce()` với timeout mặc định 30 s, mà `connectOnce` hết giờ là `exit(1)` luôn
  (Measurements.swift:150-167 cũ) — nghĩa là nếu vòng 1/3 chậm ở bước quét lại, cả script dừng, mất luôn 2 vòng
  còn lại, ngược với "mỗi vòng có timeout" (độc lập) trong brief. Đã thêm `connectWithRoundTimeout(timeoutSeconds:)`
  (Measurements.swift, cạnh `waitForDisconnect`) — giống `connectOnce` nhưng hết giờ thì trả `nil` thay vì
  `exit(1)`; xoá `connectAndTimestamp()` cũ, `reconnectLoop` giờ dùng hàm mới cho nửa `bt_seen` và `continue` sang
  vòng kế khi `nil`.
- `handlive-apple/Tools/BLESpike/Sources/BLESpike/FramedChannel.swift`: sửa race condition nêu trên.
- `handlive-android/tools/ble-spike/src/main/kotlin/app/handlive/spike/ble/BleSpikeService.kt`: thêm chú thích tại
  `startAdvertising` giải thích vì sao không có `requestConnectionPriority()` (không có GATT connection) — ghi lại
  nghi vấn nguyên nhân ngay cạnh code liên quan, không đổi hành vi.
- **Ước tính thời gian lần chạy kế tiếp** (giữ nguyên tốc độ link ~7.45 KB/s, nên 5 MB bị bỏ qua): build+install
  (~20 s) + connect (~1 s) + ping baseline (~10 s) + bulk 1 MB (~134 s, như lần này) + `skipped_5mb` (~0 s) +
  3 vòng reconnect (tuỳ người làm, mỗi vòng thường chỉ vài giây cho mỗi nửa nếu người làm nhanh) ≈
  **190–260 s** trong điều kiện bình thường — rất dưới 540 s. Trần an toàn theo timeout khai báo (mỗi nửa mỗi
  vòng tối đa 45 s, 3 vòng × 2 nửa = tối đa 270 s cho riêng phần reconnect) cộng ping/bulk1mb ở đúng mức timeout
  tối đa của chúng (60 + 240 s) cho ra **~591 s tổng nếu mọi bước đều "vừa xong trước khi hết giờ" ở mức tối đa
  cùng lúc** — vượt 540 s trên lý thuyết, nhưng đây là tình huống cực đoan không thực tế (ping baseline mất gần
  60 s hoặc bulk 1 MB mất gần 240 s nghĩa là link đã hỏng nặng so với lần đo 10:44, và cả 3 vòng người làm đều
  chậm tối đa ở cả hai nửa). Mục đích chính của các timeout này là **chặn treo vô hạn** như bài 5 MB cũ từng gặp
  (dừng ở 600 s do harness, không phải do script tự dừng) — không phải cam kết tuyệt đối dưới 540 s trong mọi kịch
  bản xấu nhất cộng dồn. Ở điều kiện link và người làm bình thường (như ước tính ~190–260 s trên), tổng vẫn chắc
  chắn dưới 540 s.

### Ghi nhận & thay đổi #166 (tự động hoá bài kết nối lại, bỏ phụ thuộc người bấm tay)

Lần 2 (11:07) cho thấy bài `reconnectLoop` của #165 đúng về mặt thiết kế (mỗi vòng có timeout độc lập, không
`exit(1)` chéo vòng — xác nhận fix sau review của Huy hoạt động đúng trong lần chạy thật: cả 3 vòng đều ghi
`reconnect_round_timeout` riêng, không dừng cả bài ở vòng 1), nhưng vô dụng nếu không có ai tắt/bật Bluetooth
trên S25 — bài đo gốc giả định một con người làm việc đó, và lần chạy 11:07 không ai được báo cần làm.

- `handlive-apple/Tools/BLESpike/Sources/BLESpike/Measurements.swift`: thêm `runReconnectOnly(rounds:,
  roundTimeoutSeconds:)` — bỏ hẳn ping baseline và cả hai bài bulk, chỉ còn `connectOnce()` ban đầu rồi
  `reconnectLoop` (tái dùng nguyên vẹn `connectWithRoundTimeout`/`waitForDisconnect` của #165). Timeout mỗi nửa
  mỗi vòng giảm từ 45 s (dành cho người) xuống **20 s** (dành cho script qua adb, phản ứng trong vài giây, không
  cần dư nhiều như con người tìm điện thoại rồi bấm tay).
- `handlive-apple/Tools/BLESpike/Sources/BLESpike/main.swift`: thêm cờ `--reconnect-only` cho subcommand `run`
  (gọi `runReconnectOnly` thay vì `run`), cập nhật `usage()`.
- `handlive-android/tools/ble-spike/run-spike.sh`: thêm mode `--reconnect-only [rounds] [out-dir]` ở vị trí
  tham số đầu tiên. Khi bật mode này, bước 7/7 chạy `BLESpike run --reconnect-only ...` **ở nền** (`&`) rồi hàm
  `run_reconnect_only()` tự điều khiển từng vòng:
  1. `probe_bt_toggle()`: thử `adb shell cmd bluetooth_manager enable`, soát output có chứa các dấu hiệu bị
     chặn (`unknown command`, `security`, `exception`, `not allowed`, `usage:` — không phân biệt hoa/thường) hay
     không; nếu có thì chuyển sang fallback `adb shell svc bluetooth <enable|disable>`. Kết quả (`cmd` hay `svc`)
     được `echo` ra — đi vào `run.log` qua `exec > >(tee -a run.log)` đã có từ trước, thoả yêu cầu "ghi rõ lệnh
     nào chạy được". **Chưa xác nhận thật trên máy** (cần lần chạy có S25 để biết Android 16 chấp nhận lệnh nào)
     — ghi rõ ở "Ước tính thời gian" dưới.
  2. Mỗi vòng: `bt_toggle disable` → ghi `bt_toggle_off` vào file riêng `run-spike-events.jsonl` → chờ tối đa
     25 s thấy `"ev":"bt_lost".*"round":N` trong `mac-run.jsonl` (không thấy thì chỉ `WARN`, không dừng — mốc
     chặn treo vô hạn thật là timeout 20 s phía Swift) → `bt_toggle enable` → ghi `bt_toggle_on` → `sleep 2` →
     `adb shell am start ... --es cmd start` (khởi động lại peripheral để phát sóng lại) → ghi `am_start` → chờ
     tối đa 25 s thấy `bt_seen`.
  3. `bt_toggle_off`/`bt_toggle_on`/`am_start` ghi vào **file riêng** `run-spike-events.jsonl`, không ghi chung
     vào `mac-run.jsonl`: file đó đã có người viết riêng (tiến trình BLESpike), và `FileHandle(forWritingAtPath:)`
     trong `EventLog.swift` không mở với `O_APPEND`, nên hai tiến trình ghi đồng thời vào cùng path với 2 fd độc
     lập có thể đè/ xen byte lên nhau.
  4. Sửa lỗi phát hiện khi tự kiểm: `EventLog.swift` ghi JSON với `JSONSerialization.sortedKeys`, nên khoá
     không luôn nằm cạnh `"ev"` theo đúng thứ tự chèn (xem thêm mục Khoa/#2987 dưới về `epoch_ms` chen vào
     *trước* `"ev"`). Mẫu khớp ban đầu dùng chuỗi cố định (`grep -F`) sẽ không khớp `bt_seen`; đã đổi
     `wait_for_marker` sang `grep -E` với pattern dạng `"ev":"X".*"round":N[,}]` (đã tự kiểm bằng `grep -E` tay
     với dòng mẫu, xem notes).
  5. Mọi lệnh `adb`/`bt_toggle` đều có `|| true` hoặc được bọc `if ! ...; then WARN; fi` — một lần gọi
     `adb`/toggle thất bại không được kéo cả script dừng qua `set -e`, vì mục tiêu là tự động hoá bền, không phải
     thêm một điểm hỏng giòn mới.

### Sửa theo finding của Khoa (#2987) và bổ sung của Lead — mốc AC2 phải tính từ lúc bật lại Bluetooth

Bản đầu của #166 tính `reconnect_ms = bt_seen - bt_lost` (monotonic clock, phía Swift) và coi đó là số AC2 —
**sai**: khoảng này còn gồm cả thời gian `run-spike.sh` cố ý chờ (tới 25 s) rồi mới gọi `bt_toggle enable`, nên
cộng dư vào con số đáng lẽ đại diện "từ lúc bật lại Bluetooth tới lúc thấy lại nhau" mà AC2 (≤ 3 s) muốn đo.

- **Đổi tên, không đổi cách tính cũ**: `Measurements.swift:258` — field đổi từ `reconnect_ms` thành
  `since_lost_ms`, vẫn tính bằng `DispatchTime` (monotonic) như trước, chỉ đổi tên để không ai lấy nhầm làm số
  AC2 (comment tại chỗ dẫn thẳng tới finding này).
- **Số AC2 thật (`reconnect_from_on_ms`) tính ở hậu xử lý, không phải lúc runtime** (theo gợi ý gọn nhất của
  Lead ở #2987): `EventLog.swift` giờ ghi thêm `epoch_ms` (wall-clock epoch, `Date().timeIntervalSince1970*1000`)
  vào **mọi** event, không riêng `bt_seen` — cùng đồng hồ hệ thống với `run-spike.sh` vì cả hai chạy trên một
  Mac. `run-spike.sh` ghi `bt_toggle_on` kèm `epoch_ms` của chính nó (hàm `epoch_ms()`, xem dưới). Cuối bài,
  hàm mới `summarize_reconnect()` (python3 inline, đọc `run-spike-events.jsonl` + `mac-run.jsonl`, khớp theo
  `round`) in `reconnect_from_on_ms = bt_seen.epoch_ms − bt_toggle_on.epoch_ms` cho từng vòng kèm p50/max — đây
  mới là số so với ngưỡng AC2 ≤ 3 s. Vòng thiếu `bt_toggle_on` hoặc `bt_seen` (timeout) bị bỏ qua, không làm vỡ
  phép tính các vòng còn lại.
- **Độ chính xác thời gian**: `date -u +%Y-%m-%dT%H:%M:%SZ` cũ chỉ tới giây — không đủ phân biệt dưới ngưỡng
  3 s. Đổi sang `zmodload zsh/datetime` + `$EPOCHREALTIME` (giây thực, không fork tiến trình con) cho hàm
  `epoch_ms()` của script; phía Swift dùng `Date().timeIntervalSince1970` (đã có sẵn, chỉ thêm field xuất ra).
- **Mốc `am_start` tách riêng**: ghi ngay sau lệnh `adb shell am start` (khởi động lại peripheral) để báo cáo
  sau này tách được "thời gian Android khởi động lại dịch vụ" khỏi "thời gian BLE kết nối lại" nếu cần — hai cái
  khác bản chất (foreground service restart vs. BLE reconnection) dù hiện chưa dùng tới trong
  `summarize_reconnect()`.
- Vì thêm `epoch_ms` (chen vào *trước* `"ev"` theo bảng chữ cái: `epoch_ms` < `ev`) nên pattern của
  `wait_for_marker` (`"ev":"X".*"round":N[,}]`) vẫn khớp đúng — đã tự kiểm lại bằng `grep -E` với dòng mẫu có cả
  `epoch_ms` lẫn `since_lost_ms`.
- **Chưa có số liệu thật** cho `reconnect_from_on_ms` — lần chạy 11:21 dừng giữa đường vì lỗi cú pháp zsh
  `$round[` (sửa ở #167), nên chưa tới lúc `summarize_reconnect()` chạy thật trên dữ liệu S25. Đã tự kiểm hàm
  này bằng dữ liệu mẫu dựng tay (3 vòng khớp đủ `bt_toggle_on`/`bt_seen`, ra đúng
  `bt_seen.epoch_ms − bt_toggle_on.epoch_ms`; thêm 1 vòng cố ý thiếu `bt_toggle_on` để kiểm không vỡ phép tính
  các vòng khác) — không phải dữ liệu từ máy thật.
- **Chưa chạm `handlive-android/tools/ble-spike/src/main/**` (BleSpikeService.kt...)** — đúng phạm vi file brief
  #166 chỉ cho sửa `run-spike.sh`, không phải cả cây `tools/ble-spike`.
- **Ước tính thời gian** cho `run-spike.sh --reconnect-only 3`: build+install (~20 s) + connect ban đầu (~1–3 s,
  như Lần 1/2) + 3 vòng × (tắt BT ~1 s + chờ `bt_lost` thực tế chỉ vài giây nếu adb toggle thật sự làm điện
  thoại mất kết nối + bật BT ~1 s + `sleep 2` + `am start` ~1 s + chờ `bt_seen` thực tế vài giây) ≈ **~60–100 s**
  trong điều kiện bình thường — rất dưới 300 s. Trần an toàn theo timeout khai báo: mỗi nửa mỗi vòng tối đa 25 s
  (phía script) hoặc 20 s (phía Swift, cái nào tới trước không quan trọng vì script chỉ WARN rồi vẫn tiếp tục) —
  3 vòng × 2 nửa × 25 s = 150 s, cộng build/connect (~25 s) ≈ **~175 s trần an toàn**, dưới 300 s cả hai cách
  tính. **Chưa chạy thật được lần này** — cần S25 cắm máy; `cmd bluetooth_manager disable` có thực sự tắt được
  Bluetooth trên Android 16 bản Samsung này hay bị OneUI chặn, bắt phải rơi về fallback `svc bluetooth`, là điều
  chỉ biết được khi chạy thật (xem "Nghiệm thu" cuối task).

### Lần 3 (11:30, reconnect-only) — peripheral không phát sóng lại, #168

`run-spike.sh --reconnect-only 3` lúc 11:30 (xem `run.log` dòng 1186-1221): `cmd bluetooth_manager
disable`/`enable` chạy được, Mac thấy `bt_lost` trong khoảng **0,7 s** (round 0) — nhanh hơn nhiều so với
ngưỡng AC2 ≤ 3 s, bằng chứng tốt rằng toggle qua adb là một kích thích thật, không phải giả lập. Nhưng sau
`enable` + `am start ... cmd start`, Mac không thấy lại peripheral (không `discovered`) trong 20 s — round 0
timeout ở bt_seen. Round 1 và 2 sau đó lại chờ `bt_lost` dù đã mất kết nối từ round 0, nên cả hai cũng hết giờ
theo (cascading). `android-HLBLESPIKE.log` không có dòng nào trong khoảng 11:3x.

**Nguyên nhân (suy luận từ code, chưa xác nhận bằng log thật — xem điểm dưới):** `BleSpikeService.serverLoop()`
(bản trước #168) chỉ bọc `catch (e: IOException)` quanh `listenUsingInsecureL2capChannel()`/`accept()`, và chỉ
kiểm tra `adapter.isEnabled` **một lần** trước khi vào `while` — nếu Bluetooth tắt rồi bật lại giữa lúc đang
`accept()`, không có gì chủ động đóng `BluetoothServerSocket`/`BluetoothLeAdvertiser` cũ hay tạo lại cái mới;
vòng lặp chỉ còn trông chờ `accept()` tự ném `IOException` (có thể không xảy ra, hoặc ném một loại exception
khác mà `catch` không bắt — ví dụ `SecurityException` khi gọi API Bluetooth đúng lúc radio vừa tắt — khiến
`serverThread` chết lặng lẽ, khớp với việc log trống hoàn toàn).

**Cách sửa** (`handlive-android/tools/ble-spike/src/main/kotlin/app/handlive/spike/ble/BleSpikeService.kt`):

- `bluetoothStateReceiver` (:59-81) đăng ký `BluetoothAdapter.ACTION_STATE_CHANGED` trong `start()` (:106-111,
  qua `ContextCompat.registerReceiver(..., RECEIVER_NOT_EXPORTED)`), gỡ trong `stop()` (:148). `STATE_OFF`: log
  `bt_state_off`, chủ động `stopAdvertising()` + đóng `serverSocket` ngay (:67-74) — buộc `accept()` đang block
  phải ném exception thay vì trông chờ OS tự làm. `STATE_ON`: log `bt_state_on`, giải phóng một permit của
  `bluetoothRestart` (Semaphore 0 permit, :57, :75-78) để đánh thức `serverLoop` ngay, không chờ vòng lặp tự
  nhiên tiếp theo.
- `serverLoop()` (:173-225) viết lại: kiểm `adapter.isEnabled` **mỗi vòng** `while` (không chỉ một lần trước
  loop như bản cũ) — nếu tắt, `drainPermits()` rồi `acquire()` chặn tới khi có permit mới (từ `STATE_ON` hoặc từ
  `stop()` để thoát). Khi bật, `advertiser` được lấy lại mới mỗi vòng (:196, không cache qua chu kỳ tắt/bật) rồi
  `listenUsingInsecureL2capChannel()`/`startAdvertising()` lại như cũ, với PSM mới (đã có sẵn từ #156, không
  đổi). `catch` đổi từ `IOException` sang `Exception` (:207) kèm log `server_loop_error` ghi cả `type` lẫn
  `message` — nếu lần sau log vẫn trống thì ít nhất giờ biết chắc không phải do loại exception bị lọt qua catch.
- `cmd start` khi service đã `running` (tức `am start` lặp lại mà `run-spike.sh` luôn gọi sau mỗi lần `enable`)
  không còn chỉ log `start_ignored_already_running` rồi bỏ qua: `ensureServerAlive()` (:138-144) kiểm
  `serverSocket == null` (nghĩa là `serverLoop` đang park chờ Bluetooth, không phải đang accept() dở) và giải
  phóng permit nếu đúng — một lớp dự phòng nếu `bluetoothStateReceiver` lỡ broadcast vì lý do gì đó.

**Điều tra log trống** (`handlive-android/tools/ble-spike/run-spike.sh`'s `cleanup()`, :428-440): thêm lệnh pull
`adb logcat -b crash` (`android-crash.log`) để biết app có crash hẳn không, và `adb logcat --pid=$(adb shell
pidof ...)` (`android-pid.log`, lấy pid **trước** khi gọi `cmd stop` vì sau đó process đã chết) để bắt mọi dòng
log của process này bất kể tag, không chỉ tag `HLBLESPIKE`. Cả ba lệnh logcat đều thêm `-T` với mốc giờ lấy lúc
script bắt đầu (`RUN_START_LOGCAT_T`, :120-124 theo format `logcat -T` chứ không phải ISO8601 của `date -u`), để
không bị buffer ring cũ (đầy/xoay vòng từ lần chạy trước) làm loãng hay che mất đúng khoảng thời gian cần xem.
**Chưa xác nhận log trống là do crash hay do buffer** — chỉ biết được khi chạy thật với 3 file log mới này.

**`run-spike.sh`/`Measurements.swift` không để một vòng hỏng kéo các vòng sau** (việc 3, chọn nhánh Swift +
mirror ở script, xem "Sửa theo finding của Khoa" phía trên cho ngữ cảnh `since_lost_ms`): `reconnectLoop`
(Measurements.swift:230-273) giờ theo dõi `isConnected` qua các vòng — nếu vòng trước timeout ở bt_seen (không
kết nối), vòng sau bỏ hẳn `waitForDisconnect` (ghi `reconnect_skip_bt_lost` thay cho `bt_lost`) và quét lại
luôn; khi quét lại thành công, `isConnected` trở lại `true` cho vòng kế. `run_reconnect_only()`
(run-spike.sh:208-256) mirror đúng state machine này bằng biến `connected`: vòng mà `connected=0` bỏ qua
`bt_toggle disable`/chờ `bt_lost`/`bt_toggle enable`, chỉ gọi lại `am start` rồi chờ `bt_seen`; vòng nào thấy lại
`bt_seen` thì `connected` quay lại `1` cho vòng sau. Đã tự test logic này bằng mock (xem "Tự kiểm" ở ghi chép
task #168) — mô phỏng đúng kịch bản 11:30 (round 0 miss bt_seen) cho kết quả round 1, 2 bỏ đúng bước tắt/bật
Bluetooth; mock thêm case "hồi phục" (round giữa thấy lại bt_seen) xác nhận round kế quay lại tắt/bật bình
thường — không bị kẹt ở trạng thái "bỏ qua" vĩnh viễn.

**Yêu cầu cho sản phẩm:** A-SVC phải dựng lại L2CAP và advertiser khi Bluetooth bật lại (không chỉ khi app khởi
động lần đầu) — bài học trực tiếp từ bug này: một service nền sống qua Doze/screen-off (AC6) nhưng không sống
sót qua một chu kỳ tắt/bật Bluetooth thật của người dùng là vô dụng cho tính năng Continuity trên thực địa, nơi
người dùng tắt/bật Bluetooth thường xuyên hơn là khởi động lại app.

**Chưa chạy thật lại được lần này** — cần S25 cắm máy để xác nhận: (1) peripheral có thực sự phát sóng lại sau
`bluetoothStateReceiver`, (2) `android-crash.log`/`android-pid.log` có lộ ra nguyên nhân log trống hay không.

### Lần 4 (reconnect-only, sau #168) — 2026-10-28 11:42, chạy thật trên S25 + Mac

Nguồn: `reports/assets/ble-g7/run-spike-events.jsonl`, `mac-run.jsonl`, `run.log`, `android-HLBLESPIKE.log` (lần
chạy sau fix #168 — peripheral giờ phát sóng lại đúng, cả 3 vòng ra số, không còn `reconnect_round_timeout` nào).

| Round | since_lost_ms (bt_lost → bt_seen) | reconnect_from_on_ms (bt_toggle_on → bt_seen, số AC2 thật) |
|---|---|---|
| 0 | 2224.4 | **10583.0** |
| 1 | 3785.4 | 2793.0 |
| 2 | 3726.9 | 2658.0 |

p50 = **2793.0 ms**, max = **10583.0 ms**, n=3 (`run.log:1541-1544`, output thật của `summarize_reconnect()`).
`since_lost_ms`/`reconnect_from_on_ms` khớp đúng `mac-run.jsonl:13,20,27` (trường `since_lost_ms`) và phép tính
`bt_seen.epoch_ms − bt_toggle_on.epoch_ms` cho từng round giữa `mac-run.jsonl:13,20,27` và
`run-spike-events.jsonl:2,5,8` (đã tính tay lại, khớp số script in ra tới 0.1 ms).

**n=3 là nhỏ** — một lần chạy duy nhất, 3 vòng; không đủ để ước lượng p95 (ngưỡng AC2 ≤ 3 s dùng p95, không phải
max của 3 mẫu) hay để biết round 0 là ngoại lệ hiếm hay là hiện tượng lặp lại mỗi lần app/script mới khởi động —
cần nhiều lần chạy hơn (xem "Chưa đo"/"What's needed next").

**Vì sao vòng đầu (round 0) chậm gấp ~4x hai vòng sau — có bằng chứng trực tiếp từ thứ tự log, không phải suy
đoán:**

- `run.log:1483` (`-- reconnect round 1/3: tắt Bluetooth trên S25 --`) và `run.log:1486` (`-- ... bật lại
  Bluetooth --`) — tức toàn bộ chu kỳ tắt/bật Bluetooth của round 0 — in ra **trước** `run.log:1489`, dòng
  `"ev":"host"` đầu tiên của tiến trình BLESpike **mới** cho lần chạy này (epoch `1793162552523`). Các dòng
  `run.log:1483-1488` là `echo`/output `adb` của zsh (không bị buffer qua `tee`), nên thứ tự này đúng là thứ tự
  thời gian thật, không phải ảnh của buffering.
- Diễn giải: `run_reconnect_only()`'s `wait_for_marker` cho `channel_opened` (đầu hàm) và cho `bt_lost
  round:0` (đầu vòng lặp round 0) đều đọc file `mac-run.jsonl` — file này là **đường dẫn cố định**, và
  `EventLog.init()` (phía Swift) chỉ `FileManager.createFile` (xoá/ghi lại rỗng) **sau khi** tiến trình Swift
  mới đã fork+exec+load xong framework CoreBluetooth. Trong khoảng trễ đó (vài trăm ms, bằng chứng:
  `run.log:1489` xảy ra sau `run.log:1486`), file `mac-run.jsonl` **vẫn còn nội dung của lần chạy 11:30 ngay
  trước đó** (Lần 3) — vốn cũng có các dòng `"channel_opened"` và `"bt_lost","round":0`. `wait_for_marker` khớp
  ngay vào các dòng cũ này (chỉ cần tồn tại trong file, không phân biệt được "cũ" hay "mới"), khiến round 0 bắt
  đầu tắt/bật Bluetooth thật **trước khi** lần kết nối ban đầu của chính lần chạy này (`connectOnce()`, dẫn tới
  `mac-run.jsonl:6` `channel_opened` epoch `1793162554806`) thậm chí xảy ra. Mốc "bắt đầu" của round 0
  (`bt_toggle_on` tại `run-spike-events.jsonl:2`, epoch `1793162552264`) vì vậy bị ghi **sớm hơn thực tế ~2.5 s**
  so với lúc kết nối thật sự bắt đầu hình thành.
- Sau đó: kết nối thật đầu tiên (`mac-run.jsonl:6`, epoch `554806`) khớp với `android-HLBLESPIKE.log:13`
  (`client_connected wall_clock_ms=1793162554762`, cách 44 ms — cùng một lần connect), nhưng phiên socket này bị
  Android đóng chỉ 53 ms sau (`android-HLBLESPIKE.log:14-15`, `session_ended`/`client_disconnected` tại
  `.815`). CoreBluetooth phía Mac không báo mất kết nối ngay — `mac-run.jsonl:7` (`disconnected`) chỉ xảy ra ở
  epoch `1793162560623`, **5.8 s sau** khi socket Android đã đóng, và không khớp với bất kỳ sự kiện nào trong
  `android-HLBLESPIKE.log` ở đúng mốc đó (dòng 17-18, khoảng 11:42:34.821–11:42:42.801, hoàn toàn im lặng phía
  Android). Khoảng 5.8 s "im lặng" này khớp với tầm BLE connection supervision timeout tiêu chuẩn (thường 4-8 s
  tuỳ connection parameters âm thầm) khi một bên đóng tầng socket L2CAP nhưng không chủ động ngắt hẳn liên kết ở
  tầng GAP/link layer — **đây là suy luận hợp lý, chưa xác nhận tuyệt đối** (CoreBluetooth không lộ lý do
  timeout qua API công khai).
- Tổng ba đoạn cộng lại khớp khá sát 10583 ms quan sát được: ~2.5 s (kết nối đầu, vô tình tính vào mốc round 0 do
  bug thứ nhất) + ~5.8 s (chờ CoreBluetooth phát hiện mất kết nối orphaned, bug thứ hai) + ~2.3 s (quét + kết nối
  lại thật, tương đương round 1/2) ≈ 10.6 s.
- **Loại trừ nguyên nhân phía Android**: `android-HLBLESPIKE.log:9-11` cho thấy `bt_state_on` → `server_listening`
  → `advertise_start_success` của round 0 chỉ mất **14 ms** (`.313` → `.315` → `.327`) — và tương tự ở round 1
  (`:26-28`, ~13 ms) và round 2 (`:38-40`, ~14 ms). Fix #168 hoạt động đúng; peripheral không phải nguyên nhân
  vòng đầu chậm. Nguyên nhân nằm ở phía script/Mac (file `mac-run.jsonl` không được dọn giữa các lần chạy), nằm
  ngoài phạm vi file cho phép sửa của #169 — ghi nhận ở đây để ai làm task kế tiếp cân nhắc xoá hoặc đổi tên
  `mac-run.jsonl`/`OUT_DIR` trước mỗi lần chạy, hoặc để `wait_for_marker` đợi thấy dòng `"host"` mới trước khi
  chấp nhận bất kỳ marker nào khác trong file.
- Round 1 và 2 không bị ảnh hưởng bởi bug này (file đã được Swift tiến trình hiện tại ghi liên tục nhiều giây
  trước đó) — `reconnect_from_on_ms` của chúng (2793, 2658 ms) phản ánh đúng một chu kỳ tắt/bật Bluetooth +
  reconnect thật, và đều sát dưới ngưỡng AC2 ≤ 3 s (2793/2658 < 3000 ms) — **cả hai đạt AC2** tính riêng lẻ; chỉ
  round 0 không đạt.

### Lần 5a (doze-start 15, phía Mac hỏng) — 2026-10-28 12:23, chạy thật trên S25 + Mac

Nguồn: snapshot của `snapshot_prev_logs()` trước khi #171 fix setsid (`reports/assets/ble-g7/prev-1793169060137/`).

`run-spike.sh --doze-start 15` kết nối thành công, mở channel, bắt đầu đo (`doze_start` lúc 12:23:33.489, `mac-run.jsonl:7`), gửi đúng 1 ping thành công (seq 1, rtt 118.58 ms, `mac-run.jsonl:8`) rồi **tiến trình BLESpike nền phía Mac dừng đột ngột** — không còn dòng nào khác trong `mac-run.jsonl` sau đó. Nguyên nhân (đã sửa, xem #171/#3099): app chạy hộ lệnh `--doze-start` rồi tự kill process group ngay khi lệnh đó thoát, mà `nohup` chỉ chặn `SIGHUP`, không chặn kill-group — tiến trình BLESpike con (`nohup ... &`) bị kill theo. Bằng chứng gián tiếp phía Android: `session_ended`/`client_disconnected` xảy ra ngay 12:23:34.214–.215 (`android-HLBLESPIKE.log:2-3`), chỉ ~0,6 s sau ping đầu — khớp với socket Mac bị đóng đột ngột khi tiến trình bị kill, không phải lỗi BLE.

Phía Android sau đó **vẫn chạy tiếp dù mất kết nối**: peripheral tự phát sóng lại (`server_listening`/`advertise_start_success`, `android-HLBLESPIKE.log:4-5`, 12:23:34.219/.228) và heartbeat 30 s chạy đều 8 tick, từ tick 1 lúc 12:23:54.704 tới tick 8 lúc 12:27:24.708 (`android-HLBLESPIKE.log:6-13`) — rồi **im hẳn**, không còn dòng `HLBLESPIKE` nào tới hết log; `android-crash.log` trống (không ghi nhận crash). `doze_enter` (force-idle thật, `run-spike-events.jsonl:1`, epoch `1793165014210` = 12:23:34.210) và `doze_exit` (khi `--doze-collect` gọi, không chờ đủ 15 phút vì phía Mac hỏng — xem #3100/#3101 — `run-spike-events.jsonl:2`, epoch `1793165266618` = 12:27:46.618) cách nhau ~4 phút 12 giây; tick 8 (heartbeat cuối) xảy ra 22 giây **trước** `doze_exit`, nên heartbeat dừng không phải do script chủ động — nó đã im lặng từ trước khi lệnh thu kết quả chạy.

### Lần 5b (doze-start 15, bản đã sửa #171) — 2026-10-28 13:31–13:58, chạy thật trên S25 + Mac

Nguồn: `reports/assets/ble-g7/` (hiện hành, sau fix setsid).

Kết nối ổn định suốt bài: `doze_start` lúc 13:31:11.146 (`mac-run.jsonl:7`), 29/29 ping thành công mỗi 30 s đúng `ping_interval_s`, `doze_done pings_sent=29` lúc 13:46:43.006 (`mac-run.jsonl:37`), **0 lần `bt_lost`** — kết nối L2CAP giữ xuyên suốt 15 phút Doze thật (`deviceidle IDLE` cả lúc vào và lúc ra, xem output `--doze-collect`). RTT đo được: p50 = 232.4 ms, p95 = 1328.7 ms (n=29) → one-way est. (RTT/2): **p50 ≈ 116.2 ms (đạt AC1), p95 ≈ 664.4 ms — gấp ~3,3 lần ngưỡng 200 ms, không đạt**.

Heartbeat Android chạy đều 30 s, **không đứt đoạn**, tick 1 lúc 13:31:35.519 tới tick 55 lúc 13:58:35.553 (`android-HLBLESPIKE.log:3-61`) — tổng 1650 s (27,5 phút), dài hơn 15 phút đo ping vì log chạy tiếp tới khi `--doze-collect` gọi lúc 13:58:39 (`doze_exit`, `run-spike-events.jsonl:2`, epoch `1793170719320`). Lưu ý: Mac ngắt kết nối ngay sau `doze_done` (`disconnected` lúc 13:46:43.010, `mac-run.jsonl:38`), peripheral phát sóng lại ngay (`session_ended`/`advertise_start_success`, `android-HLBLESPIKE.log:34,37`, cùng giây 13:46:43) nhưng **không có kết nối Mac mới** tới hết log — từ tick 32 (13:47:05.539) tới tick 55 (13:58:35.553), **12 phút liên tục không BLE**, heartbeat vẫn chạy đều, không sai nhịp.

**So với Lần 5a: "cần ping thì CPU thức?"** — dữ liệu không ủng hộ giả thuyết này. Ở Lần 5a, heartbeat chạy 8 tick (4 phút) dù **không có ping/kết nối** sau ping đầu (Mac chết từ giây đầu) — tự chạy "mồ côi" rồi dừng, không phải dừng ngay vì thiếu ping. Ở Lần 5b, heartbeat chạy thêm 12 phút sau khi mất kết nối (tick 32–55) không đứt đoạn — phản ví dụ trực tiếp: **0 ping suốt 12 phút, heartbeat vẫn đều**. Điểm khác duy nhất: Lần 5a heartbeat dừng sau ~4 phút kể từ `doze_enter` (lý do không rõ, không crash log), Lần 5b không dừng suốt 27,5 phút. Dữ liệu chưa đủ để kết luận nguyên nhân Lần 5a dừng — nhưng chắc: **ping từ Mac không phải điều kiện cần** để heartbeat Android qua Doze, vì Lần 5b chạy tốt 12 phút hoàn toàn không ping.

## Bảng tổng hợp theo AC (`phase-07-ket-noi-moi-noi.md`)

| AC | Mục tiêu | Kết quả | Nguồn |
|---|---|---|---|
| AC1, khi rảnh | Bluetooth ≤ 200 ms một chiều (p95) | **Đạt** — p95 ~134 ms (Lần 2: 91.72/133.97 ms p50/p95) | Lần 2 |
| AC1, khi đang truyền bulk | ≤ 200 ms một chiều kể cả khi đang truyền bulk | **Chưa đạt** — 4395.8/4769.3 ms (Lần 2) và 7725.3/7768.4 ms (Lần 1) p50/p95 một chiều; một luồng FIFO duy nhất, ping phải đợi hết dữ liệu bulk đã enqueue trước nó | Lần 1/2; cần channel id riêng + bộ lập lịch ưu tiên frame điều khiển ở D7.1 (A7.4) |
| AC1, khi Doze (S25 force-idle 15 phút) | ≤ 200 ms một chiều (p95), kể cả khi màn hình tắt/Doze | **Chưa đạt (p95)** — RTT p50/p95 = 232.4/1328.7 ms (n=29) → p50 ≈ 116.2 ms (đạt), p95 ≈ 664.4 ms (3,3 lần ngưỡng) | Lần 5b |
| Giữ kết nối BLE qua Doze | — (informational: 0 `bt_lost` trong 15 phút) | **Giữ được** — 0 `bt_lost`, 29/29 ping xuyên suốt 15 phút Doze thật (`deviceidle IDLE` cả vào/ra) | Lần 5b |
| AC2 | Kết nối lại ≤ 3 s từ lúc phát hiện lại peer | **Một phần** — p50 2793 ms (đạt), max 10583 ms round 0 (không đạt); n=3 quá nhỏ để kết p95 | Lần 4: round 0 bị lệch do bug stale-file, xem trên — cần n lớn hơn để kết luận |
| Throughput (1 MB) | — (informational) | 12.9 KB/s — đủ văn bản/SMS/thông tin cuộc gọi; không đủ ảnh (Wi-Fi Direct theo D7.1) | Lần 2 |
| Phát hiện mất kết nối (toggle off → bt_lost) | — (informational) | ~0,7 s (Lần 3); Lần 4 round 1/2 nhanh hơn (67/42 ms) — không phải nút nghẽn AC2; phần lớn thời gian là quét + kết nối (discover→connect, ~1–2,5 s/round Lần 4) | Lần 3, 4 |
| AC6 (ghép đôi QR qua BLE ≤ 15 s) | ≤ 15 s từ quét tới ghép đôi xong | **Chưa đo** luồng ghép đôi/QR (spike không triển khai) — nhưng heartbeat `HLBLESPIKE` qua Doze: không nhất quán — Lần 5b (kết nối giữ) 55/55 tick suốt 27,5 phút không đứt; Lần 5a (Mac chết sớm) dừng sau tick 8 (~4 phút), không rõ lý do, không crash log. Chưa khẳng định "advertising + accept luôn sống Doze" | Lần 5a/5b |
| AC3, AC4, AC7, AC8, AC9 | (xem `phase-07-ket-noi-moi-noi.md`) | **Chưa đo** | xem "Chưa đo" dưới |

## Kết luận bearer

**BLE L2CAP CoC (insecure, `listenUsingInsecureL2capChannel`/`CBCentralManager` + `BluetoothSocket`), cộng lớp
bảo mật link ở tầng ứng dụng (D7.1)** — không phải tùy chọn vì kênh này không bond.

- **RFCOMM: không khả thi** (ghi nhận "Brief items" dưới) — Android app không đọc được địa chỉ Bluetooth của máy,
  BLE là ngẫu nhiên xoay vòng, HandLive không bond (SP5 đã bỏ) — không cách nào Mac "tới" điện thoại qua RFCOMM
  mà không bond trước.
- **Kết luận G7**: BLE L2CAP CoC (insecure) đủ làm kênh điều khiển của Continuity — không phải ảnh/payload lớn
  (Wi-Fi Direct theo D7.1; throughput BLE chỉ 12.9 KB/s, Lần 2 — đủ văn bản/SMS/thông tin cuộc gọi). Kèm 4
  điều kiện bắt buộc trước khi coi bearer này xong cho sản phẩm:
  1. **Ưu tiên control-trước-bulk ở D7.1/A7.4** — AC1 chỉ đạt khi rảnh (p95 ~134 ms, Lần 2); khi bulk thì không
     (p95 4769–7768 ms, Lần 1/2) vì một luồng FIFO, ping phải đợi bulk enqueue trước — **bắt buộc** channel id
     riêng + bộ lập lịch ưu tiên control trước khi bearer xong cho làn điều khiển.
  2. **A-SVC phải dựng lại L2CAP server/advertiser khi Bluetooth bật lại** (không chỉ khởi động lần đầu) — phát
     hiện #168: service sống qua Doze/screen-off nhưng chết sau chu kỳ tắt/bật Bluetooth thật là vô dụng
     Continuity; người dùng tắt/bật Bluetooth thường hơn khởi động lại app.
  3. **Chấp nhận hoặc giảm độ trễ Doze** — L2CAP giữ được kết nối suốt 15 phút Doze (0 `bt_lost`, 29/29 ping,
     Lần 5b) nhưng chậm: p95 ~0,66 s (p50 ~116 ms đạt AC1, p95 vượt 3,3 lần ngưỡng 200 ms). Không có API công khai
     chỉnh connection interval cho L2CAP thô — `requestConnectionPriority()` chỉ dùng được với GATT. Độ trễ phụ
     thuộc interval do controller chọn, ứng dụng không điều khiển được. Sản phẩm phải chấp nhận ngưỡng này cho làn
     điều khiển khi màn hình tắt, hoặc đánh đổi bằng một GATT server tối giản để xin priority.
  4. **Bound độ dài frame từ peer** — `FrameBuffer.append` (Swift)/`readFrame` (Kotlin) đọc length 4-byte rồi cấp
     phát buffer mà không kiểm cận trên (finding Trang #165/#2960); chấp nhận được cho spike dev-only insecure cục
     bộ, nhưng **bắt buộc** bound khi mang sang code sản phẩm.
- **Vẫn còn mở, không chặn kết luận**:
  - AC2: "một phần" (n=3: p50 2793 ms đạt, max 10583 ms không đạt; quá ít mẫu để tính p95) — cần chạy thêm nhiều
    lần để biết round 0 chậm là lặp lại hay chỉ nhiễu một lần.
  - AC3–AC9: ngoài tầm spike này. AC6 mới có bằng chứng gián tiếp từ Lần 5a/5b (service sống qua Doze), chưa đo
    luồng ghép đôi QR thật. Kết luận bearer dựa trên AC1/AC2/Doze + throughput, chưa phải bộ AC đầy đủ mà spec
    yêu cầu — nhưng điều kiện dừng ("không bearer nào đạt AC1 khi rảnh → dừng") KHÔNG xảy ra (AC1 khi rảnh đạt),
    nên Phase 7 tiếp tục; các AC còn lại chờ A7.1/M7.1 đo khi có code sản phẩm.

## Yêu cầu phát hiện cho sản phẩm (rút từ spike, áp dụng A-SVC/A7.1)

1. **A-SVC phải dựng lại L2CAP server/advertiser khi nhận `BluetoothAdapter.ACTION_STATE_CHANGED`/`STATE_ON`**
   (không chỉ khi khởi động lần đầu) — phát hiện #168: service sống qua Doze/screen-off nhưng chết sau một lần
   tắt/bật Bluetooth thật thì vô dụng ngoài thực tế; người dùng tắt/bật Bluetooth thường hơn khởi động lại app.
2. **Gói quảng bá ≤ 31 byte** — dùng service UUID 16-bit (Base UUID pattern), không tên (`setIncludeDeviceName
   (false)`). Phát hiện #156: UUID 128-bit đầy đủ + service data vượt 31 byte → `ADVERTISE_FAILED_DATA_TOO_LARGE`
   → điện thoại không phát sóng.
3. **Bound độ dài frame từ peer** — `FrameBuffer.append` (Swift) và `readFrame` (Kotlin) đọc length 4-byte rồi cấp
   phát mà không kiểm cận trên (finding Trang #165/#2960) — chấp nhận được cho spike dev-only, nhưng **bắt buộc**
   bound trong sản phẩm vì attacker kiểm soát length có thể buộc cấp phát bộ nhớ tuỳ ý.
4. **Không có API công khai chỉnh connection interval cho L2CAP thô** — `requestConnectionPriority()` chỉ dùng
   được với GATT, không với `listenUsingInsecureL2capChannel`/`BluetoothSocket` (ghi chú
   `BleSpikeService.kt:244-249`). Latency/throughput phụ thuộc interval do controller chọn, ứng dụng không điều
   khiển được — A7.1/M7.1 cần cân nhắc có đáng dựng GATT server tối giản chỉ để xin priority, hay chấp nhận giới
   hạn này.

## Chưa đo

Ngoài phạm vi spike này, chờ lần chạy riêng hoặc code sản phẩm (A7.1/M7.1/T7.1):

- **Doze (Lần 5a/5b)** — đã chạy 15 phút force-idle: BLE giữ được kết nối qua Doze (0 `bt_lost`, Lần 5b), nhưng
  trễ một chiều chậm (p95 ~0,66 s so với ~134 ms khi rảnh). Heartbeat không nhất quán giữa Lần 5a và 5b (5b: 55/55
  tick; 5a: dừng ở tick 8) — chưa khẳng định được service luôn sống qua Doze. Luồng ghép đôi QR của AC6 **chưa
  đo** — spike không triển khai.
- **Mac sleep/wake**: chưa thử ngủ/thức Mac giữa reconnect, chỉ toggle Bluetooth S25 qua `adb`.
- **Out of range**: chưa đo (script không điều khiển vị trí vật lý, chỉ Bluetooth).
- **Wi-Fi Direct**: để SP4, xem "Brief items" dưới.
- **BLE sniff (AC9)**: chưa bắt gói sniffer để kiểm tra lộ định danh (`pair_id`, `device_id`, tên) — spike chỉ
  PING/BULK, chưa envelope D7.1; AC9 chỉ đo khi code sản phẩm có.
- **Scan-response layout (task #187)**: code xong (xem "Scan-response layout, task #187" trên). Sếp quyết không
  chạy đo riêng (#3309) — scan response chưa đo riêng; kiểm khi A7.1b/M7.1c chạy trên S25 + Mac.
- **AC3, AC4, AC7, AC8**: ngoài phạm vi spike — cần code sản phẩm (A7.1–A7.7/M7.1–M7.7).

## Brief items not needing device (recorded now)

- **Item 6, RFCOMM**: không triển khai (brief: "chỉ ghi nhận không khả thi nếu không tới máy trước bond"). Plan đã
  kết luận độc lập: RFCOMM chỉ dùng được nếu Mac tới được điện thoại mà không cần bond — nhưng Android app không đọc
  được địa chỉ Bluetooth (địa chỉ BLE ngẫu nhiên), và HandLive không bond (SP5 đã bỏ). **RFCOMM không khả thi.**
- **Item 7, Wi-Fi Direct**: không thử (Mac chỉ có 1 radio Wi-Fi, không có đường an toàn). Để SP4.
- **Item 5, mã hoá link của L2CAP chưa bond**: không probe — không có API nào truy vấn được trạng thái mã hoá của
  L2CAP. Bluetooth spec và plan (`phase-07-ket-noi-moi-noi.md` dòng 39) đều kỳ vọng link chưa bond thì không mã
  hoá — vì thế lớp bảo mật link của D7.1 là bắt buộc. Spike chỉ cho thấy chưa có gì trái kỳ vọng đó; không bác bỏ
  được, cũng không bắt gói để xác nhận.

## What's needed next

Bearer đã chốt (xem "Kết luận bearer"), gate không dừng Phase 7 — mục này giờ chỉ còn cho các số liệu lẻ ở "Chưa
đo" (p95 reconnect với n lớn hơn, Mac sleep/wake, out of range, luồng ghép đôi QR của AC6), không phải để chốt lại
bearer.

1. S25 on USB, debug on, Bluetooth on Mac — cần một phiên nữa của owner nếu team muốn số liệu đó; không phải
   điều kiện để dùng kết luận bearer hiện có.
2. Cách build/run `adb`/`gradle`/`swift`: vẫn đúng như trước — owner chạy `run-spike.sh` trực tiếp trong terminal,
   không qua agent (xem "Status" đầu file). Đã tự kiểm lại session này (2026-10-29): biên dịch tay sạch cả hai
   probe — Kotlin qua `K2JVMCompiler` với `android.jar`/`androidx.core`/coroutines (0 lỗi, trừ class `R` chưa sinh
   vì cần AAPT2 thật), Swift qua `swiftc -emit-module` (0 lỗi, chỉ warning Sendable-closure có từ trước) — code
   chưa rỉ sét từ lần chạy Lần 5b.
3. ~~Khi có số: điền bảng, chốt bearer (hay dừng)~~ — đã xong (xem "Bảng tổng hợp theo AC", "Kết luận bearer").
   3 trong 4 điều kiện bắt buộc cho sản phẩm đã vào code thật ở `core:transport`/`feature:connection` (topic "Viết code
   Phase 7", đóng theo quyết định #3285): `BluetoothLinkScheduler` (ưu tiên control-trước-bulk),
   `BluetoothLinkLifecycle`/`BluetoothAdvertising` (dựng lại khi `STATE_ON`), `BtRecordCodec.requireWithinBound`/
   `requireValidTransportRlen` (bound độ dài frame). Điều kiện còn lại (độ trễ Doze) là đánh đổi sản phẩm, không
   phải code. Luồng ghép đôi QR thật của AC6 vẫn chưa đo — việc của A7.2/M7.2
   khi luồng đó có code, không phải của spike này.
