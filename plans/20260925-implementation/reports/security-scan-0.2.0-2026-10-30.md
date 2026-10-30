# Security scan before v0.2.0 (2026-10-30)

Owner request: merge Phase 7 (Bluetooth offline pairing) and release v0.2.0. This scan gates the tag per
`docs/deployment-guide.md` ("Cutting a release"): no critical or high finding may stay open.

## Scope

`git log`/`git diff --shortstat v0.1.1..HEAD` per repository. Numbers measured by Long (#4130) and Huy (#4138, #4152)
and cross-checked against each repo's reflog by this reviewer. The changed source was read directly, not only counted.

| Repo | HEAD | Commits since v0.1.1 | Files | Content |
|------|------|------|------|------|
| hub | `facf1c3` | 12 | 27 | `tools/measure-sp1{,-prep,-auto}.sh`, `tools/verify-phase7.sh`, `tools/verify-android-ui.sh`, `tools/release-push.sh` and `release-tag.sh` (#234; `facf1c3` only changes `release-tag.sh`), 5 commits of Phase 7 design docs EN+VI (#238), `.gitignore` |
| shared | `259217d` | 6 | 38 | Bluetooth/CPace test vectors (`cpace.json`, `bt-pairing.json`, `bt-link.json`, `bt-frame.json`, `bt-advertisement.json`), `tools/setup-cpace-refs.sh`, `tools/vectors/*`, Bluetooth status strings, Noise psk vector-generator fix |
| android | `3900d8b` | 16 | 89 | `core/crypto` (CPaceX25519SHA512, Field25519, NoiseNNpsk0), `core/protocol` + `core/transport` (Bluetooth link, `BluetoothLinkAdmission`/`Acceptor`/`PreauthSession`, `BtPinPairingResponder`), `feature/connection` (`BluetoothAdvertising`, manifest permissions), `feature/pairing` (QR and PIN pairing over Bluetooth), "Connected via Bluetooth" label, version 0.2.0 |
| apple | `28bf435` | 29 | 93 | `HLCrypto` (CPaceX25519SHA512, Field25519, NoiseNNpsk0 initiator), `HLTransport` (CoreBluetooth central/L2CAP/channel, `BtPinPairingSearch`, `BtQrPairingSearch`, `PinAttemptCounter`), `HLAppCore` (`BluetoothFallbackPairingSearch`, `PairingController`, shared PIN counter fix #3932), macOS `NSBluetoothAlwaysUsageDescription`, "Connected via Bluetooth" label, version 0.2.0 |
| relay | `17f367b` | 0 | 0 | Unchanged; same HEAD as the v0.1.1 scan. |

Outside this scan: the two-phase logic of `tools/release-tag.sh` (#234) was reviewed separately (approved at
`facf1c3`, #4147); its code is in the hub row above and holds no injection, secret or `--force`.
CHANGELOG/README/CLAUDE.md (#235) and this report file (#237) are editorial and not scanned as product code.

Verdict, all four repositories: **0 critical, 0 high, 0 medium, 0 low.** PASS; the `v0.2.0` tag may proceed.

## Findings

None.

## Checked and clean

- **CPace-X25519-SHA512 PIN exchange** (android `CPaceX25519SHA512.kt`, apple `CPaceX25519SHA512.swift`). Follows
  draft-irtf-cfrg-cpace-21 Appendix B.1. The generator string is zero-padded to the SHA-512 block so hashing time does
  not depend on PIN length. A low-order point makes X25519 throw and the channel closes without an answer. The PIN
  never goes over the air; only `Ya`/`Yb`, then a Noise-encrypted channel.
- **Shared PIN-lockout counter, both platforms.** Android: one `AtomicInteger offers` in `PairingWindow.Pin`, spent by
  both the LAN `pair/offer` path and `BtPinPairingKeySource.onPinChannelFailedAfterCpace1()`. Apple:
  `PinAttemptCounter` is an actor created once per PIN in `PairingController` and passed by reference to both the LAN
  and Bluetooth searches in `BluetoothFallbackPairingSearch`. This closes this reviewer's earlier finding #3932,
  re-checked against the code.
- **Noise_NNpsk0 link handshake** (android `NoiseNNpsk0.kt`, apple initiator). Correct psk0 pattern (Noise rev. 34
  §9.2). A failed AEAD tag returns `null` without saying which psk failed.
- **Bluetooth admission** (`BluetoothLinkAdmission.kt`). BLE gives no client address, so failures lock the whole
  listener for `BT_AUTH_FAIL_WINDOW` after `BT_AUTH_FAIL_BLOCK` failures. Documented trade-off.
- **Android Bluetooth permissions** (`feature/connection/src/main/AndroidManifest.xml`). Only `BLUETOOTH_ADVERTISE` and
  `BLUETOOTH_CONNECT` on API 31+; no `BLUETOOTH_SCAN` because the phone never scans. Legacy `BLUETOOTH`/`BLUETOOTH_ADMIN`
  capped at `maxSdkVersion=30`. No other module requests Bluetooth.
- **New scripts, all run by the owner on the Mac, none shipped.** `measure-sp1*.sh`, `verify-phase7.sh`,
  `verify-android-ui.sh`: arguments go into zsh arrays, never `eval` or `sh -c`. `setup-cpace-refs.sh`: downloads the
  public IETF draft over HTTPS; the version is limited to two digits before it reaches the URL; the download is
  gitignored. `release-push.sh`/`release-tag.sh`: no `--force`, `$TAG` must start with `v`, all variables quoted, tag
  SHAs come from `git rev-parse`, and the two-phase `release-tag.sh` checks local and remote tags in all four repos
  before tagging any.
- **Vectors and Phase 7 docs.** Key values in `bt-*.json` are synthetic fixtures. A grep of the new docs and plans for
  keys, tokens and passwords found nothing real (two `bearer` hits are the BLE transport term).
- **Secrets across the diff.** Huy grepped `git log -p v0.1.1..main` on all four repos for private keys, API keys and
  AWS keys (#4109); this reviewer grepped the new scripts, vectors and docs. Clean. Tien's independent review (#4151,
  #4160) agrees.
- **Version bumps to 0.2.0.** One line in `handlive-android/app/build.gradle.kts`, one block (3 targets) in
  `handlive-apple/project.yml`, nothing else.

## Unresolved questions

None.

Status: DONE
Summary: every commit since `v0.1.1` in the four repositories was read (relay unchanged). 0 critical, 0 high, 0
medium, 0 low. The `v0.2.0` tag may proceed.
Concerns/Blockers: none for the tag.
