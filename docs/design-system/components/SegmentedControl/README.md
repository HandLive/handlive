English | [Tiếng Việt](README.vi.md)

# SegmentedControl

A group of two to five mutually exclusive choices that are closely tied to the same content. HandLive
uses it for the Front/Back camera, the conversation filter, and the tabs of a popover menu (if there is
one).

## When to use

| Situation | Use | Don't use |
|-----------|------|------------|
| Camera "Front" / "Back" in Camera Preview | `SegmentedControl` | — |
| The "All" / "Unread" filter in the conversation list (iOS) | `SegmentedControl` under the large title | Tab bar |
| Quality "Automatic / 480p / 720p / 1080p" | A pop-up (`Picker` with the `.menu` style), because it has a default and many levels | Segmented control |
| Switching between the app's main areas | Tab bar (iOS/Android), pane toolbar (Mac Settings) | Segmented control |

- At most ~5 segments on iPhone and Android, ~5–7 on the Mac. Segments are equal in width; labels are
  nouns (title-style in English, sentence case in Vietnamese); text **or** icons, never mixed.
- The selected segment: a `tertiary-system-background` background raised above a
  `tertiary-system-fill` track, with bolder text — not just a change of color.
- API: `Picker(...).pickerStyle(.segmented)` (SwiftUI), `NSSegmentedControl`, Android `HLSegmented`
  (each segment ≥ 36 dp tall, the whole group a 48 dp hit area).

## Dos and don'ts

- Do put an introductory label before the control on the Mac when the meaning isn't clear
  ("Camera:").
- Don't use a segmented control for immediate actions (those are buttons); don't leave a segment
  disabled without saying why — hide it entirely when the phone has only one camera.
