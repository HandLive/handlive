# Phase 3 — A3.2 [android]: call pushes for iPhone and iPad

Card A3.2 of `phase-03-cuoc-goi.md`: the `call_incoming` push of CALL-01 step 5 / API 4 and the `call_missed` push of
CALL-04 API 5 for iPhone and iPad pairs without a session, their `push_outbox` retries (CONN-04 E2), the relay held
open while a call rings (CALL-01 API 4 logic 4), and the `call_action` wake of CONN-04 (gms flavor). Branch
`feat/phase-03-calls` of handlive-android, pushed; CI `ci-android` green (see Tests). No real relay, APNs or FCM was
reachable from here: everything runs against the fake relay of the Phase 2 tests and the shared vectors.

## What was done

- **When a push leaves (feature/call, `CallPushes`)** — on the A-CALL thread, from the call context: one
  `call_incoming` per ringing incoming call (`call_id`), never for a waiting call (E9), as soon as the number is
  settled — the number-carrying `PHONE_STATE` copy arrived, with a number or withheld — or 300 ms after `RINGING`
  when it never came; at once when `READ_CALL_LOG` is missing, since no number can come (E2). A call answered or ended
  before that gets no push. The state pushed is the one an iPhone gets (`controls.answer = false`, `reject` with
  `ANSWER_PHONE_CALLS`, `hfp_connected = false`, `audio_on = phone`). Missed calls: with `READ_CALL_LOG`, every
  `log_new` entry of type `missed` (`MissedCall.Logged`, the `call_id` of the matched context or none); without it
  (flow A), the `idle` state with `end_reason = missed` (`MissedCall.Inferred`) — the two sources are never used
  together. The end of the ringing (answered, ended, waiting cleared, calls turned off) is reported too.
- **The pushes (feature/relay, `CallPushBuilder`, `PushSender`)** — for each iPhone/iPad pair registered with the relay,
  without a session, whose latest capability has `features.call.enabled`, `features.call.notify` and the relay not off
  (Macs never get one): the `call_event/state` (ringing, flow A) or `call_event/log_new` envelope sealed with `K_push`,
  `kind = alert`; `call_incoming` → `collapse_key` `call:<call_id>`, `ttl_s` 30; `call_missed` → `call:<call_id>`
  (it replaces the incoming-call notification) or `calllog:<entry_id>` when no call matched, `ttl_s` 86,400. A contact
  name that would push `env_b64` over 3,000 characters is cut to 64 code points with "…", then dropped; nothing fits →
  no push. **All five call vectors of `push-envelope.json` are rebuilt byte for byte** (`push_request` from `plaintext`,
  `id`, `ts`, `nonce`) and every request passes `relay-rest.schema.json#/$defs/push-request`.
- **`push_outbox` (core/data, handlive.db version 3)** — a new `reason` column (default `sms_new` for the rows of
  version 2, Room auto-migration 2 → 3, schema `3.json` exported) because `call_incoming` and `call_missed` share the
  collapse key `call:<call_id>` and a retry must resend the right `reason`. Network error, 429 (`Retry-After`), 5xx,
  502 → queued with the CONN-04 expiry: 30 s for `call_incoming`, 24 h for `call_missed` (and SMS); retried 5 s, 15 s,
  45 s…; `ttl_s` stays 30 / 86,400 on retries (the schema pins 30 for `call_incoming`). 409 `PUSH_TOKEN_MISSING`,
  403, 413, 400 are dropped. When the call stops ringing, a queued `call_incoming` of that call is deleted, so a late
  retry can never replace the missed-call notification under the shared collapse key. The outbox code moved to
  `PushQueue` (shared by SMS and calls).
- **The relay while a call rings (`RelayConnector.hold`)** — when an incoming call starts ringing and a
  relay-registered pair has no session, the phone opens `/v1/relay` and holds it for as long as the call rings (the
  idle rule counts a hold as activity), then releases it: from then on `RELAY_IDLE_DISCONNECT` applies (5 idle
  minutes). So a "Decline" from an iPhone notification usually needs no wake push (CALL-02 B2), and a Mac waiting on
  the relay gets the call too (CALL-01 step 4). While the number is awaited the relay JWT is fetched as well, so the
  push that follows only has its `POST` to make (the push target runs from the number to the relay's 202).
- **`call_action` wake (gms)** — FCM `t = wake` already starts the service and the relay whatever the reason; the
  reason `call_action` (CALL-02 B2) is named in `FcmPushService` and `RelayFeature.onWake`. No code path differs by
  reason (CONN-04 step 9a).
- **HLBENCH/1** — `call_push_sent call=<call_id|none> peer=<id8> reason=<call_incoming|call_missed> status=<HTTP>` for
  every push the relay answered (first try or retry), as defined by T3.1; `sms_push_sent` unchanged (202 only).

## Commits (handlive-android, branch `feat/phase-03-calls`)

| Hash | Subject |
|------|---------|
| fa5e922 | test(android): follow the call push vectors added to push-envelope.json |
| 0d34403 | feat(android): keep the push reason in push_outbox as handlive.db version 3 |
| 41371f1 | test(android): migrate handlive.db 2 to 3 and drop a queued push by collapse key and reason |
| ef4f32f | feat(android): let a ringing call hold the relay link open |
| ed6e092 | feat(android): push incoming and missed calls to iPhone and iPad without a session |
| 2b591a0 | test(android): a held relay link stays open, then leaves five idle minutes after |
| 48641cc | test(android): rebuild the call push vectors and cover call pushes and their outbox |
| 107a34e | docs(android): name the call_action wake among the FCM wake-ups |
| d2b95b0 | perf(android): fetch the relay token while a ringing call waits for its number |

Shared with A3.1 (listed there): 00ec3ff (the `call_incoming`, `call_missed`, `call_action` reasons), 142b32b
(`CallPushes`, `OfflineCallDelivery`), a27877c (`CallPushTest`), 298c7e0 (README). All pushed
(`origin/feat/phase-03-calls` = ba089dc). No handlive-shared commit for this card.

## Files

- `core/data`: `db/PushOutboxEntity.kt` (`reason`, `deleteQueued`), `db/HandLiveDatabase.kt` (version 3),
  `schemas/…/3.json`; tests `HandLiveDatabaseMigrationTest` (2 → 3), `SmsAndPushTablesTest`.
- `core/protocol`: `relay/RelayRest.kt` (`call_incoming`, `call_missed`, `call_action` reasons); test
  `PushRequestVectorTest`. `core/crypto`: test `PushEnvelopeVectorTest` (12 envelopes, 12 negatives).
- `feature/call`: `module/CallPushes.kt`, `module/OfflineCallDelivery.kt` (`MissedCall`); test `CallPushTest`.
- `feature/relay`: `push/CallPushBuilder.kt` (new), `push/PushQueue.kt` (new), `push/PushSender.kt`,
  `RelayConnector.kt`, `RelayConnection.kt`, `RelayConstants.kt`, `RelayFeature.kt` (`CallDelivery`, bench line),
  `build.gradle.kts`; tests `CallPushBuilderTest`, `CallPushSenderTest`, `RelayConnectorTest`, `PushSenderTest`,
  `testing/RelayTestKit.kt`.
- `app/src/gms/…/FcmPushService.kt` (KDoc); `README.md`, `README.vi.md`.

## Tests (real output)

```text
$ export JAVA_HOME=/opt/homebrew/opt/openjdk@21/libexec/openjdk.jdk/Contents/Home
$ ./gradlew testDebugUnitTest --rerun :app:testFossDebugUnitTest --rerun check   # android ba089dc, shared 1a87a80
> Task :core:protocol:testDebugUnitTest
> Task :core:crypto:testDebugUnitTest
> Task :core:strings:testDebugUnitTest
> Task :feature:connection:testDebugUnitTest
> Task :core:data:testDebugUnitTest
> Task :feature:clipboard:testDebugUnitTest
> Task :feature:call:testDebugUnitTest
> Task :feature:pairing:testDebugUnitTest
> Task :core:design:testDebugUnitTest
> Task :feature:sms:testDebugUnitTest
> Task :feature:relay:testDebugUnitTest
> Task :core:transport:testDebugUnitTest
> Task :app:testFossDebugUnitTest
BUILD SUCCESSFUL in 37s
780 actionable tasks: 26 executed, 754 up-to-date
```

Counts from the JUnit XML of that run: **607 tests, 0 failures, 0 errors, 0 skipped** — core/protocol 50,
core/crypto 44, core/data 20, core/strings 5, core/design 26, core/transport 61, feature/connection 33,
feature/pairing 47, feature/clipboard 101, feature/sms 68, feature/relay 41, feature/call 82, app (foss) 29. `check`
also ran ktlint, detekt and Android Lint of every module (green).

The classes of this card: `CallPushTest` 11 (feature/call, virtual clock), `CallPushBuilderTest` 3 (the five call
vectors of `push-envelope.json` byte for byte, schema of every request), `CallPushSenderTest` 6, `PushSenderTest` 5,
`RelayConnectorTest` 12 (the hold), `HandLiveDatabaseMigrationTest` 2 (2 → 3), `SmsAndPushTablesTest` 4,
`PushRequestVectorTest` 3 (12 push requests), `PushEnvelopeVectorTest` 3 (12 envelopes, 12 negatives).

CI and commit policy:

```text
$ gh run list -R HandLive/handlive-android --branch feat/phase-03-calls --limit 1
completed  success  test(android): cover the suggestion of a missing call permission  ci-android  feat/phase-03-calls  push  36298541328  5m29s
$ .githooks/check-commits.sh origin/main..HEAD
commit sạch: đã kiểm 39 commit
```

Push timing on the virtual clock (`CallPushTest`): number at `RINGING` + 120 ms → push at + 120 ms; no number → push
at + 300 ms (none at + 299 ms); no `READ_CALL_LOG` → at + 0 ms; withheld number (two copies without the key) → at the
second copy; answered at + 100 ms → no push, ringing ended at + 100 ms; a waiting call → no second push.

## Spec deviations and proposals (hub not edited)

1. **`push_outbox.reason`** (`00-common-specs.md` 0.9.1, `03-connectivity.md` CONN-04 Query): the design has no
   column for the push `reason`, but `call_incoming` and `call_missed` share `call:<call_id>`, so a retry cannot tell
   them apart. Added `reason TEXT NOT NULL DEFAULT 'sms_new'` (Room version 3). Proposal: add the column to 0.9.1 and
   to the CONN-04 INSERT.
2. **A queued `call_incoming` is dropped when the call stops ringing** (`06-call-control.md` CALL-01 E5 / API 4,
   CONN-04 E2): otherwise a retry within its 30 s could replace the missed-call notification that shares its collapse
   key. Proposal: say so in CALL-01 E5.
3. **The relay is held from `RINGING`**, not only after the push (CALL-01 step 5 / API 4 logic 4), whenever a
   relay-registered pair has no session; it also serves a Mac waiting on the relay (step 4). Proposal: name
   "an incoming call rings while a relay-registered pair has no session" among the relay demands of CONN-03 step 2.
4. **No 300 ms wait without `READ_CALL_LOG`** (CALL-01 API 4 logic 2, "up to 300 ms"): no number can come, so the push
   leaves at once. Proposal: state it.
5. **Name cut for call pushes** (CONN-04 step 5b has a cut rule for SMS only): a name that would push `env_b64` over
   3,000 characters is cut to 64 code points with "…", then dropped. Proposal: add the rule to step 5b.
6. **`ttl_s` of a retried `call_incoming`** stays 30 (`relay-rest.schema.json` pins it) although less than 30 s may
   remain of the outbox expiry; the outbox stops 30 s after the first try, so the notification can outlive the ring by
   up to ~30 s — iOS removes stale incoming notifications itself (CALL-01 API 6 logic 4).

## Pending manual checks

- A real relay and APNs: `call_incoming` on a locked and an unlocked iPhone; the missed-call push replacing it through
  the collapse key; "Decline" from the notification reaching the phone in < 2 s over the held relay.
- The push target on devices: number broadcast → 202 in < 300 ms (`shared/tools/bench/call_latency.py`, row
  `incoming push`), with the relay JWT fetched while ringing.
- FCM `call_action` wake on a `gms` build with Firebase settings (the phone joins the relay, the iPhone declines).
- The outbox with a flaky network: a 429/502 during ringing, then the call ends (queued incoming dropped).

Status: DONE_WITH_CONCERNS
Summary: call_incoming and call_missed pushes to iPhone and iPad pairs without a session, their push_outbox retries (handlive.db version 3 with a reason column), the relay held open while a call rings and the call_action wake are implemented; the five call push vectors are rebuilt byte for byte, the push timing is tested on a virtual clock, and CI is green.
Concerns/Blockers: No real relay, APNs or FCM was reachable: the push target (number → 202 in < 300 ms), the collapse-key replacement on iOS and the FCM call_action wake are pending on devices. push_outbox.reason and the dropped queued call_incoming (deviations 1 and 2) need a spec update.
