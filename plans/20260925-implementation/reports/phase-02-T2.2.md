# Phase 2 — T2.2 release documents

Done by the controller in the hub (the card's output is `docs/deployment-guide.md`); the Play Console and
App Store submissions themselves are the project owner's steps.

## What changed

`docs/deployment-guide.md` and `docs/deployment-guide.vi.md`, same commit:

- **Android:** the `foss` (default, no Play Services, no Firebase) and `gms` (FCM wake-ups) flavors with the
  Gradle properties and environment variables of the Firebase options, taken from handlive-android
  `feat/phase-02-sms-ios-relay` (`app/build.gradle.kts`, `README.md`); no `google-services.json` in git.
- **Gate G2 checklist:** Permissions Declaration Form for `READ_SMS` and `SEND_SMS` (`READ_CALL_LOG` in
  Phase 3), the demo video content, `docs/privacy.md` as the privacy policy URL and the source of the Data
  safety answers.
- **iOS/iPadOS:** bundle id `app.handlive.ios` (the relay's `RELAY_APNS_TOPIC`), the Notification Service
  Extension, App Group `group.app.handlive` used as the Keychain access group of `app.handlive.keys`
  (handlive-apple `KeychainSecretStore.swift`), the capabilities (Push Notifications, App Groups, Keychain
  Sharing, Communication Notifications, `NSUserActivityTypes`), the local network purpose string, the APNs
  `.p8` key kept only on the relay, and the App Review notes.
- **Relay:** the APNs and FCM variables and when each provider is enabled, the per-IP registration limit
  with `RELAY_TRUSTED_PROXIES` (also for the load test), and running several instances on one PostgreSQL and
  Redis (C5), from handlive-relay `README.md` at f87b18b.

## Checks

```text
$ python3 tools/docs/check_bilingual_docs.py
pairs=67 missing=0 problems=0 warnings=0
$ python3 tools/docs/validate_design_docs.py
files=16 leaves=66 problems=0
```

## Pending (project owner)

- Submit the Play Console Permissions Declaration Form and the Data safety form (gate G2); record the result
  in `docs/deployment-guide.md`.
- Create the APNs `.p8` key and the Firebase project and service account; configure them on the relay server.
- Register `app.handlive.ios`, its extension and the App Group in the Apple Developer account once the iOS
  targets exist (I2.1, I2.2).

Status: DONE_WITH_CONCERNS
Summary: The deployment guide in both languages now covers the Phase 2 release: Android flavors, the gate G2
checklist, the iOS identifiers and capabilities, the APNs key, and the relay's push settings and limits.
Concerns/Blockers: gate G2 needs the project owner's submissions; the iOS bundle ids must be checked again
when the iOS targets land.
