English | [Tiếng Việt](plan.vi.md)

# HandLive implementation plan — hand-off to coding agents

**Status:** Phase 0 and Phase 1 merged into `main` of every repository (2026-09-26, the project owner merged Phase 1 before gate G1 — the G1 real-device checks are still open, `reports/phase-01-merge.md`); Phase 2 code complete on `feat/phase-02-sms-ios-relay` (2026-09-26, started before G1 by decision of the project owner; not merged: the real-device, relay, APNs and FCM checks and gates G1 and G2 are open, `reports/phase-02-summary.md`) · **Sources:**
`plans/20260924-definitive-architecture/plan.md` (architecture, D1–D12), `docs/detailed-design/` v1.2
(33 leaf functions, C1–C20), `docs/design-system/` (Apple HIG, version 6), `docs/code-standards.md`,
`docs/project-roadmap.md`.

## 1. Planning decisions

| # | Decision | Rationale |
|---|-----------|-------|
| I1 | **Five repositories in one workspace** (since 2026-09-25, decided by the project owner so that each part can go into a group; previously a monorepo): the hub `handlive` (docs, plans, `tools/docs/`) and four repositories `handlive-android`, `handlive-apple` (macOS + iOS + shared Swift packages), `handlive-relay`, `handlive-shared` (test vectors, schemas, design tokens, `tools/vectors`, `tools/schemas`), cloned into `android/`, `apple/`, `relay/`, `shared/` inside the hub folder — `tools/workspace.sh`; report `reports/repo-split.md` | Each part is pushed to the group separately; the three platforms still match one wire protocol because the test vectors and schemas exist in a single copy in `shared/`, and builds and tests read them through `../shared` |
| I2 | **Phase 0** builds the scaffold, the protocol and encryption libraries and the cross-platform test vectors before any feature | Every later phase reuses them; encryption mismatches between Tink and CryptoKit must surface from the start |
| I3 | Phases 1 → 5 in roadmap order; one branch per phase `feat/phase-0N-<slug>`, merged into `main` once the measurable criteria are met (exceptions decided by the project owner on 2026-09-26: Phase 1 merged and Phase 2 started before gate G1; G1 still has to pass before Phase 2 ships) | Each phase is a usable product |
| I4 | Phases 4 and 5 open with a **one-week spike** with a go/no-go gate (D1, D6) before any feature code | Risks R1, R6 |
| I5 | UI strings come from the catalog `shared/strings/ui-strings.json` (stable keys, `en` + `vi`, 0.12); the wording matches the detailed design (English `X.md`, Vietnamese `X.vi.md`); the UI is built to the design system (components, tokens, wording) | No strings written in code; both languages always complete |
| I6 | When code and docs disagree: fix the docs first (00-common-specs → leaf function), run `tools/docs/validate_design_docs.py`, and only then change the code | The docs are the contract between the platforms |
| I7 | **Multilingual product, bilingual docs** (project-owner decision 2026-09-25, C20): English is the product's default language, Vietnamese the second; the localization foundation (string catalog, resource generators, language selection) is built in Phase 1 before any screen. Every document has `X.md` (English, canonical) and `X.vi.md` (Vietnamese), changed in the same commit; agent reports are written in English only; plans and reports from before 2026-09-25 stay in Vietnamese as an archive; file names stay as they are, as identifiers | Open source aimed at an international community; Vietnamese users still get a complete UI and documentation |
| I8 | **Only open-source dependencies in the app**: no ML Kit or Play Services (QR scanning uses CameraX + ZXing core); FCM only in a separate flavor (Phase 2) | Apache-2.0 and the F-Droid/APK distribution path (Plan B of gate G2) |

## 2. Phases

| Phase | Goal | Leaf functions | Platforms | Depends on | Measurable criteria | File |
|-------|---------|--------------|----------|-----------|-------------|------|
| 0 | Repository scaffold, protocol, encryption, tokens, CI | 0.2–0.8 of the common specs | All three | — | Cross-platform test vectors green; CI green | [phase-00-khung-va-dung-chung.md](phase-00-khung-va-dung-chung.md) |
| 1 | Android ↔ Mac clipboard on the LAN (MVP), English and Vietnamese UI | SET-01, SET-02, SET-03, PAIR-01 (LAN), PAIR-02, PAIR-03 (flow A), CONN-01, CONN-02, CLIP-01, CLIP-02, CLIP-03, CLIP-05 | Android, macOS | 0 | Text < 50 ms on the LAN; 5 MB image < 2 s; reconnect < 3 s | [phase-01-bang-nho-tam-mvp.md](phase-01-bang-nho-tam-mvp.md) |
| 2 | SMS, iPhone/iPad app, relay, push | SMS-01…05, CONN-03, CONN-04, CLIP-04, PAIR-01 (relay), PAIR-03 (remote), SET-02 (the remaining parts) | All three + relay | 1 | SMS notification < 500 ms; reply confirmed < 2 s | [phase-02-sms-ios-relay.md](phase-02-sms-ios-relay.md) |
| 3 | Call information and control | CALL-01…04 | Android, macOS, iOS | 2 | Incoming call < 200 ms; answer < 500 ms end to end | [phase-03-cuoc-goi.md](phase-03-cuoc-goi.md) |
| 4 | Taking calls on the Mac | AUDIO-01…04, CALL-03 (hold, DTMF, mute over HFP) | Android, macOS | 3, spike D1 | MOS ≥ 3.5 (HFP), ≥ 3.0 (Opus/WS); ERL > 40 dB | [phase-04-am-thanh-cuoc-goi.md](phase-04-am-thanh-cuoc-goi.md) |
| 5 | The phone as webcam and microphone | CAM-01…05 | Android, macOS | 1, spike D6 | Latency < 120 ms over Wi-Fi, < 70 ms over USB at 720p30 | [phase-05-camera-micro.md](phase-05-camera-micro.md) |

Effort estimate (roadmap): P1 3.5 · P2 4 · P3 3 · P4 6 · P5 5.5 person-months; Phase 0 about 0.5.

## 3. How to hand work to agents

Each task card in a phase file has: a code (`A1.3`, `M2.1` …, first letter = platform: A Android,
M macOS, I iOS, R relay, S shared, T test), inputs (doc sections to read), outputs (paths created or
changed), acceptance criteria, tests. The hand-off prompt contains exactly the items of
`~/.claude/rules/orchestration-protocol.md`: task, files to read, files it may modify, acceptance
criteria, constraints, work context path (`/Users/hxd/HandLive` — the workspace root, holding all
five repositories; the agent works in the repository of its part), reports path
(`plans/20260925-implementation/reports/`).

**Mandatory reading order before writing code:** `CLAUDE.md` → `docs/detailed-design/README.md` (catalog, conventions §3, decisions C1–C20; every document has two versions — the English `X.md` is canonical, the Vietnamese `X.vi.md` has the same content) → `docs/detailed-design/00-common-specs.md` → the phase file → the leaf
functions it names → `docs/code-standards.md`. UI work also reads
`docs/design-system/README.md`, the matching platform section in `docs/design-system/3-platforms/`
and the README of each component involved.

**File ownership:** each part is its own git repository. Android agents edit only `android/`
(handlive-android) and `shared/` (handlive-shared, in separate commits); Apple agents only `apple/`
and `shared/`; relay agents only `relay/` and `shared/`. Any change to `shared/` (test vectors,
schemas, tokens) must be called out in the report so the agents of the other platforms re-run their
tests (platform CI does not run by itself when shared changes). Edit `docs/detailed-design/` (hub
repository) only when a mismatch is found, and run the validator.

**Common definition of "done" for every task card:**
1. The code builds and the tests pass on the platform toolchain (commands listed in the phase file);
   no hidden lint, type or build errors.
2. Every exception `E<k>` of the leaf functions involved has a test, or a manual test recorded in the
   report.
3. UI strings come from the catalog, with both `en` and `vi`, matching the detailed design; components
   follow the design system; VoiceOver/TalkBack can read the state; the UI is checked in both
   languages.
4. No secrets, keys, certificates or dotenv files in commits.
5. `docs/codebase-summary.md` is updated when the code structure changes.
6. A report in `reports/<phase>-<task code>.md`, written in English, ending with the `Status:` / `Summary:` /
   `Concerns/Blockers:` block.
7. **Commit small, commit early:** at least one commit per task card, with a separate commit for each
   logical step inside it (scaffold → module → tests → docs). Never bundle a whole phase into one
   commit; a commit never spans two repositories (commit `shared/` first, then the platform
   repository). Commit before writing the report and list the hashes with the repository names in
   the report.
8. When a document changes, change both `X.md` and `X.vi.md` in the same commit; `tools/docs/check_bilingual_docs.py`
   and `tools/docs/validate_design_docs.py` pass.
9. All repositories of a phase use the same branch name (`feat/phase-0N-<slug>`); CI checks out the
   branch of the same name in handlive-shared and the hub when it exists, otherwise `main`.

## 4. Gates and risks

| Gate | When | Criteria to go ahead | If not met |
|------|---------|------------------|---------------|
| G0 | End of Phase 0 | Encryption and envelope test vectors green on Android and Apple; CI green on all three platforms | Phase 1 does not start |
| G1 | End of Phase 1 | All measurable criteria met (95th percentile, `shared/tools/bench/` scripts) on ≥ 2 real Android phones (Pixel, Samsung) and 1 Mac | Fix before starting Phase 2 (waived by the project owner on 2026-09-26: Phase 2 has started, and G1 must pass before Phase 2 ships) |
| G2 | Before the Phase 2 release | Play Console: Permissions Declaration Form for SMS and the call log submitted (`docs/deployment-guide.md`) | Activate Plan B (Notification Listener for incoming SMS; F-Droid/APK distribution) |
| G4 (spike D1) | First week of Phase 4 | `IOBluetoothHandsFreeDevice` receives SCO audio in the HF role on macOS 13, 14, 15, 26 with Pixel and Samsung | Opus/WS becomes the primary path; HFP keeps only control; update AUDIO-02 and plan D1 |
| G5 (spike D6) | First week of Phase 5 | CMIOExtension delivers frames to Zoom/Meet/FaceTime; the AudioServerPlugin loopback is audible in meeting apps | Stop Phase 5, write a report |

Items to check on real devices (not open questions; they are tasks inside the phases): the system setting names in English and Vietnamese ("Privacy & Security" / "Quyền riêng tư & Bảo mật",
"Focus" / "Tập trung", "Paste from Other Apps" / "Dán từ ứng dụng khác") — A1.4, M1.1; the Magic
Replace effect on the menu bar icon — M1.4; whether `AudioRecord` captures call audio through
Shizuku on each device — A4.3.

## 5. Testing and devices

- Unit: encryption, envelope, chunking, the connection state machine (0.11), `clip_id` deduplication,
  conflict rule QC8.
- Integration: Android (real device or emulator) ↔ Mac on the same Wi-Fi network; the latency
  scenarios have scripts in `shared/tools/bench/`.
- Real-device matrix: Android — Pixel 8 (14/15), Galaxy S22/S23 (14), Xiaomi or OPPO (Android 13);
  Apple — Apple silicon Mac on macOS 26, Intel Mac on macOS 13 or 14; iPhone on iOS 16 and 26.
  Phases 4 and 5 add AirPods (HFP conflict) and a USB cable.

## 6. Documents to update during the work

`docs/codebase-summary.md` (code structure), `docs/deployment-guide.md` (signing, notarization, PKG,
Play Console), `docs/code-standards.md` (when a new convention appears), the detailed design when it
diverges (per I6), `docs/design-system/` when the UI changes (then republish the artifact) — always
together with the `.vi.md` version.

## 7. Open questions

None left. Every uncertain point has become a gate (section 4) or a real-device check in a phase
file.
