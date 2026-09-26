English | [Tiếng Việt](01-macos.vi.md)

# macOS

On the Mac, HandLive is a menu bar app that opens windows when needed. This section defines the app's
structure, how it switches between menu-bar-only mode and Dock mode, the app's menu bar, keyboard
shortcuts, Liquid Glass, and APIs by version (macOS 13 and later).

HIG source: https://developer.apple.com/design/human-interface-guidelines/designing-for-macos ·
https://developer.apple.com/design/human-interface-guidelines/the-menu-bar ·
https://developer.apple.com/design/human-interface-guidelines/windows ·
https://developer.apple.com/design/human-interface-guidelines/panels

## Structure

| Surface | Type | API | Content |
|---|---|---|---|
| Menu bar icon | Menu bar extra | `MenuBarExtra` + `.menuBarExtraStyle(.menu)` | `MenuBarMenu`: status, quick commands, Settings, Quit |
| Messages | Main window | `Window` + `NavigationSplitView` | Sidebar: search field, a "Calls" item (the CALL-04 log), the `ThreadRow` list; right column: `MessageBubble` and the compose field |
| Camera Preview | Secondary window | `Window` | `CameraPreview` |
| Settings | Secondary window | `Settings` | Six panes (Settings section) |
| Welcome | Secondary window, fixed size | `Window` | `Onboarding` |
| Pairing, disclosure, USB debugging guide | Sheet | `sheet(isPresented:onDismiss:content:)` | `PairingCard`, `ConsentSheet`, the CAM-04 wizard |
| Calls | Panel (an exception) | `NSPanel` `.nonactivatingPanel`, `level = .floating`, `collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]`, `hidesOnDeactivate = false` | `CallPanel` |

The "New Message" button sits in the toolbar of the Messages window, not at the bottom of the sidebar.
Don't put important information or buttons at the bottom of a window.

## Activation modes

| When | Mode | What the user sees |
|---|---|---|
| Only the menu bar icon (at launch, `LSUIElement = YES`) | `.accessory` | No Dock icon, no app menu bar |
| The Messages or Camera Preview window is open | `.regular` | Dock icon, the HandLive menu bar, a Dock menu |
| The user turns off "Show HandLive in Menu Bar" | `.regular`, permanently | The Dock is the main way in |
| Both windows above are closed and the menu bar icon is showing | Back to `.accessory` | — |

- Switch with `NSApp.setActivationPolicy(_:)`, then activate the app so the window comes to the front.
- The Settings and Welcome windows don't change the mode. In `.accessory` there's no menu bar, so these
  two windows handle ⌘W and Esc themselves (check on a real Mac).
- Reopening HandLive from Finder, Launchpad, or Spotlight while it's running
  (`applicationShouldHandleReopen(_:hasVisibleWindows:)`): open the Messages window, or the Welcome
  window if the phone isn't paired yet.
- The icon follows the "Show HandLive in Menu Bar" setting (`isInserted`, on by default). The system
  may hide some icons when the menu bar is crowded, so every `MenuBarMenu` command is also available
  somewhere else.

## The app's menu bar (`.regular` mode)

| Menu | HandLive's items (besides the standard items the system creates and localizes) |
|---|---|
| HandLive | "Settings…" ⌘, · "Add Phone…" · "Quit HandLive" ⌘Q |
| File | "New Message" ⌘N · "Close" ⌘W |
| Edit | Standard items (Undo, Cut, Copy, Paste…) · "Send Clipboard to Phone" · Find ⌘F (puts the cursor in the search field at the top of the sidebar) |
| View | Show or hide the sidebar (the label follows the state) · Enter Full Screen |
| Window | Minimize ⌘M · Zoom · "Messages" · "Camera Preview" · Bring All to Front |
| Help | "HandLive Help" |

Items that can't be used yet are dimmed, not hidden; every toolbar button has a command here.

Dock menu (`applicationDockMenu(_:)`): "New Message", "Send Clipboard to Phone", "Camera Preview",
along with the system's list of windows.

## Keyboard shortcuts

| Keys | Action |
|---|---|
| ⌘, | Open Settings |
| ⌘N | New message |
| ⌘W | Close the window; Camera Preview closes without stopping the camera while a meeting app is using it |
| ⌘Q | Quit HandLive |
| ⌘F | Search conversations |
| Return · ⇧Return | Send the message · new line in the compose field |
| Return · Esc · ⌘⌫ | Answer · Ignore (closes the panel and silences the ringing on the Mac, without declining) · Decline — in `CallPanel` |
| 0–9, *, # | Dial digits while the `CallPanel` keypad is open (CALL-03 field 7) |

`CallPanel` doesn't take focus away from the app the user is typing in; the panel's keys only work
after the user clicks the panel.

## Liquid Glass and older versions

- Built with SDK 27: menus, toolbars, sidebars, and sheets turn into glass on macOS 26+ on their own;
  don't use `UIDesignRequiresCompatibility` to avoid it.
- Apply glass yourself only to `CallPanel` (`NSGlassEffectView`) and the `Feedback` HUD. Custom
  controls use `ConcentricRectangle` (26+).
- macOS 13–15: `NSVisualEffectView` `.popover` for `CallPanel`, `.hudWindow` for the HUD; corners use
  the `radius-control-mac` and `radius-panel` tokens (Materials section).

## Controls

- Each window or sheet has one prominent button at the right end of the button row
  (`.borderedProminent`, 26+ `.glassProminent`) with `.keyboardShortcut(.defaultAction)`; other
  buttons are regular push buttons; "Cancel" on the left with `.cancelAction`.
- Buttons that open a window, a sheet, or an alert have "…": "Add Phone…", "Details…", "Unpair…",
  "Decline with Message…".
- Switches and checkboxes go only in the window body, not in the toolbar; menus use checkmarks.
- Icon-only buttons have a `help(_:)` tooltip that starts with a verb and is 60–75 characters or
  shorter.
- The AccentColor is `accent`; when the user chooses an accent color other than Multicolor, controls
  follow it. Colors with a meaning (`call-accept-fill`, `call-decline-fill`, status) don't change with
  the accent color.

## Notifications, Focus, login, restoration

- The Mac doesn't receive push: local notifications through `UNUserNotificationCenter`; messages and
  calls are communication notifications (`INSendMessageIntent`, `INStartCallIntent`), which need the
  Communication Notifications capability and `NSUserActivityTypes` (Notifications section).
- Focus: `INFocusStatusCenter` (entitlement `com.apple.developer.focus-status`, key
  `NSFocusStatusUsageDescription`). When a Focus is on: no panel, no ringing; the call is still in
  `MenuBarMenu`. If the Focus status can't be read, the panel still appears but doesn't ring.
- Never show two layers for one call: while `CallPanel` is showing, the call notification is sent at
  the passive level (into Notification Center, no banner, no sound); when the panel isn't shown
  (Focus), the notification is time-sensitive so the system decides based on the caller and the Focus
  settings. Answering from the notification opens `CallPanel` in the in-call state.
- Open at login: `SMAppService.mainApp.register()` / `unregister()`, always reading the state from
  `status`; with `.requiresApproval`, a button opens `SMAppService.openSystemSettingsLoginItems()`.
- The Mac has no launch screen. On reopening, restore the window frame, the selected conversation, and
  the scroll position; Settings reopens the last pane.

## APIs by version

| API | Since | On macOS 13 |
|---|---|---|
| `MenuBarExtra(_:systemImage:isInserted:content:)`, `Window`, `NavigationSplitView`, `Form` `.grouped`, `SMAppService` | 13 | Available |
| `MenuBarExtra(_:image:isInserted:content:)` | 14 | `if #available` |
| `SettingsLink`, `OpenSettingsAction` | 14 | Needs its own way to open Settings; there's no official API yet |
| `.contentTransition(.symbolEffect(.replace))`, TipKit, `ContentUnavailableView` | 14 | The icon changes without an effect; custom empty states |
| Local network permission | 15 | Not asked |
| `NSPasteboard.accessBehavior` | 15.4 | No paste permission |
| `glassEffect(_:in:)`, `.glassProminent`, `NSGlassEffectView`, `ConcentricRectangle` | 26 | Standard materials |

## Deviations

- Intentional deviation: `CallPanel` floats on every Space and doesn't hide when the app isn't active
  (decision 10).
- Keep a File menu, as in Apple's Messages app ("New Message", "Close"), even though HandLive doesn't
  handle files, so that ⌘N and ⌘W are where people look for them.
- Synced with the detailed design (September 25, 2026): SET-03 (step 6, Special requirements) describes
  switching the activation policy `.accessory` ↔ `.regular`; SET-02 field 31 `mac.menu_bar_extra`.
- Synced with the detailed design (September 25, 2026): CALL-04 field 1 puts the call log in the
  sidebar of the Messages window; CAM-03 uses the Camera submenu in `MenuBarMenu` and the Camera
  Preview window.

## Dos and don'ts

| Do | Don't |
|---|---|
| Put every command in the app's menu bar and the Dock menu | Rely on the menu bar icon always being visible |
| Use the system's windows, sheets, and controls | Draw your own window frame or close and minimize buttons |
