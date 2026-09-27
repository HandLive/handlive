# Phase 3 — M3.3 [macOS]: Decline with Message, Calls in the Messages window, Settings › Calls, menu bar items

Card M3.3 of `phase-03-cuoc-goi.md`. Repository handlive-apple, branch `feat/phase-03-calls`. Builds on the call
controller, call log and call list of `phase-03-M3.1.md` and the notifications of `phase-03-M3.2.md`.

## What was done

- **"Decline with Message…"** (CALL-02 fields 5–7, API 5): offered only when `controls.reject`, a number, SMS in
  effect and `features.sms.can_send`; the panel lists the `call.quick_replies` templates and "Custom Message…" (one
  line of at most 160 characters, "Send", nothing sent when empty after trimming). Choosing one declines at once; on the successful `ack` (or
  the `idle` state if the ack never came) the reply joins the SMS outbox for the caller's number through the call's
  `sub_id`, attached to the existing conversation with that number when there is one (SMS-04, Query of CALL-02);
  when the call was answered first, nothing is sent and the panel says "The call was answered, so the message wasn't
  sent" (E9). Quick replies are never logged.
- **Quick replies** (`call.quick_replies`, 0.9.5): on first use the two default templates in the language of the
  moment ("I'll call you back later", "I'm in a meeting"), then user data (0.12.4).
- **Messages window › Calls** (CALL-04 field 1): a Calls item above the conversations in the sidebar with the unseen
  missed-call badge (VoiceOver "1 missed call" / "3 missed calls", plural string), the call list as its detail
  (`CallListView`: type symbol, missed calls in `text-red`, bold until seen, SIM label on dual-SIM phones, duration,
  time; the call log permission hint; "No Calls Yet"), window subtitle "Calls"; while the list shows, the pair's
  missed calls are seen and their notifications removed (step 12). A click on a missed-call notification opens it.
- **Settings › Calls** (SET-02 fields 10–12, 33; CALL-04 fields 11–12): the "Calls" switch with the reason calls do
  not work with the phone (off on either side, `READ_PHONE_STATE` missing), "Call Notifications" and "Ring on Mac"
  checkboxes (dimmed, never hidden, while Calls is off), the Focus hint with "Open System Settings" when "Ring on Mac"
  is on but HandLive may not read the Focus status, "Last synced: 5 minutes ago", the call log permission hint, and
  the "Quick Replies" list: add ("Add Quick Reply", at most 6), edit (160 characters), remove ("Remove Quick Reply"),
  reorder by dragging, footer "Up to 6 replies of 160 characters. Choose one when you decline a call on this Mac."
  "Calls" travels in the capability; "Call Notifications" and "Ring on Mac" are local on the Mac.
- **Devices** (PAIR-02 fields 8–9): a Calls row with its reason; the missing call permissions of the phone
  (`READ_CALL_LOG`, `ANSWER_PHONE_CALLS`, and `READ_PHONE_STATE`/`READ_CONTACTS` while calls are on) with "View
  Instructions…" opening "Grant Call Permission on Your Phone".
- **Menu bar menu** (MenuBarMenu README, CALL-04 API 4 logic 5): the ringing call with "Answer"/"Decline" as
  `controls` allow — also after "Ignore", while a Focus hides the panel, and with `call.notify` off (E3) — and the last
  three missed calls among the recent items ("Missed call · 2:05 PM", · SIM label), each opening the call list.
- **Shared pieces**: `MessagesModel.callsItem` lets the sidebar select the Calls item; the conversation list can carry
  rows above the conversations; `SmsEngine.send(text:toNumber:subId:)` finds the conversation of a number.

## Commits (handlive-apple)

| Hash | Subject |
|------|---------|
| d319411 | feat(apple): send an SMS to a number in its existing conversation |
| 72ff15e | feat(apple): let the Mac sidebar select a Calls item in the Messages model |
| d4f1f75 | feat(apple): let the conversation list carry rows above the conversations |
| 8322951 | feat(macos): add the Calls item to the Messages window sidebar |
| c5338ae | feat(macos): add the Calls settings pane with the quick replies |
| b114953 | feat(macos): show calls in the phone's details with the call permission instructions |
| f0229cf | feat(macos): list the ringing call and recent missed calls in the menu bar menu |
| 29a6770 | test(macos): test why calls don't work with the phone and which permissions are calls' |

The quick-reply logic of the controller came with 7ddc661 and b15b93d (`phase-03-M3.1.md`).

## Files

`Packages/HLSMS/Sources/HLSMS/SmsEngine+Send.swift`, `Packages/HLSMS/Tests/HLSMSTests/SmsEngineSendTests.swift`,
`Packages/HLSMSUI/Sources/HLSMSUI/{MessagesModel,ThreadListView}.swift`,
`Packages/HLMacUI/Sources/HLMacUI/{MessagesWindowViews,MessagesWindowController,CallsSettingsPane,SettingsView,
MacSystem,DevicesSettingsPane,MenuBarViews,MenuBarCallItems,CallPanelView,CallPanelModel,MacCalls+Actions}.swift`,
`Packages/HLMacUI/Tests/HLMacUITests/AppModelCallsTests.swift`.

## Tests

```
HLSMS     ✔ Test run with 27 tests in 5 suites passed after 0.450 seconds.   (send to a number joins its conversation)
HLSMSUI   ✔ Test run with 11 tests in 2 suites passed after 0.152 seconds.
HLAppCore ✔ Test run with 78 tests in 16 suites passed after 2.508 seconds.   (quick reply on ack, on idle, E9)
HLMacUI   ✔ Test run with 41 tests in 7 suites passed after 2.095 seconds.
            Decline with Message puts the reply into sms_outbox for the caller; quick replies keep the user's list
            and "Ring on Mac" asks for the Focus status once; calls off removes every call notification; the reasons
            calls don't work; which permissions are calls'
```

CI run 36301604773 (8e1311b): success, `Build app macOS` — `** BUILD SUCCEEDED **`.
**Final head 219854d: CI run 36303066286 — success** (HLProtocol 64, HLCrypto 46, HLTransport 99, HLDesignSystem 24,
HLLocalization 9, HLAppCore 78, HLSMS 10 + 27, HLSMSUI 11, HLCalls 13 + 14, HLMacUI 41, HLiOSUI 23 tests; "Found 0
violations, 0 serious in 362 files"; both app builds `** BUILD SUCCEEDED **`).

## Spec deviations and proposals

1. `01-setup-settings.md` SET-02 lists "Call Notifications" and "Ring on Mac" as checkboxes under the switch; they
   are shown dimmed while "Calls" is off (Toggle README: never hidden).
2. The menu bar keeps a missed call among the recent items with the notification's body text (coordinator decision);
   the list holds the last three and empties when the call list is opened. `MenuBarMenu` README does not say how many;
   proposal: write "the last three" there.
3. "Custom Message…" is cut at 160 characters like a template (CALL-02 field 7, string(160)), although an SMS may
   hold 1,600; kept as specified.

## Pending manual checks

- With the Android app: Decline with Message sends the SMS through the call's SIM and the reply shows in the
  conversation; E9 when the call is answered on the phone first.
- Settings › Calls on macOS 13–15 and 26 (grouped form), reordering by drag, VoiceOver on the list rows.
- Menu bar menu with a ringing call after Ignore and during a Focus; missed calls in the recent items.

Status: DONE
Summary: Decline with Message with editable quick replies, the Calls item and call list in the Messages window, the Settings Calls pane, the call rows in Devices and the menu bar items are done, tested and green on CI.
Concerns/Blockers: Real-device checks with the Android app remain.
