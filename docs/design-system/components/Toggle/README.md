English | [Tiếng Việt](README.vi.md)

# Toggle

Switches and checkboxes for on/off settings. The Mac distinguishes switches (main features) from
checkboxes (secondary options); iPhone/iPad and Android use only switches in list rows.

## Choosing the type

| Platform | Main feature ("Sync Clipboard", "SMS Messages", "Take Calls on Mac") | Secondary option ("Block Sensitive Content", "Ring on Mac") |
|----------|------|------|
| macOS | A mini switch in a grouped form: `Toggle` + `.toggleStyle(.switch)` + `.controlSize(.mini)` | A checkbox indented under the main feature: `.toggleStyle(.checkbox)` |
| iOS/iPadOS | A switch at the end of the list row: `Toggle` in `Form`/`List` | A switch in its own row, with a caption under the group |
| Android | `HLSwitch` 51×31 dp in a 56 dp row (the whole row is the hit target) | Same as the main feature |

- The on color: iOS and Android use `system-green`, like the iOS default; the Mac uses the accent color
  (`accent-fill`, or the color the user chose in System Settings). The switch thumb uses
  `switch-thumb`.
- When the main feature is off, the secondary options stay visible but dimmed (checkboxes on the Mac) —
  not hidden, so people can see what they'd get back by turning it on again.
- The label says what happens when it's on; the caption under the group explains the consequences.
  Don't use a switch for an immediate action — use `Button`.
- A switch doesn't only change color: the thumb's position changes too. The state is read out in words
  ("On"/"Off").

## When a feature isn't available yet

If the feature is off on the other device or a permission is missing (comparing the capabilities of
the two sides, SET-02), the switch is disabled and the row shows a reason in `text-orange` with the
fix: "Missing SMS permission on the phone · Grant Permission". When turning on a feature that needs a
disclosure (Take Calls on Mac, Accessibility on Android), the switch only turns on once `ConsentSheet`
is complete.

## Dos and don'ts

- Do let changes take effect immediately, with no "Apply" button.
- Don't mix switches and checkboxes at the same level; once a group uses checkboxes, stick with
  checkboxes.
- Don't put switches in the toolbar or in menus; menus use checkmarks.
