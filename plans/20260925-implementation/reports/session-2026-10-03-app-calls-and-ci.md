# Session handoff — CALL-05 app calls + Apple CI fix (2026-10-02/03)

Workspace main tips after this session: hub `650240e` (+ uncommitted below), shared `af3629f`, android `c18813c`,
apple `a752c67`, relay `cda13bf` (unchanged). All committed work is merged to `main`; the primary checkouts
`~/HandLive/{shared,android,apple,relay}` are on `main` at those tips.

## Done (on `main`)

1. **CALL-05 — calls from other apps on the Mac** (Telegram first). Full feature across hub docs, `shared` contracts,
   `android`, `apple`; reviewed, fixed (1 High + 6 Medium + Lows), tested on real devices (S25 ↔ this Mac):
   panel ≤ 400 ms, Decline/End ≤ 500 ms, Answer ≤ 1 s, no caller name in logs. Audio stays on the phone (v1).
   - Pairing re-done with PIN on real devices; a one-sided-pair bug (Mac key reset leaving a stale `paired-devices.bin`)
     was spun off as a separate task.
   - Mac now rings even when the build cannot read Focus status (no Communication Notifications capability) —
     `FocusState.unavailable`; CALL-01 API 5 logic 3 updated.
2. **Call-audio to the Mac: decided v1 = audio on the phone.** Evidence gathered and recorded:
   - HFP SCO is a no-go on macOS 27 (framework `kIOReturnUnsupported`, phone-side eSCO rejected `0x0D`); confirmed by an
     independent report. (`phase-04-spike-d1.md`, `phase-03-app-calls-spike.md`, `research-macos-hfp-sco-2026-10-02.md`.)
   - Shell/Shizuku capture of a VoIP app's downlink is a no-go on the S25 (Android protects `USAGE_VOICE_COMMUNICATION`;
     scrcpy `output`/`playback`/`voice-call` all silent). Owner confirmed phone-only for v1.
3. **Apple CI: from "hangs 90 min / can't build" to green** (branch merged to `main`, then deleted). Five pre-existing
   issues, all masked by the hang until it was fixed (`ci-apple-hang-and-errorcode-diagnosis-2026-10-03.md`):
   - Pairing search infinite loop (a transient connect error blacklisted the only instance forever) — real product bug.
   - Pairing fallback too broad (connected to an instance advertising a wrong `pr`/`pm`) — tightened to absent-hint only.
   - `skipsUnreachableStaleInstance` order-flaky — compare attempts as a set.
   - HLAppCore `resendAfterReconnect` races under parallel test execution — CI now runs tests serially.
   - swiftlint `--strict` debt (AppModel 267 lines; PairingSearch length/tuple/complexity) — split files, dropped an
     unused tuple member, extracted a helper, one narrow justified `disable`.
   - Verified: HLTransport 124/124, HLMacUI 69/69, HLAppCore 116/116 (serial), swiftlint 0 violations, CI end-to-end
     success. Pairing behaviour (validated on device) preserved.
4. **Branch hygiene:** merged `feat/phase-03-app-calls` to `main` in shared/android/apple + the hub docs; deleted all
   merged remote branches across the three repos.

## Committed on owner request 2026-10-04

Previously left uncommitted, then committed when the owner asked to "commit everything":

- Phase 7 "Connect anywhere" proposal: `phase-07-ket-noi-moi-noi(.vi).md`, `reports/phase-07-brainstorm(.vi).md`,
  `reports/research-direct-wifi-link-2026-10-01(.vi).md`, and the Phase 7 rows / CALL-05 index row in `README(.vi).md`,
  `docs/project-roadmap(.vi).md`, `plans/.../plan(.vi).md` (still a proposal, not scheduled).
- `reports/ci-apple-hang-and-errorcode-diagnosis-2026-10-03.md` and this handoff.
- `android/tools/audio-spike/` — the shell-audio probe, committed as a debug tool (like `tools/call-spike`); its
  finding is a no-go, not product code.

## Next steps

1. **Decide Phase 7**: commit the Phase 7 docs (they are entangled with the plan/README/roadmap edits) or drop them;
   then update the README roadmap for CALL-05.
2. **Finish T3.3** for CALL-05: cellular exclusion on a phone **with a SIM**, tap-to-answer (Accessibility off), screen
   off/locked, relay path, Zalo/WhatsApp; add `app_call_*` support to `call_latency.py`.
3. **CALL-05 follow-ups** (from the review): user-dismissed in-call notification ending the call early (L4); app-label
   falling back to the package name — needs `<queries>` / verify "Telegram" shows (L12).
4. **Apple test robustness**: HLAppCore call/session timing tests run serially in CI as a workaround; a virtual clock
   would let them run in parallel again. `PairingSearch.run` carries one `swiftlint:disable cyclomatic_complexity`.
5. **Mac pair-store stale-key bug**: the spawned task was started separately; land that fix.
6. **Gates unchanged**: G1 (device matrix/a11y), G2 (Play Console), G4 (call audio — now effectively no-go via HFP/
   Shizuku on current OSes), G5 (camera/mic, paid Apple team), G6 (browser go/no-go).

## Unresolved questions

- Phase 7: commit now or keep as a proposal until gates close?
- Should the hub CLAUDE.md "Next steps" handoff be updated from this report (separate hub commit)?

Status: DONE
Summary: CALL-05 app calls shipped to `main` and tested on real devices (audio stays on the phone for v1); Apple CI
fixed and green on `main`; all primary checkouts returned to `main`; Phase 7 and session CI docs left uncommitted.
Concerns/Blockers: Phase 7 decision pending; T3.3 scenarios and CALL-05 follow-ups remain; Mac pair-store bug fix
pending in its own task.
