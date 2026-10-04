English | [Tiếng Việt](README.vi.md)

# Screenshots

Screens of the HandLive apps as of 2026-09-27 (Phase 3 in progress, android `e495907`, apple `2edd00c`; iPhone Messages list and New Message on both platforms: apple `2fd87b3`). Every screen exists in English and Vietnamese: files end in `.en.png` or `.vi.png`. All names, numbers and devices are fictional (+1 201 555 01xx, "E2E Test Mac").

The three welcome screens were captured again on 2026-10-04 with the brand mark (android `41f13c3`, apple `8ecd350`).

## Android

Real app on an Android 15 emulator, paired with the fake Mac of `shared/tools/e2e`. The Android app has no SMS or call screens: SMS and calls are shown on the Mac and iPhone, and a ringing call uses Android's own dialer.

| | | | |
|---|---|---|---|
| <img src="android/01-welcome.en.png" alt="Welcome: end-to-end encrypted, no account needed." width="200"> | <img src="android/02-sms-permission-primer.en.png" alt="HandLive explains why it needs SMS permissions before Android asks." width="200"> | <img src="android/03-pair-a-device.en.png" alt="Pair with a Mac or iPhone by QR code or PIN." width="200"> | <img src="android/04-devices-connected.en.png" alt="The paired Mac, connected over Wi-Fi." width="200"> |
| Welcome: end-to-end encrypted, no account needed. | HandLive explains why it needs SMS permissions before Android asks. | Pair with a Mac or iPhone by QR code or PIN. | The paired Mac, connected over Wi-Fi. |
| <img src="android/05-device-details.en.png" alt="Model, last connection, features and Security Code." width="200"> | <img src="android/07-auto-send-consent.en.png" alt="What the Accessibility service does before auto-send is turned on." width="200"> | <img src="android/08-settings.en.png" alt="Clipboard, SMS, calls and Internet connection settings." width="200"> |  |
| Model, last connection, features and Security Code. | What the Accessibility service does before auto-send is turned on. | Clipboard, SMS, calls and Internet connection settings. |  |

<img src="android/06-service-notification.en.png" alt="The service notification on Android: connected to the Mac, with a Send Clipboard button." width="540">

The service notification on Android: connected to the Mac, with a Send Clipboard button.

## iPhone and iPad

Real `HLiOSUI` views in a harness app on the iOS 27 Simulator, with sample data written through the real stores. They are not taken from a device paired with a real phone.

| | | | |
|---|---|---|---|
| <img src="ios/01-welcome.en.png" alt="First run: what HandLive does and how it protects your data." width="200"> | <img src="ios/02-pairing-qr.en.png" alt="Pair with the Android phone by QR code, or use a PIN." width="200"> | <img src="ios/03-clipboard.en.png" alt="Paste to send; the last clip from the phone is ready to copy." width="200"> | <img src="ios/04-sms-conversation.en.png" alt="Read and reply to the phone's SMS messages." width="200"> |
| First run: what HandLive does and how it protects your data. | Pair with the Android phone by QR code, or use a PIN. | Paste to send; the last clip from the phone is ready to copy. | Read and reply to the phone's SMS messages. |
| <img src="ios/05-calls.en.png" alt="The phone's call log, missed calls in red." width="200"> | <img src="ios/06-incoming-call-banner.en.png" alt="An incoming call shows a banner with Decline." width="200"> | <img src="ios/07-settings.en.png" alt="Turn each feature on or off separately." width="200"> | <img src="ios/08-phone-details.en.png" alt="The paired phone: connection, features, Security Code, Unpair." width="200"> |
| The phone's call log, missed calls in red. | An incoming call shows a banner with Decline. | Turn each feature on or off separately. | The paired phone: connection, features, Security Code, Unpair. |
| <img src="ios/10-messages-list.en.png" alt="The conversation list with the All / Unread filter; unread conversations have a dot." width="200"> | <img src="ios/11-new-message.en.png" alt="New Message: type the phone number after To:." width="200"> |  |  |
| The conversation list with the All / Unread filter; unread conversations have a dot. | New Message: type the phone number after To:. |  |  |

## Mac

Real `HLMacUI` windows and views in a harness app on macOS 27, with sample data; each window captured itself. The menu bar menu is not shown: it exists only while open, and this session had no Screen Recording permission.

| | |
|---|---|
| <img src="macos/01-welcome.en.png" alt="First run: Open at Login and the menu bar icon." width="400"> | <img src="macos/02-pairing-qr.en.png" alt="Scan the QR code with HandLive on the Android phone, or use a PIN." width="400"> |
| First run: Open at Login and the menu bar icon. | Scan the QR code with HandLive on the Android phone, or use a PIN. |
| <img src="macos/03-messages-window.en.png" alt="SMS conversations and the call log in one window." width="400"> | <img src="macos/04-incoming-call-panel.en.png" alt="Floating panel for an incoming call: Answer, Decline or Ignore." width="400"> |
| SMS conversations and the call log in one window. | Floating panel for an incoming call: Answer, Decline or Ignore. |
| <img src="macos/05-new-message.en.png" alt="New Message in the Messages window." width="400"> |  |
| New Message in the Messages window. |  |

## Dark Mode and iPad

| | | |
|---|---|---|
| <img src="android/05-device-details-dark.en.png" alt="Android: device details" width="200"> | <img src="ios/04-sms-conversation-dark.en.png" alt="iPhone: conversation" width="200"> | <img src="ios/09-ipad-messages.en.png" alt="iPad: conversation list and conversation side by side" width="400"> |
| Android: device details | iPhone: conversation | iPad: conversation list and conversation side by side |

## Known issues seen while capturing

- Android pairing: when the Mac connects while the PIN is still being typed, the phone switches to Pairing… and the PIN can no longer be entered (PAIR-01 A3–A4).

To refresh: rerun the same flows on the next build and replace files with the same names.
