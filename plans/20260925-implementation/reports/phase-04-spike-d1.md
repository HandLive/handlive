# Phase 4 — spike D1 (gate G4): call audio over Bluetooth HFP on macOS

Question (`phase-04-am-thanh-cuoc-goi.md`, gate G4): can `IOBluetoothHandsFreeDevice` in the hands-free role on macOS
receive and play the SCO audio of a cellular call, and how does macOS expose that stream to apps? No other Phase 4
task card starts before this answer.

## Prepared (2026-09-28)

- **SDK check:** the macOS 27 SDK (Xcode on this Mac) still ships `IOBluetoothHandsFreeDevice`, `IOBluetoothHandsFree`
  and their delegates (`connect`, `connectSCO`, `transferAudioToComputer`/`ToPhone`, `acceptCall`, `endCall`,
  `sendDTMF`, `holdCall`, `currentCallList`, `inputMuted`, the AG indicators), available since 10.7 and not deprecated.
- **Probe:** handlive-apple `feat/phase-04-call-audio`, `Tools/HFPSpike` (`f1b5bff` tool, `45f81b5` runbook en/vi,
  `12050ea` CI build). `list` shows paired phones with the HFP gateway service; `audio-devices` lists Core Audio devices;
  `probe <address> --route --log …` connects as hands-free, logs the service-level connection time and the phone's
  features, indicators, calls, SCO open time and the Core Audio device that appears with SCO (name, transport,
  channels, sample rate), and with `--route` plays the caller on the Mac and sends the Mac microphone to the phone.
  Commands answer, end, move audio, mute, DTMF, hold. Numbers and names are never logged.
- **Checked here without a phone:** builds with the Command Line Tools, `swiftlint --strict` clean, `audio-devices`
  runs on macOS 27.0 (MacBookPro18,3). Nothing that needs a phone has run.

## To run (owner, with real devices)

Runbook: `apple/Tools/HFPSpike/README.md` (Vietnamese: `README.vi.md`). Needed: this Mac (macOS 27), ideally also a Mac
on macOS 26 and one on macOS 13 or 14; a Pixel and a Samsung with SIMs paired to the Mac over Bluetooth; a second phone
to call from; headphones; AirPods for the conflict case.

## Results

| Mac (macOS) | Phone | SLC (ms) | Phone features | SCO opened (ms) | Core Audio device (name, transport, rate) | Heard both ways | Rough latency | Mute / DTMF / hold | Errors |
|-------------|-------|----------|----------------|-----------------|-------------------------------------------|-----------------|---------------|--------------------|--------|
| MacBookPro18,3 (27.0) | Pixel | | | | | | | | |
| MacBookPro18,3 (27.0) | Samsung | | | | | | | | |
| (macOS 26) | | | | | | | | | |
| (macOS 13/14) | | | | | | | | | |

Extra cases: AirPods connected to the Mac during the call; the phone moved out of range; the audio moved back and
forth (`p`, `c`) during one call.

## Decision rule

Go ahead with HFP as the primary path when listening and talking work on at least one Mac–phone pair on macOS 26 and
one on macOS 13/14. Otherwise Opus/WS becomes the primary path and HFP keeps only the AT commands for control: update
AUDIO-02, plan D1 and the roadmap.

Status: BLOCKED
Summary: The probe and its runbook are ready and build on CI; the spike itself needs a real phone paired over Bluetooth and a real call.
Concerns/Blockers: only one Mac (macOS 27) is known to be available; gate G4 asks for macOS 26 and macOS 13/14 as well.
