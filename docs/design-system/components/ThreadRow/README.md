English | [Tiếng Việt](README.vi.md)

# ThreadRow

One SMS conversation in the list, presented the way Apple's Messages app does it: an unread dot, a
letter avatar, the name, the time, and a two-line excerpt (SMS-03).

Android doesn't have this component — people read SMS in the phone's own messaging app.

## Anatomy

| Part | Specification | Source |
|------|---------|-------|
| Unread dot | 10 pt, `unread` color, in the left margin; when there's none, the same width stays blank | `unread_count > 0` and `local_read_ts < last_ts` |
| Avatar | Initials on a gray gradient background (Contacts style); unknown number → `person.crop.circle.fill`; group → `person.2.fill` | `display_name`, `addresses` |
| Name | The contact's name, or the number formatted like "090 000 0123"; groups: the names joined with ", " | `display_name` |
| Time | "2:05 PM" for today, "Yesterday", "Sep 12"; with `chevron.forward` on iPhone | `last_ts` |
| Excerpt | At most two lines, `secondary-label`. The latest message failed to send: `exclamationmark.circle.fill` + "Not sent" in `destructive-text` | `snippet`, `sms_outbox.state` |

- Unread: a bold name and the dot. No message count in the row (Apple's way); the number of unread
  conversations appears in the Mac menu bar and on the Messages tab badge. Synced with the detailed
  design (September 25, 2026): SMS-03 field 5 no longer shows the `unread_count` number in the row.
- The selected row (Mac, iPad): the system accent color as the background, with white text.

## By platform

- **macOS:** the sidebar of the Messages window (`NavigationSplitView`, `List(selection:)` with the
  `.sidebar` style), 32 pt avatars, names in `mac-headline`, excerpts in `mac-subheadline`. Search at
  the top of the sidebar; the new message button (⌘N) in the toolbar, not at the bottom of the sidebar.
  Right-click: "Mark as Read", "Copy Number".
- **iOS/iPadOS:** a plain `List`, 40 pt avatars, names in `ios-headline`, excerpts in
  `ios-subheadline`; swipe left to mark as read; the "All / Unread" filter with `SegmentedControl`.

## Dos and don'ts

- Do keep the order by the latest message; a conversation with a failed message doesn't jump to the
  top.
- Don't truncate names in the middle; don't bold the whole excerpt.
