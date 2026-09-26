English | [Tiếng Việt](03-thong-bao.vi.md)

# Notifications

This section lists every notification HandLive sends, the type and interruption level of each, the
wording, the actions, and how Focus is respected. On Android, notifications use Android's templates
and channels; on Mac, iPhone, and iPad they're Apple notifications.

HIG source: https://developer.apple.com/design/human-interface-guidelines/notifications ·
https://developer.apple.com/design/human-interface-guidelines/managing-notifications

## Mac, iPhone, iPad

| Notification | Platform | Type · level | Title · body | Actions |
|---|---|---|---|---|
| New SMS (SMS-02) | Mac, iOS | Communication `INSendMessageIntent`, active | "Nguyễn Văn A" · "Don't forget the documents" | "Reply" (text field, "Send" button), "Mark as Read" |
| Incoming call (CALL-01) | iOS | Communication `INStartCallIntent`, time-sensitive | "Nguyễn Văn A" · "Incoming call · SIM 1" | "Decline" (destructive, requires unlocking the device) |
| Incoming call | Mac | Communication `INStartCallIntent`: passive while `CallPanel` is showing (goes only to Notification Center); time-sensitive when a Focus is on and the panel isn't shown | Same as above | "Answer", "Decline" |
| Missed call (CALL-04) | Mac, iOS | Active | Name, number, or "No Caller ID" · "Missed call · 2:05 PM" (plus "· SIM 1") | "Message" (text field) — only when there's a number and SMS can be sent |
| Sensitive content blocked (QC3) | Mac | Passive | "Sensitive Content Blocked" · "HandLive doesn't send content that looks like a password or card number." | "Send Anyway" (expires after 2 minutes) |
| Clipboard conflict (QC8) | Mac | Active | "Clipboard Not Updated on Lan's Pixel 8" · "That device just copied something new." | "Send Again" (expires after 2 minutes) |
| Camera (CAM-05) | Mac | Active (overheating), passive (low battery) | No title of its own. Overheating: "The phone is too hot — the camera has stopped. Let the phone cool down, then try again." Low battery: "Phone battery is below 20% — HandLive lowered the quality to 720p. Plug in a charger or a USB cable to keep the quality." | — |

- Hidden content: with `sms.preview` off, the body is "New SMS message" (SMS-02 field 2). When the user
  turns off previews in the system settings, the system uses `hiddenPreviewsBodyPlaceholder`: "New SMS
  message" (`HL_SMS`), "Incoming call" (`HL_CALL_INCOMING`), "Missed call" (`HL_CALL_MISSED`).
- iPhone locked and the extension can't read the keys: generic content "New SMS message", "Incoming
  call on your phone", "Missed call on your phone", with no actions (C3).
- Every action has an SF Symbol: Reply to a message `arrowshape.turn.up.left`, Mark as Read
  `envelope.open`, Answer a call `phone.fill`, Decline `phone.down.fill`, Message `message`, Send
  Anyway `paperplane`, Send Again `arrow.clockwise`.
- Grouping: `threadIdentifier` per conversation (`sms:<pair_id>:<thread_id>`) and `calls`; push uses
  `apns-collapse-id` to avoid duplicates.

## Android

| Channel (id) | Level | Notification | Actions |
|---|---|---|---|
| `hl_service` "Connection service" | `IMPORTANCE_LOW`, ongoing, no badge | "Waiting for a connection" · "Connected to Lan's MacBook" · "Connected to 2 devices" | "Send Clipboard" |
| `camera_request` | `IMPORTANCE_HIGH` (heads-up), cancels itself after 60 s | "Lan's MacBook wants to use the camera and microphone" | "Turn On", "Decline" |
| `camera_live` | `IMPORTANCE_LOW`, ongoing | "Using the camera for Lan's MacBook" | "Switch Camera", "Turn Off Microphone" or "Turn On Microphone", "Stop" (3 at most) |
| `camera_alert` | `IMPORTANCE_DEFAULT` | Overheating, low battery — the same wording as on the Mac | — |
| `clipboard` (proposed) | `IMPORTANCE_LOW` (silent, like passive) | Sensitive content blocked; conflict; progress for images over 1 MiB "Sending image to Lan's MacBook — 45%" | "Send Anyway"; "Send Again"; "Cancel" |
| `permission` (proposed) | `IMPORTANCE_LOW` | "Lan's MacBook needs SMS permission on this phone — tap to allow" (SET-01 field 17) | — |

- The template, the small icon, and the presentation belong to Android: `NotificationCompat`, a
  monochrome small icon (Material Symbols), and actions that are `PendingIntent`s opening an activity
  or service directly (Android 12+ blocks trampolines).
- People turn off individual channels in Android's notification settings; HandLive links there with
  `ACTION_CHANNEL_NOTIFICATION_SETTINGS` and doesn't build switches of its own.

## Focus

- Communication notifications (messages, calls) let the system filter by the senders and callers the
  user allows; HandLive doesn't decide on its own.
- Time-sensitive is only for a call that's ringing: an event happening right now, which breaks through
  Focus and the scheduled summary. The first time, the system asks the user whether to keep this kind
  of notification; the user can turn it off. Don't use time-sensitive for anything else.
- Mac: when a Focus is filtering out the caller, `CallPanel` doesn't appear and nothing rings; the call
  is still in `MenuBarMenu` (decision 10). Without permission to read the Focus status, the Mac doesn't
  ring, but the panel still appears (CALL-01 API 5).
- Non-communication notifications at the passive and active levels go into the scheduled summary when
  the user has it turned on; direct messages and time-sensitive notifications arrive immediately.

## Rules

- One event, one notification. A missed call is reported once per device; a new sensitive-content or
  conflict notification replaces the old one; messages that arrive through catch-up sync (SMS-01) only
  update the list and the badge; losing and regaining the connection produces no notification.
- Errors don't go out as notifications: an error shows right where it happened (the Feedback, loading,
  and errors section). The only exception: the result of an action taken directly on a notification
  while the app isn't open.
- Badges count only things not yet seen: the number of unread conversations on the iOS app icon, on the
  Messages tab, and right after the Mac menu bar icon; the Calls tab counts unseen missed calls. They go
  down as soon as the items are seen. Don't draw fake badges.
- When the app is in the foreground, don't send notifications; update the interface instead: an open
  conversation doesn't notify about its own messages (SMS-02 step 7); an iPhone with HandLive open when
  a call comes in shows an in-app banner (CALL-01 step 8); an iPhone that receives a clipboard conflict
  while the app is open reports it right on the send card (CLIP-04 E6).
- Wording: a short title, no period, no "HandLive"; the body is a complete sentence that isn't cut
  short by hand; never reveal what was just copied. At most 4 actions, each a short verb; no action
  that only opens the app.
- Don't use notifications to tell people to do things; the exception is the permission suggestion on
  Android, at most once per feature every 24 h.

## Deviations

- Intentional deviation: the iPhone reports errors from actions taken on a notification with a local
  notification, because the app isn't open: "Couldn't send the decline command. The call is still
  ringing on the phone." (CALL-02 E8), "Not sent yet. Open HandLive to try again." (SMS-04 E8).
- Synced with the detailed design (September 25, 2026): SMS-02 API 4 has `HL_SMS_REPLY` and
  `HL_SMS_MARK_READ` ("Mark as Read", only on this device, per SMS-05).
- Synced with the detailed design (September 25, 2026): CALL-01 API 6 (I-NSE) and API 7 (Mac) use
  `INStartCallIntent`; the `clipboard` channel (CLIP-01 fields 8, 12) and the `permission` channel
  (SET-01 field 17).
- Synced with the detailed design (September 25, 2026): CONN-04 API 4 and CALL-01 field 11 don't set a
  push title; the system shows the app name itself.
- Synced with the detailed design (September 25, 2026): SET-01 field 5 "Send Clipboard"; Apple-style
  tone marks.

## Dos and don'ts

| Do | Don't |
|---|---|
| Let the system filter messages and calls by person in Focus | Break through Focus for ordinary messages |
| Group messages from the same conversation together | Dump a pile of old notifications after every reconnection |
| Actions that finish the task without opening the app | An "Open" button that does the same as tapping the notification |
