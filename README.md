English | [Tiếng Việt](README.vi.md)

# HandLive

> This is the documentation hub of HandLive. An Android phone is the hub: it brings the clipboard, SMS, calls with live audio, and its camera and microphone to macOS. iPhone and iPad receive the clipboard, SMS and call details.
>
> Design motto: *"WebSocket for data, Bluetooth for voice."*

**Status:** Phase 0 is done: scaffold, protocol, encryption, tokens and CI. The apps have no user-facing features yet. The source code lives in four separate repositories cloned into this folder — see Layout. The product is multilingual: English is the default language and Vietnamese the second; every document here exists in both languages (`X.md` in English, `X.vi.md` in Vietnamese).

## What HandLive solves

An experience close to Microsoft Phone Link and Apple Continuity, but **across ecosystems**. Android users take calls, text, sync the clipboard, and use the phone's camera and microphone right on their Mac. End-to-end encryption (E2E) is always on and cannot be turned off.

| Feature | macOS | iOS/iPadOS |
|---------|:-----:|:----------:|
| Two-way clipboard | ✅ | ✅ |
| Receive and send SMS | ✅ | ✅ |
| Call details and control (answer, decline, end; hold and DTMF over Bluetooth HFP) | ✅ | ✅ (details and decline, no audio) |
| **Call audio** (talk and listen on the computer) | ✅ | ❌ (Apple offers no hands-free-side HFP API) |
| Virtual camera and microphone (Zoom, Meet, FaceTime, OBS) | ✅ | ❌ |

## Architecture at a glance

- **WebSocket** carries all data: clipboard, SMS, call details, notifications. Android runs a Ktor server, and devices on the same network find each other over mDNS.
- **Bluetooth HFP SCO** carries only **call audio**. Since Android 10, apps cannot capture call audio through public APIs; HFP is the proven path. When HFP is busy (earbuds hold the link, or the Mac is out of range) the system falls back to **Opus over WebSocket**, at about 100–150 ms latency. That path needs Shizuku and only works on some devices and Android versions (plan §13 D10).
- **End-to-end encryption** everywhere. Content uses XChaCha20-Poly1305; the two devices exchange keys with X25519 and HKDF and pair through a **QR code**. Opus audio is encrypted twice; HFP audio relies on Bluetooth link encryption (plan §13 D11).
- The **cloud relay** (Rust, Actix-web) forwards encrypted blobs only when the devices are not on the same local network. It cannot read the content.

Details: [`docs/system-architecture.md`](docs/system-architecture.md) and [`plans/20260924-definitive-architecture/plan.md`](plans/20260924-definitive-architecture/plan.md).

## Roadmap

Built in order; each phase delivers something usable.

1. **Clipboard sync** (MVP): Android and macOS over WebSocket on the local network.
2. **SMS bridge**: adds the iOS app, the cloud relay and push notifications.
3. **Call details and control**: public Telecom APIs (no `InCallService`, decision D9) and a floating call panel.
4. **Call audio**: HFP/SCO, Opus fallback, echo cancellation.
5. **Virtual camera and microphone**: CMIOExtension and AudioServerPlugin on macOS.

Details: [`docs/project-roadmap.md`](docs/project-roadmap.md).

## Layout: five repositories, one workspace

This repository (`handlive`) is the **hub**. It holds only documents, plans and doc tools. The source code lives in four separate repositories; clone them inside the hub folder (the hub's git ignores those folders). The layout is required: builds and tests read `../shared`, and the Apple tests read `../docs`.

```
HandLive/                # hub repository "handlive"
├── CLAUDE.md            # Instructions for Claude Code (read first)
├── README.md            # this file; README.vi.md is the Vietnamese version
├── docs/                # Project docs (see docs/codebase-summary.md)
│   ├── detailed-design/ # Detailed design: the contract for all code
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
| [`docs/design-guidelines.md`](docs/design-guidelines.md) | Experience and security principles |
| [`docs/code-standards.md`](docs/code-standards.md) | Code conventions per platform |
| [`docs/deployment-guide.md`](docs/deployment-guide.md) | Packaging and distribution (App Store, PKG, cloud relay) |
| [`docs/privacy.md`](docs/privacy.md) | HandLive and your privacy: what stays on the devices, what the relay sees, deleting data |
| [`docs/codebase-summary.md`](docs/codebase-summary.md) | Map of the code base, updated when code changes |
| [`docs/detailed-design/README.md`](docs/detailed-design/README.md) | Detailed design: 33 functions, protocol, error codes, data model, localization |

## License

Apache License 2.0 — see [LICENSE](LICENSE). The license applies to all five repositories of the [HandLive](https://github.com/HandLive) organization. How to contribute is in [CONTRIBUTING](https://github.com/HandLive/.github/blob/main/CONTRIBUTING.md): small commits under a real name, DCO sign-off with `git commit -s`. Report security issues privately as described in [SECURITY](https://github.com/HandLive/.github/blob/main/SECURITY.md).
