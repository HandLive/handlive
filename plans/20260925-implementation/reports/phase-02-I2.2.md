# Phase 2 — I2.2 [iOS]: Notification Service Extension and push registration

Card I2.2 of `phase-02-sms-ios-relay.md`. Repository handlive-apple, branch `feat/phase-02-sms-ios-relay`.
`K_push` and the push envelope in `HLCrypto` (first used by this card) are reported here.

## What was done

- **`K_push` and the push envelope** (`HLCrypto/PushEnvelope.swift`): `K_push` = HKDF-SHA256(PRK, empty salt,
  `handlive/v1/push`, 32); `open` checks the envelope (XChaCha20-Poly1305, AAD of 0.5.1), refuses one older than 24 h
  (`expired`) or that does not open (`undecryptable`). `KeychainSecretStore(accessGroup:)` stores the keys in the
  keychain group `group.app.handlive` that the app shares with the extension, `WhenUnlockedThisDeviceOnly` (C3).
  `HLProtocol/PushAlertFields` reads `p` and `hl` (standard base64, ≤ 3,000 characters) from the APNs payload.
- **Decoding** (`HLSMSNotifications/SmsPushDecoder`, `PushDeduplicator`): `sms/new` pushes decode into `SmsNewData`
  with the PRK of the pair named by `p`; a missing key (locked), another pair, a stale envelope or anything else gives
  `nil`; envelope ids seen in the last 24 h are kept in a file of the App Group container.
- **The extension** (`iOS/NotificationService`, target `HandLiveNotificationService`, `app.handlive.ios.nse`): reads
  the PRK from the shared keychain group, decodes, checks the id was not shown before, builds the content of SMS-02
  API 4 (sender, SIM, body — or "New SMS message" with Show Content off, read from the App Group settings), sets the
  thread `sms:<pair_id>:<thread_id>` and the `HL_SMS`/`HL_SMS_GROUP` category, and turns it into an
  `INSendMessageIntent` communication notification with the initials avatar. Locked, stale, already shown or
  unexpected: the original content stays — the `loc-key` text iOS localizes from the app's `Localizable` table
  (`push.sms_new`, `push.generic`, `push.call_*`, generated into `iOS/HandLive/Resources/Localizable.xcstrings`).
  `serviceExtensionTimeWillExpire` delivers the generic content. No database, no network, no PushKit/CallKit (C7).
  `HLBENCH/1 sms_push_shown` in debug builds.
- **Push registration** (in the app, see I2.1): `registerForRemoteNotifications()` after setup and at every launch;
  the token goes to `PUT /v1/devices/me/push-token` as lowercase hex with `topic` = the bundle id and `apns_sandbox`
  in debug builds, `apns` otherwise; sent again after the relay is turned back on and retried at the next connection.
- **Reply action** (in the app): the system wakes the app for "Reply"; the delegate runs it in a background task; the
  model connects (CONN-01/03), sends and waits about 20 s for the phone's `ack`, marks the conversation read, and
  otherwise leaves the message waiting and posts "Not sent yet. Open HandLive to try again." (SMS-04 API 5); empty text
  is ignored. "Mark as Read" is local (SMS-05 A2); a tap opens the conversation in the Messages tab.

## Commits (handlive-apple)

| Hash | Subject |
|------|---------|
| 0073220 | feat(apple): derive K_push and open the envelope of an APNs alert |
| d53d775 | feat(apple): let the keychain store use the access group shared with the extension |
| 85c930d | test(apple): test K_push, push envelope refusals and the shared access group |
| a38c59e | test(apple): open and refuse the push envelopes of push-envelope.json |
| 6ade21a | test(apple): open every push vector, including the SMS text cut ones |
| df0c7f7 | feat(apple): build SMS communication notifications and decode pushes for the extension |
| 2c763e0 | test(apple): test SMS notification content, categories, removal and push decoding |
| 01ef006 | feat(ios): generate the iPhone app's purpose strings and push loc-keys |
| 14f146c | feat(ios): add the Notification Service Extension |

## Files

`Packages/HLCrypto/Sources/HLCrypto/{PushEnvelope,KeychainSecretStore}.swift`,
`Packages/HLProtocol/Sources/HLProtocol/PushAlertFields.swift`,
`Packages/HLSMS/Sources/HLSMSNotifications/{SmsPushDecoder,SmsNotificationBuilder,SmsNotificationKeys}.swift`,
`iOS/NotificationService/NotificationService.swift`, `iOS/NotificationService-Info.plist`,
`iOS/NotificationService.entitlements`, `iOS/HandLive/Resources/Localizable.xcstrings`, `project.yml`.

## Tests

```
HLCrypto   ✔ Test run with 46 tests in 12 suites passed after 6.826 seconds.
HLSMS      ✔ Test run with 10 tests in 2 suites passed after 0.014 seconds.   (HLSMSNotificationsTests)
Mac Catalyst type-check of iOS/NotificationService/NotificationService.swift against the packages: no errors
```

CI run 36233209508 (57a9f3d): `Build app iOS + Notification Service Extension (simulator, unsigned)` —
`** BUILD SUCCEEDED **` (the extension is embedded in `HandLiveiOS`); final head bc5cae8: run 36234320082 **success**.

The vectors of `shared/test-vectors/push-envelope.json` (handlive-shared b07271f): `K_push` of both pairs, all 8
envelope vectors open (the five SMS text cut vectors keep their code-point and UTF-16 lengths, `hl` ≤ 3,000
characters, APNs `thread-id` `sms`, notification thread `sms:<pair_id>:<thread_id>`, `HL_SMS_GROUP` for the crowded
group), the 9 invalid ones are refused for their reason.

## Spec deviations and proposals

1. **Duplicates** (E7) keep the generic text: without the filtering entitlement an extension cannot drop a
   notification, and the APNs collapse id already replaces an earlier copy of the same message.
2. **Bench identity**: the extension has no `device_id`, so its lines carry `dev=00000000`; `msg` links them to the
   phone's `sms_push_sent`.
3. **Show Content off** uses `sms.notification_hidden_body` ("New SMS message") in the body, as on the Mac.

## Pending manual checks

- A signed build with the App Group, keychain group, `aps-environment` and communication notifications; the relay
  with the APNs key; the phone pushing (A2.2).
- Locked iPhone: generic "New SMS message"; unlocked: sender, text, avatar, thread; previews off.
- Memory of the extension under 30 MB (Instruments / Xcode memory gauge).
- Reply from the lock screen and from Notification Center with the app not running: Sent within ~20 s, or "Not sent
  yet" and the message sent at the next opening.

Status: DONE_WITH_CONCERNS
Summary: The extension decrypts SMS pushes with `K_push` while unlocked and shows communication notifications, with
generic loc-key text otherwise; push registration and the background Reply are in the app; covered by the shared
vectors and a Catalyst type-check, built on CI for the simulator.
Concerns/Blockers: nothing ran on a device yet (needs signing, the relay's APNs key and the Android push sender);
the 30 MB memory limit is not measured.
