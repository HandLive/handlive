# Review: clipboard HTML on android + apple `feat/clipboard-html` (2026-10-05)

**Scope.** android `88488ca..18cbb80` (5 commits), apple `a882a2d..71c7324` (4 commits), judged against the plan §1–8,
04-clipboard CLIP-01 API 5 / QC10 and the reference `shared/tools/vectors/build_clipboard_html_vectors.py` at shared tip
`754bc03` (ASCII whitespace/digits/case-fold, 34 vectors). Read-only; no Gradle/xcodebuild. The reference was executed
on hostile inputs; JVM `regionMatches(ignoreCase)` was probed with `jshell`. Both repos moved during the review: the
ASCII-whitespace fixes (android `18cbb80`, apple `71c7324`) are already in and are treated as current.

## Critical

### C1. Reference hole: an unfinished `<tag` is copied verbatim and completes later in the consumer (contract §6, QC10)
Rule broken: "Output contains no `<script`, `javascript:`, or `on…=` attribute". The reference treats a `<`+letter that
never forms a complete tag (unbalanced quote, or no `>` reachable) as text and copies it as is
(`build_clipboard_html_vectors.py:77,79`). The next `>` in the output (typically the next kept tag) closes it in any
HTML parser. Both ports reproduce the reference faithfully: Kotlin `HtmlTagScanner.kt:94-112` (`tagEnd`/`pastQuote`
→ -1 → `parseTag` null → `HtmlClipSanitizer.kt:120` copies the slice), Swift `HtmlClipSanitizer.swift:128`
(`guard let quoteEnd … else { return nil }` → `:35` copies the slice). Reproducers (reference at `754bc03`):

| input | output |
|---|---|
| `<img src=x onerror=alert(1) "<p>a</p>` | `<img src=x onerror=alert(1) "<p>a</p>` |
| `<p><style><img src="</style><img src=x onerror=alert(1)//"></p>` (classic mXSS) | `<p><img src=x onerror=alert(1)//"></p>` |
| `<img onerror=alert(1) src=x alt="<!--"><p>a</p>--><p>b</p>` (comment eats the quote) | `<img onerror=alert(1) src=x alt="<p>b</p>` |
| `<script src=//e/x.js "<p>a</p>` | `<script src=//e/x.js "<p>a</p>` |

Neither hostile test probes it (`HtmlClipSanitizerVectorTest.kt:31`, `HtmlClipSanitizerVectorTests.swift:32`).
Fix (contract → reference → vectors → both ports, in that order): a `<` followed by `/`, `!`, `?` or an ASCII letter
that does not start a complete tag or comment is emitted as `&lt;`; §6 wording "a `<` that does not start a tag … is
text and stays" narrows to `<` followed by anything else (`a < b`, `<3` unchanged). Implement by escaping such `<` in
the text slices appended at `build_clipboard_html_vectors.py:77,79`, `HtmlClipSanitizer.kt:117,120`,
`HtmlClipSanitizer.swift:35,48`, and add the four rows above as vectors (plus `a <b` → `a &lt;b`). Lossy alternative:
drop from the broken `<` to the end of input. Separately, the Kotlin and Swift hostile tests should assert the four
inputs above once the rule lands.

## Important

### I1. Kotlin close-tag search case-folds beyond ASCII (byte divergence from the reference)
`HtmlTagScanner.kt:70` uses `regionMatches(…, ignoreCase = true)`; the JVM compares `toUpperCase`/`toLowerCase`, so
`</ſcript>` (U+017F) and `</Kbd>` (Kelvin sign U+212A) match (`jshell`: both `true`). The reference is now
`re.I | re.A` (ASCII fold) and Swift folds with `$0 | 0x20` on ASCII letters only. Repro: `<script>x</ſcript><p>k</p>`
→ reference and Swift `""`, Kotlin `<p>k</p>`. Not a hole (the script body is gone either way) but violates "byte for
byte". Fix: compare chars with an ASCII fold (`if (c in 'A'..'Z') c + 32 else c`) instead of `regionMatches(ignoreCase)`;
add the vector.

### I2. Receiver measures `CLIP_MAX_HTML` on the wire field; re-sanitizing can grow it 6×
`PushValidator.kt:98` and `ClipboardEngine+Receiving.swift:172` check the raw `html` (correct per §2), then
`ClipReceiver.kt:79` / `ClipboardEngine+Receiving.swift:108` re-sanitize and write the result unchecked. `"` → `&quot;`
grows a value sixfold: a 180 KiB `alt='"""…'` becomes ~1.08 MB of HTML on the pasteboard; on Android a ~1 MB `ClipData`
hits the binder limit → `TransactionTooLargeException` → `ack INTERNAL` for a push that passed validation. §6 says the
limit "is measured on the output". Fix: after re-sanitizing, write the text alone (html dropped) when the output exceeds
`MAX_HTML_BYTES` / `maxHtmlBytes`; one test per platform.

## Minor

- M1. Android: hold → Send Anyway and Send Again keep `html` (`LocalClipIntake.kt:157-171` stores the
  `ClipContent.Text(text, html)`; `Clip.resend` reuses `content`) but nothing pins it; Apple has `sendAnywayKeepsHtml`.
  Add the twin in `LocalClipSendTest`.
- M2. `HtmlClipSanitizerVectorTests.swift:27` compares with Swift `String ==` (canonical equivalence), not bytes; the
  sanitizer never normalizes, so it holds today. Compare `Array(….utf8)` to match the "byte for byte" claim.
- M3. `Tools/HandLiveDevClient/…/MemoryPasteboard.swift:35` implements only the text-only `write`; through the
  default extension the dev client silently drops `html`. Acceptable for a tool; say so in a one-line comment.
- M4. Bench `html=1` on `clip_read`/`clip_received` (§7) is untested on both platforms. Optional.
- M5. Stale wording: `HtmlClipSanitizer.kt:3-12` and the Swift header still describe the `<`-as-text fallback that C1
  changes; update with the fix.

## Verified against the contract (no finding)

- **Sanitizer equivalence** (reference semantics, not an ideal): quoted `>` inside values, `/` before `>`, uppercase
  names, valueless attributes, duplicates (first *valid* wins on all three: `href="javascript:x" href="https://ok"` →
  `https://ok`), `java\tscript:` and `java&#115;cript:` (prefix allow-list → attribute dropped, `<a>` stays), `a=b"c"`,
  `a==b`, `a=` at the end, `<scr<script>ipt>`, NBSP between name and attribute (new vector), unclosed comment stays,
  nested comment opener, `img` without kept `src` dropped whole, `</br>` dropped, escaping order. Kotlin `ATTR` regex
  `[^"]*` loops are iterative (200k-char run test). ASCII whitespace/digits now match on both ports (android `18cbb80`,
  apple `71c7324`, `trimSpace` boundaries correct); the four new vectors should pass by inspection.
- **Receiver**: BAD_REQUEST for html with image kind, with transfer, over 180 KiB UTF-8, and (Android) ill-formed
  UTF-16, checked in the shape step before FEATURE_DISABLED on both (`PushValidator.check`, `validate`); html
  re-sanitized before every write; empty-after-sanitize → nil at all five sites (Android reader/receiver, Mac reader,
  Mac/iOS receiver, iOS paste); identity text-only (`ClipContent.Text.bytes`, `ClipContent.text(text).sha256`;
  Swift test asserts it); a push without `html` is untouched by the new branches.
- **Sender**: html only when the peer's `mimes` lists `text/html` (`ClipSender.acceptsHtml` per `attempt`, so QC6
  forwarding gates per peer — `anHtmlPushIsSanitizedAgainWrittenWithItAndForwardedPerPeer`,
  `forwardingDropsHtmlForAPeerWithoutTextHtml`; Swift `inlinePush(_:to:)`); dropped over `CLIP_MAX_HTML`
  (`ClipWire.kt`, Swift `send`) and when the inline push would exceed `CLIP_INLINE_MAX` (retry without html, both);
  chunked text never carries it (`chunkedPush` leaves `html` null; Swift `transfer == nil && includeHtml`).
- **Capability**: `["text/plain","text/html",…]` and `["text/plain","text/html"]` with images off on both; schema
  `mimes` items are a pattern, not an enum, so the shape is unchanged; `clipboard-push.schema.json` `if/then` matches §2.
- **Platform write/read**: Android `ClipData.newHtmlText(LABEL, text, html)` and `item.htmlText` (Robolectric tests);
  Mac `public.html` beside `.string` in the one `NSPasteboardItem`, read from the first item only
  (`MacPasteboard.types/string` use `pasteboardItems?.first`); iOS `UTType.html` in the same item dictionary;
  `PastedContent` loads `UTType.html` only for text. No iOS Share extension exists (only `NotificationService`), so
  "Share target stays text only" is moot. `ClipboardAccess` has both `write` requirements, `access: any ClipboardAccess`
  dispatches through the witness table; MacPasteboard, IOSPasteboard, FakePasteboard implement both.
- **Tests assert behaviour**: Android PushValidator (accept + 4 rejects), receive (sanitized write, forward keep/drop,
  3× BAD_REQUEST with no write), send (gating, two drop rules, chunked), reader, system clipboard, 30+ vectors +
  idempotence + long runs; Apple send (gating + identity, 3 size rules, Send Anyway), receive (write + 3× BAD_REQUEST),
  rules (read, empty → nil), iOS paste + copy-again, PastedContent, capability, message round-trip.
- **Lint refactors**: `FakePasteboard` moved verbatim (+ `html` field, `copy(text:html:)`); Kotlin scanner split keeps
  the control flow (`parseTag` → `tagEnd`/`pastQuote`, unclosed quote → null exactly as before).

## Recommended order
1. C1: decide the `&lt;` rule, change plan §6 + QC10, reference, vectors; then Kotlin/Swift + hostile tests.
2. I1 (Kotlin ASCII fold) and I2 (post-sanitize size) with one vector / one test each.
3. Rerun `:core:protocol` and HLProtocol vector tests against shared `754bc03` (34 vectors) before merge; M1–M5.

Status: DONE_WITH_CONCERNS
Summary: Both ports implement the contract and match the reference closely (capability, gating, validation, identity,
writes/reads, tests all verified), but the reference itself leaks `on*=`/`<script` through unfinished tags and both
ports inherit it; Kotlin's close-tag fold and the receivers' post-sanitize size are the two remaining divergences.
Concerns/Blockers: C1 needs a contract decision before code; I1/I2 are small; ports must be re-tested against the 34
vectors at shared `754bc03` (the ASCII fixes landed mid-review and were reviewed by inspection only).
