English | [Tiếng Việt](phase-02-sms-ios-relay.vi.md)

# Phase 2 — SMS, iPhone/iPad app, relay and push

**Goal:** read and reply to SMS from the Mac and iPhone/iPad; internet connection when away from the
LAN; wake the iPhone with push; an iOS app with clipboard, messages and settings.

## Context

- Leaf functions: `05-sms.md` SMS-01…05; `03-connectivity.md` CONN-03, CONN-04; `04-clipboard.md`
  CLIP-04; `02-pairing.md` PAIR-01 via the relay (`rv`), PAIR-03 flow B; `01-setup-settings.md` SET-02
  (fields 7–9, 21, 24–30), SET-03 (iOS).
- Common specs: 0.9.4 relay schema (PostgreSQL), 0.9.4 Redis (`presence`, `dev:<device_id>`,
  `revoked_notice`), relay REST, `DELETE /v1/devices/me?revoke_pairs=` (C16).
- Design system: `3-platforms/02-ios-ipados.md`; components `ThreadRow`, `MessageBubble`,
  `PasteCard`, `Notification`, `GroupedList`; `2-patterns/03-thong-bao.md`.
- Decisions: C3 (Keychain while locked), C7 (no PushKit/CallKit), C18 (`ContentObserver`, no
  `RECEIVE_SMS`), gate G2 (Play Console).

## Requirements and measurable criteria

- New-SMS notification on the Mac < 500 ms after the phone receives the message (LAN); a reply
  confirmed as "Sent" < 2 s.
- Zero-knowledge relay: no decryption, no payload logging; session data is deleted automatically after
  30 days.
- Locked iPhone: notifications show only generic content (C3), sent as a `loc-key` so the iPhone
  localizes it itself (0.12.4).
- The new Phase 2 UI strings (SMS, iOS, relay, push) go into the catalog before the code, with both
  `en` and `vi` (C20).

## Task cards

| Code | Task | Outputs | Acceptance criteria |
|------|------|---------|---------------------|
| R2.1 [relay] | REST: device registration, pairs, revocation, `DELETE /v1/devices/me` (C16), push token; WS `/v1/relay` with the `to`/`from` wrapper, Redis presence, forwarding between instances via pub/sub (C5); rate limiting; 30-day data deletion | `relay/crates/relay-server` | Integration tests with two fake clients; `cargo clippy` clean; no payload in the logs |
| R2.2 [relay] | Push proxy: APNs (.p8 token, `apns-collapse-id`, `interruption-level`), FCM; `push_outbox` with a 30 s expiry; default content per CONN-04 API 4: `loc-key` only, the relay sends no display text | `relay/crates/relay-push` | Push reaches a real iPhone in < 2 s; expiry works correctly |
| A2.1 [android] | SMS: `ContentObserver` on the provider (SMS-02), paged history sync (SMS-01), sending through `SmsManager` with `SendRegistry` and the `sending → sent → delivered/failed` states (SMS-04), read status (SMS-05); SMS permissions per SET-01 part B | `android/feature/sms` | Every `SMS_*` error code (0.8) is returned correctly; tested with two SIMs |
| A2.2 [android] | Relay: connect to `/v1/relay` when there is no LAN (CONN-03), registration, push via the relay when the iOS client has no session (CONN-04), FCM for wake-ups | `android/core/transport`, `feature/…` | Switching LAN ↔ relay loses no messages; `relay.enabled = false` closes the relay session |
| M2.1 [macOS] | Messages window: `NavigationSplitView`, `ThreadRow`, `MessageBubble`, a compose field with SIM selection and part count, `INSendMessageIntent` communication notifications with "Reply" and "Mark as Read" (SMS-02 API 4), SQLCipher storage | `apple/macOS/HandLive` | Message status strings match SMS-04; notifications show the sender's avatar; unread-count badge in the menu bar |
| M2.2 [macOS] | Internet connection (CONN-03) in `HLTransport`; Messages and Internet Connection settings; "Remove Device from Server" and "Delete All Data" with alerts | app | Switching the phone from Wi-Fi to 4G still delivers messages through the relay |
| I2.1 [iOS] | iOS app: SET-03 onboarding, pairing that shows the QR code, a Clipboard tab with `PasteButton` (CLIP-04), a Messages tab (`ThreadRow`, `MessageBubble`), a Settings tab (`GroupedList`), `HLTransport` over LAN and relay | `apple/iOS/HandLive` | Pasting raises no permission dialog; iPad uses `NavigationSplitView`; Dynamic Type AX5 truncates no text |
| I2.2 [iOS] | Notification Service Extension: decrypt the envelope with `K_push` while the device is unlocked, `INSendMessageIntent` communication notifications, a reply action (SMS-04 within ~20 s in the background), generic content while locked (C3); push registration (CONN-04) | `apple/iOS/NotificationService` | Tested locked and unlocked; the extension uses < 30 MB of memory |
| T2.1 [test] | Bench: SMS notification time and reply confirmation; relay load test with 1,000 fake connections | `tools/bench/`, `reports/` | Targets met on real devices; the relay is stable at 1,000 connections |
| T2.2 [release] | Play Console: Permissions Declaration Form (SMS, call log), privacy policy; App Store: permission descriptions, App Group, the Communication Notifications capability | `docs/deployment-guide.md` | Gate G2 |

## Testing

- Unit: `sms/history` paging, matching `local_id` against the Sent box (SMS-04 API 4), the
  forward-only status rule.
- Integration: network lost midway (CONN-02 E), relay restart (Redis presence lost).

## Risks and rollback

- Play Store rejects SMS → Plan B: a Notification Listener reads SMS notifications (no sending),
  F-Droid/APK distribution; recorded in deployment-guide.
- APNs payload limit of 4 KB → the SMS text is cut to 1,000 characters in the push, and arrives in
  full after SMS-01.
