English | [Tiếng Việt](README.vi.md)

# HandLive

> HandLive is an open source project. It brings ecosystem-native features, such as Apple Handoff, to Android. An Android device stays in sync with a Mac, iPhone and iPad, and those Apple devices sync back. This repository is the documentation hub.
>
> Design motto: *"WebSocket for data, Bluetooth for voice."*

**Status:** Phase 0–3 are merged into `main`. There is no public release yet: gates G1 (real-device matrix) and G2 (Play Console) are still open, and Phase 2/3 still need checks on a real relay, APNs and FCM. Phase 4 waits on the G4 Bluetooth HFP spike (real phone). Phases 5 and 6 run before Phase 4 finishes (owner decision 2026-09-28): G5 needs a paid Apple Developer team; G6 spike probes are on `main` with Chrome/Samsung results and the Android 16 HOME fix, but browser go/no-go decisions and product cards remain. Real-device QR pairing (Galaxy S25 Ultra ↔ Mac) is stable as of 2026-09-30. The source code lives in four repositories cloned into this folder — see Layout. The product is multilingual: English is the default language and Vietnamese the second; every document here exists in both languages (`X.md` in English, `X.vi.md` in Vietnamese).

## What HandLive solves

HandLive brings features that belong to one ecosystem, such as Apple Handoff and Continuity, onto Android. An Android device syncs its clipboard, SMS, calls, camera and microphone with a Mac. iPhone and iPad sync the clipboard, SMS and call details. Apple devices sync back to Android. End-to-end encryption (E2E) stays on. Users cannot turn it off.

| Feature | macOS | iOS/iPadOS |
|---------|:-----:|:----------:|
| Two-way clipboard | ✅ | ✅ |
| Receive and send SMS | ✅ | ✅ |
| Call details and control (answer, decline, end; hold and DTMF over Bluetooth HFP) | ✅ | ✅ (details and decline, no audio) |
| **Call audio** (talk and listen on the computer) | ✅ | ❌ (Apple offers no hands-free-side HFP API) |
| Virtual camera and microphone (Zoom, Meet, FaceTime, OBS) | ✅ | ❌ |
| Continue Browsing: the web page open on one device continues on the other (planned, Phase 6) | Planned (both ways) | Planned (from the phone only) |

## Screenshots

| | | |
|---|---|---|
| <img src="docs/screenshots/android/04-devices-connected.en.png" alt="Android: the paired Mac, connected over Wi-Fi" width="220"> | <img src="docs/screenshots/ios/04-sms-conversation.en.png" alt="iPhone: read and reply to the phone's SMS" width="220"> | <img src="docs/screenshots/ios/05-calls.en.png" alt="iPhone: the phone's call log" width="220"> |
| Android: the paired Mac, connected over Wi-Fi | iPhone: read and reply to the phone's SMS | iPhone: the phone's call log |

| | |
|---|---|
| <img src="docs/screenshots/macos/03-messages-window.en.png" alt="Mac: SMS and the call log in one window" width="420"> | <img src="docs/screenshots/macos/04-incoming-call-panel.en.png" alt="Mac: floating panel for an incoming call" width="420"> |
| Mac: SMS and the call log in one window | Mac: floating panel for an incoming call |

Every screen of the three apps, in English and Vietnamese, with how each was captured: [`docs/screenshots/README.md`](docs/screenshots/README.md).

## Architecture at a glance

- **WebSocket** carries all data: clipboard, SMS, call details, notifications. Android runs a Ktor server, and devices on the same network find each other over mDNS.
- **Bluetooth HFP SCO** carries only **call audio**. Since Android 10, apps cannot capture call audio through public APIs; HFP is the proven path. When HFP is busy (earbuds hold the link, or the Mac is out of range) the system falls back to **Opus over WebSocket**, at about 100–150 ms latency. That path needs Shizuku and only works on some devices and Android versions (plan §13 D10).
- **End-to-end encryption** everywhere. Content uses XChaCha20-Poly1305; the two devices exchange keys with X25519 and HKDF and pair through a **QR code**. Opus audio is encrypted twice; HFP audio relies on Bluetooth link encryption (plan §13 D11).
- The **cloud relay** (Rust, Actix-web) forwards encrypted blobs only when the devices are not on the same local network. It cannot read the content.

Details: [`docs/system-architecture.md`](docs/system-architecture.md) and [`plans/20260924-definitive-architecture/plan.md`](plans/20260924-definitive-architecture/plan.md).

## Roadmap and progress

Built in order; each phase delivers something usable. Exception (owner, 2026-09-28): Phases 5 and 6 proceed before Phase 4 finishes, because Phase 4 waits for the G4 HFP hardware spike. Full narrative and effort table: [`docs/project-roadmap.md`](docs/project-roadmap.md). Task cards and gates: [`plans/20260925-implementation/plan.md`](plans/20260925-implementation/plan.md).

| Phase / gate | Goal | Status (as of 2026-09-30) |
|--------------|------|---------------------------|
| **0** Scaffold, protocol, crypto, tokens, CI | Shared vectors and green CI | **Done** — merged |
| **1** Clipboard sync (MVP) | Android ↔ Mac, LAN WebSocket, QR pairing | **Code done** — merged 2026-09-26. Gate **G1** (device matrix, TalkBack/VoiceOver) still open before first release. Real-device pairing S25 ↔ Mac: stable after 2026-09-30 fixes |
| **2** SMS + iOS app + relay + push | Conversations, Rust relay, APNs/FCM | **Code done** — merged 2026-09-27. Real relay / APNs / FCM and gate **G2** (Play Console SMS declaration) still open |
| **3** Call information and control | Telecom APIs, Mac floating panel, iOS metadata | **Code done** — merged 2026-09-28. Real-device latency and OEM checks still open |
| **4** Call audio | HFP/SCO primary, Opus/WS fallback, AEC | **Spike G4** — `HFPSpike` ready on `feat/phase-04-call-audio`. Blocked on Bluetooth pairing of a real phone with the Mac and a live call. No other Phase 4 card until G4 |
| **5** Virtual camera and mic | CMIOExtension + AudioServerPlugin | **Spike G5** — `CameraSpike` ready on `feat/phase-05-camera-mic`. Blocked on a paid Apple Developer Program team (System Extension). No other Phase 5 card until G5 |
| **6** Continue Browsing | Foreground URL across devices | **Spike G6 in progress** — Android `tools/web-spike` and Apple `Tools/WebSpike` on `main` / phase-06 branches. Chrome + Samsung Internet measured on S25; HOME leave fixed on Android 16. Pending: Safari Accessibility decision, Samsung origin-only decision, Firefox/Edge/Brave rows, then product cards WEB-01…05 |
| Gate **G0** | Test vectors green | **Done** |
| Gate **G1** | Real-device Phase 1 matrix | **Open** (required before first release) |
| Gate **G2** | Play Console SMS / call-log declaration | **Open** (required before first release; Plan B: F-Droid/APK) |

### Rule: keep this roadmap current

**Whenever a concrete piece of work finishes** (a phase card merged, a gate closed or waived, a spike go/no-go, a real-device bugfix landed on `main`), the same change set **must** update:

1. The progress table in this `README.md` and `README.vi.md` (status column and the Status blurb at the top).
2. The matching summary in [`docs/project-roadmap.md`](docs/project-roadmap.md) and [`docs/project-roadmap.vi.md`](docs/project-roadmap.vi.md).
3. The hub [`CHANGELOG.md`](CHANGELOG.md) / [`CHANGELOG.vi.md`](CHANGELOG.vi.md) when the change is user- or release-visible.
4. `CLAUDE.md` Next steps when the handoff for coding agents changes.

Do not leave progress only in a plan report or a chat. A finished task without a README roadmap update is incomplete.

## Layout: five repositories, one workspace

This repository (`handlive`) is the **hub**. It holds only documents, plans and doc tools. The source code lives in four separate repositories; clone them inside the hub folder (the hub's git ignores those folders). The layout is required: builds and tests read `../shared`, and the Apple tests read `../docs`.

```
HandLive/                # hub repository "handlive"
├── CLAUDE.md            # Instructions for Claude Code (read first)
├── README.md            # this file; README.vi.md is the Vietnamese version
├── docs/                # Project docs (see docs/codebase-summary.md)
│   ├── detailed-design/ # Detailed design: the specification for all code
│   └── design-system/   # Design system (source copy of the artifact)
├── plans/               # Architecture, research, implementation plan + reports/
├── tools/docs/          # validate_design_docs.py, check_bilingual_docs.py, apple_diacritics.py, build_design_html.py
├── tools/workspace.sh   # clone <group-url> | status | run <git…> | remotes | push | hooks
├── android/             # repository "handlive-android"  (Kotlin, Gradle)
├── apple/               # repository "handlive-apple"    (Swift, macOS + iOS)
├── relay/               # repository "handlive-relay"    (Rust)
├── shared/              # repository "handlive-shared"   (test vectors, JSON Schema, design tokens, UI strings, tools)
└── .github-org/         # repository "HandLive/.github": org profile, CONTRIBUTING, SECURITY, CODE_OF_CONDUCT, PR/issue templates
```

```sh
git clone git@github.com:HandLive/handlive.git HandLive && cd HandLive
tools/workspace.sh clone git@github.com:HandLive
tools/workspace.sh status
```

## Documentation

| File | Contents |
|------|----------|
| [`docs/project-overview-pdr.md`](docs/project-overview-pdr.md) | What the product is: goals, scope, constraints |
| [`docs/system-architecture.md`](docs/system-architecture.md) | Architecture, transports, protocol, security |
| [`docs/project-roadmap.md`](docs/project-roadmap.md) | The five phases and effort estimates |
| [`docs/screenshots/README.md`](docs/screenshots/README.md) | Screenshots of the Android, iPhone, iPad and Mac apps |
| [`docs/design-guidelines.md`](docs/design-guidelines.md) | Experience and security principles |
| [`docs/code-standards.md`](docs/code-standards.md) | Code conventions per platform |
| [`docs/deployment-guide.md`](docs/deployment-guide.md) | Packaging and distribution (App Store, PKG, cloud relay) |
| [`docs/privacy.md`](docs/privacy.md) | HandLive and your privacy: what stays on the devices, what the relay sees, deleting data |
| [`docs/codebase-summary.md`](docs/codebase-summary.md) | Map of the code base, updated when code changes |
| [`docs/detailed-design/README.md`](docs/detailed-design/README.md) | Detailed design: 33 functions, protocol, error codes, data model, localization |

## License

Apache License 2.0 — see [LICENSE](LICENSE). The license applies to all five repositories of the [HandLive](https://github.com/HandLive) organization. How to contribute is in [CONTRIBUTING](https://github.com/HandLive/.github/blob/main/CONTRIBUTING.md): small commits under a real name, DCO sign-off with `git commit -s`. Report security issues privately as described in [SECURITY](https://github.com/HandLive/.github/blob/main/SECURITY.md).
