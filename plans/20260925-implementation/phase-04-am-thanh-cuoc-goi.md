English | [Tiếng Việt](phase-04-am-thanh-cuoc-goi.vi.md)

# Phase 4 — Taking calls on the Mac

**Goal:** listen and talk on cellular calls from the Mac over Bluetooth HFP (primary path), with an
Opus/WebSocket fallback through Shizuku; move the audio back and forth between the Mac and the phone;
hold, DTMF and mute with HFP commands.

## Gate G4 — spike D1 (first week, before any other task card)

Question: can `IOBluetoothHandsFreeDevice` in the HF role on macOS receive and play the SCO audio of
a cellular call, and how does macOS expose that stream to apps?
- Devices: an Apple silicon Mac on macOS 26, a Mac on macOS 13 or 14; Pixel and Samsung phones; plus
  AirPods to test conflicts.
- Results to record (`reports/phase-04-spike-d1.md`): service-level connection, opening SCO, two-way
  audio heard, the audio device name that appears, latency, errors per macOS version.
- Go ahead when listening and talking work on at least one Mac–phone pair on macOS 26 and one on
  macOS 13/14. Not met → Opus/WS becomes the primary path (D1 dual-path), HFP keeps only the AT
  commands for control; update AUDIO-02, plan D1, roadmap.

## Context

- Leaf functions: `07-call-audio.md` AUDIO-01 (disclosure `call-audio-v1`, Bluetooth and microphone
  permissions), AUDIO-02, AUDIO-03, AUDIO-04; `06-call-control.md` CALL-03 (hold, DTMF, mute over
  HFP).
- Design system: `ConsentSheet` (taking calls on the Mac), the `CallPanel` Bluetooth-connected state,
  `PermissionPrimer`.
- Decisions: D1, D2, D3, D10/C13, D11/C14; `docs/code-standards.md` (the `CallAudioRelay`
  abstraction, OEM strategies).

## Requirements and measurable criteria

- MOS ≥ 3.5 over HFP, ≥ 3.0 over Opus/WS; echo return loss > 40 dB on the loudspeaker; SCO latency
  ~40 ms, Opus/WS 100–150 ms.
- The disclosure is shown before the first enablement, storing `text_version`, `accepted_at`; no
  component ever records audio.
- HFP path: Bluetooth link encryption only (D11), the KNOB/BIAS risk is disclosed; Opus/WS path:
  TLS + E2E.

## Task cards

| Code | Task | Outputs | Acceptance criteria |
|------|------|---------|---------------------|
| M4.1 [macOS] | AUDIO-01: `ConsentSheet` with the `call-audio-v1` text, request the Bluetooth and microphone permissions (one "Continue" screen per permission), choose the HFP phone, store `consent_record` | `apple/macOS/HandLive` | A new `text_version` asks again; microphone denied → listen only (E7) |
| M4.2 [macOS] | `CallAudioRelay` protocol + `HfpCallAudioRelay` wrapping `IOBluetoothHandsFreeDevice` (per the spike results), `AUVoiceProcessingIO` (AEC, NS, AGC), audio switching (AUDIO-03), AT commands for hold/DTMF/mute (CALL-03) | `apple/Packages/HLCallAudio` | No `IOBluetooth*` calls outside the package; MOS and ERL measured |
| M4.3 [macOS] | `OpusWsCallAudioRelay`: libopus through a SwiftPM/C bridge, adaptive 20–60 ms jitter buffer, the `/v1/stream/callaudio` channel with HL frames, automatic switch when HFP fails (E3, E4) | package | End-to-end latency ≤ 150 ms; switching paths never drops the call |
| A4.1 [android] | `bt-hfp-manager`: `BluetoothHeadset` proxy and broadcasts, `call_event/hfp_status`, matching the Mac by address; OEM strategies (`SamsungBtAdapter`, `PixelBtAdapter`, `GenericBtAdapter`) | `android/feature/callaudio` | Correct state on Pixel, Samsung, Xiaomi |
| A4.2 [android] | AUDIO-01 on the Android side: enable `feature.call_audio`, `BLUETOOTH_CONNECT`, the `opus_fallback` capability with `reason` | `android/feature/callaudio` | The capability is correct for each Android version and Shizuku state |
| A4.3 [android] | `OpusWsCallAudioRelay` through a Shizuku UserService: `AudioRecord` `VOICE_CALL`/`VOICE_DOWNLINK` (Android 11+), 2-second silence detection (`capture_silent`), voice injection with `getCallUplinkInjectionAudioTrack` (Android 13, verified on real devices), Opus 16 kHz 32 kbps; limits recorded per device in deployment-guide | `android/feature/callaudio` | A matrix of ≥ 6 devices: a captured/not-captured table; a failure never drops the call |
| T4.1 [test] | Measure MOS (POLQA or PESQ with reference samples), ERL, latency; scenarios: AirPods holding SCO, out of Bluetooth range (E5), WebSocket session lost mid-call | `tools/bench/`, `reports/` | Targets met; every scenario ends with the audio back on the phone and the call still up |

## Testing

- Unit: the audio-route state machine (`phone`, `mac_hfp`, `mac_ws`), the DTMF queue waiting for
  `OK`, the jitter buffer.
- Legal: a screenshot of the disclosure and the `consent_record` row in the report; no "send
  unencrypted" path (Opus/WS).

## Risks and rollback

- Spike D1 fails → see gate G4. `IOBluetoothHandsFreeDevice` gets deprecated later → only
  `HLCallAudio` has to change.
- Android 10 cannot capture (E2) → the feature is hidden on that device, with a clear message.
