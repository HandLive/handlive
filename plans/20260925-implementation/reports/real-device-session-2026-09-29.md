# Real-device session of 2026-09-29 — hand-off

The owner connected a real phone and asked to test on real hardware (G6, then G4, then the HandLive apps). The
session ended mid-way; this is the state for the next agent.

## Hardware and what is installed

- **Phone:** Samsung Galaxy S25 Ultra (SM-S938B), Android 16 (API 36), adb serial `R5GL320PPZT`, USB. Browsers:
  Samsung Internet 30.0.0.67, Chrome 153. Same Wi-Fi as the Mac (phone 192.168.10.171, Mac 192.168.10.38).
  - `app.handlive.spike.web` (G6 probe, android `1306e78`) is installed and its accessibility service is **on**.
    Remove it when G6 is done: `adb -s R5GL320PPZT uninstall app.handlive.spike.web`.
  - `app.handlive.android` = HandLive debug `foss` build of android `main` `4b21dc6`. It went through setup and a QR
    pairing attempt that failed (below). It is **not** paired.
- **Mac (this machine, macOS 27, MacBookPro18,3):** HandLive debug build of apple `main` `eaf7989`, bundle id
  `app.handlive.mac.localtest`, signed with the free Personal Team 3S93UPADXV. The Personal Team cannot sign the
  `usernotifications.communication` / `time-sensitive` entitlements, so the build used a local copy of
  `macOS/HandLive.entitlements` without them (not committed). It runs from `~/Applications/HandLiveDev.app`
  (copied there so LaunchServices sees it; delete it after testing). The same bundle id was used by the earlier
  emulator debug build, so its data/keychain may still hold an old pair with the emulator.
- The stale emulator dev bridge (`bonjour_proxy.py`, `tcp_forward.py`, `dns-sd -R HL-e66648`) was still running
  and advertising a fake phone; it was killed. Before any live test, check nothing from `build/dev-bridge` runs.
- Tools used: `adb`; a helper to tap by resource id/text through uiautomator (was in the session scratchpad, easy to
  rewrite). Computer-use cannot drive the Mac HandLive app: it is a menu-bar (`LSUIElement`) app and is not listed
  as a controllable app.

## G6 (Web Handoff) — results so far

Recorded in `phase-06-spike-g6.md` (section "Real device and Mac runs"):

- Chrome 153 (S25): URL bar found, full path but no scheme; incognito detected through FLAG_SECURE.
- Samsung Internet 30: host only (bar text is U+200E + host; probe fixed in android `1306e78`); Secret mode
  detected through FLAG_SECURE.
- **Open bug:** HOME does not end the page on Android 16 (the service only hears the browser packages).
- Mac: Chrome reads URL/title and detects incognito (`mode=incognito`); **Safari cannot tell private windows**
  without Accessibility trust.
- Owner decisions pending: Safari (ask for Accessibility or drop it); Samsung Internet origin-only (accept or drop).
- Still missing: Firefox, Edge, Brave on a phone (install from Play Store); a Mac on macOS 13 or 14.

## HandLive pairing on real devices — open bug

- Symptom: after scanning the Mac's QR, the phone waited long, then showed "Mã QR đã đổi" (the Mac had connected
  to the fake phone of the stale bridge). After killing the bridge, the second attempt ended with
  `error.pairing_auth_failed` ("Pairing isn't secure — try again", AUTH_FAILED: MAC, signature or TLS binding).
- Evidence: the phone advertises `HL-3ea282` with `pr=…` on port 47800 (reachable from the Mac, `nc` OK); Bonjour
  resolution from the Mac took ~10 s; the Mac's unified log (`/usr/bin/log show --predicate 'processID == <pid>'
  --info --debug`) shows pairs of parallel TLS connections to 192.168.10.171:47800 closed after ~0.1 s. Neither app
  logs pairing events (HLBENCH covers sessions only).
- Not yet known: whether the phone side or the Mac side is wrong. Suspects: the 2026-09-28 security changes
  (`/v1/pair` admission 2 per IP / 4 total, 8 KiB hello cap, unclaimed connections, `plans/20260928-security-fixes`
  D5/D6), the Mac opening two connections at once, leftover pair data in `app.handlive.mac.localtest`.
- A debugging agent was started but stopped with no result. Suggested next step: pair the S25 with the Python fake
  Mac of `shared/tools/e2e` (PIN path, driven over adb) to split phone vs Mac; add temporary pairing logs if needed;
  fix test-first on `fix/real-device-pairing`.

## G4 (HFP spike) — not started

- `apple/Tools/HFPSpike` (branch `feat/phase-04-call-audio`) builds with Xcode 27 here. `HFPSpike list` printed no
  devices: the process has no Bluetooth permission yet, and the S25 is **not paired over Bluetooth** with the Mac
  (phone: "Bonded devices: 0"). The owner must pair them (System Settings › Bluetooth, allow calls for the Mac) and
  grant Bluetooth/Microphone to the app that runs the probe; the owner's iPhone can place the test call.

## G5 (camera/mic) — blocked

Needs a paid Apple Developer Program team for the System Extension; the owner refused a macOS VM. The HAL
microphone plug-in can be tried on this Mac if the owner installs the PKG himself (admin password).

Status: DONE_WITH_CONCERNS
Summary: Real-device G6 runs are recorded; HandLive pairing on real devices fails with AUTH_FAILED (root cause not
found); G4 waits for Bluetooth pairing; G5 waits for a paid team.
Concerns/Blockers: pairing bug unexplained; test apps left installed on the owner's phone and Mac (listed above).
