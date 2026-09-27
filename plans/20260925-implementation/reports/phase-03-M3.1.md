# Phase 3 — M3.1 [macOS]: call panel, and the call packages shared by the Mac and iPhone/iPad

Card M3.1 of `phase-03-cuoc-goi.md`. Repository handlive-apple, branch `feat/phase-03-calls`. As agreed, the package
work the Mac panel is the first card to use is reported here: the `call_event` messages (HLProtocol), the client call
context and commands (HLAppCore), the call log store and sync, call notifications and push decoding, the call list
(new package `HLCalls`), the capability and settings, the HLBENCH/1 events, and the CI and flaky-test fixes. The
Mac notifications are in `phase-03-M3.2.md`, the Mac call log, Settings and menu in `phase-03-M3.3.md`, the iPhone and
iPad in `phase-03-I3.1.md`.

## What was done

- **Flaky close code (coordinator's extra task, CI run 36293598842 on `main`)**: `WebSocketIntegrationTests.swift:48`
  saw `closed.code == nil`. Cause, proven with a probe build of the receive callback: when the peer sends a close
  frame and drops the TCP connection right after, Network.framework can hand over the close frame's metadata (opcode
  `.close`, `closeCode`) **and** an `EPIPE`/`ECONNRESET` error in the same `receiveMessage` callback. The channel
  looked at the error first, ended without a code, and so could lose any private close code of the phone (4401, 4403,
  4409 …) in production too, not only in the test. Fix in the channel, not the test (`WebSocketChannel.swift`): a
  pure `ReceivedFrame` reads the close frame before the error (a complete message that arrives with an error is still
  delivered, then the channel ends). Evidence: stress loop of the integration test 2 failures in 1,000 runs before,
  0 in 5,000 after; 50 full integration runs clean; four unit tests on `ReceivedFrame` pin the cases.
- **Protocol** (`HLProtocol/CallMessages.swift`, `CallLogMessages.swift`, `Features.swift`): `call_event` ops `state`
  (every field of CALL-01 API 1, `null`s encoded explicitly, lenient enums for new values), `action` with
  `audio` only for `answer` and the `CALL_ACTION_NOT_ALLOWED` details, `log_sync` (cursor, `limit` 200) and its ack
  page `{entries, cursor, has_more, reset}`, `log_new`, the `entry` object; `CallFeature` of the capability. Tests on
  every example of `06-call-control.md` and against `shared/schemas` (the schema validator gained `oneOf`,
  `maxItems`, `maxProperties`).
- **Transport** (`SessionTypes.swift`): `call_event` envelopes from the phone reach the app.
- **Call context and commands** (`HLAppCore/Calls/`): `CallController` applies each `state` per CALL-01 API 1 logic
  6 (latest envelope `ts`; an idle call only takes the idle correction; a new `call_id` replaces the context; a
  "recently ended" set drops late versions), phases ringing / waiting / in call / ended ("Call ended" for 2 s), the
  reconnect rule of E8 (a call the phone does not send again within 3 s is over), flow A missed calls when the phone
  has no call log. Commands (CALL-02 step 4, E5): buttons locked until an `ack` or a phase change; one
  `REQUEST_TIMEOUT` from the click; the **same envelope `id`** re-sent when the session comes back in time; never a
  new `id`; after an `ok` ack, 3 s for the `state`; error acks mapped to the panel problems (`CallProblem`); "Decline
  with Message…" sends its SMS on the successful ack or on `idle`, never after `offhook` (E9). `forgetCall()` for iOS
  in the background. `CallPermissions` (which missing permissions are calls', PAIR-02 field 9). No number, name or
  quick reply is ever logged.
- **Call log** (new package `Packages/HLCalls`, products `HLCalls`, `HLCallNotifications`, `HLCallsUI`):
  - `call_log_entry` and `idx_call_log_ts` added to the SQLCipher database as migration `v2-call-log` of
    `SmsDatabase` (0.9.3; one database file per device, as the spec has it).
  - `CallLogStore` / `CallLogEngine`: `log_sync` pages with the opaque cursor in `sync_cursor` (`stream = 'calllog'`),
    one transaction per page, `reset = true` deletes the pair's rows in the same transaction, `seen` rules of step 5,
    `log_new` upserts and reports new missed calls, E2 permission missing, E4 stop, E6 retry once after 5 s, E7
    rollback, 90-day pruning, badge (unseen missed), mark seen per entry or all, delete per pair.
  - `HLCallNotifications` (no database, linked by the extension too): titles ("Unknown Caller" in flow A, "No Caller
    ID" only for a hidden number, national format), bodies with time and SIM label, threads, categories
    (`HL_CALL_INCOMING_MAC`, `HL_CALL_INCOMING`, `HL_CALL_MISSED`), `userInfo` (every key, `null`s kept), the
    `INStartCallIntent` communication form, removal rules, `CallPushDecoder` for `call_event` pushes with `K_push`,
    and `CallNotificationCenter` (post a missed call, remove what a filter picks) used by both apps.
  - `HLCallsUI`: `CallListView` (fields 1–6, 12, empty state "No Calls Yet"), `CallDisplay` (list time, duration,
    timer, VoiceOver labels with the call type, problem texts), `CallerAvatar`.
- **Capability and settings** (`AppSettings`, `LocalDevice`): `feature.call`, `call.notify`, `call.ringtone`,
  `call.quick_replies` (6 × 160), `sms.peer_can_send`; `features.call` advertised (`notify` only on iPhone/iPad).
- **HLBENCH/1** (debug builds): `call_state_received`, `call_action_tap`, `call_action_sent` (one line per attempt,
  same `env`), `call_action_ack_received` in the controller; `call_alert`, `call_panel_shown`, `call_notified` on
  the Mac; `call_banner_shown` on iPhone/iPad; `call_push_shown` in the extension under the subsystem
  `app.handlive.ios.nse` (role `ios`); `call_missed_notified` in the shared helper — every Phase 3 client event of
  `shared/tools/bench/README.md`.
- **Mac panel** (`HLMacUI`): `CallPanelController` — a non-activating `NSPanel` (`.nonactivatingPanel`,
  `.borderless`), level `.floating`, `[.canJoinAllSpaces, .fullScreenAuxiliary]`, `hidesOnDeactivate = false`,
  shown with `orderFrontRegardless()` 16 pt from the top-right corner of the screen with the pointer, draggable,
  glass on macOS 26 (`NSGlassEffectView`) and `.popover` material before, `radius-panel`; slides in (fades only with
  Reduce Motion); VoiceOver "Incoming call from …" through `.announcementRequested`; `call_panel_shown` when it is
  on screen. `CallPanelView` — ringing (Decline left, Answer right, "Decline with Message…" with the quick replies
  and "Custom Message…", Ignore), call waiting with the waiting caller and the Bluetooth line, in call with the timer
  and End, "Call ended · mm:ss"; "Answering…"/"Declining…"; the caller-ID hint; connection lost; problems. Return
  answers, ⌘⌫ declines, Esc ignores. `CallRingtone` — `NSSound` looping a chime HandLive synthesizes (no sound file
  ships), stops on any state change, a button, Ignore or after 60 s, never rings twice for a call. `FocusStatus` —
  `INFocusStatusCenter`, asked when "Ring on Mac" is turned on. `CallAlertPolicy` — one visible layer per call:
  Focus on → no panel, no ring, time-sensitive notification; Focus unreadable → panel without ringing, passive
  notification; `call.notify` off → only the menu bar menu. `MacCalls` wires it into `AppModel` (link events, pair,
  database, settings, quick replies).
- **Other fixes**: `SmsEngineSyncTests` waited for new messages before the first sync had finished (CI run
  36296614907) — it now waits for `.syncStatus(.done)`. `PairingControllerTests.refreshes` slept a fixed 900 ms and
  relied on a 160 ms margin before the 250 ms ticker reached 0:00; on CI's runner the tick came late (run
  36299351693). It now waits for the countdown to run 1 → 0, then checks that no new code comes while the QR code is
  being verified (30/30 local runs, 15/15 with every core busy). Push vector counts updated for the call vectors
  (8 → 12 envelopes, 9 → 12 invalid ones).
- **CI**: `HLCalls` tested through its `HLCalls-Package` scheme and listed in `HandLive.xcworkspace`.

## Commits (handlive-apple)

| Hash | Subject |
|------|---------|
| 009593e | fix(apple): keep the peer's close code when its close frame arrives with an error |
| 90c8035 | feat(apple): add the call_event state, action and call log messages |
| a85b8d3 | test(apple): check the call_event examples and messages against the call schemas |
| c2fda0a | feat(apple): hand call_event envelopes from the phone to the app |
| 7ddc661 | feat(apple): follow the phone's call and send answer, decline and end |
| b15b93d | test(apple): test the call context, the command rules and the quick reply |
| d255f88 | feat(apple): regenerate the String Catalogs from handlive-shared 6930f0f |
| 47621b9 | test(apple): open the call push vectors with the SMS ones |
| 0652b40 | feat(apple): add the call log table to the encrypted database |
| 2b706da | feat(apple): add the call log store, its sync, the call notifications and the call list |
| c9896f2 | test(apple): test the call log store and sync, call notifications and call pushes |
| 8f1e93f | ci(apple): test HLCalls through its package scheme and list it in the workspace |
| 9f6ac25 | test(apple): let the first SMS sync finish before new messages arrive in the notify test |
| 0ae9494 | feat(apple): write the call bench events of the client in debug builds |
| 4a629d8 | feat(apple): advertise calls in the capability and keep the call settings |
| f860029 | feat(apple): regenerate the String Catalogs from handlive-shared 1a87a80 |
| 9a61412 | feat(apple): show the empty call list and read each call's type to VoiceOver |
| 97097a5 | feat(macos): add the call panel, its ringtone and the Focus rule |
| 5136088 | feat(macos): run calls in the Mac app model |
| 6e8c685 | test(macos): test the call panel, ringtone, Focus rule, notifications and commands in the app model |
| 7ff49a5 | feat(apple): share which missing permissions are calls' and let a device forget the call in the background |
| 7e8ae7f | refactor(apple): share the caller avatar, the command problem texts and the empty call list |
| 54106a9 | test(macos): wait for the pairing countdown to reach 0:00 instead of a fixed sleep |
| 4c7f57f | docs(apple): describe the calls package, the call screens and the extension's call pushes |

No commit in handlive-shared: every catalog key came from the shared agent (heads 6930f0f, then 1a87a80).

## Files

`Packages/HLTransport/Sources/HLTransport/{WebSocketChannel,SessionTypes,BenchLog}.swift`, tests
`ReceivedFrameTests.swift`, `ControlSessionMessagingTests.swift`; `Packages/HLProtocol/Sources/HLProtocol/{CallMessages,
CallLogMessages,Features}.swift`, tests `CallMessagesTests`, `CallSchemaConformanceTests`, `SchemaValidator`;
`Packages/HLAppCore/Sources/HLAppCore/Calls/{CallPeer,ActiveCall,CallProblem,CallController,CallController+Commands,
CallController+Choices}.swift`, `AppSettings.swift`, `LocalDevice.swift`, tests `CallTestSupport`, `CallContextTests`,
`CallCommandTests`, `AppCoreTests`; `Packages/HLSMS/Sources/HLSMS/SmsDatabase.swift`, tests `SmsStoreTests`,
`SmsEngineSyncTests`; `Packages/HLCrypto/Tests/HLCryptoTests/PushEnvelopeVectorTests.swift`; new `Packages/HLCalls/`
(`Package.swift`, `Sources/HLCalls/{CallLogStore,CallLogEngine,CallLogEngine+Sync,CallsModel}.swift`,
`Sources/HLCallNotifications/{CallNames,CallNotificationKeys,CallNotificationContent,CallNotificationBuilder,
CallPushDecoder,CallNotificationFilter,CallNotificationCenter}.swift`, `Sources/HLCallsUI/{CallDisplay,CallListView,
CallerAvatar}.swift`, tests); `Packages/HLMacUI/Sources/HLMacUI/{CallPanelController,CallPanelModel,CallPanelView,
CallRoundButton,CallRingtone,FocusStatus,CallAlertPolicy,MacCalls,MacCalls+Alerts,MacCalls+Actions,AppModel,
AppModel+Calls,AppModel+Link,AppModel+Messages,AppModel+Pairing,AppModel+Account}.swift`, tests `CallTestSupport`,
`AppModelCallsTests`, `TestSupport`, `PairingControllerTests`; `Packages/HLLocalization` (generated);
`.github/workflows/ci-apple.yml`; `HandLive.xcworkspace`; `README.md`, `README.vi.md`, `CLAUDE.md`.

## Tests

Local, Command Line Tools, `HL_SWIFT_TESTING_PACKAGE=1` (SwiftUI packages with
`SDKROOT=/Library/Developer/CommandLineTools/SDKs/MacOSX26.sdk`), head 219854d:

```
HLProtocol   ✔ Test run with 64 tests in 13 suites passed after 0.027 seconds.
HLCrypto     ✔ Test run with 46 tests in 12 suites passed after 6.787 seconds.
HLTransport  ✔ Test run with 99 tests in 18 suites passed after 6.840 seconds.
HLAppCore    ✔ Test run with 78 tests in 16 suites passed after 2.508 seconds.
HLDesignSystem ✔ Test run with 24 tests in 7 suites passed after 0.123 seconds.
HLLocalization ✔ Test run with 9 tests in 3 suites passed after 0.181 seconds.
HLSMS        ✔ Test run with 27 tests in 5 suites passed after 0.450 seconds.
             ✔ Test run with 10 tests in 2 suites passed after 0.025 seconds.   (HLSMSNotifications)
HLSMSUI      ✔ Test run with 11 tests in 2 suites passed after 0.152 seconds.
HLCalls      ✔ Test run with 14 tests in 3 suites passed after 0.389 seconds.   (HLCallsTests)
             ✔ Test run with 13 tests in 2 suites passed after 0.024 seconds.   (HLCallNotificationsTests)
HLMacUI      ✔ Test run with 41 tests in 7 suites passed after 2.095 seconds.
HLiOSUI      ✔ Test run with 23 tests in 3 suites passed after 1.070 seconds.
swiftlint lint --strict → Done linting! Found 0 violations, 0 serious in 362 files.
```

Flaky-test evidence: integration test in a loop 2/1000 failures before the channel fix, 0/5000 after, 50 full
`WebSocketIntegrationTests` runs clean; `refreshes` 30/30 locally and 15/15 with every core busy.

CI (`gh run list -R HandLive/handlive-apple --branch feat/phase-03-calls`): run 36301604773 on 8e1311b **success** —
HLProtocol 64, HLCrypto 46, HLTransport 99, HLDesignSystem 24, HLLocalization 9, HLAppCore 78, HLSMS 10 + 27,
HLSMSUI 11, HLCalls 13 + 14, HLMacUI 41, HLiOSUI 23 tests; "Found 0 violations, 0 serious in 362 files";
`Build app macOS` and `Build app iOS + Notification Service Extension` both `** BUILD SUCCEEDED **`. Earlier red
runs and their fixes: 36295416902 (String Catalogs behind the shared catalog → d255f88), 36296614907 (SMS notify race →
9f6ac25), 36297783016 (catalog 1a87a80 → f860029), 36299351693 (pairing countdown flake → 54106a9).
**Final head 219854d: CI run 36303066286 — success** (HLProtocol 64, HLCrypto 46, HLTransport 99, HLDesignSystem 24,
HLLocalization 9, HLAppCore 78, HLSMS 10 + 27, HLSMSUI 11, HLCalls 13 + 14, HLMacUI 41, HLiOSUI 23 tests; "Found 0
violations, 0 serious in 362 files"; both app builds `** BUILD SUCCEEDED **`).

## Spec deviations and proposals

1. `06-call-control.md` §6.1.1 "Special requirements" and CALL-01 API 5 logic 3 name a
   `com.apple.developer.focus-status` entitlement ("Focus Status" capability). Apple documents no such key; reading
   `INFocusStatusCenter` requires the **Communication Notifications** capability
   (`com.apple.developer.usernotifications.communication`, already in `macOS/HandLive.entitlements`) plus the user's
   permission and `NSFocusStatusUsageDescription` (an Apple engineer on developer.apple.com/forums/thread/682143;
   without it `INFocusStatusCenter` fails with `DNDErrorDomain` 1004 "App is missing Communication Notifications
   entitlement"). Not added. Proposal: replace the key in both places (and the `.vi.md` twin).
2. CALL-01 API 5 "Method": "NSSound looping a ringtone file from the bundle". The ringtone is synthesized in code
   (a soft two-note chime) and played with `NSSound`, so no third-party sound ships and nothing enters NOTICE.
   Proposal: allow a synthesized or first-party tone.
3. Keyboard: the panel never takes focus (API 5 logic 1), so Return, ⌘⌫ and Esc work once the user clicks it (it
   then becomes key without activating HandLive). Proposal: say so in the CallPanel README.
4. A call answered from the Mac's notification during a Focus opens the in-call panel (API 7 "Response: opens the
   in-call panel"); other in-call panels stay hidden while a Focus is on, as E4 asks for ringing calls.
5. `shared/tools/bench/README.md` gives the extension its own subsystem; `BenchLog.configure` gained an optional
   `subsystem`, the line keeps `role=ios`.

## Pending manual checks

- Real Mac with the Android app (A3.x): panel ≤ 300 ms after `state` (`call_state_received` → `call_panel_shown` in
  `call_latency.py`), on every Space including a full-screen app, no focus taken while typing elsewhere, drag,
  VoiceOver announcement, Reduce Motion.
- Ringtone: loops, follows the system volume, stops on answer, decline, Ignore, a state change and after 60 s.
- Focus: the permission prompt when "Ring on Mac" is turned on; Focus on → no panel, no ring; permission denied →
  panel without ringing.
- Answer and Decline from the panel against a real phone (< 500 ms), E5 with the phone unplugged from the network,
  the same envelope `id` after a reconnect.
- Signed build with the Communication Notifications capability (Focus status needs it).

Status: DONE
Summary: The call packages (protocol, controller, call log, notifications, push decoding, bench events) and the Mac call panel with ringtone and Focus rule are done, tested locally and green on CI; the flaky close-code test was fixed in the channel with evidence.
Concerns/Blockers: Only real-device checks remain (panel timing, Spaces, Focus, ringtone, end to end with Android).
