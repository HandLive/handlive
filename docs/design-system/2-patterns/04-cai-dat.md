English | [Tiếng Việt](04-cai-dat.vi.md)

# Settings

This section defines the Settings screens on each platform: a multi-pane window on the Mac, a Settings
tab with a grouped list on iPhone, iPad, and Android, and the exact labels of the SET-02 keys. Settings
belong to each device and don't sync to other devices; the other side only learns about them through
capabilities.

HIG source: https://developer.apple.com/design/human-interface-guidelines/settings ·
https://developer.apple.com/design/human-interface-guidelines/toggles

## General rules

- Few settings, good defaults (0.9.5); an option tied to a task lives right where that task happens.
- Changes take effect immediately, with no "Apply" button. Keys that affect capabilities send
  `capability/update`; the other side applies them within ≤ 1 s on the same Wi-Fi network.
- The label says what happens when the setting is on; the caption under the group states the
  consequences.
- Turning on a feature that needs an activation flow (`ConsentSheet` for Take Calls on Mac, CAM-01,
  the Accessibility disclosure): the switch only turns fully on once the flow is complete. Turning off
  a feature that's running (the camera is streaming, call audio is on the Mac) asks for confirmation
  with an `Alert` (SET-02 E9).
- Don't duplicate system settings (appearance, text size); link to them with a button.
- Destructive actions go in the last group, always through an `Alert`. Buttons that open an alert or a
  sheet have "…" on the Mac, but not on iPhone or Android.

## macOS: the Settings window

- Opened with ⌘, or "Settings…" in the HandLive menu and in `MenuBarMenu`, not with a toolbar button.
  `Settings` scene; `SettingsLink` exists only from macOS 14.
- The pane toolbar isn't customizable, is always visible, and always highlights the open pane; the
  window title is the pane's name; reopening shows the last pane viewed.
- The minimize and zoom buttons are dimmed; the window resizes to fit the pane.
- Each pane is a `Form` with `.formStyle(.grouped)`. Main features use mini switches
  (`.toggleStyle(.switch)` + `.controlSize(.mini)`); secondary options use checkboxes indented beneath
  them, dimmed while the main feature is off. Group captions use the `mac-footnote` style.

| Pane | Rows (type · key) |
|---|---|
| General `gearshape` | Switch "Show HandLive in Menu Bar" (when off, the app has a Dock icon) · switch "Open HandLive at Login" (`SMAppService`) · switch "Internet Connection" (`relay.enabled`) · button "Remove Device from Server…" · destructive button "Delete All HandLive Data…" |
| Devices `candybarphone` | The phone's `DeviceRow` with "Details…" and "Unpair…"; if there's none yet, "Add Phone…" (PAIR-02) |
| Clipboard `doc.on.clipboard` | Switch "Sync Clipboard" (`feature.clipboard`) › checkboxes "Sync Images" (`clip.send_images`), "Block Sensitive Content" (`clip.block_sensitive`) · pop-up "Auto-Clear Received Clipboard": Off, After 1 Minute, After 5 Minutes (`clip.auto_clear_s`), caption "Clears only content received from other devices, and only if you haven't copied anything new." · macOS 15.4+: a "Paste from Other Apps" row with "Open System Settings" (CLIP-02 fields 2–3) |
| Messages `message` | Switch "SMS Messages" (`feature.sms`) › checkbox "New SMS Notifications" (`sms.notify`) › checkbox "Show Content in Notifications" (`sms.preview`) · "Last synced: 5 minutes ago" and the button "Resync All SMS…" · caption "Marking as read on this device doesn't change the status on the phone." |
| Calls `phone` | Switch "Calls" (`feature.call`) › checkboxes "Call Notifications" (`call.notify`), "Ring on Mac" (`call.ringtone`) · the "Quick Replies" list, up to 6 templates (`call.quick_replies`) · switch "Take Calls on Mac" (`feature.call_audio`) › pop-up "Phone for Bluetooth" (`call_audio.phone_bt_address`), checkbox "Wi-Fi Fallback (Requires Shizuku)" (`call_audio.allow_opus_fallback`), the AUDIO-01 step 12 checklist |
| Camera `web.camera` | Switch "Use Phone as Webcam" (`feature.camera`) › the CAM-01 checklist with "Install Microphone Driver" · pop-up "Default Camera": Front Camera, Back Camera (`cam.default_camera`) · pop-up "Default Quality": Automatic, 480p, 720p, 1080p (`cam.default_quality`) · checkbox "Automatic USB Boost" (`cam.usb_boost`) · button "Show USB Debugging Guide Again" (`cam.usb_wizard_dismissed`) · button "Remove Virtual Camera and Microphone…" |

Confirmation for "Resync All SMS…": "Delete messages saved on Lan's MacBook and download them again from
the phone? Messages waiting to be sent are kept." with "Cancel" and "Resync" (SMS-01 field 6).

## iOS and iPadOS: the Settings tab

- A `List` with the `.insetGrouped` style (`GroupedList`), large title "Settings"; group headers in
  sentence case, and on iOS 16–18 set `.textCase(nil)` so they aren't uppercased.
- Group order: Phone (`DeviceRow`, opens the PAIR-02 details) · Clipboard ("Sync Clipboard", "Sync
  Images", "Auto-Clear Received Clipboard" opening a choice list with checkmarks) · Messages ("SMS
  Messages", "New SMS Notifications", "Show Content in Notifications", "Resync All SMS") · Calls
  ("Calls", "Call Notifications") · "Internet Connection" · Permissions ("Notifications", "Local
  Network", values On/Off) · Data ("Remove Device from Server", "Delete All HandLive Data").
- No "Block Sensitive Content": the iPhone only sends when the user taps Paste (QC3).
- Permission turned off: the row shows a reason in `text-orange` and "Open Settings"
  (`UIApplication.openSettingsURLString`). Time-sensitive turned off: "Focus may silence call
  notifications" (SET-03 field 8).

## Android: the Settings tab

- The same Apple-style grouped list (`HLGroupedList`, `HLSwitch` in `system-green`) with Android's
  keys: "Sync Clipboard", "Auto-Send on Copy" (`clip.auto_send`, caption "Agreed on Sep 24, 2026
  at 2:05 PM"), "Sync Images", "Block Sensitive Content", "Auto-Clear Received Clipboard", "SMS
  Messages", "Calls", "Take Calls on Mac" and "Wi-Fi Fallback (Requires Shizuku)" with the Shizuku
  status, "Use Phone as Webcam", "Internet Connection", the Data group.
- The "Permissions & Background" row opens the per-feature cards (SET-01 field 10) and the
  background status (fields 6–9).
- Link straight to the system pages instead of rebuilding them: app info
  `ACTION_APPLICATION_DETAILS_SETTINGS`; notifications `ACTION_APP_NOTIFICATION_SETTINGS`, individual
  channels `ACTION_CHANNEL_NOTIFICATION_SETTINGS`; `ACTION_ACCESSIBILITY_SETTINGS`; the battery
  optimization exemption. When a permission is denied, the key still stores `true` and the row shows
  the reason (SET-02 E2).

## When a feature isn't available yet

A feature only takes effect when it's on at both ends and the phone has the permissions it needs. The
reason sits under the row title in `text-orange`; the switch is disabled but stays visible.

| Cause | Text | Action |
|---|---|---|
| Off on the other device | "Off on Lan's Pixel 8" | — |
| Permission missing on the phone | "Missing SMS permission on the phone" | "View Instructions" (Mac, iPhone), "Grant Permission" (Android) |
| Relay off on the other side | "Internet connection is off on the phone" | — |
| Auto-send off on the phone | "Auto-send is off on the phone — use the Send Clipboard button on the phone" | — |
| Camera while connected over the internet | "Requires the same Wi-Fi network or a USB cable" | — |

## Deviations

- Synced with the detailed design (September 25, 2026): the SET-02 labels "Sync Clipboard",
  "Auto-Clear Received Clipboard".
- Synced with the detailed design (September 25, 2026): SET-02 field 14 "Wi-Fi Fallback, Requires
  Shizuku". Still to sync: AUDIO-01 step 1 names the pane "Call Audio" (design system: the Calls pane);
  "Switch to USB When Plugged In" (field 19) should follow CAM-04: "Automatic USB Boost".
- Synced with the detailed design (September 25, 2026): the `mac.menu_bar_extra` key (SET-02 field 31,
  0.9.5).

## Dos and don'ts

| Do | Don't |
|---|---|
| Save as soon as a switch is flipped | A "Save" or "Apply" button |
| State the reason and the fix right under the row | Disable a switch without explaining why |
