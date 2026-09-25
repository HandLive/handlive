English | [Tiếng Việt](README.vi.md)

# CameraPreview

The "Camera Preview" window on the Mac while the phone works as a webcam (CAM-02…05): the picture from
the phone, the session status, the transport, and the controls. The quick controls are also in
`MenuBarMenu`.

## Anatomy

| Part | Specification |
|------|---------|
| Video frame | `video-background`, 16:9, `radius-card` corners; while waiting: "Waiting for the phone…"; with the video paused: "Video paused" |
| Status (top left) | A glass pill: a pulsing dot + "Live" · "Via Wi-Fi" or "Via USB"; other states: "Requesting…", "Tap Turn On on the phone", "Starting…", "Stopping…", "Error" |
| Control bar (bottom, floating over the picture) | **Clear** glass with a 35% dark layer (`glass-dim`), because it sits over video: `SegmentedControl` "Front / Back" (hidden when the phone has one camera), a microphone on/off button, a pause video button, a "Quality" pop-up (Automatic, 480p, 720p, 1080p; levels beyond the phone's capability are dimmed with a reason), a "Stop" button |
| Stats | "Front camera · 1280×720 · 24 fps · 1.9 Mbps", `mac-caption-2`, tabular digits |
| Lower quality | A `text-orange` line with an icon: "Lowering quality · Phone is hot" (other reasons: "Slow Wi-Fi network", "Low phone battery (18%)", "Requested by the meeting app", "Your choice") |
| In use by | "An app is using HandLive Camera and HandLive Microphone" |

"Stop" is a regular button, not a destructive one: stopping the camera loses no data. There's no mirror
option.

## By platform

- **macOS:** a regular window that resizes while keeping its aspect ratio; ⌘W closes it (without
  stopping the camera if a meeting app is using it); from macOS 26 the control bar is a
  `GlassEffectContainer` with `.clear`, before that `.hudWindow`.
- **Android:** doesn't have this window; while streaming, the `camera_live` channel notification has
  "Switch Camera", "Turn Off Microphone" / "Turn On Microphone", "Stop", along with Android's privacy
  indicators.

## Dos and don'ts

- Do let text state the status; a dark frame alone doesn't tell whether the camera is live or waiting.
- Don't switch Wi-Fi ↔ USB on your own without changing the transport label.
