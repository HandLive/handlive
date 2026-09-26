English | [Tiếng Việt](design-guidelines.vi.md)

# HandLive — Design Guidelines

> HandLive brings ecosystem-native features, such as Apple Handoff, to Android, so Android devices stay in sync with Apple devices and the other way around. This document states the experience and security principles. Security details: `docs/system-architecture.md` §6, original plan §6.

## UX principles

- **Zero-config, wireless by default.** Mass-market users must be able to use it right after QR pairing,
  without ADB/USB/terminal. Anything that needs technical setup (Shizuku, USB debugging) is an optional
  "boost" with a step-by-step wizard.
- **Independent features, graceful degradation.** One broken feature does not break another. When the
  primary transport fails → fall back automatically (HFP→Opus/WS, LAN→cloud relay) and *notify* the
  user instead of dying silently.
- **Pairing via QR code**, not a 6-digit PIN (256-bit entropy vs ~20-bit; out-of-band authentication
  through the camera). The PIN is only a fallback.
- **iOS is a second-class citizen on purpose** — do not try to squeeze in call audio; set clear
  expectations in the UI (clipboard + SMS + call metadata).
- **macOS call UI** is a floating `NSPanel` (level `.floating`) — CallKit is not available natively on macOS.

## UI design system

- Source: the "HandLive Design System" artifact — https://claude.ai/artifact/2rsmYxBjxXrd12FByTd9vT (a
  copy in `docs/design-system/`, tokens in `shared/design-tokens/tokens.json`). Follows the
  **Apple Human Interface Guidelines** (2026-09-24 edition, Liquid Glass) on **every platform**: Mac,
  iPhone and iPad use the system controls, the San Francisco font, SF Symbols and system materials;
  Android rebuilds the same language in Compose (Inter font, Material Symbols Rounded) and keeps the
  parts Android owns as they are (notifications, permission dialogs, Quick Settings tiles, the back
  gesture). Apple's license does not allow SF Pro, SF Symbols or the UI Kit on Android.
- Brand colors follow feng shui for the Sơn Đầu Hỏa element (fire on the mountaintop): vermilion,
  ember red and flame orange for identity; green (Wood feeds Fire) is the AccentColor; no black or
  blue for the brand. Four appearances: Light, Dark and two high-contrast variants; every
  text–background pair ≥ 4.5:1.
- Decisions, HIG research and the list of points synced with `docs/detailed-design/` (2026-09-25):
  `plans/20260924-apple-hig-design-system/`. UI wording: `docs/detailed-design/README.md`
  §3.5.

## Security principles (non-negotiable)

- **E2E cannot be turned off.** There is no "send unencrypted" option. Consistent across the whole system.
- **Audio.** The Opus/WS path is encrypted in two layers (TLS + E2E XChaCha20). The HFP path has only
  Bluetooth link encryption, because apps cannot touch the SCO frames of cellular calls (plan §13
  D11); the KNOB/BIAS risk must be disclosed when the user turns on taking calls on the Mac.
- **Zero-knowledge cloud relay.** The server never holds keys, never decrypts, never logs payloads.
- **Hardware-backed keys** when available (StrongBox / Secure Enclave). Stolen device → biometrics/passcode
  required + remote unpair.
- **Sensitive clipboard content:** detect patterns (credit cards, password managers) → do not sync, only
  notify. Auto-clear on the receiver after 60s.

## Legal / privacy

- Call audio relay: **disclosure before enabling** (dialog + logged consent timestamp). Two-party-consent
  states (CA/FL/IL) require "all parties aware". No recording.
- Relaying between devices of the *same user* (like Continuity/Phone Link) → lower legal risk than a
  third-party relay.

## Performance targets

See `docs/project-overview-pdr.md` §7. Principle: measurable, not "feels fast". The detailed latency
budget for camera/mic is in the original plan §10.5.
