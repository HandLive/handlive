English | [Tiếng Việt](10-quyen-rieng-tu.vi.md)

# Privacy

HandLive asks for a permission right when people need the feature, says clearly where data goes, and
offers no way to turn off end-to-end encryption. This section lists the permissions on each platform,
the permission explanations (purpose strings), the rules for the screen shown before a permission
request, and how sensitive content is handled.

HIG source: https://developer.apple.com/design/human-interface-guidelines/privacy

## Principles

- Ask only for permissions for features the user turns on or is using. During setup, ask only for the
  core permissions: notifications and local network.
- Say clearly where data goes: only between paired devices; the server behind the internet connection
  only relays encrypted data and can't read the content. No account needed.
- A denied permission only makes that one feature unavailable; the other features keep working.
- Declare the privacy labels on the App Store (iOS) and the Data safety section on Google Play.

## macOS

| Permission | When it's requested | Purpose string |
|---|---|---|
| Notifications | `Onboarding`, after the explanation screen | None; the system dialog |
| Local network (macOS 15+) | `Onboarding`, the first Bonjour browse | `NSLocalNetworkUsageDescription`: "HandLive looks for your Android phone on your Wi-Fi network to connect to it directly, not over the internet." |
| Bluetooth | Turning on "Take Calls on Mac", after `ConsentSheet` | `NSBluetoothAlwaysUsageDescription`: "HandLive connects to your phone over Bluetooth so you can listen and talk during calls on this Mac." |
| Microphone | Right after Bluetooth, in the same flow | `NSMicrophoneUsageDescription`: "HandLive uses the microphone so you can talk during calls transferred from your phone." |
| Camera | Turning on "Use Phone as Webcam" | `NSCameraUsageDescription`: "HandLive brings the picture from your phone into the HandLive Camera virtual camera." |
| Camera extension approval | In the same webcam flow, when the system needs the user to approve it | None; HandLive points the way to the right page in System Settings |
| Virtual microphone driver | In the same webcam flow, when audio is needed | Say beforehand: macOS will ask for an administrator password, and audio cuts out for about 1–2 seconds |
| Paste from Other Apps (macOS 15.4+) | There's no API to request it | Instructions: System Settings › Privacy & Security › Paste from Other Apps |

- Synced with the detailed design (September 25, 2026): AUDIO-01 API 3 requests the microphone
  permission, `NSMicrophoneUsageDescription` is declared in SET-03; AUDIO-02 E7 covers a denial.
- Synced with the detailed design (September 25, 2026): the Bluetooth purpose string in AUDIO-01 API 3
  covers both listening and talking: "HandLive connects to your phone over Bluetooth so you can listen
  and talk during calls on your Mac."

## iOS and iPadOS

| Permission | When it's requested | Notes |
|---|---|---|
| Notifications, including time sensitivity | `Onboarding` | Incoming calls are time-sensitive notifications |
| Local network | `Onboarding` | Same purpose string as on macOS |

- No request for the camera (the Android phone scans the QR code shown on the iPhone or iPad),
  Bluetooth, or the microphone.
- Pasting happens only through `PasteButton`, which is a user action, so iOS doesn't ask for paste
  permission. Synced with the detailed design (September 25, 2026): SET-03 field 11 no longer has the
  sentence about paste permission.

## Android

The permission dialogs belong to Android and stay as they are. Each request covers only the
permissions of one feature.

| Feature | Permission | When it's requested |
|---|---|---|
| General | `POST_NOTIFICATIONS` (Android 13+) | First launch |
| Pairing | `CAMERA` | When the QR code scan screen opens |
| Messages | `READ_SMS`, `SEND_SMS`, `READ_CONTACTS`, `READ_PHONE_STATE` | When Messages is turned on |
| Calls | `READ_PHONE_STATE`, `READ_CALL_LOG`, `ANSWER_PHONE_CALLS`, `READ_CONTACTS` | When Calls is turned on |
| Take Calls on Mac | `BLUETOOTH_CONNECT` (Android 12+); Shizuku for the fallback path | When the feature is turned on |
| Webcam | `CAMERA`, `RECORD_AUDIO` | When Use Phone as Webcam is turned on |
| Auto-sending the clipboard | Accessibility service | After `ConsentSheet` |

For permissions denied for good (Android won't show the dialog again): an "Open Settings" button that
goes to the app info page; don't keep calling the dialog.

## Purpose strings

- One complete, active sentence in sentence case, ending with a period; the subject is "HandLive"; say
  what it does and what for.
- Specific: "HandLive looks for your Android phone on your Wi-Fi network to connect to it directly."
  Not vague: "HandLive needs this permission to work better."
- No commands ("Please allow…"), and no promises about things the app doesn't do.

## Permission primers

- Exactly one "Continue" button; choosing it opens the system dialog. No "Skip", "Cancel", "Not Now", or
  close button; people decline right in the system dialog. HandLive's button never says "Allow".
- Don't imitate the system dialog, don't add arrows pointing at the "Allow" button, and don't reward
  people for agreeing: App Review rejects screens like that.
- Synced with the detailed design (September 25, 2026): SET-03 field 14 now has only "Continue".
- Exception: disclosures that need legal consent (`ConsentSheet`) have two choices.
  - Take Calls on Mac (disclosure version `call-audio-v1`): "Cancel" and "Agree"; "Agree" is the
    default button and isn't red.
  - Accessibility on Android (auto-sending the clipboard): "Agree" and "Send Manually".
- After a denial: the feature shows the reason in `text-orange` text with an "Open Settings" button;
  don't ask again unless the user turns the feature back on themselves.

## End-to-end encryption

- Always on, with no switch to turn it off and no encryption item in Settings.
- Say it in one sentence in `Onboarding`: "Data is end-to-end encrypted and travels only between
  your devices; the server can't read it. No account needed."
- The device details include a "Security Code" (8 characters) so people can compare the two devices
  if they want to.
- Call audio over Bluetooth has only Bluetooth link encryption; `ConsentSheet` says so clearly. The
  Wi-Fi path is still end-to-end encrypted.

## Sensitive clipboard content

- "Block Sensitive Content" is on by default on Android and Mac: content marked as sensitive
  (`EXTRA_IS_SENSITIVE`; `org.nspasteboard.ConcealedType`, `TransientType`, `AutoGeneratedType`) or
  containing a string of digits that looks like a card number isn't sent. The notification "Sensitive
  Content Blocked" has a "Send Anyway" button (valid for 120 s) and doesn't show the content.
- Content sent with "Send Anyway" is marked as sensitive on the receiving side so clipboard managers
  don't save it.
- iPhone, iPad: the app never reads the clipboard on its own; it sends only when the user taps the
  Paste button. Received content stays on this device only (`.localOnly`, not shared through
  Universal Clipboard) and expires according to "Auto-Clear Received Clipboard".
- Never log clipboard content, messages, or phone numbers.

## Message content in notifications

- The option "Show Content in Notifications" (Settings › Messages on Mac, iPhone, iPad) is on by
  default. When it's off, notifications only say "New SMS message".
- When the device is locked or the user hides previews in the system settings, the placeholder "New
  SMS message" is shown (`hiddenPreviewsBodyPlaceholder`).
- Content that goes through the push service is always generic; the real content is decrypted on the
  device.

## Dos and don'ts

| Do | Don't |
|---|---|
| Request Bluetooth when Take Calls on Mac is turned on | Request every permission when the app first opens |
| One "Continue" button on the primer | Add "Skip" to get around the system dialog |
| A specific explanation that ends with a period | "Needs permission for a better experience" |
| Be clear about the limits of Bluetooth | A switch that turns off encryption |
