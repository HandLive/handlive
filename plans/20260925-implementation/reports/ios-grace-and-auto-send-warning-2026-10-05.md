# iPhone background grace and the Auto-Send switch warning (2026-10-05)

Owner decisions of 14:05 on the open items of the morning:

> 1. Hỗ trợ tiếp cận là chuẩn rồi · 2. tôi muốn có chạy ngầm · 3. nên có cảnh báo

1. Keep "Hỗ trợ tiếp cận" and the current restricted-setting strings; One UI's "Hỗ trợ" is not followed. No change.
2. iPhone in the background: option (a) of `reports/ios-background-disconnect-2026-10-05.md`, a grace of up to 25 s.
3. Android Auto-Send switch: a warning before it turns off a service that never came on.

Run by the forum team (lead, BA, Android, Apple, QA, BA reviewer, pentester). Every task went through BA, tester and
pentester review.

## What changed

**Contract.**
- handlive-shared#5 (`e089f53`): three Android-only strings.
- Hub (`d2cbfb7`, `b8005fe`, `82af3cb`, `3ea36cb`):
  - SET-02 field 2, field 39 (action sheet), E10, step 2; WEB-01 E3 notes the same pattern for `feature.web`.
  - `IOS_BACKGROUND_GRACE` = 25 s (00-common-specs).
  - CONN-02 E3, step 8, S8, API 4, CONN-01; CLIP-04 E1/E2; 04-clipboard; WEB-05; SMS-04 and CALL-02 B2.
  - SET-01 field 15 and SET-02 field 39 share one meaning of "on": HandLive is in the list of enabled Accessibility
    services.

**Android** (android #7, `8093903`).
- `HLActionSheet` from the Auto-Send row when the switch is on but the status is `needs_accessibility`:
  - Turn On: consent, field 14 or Accessibility.
  - Send Manually: off.
  - Cancel, Back or a tap outside: nothing changes.
- The sheet survives rotation and closes itself once the service is on or the switch changes elsewhere.

**iOS** (apple #4).
- `BackgroundTaskProviding` and `IOSAppModel+Background`.
- One hold counter shared by the grace and the notification actions (quick reply, decline, call back), with close and
  reopen ordered on one queue: a return after `bye` waits for the close, so there is never a second session for the same
  pair (4409).
- A clip received while held is written only if `changeCount` has not moved since the reference. The reference moves
  after each write or clear by HandLive.
- Local notifications for SMS and calls follow the NSE rules: locked phone → generic text, `sms.preview` respected, no
  new strings.
- `.inactive` ignored; a session lost while held is not reopened in the background.

## Verification

- Android: all module unit tests, detekt, ktlint, lint, assemble green (924 tests); CI green; mutation checks turn the
  new tests red. Manual on the API 35 emulator, en and vi:
  - the sheet text;
  - Cancel keeps "Auto-send isn't on yet";
  - Turn On → field 14 Continue;
  - Send Manually → off;
  - the emulator was put back.
- iOS: `HLTests-all` on macOS 616 tests, 0 failures (19 new, a hanging `bye` included: the task always ends, the close is awaited at most 3 s); the iOS app target compiles for the simulator;
  `swiftlint --strict` clean; `generate-strings.py --check` OK.
- Docs: `validate_design_docs.py` and `check_bilingual_docs.py` problems=0.

## Limits, said plainly

- 25 s is the most a generic iOS app gets. There is no background mode for a sync app, and PushKit is out by decision C7.
- Longer away time gives SMS and call alerts only, through the relay and APNs (gate G2: relay host, paid Apple Developer
  team). The clipboard never syncs in the background.
- Not yet checked on a real iPhone:
  - pasteboard writes and the LAN socket during the grace;
  - a locked phone and Low Power Mode;
  - the time iOS really grants (`grace_begin`/`grace_end` logs are in place).

## Unresolved questions

- Real-iPhone check of the grace (owner's iPhone, about 10 minutes).
- Relay host and paid Apple Developer team for option (c), when the owner wants alerts while away.

Status: DONE_WITH_CONCERNS
Summary: The switch warning is merged and verified on the emulator; the iPhone grace is merged with unit tests only.
Concerns/Blockers: real-device behaviour of the iOS grace is unverified.
