# Phase 1 — A1.3 [android]: Clipboard (CLIP-01, CLIP-02 API 3–5, CLIP-03, CLIP-05)

Card A1.3 of `phase-01-bang-nho-tam-mvp.md`. Repository handlive-android, branch `feat/phase-01-clipboard`, pushed; CI `ci-android` green (eec715b, and 58ffe4e at the end of A1.4). New module `feature/clipboard` (A-CLIP); the screens that show the disclosure and the Clipboard settings group come with A1.4 and use the APIs below.

## What was done

- **Protocol** (`core/protocol`): `clipboard/push|cancel|conflict` models and the push `ack` data (`clip_id`, `status`, `reason`, `transfer_id`), checked against the JSON examples of 04-clipboard. `PeerSession.request(afterSend = …)`: a chunked push sends its chunks between the push and the `ack` wait, so the 10 s start after the last chunk (CLIP-03 API 3 rule 3).
- **Engine** (`engine/`, plain Kotlin): 0.10 constants (`CLIP_INLINE_MAX`, `CLIP_LOOP_WINDOW`, `CLIP_DETECT_DEBOUNCE`, `CLIP_TRANSFER_IDLE_TIMEOUT`, `CLIP_STALE_AFTER`…); QC3 card rule (13–19 digits, Luhn, ≤ 256 characters); QC6 `clip_id` ledger (256 / 10 min, rejected clips may come again); QC8 policy (500 ms window on the receiver's clock, then `origin_ts`, then `origin_device_id`); QC4 loop guard (written clip 5 s on every path, sent clip 5 s on the automatic path, Accessibility signals ignored 1 s after a write); receiver checks in the spec order (`BAD_REQUEST` → `FEATURE_DISABLED` → `CLIP_TOO_LARGE` → `CLIP_UNSUPPORTED_MIME`, lone surrogates = invalid UTF-8); 64 KiB chunk plan, incremental SHA-256 receive into a file, chunk source from memory or file; the copy-signal matcher of CLIP-01 API 1 (Copy/Cut in the system language, "copy"/"sao chép", "copied"/"đã sao chép"/"clipboard"/"bảng nhớ tạm"/"bộ nhớ đệm" toasts and announcements, SystemUI clipboard overlay).
- **Module** (`module/`, JVM-testable behind interfaces, one serial dispatcher):
  - `LocalClipIntake` (CLIP-01 steps 5–9, CLIP-03 steps 2–6): E3/E9/QC3/QC5 in order; sensitive content held ≤ 120 s with "Send Anyway"; images normalized on the IO dispatcher; new UUIDv7 `clip_id` → latest clip (QC7) → every eligible client; manual results in place ("Sent to …" on the first `applied`, "Not connected — …" for E6). "Send Again" resends the content under a new `clip_id`.
  - `ClipSender` (QC1, QC6, QC7): targets = sessions with effective clipboard, within the peer's `mimes` and the smaller limits, never the origin device or the pair it came from, never a pair that acknowledged it; E8 no retry; `CLIP_CHECKSUM_MISMATCH` resent once then "Couldn't send the image"; `FEATURE_DISABLED` pauses the pair until its next capability; replay on every new session when fresh.
  - `OutgoingTransfers` (CLIP-03 sender): push with `transfer`, chunks in order, one transfer per peer, `cancel superseded` for any newer clip (E5), `cancel user` from the progress (E6, not replayed), receiver cancels honoured, progress for images > 1 MiB.
  - `ClipReceiver` + `IncomingTransfers` (CLIP-02 API 3–5, CLIP-03 receiver): validation, de-duplication, QC8 (a) `ignored/conflict` + `clipboard/conflict {device_id, device_name}` / (b) silent, write → QC4 trace → CLIP-05 → `ack applied` → forward unchanged (new `transfer_id` per hop, chunks read back from the verified file); `<transfer_id>.part` written chunk by chunk, renamed to `<clip_id>.png|.jpg|.txt`; out of order → `BAD_REQUEST`; wrong hash → `CLIP_CHECKSUM_MISMATCH` with `details.transfer_id`; 30 s idle → `cancel timeout`; no room → `INTERNAL` + "Not enough storage to receive the image" (E9); session gone → file deleted (E8). Conflicts about another client's clip are passed back to that client unless the clip was a QC7 replay.
  - `ClipboardTrace` (CLIP-05, C17): write trace (`sha256`, `wallFrom`, `wallTo`, `elapsedAt`, `changed`, file); timer on the monotonic clock, recomputed on setting changes, cancelled by `0`, replaced by a newer clip; at the deadline "unchanged" is concluded **only** from the description read with focus (label "HandLive" and system timestamp within the write interval) — directly when A-UI has focus, through `ClipboardReadActivity` in verification mode when the Accessibility service runs, otherwise postponed until A-UI gets focus. Signs of change (in-app listener, copy signal after the 1 s window, a local clip sent, a read with another SHA-256) drop the timer. A cleared clip is forgotten (no replay, no "Send Again") and its file deleted.
- **Android components** (`system/`, `component/`): `SystemClipboard` (label "HandLive", `android.content.extra.IS_SENSITIVE` on every version, `clearPrimaryClip`, description without reading content), `ClipReader` (item 0: text/HTML via `coerceToText`, text URIs, image URI copied into `cache/clip/` at most 10 MiB + 1 byte, revoked grant = E10), `AndroidImageNormalizer` (PNG/JPEG unchanged, others through `ImageDecoder` → PNG, first frame), `ClipboardAccessibilityService` (config of API 1 incl. `isAccessibilityTool=false`, `canRetrieveWindowContent=false`; consent + settings gate; own package dropped; 300 ms debounce; `disableSelf()` when auto-send is turned off; A3 capability via `ConnectionRuntime.setAccessibilityRunning`), `ClipboardReadActivity` (transparent, own task, not in Recents, no animation; read / verification / Share modes; 1 s focus limit), activity-alias Share target "Send to Devices (HandLive)", `ClipboardTileService` (subtitle "To <client>" / "To N devices" / "Not connected", `PendingIntent` variant on 34+, `unlockAndRun` when locked), `ClipNotifier` (toasts; silent `clipboard` notifications with "Send Anyway"/"Send Again" expiring after 120 s; progress with "Cancel", updated per 5 %), `ClipActionReceiver`, `ClipFileProvider` (`${applicationId}.clipfiles`, only `cache/clip/`), `AccessibilityConsent` (Agree → `clip.a11y_consent_at`, Send Manually → `clip.auto_send = false`, Settings › Accessibility intent, service state).
- **Wiring**: `ClipboardFeature.install` registers `type = clipboard`, installs the notification's "Send Clipboard" (shown only while a client has active clipboard — CLIP-01 field 4), cleans `cache/clip/` at start (`.part` files, files older than 1 h); `MainActivity` registers the in-app listener in `onResume` (reads directly, ignores HandLive's own write) and runs postponed CLIP-05 checks. `features.clipboard.auto_send` now also needs the recorded consent (E1).
- **Bench hooks** (`HLBENCH/1`, debug builds): `copy_detected` (once per debounce window, and from the in-app listener), `clip_read` (clip ready to send, `kind`, `bytes`, `source`), `clip_sent` (push handed to the WebSocket, per peer, also when forwarding), `clip_received`, `clip_applied` (after the clipboard write; after the last verified chunk for chunked clips), `ack_sent`, `ack_received` — ids, kinds, sizes and states only.

## Commits (handlive-android)

| Hash | Subject |
|------|---------|
| 86d6cfe | feat(android): add clipboard push, ack, cancel and conflict models |
| f96ee17 | test(android): round-trip the clipboard examples of the spec |
| 02706b9 | feat(android): let a request send chunks before its ack timeout starts |
| a180efb | refactor(android): share the phone's display name between features |
| b212fad | feat(android): show Send Clipboard only while a client has active clipboard |
| cce532b | feat(android): add the clipboard engine for limits, loops, conflicts and chunks |
| 32f1c38 | feat(android): send, receive, forward and auto-clear clips in the clipboard module |
| 2d4bf40 | feat(android): detect copies and read, share and write the Android clipboard |
| fca8ad3 | feat(android): install the clipboard feature and its focus hooks in the app |
| e207c8e | fix(android): declare the clipfiles paths so URIs work before the provider starts |
| 41d998f | refactor(android): let tests set the free space of the clip cache |
| ec6a374 | test(android): check that the ack wait starts after the chunks |
| 8268438 | test(android): cover the clipboard engine rules |
| 33c306b | test(android): cover sending, receiving, chunked transfers and safe auto-clear |
| 27710eb | test(android): check clipboard notifications, reads and writes on Robolectric |
| 9c416d9 | fix(android): advertise auto-send only with the recorded Accessibility consent |
| 5752b92 | test(android): require the consent for auto_send in the capability |
| bc78c73 | feat(android): record the Accessibility disclosure choice for auto-send |
| 25eef48 | test(android): check the disclosure choices and the Accessibility page |
| 8fd03e0 | docs: describe core:strings and the connection, pairing and clipboard modules |
| eec715b | test(android): cover images off, undecodable images, sender cancel and failed clears |

No change under `shared/` for this card.

## Files

Created: `feature/clipboard/**` — `build.gradle.kts`, `AndroidManifest.xml`, `res/xml/{clipboard_accessibility,clip_paths}.xml`, `res/values/themes.xml`; `ClipboardFeature.kt`, `ClipNotices.kt`; `engine/{ClipLimits,Clip,ClipIdLedger,ConflictPolicy,LoopGuard,PushValidator,SensitiveContent,Transfers,ChunkSource,CopySignalMatcher}.kt`; `module/{ClipEnvironment,ClipFiles,ClipState,ClipWire,LocalRead,LocalClipIntake,ClipSender,OutgoingTransfers,ClipReceiver,IncomingTransfers,ClipboardTrace,ClipboardModule}.kt`; `system/{SystemClipboard,ClipReader,AndroidImageNormalizer}.kt`; `component/{ClipboardAccessibilityService,ClipboardReadActivity,ClipboardTileService,ClipActionReceiver,ClipNotifier,ClipFileProvider,AccessibilityConsent}.kt`; tests (15 classes, `testing/ClipboardTestKit.kt`); `core/protocol/.../clipboard/ClipboardMessages.kt` + test; `feature/connection/.../LocalDeviceName.kt`.
Changed: `feature/connection` (`PeerSession.request`, `HandLiveService` button rule, `LocalCapabilityBuilder` consent), `feature/pairing/PairingFeature.kt`, `app` (dependency, `HandLiveApplication`, `MainActivity` focus hooks), `settings.gradle.kts`, `README.md`, `README.vi.md`.

## Tests (real output)

```text
$ ./gradlew check        # JDK 21, platforms;android-37.0
BUILD SUCCESSFUL in 29s
585 actionable tasks: 59 executed, 526 up-to-date
$ ./gradlew :feature:clipboard:check     # after the last test commit
feature:clipboard tests=97, failures=0 — LocalClipSendTest 18, AutoClearTest 16, ChunkedTransferTest 12,
ClipReceiveTest 11, TransfersTest 6, ClipReaderTest 6, ClipNotifierTest 5, SystemClipboardTest 3,
AccessibilityConsentTest 2, SensitiveContentTest 3, ClipIdLedgerTest 3, ConflictPolicyTest 3, LoopGuardTest 3,
PushValidatorTest 3, CopySignalMatcherTest 3
core:protocol ClipboardMessagesTest 4; feature:connection SessionRouterTest 7 (ack wait after the chunks),
LocalCapabilityBuilderTest 4 (auto_send needs the consent)
```

Module tests run the real `ClipboardModule` on the coroutine test scheduler (virtual time for the 10 s, 30 s, 60 s and 120 s rules) with sessions built from `PeerSession` and envelopes routed through `SessionRouter`, so `ack` correlation and de-duplication are the production ones.

**Exception coverage** (test, or manual check below):

| Function | E | Covered by |
|----------|---|------------|
| CLIP-01 | E1 | `LocalCapabilityBuilderTest` (auto_send needs setting, consent, running service), `AccessibilityConsentTest`; event gating — manual |
| | E2 | `CopySignalMatcherTest` negatives; per app/OEM — manual |
| | E3 | `anEmptyOrUnreadableClipIsReportedOnlyOnTheManualPath`, `ClipReaderTest.emptyClipsAndOtherTypesAreE3`; 1 s focus limit — manual |
| | E4 | `sensitiveContentIsHeldUntilSendAnywayForAtMostTwoMinutes`, `blockSensitiveOffSendsCardNumbers`, `SensitiveContentTest`, `ClipReaderTest.theSensitiveExtraIsReadOnEveryVersion`, `ClipNotifierTest` |
| | E5 | `textOverOneMebibyteIsTooLarge` |
| | E6 | `withoutClientsTheClipIsKeptAndReplayedWithinTwoMinutes`, `aStaleClipIsNotReplayed` |
| | E7 | `sendAgainResendsTheSameContentAsANewClip`, `aConflictAboutAReplayedClipIsNotShown` |
| | E8 | `noAckIsNotRetriedButReplayedOnTheNextSessionAckedClipsAreNot` |
| | E9 | `theAutomaticPathSkipsTheClipSentWithinFiveSecondsTheManualPathDoesNot`, `theClipJustReceivedIsNotSentBack`, `LoopGuardTest` |
| | E10 | `featureDisabledPausesThePairUntilItsNextCapabilityUpdate` |
| CLIP-02 (phone side) | E7 | `aLocalChangeWithinFiveHundredMillisecondsWinsAndTheSenderIsTold`, `crossingClipsKeepTheNewerOriginTsWithoutAConflictMessage`, `aLocalChangeTheSenderAlreadyAcknowledgedIsNoConflict` |
| | E8 | `aFailedWriteIsInternalAndTheSameClipMayComeAgain` |
| | API 4–5 | `aMacClipIsWrittenAppliedAndForwardedUnchanged`, `aConflictAboutAForwardedClipGoesBackToItsOrigin`, `aConflictAboutAReplayedForwardedClipIsDropped`, `aReceivedClipIsNotReplayedToItsOriginOrWhereItWasDelivered`, `refusedPushesGetRejectedAcksAndAreNotForwarded`, `aDuplicateClipIdIsIgnoredAndNotWrittenAgain` (E1–E6, E9 of CLIP-02 are Mac-side, card M1.4) |
| CLIP-03 | E1 | `imagesStayOnThePhoneWhenSyncImagesIsOff`, `peerMimesAndLimitsChooseTheTargets`, receiver `CLIP_UNSUPPORTED_MIME` |
| | E2 | `ClipReaderTest.anImageOverTenMebibytesIsTooLargeAndLeavesNoFile`, toast in `anEmptyOrUnreadableClip…` |
| | E3 | `anUndecodableImageIsReportedOnlyOnTheManualPath`; real decoders — manual |
| | E4 | `aWrongHashIsReportedWithTheTransferAndTheFileIsDeleted`, `theSenderResendsOnceAfterAMismatchThenGivesUp` |
| | E5 | `aNewerClipCancelsTheRunningTransferAsSuperseded` |
| | E6 | `cancelOnEitherSideStopsTheTransfer`, `cancelOnTheSendingProgressStopsTheTransferAndTheClipIsNotReplayed` |
| | E7 | `theReceiverCancelsAfterThirtySecondsWithoutAChunk` |
| | E8 | `aClosedSessionDropsTheTransferWithoutAnAck` |
| | E9 | `noStorageIsInternalWithTheNoSpaceMessage` |
| | E10 | `ClipReaderTest.aRevokedGrantIsSkippedSilently` |
| CLIP-05 (C17) | E1 | `theUsersOwnCopyIsNeverCleared`, `aHandLiveLabelWithAnotherTimestampIsNotHandLivesClip`, `aCopySignalAfterTheFirstSecondDropsTheTimer`, `sendingALocalClipOrReadingOtherContentIsASignOfChange`, `theInAppListenerIgnoresHandLivesWriteButNotTheUsers` |
| | E2 | `aNewClipReplacesTheTimer` |
| | E3 | `withoutFocusOrAccessibilityTheCheckWaitsForTheApp`, `aPostponedCheckFindsTheUsersCopyAndLeavesIt`, `anActivityWithoutFocusPostponesTheCheck`, `withAccessibilityTheActivityVerifiesTheDescription` |
| | E4 | by design (timer not persisted) — manual |
| | E5 | `changingTheSettingRecomputesTheDeadlineAndOffCancelsIt` |
| | E6 | deadline on `elapsedRealtime` — manual (deep sleep) |
| | E7 | `aFailingClearIsIgnored` |

## Spec deviations and proposals

1. **Too-large toast on the automatic path too.** CLIP-01 field 10 mentions the manual path; QC5 and CLIP-03 E2 say "reported in place" for every path. The phone toasts "Content is too large…" / "Image is too large…" on both paths, otherwise an automatic copy silently goes nowhere. Proposal: say "both paths" in field 10.
2. **`ignored`/`cancelled` is not a final outcome.** API 5 logic 6 makes every `ignored` clip a duplicate, but a transfer cancelled for `timeout` is "not received" and QC7 may replay it with the same `clip_id`. Android records cancelled clips like rejected ones (may come again). Proposal: add this to logic 6.
3. **QC8 "local change" on the phone** is its latest clip whatever its origin: a Mac clip written and being forwarded to the iPad counts as the phone's unacknowledged change towards the iPad. Proposal: state it in QC8 for the hub role.
4. **"At most 4 chunks waiting"** is not counted: chunks are sent one envelope at a time through the session's cipher lock, other envelopes interleave between them, and back-pressure comes from the WebSocket's outgoing queue. To be measured with the 5 MB scenario (I1); a counter can be added in `OutgoingTransfers` if calls/SMS starve.
5. **E9 on the manual path.** QC4 ("same as the clip just received within 5 s") skips on every path; the manual path then shows no toast (no catalog text fits). Proposal: decide a text or keep silence.
6. **Missing text for a peer's refusal of a manual send** (`INTERNAL`, `CLIP_UNSUPPORTED_MIME`): only `FEATURE_DISABLED` ("This feature is off on …") and `CLIP_TOO_LARGE` have Android texts; the others are silent. Proposal: `error.clip_write_failed_on_device` "Couldn't update the clipboard on {device_name}" for Android (the Mac has the reverse `error.clip_write_failed_on_phone`). Not added to the catalog (a design decision, not a missing key).
7. **"Send Again"** needs the clip in memory: kept 120 s from the conflict notification; a conflict about a clip the phone no longer holds is dropped. "Send Again" counts as a manual send ("Sent to …").
8. **Card-number separators**: single spaces or hyphens are accepted between any two digits (not only between 4-digit groups); two in a row break the run.
9. **CLIP-05 "changed"** drops the timer but keeps the clip file (a false Accessibility signal must not break a paste); the file goes with the next HandLive write, CLIP-05 clear, or the 1 h cleanup at start.
10. **`FEATURE_DISABLED` pause** lasts until the peer's capability changes; identical `capability/update`s are coalesced by the state flow, which is harmless because the peer's next real change differs.
11. **Images over 40 MP** that need conversion (HEIC, WebP…) are treated as unreadable (E3) instead of being decoded into ~160 MB of pixels; their PNG would exceed 10 MiB anyway.
12. **Implementation notes**: `ClipFileProvider` subclasses `FileProvider` (with the paths meta-data) so no other library's provider clashes in the merged manifest; the tile uses `startActivityAndCollapse(Intent)` below API 34 under a targeted `@SuppressLint("StartActivityAndCollapseDeprecated")` because lint ignores the SDK guard; `ClipboardReadActivity` is a platform `Activity` with a translucent platform theme.

## Pending manual checks (no device here)

- Copy detection per app and OEM (Chrome, Gmail, Keep, WhatsApp, Samsung Notes, MIUI), the Android 13+ overlay rule, external keyboard copy on 10–12 (E2 expected); record failing devices in `docs/deployment-guide.md`.
- `ClipboardReadActivity` focus and the keyboard flicker, the system toast "HandLive pasted from your clipboard" on 12+, background start from the bound Accessibility service, verification mode for CLIP-05.
- Quick Settings tile on API 29–33 and 34+, notification button, Share target label, locked-screen tap.
- Paste of received images and large texts through `clipfiles` in Messages, Gmail, Keep; `IS_SENSITIVE` hides the overlay preview on 13+; content from password managers is blocked.
- CLIP-05 on Android 10–15: the system timestamp falls within [`wallFrom`, `wallTo`]; deep sleep delays the deadline (E6).
- `AndroidImageNormalizer` with HEIC, WebP, GIF, TIFF; progress notification and Cancel on both sides.
- Latency with `shared/tools/bench` (T1.1): text p95 < 50 ms and 5 MB image p95 < 2 s, Pixel and Samsung against both Macs (needs M1.4).

```text
Status: DONE_WITH_CONCERNS
Summary: feature:clipboard implements CLIP-01 (Accessibility detection, ClipboardReadActivity, notification button, tile, Share, disclosure choices), CLIP-02 writes and forwarding, CLIP-03 chunked transfers and CLIP-05 safe auto-clear with QC1–QC8 and HLBENCH hooks; 97 module tests (every E covered or listed for devices) and ./gradlew check green.
Concerns/Blockers: nothing ran on a real phone yet — copy detection, focus behaviour and latency targets are unverified until devices and the Mac client (M1.4) are available.
```

## Follow-up (controller update: catalog keys decided from this report)

Repository handlive-android, branch `feat/phase-01-clipboard` (after the S1.3 commits up to 0dc94dd), pushed; CI `ci-android` run 36180009175 green on 4f40e22 (`gradlew check` 4 min, commit author check).

- **`error.clip_write_failed_on_device`** (CLIP-01 field 11): a manual send the peer refuses with an error other than `FEATURE_DISABLED`, `CLIP_TOO_LARGE` (and `CLIP_CHECKSUM_MISMATCH`, which keeps its resend and "Couldn't send the image") now shows "Couldn't update the clipboard on <device>". The automatic path stays silent; a timeout (E8) is not a refusal and stays silent too.
- **`clipboard.skipped_just_received`** (CLIP-01 field 11, QC4/E9): the loop guard now remembers which device the written clip came from; a manual send (notification button, tile or Share) of that same text or image within 5 s is skipped with "Not sent — this just came from <device>." instead of silence. The automatic path stays silent.
- **Verified against the updated specs, no change needed:** the `clipboard` channel is `IMPORTANCE_LOW` with the catalog name and description (a new test checks the descriptions of all three channels); the too-large toast shows on both the automatic and the manual path (test now covers both).
- The `ClipMessage` results that carry a device name are data classes now (clearer assertions).

| Hash | Subject |
|------|---------|
| f24e63a | feat(android): explain refused and skipped manual clipboard sends |
| 82221f0 | test(android): cover refused and skipped manual sends and too-large text on both paths |
| 561d531 | docs: cite the specs for the low importance of the notification channels |
| 4f40e22 | test(android): check the channel descriptions and the Security Code form |

```text
$ ./gradlew check
BUILD SUCCESSFUL
feature:clipboard tests=101, failures=0 — new: aRefusedManualSendSaysTheClipboardWasNotUpdated (INTERNAL on a manual
  send → "Couldn't update…"; CLIP_UNSUPPORTED_MIME on an automatic send → silent),
  theClipJustReceivedIsNotSentBackAndAManualSendSaysWhy (auto silent; manual and Share → the toast),
  anImageJustReceivedIsNotSentBackEither, textOverOneMebibyteIsTooLargeOnBothPaths,
  LoopGuardTest (origin device of the written clip), ClipNotifierTest (both toasts in English, Vietnamese)
feature:connection ServiceNotificationTest tests=5 (descriptions of hl_service, clipboard, permission)
```

```text
Status: DONE_WITH_CONCERNS
Summary: The two decided clipboard texts are adopted (peer refusal of a manual send, manual send of the clip just received) and the channel and too-large clarifications are verified by tests; ./gradlew check and CI green.
Concerns/Blockers: unchanged — nothing ran on a real phone yet; copy detection, focus behaviour and latency targets wait for devices and the Mac client (M1.4).
```
