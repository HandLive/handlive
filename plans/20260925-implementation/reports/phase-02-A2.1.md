# Phase 2 — A2.1 [android]: SMS bridge on the phone

Card A2.1 of `phase-02-sms-ios-relay.md`: SMS-01…05 on Android in the new module `android/feature/sms`, the Room
tables and settings keys it needs, the SMS capability, SET-01 part B for SMS and the phone's `HLBENCH/1` SMS events.
Branch `feat/phase-02-sms-ios-relay` of handlive-android, pushed (head `69ff48f`); CI `ci-android` green on every
finished run (last: 36225980996 on `69ff48f`, with shared at sync 1). One handlive-shared commit (catalog keys,
below).

## What was done

- **Protocol (`core/protocol`)** — the group 5 bodies of `05-sms.md`/0.7: `SmsThreadData`, `SmsMessageData`
  (`ts_sent`, `sub_id` written even when `null`, `local_id` only on the creator's copy), `sms/sync`, `sms/history`,
  `sms/new`, `sms/send` + ack data, `sms/status`, `sms/read_changed`; every example of 05-sms round-trips byte for
  byte, and what the phone emits is validated against `shared/schemas/sms-*.schema.json`.
- **Data (`core/data`)** — Room `handlive.db` version 2 with an `AutoMigration(1 → 2)` (schema `2.json`):
  `sms_observer_state` (the observer's `last_sms_id`, SMS-02 API 3) and `push_outbox` (A2.2); settings keys of 0.9.5
  already present (`feature.sms`, `perm.requested`).
- **Capability (`feature/connection`)** — `features.sms` = `enabled` (switch and telephony), `can_send`, `sims`
  (subscription id, slot, carrier label) and `default_sub_id`; `READ_SMS`, `SEND_SMS`, `READ_CONTACTS`,
  `READ_PHONE_STATE` in `permissions_missing`; a SIM change or a permission result recomputes it and sends
  `capability/update`.
- **SMS-01 `sms/sync`** — stateless cursor `b64u({"v":1,"id","t"})`; first sync walks the newest threads with a
  `page_token` `{v,m,th,o}`, catch-up pages with `{v,m,a}`; 500 messages / 180 KiB per page, `unread` entries with
  `unread_count ≥ 1`; `SMS_CURSOR_INVALID` for a bad cursor or token.
- **SMS-03 `sms/history`** — pages older than `before_ts`, a group of rows with the same date is never split;
  `SMS_THREAD_NOT_FOUND`.
- **SMS-02 observer** — `ContentObserver` on `content://sms` without `RECEIVE_SMS` (C18), 100 ms debounce, one serial
  round at a time from the persisted `last_sms_id`; drafts ignored, `pending_out` rows waited for up to 10 min;
  `sms/new` to every session with SMS effective (the creator's copy carries its `local_id`), then the unread snapshot
  diff as `sms/read_changed` (SMS-05); clients without a session are handed to the relay module (A2.2: push, relay).
- **SMS-04 sending** — `SmsManager` of the chosen `sub_id` (SIM selection logic 3), `divideMessage` +
  `sendMultipartTextMessage`, sent/delivered `PendingIntent`s with unique data URIs; `SendRegistry` keyed by
  `local_id` (1,000 entries, 24 h) so a retried `sms/send` is acknowledged again without sending twice; forward-only
  `sending → sent → delivered | failed` in `sms/status`; the Sent-box row is matched back to its `local_id`
  (API 4: same recipient and text, within 60 s of the final result). Refusals in the order of the SMS-04 error table:
  `FEATURE_DISABLED`, `PERMISSION_MISSING`, `BAD_REQUEST`, `PAYLOAD_TOO_LARGE`, `SMS_INVALID_ADDRESS`,
  `SMS_SIM_UNAVAILABLE`; radio results map to `SMS_NO_SERVICE`, `SMS_RADIO_OFF`, `SMS_LIMIT_EXCEEDED`,
  `SMS_GENERIC_FAILURE`. **All 8 `SMS_*` codes of 0.8 are produced where the specs say**, plus `INTERNAL` for a
  provider error (the session goes on).
- **SET-01 part B / SET-02 field 7 (app)** — the "SMS Messages" switch; turning it on with permissions missing opens
  the PermissionPrimer ("Use SMS on Your Mac and iPhone", the SMS body, one "Continue") and then one
  `RequestMultiplePermissions` for the missing four, recorded in `perm.requested`; the feature card in Settings and in
  Permissions & Background shows On / Off / Needs permission (+ "Grant Permission") / Permission denied (+ "Open
  Settings", E5) / Not supported on this phone. SET-01 field 17: a client refused with `PERMISSION_MISSING` makes the
  phone post "<device> needs permission to read SMS on this phone — tap to allow" on the `permission` channel, at most
  once a day; tapping it opens the SMS primer. No `sms` notification channel (decision). SET-02 field 24 / PAIR-02
  field 8: device details show SMS as On, Off, Off on <device> or Missing SMS permission on the phone.
- **HLBENCH/1 (debug builds)** — `sms_detected` (with `onchange` = the first `onChange` of the batch; the untimed
  round at start writes none), `sms_new_sent` (`via` lan/relay), `sms_send_received`, `sms_send_ack_sent`,
  `sms_radio_done` (every part), `sms_status_sent`; `sms_push_sent` comes from A2.2. Ids, boxes, states and codes
  only.

## Commits (handlive-android, branch `feat/phase-02-sms-ios-relay`)

| Hash | Subject |
|------|---------|
| 4eaebdd | feat(android): add the sms envelope models of group 5 |
| 2413192 | test(android): round-trip the sms examples of 05-sms |
| 22007e4 | feat(android): add sms_observer_state and push_outbox to handlive.db version 2 |
| e5ed2fb | test(android): cover the version 2 migration, the SMS and push tables and relay pairs |
| f5f95da | feat(android): advertise SMS with its permissions and SIMs in the capability |
| b63560a | test(android): check the SMS capability, its SIMs and missing permissions |
| 7e4ce54 | build(android): add the feature/sms module with the SMS permissions |
| c0a683c | feat(android): read SMS rows, conversations and contact names for group 5 |
| 6cbccdf | feat(android): page sms/sync and sms/history with stateless cursors and tokens |
| 601fd3b | feat(android): send SMS for clients with SendRegistry and forward-only statuses |
| f940c39 | feat(android): observe the SMS provider for new messages and read status |
| 0bd2d41 | feat(android): answer sms requests and run the SMS observer in the service |
| cc32463 | test(android): cover sync and history paging, cursors and their errors |
| 761b364 | test(android): cover sending, SIM choice, statuses and the sms request acks |
| e396686 | test(android): cover the observer, local_id matching and the provider queries |
| 06f2230 | test(android): validate the emitted sms messages against the shared schemas |
| b9952cd | feat(android): write the SMS bench events in debug builds |
| de7fdc6 | feat(android): turn SMS on with its permission primer and show its status |
| 0faf010 | feat(android): suggest the SMS permission when a client is refused for it |
| 66ac945 | test(android): cover the SMS feature card, the primer and their texts at 200 % |
| 835ed33 | feat(android): show SMS per paired device with the reason it is off |
| 458d3e6 | test(android): cover the SMS availability of paired devices |
| b26569c | refactor(android): let the SMS bench trace write through an injectable sink |
| f3d3da5 | test(android): cover the SMS bench events and their fields |
| a08bd99 | docs(android): describe the SMS and relay modules, the flavors and the build settings |

handlive-shared, branch `feat/phase-02-sms-ios-relay`: **335018c** feat(shared): add the Android SMS primer title and
feature card statuses — new keys `permission.sms_primer_title`, `permission.status_needs_permission`,
`permission.status_denied`, `permission.status_unsupported` (texts of SET-01 fields 10 and 12), and `android` added to
`pairing.reason_missing_sms_permission`; `check_strings.py --docs`: 0 errors, no new warning. (Taken with the
`.locks/shared` lock, released.) Apple and relay are unaffected (Android-only keys, one platform widened).

## Files

- New module `feature/sms`: `SmsFeature`, `SmsConstants`, `SmsBenchTrace`; `module/` (`SmsModule`, `SmsServices`,
  `SmsRequests`, `SmsReplies`, `SmsBroadcaster`, `SmsEvents`, `SmsError`, `SmsAccess`, `SmsTrace`), `provider/`
  (`SmsProvider`, `SmsObjects`, `AddressNormalizer`), `sync/` (`SyncTokens`, `PageBudget`, `SmsSyncEngine`,
  `SmsHistoryEngine`), `send/` (`SendStatus`, `SendRegistry`, `SmsRadio`, `SimSelection`, `SmsSendPipeline`),
  `observe/` (`ObserverState`, `NewMessageScanner`, `ReadStateTracker`), `system/` (Android: `ContentResolverSmsProvider`,
  `ContentResolverThreadStore`, `ProviderQueries`, `PhoneLookupContactNames`, `PhoneNumberNormalizer`,
  `AndroidSmsRadio`, `SmsResultReceiver`, `SmsContentObserver`, `AndroidSmsAccess`, `RoomObserverState`,
  `DirectorySimChoices`, `SmsPermissionNotifier`); 16 test classes + `testing/` fakes.
- `core/protocol`: `sms/SmsMessages.kt`; the JSON Schema validator moved to test fixtures.
- `core/data`: `db/SmsObserverStateEntity.kt`, `db/HandLiveDatabase.kt` (v2), `schemas/…/2.json`, `HandLiveData`.
- `feature/connection`: `capability/SimDirectory.kt`, `SimChangeWatcher.kt`, `LocalEnvironmentReader`,
  `LocalCapabilityBuilder`, `ConnectionRuntime`, `bench/BenchLog` (list overload), manifest (`READ_PHONE_STATE`).
- `feature/pairing`: `devices/DeviceListModel.kt` (`SmsAvailability`), `PairingFeature`.
- `app`: `ui/settings/FeatureStatus.kt`, `SmsPrimerScreen.kt`, `SettingsModel/Screen`, `PermissionsScreen`,
  `ui/system/SmsAccessReader.kt`, `ui/main/SmsPermissionRoute.kt`, `Route`, `SubscreenRoutes`, `TabRoutes`,
  `ResumedState`, `SettingsActionsImpl`, `MainScreen`, `HandLiveApp`, `MainActivity` (notification deep link),
  `ui/devices/DeviceDetailsScreen.kt`; tests `FeatureStatusTest`, `ScreenCatalog` (+3 screens), `UiSamples`.
- `README.md`, `README.vi.md`, `CLAUDE.md`.

## Tests (real output)

```text
$ ./gradlew check --continue            # JDK 21, 69ff48f with shared b07271f
BUILD SUCCESSFUL in 4s
718 actionable tasks: 12 executed, 706 up-to-date
```

JVM unit tests per module (JUnit XML of the latest runs, all 0 failures / 0 errors; 493 in total): core/protocol 41,
core/crypto 44, core/transport 58, core/data 18, feature/connection 31, feature/pairing 46, **feature/sms 68**,
feature/relay 28, feature/clipboard 101, app 27, core/strings 5, core/design 26. SMS coverage: sync paging and tokens (SmsSyncEngineTest
11, SyncTokensTest), history paging and the same-date group (SmsHistoryEngineTest 4), sending, SIM choice, the
refusal order and each E<k>, retry de-duplication, forward-only statuses (SmsSendTest 13, SendStatusTest 2),
`local_id` matching and the observer (NewMessageScannerTest 5, SmsEventsTest 5), read changes (ReadStateTrackerTest
4), request acks (SmsRequestsTest 4, SmsModuleTest 5), provider SQL on a real SQLite provider
(ContentResolverSmsProviderTest 4), emitted messages against the schemas (SmsMessageSchemaTest 2), bench events
(SmsTraceTest 3, SmsBenchTraceTest 1). The app's text-fit test renders the new SMS screens at 200 % in English and
Vietnamese (320 dp and 411 dp) with nothing cut.

## Spec deviations and proposals

1. `05-sms.md` SMS-04 API 1: the order of the refusal checks follows the **E-table** (`FEATURE_DISABLED` →
   `PERMISSION_MISSING` → `BAD_REQUEST` → `PAYLOAD_TOO_LARGE` → `SMS_INVALID_ADDRESS` → `SMS_SIM_UNAVAILABLE`); the
   business-logic steps list the SIM check before the address check. Proposal: state one order.
2. `05-sms.md` SMS-04 API 4: the Sent-box row is matched to `SendRegistry` by normalized recipient + identical text,
   oldest unmatched entry, while waiting for its final result or ≤ 60 s after it (`SMS_SEND_MATCH_WINDOW`); the spec
   gives no window. Proposal: add the window to 0.10.
3. `00-common-specs.md` 0.9.2 address normalization: `PhoneNumberUtils.formatNumberToE164` with the default SMS SIM's
   country instead of libphonenumber (1 MB); short codes and alphanumeric senders are kept as they are.
4. `05-sms.md` SMS-03: a group of rows with the same `date` is returned whole even past the 500-row / 180 KiB budget,
   so the `before_ts` cursor never skips rows. Proposal: say so in the paging rules.
5. `05-sms.md` SMS-01 `display_name` of a group thread: the contact names joined with ", ", an unknown number shown as
   the number; `null` only when no participant has a contact name.
6. `00-common-specs.md` 0.7.2 `features.sms`: `default_sub_id` is omitted when Android reports none; a SIM `label`
   is the subscription display name, else the carrier name, else empty (no invented "SIM 1" text — the client
   decides).
7. SET-01 field 17 has only a "read SMS" text: the phone also posts it when `SEND_SMS` or `READ_CONTACTS` is the
   missing one (the primer asks all four). Proposal: a generic "needs SMS permission on this phone" text.
8. The SMS primer uses the `smartphone` symbol; the design system maps Messages to `chat_bubble`, which is not bundled
   in `core/design` yet (adding it means fetching the Material Symbols drawable).

## Pending manual checks (no device here)

- **Two SIMs**: SIM choice, `sub_id` of sent and received rows, SIM change → `capability/update`.
- Latency targets with `sms_latency.py`: new SMS notification < 500 ms on the LAN / ≤ 1 s over the relay; reply
  confirmed Sent < 2 s; placeholder < 100 ms, ack < 300 ms.
- Multipart sends and delivery reports on real carriers (GSM and CDMA status codes), `pending_out` behaviour of the
  OEM SMS app.
- TalkBack on the SMS switch, primer, feature card and device details; 200 % font on a device.
- Play Console SMS/Call Log permission declaration (gate G2) — `READ_SMS`/`SEND_SMS` are in the `feature/sms`
  manifest.

Status: DONE_WITH_CONCERNS
Summary: The SMS bridge (sync, history, new messages, sending with statuses, read changes, every SMS_* code), the SMS
switch with its permission flow, the permission notification and the bench events are implemented, tested (JVM) and
pushed.
Concerns/Blockers: "tested with two SIMs" and the latency targets need a real phone; the spec points 1–7 above wait
for the spec owner.
