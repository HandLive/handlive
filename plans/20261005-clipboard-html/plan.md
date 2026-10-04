# Clipboard HTML: a text clip keeps its rich form (2026-10-05)

**Status:** in progress · **Route:** feature · **Ship mode:** beta · **Owner decision:** 2026-10-05 04:04 ("làm luôn tính năng clip HTML")
**Repos:** shared (schema, vectors, e2e) → android, apple in parallel → hub (spec en + vi, docs). Contract first: this file is the contract until the spec lands.

## Why

Copying an article (text with pictures) on the phone and pasting it in Notes or Word on the Mac gives plain text only: a text clip carries `text` alone (CLIP-01), the HTML a browser puts beside it is dropped (`coerceToText`). With the HTML on the Mac pasteboard, Notes, Pages, Word and Mail render the article and fetch its pictures from the `<img src>` URLs themselves — no image bytes travel.

## Contract (00-common-specs 0.7.2, 0.10; 04-clipboard CLIP-01, CLIP-02, CLIP-04)

1. **Capability.** `features.clipboard.mimes` may list `"text/html"`: this peer accepts the optional `html` field on a text push. Android, macOS, iOS and iPadOS all list it from this version on (`["text/plain", "text/html", "image/png", "image/jpeg"]` when images are on; `["text/plain", "text/html"]` when off). A sender adds `html` only when the peer lists `text/html`; older peers never see the field.
2. **`clipboard/push.data.html`** (string, optional): the sanitized HTML form of `text`, UTF-8. Allowed only when `kind = "text"` **and** `text` is inline (no `transfer`); the whole push plaintext must stay within `CLIP_INLINE_MAX` (180 KiB). New constant **`CLIP_MAX_HTML` = 180 KiB** (UTF-8 of `html` after sanitizing). Sender rule: sanitize, then drop `html` (send plain text as today) when the sanitized HTML exceeds `CLIP_MAX_HTML` or the push plaintext with it exceeds `CLIP_INLINE_MAX`, or when the text itself is chunked. Receiver rule (`BAD_REQUEST`): `html` with `kind = image`, with `transfer`, or longer than `CLIP_MAX_HTML`. The receiver sanitizes again before writing (defense in depth) and never trusts the sender's sanitizing; when the re-sanitized HTML exceeds `CLIP_MAX_HTML` (escaping can grow it), the text is written alone and the push still acks `applied`.
3. **Identity unchanged.** `clip_id`, SHA-256, loop guard (QC4), conflicts (QC8), de-duplication (QC6) and the sensitive-content checks (QC3) look at `text` only; `html` is an attachment of the clip. A clip forwarded by Android (QC6) keeps `html` for clients that list `text/html`, drops it for others.
4. **Writes.** Android: `ClipData.newHtmlText("HandLive", text, html)` instead of `newPlainText` when `html` is present (CLIP-02 API 3). macOS: the one pasteboard item gets `public.html` beside `public.utf8-plain-text` (CLIP-01 API 7). iPhone/iPad: `UTType.html` beside `UTType.utf8PlainText` in the same item (CLIP-04 API 1). The HTML written is the receiver-sanitized form.
5. **Reads.** Android (CLIP-01 API 2 logic 2): a text item whose `htmlText` is set sends both (sanitized). macOS (CLIP-02 API 1): when the first item also declares `public.html`, read it as a string and send it sanitized beside the text. iPhone/iPad (CLIP-04 API 3): the Paste button also loads the `public.html` representation when offered. The Share target stays text only.
6. **Sanitizer `HtmlClipSanitizer`** on every platform, the same algorithm, proven equal by the shared vectors `shared/test-vectors/clipboard-html.json` (input → output, both platforms must match byte for byte):
   - Comments `<!-- … -->` removed; an unclosed `<!--` runs to the end. `<!…>` (doctype, CDATA) and `<?…>` are HTML "bogus comments": dropped up to the next `>` (or the end). Tag and attribute names are case-insensitive on ASCII letters only (`</ſcript>` does not close `<script>`); output tags lowercase.
   - **Dropped with their content** (to the matching close tag, or to the end when unclosed): `script`, `style`, `iframe`, `object`, `embed`, `svg`, `math`, `template`, `noscript`, `head`, `title`, `textarea`, `select`, `button`, `form`, `input`, `video`, `audio`, `canvas`, `link`, `meta`, `base`, `applet`, `frame`, `frameset`.
   - **Kept** (tag and allowed attributes only): `a[href]`, `abbr`, `b`, `blockquote`, `br`, `caption`, `code`, `div`, `em`, `figcaption`, `figure`, `h1`–`h6`, `hr`, `i`, `img[src alt width height]`, `li`, `ol`, `p`, `pre`, `s`, `span`, `strong`, `sub`, `sup`, `table`, `tbody`, `td[colspan rowspan]`, `tfoot`, `th[colspan rowspan]`, `thead`, `tr`, `u`, `ul`.
   - Any other tag (`font`, `section`, `article`, `center`, `nav`, `header`, `footer`, `aside`, `main`, `small`, `big`, `mark`, `label`, …) is **unwrapped**: the tag goes, its content stays.
   - `href`: trimmed; kept only when the scheme is `http`, `https` or `mailto` (case-insensitive); otherwise the attribute goes (the `<a>` stays). `img src`: trimmed; kept only for `http`/`https`; an `img` without a kept `src` is dropped whole (no `<img>` is emitted). `width`, `height`, `colspan`, `rowspan`: digits only, else dropped. Whitespace (trimming, attribute separators) and digits are ASCII only, as in HTML and URL parsing: NBSP and other Unicode spaces stay part of a value, `²` is not a digit. Every other attribute (`style`, `class`, `id`, `on*`, `data-*`, `target`, `loading`, `srcset`, …) goes.
   - Attributes are re-serialized as ` name="value"` in the order `href` | `src alt width height` | `colspan rowspan`, the value with `"` as `&quot;` and `<` `>` as `&lt;` `&gt;`; other entities in values stay as written. Void tags `br`, `hr`, `img` are emitted `<br>`, `<hr>`, `<img …>`; their closing forms (`</br>`) are dropped. Text between tags is copied as is (entities untouched), except that a `<` followed by `/` or an ASCII letter that did not complete a tag (no `>`, or a quote left open) is emitted as `&lt;`, so the parser rendering the result cannot close it at a later `>`; any other `<` is text and stays.
   - Output must contain no `<script`, no `javascript:` and no `on…=` attribute; `CLIP_MAX_HTML` is measured on the output.
7. **Bench** (debug builds): `clip_read` and `clip_received` gain `html=1` when the clip carries HTML; nothing else.
8. **No new setting, no new UI string.** Sensitive clips (QC3 `sensitive = true`) send `html` too; the Mac marks the item concealed as today.

## Work split (one branch `feat/clipboard-html` per repo)

| Repo | Owner | Work |
|------|-------|------|
| shared | agent | `schemas/clipboard-push.schema.json` (`html` string, `maxLength` not expressible in bytes — document; `allOf` rule: `html` only with `kind = text` and `text`); examples in the spec round-trip; `vectors/clipboard-html.json` committed by the controller, wired into `generate_vectors.py --check` (a builder that emits the same JSON) and `verify_vectors.py`; fake Mac (`mac_session.py`) records `html` of inbound pushes and sends `html` on request; e2e `clipboard` step: Mac → phone text + html, then Send Clipboard returns the same `html`; capability sample lists `text/html`; README rows |
| android | agent | `ClipboardPushData.html`; `ClipboardValues.MIME_HTML`; `HtmlClipSanitizer` (`core/protocol`, pure Kotlin, vector-driven test from `../shared/vectors/clipboard-html.json`); `LocalCapabilityBuilder` lists `text/html`; `ClipReader` keeps `item.htmlText` (sanitized) beside the text; `ClipContent.Text(text, html)`; `ClipWire` inline push with `html`, retry without it when over `CLIP_INLINE_MAX`; `PushValidator` rules of §2; `SystemClipboard.writeText` → `newHtmlText` when html; forwarding keeps/drops per peer mimes; `BenchLog` `html=1`; tests |
| apple | agent | `ClipboardPushData.html`, `ClipMime.html`, `ClipboardLimits.mimes` + `text/html`, `HtmlClipSanitizer` (HLProtocol or HLAppCore, vector-driven test reading `../shared/vectors/clipboard-html.json` like the other vector tests); `LocalClipReader` reads `public.html` beside text; `OutgoingClip`/`ReceivedClip` carry `html`; `ClipboardEngine` send (inline rule) and receive (validate, sanitize, write); `ClipboardAccess.write(_:html:clipId:sensitive:)` with a default so fakes keep compiling; `MacPasteboard` writes `public.html`; `IOSPasteboard` writes `UTType.html`; `PastedContent` loads html; tests |
| hub | agent | 00-common-specs: 0.7.2 `mimes` text, 0.10 `CLIP_MAX_HTML`; 04-clipboard: CLIP-01 API 2 logic 2, API 5 table + example, API 7; CLIP-02 API 1, API 3; CLIP-04 API 1, API 3; the sanitizer as a shared rule (new QC or in API 5 logic); en + vi same commit; `validate_design_docs.py` problems=0 |

## Acceptance

- [ ] Vectors: Kotlin and Swift sanitizers reproduce every case of `clipboard-html.json`.
- [ ] Unit tests green on android (`:feature:clipboard`, `:core:protocol`) and apple (HLProtocol, HLAppCore, HLMacUI, HLiOSUI).
- [ ] e2e `clipboard` on the API 35 emulator: the new html step PASS, all earlier steps PASS.
- [ ] Live: an article copied in Samsung Internet on the S25 pastes with its pictures in Notes on the Mac (owner).
- [ ] Spec en + vi updated, `validate_design_docs.py` problems=0; README roadmap row, CHANGELOG, handoff.

## Validation and red-team (inline, unattended)

- *Security:* HTML from another device is written to the pasteboard of this one; apps that paste HTML do not execute script, but `javascript:` links and event attributes must never survive → the receiver sanitizes too, and the vectors pin the rules. Remote `<img src>` fetches happen only when the user pastes into an app that renders HTML (same as pasting from a browser).
- *Compatibility:* older peers never receive `html` (capability-gated); the schema stays backward compatible (optional field). A peer that lists `text/html` but is attacked with `html` beside a chunked text answers `BAD_REQUEST`.
- *Size:* a long article's HTML is cut to plain text rather than chunked (YAGNI); revisit if users hit it.
- *Rollback:* remove `text/html` from the capability on either side; the field disappears from the wire.
