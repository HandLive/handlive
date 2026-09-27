# Phase 3 — end-to-end tests: the real Android app against a fake Mac and the real Mac app (2026-09-27/28)

Owner's question: do pairing, clipboard, SMS and calls work end to end on the real Android app, and do calls and SMS
reach the other devices (LAN and relay)? This report answers with runs of a new harness, `shared/tools/e2e/`, against
the real app on Android emulators, then with the real Mac app. The harness runs changed no Android code; bugs are
listed with evidence and what happened to them.

Code under test: android `eccf499` (feat/phase-03-calls), foss debug. LAN runs used a clean export of that commit built
in the scratchpad (same commit; the controller was running Gradle in `android/`); the shared emulator 5554 runs used
the relay agent's build of the same commit with its two debug relay patches (`relay_stack/android_patches/`).
Harness: shared `feat/phase-03-calls` (commits below). Relay: the relay agent's local stack (relay `ee0532e`).

## What was built — `shared/tools/e2e/`

| File | What |
|------|------|
| `e2e.py` | The command: `setup`, `clipboard`, `sms`, `calls`, `all`; stage 2 `relay`, `push`. Options: `--serial`, `--apk`, `--state-dir`, `--host-port`, `--step-delay` (default 1 s, 0 = fast), `--shared-device`, `--lock-dir` (per-scenario emulator lock, stale after 30 min), `--relay-state` |
| `fake_mac.py` | The fake Mac/iPhone: identity, capability (as `apple/…/LocalDevice.swift` builds it), PIN pairing, sessions |
| `mac_crypto.py` | Keys, PIN pairing (Argon2id K_pin, K_pa, T_offer, confirm/done, PRK, attestation, Security Code), session keys (T1/T2), envelopes, chunks, K_push — all from `tools/vectors` derivations |
| `mac_pairing.py`, `mac_session.py` | `/v1/pair` PIN client (wrong PIN → `pair/error PIN_INVALID` + attempts left); `/v1/ctl` client: handshake, capability, receive thread, ack matching, events, auto-ack of phone clips, `session/bye` |
| `transport.py` | TLS 1.3, leaf-certificate SHA-256 pin checked before the WebSocket upgrade, WS ping 15 s / pong 10 s, `abort()` = leave without close frame |
| `relay_client.py` | Relay account (HLREG1/HLAUTH1 via `relay_stack/stack_rest.py`), `POST /v1/pairs`, `GET /v1/pairs`, APNs token; `/v1/relay` link with `{to,env}`/`{from,env}` wrappers; a relay channel that carries the same session |
| `schema_check.py` | Every message sent and received validated against `shared/schemas` (payload per `<type>-<op>`, acks per `#ack`/`#ack-failure`, relay wrappers and control ops) |
| `adb_device.py`, `ui_automator.py` | adb (install, `pm grant/revoke`, forward, logcat, crash filter by time), emulator console (TCP + token) and `adb emu gsm/sms`, SMS and contacts providers, `telephony.registry` call state; uiautomator dump + tap by catalog text (`shared/strings/ui-strings.json`) |
| `bench_lines.py` | `HLBENCH/1` lines with `role=macos`; `calls` runs `tools/bench/call_latency.py` on the phone's logcat + these |
| `scenario_*.py`, `steps.py` | Scenarios; PASS/FAIL/SKIP/INFO per step with spec reference and latency, `results.json` |
| `self_test.py`, `fake_phone.py` | CI self-test (no emulator): vectors replay (PIN pairing, session, envelopes, chunks, K_push), full client vs an in-process fake phone over TLS, relayed session through `tools/bench/relay_load_fake.py`, UI parser, HLBENCH parse. Wired into `ci-shared` |
| `README.md`, `README.vi.md`, `requirements.txt` | Docs (en/vi); pins `websockets==17.1` + vector/schema requirements |

State (keys, pair, logs) lives in `--state-dir` outside the repo (mode 0600 pair file). Numbers are fictional
(+1 201 555 01xx, accepted by libphonenumber; +1 555 numbers are not); contact "E2E Test Contact".

## Commits (handlive-shared, `feat/phase-03-calls`, pushed)

Harness commits: `a2c6292` fake Mac client, `ff4a2e4` emulator driver, `e632cd6` self-test, `eb70fe7` setup scenario,
`361bdae` clipboard scenario, `a2c99f3` call state and emulator console, `b67ebe4` SMS scenario, `b4e2ee8` call scenario,
`2030273` README (en/vi), `6bc9c7a` one emulator shared safely, `893b02f` sessions through the relay, `75254f0` busy shared
emulator, `5370638` relay and push scenarios. The local relay stack commits are listed in `phase-03-e2e-relay.md`.

## How to run

```sh
cd shared
tools/.venv/bin/pip install -r tools/e2e/requirements.txt
tools/.venv/bin/python tools/e2e/self_test.py                                  # CI part, "0 failed"
tools/.venv/bin/python tools/e2e/e2e.py all --serial emulator-5556 --apk <app-foss-debug.apk>          # own emulator
tools/.venv/bin/python tools/e2e/e2e.py setup clipboard sms calls --serial emulator-5554 --shared-device --host-port 47820
tools/.venv/bin/python tools/e2e/e2e.py relay push --serial emulator-5554 --shared-device --host-port 47820   # stage 2
```

## Results against the real Android app (android `eccf499`)

| Emulator | Scenarios | PASS | FAIL | SKIP / INFO |
|----------|-----------|------|------|-------------|
| 5556 (own) | setup, clipboard, sms, calls | 110 | 4 | 3 / 6 |
| 5558 (own, second run of setup) | setup | 20 | 4 (1 environment) | 0 / 2 |
| 5554 (shared, local relay) | relay, push | 6 | 3 | 0 / 1 |

Failures and what happened to them:

| # | Check | Spec | Outcome |
|---|-------|------|---------|
| 1 | The PIN entry turned into "Pairing…" as soon as the Mac connected, so the PIN could not be typed | PAIR-01 A3–A4 | Fixed: android `0cd3a61`…`c0d2d51`, spec hub `4091655` (`phase-03-android-pin-pairing-fix.md`) |
| 2 | After the first pairing the app opened Devices, not the feature list | SET-01 step 8 | Open, handed to the Android fix (`phase-03-android-e2e-fixes.md`) |
| 3 | A new session's `capability/hello` still listed SMS and call permissions granted after start as missing | SET-01 API 2 logic 4 | Open, same hand-off |
| 4 | A connection that never sends `session/hello` ended with 1006, not a 4408 close | CONN-01 API 3 logic 2, 0.8.3 | Open, same hand-off |
| 5 | Pairing over the relay: ANR in `MainActivity` while another agent drove the same emulator | PAIR-01 relay | Not seen on a dedicated emulator; relay checks pass (`phase-03-e2e-relay.md`) |
| 6 | TLS handshake timeout on 5558 | — | Environment: host load average above 100 at that time |

## The real Mac app against the Android app (emulator-5580, 2026-09-27/28)

A Mac test build (`dd-mac-signed`, debug endpoint override) paired with the app on its own emulator through adb forward, a
TCP forwarder and a Bonjour proxy (scratchpad tools; the forwarder now listens on every address and the Mac uses the host
name, after DHCP moved the Mac from .168 to .166 mid-run).

| Symptom seen by the owner | Cause | Fix (repo `commit`) | Live check |
|---------------------------|-------|---------------------|------------|
| Connected / disconnected every 1.5 s, panel jumping | The connect-timeout timer cancelled a connection that was already ready | apple `50c6c17` (+ test: a connection outlives its timeout) | Session stays up; a call rang, was answered and ended from the Mac panel |
| Call panel cut off | macOS 26 glass container reports no fitting size | apple `1d1464e` | Panel sized to its content |
| One clip sent over and over, Android copy overlay each round | The emulator's clipboard sharing wrote each applied clip back to the Mac; the Mac compared only with *received* clips | spec hub `6b78fb2`; apple `365bb4e` (echo of the sent clip ignored while unacknowledged and 5 s after `applied`); android `728b43f` (content the phone wrote or sent within 5 s is acknowledged without a second write) | One `clip_sent`, one `clip_applied`, nothing for 25 s; the echo (`changeCount` +1) ignored |
| A copied image arrived as nothing / as a file name | (a) the emulator writes an empty text back once the phone holds an image and the Mac sent it, replacing the image; (b) a file copied in Finder was skipped by spec, the name came from the emulator's own sharing | spec hub `6961592`; apple `18706f0` (no empty text), `81a66d5` (an image file copied in Finder goes as the image, ≤ 10 MiB), `4b41bab` (lint split) | A PNG copied the Finder way arrived as `image/png` and was applied; the empty echo was ignored |
| — (peer request) | PIN search while the phone waits for a retyped PIN | Already retried; apple `34e2191` locks it with a test | — |

Environment findings: host load average 15–750 during the runs (`fileproviderd` ≈ 90 % CPU with 68 h of CPU time, the
Synology Drive file provider, Spotlight, other builds). The emulator froze for 7–13 s at a time (SystemUI skipped
457–763 frames, `system_server` watchdog contention), which dropped sessions and made one image write take 18 s. These
are not app faults, but they make timing results from this machine meaningless (G1 needs real devices).

Status: DONE_WITH_CONCERNS
Summary: The harness drove the real Android app through pairing, clipboard, SMS, calls, relay and push (136 checks pass); the real Mac app against it exposed five bugs, all fixed, tested and pushed.
Concerns/Blockers: three Android failures (SET-01 step 8, capability after a late permission grant, 4408 close) are being fixed; latency targets and G1 still need real phones and a quiet machine.

