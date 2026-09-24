# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project status: pre-implementation

There is **no code yet**. The repository holds architecture/research documents under `plans/`, project docs under `docs/`, and the implementation-level spec under `docs/detailed-design/`. Everything below describes the *decided* design that future code must implement, not existing code. When you start implementing, treat the "Definitive Architecture" plan as the source of truth and the three research plans as supporting detail.

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
- **UI follows the HandLive Design System** (Apple Human Interface Guidelines on every platform, Android included; see `docs/design-guidelines.md` and `plans/20260924-apple-hig-design-system/`). Vietnamese UI strings use Apple-style diacritics (hủy, xóa, tùy, mã hóa) and the design system's terminology ("bảng nhớ tạm", not "clipboard").

## Key risks the design already commits to mitigating

- `IOBluetoothHandsFreeDevice` is fragile (legacy API, no confirmed working reports on macOS 13+; the Phase-4 one-week spike decides go/no-go). All BT-HFP calls must sit behind an abstraction layer (`CallAudioRelay` interface) so the Opus/WS fallback or a future `CompanionDeviceManager` path can swap in.
- SMS permissions (`READ_SMS`/`SEND_SMS`) risk Play Store rejection → fallbacks: Notification Listener Service, then F-Droid/direct APK.
- Android OEM Bluetooth fragmentation → strategy-pattern adapters (`SamsungBtAdapter`, `PixelBtAdapter`, `GenericBtAdapter`).
