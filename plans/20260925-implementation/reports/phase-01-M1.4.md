# Phase 1 — M1.4 [macOS]: clipboard sync (CLIP-01…03, CLIP-05)

Card M1.4 of `phase-01-bang-nho-tam-mvp.md`. Repository handlive-apple, branch `feat/phase-01-clipboard`.
Includes the controller's bench request for this card (`HLBENCH/1` clipboard events).

## What was done

- **Messages** (`HLProtocol/ClipboardMessages.swift`): `clipboard/push` (text inline or `transfer`), ack data
  (`applied`, `ignored` + reason, `rejected` + `transfer_id`), `cancel`, `conflict`; unknown `source`/`status`/
  `reason` values decode (forward compatibility); `null` from kotlinx counts as absent.
- **Rules** (`HLAppCore/Clipboard`): QC3 card numbers (the Android regex and Luhn, ≤ 256 characters) and the
  `org.nspasteboard.*` types; QC6 `clip_id` ledger (256 for 10 minutes; a rejected clip may come again); QC8
  decisions; the first-item reader of CLIP-02 API 1 (text or image by the source app's order, file URLs skip the
  item, HandLive's own write recognized by `app.handlive.clip-id`); image normalization (PNG/JPEG kept, TIFF/HEIC/…
  → PNG with ImageIO, first frame, off the main actor).
- **Engine** (`ClipboardEngine`, platform-neutral):
  - **Polling (CLIP-02)**: `changeCount` every 500 ms; content is read only when it changed and was not HandLive's
    write; no automatic reading when macOS asks or refuses paste access (one guide per launch); pauses for sleep and
    checks once on wake. "Send Clipboard to Phone" reads at once.
  - **Sending**: QC4 (same SHA-256 as the clip received < 5 s ago), QC3 hold with "Send Anyway" (120 s), QC5 limits
    (the smaller of this Mac's and the phone's), inline when the push plaintext ≤ 180 KiB, else 64 KiB chunks; images
    only when "Sync Images" is on and the phone takes the MIME type; ack 10 s counted from the last chunk;
    `CLIP_CHECKSUM_MISMATCH` → one resend with a new `transfer_id`; a newer clip cancels a running transfer
    (`superseded`); "Cancel" sends `user`; `FEATURE_DISABLED` suspends until the next `capability/update`.
  - **QC7**: the latest local clip stays until acknowledged and is replayed on the next session within 120 s (not a
    clip the phone cancelled as `user`, not one that lost a conflict).
  - **Receiving (CLIP-01 API 5)**: validation → `BAD_REQUEST` / `FEATURE_DISABLED` / `CLIP_TOO_LARGE` /
    `CLIP_UNSUPPORTED_MIME`; duplicates `ignored`; QC8 (a) keeps a copy younger than 500 ms — also one the poll has
    not seen yet — answers `ignored`/`conflict` and sends `clipboard/conflict`; QC8 (b) compares `origin_ts`, then
    `origin_device_id`; the write carries the clip-id mark (concealed when sensitive), records the QC4 trace, schedules
    auto-clear and answers `applied`; a failed write answers `INTERNAL`.
  - **Chunks (CLIP-03)**: one incoming transfer (a newer push replaces it); chunks go to
    `tmp/HandLive/clip/<transfer_id>.part` with an incremental SHA-256; out of order → `BAD_REQUEST`; size or SHA-256
    wrong → `CLIP_CHECKSUM_MISMATCH` with `transfer_id`; 30 s without a chunk → `cancel timeout`; no room → `INTERNAL`
    and "Not enough storage…"; chunked text must be UTF-8; the file is deleted in every case; progress for images
    over 1 MiB in each direction.
  - **Auto-clear (CLIP-05)**: deadline = write time + `clip.auto_clear_s` on the wall clock; cleared only if
    `changeCount` still equals the write, then taken as seen; a new clip or a changed setting reschedules; checked on
    wake; after a restart a HandLive clip still on the clipboard gets a full interval.
  - **Bench** (debug builds): `copy_detected`, `clip_read` (clip, kind, bytes, source `mac`), `clip_sent`,
    `clip_received`, `clip_applied`, `ack_sent`, `ack_received` (status), with `peer` = the phone's first 8 hex digits.
- **Mac** (`HLMacUI`): `MacPasteboard` writes one item with every type in one pass, kept on this Mac
  (`prepareForNewContents(with: .currentHostOnly)`), a received JPEG also promises PNG converted on demand;
  `UserNotificationAlerts` posts "Sensitive Content Blocked" with "Send Anyway" and "Clipboard Not Updated on <name>"
  with "Send Again" (one per kind, removed after 120 s); `AppModel` runs the engine while a phone is paired and Sync
  Clipboard is on, follows the session, sleep and settings; results go to the status line of the menu (2 min) and a
  checkmark on the menu bar icon for about a second after a manual send; image progress with Cancel in the menu;
  "Send Clipboard to Phone" works offline too (CLIP-02 E6).

## Commits

| Repository | Hash | Subject |
|------------|------|---------|
| handlive-shared | 1c8d851 | feat(shared): show the empty-clipboard and just-received results of a manual send on the Mac |
| handlive-apple | b136aa3 | feat(apple): regenerate the strings for the Mac manual-send results |
| handlive-apple | 01643dd | feat(apple): add the clipboard push, ack, cancel and conflict messages |
| handlive-apple | df46ea2 | test(apple): decode the clipboard examples of CLIP-01 and CLIP-03 |
| handlive-apple | 46adae2 | refactor(apple): move the Encodable-to-JSONValue helper into HLProtocol |
| handlive-apple | 4c722a7 | feat(apple): let feature modules and their tests build incoming envelopes |
| handlive-apple | 98f77b3 | feat(apple): add the clipboard rules: card numbers, de-duplication, conflicts and what counts as a copy |
| handlive-apple | 0985436 | feat(apple): sync the clipboard with the phone |
| handlive-apple | bb9ef02 | test(apple): test the clipboard rules against the Android cases |
| handlive-apple | 2a2dfd3 | test(apple): test sending, receiving, chunked transfers and auto-clear of the clipboard |
| handlive-apple | c7a2274 | feat(apple): expose the clipboard polling state and progress values to the UI |
| handlive-apple | 8ff0505 | feat(apple): read and write NSPasteboard for the clipboard |
| handlive-apple | a439780 | feat(apple): notify blocked sensitive content and conflicts with Send Anyway and Send Again |
| handlive-apple | 1a18627 | feat(apple): run the clipboard in the Mac app |
| handlive-apple | e85dbc9 | test(apple): test the clipboard wiring of the Mac app model |
| handlive-apple | 7387f3e | fix(apple): keep Send Clipboard to Phone usable while the phone is offline |
| handlive-apple | 0039d94 | test(apple): let the clipboard engine's timers outlive the test harness |
| handlive-apple | f59d51f | test(apple): cover the remaining clipboard exceptions on the Mac |
| handlive-apple | 001d60c | docs(apple): describe the clipboard engine and the Mac pasteboard |

The Android and relay agents need not re-run anything for 1c8d851: it only adds `macos` to the platforms of two
existing strings (`check_strings.py`: 208 strings, 0 errors).

## Files

- HLProtocol: `ClipboardMessages.swift`, `JSONValue.swift` (`HLJSON.convert(from:)` now public); test
  `ClipboardMessagesTests`.
- HLTransport: `SessionTypes.swift` (public `IncomingEnvelope` initializer).
- HLAppCore `Sources/HLAppCore/Clipboard/`: `ClipboardConstants`, `SensitiveContent`, `ClipLedger`, `ClipContent`
  (+ `ImageNormalizer`), `ClipboardAccess`, `LocalClipReader` (+ `ConflictPolicy`), `ClipboardPeer` (+
  `SessionClipboardPeer`), `IncomingTransfer`, `ClipboardEvents`, `ClipboardEngine` (+`Sending`, `Receiving`,
  `Transfers`); tests `ClipboardTestSupport`, `ClipboardRulesTests`, `ClipboardSendTests`, `ClipboardReceiveTests`,
  `ClipboardTransferTests`, `ClipboardAutoClearTests`, `ClipboardExceptionTests`.
- HLMacUI: `MacPasteboard`, `ClipboardAlerts`, `AppModel+Clipboard` and the wiring in `AppModel`, `AppModel+Link`,
  `AppModel+Settings`, `AppModel+Pairing`, `AppCoordinator`, `MenuBarViews`; tests `AppModelClipboardTests`,
  `TestSupport` (stub pasteboard and notifications, so tests never touch the real clipboard).
- HLLocalization: regenerated catalogs and `L10n` (`Clipboard.emptyOrNotText`, `Clipboard.skippedJustReceived`).

## Tests (real output)

```text
$ cd apple/Packages/HLAppCore && HL_SWIFT_TESTING_PACKAGE=1 SDKROOT=/Library/Developer/CommandLineTools/SDKs/MacOSX26.sdk swift test
✔ Test run with 40 tests in 10 suites passed after 2.176 seconds.    (3 runs in a row, all green; 32 clipboard tests)
$ cd apple/Packages/HLProtocol && … swift test
✔ Test run with 33 tests in 8 suites passed after 0.016 seconds.
$ cd apple/Packages/HLMacUI && … swift test
✔ Test run with 17 tests in 4 suites passed after 1.802 seconds.
$ cd apple && TOOLCHAIN_DIR=/Library/Developer/CommandLineTools swiftlint lint --strict
Done linting! Found 0 violations, 0 serious in 189 files.
```

Acceptance "no content is read while `changeCount` is unchanged": `ClipboardSendTests.pollsWithoutReading` counts the
fake pasteboard's reads. Exceptions and their tests (Mac side):

| Spec | Case | Test |
|------|------|------|
| CLIP-01 | E7 conflict (QC8 a, b) | `freshLocalChangeWins`, `crossingClips`, `sendAgain` |
| CLIP-01 | E8 write failure → `INTERNAL`; E9 loop; E10 `FEATURE_DISABLED` (receiver and sender) | `rejections`, `loopPrevention`, `ackErrors` |
| CLIP-02 | E1 own write / QC4; E2 paste access; E3 file URL; E4 sensitive; E5 > 1 MiB; E6 offline; E7 conflict; E8 `INTERNAL`; E9 no ack → replay | `loopPrevention`, `pasteAccess`, `reader`, `sensitive`, `sizes`, `manualSend`, `sendAgain`, `ackErrors`, `noAckIsReplayed` |
| CLIP-03 | E1 images off / MIME not taken; E2 over the phone's limit; E3 unreadable; E4 checksum (both sides, one resend); E5 superseded; E6 Cancel (both sides); E7 idle 30 s; E8 lost session; E9 no room | `sendImage`, `imageLimits`, `receiveFailures`, `resendOnce`, `superseded`, `cancels`, `userCancelsSending`, `lostSessionAndNoSpace` |
| CLIP-05 | E1 later copy kept; E2 new clip; E4 restart; E5 setting 0; E6 wake | `keepsUserContent`, `newClipAndWake`, `rearmsAfterRestart`, `clears` |

CLIP-01 E1–E6 and CLIP-03 E10, CLIP-05 E3 are Android's; CLIP-05 E7 (`clearContents` failing) cannot happen on macOS.

## CI

- https://github.com/HandLive/handlive-apple/actions/runs/36183079256 — success on 0039d94 (everything but the last
  test commit): HLAppCore 35, HLMacUI 17, HLProtocol 33 tests, SwiftLint 0 violations, app build.
- 36182328910 failed on e85dbc9: an auto-clear rescheduled one second ahead fired after its test and read an
  `unowned` test harness (a test-only crash); fixed in 0039d94.
- https://github.com/HandLive/handlive-apple/actions/runs/36185259682 — success on 7f8aa97 (includes the exception
  tests of f59d51f): HLProtocol 33, HLCrypto 39, HLTransport 65, HLDesignSystem 23, HLLocalization 9, HLAppCore 40,
  HLMacUI 17 tests; SwiftLint 0 violations in 189 files; app build succeeded.

## Spec deviations and proposals

1. **Manual-send results on the Mac**: `clipboard.empty_or_not_text` and `clipboard.skipped_just_received` are now also
   Mac strings (shared 1c8d851), following the Feedback README. Proposal: list them under CLIP-02 field 4.
2. **Errors in place only**: "Couldn't send the image" (CLIP-03 E4, second failure) is a status line in the menu, not a
   notification, per QC5/C19 ("errors never go out as system notifications"). CLIP-03 E4 says "notification".
3. **Image size is checked after normalization**: a large TIFF whose PNG fits is sent (CLIP-03 E2 says "source or after
   normalization"; screenshots carry a huge TIFF next to a small PNG).
4. **QC8 (a) for a copy the poll has not seen**: at every incoming push the Mac compares `changeCount` first, so a copy
   made in the last 500 ms counts as a local change (and is sent afterwards).
5. **One chunk in flight**: each chunk waits for the transport's send completion (within "at most 4 chunks waiting").
6. **Any newer push replaces an incoming transfer**, text included (CLIP-03 API 3 logic 2 read literally).
7. **`ignored`/`cancelled` does not decide replay**; the `clipboard/cancel` before it does (`user` → not replayed,
   `timeout` → replayed). `FEATURE_DISABLED` marks the clip handled (not replayed) and suspends until the next update.
8. **Chunked text that fails its SHA-256 twice** shows "Couldn't update the clipboard on the phone" (no text-specific
   string exists).
9. **Status line lifetime**: two minutes (the Feedback README says "the next time the menu opens").

## Pending manual checks

- Latency on real devices with `shared/tools/bench` (T1, T2, I1, I2, T4): text p95 < 50 ms, 5 MB image p95 < 2 s.
- Copy/paste of text and images both ways; JPEG from the phone pasted into an app that reads only PNG (the promise).
- Magic Replace of the checkmark on macOS 15/26 and the static swap on macOS 13 (card note).
- "Send Anyway" / "Send Again" buttons on the notifications; replacement of an older notification; removal after 120 s.
- macOS 15.4+ with "Paste from Other Apps" set to Ask: automatic sending stops, the menu item still sends after the
  system prompt.
- Auto-clear after one minute; a clipboard manager (e.g. Maccy) ignores concealed clips; Universal Clipboard does not
  pass HandLive's writes to an iPhone (`.currentHostOnly`).

Status: DONE
Summary: The Mac syncs text and images with the phone per CLIP-01…03 and CLIP-05 — polling without reading content,
inline and chunked transfers, conflicts, replay, sensitive-content blocking, auto-clear, notifications with actions,
menu feedback and bench events — with every Mac-side exception tested.
Concerns/Blockers: latency targets and the UI effects need the real-device bench pass.
