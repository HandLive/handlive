# Android clipboard HTML (2026-10-05)

Repo handlive-android, branch `feat/clipboard-html` from `main` `88488ca`. Not pushed, no PR.

## Commits (handlive-android)
- `16d8c1e` feat(android): HtmlClipSanitizer and the html field of clipboard/push (also capability `text/html`, samples, tests)
- `843176d` refactor(android): split the HTML tag scanner from the sanitizer (detekt)
- `97c3c42` feat(android): read, send and write the HTML of a text clip
- `11f6d2d` test(android): HTML of a text clip across read, send, receive and write

## What changed
- `core/protocol`: `ClipboardPushData.html`, `ClipboardValues.MIME_HTML`; `HtmlClipSanitizer` (+ `sanitizeOrNull`) and internal `HtmlTagScanner` (hand-written tag/comment/close-tag scanner, no regex over tags: a JVM regex over a 180 KiB attribute run overflows the stack). Tests: `HtmlClipSanitizerVectorTest` (30 vector cases equal byte for byte, idempotence, no script/javascript:/on*, 200k-char attribute runs), push round trip with `html`.
- `feature/connection`: `LocalCapabilityBuilder` TEXT_MIMES/ALL_MIMES list `text/html` after `text/plain`; builder tests and `CapabilitySamples` updated.
- `feature/clipboard`:
  - `ClipLimits.MAX_HTML_BYTES` (180 KiB); `ClipContent.Text(text, html)` (identity from text only); `LocalRead.Text.html`.
  - `ClipReader`: item with `htmlText` -> sanitized html beside coerced text; Share target unchanged (text only).
  - `ClipWire.inlineOrNull(clip, withHtml)`: html only when peer lists `text/html`, <= CLIP_MAX_HTML, plaintext within CLIP_INLINE_MAX, else retry without; chunked pushes never carry html. `ClipSender` passes `withHtml` per target from peer `mimes`, so forwarding keeps html for peers with `text/html` and drops it for others.
  - `PushValidator`: `BAD_REQUEST` for html with kind image, with transfer, > CLIP_MAX_HTML UTF-8 bytes, or ill-formed UTF-16.
  - `ClipReceiver`: re-sanitizes `push.html` before apply; `writeText(..., html)`; `clip_received` bench line gets `html=1` only with html. `LocalClipIntake`: `clip_read` gets `html=1` only for clips with html.
  - `SystemClipboard.writeText(..., html: String? = null)`: `ClipData.newHtmlText` when html, else `newPlainText`.
  - Tests: ClipReaderTest, SystemClipboardTest (Robolectric, item `htmlText`), LocalClipSendTest (4 new), ClipReceiveTest (3 new), PushValidatorTest (2 new), ClipboardTestKit (`HTML_MIMES`, `FakeWriter` records html, `readText(html=)`).

## Gradle (JAVA_HOME openjdk@21, ANDROID_HOME set, `--offline`)
- `:core:protocol:testDebugUnitTest :feature:clipboard:testDebugUnitTest :feature:connection:testDebugUnitTest :feature:clipboard:check :core:protocol:check :feature:connection:detekt :feature:connection:ktlintCheck :app:assembleFossDebug` -> BUILD SUCCESSFUL.
- Test counts: core/protocol 57, feature/clipboard 126, feature/connection 44; 0 failures. detekt and ktlint clean (ktlintFormat used for layout).
- APK: `/private/tmp/claude-501/-Users-hxd-HandLive--claude-worktrees-check-progress-image-copy-debug-906617/f5772b97-6162-478d-ad43-4e6cdd573124/scratchpad/app-foss-debug-html.apk`

## Deviations from the contract
- None to the wire or limits. Two small points of interpretation:
  - `width/height/colspan/rowspan` "digits only" is ASCII `0-9` in Kotlin; the Python reference uses `str.isdigit()`, which also accepts non-ASCII digits (e.g. `²`, Arabic-Indic). Vectors do not cover it; Swift should pick the same as one of the two (suggest the reference be tightened to ASCII).
  - A sanitized html that ends up empty is treated as no html (not written, not sent).
- Same Python-vs-Kotlin whitespace note: whitespace for `strip`/`\s` follows Python (includes U+001C-U+001F, U+0085, U+00A0, Unicode spaces).
- Tag-scan worst case is quadratic on adversarial input with many unclosed quotes (same as the reference); bounded by the 180 KiB receiver check.

Status: DONE
Summary: Clipboard HTML implemented on Android (sanitizer matching all 30 vectors, capability, read, send with per-peer gating, receive validation and re-sanitizing, newHtmlText write, bench); all listed Gradle tasks green, APK copied.
Concerns/Blockers: ASCII-digit vs Python isdigit divergence for exotic digits (see above); decide in the reference/Swift.
