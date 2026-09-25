# Phase 1 — A1.1 [android]: HandLiveService, mDNS with hourly hints, session upkeep

Card A1.1 of `phase-01-bang-nho-tam-mvp.md` (CONN-01 API 1, C6, CONN-02, SET-01 API 3). Repository handlive-android, branch `feat/phase-01-clipboard`, pushed; CI green.

## What was done

New module `feature/connection` (A-SVC):

- **`HandLiveService`** — foreground service type `connectedDevice` (`FOREGROUND_SERVICE_CONNECTED_DEVICE`, `CHANGE_NETWORK_STATE` as the Android 14 prerequisite, `INTERNET`, `ACCESS_NETWORK_STATE`, `RECEIVE_BOOT_COMPLETED`, `POST_NOTIFICATIONS`). `startForeground` is the first thing `onStartCommand` does (the 5 s rule); a refusal (`ForegroundServiceStartNotAllowedException`, `SecurityException`) marks the service `FAILED` for the SET-01 E2 retry. `START_STICKY` (CONN-02 E6). `ServiceRestartReceiver` restarts it on `BOOT_COMPLETED`/`MY_PACKAGE_REPLACED` once setup is complete; `ServiceLauncher` starts/stops it from the UI.
- **Notification** (`hl_service`, "Connection service", `IMPORTANCE_LOW`, no badge; channels `clipboard` and `permission` are created with it, all names and descriptions from the catalog): no title of its own, "Waiting for a connection" / "Connected to <client>" / "Connected to N devices" (plural), the "Send Clipboard" action (installed by the clipboard feature through `ServiceHooks`), tap opens the app, silent, ongoing, `FOREGROUND_SERVICE_IMMEDIATE`. Text updates follow the connected clients.
- **`ConnectionRuntime`** (one per process): loads identity and TLS keys off the main thread, starts the TLS server on 47800–47809, serves `/v1/pair` through a pluggable `PairingEndpoint`, tracks sessions (`sessions`, `connectedPeers`, `sessionEnded` with the peer's bye reason), records `last_seen_at` + `features_json` when a client connects or updates its capability, and says `session/bye {shutdown}` to every client when stopped.
- **Capability** (0.7.2, SET-02 API 1): `LocalCapabilityBuilder` — Phase 1 advertises `clipboard` (enabled, `auto_send` = setting ∧ Accessibility service running, 1 MiB / 10 MiB limits, `mimes` without images when `clip.send_images` is off) and `relay.enabled`; SMS, call, call audio and camera are absent (not implemented yet = off for every peer). `permissions_missing` holds `POST_NOTIFICATIONS` when missing on Android 13+. `CapabilityPublisher` recomputes on every settings/Accessibility/permission change and sends one full `capability/update` per session, coalescing 300 ms.
- **mDNS** (`DiscoveryAdvertising`, `MdnsAdvertiser`, `NsdMdnsRegistrar`): `_handlive._tcp`, instance `HL-<6 random hex>` new at every start, TXT `v=1`, `h` = the hourly hint of every active pair (at most 8), `pr`/`pm` during a pairing window. `DiscoveryHints`: `K_disc` = HKDF(`PRK`, "handlive/v1/discovery"), hint = 8 lowercase hex of HMAC(`K_disc`, "HLDISC1" ‖ int64 BE hour). The advertisement is rebuilt on pair changes, just after every hour boundary, on pairing windows and on default-network changes; TXT changes unregister/register at most once per second; failures retry after 5 s, 30 s, then every 5 min.
- **Session upkeep on the phone's side (CONN-02):** clients ping, the phone answers (raw frames, A1.0) and closes silent sessions after 45 s (4411); rekey 4410 (A1.0); `ping/ping` (relay E2E ping) is answered with `{seq, server_ts}`; a new default network re-registers mDNS so clients find the phone quickly; the service restarts itself (`START_STICKY`, boot/update receiver). Client-side backoff belongs to the Mac.
- **Envelope routing** (`SessionRouter`, `PeerSession`, 0.5.1): `ack`s complete requests by `id` (senders choose the UUIDv7 `id` so the waiter exists before the envelope leaves; 10 s `REQUEST_TIMEOUT`); a repeated `id` (5 min / 1 000) gets its old `ack` and is not processed again; a type without a handler gets `UNSUPPORTED_TYPE` when the op is a request of 0.7.1 and is ignored when it is an event.
- **Bench hooks** (controller request, `shared/tools/bench`): `BenchLog` writes `HLBENCH/1 wall= mono= dev= role=android ev=…` with `Log.i("HLBENCH", …)` in debuggable builds only; `net` events `up`/`down`/`changed` come from the default network callback.
- **Device test** `ServiceDiscoveryDeviceTest` (not run, no device): the runtime starts and `_handlive._tcp` with TXT `v=1` on port 47800–47809 is discovered and resolved within 2 s.

## Commits (handlive-android)

| Hash | Subject |
|------|---------|
| 754f442 | feat(android): serve /v1/pair on the control server port |
| 7e06b13 | feat(android): run the connection service with mDNS hints and capability |
| dabb1f3 | test(android): cover discovery hints, advertising, capability and routing |
| 16b0bdb | test(android): add a device test for discovery within two seconds |
| bbf5038 | feat(android): create notification channels at process start |
| df40def | feat(android): write HLBENCH/1 lines in debug builds |
| 226295b | feat(android): report ended sessions with the peer's bye reason |
| 27fae4f | test(android): check the service notification texts and channels |

## Files

Created: `feature/connection/**` — `HandLiveService.kt`, `ServiceLauncher.kt`, `ServiceRestartReceiver.kt`, `ConnectionRuntime.kt`, `ConnectedPeer.kt`, `capability/{LocalCapabilityBuilder,LocalEnvironmentReader,CapabilityPublisher}.kt`, `discovery/{DiscoveryHints,MdnsTxtRecord,MdnsAdvertiser,NsdMdnsRegistrar,DiscoveryAdvertising}.kt`, `session/{PeerSession,SessionRouter,ProcessedEnvelopeCache}.kt`, `notification/{NotificationChannels,ServiceNotification}.kt`, `bench/BenchLog.kt`, manifest, tests; `app/.../HandLiveApplication.kt`; `core/transport/.../server/PairingEndpoint.kt`, `PeerCapabilityState.kt`.
Changed: `settings.gradle.kts`, `gradle/libs.versions.toml` (androidx.core), `app/build.gradle.kts`, `app/src/main/AndroidManifest.xml`, `core/transport` (`ControlServer` pair route and data-class config, `ControlSession` caller-chosen id and bye reason, `ControlSessionDispatcher`, `EncryptedEnvelopeChannel`).

## Tests (real output)

```text
$ ./gradlew :feature:connection:check
BUILD SUCCESSFUL in 15s
DiscoveryHintsTest tests=3        (K_disc and hints of pair-prk.json match values computed independently in
                                   Python — the same values the Mac's HLCrypto tests use; hour boundaries; ≤ 8 hints)
MdnsAdvertiserTest tests=4        (TXT keys; two changes within 1 s → one re-registration; retries at 5 s, 30 s,
                                   5 min; a new network generation forces a fresh registration)
LocalCapabilityBuilderTest tests=4
SessionRouterTest tests=6         (ack completes the request; timeout; duplicate id → same ack, handler once;
                                   unknown request → UNSUPPORTED_TYPE, unknown event ignored; ping → seq, server_ts;
                                   processed ids expire after 5 min)
ServiceNotificationTest tests=4   (en and vi texts; hl_service/clipboard/permission IMPORTANCE_LOW, names)
BenchLogTest tests=2
$ ./gradlew :feature:connection:assembleDebugAndroidTest → BUILD SUCCESSFUL
```

## Spec deviations and proposals

1. **Features not implemented yet are absent from the capability**, not `enabled: false`. The settings keys `feature.sms`/`feature.call` exist with their defaults but have no effect until Phase 2/3. `permissions_missing` therefore lists only `POST_NOTIFICATIONS`.
2. **Instance name** stays `HL-<6 hex>` for the whole service lifetime and changes at every service start (0.4.1); TXT changes re-register under the same name.
3. **Hint discovery vector.** No shared vector covers `K_disc`/hints; Android and the Mac both test against values computed independently with Python from `pair-prk.json` and they agree. Proposal: add `discovery-hint.json` to `shared/test-vectors` (S-card).
4. **The service is not started by the UI yet**: SET-01 (A1.4) starts it; the boot receiver starts it once `setup.completed_at` is set.
5. **Waiting-state text.** Catalog/SET-01 "Waiting for a connection" is used (the design system's "HandLive is waiting…" contradicts its own no-"HandLive" rule; S1.2 item 4).

## Pending manual checks

- Pixel and Samsung, Android 14/15 and 13: the Mac finds the phone within 2 s (`ServiceDiscoveryDeviceTest` plus a real Mac browse), the hint in TXT `h` changes at the hour, the TXT changes within ~1 s when a pair is added or removed, re-registration after switching Wi-Fi networks.
- The ongoing notification in both languages; Android 14 lets the user swipe it away and it comes back on the next connection change.
- Service restart after reboot and after an app update; OEM battery killers (Xiaomi, OPPO) with and without the battery exemption.
- Bench: `adb logcat -s HLBENCH` shows `net` lines on Wi-Fi off/on.

```text
Status: DONE_WITH_CONCERNS
Summary: feature:connection runs HandLiveService (connectedDevice, hl_service notification with catalog texts), the TLS server on 47800–47809 with /v1/pair, mDNS with hourly hints re-registered on pair/hour/network changes, capability updates, envelope routing with ack correlation and de-duplication, and HLBENCH logging; unit tests green, device test written.
Concerns/Blockers: discovery time, notification behaviour and restarts are unverified on real phones; no shared vector for the discovery hint.
```
