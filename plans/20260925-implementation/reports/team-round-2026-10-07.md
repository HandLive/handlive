# Team round: Apple clipboard tests, app-call e2e, Liquid Glass icon (2026-10-07)

Owner question (2026-10-05 23:17): "what is left to build?". The team (lead; Phong, Android; Vy, Apple; Mai, Apple
and brand; reviewers Huy / Linh (BA), Trang / Nam (Tester), Khoa / Quân (Pentester)) listed the work that needs no
hardware and no owner decision. The owner answered "tiếp tục đi" (go on) without picking the open options, so the lead
took the safe defaults: push + PR with the owner merging (rule of 2026-10-05), stacked PRs for work on unmerged
branches, the old OS keeps the compact-mark icon, an app call ended `unknown` keeps `answered_at = null`.

## Outcome

| Item | What changed | PR | Review |
|------|--------------|----|--------|
| Apple clipboard tests | Test-only. The harness reads the engine's in-flight push (`sending`, via `@testable`) and `pushSettled()` waits until it settles (ack handled, suspended, told, or ended without an ack; 2 s cap). 11 `Task.sleep` removed from `ClipboardIOSTests` and `ClipboardSendTests`. CI stays serial. | apple #6 | BA, Tester, Pentester approve; 2 low fixed (helper name, whole-suite evidence) |
| App-call e2e | `android/tools/fake-call-app`: a debug-only Gradle project (not in `settings.gradle.kts`, the product APK or CI) that posts a `CallStyle` ringing call, an in-call notification and an upload with Cancel. `shared/tools/e2e` scenario `app_calls` with the fake Mac: label is the launcher label, decline reaches the app, a swiped in-call notification keeps the call `ongoing` with End hidden, the upload never re-attaches the call nor gets its Cancel sent, the app's hang-up ends it `ended`, leaving communication mode ends a detached call `unknown`. Bench self-test: two Macs, a resent tap-to-answer. | android #9 (base #8), shared #7 (base #6) | BA, Tester, Pentester approve; 1 low (stale logcat on API 29) sent back |
| Liquid Glass icon | `tools/brand/icon_composer_writer.py` writes `AppIcon.icon` (`icon.json` + 4 SVG layers, light/dark/tinted) from the brand geometry; `build_brand_assets.py --apple-icon --icon-preview`. iPhone/iPad use it (iOS 26+; iOS 16–18 get the flat 1024 Xcode derives). The Mac keeps `AppIcon.appiconset` with the compact mark at 16/32 pt. | apple #7, hub #17 | BA, Tester, Pentester approve; 6 low fixed |
| `<queries>` wording | Spec CALL-05 `app.label`, `PackageAppLabels` KDoc, the manifest comment and the 2026-10-05 changelog/report now say what was measured. | hub #15, android #8, hub #16 | BA checked the wording |

### Measurements

Apple, local, Xcode 27.0, whole `HLAppCoreTests` in parallel ×100 (same command on both):

| Test | `main` `3f8c4cd` | apple #6 |
|------|------------------|----------|
| `ClipboardIOSTests/sendPastedWithHtml` | 100 fail | 0 |
| `ClipboardSendTests/replayWindow` | 20 | 0 |
| `ClipboardSendTests/ackErrors` | 13 | 0 |

The three call tests still fail on this branch (34 / 34 / 50) because their fix is apple #5, not merged yet. Tester
rerun of the two clipboard suites ×50 in parallel: 1050/1050.

e2e (emulator, Phong's runs, logs in shared #7): API 35 19/19 PASS; API 29 12 PASS + 1 SKIP (swiping an ongoing
notification exists from API 34).

## Findings worth keeping

- **Notification listener visibility.** On an Android 15 emulator `dumpsys package queries` shows the fake app becoming
  visible to HandLive once it posts a notification, and a mutant APK without the launcher `<queries>` still reads the
  label "E2E Caller". The 2026-10-05 claim that the listener has no implicit visibility came from the docs' silence;
  the package-name label on the S25 was inferred in review, never seen. The query stays (harmless, not restricted by
  Play) as a safeguard for Android 11–14 and OEM builds, which are not measured.
- **Clipboard flakiness was ordering, not time.** `sendPastedWithHtml` passed alone and failed every time with its
  suite in parallel: it received a push while its own clip was unacknowledged, and QC8 ignored it as a conflict.
- **Xcode 27 and `.icon`.** With `AppIcon.icon` and `AppIcon.appiconset` of the same name, `actool` derives every older
  size from the `.icon` and ignores the set (`assetutil --info`, byte-identical `.icns`);
  `--enable-icon-stack-fallback-generation disabled` has no effect. Hence the Mac stays on the set.
- **Apple bench lines on CI.** `phase-03-app-calls-review.md` said the Apple bench tests that read the unified log were
  not proven on the CI runner; CI run `37297615615` ran them (`AppCallCommandTests`, `AppCallRoutingTests`) green.

## Not done

- Won't do: a separate `reason` for app calls resent after a setting change; the bench already times one send per
  change.
- Deferred to a VPS: the two-instance relay load test (routing between instances already has a functional test).
- After apple #5 merges: `ManualClock` review debt (cancellation-aware `waitForSleepers`, helper names).

## Unresolved questions

- Owner: should the Mac move to Liquid Glass now (drops the compact mark at 16/32 pt)?
- Owner: should an app call ended `unknown` keep `answered_at` (duration on the Mac)? Today `null`, like E10.
- Not measured: whether Android 11–14 hide the calling app from the listener without the launcher query.

Status: DONE_WITH_CONCERNS
Summary: Three tasks reviewed by BA, Tester and Pentester; PRs apple #6, apple #7 + hub #17, android #9 + shared #7
(stacked) open for the owner, plus wording fixes on #8, #15 and #16.
Concerns/Blockers: the S25 checks of 2026-10-05 still wait for the owner's merges.
