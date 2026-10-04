# Android clipboard HTML: review fixes (2026-10-05)

Repo `android`, branch `feat/clipboard-html` (base ce40c8c). Not pushed.

## Commits
- `ecae9de` fix(android): sanitizer: unclosed/bogus comments, stray tag start escaped, ASCII-only close-tag fold, hostile tests
- `ff776aa` fix(android): receiver writes text alone when sanitized html outgrows MAX_HTML_BYTES

## Changes
1. `HtmlPrePasses` (in `HtmlTagScanner.kt`): `stripComments` (unclosed `<!--` runs to end) then `stripBogusComments`
   (`<!…>`, `<?…>` up to next `>` or end), same order as `COMMENT_RE` then `BOGUS_RE`.
2. `HtmlTagScanner.appendText`: in every copied text segment (between tags and tail), `<` before `/` or an ASCII
   letter becomes `&lt;`; dropped content untouched. KDocs updated.
3. `closeEndAt`: manual ASCII-only case fold (`</ſcript>` and Kelvin sign no longer close `<script>`).
4. `ClipReceiver`: `sanitizedHtml` re-sanitizes `push.html`; over `MAX_HTML_BYTES` (UTF-8) means html = null, text
   written, ack applied.
5. Tests: vector test needs >= 41 cases (passes with all 41); hostile test added for the unclosed-quote and mXSS
   inputs (no `<img`, no `<script`, no `onerror=` inside a tag); long-run test now expects the leading `<` escaped;
   receiver test with `'`-quoted href of 92160 `"` (about 92 KB raw, about 550 KB after `&quot;`).

## Verification
- `:core:protocol:testDebugUnitTest :core:protocol:check :feature:clipboard:testDebugUnitTest
  :feature:clipboard:check :core:crypto:testDebugUnitTest`: rc 0 (detekt + ktlint clean).
- XML counts: core:protocol 58 tests, 0 failures (HtmlClipSanitizerVectorTest 5); feature:clipboard 127 tests, 0
  failures (ClipReceiveTest 16).
- `:app:assembleFossDebug` rc 0; APK copied to scratchpad as `app-foss-debug-html3.apk` (60.6 MB).

## Deviations
- Detekt limits (TooManyFunctions, ReturnCount, ComplexCondition) forced the pre-passes into a second internal
  object `HtmlPrePasses` in the same file, and `sanitizedHtml` into a private top-level function in `ClipReceiver.kt`.
  No new files.
- Perf note: a long run of `<a` without `>` is quadratic in the scanner (same as the reference regex); the receiver
  test uses the quote-growth case instead.

Status: DONE
Summary: Three sanitizer fixes and the receiver size guard are in; all 41 shared vectors pass byte for byte, checks are green, APK built.
Concerns/Blockers: none
