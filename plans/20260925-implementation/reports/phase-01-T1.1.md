# Phase 1 — T1.1: latency and reconnect measurement

Card T1.1 of `phase-01-bang-nho-tam-mvp.md`: scripts in `shared/tools/bench/` that compute clipboard text/image latency and reconnect time from timestamped logs of both devices, the log format both apps must emit, and a manual test script for the device matrix (plan.md §5). Branch `feat/phase-01-clipboard` of handlive-shared, pushed; CI `ci-shared` green (run 36157996078, "bench self-test: 22 passed, 0 failed"). Committed under the workspace lock.

**The measurement table itself cannot be produced here**: it needs debug builds of the Android and Mac apps that emit the `HLBENCH/1` lines (A1.3, M1.4 and the connection cards) and the real devices of the matrix. The scripts were verified only on synthetic logs.

## What was done

- **Log format `HLBENCH/1`** (defined in `tools/bench/README.md`): one line per event, debug builds only, Android `Log.i("HLBENCH", …)`, macOS `Logger(subsystem: "app.handlive.mac", category: "bench")` with `privacy: .public`. Fields `wall` (epoch ms), `mono` (monotonic ns that counts sleep: `SystemClock.elapsedRealtimeNanos()`, `clock_gettime_nsec_np(CLOCK_MONOTONIC_RAW)`), `dev` (first 8 hex digits of `device_id`), `role`, `ev`. Events: `copy_detected`, `clip_read` (start of the QC9 latency), `clip_sent`, `clip_received`, `clip_applied` (end), `ack_sent`, `ack_received`, `state` (0.11 transitions, `channel` with `Connected`), `net` (`up`/`down`/`changed`), `wake`. No clipboard content, names or addresses (QC2).
- **Clock sync without extra traffic** (`clock_sync.py`): each `clipboard/push` and its `ack` give the four NTP timestamps, so the offset is `((t2 − t1) + (t3 − t4)) / 2` with error ≤ half the round trip; per measurement the smallest-round-trip exchange within ±120 s is used (drift-proof), a device two hops away (iPad via the phone) is chained, `--offset A:B=MS` covers sessions without clips, and "assumed 0" is reported when nothing is known. This answers the card's "NTP or envelope `ts`" choice: envelope-level acks already give a better estimate than NTP-synced wall clocks.
- **`clip_latency.py`**: per transfer the latency `clip_applied` − `clip_read` on the sender's clock, copy detection shown apart, the split into sender, network and receiver time, forwarded clips (QC6) marked with 2 hops; clips read but never applied (conflict, loss, missing log) listed; summary per bucket — text inline (≤ 180 KiB, target 50 ms), text chunked, images below 4.5 MB, about 5 MB (target 2 s), above — with median, p95, max and PASS/FAIL on the p95; `--json` for reports, `--check` exits 1 on a miss.
- **`reconnect_time.py`**: per client episode from leaving `Connected` to the next `Connected`, the trigger is the last `net up/changed` or `wake` on any device after the previous connection came up (the phone's times put on the client's clock); target 3000 ms on the p95; episodes without a trigger (pong timeout, service restart) report only the time since the loss.
- **`collect_logs.sh`** (records `adb logcat -s HLBENCH:I` and `log stream` for one session; shellcheck clean), **`make_test_png.py`** (incompressible PNG of a given size, standard library: 5 000 000 → 1290×1290, 4 995 173 bytes, read back by `sips`).
- **`self_test.py`**: synthetic Mac, phone and iPad logs with clock skews of 0, +1234.5 and −250 ms and known timings; checks the offsets (direct and chained), every latency to 0.01 ms, detection, breakdown, the forwarded clip, the refused clip, the bucket summary and `--check`, three reconnect episodes (Mac Wi-Fi, phone Wi-Fi on the Mac's clock, no trigger), manual and assumed offsets, and that a malformed line is reported without stopping the run. CI runs it.
- **Manual test script for the device matrix** (README, section "Manual test on the device matrix"): preparation per phone × Mac pair, scenarios T1–T4 (text both ways, manual send, chunked text), I1–I2 (5 MB, 1 MB, 10 MB and a refused 11 MB image), R1–R5 (Mac Wi-Fi off/on, SSID switch within the LAN, phone Wi-Fi off/on, Mac sleep/wake, phone Doze) with repeat counts, and the result table to fill (p95 per direction, reconnect, not applied, notes) with the pass rule.

## Commits (handlive-shared, branch `feat/phase-01-clipboard`)

| Hash | Subject |
|------|---------|
| 69da15c | feat(shared): measure clipboard latency and reconnect time from device logs |
| 41ded87 | feat(shared): add log capture and test image tools for the device matrix |
| 99b78e4 | docs: define the HLBENCH/1 log format and the device matrix test |
| 98fa525 | ci: run the benchmark self-test in ci-shared |

## Files

Created: `shared/tools/bench/{bench_log,clock_sync,clip_latency,reconnect_time,self_test,make_test_png}.py`, `shared/tools/bench/collect_logs.sh`, `shared/tools/bench/README.md`, `shared/tools/bench/README.vi.md`. Changed: `shared/.github/workflows/ci-shared.yml`, `shared/README.md`, `shared/README.vi.md`.

**For the Android and Apple agents:** emit the `HLBENCH/1` lines of `shared/tools/bench/README.md` at the listed points (A1.1, A1.3, M1.2, M1.4) in debug builds; the gate G1 measurement depends on them. The plan's "`tools/bench/clip-latency`" (A1.3) is `tools/bench/clip_latency.py`.

## Tests (real output)

```text
$ python3 tools/bench/self_test.py
bench self-test: 22 passed, 0 failed

$ python3 tools/bench/clip_latency.py <synthetic logs of self_test.py>
skipped android.log:20: could not convert string to float: 'nope'
clip                                  kind      bytes  sender→receiver   hops  latency  detect   send    net   recv  clock offset receiver-sender
0192f3e0-0000-7000-8000-00000000000a  text         27  8c7d6e5f→5b1f8c2e    1      6.0   300.0    1.0    3.0    2.0  -1234.5 ±3.0 (exchange)
0192f3e0-0000-7000-8000-00000000000d  image   5000000  5b1f8c2e→8c7d6e5f    1   1400.0       —    1.0    3.0 1396.0  1234.5 ±3.0 (exchange)
0192f3e0-0000-7000-8000-00000000000e  text         50  5b1f8c2e→a1b2c3d4    2     16.0       —      —      —      —  -250.0 ±7.0 (chain)
summary (direct transfers, ms)
  text inline     n=4    median=7.0 p95=64.0 max=64.0  target < 50 → FAIL
  image ≈ 5 MB    n=1    median=1400.0 p95=1400.0 max=1400.0  target < 2000 → PASS

$ python3 tools/bench/reconnect_time.py <same logs> --check
client    lost to      trigger                reconnect since loss  channel
5b1f8c2e  Backoff      net up on 5b1f8c2e          1250       3050  lan
5b1f8c2e  Backoff      net up on 8c7d6e5f          2200       4700  lan
5b1f8c2e  Backoff      loss                           —        900  lan
summary: n=2 median=1250 p95=2200 max=2200 ms, target < 3000 → PASS
```

(The synthetic set deliberately contains one 64 ms text clip, so the text bucket fails; rows abridged.)

## Measurements

| Phone (Android) | Mac (macOS) | Text phone → Mac | Text Mac → phone | Image 5 MB phone → Mac | Image 5 MB Mac → phone | Reconnect | Not applied | Notes |
|-----------------|-------------|------------------|------------------|------------------------|------------------------|-----------|-------------|-------|
| Pixel 8 | Apple silicon | not run | not run | not run | not run | not run | — | needs app builds with HLBENCH/1 and the devices |
| Galaxy S22/S23 | Intel | not run | not run | not run | not run | not run | — | same |

## Spec deviations and proposals

1. **Where latency starts.** The phase goal says "from copying to being able to paste on the other device"; QC9 excludes copy detection. The scripts report the QC9 latency against the targets and show copy detection (`copy_detected` → `clip_read`) apart, so both readings are available. Proposal: state in the Phase 1 file that the 50 ms target is QC9's.
2. **Percentile.** The specs give "< 50 ms", "< 2 s", "< 3 s" without saying over which statistic; the scripts judge the 95th percentile and always print the maximum. Proposal: write p95 into gate G1.
3. **Log hooks are a new contract** for the apps (debug builds only). Proposal: mention `shared/tools/bench/README.md` in A1.3, M1.4, A1.1 and M1.2 of the Phase 1 file.

## Pending manual checks

- The whole device-matrix run (README scenarios T1–R5) on Pixel, Samsung, and the Apple silicon and Intel Macs, once the apps emit `HLBENCH/1`; fill the measurement table above.
- `collect_logs.sh` against real devices (`adb` and `log stream` availability, the `privacy: .public` logging on the Mac).

Status: DONE_WITH_CONCERNS
Summary: The HLBENCH/1 log format, the latency and reconnect scripts with NTP-style clock sync from push/ack exchanges, the capture and test-image tools, the self-test (in CI) and the device-matrix procedure are pushed on feat/phase-01-clipboard of handlive-shared.
Concerns/Blockers: No measurements yet — they need app builds that emit HLBENCH/1 and the real devices; the scripts are verified on synthetic logs only.
