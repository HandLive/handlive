# Clipboard image sync: investigation, fix and roadmap work (2026-10-05)

Owner ask (01:08, unattended `/vibe --ship --beta`): report progress, debug why copying an image fails, check whether code was deleted, fix first, then run the roadmap with many agents. Plan: `plans/20261005-clipboard-image-sync-fix/plan.md`. Issue: HandLive/handlive#1.

## 1. Was code deleted? No

| Repo | Range | Clipboard / transport / connection sources removed |
|------|-------|----------------------------------------------------|
| android | `4c6db55` (2026-10-01 tip) → `a4b2fb7` | none (only a notification-channel parameter) |
| apple | `214b4f4` → `baf6060` | none in Clipboard, Pasteboard, Transport; the removed lines are the Calls → AppCall and PairingSearch → PhoneBoard refactors |
| apple working tree | uncommitted | **`iOS/Info.plist` lost `NSLocalNetworkUsageDescription` at 2026-10-04 20:36** (not committed). Breaks `GeneratedFilesTests.purposeStrings`; an iPhone built from that tree gets no local-network prompt. Left untouched; owner decides (`git checkout -- iOS/Info.plist`) |

## 2. What is proven to work (this machine, 2026-10-05)

| Path | Method | Result |
|------|--------|--------|
| Mac reads an image (Finder file URL, TIFF from `NSImage`, raw PNG, `screencapture -c`) on macOS 26 | replica of `LocalClipReader` + `ImageNormalizer` on the real `NSPasteboard` | all four → PNG, would be sent |
| Mac writes a received PNG / JPEG the `MacPasteboard.write` way | replica; read back with `NSImage(pasteboard:)` | both readable |
| Android receives chunked images from a Mac | `e2e.py setup clipboard`, API 35 emulator, APK of `main` then of the fix | PNG 300 kB and 5 MB applied; `CLIP_TOO_LARGE`, `CLIP_CHECKSUM_MISMATCH` answered |
| **Android sends an image to a Mac** (never covered before) | new e2e step: Chrome "Copy image" → Send Clipboard → fake Mac verifies chunks and SHA-256 | PNG 0.3 MB (5 chunks) and 3.0 MB (46 chunks) byte-exact, in order, `source=manual`; phone `clip_read kind=image` seen |
| Protocol (chunk format, b64u SHA-256, UUIDv7 ids, 256 KiB frames) | shared vectors, Mac `maximumMessageSize` = 512 KiB, Android `InboundFrames` 256 KiB, relay `max_frame_size` set | consistent |

The first e2e run of the night used the APK built on 2026-09-29 (Gradle had silently failed: no `JAVA_HOME` in the non-login shell; `gradlew | tail` exits 0 in zsh). It was repeated with the APK of the fix; both pass the same image steps.

## 3. What was wrong in the code (fixed)

1. **Spec contradiction, code followed the losing side.** CLIP-01 API 2 logic 2 said "has `text` → text; has an image `uri` → image", CLIP-03 API 1 logic 1 said "an item with an image URI is an image". `ClipReader.read` checked `item.text`/`htmlText` first, so a copied picture whose `ClipData` item also carried the image's URL, its alt text or an empty string (browsers, OEM galleries do this) went out as that text or was dropped as empty. Spec (en + vi) and code now agree: the image URI wins. Tests: 3 new `ClipReaderTest` cases.
2. **A lost URI grant was silent even on Send Clipboard** (CLIP-03 E10 covered only "the clip changed"). AOSP `UriGrantsManagerService.checkGrantUriPermissionUnlocked` refuses a grant when the clip owner is a system-uid process (two Settings authorities excepted), so a primary clip rewritten by an OEM clipboard service carries URI items no app can open: `openInputStream` throws `SecurityException` → `PERMISSION_LOST` → nothing, no message. The manual path now says "Couldn't read the image" (existing string) and debug builds log `clip_read_failed reason=… authority=… source=…` (never the path or content). Spec E10 (en + vi), `shared/tools/bench/README*.md` row.

Verification: `:feature:clipboard:testDebugUnitTest` 115 tests, 0 failures; `:feature:clipboard:check`, `:feature:connection:detekt` + `ktlintCheck` green; `validate_design_docs.py` problems=0; `check_bilingual_docs.py` problems=0; shared `bench/self_test.py` 68 passed, `e2e/self_test.py` 0 failed.

## 4. What is still open: the S25 itself

Not reproduced here (no device attached; the Mac app was not run on this machine in the last 3 days, release builds log nothing). Ranked hypotheses and the owner's 10-minute check are in CLAUDE.md "In progress" item 8 and in `research-samsung-clipboard-images-2026-10-05.md` (with a reviewer note on which claims AOSP confirms and which are doubtful). Direction of the owner's failure (phone → Mac, Mac → phone, iPhone) is unknown.

## 5. Roadmap work by parallel agents (same night)

| Agent | Outcome | Branch / PR |
|-------|---------|-------------|
| e2e phone → Mac image | fake Mac accepts chunked pushes (order, size, SHA-256, `CLIP_CHECKSUM_MISMATCH`); new scenario step; READMEs | shared `feat/e2e-phone-to-mac-image` (`60724af`, `b03b6e3`, `680f361`), plus `d2cd8fb` bench row; `e2e-phone-to-mac-image-2026-10-05.md` |
| release-apple split | `sign` / `launch` (no secrets, `permissions: {}`) / `publish`; `actionlint` clean; not dispatched yet | apple `ci/release-apple-split-jobs` `6836366` → HandLive/handlive-apple#1; hub docs `1394276`, `d3b3082`; `release-apple-split-jobs-2026-10-05.md` |
| website image digests | 4 images pinned to multi-arch index digests, docs on refreshing them, scan report row closed | hub `776c65a`, `9a40ada`; `website-image-digests-2026-10-05.md` |
| One UI clipboard research | 5 ranked hypotheses with device checks; reviewer note added | `research-samsung-clipboard-images-2026-10-05.md` |

Fake-Mac race found while rerunning: `wait()` returned a push before the fake Mac had recorded its ack, so "the Mac acked it applied" could fail by timing. Fixed in `mac_session.py` (events are published after the clipboard handling) — see the shared branch.

## 6. Commits and PRs

- android `fix/clipboard-image-item-precedence`: `ad46b80` test, `4f19dc8` fix (image URI first), `98c77a7` fix (manual-path message, `clip_read_failed`) → HandLive/handlive-android#1
- shared `feat/e2e-phone-to-mac-image`: see §5 + the race fix → PR below
- apple `ci/release-apple-split-jobs`: `6836366` → HandLive/handlive-apple#1
- hub `feat/check-progress-image-copy-debug-906617`: `8a6548c` spec precedence + plan, `2f9876b` spec E10 + research note, `776c65a`/`9a40ada` website, `1394276`/`d3b3082` release-apple docs, `5379ccd` roadmap + changelog, this report and CLAUDE.md → PR below

PR numbers of shared and hub, review and merge results: appended at the end of the run.

## Unresolved questions

1. Which direction failed for the owner, and does the S25 show `clip_read_failed … authority=…` or no `clip_read` at all?
2. `apple/iOS/Info.plist`: restore the deleted purpose string, or was the deletion intended for the personal-team build?
3. release-apple: add a fourth build-only job without the `release` environment (full secret isolation), and a test path for unprotected branches?
4. Website images: refresh cadence (monthly?) and whether to add Renovate/Dependabot.

Status: DONE_WITH_CONCERNS
Summary: No code was deleted; every clipboard image path that can be exercised on this machine works, a spec contradiction that silently mis-sent image copies with a text beside the URI is fixed, a silent lost-grant case now tells the user and logs, and the phone → Mac image path is covered by e2e; the S25-specific failure still needs one device check by the owner.
Concerns/Blockers: real-device root cause unconfirmed; `iOS/Info.plist` local deletion pending the owner's decision.
