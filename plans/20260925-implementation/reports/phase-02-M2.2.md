# Phase 2 — M2.2 [macOS]: Internet connection (CONN-03) and the relay settings

Card M2.2 of `phase-02-sms-ios-relay.md`. Repository handlive-apple, branch `feat/phase-02-sms-ios-relay`.
The relay client in `HLTransport` (first used by this card) is reported here.

## What was done

- **Relay REST client** (`RelayAPIClient`, `RelayHTTPTransport`, `RelayTrust`, `RelayConfiguration`):
  `POST /v1/devices` signed `HLREG1`, `POST /v1/auth/challenge` + `/v1/auth/token` signed `HLAUTH1`, the JWT reused
  while more than 60 s are left, one retry after `401 TOKEN_EXPIRED`, a new registration when the relay forgot the
  device (404 at the challenge); `POST /v1/pairs` (one 404 → register again and retry; the manager waits 24 h after
  a second 404 or any other 4xx), `GET /v1/pairs`, `POST /v1/pairs/{id}/revoke` (404 counts as revoked),
  `PUT /v1/devices/me/push-token`, `POST /v1/push`, `DELETE /v1/devices/me?revoke_pairs=` (404 counts as deleted).
  TLS 1.3 with the system chain plus SPKI pins of ISRG Root X1/X2 and an optional backup pin (`HLRelayBackupPin`);
  host from the `HLRelayHost` Info.plist key, none → LAN only. Errors map to CONN-03 E1/E3/E6/E7.
- **`/v1/relay`** (`RelaySocketConnector`, `RelayLink`, `RelayPeerChannel`): Network.framework WebSocket with the
  `Authorization` header, `{"to","env"}` out, `{"from","env"}` and `HR` binary frames in, control ops `presence`,
  `error`, `pair_revoked`, `rv_joined`, `rv_msg`; a virtual `MessageChannel` per peer so `ControlSession` runs the
  same handshake, capability and rekey through the relay; end-to-end `ping/ping` every 30 s; a relayed session always
  says `session/bye` before it ends (`shutdown` for every other end, never after the phone's own bye; batch 5 rule).
- **Connection manager** (0.11 + relay): LAN first; after the discovery grace the relay (`ConnectingRelay`), the
  first presence of the phone within 3 s, `WaitingPeer` with a `wake` push (at most once per 5 min per reason),
  handshake through the relay, back to the LAN in the background when the phone shows up (the relay session ends
  after a 5 s grace), `relay.enabled` on/off (relayed session closed with `session/bye {shutdown}`), `410
  DEVICE_REVOKED` → relay off, pin mismatch and `429` reported as link issues with the retry time;
  `refreshPairOnRelay()` for the device screens (at most once a minute): a pair listed while unregistered here is
  marked registered, a revoked one is cleaned up (PAIR-03 flow B), a missing one is registered again.
- **Pairing over the relay**: the QR code joins a rendezvous first (at most 5 s) and carries `rv`; the exchange runs
  inside `rv_msg` when no LAN window shows. `PairingController` moved to `HLAppCore` behind `PairingHost` so the
  iPhone shares it.
- **Mac app**: the relay services built from this Mac's identity; the pair's relay registration handed to the
  manager (`relay_registered`); relay events update the record. Settings › General (per the design system's pane
  table): "Internet Connection" with the relay's problem under it (`error.relay_pin_mismatch`,
  `error.relay_device_revoked`, `error.relay_rate_limited` with the wait), "Remove Device from Server…" and the
  destructive "Delete All HandLive Data…", each with its alert (title, warning of field 29, "Remove from Server" /
  "Delete All" and "Cancel"), the E7 alert ("Delete" / "Cancel") and the result line ("Removed from the server" or
  "Couldn't connect to the server. Try again later."). Settings › Messages: SMS switch with its reason, the two
  checkboxes, "Last synced: …", "Resync All SMS…" with its confirmation, the contacts hint, the read-state caption.
  - Remove from Server: `revoke_pairs=false`, every pair kept with `relay_registered = 0`, `relay.enabled = false`
    sent in `capability/update` (C16).
  - Delete All: `revoke_pairs=true` (or E7), `pair/revoke {reinstall}` on a LAN session, then the keys, the SMS
    database, the pair store, the settings, every notification and the login item; the app starts over at the
    welcome window with new keys.
  - Setup (SET-03 step 13): `POST /v1/devices` in the background once setup is done, with the internet connection
    on; a failure is retried by the next relay use (E7).
  - Unpair (PAIR-03): a pair registered with the relay keeps a tombstone until `POST /v1/pairs/{id}/revoke` goes
    through (reason `user` after an acknowledged revoke, `lost_device` in flow B); retried at launch and on the next
    connection. Settings › Devices asks the relay about the pair when it opens.

## Commits (handlive-apple)

| Hash | Subject |
|------|---------|
| 6a956ed | feat(apple): add the relay frames, control ops, REST bodies and APNs push fields |
| fedc73b | feat(apple): add the pair registration answer and public initializers to the relay bodies |
| c9670c1 | feat(apple): call the relay REST API with a JWT over pinned TLS |
| fc6e8c4 | feat(apple): route envelopes and the pairing rendezvous through the relay connection |
| 4c26571 | feat(apple): add the relay edges for a phone that leaves or comes home |
| 038e9f1 | feat(apple): ping end to end every 30 s on sessions through the relay |
| 70a2b3d | feat(apple): connect through the relay with wake pushes and move back to the LAN |
| 1ae43e5 | feat(apple): pair through the relay rendezvous when the LAN shows no window |
| f808d5d | test(apple): test the relay client, link, pins, manager routes and rendezvous pairing |
| 545f2f2 | test(apple): check the HR frames and the relay rewrite against relay-frame.json |
| 362cc0d | test(apple): loop over the invalid relay frames with a where clause |
| b9575b3 | fix(apple): derive K_pin on a Dispatch worker so Argon2id never stalls the cooperative pool |
| 9d3407b | test(apple): derive K_pin off the pool in the tests and give manager waits ten seconds |
| c735702 | feat(apple): hand the pair's relay registration and relay switch to the manager |
| aacaa40 | test(apple): test the SMS capability and the pair's relay registration |
| 8d50b13 | feat(apple): remove every settings key for Delete All HandLive Data |
| 9d7f989 | feat(apple): report a rate-limited relay as a link issue |
| ccc7054 | feat(apple): remove the Mac from the relay, delete all its data and revoke pairs there |
| 162a94e | feat(apple): add the Messages settings pane and the server actions in General |
| 7577d18 | test(apple): test the relay account actions and the Messages settings state |
| 7764b6a | refactor(apple): share the pairing controller between the Mac and iOS |
| a0468b0 | test(apple): show the QR code without rv when the relay can't be reached |
| d702bca | feat(apple): say session/bye before every end of a relayed session |
| 1b58e42 | feat(apple): register this device again when POST /v1/pairs answers 404 |
| 21b14f5 | feat(apple): wait 24 h after a second 404 and mark a pair the relay lists as registered |
| 8a65610 | feat(apple): check the pair on the relay from Settings > Devices |
| b8fc24d | feat(apple): wait 24 h after any 4xx answer to POST /v1/pairs |
| b7bf88f | feat(apple): register with the relay when setup finishes |

## Files

`Packages/HLProtocol/Sources/HLProtocol/{RelayFrames,RelayRestMessages,RelayPairMessages}.swift`;
`Packages/HLTransport/Sources/HLTransport/{RelayConfiguration,RelayTrust,RelayHTTPTransport,RelayAPIClient,
RelayAPIClient+Calls,RelaySocketConnector,RelayLink,RelayPeerChannel,RelayServices,PairingRendezvous,
ConnectionManager*,ControlSession*,SignalQueue,ConnectionTypes,ConnectionStateMachine}.swift`;
`Packages/HLAppCore/Sources/HLAppCore/{Pairing/PairingController,AppSettings,PairedDeviceRecord}.swift`;
`Packages/HLMacUI/Sources/HLMacUI/{AppModel+Account,AppModel+Link,ServerSettingsSections,MessagesSettingsPane,
SettingsView,DevicesSettingsPane}.swift` and tests.

## Tests

```
HLTransport  (LIBDISPATCH_COOPERATIVE_POOL_STRICT=1)  ✔ Test run with 94 tests in 17 suites passed after 7.065 seconds.
HLAppCore    ✔ Test run with 49 tests in 12 suites passed after 2.196 seconds.
HLMacUI      ✔ Test run with 31 tests in 6 suites passed after 1.646 seconds.
```

CI (GitHub Actions, macos-15, Xcode 26.3): run 36233209508 on 57a9f3d — every package test, SwiftLint (0 violations
in 298 files), the Mac app and the iOS app with its extension built. Final head bc5cae8: run 36234320082 **success**.

Relay behaviour is tested against fakes (`FakeRelayAPI`, `FakeRelay`, `ScriptedRelayHTTP`, `FakeRendezvousRelay`);
the frames against `shared/test-vectors/relay-frame.json`; pins against the ISRG root certificates.

## Spec deviations and proposals

1. **Relay host and backup pin**: `HLRelayHost` (Info.plist) names `{RELAY_HOST}`; no value → the apps stay on the
   LAN (the repository sets none). Pins: ISRG Root X1 and X2; the backup SPKI pin (`HLRelayBackupPin`) waits for the
   owner's key. Proposal: write the build setting and the pin rotation into `docs/deployment-guide.md`.
2. **Settings panes**: the card says "Messages and Internet Connection" panes; the design system's Mac pane table
   (2-patterns/04-cai-dat.md) puts "Internet Connection", "Remove Device from Server…" and "Delete All HandLive
   Data…" in General, which is what the app does; Messages is its own pane.
3. **Alert titles**: the Mac alerts use `settings.remove_from_server` / `settings.delete_all_data`, whose catalog
   platforms are android and ios only. Proposal: add `macos` to both keys.
4. **State machine**: extra edges `WaitingPeer → Discovering` (the phone shows up on the LAN) and `peerOffline`
   (a relayed session ends because the phone left the relay); the LAN upgrade runs in the background and replays
   the 0.11 events when it succeeds. Proposal: add them to 0.11.
5. **`sms/send` retries** are counted per session (`unanswered` set), so a message without an `ack` after every
   retry waits for the next session (SMS-04 E1) instead of blocking the rest.
6. **Argon2id** runs on a Dispatch worker: on the Swift cooperative pool it starved the other tasks of a test run.

## Pending manual checks

- Acceptance: switching the phone from Wi-Fi to 4G still delivers messages through the relay (needs the relay
  deployed, `HLRelayHost` set and the Android relay client A2.2).
- Remove from Server and Delete All against the real relay, including E7 offline; the pair re-registration after
  turning the internet connection back on; tombstone revocation after a network comes back.
- Rendezvous pairing (QR with `rv`) with the phone on another network.

Status: DONE_WITH_CONCERNS
Summary: The Mac reaches the phone through the relay (REST, pins, `/v1/relay`, rendezvous pairing, wake pushes,
LAN upgrade) and Settings has the relay switch, Remove from Server and Delete All with their alerts; the batch 5
relay rules are in; tests green locally.
Concerns/Blockers: not run against a real relay yet (host and backup pin not configured); proposals 1, 3, 4.
