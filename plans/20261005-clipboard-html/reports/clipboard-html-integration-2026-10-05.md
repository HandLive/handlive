# Clipboard HTML: integration, review, e2e and device installs (2026-10-05, 04:00–05:00)

Owner ask (04:04): "làm luôn tính năng clip HTML đi" after whole-article copies pasted as plain text on the Mac. Contract first:
`plan.md` of this folder, then the spec (hub `cff2b75`, `99f6079`, `61fc00b`), then three repos in parallel.

## What landed (per repo)
| Repo | Branch / PR | Commits | Report |
|------|-------------|---------|--------|
| shared | `feat/clipboard-html` → PR #4 **merged** | `1172cae` reference sanitizer + vectors; `03a8294`…`e63c63a` schema, samples, fake Mac, verifier, e2e steps, READMEs; `754bc03` ASCII whitespace/digits (+4 vectors); `dd29e7b` hardened reference (+7 vectors, 41 in all) | `shared-clipboard-html-2026-10-05.md` |
| android | `feat/clipboard-html` → PR #5 | `16d8c1e`…`11f6d2d` feature; `18cbb80` ASCII whitespace; `ce40c8c` vector coverage test; `ecae9de` sanitizer review fixes; `ff776aa` receiver size guard | `android-clipboard-html-2026-10-05.md`, `android-clipboard-html-review-fixes-2026-10-05.md` |
| apple | `feat/clipboard-html` → PR #3 | `ec2108b`…`a110a73` feature; `71c7324` ASCII trim; `3432667` lint; `c789e0e` sanitizer review fixes; `d9b60c9` receiver size guard; `99d515c` attribute scanner in its own file | `apple-clipboard-html-2026-10-05.md`, `apple-clipboard-html-review-fixes-2026-10-05.md` |
| hub | `feat/clipboard-html` | `0f18b30` plan; `9b486ca` roadmap/changelog/handoff; `cff2b75` spec API 5 html; `99f6079` ASCII + mailto; `61fc00b` hardened sanitizer rules; `63d7bea` iPhone background note | this file |

## Contract decisions taken during integration
- Both ports flagged `str.isdigit()` / `\s` (Unicode) in the Python reference → reference tightened to ASCII (`re.A`, explicit strip set, `0-9`), spec QC10 and plan §6 say so; Kotlin `isSpace`/`SPACE_CLASS` and Swift `trimSpace` changed to match. Spec QC10 also lacked `mailto` for `href` (plan and vectors had it) → fixed.
- Review C1 (Critical, in the reference itself): a `<` + letter that never completes a tag (quote left open, no `>`) was copied as text; the parser rendering the result closes it at the next `>` → `onerror=` / `<script` smuggled (`<img src=x onerror=alert(1) "<p>a</p>`, classic mXSS via `<style>`). Fix in contract + reference + both ports: such a `<` is emitted `&lt;`; `<!…>`/`<?…>` dropped as bogus comments up to the next `>`; an unclosed `<!--` runs to the end; close tags fold case on ASCII only (I1: Kotlin `regionMatches(ignoreCase)` matched `</ſcript>`). 7 vectors pin it.
- Review I2: receivers measured `CLIP_MAX_HTML` on the raw field, re-sanitizing can grow it ~6× (`"` → `&quot;`) → both receivers now write the text alone when the sanitized html exceeds the limit (plan §2, spec CLIP-02 logic 8); unit tests on both.
- Minor review items done: Swift vector test compares bytes; Swift file split instead of a lint exemption. Left: Android test for hold → Send Anyway keeping html; dev client `MemoryPasteboard` drops html through the default extension; bench `html=1` untested.

## Checks
- Vectors: `generate_vectors.py --check` 22 files 0 drift; `verify_vectors.py` 1676 checks 0 errors (clipboard-html.json 41 cases, idempotence); Kotlin and Swift vector tests byte-exact on all 41.
- Unit: android `core:protocol` 58, `feature:clipboard` 127, `feature:connection` 44, `core:crypto` coverage test; detekt + ktlint clean. Apple `HLTests-html` 209 ✔ / 0 ✘ after the fixes (302 across four packages before); `swiftlint --strict` 0.
- e2e `setup clipboard`, API 35 emulator, final APK `app-foss-debug-html3.apk`: setup 27 PASS + 1 INFO; clipboard 21 PASS, 1 SKIP (Accessibility auto path, as always), 0 FAIL. Mac → phone text with html applied in 188 ms; phone → Mac returns the sanitized html with the text unchanged; html + transfer and html on an image → `BAD_REQUEST`. (Same result with the intermediate APK: 48 PASS.)
- Branch CI: hub green; shared red once (`e2e/self_test.py` loopback TLS EOF flake) → rerun green; android red once (`VectorFileCoverageTest`: new vector file unregistered → `ce40c8c`) then green; apple red twice (SwiftLint `optional_data_string_conversion` in my `trimSpace` → `3432667`; `CallLogEngineTests` badge timing flake → rerun green).
- Harness note: the earlier e2e invocation launched through the background runner silently kept running while a second one started; both were killed, the emulator died with them and was restarted (`hl-claude-api35`, port 5580). Run e2e detached with `nohup … python -u` and poll the log.

## Devices (owner ask "xong thì cài lại cho mac và s25 luôn")
- S25 `R5GL320PPZT`: `adb install -r app-foss-debug-html3.apk` at 04:51:59 (debuggable foss APK, pairing kept).
- Mac: Debug `app.handlive.mac.localtest` (team 3S93UPADXV, keychain-only entitlements) compiled 04:56 from apple `99d515c`, `/Applications/HandLive.app` replaced and relaunched (pid 2199). Both reconnect without re-pairing.
- Owner test: copy an article in Samsung Internet on the S25 → paste in Notes on the Mac; expect headings, links and pictures (remote `<img src="https://…">`; pictures load from the web, never embedded).

## Side finding: iPhone drops the link when HandLive leaves the foreground
By design (CONN-02 E3: `session/bye {shutdown}` on `.background`, immediate reconnect on `.active`), not a bug; the away-time path (relay + APNs alerts, CONN-04, SMS/calls only) is unconfigured (gate G2). Options for the owner in `plans/20260925-implementation/reports/ios-background-disconnect-2026-10-05.md` and CLAUDE.md "In progress" item 9.

## Unresolved questions
1. Owner live test (acceptance box 4): Samsung Internet → Notes with pictures.
2. iPhone background behaviour: pick (a) ~25 s `beginBackgroundTask` grace + instant reconnect, (d) visible "paused" status, (c) wire relay + APNs (G2 inputs), or keep as designed.
3. `apple/iOS/Info.plist`: uncommitted deletion of `NSLocalNetworkUsageDescription` still in the working tree (not staged anywhere).
4. e2e sample HTML is already in sanitized form, so the phone-side re-sanitize is proven by unit tests, only weakly by e2e.
5. Sanitizer worst case is quadratic on adversarial input (many unclosed quotes / `<a` runs), bounded by `CLIP_MAX_HTML` on the receiver; acceptable for 180 KiB, noted.

Status: DONE_WITH_CONCERNS
Summary: Clipboard HTML implemented across shared/android/apple with a hardened shared sanitizer (41 vectors), reviewed, e2e green with the final APK, both owner devices reinstalled; shared merged, android/apple/hub PRs shipping.
Concerns/Blockers: owner live test pending; iPhone background behaviour needs an owner decision.
