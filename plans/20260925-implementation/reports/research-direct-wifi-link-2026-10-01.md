# Research: Android ↔ Mac without a shared network — Wi-Fi Direct, hotspot, BLE (2026-10-01)

Follow-up of cloud session `session_01QqwiGV7S1RZWgFATr95MYp` ("Android-Mac WiFi kết nối trực tiếp"). Only that
session's final summary was readable (Chrome read-only); this report re-checks its conclusions and closes its open
questions. Method: AOSP `main` source, HandLive specs and code, a read-only CoreWLAN probe on this Mac (macOS 27.0,
MacBookPro18,3), installed Xcode SDKs (macOS 27.0, iOS 27.0), web sources. **No phone was attached** (`adb devices`
empty) and the Mac's only uplink is Wi-Fi `en0`, so no join test was run (it would have cut this machine off).

## 1. Verdict

Owner scenarios (confirmed 2026-10-01): **X** — both devices offline; **Y** — phone on mobile data, Mac on public Wi-Fi.

- **Wi-Fi Direct is the wrong tool for Y** and only marginal for X. In Y the Mac would have to leave the public Wi-Fi
  (one radio) and lose Internet. In X it works, but the phone's own hotspot gives the same LAN with no new code.
- **Y is already designed: the relay (CONN-03).** Both devices are online; the relay code is merged (Phase 2) but **not
  deployed** (G2 / owner inputs), so Y does not work in the current beta. Deploying the relay is the fastest unlock.
- **X works today in principle through the phone hotspot** (hotspot on, mobile data may be off; the Mac joins once and
  auto-joins later): A-SVC listens on every interface and Android 14+ advertises mDNS on the hotspot interface. Needs a
  device check (T1, T5), then at most a gateway candidate in CONN-01.
- **Calls are covered by Phase 4 itself:** HFP over Bluetooth carries call audio and answer/end/caller ID with no data
  network in both X and Y (once G4 passes).
- **The one new transport worth a spike is a BLE "nearby link"** (L2CAP CoC) that carries the same envelopes as the
  relay does: automatic, works in **both X and Y without touching either device's network**, enough for clipboard text,
  SMS and call metadata; images capped through capability negotiation (tens of KB/s).
- Independent of all this: the **Android 17 local network permission** breaks the existing LAN server when targetSdk
  reaches 37 (R2).
- Wi-Fi Direct stays as a possible later "bandwidth upgrade" in X only (after BLE), never in Y.

## 2. Corrections to the earlier session

| Earlier claim / open point | Finding | Evidence |
|---|---|---|
| Flying Carpet shows how Wi-Fi Direct behaves | Flying Carpet uses **LocalOnlyHotspot**, not Wi-Fi Direct; its Xiaomi/MIUI/HarmonyOS failures are LOHS failures. It is **GPL-3.0** → no code reuse in Apache-2.0 HandLive | FlyingCarpet README; repo tree (`ViewController.swift` imports CoreWLAN + CoreLocation) |
| "Is `192.168.49.1` the same on every OEM?" | Not guaranteed. AOSP uses `192.168.49.1/24` only when the OEM sets `config_tether_enable_legacy_wifi_p2p_dedicated_ip` (default **false**); otherwise `RoutingCoordinator.requestDownstreamAddress` picks a private prefix. Read `WifiP2pInfo.groupOwnerAddress` or, on the Mac, the joined network's gateway | `IpServer.java` (`LEGACY_WIFI_P2P_IFACE_ADDRESS`, `shouldUseWifiP2pDedicatedIp()`), `TetheringConfiguration.java` (default `false`) |
| "Does mDNS run inside a Wi-Fi Direct group?" | On the Connectivity-module mDNS stack (Android 14+ default), a registration with no `Network` opens sockets on every active network **plus** local-only (LOHS), tethered (hotspot) and the Wi-Fi P2P interface. HandLive registers without `setNetwork` → it should be advertised on all of them. Android 10–13 (native mdnsresponder) unverified | `MdnsSocketProvider.requestSocket(null)`; `NsdMdnsRegistrar.kt` (no `setNetwork`) |
| "CoreWLAN on macOS 13+ needs which permission?" | Measured on macOS 27: without Location authorization `scanForNetworks` returns networks with **SSID and BSSID nil**; `ssid()` nil; `networksetup -getairportnetwork` says "not associated"; `ipconfig getsummary` shows `<redacted>`. Picking the `CWNetwork` to `associate(to:password:)` therefore needs Location ("Allow While Using"). On 15.1+ a CLI process may stay redacted even when authorized; a GUI app with a running run loop works (Apple DTS) | probe below; Apple forum 769950 |
| Sandbox / App Store for CoreWLAN | Not a blocker: the Mac app is Developer ID + notarized, **not sandboxed** (`macOS/HandLive.entitlements` has no `app-sandbox`; deployment guide) | entitlements, `docs/deployment-guide.md` |

Probe output (macOS 27.0, CL status `notDetermined`):

```text
iface: en0  security: 4  channel: 157 band=5GHz width=40MHz
ssid(): nil  bssid(): nil
scan count: 10 withSSID: 0
```

## 3. Other verified facts

- **F1 — Android 17 local network permission (affects today's LAN mode).** Apps targeting SDK 37 need runtime
  `ACCESS_LOCAL_NETWORK` (group `NEARBY_DEVICES`) for outgoing TCP to the LAN, **accepting incoming TCP**, UDP
  multicast (mDNS) and `.local` resolution; without it packets are silently dropped (connect timeouts, `EPERM`). Apps
  targeting < 37 with `INTERNET` get an implicit grant. Android 16 opt-in test: `adb shell am compat enable
  RESTRICT_LOCAL_NETWORK <pkg>` + reboot; access returns with `NEARBY_WIFI_DEVICES`. HandLive targets 35
  (`app/build.gradle.kts:30`), so it is safe today, but the bump to 37 breaks A-SVC's server and NSD unless SET-01 asks
  for "Nearby devices". The NSD picker exemption (`FLAG_SHOW_PICKER`) does not apply: the phone is the server.
  Side effect: Wi-Fi Direct/LOHS need `NEARBY_WIFI_DEVICES`, the same group → on Android 17+ a direct mode adds no
  new permission prompt; on Android 10–12 it needs `ACCESS_FINE_LOCATION` with location services on.
- **F2 — Wi-Fi Aware is iOS/iPadOS only.** The macOS 27.0 SDK ships `WiFiAware.framework`, but every top-level declaration
  (25/25) is `@available(macOS, unavailable)`; `swiftc` on this Mac rejects `WAPairedDevice` ("unavailable in macOS"). On iOS 26+ it needs system pairing (`WAPairedDevice`); iOS 26.4 adds
  `WAConnection.deriveSharedSecret(for: .tlsPSK …)`. A future option for the second-class iOS app only; Android side
  would need Wi-Fi Aware pairing (Android 14+). Not researched further.
- **F3 — HandLive already fits a direct link.** A-SVC listens on `0.0.0.0` (`ControlServer.kt:45`); TLS is pinned by
  certificate SHA-256 with **no hostname check** (0.4.1); the Mac already tries a raw `host:port` candidate before
  mDNS (`last_host` fast path, `ConnectionManager+Run.swift:75-82`). A direct link only needs one more candidate host.
- **F4 — PCC mode (API 36).** `WifiP2pConfig.Builder.setPccModeConnectionType`: `LEGACY_ONLY`, `LEGACY_OR_R2`,
  `R2_ONLY` (R2 devices only). The Mac joins as a legacy WPA2 client → never `R2_ONLY`. Passphrase 8–63 chars.
- **F5 — `networksetup -setairportnetwork en0 <ssid> <pass>`** is reported to still join on Sonoma/Sequoia without
  reading SSIDs (only `-getairportnetwork` was neutered). Unverified on macOS 27; it would avoid the Location prompt.
- **F6 — Peers.** NearDrop: Wi-Fi LAN only (Quick Share's Wi-Fi Direct/hotspot upgrade unsupported on macOS). KDE
  Connect: Bluetooth backend shipped, on by default in recent releases. LocalSend: LAN only. None runs Wi-Fi Direct
  with a Mac.
- **F7 — BLE L2CAP CoC.** Android API 29+ (`listenUsingInsecureL2capChannel`, matches minSdk 29) ↔ CoreBluetooth
  `openL2CAPChannel`; insecure channels interoperate, secure ones are reported flaky. Real throughput tens to ~100
  KB/s: enough for clipboard text, SMS, call metadata; too slow for 5 MB images or camera.

## 4. What problem does a direct link actually solve?

| # | Situation | Today (beta) | Best answer |
|---|---|---|---|
| **X** | **Both offline** (owner) | Nothing | Now: **phone hotspot (A)** with mobile data off. Next: **BLE nearby link (D)**, automatic. Later, optional: Wi-Fi Direct upgrade for images (B) |
| **Y** | **Phone on mobile data, Mac on public Wi-Fi** (owner) | Nothing — relay not deployed | Now: **deploy the relay (G)**; or the user moves the Mac to the phone hotspot (A). Next: **BLE (D)** without relay or mobile data. Never B/C (Mac would lose the public Wi-Fi) |
| S1 | Same Wi-Fi, mDNS works | LAN (CONN-01) | — |
| S2 | Same Wi-Fi, client isolation / mDNS blocked (hotel, office, guest) | Nothing until the relay is deployed | Relay; BLE when nearby |
| S3 | Phone on cellular, Mac with no network at all | Nothing | Hotspot (A): Mac gets Internet *and* a LAN with the phone |
| S5 | Camera/mic (P5) without a shared LAN | Planned USB | **USB (E)**; a Wi-Fi Direct link would drop the video call's Internet |

Per feature in X and Y:

| Feature | X (both offline) | Y (cellular + public Wi-Fi) |
|---|---|---|
| Call audio, answer/end, caller ID | HFP over Bluetooth (Phase 4, G4) — no data network needed | Same |
| Call notifications/metadata (CALL-04) | Hotspot or BLE | Relay, hotspot or BLE |
| SMS | Hotspot or BLE | Relay, hotspot or BLE |
| Clipboard text | Hotspot or BLE | Relay, hotspot or BLE |
| Clipboard images (≤ 10 MiB) | Hotspot (BLE too slow; Wi-Fi Direct upgrade later) | Relay (2 MiB/s cap, uses mobile data) or hotspot |
| Camera/mic | USB | USB |

## 5. Options

| Option | Mac keeps Internet | Android app-controlled | Mac joins via | Bandwidth | Cost |
|---|---|---|---|---|---|
| A. Phone hotspot (user turns on tethering) | **Yes** (cellular) | No — third-party apps cannot toggle tethering | User, once; macOS auto-joins known networks | Wi-Fi | Low: verify + gateway candidate |
| B. Wi-Fi Direct autonomous GO | No (unless Ethernet) | Yes, SSID/passphrase settable (API 29+) | CoreWLAN + Location, or `networksetup` | Wi-Fi, no AP hop | High: new spec, both apps, drops (macOS rejoins Internet Wi-Fi) |
| C. LocalOnlyHotspot | No | Yes, but SSID/passphrase random | Same as B, credentials must be sent | Wi-Fi | High; OEM gaps (Xiaomi/HarmonyOS) |
| D. BLE L2CAP | Yes — neither device changes network | Yes | CoreBluetooth | tens of KB/s | Medium-high: new transport + framing |
| E. USB adb forward (0.4.2) | Yes | n/a | adb host protocol | Highest | Already planned (P5); needs USB debugging on |
| F. Wi-Fi Aware | Yes (concurrent) | Yes | — | Wi-Fi | **Impossible on Mac** (F2) |
| G. Relay (CONN-03) | Yes | Yes | Internet on both | 2 MiB/s per pair | Code merged; **deployment pending** (VPS, APNs, FCM) |

Only **D** serves both owner scenarios automatically without changing any network; **A** serves both today with a manual
toggle; **G** serves Y only; **B/C** serve X only.

## 6. Recommendation

Order: R0–R2 need no new transport; R3 is the new transport; R4 is optional.

- **R0 — Deploy the relay (Y, S2).** Already designed and merged; blocked on owner inputs (`phase-02-merge.md`: relay
  host and pins, APNs key, Firebase). Public Wi-Fi notes: a captive portal blocks the relay until the user signs in
  (retry on path change, already in CONN-02); the relay is on 443, rarely blocked.
- **R1 — Phone hotspot as the zero-code answer for X (and a user choice in Y).**
  1. Verify on the S25 (T1, T5) that a hotspot with **mobile data off** turns on (carrier entitlement checks may refuse),
     that `_handlive._tcp` is visible to the Mac, and that A-SVC accepts on the tether interface.
  2. Only if T1/T2 show gaps: add a third candidate to CONN-01 step 2, the **default gateway of the Mac's Wi-Fi path**
     (`NWPath.gateways`), through the same pinned TLS (1–2 s timeout). It covers Android 10–13 if their mDNS skips
     tether interfaces and the hotspot prefix changing per session; it also serves B/C later (the gateway *is* the
     phone).
  3. UX: the Mac's E3 text ("Put both devices on the same Wi-Fi network…") also suggests the phone's hotspot; Android
     offers "Open Hotspot Settings" (third-party apps cannot toggle tethering); respect `NWPath.isExpensive` for images.
- **R2 — Android 17 local network permission (independent, applies to every LAN feature).** Add `ACCESS_LOCAL_NETWORK`
  to the permission model and SET-01 onboarding before targetSdk 37; test now on the S25 (Android 16) with the compat
  flag (T3). Record it in `00-common-specs` and the deployment guide.
- **R3 — BLE nearby link: spike, then spec (X and Y, automatic, no network change).**
  - Transport: Android A-SVC is a BLE peripheral (advertising + `listenUsingInsecureL2capChannel`, minSdk 29 OK); the
    Mac is the central (`CBPeripheral.openL2CAPChannel`). PSM published in a GATT characteristic (or service data).
  - Discovery and privacy: a fixed HandLive service UUID (like the fixed `_handlive._tcp`) plus the **rotating hourly
    hint** of 0.4.1 in service data; Android randomizes its BLE address.
  - Security: **reuse the relay trust model** — no Bluetooth bonding, insecure L2CAP, then the 0.6.3 session handshake
    (PRK HMAC + ephemeral X25519), which never relied on TLS. Errors before the handshake authenticates follow the
    CONN-03 E9 rule (never unpair).
  - Framing: length-prefixed frames on the L2CAP stream carrying the text envelope or the binary HL frame (the relay
    wrapper minus routing).
  - Bandwidth: declare reduced limits in `capability/hello` for a BLE session (images off or a small
    `max_image_bytes`; no call-audio/camera streams); feature gating already handles it.
  - Priority: one `/v1/ctl` session per pair stays the rule; LAN > relay > BLE, with upgrade when a better path shows
    up (as CONN-02 does for relay → LAN). Owner may prefer BLE over relay in Y to save mobile data.
  - Permissions: Android 12+ `BLUETOOTH_ADVERTISE` + `BLUETOOTH_CONNECT` (group "Nearby devices", the same prompt as
    R2); Android 10–11 install-time only. Mac: the Bluetooth TCC prompt that Phase 4 HFP needs anyway.
  - Spike (T6): Android ↔ Mac L2CAP throughput and stability, A-SVC advertising in the background on One UI,
    coexistence with an active HFP call. Then `00-common-specs` 0.4.5 + a CONN leaf before any product code.
- **R4 — Optional later: Wi-Fi Direct bandwidth upgrade in X only** (the Quick Share pattern: BLE first, Wi-Fi for bulk):
  - Only when the Mac's Wi-Fi is not associated (X) — never in Y.
  - SSID `DIRECT-hl-<hint>` and passphrase derived from the pair key, e.g. `HKDF(PRK, info = "handlive/v1/direct-wifi"
    ‖ hour)`: no credential exchange needed, nothing stable on air, and a rogue AP cannot finish the WPA2 4-way
    handshake. The BLE link can ask the phone to start the group.
  - The Mac joins (CoreWLAN + Location, or `networksetup`, T4) and connects to the gateway; `LEGACY_OR_R2` on API 36.
  - Wi-Fi Aware for iPhone/iPad stays a separate research item (F2).

## 7. Hardware checks (owner + S25 + this Mac)

| # | Check | Steps | Pass |
|---|---|---|---|
| T1 | Hotspot path (safe: the Mac stays online via cellular) | Turn on the S25 hotspot, join it from the Mac; `dns-sd -B _handlive._tcp`; `route -n get default`; `nc -vz <gateway> 47800`; open HandLive | Instance visible; port open; HandLive connects with no code change |
| T2 | Same on an Android 10–13 phone or emulator with tethering | As T1 | Tells whether the gateway candidate is required |
| T3 | Android 17 LNP rehearsal on Android 16 | `adb shell am compat enable RESTRICT_LOCAL_NETWORK <pkg>`; reboot; connect from the Mac; then grant Nearby devices | Fails without, recovers with the permission |
| T4 | Wi-Fi Direct (only if R4 goes ahead; needs Ethernet on the Mac or an accepted outage) | Probe app creates a group with a fixed `DIRECT-hl-…`; Mac joins with `networksetup -setairportnetwork`; connect to the gateway | Join without a Location prompt; link survives 30 min; note macOS rejoining the Internet Wi-Fi |
| T5 | Scenario X rehearsal | S25: mobile data off, Wi-Fi off, hotspot on; Mac: join it (Mac offline for the test) | Hotspot starts without data; HandLive connects; clipboard text + image + SMS work |
| T6 | BLE spike (R3) | Probe pair: Android peripheral + L2CAP server, Mac central; 1 KB and 1 MB transfers; screen off 10 min; during an HFP call | Throughput and drop rate recorded; background advertising survives on One UI |

## 8. Documents to change if the owner accepts (none changed yet)

- `docs/detailed-design/00-common-specs.md` (+ `.vi.md`): 0.4.1 note on hotspot/gateway candidate; permission table
  row for `ACCESS_LOCAL_NETWORK`; after T6, 0.4.5 BLE nearby link (frames, advertisement, PSM, limits) and a state for
  it in the 0.11 state machine.
- `docs/detailed-design/03-connectivity.md` (+ `.vi.md`): CONN-01 step 2 (c) gateway candidate, E3/E7 wording; after
  T6, a new leaf for the BLE link.
- `plans/20260925-implementation/plan.md` (+ `.vi.md`): a gate for the BLE spike next to G4–G6, if the owner agrees.
- `docs/detailed-design/01-setup-settings.md` (+ `.vi.md`): SET-01 Nearby devices on Android 17+.
- `docs/deployment-guide.md` (+ `.vi.md`): targetSdk 37 prerequisite.
- `shared/strings/ui-strings.json`: hotspot status line (en + vi).

## Sources

- [Android — Local network permission](https://developer.android.com/privacy-and-security/local-network-permission)
- AOSP Connectivity `main`: [`IpServer.java`](https://android.googlesource.com/platform/packages/modules/Connectivity/+/refs/heads/main/Tethering/src/android/net/ip/IpServer.java),
  [`TetheringConfiguration.java`](https://android.googlesource.com/platform/packages/modules/Connectivity/+/refs/heads/main/Tethering/src/com/android/networkstack/tethering/TetheringConfiguration.java),
  [`MdnsSocketProvider.java`](https://android.googlesource.com/platform/packages/modules/Connectivity/+/refs/heads/main/service-t/src/com/android/server/connectivity/mdns/MdnsSocketProvider.java)
- [WifiP2pConfig.Builder](https://developer.android.com/reference/android/net/wifi/p2p/WifiP2pConfig.Builder)
- [Apple forum 769950 — CoreWLAN SSIDs nil on 15.1](https://developer.apple.com/forums/thread/769950);
  [Apple forum 787701 — no Wi-Fi Aware on macOS 26](https://developer.apple.com/forums/thread/787701)
- Local SDKs: `MacOSX27.0.sdk` / `iPhoneOS27.0.sdk` `WiFiAware.framework` swiftinterface
- [Flying Carpet](https://github.com/spieglt/FlyingCarpet) (GPL-3.0), [NearDrop](https://github.com/grishka/NearDrop),
  [KDE Connect Bluetooth backend](https://www.phoronix.com/news/KDE-Connect-Bluetooth-Backend)
- [Apple forum 89644 — L2CAP throughput](https://developer.apple.com/forums/thread/89644);
  [Cross-platform offline-first apps with BLE](https://octet-stream.net/b/scb/building-cross-platform-offline-first-apps-with-ble.html)

## Unresolved questions

1. Owner: in Y, should a nearby BLE link win over the relay (saves mobile data, no images) or only serve as fallback?
2. Owner: add a BLE spike gate now, or after G4 (it shares the Mac Bluetooth permission and radio with HFP)?
3. Does the S25 hotspot start with mobile data off (carrier entitlement)? (T5)
4. Does Android 10–13 (native mdnsresponder) advertise on tether interfaces? (T2)
5. Does Samsung One UI apply hotspot client isolation toward the phone itself? (T1)
6. Only if R4: does `networksetup -setairportnetwork` join on macOS 27 without Location? (T4)

```text
Status: DONE_WITH_CONCERNS
Summary: For the owner's scenarios (both offline; phone cellular + Mac public Wi-Fi), Wi-Fi Direct is dropped as the
main path: deploy the relay (Y), use the phone hotspot now (X), spike a BLE L2CAP nearby link for both, prepare the
Android 17 local network permission.
Concerns/Blockers: no device test run (no phone attached, Mac on Wi-Fi only); BLE throughput Android ↔ Mac unmeasured.
```
