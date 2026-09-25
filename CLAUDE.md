# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project status: Phase 0 done (scaffold, protocol, crypto, tokens, CI)

This repository is the **hub** of a five-repository workspace: it holds only the architecture/research documents under `plans/`, project docs under `docs/`, the implementation-level spec under `docs/detailed-design/` and the documentation tools under `tools/docs/`. Phase 0 code lives in four repositories checked out **inside this directory** and git-ignored here: `android/` (handlive-android), `apple/` (handlive-apple), `relay/` (handlive-relay) and `shared/` (handlive-shared: test vectors, JSON schemas, design tokens and their tools). `tools/workspace.sh clone <group-url>` checks them out and `tools/workspace.sh status` shows all five; layout and test commands: `docs/codebase-summary.md`. No user-facing feature exists yet. The implementation plan with per-phase task cards for coding agents is `plans/20260925-implementation/plan.md` (see the hand-off section below); the UI design system is mirrored in `docs/design-system/`. Everything below describes the *decided* design that future code must implement, not existing code. When you start implementing, treat the "Definitive Architecture" plan as the source of truth and the three research plans as supporting detail.

Planning docs are written in **Vietnamese** (with diacritics). Keep that convention for new plans, reports, and user-facing communication.

## What HandLive is

A multi-platform system that turns an Android phone into a hub whose clipboard, SMS, calls (including live **call audio**), and camera/mic are relayed to macOS (full features) and iOS/iPadOS (clipboard + SMS + call metadata only, no audio). Comparable to Microsoft Phone Link / Apple Continuity, but cross-ecosystem.

Design tagline: **"WebSocket for data, Bluetooth for voice."**

## Core architectural decisions (do not silently reverse — see `plans/20260924-definitive-architecture/plan.md`)

- **Transport split:** WebSocket (Ktor server on Android, mDNS/`NsdManager` discovery) is the primary channel for *all* data — clipboard, SMS, call metadata, notifications. Bluetooth HFP SCO is used for exactly one thing: relaying **cellular call audio** to macOS, because Android 10+ blocks call-audio capture via public APIs and HFP is the only proven path (Microsoft Phone Link uses it).
- **Call-audio fallback chain:** HFP SCO (primary) → Opus-over-WebSocket (~100–150ms) when HFP is unavailable (AirPods hold the HFP slot, out of BT range). The Opus/WS path is a permanent designed-in fallback, promotable to primary if HFP proves unworkable. It runs through Shizuku (shell uid): impossible on Android 10, call-audio capture works only on some Android 11+ devices, uplink injection (Android 13+) is unverified — plan §13 D10.
- **Feature independence:** every feature must work standalone — a clipboard failure must not take down SMS, etc. Capability negotiation on connect: features activate only when *both* peers support them.
- **End-to-end encryption everywhere, no opt-out.** Envelope is plaintext JSON; `payload` is XChaCha20-Poly1305-encrypted. The HFP/SCO call-audio path relies on Bluetooth link encryption only, because apps cannot touch SCO frames of cellular calls (plan §13 D11; residual KNOB/BIAS risk is disclosed to the user); the Opus/WS path is TLS + E2E. Session keys via X25519 ECDH + HKDF-SHA256, exchanged through **QR-code pairing** (256-bit entropy; a 6-digit-PIN + Argon2id path is the fallback).
- **iOS is intentionally second-class:** no call-audio relay (Apple exposes no HFP HF API). Do not attempt to add it.
- **Camera/mic streaming (Phase 5):** Android Camera2→MediaCodec (H.264 HW) + libopus over a *separate* WebSocket channel (never shared with the control channel); macOS decodes via VideoToolbox and exposes a **CMIOExtension** virtual camera + **AudioServerPlugin** (HAL) virtual mic. WiFi is primary; USB (ADB port-forward) is an optional auto-detected latency boost.

## Planned tech stack (per component)

| Component | Language / key APIs |
|-----------|---------------------|
| Android app | Kotlin, minSdk 29 / targetSdk 35; Ktor WebSocket server; Camera2 + MediaCodec; `TelecomManager` + `TelephonyCallback` (no `InCallService` — plan §13 D9); stock Bluetooth stack as HFP AG; Shizuku (optional) for the Opus/WS call-audio fallback; Google Tink crypto; libopus via JNI |
| macOS app | Swift 6, AppKit, macOS 13+; `URLSessionWebSocketTask` + Bonjour; `IOBluetoothHandsFreeDevice` (HFP HF); `AUVoiceProcessingIO` (echo cancel); CryptoKit; CMIOExtension + AudioServerPlugin; VideoToolbox |
| iOS/iPadOS app | Swift 6, SwiftUI, iOS 16+; WebSocket + APNs alert + Notification Service Extension (metadata only; no PushKit/CallKit — detailed design C7); clipboard + SMS |
| Cloud relay | Rust, Actix-web + actix-ws; zero-knowledge (relays encrypted blobs only, never decrypts/logs payloads); self-hosted single VPS initially |

## Development phases (build in order)

1. **Clipboard sync** (MVP): Android FG service + Ktor WS server + mDNS + QR pairing + XChaCha20 E2E ↔ macOS menu-bar app. Target: text <50ms, 5MB image <2s.
2. **SMS bridge** + iOS app + Rust cloud relay + push.
3. **Call metadata + control** (public Telecom APIs + floating `NSPanel`: answer/reject/end; hold/DTMF/mute via HFP AT commands once Phase 4 lands).
4. **Call audio relay** (HFP/SCO + Opus/WS fallback + AEC). Starts with a 1-week HFP spike; legal disclosure UI required before enabling.
5. **Camera/mic virtual devices** (CMIOExtension + AudioServerPlugin). Starts with a 1-week CMIOExtension spike.

## Conventions specific to this repo

- **Plans** live in `plans/<YYYYMMDD>-<slug>/plan.md`. Reports go under a `reports/` subdirectory. Prefer updating the relevant existing plan over creating parallel ones.
- **Message protocol wire format** (already specified — match it): JSON envelope `{v, type, id (uuid-v7), ts (ms), payload (base64 encrypted)}`; audio uses a raw binary frame `[0x48 0x4C][ver:1B][seq:4B][ts:4B][encrypted_opus:NB]` instead of JSON wrapping. The `type` set is extended with `session` and `camera`; the fine-grained `op` lives inside the encrypted payload — see `docs/detailed-design/00-common-specs.md`.
- **Detailed design** lives in `docs/detailed-design/` (one file per function group, each leaf function with 5 sections; shared protocol, error codes and data model in `00-common-specs.md`). Implement against it; add new message types, error codes or tables there first.
- **UI follows the HandLive Design System** (Apple Human Interface Guidelines on every platform, Android included; source mirrored in `docs/design-system/`, tokens in `shared/design-tokens/tokens.json`; decisions in `plans/20260924-apple-hig-design-system/`). Vietnamese UI strings use Apple-style diacritics (hủy, xóa, tùy, mã hóa) and the design system's terminology ("bảng nhớ tạm", not "clipboard").

## Implementation hand-off (coding agents start here)

- **Plan:** `plans/20260925-implementation/plan.md` — workspace layout (hub + the `android/`, `apple/`, `relay/`, `shared/` repositories), phase files `phase-00`…`phase-05` with task cards (owner prefix A/M/I/R/S/T, inputs, outputs, acceptance criteria, tests), gates (G0 test vectors, G1 latency targets, G2 Play Console, G4 HFP spike, G5 CMIOExtension spike). Reports go to `plans/20260925-implementation/reports/` and end with the status block from `~/.claude/rules/orchestration-protocol.md`.
- **Read in this order before coding a task:** this file → `docs/detailed-design/README.md` (catalog, conventions §3 incl. §3.5 UI wording, decisions C1–C19) → `docs/detailed-design/00-common-specs.md` (protocol, errors, data model, settings keys) → the phase file → the leaf functions it names → `docs/code-standards.md`. UI work also reads `docs/design-system/README.md`, the platform section in `docs/design-system/3-platforms/` and the component READMEs.
- **Contracts:** wire format, error codes, settings keys and tables live in `00-common-specs.md`; change them there first, then the leaf spec (run `python3 tools/docs/validate_design_docs.py`, must print `problems=0`), then code. Never invent message types, error codes or UI strings in code — UI strings come verbatim from the leaf specs.
- **File ownership:** every part is its own git repository. Android agents work in `android/` (handlive-android) and, when the contract data must change, in `shared/` (handlive-shared) as separate commits; Apple agents `apple/` + `shared/`; relay agents `relay/` + `shared/`. Docs, plans and reports change only in this hub repository. Any change in `shared/` (test vectors, schemas, tokens) is called out in the report so the other platforms re-run their tests — platform CI does not trigger on it by itself (start the workflow by hand).
- **Workspace layout is mandatory:** build scripts and tests resolve `../shared`, Apple tests also read `../docs`; each part carries a short `CLAUDE.md` saying so. CI reproduces the layout by checking out the hub at the workspace root, the part into `<part>/` and handlive-shared into `shared/` (`docs/deployment-guide.md`, CI section).
- **Branches and commits:** one branch per phase (`feat/phase-0N-<slug>`) in every repository the phase touches, the hub included for docs. **Commit early and small:** at least one commit per task card, and a separate commit for each logical step inside it (scaffold, then a module, then its tests, then docs) — never one commit per phase, and a commit never spans two repositories (commit `shared/` first, then the platform). Commit before writing the report and list the commit hashes with their repository in it. Conventional commits (`feat(android): …`, `test(relay): …`, `docs: …`), no AI references in messages.
- **Doc tools:** `tools/docs/validate_design_docs.py` (template + Mermaid check), `tools/docs/apple_diacritics.py` (Apple-style tone marks; dry run by default, `--write` to apply), `tools/docs/build_design_html.py` (HTML export to `build/docs/`; needs the `markdown` package: `$HOME/.claude/skills/.venv/bin/python3`). Design-system edits go to `docs/design-system/` first, then the artifact is republished. Contract tools live in `shared/tools/` (`vectors/`, `schemas/`) and run from the `shared/` repository root with its venv (`shared/tools/.venv`).

## Key risks the design already commits to mitigating

- `IOBluetoothHandsFreeDevice` is fragile (legacy API, no confirmed working reports on macOS 13+; the Phase-4 one-week spike decides go/no-go). All BT-HFP calls must sit behind an abstraction layer (`CallAudioRelay` interface) so the Opus/WS fallback or a future `CompanionDeviceManager` path can swap in.
- SMS permissions (`READ_SMS`/`SEND_SMS`) risk Play Store rejection → fallbacks: Notification Listener Service, then F-Droid/direct APK.
- Android OEM Bluetooth fragmentation → strategy-pattern adapters (`SamsungBtAdapter`, `PixelBtAdapter`, `GenericBtAdapter`).
