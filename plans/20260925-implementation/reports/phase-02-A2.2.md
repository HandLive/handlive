# Phase 2 — A2.2 [android]: the phone on the relay, pushes and FCM

Card A2.2 of `phase-02-sms-ios-relay.md`: CONN-03 (relay client, `/v1/relay`, relayed `/v1/ctl` sessions), CONN-04
(alert pushes for iPhone/iPad with the phone's `push_outbox`, FCM wake-ups), PAIR-01 over the relay rendezvous,
PAIR-03 flow B, and the Android rows of SET-02 fields 7–9, 21, 24–30. Branch `feat/phase-02-sms-ios-relay` of
handlive-android, pushed (head `69ff48f`), tested against handlive-shared `b07271f` (shared sync 1: 304 strings,
10 push vectors, per-reason `ttl_s`). No real relay was reachable from here (see pending checks); everything runs
against fakes and the shared vectors.

## What was done

- **Wire formats** — `core/protocol`: the `{"to","env"}`/`{"from","env"}` wrapper, control ops (`presence`, `error`,
  `rv_join`, `rv_joined`, `rv_msg`, `pair_revoked`; unknown ops and unreadable frames ignored), the `HR` binary frame,
  and every REST body of 0.7.4 with the relay error codes of 0.8.2 (`relay-frame.json`, `push-envelope.json` vectors).
  `core/crypto`: `K_push` = HKDF(PRK, "handlive/v1/push") and push envelopes; `env_b64` = standard base64 with padding
  of the UTF-8 envelope JSON.
- **Relay client (`core/transport`)** — one OkHttp client with `CertificatePinner` (ISRG Root X1/X2 + the build's
  extra pins; a pin mismatch never connects, E7); `POST /v1/devices` (HLREG1), challenge + `POST /v1/auth/token`
  (HLAUTH1), JWT reused while > 60 s are left, renewed once on 401 `TOKEN_EXPIRED`, the device registered again once on
  404 `DEVICE_NOT_FOUND`/401 `SIGNATURE_INVALID` (E2); `GET/POST /v1/pairs`, revoke, push token, `POST /v1/push`,
  `DELETE /v1/devices/me`. `/v1/relay` WebSocket (pings every 15 s). Peer envelopes run as `/v1/ctl` sessions through
  the **same handshake, admission limits, rekey and idle close as the LAN** (`ControlServer.serveRelayPeer`,
  `SessionTransport.RELAY`); a `session/hello` from a peer starts a new virtual session, `presence` offline or
  `error NOT_CONNECTED|NOT_PAIRED` ends it.
- **No lost messages when switching LAN ↔ relay** — the 0.5.1 duplicate ledger is kept per pair across its sessions,
  so a request the client retries on its next session (either path) gets its original `ack` and is not executed twice
  (`sms/send` also de-duplicates by `local_id`); the client keeps its own outbox until acked.
- **When the phone is on the relay (`feature/relay`)** — no permanent connection: it connects while a client may be
  waiting there — service start with a relay-registered pair that has no session, a LAN session dropped without
  `bye`, a network change, an SMS for a client without a session, a pairing rendezvous, an FCM wake-up (gms) — and
  leaves after `RELAY_IDLE_DISCONNECT` (5 min without relayed sessions, rendezvous or traffic). Reconnects follow
  `RECONNECT_BACKOFF` 0.5 → 30 s ± 20 %, reset by a network change. 410 `DEVICE_REVOKED` stops it for good, writes
  `relay.enabled = false` and Settings shows "This device was removed from the internet service" (E3).
- **`relay.enabled` (SET-02 field 21)** — off: `capability/update`, then `session/bye {shutdown}` on each relayed
  session, then the link closes; LAN sessions stay. On: the device and the pairs at `relay_registered = 0` are
  registered again (SET-02 API 6).
- **Registrations** — the device once per process; each unregistered pair (`POST /v1/pairs`, 200/201 →
  `relay_registered = 1`, a 4xx waits 24 h); tombstones revoked until the relay confirms (PAIR-03 E3); `GET /v1/pairs`
  at most once a minute (forced after `error NOT_PAIRED`): a revoked pair is cleaned up with "<name> was unpaired from
  another device" (PAIR-02 E3), a forgotten one goes back to `relay_registered = 0`.
- **Pairing and unpairing over the relay** — a QR window with `rv` also joins the rendezvous (joined again on every
  new link, left when the window closes); a stored pair is registered right away; unpairing revokes the pair on the
  relay (`user`, or `lost_device` when the peer could not be told); `pair_revoked` is cleaned up like a revocation
  from the peer.
- **Pushes (CONN-04, SMS-02 step 10)** — only for an inbox message, to iPhone/iPad pairs registered with the relay,
  without a session, whose last capability has `sms.enabled`, `sms.notify` and relay not off. `sms/new` without
  `local_id`, sealed with `K_push`; `collapse_key` = `message_key`, `ttl_s` 86,400 (also on retries); the body cut to
  ≤ 1,000 code points ending with "…", then body, then snippet, cut to the longest fit until `env_b64` ≤ 3,000 —
  **identical to all five truncation vectors** (texts and `env_b64` length); nothing fits → no alert. Validated
  against `relay-rest.schema.json#/$defs/push-request` (the phone never builds FCM/APNs payloads, `push.schema.json`
  is the relay's). Network error, 429 (`Retry-After`), 5xx and 502 `PUSH_PROVIDER_ERROR` → `push_outbox`, retried
  5 s, 15 s, 45 s… ≤ 5 min apart until 24 h; 409 `PUSH_TOKEN_MISSING`, 403, 413, 400 are dropped.
- **FCM (gms flavor only)** — `foss` (default) has no Play Services or Firebase (checked in the APK: 0 references);
  `gms` initializes Firebase from build settings (no `google-services.json`), sends the token with
  `PUT /v1/devices/me/push-token` (new token or weekly), and a `t = wake` message starts the service and the relay.
  `./gradlew check` (and so CI) compiles the gms flavor without any Firebase setting, and detekt covers the flavor
  sources.
- **SET-02 fields 26–30 (Data section)** — "Remove Device from Server": action sheet with the warning and "Remove
  from Server", `DELETE /v1/devices/me?revoke_pairs=false`, then registrations forgotten and `relay.enabled = false`
  → "Removed from the server", or E5 "Couldn't connect to the server. Try again later."; E6 (device already gone)
  counts as done. "Delete All HandLive Data": "Delete All", `revoke_pairs=true`, then `pair/revoke {reinstall}` to
  LAN/USB sessions (10 s, in parallel), every pair deleted without tombstones, Accessibility service and A-SVC
  stopped, then keys (`hl_master`), TLS identity, database, settings and notifications deleted and HandLive restarts
  at the welcome screen; relay unreachable → E7 alert "Delete" / "Cancel". Cancel changes nothing (E8).
- **Bench** — `sms_push_sent` (`msg`, `peer`) after a 202.

## Commits (handlive-android, branch `feat/phase-02-sms-ios-relay`)

| Hash | Subject |
|------|---------|
| 22007e4 | feat(android): add sms_observer_state and push_outbox to handlive.db version 2 |
| e110daa | feat(android): track relay registration, tombstones and push targets of the pairs |
| e5ed2fb | test(android): cover the version 2 migration, the SMS and push tables and relay pairs |
| 9b39605 | feat(android): derive K_push and seal push envelopes for iPhone and iPad |
| a734a5f | feat(android): add the relay routing frames, control ops and REST bodies |
| f18b698 | test(android): share the JSON Schema validator through the protocol test fixtures |
| 97fc983 | test(android): check K_push, push envelopes and HR frames against the shared vectors |
| 4db4d04 | style(android): name the offsets of the HR header |
| df2400c | feat(android): serve /v1/ctl sessions of relay peers with the LAN handshake |
| 87184a9 | feat(android): add the pinned relay REST client with registration and JWT renewal |
| 39f25ef | feat(android): carry peer sessions and the pairing rendezvous over /v1/relay |
| 172effa | test(android): cover relay authentication, the relay WebSocket and relayed sessions |
| 8d65bd1 | refactor(android): keep one envelope ledger per pair across its sessions |
| de2e7b9 | feat(android): open the control server to relayed sessions through RelayGate |
| c8142de | test(android): a request retried on the pair's next session gets its old ack |
| 3cdd820 | feat(android): build the relay client and its socket factory on one pinned client |
| 1bb9f4f | feat(android): let pairing use the relay rendezvous and revoke pairs on the relay |
| 5e6ce3f | feat(android): add the relay feature with on-demand /v1/relay and SMS pushes |
| 9692d7e | build(android): add the foss and gms flavors and install the relay at start |
| 3d06681 | fix(android): keep a cut SMS text within 1,000 code points including the ellipsis |
| 54dd998 | test(android): cover the relay connection, registrations and SMS pushes |
| 2382a4e | test(android): accept the message_key collapse key of SMS pushes in the vectors |
| 77f0feb | feat(android): add the reinstall revocation reason and the deletion helpers of API 7 |
| 524b2ae | feat(android): tell LAN clients about a full deletion and drop every pair |
| 3838dff | feat(android): delete this device from the relay for Remove and Delete All |
| dc88d79 | feat(android): remove the device from the server or delete all data in Settings |
| 0642b4d | test(android): cover device deletion on the relay, the reinstall revocation and flow A1-A6 |
| a08bd99 | docs(android): describe the SMS and relay modules, the flavors and the build settings |
| 9dd24eb | refactor(android): close relayed sessions in the control server |
| 59710e9 | test(android): switching the relay off sends the capability, then bye shutdown |
| 0b22fb5 | test(android): check the push text cut and collapse keys against the new vectors |
| e264e30 | fix(android): send ttl_s 86,400 with every SMS push, retried or not |
| 8017e5f | test(android): a retried SMS push keeps ttl_s 86,400 and matches the schema |
| fe3f932 | feat(android): name the action on the Remove from Server and Delete All buttons |
| 69ff48f | build(android): run detekt on the flavor sources and compile gms in check |

No handlive-shared commit for this card (the catalog commit 335018c is listed in the A2.1 report).

## Files

- `core/protocol`: `relay/RelayFrame.kt`, `relay/RelayMessages.kt`, `relay/RelayRest.kt`, `pairing/PairMessages.kt`
  (`reinstall`); tests `RelayFrameVectorTest`, `PushRequestVectorTest`.
- `core/crypto`: `derivation/PushKeyDerivation.kt`, `message/PushEnvelopes.kt`; `PushEnvelopeVectorTest`.
- `core/transport`: `relay/` (`RelayConfig`, `RelayHttp`, `OkHttpRelayTransport` + `RelayTransport`, `RelayAuth`,
  `RelayApi`, `RelayLink`, `RelayPeerMux`, `RelayPeerSocket`, `RelayRendezvous`), `server/ControlServer`,
  `ControlConnectionHandler`, `ControlSession` (`SessionTransport`), `tls/AndroidTlsIdentityStorage`; tests
  `RelayAuthTest`, `RelayLinkTest`, `RelayPeerMuxTest`.
- `core/data`: `db/PushOutboxEntity.kt`, `pairing/RelayPairs.kt`, `PairedDeviceDao`, `PairStore`, `HandLiveData`.
- `feature/connection`: `RelayGate.kt`, `session/SessionTable.kt`, `session/EnvelopeLedger.kt`, `ConnectionRuntime`.
- New module `feature/relay`: `RelayFeature`, `RelayConnector`, `RelayConnection`, `RelayRendezvousTable`,
  `RelayBackoff`, `RelayOwner`, `RelayRegistrar`, `RelayStatus` (`ServerDeletion`), `RelayConstants`,
  `RelayRuntimeSupport`, `push/PushEnvelopeBuilder`, `push/PushSender`, `push/PushOutboxRunner`; tests
  `RelayConnectorTest`, `RelayRegistrarTest`, `PushSenderTest`, `PushEnvelopeBuilderTest`,
  `PushTruncationVectorTest`, `testing/`.
- `feature/pairing`: `PairingCoordinator` (rendezvous, `onPaired`), `UnpairController` (remote revoke,
  `onRevokedByRelay`, `revokeAllForReinstall`); `UnpairControllerTest`.
- `app`: `build.gradle.kts` (flavors, build settings), `src/foss/…/PushBootstrap.kt`, `src/gms/…/PushBootstrap.kt`,
  `FcmPushService.kt`, `src/gms/AndroidManifest.xml`, `HandLiveApplication`, `settings/DataEraser.kt`,
  `ui/settings/DataActions.kt`, `DataActionDialogs.kt`, `SettingsModel/Screen`, `ui/main/TabRoutes.kt`,
  `ui/AppDependencies.kt`, `MainScreen` (unpaired-elsewhere notice); `DataActionsTest`.
- `gradle/libs.versions.toml` (`firebase-messaging` 25.1.3, gms only), `settings.gradle.kts`.
- CI: `ci-android` green on `69ff48f` (run 36225980996, shared at sync 1, gms compiled in `check`).

## Tests (real output)

```text
$ ./gradlew check --continue            # JDK 21, 69ff48f with shared b07271f (check now also compiles gms)
BUILD SUCCESSFUL in 4s
718 actionable tasks: 12 executed, 706 up-to-date
$ ./gradlew assembleFossDebug assembleGmsDebug          # both flavors without any build setting
BUILD SUCCESSFUL
$ unzip classes*.dex of each APK | grep -c com/google/firebase/messaging
foss: 0 (Play Services 0)    gms: 7 (Play Services 10)
```

Relay tests: `RelayConnectorTest` 9 (demand, 5-minute idle close, backoff, token renewal, E2 re-registration, E3 and
E7 stop, a relayed session keeps the link, control ops, rendezvous re-join, switch-off), `RelayRegistrarTest` 7
(device + pairs against `pairs-request`, 404 → 24 h, tombstones, `GET /v1/pairs` rules, push token weekly, deletion
and E6), `PushSenderTest` 5 (targets, outbox retries, `Retry-After`, drops, expiry, `ttl_s`), `PushEnvelopeBuilderTest`
6 and `PushTruncationVectorTest` 1 (the five truncation vectors), `RelayAuthTest` 7, `RelayLinkTest` 2,
`RelayPeerMuxTest` 5 (relayed handshake, peer gone, replacement, dropped envelopes, capability → bye shutdown),
session ledger test, `UnpairControllerTest` +2, `DataActionsTest` 6. All modules: 493 JVM tests, 0 failures.

## Spec deviations and proposals

1. `03-connectivity.md` CONN-03 step 2 ("connect when there is no LAN session"): without a signal the phone cannot
   know that a client waits on the relay, so it connects on the demands listed above and leaves after 5 idle minutes;
   with the `foss` flavor a client outside the LAN reaches the phone only while one of those demands is recent.
   Proposal: write this demand list into CONN-03.
2. `00-common-specs.md` 0.4.3 pins: ISRG Root X1/X2 are in the code; the project's backup pin goes in the build
   setting `handlive.relayExtraPins` — **the owner still has to supply it**, and the relay host (`handlive.relayHost`).
3. `02-pairing.md` PAIR-01 API 8: the relay answers 404 `DEVICE_NOT_FOUND` both for an unknown caller and for a peer
   that is not registered, so the phone registers itself again and retries once before waiting 24 h. Proposal: a
   distinct code for the peer (e.g. `PEER_NOT_REGISTERED`) in 0.8.2.
4. `02-pairing.md` PAIR-03 E3: a tombstone revoked later uses `reason = user` (`lost_device` is not stored with the
   tombstone).
5. Relayed `/v1/ctl` sessions have no WebSocket close frame: a session the phone ends without `session/bye` (idle
   4410/4411, replacement 4409) is noticed by the client only through its pings. Proposal (CONN-03 step 9): always send
   `session/bye {reason}` before closing a relayed session, or add a relay op.
6. `00-common-specs.md` 0.5.1: duplicate detection is per pair across its sessions (LAN or relay), not per session —
   this is what makes LAN ↔ relay switching lossless without double execution.
7. `01-setup-settings.md` SET-02 E6: 410 `DEVICE_REVOKED` during a deletion also counts as done. A6: after "Delete
   All" the process restarts (`Intent.makeRestartActivityTask` + exit), since every singleton held the deleted keys
   and database. Field 26 is hidden in a build without a relay host.
8. `03-connectivity.md` CONN-03 E7 on Android: `error.relay_pin_mismatch` is catalogued for macOS/iOS only, so the
   phone just stays off the relay. Proposal: widen it to android and show it under Internet Connection.
9. SMS-02 API 2 logic 1: the phone also skips a push when the client's capability has `features.relay.enabled =
   false` (SET-02 field 21: "no push is sent").
10. The first `sms/sync` catch-up and other client requests during an FCM-started session depend on Android allowing
    a foreground service start from a high-priority FCM message (Android 12+ exemption) — to be verified on devices.

## Pending manual checks

- Real relay end to end (R2.1/R2.2 server): registration, token, `/v1/relay`, relayed sessions from a Mac and an
  iPhone, pairing through the rendezvous, `pair_revoked`, `GET /v1/pairs`, remove/delete flows.
- Push to a real iPhone (< 2 s, collapse per message, 24 h expiry) and FCM wake-ups with a configured `gms` build.
- LAN ↔ relay switching on devices (Wi-Fi off/on, airplane mode) with SMS traffic; "relay.enabled = false" closing
  the relayed sessions on the client side.
- "Delete All HandLive Data" on Android 10–15 (restart to the welcome screen, Accessibility service off, Keystore
  entry gone); Doze/battery behaviour of the on-demand relay link; TalkBack on the Data section and dialogs.

Status: DONE_WITH_CONCERNS
Summary: The relay client, relayed sessions with lossless LAN ↔ relay switching, registrations, remote revocation,
pairing through the rendezvous, SMS pushes with the push outbox, FCM in the gms flavor and SET-02 fields 21 and
24–30 are implemented, tested against fakes and the shared vectors, and pushed.
Concerns/Blockers: no real relay, APNs or FCM run from here; the backup certificate pin and the relay host must come
from the owner; spec points 1, 3, 5 and 8 need a decision.
