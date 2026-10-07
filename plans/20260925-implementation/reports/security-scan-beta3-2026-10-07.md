# Security scan before v0.1.0-beta.3 (2026-10-07)

Owner request: "em hãy merge rồi release beta luôn đi" (merge, then release the next beta). This scan gates the
`v0.1.0-beta.3` tag: no critical or high finding may stay open.

## Scope

`git diff v0.1.0-beta.2..origin/main` per repository, same method as the beta.2 scan
(`security-scan-beta2-2026-10-04.md`): threat model first, then the changed non-test code, with the vbsec rule names.
Read only; no product code changed by this scan.

| Repo | `main` | Commits since beta.2 | Files | Scanned by |
|------|--------|----------------------|-------|------------|
| hub | `7a9f81d` | 111 | 73 (docs, plans, `release-collect.yml`, `tools/brand/`, `website/`) | Khoa |
| android | `a93b81b` | 50 | 85 (clipboard HTML, clipboard images, app calls, restricted settings, `tools/fake-call-app`) | Khoa |
| shared | `1fb2b06` | 38 | 34 (clipboard HTML schema and vectors, bench, e2e) | Khoa |
| relay | `cda13bf` | 0 | 0 (tag `v0.1.0-beta.2` points at `cda13bf`; no diff) | Khoa |
| apple | `ad8e672` | 43 | 92 | Quân (section below) |

Focus areas from the task: the notification listener and app calls (detached calls, `<queries>`), the clipboard HTML
sanitizer, restricted settings, iOS grace and notifications, bench/e2e tools (`fake-call-app` kept out of the
product), CI/release workflows (`macos-26`, environment `release`), the brand script.

Verdict, all five repositories: 0 critical, 0 high, **1 medium (fix before the tag)**, 2 low (one deferred, one fixed
the same day). The tag waits until the medium fix is merged on the shared reference, Apple and Android with its review;
then the scan is PASS.

## Findings

| Sev | Where | Rule | Issue | Outcome |
|-----|-------|------|-------|---------|
| M | apple `Packages/HLProtocol/Sources/HLProtocol/HtmlClipSanitizer.swift:133-163`; android `core/protocol/.../clipboard/HtmlTagScanner.kt:43-123` (`nextTag`, `parseTag`, `tagEnd`, `pastQuote`) | DOS / ALGORITHMIC-COMPLEXITY | The clipboard HTML sanitizer, new since beta.2, is quadratic: from every `<` + letter the tag scan runs to the next `>` (or, inside a quoted value, to the closing quote), and when it fails the next `<` is tried from scratch. Two inputs, measured on copies of the `main` code (no repo change). Apple (Quân, `swiftc -O`), `"<a"` repeated: 20 KB 0.09 s, 40 KB 1.41 s, 80 KB 5.20 s. Android (Khoa, JVM, Kotlin 2.2.21), `"<a"` repeated: 20 KiB 0.12 s, 40 KiB 0.49 s, 80 KiB 1.92 s, 160 KiB 10.25 s. Second pattern, `"<a\"x\""` repeated + `"'>"` (a `>` exists, the last quote never closes): 40 Ki chars 0.34 s, 80 Ki 1.71 s, 160 Ki 6.12 s. A web page sets any `text/html` on copy (`clipboardData.setData`), and the local read paths sanitize the raw HTML with no size cap (Mac `LocalClipReader.swift:61`, iOS `PastedContent.swift:43`, Android `ClipReader.kt` with `htmlText`; the 180 KiB `CLIP_MAX_HTML` caps only the output). Apple runs it on `@MainActor`, so the app freezes. Android runs it on `Dispatchers.IO`, but the transparent `ClipboardReadActivity` stays on top until the read returns (`ClipboardReadActivity.kt:75`), and its no-focus timeout was already cancelled (`:68`). The receive path is capped at 180 KiB (a paired peer only): about 25 s on Apple. | **Fix before the tag** (lead decision `msg_a6df573ce744`; Tuấn shared reference, Vy Apple, Phong Android). Output must stay byte-identical (shared vectors). The decided guard, "no `>` after this point → the rest is text", fixes the first pattern only. The second pattern needs memoizing scan failures by position: every position outside quotes that a failed `tagEnd` passed also fails later, so a later scan stops when it reaches one, which keeps the total linear. Performance test with both patterns (~1 MiB, < 1 s) on every port, plus a shared vector for each. Follow-up (spec change, CLIP-01): cap the raw HTML before sanitizing on the local read paths. |
| L | android `feature/clipboard/.../system/ClipReader.kt` | Confused deputy (URI read) | The clipboard read opens a clip's URI without restricting its scheme or provider, so a local app able to write the clipboard can make HandLive read data it should not. Details are kept out of this public report until the fix ships. | **Deferred** (not a blocker): present since beta.1, needs a malicious app already on the phone, data at rest is mostly ciphertext under Android Keystore keys. Fix in the next round: restrict the schemes and providers HandLive reads, with tests. Tracked: HandLive/handlive-android#13. |
| L | GitHub settings of handlive-apple, environment `release` | BROKEN-ACCESS-CONTROL (CI) | `release-apple.yml:71` says only tags `v*` and `main` may use environment `release`, but the environment has no deployment branch policy (`deployment_branch_policy: null`, no protection rule): a workflow on any branch could reach its secrets. handlive-android's `release` has the policy (`main`, `v*`). | **Fixed 2026-10-07** before the tag: the lead set the deployment policy through the API (custom: branch `main`, tag `v*`), as on handlive-android; the environment held 0 secrets meanwhile. |

## Checked and clean

- **Clipboard HTML (android `HtmlClipSanitizer.kt`, `HtmlTagScanner.kt`; shared `clipboard-html.json`).** Allowlist
  of tags and attributes; `href` keeps `http`/`https`/`mailto`, `img src` keeps `http`/`https` (an allowlist, so entity
  or control-character tricks such as `javascript&#58;` are dropped); attribute values escape `"`, `<`, `>`. The comment
  passes run before the tag scanner, so a tag rebuilt by stripping (`<<!x>script>`) still meets the allowlist
  (`script` is dropped with its content). Text keeps no `<` followed by `/` or a letter. The receiver sanitizes again
  before writing (`ClipReceiver.kt`, `sanitizedHtml`) and caps the result at `CLIP_MAX_HTML`; `PushValidator` refuses
  `html` outside an inline text clip or over the limit. The shared schema has no `maxLength` for `html`: the limit is
  enforced in code on both ends (documentation note only). Its running time is the medium finding above. The shared
  Python reference (`tools/vectors/build_clipboard_html_vectors.py`) only generates the vectors on a developer machine
  and ships in no app.
- **Clipboard images.** The image now wins over the text beside it (owner bug fix); copy is capped at
  `CLIP_MAX_IMAGE` + 1 byte and the file deleted on failure. The new `clip_read_failed` lines log MIME types, part
  names and the provider authority, never content or paths, and `BenchLog` only writes on a debuggable build
  (`FLAG_DEBUGGABLE`).
- **App calls (CALL-05).** `<queries>` adds only the `MAIN`/`LAUNCHER` intent; no code lists packages
  (`queryIntentServices` is the existing InCallService lookup), no `QUERY_ALL_PACKAGES`, labels are not logged. A
  swiped in-call notification detaches the call with `end = null`: an `end` from the Mac gets
  `CALL_APP_ACTION_UNAVAILABLE` (`AppCallActions.kt:63`) and only a later in-call-shaped notification of the same
  package (`sbn.packageName`, set by the system) re-attaches it, so an upload's single Cancel action is never sent
  (test `anUploadOfTheAppAfterTheSwipeNeverBringsEndBackNorHasItsCancelSent`). The audio-mode listener lives on the
  application context and is removed when no call is detached. Direct answering now needs Android to vouch for the
  call (`AppNotificationReader.vouchedFor`): API 34+ a foreground-service or user-initiated-job flag or a granted
  full-screen intent, API 31–33 the platform `CallStyle`, below 31 never (answer by tapping the phone). This closes the
  beta.2 open question on app-call answering.
- **Restricted settings (android `RestrictedSettings.kt`, `PhoneEnvironment.kt`, `SpecialAccessTrip.kt`).** Reads
  the app's own install source and opens system settings pages; no new exported component, no app-op probing.
  `android:largeHeap` (PIN pairing on small heaps) has no security effect.
- **`tools/fake-call-app` (android) and e2e tools (shared).** A separate Gradle build that the product's
  `settings.gradle.kts`, `app/` and CI do not reference; debug only, no keystore. Its PendingIntents are explicit and
  `FLAG_IMMUTABLE`; the service is not exported; the exported launcher activity accepts five fixed commands on a fake
  call. `adb_device.run` uses `subprocess.run` with an argument list; strings sent to `adb shell` are constants and
  integer coordinates. The fake caller is "E2E Test Caller", no phone number.
- **Bench (shared `bench_log.py`, `app_call_latency.py`).** Offline parser of the developer's own logs: no `eval`,
  `pickle` or shell; clock fields that are not finite numbers drop the line; output has ids and timings only.
- **Hub `release-collect.yml`.** Only `contents: write` on its job, `contents: read` by default, no third-party
  action. `inputs.tag` reaches the scripts through `env`, not `${{ }}` inside `run`, and must match
  `^v[0-9]+\.[0-9]+\.[0-9]+(-[0-9A-Za-z.]+)?$`. Each file needs its `.sha256` and passes `sha256sum --check
  --strict`. The checksums come from the same platform Release as the files, so they catch a broken copy, not a
  tampered platform Release; the platform Releases are written only by the signing workflows (signing secrets in
  environment `release`, tags `v*` and `main` only).
- **Hub `website/`.** All four images pinned to digests (closes the beta.2 low); content changes are the release link
  and badge.
- **Hub `tools/brand/`.** Local scripts calling `rsvg-convert`, `magick` and `ictool` with argument lists; writes only
  under the brand output directory.
- **Secrets and identities.** No `.jks`, `.p8`, `.p12`, `.keystore`, `.pem` or `.env` file added; the added lines
  match no private-key, GitHub, AWS, Google or Slack token pattern. Commit identities on `main` were checked in task
  (D): `Hồ Xuân Dũng <me@hxd.vn>`, plus the owner's GitHub account on merge commits.

## beta.2 open items

| Item | State |
|------|-------|
| App-call answering (API 34+ vouching) | Done: `vouchedFor`, CALL-05 API 1 logic 6 |
| Split `release-apple` into sign / launch / publish | Done on `main`: `sign` (environment `release`, `macos-26`), `launch` (no environment, `permissions: {}`, `macos-15`), `publish` (environment `release`) |
| Erase both keychains | Merged (apple `baf6060`) |
| Website image digests | Done (2026-10-05) |
| `ANDROID_RELEASE_*` as environment `release` secrets | Done, checked through the GitHub API: no repository secret in handlive-android; the three secrets sit in environment `release`, whose deployment policy allows branch `main` and tag `v*` only |

## Apple (Quân)

`v0.1.0-beta.2..ad8e672`, 43 commits, 55 non-test files: 0 critical, 0 high, 1 medium (the sanitizer, in the table
above), 0 low. Checked and clean:

- **Sanitizer output (XSS).** Output is rebuilt from the tag and attribute allowlist with `"`, `<`, `>` escaped;
  `href` `http:`/`https:`/`mailto:`, `src` `http(s):`, values trimmed, so `javascript:` and entities do not pass; `<` +
  letter or `/` in text becomes `&lt;`; a leftover `<!`/`<?` only makes a comment. The receiver sanitizes again
  (`ClipboardEngine+Receiving.swift:107`). A remote `img src` loads when pasted into Mail: by design (CLIP-01), a
  privacy note, not a defect.
- **Pasteboard with HTML.** HTML sits in the same item as the text; Mac `.currentHostOnly` and the concealed type when
  `sensitive`; iOS `.localOnly` plus the expiry; an unchanged `changeCount` returns nil.
- **iOS background grace and local notifications.** Locked (`!isProtectedDataAvailable`): generic text only, no
  title, number, content or action. Unlocked: SMS content only with `sms.preview`, as in the NSE. `BenchLog` writes
  `call`/`msg` keys, `wait_ms` and `reason` only.
- **Call controllers, `CallActionSender`.** The injected clock comes from code in the same process (every caller uses
  the default); a resend keeps one envelope id, one deadline, no endless loop.
- **Keychain erase.** `deleteAllInEveryKeychain` also clears the login keychain with `SecKeychainItemDelete` (matched by
  HandLive's service); an ad hoc build that meets `errSecMissingEntitlement` skips it (residual risk recorded in the
  beta.2 scan). The query drops `kSecAttrAccessGroup`, so it erases more widely, which is safer for an erase.
- **`release-apple`.** `sign` (environment `release`, `contents: read`, secrets on the steps that need them, keychain
  removed `if: always()`), `launch` (`permissions: {}`, no environment, no secret, no checkout, `macos-15`), `publish`
  (ubuntu, environment `release`, `contents: write`, runs no built code, `sha256sum --strict` per file, no overwrite
  without `replace`). The dispatch `tag` goes through env `TAG` and a version regex, never `${{ }}` inside a script;
  checkout `persist-credentials: false`; actions pinned by SHA. `ci-apple` only moved to `runs-on: macos-26`. The
  environment's branch policy was the second low above, fixed before the tag.
- **`AppIcon.icon`.** SVGs hold only `<path>`, `icon.json` no path or URL, previews `-strip`ped.

## Unresolved questions

- None: the medium is fixed before the tag, the URI low is deferred to the next round (lead decision), the
  environment low is fixed.

Status: DONE_WITH_CONCERNS
Summary: 0 critical, 0 high, 1 medium (quadratic clipboard HTML sanitizer on Apple and Android, fixed before the tag
on all three implementations), 1 low deferred (clipboard URI read on Android, android#13), 1 low fixed (handlive-apple
environment `release` limited to `main` and `v*`).
Concerns/Blockers: tag `v0.1.0-beta.3` waits for the sanitizer fix (shared, Apple, Android) to be merged with its review.
