# Phase 3 spec follow-ups — Android

Date: 2026-09-28. Repository: handlive-android, branch `fix/phase-03-spec-followups` (from `origin/main` 3afbc39),
pushed. Built against handlive-shared `fix/phase-03-spec-followups` (8520c56). Hub specs: commit 60818a8.

## Changes

1. **String resources.** Android resources are generated at build time from `../shared/strings/ui-strings.json`
   (`:core:strings:generateStringResources`, `buildSrc/.../strings/`) and never committed, so the new catalog
   (`pairing.empty_body_android` text, new `setup.autostart_body`) needed no Android commit. Verified by the build
   and the catalog tests in `core/strings`.
2. **Keep HandLive Running (SET-01 field 8).** `AutostartScreen`
   (`app/src/main/kotlin/app/handlive/android/ui/onboarding/SetupScreens.kt`) now shows `setup.autostart_body` as
   the step body on every manufacturer, including ones without specific steps. The manufacturer steps
   (Xiaomi/OPPO/Samsung) moved below it, as secondary-label body text, above "Pause app activity if unused".
   The Settings › Permissions screen is unchanged (field 8 belongs to the setup step).
3. **RECONNECT_BACKOFF (0.10, CONN-05).** The only Android backoff is the relay client
   (`feature/relay/.../RelayConnector.kt`). It used to reset to the first step as soon as a link opened and on
   every `CLOSED`. Now it resets only when the link stayed open for 30 s (`RelayConstants.BACKOFF_STABLE_MILLIS`);
   a link that drops sooner counts as a failed try and the backoff keeps climbing. `networkChanged()` still
   cancels the wait and retries at once from step 0 (unchanged). The LAN side has no Android backoff: the phone is
   the server and clients reconnect.

## Commits (handlive-android)

- `fea16c3` feat(android): explain Keep HandLive Running on every manufacturer
- `6d765b8` fix(android): reset the relay backoff only after a stable link

## Tests

- New `app/src/test/.../ui/onboarding/AutostartScreenTest.kt` (Robolectric): the reason shows with no manufacturer
  (and no "Open Manufacturer Settings"), shows above the Samsung steps, and in Vietnamese. Written first; failed
  3/3 before the change.
- `RelayConnectorTest`: `aLinkThatDropsWithinThirtySecondsKeepsClimbingTheBackoff` (failed before the fix: reopened
  at 0.5 s) and `aLinkThatStaysThirtySecondsResetsTheBackoff`. Existing backoff tests still pass.
- `./gradlew check` locally: BUILD SUCCESSFUL.
- CI: `ci-android` run 36364815559 (workflow_dispatch; pushes to `fix/**` do not trigger it) — success, with
  hub → main, handlive-shared → `fix/phase-03-spec-followups`.

## Notes

- The Android branch needs handlive-shared `fix/phase-03-spec-followups` merged first (or together): against shared
  `main` the build fails, as `R.string.setup_autostart_body` does not exist there.
- `ci-android.yml` triggers on push only for `main` and `feat/**`; `fix/**` branches need a manual dispatch.

Status: DONE
Summary: Autostart step shows the reason sentence on every manufacturer; relay backoff resets only after 30 s of stable link; strings regenerate at build time (no commit needed). Local check and CI green.
Concerns/Blockers: Merge order — handlive-shared `fix/phase-03-spec-followups` must reach main before or with this branch.
