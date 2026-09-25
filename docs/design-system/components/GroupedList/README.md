English | [Tiếng Việt](README.vi.md)

# GroupedList

An iPhone Settings–style grouped list — rounded groups on a `system-grouped-background` background, with
headers and captions — used for Settings, Devices, and the permission screens on iOS/iPadOS and
Android. On the Mac, the same structure is a `Form` with the `.grouped` style (see `Toggle`).

## Anatomy

| Part | Specification | Token |
|------|---------|-------|
| Group header | Sentence case (no longer all caps since Liquid Glass), 13 pt Semibold | `secondary-label` |
| Group | Cell background, concentric corners (`radius-sheet` from iOS 26, `radius-row` on iOS 16–18) | `secondary-system-grouped-background` |
| Row | ≥ 44 pt tall (Android 56 dp); a square `size-row-icon` icon (30 pt) with `radius-row-icon` (8 pt) corners and an `on-icon-fill` glyph on the color; `ios-body` text | `label`, `separator` |
| Value | On the right, before the chevron | `secondary-label` |
| Chevron | `chevron.forward` ↔ `chevron_right` when the row opens a subscreen | `tertiary-label` |
| Group caption | A complete sentence explaining the consequences | `secondary-label` |
| Reason it isn't available yet | Under the row title, with an info icon | `text-orange` |

Row types: navigation (title + value + chevron), switch (`Toggle`), action (`accent` text, for example
"Resync All SMS"), destructive (`destructive-text` text, always in the last group, always confirmed with
an `Alert`).

The icon tile's color follows the function group and avoids blue: Devices `system-gray`, Clipboard
`system-orange`, Messages `system-green`, Calls `call-accept-fill`, Notifications `system-red`, Internet
Connection `system-purple`.

## API

SwiftUI `Form` or `List` with `.listStyle(.insetGrouped)`, `Section(header:footer:)`,
`LabeledContent`, `NavigationLink`. Android: `HLGroupedList { section(title, footer) { row(...) } }`
built with `LazyColumn`; each row is a single hit target, with `Modifier.semantics { role = Role.Switch }`
for switch rows.

## Dos and don'ts

- Do make the label say what happens when the setting is on; let the caption state the consequence of
  turning it off when that isn't obvious.
- Don't put two destructive actions in one group; don't put a destructive action at the top of the
  list.
- Don't duplicate system settings; link to them with an "Open Settings" button.
