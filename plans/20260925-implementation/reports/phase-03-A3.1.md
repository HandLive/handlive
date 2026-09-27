# Phase 3 — A3.1 [android]: calls on the phone

Card A3.1 of `phase-03-cuoc-goi.md`: CALL-01…04 on Android in the new module `android/feature/call` — the call context
from the public call state APIs and the `PHONE_STATE` broadcast, `call_event/state` per session, `answer`, `reject` and
`end` through `TelecomManager` (no `InCallService`, C12), the call log (`log_sync`, `log_new`) — the `features.call`
capability, SET-01 part B for the call permissions, SET-02 field 10 and the `HLBENCH/1` call events. Branch
`feat/phase-03-calls` of handlive-android, pushed; CI `ci-android` green (see Tests). One handlive-shared commit
(catalog, below). Tested with fakes of Telephony, Telecom and the call log, and with Robolectric for the Android
adapters; no device or emulator here.

## What was done

- **Protocol (`core/protocol`)** — the `call_event` bodies of 06-call-control: `state` (every field required, nullable
  ones written as `null`), `controls`, `action`, `log_sync` + its page, the shared `entry`, `log_new`; the ops, enums
  and the `details.reason` values. Every JSON example of CALL-01…04 round-trips byte for byte.
- **Capability (`feature/connection`)** — `features.call` = `enabled` (`feature.call` and telephony), `can_answer` =
  `can_end` = `ANSWER_PHONE_CALLS`, `caller_id` = `READ_CALL_LOG`; `READ_PHONE_STATE`, `READ_CALL_LOG`,
  `ANSWER_PHONE_CALLS`, `READ_CONTACTS` in `permissions_missing` while calls are on (each permission once, in the order
  of the SET-01 API 2 table, SMS and calls together). A permission result, the switch or the SIMs recompute it and send
  `capability/update`; calls are effective only with `READ_PHONE_STATE` (already in `EffectiveFeatures`).
- **The call context (`context/`)** — `CallTracker` fed one event at a time on the A-CALL thread: the default listener
  is the only source of the state (`IDLE → RINGING` incoming, `IDLE → OFFHOOK` outgoing, `RINGING → OFFHOOK`
  `answered_at`, `OFFHOOK → RINGING` waiting (E9), `→ IDLE` with `end_reason` `ended` / `rejected` (the "declined by
  HandLive" flag, 3 s) / `missed`); the first report after (re)registration rebuilds the context (E8: `unknown` when
  `OFFHOOK`). `PHONE_STATE` copies only set numbers: the copy with `EXTRA_INCOMING_NUMBER` sets the main number, or the
  waiting number while a call waits; a copy that arrives before its state is held 2 s (API 3 logic 4); an empty number
  → `restricted`, and two ringing copies without the key while `READ_CALL_LOG` is granted → `restricted` too (see
  deviation 1); `READ_CALL_LOG` missing → `number = null`, `presentation = unknown` (E2). A late number re-sends the
  state with the same `call_id` (E10). `sub_id` = the only per-SIM listener reporting the new state within 500 ms;
  `sim_label` = the SIM's display name only with more than one active SIM (`SimFinder`). Numbers in E.164 for the SIM's
  country through the platform's libphonenumber, names through `PhoneLookup` behind a 200-number LRU cache (dropped when
  the contacts change). Ended contexts stay 60 s in `RecentCalls` for the call log.
- **`call_event/state` (`CallBroadcaster`)** — one envelope per session with calls in effect: `controls` per client
  (`answer` only for a Mac, all per `ANSWER_PHONE_CALLS`; `hold`/`dtmf`/`mute` `unavailable` until HFP exists),
  `hfp_connected = false`, `audio_on = phone`; sent only when a field differs from the version that session last got;
  a session on which calls become effective gets the current call (E8); an ended call only goes where it was seen, and
  its `end_reason` correction once more. A single queue on the A-CALL thread processes every event to its end, so a
  client never gets an older state after a newer one. All emitted states pass `call_event-state.schema.json` (with its
  consistency rules).
- **`call_event/action` (`CallActions`)** — checks in the order of the error table: `FEATURE_DISABLED`, `BAD_REQUEST`,
  `CALL_HFP_REQUIRED` (`details.action`, for `hold`, `unhold`, `dtmf`, `mute`, even without a call), `CALL_NOT_FOUND`
  (no context, another `call_id`, a recently ended one, or `endCall()` false on an idle phone), `PERMISSION_MISSING`
  (`details.permission` = `android.permission.ANSWER_PHONE_CALLS`, also on a `SecurityException`, which re-sends the
  capability), `CALL_ACTION_NOT_ALLOWED` (`details.state` + `reason`: `waiting`, `state` (wrong state or another command
  within 3 s), `platform` (`answer` from iPhone/iPad), `system` (`endCall()` false while in a call, E9)); then
  `acceptRingingCall()` (the `audio` kept for call audio) or `endCall()` (`reject` sets the flag first) and the `ack`
  as soon as Telecom returns; `INTERNAL` for any other failure. A repeated `id` gets its first `ack`.
- **Call log (`log/`)** — `log_sync`: `feature.call` → `READ_CALL_LOG` → `limit` 1–500 → cursor `b64u({"v":1,"id"})`
  (unreadable, another version or beyond the largest `_ID` → first sync with `reset`); first sync from the smallest
  `_ID` of the 500 newest entries of 90 days; `limit + 1` rows for `has_more`; pages close at 180 KiB; unknown `TYPE`s
  skipped with the cursor past them; `sub_id` from the phone account (API 30+); names from `PhoneLookup` (cached per
  page) else `CACHED_NAME`; provider errors → `INTERNAL`. `log_new`: a `ContentObserver` on `CallLog.Calls` (100 ms
  coalescing), `last_calllog_id` from the largest `_ID` at registration, lowered after deletions; each new entry goes to
  every session with calls in effect with the `call_id` of the recently ended context it matches (5 s, direction,
  number); a `missed` context whose entry says declined, blocked or answered elsewhere gets one corrected `idle` state.
- **Android side (`system/`, `CallFeature`)** — `TelephonyCallback.CallStateListener` (API 31+) or
  `PhoneStateListener(executor)` (API 29–30), default and per SIM, re-registered when the SIMs change; the
  `ACTION_PHONE_STATE_CHANGED` receiver registered at runtime; all of it only while calls are on with
  `READ_PHONE_STATE` and the service runs, the call log observer with `READ_CALL_LOG`, the contacts observer with
  `READ_CONTACTS`; a refused registration re-reads the permissions. `AndroidTelecom` (deprecated methods, C12),
  `ContentResolverCallLog` (the `LIMIT_PARAM_KEY` queries), `PhoneAccountSubIds`, `DirectorySimLabels`. The manifest of
  the module declares `READ_PHONE_STATE`, `READ_CALL_LOG`, `ANSWER_PHONE_CALLS`, `READ_CONTACTS`.
- **UI (app)** — SET-02 field 10: the "Calls" switch in Settings with its status ("Needs permission" / "Permission
  denied" / "Not supported on this phone") and "Grant Permission" or "Open Settings"; turning it on with permissions
  missing opens the calls PermissionPrimer (the design system's call primer body, one "Continue") and then one
  `RequestMultiplePermissions` for the missing ones, remembered in `perm.requested`; the Calls card in Permissions &
  Background; device details show "Calls": On, Off, "Off on <device>" or "Missing permission on the phone" (SET-02 field
  24). The primer is titled "See Calls on Your Mac and iPhone" (`permission.calls_primer_title`). A client refused with
  `PERMISSION_MISSING` for a call permission makes the phone post the SET-01 field 17 suggestion "<device> needs call
  permission on this phone — tap to allow" (`notification.permission_call`, channel `permission`, at most once per 24 h,
  nothing while notifications are off); tapping it opens the calls primer (`CallPermissionNotifier`,
  `OpenRequest.CALL_PERMISSION`). The SMS code paths were generalized for this (`FeatureAccess`,
  `PermissionPrimerRoute`, one pair of settings actions for both telephony features, `OpenRequest` for notification
  deep links).
- **Privacy** — the module writes no log at all (a source guard test fails on `Log`, `println`, `printStackTrace`,
  `System.out`, Timber); the bench lines carry ids, states, `sub_id`s and codes only (tested: no number, name or SIM
  label).
- **HLBENCH/1 (debug builds)** — the Android rows of T3.1: `call_changed` (`os` = wall clock taken on entry of the
  listener callback or the broadcast receiver; `trigger` listener/broadcast/calllog; `number` known/none, `sub`, `end`;
  only for changes the clients can see), `call_state_sent` (`env`, `via`, `reason` change/session),
  `call_action_received`, `call_action_ack_sent` (`ok`, `code`); `call_push_sent` is in A3.2.

## Commits (handlive-android, branch `feat/phase-03-calls`)

| Hash | Subject |
|------|---------|
| 00ec3ff | feat(android): add the call_event messages of group 6 and the call push reasons (the reasons serve A3.2) |
| 7fa7824 | test(android): round-trip the call_event examples of 06-call-control |
| 31a0792 | feat(android): advertise calls with their permissions in the capability |
| bab6f65 | test(android): check the calls capability and its missing permissions |
| c3239fe | build(android): add the feature/call module with the call permissions |
| d0cade0 | feat(android): track the call context from the call state listeners and the PHONE_STATE broadcast |
| 3b271bb | feat(android): page the call log with its cursor and read the new call log rows |
| 142b32b | feat(android): send call_event/state per session and answer, decline and end calls through Telecom (also `CallPushes`, `OfflineCallDelivery` of A3.2) |
| 3b8cae1 | feat(android): run the call listeners, the PHONE_STATE receiver and the call log observer in the service |
| 9a39b67 | test(android): cover the call context state machine, waiting calls, late numbers and SIM labels |
| f6af824 | test(android): cover call states per session, the call actions and each of their errors |
| a27877c | test(android): cover call log paging and log_new, and what goes to clients without a session (also `CallPushTest` of A3.2) |
| e7320f2 | test(android): validate the emitted call_event messages and acks against the shared schemas |
| baf780e | docs(android): describe the capability and the client audio without plan phases |
| 0890d8e | refactor(android): count a call context as changed only when clients would see it |
| 465d2a8 | feat(android): write the call events of the benchmark in debug builds |
| 02f938c | test(android): cover the call bench events and keep call data out of every log |
| e62f81a | refactor(android): read the permissions and run the primer of any telephony feature |
| d4fdb55 | feat(android): turn calls on with their permission primer and show their status |
| 86fd8f1 | test(android): cover the calls card, its primer and their texts at 200 % |
| a673b01 | feat(android): show calls per paired device with the reason they are off |
| 66e2c35 | test(android): cover the calls availability of paired devices |
| 298c7e0 | docs(android): describe the calls module, the call pushes and handlive.db version 3 (both cards) |
| 142c111 | fix(android): keep following the calls capability when a system service refuses a listener |
| b89817f | refactor(android): switch and grant the telephony features through one pair of settings actions |
| 2535e2c | refactor(android): name the screens a notification opens in one place, the calls primer included |
| 4cbdfbe | test(android): run the call log queries, the PHONE_STATE receiver, the call state listeners and the number lookups on the platform |
| 5c6a248 | test(android): check the call listeners, the call log and Telecom on a real phone |
| 0fd14ef | feat(android): title the calls primer and suggest the call permission a client needed |
| ba089dc | test(android): cover the suggestion of a missing call permission |

All pushed (`origin/feat/phase-03-calls` = ba089dc); the A3.2 commits are listed in `phase-03-A3.2.md`.

handlive-shared, branch `feat/phase-03-calls`: **cc9bc2f** feat(shared): show the missing permission reason of calls on
Android too — `pairing.reason_missing_permission` ("Missing permission on the phone", SET-02 field 24) widened to
`android` for the Calls row of a device's details (taken with the `.locks/shared` lock, released); `check_strings.py`
and `--docs`: 373 strings, 0 errors, 0 warnings. Apple and relay are unaffected (a platform added to one key).

The two Android keys of the call permission texts, `permission.calls_primer_title` and `notification.permission_call`,
were added by the shared agent (64a73dd; head 1a87a80) and are used from the generated resources (0fd14ef). No other
catalog key was missing.

## Files

- New module `feature/call` (54 files): `CallFeature`, `CallConstants`, `CallBenchTrace`; `context/` (`PhoneState`,
  `CallContext`, `CallTracker`, `CallerNumbers`, `SimFinder`, `RecentCalls`, `CallNumbers` + `NameCache`), `module/`
  (`CallModule`, `CallEvents`, `CallPushes`, `CallRequests`, `CallBroadcaster`, `CallStateView`, `CallActions`,
  `CallError`, `CallAccess` + `CallTelecom`, `CallServices`, `CallTrace`, `OfflineCallDelivery`), `log/`
  (`CallLogProvider`, `CallLogCursor`, `CallLogEntries`, `CallLogSyncEngine`, `CallLogWatcher`, `CallLogRequests`),
  `system/` (`TelephonyWatcher`, `PhoneStateReceiver`, `ContentResolverCallLog`, `UriObserver`, `SystemCallNumbers`,
  `AndroidCallSystem`, `CallPermissionNotifier`); 14 unit test classes + `testing/` fakes and harness;
  `src/androidTest/…/CallSystemDeviceTest.kt` (real phone).
- `core/protocol`: `call/CallMessages.kt`; test `call/CallMessagesTest.kt`.
- `feature/connection`: `capability/LocalCapabilityBuilder.kt`, `LocalEnvironmentReader.kt` (`AndroidPermissions.CALLS`,
  `RUNTIME`), `notification/OpenRequest.kt`; test `LocalCapabilityBuilderTest`.
- `feature/pairing`: `devices/DeviceListModel.kt` (`CallAvailability`); test `DeviceListModelTest`.
- `feature/sms`: `system/SmsPermissionNotifier.kt` (uses `OpenRequest`).
- `app`: `HandLiveApplication`, `MainActivity`, `ui/main/{MainScreen, Route, SettingsActionsImpl, SubscreenRoutes,
  TabRoutes, ResumedState, PermissionPrimerRoute}`, `ui/settings/{CallsPrimerScreen, FeatureStatus, PermissionsScreen,
  SettingsModel, SettingsScreen}`, `ui/system/FeatureAccessReader`, `ui/devices/DeviceDetailsScreen`,
  `build.gradle.kts`; tests `FeatureStatusTest`, `ScreenCatalog` (+3 screens), `UiSamples`.
- `settings.gradle.kts`, `README.md`, `README.vi.md`.

## Tests (real output)

```text
$ export JAVA_HOME=/opt/homebrew/opt/openjdk@21/libexec/openjdk.jdk/Contents/Home
$ ./gradlew testDebugUnitTest --rerun :app:testFossDebugUnitTest --rerun check   # android ba089dc, shared 1a87a80
> Task :core:protocol:testDebugUnitTest
> Task :core:crypto:testDebugUnitTest
> Task :core:strings:testDebugUnitTest
> Task :feature:connection:testDebugUnitTest
> Task :core:data:testDebugUnitTest
> Task :feature:clipboard:testDebugUnitTest
> Task :feature:call:testDebugUnitTest
> Task :feature:pairing:testDebugUnitTest
> Task :core:design:testDebugUnitTest
> Task :feature:sms:testDebugUnitTest
> Task :feature:relay:testDebugUnitTest
> Task :core:transport:testDebugUnitTest
> Task :app:testFossDebugUnitTest
BUILD SUCCESSFUL in 37s
780 actionable tasks: 26 executed, 754 up-to-date
```

Counts from the JUnit XML of that run: **607 tests, 0 failures, 0 errors, 0 skipped** — core/protocol 50,
core/crypto 44, core/data 20, core/strings 5, core/design 26, core/transport 61, feature/connection 33,
feature/pairing 47, feature/clipboard 101, feature/sms 68, feature/relay 41, feature/call 82, app (foss) 29. `check`
also ran ktlint, detekt and Android Lint of every module (green).

The call classes of this card: `CallTrackerTest` 13, `CallActionTest` 14, `CallLogSyncTest` 10, `CallStateTest` 9,
`CallLogNewTest` 7, `CallMessageSchemaTest` 4 (every emitted `call_event` message and `ack` against
`call_event-*.schema.json`), `CallBenchTraceTest` 3, `CallLogPrivacyTest` 1 (no log call in the module's sources), and
on Robolectric `ContentResolverCallLogTest` 2, `PhoneStateReceiverTest` 2, `SystemCallNumbersTest` 2,
`TelephonyWatcherTest` 2, `CallPermissionNotifierTest` 2; `CallMessagesTest` 8 (core/protocol),
`LocalCapabilityBuilderTest` 8, `DeviceListModelTest` 5, `FeatureStatusTest` 4, and the screen catalog loops
(`ScreenSemanticsTest`, `ScreenTextFitTest`: en/vi, 200 % text, 320 dp) with the Calls settings, Permissions and primer
screens.

```text
$ ./gradlew :feature:call:assembleDebugAndroidTest
BUILD SUCCESSFUL in 1s
```

The device test `CallSystemDeviceTest` (listener reports the idle phone, call log queries with `limit`, Telecom idle)
builds; it was not run (no phone here).

CI and commit policy:

```text
$ gh run list -R HandLive/handlive-android --branch feat/phase-03-calls --limit 1
completed  success  test(android): cover the suggestion of a missing call permission  ci-android  feat/phase-03-calls  push  36298541328  5m29s
$ .githooks/check-commits.sh origin/main..HEAD
commit sạch: đã kiểm 39 commit
```

## Spec deviations and proposals (hub not edited)

1. **`restricted` from two copies without the number key** (`06-call-control.md` CALL-01 API 3 logic 3): in AOSP's
   `TelephonyRegistry.broadcastCallStateChanged` the copy for `READ_CALL_LOG` holders gets `EXTRA_INCOMING_NUMBER` only
   when the number is not empty, so "the key present with an empty value" may never arrive for a withheld caller.
   A-CALL also treats two ringing copies without the key, while `READ_CALL_LOG` is granted, as the withheld case
   (`presentation = restricted`, the push leaves then). Proposal: add this to logic 3; check on devices.
2. **Numbers from `OFFHOOK` copies** (CALL-01 API 3 logic 2, "otherwise set `number`"): used only for an `incoming`
   context whose ringing copy never came; never for `outgoing` or `unknown` contexts, whose number stays `null` as the
   `number` row says — although AOSP's `OFFHOOK` copy may carry the dialed number. Proposal: decide whether outgoing
   calls should take it (the schema rule "`outgoing` → `presentation = unknown`" would change).
3. **`sub_id` is found only for the transition that created the context** (CALL-01 API 2 logic 3 names no
   transition), not for a waiting call's SIM.
4. **First `log_sync` with no entry in the 90-day window but older ones** (CALL-04 API 1 logic 3 only covers an empty
   call log): the cursor is the largest existing `_ID`, so the next sync returns only new entries, not the old ones.
   Proposal: state it.
5. **Name cache of `log_sync`** (CALL-04 API 1 logic 7, "scoped to one sync"): scoped to one page (one `ack`).
6. **`display_name` of an entry** (CALL-04 shared object): `CACHED_NAME` is also used when `READ_CONTACTS` is granted
   but `PhoneLookup` finds nothing (step 4 "falling back to `CACHED_NAME`"). Proposal: say so in the object table.
7. **Symbol of the calls primer**: the design system maps calls to the Material `call` symbol, which `core/design` does
   not bundle yet (adding it means adding the Material Symbols asset); the primer uses `smartphone` like the SMS one.
   Proposal: add `call`, `call_end`, `phone_missed` to `core/design` with the Phase 4 UI.
8. **SET-01 step 8** (the feature list opened after the first pairing) is not done by the app (unchanged from
   Phases 1–2); the Calls card lives in Settings › Permissions & Background.
9. **The Calls switch has no one-line description** (SET-02 usability rule): the spec gives none (as for SMS).
10. **`call_changed` only for visible changes**: a `PHONE_STATE` copy that changes nothing a client sees (a copy without
    the number key) writes no bench line and sends nothing.

## Pending manual checks

- Real calls between two SIMs of a dual-SIM phone: `sub_id` and `sim_label` (C5), per-SIM listener behavior on Pixel,
  Samsung and Xiaomi.
- `acceptRingingCall()` and `endCall()` on Pixel and Samsung (OEM blocks, the emergency call refusal of E9).
- The two `PHONE_STATE` copies (with and without `EXTRA_INCOMING_NUMBER`), their order, and a withheld caller.
- Latency targets with `shared/tools/bench/call_latency.py`: state < 200 ms on the LAN; answer < 500 ms at the 95th
  percentile (click on the Mac → `state = offhook` back on the Mac, click → `OFFHOOK` on the phone also reported);
  `log_new` ≤ 1 s after the call ends; the name lookup ≤ 30 ms.
- Call waiting (E9) on devices; the `end_reason` correction for a call declined on the phone and one answered on
  another device.
- TalkBack on the Calls switch, card and primer; 200 % text on devices (the text-fit test covers en/vi at 200 % and a
  320 dp phone); the system permission dialog groups (Phone, Call logs, Contacts) in en and vi.
- Android 10 (API 29) and 11 (API 30) paths: `PhoneStateListener`, `getSubscriptionId(PhoneAccountHandle)`.
- `./gradlew :feature:call:connectedDebugAndroidTest` on a phone with a SIM and no call (`CallSystemDeviceTest`).
- The call permission suggestion from a Mac refused with `PERMISSION_MISSING`, and its tap opening the calls primer.

Status: DONE_WITH_CONCERNS
Summary: Calls on the phone are implemented in the new module feature/call (call context from the listeners and the PHONE_STATE broadcast, call_event/state per session, answer/reject/end through Telecom with every error code, log_sync and log_new, the features.call capability, the call permissions primer and suggestion, the Calls switch, the call bench events); 607 unit tests and the full check are green locally and in CI (run 36298541328).
Concerns/Blockers: Nothing ran on a phone: the two PHONE_STATE copies and withheld callers, the per-SIM listeners, acceptRingingCall/endCall on OEM builds, the Android 10–11 paths, the latency targets and CallSystemDeviceTest are pending on devices. Deviations 1 and 2 (withheld detection, numbers of outgoing calls) need a spec decision; the calls primer uses the smartphone symbol until core/design bundles `call`.
