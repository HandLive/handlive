English | [Tiếng Việt](README.vi.md)

# Notification

HandLive's system notifications. On Mac, iPhone, and iPad they're Apple notifications (messages and
calls use the **communication notification** style, with the sender's avatar); on Android they're
Android notifications with their own channels — not rebuilt in the Apple style, because they're part
of the operating system's interface.

## Catalog

| Event | Platform | Type / level | Title · body | Actions |
|--------|---------|-----------|---------------------|-----------|
| New SMS (SMS-02) | Mac, iOS | Communication (`INSendMessageIntent`), active | Sender's name · the message text; with content hidden, "New SMS message" | "Reply" (text field), "Mark as Read" |
| Incoming call (CALL-01) | iOS | Communication (`INStartCallIntent`), time-sensitive | Name or number · "Incoming call · SIM 1" | "Decline" |
| Incoming call (CALL-01) | Mac | Communication; passive while `CallPanel` is showing, time-sensitive when a Focus is on and there's no panel | Same as above | "Answer", "Decline" |
| Missed call | Mac, iOS | Active | Name or number · "Missed call · 2:05 PM" | "Message" |
| Sensitive content blocked (CLIP-01) | Mac, Android | Passive | "Sensitive Content Blocked" · "HandLive doesn't send content that looks like a password or card number." | "Send Anyway" (expires after 2 minutes) |
| Clipboard conflict | Mac, Android | Active | "Clipboard Not Updated on Lan's MacBook" · "That device just copied something new." | "Send Again" |
| The Mac asks for the camera (CAM-02) | Android | `camera_request` channel, high level | "Lan's MacBook wants to use the camera and microphone" | "Turn On", "Decline" (cancels itself after 60 seconds) |
| Camera live | Android | `camera_live` channel, ongoing | "Using the camera for Lan's MacBook" | "Switch Camera", "Turn Off Microphone", "Stop" |
| Connection service | Android | `hl_service` channel, low | "Connected to Lan's MacBook" | "Send Clipboard" |

## Content

- A short title, no period, no "HandLive" (the system already shows the app's name). The body is a
  complete sentence that isn't cut short by hand.
- At most four actions, each a short verb with an SF Symbol; no action that only opens the app.
- Don't send notifications while the app is open in the foreground — update the interface instead. No
  repeated notifications for the same thing; errors don't go out as notifications.
- The app icon badge counts only unread messages.
- Respect Focus: communication notifications let the system filter by sender or caller.

## Dos and don'ts

- Do let message notifications show their content according to the "Show Content in Notifications"
  option.
- Don't use time-sensitive for anything other than a ringing call.
- Don't redraw notifications inside the app; the preview here only illustrates the content.
