# Phase 3 extension — spike T3.2: calls from other apps (Telegram) on the Mac

Date 2026-10-01. Phase file: `phase-03-cuoc-goi-app.md`. Design: `phase-03-app-calls-brainstorm.md`.

## Setup

- Phone: Galaxy S25 Ultra (SM-S938B), Android 16 (API 36), One UI, **no SIM**, on Wi-Fi; Telegram
  (`org.telegram.messenger`) called from the owner's iPhone.
- Mac: MacBookPro18,3, macOS 27.0.1 (26A434), paired with the S25 over Bluetooth.
- Probe: handlive-android `tools/call-spike` (`app.handlive.spike.call`, branch `feat/phase-03-app-calls`, standalone
  debug build, no network permission): notification listener, adb command receiver (`DUMP`-protected), background
  PendingIntent sender with the background-activity-start option, `setCommunicationDevice` router, optional no-op
  accessibility service. Mac side: `apple/Tools/HFPSpike` as a CLI and as an ad-hoc signed app bundle
  (`NSBluetoothAlwaysUsageDescription`, `NSMicrophoneUsageDescription`, hardened runtime, `audio-input`).
- Logs never hold names or numbers (`HLCALL` lines: shape, key hash, timings).

## Results

| # | Question | Result | Evidence |
|---|---|---|---|
| 1 | Listener sees Telegram's call notifications | **Go.** Ringing: `CallStyle` `callType=1`, `category=call`, channel `incoming_calls40`, `callPerson`, `declineIntent` (broadcast), `answerIntent` (activity), actions "Từ chối", "Trả lời". In call: **no `CallStyle`** — channel `Other3`, ongoing, one action "Kết thúc" (End), no `hangUpIntent` | `ev=posted phase=ringing style=1 … latency_ms=215–232` (5 calls); `ev=watched channel=Other3 ongoing=1 actions="Kết thúc"` |
| 2a | Decline from the background | **Go.** Notification removed 12–14 ms after the send | `ev=removed reason=8 since_cmd=decline:12` |
| 2b | Answer from the background, no exemption | **Blocked**: background activity launch | `ActivityTaskManager: Background activity launch blocked … voip_answer … (BAL_BLOCK)` |
| 2c | Answer from the background with a bound accessibility service | **Go.** Ringing notification removed 160 ms (1.5 s on a second run) after the send; in-call notification posted 0.3–1.5 s after | `since_cmd=answer:160`, `answer:291` |
| 2d | End from the background (ordinary action 0 of the `Other3` notification) | **Go.** Removed 19–28 ms after the send | `since_cmd=action:0:19` |
| 3a | Route to the Mac with `setCommunicationDevice` only | **No.** Recorded but not applied: Telegram owns the mode | `AS.AudioDeviceBroker setCommunicationRouteForClient uid 10160 bt_sco` then `MicModeManager setCommunicationDevice() deviceType: 1` |
| 3b | Route after the probe takes `MODE_IN_COMMUNICATION` | Android **tries**: virtual call + eSCO request to the Mac. **The Mac rejects it** with HCI status 0x0D (limited resources), every attempt | `startScoUsingVirtualVoiceCall` → `bta_ag_sco_open` → `btif_hf_debug_sco_connection_comp: status 13` → `audio connection failed` |
| 3c | Mac opens SCO itself (`connectSCO`, `transferAudioToComputer`) | **No.** `kIOReturnUnsupported` (0xE00002C7), also while the phone reports `call=1`, also from the app bundle with Bluetooth access granted | `HFPSpike` `sco_opened status -536870201` |

Side effect seen in 3b: while a communication-route request to the Mac stands and SCO keeps failing, Android restarts
the virtual call every 200–300 ms (the Mac sees `callsetup 2→3`, `call 1→0` in a loop); it stops when the request is
cleared (`clearCommunicationDevice` + `MODE_NORMAL`).

### Retest 2026-10-02 (owner asked for audio on the Mac)

- The HF side never offered codec negotiation (`hf_features=116`: bit 7 clear), so the 2026-10-01 SCO attempts were
  already CVSD; a "CVSD instead of wideband" retry is not a new variant.
- Telegram cannot pick the Mac until it holds `BLUETOOTH_CONNECT` (owner granted it); even then its call screen offered
  only the speaker, while Android listed the Mac as `bt_sco` and `HeadsetService` reported it as the active, connected
  HFP device (`mAudioState 10`, SCO never requested).
- Mac-initiated SCO during the live Telegram call (`transferAudioToComputer`): IOBluetooth inside the app logs
  `connectSCO … rfcomm connected:1 sco connected:0` then `Failed to open SCO connection` and returns
  `kIOReturnUnsupported` within 0.3 ms — the framework fails locally, `bluetoothd` is never asked.
- Verdict for question 3 unchanged and stronger: **no-go on macOS 27.0.1** in both directions (phone-initiated eSCO
  rejected with 0x0D, Mac-initiated SCO unsupported by the framework). Evidence: `hfp-telegram-route.jsonl`, unified log
  06:54:49 (scratchpad, not committed).

### Shell/Shizuku audio capture retest 2026-10-02 (owner wants audio on the Mac)

Owner asked to verify audio on the Mac via the shell (Shizuku) path (plan D10), since macOS HFP is a no-go. Tested on
the S25 (Android 16, no SIM) with a live Telegram call (`MODE_IN_COMMUNICATION`), the shell uid (adb) holding
`CAPTURE_AUDIO_OUTPUT`, `CAPTURE_VOICE_COMMUNICATION_OUTPUT` and `MODIFY_AUDIO_ROUTING`.

- `AudioRecord` under `app_process` (tool `android/tools/audio-spike`), downlink sources: `VOICE_COMMUNICATION`,
  `VOICE_DOWNLINK`, `VOICE_CALL` → RMS 0 (silence). `MIC`, `VOICE_RECOGNITION` → non-zero but only the phone's own
  microphone (ambient), not the remote party.
- scrcpy 4.1 recording, 7 s each during the call, measured with `ffmpeg volumedetect`:
  `playback` −91.0 dB, `voice-call` −91.0 dB, `voice-call-downlink` −91.0 dB — all digital silence.

Conclusion: at shell privilege there is **no path to capture a VoIP app's downlink audio** on this device. Android
protects `USAGE_VOICE_COMMUNICATION` playback from capture even for the shell uid; the telephony capture paths do not
see VoIP; `AudioPlaybackCapture` is opted out by the app. So the Opus-over-WS / Shizuku fallback (D10) cannot deliver
Telegram call audio to the Mac. (Cellular-call capture via the telephony paths is a separate question, untestable here
without a SIM, and uplink injection stays unverified — plan D10.) Evidence: `audio-spike` RMS lines, `cap-*.mkv`
volumedetect (scratchpad, not committed). The spike tool is debug-only and not committed.

## Criteria (phone side, LAN not involved)

| AC | Target | Measured | Verdict |
|---|---|---|---|
| AC1 | Mac panel ≤ 200 ms after the notification is posted | Notification post → listener **215–232 ms** on this phone, before any transport | **Cannot be met as written** (OS delivery alone exceeds it) |
| AC2 | Decline/End ≤ 500 ms | 12–28 ms after the intent is sent | Met (phone side) |
| AC3 | Answer ≤ 1 s | 160 ms – 1.5 s after the intent is sent, only with a background-start exemption | Met with an exemption |
| AC4 | Audio on the Mac ≤ 1.5 s | No audio: the Mac refuses SCO | **No-go on macOS 27** |

## Go / no-go

- Question 1: **go**. Question 2: **go, with a background-activity-start exemption** for Answer (decline and end need
  none). Question 3: **no-go on macOS 27.0.1** — the blocker is the Mac's HFP audio (the same blocker as gate G4), not
  Android.
- v1 ships with the audio on the phone (AC4 fallback), as planned.

## Consequences for the product cards

1. Answer needs HandLive to be exempt from background-activity-start limits. The bound clipboard accessibility service
   gives that, but it is optional; candidates to check: a CompanionDeviceManager association with the Mac, or the
   "display over other apps" permission. Without one, Answer must fall back (e.g. bring the phone's call UI up through
   a HandLive notification the user taps).
2. Telegram's in-call notification is not `CallStyle`: End must use an ordinary action of the same app's ongoing
   notification (here the only action). A per-app rule (package, channel, single action) is needed; titles are
   localized and must not be matched as text alone.
3. AC1 must be re-based on what the OS allows (owner decision).
4. If the audio route is ever attempted, the request must be cleared on the first SCO failure (to stop the
   virtual-call loop).

## Not tested

Screen off / locked variants; Zalo, WhatsApp; relay path; macOS 26 and 13/14 (the Mac mini).

Status: DONE_WITH_CONCERNS
Summary: Telegram call notifications can be read, declined, answered (with a background-start exemption) and ended from
the background; moving the audio to the Mac fails because macOS 27 refuses HFP SCO.
Concerns/Blockers: AC1 (≤ 200 ms) is below the phone's own notification delivery time; Answer depends on an exemption
HandLive does not always hold; the probe is not committed yet (owner asked not to commit).
