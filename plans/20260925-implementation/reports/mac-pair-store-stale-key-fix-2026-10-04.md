# Fix — one-sided pair after a db_key change (Mac, iOS) (2026-10-04)

Product fix for the bug found during the CALL-05 run (`phase-03-app-calls-T3.3.md`, "Found during the run"): after a
build without the Keychain entitlement, the Mac made new keys but kept `paired-devices.bin` sealed with the old key.

## Root cause (proven by a failing test first)

- `AppModel.launch()` / `IOSAppModel.launch()`: `keysMissing` → clear setup flags → `loadOrCreate` makes a **new
  `db_key`**; `paired-devices.bin` and `handlive.sqlite` stay sealed with the old one.
- `try? store.active()` → silently `nil` (UI shows unpaired); `completePairing` → `store.upsert` → `read()` throws
  `authenticationFailed` → `saveFailed` while the phone already finished PAIR-01 → **one-sided pair**.
- Same for SMS: `SmsDatabase(url:key:)` throws `SQLITE_NOTADB` → `startMessages` returns → **SMS (and call log) off,
  silently**.
- Trigger: keys recreated after a Keychain loss, or a build signed by another team (another default keychain access
  group) with the same bundle id. Local builds use `app.handlive.mac.localtest`, release `app.handlive.mac`, so they
  already have separate data folders; production has one team.
- Red test before the fix: `completePairing` → `.authenticationFailed`, `messages == nil`.

## Fix (owner decisions 2026-10-04)

Spec first: SET-03 API 1 logic 5 (new), SET-02 API 7 method list, SET-03 Query (`PRAGMA cipher_compatibility = 4`),
en + vi.

- **Two slots, no renames.** Pair store and `handlive.sqlite` each get a second slot `*.alt`.
  - main opens with `db_key` → main.
  - main missing or sealed with another key → `.alt` when it opens with the key or is missing (new empty file); the
    other key's file stays put, so switching back to the other build finds its data again.
  - both slots foreign → the one modified longest ago is deleted, start empty there (one generation kept).
  - any other error (I/O, permissions, locked DB) → no slot changes (pair store keeps main; SQLite rethrows).
  - Delete All removes both slots.
- **SQLCipher format pinned** (`cipher_compatibility = 4`): a future library default change must not read real data
  as `SQLITE_NOTADB`. No-op on 4.x (existing DBs open unchanged).
- APIs (additive): `PairedDeviceStore.open(fileURL:databaseKey:)`, `altURL(for:)`, `deleteFiles(at:)`;
  `SmsDatabase.open(url:key:)`, `altURL(for:)`; `removeFiles(at:)` now covers both slots, `deleteFiles()` its own.
- Wired: Mac `AppModel.launch` / `startMessages` / `eraseLocalData`; iOS `IOSAppModel.launch` / `startMessages` /
  `eraseLocalData`.

## Review history

- Owner chose "drop the unreadable file" first; review M1 (switching between two differently signed builds of one
  bundle id would destroy each other's data) → owner chose **keep instead of delete**; M2 (`SQLITE_NOTADB` also on a
  SQLCipher major update) → owner chose **pin now**.
- First keep design (rename to `*.stale` + 3-step swap) failed re-review: H1 a build opened without pairing lost the
  other build's pair on switch-back; M1 a non-key error on the copy still deleted it; M2 an interrupted swap could lose
  data later and Delete All missed `.swap`. Replaced by the two-slot scheme above (no moves at all → no crash window;
  same owner intent: nothing destroyed, one generation, switch-back restores).
- Final re-review of the two-slot design: no Critical/High; one Medium — the SMS "older foreign slot" was judged from
  modification times read after the wrong-key open attempts, which can checkpoint a leftover `-wal` (unclean exit) and
  touch the files, so the newer generation could be dropped (pair store unaffected). Fixed in `596321e`: both times
  are read before any attempt. Reviewer verified A→B(no pair)→A, A→B(pair)→A→B and Delete All on both slots.

## Verification

- `swiftlint lint --strict`: 0 violations (455 files). Two test files over 250 lines were split:
  `HLAppCoreTests/PairedDeviceStoreTests.swift`, `HLiOSUITests/IOSAppModelKeysTests.swift`.
- `xcodebuild test`, serial as CI: HLAppCore 118, HLSMS 30 + 10, HLCalls 14 + 14, HLMacUI 70, HLiOSUI 25 — all pass.
- New tests: two keys share each store (each finds its own data; opening without pairing loses nothing; a third key
  replaces the older foreign file, in both directions; Delete All removes both slots); non-key errors change no slot
  (directory at the pair store path; `chmod 000` database); Mac and iOS app models switch A → B (no pair) → A → B
  (pair) → A → B.
- `tools/docs/validate_design_docs.py` problems=0; `check_bilingual_docs.py` problems=0.
- Not run: real device (Mac + S25) re-pair after a signing change; CI on GitHub (not pushed).

## Commits (branch `fix/mac-pair-store-stale-key`, not merged, not pushed)

| Repo | Commit | Subject |
|------|--------|---------|
| hub | `a1a6da9` | docs: SET-03 keeps data of another db_key in place and uses a second slot |
| hub | `8af5293` | docs: roadmap and changelog for the one-sided pair fix |
| apple | `ddeca32` | fix(apple): open pair store and SMS database in a second slot beside another db_key |
| apple | `8942ee5` | fix(apple): Mac and iOS keep pairing and SMS working after a db_key change |
| apple | `0f49f25` | docs(apple): changelog for the db_key second slot |
| apple | `596321e` | fix(apple): pick the older foreign SMS slot from times read before opening |

No `shared/` change (no contract, vector, schema or bench event changed); Android unaffected (Keystore keys and app
data are removed together).

## Unresolved questions

- The phone still reports success before the Mac saves (PAIR-01 order); with this fix a save no longer fails for a
  key mismatch, but any other save error stays one-sided. Change PAIR-01 so the Mac confirms after saving?
- No diagnostic trace when a slot switch happens (no bench event); add one if field debugging needs it.
- `apple/Packages/.claude/agent-memory/` (reviewer tool memory) is untracked in the apple worktree; not committed.
- The mtime-order bug's red case needs WAL frames left by an unclean exit; the new test guards the direction only (a
  clean `pool.close()` leaves nothing for a wrong-key open to checkpoint), the reviewer's probe reproduced the bug.

Status: DONE_WITH_CONCERNS
Summary: One-sided pair and silent SMS-off after a db_key change fixed on Mac and iOS with a two-slot store/database
and a pinned SQLCipher format; spec, tests, lint green; committed on branch, not merged.
Concerns/Blockers: real-device re-check and GitHub CI not run yet.
