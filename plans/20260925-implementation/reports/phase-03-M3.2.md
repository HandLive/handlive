# Phase 3 — M3.2 [macOS]: communication notification of an incoming call, missed-call notification

Card M3.2 of `phase-03-cuoc-goi.md`. Repository handlive-apple, branch `feat/phase-03-calls`. The notification
content, categories, `userInfo` and removal rules live in the shared `HLCallNotifications` product (see
`phase-03-M3.1.md`); this card wires them into the Mac app.

## What was done

- **Incoming call (CALL-01 API 7)** — `UserNotificationCalls.postIncoming`: identifier = `call_id`, title = the
  caller (name, national number, "Unknown Caller", "No Caller ID"), body "Incoming call" (· SIM label), thread
  `calls`, category `HL_CALL_INCOMING_MAC` ("Answer", "Decline" `.destructive`, placeholder "Incoming call"),
  `userInfo {pair_id, call_id, started_at}`, turned into a communication notification with `INStartCallIntent`
  (`INPerson` with the E.164 number as `.phoneNumber` handle and an initials avatar, `INInteraction` donated with
  `direction = .incoming`, `content.updating(from:)`; the plain content stays if the system refuses).
  Level from `CallAlertPolicy`: **passive** while the panel shows (Notification Center only), **time-sensitive**
  with sound when a Focus hides the panel, passive when the Focus status cannot be read; nothing with
  `call.notify` off (E3). Re-posted with the same identifier only when its content changes (the number arriving
  late, E10), so no second banner. `call_notified` bench line once added.
- **One visible layer per call** (API 7 logic 1): the panel or the banner, never both; `willPresent` answers `[.list]`
  for a passive call notification even while HandLive is active.
- **Removal** (logic 2, step 12): the notification goes as soon as the call is no longer ringing (answered, declined,
  ended, a new call), when calls are turned off here, and on unpairing.
- **Actions without a window** (logic 4): `UserNotificationAlerts` routes `HL_CALL_ANSWER` and `HL_CALL_REJECT` to
  `MacCalls.handleNotification`, which sends the command through the same controller as the panel (same locking, E5
  and problems); "Answer" opens the in-call panel even during a Focus; a click on the notification brings the panel
  back (after Ignore) unless a Focus is still on.
- **Missed calls (CALL-04 API 4)**: from `log_new` of a new missed entry, or from the idle `state` with
  `end_reason = missed` when the phone has no call log (flow A); identifier `call-missed:<pair_id>:<entry_id>` (flow A
  `…:<call_id>`), thread `calls:<pair_id>`, body "Missed call · 2:05 PM" (· SIM label), default sound, category
  `HL_CALL_MISSED` with the "Message" text action only when there is a number and the phone can send SMS (E10);
  `call.notify` off → none (E8); entries from `log_sync` never notify; `call_missed_notified` bench line. "Message"
  sends the SMS at once through the SMS engine to the call's SIM (empty text ignored) and marks the entry seen; a
  click opens the Messages window on its Calls item and marks the entry seen; opening the call list removes the
  pair's missed-call notifications.
- **Declarations**: `macOS/Info.plist` `NSUserActivityTypes` gained `INStartCallIntent`; `macOS/HandLive.entitlements`
  gained `com.apple.developer.usernotifications.time-sensitive` next to the communication notifications entitlement.
- Posting a missed call and removing notifications by rule now go through `CallNotificationCenter`, shared with the
  iPhone/iPad app.

## Commits (handlive-apple)

| Hash | Subject |
|------|---------|
| c89df67 | feat(macos): post the incoming and missed call notifications and route their actions |
| 9ce8741 | feat(macos): declare INStartCallIntent and time-sensitive notifications for calls |
| fb55036 | refactor(macos): remove call notifications through the shared call filter |
| 92b0992 | refactor(apple): post missed calls and remove call notifications through one shared helper |

The content, categories and filters themselves came with 2b706da and c9896f2 (`phase-03-M3.1.md`); the app-model tests
with 6e8c685.

## Files

`Packages/HLMacUI/Sources/HLMacUI/{CallNotifier,ClipboardAlerts,MacCalls+Alerts,MacCalls+Actions}.swift`,
`Packages/HLCalls/Sources/HLCallNotifications/{CallNotificationBuilder,CallNotificationContent,CallNotificationKeys,
CallNotificationFilter,CallNotificationCenter}.swift`, `Packages/HLMacUI/Tests/HLMacUITests/{TestSupport,
AppModelCallsTests}.swift`, `macOS/Info.plist`, `macOS/HandLive.entitlements`, `project.yml`.

## Tests

```
HLCalls   HLCallNotificationsTests: ✔ Test run with 13 tests in 2 suites passed after 0.024 seconds.
            content, levels and schema (`call-notification.schema.json`), titles, missed-call identifiers and
            threads, Message only with a number and SMS, categories and actions, userInfo round trip and responses,
            removal filters (generic pushes included)
HLMacUI   ✔ Test run with 41 tests in 7 suites passed after 2.095 seconds.
            AppModelCallsTests: ringing → panel + passive notification, answered → only the in-call panel; Focus on →
            time-sensitive notification, no panel, no ring; Focus unreadable → passive; notify off → nothing but the
            menu; Answer from the notification during a Focus; flow A missed call with and without Message
```

CI run 36301604773 (8e1311b): success, including `Build app macOS` — `** BUILD SUCCEEDED **`.
**Final head 219854d: CI run 36303066286 — success** (HLProtocol 64, HLCrypto 46, HLTransport 99, HLDesignSystem 24,
HLLocalization 9, HLAppCore 78, HLSMS 10 + 27, HLSMSUI 11, HLCalls 13 + 14, HLMacUI 41, HLiOSUI 23 tests; "Found 0
violations, 0 serious in 362 files"; both app builds `** BUILD SUCCEEDED **`).

## Spec deviations and proposals

1. `06-call-control.md` CALL-01 "Special requirements" lists the time-sensitive entitlement for I-APP only; on macOS
   12+ a `.timeSensitive` notification without `com.apple.developer.usernotifications.time-sensitive` is delivered as
   active and does not break through a Focus, so the Mac needs it too (added). Proposal: name it for M-APP as well.
2. One category, `HL_CALL_INCOMING_MAC`, always carries both "Answer" and "Decline" (API 7 table); when `controls`
   forbid one (for example `ANSWER_PHONE_CALLS` missing), choosing it does nothing because the controller refuses a
   command `controls` do not allow. Proposal: a second category without actions for calls whose `controls` allow
   nothing, or accept.
3. A late or repeated post keeps the same identifier; the time-sensitive variant plays the default sound (the level
   alone is silent on macOS). Proposal: say in API 7 that the Focus variant has `sound = .default`.

## Pending manual checks

- Signed Mac build with Communication Notifications and Time Sensitive Notifications: the avatar and caller in the
  banner, the notification breaking through a Focus that allows the caller (and filtered when it does not).
- Passive notification in Notification Center while the panel shows, with no banner and no sound.
- Answer and Decline from the banner without a window opening; removal when the phone answers or the caller hangs up.
- Missed-call notification ≤ 1.5 s after the call ends (`call_missed_notified`), "Message" sent through the phone,
  one notification per missed call.

Status: DONE
Summary: The Mac posts the incoming call as an INStartCallIntent communication notification (passive with the panel, time-sensitive during a Focus), removes it when the call stops ringing, handles Answer and Decline without a window, and notifies missed calls with Message.
Concerns/Blockers: Real-device checks with a signed build and the Android app remain.
