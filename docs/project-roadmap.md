English | [Tiếng Việt](project-roadmap.vi.md)

# HandLive: Roadmap

> Source: `plans/20260924-definitive-architecture/plan.md`, sections 8 and 11. Task cards, Phase 0, gates and the device matrix are in `plans/20260925-implementation/plan.md`. **Live progress table:** hub [`README.md`](../README.md#status) (must be updated whenever a concrete task finishes).

HandLive brings ecosystem-native features, such as Apple Handoff, to Android. The roadmap below is built **in order**. Each phase is a usable piece. Each later phase stands on the infrastructure of the phase before it. The WebSocket, pairing and encryption from Phase 1 are reused by every later phase. One exception to the order (project owner's decision, 2026-09-28): Phases 5 and 6 are done before Phase 4. Phase 4 itself is stopped (project owner's decision, 2026-10-12): only macOS 27 is available, so calls on the computer stay notification + answer/decline/end only, no audio; gate G4 is closed, reopened only on a later owner decision. Phase 7 started on 2026-10-28 (project owner's decision) without waiting for Phases 4–6 or their gates.

## Progress snapshot (2026-10-30)

**Latest release:** [`v0.2.0`](https://github.com/HandLive/handlive/releases/tag/v0.2.0) (2026-10-30): Phase 7 offline connectivity — when both devices are near each other without a network, they connect over Bluetooth L2CAP (control channel only: clipboard text, SMS and call notifications); first pairing over Bluetooth by QR (flow B) or a PIN through CPace-X25519-SHA512 (flow C); Bluetooth admission policy and pre-auth bans; "Connected via Bluetooth" label on Android and Mac. No relay deployment in this release; Wi-Fi Direct and relay bulk are specced but not implemented (tracked for a later release). Every change since v0.1.1 passed a security scan: 0 critical, 0 high, 0 medium, 0 low ([deployment guide](deployment-guide.md)). Live table: hub [`README.md`](../README.md#status).

**Previous release:** [`v0.1.1`](https://github.com/HandLive/handlive/releases/tag/v0.1.1) (2026-10-22): the first tag without a pre-release suffix; Google Play readiness on Android (application id `com.handlive.android`, target API 36, R8 on release, signed Play bundle on CI) and the paid-team identifiers on iPhone and iPad (App Group `group.app.hxd.handlive`), the clipboard URI policy (android #13 fixed), the Mac welcome window returns to the menu bar on close; same three files on one page: Mac DMG signed ad hoc (Open Anyway once), iOS IPA (unsigned, for sideloading), Android APK (`foss`, signed). A beta install on Android must be removed first (new application id) and an iPhone beta install must pair again. Every change since beta.3 passed a security scan ([deployment guide](deployment-guide.md)). Live table: hub [`README.md`](../README.md#status).

| Phase | Code on `main` | Gate / blocker |
|-------|----------------|----------------|
| 0 | Done | G0 done |
| 1 | Done (2026-09-26) | G1 open; S25↔Mac pairing stable (2026-09-30); one-sided pair after a key reset fixed (2026-10-04); image items with a text beside the URI, lost-grant message and phone → Mac image e2e (2026-10-05); text clips carry their HTML (`text/html` capability, CLIP-01 API 5 `html`, 2026-10-05); restricted-setting guidance shown again on return, consent asked once (2026-10-05, android #6, replayed on the S25); the Auto-Send switch asks before turning off a service that never came on (android #7); App Store Connect store screenshots recaptured at native 1320×2868 (2026-10-12); reading copied images opens only items shared by other apps via a content provider, other URIs rejected (2026-10-12, android #13) |
| 2 | Done (2026-09-27) | G2 open; real relay / APNs / FCM checks open; iPhone background grace of 25 s (2026-10-05); Liquid Glass app icon on iPhone, iPad and Mac (2026-10-07, apple #7 + #8, hub #17 + #19); Play Console store screenshots recaptured at 1080×1920 (2026-10-12) |
| 3 | Done (2026-09-28) | Real-device checks open; app calls show the app's name and outlive a swiped in-call notification (2026-10-05, android #8 + hub #15, merged 2026-10-07); the call bench reads app calls (shared #6); e2e covers app calls with a fake calling app (2026-10-07, android #9 + shared #7) |
| 4 | Stopped (owner decision, 2026-10-12) | G4 closed: only macOS 27 available, calls stay notification + answer/decline/end, no audio |
| 5 | Spike on `main` (`CameraSpike`, merged 2026-09-30) | G5: need paid Apple Developer team |
| 6 | Spike probes on `main` (Apple+Android merged 2026-09-30); product cards not started | G6: owner browser decisions; Firefox/Edge/Brave rows |
| 7 | Released in `v0.2.0` (2026-10-30) | Spike G7 done; Bluetooth offline pairing (QR flow B, PIN flow C via CPace-X25519-SHA512) shipped; Wi-Fi Direct and relay bulk specced, not implemented |
| G0 | Done | Test vectors |
| G1 | Open (before 1.0) | Real-device Phase 1 matrix |
| G2 | Open (before 1.0) | Play Console SMS / call-log (Plan B: F-Droid/APK) |

## Phase 1. Clipboard sync (MVP)

Android runs a foreground service and a Ktor WebSocket server, finds devices on the network over mDNS (`NsdManager` on Android, `NWBrowser` on Apple), pairs by QR code, encrypts with XChaCha20. macOS is a menu bar app. Text and images (in chunks), auto-clear after 60 seconds, the two devices negotiate features when they connect.
**Measure:** text under 50 ms on the local network, a 5 MB image under 2 seconds, reconnect under 3 seconds. **Effort:** about 3.5 person-months.

## Phase 2. SMS bridge

Android receives and sends SMS. macOS and iOS get a conversation screen, syncing the latest 50 messages per contact. Adds the **iOS app** (clipboard and SMS), a **cloud relay** written in Rust for devices outside the local network, and APNs and FCM push notifications.
**Measure:** notification under 500 ms, reply confirmation under 2 seconds. **Effort:** about 4 person-months.

## Phase 3. Call information and control

Android uses the public Telecom APIs: `TelephonyCallback`, `acceptRingingCall`, `endCall`. No `InCallService` (decision D9). macOS shows a floating `NSPanel` and a communication notification. Answering or declining goes over Wi-Fi. Hold, DTMF and mute over HFP wait for Phase 4. Call history included. iOS shows call information.
**Measure:** incoming-call notification under 200 ms, answer under 500 ms end to end. **Effort:** about 3 person-months.

## Phase 4. Call audio

**Stopped (owner decision, 2026-10-12):** only macOS 27 is available, so calls on the computer keep notification +
answer/decline/end control only, no audio; the design below is kept as reference and reopens only on a later owner
decision.

**Starts with a one-week HFP spike.** Bluetooth HFP (the phone is the AG, the Mac is the HF), SCO routing, echo cancellation with `AUVoiceProcessingIO`. Opus-over-WebSocket fallback, two-layer encryption, adaptive jitter buffer, detection of a headset holding HFP. The HFP path relies on Bluetooth link encryption (D11). A disclosure screen before the feature is turned on (legal requirement).
**Measure:** MOS of 3.5 or more over Bluetooth, 3.0 or more over WebSocket. Echo return loss above 40 dB. **Effort:** about 6 person-months.

## Phase 5. Virtual camera and mic

**Starts with a one-week CMIOExtension spike.** Android captures video with Camera2, encodes it with MediaCodec, sends it over Wi-Fi, detects a USB cable by itself, and lowers quality when the phone runs hot. macOS decodes with VideoToolbox, outputs video through CMIOExtension and audio through AudioServerPlugin, and installs via a PKG.
**Measure:** latency under 120 ms over Wi-Fi, under 70 ms over USB. **Effort:** about 5.5 person-months.

## Phase 6. Continue Browsing (proposed)

**Starts with the G6 spike (3–5 days).** The web page open on one device continues on another: Android to Mac, Android to iPhone and iPad (while the app is open), Mac to Android. Android reads the foreground browser's address bar through a separate Accessibility service, limited to the supported browsers, behind a disclosure and off by default. The Mac reads the front tab through Apple Events, with the Automation permission per browser. The Mac shows the page in its menu, Android as a quiet notification, iPhone and iPad as a banner; the user opens it with one click or tap. Private tabs are never sent and pages are never stored. Built only on Phase 1 infrastructure (session, encryption, capabilities), so it does not depend on Phases 4 and 5; by the project owner's decision of 2026-09-28 it is done before Phase 4 finishes. Detailed design: group 9, WEB-01 to WEB-05, decision C21.
**Gate G6:** Android address bar and incognito detection for Chrome, Samsung Internet, Firefox, Edge and Brave on Android 10 and 15, with the battery cost of the service; Apple Events for Safari, Chrome and Arc on macOS 13 and 26, Safari private windows, TCC for a Developer ID build; the current Play Accessibility policy. Go or no-go per browser. **Effort:** about 1.5 person-months (Android 3 weeks, macOS 2 weeks, iOS half a week, test 1 week, spike 1 week).

## Phase 7. Connect anywhere (started)

**Started on 2026-10-28 by the project owner's decision, with the G7 spike (about one week), without waiting for gates G4, G5 and G6.** After the first QR pairing the phone and the Mac near each other connect by themselves when neither has a network (the owner's case), and neither device ever leaves or changes its current Wi-Fi; the same Bluetooth path also covers phone on mobile data and Mac on another Wi-Fi while they are near each other. A Bluetooth link (BLE or classic, chosen by G7) carries the control channel; a new bulk lane carries images over the LAN, Wi-Fi Direct (only while the Mac's Wi-Fi is idle) or Bluetooth; first pairing also works offline over BLE. Dropped on 2026-10-28: bulk over the relay (the relay is not deployed) and automatic HFP bonding (Phase 4 is stopped). If G7 fails there is no relay fallback and the product stays LAN only. Every Bluetooth path is secured beyond the session handshake (link-security layer, admission policy). Plan: `plans/20260925-implementation/phase-07-ket-noi-moi-noi.md`.
**Measure:** text under 50 ms on the LAN and within 200 ms over Bluetooth; a 5 MB image within 2 s on the LAN, the first one offline within 10 s; no device changes its Wi-Fi. **Effort:** estimated after G7.

## Total effort

About 22 person-months for Phases 1 to 5; Phase 6 adds about 1.5. Two people take about 11 months. Three people take about 7.5 months. The MVP (Phase 1) takes about 2 months with two people. Usable clipboard and SMS (Phase 1 plus Phase 2) takes about 4 months with two people.

| Phase | Android | macOS | iOS | Server | Test | Total |
|-------|:-------:|:-----:|:---:|:------:|:----:|:----:|
| P1 | 1.5 | 1.5 | — | — | 0.5 | 3.5 |
| P2 | 1 | 0.5 | 1 | 1 | 0.5 | 4 |
| P3 | 1 | 1 | 0.5 | — | 0.5 | 3 |
| P4 | 2 | 2 | — | 0.5 | 1.5 | 6 |
| P5 | 2 | 2.5 | — | — | 1 | 5.5 |
| P6 | 0.6 | 0.4 | 0.1 | — | 0.4 | 1.5 |
