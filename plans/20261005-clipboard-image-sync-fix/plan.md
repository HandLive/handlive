# Clipboard image sync: debug and fix (2026-10-05)

**Status:** implemented, PRs open (android #1, shared #1, apple #1, hub #2) · **Route:** bugfix · **Ship mode:** beta · **Repos:** android (code), hub (spec, docs, reports), shared (e2e coverage, separate branch)

## Problem

Owner report (2026-10-05): copying an image does not sync between the Galaxy S25 Ultra and the Mac while text does; the owner suspects code was deleted by the 2026-10-04 sessions.

## Findings (evidence first)

| Check | Result | Evidence |
|-------|--------|----------|
| Deleted code in the clipboard, transport or connection paths since 2026-10-01 (android `4c6db55`, apple `214b4f4`) | **None.** Android: no removed source line in `feature/clipboard`, `core/transport`, `feature/connection`, `core/protocol`. Apple: removed lines belong to the Calls and PairingSearch refactors only | `git diff` of both repos |
| Uncommitted change in `apple/iOS/Info.plist` (2026-10-04 20:36): `NSLocalNetworkUsageDescription` removed | **Accidental local deletion, not committed.** Breaks `GeneratedFilesTests.purposeStrings` and would deny the iPhone's local-network prompt if built from this tree | `git -C apple diff iOS/Info.plist` |
| Mac reads an image from the pasteboard (Finder file URL, TIFF from `NSImage`, raw PNG, `screencapture -c`) on macOS 26 | **OK**: all four normalize to PNG and would be sent | `scratchpad/macread.swift` replica of `LocalClipReader` + `ImageNormalizer` |
| Mac writes a received PNG/JPEG the `MacPasteboard.write` way and another app reads it | **OK** | `scratchpad/macwrite.swift` |
| Android receives chunked images from a Mac (API 35 emulator, APK of `main` a4b2fb7) | **OK**: PNG 300 kB and 5 MB applied, CLIP_TOO_LARGE and CLIP_CHECKSUM_MISMATCH answered | `shared/tools/e2e e2e.py setup clipboard`: 27 + 15 PASS, 1 SKIP |
| Android reads an image for phone → Mac | **Never covered end to end** (the harness sends text only from the phone); unit tests use a URI-only `ClipData`. `ClipReader.read` prefers `item.text`/`htmlText` over the image URI, so an item that carries both (an empty string, the URL or the alt text beside the picture, as browsers and OEM galleries do) is sent as text or dropped as E3 | code reading; spec contradiction CLIP-01 API 2 logic 2 vs CLIP-03 API 1 logic 1 |

## Fix (this plan)

1. **Spec first** (hub, `docs/detailed-design/04-clipboard.md` + `.vi.md`): CLIP-01 API 2 logic 2 and CLIP-03 API 1 logic 1 state that an item whose URI is an image is the copied image even when text or HTML stands beside it. `validate_design_docs.py` → `problems=0`.
2. **Android** (`feature/clipboard/.../system/ClipReader.kt`): check the image URI before the text/HTML rule. Tests in `ClipReaderTest`: image with empty text, with its URL, with alt text, with HTML beside it → `LocalRead.Image`; text with a non-image URI stays text.
3. **Evidence for the real device** (parallel agents, separate branches): e2e step phone → Mac image through Chrome "Copy image" + the Send Clipboard button (shared `feat/e2e-phone-to-mac-image`); research of One UI 8 clipboard `ClipData` shapes (report only).
4. **Docs**: README roadmap row for Phase 1, CHANGELOG (hub), report under `plans/20260925-implementation/reports/`.

## Acceptance criteria

- [x] `:feature:clipboard` unit tests green (115, 0 failures), the three new `ClipReaderTest` cases and the `LocalClipSendTest` update included.
- [x] `python3 tools/docs/validate_design_docs.py` prints `problems=0`; `check_bilingual_docs.py` green.
- [x] e2e `clipboard` scenario on the API 35 emulator fully PASS with the new APK (17 PASS, 1 SKIP), the two phone → Mac image steps included.
- [ ] Android PR reviewed, labeled, merged (`--ship --beta`); hub docs PR merged; CI green.
- [x] Report lists what is proven, what is still a hypothesis, and the exact device check for the owner (`reports/clipboard-image-sync-debug-2026-10-05.md`).

## Validation and red-team (inline; the interactive `/ck:plan validate` and `red-team` gates would block on owner questions in this unattended run)

- *Does the precedence change break a legitimate text copy?* A text item never carries an image-MIME URI unless the user copied a picture or an image file; a file copy of an image matches the Mac rule "an image file copied in Finder is the copied image". A text item with a non-image URI (PDF, document) stays text — covered by a test.
- *Is this proven to be the S25 root cause?* No. It is a spec contradiction that silently drops or mis-sends real-world image clips; the owner's device logs or the research report must confirm. The report says so plainly.
- *Rollback:* revert the one `when` reordering; no data or wire change.

## Unresolved questions

- Which direction failed for the owner (phone → Mac, Mac → phone, iPhone)? The report asks for one `adb logcat -s HLBENCH:I` capture with a debug build.
