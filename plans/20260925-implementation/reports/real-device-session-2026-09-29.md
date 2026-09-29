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

## HandLive pairing on real devices — status 2026-09-30

- **Earlier open bug (AUTH_FAILED / "Couldn't find the phone"):** addressed on the working trees
  (`apple` + `android` on `fix/security-scan-findings`, plus `shared` string updates). Owner reports QR pairing
  is smoother and more stable on the S25 ↔ Mac path (2026-09-30).
- Fixes kept (not yet committed as of this note): store `lastHost`/`lastPort` after LAN pair; skip ghost Bonjour
  instances and retry `PAIRING_CLOSED` without blacklisting the live phone; stable mDNS instance name; Mac Settings /
  Pair Phone bring-forward (leave `.accessory`, float the window) so Local Network and pairing UI stay in front.
- **Still open:** commit the pairing/UI work onto `fix/real-device-pairing` (apple already has that branch name);
  re-run Phase 2/3 checks on this pair once committed; G1 device matrix still needs formal fill-in.
- Debug session instrumentation was removed after the owner confirmed Settings and pairing.

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
