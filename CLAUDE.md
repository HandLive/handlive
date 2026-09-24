# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project status: pre-implementation

There is **no code yet**. The repository currently holds only architecture/research documents under `plans/`. Everything below describes the *decided* design that future code must implement, not existing code. When you start implementing, treat the "Definitive Architecture" plan as the source of truth and the three research plans as supporting detail.

Planning docs are written in **Vietnamese** (with diacritics). Keep that convention for new plans, reports, and user-facing communication.

## What HandLive is

A multi-platform system that turns an Android phone into a hub whose clipboard, SMS, calls (including live **call audio**), and camera/mic are relayed to macOS (full features) and iOS/iPadOS (clipboard + SMS + call metadata only, no audio). Comparable to Microsoft Phone Link / Apple Continuity, but cross-ecosystem.

Design tagline: **"WebSocket for data, Bluetooth for voice."**

## Core architectural decisions (do not silently reverse — see `plans/20260924-definitive-architecture/plan.md`)

- **Transport split:** WebSocket (Ktor server on Android, mDNS/`NsdManager` discovery) is the primary channel for *all* data — clipboard, SMS, call metadata, notifications. Bluetooth HFP SCO is used for exactly one thing: relaying **cellular call audio** to macOS, because Android 10+ blocks call-audio capture via public APIs and HFP is the only proven path (Microsoft Phone Link uses it).
- **Call-audio fallback chain:** HFP SCO (primary) → Opus-over-WebSocket (~100–150ms) when HFP is unavailable (AirPods hold the HFP slot, out of BT range). The Opus/WS path is a permanent designed-in fallback, promotable to primary if HFP proves unworkable.
- **Feature independence:** every feature must work standalone — a clipboard failure must not take down SMS, etc. Capability negotiation on connect: features activate only when *both* peers support them.
- **End-to-end encryption everywhere, no opt-out.** Envelope is plaintext JSON; `payload` is XChaCha20-Poly1305-encrypted. Call/BT audio gets **dual-layer** encryption (BT link SSP + app-level E2E per SCO frame) because BT link crypto has known breaks (KNOB/BIAS). Session keys via X25519 ECDH + HKDF-SHA256, exchanged through **QR-code pairing** (256-bit entropy; a 6-digit-PIN + Argon2id path is the fallback).
- **iOS is intentionally second-class:** no call-audio relay (Apple exposes no HFP HF API). Do not attempt to add it.
- **Camera/mic streaming (Phase 5):** Android Camera2→MediaCodec (H.264 HW) + libopus over a *separate* WebSocket channel (never shared with the control channel); macOS decodes via VideoToolbox and exposes a **CMIOExtension** virtual camera + **AudioServerPlugin** (HAL) virtual mic. WiFi is primary; USB (ADB port-forward) is an optional auto-detected latency boost.

## Planned tech stack (per component)

| Component | Language / key APIs |
|-----------|---------------------|
| Android app | Kotlin, minSdk 29 / targetSdk 35; Ktor WebSocket server; Camera2 + MediaCodec; `InCallService`/`TelecomManager`; `BluetoothHeadsetClient` (@SystemApi via **Shizuku**); Google Tink crypto; libopus via JNI |
| macOS app | Swift 6, AppKit, macOS 13+; `URLSessionWebSocketTask` + Bonjour; `IOBluetoothHandsFreeDevice` (HFP HF); `AUVoiceProcessingIO` (echo cancel); CryptoKit; CMIOExtension + AudioServerPlugin; VideoToolbox |
| iOS/iPadOS app | Swift 6, SwiftUI, iOS 16+; WebSocket + APNs/PushKit (metadata only); clipboard + SMS |
| Cloud relay | Rust, Actix-web + actix-ws; zero-knowledge (relays encrypted blobs only, never decrypts/logs payloads); self-hosted single VPS initially |

## Development phases (build in order)

1. **Clipboard sync** (MVP): Android FG service + Ktor WS server + mDNS + QR pairing + XChaCha20 E2E ↔ macOS menu-bar app. Target: text <50ms, 5MB image <2s.
2. **SMS bridge** + iOS app + Rust cloud relay + push.
3. **Call metadata + control** (`InCallService`, floating `NSPanel`, answer/reject/hold/DTMF).
4. **Call audio relay** (HFP/SCO + Opus/WS fallback + AEC). Starts with a 1-week HFP spike; legal disclosure UI required before enabling.
5. **Camera/mic virtual devices** (CMIOExtension + AudioServerPlugin). Starts with a 1-week CMIOExtension spike.

## Conventions specific to this repo

- **Plans** live in `plans/<YYYYMMDD>-<slug>/plan.md`. Reports go under a `reports/` subdirectory. Prefer updating the relevant existing plan over creating parallel ones.
- **Message protocol wire format** (already specified — match it): JSON envelope `{v, type, id (uuid-v7), ts (ms), payload (base64 encrypted)}`; audio uses a raw binary frame `[0x48 0x4C][ver:1B][seq:4B][ts:4B][encrypted_opus:NB]` instead of JSON wrapping.
- **Not a git repo** yet. `git init` before any commit workflow.
- When implementation begins, create the standard `docs/` set (see the root/global `CLAUDE.md` documentation-management rules) and a `README.md` — both are currently absent.

## Key risks the design already commits to mitigating

- `BluetoothHeadsetClient` @SystemApi and `IOBluetoothHandsFreeDevice` are both fragile (hidden/legacy). All BT-HFP calls must sit behind an abstraction layer (`CallAudioRelay` interface) so the Opus/WS fallback or a future `CompanionDeviceManager` path can swap in.
- SMS permissions (`READ_SMS`/`SEND_SMS`) risk Play Store rejection → fallbacks: Notification Listener Service, then F-Droid/direct APK.
- Android OEM Bluetooth fragmentation → strategy-pattern adapters (`SamsungBtAdapter`, `PixelBtAdapter`, `GenericBtAdapter`).
