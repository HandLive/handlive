# Release pipeline — installable files for a version tag (2026-10-04)

Owner report: tags were created but no installable build ever appeared.

## Root cause

- No release workflow existed in any of the five repositories; `docs/deployment-guide.md` said "No build pipeline
  yet". The CI workflows run on pushes to `main`/`feat/**` only, so a pushed tag triggered nothing.
- The `v0.1.0-beta.1` Releases (hub, android, apple, relay, shared) were created by hand with 0 assets.

## Owner decisions

Android `foss` APK, iOS unsigned IPA, macOS Developer ID + notarization written now (gated on secrets), relay skipped;
the owner creates the Android keystore; merge to `main`, dry run `publish=false`, then publish; backfill
`v0.1.0-beta.1`.

## What was built

| Repo | Workflow | Jobs | Output |
|------|----------|------|--------|
| android | `release-android` | `build` (read-only, no secret: Gradle `assembleFossRelease`, no build cache) → `sign` (environment `release`, `contents: write`: zipalign -P 16, apksigner, publish) | `HandLive-<v>-android-foss.apk` + `.sha256` |
| apple | `release-apple` | `build` matrix ios/macos (read-only, no secret) → `release` (environment `release`, `contents: write`: Developer ID signing inside out, notarytool, stapler, launch check, publish) | `HandLive-<v>-ios-unsigned.ipa` (+ `HandLive-<v>-macos.zip` with the 7 macOS secrets) + `.sha256` |

- Triggers: pushed tag `v*`; manual run with `tag`, `publish` (false = artifacts only), `replace` (attached files are
  never replaced otherwise).
- Checks: tag regex (one line); tag = `versionName` / version core = `MARKETING_VERSION`; warning when the build
  number is not above the previous tag's; hub/shared at the same tag, 404 → `main` with a warning, other API errors
  stop.
- macOS: an ad-hoc/unsigned binary gets -34018 from the data-protection Keychain (verified locally), so no unsigned Mac
  app is published. The profile is checked (team, App ID, `ProvisionsAllDevices`, certificate, three capabilities);
  any Mach-O beyond the main executable and top-level frameworks stops the job.
- Docs: `docs/deployment-guide.md` (en, vi) Release builds; README status row; `CLAUDE.md` handoff item 7;
  CHANGELOGs of hub, android, apple.

## Review

Code-reviewer, first pass: no Critical. Fixed: H1 (signing secrets and write token shared a job with third-party
build code → split jobs + environment), M1 (PKCS12 key password = store password → optional secret), M2 (silent
fallback to `main`), M3 (profile checks + launch check), M4 (`--clobber` over published files → `replace` input), L1–L9
(newline in tag, `find -exec` hiding codesign failures, secret files left on failure, nested code guard, 16 KB
alignment, build cache, docs on partial secrets, build-number warning, README/CLAUDE.md).

## Verification

- `actionlint` (with shellcheck) clean; shell fragments (nested-code guard on a real `SQLCipher.framework` layout,
  profile certificate extraction, version reads, tag regex with a newline) tested locally.
- Dry runs of `v0.1.0-beta.1` (`publish=false`):
  - android run 37200887646: `build` green (279 s, unsigned APK artifact 16.8 MB); `sign` stopped on the missing
    secrets, as intended.
  - apple run 37200890495: green; IPA verified (SHA-256 OK; `Payload/HandLive.app` with the Notification Service
    Extension and `SQLCipher.framework`; 0.1.0, `app.handlive.ios`); Mac app compiled, notice "macOS not published".
- Publish: apple run 37201988578 attached `HandLive-0.1.0-beta.1-ios-unsigned.ipa` (+ `.sha256`) to the existing
  pre-release `v0.1.0-beta.1`.
- Not run yet: Android signing (no keystore), the whole macOS signing/notarization path (no paid team).

## Commits (merged to `main`, pushed)

| Repo | Commit | Subject |
|------|--------|---------|
| android | `4f97235` | ci(android): release workflow that attaches the signed APK to a tag's Release |
| apple | `357886e` | ci(apple): release workflow for the iOS IPA and the notarized Mac app |
| hub | `2dbd97a` | docs: release builds, how to cut a release and the signing secrets |
| hub | `fac41ed` | docs: README status and handoff for the release workflows |

## Unresolved questions

- Owner: create the Android keystore and its secrets (ideally `--env release`), then rerun `release-android` for
  `v0.1.0-beta.1` with `publish=true`.
- Owner: protect the environment `release` (required reviewer, tags `v*`) and add a tag ruleset for `v*`.
- Paid Apple Developer team: the seven macOS secrets; the first real run tests the signing path. A `.p12` exported on
  macOS 26/27 should be test-imported on a macOS 15 runner once.

Status: DONE_WITH_CONCERNS
Summary: Tag-driven release workflows exist for Android and Apple; the iOS IPA is attached to v0.1.0-beta.1; Android
waits for the owner's keystore secrets and macOS for the paid Apple team.
Concerns/Blockers: Android and macOS signing paths not exercised yet (owner inputs).
