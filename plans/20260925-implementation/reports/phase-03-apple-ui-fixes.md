# Phase 3 — Apple UI fixes found while capturing screenshots

Date: 2026-09-27. Branch `feat/phase-03-calls` (apple), `main` (hub). No spec, string or `shared/` change.

## Fixes

1. **iPhone Messages list (iOS 27): large title hidden, search field over the All/Unread filter.**
   Cause: `MessagesSplitView` put the filter in `safeAreaInset(edge: .top)` above a `.searchable` list; on
   iOS 26+ the inset sits under the navigation bar. Fix: the filter is passed as the `header` of
   `ThreadListView` (the same slot the Mac uses for "Calls"), so it is the list's first row, no separator,
   inset `space8`/`space16`. Result: large title "Messages" visible, search field appears above the filter
   when pulled down, filter scrolls with the list. iPad split view: sidebar shows title, search, filter, rows
   correctly (en, vi).
2. **New Message "To: To:" (iOS and Mac).** Cause: `TextField(text:prompt: nil) { Text(label) }` — a `nil`
   prompt makes SwiftUI draw the label as the placeholder, next to the visible "To:" text. Fix: empty prompt
   (`Text(verbatim: "")`); the label stays as the VoiceOver label. Matches SMS-04 field 1 (label "To:"
   once). No new string needed.
3. **Stale `HandLive.xcodeproj`.** `xcodegen generate` in `apple/`; `xcodebuild -scheme HandLiveiOS
   -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO build` → BUILD SUCCEEDED (includes
   `HandLiveNotificationService` with `HLCallNotifications`). Nothing to commit (project is git-ignored).
   `apple/README.md`, `apple/CLAUDE.md` and `docs/codebase-summary.md` already say to run `xcodegen
   generate`; they could add "again after pulling a `project.yml` change" — not changed here.

## Verification

- Harness (scratch, not committed) on iOS 27 Simulator, iPhone 17 and iPad Air 11-inch (M4), en and vi;
  swipe-down on the iPhone list checked the search field position. Mac harness: Messages window, New
  Message, en and vi. All images inspected.
- `xcodebuild test` HLSMSUI (11 tests) and HLiOSUI (23 tests), `platform=macOS`: passed.
- `swiftlint lint --strict`: 0 violations.
- No tests added: both changes are view layout only, no model logic changed.

## Screenshots (hub)

Added `docs/screenshots/ios/10-messages-list.{en,vi}.png`, `ios/11-new-message.{en,vi}.png`,
`macos/05-new-message.{en,vi}.png` (`sips -Z 1200`), listed in `README.md` and `README.vi.md`; the two
known issues removed. `ios/09-ipad-messages.en.png` unchanged (the iPad sidebar was already correct).
`check_bilingual_docs.py`: problems=0.

## Commits

| Repo | Hash | Message |
|------|------|---------|
| handlive-apple | `750925f` | fix(apple): put the All/Unread filter inside the iPhone Messages list |
| handlive-apple | `2fd87b3` | fix(apple): show the To: label once in New Message |
| handlive (hub) | `56e7884` | docs: add the Messages list and New Message screenshots |

## Unresolved questions

- iPad sidebar in Vietnamese shows the inline title "Tin nhắn" trailing-aligned next to the toolbar
  buttons, while English is leading-aligned. System layout, not caused by this change; worth a look later.

Status: DONE
Summary: Filter moved into the list's first row (large title and search fixed), "To:" shown once in New Message, xcodeproj regenerated and iOS app builds; screenshots added to the hub gallery.
