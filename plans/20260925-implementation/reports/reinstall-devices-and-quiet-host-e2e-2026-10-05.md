# Reinstall of the 2026-10-05 fix on the owner's devices, and the quiet-host e2e (2026-10-05, 02:58–03:30)

Owner ask: reinstall the app on the Mac and the S25, then run the rest of the plan. Plan: `plans/20261005-reinstall-devices-and-quiet-host-e2e/plan.md`. Issue: HandLive/handlive#4. Builds: android `main` `bbdc6af`, apple `main` `84ffa11` (both carry the clipboard image fix of HandLive/handlive-android#1).

## 1. What was installed before

| Device | Build found | Signer / identity |
|--------|-------------|-------------------|
| Galaxy S25 Ultra (`R5GL320PPZT`, Android 16) | `app.handlive.android` 0.1.0-beta.2, **debuggable**, installed 2026-10-04 20:56 | this Mac's debug keystore (`~/.android/debug.keystore`) |
| Mac (`/Applications/HandLive.app`, 2026-10-01) | **Debug** build, bundle `app.handlive.mac.localtest`, 0.1.0 (1) | Apple Development me@hxd.vn, team 3S93UPADXV, `keychain-access-groups 3S93UPADXV.app.handlive.mac`, no notification entitlements |

Both are development builds, so both write `HLBENCH/1` lines (release builds never do). That is what the owner's device check needs.

## 2. Reinstall (pairing kept on both sides)

- **S25:** `adb install -r` of the foss debug APK built from `main` (`JAVA_HOME` set, 60 MB). "Success"; `lastUpdateTime 2026-10-05 03:02:34`, `pkgFlags DEBUGGABLE`; `databases/handlive.db` and the DataStore survived. `versionName` still reads `0.1.0-beta.2` (the version string on `main` has not moved).
- **Mac:** `xcodebuild -configuration Debug` of apple `main` with the installed app's identity: `PRODUCT_BUNDLE_IDENTIFIER=app.handlive.mac.localtest DEVELOPMENT_TEAM=3S93UPADXV CODE_SIGN_STYLE=Automatic` and a reduced entitlements file holding only `keychain-access-groups $(AppIdentifierPrefix)app.handlive.mac`. A personal team cannot provision the Communication / Time-Sensitive Notifications entitlements of `macOS/HandLive.entitlements`, so the first attempt failed with "Cannot create a Mac App Development provisioning profile … do not support …"; the installed app never had those entitlements either. Old bundle quit and kept at `<scratchpad>/HandLive-old-2026-10-01.app`; new bundle copied to `/Applications`, `codesign --verify --deep --strict` OK, relaunched.
- **Reconnection:** Mac `HLBENCH` `ev=state` Idle → Discovering → ConnectingLAN → Handshaking → **Connected**; the S25's service notification "Đã kết nối với MacBook Pro" posted at 03:05:28, right after the relaunch. No re-pairing was needed.
- Pitfall found and recorded: `log` is a zsh builtin, so `log show`/`log stream` in a shell command do nothing; use `/usr/bin/log --info`.

## 3. Quiet-host e2e (roadmap "Plan next" item 4)

API 35 emulator `hl-claude-api35` (google_apis, headless), APK of `main`, fresh state dir, the Mac build finished first: `e2e.py all` → **0 FAIL**.

| Scenario | Result | Notes |
|----------|--------|-------|
| setup | 27 PASS, 1 INFO | PIN pairing (wrong PIN → `PIN_INVALID`, "2 attempts left", field usable while the Mac is connected), feature list after the first pairing, handshake 25 ms (target 300), 4409 replace, **4408 after 5023 ms (target 5000)**, **4411 after 45 119 ms (target 45 000)** |
| clipboard | 16 PASS, 2 SKIP | Mac → phone text 61 ms (target 50, emulator); phone → Mac PNG 0.3 MB byte-exact (8.2 s incl. UI); Mac → phone PNG 300 kB 429 ms, 5 MB 2063 ms (target 2000); CLIP_TOO_LARGE, CHECKSUM_MISMATCH. SKIP: the 3 MB phone → Mac step ("Chrome offered no Copy image entry", a driving flake of the new step, passed at 01:54 and 02:00), the Accessibility auto path (by design) |
| sms | 36 PASS, 1 SKIP, 1 INFO | late permission grant → new capability reflects it; sync paging, history, send with `sms/status`, read_changed, revoked `READ_SMS`. SKIP: the emulator cannot deliver an SMS to itself |
| calls | 35 PASS, 1 SKIP, 2 INFO | answer/decline/end from the Mac, log_new, log_sync; bench: state LAN p95 92 ms (target 200), answer → offhook 200 ms (target 500), answer/decline back on client p95 234 ms (target 500). SKIP: waiting call (emulator modem) |

API 29 emulator `hl-api29`: two findings and a green rerun, see §5.

Timings on an emulator on this host are trends only (gate G1 needs real devices); the two targets above the line (text 61 vs 50 ms, 5 MB image 2063 vs 2000 ms) were within 20 % on a host that was also building.

## 4. Device check status

Monitors on both sides ran from 03:08 (S25 `adb logcat -s HLBENCH:I`, Mac `/usr/bin/log stream --info`). Owner's own logcat showed one `clip_read kind=text source=manual` at 02:55 (before the reinstall). Image copy events seen while attached: see §5.

## 5. API 29 (Android 10, `hl-api29`, google_apis, headless) and live events

Two findings, one in the harness and one in the app:

1. **Harness:** on this image `uiautomator dump` shows only HandLive's window while the system dialog `com.android.settings/.fuelgauge.RequestIgnoreBatteryOptimizations` is the resumed activity (ActivityTaskManager logged its start on Continue). The harness never found `android:id/button1`, never tapped Allow, and every later setup step failed behind the dialog. Fix: when the button is missing and that dialog is resumed, grant with `dumpsys deviceidle whitelist +app.handlive.android`, press BACK and record an INFO line (shared `fix/e2e-api29-battery-dialog` → HandLive/handlive-shared#2, merged `aac5f4d`).
2. **App (HandLive/handlive-android#2):** with the dialog out of the way, PIN pairing died twice with `OutOfMemoryError "Failed to allocate a 67108880 byte allocation … growth limit 50331648"` on the pairing dispatcher: the pure-Kotlin Argon2id keeps `K_pin`'s 64 MiB (0.6.2, fixed by the spec) in one Java array, and the app's heap growth limit is 48 MB on this emulator (`dalvik.vm.heapgrowthlimit`; 256 MB on the S25, 128–192 MB on low-end phones). The fake Mac saw close 1006 and the phone stayed on "Pairing…". Fix: `android:largeHeap="true"` with a manifest comment (android `fix/pin-pairing-large-heap`); moving the Argon2 memory off the heap stays open in the issue.

Rerun with the largeHeap APK (`e2e.py setup clipboard`, fresh state): **setup 25 PASS, 2 INFO** — PIN pairing completes (8844 ms on this slow image), **4408 after 5008 ms** (target 5000), **4411 after 45 349 ms** (target 45 000); clipboard 15 PASS, 3 SKIP (Chrome on Android 10 offers no "Copy image" long-press entry, so both phone → Mac image steps skip with that reason; the Accessibility auto path by design). Android PR: `fix/pin-pairing-large-heap`.

Live events while attached (03:08–03:30): the owner's copies on the Mac were text (4, 11 and 4 bytes); each went `copy_detected → clip_read → clip_sent` on the Mac and `clip_received → clip_applied → ack_sent applied` on the S25 within the same second. No image copy was made in that window, so the S25 image hypothesis (One UI clipboard, system-uid URI grants) is still open; the owner's check in CLAUDE.md item 8 stands. One `Connected → Idle → … → Connected` cycle at 03:14:43 matched a macOS sleep attempt that powerd reverted.

## 6. The S25 answer (03:51)

The owner copied an image on the S25 with the diagnostics build attached: **no HLBENCH line at all** — no `copy_detected`, no read. `settings get secure enabled_accessibility_services` lists only the web spike's service and Link to Windows; `dumpsys accessibility` shows HandLive's `ClipboardAccessibilityService` installed but **not enabled**; `appops get … ACCESS_RESTRICTED_SETTINGS` says `default; rejectTime=+5d…` — Android 13+ refused to turn the service on because the APK is sideloaded (`installerPackageName=null`, SET-01 E7 "Restricted setting"), about five days earlier. So automatic sending on copy has never been active on this phone; every phone → Mac clip tonight went through the manual button, and an image copied without pressing it does nothing by design (CLIP-01 E1). The one `copy_detected` at 03:29:47 came from the in-app listener (HandLive in the foreground), after which the read found nothing to send on that clip.

Owner steps: Settings › Apps › HandLive › ⋮ › Allow restricted settings (authenticate), then Settings › Accessibility › HandLive › On (the app's RestrictedSettingScreen already says this, SET-01 field 14); meanwhile the manual path (notification button, tile) works for images too, as the emulator e2e shows. The One UI URI-grant hypothesis stays untested until the service is on or the button is pressed with an image on the clipboard.

## 7. Resolved (03:57)

The owner allowed the restricted setting and turned HandLive on in Accessibility (`ACCESS_RESTRICTED_SETTINGS` rejectTime reset to seconds ago; `enabled_accessibility_services` now lists `ClipboardAccessibilityService`). The next image copy in Samsung Gallery went through in 0.5 s: S25 `copy_detected 03:57:44.216 → clip_read kind=image bytes=171108 source=auto → clip_sent`; Mac `clip_received kind=image → clip_applied → ack_sent applied`; S25 `ack_received applied` at 03:57:44.719. **Root cause of "image copy fails" on the S25: Android 13+'s restricted-settings rule kept the sideloaded app's Accessibility service off, so no copy was ever detected; the sync code was sound.** The night's code changes still stand on their own merits (image URI precedence, lost-grant message, `largeHeap`, diagnostics). Mac → S25 image: not yet exercised by the owner.

## Unresolved questions

1. The 3 MB phone → Mac e2e step skipped once because Chrome showed no "Copy image" in its long-press menu; make the step retry the long-press or fall back to Google Photos.
2. The S25 image copy still needs the owner's action while a monitor is attached.

Status: DONE_WITH_CONCERNS
Summary: Both devices run the fixed builds without re-pairing and are connected; the quiet-host e2e passed every step the emulators can run on API 35 and, after a harness fix and the largeHeap fix, on API 29; the S25 image copy was not exercised by the owner while attached.
Concerns/Blockers: none blocking; the Chrome-driving flake of the new e2e step is a follow-up.
