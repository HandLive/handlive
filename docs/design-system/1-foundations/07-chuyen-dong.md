English | [Tiếng Việt](07-chuyen-dong.vi.md)

# Motion and haptics

In HandLive, motion only signals that something is in progress and points to what just changed;
haptics only confirm important results on iPhone and Android. This section defines springs,
durations, the motion that's allowed, and how to respect Reduce Motion.

HIG source: https://developer.apple.com/design/human-interface-guidelines/motion ·
https://developer.apple.com/design/human-interface-guidelines/playing-haptics

## Principles

- Purposeful, not decorative. Motion is never the only way to convey information: there's always text
  or an icon alongside it.
- Don't add motion to actions people repeat often, such as sending a message or toggling items in a
  list.
- Don't make people wait for an animation: the next action is accepted immediately and the animation
  is interrupted.
- Feedback matches the gesture: what opens with a swipe up closes with a swipe down.
- System controls already have motion and follow Reduce Motion on their own; prefer system controls.

## Springs on Apple platforms

| Type | macOS 14+, iOS 17+ | macOS 13, iOS 16 | Used for |
|---|---|---|---|
| No bounce | `.smooth` | `.spring(response: 0.5, dampingFraction: 1)` | Sheets, `CallPanel`, layout changes |
| Quick, very slight bounce | `.snappy` | `.spring(response: 0.5, dampingFraction: 0.85)` | Small state changes in custom views |
| Bouncy | `.bouncy` | — | Not used |

Liquid Glass has its own motion (morphing between buttons in a `GlassEffectContainer`, a stronger
response to touch than to the trackpad); don't add effects of your own on glass.

## Durations for Android and the web

| Token | Value | Used for | Compose |
|---|---|---|---|
| `duration-quick` | 150 ms | Press, hover, color changes | `tween(150)` |
| `duration-standard` | 250 ms | Switches, segmented controls, state changes | `tween(250)` |
| `duration-emphasized` | 400 ms | Sheets, panels, screen transitions | `tween(400)` |
| `duration-pulse` | 1500 ms | Pulse of the Connecting and Camera live dots | `infiniteRepeatable(tween(1500), RepeatMode.Reverse)` |

- When a fixed duration isn't needed, use `spring(dampingRatio = Spring.DampingRatioNoBouncy)` to get
  close to the feel of Apple's springs.
- The back gesture and predictive back belong to Android: keep them as they are, don't rebuild them.

## Motion HandLive uses

| Motion | Description | With Reduce Motion on |
|---|---|---|
| Connecting pulse | The `status-connecting` dot fades out and back in with `duration-pulse`; the menu bar icon runs variable color. Stops once connected or on an error | The dot and icon stay still; the text "Connecting…" stays |
| Camera live pulse | The dot next to "Live" on `CameraPreview`, with the same rhythm | The dot stays still |
| Menu bar icon | After the clipboard is sent, the icon changes to `checkmark` with Magic Replace, holds for about 1 second, then changes back. Magic Replace is the default style of Replace from macOS 15; for two symbols from different families, the system falls back to a regular replace on its own. Switching between a symbol with and without `.slash` also uses this effect | Changes immediately, no animation |
| Sheet, `CallPanel` appearing | Sheets use the system transition. `CallPanel` slides in gently from the top-right corner and fades in, like a notification | Fade in only |
| State change | The status dot and text change within `duration-standard` | Change immediately |

- Changing symbols: SwiftUI `.contentTransition(.symbolEffect(.replace))`, AppKit
  `NSImageView.setSymbolImage(_:contentTransition:)` (macOS 14, iOS 17). macOS 14 runs the regular
  Replace; macOS 13 swaps the image immediately.
- Not used: background motion, parallax, confetti, flashing, depth zooms, animated blur, looping
  animations when nothing is in progress.

## Reduce Motion

| Platform | Reading the setting |
|---|---|
| SwiftUI | `@Environment(\.accessibilityReduceMotion)` |
| UIKit | `UIAccessibility.isReduceMotionEnabled` |
| AppKit | `NSWorkspace.shared.accessibilityDisplayShouldReduceMotion` |
| Android | `Settings.Global.ANIMATOR_DURATION_SCALE` equals 0 (the user turned off animations in Accessibility) |

When it's on, per the HIG: remove animations that play and repeat on their own; tighten springs so
they don't bounce; replace sliding or zooming transitions with fades; don't animate blur; motion that
follows the user's finger stays. States still change fully; only the motion is removed.

## No timed dismissal

- `CallPanel` closes when the call ends, not on a timer. `Alert`, `ConsentSheet`, and every error
  message with buttons close only when the user makes a choice.
- Confirmation indicators without buttons (the `checkmark` in the menu bar, the HUD-style `Feedback`
  "Sent") may revert on their own after about 1 second (menu bar) or 1.5 seconds (HUD), because they
  hold no actions and aren't the only place that information appears.
- When buttons are needed (Try Again, Send Anyway), use a notification or a status line, not a
  self-hiding HUD.

## Haptics

| Event | iOS | Android API 30+ | Android API 29 |
|---|---|---|---|
| Success: clipboard sent with `PasteButton`, pairing complete | `UINotificationFeedbackGenerator` `.success` | `HapticFeedbackConstants.CONFIRM` | `VIRTUAL_KEY` |
| Needs attention: not connected, will send after reconnecting | `.warning` | No vibration | No vibration |
| Error: sending failed, incorrect PIN | `.error` | `HapticFeedbackConstants.REJECT` | `LONG_PRESS` |

- iOS 17+ can use `.sensoryFeedback(.success, trigger:)`; iOS 16 uses
  `UINotificationFeedbackGenerator`, calling `prepare()` first.
- Android: `View.performHapticFeedback` respects the system vibration settings;
  AndroidX Core's `HapticFeedbackConstantsCompat` falls back to the older constants on API 29.
- macOS: HandLive plays no haptics; Force Touch trackpad feedback is reserved for alignment and drag
  and drop.
- Haptics always come with a visible change. No vibration for each message sent. Don't vibrate for
  incoming calls yourself: the system notification takes care of the ringtone and vibration.

## Dos and don'ts

| Do | Don't |
|---|---|
| A slow pulse for things in progress | Flashing to get attention |
| Fade instead of slide when Reduce Motion is on | Drop the state change altogether |
| Vibrate once when pairing completes | Vibrate for every action |
| Close `CallPanel` when the call ends | Auto-close `CallPanel` after a few seconds |
