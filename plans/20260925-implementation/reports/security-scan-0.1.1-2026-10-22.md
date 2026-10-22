# Security scan before v0.1.1 (2026-10-22)

Owner request (15:12): pull the latest code, build the release and publish it on GitHub and the website. The owner
chose the tag `v0.1.1` (the first tag without a pre-release suffix) and asked for this scan before it, as
`docs/deployment-guide.md` (Cutting a release) requires: no critical or high finding may stay open.

## Scope

`git diff v0.1.0-beta.3..main` per repository, same method as the beta.3 scan (`security-scan-beta3-2026-10-07.md`):
threat model first, then the changed non-test code. Read only; no product code changed by this scan. `main` CI is
green on every repository at the commit scanned.

| Repo | `main` | Commits since beta.3 | Files | Content |
|------|--------|----------------------|-------|---------|
| hub | `299bf98` | 36 | 69 | docs, plans, store screenshots and listing, website Vietnamese copy, `tools/release/play-release.zsh` and `setup-fcm.zsh` (new), `tools/brand/` (Play feature graphic), `.gitignore` |
| shared | `66d27fc` | 7 | 7 | README; `tools/e2e/` only (adb device helper, fake Mac, scenario namespaces) |
| relay | `17f367b` | 2 | 2 | README only; no Rust change |
| android | `ed62ca4` | 7 | 11 | `applicationId` and `targetSdk` for Play, R8 on release, Play upload signing in Gradle, `play-bundle.yml` (new), clipboard URI policy (android #13 fix, #15) |
| apple | `e401f2a` | 11 | 23 | paid-team identifiers (App Group, extension bundle id, entitlements), Xcode 27 project settings, welcome-window delegate fix, screenshot UI-test seams and target, package AccentColor removal |

Verdict, all five repositories: 0 critical, 0 high, 0 medium, **1 low (deferred, not a blocker)**, 2 informational
notes for the release. The scan is PASS; the tag may proceed.

## Findings

| Sev | Where | Rule | Issue | Outcome |
|-----|-------|------|-------|---------|
| L | apple `Packages/HLiOSUI/Sources/HLiOSUI/IOSAppModel+Messages.swift:41-58`, `IOSAppModel+Calls.swift:36-47`, `Packages/HLAppCore/Sources/HLAppCore/SystemPermissions.swift:20-25` | Test code in production (UI-test seams) | Three XCUITest seams ship in the Release iOS build, each gated on a launch argument: `-HLUITestSeedDemoMessages` calls `store.resetForResync` (wipes the synced SMS history of the active pair) and inserts demo threads; `-HLUITestSeedIncomingCall` feeds a fake ringing call into the real `CallController`; `-HLUITestSkipNotificationRequest` reports notifications as allowed without asking. Both seed seams also write a debug line (pair id, call state) to `/tmp/…` (sandboxed on a device, so the write fails silently). An installed app receives launch arguments only from Xcode or an XCUITest runner, so a user or another app cannot trigger them; the data they could wipe is the local copy of a sync that the next sync restores. `project.yml` says the UI-test target is "Scratch, not committed" but it is committed (`HandLiveiOSUITests`, `iOS/HandLiveScreenshotUITests`). | **Deferred** (not a blocker): wrap the three seams and the debug writes in `#if DEBUG` in the next round, and fix the `project.yml` comment. Tracked in this report; no issue opened by the scan (owner's call). |
| I | android `app/build.gradle.kts:56` (`applicationId = "com.handlive.android"`, was `app.handlive.android`) | Release note | Android treats the new id as a different app: a phone with beta.3 does not update, it gets a second HandLive beside the old one, with its own pairing. The old install must be removed by hand (its pairings on the Mac stay until the user removes them). The `namespace` and every Kotlin package stay `app.handlive.android`; the Mac and iPhone are not affected. | **Written into the Android changelog and the hub's release notes** (this release). |
| I | android `app/build.gradle.kts:124-131` (`isMinifyEnabled`, `isShrinkResources`, `proguard-rules.pro`) | Release risk, not security | `v0.1.1` is the first APK built with R8. The keep rules cover kotlinx-serialization, Firebase registrars, Netty's reflective channel factories and loggers (the commit says the earlier rules failed at startup, so the obfuscated build was run), and `play-bundle` built the `gmsRelease` AAB green three times on `main`, but no CI job launches the `foss` release APK (release-apple has `launch`; release-android has not). | **Owner check after the release:** install `HandLive-0.1.1-android-foss.apk` on the S25 and run one clipboard push, one SMS and one call notification. |

## Checked and clean

- **Clipboard URI policy (android `ClipUriPolicy.kt`, `ClipImageCopier.kt`, `ClipReader.kt`; closes android #13, the
  low finding deferred at beta.3).** A clip URI is opened only when its scheme is `content`, the authority resolves to
  a provider (`resolveContentProvider`) and that provider lives in another package: `file`, `android.resource`, HandLive's
  own provider and unresolved authorities are refused before `getType`, `openInputStream`, `coerceToText` or
  `coerceToHtmlText` could touch them (`wouldOpenUri` decides whether the text path would open the URI; a refused URI
  returns only the `text` already on the item). The refusal is told as "Couldn't read the image" or the text failure
  and logged on debug builds as `clip_read_failed … why=uri_not_allowed authority=…` (authority only, never the path or
  the content). Image copy is still capped at `CLIP_MAX_IMAGE` + 1 byte with the file deleted on failure. Unit tests
  cover the scheme, the own-provider and the unresolved-provider cases (`ClipUriPolicyTest`, `ClipReaderTest`).
- **Play upload signing (android `app/build.gradle.kts`, `play-bundle.yml`).** Gradle signs `release` only when the
  four `HANDLIVE_UPLOAD_*` values are set and the keystore file exists (`ValueSource`, so the configuration cache
  fingerprints the file instead of reading it ad hoc); CI sets none of them, so `release-android` keeps building the
  unsigned `foss` APK and signing it with `apksigner` in its separate job, unchanged. `play-bundle` runs on demand from
  `main` only (`if: github.ref == 'refs/heads/main'`), in the environment `release` (deployment policy `main` and `v*`),
  with `contents: read`; it checks the seven secrets by name, decodes the keystore under `umask 077` into `RUNNER_TEMP`
  and verifies mode 600, runs Gradle with `--no-configuration-cache` so the passwords are not written to disk, verifies
  the AAB with `jarsigner` (`jar verified.` required, since an unsigned archive also exits 0), uploads only the AAB and
  `mapping.txt` (7 days), and removes the keystore in an `always()` step. No step prints a secret value;
  `persist-credentials: false` on every checkout. `HANDLIVE_REPOS_TOKEN || github.token` is the same pattern as the
  release workflows.
- **FCM secrets (hub `tools/release/setup-fcm.zsh`, `.gitignore`).** The script reads `google-services.json` locally
  and stores the four values as environment secrets through `gh secret set NAME < file` (stdin, never `--body`,
  never printed); `google-services.json` and `*-firebase-adminsdk-*.json` are git-ignored. History of all five
  repositories holds no `google-services.json`, keystore, `.p8` or `.p12`, and no `AIza…` key in code.
- **`play-release.zsh` (hub).** Lists secret names only, merges the Android PR and dispatches `play-bundle` with `gh`;
  no secret value in arguments or output. Runs on the owner's Mac only; ships in no app.
- **Apple identifiers (`iOS/*.entitlements`, `project.yml`, `KeychainSecretStore.swift`, `NotificationService.swift`).**
  App Group `group.app.hxd.handlive` is the keychain access group shared by the app and the extension (an App Group
  name is a valid keychain access group by itself, so the explicit `keychain-access-groups` entry for it is gone); the
  extension's bundle id is `app.handlive.ios.notifications`; the Communication Notifications entitlement stays on the
  app target only. The unsigned IPA is re-signed by the installer's own account, as before. A beta.3 iPhone install
  updated to this build loses its settings and keys and must pair again (changelog).
- **Welcome window (`WindowPresenter.swift`).** The delegate is now owned by the presenter; closing the window runs
  `windowWillClose` again, so the app returns to the menu bar. No security effect.
- **Xcode 27 settings (`project.yml`).** `ENABLE_USER_SCRIPT_SANDBOXING`, `DEAD_CODE_STRIPPING`, string catalogs:
  hardening or neutral; no target has a run-script phase. `xcodeVersion: "27.0"` only sets `LastUpgradeCheck`;
  `ci-apple` is green on `macos-26`.
- **Design-system catalog (`design_tokens_asset_catalog.py`).** Drops the package's duplicate `AccentColor`; the app
  catalogs keep theirs. Build-time only.
- **shared `tools/e2e/`, android `AppLanguageSettingTest.kt`, apple `ScreenshotUITests.swift`.** Test tooling, in no
  product build (the UI-test target is its own bundle; its seams are the low finding above).
- **relay.** README only; `cda13bf` is still the last code commit, as at beta.3.

## Unresolved questions

- Whether to open an apple issue for the `#if DEBUG` guard of the UI-test seams now or fold it into the next
  screenshot round (owner's call; the scan treats it as low).

Status: DONE
Summary: every change since `v0.1.0-beta.3` on the five repositories was read; 0 critical, 0 high, 0 medium, 1 low
(UI-test seams in the Release iOS build, deferred), 2 release notes (new Android application id, first R8 APK). The
`v0.1.1` tag may proceed.
Concerns/Blockers: none for the tag. The owner should launch the R8 `foss` APK on the S25 after the release.
