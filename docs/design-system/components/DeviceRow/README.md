English | [Tiếng Việt](README.vi.md)

# DeviceRow

One paired device: its type, its name, the link status, and the way into its details (PAIR-02). Android
sees a list of up to eight devices; the Mac and iPhone/iPad see only one phone.

## Anatomy

| Part | Content | Source |
|------|----------|-------|
| Icon | `laptopcomputer` ↔ `laptop_mac`, `iphone` ↔ `phone_iphone`, `ipad` ↔ `tablet_mac`, Android phone `candybarphone` ↔ `smartphone`; round `tertiary-system-fill` tile | `peer_platform` |
| Name | Exactly as the user named it, one line, truncated at the end with "…" | `peer_name` |
| Status | A small `StatusIndicator`: "Connected via Wi-Fi", "Phone offline · last seen 2:05 PM" | The connection state machine, `last_seen_at` |
| Trailing end | A chevron that opens the details (iOS/Android); on the Mac, a "Details…" button | — |

The details screen has: the features in use and the reasons a feature isn't available yet, the
permissions missing on the phone, the **Security Code** of 8 hex characters (shown in two groups, "7F3A
9C21", in a small `code-pin` style, selectable and copyable), and the "Unpair" button in the last group.

## By platform

- **macOS:** Settings › Devices: one row in a grouped `Form`, a 32 pt icon, the name in `mac-headline`,
  the status in `mac-subheadline`, the "Details…" and "Unpair…" buttons on the right.
- **iOS/iPadOS:** Settings › Phone, a 60 pt row in `GroupedList`.
- **Android:** the Devices screen (the main tab), 72 dp rows; the empty state has the `brand-title`
  title "No Devices Yet" and the "Add Device" button.

## Dos and don'ts

- Do update the status within ≤ 1 second when the connection changes, with no need to pull to refresh.
- Don't show `pair_id`, keys, or IP addresses in the row.
- Don't put "Unpair" directly on the row; always go through the details screen and a confirmation
  `Alert`.
