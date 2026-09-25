English | [Tiếng Việt](README.vi.md)

# PermissionPrimer

A short explanation screen shown right before the system's permission dialog. Per the HIG:
**exactly one "Continue" button**, with no "Skip", "Cancel", or close button — people agree or decline
in the system dialog that comes right after.

Synced with the detailed design (September 25, 2026): SET-03 field 14 now has only "Continue". Steps
that don't request a permission (for example, the manufacturer's autostart instructions on Android)
still have "Skip".

## When it appears

Only when the system dialog alone doesn't give enough context, and only when the user is about to use
the feature that needs the permission. Initial setup asks only for the permissions the app needs to
run.

| Permission | Platform | When it's asked | Screen title |
|-------|---------|---------|------------|
| Local network | macOS, iOS | Initial setup | "Find Your Phone on Wi-Fi" |
| Notifications | macOS, iOS | Initial setup | "Get Notified About Messages and Calls" |
| Bluetooth, microphone | macOS | When Call Audio on Mac is turned on, after `ConsentSheet` | "Connect to Your Phone over Bluetooth" |
| SMS, phone, contacts, notifications | Android | When the corresponding feature is turned on (during initial setup if the user chooses to turn it on) | "Read and Send Messages from Your Computer"… |
| Camera, microphone | Android | The first time the Mac asks to use the camera | "Use the Camera for Meetings on Your Mac" |

## Anatomy

A large icon in an `accent-tint` circle, a bold `ios-title-2` title (Mac `mac-title-2`), one or two
sentences on the benefit and where the data goes, a sentence saying the system will ask in the next
step, and a prominent full-width "Continue" button. Small print at the bottom: "You can change this in
Settings at any time."

Permission already denied: this screen doesn't appear anymore; in Settings, the feature's row shows the
reason in `text-orange` and an "Open Settings" button that goes straight to the app's page in the
system settings.

## Dos and don'ts

- Do write purpose strings that are active, in sentence case, and end with a period: "HandLive looks
  for your Android phone on your Wi-Fi network to connect to it directly, without going through the
  internet."
- Don't use the label "Allow" on the primer (that label belongs to the system dialog); don't redraw the
  system dialog; don't promise rewards in exchange for a permission.
