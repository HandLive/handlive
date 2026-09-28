# Phase 5 — spike D6 (gate G5): virtual camera and virtual microphone on macOS

Question (`phase-05-camera-micro.md`, gate G5): can a CMIOExtension activated from an app in `/Applications` deliver
720p30 frames pushed into its sink stream to Zoom/Meet/FaceTime, does an extension update need a restart (C11), and is
an AudioServerPlugIn loopback on the model of C8, installed by a PKG whose `postinstall` runs `killall coreaudiod`
(C9), audible in meeting apps? Not met → Phase 5 stops.

## Prepared (2026-09-28)

- **Probe:** handlive-apple `feat/phase-05-camera-mic` (from `origin/main` `6487c16`), `Tools/CameraSpike`. Own
  identifiers so it never collides with the product: host `app.handlive.spike.camera`, extension
  `app.handlive.spike.camera.extension`, camera UID `app.handlive.spike.camera.device`, microphone UIDs
  `app.handlive.spike.mic.feed` / `.input`.
  - **Host app** `HandLiveCameraSpike.app`: Activate / Properties / Deactivate (`OSSystemExtensionRequest`, every
    delegate callback logged: needs approval, replace old→new version, `completed` / `will_complete_after_reboot`,
    error name/code); finds the sink stream through the CoreMediaIO C API and pushes a generated 1280×720 BGRA 30 fps
    test pattern (`CMIOStreamCopyBufferQueue`, `CMIODeviceStartStream`, `CMSimpleQueueEnqueue`, frame-slot clock,
    counters for sent / queue full / late timer); **camera self-check** reads the virtual camera through AVFoundation
    like a meeting app and computes latency from a 64-cell timestamp strip in every frame (32 bits of host-clock ms +
    32 inverted check bits); big live clock in the window for the screenshot method; listens for the extension's
    Darwin notifications; **microphone** part plays a 20 ms 1 kHz beep at every host-clock second into the hidden
    feed device (AUHAL) and can listen to "HandLive Microphone Spike" to measure the in-driver loopback latency from
    burst onsets. Events go to `~/Library/Logs/HandLiveCameraSpike/events-*.jsonl`.
  - **Camera Extension** "HandLive Camera Spike": source stream (any client) + sink stream (only signing ID
    `app.handlive.spike.camera`, the signing ID seen is logged); forwards each sink frame immediately with the current
    host time; grey `--:--` placeholder after 1 s without sink frames; posts `app.handlive.spike.camera.demand` /
    `.idle` on source start/stop (CAM-02 API 1).
  - **HAL plug-in** `HandLiveSpikeMic.driver` (C): hidden output device "HandLive Microphone Spike Feed" + visible
    input device "HandLive Microphone Spike", 48 kHz mono Float32, one 16,384-frame ring buffer on a shared
    timeline; each slot is tagged with its sample time so stale frames read as silence when the feed stops.
  - **PKG layout + build script** `build.sh`: `test`, `unsigned`, `dev <TEAM>` (Apple Development, automatic
    signing), `developer-id <TEAM>` (archive, export, notarize, staple), `pkg` (non-relocatable
    `HandLiveSpikeMic.pkg` into `/Library/Audio/Plug-Ins/HAL`, `postinstall` = `killall coreaudiod`; payload-free
    `HandLiveSpikeMic-Uninstall.pkg`). `HL_BUILD_NUMBER` raises `CFBundleVersion` for the C11 update test.
  - **Runbook** `Tools/CameraSpike/README.md` (Vietnamese `README.vi.md`): signing, build, activation and approval
    path, tests in Photo Booth / FaceTime / Zoom / Meet (Safari, Chrome), two latency methods, update test, PKG
    install and checks, uninstall, 19-row results table.
- **CI:** the probe has its own XcodeGen `project.yml`; `ci-apple` does not build it (a system extension needs
  signing), it only lints its Swift files like every file under `Tools/` (clean). CI run `36452215225` on this
  branch: commit policy passed; the build job failed in the **HLProtocol** tests, unrelated to the probe —
  `MessageType` lacks the `web` type that handlive-shared `main` now has in `envelope.schema.json` (Phase 6). The
  same failure happens on apple `main` (run `36450704048`); it clears when the Phase 6 Apple work adds `web`.

## Verified here (no system change)

This Mac: MacBookPro18,3, macOS 27.0 (26A428), Xcode 27.0 (27A266a), SIP enabled.

| Check | Result |
|-------|--------|
| `swift test` (CameraSpikeKit: timestamp strip round trip incl. 2× downscale, placeholder/blank frames not decoded, moving box, clock digits, clipping, frame clock incl. late/early timer, latency stats, click track + onset detector) | 16 tests pass (one rounding bug in frame presentation times found and fixed) |
| HAL plug-in loaded in-process through its CFPlugIn factory, as `coreaudiod` does (`Tests/PluginSmokeTest`) | 25/25 checks pass: factory, driver interface, both UIDs → devices, names, feed hidden / input visible, only the input can be default, one stream per device in the right scope and direction, 48 kHz mono Float32, IO start/stop and running state, WriteMix/ReadInput routing, bit-exact loopback at the same sample time across the ring wrap, stale slots silent |
| `xcodebuild` unsigned (Debug and Release, arm64 + x86_64) of host + embedded extension (`Contents/Library/SystemExtensions/app.handlive.spike.camera.extension.systemextension`) + plug-in | builds, no warnings in our code |
| `./build.sh pkg` | builds both PKGs; `relocatable="false"`, `install-location="/"`, `postinstall` present. The payload also lists `._*` entries for the `com.apple.provenance` attribute that macOS puts on files created by this shell (cannot be removed); Installer restores them as attributes, not files |
| `swiftlint lint --strict` (whole repo) | 0 violations |
| Signing with "Apple Development: me@hxd.vn (F349V24RRM)" | extension: signs (team `3S93UPADXV`, sandbox + app group `3S93UPADXV.app.handlive.spike.camera.extension`, no profile needed); plug-in: signs, `codesign --verify --strict` valid; **host: fails** — `No profiles for 'app.handlive.spike.camera' were found … Automatic signing is disabled` (run without `-allowProvisioningUpdates`, so no account change) |

Not run, by design (owner's steps): activating the extension, approving it in System Settings, copying to
`/Applications`, installing the PKG / plug-in, `killall coreaudiod`, any meeting app.

## Signing findings

- F349V24RRM is the **certificate's** ID, not a team. The certificate's team (OU) is **3S93UPADXV**, "Dung Ho"; the
  only profile on this Mac is Xcode-managed, `LocalProvision`, 7-day lifetime — a free **Personal Team**.
- The host needs `com.apple.developer.system-extension.install`, a restricted entitlement that only a provisioning
  profile grants. A Personal Team cannot add the System Extension capability, so **the owner needs a paid Apple
  Developer Program membership** before step A of the runbook can run (high confidence; row 2 of the results
  confirms it).
- With a paid team, expected: Apple Development + a development profile with the System Extension capability that
  lists this Mac is enough to activate from `/Applications` with SIP on, no notarization; Developer ID + notarization
  (and a Developer ID Installer–signed, notarized PKG) are needed for distribution, as CAM-01 already says.
  Disabling SIP / `systemextensionsctl developer on` is not a valid workaround for the gate.
- Camera Extension: no profile needed for its team-prefixed app group; the `CMIOExtensionMachServiceName`
  (`$(TeamIdentifierPrefix)$(PRODUCT_BUNDLE_IDENTIFIER)`) must be inside that group.
- HAL plug-in: signs with Apple Development without a profile; whether `coreaudiod` accepts that (and ad-hoc — spec
  says ad-hoc is rejected) is results row 14.

## License decision for the HAL plug-in

- BlackHole (ExistentialAudio/BlackHole) is **GPL-3.0** (its `LICENSE`, checked through the GitHub API on
  2026-09-28), plus name/branding restrictions. It cannot be used in HandLive (Apache-2.0; GPL/LGPL/AGPL excluded).
- Apple's NullAudio/SimpleAudio samples were not copied either. The plug-in is **written from scratch** against the
  public SDK header `CoreAudio/AudioServerPlugIn.h`; only the *architecture* of C8 (hidden output + visible input
  sharing a ring buffer in the driver) is reused, which is an idea, not code. No third-party code or asset is
  bundled, so `NOTICE` is unchanged.

## To run (owner)

Runbook: `apple/Tools/CameraSpike/README.md` (`README.vi.md`). Needed: a paid Apple Developer team signed in in
Xcode (Settings › Accounts), this Mac (and ideally one on macOS 13/14, since the product targets macOS 13+), Photo
Booth, FaceTime, Zoom, Google Meet in Safari and Chrome, QuickTime Player, administrator rights for the PKG.

## Results (to fill in)

| # | Check | Result |
|---|-------|--------|
| 1 | Mac model, macOS, Xcode | |
| 2 | Paid team; `./build.sh dev` signs the host with the System Extension capability | |
| 3 | Activation from `/Applications`, Apple Development, SIP on: result, approval path | |
| 4 | Activation from outside `/Applications`: `unsupportedParentBundleLocation`? | |
| 5 | Sink opened by the host; camera permission needed? | |
| 6 | Frames in Photo Booth / FaceTime / Zoom / Meet Safari / Meet Chrome | |
| 7 | Self-check latency ms (min / median / p95 / max), fps | |
| 8 | Screenshot latency ms per app | |
| 9 | Placeholder within ~1 s after Stop Feed | |
| 10 | Demand / idle Darwin notifications received | |
| 11 | Sink guard: signing ID seen, others refused | |
| 12 | Update 1 → 2: `completed` / `will_complete_after_reboot`; camera before and after restart (C11) | |
| 13 | PKG install: devices appear (seconds after Installer), feed hidden | |
| 14 | `coreaudiod` accepts the plug-in signature (Apple Development; ad-hoc) | |
| 15 | Loopback latency ms | |
| 16 | Beeps heard in FaceTime / Zoom / Meet Safari / Meet Chrome / QuickTime | |
| 17 | `running_somewhere` = 1 while a meeting app uses the microphone | |
| 18 | Deactivate + uninstall PKG clean; restart needed? | |
| 19 | Errors | |

## Decision rule

Gate G5 passes when rows 3, 6 and 16 are yes with a Mac-side latency that leaves room for CAM-02's < 120 ms
end-to-end target over Wi-Fi. Then Phase 5 task cards start; C11 row 12 sets how CAM-01 E3 handles updates, row 14
whether the product plug-in must be Developer ID–signed even in development. Otherwise Phase 5 stops and this report
records why.

## Commits (handlive-apple, branch `feat/phase-05-camera-mic`, pushed)

| Hash | Message |
|------|---------|
| `b3de3e6` | feat(apple): add the camera spike's test pattern, frame clock and click track |
| `d40f92e` | feat(apple): add the camera spike's Camera Extension |
| `fc307e4` | feat(apple): add the camera spike's host app |
| `477c784` | feat(apple): add the camera spike's loopback HAL plug-in |
| `30b0329` | feat(apple): add the camera spike's build script and PKG layout |
| `f9396da` | docs(apple): add the camera spike runbook |

No change in `shared/`, `android/`, `relay/` or hub docs.

Status: BLOCKED
Summary: The G5 probe (Camera Extension + host feeding the sink, loopback HAL plug-in written from scratch, PKG layout, runbook) builds, its logic and the plug-in pass local tests; the gate itself needs the owner to activate and install it.
Concerns/Blockers: the host app cannot be signed on this Mac — the only identity belongs to a free Personal Team (3S93UPADXV), which cannot get the System Extension capability; a paid Apple Developer Program team is required before the spike can run. Nothing was activated or installed here.
