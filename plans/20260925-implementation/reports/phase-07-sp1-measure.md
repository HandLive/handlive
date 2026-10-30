English | [Tiếng Việt](phase-07-sp1-measure.vi.md)

# SP1 real-device measurement: Bluetooth control channel (Samsung Galaxy S25 + Mac)

Goal: measure AC1 (text envelope latency) and AC2 (reconnect time) of the Bluetooth control channel on real
hardware, with both devices offline. The owner decided to measure SP1 before continuing Phase 7. Targets:
`phase-07-ket-noi-moi-noi.md` AC1/AC2. `reports/phase-07-spike-g7.md` has the numbers from the throwaway spike;
this run repeats them on the real app.

## Wiring check (done 2026-10-29, before this runbook was written)

Confirmed on the real app path, not just classes that exist unused:

- Android: `ConnectionRuntime.startLocked()` calls `bluetooth.start(...)` (`BluetoothAdvertising`) beside the LAN
  server (`handlive-android/feature/connection/src/main/kotlin/app/handlive/android/feature/connection/ConnectionRuntime.kt:213`).
  `ConnectionRuntime` is created and run by the real foreground service, `HandLiveService.onStartCommand`
  (`handlive-android/feature/connection/src/main/kotlin/app/handlive/android/feature/connection/HandLiveService.kt:50`).
- macOS: `AppModel`'s default `makeManager` builds `ConnectionManager(localCapability:, relay:)`
  (`handlive-apple/Packages/HLMacUI/Sources/HLMacUI/AppModel.swift:108`), whose default `bluetooth` parameter is
  `ConnectionManager.defaultBluetoothCentral()`, which is `CoreBluetoothCentral()` on macOS
  (`handlive-apple/Packages/HLTransport/Sources/HLTransport/ConnectionManager.swift:91-96`).

Both sides are wired for real. No blocker to measuring AC1.

**Known gap, not a blocker, flagged to Lead separately:** `bt_seen`/`bt_lost` bench events (named in AC2 and in
`shared/tools/bench/README.md`) are not emitted anywhere in production code — only in the throwaway spike
(`handlive-apple/Tools/BLESpike`, `handlive-android/tools/ble-spike`). `CoreBluetoothCentral.swift` has zero
`BenchLog.event` calls. `reconnect_time.py` still produces a usable number without them: it falls back to
`since_loss_ms` (Connected → leaves Connected → Connected again) when no `bt_seen`/`wake`/`net up` trigger is
found in the window, which is a safe upper bound on AC2's "time since the peer was seen again". Use that column.

## Conditions

- Both devices **offline**: Wi-Fi off on the S25 (Settings → Wi-Fi) and on the Mac (menu bar), mobile data off on
  the S25. Bluetooth **on** on both.
- The two devices must already be **paired from a previous LAN session** (flow A, `pairing_secret` stored) —
  SP1 only exercises the Bluetooth control channel of an existing pair, not pairing itself (A7.2/M7.2, not done
  yet).
- S25 connected to this Mac over USB with `adb` (USB debugging on). Run the script on this same Mac, since it is
  also the measurement device for the Bluetooth side.
- Xcode command-line tools and `xcodegen` installed (`brew install xcodegen` if missing).

## Steps

The measurement runs in up to three **log sessions**. `clip_latency.py` groups clips by type (text or image), not
by condition, so text clips from the idle pass, the load pass and the Doze pass must sit in separate log files or
their numbers mix. Each run of the script starts a new session with new log files.

### Session 1: AC1 idle, AC2, scan response

1. `zsh handlive/tools/measure-sp1.sh [adb_serial]` (omit `adb_serial` when only one device is attached). It:
   - builds and installs the debug APK on the S25, grants `BLUETOOTH_ADVERTISE`/`BLUETOOTH_CONNECT` (there is no
     permission screen yet — A7.7a/b are not built — so the script grants them directly via `pm grant`), opens
     the app;
   - runs `xcodegen generate` + `xcodebuild build` for the macOS app (scheme `HandLive`, Debug) and opens it;
   - starts `adb logcat` and `log stream`, writing `HLBENCH/1` lines to
     `handlive/.build-logs/sp1-<timestamp>-android.log` and `...-mac.log`. The script prints both paths; keep
     them for the checks below.
2. Confirm the link is really on Bluetooth. **The Mac's status indicator shows Wi-Fi even on a Bluetooth link**
   (temporary placeholder label until the Bluetooth strings land, `AppModel+Link.swift:109`), so do not judge by
   the label. In a second terminal, run:

   ```sh
   grep 'ev=state' <mac log path> | tail -n 1
   ```

   The line must end with `to=Connected channel=bluetooth`. Run it again whenever you need to check the link
   during this session.
3. AC1 idle: copy a short text clip on one device, confirm it lands on the other, repeat **at least 30 times**, a
   few seconds apart, alternating direction. When done, run the `grep` from step 2 again: if the last line is
   not `to=Connected channel=bluetooth`, or the log shows `to=ConnectingBT` repeatedly, note it — that is itself a
   finding, not expected noise.
4. AC2: toggle Bluetooth off then on again on the S25 (Settings → Connected devices → Bluetooth, or the Quick
   Settings tile), wait until the `grep` from step 2 shows `to=Connected channel=bluetooth` again, then repeat
   **at least 5 times**. A phone screen-off period between rounds is fine and closer to real use.
5. Scan-response check (spec risk, 0.4.5 "Advertisement"): lock the S25 screen (keep Bluetooth on) and wait about
   a minute. On the Mac, quit HandLive (Cmd-Q), then open it again with `open <macOS app path>` (the script printed
   the path on the `App macOS:` line). With the phone screen still off, confirm the Mac connects again (`grep`
   from step 2) and that a new `bt_accept` line appears in the Android log:

   ```sh
   grep -c 'ev=bt_accept' <android log path>
   ```

   The count must go up by at least one. This checks the "service data read on Mac even in background"
   acceptance line of A7.1b/M7.1c with the phone's screen off.
6. Press Ctrl-C in the script's terminal to stop logging. It prints the two log paths and line counts.

### Session 2 (optional): AC1 under load

7. Run `zsh handlive/tools/measure-sp1.sh --log-only [adb_serial]` — same as step 1 but skips the APK build/install
   and the Xcode build, reusing the app already installed/built by session 1 and just reopening it on both
   devices (fails with a clear message if session 1 was never run in full). Confirm the Bluetooth link (step 2).
   Start a large image copy (≈5 MB) in one direction and, while it is in flight, do a few short-text copies in the
   other direction. Repeat until you have about 10 text copies. Expected to be **much worse** per the spike (FIFO
   queue, no priority lane yet — D7.1/A7.4 not built). Record the number; a miss here is not a blocker. Ctrl-C to
   stop.

### Session 3: AC1 with the phone in Doze

8. Run `zsh handlive/tools/measure-sp1.sh --log-only [adb_serial]` (same reuse as step 7) and confirm the Bluetooth
   link (step 2). Put the S25 into Doze with the same commands the spike used (add `-s <adb_serial>` after `adb`
   when more than one device is attached):

   ```sh
   adb shell dumpsys battery unplug
   adb shell input keyevent KEYCODE_SLEEP
   adb shell dumpsys deviceidle force-idle
   ```

9. Leave the phone untouched. On the **Mac only**, copy a short text clip about every 30 seconds, **at least 30
   times** (about 15 minutes, like the spike's Doze pass). Only the Mac → phone direction is measured here: the
   phone's screen stays off.
10. Restore the phone, then Ctrl-C to stop logging:

    ```sh
    adb shell dumpsys deviceidle unforce
    adb shell dumpsys battery reset
    adb shell input keyevent KEYCODE_WAKEUP
    ```

## Reading AC1 / AC2 from the logs

The two tools below already exist and are channel-agnostic (they read `clip_read`/`clip_applied`/`state`
regardless of whether the session is LAN or Bluetooth — `ConnectionRoute.benchChannel` on macOS, and `state`'s
own `channel` field). Run them on each session's pair of logs:

```sh
python3 handlive-shared/tools/bench/clip_latency.py \
  handlive/.build-logs/sp1-<ts>-android.log handlive/.build-logs/sp1-<ts>-mac.log --json

python3 handlive-shared/tools/bench/reconnect_time.py \
  handlive/.build-logs/sp1-<ts>-mac.log handlive/.build-logs/sp1-<ts>-android.log --json
```

- AC1: `clip_latency.py`'s bucket **"text inline"** — from session 1 for idle, session 2 for under load, session
  3 for Doze. Its built-in target (50 ms, `--check`) is the **LAN** target from Phase 1 — ignore `--check`'s
  verdict here and compare the printed `p95` by hand against **200 ms** (sessions 1 and 2) or **3000 ms**
  (session 3, Doze — owner-accepted relaxed threshold for that condition only, since the spike measured p95 ≈
  664 ms one-way under real Doze).
- AC2: `reconnect_time.py` on the session 1 logs. Read `since_loss_ms` (not `reconnect_ms`, which needs `bt_seen`
  — see the gap above) at its **p95** across the step-4 rounds, compare by hand against **3000 ms**.
- A transfer or episode the tools can't pair (missing `clip_applied`, no return to `Connected`) is dropped
  silently from the percentile — if the count in the output is smaller than the copies or rounds actually done,
  say so in the results, don't just report the percentile.

## Results (fill in after measuring)

| Scenario | Metric | Target | n | p50 | p95 | Met? |
|---|---|---|---|---|---|---|
| AC1, idle, established link (session 1) | text inline latency (one-way, `clip_applied` − `clip_read`) | ≤ 200 ms | | | | |
| AC1, during a 5 MB image transfer (session 2) | same | ≤ 200 ms | | | | |
| AC1, phone in Doze, Mac → phone (session 3) | same | ≤ 3000 ms (relaxed) | | | | |
| AC2, Bluetooth toggle off/on (session 1) | `since_loss_ms` | ≤ 3000 ms | | | | |
| Scan response, phone screen off (session 1, step 5) | Mac reconnects, new `bt_accept` line | pass/fail | | — | — | |

## Risks called out in the spec, carried into this measurement

- **Scan response** (0.4.5 "Advertisement"): the spike never tried it; A7.1b/M7.1c's acceptance line requires
  "scan response contains service data read on Mac, even when app is in background" — step 5 above is the first
  real check of this on production code.
- **Doze RTT**: the spike measured p95 ≈ 664 ms one-way during 15 minutes of forced Doze on the spike's own
  loopback, against the general 200 ms target — hence the separate 3000 ms threshold accepted for that condition
  only; this run is the first measurement on the real app's scheduler/session code instead of the spike's.
- **Hint/PSM rotation** (`BT_HINT_PERIOD` = 15 minutes, `00-common-specs.md:1370`): a run longer than ~15 minutes
  crosses a rotation boundary; if AC2 numbers look unusually bad for one round only, check whether that round
  straddled a rotation (the advertising set and PSM both change at the boundary, `00-common-specs.md:225`) before
  calling it a regression.
