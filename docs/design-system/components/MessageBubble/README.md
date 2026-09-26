English | [Tiếng Việt](README.vi.md)

# MessageBubble

The bubble of a single SMS in a conversation, and the compose field at the bottom (SMS-03, SMS-04).
Following the convention of Apple's Messages, SMS you send are green — in HandLive that's
`bubble-outgoing` (darker than Apple's SMS green so white text reaches 4.5:1) — and incoming messages
use `bubble-incoming`.

## Bubbles

| Part | Specification |
|------|---------|
| Incoming message | Left, `bubble-incoming` background, `label` text, 18 pt corners |
| Outgoing message | Right, `bubble-outgoing` background, `on-bubble-outgoing` text |
| Links, phone numbers | Detected automatically, underlined, in the same color as the text; numbers never break across lines |
| Date markers | "Today", "Yesterday", "Sep 12", centered, when the day changes |
| Time and status | Under the last message of a cluster, `ios-caption-1` / `mac-caption-2` |

The status of an outgoing message only moves forward, and each status has its own icon:

| Status | Text | SF Symbol ↔ Material |
|-----------|-----|----------------------|
| `pending` | "Waiting for phone" | `clock` ↔ `schedule` |
| `sending` | "Sending…" | A small `ProgressView` |
| `sent` | "Sent" | `checkmark` ↔ `check` |
| `delivered` | "Delivered" | `checkmark.circle` ↔ `done_all` |
| `failed` | "Not sent · \<reason>" + a "Try Again" button; a red `exclamationmark.circle.fill` icon next to the bubble | ↔ `error` |

Reasons by error code, as in SMS-04 field 8: `SMS_NO_SERVICE` "No service" · `SMS_RADIO_OFF`
"The phone is in airplane mode" · `SMS_LIMIT_EXCEEDED` "Sending limit reached. Try again later." ·
`SMS_INVALID_ADDRESS` "Invalid number" · `SMS_SIM_UNAVAILABLE` "The SIM isn't active" ·
`PERMISSION_MISSING` "Missing SMS permission on the phone" · `NOT_CONNECTED` "Couldn't connect to the phone" · anything else "Couldn't send".

## Compose field

A capsule text field "SMS Message" on glass, with a round `accent-fill` send button (`arrow.up`).
Dual-SIM phones: a "SIM 1" chip opens a menu to choose the SIM. Under the field, the character and
part counter of SMS-04 field 3: "0/160" while empty, then "{used}/{limit} · {parts}", for example
"120/160 · 1 message" (each part is charged). At most 1,600 characters. Mac: Return sends, ⇧Return
adds a new line. Conversations with several recipients: no compose field; the line "Reply to group
conversations on the phone" takes its place. If the phone can't send SMS: hide the compose field.

## Dos and don'ts

- Do show a temporary bubble as soon as the user sends (≤ 100 ms), with "Waiting for phone".
- Don't resend failed messages automatically; the user decides with "Try Again".
- Don't change bubble colors to follow the system accent color.
