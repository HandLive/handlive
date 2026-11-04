[English](phase-07-sp3.md) | Tiếng Việt

# SP3 — làn bulk trên liên kết Bluetooth (A7.4 ∥ M7.4, 0.4.7)

Mục tiêu: đưa toàn bộ một lần chuyển CLIP-03 (push kèm `transfer`, chunk, cancel, ack, conflict) lên kênh `0x02` của liên kết Bluetooth, theo mục "Bulk lane on the Bluetooth link (channel `0x02`)" trong `docs/detailed-design/00-common-specs.md`. Mọi envelope khác vẫn ở `0x01`. Clipboard engine chọn làn, không phải tầng transport. SP3 đã bỏ phần stream.

Trạng thái: **code xong ở Android, Mac và shared; chưa push**. Đo trên máy thật (AC1 trên Galaxy S25 và Mac thật) còn nợ, tách thành việc riêng; sếp tạm chưa có máy.

## Phạm vi

Trong phạm vi: A7.4 (Android), M7.4 (Mac), chuỗi ghi chú tiến độ ở shared.

Ngoài phạm vi (sang SP4): `/v1/stream/bulk` trên Wi-Fi Direct (A7.3/M7.3, A7.5/M7.5), chọn làn "LAN > Wi-Fi Direct > Bluetooth", khởi động lại khi đổi làn.

## Commit

| Repo | Commit (cũ đến mới) |
|---|---|
| `handlive` (spec 0.4.7) | `53f69a0` |
| `handlive-shared` | `3eb92ad` |
| `handlive-android` | `43b5b95`, `55ccf6f`, `091cdac`, `3f11939`, `be88bbe`, `0a29dd0`, `2cf835d`, `d2c37e2`, `cf64ef5` |
| `handlive-apple` | `c1a85c7`, `0cbea4b`, `abf5c3f`, `43aca3c`, `7473e93`, `cd217b5`, `fb94555`, `be4b18c`, `d02268b`, `fa9810d`, `e4026ae`, `f29efec` |

Ở `handlive-android`, `be88bbe`, `0a29dd0` và `cf64ef5` là các bước test, tính năng và chú thích của cùng ghi chú Bluetooth; `2cf835d` và `d2c37e2` là bản sửa để control chen được giữa lúc gửi bulk.

## Đã thay đổi

- **Spec 0.4.7**: tám luật bulk, `BT_BULK_QUEUED` = 2. Bên nhận không giới hạn kiểu envelope trên `0x02`.
- **Shared**: hai chuỗi `clipboard.bulk_bluetooth_sending` và `clipboard.bulk_bluetooth_receiving` (CLIP-03 trường 10), sinh vào cả hai app. Phải lên remote trước Android để CI sinh được chuỗi.
- **Android**: làn bulk trong `BluetoothPeerSocket`, trạng thái làn tách ra khỏi file này. `BluetoothLinkWritePump` cho envelope control ngắn chen giữa các mảnh bulk (0.4.5 Priority). Qua Bluetooth, tiến độ hiện từ `BULK_DIRECT_MIN` (128 KiB), kèm ghi chú Bluetooth bên dưới.
- **Mac**: `EnvelopeLane` đi qua `ControlSession` và `ClipboardPeer`; clipboard engine chọn `.bulk` cho envelope của lần chuyển. `BluetoothChannel` gửi `.bulkText` trên `0x02` với backpressure `BT_BULK_QUEUED` và chuyển bulk lên dạng `.text`. Qua Bluetooth, tiến độ hiện từ 128 KiB (LAN và relay giữ 1 MiB), ghi chú nằm trên menu bar. `WebSocketChannel` và `RelayPeerChannel` gửi `.bulkText` như một text frame.

## Luật và nơi thực hiện (Mac)

| Luật | Nơi thực hiện |
|---|---|
| Lần chuyển ở `0x02`, mọi thứ khác ở `0x01` | `ClipboardEngine+Sending.swift`, `+Receiving.swift`, `+Transfers.swift` truyền `lane: .bulk` cho envelope của lần chuyển và `.control` cho envelope inline |
| Bên gửi chọn làn, transport không đoán | `EnvelopeLane` trên `ControlSession` và `ClipboardPeer`, mặc định `.control` |
| Envelope bulk được xếp hàng | `BluetoothLinkScheduler.bulkEnvelopesQueued` |
| Backpressure `BT_BULK_QUEUED` | `BluetoothChannel.Writer.send` chờ trên `bulkBackpressureWaiters` khi hàng đợi đầy |
| Đóng liên kết khi `long` = 1 trên `0x02`, `dlen` > `BT_BULK_FRAGMENT_MAX`, message > `BT_MESSAGE_MAX` | `BtTransportFrame.decode`, `BluetoothBulkReassembler.accept` |
| Bulk ráp xong đi lên dạng `.text`; `.binary` bị từ chối | `BluetoothChannel.readLoop`, phần gửi của `BluetoothChannel` |
| Bulk ráp dở bị bỏ khi đóng liên kết | `BluetoothBulkReassembler` thuộc từng kênh và mất cùng kênh |

## Kiểm thử

| Repo | Kết quả |
|---|---|
| Android | `./gradlew check`: 1128 test xanh (Dev2 báo). `BulkLaneContractTest` phủ contract; `be88bbe` đỏ có chủ đích cho đến `0a29dd0`. |
| Mac | `HLTransportTests` 190, `HLAppCoreTests` 147, `HLMacUITests` 71, đều xanh; build Mac và iOS xanh. |

File test ở Mac: `BluetoothBulkLaneTests` (làn theo kiểu envelope, `long` = 1, `dlen`, vượt trần, nhiều mảnh, ráp dở), `BluetoothBulkLaneTransferTests` (control vượt bulk, hàng đợi đầy, ảnh 10 MiB, `.binary` bị từ chối, text frame trên LAN), `ClipboardBulkLaneTests` (làn của từng envelope, ngưỡng 128 KiB), `AppModelClipboardTests.bluetoothNote`.

`HLMacUI` chạy bằng `xcodebuild` đang đỏ vì crash CoreBluetooth có sẵn trên `main`, không phải do SP3.

## Review

A7.4: Khoa, Trang và Huy approve; finding high của Huy (control bị bỏ đói khi gửi bulk) đã sửa ở `d2c37e2`. M7.4: Khoa, Trang và Huy approve. Reviewer phía Mac không chạy lại test; số liệu trên là của người viết code.

## Việc còn nợ

- AC1 trên Galaxy S25 và Mac thật, cho cả A7.4 và M7.4. Runbook: `phase-07-sp1-measure.md`, session 2.
- Android: ngưỡng tiến độ chờ Khoa xác nhận trên thẻ. Hai ghi chú low của Trang còn mở.
- Mac, low và không chặn: bên gửi chưa tự chặn `BT_MESSAGE_MAX` (`BluetoothChannel.swift:105`, bên kia sẽ đóng liên kết); bulk bị huỷ giữa lúc chờ backpressure không resume continuation (được dọn khi kênh đóng).
- Test CoreBluetooth đỏ sẵn trên `main` cần một việc riêng.

## Thứ tự push

shared `3eb92ad` → android → apple → hub, theo SHA cố định bằng `tools/sp3-push.sh` (chạy `--dry-run` trước), sang nhánh remote `feat/p07-sp3-bulk-bluetooth`. Nhánh local `feat/p07-sp3-sp4-bulk-wifi-direct` còn nhận thêm commit SP4.

## Tiếp theo

SP4: T7.0b → S7.1c ∥ S7.1d → A7.3 ∥ M7.3 → A7.5 ∥ M7.5 → A7.7b ∥ M7.7b.
