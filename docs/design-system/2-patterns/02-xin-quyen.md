English | [Tiếng Việt](02-xin-quyen.vi.md)

# Requesting permission

This section defines when each permission is requested, with which explanation, and what the
interface looks like after a denial. Each permission belongs to one feature; a missing permission for
one feature doesn't break any other feature.

HIG source:
https://developer.apple.com/design/human-interface-guidelines/privacy#Requesting-permission ·
https://developer.apple.com/design/human-interface-guidelines/privacy#Pre-alert-screens-windows-or-views

## Rules

- Ask when people are about to use the feature; initial setup asks only for the permissions the app
  needs to run; one feature at a time.
- `PermissionPrimer` appears right before the system dialog when the dialog alone doesn't give enough
  context: a title, one or two sentences on the benefit and where the data goes, and exactly one
  "Continue" button that opens the dialog. No "Skip", no "Cancel", no close button, no label that looks
  like "Allow".
- Android always has a primer: the runtime dialog doesn't let apps add text, so the primer is the only
  explanation.
- Purpose strings on Apple platforms: one active, specific sentence that ends with a period and starts
  with "HandLive".
- Don't ask again automatically after a denial; no rewards and no threats in exchange for a
  permission.

## Permission table

| Permission | Platform | When it's requested | Primer | Purpose string or system permission |
|---|---|---|---|---|
| Notifications | macOS, iOS | Initial setup | "Get Notified About Messages and Calls" | No purpose string; `requestAuthorization(options: [.alert, .sound, .badge])`. Time-sensitive comes with the entitlement, not with a separate request |
| Local network | iOS, macOS 15+ | Initial setup | "Find Your Phone on Wi-Fi" | `NSLocalNetworkUsageDescription`: "HandLive looks for your Android phone on your Wi-Fi network to connect to it directly, not over the internet." |
| Notifications | Android 13+ | Initial setup | "Notifications show the connection status and let you confirm requests from your Mac, such as turning on the camera." | `POST_NOTIFICATIONS` |
| Background activity | Android | Initial setup | "So your Mac and iPhone can always reach this phone, HandLive needs to run in the background without being stopped by the system." | The battery optimization exemption dialog |
| Camera (QR scanning) | Android | Tapping "Scan QR Code" | Proposed: "HandLive uses the camera to scan the QR code on your Mac, iPhone, or iPad." | `CAMERA`; if denied, use "Enter PIN" |
| SMS | Android | The feature card after the first pairing, or when "SMS Messages" is turned on | "To view and reply to SMS messages on your Mac or iPhone, HandLive needs to read and send SMS, read your contacts to show sender names, and read the phone state to choose a SIM." | `READ_SMS`, `SEND_SMS`, `READ_CONTACTS`, `READ_PHONE_STATE` |
| Calls | Android | Like SMS, when "Calls" is turned on | Proposed: "To announce incoming calls and let you answer or decline them on your Mac, HandLive needs to read the phone state, the call log, and your contacts." | `READ_PHONE_STATE`, `READ_CALL_LOG`, `ANSWER_PHONE_CALLS`, `READ_CONTACTS` |
| Auto-sending the clipboard | Android | Turning on "Auto-Send on Copy" | `ConsentSheet` (CLIP-01 field 2) | The service in Settings › Accessibility |
| Bluetooth, microphone | macOS | Turning on "Take Calls on Mac", right after `ConsentSheet` | "Connect to Your Phone over Bluetooth" | `NSBluetoothAlwaysUsageDescription`: "HandLive connects to your phone over Bluetooth so you can listen and talk during calls on this Mac." · `NSMicrophoneUsageDescription`: "HandLive uses the microphone so you can talk during calls transferred from your phone." |
| Nearby devices | Android 12+ | Turning on "Take Calls on Mac" on the phone | Proposed: "To move call audio to your Mac, HandLive needs to connect to the Mac over Bluetooth." | `BLUETOOTH_CONNECT` (granted at install time on Android 10–11) |
| Focus status | macOS | Turning on "Ring on Mac" | Not needed | `NSFocusStatusUsageDescription`: "HandLive reads your Focus status so it doesn't ring or show calls while a Focus is on." Until it's allowed, the Mac doesn't ring |
| Camera | macOS | Turning on "Use Phone as Webcam" (CAM-01 step 3) | The CAM-01 checklist | `NSCameraUsageDescription`: "HandLive brings the picture from your phone into the HandLive Camera virtual camera." |
| Camera, microphone | Android | Turning on "Use Phone as Webcam" on the phone (usually right after the Mac turns it on) | "Use the Camera for Meetings on Your Mac" | `CAMERA`, `RECORD_AUDIO` |

iPhone and iPad request neither the camera permission (they only show the QR code) nor the paste
permission (`PasteButton`).

Not permission dialogs, only instructions with a button that opens the right page: the Camera
Extension (CAM-01 field 5), the virtual microphone driver (CAM-01 field 8), Paste from Other Apps on
macOS 15.4+ (C10), login items that need approval (`SMAppService.openSystemSettingsLoginItems()`), the
Shizuku permission (AUDIO-01 step 10).

## After a denial

- The feature stays on but can't be used yet. Its row in Settings shows the reason in `text-orange`
  and one button: on the Mac "Open System Settings", on iOS and Android "Open Settings".
- Destinations: Mac `x-apple.systempreferences:com.apple.preference.security?Privacy_Bluetooth` and
  the matching pages; iOS `UIApplication.openSettingsURLString`, `openNotificationSettingsURLString`;
  Android `ACTION_APPLICATION_DETAILS_SETTINGS`, `ACTION_APP_NOTIFICATION_SETTINGS`,
  `ACTION_ACCESSIBILITY_SETTINGS`.
- Android doesn't report a permanent denial: infer it from `perm.requested` and
  `shouldShowRequestPermissionRationale` (Android 11+ blocks the dialog on its own after two denials).
  From then on, don't call the dialog; show "Open Settings" instead.
- The Mac and iPhone see the permissions missing on the phone (`permissions_missing`) on the Devices
  page, for example "Missing SMS permission on the phone"; the phone posts a suggestion notification
  at most once per feature every 24 h (SET-01 field 17).

## Android specifics

- The runtime dialog is system UI: don't redraw it or cover it. The system groups permissions: SMS,
  Contacts, Phone, Call logs, Camera, Microphone, Nearby devices.
- Accessibility goes through the full-screen `ConsentSheet`; only after "Agree" does Settings ›
  Accessibility open. The disclosure mentions in advance the system toast "HandLive pasted from your
  clipboard" (Android 12+).
- Installs from outside Google Play on Android 13+: before opening Accessibility, walk people through
  "Restricted setting": Settings › Apps › HandLive › ⋮ › "Allow restricted settings" (SET-01 API 6).

## Two choices: only in ConsentSheet

| Disclosure | Platform | Choices | Recorded in |
|---|---|---|---|
| Take Calls on Mac (`call-audio-v1`) | macOS | "Cancel" (left) · "Agree" (right, default, not red) | `consent_record` |
| Auto-Send on Copy (CLIP-01 field 3) | Android | "Send Manually" · "Agree" (the detailed design says "No, I'll send manually"; a button should start with a verb) | `clip.a11y_consent_at` |

Nothing is preselected. When the disclosure's content changes, bump the text version and ask again.

## Deviations

- Synced with the detailed design (September 25, 2026): SET-03 field 14 now has only "Continue"
  (decision 11).
- Synced with the detailed design (September 25, 2026): AUDIO-01 requests the microphone permission
  together with Bluetooth (API 3), `NSMicrophoneUsageDescription` is declared in SET-03; AUDIO-02 E7
  and AUDIO-04 condition 6 say clearly that after a denial the call is listen-only.
- Synced with the detailed design (September 25, 2026): CALL-01 API 5 and SET-03 declare
  `NSFocusStatusUsageDescription`. Still to sync: the Android sentences marked "Proposed" go into
  SET-01 API 2.
- Synced with the detailed design (September 25, 2026): SET-03 step 7 only says that incoming calls
  use the time-sensitive level "so they arrive in time"; the Mac respects Focus (decision 10).
- Synced with the detailed design (September 25, 2026): the detailed design writes "Quyền riêng tư &
  Bảo mật" (Privacy & Security) following Apple's Vietnamese localization; the implementation plan
  includes a task to check system section names on real devices. Apple-style tone marks have been
  applied to the detailed design.

## Dos and don'ts

| Do | Don't |
|---|---|
| State the benefit and where data goes in one or two sentences | Write "for a better experience" |
| Let people answer in the system dialog | Add a "Not Now" button to the primer |
| Keep other features working when one permission is denied | Block the whole app over one missing permission |
