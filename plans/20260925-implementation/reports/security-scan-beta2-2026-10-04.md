# Security scan before v0.1.0-beta.2 (2026-10-04)

Owner request: scan the changes, fix, commit, merge, push, package and release the next beta.

## Scope

vbsec (21 rules), LARGE mode, 3 sub-agents. Every non-test file changed since `v0.1.0-beta.1`: android 83 (incl.
`fix/devices-empty-state`), apple 68, hub + shared 52 (mostly the new `website/`). Relay unchanged. Full report
(Vietnamese, JSON validated): hub worktree `vbsec-reports/scan-2026-10-04-212000.md` (git-ignored).

Verdict PASS: 0 critical, 0 high, 2 medium, 6 low.

## Findings and outcome

| Sev | Where | Rule | Issue | Outcome |
|-----|-------|------|-------|---------|
| M | hub `website/bin/setup.sh:23` | BROKEN-ACCESS-CONTROL | nginx public before WP-CLI install → web installer admin takeover | Fixed: nginx denies install/setup-config, nginx starts after install (403 verified, was 200) |
| M | apple `release-apple.yml:418` | BROKEN-ACCESS-CONTROL | signed app launched inside the notarization step (notary key in env/disk, keychain unlocked) | Fixed: launch step after keychain removal, no secret env; ad-hoc sign/launch/DMG moved to the read-only build job |
| L | android `AppNotificationReader.kt:26` | BROKEN-ACCESS-CONTROL | bare `android.callType` extra = fake call; Answer lends HandLive's BAL exemption | Fixed: API 31+ requires the platform `CallStyle` template; test red on old code |
| L | hub `inc/hardening.php:29` | VERBOSE-ERROR-DEBUG-MODE | admin login name in RSS `dc:creator` and oEmbed | Fixed: public name HandLive, oEmbed author fields dropped (verified) |
| L | hub `nginx/default.conf:4` | BRUTE-FORCE | behind a proxy the login limit is one shared bucket (owner lockout) | Documented in `docs/website.md` Going live |
| L | hub `docker-compose.yml:35` | OUTDATED-DEPENDENCY | floating image tags; Polylang unpinned, no updates | Partial: Polylang auto-updates; image digests open |
| L | apple `KeychainSecretStore.swift:80` | WEAK-PASSWORD-HASHING | Erase All Data clears only the current build's keychain | Open: follow-up task (needs cross-signature test) |
| L | apple `release-apple.yml:143` | OUTDATED-DEPENDENCY | unpinned `brew install xcodegen` | Fixed: XcodeGen 2.46.0 by SHA-256 (`Tools/fetch-xcodegen.sh`), byte-identical project |

## Review of the fixes

Code-reviewer: no critical/high; all branches mergeable. Applied: M2 (re-running the release for an older tag lacked
the script → run it from `$GITHUB_SHA`), L2 (setup rerun recreates nginx), L3 (seed fails loudly), L4 (auto-update
step idempotent; rerun tested). Wording corrected for M1/M3 (residual risk documented, not overclaimed).

## Verification

- android: `./gradlew check` green on the merged branch; new reader tests fail on the old reader
  (`expected null, but was 1`).
- apple: `actionlint` clean; pinned XcodeGen generates a byte-identical project; script tested through the pipe.
- hub: throwaway stack (`hl-scantest`, port 8091) installed and rerun: installer 403, feed "HandLive", oEmbed without
  author, Polylang auto-update enabled; `validate_design_docs` and `check_bilingual_docs` problems=0.

## Commits

| Repo | Commit | Subject |
|------|--------|---------|
| android | `6ef5b01` | fix(android): an app call needs the platform CallStyle template |
| android | `5dff736` | docs(android): what the CallStyle check leaves open |
| apple | `4b87d59` | ci(apple): run built code only without secrets and pin XcodeGen |
| apple | `7121ab1` | ci(apple): a release of an older tag runs the workflow's own XcodeGen script |
| hub | `78d27ac` | fix(website): close the web installer and keep the login name out of feeds and embeds |
| hub | `a413b14` | docs: the login limit behind a reverse proxy needs the real client address |
| hub | `ed06ed1` | docs: CALL-05 counts android.callType only with the CallStyle template from API 31 |
| hub | `c4a6fae` | docs: where the Apple release launches the app and the pinned XcodeGen |
| hub | `4ee0b3e` | docs: v0.1.0-beta.2 changelog with the fixes and the security scan |
| hub | `2f01255` | fix(website): a setup rerun applies the nginx config and keeps going |
| hub | `6a3b8e4` | docs: what the CallStyle check and the release launch step leave open |

## Unresolved questions

- Owner: tighten app-call answering (API 34+: background start only with a real FGS/UIJ flag or a granted
  full-screen intent; `answer_mode = tap` below API 31)? Changes UX.
- Owner: split `release-apple` into sign / launch / publish jobs before adding the macOS signing secrets.
- Owner: the `ANDROID_RELEASE_*` secrets are repository secrets; the guide asks for environment `release` secrets.
- Open LOWs: erase both keychains (task chip), website image digests.

Status: DONE_WITH_CONCERNS
Summary: Scan PASS (0 critical/high); 6 of 8 findings fixed and verified, 2 low open with follow-ups.
Concerns/Blockers: residual app-call and release-job risks need owner decisions.
