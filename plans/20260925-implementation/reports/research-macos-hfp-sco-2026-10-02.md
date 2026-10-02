# Research: Mac as Bluetooth HFP Hands-Free unit with SCO audio (2026-10-02)

Question: can a Mac be the HFP HF for a phone with SCO call audio on macOS 11–15, 26, 27 (Apple Silicon)? Feeds G4 / D1.

## Local evidence (this Mac, macOS 27.0.1, Apple Silicon, S25 Ultra)
- `IOBluetoothHandsFreeDevice` service-level connection (RFCOMM/AT) works.
- `connectSCO`/`transferAudioToComputer` fail in-process in ~0.3 ms ("Failed to open SCO connection",
  `kIOReturnUnsupported`); never reaches `bluetoothd`.
- Phone-initiated CVSD eSCO is rejected by the Mac with HCI 0x0D (Connection Rejected, Limited Resources).
- No SCO audio kext loaded/present: only IOBluetoothFamily, AppleBluetoothModule, IOBluetoothHIDDriver.
- System `BTAudioHALPlugin` serves only Mac-as-audio-gateway (headsets/AirPods), not Mac-as-HF.

## (1) IOBluetoothHandsFreeDevice SCO on Apple Silicon / macOS 11+
- Independent reproduction of our exact failure: phonebt issue #1 (2026-09-24, open) — MacBook Air M5, macOS 27.0,
  Galaxy A14. SLC, dial/answer/hang-up work; SCO never opens; log shows `SCO/eSCO reject (HOST_REJ_RESOURCES)`
  (= HCI 0x0D); phone shows Mac as audio route then reverts after ~1 s. No workaround.
  https://github.com/icoainc/phonebt/issues/1
- phonebt itself (Apache-2.0, 2026) defaults to a wired USB audio adapter ("USB Advanced Audio Device") for call
  audio; Bluetooth SCO is only a fallback and README says it "may not work with all phone/Mac combinations".
  https://github.com/bitandbytes/phonebt
- Apple forums: HF API thread unanswered, no DTS reply (Jun 2025): https://developer.apple.com/forums/thread/786421
- Legacy kext `com.apple.driver.IOBluetoothSCOAudioDriver` (IOBluetoothSCOAudioEngine) existed in the Intel/kext
  era (OS X Lion forum logs). https://discussions.apple.com/thread/3200456?page=12
- Removal date: NOT found in public sources. Best inference: Monterey (12) rewrote the Bluetooth stack and moved
  most of it into userspace `bluetoothd`, which matches the kext disappearing.
  https://dortania.github.io/OpenCore-Install-Guide/extras/monterey.html
- Phone Amego (the long-standing Mac HF app) documents an "Alternate HFP" mode that has "no longer any control
  over call audio"; release notes stop at a Ventura rebuild (v1.5.08, Feb 2023), no SCO-audio fix noted.
  https://www.sustworks.com/pa_guide/handsfree.html · http://www.sustworks.com/pa_guide/releaseNotes.html

## (2) User-space stack + external USB dongle on macOS Apple Silicon
- BTstack libusb port README: from macOS 26.0 (through 26.4) libusb access to a BT controller causes a
  **kernel panic**; recommended workaround = Linux VM (Ubuntu in UTM + CSR8510).
  https://github.com/bluekitchen/btstack/blob/master/port/libusb/README.md
- BTstack PR #758 (merged to develop 2026-09-28): root cause is a NULL deref in Apple's USB host stack on
  reset/re-enumeration; skipping `libusb_reset_device` fixes HCI cmd/event on 26.6 (M2, M4). SCO/isochronous/HFP
  explicitly untested. On **macOS 27.0 the panic fires earlier, between `libusb_init` and first `libusb_open`** —
  external USB controllers unusable from userspace. https://github.com/bluekitchen/btstack/pull/758
- libusb #1762 (Mar 2026, closed as kernel bug): `libusb_claim_interface` on a device with an **isochronous**
  endpoint panics `IOUSBHostFamily` (macOS 26.3.1, M1 Pro). BT dongles carry SCO on an isochronous interface.
  https://github.com/libusb/libusb/issues/1762
- Dongle must be kept from macOS: `nvram bluetoothHostControllerSwitchBehavior=never` (google.github.io/bumble/platforms/macos.html).
- Bumble (Google, Apache-2.0): SCO over USB HCI absent until PR #896 (merged 2026-06-01); tested Broadcom/Realtek
  CVSD only, audio "somewhat glitchy", Intel alt-setting issues, macOS not mentioned. Has HFP HF examples
  (`run_hfp_handsfree.py`). https://github.com/google/bumble/pull/896 · https://github.com/google/bumble/discussions/560
- Licenses: BTstack = BSD + 4th clause "solely for personal benefit and not for any commercial purpose" →
  not Apache-2.0-compatible for HandLive distribution; needs a paid BlueKitchen commercial license.
  https://github.com/bluekitchen/btstack/blob/master/LICENSE · Bumble = Apache-2.0 (compatible, but Python runtime).
- Known working Mac setups: none found for HFP HF + SCO audio via libusb on Apple Silicon (any macOS version).

## (3) Shipping Mac apps receiving phone call audio over HFP today
- Phone Amego, Dialogue (v1.2), PhoneCall-Handsfree (last update 2020-10, v1.3.1), Connecton (2020-11, claims
  Apple Silicon/Big Sur) all exist, but none has a recent update or verifiable report of SCO audio working on
  Apple Silicon with macOS 13+. https://apps.apple.com/us/app/phonecall-handsfree/id1435288006?mt=12 ·
  https://apps.apple.com/us/app/connecton/id1497000705?mt=12 · https://www.getdialogue.com/
- Phone Link (our HFP precedent) is Windows-only; newest active Mac project (phonebt) works around SCO with USB audio.

## Verdict
| Route | Works on macOS 27? | Evidence | Cost |
|-------|--------------------|----------|------|
| IOBluetoothHandsFreeDevice + built-in BT, Mac-initiated SCO | No | local 0.3 ms `kIOReturnUnsupported`; phonebt #1 (M5, 27.0) | free |
| Phone-initiated SCO/eSCO to Mac | No | local HCI 0x0D; phonebt #1 `HOST_REJ_RESOURCES` | free |
| BTstack libusb + USB dongle, native macOS | No (kernel panic) | BTstack README; PR #758 (27.0 panics before open) | dongle ~US$10 + commercial license |
| Bumble USB + dongle, native macOS | No (same USB-stack panic; SCO path glitchy, untested on Mac) | PR #758, libusb #1762, Bumble PR #896 | Apache-2.0, Python bundle |
| Linux VM (UTM) + passthrough dongle + BTstack/BlueZ | Unverified; ok on 26 per BTstack, 27 at risk (QEMU USB passthrough also goes through host USB stack) | BTstack README | VM per user — not shippable UX |
| Existing Mac HF apps | No evidence | stale (2020–2023), no Apple Silicon SCO reports | n/a |
| Opus/WS fallback (plan D10, Shizuku) | Independent of Mac BT | design | device-dependent capture |

Recommendation: treat HFP/SCO-to-Mac as **no-go on macOS 26/27** for a consumer app; G4 can close with
"HFP primary not viable", promote Opus/WS to primary (AUDIO-02 / plan D1) and keep HFP only for SLC
(call control AT commands), which does work. Owner decision required.

Unresolved: did SCO-to-Mac work on macOS 13/14 Apple Silicon (an older-Mac run would date the regression)?
Will Apple fix the IOUSBHostFamily panic in 27.x (no Feedback number found)?

Status: DONE_WITH_CONCERNS
Summary: Mac-as-HF SCO audio is broken on macOS 27 (local + independent M5/27.0 report, same HCI 0x0D); the
libusb/dongle escape hatch kernel-panics on macOS 26/27; no shipping Mac app is verified to receive HFP call audio.
Concerns/Blockers: macOS version that dropped IOBluetoothSCOAudioDriver not found publicly (Monterey inferred);
no data for macOS 13–15 Apple Silicon; Linux-VM route untested on 27.
