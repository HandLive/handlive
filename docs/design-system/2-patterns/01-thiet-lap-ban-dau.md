English | [Tiếng Việt](01-thiet-lap-ban-dau.vi.md)

# Onboarding

This section defines the first launch on each platform: a short welcome, only the permissions the app
needs to run, pairing with a QR code, and then into the app. Each feature's permissions wait until
that feature is used.

HIG source: https://developer.apple.com/design/human-interface-guidelines/onboarding ·
https://developer.apple.com/design/human-interface-guidelines/launching ·
https://developer.apple.com/design/human-interface-guidelines/privacy#Requesting-permission

## Principles

- Short, and teaching through real tasks: the pairing step is the tutorial. Mac and iPhone: at most 6
  screens (SET-03); Android: at most 5 screens before pairing (SET-01); done within 60 s.
- Talk only about HandLive; don't teach people how to use their device. Contextual tips (TipKit, iOS
  17 and macOS 14 or later) take the place of a series of tutorial screens.
- Ask here only for the permissions needed to run: notifications and local network (Mac, iPhone);
  notifications and background activity (Android). The Mac's Bluetooth and microphone permissions are
  requested when "Call Audio on Mac" is turned on; the camera permission and the Camera Extension when
  "Use Phone as Webcam" is turned on; Android's SMS and call permissions on the feature cards after the
  first pairing. Details in Requesting permission.
- Permission primers have no "Skip"; people decline in the system dialog. "Skip" appears only on steps
  that don't open a system dialog, for example the manufacturer-specific autostart instructions.
- Closing midway still lets people into the app: the empty state invites them to "Pair Phone…"
  (Android: "Add Device"). Steps already completed are skipped automatically; the next launch picks up
  from the first missing step.
- The launch screen carries no branding. iOS: a plain `system-background`, no text, no logo. macOS has
  no launch screen. Android 12+: keep the system splash screen (the app icon on `system-background`),
  with no added text. The brand (`wordmark`, `brand-large-title`, the `brand-glow` background) appears
  only on the Welcome, pairing, and Paired screens.

## Steps

### macOS

On first launch, the menu bar icon shows "Not paired" and the welcome window opens in front.

| # | Screen | Content | Buttons |
|---|-----|----------|-----|
| 1 | Welcome | "Welcome to HandLive", feature rows with a privacy summary: end-to-end encrypted, travels only between your devices, no account needed | "Get Started" |
| 2 | Move to the Applications folder (when needed) | "The virtual camera only works when HandLive is in the Applications folder." | "Not Now", "Move" |
| 3 | Notifications | `PermissionPrimer` | "Continue" |
| 4 | Local network (macOS 15+) | `PermissionPrimer` | "Continue" |
| 5 | Menu bar | Checkboxes "Show HandLive in Menu Bar" and "Open HandLive at Login", checked by default; caption "When this is off, HandLive appears in the Dock." | "Continue" |
| 6 | Paste from Other Apps (macOS 15.4+, when needed) | Instructions for choosing Always Allow (C10) | "Open System Settings", "Continue" |
| 7 | Pairing | `PairingCard` sheet over the welcome window | "Cancel" |
| 8 | Paired | The phone's name, three things you can do right away (copy and paste, messages, calls), where HandLive lives in the menu bar | "Done" |

Unchecking "Show HandLive in Menu Bar" immediately switches the app to having a Dock icon (see macOS).

### iOS and iPadOS

| # | Screen | Content | Buttons |
|---|-----|----------|-----|
| 1 | Welcome | Title and privacy summary, as on the Mac | "Get Started" |
| 2 | Notifications | `PermissionPrimer`: when HandLive is closed, incoming SMS and calls can reach you only through notifications | "Continue" |
| 3 | Local network | `PermissionPrimer` | "Continue" |
| 4 | Pairing | `PairingCard` sheet: iPhone and iPad show the QR code, no camera permission needed | "Cancel" |
| 5 | Paired | The phone's name and the limits: the clipboard syncs while HandLive is open; when the app is closed, incoming SMS and calls arrive as notifications; iPhone and iPad can't take call audio | "Done" |

### Android

| # | Screen | Content | Buttons |
|---|-----|----------|-----|
| 1 | Welcome | The phone's role as the hub, a privacy summary (SET-01 field 1) | "Get Started" |
| 2 | Notifications (Android 13+) | `PermissionPrimer`, then the system dialog | "Continue" |
| 3 | Background activity | `PermissionPrimer`, then the battery optimization exemption dialog; on Android 11+, suggest turning off "Pause app activity if unused" | "Continue" |
| 4 | Autostart (Xiaomi, OPPO, Samsung…) | Manufacturer-specific instructions (SET-01 API 5) | "Open Manufacturer Settings", "Done", "Skip" |
| 5 | Pair device | "Scan QR Code" (the camera permission is explained right before the scanner) or "Enter PIN" | — |
| 6 | Confirm | "Pair with Lan's MacBook?" with the Security Code | "Cancel", "Pair" |
| 7 | Paired | Feature cards (SET-01 field 10) with "Grant Access" for SMS, calls, and auto-sending the clipboard | "Done" |

## Components

| Component | Role |
|------------|---------|
| `Onboarding` | The welcome screen: a `brand-large-title` title, feature rows, the link "HandLive and Your Privacy", one primary button |
| `PermissionPrimer` | The explanation screen before the system dialog, with exactly one "Continue" button |
| `PairingCard` | QR code in `qr-ink` on `qr-paper`, `size-qr` on a side on the Mac, the countdown "Code changes in 1:42", "Can't Scan? Use a PIN" |
| `ConsentSheet` | The Accessibility disclosure on Android, opened from the auto-send clipboard card |

## Pairing (PAIR-01)

- The Mac and iPhone/iPad show the QR code; Android scans it. The code refreshes itself after 120 s.
- The 6-digit PIN is the fallback, usable only on the same Wi-Fi network; it's shown in `code-pin`, in
  groups of three digits "482 915"; after more than 3 wrong attempts, a new code is generated.
- Errors show right inside the sheet, not as an alert: "Couldn't pair securely. Try again." (E4). When
  the code expires, a new one replaces it automatically, with no error.
- Once paired: the sheet closes itself, and both devices show "Paired with <name>". This is a Delight
  moment: an illustration on `brand-glow`, a `success` haptic on iPhone; with Reduce Motion on, drop
  the motion but keep the content. During onboarding, the Paired screen takes the place of the
  `Feedback` HUD; pairing again from Settings shows only the HUD.

## Deviations

- Synced with the detailed design (September 25, 2026): SET-03 field 14 now has only "Continue"
  (decision 11).
- Synced with the detailed design (September 25, 2026): SET-03 puts the two checkboxes "Open HandLive
  at Login" (field 3) and "Show HandLive in Menu Bar" (field 16) on the welcome screen; the Menu bar
  screen in the step table above is an equivalent presentation — when building the UI, follow SET-03.
- Synced with the detailed design (September 25, 2026): SET-03 field 11 drops the sentence about
  paste permission and says clearly that sending uses the Paste button (CLIP-04); the limits still
  appear at step 11 of SET-03.
- Synced with the detailed design (September 25, 2026): SET-01 field 6 uses "Continue"; PAIR-01 field 5
  uses "Pair" / "Cancel".
- The Vietnamese detailed design writes "huỷ, xoá, tuỳ"; the Vietnamese version of this section uses
  the Apple style "hủy, xóa, tùy".

## Dos and don'ts

| Do | Don't |
|-----|-----------|
| Get people to the pairing step in ≤ 3 taps | A series of feature introduction screens |
| Ask for a permission once people understand why it's needed | Ask for every permission as soon as the app opens |
| Let people into the app even before pairing | Lock the app until pairing is done |
| Be upfront about the limits of iPhone and iPad | Promise features the platform doesn't allow |
