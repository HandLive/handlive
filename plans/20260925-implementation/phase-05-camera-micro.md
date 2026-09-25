English | [Tiếng Việt](phase-05-camera-micro.vi.md)

# Phase 5 — The phone as a webcam and microphone for the Mac

**Goal:** meeting apps on the Mac pick "HandLive Camera" and "HandLive Microphone"; picture and sound
come from the phone over Wi-Fi, speeding up automatically over USB when a cable is plugged in; quality
adapts to the network, temperature and battery.

## Gate G5 — spike D6 (first week)

- CMIOExtension: a Developer ID–signed extension activated from the app in `/Applications`,
  delivering 720p30 frames from the sink stream that Zoom/Meet/FaceTime receive; check whether
  updating the extension requires a restart (C11).
- AudioServerPlugin loopback on the BlackHole model (C8): a hidden device + "HandLive Microphone",
  installed with an embedded PKG + `postinstall` `killall coreaudiod` (C9); meeting apps hear the PCM
  the app plays.
- Results in `reports/phase-05-spike-d6.md`; not met → stop Phase 5.

## Context

- Leaf functions: `08-camera-mic.md` CAM-01…05 (including the "Image rules": `rotation_deg`,
  center-crop, choosing the encode size); common specs 0.5 HL frame, the `/v1/stream/camera` channel,
  the `HLSTREAM1` MAC.
- Research: `plans/20260924-virtual-camera-mic-research/plan.md`,
  `plans/20260924-ipc-research/plan.md`; architecture §10.
- Design system: `CameraPreview`, `MenuBarMenu` (Camera submenu), `Notification` (channels
  `camera_request`, `camera_live`, `camera_alert`).
- Decisions: D6, D7/C9, D8, C8, C11.

## Requirements and measurable criteria

- Glass-to-glass latency at 720p30 < 120 ms over Wi-Fi, < 70 ms over USB; the first frame is an IDR
  with SPS/PPS; IDR interval 1–2 s when switching channels.
- The phone shows the privacy indicator and an ongoing notification with "Stop"; a start request
  cancels itself after 60 s.
- Mac: the "Stop" button is not destructive; no mirroring.

## Task cards

| Code | Task | Outputs | Acceptance criteria |
|------|------|---------|---------------------|
| M5.1 [macOS] | CAM-01: activate the CMIOExtension (`OSSystemExtensionRequest`), install the virtual-microphone PKG, guidance for allowing them in System Settings, uninstall; extension target `HandLiveCameraExtension`, driver `HandLiveMic` | `apple/macOS/…Extension`, `apple/macOS/HandLiveMic`, `docs/deployment-guide.md` | Install, uninstall and update (including when a restart is needed) follow the Es of CAM-01 |
| M5.2 [macOS] | CAM-02: demand from consumers (`app.handlive.camera.demand`, `DeviceIsRunningSomewhere`), `camera/start` with `hlaf`, the stream channel, `VTDecompressionSession` → `VTPixelTransferSession` → sink stream; Opus decode → AUHAL `app.handlive.mic.feed`; a "Waiting for the phone…" placeholder frame | app, packages | Latency meets the target over Wi-Fi; lost frames → `camera/keyframe` |
| M5.3 [macOS] | The `CameraPreview` window, the Camera submenu in `MenuBarMenu`, CAM-03 controls (`camera/config`), CAM-04 USB: IOKit detection, embedded adb `forward`, a wizard for turning on USB debugging (D8), channel switch with an IDR | app | Switching Wi-Fi ↔ USB never breaks the picture for longer than 1 IDR frame |
| A5.1 [android] | CAM-02: FGS type `camera | microphone` (the `camera_request` notification with "Turn On"/"Decline" is the Android 14+ exemption), Camera2 + `MediaCodec` H.264 (1080p/720p/480p tiers), `AudioRecord` 48 kHz + Opus 32 kbps, HL frames, rotation by `rotation_deg` and center-crop | `android/feature/camera` | The first frame is an IDR; the FGS starts from the notification on Android 14+ |
| A5.2 [android] | CAM-03 applies the configuration (switch camera, quality, microphone, pause video), CAM-05 adaptation: cut the bitrate to 75 %, lower the tier, lower the fps, temperature (`PowerManager.thermalStatus`), battery < 20 %; `camera/state` with `reason` | `android/feature/camera` | A congested-network scenario steps down and back up in the right order; overheating → stop with a `camera_alert` notification |
| A5.3 [android] | CAM-04 on the Android side: accept connections from `127.0.0.1` as the `usb` channel, close the Wi-Fi connection with code 4409, `camera/state reason = transport` | `android/core/transport` | Channel switch < 1 s |
| T5.1 [test] | Measure glass-to-glass latency (a millisecond clock filmed by the camera), fps, bitrate; a matrix of Zoom, Meet, FaceTime, Teams; 15 minutes with a hot phone | `tools/bench/`, `reports/` | Targets met; no continuous frame drop longer than 2 s |

## Testing

- Unit: choosing the encode size from `hlaf` and the tier, the CAM-05 state machine, Annex-B parsing.
- Manual: update the extension from an old version, clean uninstall, reinstall; the app not yet in
  `/Applications` (E1 of CAM-01).

## Risks and rollback

- The extension needs a restart after an update (C11) → say so clearly; do not block the rest.
- `killall coreaudiod` cuts the audio of meeting apps for a few seconds → install when no meeting is
  running, with a warning first.
- USB: adb does not work on some OEMs → Wi-Fi is always there.
