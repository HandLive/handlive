# Phase 3 — T3.1 [test]: call benchmark

Card T3.1 of `phase-03-cuoc-goi.md` (shared part): the `HLBENCH/1` log format gains the Phase 3 call events, a new
analysis script prints the 95th percentile against each call target, a synthetic-log self-test runs in `ci-shared`,
and `tools/bench/README.md` + `README.vi.md` describe the events and the device scenarios (call waiting, two SIMs,
Focus on, AirPods connected, the iPhone in the background). Branch `feat/phase-03-calls` of handlive-shared, pushed
under the workspace lock; CI `ci-shared` green (run 36296441619 on 6930f0f, which runs the new self-test). The
measurements on Pixel and Samsung are still to be done on real devices (see "Pending manual checks").

## Events the Android and Apple agents must emit

Debug builds only, same line format as Phase 1/2 (`HLBENCH/1 wall=<ms> mono=<ns> dev=<id8> role=<android|macos|ios>
ev=<event> key=value…`; Android `Log.i("HLBENCH", line)`, Apple `Logger(subsystem:, category: "bench")` with
`privacy: .public`, the iOS extension under `app.handlive.ios.nse`). **Privacy:** only `call_id`, envelope ids,
states, `sub_id`, `entry_id` and error codes — never a number, a contact name, a SIM label or a DTMF digit.
Field values never contain spaces; booleans are `true`/`false`.

| `ev` | Who | When | Required fields (optional) |
|------|-----|------|----------------------------|
| `call_changed` | Android (A-CALL) | A-CALL applied an OS event that changed the call context (CALL-01 API 1–3, CALL-04 API 3 correction); one line per applied event | `call` (call_id), `state` (ringing/offhook/idle), `waiting` (true/false), `trigger` (`listener` = API 2 callback, `broadcast` = API 3 copy with the number, `calllog` = end_reason correction), `os` (wall ms when the OS delivered that callback or broadcast) (`number` = known/none after the change, `sub` = sub_id, `end` = end_reason when idle) |
| `call_state_sent` | Android (A-SVC) | `call_event/state` handed to one client's session | `call`, `env` (the envelope `id`), `peer`, `via` (lan/relay), `state`, `reason` (`change` = the context changed; `session` = current state for a new session, E8) |
| `call_state_received` | Mac, iPhone, iPad | `call_event/state` decrypted | `call`, `env`, `peer`, `state` (`waiting`) |
| `call_alert` | Mac | M-APP decided how to alert a ringing call (CALL-01 step 7) | `call`, `focus` (off/on/unknown = Focus status not readable), `panel` (true/false), `ring` (true/false), `level` (passive/time_sensitive/none) |
| `call_panel_shown` | Mac | Ringing call panel on screen (`orderFrontRegardless()` returned) | `call` |
| `call_banner_shown` | iPhone, iPad | In-app banner of a ringing call on screen | `call` |
| `call_notified` | Mac | Incoming-call communication notification added | `call`, `level` (passive/time_sensitive) |
| `call_push_sent` | Android | `POST /v1/push` answered (call_incoming or call_missed) | `call`, `peer`, `reason`, `status` (HTTP status) |
| `call_push_shown` | iPhone/iPad NSE | Call push decrypted and handed to the content handler | `call`, `reason`, `late` (true when > 60 s after `started_at`, E7) |
| `call_action_tap` | Mac, iPhone, iPad | Answer, Decline (also Decline with Message…) or End chosen, or `HL_CALL_REJECT` reached the iOS app | `call`, `action` (answer/reject/end), `from` (panel/menu/notification/banner) |
| `call_action_sent` | Mac, iPhone, iPad | `call_event/action` handed to the WebSocket, one line per attempt (a retry keeps the envelope id) | `call`, `env`, `peer`, `action`, `via`, `attempt` (1, 2…) |
| `call_action_received` | Android | `call_event/action` decrypted | `call`, `env`, `peer`, `action` |
| `call_action_ack_sent` | Android | Its ack handed to the WebSocket (after the Telecom method returned, or with the error) | `call`, `env`, `peer`, `ok` (`code`) |
| `call_action_ack_received` | Mac, iPhone, iPad | That ack decrypted | `call`, `env`, `peer`, `ok` (`code`) |
| `call_missed_notified` | Mac, iPhone, iPad | Missed-call notification added (by the app; a push-created one is `call_push_shown reason=call_missed`) | `call` (or `none` when no call matched), `source` (`log_new`, or `state` in flow A) (`entry` = entry_id) |

Phase 1/2 events are unchanged; `state`, `net`, `wake` still apply (the iPhone's `state to=Connected` shows the
background connection of a notification decline). Exact example lines are in `tools/bench/README.md`.

## Analysis — `tools/bench/call_latency.py`

`python3 tools/bench/call_latency.py android.log mac.log [iphone.log] [--offset A:B=MS] [--json] [--check]`

| Summary row | Target (p95) | From → to |
|-------------|--------------|-----------|
| `state lan` / `state relay` | 200 ms / 1 s | `call_changed.os` of the change → client `call_state_received` of the envelope that carried it (joined on `env`, client time put on the phone's clock); envelopes sent for a new session (`reason=session`) are not measured |
| `shown panel` / `shown banner` | 300 ms | first RINGING `call_changed.os` → `call_panel_shown` (Mac) / `call_banner_shown` (iPhone, iPad) |
| `answer to phone offhook` | 500 ms | Mac `call_action_tap action=answer` → the phone's OFFHOOK `call_changed.os` (across clocks) |
| `answer back on client`, `decline back on client`, `end back on client` | 500 ms | tap → the same client's `call_state_received` with `offhook` / `idle` (one device) |
| `decline from notification` | 2 s | `call_action_tap from=notification` on the iPhone → the phone's IDLE `call_changed.os` |
| `missed notification` | 1.5 s | the phone's IDLE `call_changed end=missed` → `call_missed_notified` |
| `incoming push` | 300 ms | number known (`call_changed number=known`, or RINGING + 300 ms when it never came) → `call_push_sent status=202`, phone only |
| `push shown` | — | first RINGING → the extension's `call_push_shown` |

It also prints one row per state envelope (trigger, phone/network split), the envelopes never received, one row per
action (source, transport, attempts, ack, error code), and the Mac alerts that break the Focus rule of CALL-01 E4 /
API 5 (Focus on → no panel, no ringtone, time-sensitive; Focus status unknown → panel without ringtone; a panel
always with a passive notification; no panel while a Focus is on). `--check` exits 1 on a missed target, a Focus
problem, or nothing measured. `clock_sync.py` now also takes the `call_event/action` ↔ ack exchanges (a retried
action is left out), so a session with calls only still gets the phone ↔ Mac and phone ↔ iPhone offsets.

Self-test (`call_self_test.py`, run by `self_test.py` in CI): phone +1234.5 ms, iPad −250 ms, no clipboard or SMS
traffic; 23 checks (offsets from call actions, 13 state latencies to 0.01 ms, the number broadcast measured from its
own arrival, relay copies apart, a lost envelope listed, panel/banner, answer/decline/end both ways, a decline from
the iPad notification after a 900 ms background connection, the missed-call notification, push after number and
push display, the Focus rule, `--check` failing on a panel during a Focus and on a 450 ms panel).
**bench self-test: 65 passed, 0 failed** (42 before).

Device scenarios added to the README manual-test table: C1 incoming call on the LAN (×20), C2 answer and end from
the Mac (×10), C3 decline and Decline with Message… (10 + 2), C4 call waiting E9 (×3), C5 two SIMs (3 + 3), C6 Focus
on and Focus status not granted (3 + 2), C7 AirPods connected (×3, no effect in this phase), C8 iPhone in the
background: push and Decline from the notification over the relay (×10), C9 missed call with the Mac, then the
iPhone in the background (5 + 3), C10 iPhone in-app banner (×5); plus the Phase 3 result row per pair.

## Commits (handlive-shared, branch `feat/phase-03-calls`)

| Hash | Subject |
|------|---------|
| b77f036 | feat(shared): log the call events of the benchmark and use call actions as clock exchanges |
| 60248e4 | feat(shared): measure call state delivery, the call panel and call actions |
| d24d43c | test(shared): check the call benchmark on synthetic logs |
| 6930f0f | docs: describe the call benchmark events and device scenarios |

Each commit was checked in isolation (`self_test.py`). All signed off; `.githooks/check-commits.sh origin/main..HEAD`
→ "commit sạch: đã kiểm 17 commit".

## Files

Created: `shared/tools/bench/call_latency.py`, `call_self_test.py`.
Changed: `shared/tools/bench/bench_log.py`, `clock_sync.py`, `self_test.py`, `README.md`, `README.vi.md`;
`shared/README.md`, `README.vi.md`.

## Tests (real output, from `shared/`)

```text
$ python3 tools/bench/self_test.py
bench self-test: 65 passed, 0 failed

$ tools/.venv/bin/python tools/bench/relay_load_self_test.py | tail -1
relay load self-test: 10 passed, 0 failed

$ python3 tools/bench/call_latency.py <synthetic logs of call_self_test> | tail -13
summary (ms)
  state lan                 n=11   median=11.0 p95=13.0 max=13.0  target < 200 → PASS
  state relay               n=2    median=70.0 p95=300.0 max=300.0  target < 1000 → PASS
  shown panel               n=2    median=90.0 p95=120.0 max=120.0  target < 300 → PASS
  shown banner              n=1    median=250.0 p95=250.0 max=250.0  target < 300 → PASS
  answer to phone offhook   n=1    median=165.0 p95=165.0 max=165.0  target < 500 → PASS
  answer back on client     n=1    median=178.0 p95=178.0 max=178.0  target < 500 → PASS
  decline back on client    n=1    median=98.0 p95=98.0 max=98.0  target < 500 → PASS
  end back on client        n=1    median=108.0 p95=108.0 max=108.0  target < 500 → PASS
  decline from notification n=1    median=994.0 p95=994.0 max=994.0  target < 2000 → PASS
  missed notification       n=1    median=900.0 p95=900.0 max=900.0  target < 1500 → PASS
  incoming push             n=1    median=180.0 p95=180.0 max=180.0  target < 300 → PASS
  push shown                n=1    median=1100.0 p95=1100.0 max=1100.0  no target

$ gh run list -R HandLive/handlive-shared --branch feat/phase-03-calls --limit 1
completed  success  docs: describe the call benchmark events and device scenarios  ci-shared  push  36296441619
```

## Spec deviations and proposals (hub not edited)

1. **Answer target**: the phase file says "answer tapped on the Mac → OFFHOOK on the phone < 500 ms end to end";
   CALL-02 measures "from the click until the Mac receives `state = offhook`". Both are reported
   (`answer to phone offhook`, `answer back on client`) with 500 ms each.
2. **Decline from an iPhone notification**: CALL-02 allows ≤ 15 s including the background connection; the I3.1 card
   asks < 2 s via the relay. The script uses 2 s (the card's figure, which assumes the phone already opened the relay
   after the push, CALL-01 API 4 logic 4). Proposal: write the 2 s figure into CALL-02 special requirements, keeping
   15 s as the hard deadline.
3. **"Push within < 300 ms after the number is known"** (A3.2) is read as: from the broadcast that brought the
   number — or RINGING + 300 ms when no number came (CALL-01 API 4 logic 2) — to the relay's 202; it includes the
   relay REST round trip. Proposal: say in CALL-01 API 4 which end point the 300 ms uses.
4. The Mac's Focus rule is checked from `call_alert`; the spec does not name the "Focus status not readable" case
   in field 15 (`interruptionLevel` passive because the panel shows). The script expects passive there.

## Pending manual checks

- Run scenarios C1–C10 on the device matrix (Pixel 8, Galaxy S22/S23, one Mac; an iPhone for C8–C10) once the
  Android and Apple agents emit the events, and fill the Phase 3 result row per pair (targets met on Pixel and
  Samsung is the card's acceptance criterion, still open).
- Check on a real Mac that `call_panel_shown` is logged after `orderFrontRegardless()` returns, and on Android that
  `os` is taken on entry of the listener callback / broadcast receiver (not after the name lookup).

Status: DONE_WITH_CONCERNS
Summary: The HLBENCH/1 call events, call_latency.py with p95 against every CALL-01…04 target, the Focus rule check, a 23-check synthetic self-test in CI and the device scenarios are pushed on feat/phase-03-calls; bench self-test 65/65, CI green.
Concerns/Blockers: the real-device measurements (Pixel, Samsung) wait for the platform agents to emit the events; the answer and iPhone-decline targets need the spec wording of deviations 1–3.
