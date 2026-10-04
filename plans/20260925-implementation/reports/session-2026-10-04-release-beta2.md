# Session handoff — fixes, CI, release pipeline and v0.1.0-beta.2 (2026-10-04)

Started from `plans/next-session-kickoff-prompt.md`; every merge and push below was asked for by the owner in chat.
Detailed reports exist per area; this file links them and covers the rest.

## Done (on `main`)

| Area | Outcome | Report / commits |
|------|---------|------------------|
| Mac/iOS one-sided pair after a `db_key` change | Pair store and SMS DB open in a second slot (`*.alt`), SQLCipher format pinned | `mac-pair-store-stale-key-fix-2026-10-04.md` |
| Apple CI speed | `ci-apple` in four parallel lanes, ~3–4 min | `ci-apple-parallel-lanes-2026-10-04.md` |
| Release pipeline | `release-android` (signed `foss` APK), `release-apple` (IPA, ad-hoc DMG; Developer ID path written, not run); Mac without a team signature uses the login keychain (0.6.1) | `release-pipeline-2026-10-04.md` |
| Brand mark | Tests and spec ported onto the other session's in-app brand mark | android `a9d31c0`, apple `4952098`, hub `8b7f6b2` |
| Settings UI | Android lists clear of the floating tab bar; iOS/Mac "Last synced" never "in 0 seconds" (`HLRelativeTime`); before/after in `assets/android-settings-before-after.png`, `assets/ios-settings-before-after.png` | android `5de11eb`, apple `a6b468e` |
| Android Devices tab | Empty state with a banner no longer crashes; Add Device clear of the tab bar in short windows (tests red on old code) | android `58f821c` |
| iPhone install | Debug build installed on the owner's iPhone via the personal team (`apple/localtest/`, git-excluded) | — |
| Security scan + fixes | vbsec PASS (0 critical/high); 6 of 8 findings fixed; Delete All in both Mac keychains done by a spawned session | `security-scan-beta2-2026-10-04.md`, `erase-both-keychains-2026-10-04.md` |
| v0.1.0-beta.2 | Tags on all five repos (hub `9eb0766`, shared `7254abe`, relay `cda13bf`, android `45d067b`, apple `c40d918`); Releases on all five; APK (signed after the owner reset the keystore secret), IPA and ad-hoc DMG verified (checksums, apksigner, codesign, versions) | hub `155cb47` handoff |
| One download page | Hub `release-collect` gathers APK/IPA/DMG with checked SHA-256 into the hub's Release; run for beta.2: 6 files | hub `21db3a8`, `c05ba9d` |
| Website download link | Get the Beta (header, footer, hero, CTA, beta post) opens the hub's beta.2 Release; verified on a throwaway stack in en and vi | hub `9e46176`, `75ce3ef` |

| Follow-ups (owner, 2026-10-05) | Home page badge reads v0.1.0-beta.2 and opens its release; new Android release key `CN=Ho Xuan Dung, O=HandLive, C=VN` re-signed the beta.2 APK (old `CN=y` key retired); signing secrets moved to the environment `release` (tags `v*` and `main` only); app calls answer directly only when Android vouches for the call | hub `aaf9ad8`, `54918b7`, `2d08c78`; android `f656287`, `9861366`; runs 37221615865, 37221982189 |

## Verification highlights

- android `./gradlew check` green after the merges; CI green on hub, android, apple `main` before tagging.
- `release-android` rerun 37210387723 signed and attached the APK; `release-apple` 37210395431 attached IPA + DMG
  (DMG built and launch-checked in the read-only build job); `release-collect` 37219463899 attached all six files.
- Website changes tested on an isolated compose project (`hl-scantest`, port 8091), never on the owner's running stack.

## Next steps

1. Owner: back up `~/Documents/HandLive-keys/handlive-release.jks` and `handlive-release.password` off the Mac (a
   password manager), then delete the password file; losing the key breaks updates of installed apps.
2. Optional: a required reviewer on the environment `release` (now limited to tags `v*` and `main`).
3. Before the paid Apple team's secrets: split `release-apple` into sign / launch / publish jobs.
4. On each release: website link (`docs/website.md`), then `release-collect` runs on the hub tag.
5. Website: pin image digests (scan LOW); hero badge still reads "Public beta · v0.1.0-beta.1" (links the beta.1 post).

## Unresolved questions

- None from this session; the owner decided the key name, the secret placement and app-call answering (all done).

Status: DONE
Summary: v0.1.0-beta.2 is released on all five repos with every installable file, the APK signed by the owner's new
key, on the hub's Release and the website pointing there; the day's fixes, CI speed-up, release pipeline, security
scan and its follow-ups are merged.
Concerns/Blockers: none; the key backup is the owner's to do.
