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
| MacBookPro18,3 (27.0.1) | Samsung S25 Ultra (Android 16, no SIM) | 817–1164 (after the Mac's SDP cache was refreshed; the first attempt with a stale cache never reached RFCOMM) | 4079, hold modes 43 | **Not opened**: phone-initiated eSCO/SCO (virtual call) rejected by the Mac with HCI 0x0D every time; Mac-initiated `connectSCO`/`transferAudioToComputer` → `kIOReturnUnsupported`, also as a signed app bundle with Bluetooth access | none | no | — | not testable without SCO | stale SDP cache; 0x0D; 0xE00002C7 |
| (macOS 26) | | | | | | | | | |
| (macOS 13/14) | | | | | | | | | |

Extra cases: AirPods connected to the Mac during the call; the phone moved out of range; the audio moved back and
forth (`p`, `c`) during one call.

### Session 2026-10-01 (owner present, S25 without SIM)

- No cellular call was possible (no SIM). Indicators, features and the SLC work; the audio path was driven instead
  through an Android virtual voice call (the app-call spike forced the communication route to the Mac, see
  `phase-03-app-calls-spike.md`): the phone opened SCO toward the Mac and **macOS 27.0.1 refused it (HCI 0x0D)**;
  the Mac could not open SCO itself (`kIOReturnUnsupported`). A Telegram call is not reported over HFP at all.
- Reading: on macOS 27 the HF-side SCO of `IOBluetoothHandsFreeDevice` is not usable by this probe. Still to run
  before deciding D1: a real cellular call (SIM), and macOS 26 / 13–14 (the Mac mini).

## Decision rule

Go ahead with HFP as the primary path when listening and talking work on at least one Mac–phone pair on macOS 26 and
one on macOS 13/14. Otherwise Opus/WS becomes the primary path and HFP keeps only the AT commands for control: update
AUDIO-02, plan D1 and the roadmap.

Status: BLOCKED
Summary: The probe and its runbook are ready and build on CI; the spike itself needs a real phone paired over Bluetooth and a real call.
Concerns/Blockers: only one Mac (macOS 27) is known to be available; gate G4 asks for macOS 26 and macOS 13/14 as well.

### Session 2026-10-02 (Telegram call, macOS 27.0.1)

Mac-initiated SCO (`transferAudioToComputer`) during a live VoIP call: IOBluetooth logs `Failed to open SCO
connection` and returns `kIOReturnUnsupported` within 0.3 ms without reaching `bluetoothd`; the HF never offered codec
negotiation, so the earlier phone-initiated 0x0D rejections were CVSD. HFP audio through public APIs is a no-go on
macOS 27.0.1; macOS 26 and 13/14 still untested (Mac mini). Details: `phase-03-app-calls-spike.md` (retest).
