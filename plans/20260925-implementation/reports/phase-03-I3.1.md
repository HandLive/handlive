# Phase 3 — I3.1 [iOS]: call pushes in the extension, Decline from the notification, in-app banner, Calls tab

Card I3.1 of `phase-03-cuoc-goi.md`. Repository handlive-apple, branch `feat/phase-03-calls`. Builds on the shared call
packages of `phase-03-M3.1.md` (`CallController`, `HLCalls`, `HLCallNotifications`, `HLCallsUI`).

## What was done

- **Notification Service Extension** (CALL-01 API 6, CALL-04 API 4): a `call_event` push is opened with `K_push`
  of the pair in `p` (Keychain group, readable only while unlocked, C3) before the SMS path.
  - Ringing `state` → title = caller (name, national number, "Unknown Caller", "No Caller ID"), body "Incoming call"
    (· SIM label), thread `calls`, `userInfo {pair_id, call_id, started_at}` merged with the push's `p`/`hl`,
    category `HL_CALL_INCOMING` with "Decline" (`.destructive`, `.authenticationRequired`, placeholder "Incoming
    call") only when `controls.reject` (field 7), and the `INStartCallIntent` communication form (initials avatar,
    E.164 handle for Focus filtering); the time-sensitive level comes from APNs.
  - More than 60 s after `started_at` → "Incoming call at <time>", no category, no communication form (E7).
  - Missed call (`log_new` of a missed entry, or an idle `state` missed in flow A) → title, "Missed call · 2:05 PM"
    (· SIM label), "Message" (`HL_CALL_MISSED`) only when the app's copy `sms.peer_can_send` says `true` and there is
    a number; the relay's collapse key makes it replace the incoming notification.
  - Locked, another pair, older than 24 h, a duplicate envelope id or anything unexpected → the generic `loc-key`
    text stays, with no button (E6, E9). No database, no network.
  - `call_push_shown` (`call`, `reason`, `late`) under the subsystem `app.handlive.ios.nse`, role `ios`.
- **Declarations**: `INStartCallIntent` in the app's `NSUserActivityTypes`; `IntentsSupported`
  (`INSendMessageIntent`, `INStartCallIntent`) in the extension's `NSExtensionAttributes`; the Communication
  Notifications entitlement on the extension (CALL-01 API 6: "I-NSE needs the Communication Notifications
  capability"). The app already had the time-sensitive and communication entitlements.
- **Decline from the notification** (CALL-02 flow B, API 6): the delegate runs it in a `beginBackgroundTask`; older
  than 90 s or another pair → only remove the notification (logic 2); otherwise wake the connection manager (LAN,
  then relay), and when the relay reports the phone offline (`waitingPeer`) send the `call_action` wake push
  (CONN-04); `reject` with one 15 s deadline (`CALL_REJECT_BG_TIMEOUT`, connection included) and the same envelope
  `id` on every attempt; a successful `ack`, `CALL_NOT_FOUND` or any `CALL_ACTION_NOT_ALLOWED` → remove the
  notification (B3); anything else → the local notification "Couldn't decline the call. It's still ringing on the
  phone." (E8); the app never comes to the foreground; `call_action_tap from=notification`.
- **"Message" on a missed call** (CALL-04 API 4): queued in `sms_outbox` for the number through the call's SIM, in a
  background task of about 20 s (`SMS_QUICK_REPLY_TIMEOUT`); no acceptance in time → "Not sent yet. Open HandLive to
  try again." and the next opening sends it; empty text ignored; the entry becomes seen.
- **The app's copy of the phone's SMS send capability** (`sms.peer_can_send`, 0.9.5): rewritten on every connection,
  `capability/update` and SMS switch here; removed on unpairing; erased with "Delete All HandLive Data".
- **Removing incoming-call notifications** (API 6 logic 4): when the call's `state` is no longer `ringing`, or when
  the app first hears of the call in another state; on every return to the foreground, every incoming-call
  notification whose call started over 60 s ago. Generic ones (shown while locked) are recognized by the `call_event`
  type of their plain envelope; the app opens them with `K_push` to learn the call, or judges them by the envelope
  `ts` when they are too old to open. Opening the Calls tab removes the pair's missed-call notifications, generic ones
  included. Bug fixed on the way: after an SMS sync, "remove the generic notifications" removed every notification
  with `p`, calls included — it now removes only generic **SMS** pushes.
- **In-app banner** (step 8, fields 1–5 and 7): a material card over the tabs — "Incoming Call" or "Call Waiting"
  (then only the waiting caller, no Bluetooth line), the caller and number, the SIM label, a round red "Decline"
  when `controls.reject`, "Declining…", "Lost connection to the phone", the command problem; VoiceOver "Incoming call
  from …" once per call; `call_banner_shown`; closes on `offhook`/`idle`; none with "Call Notifications" off (E3).
  In the foreground an incoming-call push never shows as a system banner: the banner comes from the push itself when
  no session brought the call yet, and the app reconnects at once (logic 3); missed-call notifications only go to
  Notification Center (`[.list]`). In the background the app forgets the call (pushes take over).
- **Calls tab** (CALL-04, 02-ios-ipados.md): `phone.fill`, large title "Calls", a plain `CallListView` (type symbol,
  missed in `text-red` and bold until seen, SIM label, duration, time; call log permission hint; "No Calls Yet"),
  badge of unseen missed calls read by VoiceOver as "3 missed calls"; opening it marks the pair's missed calls seen;
  a tap on a missed-call notification opens it.
- **Settings and details**: a Calls group ("Calls" with the reason calls don't work with the phone, "Call
  Notifications" — both in this device's capability — "Last synced", the call log permission hint); the
  Notifications row says "Focus may silence call notifications" when Time Sensitive notifications are off (SET-03
  field 8), and so does the last setup screen; the phone's details show a Calls row and the call permission
  instructions ("Grant Call Permission on Your Phone").
- **App delegate**: registers the SMS and call categories at launch, asks the model how to present a notification in
  the foreground, routes call and SMS actions in background tasks.

## Commits (handlive-apple)

| Hash | Subject |
|------|---------|
| 6a53812 | feat(ios): declare INStartCallIntent for the app and the intents the extension supports |
| 8c527ea | feat(apple): decline a call from a notification and keep the phone's SMS send capability for the extension |
| d192f19 | feat(apple): quick reply to a number with an acceptance deadline |
| cb63a9f | feat(apple): keep the push's userInfo in rebuilt call notifications |
| 19de323 | feat(apple): let the notification extension log bench lines under its own subsystem |
| 181d125 | feat(ios): show incoming and missed call pushes in the notification extension |
| e7dc2df | fix(apple): remove only generic SMS pushes after a sync, never call pushes |
| 640d8fa | feat(apple): find generic call pushes when removing call notifications |
| 6fb1774 | feat(apple): treat a notification decline refused because the call moved on as done |
| 7ee9310 | feat(apple): read the app's Time Sensitive notification setting |
| 4703c37 | feat(apple): judge an incoming call push that no longer opens by its envelope time |
| 528c66a | feat(apple): open a call push from its already read fields |
| 242146a | feat(ios): add the calls model with the in-app banner, the call log and the call notifications |
| 749308f | feat(ios): run calls in the app: decline and message from notifications, the banner from a push, the extension's SMS copy |
| 90f1ee8 | feat(ios): add the Calls tab, the incoming-call banner, the Calls settings and the call row in the phone's details |
| 6024e19 | test(ios): test the call banner, notification actions, missed calls and the extension's SMS copy |
| 8e1311b | feat(ios): give the notification extension the Communication Notifications entitlement |
| 0a10dec | feat(ios): warn at the end of setup when Time Sensitive notifications are off |
| 523a479 | feat(apple): offer Decline on an iPhone call notification only when the phone allows it |
| 219854d | fix(ios): tell a late call push by its time, not by a missing Decline |

Also used from `phase-03-M3.1.md`: 2b706da (push decoding, notification content), 7ff49a5 (`forgetCall`,
`CallPermissions.isCall`), 92b0992 (`CallNotificationCenter`), 7e8ae7f (avatar, problem texts, empty list), 4c7f57f
(README, CLAUDE.md).

## Files

`iOS/NotificationService/NotificationService.swift`, `iOS/NotificationService-Info.plist`,
`iOS/NotificationService.entitlements`, `iOS/Info.plist`, `project.yml`;
`Packages/HLiOSUI/Package.swift`, `Sources/HLiOSUI/{IOSCalls,IOSCalls+Events,IOSCallNotifying,IOSAppModel+Calls,
CallBannerView,CallsTabView}.swift` (new), `{IOSAppModel,IOSAppModel+Link,IOSAppModel+Messages,IOSAppModel+Account,
IOSAppModel+Data,IOSNotifying,IOSAppDelegate,IOSRootView,SettingsTabView,PhoneDetailsView,IOSSetupFlow,
IOSSetupView}.swift`, tests `IOSCallsTests`, `IOSCallTestSupport` (new), `IOSTestSupport`, `IOSAppModelTests`;
`Packages/HLCalls/Sources/HLCallNotifications/{CallNotificationContent,CallNotificationBuilder,CallNotificationFilter,
CallPushDecoder}.swift` and tests; `Packages/HLAppCore/Sources/HLAppCore/{AppSettings,SystemPermissions}.swift`,
`Calls/CallController+Commands.swift`, tests; `Packages/HLSMS/Sources/{HLSMS/SmsEngine+Send,
HLSMSNotifications/SmsNotificationKeys}.swift` and tests; `Packages/HLTransport/Sources/HLTransport/BenchLog.swift`.

## Tests

```
HLiOSUI   ✔ Test run with 23 tests in 3 suites passed after 1.070 seconds.   (model on macOS)
            IOSCallsTests: banner with VoiceOver, removed with the notification when answered; a call first heard of
            in another state; notify off; call waiting; Decline on the banner once; Decline from the notification
            (accepted → removed, no phone in 15 s → "Couldn't decline", over 90 s → removed, not sent); foreground
            presentation of a sealed incoming push (banner, no system banner) and of missed calls ([.list]); generic
            pushes opened with K_push, background forgets the call; flow A missed call without Message; Message → outbox
            and "Not sent yet"; the sms.peer_can_send copy follows the capability and goes with the pair; settings
            IOSSetupFlowTests: Time Sensitive read with the notification permission
HLCalls   ✔ Test run with 14 tests in 3 suites passed after 0.389 seconds.
          ✔ Test run with 13 tests in 2 suites passed after 0.024 seconds.
            (push decoding of the five call vectors, rebuilt content keeps p/hl, late push, no Decline
            without controls.reject, generic call pushes in the filters, missed-call rules)
HLAppCore ✔ Test run with 78 tests in 16 suites passed after 2.508 seconds.   (decline from a notification outcomes)
HLSMS     ✔ Test run with 27 tests in 5 suites passed after 0.450 seconds.   (quick reply to a number, deadline)
          ✔ Test run with 10 tests in 2 suites passed after 0.025 seconds.   (generic cleanup keeps call pushes)
Mac Catalyst build of HLiOSUI (every iOS view, the app delegate):
  swift build --triple arm64-apple-ios16.0-macabi → Build complete!
Mac Catalyst type-check of iOS/NotificationService/NotificationService.swift against HLCalls → exit 0
swiftlint lint --strict → Done linting! Found 0 violations, 0 serious in 362 files.
```

CI run 36301604773 (8e1311b): **success** — every package test (HLiOSUI 23, HLCalls 13 + 14 …), SwiftLint "Found 0
violations, 0 serious in 362 files", `Build app iOS + Notification Service Extension (simulator, unsigned)` and
`Build app macOS` both `** BUILD SUCCEEDED **`.
**Final head 219854d: CI run 36303066286 — success** (HLProtocol 64, HLCrypto 46, HLTransport 99, HLDesignSystem 24,
HLLocalization 9, HLAppCore 78, HLSMS 10 + 27, HLSMSUI 11, HLCalls 13 + 14, HLMacUI 41, HLiOSUI 23 tests; "Found 0
violations, 0 serious in 362 files"; both app builds `** BUILD SUCCEEDED **`).

## Spec deviations and proposals

1. **Calls tab layout** — the task asked for "iPad in `NavigationSplitView` as the Messages tab does"; the tab uses a
   `NavigationStack` on iPhone and iPad. CALL-04 defines no call detail screen, and 02-ios-ipados.md lists only
   Messages as a split view ("Each tab's root screen has a large title … (`NavigationStack`)"); a split view would
   show an empty detail column. Proposal: keep the stack, or specify a call detail (caller, time, duration, "Message")
   first.
2. `sms.peer_can_send` (00-common-specs 0.9.5) is "the copy of `features.sms.can_send`"; the app writes `true` only
   when SMS is also on at both ends (otherwise "Message" would queue an SMS nobody sends). Proposal: "`can_send` with
   SMS in effect".
3. CALL-01 field 7 makes "Decline" depend on `controls.reject`; API 6 step 9 sets `HL_CALL_INCOMING` unconditionally.
   The extension sets the category only when `controls.reject` is `true`. Proposal: say so in API 6.
4. CALL-02 B3 lists the outcomes that remove the notification; the app also removes it for `CALL_ACTION_NOT_ALLOWED`
   with `reason = system` (the phone no longer lets the call be declined) and posts "Couldn't decline the call" for
   every other error (`PERMISSION_MISSING`, `FEATURE_DISABLED`, `INTERNAL`). Proposal: write both down.
5. CALL-01 E7 says nothing about the level of a late push: it keeps the level APNs gave it (time-sensitive), because
   `call-notification.schema.json` allows only `passive`/`timeSensitive` for incoming content. Proposal: `active`
   for a late push.
6. CALL-01 API 6 logic 4 removes stale `HL_CALL_INCOMING` notifications by `started_at`; a generic one (device locked
   when it arrived) has no `started_at`, so the app opens it with `K_push`, and when it is older than 24 h
   (`PushEnvelope` refuses it) uses the plain envelope `ts`. Proposal: mention generic notifications there.
7. SMS-05 API 2 logic 2 ("remove the generic notifications after SMS-01") must mean generic **SMS** notifications now
   that calls push too; the filter checks the envelope type. Proposal: reword.
8. While the app is open, missed-call notifications are still posted (CALL-04 API 4: "I-APP while it is running") but
   presented only in Notification Center, since 02-ios-ipados.md says the open app shows no notifications.
9. "Message" (`HL_CALL_SMS`), like SMS "Reply", has no `.authenticationRequired`: sent from a locked device the app
   cannot read `PRK` (C3), so the message waits and "Not sent yet" appears. Proposal: add `.authenticationRequired` to
   both text actions, as "Decline" has.
10. The extension had no `IntentsSupported` and no Communication Notifications entitlement in Phase 2, so SMS
    communication notifications may not have shown as such on a device; both are fixed here.

## Pending manual checks

- Signed build: the App IDs of `app.handlive.ios` and `app.handlive.ios.nse` need the Communication Notifications
  capability, the app also Time Sensitive Notifications; APNs `call_incoming` and `call_missed` through the relay.
- Unlocked iPhone: communication notification with avatar and "Decline"; locked: generic text, no button; a push over
  60 s late; the missed-call push replacing the incoming one (collapse key); stale notifications gone after opening
  the app.
- Decline from the notification with the phone already on the relay: < 2 s to IDLE (`call_action_tap
  from=notification` → the phone's IDLE callback); with the phone offline on the relay: the `call_action` wake; no
  phone within 15 s: "Couldn't decline the call"; also when HandLive was not running and the system launches it in
  the background for the action (the scene may report `background` while the command waits).
- In-app banner ≤ 300 ms, VoiceOver, Decline; Calls tab and badge on iPhone and iPad; "Message" from a missed-call
  notification; the Time Sensitive warning after turning it off in Settings.
- Extension memory under 30 MB (Instruments) with a call push.

## Follow-up: controller decisions

The controller decided the deviations above (spec sync 3 on hub main, 13df812 and later; handlive-shared aa689d6 and
fcf709d). Kept as built: the `NavigationStack` Calls tab (1); `sms.peer_can_send` = `can_send` with SMS in effect at
both ends (2); `HL_CALL_INCOMING` only with `controls.reject` (3); the B3 removal and error rules (4); the cleanup of
generic call notifications (6); removal of generic **SMS** pushes only (7); missed-call notifications only in
Notification Center while the app is open (8). Changed in code (handlive-apple):

| Decision | Commit |
|----------|--------|
| A late incoming-call push (E7, over 60 s after `started_at`) shows at `interruptionLevel = .active`, no longer time-sensitive (deviation 5) | 0df53dd feat(apple): show a late incoming call push at the active level |
| "Message" (`HL_CALL_SMS`) of a missed call runs only on an unlocked device (`.authenticationRequired`; the Mac shares the category) (deviation 9) | ae7930b feat(apple): let a missed call's Message run only on an unlocked device |
| SMS "Reply" likewise (deviation 9) | 356c4bb feat(apple): let an SMS notification's Reply run only on an unlocked device |
| Mac: `HL_CALL_INCOMING_MAC` only when `controls.answer` and `controls.reject` are both true, otherwise no category (`phase-03-M3.2.md`) | b39e6d1 feat(apple): give the Mac call notification Answer and Decline only when the phone allows both |
| The Mac Focus variant's default sound (CALL-01 API 7 after spec sync 3) is now in the schema form of the content and checked against the schema; passive Mac, iPhone and late content carry none | d5db1e7 test(apple): check the default sound of the Mac call notification during a Focus against the schema |
| Mac: a waiting call (`waiting = true`, the first call already answered) stays in the in-call panel with the status "Call waiting" (`call.status_waiting`), the waiting caller and "Handle it on the phone or connect via Bluetooth", and no End (`controls.end = false`, CALL-03 E7; hub ee2a87e). `call.waiting_title` is now used only by the iPhone/iPad banner, so shared may drop `macos` from its platforms | b571af6 feat(macos): show a waiting call inside the in-call panel as Call waiting; 49d6846 test(macos): test the in-call panel of a waiting call |
| String Catalogs regenerated for the catalog comments of handlive-shared 2d4eaeb (3 comment lines, no text change) | fdbac16 feat(apple): regenerate the String Catalogs from handlive-shared 2d4eaeb |

Schema conflict found on the way: handlive-shared 26cb74c added the rule "content without a category must be at the
active level", which rejected the button-less Mac and iPhone contents the decisions ask for. It was reported to the
controller; shared aa689d6 dropped the rule (keeping "active ⇒ no category, no identifier") and fcf709d allowed the
Mac Focus sound. The apple tests validate every incoming shape against fcf709d.

Tests (local, Command Line Tools, shared at fcf709d):

```
HLProtocol   ✔ Test run with 64 tests in 13 suites passed after 0.030 seconds.
HLCrypto     ✔ Test run with 46 tests in 12 suites passed after 6.807 seconds.
HLTransport  ✔ Test run with 99 tests in 18 suites passed after 6.791 seconds.
HLDesignSystem ✔ Test run with 24 tests in 7 suites passed after 0.108 seconds.
HLLocalization ✔ Test run with 9 tests in 3 suites passed after 0.211 seconds.
HLAppCore    ✔ Test run with 78 tests in 16 suites passed after 2.305 seconds.
HLSMS        ✔ Test run with 27 tests in 5 suites passed after 0.439 seconds.
             ✔ Test run with 10 tests in 2 suites passed after 0.015 seconds.   (Reply only once unlocked)
HLSMSUI      ✔ Test run with 11 tests in 2 suites passed after 0.165 seconds.
HLCalls      ✔ Test run with 14 tests in 3 suites passed after 0.382 seconds.
             ✔ Test run with 14 tests in 2 suites passed after 0.020 seconds.   (late level, Mac categories, Message, sound)
HLMacUI      ✔ Test run with 41 tests in 7 suites passed after 2.410 seconds.
HLiOSUI      ✔ Test run with 23 tests in 3 suites passed after 1.074 seconds.
After the waiting-call layout and the regenerated catalog (shared at 2d4eaeb):
HLMacUI      ✔ Test run with 42 tests in 7 suites passed after 2.227 seconds.   (waiting call in the in-call panel)
HLLocalization ✔ Test run with 9 tests in 3 suites passed after 0.251 seconds.  (generate-strings.py --check: OK)
Mac Catalyst type-check of iOS/NotificationService/NotificationService.swift against HLCalls → exit 0
swiftlint lint --strict → Done linting! Found 0 violations, 0 serious in 362 files.
```

CI (`ci-apple`, handlive-shared checked out at the same-named branch):
- run 36305556300 on d5db1e7 with shared fcf709d — **success**;
- **final head fdbac16: run 36306282473, shared 2d4eaeb — success**. HLProtocol 64, HLCrypto 46, HLTransport 99,
  HLDesignSystem 24, HLLocalization 9, HLAppCore 78, HLSMS 10 + 27, HLSMSUI 11, HLCalls 14 + 14, HLMacUI 42, HLiOSUI
  23 tests; "Found 0 violations, 0 serious in 362 files"; `Build app macOS` and `Build app iOS + Notification Service
  Extension` both `** BUILD SUCCEEDED **`.

With the Calls tab decided, the only open items are the real-device checks above.

Status: DONE
Summary: The extension turns call pushes into INStartCallIntent and missed-call notifications (a late push at the active level), Decline works from the notification in the background with the wake and the 15 s deadline, "Message" and "Reply" need an unlocked device, and the app has the incoming-call banner, the Calls tab, the Calls settings and the stale-notification cleanup; tested locally and on CI.
Concerns/Blockers: Every push path and the < 2 s decline still need a signed build, APNs and the Android app.
