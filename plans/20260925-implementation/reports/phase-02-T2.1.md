# Phase 2 — T2.1 [test]: SMS bench and relay load test

Card T2.1 of `phase-02-sms-ios-relay.md`: (a) extend the `HLBENCH/1` log format and the analysis with the Phase 2
events that measure "new SMS notification on the Mac < 500 ms after the phone receives it" and "reply confirmed as
Sent < 2 s", with 95th-percentile output; (b) a relay load test with 1,000 fake devices. Branch
`feat/phase-02-sms-ios-relay` of handlive-shared, pushed; CI `ci-shared` green (run 36221312941 on 5d8b238, which
also runs both new self-tests). Committed under the workspace lock.

## (a) SMS events and analysis

**Events the Android and Apple agents must emit** (debug builds only, same line format and privacy rules as Phase 1;
only `message_key`, `local_id`, states and error codes — never text, numbers or names). Exact list:

| `ev` | Who | When | Required fields (optional) |
|------|-----|------|----------------------------|
| `sms_detected` | Android (A-SMS) | A new provider row it will broadcast was read (SMS-02 steps 3–4) | `msg` (message_key), `box` (inbox/sent/failed), `onchange` (wall ms of the first `onChange` of the coalesced batch) (`provider` = the row's `date`) |
| `sms_new_sent` | Android (A-SVC) | `sms/new` handed to one client's session | `msg`, `peer`, `via` (lan/relay) |
| `sms_new_received` | Mac, iPhone, iPad | `sms/new` decrypted | `msg`, `peer` |
| `sms_notified` | Mac, iPhone, iPad | `UNUserNotificationCenter.add` completed without error (not logged when no notification is due) | `msg` |
| `sms_push_sent` | Android | `POST /v1/push` answered 202 for an iPhone/iPad without a session | `msg`, `peer` |
| `sms_push_shown` | iPhone/iPad NSE (subsystem `app.handlive.ios.nse`) | Decrypted push handed to the content handler | `msg` |
| `sms_send_tap` | Mac, iPhone, iPad | Send pressed (conversation, New Message) or quick reply submitted | `local` |
| `sms_bubble` | Mac, iPhone, iPad | Placeholder bubble on screen | `local` |
| `sms_send_sent` | Mac, iPhone, iPad | `sms/send` handed to the WebSocket, one line per attempt | `local`, `peer`, `attempt`, `via` |
| `sms_send_received` | Android | `sms/send` decrypted | `local`, `peer` |
| `sms_send_ack_sent` | Android | Its ack handed to the WebSocket | `local`, `peer`, `ok` (`code`) |
| `sms_send_ack_received` | Mac, iPhone, iPad | That ack decrypted | `local`, `peer`, `ok` (`code`) |
| `sms_radio_done` | Android | Every part reported by `SmsManager` | `local`, `result` (sent/failed) (`code`) |
| `sms_status_sent` | Android | `sms/status` handed to the WebSocket | `local`, `peer`, `status` (`code`) |
| `sms_status_received` | Mac, iPhone, iPad | Status applied to the outbox and shown | `local`, `status` (`code`) |

Existing Phase 1 events (`state`, `net`, `wake`, clipboard) are unchanged; the iOS app also emits `state` and `net`.

**Analysis** — `tools/bench/sms_latency.py android.log mac.log [ipad.log] [--offset A:B=MS] [--json] [--check]`:
- Notification latency = client `sms_notified` (put on the phone's clock) − phone `onchange`, incoming messages only,
  split into detection, phone, network and client time; buckets `notification lan` (target 500 ms) and
  `notification relay` (1 s, SMS-02's relay figure); incoming messages sent to a client but never notified are listed.
- Reply time = client `sms_status_received status=sent` − `sms_send_tap` (one device, no clock offset), with
  attempts, final status, error code and the phone's radio time; `reply sent` (target 2 s), `placeholder bubble`
  (100 ms) and `ack lan` (300 ms, sends without a retry) from SMS-04; `push shown` without a target.
- Summary rows print median, **95th percentile** and maximum with PASS/FAIL on the p95; `--json` for reports;
  `--check` exits 1 on a miss or when nothing with a target was measured.
- `clock_sync.py` now also takes the `sms/send` → ack exchanges (a retried send is left out), so a session with SMS
  but no clipboard traffic still gets the phone ↔ Mac offset; an iPad is chained through the phone.
- `sms_self_test.py` (run by `self_test.py` in CI): no clipboard events, phone +1234.5 ms and iPad −250 ms skews;
  checks the offset from `sms/send` exchanges, three notification latencies to 0.01 ms and their breakdown, the LAN
  and relay buckets, the not-notified list (a `box=sent` message is not listed), a failed retried reply
  (`SMS_NO_SERVICE`, 2 attempts, excluded from the offset and the ack metric), reply times over LAN and relay and from
  the iPad, bubble/ack/radio times, the chained iPad push time, the summary and a 720 ms notification that makes
  `--check` fail. **bench self-test: 42 passed, 0 failed** (22 before).
- Device-matrix procedure (README): scenarios S1 (incoming SMS on the LAN ×20), S2 (via the relay ×10), S3 (reply
  from the Messages window ×20), S4 (quick reply on the Mac, then on an iPhone in the background, 5 + 5) and the result
  row to fill.

## (b) Relay load test

- `tools/bench/relay_load.py` (Python asyncio; `requirements-load.txt` = the vector tools' pinned `cryptography`
  50.0.1 and PyNaCl 1.6.2 plus `websockets==17.1`, BSD-3-Clause, no dependency; REST through `urllib`):
  - N devices (default 1,000), each with its own Ed25519 key and UUIDv8 `device_id`.
  - `POST /v1/devices` with `HLREG1` and `POST /v1/auth/challenge` + `/v1/auth/token` with `HLAUTH1`: messages and
    signatures from `tools/vectors/handlive_protocol_derivations.py` (the relay-auth vector code).
  - `POST /v1/pairs` with the 0.6.2 attestation signed by both devices (android = device 2k, macos/ios = 2k+1).
  - `/v1/relay` for every device, then `--frames` frames per device to its peer every `--interval-ms`: text wrappers,
    alternating with binary `HR` frames with `--binary`.
  - Reported: failures per step (HTTP status and code), relay `error` ops, unexpected closes, frames lost, and
    p50/p95/p99/max of registration, connection and forwarding (one process, one monotonic clock).
  - `--cleanup` removes the devices afterwards (`DELETE /v1/devices/me?revoke_pairs=false`); `--check` exits 1 on any
    problem.
  - One `X-Forwarded-For` (10.x.y.z) per device, because the relay allows 10 new registrations per hour per IP; the
    relay must trust the proxy (`RELAY_TRUSTED_PROXIES=127.0.0.1`).
- `relay_load_fake.py` (in-process stand-in: verifies HLREG1/HLAUTH1/attestations with libsodium, enforces the 10/h
  per IP limit, presence, `to`/`from` and HR forwarding, relay errors) and `relay_load_self_test.py`: 20 devices all
  delivered and cleaned up; 12 devices without `X-Forwarded-For` → two `429 RATE_LIMITED` counted and `--check`
  failing. **relay load self-test: 10 passed, 0 failed**; added to CI (`ci: run the relay load self-test in
  ci-shared`).
- **Real run** against handlive-relay `feat/phase-02-sms-ios-relay` at **04bc259**, built `--release` from a local
  clone in the scratchpad with its own `CARGO_TARGET_DIR` (the relay agent's working tree and build lock untouched);
  temporary PostgreSQL 18.6 (`initdb` in the scratchpad, 127.0.0.1:55433, no Unix socket) and Redis
  (127.0.0.1:56380, no persistence); relay on 127.0.0.1:58080 with `RELAY_TRUSTED_PROXIES=127.0.0.1`, `RUST_LOG=warn`,
  `ulimit -n 10240`, one instance. All three services were stopped and their data removed afterwards; the relay log
  had no warning or error.

```text
$ relay_load.py --relay http://127.0.0.1:58080 --devices 1000 --frames 10 --interval-ms 1000 --binary --drain-s 15 --cleanup --check
devices 1000: registered 1000, pairs 500, connected 1000, presence frames 1975, setup 2.03 s
frames sent {'text': 5000, 'binary': 5000}, received {'text': 5000, 'binary': 5000}, lost {'text': 0, 'binary': 0}
  register        n=1000   p50=957.2 p95=996.5 p99=1000.5 max=1002.7 ms
  connect         n=1000   p50=36.9 p95=44.2 p99=46.5 max=47.8 ms
  forward_text    n=5000   p50=0.7 p95=4.0 p99=7.0 max=24.1 ms
  forward_binary  n=5000   p50=0.8 p95=8.1 p99=20.2 max=78.8 ms
exit=0          (16.2 s wall clock)

$ relay_load.py … --devices 1000 --frames 3 --interval-ms 50000 --binary --drain-s 15 --cleanup --check --json
registered 1000, pairs 500, connected 1000, failures {}, relay_errors {}, unexpected_closes {}
sent {'text': 2000, 'binary': 1000}, received {'text': 2000, 'binary': 1000}, lost 0 / 0
connect p95 408.4 ms; forward_text p50 1.23 / p95 5.57 / p99 17.18 / max 37.05 ms; forward_binary p95 3.9 ms
exit=0          (about 3.5 minutes with data frames 50 s apart: the 1,000 connections outlived the relay's 45 s
                 idle timeout on WebSocket pings alone)

$ relay_load.py … --devices 200 --frames 5 --interval-ms 200 --binary --cleanup --check   → 0 lost, exit=0
$ relay_load.py … --devices 20 --frames 4 --interval-ms 100 --binary --check              → 0 lost, exit=0
```

Registration times include the client's own queue (32 REST calls in flight for 3,000 calls), so they measure
throughput rather than one request (the second 1,000-device run shows p50 3.4 s while other checks ran on the
machine). **Result: the relay was stable at 1,000 connections — no failure, no relay error, no unexpected close, no
lost frame; forwarding p95 ≤ 8.1 ms locally.**

## Commits (handlive-shared, branch `feat/phase-02-sms-ios-relay`)

| Hash | Subject |
|------|---------|
| cf9ac4e | feat(shared): log and measure the SMS notification and reply times |
| b48b319 | test(shared): check the SMS latency script on synthetic logs |
| 17ca871 | feat(shared): add a relay load test with fake devices |
| a54041f | test(shared): run the relay load test against an in-process fake relay |
| 4300687 | ci: run the relay load self-test in ci-shared |
| 5d8b238 | docs: describe the SMS events, the SMS latency script and the relay load test |

## Files

New: `shared/tools/bench/sms_latency.py`, `sms_self_test.py`, `relay_load.py`, `relay_load_fake.py`,
`relay_load_self_test.py`, `requirements-load.txt`. Changed: `shared/tools/bench/bench_log.py` (events),
`clock_sync.py` (`Exchange.ref`, sms/send exchanges), `self_test.py`, `README.md` + `README.vi.md` (bench and
top-level), `.github/workflows/ci-shared.yml`.

## Tests (real output, from `shared/`)

```text
$ python3 tools/bench/self_test.py                               → bench self-test: 42 passed, 0 failed
$ tools/.venv/bin/python tools/bench/relay_load_self_test.py     → relay load self-test: 10 passed, 0 failed
$ tools/.venv/bin/python tools/schemas/check_schemas.py          → XANH: mọi kiểm tra đạt
$ tools/.venv/bin/python tools/vectors/verify_vectors.py         → Tổng: 1272 phép kiểm, 0 lỗi
$ tools/.venv/bin/python tools/vectors/generate_vectors.py --check → check: 20 file, 0 lệch
$ gh run view 36221312941 (ci-shared) → "bench self-test: 42 passed, 0 failed", "relay load self-test: 10 passed, 0 failed"
```

## Spec deviations and proposals (hub not edited)

1. **Start of the notification latency.** SMS-02 measures "from the moment the provider writes the message"; that
   moment is not observable, so the start is the first `ContentObserver.onChange` of the batch (`onchange`), which
   fires right after the write; the row's `date` is logged as `provider` for reference. Proposal: name `onChange` as
   the start point in SMS-02 and the Phase 2 criteria, and say the targets are judged on the 95th percentile.
2. **"Reply confirmed as Sent < 2 s"** is measured tap → "Sent" shown on the client, so it includes the carrier's
   radio time (`sms_radio_done`); the report shows that part so a slow network can be told apart from HandLive.
3. **The relay's 10 registrations per hour per IP** makes any load or CI test above 10 devices depend on
   `RELAY_TRUSTED_PROXIES` and `X-Forwarded-For`. Proposal: document this in the relay README / deployment guide (the
   relay agent may prefer a test-only setting).
4. **PostgreSQL 18** was used for the run (0.1 names PostgreSQL 16); the migrations and queries worked unchanged.

## Pending

- The real-device measurements (S1–S4 on the device matrix) — they need Android and Apple debug builds that emit the
  events above (A2.1, A2.2, M2.1, I2.1, I2.2) and the phones; the result rows in `tools/bench/README.md` stay empty.
- A load test across two relay instances (Redis pub/sub routing, C5): `relay_load.py` drives one base URL; splitting
  the devices between two instances behind separate URLs is the next step.
- The load test ran on one Mac against a local relay; a VPS run with TLS and real network latency is still to do.

Status: DONE_WITH_CONCERNS
Summary: HLBENCH/1 now has the 15 SMS events and sms_latency.py reports the notification and reply-to-Sent times with p95 and targets (self-tested, CI); relay_load.py drove 1,000 fake devices through the real relay (04bc259) with zero failures or lost frames, forwarding p95 ≤ 8.1 ms, and held the connections past the idle timeout.
Concerns/Blockers: the SMS targets can only be measured once the apps emit the events on real devices; multi-instance and VPS load runs are still pending.
