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

## Verification highlights

- android `./gradlew check` green after the merges; CI green on hub, android, apple `main` before tagging.
- `release-android` rerun 37210387723 signed and attached the APK; `release-apple` 37210395431 attached IPA + DMG
  (DMG built and launch-checked in the read-only build job); `release-collect` 37219463899 attached all six files.
- Website changes tested on an isolated compose project (`hl-scantest`, port 8091), never on the owner's running stack.

## Next steps

1. Owner: back up `~/Documents/HandLive-keys/handlive-release.jks` and its password off the Mac; decide whether to
   replace the key (certificate DN `CN=y, OU=y, …`) before the APK reaches real users — later replacement breaks updates.
2. Owner: move the `ANDROID_RELEASE_*` secrets into environment `release` with a required reviewer and a `v*` tag rule.
3. Before the paid Apple team's secrets: split `release-apple` into sign / launch / publish jobs.
4. On each release: website link (`docs/website.md`), then `release-collect` runs on the hub tag.
5. Website: pin image digests (scan LOW); hero badge still reads "Public beta · v0.1.0-beta.1" (links the beta.1 post).

## Unresolved questions

- Tighten app-call answering (API 34+: background start only with a real FGS/UIJ or granted full-screen intent;
  `answer_mode = tap` below API 31)? Changes UX.
- Replace the Android release key now (proper certificate name) or keep it?

Status: DONE_WITH_CONCERNS
Summary: v0.1.0-beta.2 is released on all five repos with every installable file on the hub's Release and the website
pointing there; the day's fixes, CI speed-up, release pipeline and security scan are merged.
Concerns/Blockers: owner decisions on the Android key name, secret placement and app-call answering.
