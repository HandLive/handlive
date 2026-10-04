# Apple clipboard HTML (2026-10-05)

Repo `/Users/hxd/HandLive/apple`, branch `feat/clipboard-html` from `main` `a882a2d`. Not pushed. `iOS/Info.plist` (unrelated) left untouched and unstaged.

## Commits (handlive-apple)
- `ec2108b` feat(apple): HtmlClipSanitizer and the html field of clipboard/push
- `1a5ff06` feat(apple): read, send and write the HTML of a text clip on Mac and iOS
- `a110a73` test(apple): clipboard HTML on send, receive, read and paste

## Changes per file
- HLProtocol: `ClipboardMessages.swift` (`ClipMime.html`, `ClipboardPushData.html`, key `html`, init default nil); new `HtmlClipSanitizer.swift` (byte-level port of the Python reference; quoted `>` in attribute values honoured; drop/keep/unwrap sets, attribute order, scheme and digit rules as §6).
- HLAppCore: `LocalDevice.swift` (`ClipboardLimits.htmlMime`, `textMimes`, `mimes` = text/plain, text/html, image/png, image/jpeg; images off = text/plain + text/html); `ClipboardConstants.maxHtmlBytes` (180 KiB); `ClipboardAccess.swift` (`PasteboardTypeID.html`, new `write(_:html:clipId:sensitive:)` requirement + default extension calling the old `write`); `ClipboardEvents.swift` (`html` on `OutgoingClip`, `ReceivedClip`, `HeldClip`); `LocalClipReader.swift` (`.text(String, html:, sensitiveType:)`, reads `public.html` only when the first item declares it, sanitized, empty → nil); `ClipboardEngine+LocalClips.swift` (html carried through capture, hold, Send Anyway/Again); `+Sending.swift` (`send(_:html:sensitive:manual:)` drops html over `maxHtmlBytes`; `inlinePush(_:to:)` adds html only when the phone lists `text/html`, retries without it over `CLIP_INLINE_MAX`; chunked text never carries it; bench `clip_read html=1`); `+Receiving.swift` (validate: BAD_REQUEST for html with image, with transfer, or > `maxHtmlBytes`; write re-sanitizes and passes html to `access.write`; `ReceivedClip.html`; bench `clip_received html=1`); `+Paste.swift` (`sendPasted(_:html:)`, copy-again keeps html).
- HLMacUI: `MacPasteboard.swift` (`public.html` set beside `.string` in the one item; old `write` forwards).
- HLiOSUI: `IOSPasteboard.swift` (`UTType.html` beside utf8PlainText); `PastedContent.swift` (`Loaded {content, html}`; loads and sanitizes `UTType.html` for text); `IOSAppModel+Clipboard.swift` (`sendPasted` passes html).
- Tests: `HtmlClipSanitizerVectorTests` (30 vectors byte for byte, hostile input, multibyte); `ClipboardMessagesTests` (html round trip, absent key); `ClipboardSendTests` (3 new: html only to text/html phone, dropped over inline limit / max html / chunked, Send Anyway keeps html); `ClipboardReceiveTests` (2 new: html sanitized and written, BAD_REQUEST cases); `ClipboardRulesTests` (public.html read); `ClipboardIOSTests` (paste with html, copy again); `AppCoreTests` (capability mimes); new `PastedContentTests`; test support: `FakePasteboard` moved to its own file (file_length lint), records html, `ClipboardHarness.htmlFeature`.

## Verification
- Package tests, CI way (`Tools/make-test-scheme.sh HLTests-html only HLProtocolTests HLAppCoreTests HLMacUITests HLiOSUITests`, then `xcodebuild test -workspace HandLive.xcworkspace -scheme HLTests-html -destination 'platform=macOS' -parallel-testing-enabled NO`): HLProtocol 80, HLAppCore 125, HLMacUI 70, HLiOSUI 27 tests, all pass (302). HLTransport untouched. `SchemaConformanceTests` passed (the shared schema checkout already accepted the unchanged examples; no html example is validated against the schema yet).
- `swiftlint lint --strict`: 0 violations.
- `xcodegen generate` + Mac app Debug (arm64, unsigned): BUILD SUCCEEDED. The iOS app target was not built.

## Deviations / notes
- `ClipboardAccess` has both `write` forms as requirements (the default extension alone would dispatch statically to the text-only one through the existential). Real pasteboards implement the new form; the old one forwards with `html: nil`.
- `apply` / `Transfers` untouched: html comes from `push.html` inside `write`; chunked text is rejected earlier in `validate`.
- Sanitizer digit/whitespace handling is ASCII (Python `isdigit`/`\s`/`strip` are Unicode); no vector exercises the difference. Kotlin should match one choice; ASCII-only is the stricter and safer one.
- No automated test touches the real `NSPasteboard`/`UIPasteboard` (none existed; writing would clobber the user's clipboard), so `MacPasteboard`/`IOSPasteboard` html writes are verified by build only.
- `Tools/HandLiveDevClient` `MemoryPasteboard` not built; compiles through the default extension.

Status: DONE
Summary: HTML of text clips is read, sanitized, sent (capability-gated, size-ruled), validated, re-sanitized and written on Mac and iOS; 30/30 vectors match byte for byte, 302 package tests green, SwiftLint clean, Mac app builds.
Concerns/Blockers: none; real-pasteboard html writes and the iOS app build are unverified here.
