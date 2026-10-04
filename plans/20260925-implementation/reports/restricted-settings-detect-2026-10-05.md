# Restricted-setting block: guidance on return, consent asked once (2026-10-05)

Follow-up of the S25 image-copy case (CLAUDE.md "In progress" item 8): the Accessibility service had been off since
2026-09-30, blocked by Android 13+'s restricted-setting rule for sideloaded APKs, and HandLive never said so after the
first attempt. Run by a forum team (lead, Android, QA, two BAs, pentester) while the owner slept; the owner's rule for
the night: skip the gates that need him, never skip a warning, no push, no merge, do not touch the S25.

Shipped: android #6 (merged `715c65b`, CI green); hub `fix/restricted-settings-detect` via its PR. Shared unchanged.

## Outcome

- SET-01 field 14 ("Restricted setting" guidance) comes back **once per return** when the user leaves Accessibility
  (Auto-Send on Copy) or Notification access (Calls from Other Apps) without turning HandLive on: E7, E8, E11, API 6
  logic 6, API 9 logic 4. Its button is "Continue" (system page) before the page opens and "Open Settings" (App info,
  `common.open_settings`) on a return. A return from App info opens nothing; auto-send off or the feature off never
  warns. No new UI string, field 15 keeps its three values.
- The disclosure is asked **once**: SET-02 field 2 and CLIP-01 A1 no longer read as "show it again while the service is
  off" (the old wording is where `SettingsActionsImpl` re-pushed the consent screen).
- **Bug found on the way:** the first Agree on the disclosure was lost. The screen popped itself right after launching
  the DataStore write in its own `rememberCoroutineScope`, which leaving composition cancels. Fixed by writing first,
  then leaving; `ConsentChoicesTest` fails on the old order (2/2) and passes on the new one.
- Restriction state `R` = `none` (API ≤ 32, or installed by Google Play) / `likely` (API 33+, any other installer).

## What did not work (keep it)

- Reading Android's own verdict: `AppOpsManager.unsafeCheckOpNoThrow("android:access_restricted_settings", myUid,
  packageName)` throws on Android 15 (emulator API 35):
  `SecurityException: verifyIncomingOp: uid 10213 does not have any of {MANAGE_APPOPS, GET_APP_OPS_STATS, MANAGE_APP_OPS_MODES}`.
  `EnhancedConfirmationManager` is a system API. The spec says not to try again (SET-01 API 6 logic 2).
- `appops get app.handlive.android ACCESS_RESTRICTED_SETTINGS` printed `default; rejectTime=…` on the S25 after the
  owner had allowed restricted settings, and on the emulator; the "rejected" in the earlier handoff was the
  `rejectTime` field, not the mode. AOSP `EnhancedConfirmationService` maps `ALLOWED` / `ERRORED` / `IGNORED` /
  `DEFAULT` to not guarded / guarded / guarded and acknowledged / implicit, and "Allow restricted settings" only
  appears in App info once the block dialog was shown (`IGNORED`).
- Known limit (spec, logic 2): leaving Accessibility with Back before touching HandLive gives "Open Settings" on the
  return, and App info has no Allow item yet; nothing is stuck (a return from App info opens nothing, the next tap
  gives "Continue"), one screen is wasted.

## Commits

| Repo | Commits |
|------|---------|
| hub `fix/restricted-settings-detect` | `604bca0`, `f7fa3d8`, `806dd3f`, `0ef6f0b`, `fce6a94`, `b676e20` (spec, en + vi); docs commit with this report |
| android `fix/restricted-settings-detect` (rebased on `origin/main` `1b9751b`) | `1f6e3ef`, `d5b2ed5`, `a5dbaee`, `ec447d2`, `e353c42`, `8a58a4d`, `689aaf6`, `c22aab7`, `d05d018`, `b50c05e`, `cc2a59b`, `bcf7325` |

The spec went through three review rounds (BA, tester, pentester) and changed twice on evidence: `ERRORED` would have
sent a fresh install to an App info page without the Allow item, then the app-op read itself turned out impossible.
The android history keeps the 4-value state and its removal (`d05d018`) on purpose; squash on merge if preferred.

## Verification

- Hub: `validate_design_docs.py` problems=0, `check_bilingual_docs.py` problems=0, `apple_diacritics.py` dry run clean.
- Android, after the rebase: `testDebugUnitTest` (all modules) + `:app:testFossDebugUnitTest` + `detekt` +
  `ktlintCheck` + `:app:lintFossDebug` + `:app:assembleFossDebug` → green, 914 test results, 0 failures (final run after `bcf7325`). `SpecialAccessTripRestorationTest` turns red when
  `rememberSaveable` is swapped for `remember`.
- Manual, emulator-5580 (API 35, adb install, so `R = likely`): Continue → Accessibility → back → field 14 with
  Open Settings once → App info → back → nothing opens; Back on field 14 returns to the card; Notification access path
  the same; Vietnamese strings "Tiếp tục" / "Mở cài đặt". The emulator was put back (appops `default`, locale, data
  and the "E2E Test Mac" pair kept). The S25 was not touched.
- Reviews: BA (Thảo), tester (Lan), pentester (Khoa) approved both tasks; remaining lows fixed (`b50c05e`, `b676e20`,
  `cc2a59b`, `bcf7325`).

## S25 replay (06:34–06:39, owner approved; One UI 8, Android 16, locale vi-VN)

The fix APK (`adb install -r`, same debug signer, pairing kept) was installed, the HandLive service turned off and the
op set to `deny`, then the flow was driven through the UI:

| Step | Seen |
|------|------|
| Settings › Tự gửi khi sao chép (on, service off) | "Chưa bật tự gửi"; switch on → field 14 with **Tiếp tục** |
| Tiếp tục → Hỗ trợ › Ứng dụng đã cài đặt | HandLive greyed out, "Do chế độ Cài đặt hạn chế kiểm soát" |
| Tap HandLive | dialog "Ứng dụng đã bị từ chối cấp quyền"; op went `deny` → **`ignore`** (AOSP model confirmed on One UI) |
| Đóng, Back to HandLive | field 14 shown again by itself with **Mở cài đặt** (E8) |
| Mở cài đặt | App info "Thông tin ứng dụng"; ⋮ lists **"Cho phép cài đặt bị hạn chế"** |
| Allow (needs the owner's PIN/biometric, so `appops set … allow` stood in), Back | HandLive, nothing opened by itself |
| Switch off/on → Tiếp tục → HandLive → Tắt → "Cho phép" (full control) → back | card "Đã đồng ý lúc 21:11, 29 Th9, 2026" (on) |

Phone put back: service list identical to before, Chrome in front, still connected to the MacBook Pro. The op is left
at `allow` (what Allow sets in AOSP) instead of the earlier `default`, so Android does not guard HandLive again.

Findings for G1 / a follow-up (not changed here):
- One UI Vietnamese names differ from `setup.restricted_settings_help*`: Accessibility is "Hỗ trợ" (string: "Hỗ trợ
  tiếp cận"), the menu item is "Cho phép cài đặt bị hạn chế" (string: "Cho phép chế độ cài đặt bị hạn chế"), the block
  shows as "Ứng dụng đã bị từ chối cấp quyền" / "Do chế độ Cài đặt hạn chế kiểm soát" (string quotes "Chế độ cài đặt bị
  hạn chế"). Pixel/AOSP names still unchecked; the strings may need OEM-neutral wording.
- In Settings, tapping the Auto-Send row while it reads "Chưa bật tự gửi" turns the switch off (it is a switch); the
  way back is off → on, or the Permissions card. Worth a look in SET-02.

## Workspace notes

- Worktrees: hub `.claude/worktrees/restricted-settings-detect`; android and shared under
  `.worktrees/restricted-settings/` with `docs` symlinked to the hub worktree (`:core:design` tests read `../docs`).
  The main `android/` and `apple/` checkouts were left alone: another session was fixing clipboard HTML there.
- `ANDROID_HOME` on this machine is `/opt/homebrew/share/android-commandlinetools`.

## Unresolved questions

- Owner decided 06:33: PRs and merge (done), S25 replay (done, above), no reminder in the service notification.
- Vietnamese restricted-setting strings vs One UI names (above): reword OEM-neutral or per OEM?
- G1 checklist: One UI Vietnamese names ("Cho phép chế độ cài đặt bị hạn chế", "Thông tin ứng dụng"); TalkBack reads
  the title first when field 14 shows by itself; API 33/34 behaviour (no AVD here).
- WEB-01 (after G6): logic 6/7 must tell the clipboard service from "HandLive Browser Pages" and honour `feature.web`.

Status: DONE_WITH_CONCERNS
Summary: Field 14 now comes back on return and consent is asked once, on hub + android branches, reviewed and green;
the app-op read is impossible on Android 15, so detection stays the install source.
Concerns/Blockers: One UI Vietnamese setting names differ from the strings (G1 follow-up).
