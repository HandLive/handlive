English | [Tiếng Việt](project-roadmap.vi.md)

# HandLive: Roadmap

> Source: `plans/20260924-definitive-architecture/plan.md`, sections 8 and 11. Task cards, Phase 0, gates and the device matrix are in `plans/20260925-implementation/plan.md`.

HandLive brings ecosystem-native features, such as Apple Handoff, to Android. The roadmap below is built **in order**. Each phase is a usable piece. Each later phase stands on the infrastructure of the phase before it. The WebSocket, pairing and encryption from Phase 1 are reused by every later phase.

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

**Starts with a one-week HFP spike.** Bluetooth HFP (the phone is the AG, the Mac is the HF), SCO routing, echo cancellation with `AUVoiceProcessingIO`. Opus-over-WebSocket fallback, two-layer encryption, adaptive jitter buffer, detection of a headset holding HFP. The HFP path relies on Bluetooth link encryption (D11). A disclosure screen before the feature is turned on (legal requirement).
**Measure:** MOS of 3.5 or more over Bluetooth, 3.0 or more over WebSocket. Echo return loss above 40 dB. **Effort:** about 6 person-months.

## Phase 5. Virtual camera and mic

**Starts with a one-week CMIOExtension spike.** Android captures video with Camera2, encodes it with MediaCodec, sends it over Wi-Fi, detects a USB cable by itself, and lowers quality when the phone runs hot. macOS decodes with VideoToolbox, outputs video through CMIOExtension and audio through AudioServerPlugin, and installs via a PKG.
**Measure:** latency under 120 ms over Wi-Fi, under 70 ms over USB. **Effort:** about 5.5 person-months.

## Total effort

About 22 person-months. Two people take about 11 months. Three people take about 7.5 months. The MVP (Phase 1) takes about 2 months with two people. Usable clipboard and SMS (Phase 1 plus Phase 2) takes about 4 months with two people.

| Phase | Android | macOS | iOS | Server | Test | Total |
|-------|:-------:|:-----:|:---:|:------:|:----:|:----:|
| P1 | 1.5 | 1.5 | — | — | 0.5 | 3.5 |
| P2 | 1 | 0.5 | 1 | 1 | 0.5 | 4 |
| P3 | 1 | 1 | 0.5 | — | 0.5 | 3 |
| P4 | 2 | 2 | — | 0.5 | 1.5 | 6 |
| P5 | 2 | 2.5 | — | — | 1 | 5.5 |
