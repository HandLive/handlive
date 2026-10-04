---
type: brainstorm-report
date: 2026-10-01
status: approved-design
modes: none (no --html, no --wiki)
inputs:
  - plans/20260925-implementation/reports/research-direct-wifi-link-2026-10-01.md
roadmap: after gates G4, G5, G6 close (owner decision 2026-10-01)
---

# Brainstorm: "Connect anywhere" — automatic Android ↔ Mac link without changing Wi-Fi

Vietnamese twin: `phase-07-brainstorm.vi.md`.

> **Note (2026-10-01, after the red-team review):** parts of this design are superseded — the Bluetooth link needs its own link-security layer, admission policy and route-based pre-auth rule (it does not reuse the relay trust model as is); the relay cap is not raised; bonding auto-confirms only on an E2E-verified value and flow (a) is dropped; Wi-Fi Direct is on demand only; AC1 keeps the LAN target < 50 ms; AC7 is relaxed for Android 10–12; AC8–AC10 were added; after validation, AC3 in X allows ≤ 10 s for the first image and HFP bonding starts right after QR pairing. The authoritative plan is `../phase-07-ket-noi-moi-noi.md`.

## 1. Summary

The owner wants HandLive to connect the phone and the Mac by itself everywhere, with no manual network steps, and
**without either device ever leaving its current Wi-Fi**. Approved design: an automatic transport ladder with two
lanes. The **control lane** (`/v1/ctl`: clipboard text, SMS, calls) rides LAN → Bluetooth → relay. A new **bulk lane**
(`/v1/stream/bulk`, images) rides LAN → Wi-Fi Direct (only while the Mac's Wi-Fi is not associated) → relay →
Bluetooth. Five new components, split into sub-projects SP0–SP5, start after G4/G5/G6 close.

## 2. Problem first

- **Solution jump:** "auto-open host, auto-connect" was the owner's starting point.
- **Underlying problem:** after the first QR scan, HandLive must keep working wherever the user is, with zero user
  steps, and must never cost the user the network they are on.
- **Problem statement:** a user moving between home, office, café and plane loses HandLive whenever the phone and Mac
  are not on the same LAN (today only LAN works; the relay is merged but not deployed), and the fixes found so far
  (hotspot, manual Wi-Fi join) need manual steps or cut the Mac off the Internet. Success: in scenarios X and Y the
  features work with no user action and no Wi-Fi change.
- **Three framings considered:**
  - A — "a network problem": put both devices on one network (hotspot, Wi-Fi Direct). Rejected as the main path: the
    Mac has one Wi-Fi radio, so joining any phone network drops its current Wi-Fi.
  - B — "a server problem": route everything through the relay. Needed for distance, useless when both are offline.
  - C — "a proximity problem": when the devices are near each other, use a radio that does not touch Wi-Fi
    (Bluetooth), and use Wi-Fi Direct only when the Mac's Wi-Fi is idle. **Chosen**, combined with B.
- **Evidence status:** medium — owner's own daily scenarios (X, Y) + verified platform constraints; no user data.
- **Kill criteria:** SP0 shows Bluetooth between S25 and Mac below the 200 ms text target on an established link, or
  background advertising on One UI not surviving → fall back to relay + LAN only.

## 3. Requirements (agreed)

**Scenarios:** X — both offline. Y — phone on mobile data, Mac on public Wi-Fi. Plus existing LAN and long-distance.

**Acceptance criteria:**

| # | Criterion |
|---|---|
| AC1 | Text (clipboard; SMS and call notifications ride the same lane): **≤ 200 ms** from copy to available on the other device, on an already established link (LAN, Bluetooth; relay best effort) |
| AC2 | Reconnect **≤ 3 s** after the devices come into range or a network changes |
| AC3 | Image 5 MB: **≤ 2 s** on LAN and in X (Wi-Fi Direct kept up while the Mac's Wi-Fi is idle). Y: bounded by the phone's mobile upload; relay cap raised; measured and reported. Bluetooth only: background transfer, no time commitment |
| AC4 | No device ever changes or loses its current Wi-Fi association; the Mac joins Wi-Fi Direct only when its Wi-Fi is not associated; HandLive never toggles radio power |
| AC5 | Bluetooth bonding for HFP started by HandLive: target ≤ 1 tap on the phone, 0 clicks on the Mac (to confirm in SP0) |
| AC6 | First pairing with both devices offline (QR over BLE): target ≤ 15 s from scan to Paired (to confirm) |
| AC7 | Only one-time OS prompts at setup: Mac — Local Network, Bluetooth, Location; Android — Nearby devices (plus existing ones) |

**In scope:** Bluetooth link, offline first pairing, automatic HFP bonding, Wi-Fi Direct bulk upgrade, multi-path bulk
lane. **Out of scope:** iPhone/iPad (Wi-Fi Aware), camera/mic (USB path), relay operations. **Parallel tracks, not
part of this phase:** relay deployment (G2 inputs), Android 17 `ACCESS_LOCAL_NETWORK`.

**Constraints:** spec first in the hub (`00-common-specs`, leaf specs, bilingual), Apache-2.0 only, minSdk 29,
macOS 13+, E2E always on, one `/v1/ctl` session per pair, UI strings from the catalog.

## 4. Platform facts that shape the design (verified)

| Fact | Consequence | Evidence |
|---|---|---|
| Mac has one Wi-Fi radio; macOS has no Wi-Fi Direct/P2P API for non-Apple peers; Wi-Fi Aware is `unavailable` on macOS 27 | Wi-Fi Direct only when the Mac's Wi-Fi is idle | SDK swiftinterface; `swiftc` error |
| Android can keep its Wi-Fi while hosting a P2P group (STA + P2P concurrency); apps cannot enable tethering | Phone hosts Wi-Fi Direct, never a real hotspot | Android APIs |
| CoreWLAN without Location: scan returns SSID nil, scan-by-name returns 0 even for the current network | Mac auto-join needs Location (accepted) or `networksetup` | probe on this Mac, macOS 27 |
| Session handshake 0.6.3 is authenticated by `PRK`, not by TLS | Any byte pipe (BLE, RFCOMM) can carry `/v1/ctl` like the relay does | `00-common-specs` 0.6.3 |
| macOS 27 SDK: `IOBluetoothDevicePair` with `devicePairingUserConfirmationRequest:numericValue:` + `replyUserConfirmation:`; `openRFCOMMChannelSync`, classic `openL2CAPChannelSync` | Mac can start bonding and confirm by itself | SDK headers |
| Android `setPairingConfirmation` needs a system permission | At least one tap on the phone to bond | Android API |
| Apps cannot turn Wi-Fi on (API 29+) or Bluetooth on silently (API 33+) | Radio off → degrade, optionally one-tap system panel | Android API |
| AOSP mDNS advertises on P2P/tether interfaces (Android 14+); P2P GO address not fixed | Use the gateway of the joined network, not `192.168.49.1` | AOSP `MdnsSocketProvider`, `IpServer` |

## 5. Approaches evaluated

| Approach | Pros | Cons | Verdict |
|---|---|---|---|
| 1. Full ladder (LAN → Bluetooth → relay; Wi-Fi Direct bulk upgrade) | Meets X and Y with no network change; Quick Share-proven pattern | Two new transports, multi-path | **Chosen**, phased |
| 2. Bluetooth + relay only | One new transport, no Location prompt | No fast images when both offline (fails AC3 in X) | Rejected by AC3 |
| 3. Always-on Wi-Fi Direct host, no Bluetooth | Fewer radios | Battery, useless in Y, breaks AC4 when the Mac is on Wi-Fi, no signalling channel | Rejected |
| Hotspot / manual join | Zero code | Manual steps, Mac loses its Wi-Fi | Rejected (owner rule) |

## 6. Final design

**Invariant:** HandLive never moves a device off its current Wi-Fi and never toggles radio power.

**Routing:**

| Situation | Control lane | Bulk lane (images) |
|---|---|---|
| Same LAN | LAN | LAN |
| X, Mac Wi-Fi idle | Bluetooth | Wi-Fi Direct (kept up while X holds), else Bluetooth in background |
| X, Mac on a Wi-Fi without Internet | Bluetooth | Bluetooth in background (Mac Wi-Fi not idle) |
| Y, devices near each other | Bluetooth | Relay (cap raised), else Bluetooth in background |
| Same Wi-Fi with client isolation, near | Bluetooth | Relay |
| Far apart, both online | Relay | Relay |

Control-lane priority: LAN > Bluetooth > relay (owner: Bluetooth before relay saves mobile data). Upgrade when a better
path appears, as CONN-02 does today for relay → LAN.

**Components:**

1. **Bluetooth link (control lane).** Android A-SVC advertises a fixed HandLive service UUID with the rotating hourly
   hint (0.4.1 `h`) in service data; the Mac scans, matches and connects. The link carries length-prefixed frames
   (text envelope or binary HL frame — the relay wrapper without routing) and runs the 0.6.3 handshake without TLS.
   Pre-authentication errors never unpair (CONN-03 E9 rule). Data bearer — **BLE L2CAP CoC or classic RFCOMM — chosen
   by SP0 numbers.** The link is kept up while no LAN session exists (AC1/AC2).
2. **Offline first pairing (QR over BLE).** No QR change: while in QR pairing mode the phone advertises the `pr` hint
   (SHA-256 of `pk`) over BLE; the Mac finds it and runs PAIR-01 in its rendezvous variant (as through the relay, no
   TLS). PIN pairing stays LAN-only.
3. **Automatic classic bonding (HFP).** After HandLive pairing, when no bond exists, HandLive starts Bluetooth bonding;
   the Mac uses `IOBluetoothDevicePair` and confirms the numeric value itself after checking it against the value the
   phone sends over E2E. Candidate flows to test in SP0: (a) Mac-initiated after the phone becomes discoverable,
   (b) phone-initiated to the Mac address (`IOBluetoothHostController.addressAsString`), (c) cross-transport key
   derivation from a BLE bond. Pick the one meeting AC5.
4. **Wi-Fi Direct bulk upgrade (X only).** When the Mac's Wi-Fi is not associated and the devices are linked over
   Bluetooth, the control lane asks the phone to host a group: SSID `DIRECT-hl-<hint>`, passphrase
   `HKDF(PRK, "handlive/v1/direct-wifi" ‖ hour)`, `LEGACY_OR_R2` on API 36. The Mac joins (CoreWLAN with Location),
   connects to the gateway with the pinned TLS certificate, and keeps the group while X holds (AC3). It leaves as soon
   as the Mac's own Wi-Fi associates elsewhere.
5. **Multi-path bulk lane.** New stream channel `/v1/stream/bulk`, keys from `K_stream` (0.6.3 step 7, channel `bulk`),
   carrying the existing clipboard chunk envelopes. Runs over LAN, Wi-Fi Direct, relay (binary `HR` frames; relay rate
   cap raised for AC3) or Bluetooth. Capability negotiation tells the peer which bulk paths exist.

**Failure handling:** Bluetooth off → no proximity link, relay/LAN only, optional one-tap enable prompt on Android, a
status note on the Mac. Phone Wi-Fi off in X → images over Bluetooth in background, optional one-tap Wi-Fi panel.
Location denied on the Mac → no Wi-Fi Direct, images over Bluetooth. Relay not deployed → Y images over Bluetooth.

**Security and privacy:** no device name or stable ID on air (fixed service UUID + hourly hint, Android random address,
hourly SSID); everything E2E with the existing keys; insecure L2CAP/RFCOMM authenticated by the session handshake;
WPA2 group passphrase derived from `PRK` (a rogue AP cannot finish the 4-way handshake); bonding numeric value bound to
the E2E channel; rate-limit pre-auth connections.

**Permissions (one-time, accepted):** Mac — Local Network, Bluetooth, Location; Android 12+ — `BLUETOOTH_ADVERTISE`,
`BLUETOOTH_CONNECT`, `BLUETOOTH_SCAN` if needed, `NEARBY_WIFI_DEVICES` (one "Nearby devices" prompt); Android 10–12 —
`ACCESS_FINE_LOCATION` for Wi-Fi Direct.

## 7. Sub-projects and order (after G4/G5/G6)

| SP | Content | Depends on | Gate / output |
|---|---|---|---|
| SP0 | Spike: BLE L2CAP vs RFCOMM throughput/latency S25 ↔ Mac, background advertising on One UI, coexistence with an HFP call, bonding flows (a)(b)(c), Mac joining Wi-Fi Direct (CoreWLAN + `networksetup`), battery of a kept group | G4 closed | Spike report; bearer choice; AC numbers confirmed |
| SP1 | Bluetooth control link + `.bluetooth` route in the state machines | SP0 | Spec 0.4.5 + CONN leaf, then code |
| SP2 | Offline first pairing over BLE | SP1 | PAIR-01 variant |
| SP3 | Bulk lane `/v1/stream/bulk` multi-path (+ relay cap change) | SP1 | Spec + relay change |
| SP4 | Wi-Fi Direct bulk upgrade (X) | SP3 | Spec + both apps |
| SP5 | Automatic classic bonding for HFP | SP0, Phase 4 product cards | 07-call-audio update |

## 8. Risks

| Risk | Impact | Mitigation |
|---|---|---|
| One UI throttles background BLE advertising | AC2 fails | Foreground service already `connectedDevice`; SP0 measures; classic page-scan as alternative |
| IOBluetooth legacy fragility (shared with HFP) | Classic bearer unusable | SP0 compares with BLE; keep bearer behind an interface like `CallAudioRelay` |
| macOS asks the user before joining an unknown network or rejoins another one | AC3 in X | SP0 tests both join paths; treat Wi-Fi Direct as opportunistic |
| Relay upload over mobile data too slow for 5 MB | AC3 in Y | Accepted: Y bounded by uplink; report measured numbers |
| Multi-path adds state complexity | Bugs, delay | Bulk lane reuses the stream-channel mechanism; one control session per pair stays |
| Pairing-key broadcast not readable on Android without a system permission | AC5 (needs a visual compare) | SP0 tests; fallback: user compares codes once |

## 9. Validation

Per sub-project: unit tests on frames and key derivation (shared test vectors first), the existing e2e harness
extended with a fake Bluetooth pipe, then real-device runs on S25 + this Mac for X and Y: AC1 and AC3 timed with the
bench log (`BenchLog`), AC4 checked by recording the Wi-Fi association before/after on both devices.

## 10. Documents to change (spec first, none changed yet)

`00-common-specs` 0.4.5 (Bluetooth link), 0.4.6 (Wi-Fi Direct bulk), 0.6.3 step 7 (`bulk` channel), 0.11 state
machine; `02-pairing` (BLE rendezvous); `03-connectivity` (new CONN leaves); `04-clipboard` CLIP-03 (bulk lane);
`07-call-audio` (bonding); `01-setup-settings` (permissions); relay rate cap; `plan.md` new phase; UI strings.

## 11. Next steps

1. Close G4/G5/G6 (owner hardware).
2. Plan written: `plans/20260925-implementation/phase-07-ket-noi-moi-noi.md` (tests-first).
3. Keep the parallel tracks moving: relay deployment, Android 17 permission.

## Unresolved questions

1. AC5 and AC6 thresholds were proposed, not explicitly confirmed by the owner.
2. Should HandLive offer the one-tap system prompts (enable Bluetooth/Wi-Fi) or stay silent when a radio is off?
3. Does the 200 ms target apply to SMS and call notifications as well as clipboard text (assumed yes)?
4. Acceptable battery cost on the phone for keeping the Wi-Fi Direct group up in X (SP0 measures).
