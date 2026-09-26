# Phase 2 — M2.1 [macOS]: Messages window, SMS engine and store (SMS-01…05)

Card M2.1 of `phase-02-sms-ios-relay.md`. Repository handlive-apple, branch `feat/phase-02-sms-ios-relay`.
As agreed, the package work that M2.1 is the first card to use is reported here: the SMS messages of HLProtocol,
the SQLCipher store and SMS engine (`HLSMS`), the SMS notifications (`HLSMSNotifications`), the shared Messages
screens (`HLSMSUI`), the design-system components `ThreadRow` and `MessageBubble`, the string regeneration and the CI
fix for SQLCipher. The relay client is in `phase-02-M2.2.md`, `K_push` and the extension in `phase-02-I2.2.md`.

## What was done

- **Protocol** (`HLProtocol/SmsMessages.swift`, `SmsSendMessages.swift`): `sms/sync` (page token, per-thread limit,
  unread states), `sms/history`, `sms/new`, `sms/send` (1,600 characters) with its ack, `sms/status` (forward-only,
  error code), `sms/read_changed`, `ping/ping`; lenient enums for unknown `box`/`status` values; tests on every Phase
  2 SMS example of `05-sms.md`.
- **Encrypted database** (`HLSMS/SmsDatabase.swift`): GRDB 7.11.1 vendored in `ThirdParty/GRDB` (MIT) with the
  manifest GRDB documents for SQLCipher, linking SQLCipher 4.19.0 Community Edition (BSD-style, Zetetic). The key is
  the raw 32-byte `db_key` from the Keychain (`PRAGMA key = "x'<hex>'"`, 0.6.1); `PRAGMA cipher_version` must answer
  or the store refuses to open (never a plaintext fallback, 0.6.5). Schema `v1-sms`: `sms_thread`, `sms_message` with
  `idx_sms_message_thread_ts`, `sms_outbox`, `sync_cursor` (0.9.3). Tests check that the file has no SQLite header
  and no plaintext and that a wrong key fails. Licenses in `NOTICE`.
  - **CI**: xcodebuild hangs on GitHub's macOS runners while it downloads SQLCipher.swift's remote binary target
    (every run stopped at HLSMS for 40 min, then timed out). `ThirdParty/SQLCipher` is now a local package whose
    binary target is the same official XCFramework, fetched by `ThirdParty/SQLCipher/fetch.sh` with its SHA-256
    checked (the checksum SQLCipher.swift publishes); CI runs the script first; the framework is not committed.
- **Store** (`SmsStore*`): pages of 50 by `last_ts` and keyset pages of messages; the sync page, unread
  reconciliation and cursor in one transaction; resync keeps the waiting outbox; `sms/new` upserts (fallback match on
  address/body/time for a sent copy, the outbox entry settles on the echoed `local_id`); history `INSERT OR IGNORE`;
  local read state (`local_read_ts`); the outbox (`pending → sending → sent → delivered`, `failed`, forward-only);
  24 h expiry; delete per pair and delete all.
- **Engine** (`SmsEngine*`): SMS-01 sync with page tokens, the cursor saved at the last page, `SMS_CURSOR_INVALID`
  recovery (page token → from the cursor, cursor → automatic resync), `INTERNAL` retried once after 5 s, first-sync
  count; SMS-02 notify rules (inbox only, not the conversation open in the window in use, `sms.notify`); SMS-03
  history paging with `mayHaveOlder`, E2–E5 states; SMS-04 send/reply/retry, the outbox flushed one by one, retries
  with the same envelope `id` after 5/15/45 s, no automatic resend after an `ack`, wake push when the phone is away
  (CONN-04 step 5a), quick reply with a deadline; SMS-05 read state from the phone and local "Mark as Read"; SIM
  labels on dual-SIM phones; the GSM-7/UCS-2 part counter (160/153, 70/67, extension characters count 2).
- **Notifications** (`HLSMSNotifications`, no database, also used by the extension): content (title from contact
  name or national number, SIM subtitle, body or "New SMS message" with previews off), `INSendMessageIntent`
  communication notification with an initials avatar, thread `sms:<pair_id>:<thread_id>`, categories `HL_SMS`
  (Reply with "SMS Message" placeholder and "Send", Mark as Read) and `HL_SMS_GROUP` (Mark as Read only), removal by
  `userInfo` (up to `read_up_to_ts`, generic ones after a sync), `SmsNotificationResponse` shared by the Mac and iOS.
- **Screens** (`HLSMSUI`, shared with iOS): `MessagesModel` (GRDB observation of the list, search, unread filter,
  sync banner, failed-send marks, New Message, whether the screen is in use), `ConversationModel` (newest page,
  placeholders, history, counter, SIM), `ThreadListView`, `ConversationView` (day markers, unread divider, history
  banner with Try Again, group note), `ComposeBar` (capsule field, SIM chip titled "Choose SIM", counter
  "{used}/{limit} · {parts}"), `NewMessageView` ("To:" field, invalid-number message), `SmsDisplay` (times, status
  words of SMS-04 field 8, failure reasons, VoiceOver labels "{sender}, {time}" / "You, {time}, {status}").
  `HLDesignSystem` gained `ThreadRow` and `MessageBubble` (text as accessibility value; links and numbers detected).
- **Mac** (`HLMacUI`):
  - `AppModel` opens the database with `db_key`, runs the engine with the connection events, posts and removes
    communication notifications (`UserNotificationSms`), routes Reply (sent at once, conversation marked read), Mark
    as Read and a tap (opens the conversation), keeps the unread count, expires the outbox every hour, forgets a
    pair's messages on unpair; `NSUserActivityTypes` = `INSendMessageIntent` and the communication-notifications
    entitlement.
  - **Messages window** (`MessagesWindowController`): a sidebar split view — the system search field at the top of the
    sidebar and the conversation list, the conversation or New Message on the right; toolbar with the sidebar toggle
    and "New Message"; File › New Message ⌘N, Edit › Find ⌘F (focuses the search), View › sidebar, Window ›
    Messages; the Dock icon and app menu bar while it is open; frame kept between openings; the conversation counts
    as open only while the window is key. Menu bar: the unread conversation count right after the icon (99+),
    "Messages" with its badge in the menu; Dock menu "New Message"; reopening the app opens Messages once paired.
  - `HLBENCH/1` (debug builds): `sms_new_received`, `sms_notified`, `sms_send_tap`, `sms_bubble`, `sms_send_sent`
    (attempt, `via` lan/relay), `sms_send_ack_received`, `sms_status_received`.
- **Strings**: String Catalogs and `L10n` regenerated from handlive-shared (43d0381 → 68d9508 → 9ff23b7, 304 keys);
  no text in code (the scan now also covers `iOS/`).

## Commits (handlive-apple)

| Hash | Subject |
|------|---------|
| 12508ca | feat(apple): add the sms and ping message data of SMS-01…05 and CONN-02 |
| d5423d2 | test(apple): decode the sms and relay examples of the Phase 2 specs |
| 32a6c9e | build(apple): vendor GRDB 7.11.1 built against SQLCipher 4.19.0 for the encrypted database |
| a043f4e | feat(apple): add a public initializer for the SIM of the sms capability |
| 9c481c9 | feat(apple): let a request reuse its envelope id and hand sms envelopes to the app |
| c7bb65f | feat(apple): add the SQLCipher database with the SMS tables of 0.9.3 |
| 0e01043 | feat(apple): add the SMS queries and the part counter of SMS-01…05 |
| 5373003 | feat(apple): sync, receive, send and page SMS with the phone |
| 5f17cdf | test(apple): test the encrypted SMS store, outbox rules and the SMS engine |
| e175e64 | ci(apple): test the HLSMS package and list it in the workspace |
| 5630eb7 | fix(apple): list the GSM-7 alphabet by code point instead of as text |
| 43d0381 | feat(apple): regenerate the string catalogs with the Phase 2 strings |
| aba007e | test(apple): use call_event as the unhandled type now that sms is handled |
| dd549c1 | feat(apple): let bench lines carry optional fields built at run time |
| 9649786 | feat(apple): write the SMS bench events of HLBENCH/1 in debug builds |
| df0c7f7 | feat(apple): build SMS communication notifications and decode pushes for the extension |
| 2c763e0 | test(apple): test SMS notification content, categories, removal and push decoding |
| 93886d1 | feat(apple): add the ThreadRow and MessageBubble components of the design system |
| 54277d4 | feat(apple): read the bubble text as its accessibility value |
| ec9d03c | feat(apple): let the screens and notifications mark a conversation read |
| 621e57b | feat(apple): add the shared Messages models and views for Mac and iPhone |
| 46e16b6 | test(apple): test the Messages models over the encrypted database and their texts |
| 80316c4 | ci(apple): test HLSMSUI and list it in the project |
| 1abb081 | feat(apple): read and write the sms.* settings |
| a13d17e | feat(apple): advertise SMS in the capability, with sms.notify on iPhone and iPad |
| 44457f3 | feat(apple): post SMS notifications on the Mac and route Reply and Mark as Read |
| 783623c | feat(apple): run the SMS engine and the relay services in the Mac app model |
| beb0981 | test(apple): test SMS in the Mac app model |
| d3be2e7 | feat(apple): regenerate L10n and the String Catalogs from the Phase 2 catalog |
| 2e3182d | feat(apple): use the catalog texts for bubble labels, SMS errors and the reply field |
| 0a3832b | feat(apple): add the New Message screen |
| 683595e | feat(apple): open New Message from the Messages model and follow whether it is in use |
| d3ca6c2 | feat(apple): add the Messages window on the Mac |
| 2fc48da | feat(apple): reach Messages from the menus, the Dock and the menu bar icon |
| 72e1928 | feat(apple): declare communication notifications for the Mac app |
| a811548 | feat(apple): expire waiting SMS every hour on the Mac |
| 3e8cebd | feat(apple): delete the SMS database files even when a connection stays open |
| 367a84c | feat(apple): show when SMS last synced and close the Messages model |
| 915caa7 | feat(apple): regenerate the String Catalogs from handlive-shared 9ff23b7 |
| dbf7a5e | refactor(apple): share how an SMS notification response is read |
| 6602d79 | fix(apple): link SQLCipher's XCFramework as a local binary target |
| acceda9 | ci(apple): test HLSMS through its package scheme |
| bc5cae8 | test(apple): wait for the badge that follows the end of the first sync |

No commit in handlive-shared: the catalog keys this card needed came from the shared agent (S2.1, shared sync 1).

## Files

`Packages/HLProtocol/Sources/HLProtocol/{SmsMessages,SmsSendMessages}.swift`; `Packages/HLSMS/` (package: `HLSMS`,
`HLSMSNotifications`, tests); `Packages/HLSMSUI/`; `Packages/HLDesignSystem/Sources/HLDesignSystem/Components/
{ThreadRow,MessageBubble}.swift`; `Packages/HLMacUI/Sources/HLMacUI/{AppModel+Messages,SmsNotifier,
MessagesWindowController,MessagesWindowViews,ClipboardAlerts,HandLiveScenes,MenuBarViews,AppCoordinator,
WindowPresenter}.swift`; `ThirdParty/GRDB/`, `ThirdParty/SQLCipher/{Package.swift,fetch.sh,LICENSE.md}`; `NOTICE`;
`macOS/{Info.plist,HandLive.entitlements}`; `.github/workflows/ci-apple.yml`; `README.md`, `README.vi.md`.

## Tests (local, Command Line Tools; `HL_SWIFT_TESTING_PACKAGE=1`, SwiftUI packages with `SDKROOT=…/MacOSX26.sdk`)

```
HLProtocol       ✔ Test run with 51 tests in 11 suites passed after 0.021 seconds.
HLSMS            ✔ Test run with 24 tests in 4 suites passed after 0.419 seconds.   (HLSMSTests)
                 ✔ Test run with 10 tests in 2 suites passed after 0.014 seconds.   (HLSMSNotificationsTests)
HLSMSUI          ✔ Test run with 9 tests in 2 suites passed after 0.148 seconds.
HLDesignSystem   ✔ Test run with 24 tests in 7 suites passed after 0.129 seconds.
HLLocalization   ✔ Test run with 9 tests in 3 suites passed after 0.163 seconds.
HLMacUI          ✔ Test run with 31 tests in 6 suites passed after 1.646 seconds.
swiftlint lint --strict (TOOLCHAIN_DIR=/Library/Developer/CommandLineTools): no violations
generate-strings.py --check: OK: 11 files match ui-strings.json
```

CI (GitHub Actions, macos-15, Xcode 26.3), run 36233209508 on 57a9f3d: HLProtocol 51, HLCrypto 46, HLTransport 94,
HLDesignSystem 24, HLLocalization 9, HLAppCore 49, HLSMS 10 + 24, HLSMSUI 9, HLMacUI 30, HLiOSUI 10 tests passed;
SwiftLint 0 violations in 298 files; the Mac app and the iOS app with its extension built. Final head bc5cae8: run
36234320082 **success** (HLMacUI 31, HLiOSUI 11 tests; the rest as above).

## Spec deviations and proposals

1. **SQLCipher build**: GRDB vendored with its documented SQLCipher manifest; SQLCipher's official XCFramework as a
   local binary target fetched by `fetch.sh` (checksum-verified, not committed) because xcodebuild hangs on the
   remote one in CI. Developers run `ThirdParty/SQLCipher/fetch.sh` once after cloning (README).
2. **No foreign key to `paired_device`**: the pair store is still the sealed file of Phase 1, so the SMS tables carry
   `pair_id` without a foreign key and unpairing deletes the rows explicitly. Proposal: note it in 0.9.3.
3. **Messages window is an AppKit window hosting SwiftUI** (sidebar split view, AppKit toolbar), not a SwiftUI
   `Window` scene (03-platforms/01-macos.md): a `Window` scene opens by itself at launch on macOS 13–14 and cannot be
   opened from a notification without a captured `openWindow`. Window › Messages, ⌘N, ⌘F, the sidebar command and the
   frame restore are there; restoring the selected conversation across launches is not.
4. **Menu bar icon count and VoiceOver**: no catalog key says "{count} unread conversations", so the count is not
   in the icon's accessibility label (the Messages menu item carries the badge). Proposal: add
   `a11y.unread_conversations` (plural) to the catalog.
5. **SMS-01 E2 "View Instructions"** has no defined target on Mac/iOS; the reason is shown without the button.
   Proposal: point it at the PAIR-02 permission guide.
6. **Phone numbers**: `PhoneNumberDisplay` formats Vietnamese numbers nationally; other countries stay in E.164.
7. **`sms_bubble`** is logged right after the outbox write (the database observation shows the bubble next).
8. The unread count of a conversation is only in its row's accessibility label, as the spec sync asked.

## Pending manual checks

- Real phone (A2.1): first sync of a large inbox, new SMS notification < 500 ms on the LAN (T2.1 bench), reply
  confirmed Sent < 2 s, dual-SIM picker, a message to a new number opening its conversation.
- Notifications on a signed build: communication notification with the initials avatar, Reply and Mark as Read
  from Notification Center, Focus behaviour.
- Messages window: Dock icon and app menu bar only while open, ⌘N/⌘F/⌘W, Window › Messages, VoiceOver of bubbles
  and rows, `-AppleLanguages (vi)`.

Status: DONE_WITH_CONCERNS
Summary: SMS on the Mac works end to end in code (SQLCipher store, sync/history/send/read engine, notifications,
Messages window, menu bar badge) with tests green locally; the CI SQLCipher hang is fixed with a local binary target.
Concerns/Blockers: real-device checks with the Android app are pending; the window restores its frame but not the
selected conversation across launches; two catalog proposals (items 4, 5).
