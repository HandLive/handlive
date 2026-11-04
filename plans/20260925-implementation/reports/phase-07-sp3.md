English | [Tiếng Việt](phase-07-sp3.vi.md)

# SP3 — bulk lane on the Bluetooth link (A7.4 ∥ M7.4, 0.4.7)

Goal: carry the whole CLIP-03 transfer (push with `transfer`, chunks, cancel, ack, conflict) on channel `0x02` of the Bluetooth link, per "Bulk lane on the Bluetooth link (channel `0x02`)" in `docs/detailed-design/00-common-specs.md`. Every other envelope stays on `0x01`. The clipboard engine picks the lane, not the transport. Streaming is dropped from SP3.

Status: **code done on Android, Mac and shared; not yet pushed**. Real-device measurement (AC1 on a Galaxy S25 and a real Mac) is owed and tracked as a separate task; the owner has no device for now.

## Scope

In scope: A7.4 (Android), M7.4 (Mac), the progress note strings in shared.

Out of scope (moved to SP4): `/v1/stream/bulk` on Wi-Fi Direct (A7.3/M7.3, A7.5/M7.5), lane choice "LAN > Wi-Fi Direct > Bluetooth", restart on lane change.

## Commits

| Repo | Commits (oldest first) |
|---|---|
| `handlive` (spec 0.4.7) | `53f69a0` |
| `handlive-shared` | `3eb92ad` |
| `handlive-android` | `43b5b95`, `55ccf6f`, `091cdac`, `3f11939`, `be88bbe`, `0a29dd0`, `2cf835d`, `d2c37e2`, `cf64ef5` |
| `handlive-apple` | `c1a85c7`, `0cbea4b`, `abf5c3f`, `43aca3c`, `7473e93`, `cd217b5`, `fb94555`, `be4b18c`, `d02268b`, `fa9810d`, `e4026ae`, `f29efec` |

`handlive-android` commits `be88bbe`, `0a29dd0` and `cf64ef5` are test, feature and comment steps of the same note; `2cf835d` and `d2c37e2` are the control-cuts-in-mid-bulk fix.

## What changed

- **Spec 0.4.7**: eight bulk rules, `BT_BULK_QUEUED` = 2. The receiver does not restrict envelope types on `0x02`.
- **Shared**: two strings, `clipboard.bulk_bluetooth_sending` and `clipboard.bulk_bluetooth_receiving` (CLIP-03 field 10), generated into both apps. Must reach the remote before Android so CI can generate them.
- **Android**: bulk lane in `BluetoothPeerSocket`, with the lane state moved out of it. `BluetoothLinkWritePump` lets short control envelopes cut in between bulk fragments (0.4.5 Priority). Progress shows from `BULK_DIRECT_MIN` (128 KiB) over Bluetooth, with the Bluetooth note under it.
- **Mac**: `EnvelopeLane` threads through `ControlSession` and `ClipboardPeer`; the clipboard engine picks `.bulk` for transfer envelopes. `BluetoothChannel` sends `.bulkText` on `0x02` with `BT_BULK_QUEUED` backpressure and hands bulk up as `.text`. Progress from 128 KiB over Bluetooth (LAN and relay keep 1 MiB), with the note in the menu bar. `WebSocketChannel` and `RelayPeerChannel` send `.bulkText` as a text frame.

## Rules and where they live (Mac)

| Rule | Where |
|---|---|
| Transfer on `0x02`, everything else on `0x01` | `ClipboardEngine+Sending.swift`, `+Receiving.swift`, `+Transfers.swift` pass `lane: .bulk` for transfer envelopes and `.control` for inline ones |
| Sender picks the lane, transport never guesses | `EnvelopeLane` on `ControlSession` and `ClipboardPeer`, default `.control` |
| Bulk envelopes queued | `BluetoothLinkScheduler.bulkEnvelopesQueued` |
| `BT_BULK_QUEUED` backpressure | `BluetoothChannel.Writer.send` waits on `bulkBackpressureWaiters` while the queue is full |
| Link closes on `long` = 1 on `0x02`, `dlen` > `BT_BULK_FRAGMENT_MAX`, message > `BT_MESSAGE_MAX` | `BtTransportFrame.decode`, `BluetoothBulkReassembler.accept` |
| Reassembled bulk delivered as `.text`; `.binary` rejected | `BluetoothChannel.readLoop`, `BluetoothChannel` send |
| Half-reassembled bulk dropped at link close | `BluetoothBulkReassembler` is per channel and dies with it |

## Tests

| Repo | Result |
|---|---|
| Android | `./gradlew check`: 1128 tests green (reported by Dev2). `BulkLaneContractTest` covers the contract; `be88bbe` was red by design until `0a29dd0`. |
| Mac | `HLTransportTests` 190, `HLAppCoreTests` 147, `HLMacUITests` 71, all green; Mac and iOS builds green. |

Mac test files: `BluetoothBulkLaneTests` (lane per type, `long` = 1, `dlen`, oversize, multi-fragment, half-reassembled), `BluetoothBulkLaneTransferTests` (control overtakes bulk, full queue, 10 MiB image, `.binary` rejected, LAN text frame), `ClipboardBulkLaneTests` (lane of each envelope, 128 KiB threshold), `AppModelClipboardTests.bluetoothNote`.

`HLMacUI` under `xcodebuild` is red from a CoreBluetooth crash already on `main`, not from SP3.

## Reviews

A7.4: Khoa, Trang and Huy approve; Huy's high finding (control starved during bulk) fixed in `d2c37e2`. M7.4: Khoa, Trang and Huy approve. Reviewers on Mac did not rerun the tests; the figures above are from the authors.

## Open items

- AC1 on a Galaxy S25 and a real Mac, for both A7.4 and M7.4. Runbook: `phase-07-sp1-measure.md`, session 2.
- Android: the progress threshold waits for Khoa's confirmation on the card. Two low notes from Trang remain.
- Mac, low and non-blocking: the sender does not cap at `BT_MESSAGE_MAX` itself (`BluetoothChannel.swift:105`, the peer closes the link); a bulk send cancelled while waiting on backpressure does not resume its continuation (cleaned up when the channel closes).
- CoreBluetooth tests red on `main` need their own task.

## Push order

shared `3eb92ad` → android → apple → hub, by fixed SHA with `tools/sp3-push.sh` (`--dry-run` first), to the remote branch `feat/p07-sp3-bulk-bluetooth`. The local branch `feat/p07-sp3-sp4-bulk-wifi-direct` also takes SP4 commits.

## What's next

SP4: T7.0b → S7.1c ∥ S7.1d → A7.3 ∥ M7.3 → A7.5 ∥ M7.5 → A7.7b ∥ M7.7b.
