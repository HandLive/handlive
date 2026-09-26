# Phase 2 — R2.2 [relay]: push proxy (`crates/relay-push`, `POST /v1/push`)

Card R2.2 of `phase-02-sms-ios-relay.md`, plus the push part of the shared-contract checks (brief step 3).
Repository handlive-relay, branch `feat/phase-02-sms-ios-relay`, pushed; CI `ci-relay` green on 14a9c3f (run
36222312955). No change in `shared/` or the hub; no key, certificate or service-account file anywhere in the
repository — tests generate their keys at run time.

## What was done

- **New crate `crates/relay-push`** (wired into relay-server through `AppState.push`):
  - `payload.rs` — the APNs payload of CONN-04 API 4 exactly: `aps.alert.loc-key` (`push.sms_new`,
    `push.call_incoming`, `push.call_missed`), `mutable-content: 1`, `sound: "default"`, `thread-id`,
    `interruption-level` (`time-sensitive` only for incoming calls), plus `p` (pair_id) and `hl` (the envelope
    encrypted with `K_push`). No title, no body, no display text (0.12.4). The FCM message of API 3: data
    `{t: "wake", p, r}`, `priority: HIGH`, `ttl` = min(ttl_s, 60) s, `collapse_key: "wake"`, no `notification` block.
  - `apns.rs` — HTTP/2 to `/3/device/<token>` (production, or sandbox for `apns_sandbox` tokens) with
    `authorization: bearer`, `apns-push-type: alert`, `apns-topic`, `apns-priority: 10`, `apns-expiration` = now +
    ttl, `apns-collapse-id`. Provider token: ES256 JWT (`kid`, `iss` = team, `iat`, no `typ`) signed with the `.p8`
    key, reused and renewed every 50 minutes (Apple: not more than every 20, at least every 60) or at once after
    `ExpiredProviderToken` / `InvalidProviderToken`. 410 → token dead; 500/503 and network errors → one retry after
    500 ms; 400, other 403 and 429 → logged by status and APNs reason only. Payload over 4 KB → not sent.
  - `fcm.rs` — service-account JSON (`client_email`, `private_key`, `token_uri`), RS256 assertion for the
    `firebase.messaging` scope traded at `token_uri`, access token reused until five minutes before expiry or renewed
    once after a 401; `UNREGISTERED` → token dead; 500/503/network → one retry; anything else logged by status and
    error code.
  - `config.rs` — only from the environment and key files at run time: `RELAY_APNS_KEY_PATH`, `RELAY_APNS_KEY_ID`,
    `RELAY_APNS_TEAM_ID`, `RELAY_APNS_TOPIC` (+ optional `RELAY_APNS_URL`, `RELAY_APNS_SANDBOX_URL`),
    `RELAY_FCM_PROJECT_ID`, `RELAY_FCM_SERVICE_ACCOUNT_PATH` (+ optional `RELAY_FCM_URL`). A partial set or an
    unreadable key stops the relay (without echoing the key); an unset provider answers 502.
  - HTTP client: reqwest 0.13 on rustls with the ring provider (no aws-lc), OS trust store; request URLs are stripped
    from logged errors (they hold device tokens).
- **`POST /v1/push`** (`routes/push.rs`, CONN-04 API 2): 30 per minute per sender (`rl:<device_id>:push:<minute>`);
  `kind`/`reason` must agree; `env_b64` only with alerts, standard base64, ≤ 3,000 characters (413 beyond);
  `collapse_key` printable ASCII ≤ 64; `ttl_s` 0…86,400 (default per reason); the caller and `to` must be the two
  members of the non-revoked pair (403 `NOT_PAIRED`); `wake` only to Android and `alert` only to iOS/iPadOS (400);
  no token → 409 `PUSH_TOKEN_MISSING`. A wake with the same reason for the same device within 5 minutes answers 202
  without a second send (`wake:<device_id>:<reason>`, released when the send fails). Sent → 202 `{"accepted":true}`
  and one push in the sender's `usage_daily` tally; dead token → cleared in `devices`, 409; provider or configuration
  error → 502 `PUSH_PROVIDER_ERROR`. `env_b64` is passed through and never stored or logged.
- `PUT /v1/devices/me/push-token` also refuses an APNs topic other than `RELAY_APNS_TOPIC` when APNs is configured.
- Docs: README + README.vi (endpoint, push behaviour, variables, mock providers, load-test note), `.env.example` lists
  the push variables commented out, `CLAUDE.md`.

## Commits (handlive-relay, `feat/phase-02-sms-ios-relay`)

| Hash | Subject |
|------|---------|
| 19b371f | feat(relay): add the relay-push crate with the push bodies and settings |
| 0688718 | feat(relay): send APNs alerts over HTTP/2 with a provider token |
| 07d05a1 | feat(relay): send FCM wakes with a service-account OAuth2 token and add the gateway |
| 87d5ce1 | feat(relay): add POST /v1/push to wake phones and alert iPhones |
| 68ab4f7 | test(relay): check the push bodies, answer mapping and settings |
| 6f27865 | test(relay): run the push clients against mock APNs and FCM servers |
| e9fca37 | test(relay): cover POST /v1/push against mock providers |
| 51e04d2 | test(relay): validate relay output against the shared JSON Schemas (shared with R2.1) |
| 32da303 | test(relay): check HR frames, wrapper rewrites and push requests against the shared vectors (shared with R2.1) |
| 1f944c5 | test(relay): send the push-envelope vectors through the APNs client |
| 43a47e5 | docs: describe the push proxy, its settings and the load-test setup |
| 14a9c3f | test(relay): include pushes in the zero-knowledge log check |

## Files

Created: `crates/relay-push/{Cargo.toml,src/{lib,config,payload,apns,fcm,http}.rs}`,
`crates/relay-push/tests/{common/mod.rs,payload_and_verdicts.rs,config_env.rs,mock_providers.rs,shared_push_vectors.rs}`,
`crates/relay-server/src/routes/push.rs`, `crates/relay-server/tests/{common/push_mocks.rs,db_push_rest.rs}`.
Changed: `Cargo.toml` (member, reqwest, rustls, rsa, opt-level for RSA test-key generation), `Cargo.lock`,
`crates/relay-server/{Cargo.toml,src/config.rs,src/state.rs,src/store/devices.rs,src/routes/{mod,devices}.rs}`,
test harness `Config` literals, `tests/relay_log_privacy.rs`, `README.md`, `README.vi.md`, `CLAUDE.md`,
`.env.example`. New crates are MIT, Apache-2.0 or ISC; `webpki-root-certs` (CDLA-Permissive-2.0) is in `Cargo.lock`
through `rustls-platform-verifier` for other targets only and is not compiled for Linux or macOS.

## Tests (real output, from `relay/`)

```text
$ cargo test -p relay-push
Running tests/config_env.rs            test result: ok. 1 passed; 0 failed
Running tests/mock_providers.rs        test result: ok. 4 passed; 0 failed
Running tests/payload_and_verdicts.rs  test result: ok. 5 passed; 0 failed
Running tests/shared_push_vectors.rs   test result: ok. 1 passed; 0 failed

$ set -a && . ./.env.example && set +a && cargo test -- --ignored   (PostgreSQL + Redis)
Running tests/db_push_rest.rs          test result: ok. 3 passed; 0 failed
Running tests/relay_log_privacy.rs     test result: ok. 1 passed; 0 failed
Running tests/shared_schemas.rs        test result: ok. 1 passed; 0 failed
```

What they cover: a mock APNs over HTTP/2 (actix `bind_auto_h2c`) that verifies the ES256 provider token and records
headers and bodies; a mock FCM that verifies the RS256 assertion (iss, scope, aud, exp) and the bearer token; keys
generated per run (P-256 `.p8`, RSA-2048 service account). Checked: every header and payload of CONN-04 API 3–4 and
of the three `push-envelope.json` requests; sandbox routing; provider token and access token reuse; 410 /
`UNREGISTERED` → token cleared and 409; 503 → one retry; `ExpiredProviderToken` → new token; 401 → one renewal;
400 / 429 → 502 without retry; unreachable endpoint; 4 KB overflow never sent; the route's 400 / 403 / 409 / 413 /
429 / 502; wake coalescing and its release after a failure; usage counting; APNs topic check; FCM request and APNs
payload against `push.schema.json`; no envelope, token or id in any log record.

## Spec deviations and proposals (hub not edited)

1. **`push_outbox` is Android's table** (`00-common-specs.md` 0.9.1; `03-connectivity.md` CONN-04 E2 and step 5b;
   `01-setup-settings.md` SET-02 queries). The R2.2 card and the brief ask for "`push_outbox` with a 30 s expiry" on
   the relay, but the contract defines it on the phone and tables change in 00-common-specs first. The relay therefore
   retries once inside the request (500/503/network) and answers 502, so the phone's `push_outbox` retries until its
   deadline (30 s for calls, 24 h for SMS); the relay's own expiry is `apns-expiration` = now + `ttl_s` and the FCM
   TTL. Proposal: move that part of R2.2 to A2.2, or add a relay table to 0.9.4 if a relay-side queue is wanted.
2. **`thread-id` of SMS pushes** (CONN-04 API 4 table; `shared/schemas/push.schema.json#/$defs/apns-payload`;
   `push-envelope.json`): `sms:<thread_id>` is inside the encrypted envelope and `POST /v1/push` has no field for it,
   so the relay cannot produce it. It sends the generic group `sms`; the tests assert that this is the only difference
   from the schema and the vectors. Proposal A (preferred, matches SMS-02 "the push content that the relay and APNs see
   is always generic"): `thread-id` = `sms` for SMS pushes, I-NSE sets `sms:<thread_id>` after decrypting; update the
   schema and the vectors. Proposal B: an optional `thread_key` in `POST /v1/push`.
3. **Dead tokens answer 409, not 502** (CONN-04 E3): after FCM `UNREGISTERED` or APNs 410 the relay deletes the token
   and answers 409 `PUSH_TOKEN_MISSING`, so the phone does not queue a retry for a token that cannot work. APNs 400
   (`BadDeviceToken`, `DeviceTokenNotForTopic`) stays a configuration error (502) as API 4 says.
4. **Defaults the spec leaves open**: `ttl_s` accepted 0–86,400; FCM `collapse_key` always `wake` and TTL capped at 60 s
   (0.4.4); `sound: "default"` kept from the API 4 example (the schema requires it); a push to a Mac → 400; a
   `collapse_key` must be printable ASCII because it becomes a header; an FCM `topic` is ignored (receiver lenient,
   0.5.1 rule 6) and APNs tokens are stored lowercase.
5. **Call TTL**: the default for `call_incoming` stays 60 s per CONN-04 API 2; CALL-01 sends 30 (shared S2.3
   proposal 2). If the hub changes the default to 30, it is one line in `Reason::default_ttl_s`.
6. **Coalescing key** `wake:<device_id>:<reason>` is new in Redis (see R2.1 deviation 6).

## Pending manual checks

- Push reaches a real iPhone in < 2 s (needs the `.p8` key, key id, team id and a device with the app; set
  `RELAY_APNS_*`), locked and unlocked, including the 50-minute provider-token renewal on a long-running relay.
- FCM wake reaches a real Android phone (needs a Firebase project and a service account; `RELAY_FCM_*`).

Status: DONE_WITH_CONCERNS
Summary: relay-push sends FCM wakes and APNs alerts exactly as CONN-04 API 3–4 (HTTP/2, ES256 provider token, OAuth2 service account, loc-key only), and POST /v1/push checks pair, platform, token, limits and coalescing with the spec's error mapping; tested against local mock providers, the shared push vectors and schemas, in CI.
Concerns/Blockers: push_outbox stays on the phone as the detailed design defines it (card and spec disagree); the SMS thread-id cannot be produced by the relay (schema/vectors need a decision); the real-iPhone < 2 s check needs Apple credentials.
