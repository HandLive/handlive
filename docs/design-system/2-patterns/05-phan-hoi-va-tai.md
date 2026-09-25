English | [Tiếng Việt](05-phan-hoi-va-tai.vi.md)

# Feedback, loading, and errors

This section defines how HandLive reports results, waiting states, progress, and errors: the level of
interruption matches the importance, the message appears right where the user is looking, and it
always says what to do next.

HIG source: https://developer.apple.com/design/human-interface-guidelines/feedback ·
https://developer.apple.com/design/human-interface-guidelines/loading ·
https://developer.apple.com/design/human-interface-guidelines/progress-indicators ·
https://developer.apple.com/design/human-interface-guidelines/alerts

## Choosing how to report

| Situation | How | Example |
|---|---|---|
| An action the user started completes | `Feedback`. Mac: the menu bar icon changes to `checkmark` for ~1 second, then changes back. iPhone, Android: a glass HUD for ~1.5 seconds with a haptic | "Sent to Lan's Pixel 8" |
| An automatic task succeeds | Silence; the status updates in place. Only the first copy from phone to Mac gets the `checkmark` above (a Delight moment) | — |
| Waiting, queued | Status text right on the item | "Waiting for the phone", "2 messages waiting for the phone", "Tap Turn On on the phone" |
| An error that can be fixed | Right where the error happened, with a button that fixes it | "Not sent · No service" and "Try Again" under the bubble |
| Connection lost | `StatusIndicator` only | "Disconnected" and "Reconnect Now" |
| An action that can't be undone | A confirmation `Alert` | "Unpair Lan's Pixel 8?" |
| An error the app can't recover from on its own | An `Alert` with a button that leads to the fix | Key generation failed during setup (SET-03 E1), with a "Try Again" button |

- Mac, macOS 14+: `.contentTransition(.symbolEffect(.replace))`; from macOS 15 the system uses Magic
  Replace on its own; macOS 13 changes the icon with no effect.
- Haptics: iOS `UINotificationFeedbackGenerator` `.success` / `.error` (iOS 17+ `.sensoryFeedback`);
  Android `HapticFeedbackConstants.CONFIRM` / `REJECT` (API 30+), API 29 `CONTEXT_CLICK`.
- Android, when HandLive isn't on screen (the Quick Settings tile, a notification button, the share
  sheet): the system toast replaces the HUD.
- Reduce Motion: the HUD only fades in and out, and the menu bar icon swaps directly. VoiceOver and
  TalkBack read the same sentence.
- The HUD has no buttons. Things to do ("Send Anyway", "Send Again") go through `Notification` or live
  in the screen that's open.

## Errors

Write the way you'd speak: what happened, why, and what to do next. No "Error", no error codes, no
blaming the user.

| Error | Where it shows | Text | Action |
|---|---|---|---|
| SMS failed to send (SMS-04 E7) | Under the bubble | "Not sent · The phone is in Airplane Mode" | "Try Again" |
| Loading older messages without a session (SMS-03 E2) | Banner at the top of the conversation | "Connect the phone to load older messages" | Loads automatically on reconnection |
| A call command didn't get through (CALL-02 E5) | In `CallPanel` | "Couldn't send the command to the phone" | The panel returns to its previous state |
| Actions available only over Bluetooth (CALL-03 E2) | In `CallPanel`, in place of the three hidden buttons | "Connect to the phone over Bluetooth to hold, use the keypad, or mute" | — |
| Copied content too large (CLIP-01 E5) | Mac: the `MenuBarMenu` status line; Android: a toast | "Content is too large to send (up to 1 MB of text)" | — |
| The phone couldn't write it (CLIP-02 E8) | Mac: the `MenuBarMenu` status line | "Couldn't update the clipboard on the phone" | — |
| Camera while connected over the internet (CAM-02 E1) | Camera preview, `MenuBarMenu` | "Requires the same Wi-Fi network or a USB cable" | — |
| Pairing failed authentication (PAIR-01 E4) | In the pairing sheet | "Pairing isn't secure — try again" | A new QR code |
| Server not responding (SET-02 E5) | Under the button just used | "Couldn't connect to the server. Try again later." | — |

## Alerts: only two jobs

- Confirming an action that can't be undone: "Unpair" (PAIR-03), "Remove Device from Server", "Erase
  All HandLive Data" (wording from SET-02 field 29), "Resync All SMS" (SMS-01 field 6), "Remove Virtual
  Camera and Microphone" (CAM-01 A1), turning off a feature that's running (SET-02 E9).
- Errors that can't recover on their own: key generation failed (SET-03 E1, SET-01 E9); "Couldn't
  Start the Connection Service" with "Try Again" (SET-01 E2); "Couldn't connect to the server. Remove
  from this device anyway?" (SET-02 E7).
- Mac: "Cancel" on the left, the action on the right as the default button, not red, because the user
  chose it deliberately (decision 12); Esc or ⌘. means Cancel. iPhone, Android: an action sheet, with
  the destructive action in red at the top and "Cancel" at the bottom.
- No alert right as the app opens; never two alerts stacked on top of each other.

## Connection lost

- No alert and no notification, even when the connection drops and comes back many times. Only
  `StatusIndicator`: the menu bar icon adds `.slash`, and the row reads "Disconnected", "Phone
  offline · last seen 2:05 PM", or "Connecting…"; while waiting to retry: "Retrying in 8 s" and
  "Reconnect Now" (CONN-02 fields 3–4).
- Synced data stays viewable. Tasks that need the phone are queued ("Waiting for the phone") or dimmed with
  a reason: the Paste button is disabled with "Not connected to the phone" (CLIP-04 field 4).
- `CallPanel` losing its session: "Disconnected from the phone" (CALL-03 E6).
- "Needs to be paired again" (the pairing was revoked) is `status-error` because the user has to do something:
  it comes with "Pair Phone…".

## Loading and progress

- Show local data immediately and sync in the background; don't block the whole screen. The first
  time: the banner "Syncing messages…" and "Loaded 1,500 messages" on the list (SMS-01 fields 1–2);
  "Loading older messages" at the top of a conversation (SMS-03 field 10).
- A specific sentence instead of "Loading…". Mac: a small spinner without a label next to the content
  being loaded.
- When the total is known, use a determinate bar; don't turn a spinner into a bar midway. Images over 1
  MiB: "Sending image to Lan's Pixel 8 — 45%", the size in MB, a "Cancel" button (CLIP-03) — on the Mac
  in `MenuBarMenu`, on Android in the notification, on iPhone on the send card.
- A button that's working changes its label and stays locked until there's a result: "Pairing…",
  "Answering…", "Declining…" (CALL-02 field 9).
- Refresh automatically; pull to refresh on iPhone is only a secondary way.

## Empty states

| Where | Text | Next step |
|---|---|---|
| Mac, iPhone not paired | "Not paired" | "Pair Phone…" |
| Android with no devices | "No Devices Yet" | "Add Device" |
| No messages (SMS-03 E1) | "No Messages Yet" with the sync status | Wait for the sync, or "New Message" |
| Feature off or permission missing on the phone | The reason, as in Settings | "View Instructions" |
| The clipboard on iPhone | "Nothing Received Yet" | A sentence explaining how to copy on the phone |

Tabs on iPhone are never hidden or disabled because they're empty; each tab explains why right in its
content.

## Deviations

- Synced with the detailed design (September 25, 2026): CLIP-01 E5, CLIP-02 E5 and E8, and CLIP-03 E2
  report errors in place — in the `MenuBarMenu` status line (Mac) or a toast (Android); notifications
  are kept only for tasks that need an action ("Send Anyway", "Send Again").
- Synced with the detailed design (September 25, 2026): CAM-05 field 1 uses orange
  (`status-connecting`) for both "Adapting to the network" and "Limited by heat/battery", told apart by
  text and icon; "Good" uses `status-connected`.
- Synced with the detailed design (September 25, 2026): "Couldn't update the clipboard on the phone";
  Apple-style tone marks.

## Dos and don'ts

| Do | Don't |
|---|---|
| Confirm success when the user has just acted | Report every routine automatic sync |
| Keep the old data on screen when the connection drops | Replace the screen with a spinner or an alert |
| State the reason and put a fix button next to the error | A generic "Something went wrong" |
