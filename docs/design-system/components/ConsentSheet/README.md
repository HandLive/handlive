English | [Tiếng Việt](README.vi.md)

# ConsentSheet

A disclosure sheet the user must agree to before turning on a feature with legal or privacy
consequences. It's the only exception allowed to offer two choices before a system dialog (the HIG
allows this when legal consent is needed). The choice and the version of the text are recorded.

| Where it's used | Platform | Recorded in |
|----------|---------|---------|
| Take Calls on Mac (AUDIO-01, text `call-audio-v1`) | macOS — a sheet attached to the Settings window | `consent_record` |
| Auto-Send on Copy, through Accessibility (CLIP-01) | Android — a sheet that rises from the bottom | `clip.a11y_consent_at` |

## Content

- The title is the feature's name ("Take Calls on Mac"), not "Warning".
- Three to five feature rows, each with an SF Symbol in `accent` and one sentence: what HandLive does,
  what HandLive doesn't do, and the user's responsibility.
- For Take Calls on Mac, it must say: audio travels only between your devices; nothing is recorded; you
  tell the other person where the law requires consent from both parties (California, Florida,
  Illinois…); over Bluetooth there's only Bluetooth's encryption, while over Wi-Fi it's end-to-end
  encrypted.
- Two buttons: on the Mac (call audio), "Cancel" and "Agree" — "Agree" is the default, on the right; on
  Android (Accessibility), "Send Manually" and "Agree" — "Agree" is full width at the bottom. Synced
  with the detailed design (September 25, 2026): CLIP-01 field 3 says "Send Manually". Only after the
  user agrees does the system permission dialog come (Bluetooth, microphone; the Accessibility settings
  on Android).

## By platform

- **macOS:** `.sheet` on the Settings window, ~460 pt wide, with the parent window dimmed; Esc =
  Cancel, Return = Agree.
- **Android:** a sheet with a drag handle, `radius-sheet` corners, a `system-background` background;
  swipe down = Cancel. Installs from outside Google Play on Android 13+ add an "Allow restricted
  settings" step.
- **iOS:** not available (the iPhone doesn't take call audio and has no Android-style Accessibility
  service).

## Dos and don'ts

- Do write short, plain sentences; don't bold whole paragraphs, and don't hide conditions in small
  print.
- Don't preselect agreement, and don't add an "I have read this" checkbox.
- When the disclosure's content changes, bump the version (`call-audio-v2`) and ask again.
