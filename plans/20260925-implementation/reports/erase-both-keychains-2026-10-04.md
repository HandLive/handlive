# Erase both Mac keychains (security scan 2026-10-04, LOW WEAK-PASSWORD-HASHING)

Date: 2026-10-04. Branch `fix/erase-both-keychains` in apple and hub. Not merged, not pushed (owner's go-ahead).

## Problem

`KeychainSecretStore` uses one keychain per build: data-protection (team-signed) or login (ad-hoc, 0.6.1).
"Delete All HandLive Data" only cleared that one, so a user who ran both builds kept the other build's `ik_sig`,
`ik_dh`, `db_key` and PRKs; login-keychain items travel in Time Machine / Migration Assistant.

## Measured on this Mac (macOS 27.0.1)

Probe app built from the production `KeychainSecretStore` with its own service `app.handlive.keys.erase-probe`
(never the app's keys; the installed `/Applications/HandLive.app` and its pairing untouched). Three signatures:
Personal Team (Apple Development, team 3S93UPADXV, keychain group `3S93UPADXV.app.handlive.erase-probe`, Xcode
automatic signing) and two ad-hoc builds with different cdhashes (`codesign --force --deep --sign -`, as
`release-apple`). Each step also ran with `SecKeychainSetUserInteractionAllowed(false)`.

| Case | Old code (`SecItemDelete`) | New code |
|------|----------------------------|----------|
| Team deletes login items an ad-hoc build created | `-25244` errSecInvalidOwnerEdit, no dialog, items stay | deleted, no dialog |
| Ad-hoc B (update) deletes ad-hoc A's items: fresh-install `deleteAll`, `delete(account:)`, `save` over them | `-25244`, items stay | ok |
| Ad-hoc deletes in the data-protection keychain | `-34018` | tolerated; team keys stay (device-only) |
| Team fresh install (`deleteAll`) | — | data-protection only; ad-hoc keys stay (switch back works) |
| Team Delete All (`deleteAllInEveryKeychain`), UI allowed | — | both keychains empty, no SecurityAgent |

Other facts: `/usr/bin/security delete-generic-password` and the legacy `SecKeychainItemDelete` delete the foreign
items silently; a team-signed query *without* `kSecUseDataProtectionKeychain` matches its data-protection items too,
with the flag explicitly `false` it does not. Answer to "does it prompt": no dialog in any case.

Pre-existing bug found: an updated ad-hoc DMG could not delete its predecessor's login items, so Delete All left them
(`try?`), the next launch's fresh-install `deleteAll` threw → stuck at E1; Unpair kept the PRK.

## Owner decisions (2026-10-04)

- Delete login-keychain items with `SecKeychainItemDelete` on references (not `/usr/bin/security`, not "document only").
- Fix every login-keychain delete in this branch (fresh install, `delete(account:)`, Delete All).

## Changes

- Spec (hub): 0.6.1 rule for login-keychain deletion; SET-02 API 7 method/response/example + logic 6 (both keychains,
  residuals); SET-03 API 1 logic 1 (fresh install: this build's keychain only) + Query; PAIR-03 step 7 / API 5. en + vi.
- apple `HLCrypto`: `LoginKeychain` (the one deprecated call, isolated); `KeychainSecretStore.matchQuery` with an
  explicit data-protection flag, `deleteItems`, `deleteAllInEveryKeychain()` (tolerates `errSecMissingEntitlement`);
  `SecretStore.deleteAllInEveryKeychain()` (default = `deleteAll()`); `InMemorySecretStore.everyKeychainDeletions`.
- apple callers: `AppModel+Account.eraseLocalData` (Mac) and `IOSAppModel+Data.eraseLocalData` (iOS, same as before
  there) call `deleteAllInEveryKeychain()`.

Commits — hub: `d3e7483` docs (spec), `886edf1` docs (changelog), plus this report.
apple: `0413c26` fix (login-keychain delete), `dc339d7` test, `4616084` fix (both keychains), `e492b9d` test,
`041f6cd` docs (changelog). Both branches rebased on today's `main` (hub `62cfbb9`, apple `c40d918`).

## Verification

- `validate_design_docs.py` problems=0; `check_bilingual_docs.py` problems=0; `apple_diacritics.py` 0 changes.
- HLCrypto 53/53; HLAppCore identity tests 2/2 (full run: 3 call-command timing tests failed once at load avg ~15,
  27/27 on rerun, untouched code); HLMacUI 70/70 and HLiOSUI 25/25 (`xcodebuild test`); HandLiveDevClient builds;
  `swiftlint lint --strict` clean; `check_package_imports.py` 0 outside dependencies. No `shared/` change.
- New compiler warning: `SecKeychainItemDelete` deprecated (macOS 10.10), one site in `LoginKeychain.swift`.

## Residual / notes

- Ad-hoc build cannot reach the data-protection keychain: a team build's keys stay there until a team build erases
  (device-only, not in backups). In spec SET-02 API 7 logic 6.
- The other build's pairs are not revoked: its keys are gone so it never reconnects, but the phone and relay keep
  the pair until removed there (PAIR-03).
- Real HandLive app not erased end to end: the team build shares group `3S93UPADXV.app.handlive.mac` with the
  installed app, so a Delete All test would wipe the owner's live keys and pairing. The probe covers the keychain calls.
- Xcode renewed the Mac Personal Team profile for `app.handlive.mac.localtest` (old one expired 2026-10-04 17:14;
  new one until 2026-10-11).

## Unresolved questions

- Run an isolated end-to-end check with the real app (separate bundle id and keychain group → registers a new App ID
  on the Personal Team) before merge, or is the probe enough?
- README roadmap / CLAUDE.md handoff: update at merge (scan fixes are not on the roadmap table)?

Status: DONE_WITH_CONCERNS
Summary: Delete All now clears both Mac keychains and every login-keychain delete works across signatures; measured
with team and ad-hoc builds, no dialog. Branches ready, waiting for the owner's merge go-ahead.
Concerns/Blockers: one deprecated API (no replacement); ad-hoc builds still cannot erase a team build's device-only keys.
