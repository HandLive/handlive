# Phase 3 — spec sync 3: call notifications, the Mac panel and the deployment guide as built

Applies the coordinator's decisions 1–18, taken from the "Spec deviations and proposals" of `phase-03-M3.1.md`,
`phase-03-M3.2.md`, `phase-03-M3.3.md` and `phase-03-I3.1.md`, in both languages. For the deployment guide I read these
files in `apple/` (branch `feat/phase-03-calls`, head 219854d), without changing them:

- `macOS/HandLive.entitlements`, `iOS/HandLive.entitlements`, `iOS/NotificationService.entitlements`;
- `macOS/Info.plist`, `iOS/Info.plist`, `iOS/NotificationService-Info.plist`;
- `project.yml`.

Hub `main`, pushed (`e8a096c..13df812`); hub CI `ci-docs` run 36304451349 on 13df812 green. No nested repository was edited.

## Decisions applied

| # | Decision | Where (EN + VI) |
|---|----------|-----------------|
| 1 | No `com.apple.developer.focus-status`: reading the Focus status needs Communication Notifications, the user's permission and `NSFocusStatusUsageDescription`. The Mac needs Time Sensitive Notifications too, or a `.timeSensitive` notification arrives as active | `06-call-control` §6.1.1 special requirements, CALL-01 API 5 logic 3; also `design-system/3-platforms/01-macos` (see 1 below) |
| 2 | Synthesized or first-party ringtone played with `NSSound` | CALL-01 API 5 Method |
| 3 | Answered from the Mac notification during a Focus → in-call panel; other in-call panels stay hidden; the Focus variant has `sound = .default` | CALL-01 E4; API 7 (new `sound` row, Response); CALL-03 step 1 note |
| 4 | `HL_CALL_INCOMING_MAC` only when `controls.answer` and `controls.reject` are both true; otherwise no category, and the panel offers what `controls` allow | CALL-01 API 7 `categoryIdentifier` row; field 15 aligned |
| 5 | `HL_CALL_INCOMING` ("Decline") only when `controls.reject` is true | CALL-01 API 6 table; field 11 and step 9 aligned |
| 6 | Late push (> 60 s) at `interruptionLevel = .active` | CALL-01 E7; API 6 table and logic 2 |
| 7 | Stale-notification removal covers generic notifications (no `started_at`): the app opens them with `K_push`, and uses the envelope `ts` when the envelope is refused as older than 24 h | CALL-01 API 6 logic 4 |
| 8 | Notification decline: `CALL_ACTION_NOT_ALLOWED` with `reason = system` removes the notification; every other error and the timeout post "Couldn't decline the call" | CALL-02 B3 |
| 9 | "Message" (`HL_CALL_SMS`) has `.authenticationRequired`; missed calls go to Notification Center only while the app is open; the Mac menu keeps the last three and empties them when the call list opens ("the last three" also in MenuBarMenu) | CALL-04 API 4 Method, logic 1, logic 5; `design-system/components/MenuBarMenu/README` |
| 10 | `sms.peer_can_send` = `features.sms.can_send` with SMS in effect at both ends; the app writes `true` only then | `00-common-specs` 0.9.5; `03-connectivity` CONN-04 step 9b; CALL-04 API 4 logic 2 and `categoryIdentifier` row |
| 11 | SMS "Reply" has `.authenticationRequired` | `05-sms` SMS-02 API 4 |
| 12 | After SMS-01, remove only the generic SMS notifications; the filter checks the envelope type | SMS-05 API 2 logic 2 |
| 13 | "Call Notifications" and "Ring on Mac" are checkboxes under Calls, dimmed (never hidden) while Calls is off | `01-setup-settings` SET-02 fields 11, 12 |
| 14 | The panel never takes focus; the keys work once it is clicked (key without activating HandLive) | `design-system/components/CallPanel/README` |
| 15 | macOS app: Communication Notifications (call notifications and Focus status), Time Sensitive Notifications, `INStartCallIntent`, `NSFocusStatusUsageDescription` from `infoplist.focus_status_usage` | `docs/deployment-guide` › macOS app |
| 16 | iOS app: Time Sensitive Notifications and `INStartCallIntent`. Extension: Communication Notifications entitlement and `IntentsSupported`, added in Phase 3 and needed by SMS too | `docs/deployment-guide` › iOS/iPadOS app (the capabilities bullet rewritten; new extension bullet) |
| 17 | G2 video also shows calls; `READ_PHONE_STATE`, `READ_CONTACTS`, `ANSWER_PHONE_CALLS` need no form | `docs/deployment-guide` › Android, G2 checklist |
| 18 | Table of `acceptRingingCall` / `endCall` per device model | `docs/deployment-guide` › Android (Pixel, Samsung: "Not tested yet") |

### Closest-correct changes and interpretations (please confirm)

1. **The same wrong key was in the design system.** `3-platforms/01-macos` (+ vi) named
   `com.apple.developer.focus-status` too. It now names the Communication Notifications capability, and the
   Time Sensitive Notifications entitlement for time-sensitive call notifications on the Mac.
2. **Decision 3 conflicted with CALL-03 step 1.** Step 1 showed the in-call panel for any `offhook`. A note now
   keeps the panel hidden during a Focus, unless the call was answered from the Mac notification. The Focus
   variant's sound is a new `sound` row in the API 7 table.
3. **Decisions 4 and 5 are also reflected in the field rows:** CALL-01 field 15 (the Mac buttons), field 11
   and step 9 (the iPhone "Decline").
4. **Decision 7:** "every `HL_CALL_INCOMING` notification" became "every incoming-call notification". Since
   decision 5, the category is optional, so removal must not depend on it.
5. **Decision 8:** B3 already listed `CALL_ACTION_NOT_ALLOWED`. It now says "any `reason`, `system` included",
   and names the errors that post the failure notification.
6. **Decision 10:** the CALL-04 API 4 `categoryIdentifier` row now also requires SMS in effect, like the copy
   and like CALL-01 field 8.
7. **Decision 12:** logic 2 used to say generic notifications "have no `userInfo`". They carry the push's `p`
   and `hl`, and the filter reads the envelope `type` from `hl`, so that phrase was corrected. This matches
   `SmsNotificationKeys.genericIdentifiers`.
8. **Decision 13** is scoped to the Mac. Per the Toggle README, checkboxes are the Mac control; iPhone uses
   switches.
9. **Decisions 15 and 16** name exactly what the Apple files configure:
   - Entitlements: macOS `com.apple.developer.usernotifications.communication`, `…time-sensitive` and
     `keychain-access-groups`. iOS app: `aps-environment` = `development` in the file, communication,
     time-sensitive, App Group `group.app.handlive`, keychain groups `$(AppIdentifierPrefix)app.handlive.ios`
     and `group.app.handlive`. Extension: communication, App Group, keychain group.
   - Info.plists: `NSUserActivityTypes` = `INSendMessageIntent`, `INStartCallIntent` (Mac and iOS app);
     `IntentsSupported` = the same two, in the extension's `NSExtensionAttributes`, extension point
     `com.apple.usernotifications.service`. The Mac also has `NSFocusStatusUsageDescription`,
     `NSLocalNetworkUsageDescription`, `NSMicrophoneUsageDescription` and `NSBonjourServices`.
   - Bundle ids from `project.yml`: `app.handlive.mac`, `app.handlive.ios`, `app.handlive.ios.nse`.
   - The guide also says which App IDs need which capability (I3.1 pending checks).
10. **Decision 18:** the table columns are device model, Android version, `acceptRingingCall()` and
    `endCall()`. The rows are "Pixel" and "Samsung", marked "Not tested yet".

## Commits (hub `main`, pushed)

| Hash | Subject |
|------|---------|
| 5a79a00 | docs(spec): keep the iPhone copy of SMS sending true only with SMS in effect |
| 57e64a4 | docs(spec): settle the call notifications on the Mac and iPhone as built |
| c3e5f1f | docs(spec): read the SMS send copy as sending with SMS in effect in the extension |
| c29f7b7 | docs(spec): unlock before an SMS reply and clear only generic SMS notifications |
| 085d6a9 | docs(spec): show the call options as checkboxes under the Calls switch |
| ce955f3 | docs(design-system): note the call panel keys, the last three missed calls and the Focus capability |
| 13df812 | docs: add the call capabilities, the G2 call video and the call control table to the deployment guide |

All seven are signed off (`Hồ Xuân Dũng <me@hxd.vn>`), have no AI attribution, and passed the hooks. Only
explicit paths were staged. `git pull --rebase` refused to run, because another agent had an uncommitted change
in `plans/20260925-implementation/reports/phase-03-S3.2.md`. I left that file untouched. A `git fetch` just
before had shown no new commit on `origin/main`, so the push was a plain fast-forward.

## Checks (real output)

```text
$ python3 tools/docs/validate_design_docs.py
files=16 leaves=66 problems=0

$ python3 tools/docs/check_bilingual_docs.py
pairs=67 missing=0 problems=0 warnings=0

$ cd shared && tools/.venv/bin/python tools/schemas/check_schemas.py   (exit 0, shared head aa689d6)
== Tổng kết
  schema hợp lệ metaschema: 45
  $ref phân giải được: 250
  enum khớp bảng spec: 43
  loc-key có trong catalog: 3
  ví dụ 00-common-specs: 6
  ngoài phạm vi S0.2 (bỏ qua): 39
  ví dụ 01–08: 215
  payload bắt tay giải từ envelope: 2
  envelope trong env_b64/hl: 39
  mẫu dương tự viết: 121
  mẫu âm bị từ chối: 235
  ví dụ catalog chuỗi giao diện: 1
  tin trong test vector: 65
  XANH: mọi kiểm tra đạt

$ cd shared && tools/.venv/bin/python tools/strings/check_strings.py --docs
  en: 393 of 393 texts found in 50 English docs
  vi: 393 of 393 texts found in 50 Vietnamese docs
== 393 strings, 0 errors, 0 warnings
OK
```

- **Both parallel shared changes have landed, and `check_schemas.py` passes with them.**
  - `26cb74c` allows `active` for a late push. Its new check reads the `interruptionLevel` rows of CALL-01
    API 6 and 7, and my API 6 row names `.active`.
  - `9631667` lets content without actions have no category.
- **Tested read-only against the current `call-notification.schema.json#/$defs/incoming`:**
  - valid: iPhone content without `HL_CALL_INCOMING` at `timeSensitive` (decision 5);
  - valid: Mac content without a category at `passive`, with an identifier (decision 4);
  - valid: a late push at `active` with no category (decision 6);
  - rejected: the Mac Focus variant with `"sound": "default"` ("Additional properties are not allowed").
- No JSON example in the specs changed.

## New or changed UI texts for the catalog

None. The texts this sync names already have keys: `call.decline_failed`, `call.incoming_body`,
`call.missed_body`, `infoplist.focus_status_usage`.

## Unresolved questions

1. **Shared follow-up:** `call-notification.schema.json#/$defs/incoming` has no `sound` property (it has
   `additionalProperties: false`), but CALL-01 API 7 now gives the Mac Focus variant `sound = .default`.
   Proposal: allow `sound` = `default` for the Mac content at `timeSensitive`, as the `missed` definition
   already allows `sound`.
2. I3.1 deviation 1, the Calls tab as a `NavigationStack` on iPad, is still undecided. Keep it, or specify a call
   detail screen first.
3. `design-system/3-platforms/02-ios-ipados` says "When the app is open, there are no notifications". CALL-04
   API 4 now posts missed calls to Notification Center only while the app is open. The design-system wording
   could say "no banners".
4. M3.3 deviation 3: "Custom Message…" is cut at 160 characters, as CALL-02 field 7 specifies. Left unchanged.
5. The deployment table (decision 18) and the entitlement bullets need the real-device and signed-build checks
   of the four reports; the owner fills the table.

Status: DONE_WITH_CONCERNS
Summary: All 18 decisions are written into 00, 01, 03, 05, 06, the design system (CallPanel, MenuBarMenu, macOS platform page) and the deployment guide, in both languages, in 7 signed commits pushed to hub main; validate_design_docs, check_bilingual_docs, check_schemas (with the shared late-push and no-category changes landed) and check_strings --docs are all green.
Concerns/Blockers: the incoming-call notification schema does not allow the `sound` that the Mac Focus variant now has (shared follow-up, unresolved question 1).
