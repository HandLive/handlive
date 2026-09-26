# Phase 2 — R2.1 [relay]: REST, the `/v1/relay` channel, Redis routing, limits and cleanup

Card R2.1 of `phase-02-sms-ios-relay.md`, plus the relay part of the shared-contract checks (brief step 3).
Repository handlive-relay, branch `feat/phase-02-sms-ios-relay`, pushed; CI `ci-relay` green on the last commit
14a9c3f (run 36222312955: commit policy, fmt + clippy + test, integration on PostgreSQL 16 + Redis 7, with
`handlive-shared → feat/phase-02-sms-ios-relay`). No change in `shared/` or the hub.

## What was done

**REST** (`crates/relay-server/src/routes/`), every JWT endpoint behind the Phase 0 extractor (404/410) and the
REST limit of 60 calls per minute per device (`rl:<device_id>:rest:<minute>`, 429 + `Retry-After`):

- `POST /v1/devices` kept; it now also counts **new** devices per client IP (10 per hour, `rl:ip:<ip>:reg:<hour>`);
  `X-Forwarded-For` is read only from `RELAY_TRUSTED_PROXIES`, right-most untrusted hop (0.9.4, deferred in Phase 0).
- `PUT /v1/devices/me/push-token` (CONN-04 API 1): provider must fit the platform (android ↔ fcm, ios/ipados ↔
  apns/apns_sandbox, a Mac never), APNs token hex (stored lowercase) with a topic, 8 KiB body limit, 204.
- `DELETE /v1/devices/me?revoke_pairs=` (SET-02 API 2, C16): one transaction reads the peers of the unrevoked pairs and
  deletes the device (pairs by cascade). `true`: `revoked_notice:<peer>` (`<pair_id>|<device_id>`, 30 days) and
  `pair_revoked` published at once; `false`: nobody told, the peers' connections just stop routing the pair.
  Presence and challenge deleted, the device's relay connection closed with 1000. Already gone → 204; locked out → 410.
- `POST /v1/pairs` (PAIR-01 API 8): attestation parsed (`HLPAIR1`, 127 bytes) and matched with the body and the keys in
  `devices`, both Ed25519 signatures verified strictly; 201 / 200 identical / 409 `PAIR_EXISTS` / 403 / 404 / 400 /
  401. Both members' relay connections reload their pairs and get `presence` for the new pair.
- `GET /v1/pairs[?include_revoked=]` (PAIR-02 API 1) with `peer_online` from `presence:<peer>`.
- `POST /v1/pairs/{pair_id}/revoke` (PAIR-03 API 3): 204 (also when already revoked), 403, 404; the peer gets
  `pair_revoked` at once, both connections stop routing.

**The relay channel** `GET /v1/relay` (`src/relay/`, CONN-03 API 4–6, PAIR-01 API 7, PAIR-03 API 4, C5):

- One task per connection. Opening: subscribe `dev:<device_id>`, claim `presence:<device_id>` = instance id (TTL 60 s,
  renewed every 20 s by a compare-and-set script), tell older connections to close (4409, also across instances),
  send `presence` for every pair, `pair_revoked` for pairs revoked in the last 30 days and for `revoked_notice`
  entries (then deleted), announce `online` to the peers. Closing: release presence only if still ours, then
  announce `offline`.
- Text `{"to","env"}` → `{"from","env"}` with `env` copied byte for byte (a device-sent `from` is ignored); binary `HR`
  frames get the source id in place of the destination; only the 20-byte header is checked. Only peers of valid pairs
  whose rows exist for both devices (`NOT_PAIRED`, checked when sending and again when delivering); nobody subscribed
  to `dev:<to>` → `NOT_CONNECTED`; > 256 KiB → `PAYLOAD_TOO_LARGE` (connection kept); > 1 MiB → close 4400; malformed
  → `BAD_REQUEST`. 2 MiB/s per pair: a token bucket delays reading the sender, never drops.
- Rendezvous: `rv_join` (Lua: at most 2 members, TTL 180 s set on creation only), `rv_joined` to both when the second
  joins, `rv_msg` only between members, only `type = pair`, never a PIN-mode `pair/hello`.
- Instances forward through Redis pub/sub on `dev:<device_id>` (tagged bus messages). A lost pub/sub connection is
  re-established, every channel re-subscribed and every connection re-asserts presence and reloads its pairs
  (Redis restart). Relay pings every 15 s, closes 4411 after 45 s of silence; a receiver with 32 MiB waiting or a
  write stuck 10 s is dropped (4500).
- Statistics: envelopes and bytes (and pushes, R2.2) tallied per device and written every minute to `usage_daily`
  under SHA-256(device_id ‖ monthly salt), the salt 32 random bytes in Redis (`usage_salt:<YYYY-MM>`, 40 days).
  Daily cleanup (one instance per day, `maintenance:<day>` lock): statistics > 30 days, devices inactive 180 days.
- Zero-knowledge: nothing about `env`, payloads, tokens, ids or query strings is logged; the access log keeps
  `%U %s %b %Dms`.

**Contract checks** (brief step 3, shared at 5d8b238): `relay-frame.json` frames, rewrites and the 8 negatives;
`pair-handshake.json` `pairs_request` bodies and negative client signatures; every body and control message of a full
session validated against `shared/schemas` (`relay-rest`, `relay-<op>`, `relay-wrapper`, `push`) with `jsonschema`
(test-only). This found two contract gaps that are fixed in 6232fc7 (see deviations 1–2).

## Commits (handlive-relay, `feat/phase-02-sms-ios-relay`)

| Hash | Subject |
|------|---------|
| cfc5dae | feat(relay): add the Phase 2 relay error codes and settings |
| 7d56ef9 | feat(relay): verify pair attestations |
| 3dce5ba | feat(relay): add the pairs, push-token and statistics queries |
| e25269b | feat(relay): add the relay wire formats, bus encoding and Redis helpers |
| c86abfd | feat(relay): serve /v1/relay with routing between instances through Redis |
| 3f8c0b2 | feat(relay): register, list and revoke pairs |
| 77ef6d5 | feat(relay): add push-token registration, device removal and the IP limit |
| 6ad56d8 | feat(relay): write usage statistics and run the daily cleanup |
| 967a69b | test(relay): check pair registrations against the shared pairing vectors |
| c7ee905 | test(relay): cover the relay wire formats, limits and statistics rules |
| d53f688 | test(relay): exercise /v1/relay with real WebSocket clients |
| ce1d267 | fix(relay): claim presence before closing the device's older connection |
| 93a90db | test(relay): run the pairing rendezvous with the shared pairing envelopes |
| 4503966 | test(relay): forward across two instances and survive a Redis restart |
| 00a6b05 | test(relay): check that relay logs carry no content or identifiers |
| 3b6112b | test(relay): check that the pair bandwidth limit delays without dropping |
| 38b4e1c | test(relay): cover the pair and device REST endpoints |
| 64253c8 | test(relay): cover usage statistics and the daily cleanup |
| 075547e | test(relay): make the close-code checks independent of TCP resets |
| 04bc259 | docs: describe the Phase 2 relay endpoints, channel and settings |
| 6232fc7 | fix(relay): keep relay error ops within the codes of CONN-03 API 5 |
| 51e04d2 | test(relay): validate relay output against the shared JSON Schemas |
| 32da303 | test(relay): check HR frames, wrapper rewrites and push requests against the shared vectors |

(R2.2 commits are listed in `phase-02-R2.2.md`.) All signed off under Hồ Xuân Dũng; the commit hook and the CI
commit-policy job passed.

## Files

Created (`crates/relay-server/`): `src/attestation.rs`, `src/limits.rs`, `src/usage.rs`, `src/maintenance.rs`,
`src/relay/{mod,wire,bus,hub,presence,rendezvous,bandwidth,connection,inbound,outbound}.rs`,
`src/routes/{pairs,relay_ws}.rs`, `src/store/{pairs,usage}.rs`; tests `common/{relay_harness,schemas}.rs`,
`pair_attestation_vectors.rs`, `relay_wire_formats.rs`, `limits_and_usage.rs`, `relay_ws_forwarding.rs`,
`relay_ws_lifecycle.rs`, `relay_ws_rendezvous.rs`, `relay_multi_instance.rs`, `relay_redis_restart.rs`,
`relay_log_privacy.rs`, `relay_bandwidth.rs`, `db_pairs_rest.rs`, `db_devices_rest.rs`, `db_usage_and_cleanup.rs`,
`shared_relay_vectors.rs`, `shared_schemas.rs`.
Changed: `Cargo.toml`, `Cargo.lock`, `crates/relay-server/Cargo.toml`, `src/{lib,main,config,state,error,b64u}.rs`,
`src/routes/{mod,devices}.rs`, `src/store/{mod,devices}.rs`, `tests/common/{mod,http_harness}.rs`, `README.md`,
`README.vi.md`, `CLAUDE.md`. New crates: actix-ws, futures-util (MIT/Apache); test-only tokio-tungstenite (MIT),
jsonschema (MIT). Every new crate is MIT, Apache-2.0 or ISC.

## Tests (real output, from `relay/`, local PostgreSQL 18 + Redis on 55432/56379)

```text
$ export PATH=/opt/homebrew/opt/rustup/bin:$PATH; cargo fmt --check && cargo clippy --all-targets -- -D warnings && cargo test
fmt ok
    Finished `dev` profile [unoptimized + debuginfo] target(s) in 0.60s
tests/challenge_and_token_proof.rs 6 passed · device_identity_vectors.rs 3 · error_responses.rs 3 · jwt_tokens.rs 5
tests/limits_and_usage.rs 6 · pair_attestation_vectors.rs 6 · registration_validation.rs 5 · relay_wire_formats.rs 9
tests/shared_relay_vectors.rs 3 · shared_signature_vectors.rs 6 · signature_verification.rs 4   (+ relay-push 11)
→ 67 passed, 0 failed; the integration files show "N ignored"

$ set -a && . ./.env.example && set +a && cargo test -- --ignored
Running tests/db_auth_and_jwt.rs            test result: ok. 4 passed; 0 failed
Running tests/db_devices_rest.rs            test result: ok. 3 passed; 0 failed
Running tests/db_pairs_rest.rs              test result: ok. 3 passed; 0 failed
Running tests/db_push_rest.rs               test result: ok. 3 passed; 0 failed
Running tests/db_schema_and_registration.rs test result: ok. 2 passed; 0 failed
Running tests/db_usage_and_cleanup.rs       test result: ok. 2 passed; 0 failed
Running tests/relay_bandwidth.rs            test result: ok. 1 passed; 0 failed
Running tests/relay_log_privacy.rs          test result: ok. 1 passed; 0 failed
Running tests/relay_multi_instance.rs       test result: ok. 2 passed; 0 failed
Running tests/relay_redis_restart.rs        test result: ok. 1 passed; 0 failed
Running tests/relay_ws_forwarding.rs        test result: ok. 4 passed; 0 failed
Running tests/relay_ws_lifecycle.rs         test result: ok. 6 passed; 0 failed
Running tests/relay_ws_rendezvous.rs        test result: ok. 2 passed; 0 failed
Running tests/shared_schemas.rs             test result: ok. 1 passed; 0 failed
```

The WebSocket suites were also run six times in a row without a failure. Smoke run of the binary: migrations
applied, the daily cleanup ran once, `POST /v1/auth/challenge` → 404 `DEVICE_NOT_FOUND`, `GET /v1/relay` without a
token → 401 `SIGNATURE_INVALID`, access log `/v1/relay 401 83 0.130000ms`. The shared agent's load test (T2.1) ran
against 04bc259: 1,000 devices, 10,000 frames, nothing lost, p95 4.0 ms text / 8.1 ms binary.

Covered scenarios (phase file "Testing" and the brief): both frame kinds, env byte for byte and in order; offline
peer; phone with Mac + iPhone; rendezvous with the vector envelopes; revocation while connected and replay on
reconnect; pair registered while connected; DELETE with and without `revoke_pairs`; two instances (forwarding,
presence, revocation, replacement); Redis restart (FLUSHALL + CLIENT KILL: presence restored, `dev:` channels
re-subscribed, forwarding resumes, refused frames get an error, none lost silently); log capture at TRACE with no
payload, id, token or query in any record; bandwidth delay without loss; close codes 4400/4409/4411/1000.

CI note: the first idle-close test used a tungstenite client that answered queued pings after the relay closed, and
Linux reset the socket before the 4411 frame was read (run 36220620510); fixed in 075547e with a raw client that never
writes. Not a relay bug.

## Spec deviations and proposals (hub not edited)

1. **`error` op code when Redis fails** (`00-common-specs.md` 0.7.3, `03-connectivity.md` CONN-03 API 5–6): the op may
   only carry the five codes of API 5 (`relay-error.schema.json`). A frame the relay cannot publish is answered
   `NOT_CONNECTED`. Proposal: say so in API 6 logic 3.
2. **`to` that is not a device id** (CONN-03 API 6): a `to` or `HR` destination that is not a UUIDv8 → `BAD_REQUEST`
   without `to` (as the vector "to is not a device_id"), so the error never echoes a malformed id. Proposal: add to
   API 6.
3. **Connected check** (CONN-03 API 6 logic 3 and its Redis block): `NOT_CONNECTED` comes from the PUBLISH receiver
   count (0) instead of `EXISTS presence:<to>`; exact even after an instance crash. Presence still feeds `presence`
   and `GET /v1/pairs`. Proposal: update the Redis block.
4. **`RELAY_RATE_LIMIT` 2 MiB/s per pair** (0.10): enforced per sending device and pair in the sender's connection;
   a shared budget across instances would cost a Redis round trip per frame. Proposal: "2 MiB/s per pair and
   direction". The `INCR rl:<device_id>:relay:<minute>` line of the CONN-03 Redis block has no limit value and is not
   implemented (the upgrade counts against the REST limit). Proposal: remove it or give a number.
5. **Limits the spec leaves open** (CONN-03 API 4/6): hard frame limit 1 MiB (then close 4400); relay pings every 15 s
   and closes 4411 after 45 s of silence; a receiver with 32 MiB queued or a write stuck 10 s is dropped (4500).
   Proposal: document in API 4.
6. **New Redis keys** (0.9.4 table): `usage_salt:<YYYY-MM>` (40 days), `maintenance:<day>` (25 h lock),
   `wake:<device_id>:<reason>` (300 s, R2.2). Proposal: add them.
7. **Monthly salt** (0.6.5): 32 random bytes kept only in Redis, so hashes become unlinkable when it expires; a Redis
   restart mid-month starts a new salt. `device_hash` = SHA-256(16-byte device_id ‖ salt). Proposal: state it.
8. **`POST /v1/pairs` platforms** (PAIR-01 API 8): `device_a` must be Android and `device_b` a Mac/iPhone/iPad (400
   otherwise), as the 0.9.4 comments say; a locked-out peer counts as not registered (404, per the spec query).
   Proposal: add to API 8 logic.
9. **Rendezvous** (PAIR-01 API 7): `rv_msg` with no other member → `error NOT_CONNECTED`; an expired `rv_id` cannot be
   told from a new one, so `rv_join` recreates it (`peer_present = false`) and the device times out per E3. The PIN
   block needs the relay to decode the unencrypted `pair` payload — the only place it looks inside an envelope, as
   API 7 logic 4 requires; this should stay an explicit exception to "the relay checks only the wrapper".
10. **C16 silent removal** (SET-02 API 2): the device's presence is deleted before its connection is told to close, so
    the peers get no `presence offline` either; their connections drop the pair without any message.
11. **Queries**: `GET /v1/pairs?include_revoked=` with a value other than true/false and a missing `revoke_pairs` →
    400 in the relay error format.

## Pending manual checks

- Real clients over the relay (Android A2.2, Mac M2.2, iPhone I2.1): switch Wi-Fi ↔ 4G while messaging.
- Deployment behind the TLS reverse proxy with `RELAY_TRUSTED_PROXIES` set (per-IP limit on real addresses).

Status: DONE
Summary: The relay serves every Phase 2 REST endpoint and the /v1/relay channel (wrapper and HR forwarding, presence, rendezvous, revocation notices) across instances through Redis, with the 0.10 limits, the 30-day cleanup and zero-knowledge logs; 67 unit and 35 integration tests pass locally and in CI, including the shared vectors and schemas.
Concerns/Blockers: none for the card; the spec clarifications above (error code on Redis failure, UUIDv8 check, per-direction bandwidth, new Redis keys) need a hub decision.
