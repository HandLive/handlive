English | [Tiếng Việt](project-overview-pdr.vi.md)

# HandLive: Product Definition

> **Date:** 2026-09-24. **Status:** no user-facing features implemented yet.

## 1. Problem

Android users do not get the seamless phone-to-computer experience of Apple Continuity, or of Microsoft Phone Link between Android and Windows. HandLive fills that gap for **Android with macOS and iOS**. The focus is on three missing flows: call audio, camera and mic, and syncing data the moment it appears. Every flow is end-to-end encrypted.

## 2. Goals

- Two-way clipboard sync. Text latency under 50 ms on the local network.
- Receive and send SMS from macOS and iOS.
- Receive calls, control them, then **listen and talk** right on macOS.
- Use the Android camera and mic as virtual devices in Zoom, Meet, FaceTime, OBS.
- End-to-end encryption always on. No server can read the content.

## 3. Out of scope

- No call audio relay to iOS. Apple does not expose an HFP API for the headset side. iOS only gets clipboard, SMS and call information.
- No call recording. The system only relays audio while a call is in progress and stores nothing.
- No high-quality music over HFP. That channel is mono, 8 or 16 kHz.

## 4. Users

Mainstream users, not only developers. The default is **works right away, wireless, no extra configuration**. ADB, a USB cable and Shizuku are only speed-up options for people who want to fine-tune. Core features do not depend on them.

## 5. Platforms

| Platform | Minimum requirement |
|----------|---------------------|
| Android | minSdk 29 (Android 10), targetSdk 35 |
| macOS | 13+ |
| iOS/iPadOS | 16+ |
| Cloud relay | Rust/Actix-web, self-hosted on one VPS at first |

## 6. Settled decisions

The full list is in section 12 (D1 to D8) of `plans/20260924-definitive-architecture/plan.md`. Summary:

- **D1:** Call audio has two paths. Try HFP for one week. If it does not work, switch entirely to Opus over WebSocket.
- **D2:** Tell the user clearly before relaying call audio (both parties are aware). This does not hold the release schedule back while waiting for a legal conclusion.
- **D3:** Use `BluetoothHeadsetClient` (SystemApi) with Shizuku right away. Keep an eye on CompanionDeviceManager.
- **D4:** Background clipboard through an Accessibility Service. Fallback: manual send with the notification button, the Quick Settings tile, or Share (C15).
- **D5:** Self-host the cloud relay on one VPS. Move to a managed service above 500 concurrent users.
- **D6:** Try CMIOExtension in the first week of Phase 5.
- **D7:** Distribute the AudioServerPlugin as a notarized PKG and a Homebrew cask.
- **D8:** USB speed-up over ADB, with step-by-step guidance. Native UVC is left for v2.
- **D9 to D12** (added 2026-09-24, plan §13): call control with public APIs. Hold, DTMF and mute go through HFP, without `InCallService`. Keep Opus/WebSocket with Shizuku, with the recorded limits. HFP audio relies on Bluetooth encryption. The clipboard uses Accessibility by default and still has a manual send path.

## 7. Success metrics

- Clipboard: text under 50 ms on the local network, a 5 MB image under 2 seconds, reconnect under 3 seconds.
- SMS: notification on macOS under 500 ms, reply confirmation under 2 seconds.
- Calls: incoming-call notification under 200 ms, answer time under 500 ms end to end.
- Audio: MOS of 3.5 or more over Bluetooth, 3.0 or more over WebSocket. Echo return loss above 40 dB.
- Camera and mic: latency under 120 ms over Wi-Fi, under 70 ms over USB.

## Open questions

- The repository structure is settled: five repositories in one workspace (hub, android, apple, relay, shared). See the README.
- The disclosure wording for call-audio relay still needs a lawyer's review. This runs in parallel with development.
