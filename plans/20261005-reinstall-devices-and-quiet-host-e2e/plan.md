# Reinstall the fixed builds on the owner's devices, then the quiet-host e2e (2026-10-05, run 2)

**Status:** done except the owner's image copy on the S25 (PRs: shared #2 merged, android largeHeap PR, hub PR) · **Route:** feature (operations + roadmap item 4) · **Ship mode:** beta · **Repos:** hub (plan, report, roadmap), shared/android only if the e2e finds a bug

## Scope

1. **Reinstall with the clipboard image fix (`main` of 2026-10-05):**
   - S25 Ultra (adb `R5GL320PPZT`, Android 16): the installed app is the *debuggable* build labelled beta.2 (2026-10-04 20:56). Install the foss debug APK of android `bbdc6af` with `adb install -r` so the data and the pairing stay (same debug signer).
   - Mac: `/Applications/HandLive.app` is the *Debug* build with bundle `app.handlive.mac.localtest`, signed by the owner's Apple Development identity (team 3S93UPADXV), keychain group `3S93UPADXV.app.handlive.mac`, pair store in `~/Library/Application Support/app.handlive.mac.localtest/`. Build apple `84ffa11` the same way (Debug, bundle id and team overridden on the command line) so keychain items and the pair store stay; keep the old bundle in the scratchpad; quit, replace, relaunch.
   - Both builds are Debug on purpose: they write the `HLBENCH/1` lines (`clip_read`, `clip_read_failed`) the owner's device check needs.
2. **Owner device check** (CLAUDE.md "In progress" item 8) is the owner's; this run only prepares it and captures a first logcat sample if an image copy happens while attached.
3. **Roadmap item 4, quiet-host e2e:** `e2e.py all` on the API 35 emulator (`hl-claude-api35`, port 5580) with the APK of `main`, then the 4408 check on the API 29 emulator (`hl-api29`), after the Mac build finished so the host is quiet. Report latencies against the gate G1 targets as trends only.
4. **Docs:** report under `plans/20260925-implementation/reports/`, README roadmap row if a gate item closes, CLAUDE.md handoff.

## Acceptance criteria

- [x] S25 shows `versionName` of `main` with `pkgFlags DEBUGGABLE`, the pair survives (Devices tab lists the Mac, no re-pairing).
- [x] The Mac runs the new Debug build (`Identifier=app.handlive.mac.localtest`, same team), connects to the phone without re-pairing (an `ev=state … to=Connected` HLBENCH line).
- [x] `e2e.py all` on API 35: every step PASS or a known SKIP; failures investigated (bug → separate fix branch).
- [x] API 29: the 4408 step (a connection that never sends `session/hello` is closed) PASS.
- [ ] Report written; hub PR merged; CI green.

## Validation and red-team (inline: unattended run)

- *Could the reinstall lose the owner's pairing?* S25: `adb install -r` with a different signer fails without touching the app; it is never uninstalled without the owner. Mac: identical bundle id, team and entitlements; the old bundle is kept in the scratchpad for a rollback by copy.
- *Could the Debug Mac build misbehave vs the owner's?* It is the same configuration the owner has used since 2026-10-01 (dev bridge), now on `main` of 2026-10-05.
- *Rollback:* copy the saved bundle back to `/Applications`; `adb install -r` the beta.2 APK from the Release page.
