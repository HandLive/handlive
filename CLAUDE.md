# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this
repository.

## Project status: Phase 0–3 on `main`; Phase 4–6 spikes on `main`; beta `v0.1.0-beta.2`; G1/G2/G4/G5/G6 open

Phase 0–3 product code is on `main` (clipboard, SMS, iOS shell, Rust relay, call metadata/control). Phase 4–6
**spike probes** are also on `main` (merged 2026-09-30): `HFPSpike`, `CameraSpike`, Android `tools/web-spike`,
Apple `Tools/WebSpike`. Coordinated public betas: **`v0.1.0-beta.1`** and **`v0.1.0-beta.2`** (2026-10-04, the first with installable files) on hub/android/apple/shared/relay
(not a store release). Live progress board: hub `README.md` / `README.vi.md` (Roadmap and progress). Still
required before 1.0: gates **G1** (device matrix, TalkBack/VoiceOver) and **G2** (Play Console), Phase 2/3 checks
on a real relay / APNs / FCM, and spike gates **G4** (BT phone + live call), **G5** (paid Apple Developer team),
**G6** (browser go/no-go). Owner decision 2026-09-28: Phases 5 and 6 proceed before Phase 4 finishes. Security
scan fixes of 2026-09-28 are merged. Reports: `plans/20260925-implementation/reports/`.

This repository is the **hub** of a five-repository workspace: it holds only the
architecture/research documents under `plans/`, project docs under `docs/`, the implementation-level
spec under `docs/detailed-design/`, the documentation tools under `tools/docs/`, and the WordPress product
site under `website/` (`docs/website.md`). The app code
lives in four repositories checked out **inside this directory** and git-ignored here: `android/`
(handlive-android), `apple/` (handlive-apple), `relay/` (handlive-relay) and `shared/`
(handlive-shared: test vectors, JSON schemas, design tokens and their tools).
`tools/workspace.sh clone <group-url>` checks them out and `tools/workspace.sh status` shows all
five; layout and test commands: `docs/codebase-summary.md`. The
implementation plan with per-phase task cards for coding agents is
`plans/20260925-implementation/plan.md` (see the hand-off section below); the UI design system is
mirrored in `docs/design-system/`. Everything below describes the *decided* design that future code
must implement, not existing code. When you start implementing, treat the "Definitive Architecture"
plan as the source of truth and the three research plans as supporting detail.

The product is **multilingual**: English (`en`) is the default language and Vietnamese (`vi`) the
second (detailed design C20, 0.12). **Documentation is bilingual**: `X.md` is the English,
canonical version and `X.vi.md` the Vietnamese one, same folder and structure, both updated in the
same commit (`tools/docs/check_bilingual_docs.py`). Agent reports under `plans/*/reports/` are
English only; plans and reports dated before 2026-09-25 stay Vietnamese as an archive. Talk to the
project owner in Vietnamese with diacritics.

## Progress report (handoff of 2026-10-01 — start here)

### Done (on `main`)

| Area | What landed | Tips (approx.) |
|------|-------------|----------------|
| Phase 0–3 | Scaffold, clipboard, SMS, iOS, relay, call metadata/control | product on `main` since 2026-09-26…28 |
| Real-device pairing | S25 Ultra ↔ Mac QR pairing stable; Settings/Pair bring-forward; stable Bonjour name | android `4c6db55` lineage; apple `214b4f4` lineage |
| G6 spike (Android) | HOME leave ends page on Android 16 (`inactive reason=left`); probe on `main` | android `tools/web-spike` |
| Phase 4–6 spikes | Merged onto `main` (2026-09-30): HFPSpike, CameraSpike, WebSpike (Apple), web-spike (Android) | apple `214b4f4` |
| Hub docs | Live README roadmap + mandatory update rule; bilingual snapshot in `docs/project-roadmap*.md` | hub `650240e` |
| Beta | Coordinated tags/releases **`v0.1.0-beta.1`** and **`v0.1.0-beta.2`** on all five repos (prerelease, not store); beta.2 has the signed APK, the iOS IPA and the ad-hoc Mac DMG, all gathered on the hub's Release (`release-collect`); the website's Get the Beta opens it | beta.2: hub `9eb0766`, android `45d067b`, apple `c40d918` |
| CI hygiene | shared: sort `settings.check_again`; android: skip `tools/` in `UiTextSourceGuardTest` | shared `b330d4b`; android `4c6db55` |
| Security | 2026-09-28 scan fixes merged; 2026-10-04 scan of everything since beta.1: PASS, 6 of 8 findings fixed (`reports/security-scan-beta2-2026-10-04.md`) | relay `cda13bf`; beta.2 tips |
| Reinstall + quiet-host e2e (2026-10-05, 03:00) | Owner's Mac (Debug, `app.handlive.mac.localtest`) and S25 (debuggable APK) rebuilt from `main` without re-pairing, both connected; `e2e.py all` on API 35: 0 FAIL (setup 27, clipboard 16, sms 36, calls 35 PASS); API 29 exposed two bugs, both fixed: the harness could not see Android 10's battery dialog (shared #2), and PIN pairing hit `OutOfMemoryError` because Argon2id's 64 MiB sits on a 48 MB heap → `android:largeHeap` (android #3, follow-up: off-heap Argon2 in android issue #2); rerun green (`reports/reinstall-devices-and-quiet-host-e2e-2026-10-05.md`) | hub `feat/reinstall-devices-and-quiet-host-e2e` |
| Clipboard images (2026-10-05) | Owner report "image copy fails" (S25 ↔ Mac): no code deleted; Mac read/write and Android receive verified; phone → Mac image e2e added and green on the API 35 emulator; fix: an image URI wins over the text beside it, a lost URI grant is told on Send Clipboard and logged (`clip_read_failed`, debug); release-apple split into sign/launch/publish; website images pinned to digests. Root cause on the S25 itself still needs the owner's device check (`reports/clipboard-image-sync-debug-2026-10-05.md`) | android `fix/clipboard-image-item-precedence`, shared `feat/e2e-phone-to-mac-image`, apple `ci/release-apple-split-jobs`, hub `feat/check-progress-image-copy-debug-906617` |

**Commit identity:** always `Hồ Xuân Dũng <me@hxd.vn>` (GitHub `xuandung38`). Never `dunghx1@viettel.com.vn` or any Viettel email in author/committer/`Signed-off-by`. Use `env -u CURSOR_AGENT git commit` so Cursor does not inject Co-authored-by trailers.

**Workspace tips to treat as current `main`:** hub `a7f0a2c`, android `a4b2fb7`, apple `baf6060`, shared `7254abe`, relay `cda13bf` (before the 2026-10-05 PRs; the PR merges of that day move them). Confirm with `tools/workspace.sh status` before coding. **Local JDK:** Gradle needs `JAVA_HOME=/opt/homebrew/opt/openjdk@21/libexec/openjdk.jdk/Contents/Home` in a non-login shell, else `gradlew` prints "Unable to locate a Java Runtime" and a piped command still exits 0.

### In progress / blocked (owner or gate)

1. **Gate G4 (call audio spike):** run `apple/Tools/HFPSpike` with S25 paired over Bluetooth + a live cellular call; fill `reports/phase-04-spike-d1.md`; decide HFP vs Opus/WS primary (AUDIO-02 / plan D1). No other Phase 4 product card until G4.
2. **Gate G5 (camera/mic spike):** needs a **paid Apple Developer Program team** (System Extension). Runbook: `apple/Tools/CameraSpike/README.md`. No other Phase 5 card until G5.
3. **Gate G6 (Continue Browsing spike):** Chrome + Samsung measured on S25; HOME fix verified. Pending owner decisions: Safari Accessibility, Samsung origin-only; matrix rows Firefox/Edge/Brave; then product cards WEB-01…05.
4. **Gate G1 (formal):** device matrix in `shared/tools/bench/README.md`, TalkBack/VoiceOver, system setting names. Pairing on this machine is informally green only.
5. **Gate G2 + Phase 2/3 real stack:** Play Console SMS/call-log declaration; real relay host, APNs, FCM (owner inputs in `phase-02-merge.md`).
6. **Apple CI:** `ci-apple` has been cancelled repeatedly when multiple `workflow_dispatch` runs overlap (concurrency). Prefer **one** dispatch and do not cancel/stack. Hub/android/shared/relay CI were green after the beta/CI fixes; re-check before relying on apple green. (2026-10-04: `ci-apple` now runs four parallel lanes, ~3–4 min.)
7. **Release files (2026-10-04):** tag-driven `release-android` / `release-apple` build and sign the APK, the iOS IPA and the Mac DMG; the hub's `release-collect` copies them (checksums checked) into the hub's Release, the one download page (`docs/deployment-guide.md`, Release builds). `v0.1.0-beta.2` is complete on all five repos. On each new release, change the website's download link and home page badge (`docs/website.md`, Writing and translating). The Android release key is `~/Documents/HandLive-keys/handlive-release.jks` on the owner's Mac (`CN=Ho Xuan Dung, O=HandLive, C=VN`, certificate SHA-256 `bddc9efc…a0f9`; the first `CN=y` key is kept as `.bak` and signs nothing); its secrets live only in the environment `release` of handlive-android, which tags `v*` and `main` alone may use. macOS turns notarized with the paid team's seven secrets; split `release-apple` into sign / launch / publish jobs before adding them (scan report). App calls answer directly only when Android vouches for the call (CALL-05 API 1 logic 6, on `main` after beta.2).
8. **Clipboard images on the S25 (owner, 10 minutes):** both devices already run the Debug builds of 2026-10-05 03:35 (S25 debuggable APK, Mac `app.handlive.mac.localtest`), which log every silent outcome. Copy an image in Samsung Internet / Gallery / Chrome, press Send Clipboard, then read `adb logcat -s HLBENCH:I | grep -E 'copy_detected|clip_read'` (on the Mac: `/usr/bin/log stream --info --predicate 'process == "HandLive"' | grep clip_read`; `log` is a zsh builtin, use the full path). How to read it: `clip_read kind=image` → the read works, look at the send/ack lines; `clip_read_failed stage=read why=neither_text_nor_image mimes=… parts=…` → the OEM clipboard hands out an item HandLive does not recognize (the MIME types tell what to support); `stage=copy reason=permission_lost authority=com.sec…` → the One UI hypothesis (AOSP refuses URI grants on behalf of a system-uid clip owner, `UriGrantsManagerService.checkGrantUriPermissionUnlocked`); `stage=focus why=no_focus` → the read activity never got focus; `stage=start` → the system refused the background start; `copy_detected` with nothing after it on a release build means nothing (release builds do not log). On the Mac, `clip_read_failed reason=empty_or_not_text types=…` lists the pasteboard type identifiers of the copied item. First live sample (03:29:47, before these logs existed): `copy_detected` then silence. **Resolved 03:51:** the S25 has HandLive's Accessibility service **off**, blocked by Android 13+'s restricted-settings rule for sideloaded APKs (`appops get app.handlive.android ACCESS_RESTRICTED_SETTINGS` → rejected ~2026-09-30), so no copy is ever detected there; images only ever went untested on the manual button. Owner: App info › ⋮ › Allow restricted settings, then Accessibility › HandLive › On (SET-01 E7, field 14), then retry the image copy. **Done 03:57: with the service on, a Gallery image reached the Mac in 0.5 s (`clip_read kind=image … ack_received applied`). Root cause closed; the product follow-up is to detect the restricted-settings block and surface SET-01 field 14 earlier (the owner saw the block on 2026-09-30 and the app did not say so afterwards).** Also: `apple/iOS/Info.plist` has an uncommitted deletion of `NSLocalNetworkUsageDescription` (2026-10-04 20:36) that breaks `GeneratedFilesTests.purposeStrings` and the iPhone's local-network prompt; restore it with `git checkout -- iOS/Info.plist` unless it was meant.

### Plan next (priority order)

0. **Keep the README roadmap current** after every concrete finish (same change set as code/docs). Rule in hub README → Roadmap and progress.
1. **Owner hardware day for G4:** BT pair S25 ↔ Mac, grant Bluetooth permission, one real call through `HFPSpike`; write `phase-04-spike-d1.md`.
2. **Owner inputs for G5:** paid Apple Developer team; run CameraSpike; write/update `phase-05-spike-d6.md`.
3. **Owner decisions for G6:** Safari / Samsung Internet; install Firefox/Edge/Brave for matrix; then open WEB-01…05 only after go/no-go.
4. ~~Quiet-host e2e~~ **done 2026-10-05** on API 35 (`all`: 0 FAIL) and API 29 (`reports/reinstall-devices-and-quiet-host-e2e-2026-10-05.md`); rerun after Phase 1–3 code changes.
5. **Formal G1 matrix** on ≥2 Android phones + 1 Mac (latency, a11y, setting names).
6. **G2 + production push:** Play forms; deploy/configure relay; APNs `.p8` + FCM. Logo and app icons exist
   (`docs/brand-guidelines.md`, hub branch `feat/ckm-brand-from-start-008ce2`,
   `feat/brand-identity` in shared/android/apple, 2026-10-01); still
   open: an Icon Composer `.icon` for Liquid Glass (the mark on the welcome screens landed 2026-10-04).
7. **After gates:** Phase 4/5/6 **product** cards (not spikes) on `feat/phase-0N-*` as usual; one repo per commit; `shared/` first when contracts change.

### Archive

Older handoffs (2026-09-29 pairing AUTH_FAILED open bug, spikes still on feat branches) are superseded: pairing is stable; spikes are on `main`. Details remain in
`plans/20260925-implementation/reports/real-device-session-2026-09-29.md` and the phase spike reports.

## Next steps (handoff of 2026-09-29 — archive)

0. **Real-device session of 2026-09-29 (read `plans/20260925-implementation/reports/real-device-session-2026-09-29.md`
   first).** A Galaxy S25 Ultra (adb `R5GL320PPZT`) is connected; the G6 probe and a HandLive debug build are
   installed on it, and a HandLive debug build runs on this Mac from `~/Applications/HandLiveDev.app`.
   - **Open bug:** HandLive QR pairing phone ↔ Mac fails with AUTH_FAILED on real devices; root cause unknown (split
     phone vs Mac with the `shared/tools/e2e` fake Mac, fix test-first on `fix/real-device-pairing`).
   - G6 real-device results are in `phase-06-spike-g6.md`; owner decisions pending on Safari (Accessibility) and
     Samsung Internet (origin only); HOME does not end a page on Android 16 (probe bug).
   - G4 needs the S25 paired with the Mac over Bluetooth and the Bluetooth permission granted — owner actions.

1. **Gates G5 and G6 (Phases 5 and 6 go before Phase 4, owner decision 2026-09-28).** Both probes are built and
   pushed; each needs the owner's hardware.
   - G5: `apple/Tools/CameraSpike` on `feat/phase-05-camera-mic`, runbook in its README, results in
     `reports/phase-05-spike-d6.md`. Signing the host app needs a **paid Apple Developer Program team** (the current
     team 3S93UPADXV is a free Personal Team without the System Extension capability).
   - G6: `android/tools/web-spike` and `apple/Tools/WebSpike` on `feat/phase-06-web-handoff`, results in
     `reports/phase-06-spike-g6.md`. Needs real phones with Samsung Internet, Firefox, Edge, Brave installed, the
     accessibility service turned on by hand, and Automation grants on macOS 26 and 13/14.
   - No other Phase 5 or 6 card starts before its gate.
2. **Phase 4, gate G4: the HFP spike.** It needs the owner's hardware.
   - Run `apple/Tools/HFPSpike` from branch `feat/phase-04-call-audio`, following the runbook
     `apple/Tools/HFPSpike/README.md`.
   - Hardware: an Android phone with a SIM, paired to the Mac over Bluetooth, and a real call.
   - Fill in `reports/phase-04-spike-d1.md`. G4 also asks for runs on macOS 26 and on macOS 13 or 14.
   - Decide whether HFP or Opus/WS is the primary path (update AUDIO-02 and plan D1) before any other Phase 4 card.
3. **Rerun the end-to-end checks on a quiet host** with `shared/tools/e2e`.
   - Use an emulator that is not paired with the Mac test app, and pull `android/` before building the APK.
   - Rerun:
     - the PIN pairing fixes (android `0cd3a61`…`c0d2d51`);
     - the capability after a late permission grant (`9415777`);
     - the feature list after the first pairing (`cf567c8`, harness `88da57a`);
     - the 4408 check on API 29.
4. **Before the first release:**
   - gates G1 and G2, and the Phase 2 and Phase 3 checks on real devices;
   - the owner inputs listed in `phase-02-merge.md`: relay host and pins, APNs key, Firebase, app ids, logo and icon.
5. **Live Mac ↔ emulator testing** uses emulator `hl-claude-api35` (serial `emulator-5580`) with a debug build of the
   Mac app.
   - How to rebuild the bridge and the debug build: `build/dev-bridge/README.md` (this machine only, git-ignored).
   - The host is overloaded (`fileproviderd`, Synology Drive, Spotlight) and freezes the emulator for seconds, so
     timing results from this machine do not count.

## What HandLive is

An open source project (Apache-2.0) that brings ecosystem-native features, such as Apple Handoff and
Continuity, to Android. An Android device stays in sync with a Mac (clipboard, SMS, calls including
live **call audio**, camera/mic) and with iPhone/iPad (clipboard + SMS + call metadata only, no
audio), and those Apple devices sync back to Android. End-to-end encryption is always on.

Design tagline: **"WebSocket for data, Bluetooth for voice."**

## Core architectural decisions (do not silently reverse — see `plans/20260924-definitive-architecture/plan.md`)

- **Transport split:** WebSocket (Ktor server on Android, mDNS/`NsdManager` discovery) is the
  primary channel for *all* data — clipboard, SMS, call metadata, notifications. Bluetooth HFP SCO
  is used for exactly one thing: relaying **cellular call audio** to macOS, because Android 10+
  blocks call-audio capture via public APIs and HFP is the only proven path (Microsoft Phone Link
  uses it).
- **Call-audio fallback chain:** HFP SCO (primary) → Opus-over-WebSocket (~100–150ms) when HFP is
  unavailable (AirPods hold the HFP slot, out of BT range). The Opus/WS path is a permanent
  designed-in fallback, promotable to primary if HFP proves unworkable. It runs through Shizuku
  (shell uid): impossible on Android 10, call-audio capture works only on some Android 11+ devices,
  uplink injection (Android 13+) is unverified — plan §13 D10.
- **Feature independence:** every feature must work standalone — a clipboard failure must not take
  down SMS, etc. Capability negotiation on connect: features activate only when *both* peers support
  them.
- **End-to-end encryption everywhere, no opt-out.** Envelope is plaintext JSON; `payload` is
  XChaCha20-Poly1305-encrypted. The HFP/SCO call-audio path relies on Bluetooth link encryption
  only, because apps cannot touch SCO frames of cellular calls (plan §13 D11; residual KNOB/BIAS
  risk is disclosed to the user); the Opus/WS path is TLS + E2E. Session keys via X25519 ECDH +
  HKDF-SHA256, exchanged through **QR-code pairing** (256-bit entropy; a 6-digit-PIN + Argon2id path
  is the fallback).
- **iOS is intentionally second-class:** no call-audio relay (Apple exposes no HFP HF API). Do not
  attempt to add it.
- **Camera/mic streaming (Phase 5):** Android Camera2→MediaCodec (H.264 HW) + libopus over a
  *separate* WebSocket channel (never shared with the control channel); macOS decodes via
  VideoToolbox and exposes a **CMIOExtension** virtual camera + **AudioServerPlugin** (HAL) virtual
  mic. WiFi is primary; USB (ADB port-forward) is an optional auto-detected latency boost.

## Planned tech stack (per component)

| Component | Language / key APIs |
|-----------|---------------------|
| Android app | Kotlin, minSdk 29 / targetSdk 35; Ktor WebSocket server; Camera2 + MediaCodec; `TelecomManager` + `TelephonyCallback` (no `InCallService` — plan §13 D9); stock Bluetooth stack as HFP AG; Shizuku (optional) for the Opus/WS call-audio fallback; Google Tink crypto; libopus via JNI |
| macOS app | Swift 6, AppKit + SwiftUI, macOS 13+; Network.framework (`NWConnection` WebSocket, `NWBrowser` Bonjour); `IOBluetoothHandsFreeDevice` (HFP HF); `AUVoiceProcessingIO` (echo cancel); CryptoKit; CMIOExtension + AudioServerPlugin; VideoToolbox |
| iOS/iPadOS app | Swift 6, SwiftUI, iOS 16+; WebSocket + APNs alert + Notification Service Extension (metadata only; no PushKit/CallKit — detailed design C7); clipboard + SMS |
| Cloud relay | Rust, Actix-web + actix-ws; zero-knowledge (relays encrypted blobs only, never decrypts/logs payloads); self-hosted single VPS initially |

## Development phases (build in order; exception: Phases 5 and 6 before Phase 4 finishes)

1. **Clipboard sync** (MVP): Android FG service + Ktor WS server + mDNS + QR pairing + XChaCha20 E2E
   ↔ macOS menu-bar app. Target: text <50ms, 5MB image <2s.
2. **SMS bridge** + iOS app + Rust cloud relay + push.
3. **Call metadata + control** (public Telecom APIs + floating `NSPanel`: answer/reject/end;
   hold/DTMF/mute via HFP AT commands once Phase 4 lands).
4. **Call audio relay** (HFP/SCO + Opus/WS fallback + AEC). Starts with a 1-week HFP spike; legal
   disclosure UI required before enabling.
5. **Camera/mic virtual devices** (CMIOExtension + AudioServerPlugin). Starts with a 1-week
   CMIOExtension spike.
6. **Web Handoff ("Continue Browsing")**: the page open in the foreground browser appears on the other device
   (Android AccessibilityService reading the URL bar, Mac Apple Events; iPhone/iPad receive only). Starts with the
   G6 spike; design `plans/20260928-web-handoff/plan.md`, group 9 of the detailed design.

## Conventions specific to this repo

- **README roadmap is the live progress board.** When a concrete task finishes (phase card merge, gate close,
  spike go/no-go, real-device fix on `main`), update in the **same** change set: `README.md` + `README.vi.md`
  progress table and Status blurb, `docs/project-roadmap.md` + `.vi.md` snapshot, hub `CHANGELOG.md` /
  `CHANGELOG.vi.md` when user-visible, and this file's Next steps when the agent handoff changes. A finished
  task without a README roadmap update is incomplete.
- **Plans** live in `plans/<YYYYMMDD>-<slug>/plan.md`. Reports go under a `reports/` subdirectory.
  Prefer updating the relevant existing plan over creating parallel ones.
- **Message protocol wire format** (already specified — match it): JSON envelope
  `{v, type, id (uuid-v7), ts (ms), payload (base64 encrypted)}`; audio uses a raw binary frame
  `[0x48 0x4C][ver:1B][seq:4B][ts:4B][encrypted_opus:NB]` instead of JSON wrapping. The `type` set
  is extended with `session` and `camera`; the fine-grained `op` lives inside the encrypted payload
  — see `docs/detailed-design/00-common-specs.md`.
- **Detailed design** lives in `docs/detailed-design/` (one file per function group, each leaf
  function with 5 sections; shared protocol, error codes and data model in `00-common-specs.md`).
  Implement against it; add new message types, error codes or tables there first.
- **UI follows the HandLive Design System** (Apple Human Interface Guidelines on every platform,
  Android included; source mirrored in `docs/design-system/`, tokens in
  `shared/design-tokens/tokens.json`; decisions in `plans/20260924-apple-hig-design-system/`).
  Every UI string has a stable key in `shared/strings/ui-strings.json` with English and Vietnamese
  text, generated into Android resources and Apple String Catalogs — never hard-coded. English UI
  text uses Apple's English style (title-style capitalization for buttons, menus, window titles);
  Vietnamese UI strings use Apple-style diacritics (hủy, xóa, tùy, mã hóa) and the design system's
  terminology ("bảng nhớ tạm", not "clipboard").

- **License and commits:** every repository is Apache-2.0 (`LICENSE`), except the hub's `website/` (WordPress theme
  and site tooling), which is GPL-2.0-or-later as WordPress requires (owner decision 2026-10-04; WordPress and
  Polylang are installed at setup, never committed). New third-party code or assets must be
  Apache-2.0-compatible (Apache, MIT, BSD, ISC, MPL-2.0; OFL for fonts — never GPL, LGPL or AGPL) and bundled
  assets are listed in that repo's `NOTICE`. Commits carry a real person's name and a DCO sign-off
  (`git commit -s`); `.githooks/commit-msg` and the `commit-policy` CI job reject AI identities and co-author
  trailers — enable the hooks with `tools/workspace.sh hooks`. Community files (CONTRIBUTING, SECURITY,
  CODE_OF_CONDUCT, PR/issue templates) live in the org repo `HandLive/.github`, checked out as `.github-org/`.

## Implementation hand-off (coding agents start here)

- **Plan:** `plans/20260925-implementation/plan.md` — workspace layout (hub + the `android/`,
  `apple/`, `relay/`, `shared/` repositories), phase files `phase-00` …`phase-05` with task cards
  (owner prefix A/M/I/R/S/T, inputs, outputs, acceptance criteria, tests), gates (G0 test vectors,
  G1 latency targets, G2 Play Console, G4 HFP spike, G5 CMIOExtension spike). Reports go to
  `plans/20260925-implementation/reports/` and end with the status block from
  `~/.claude/rules/orchestration-protocol.md`.
- **Read in this order before coding a task:** this file → `docs/detailed-design/README.md`
  (catalog, conventions §3 incl. §3.5 UI wording, decisions C1–C21; read `X.md` or its Vietnamese
  twin `X.vi.md`) →
  `docs/detailed-design/00-common-specs.md` (protocol, errors, data model, settings keys) → the
  phase file → the leaf functions it names → `docs/code-standards.md`. UI work also reads
  `docs/design-system/README.md`, the platform section in `docs/design-system/3-platforms/` and the
  component READMEs.
- **Contracts:** wire format, error codes, settings keys and tables live in `00-common-specs.md`;
  change them there first, then the leaf spec (run `python3 tools/docs/validate_design_docs.py`,
  must print `problems=0`), then code. Never invent message types, error codes or UI strings in code
  — UI strings come from the string catalog, whose text matches the leaf specs (English in `X.md`,
  Vietnamese in `X.vi.md`).
- **File ownership:** every part is its own git repository. Android agents work in `android/`
  (handlive-android) and, when the contract data must change, in `shared/` (handlive-shared) as
  separate commits; Apple agents `apple/` + `shared/`; relay agents `relay/` + `shared/`. Docs,
  plans and reports change only in this hub repository. Any change in `shared/` (test vectors,
  schemas, tokens) is called out in the report so the other platforms re-run their tests — platform
  CI does not trigger on it by itself (start the workflow by hand).
- **Workspace layout is mandatory:** build scripts and tests resolve `../shared`, Apple tests also
  read `../docs`; each part carries a short `CLAUDE.md` saying so. CI reproduces the layout by
  checking out the hub at the workspace root, the part into `<part>/` and handlive-shared into
  `shared/` (`docs/deployment-guide.md`, CI section).
- **Branches and commits:** one branch per phase (`feat/phase-0N-<slug>`) in every repository the
  phase touches, the hub included for docs. **Commit early and small:** at least one commit per task
  card, and a separate commit for each logical step inside it (scaffold, then a module, then its
  tests, then docs) — never one commit per phase, and a commit never spans two repositories (commit
  `shared/` first, then the platform). Commit before writing the report and list the commit hashes
  with their repository in it. Conventional commits (`feat(android): …`, `test(relay): …`,
  `docs: …`), no AI references in messages.
- **Doc tools:** `tools/docs/validate_design_docs.py` (template + Mermaid check),
  `tools/docs/apple_diacritics.py` (Apple-style tone marks; dry run by default, `--write` to apply),
  `tools/docs/build_design_html.py` (HTML export to `build/docs/`; needs the `markdown` package:
  `$HOME/.claude/skills/.venv/bin/python3`). Design-system edits go to `docs/design-system/` first,
  then the artifact is republished. Contract tools live in `shared/tools/` (`vectors/`, `schemas/`)
  and run from the `shared/` repository root with its venv (`shared/tools/.venv`).

## Key risks the design already commits to mitigating

- `IOBluetoothHandsFreeDevice` is fragile (legacy API, no confirmed working reports on macOS 13+;
  the Phase-4 one-week spike decides go/no-go). All BT-HFP calls must sit behind an abstraction
  layer (`CallAudioRelay` interface) so the Opus/WS fallback or a future `CompanionDeviceManager`
  path can swap in.
- SMS permissions (`READ_SMS`/`SEND_SMS`) risk Play Store rejection → fallbacks: Notification
  Listener Service, then F-Droid/direct APK.
- Android OEM Bluetooth fragmentation → strategy-pattern adapters (`SamsungBtAdapter`,
  `PixelBtAdapter`, `GenericBtAdapter`).
