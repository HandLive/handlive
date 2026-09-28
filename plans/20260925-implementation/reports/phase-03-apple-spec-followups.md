# Phase 3 follow-up: Apple changes for the settled spec proposals

Date: 2026-09-28. Repository: handlive-apple, branch `fix/phase-03-spec-followups` from `origin/main` (`d8a9c93`).
Specs: hub `60818a8` (00-common-specs §0.10 `RECONNECT_BACKOFF`, 03-connectivity CONN-05, 06-call-control CALL-03 E6).

## What changed

1. **Reconnect backoff resets only after a stable session** (HLTransport).
   - `ConnectionManager.adopt` no longer resets `backoff`. It sets `backoffResetAt = now + configuration.backoffResetAfter`
     (new `ConnectionConfiguration.backoffResetAfter`, default 30 s).
   - `superviseSession` also waits for that deadline; once it passes while still `Connected`, `backoff.reset()`. A
     session that drops sooner keeps the current step. The relay upgrade recheck (60 s) does not fire on the reset timeout.
   - Immediate retry on network change or wake-up is unchanged.
2. **Call panel "Lost connection to the phone" waits 3 s** (HLAppCore, used by the Mac panel and the iOS banner).
   - `CallController.disconnected()` starts a task that sets `connectionLost` only after `connectionLostDelay` (3 s,
     same value as `reconnectGrace` but a separate knob) if the session is still gone and the call is the same and not
     ended. `connected()` and `clear()` cancel it; `connected()` still clears the flag at once.
   - `connected()` / `disconnected()` moved to the new `CallController+Session.swift` (file length lint limit 250).
3. **String catalogs**: `python3 Packages/HLLocalization/Scripts/generate-strings.py --check` against shared
   `fix/phase-03-spec-followups` (`8520c56`) → "OK: 11 files match ui-strings.json". No Apple change, nothing committed.

## Commits (handlive-apple)

- `2f369b5` test(apple): keep the backoff step after a session that drops before it is stable
- `321bbfc` fix(apple): reset the reconnect backoff only after a stable session
- `2a515dd` test(apple): show the call panel's lost connection only after three seconds
- `f66fa4a` fix(apple): wait three seconds before the call panel shows a lost connection

## Tests

- New: `HLTransportTests/ConnectionManagerBackoffTests.swift` (short sessions keep the step: attempt reaches 3 after
  three quick drops; a stable session resets to 0 while still connected). `ManagerHarness.make` takes a configuration.
- New: `CallContextTests.connectionLostNoticeWaits` (nothing right away, quick reconnect shows nothing, shown after the
  delay, hidden on reconnect); `reconnect` test updated to wait for the delayed flag.
- Both new tests failed before the fixes (red confirmed), pass after.
- Local (Command Line Tools mode, `HL_SWIFT_TESTING_PACKAGE=1 swift test`): HLTransport 103/103, HLAppCore 84/84,
  HLLocalization 9/9, HLMacUI 43/43, HLiOSUI 23/23. `swiftlint lint --strict`: 0 violations.

## CI

- `ci-apple` does not trigger on `fix/**` pushes; started by hand (workflow_dispatch):
  run 36364998462 — success (xcodebuild test + swiftlint + app build, 9m23s), hub `main`, handlive-shared
  `fix/phase-03-spec-followups`. No flaky test seen. The `commit-policy` job is skipped on workflow_dispatch; commits
  are signed off, no AI trailers.

## Notes

- The branch is pushed, not merged; `main` untouched. The `feat/phase-03-calls` working tree was clean before switching.
- A relay→LAN upgrade calls `adopt` again and restarts the 30 s stability timer (the new session counts from its start).

## Unresolved questions

- Should `ci-apple` also trigger on `fix/**` branches? Right now such branches need a manual run.

Status: DONE
Summary: Backoff now resets only after 30 s Connected, and the call panel's lost-connection notice waits 3 s; TDD commits pushed on `fix/phase-03-spec-followups`, CI green; Apple strings unchanged.
Concerns/Blockers: none; merge to main left to the project owner.
