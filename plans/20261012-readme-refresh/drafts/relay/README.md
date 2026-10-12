English | [Tiếng Việt](README.vi.md)

# handlive-relay

[![License: Apache-2.0](https://img.shields.io/badge/License-Apache_2.0-blue.svg)](LICENSE)

The HandLive zero-knowledge cloud relay service, written in Rust (actix-web 4, actix-ws, sqlx/PostgreSQL 16, Redis 7). It routes end-to-end encrypted traffic between paired HandLive devices across different networks. The relay never inspects, decrypts, or persists payload contents.

## Overview

- **Zero-knowledge forwarding:** Forwards end-to-end encrypted data without decrypting or logging payload contents. Logs contain only HTTP path, status, byte size, and error codes.
- **Headless service:** Contains no user interface and emits no localized text. Errors are returned as standardized machine codes; client applications handle presentation.
- **Multi-instance coordination:** Instances scale horizontally, sharing connection states via Redis (`dev:<device_id>`). If Redis restarts, instances re-subscribe and restore presence without disconnecting active clients.
- **Push dispatch proxy:** Securely forwards wake-up notifications to Android via FCM HTTP v1 and alert notifications to Apple devices via APNs over HTTP/2.

## Workspace context

This repository is one component of the HandLive workspace:
- Hub repository [`handlive`](https://github.com/HandLive/handlive) (docs, plans) is the parent directory.
- [`handlive-shared`](https://github.com/HandLive/handlive-shared) (`../shared`) supplies shared protocol schemas and test vectors (integration tests read `../shared/test-vectors`).
- Clone the full workspace from the hub using `tools/workspace.sh clone <group-url>`. See [`CLAUDE.md`](CLAUDE.md) for local workspace workflows.

## Endpoints

Specification: [`docs/detailed-design/00-common-specs.md`](https://github.com/HandLive/handlive/blob/main/docs/detailed-design/00-common-specs.md) (0.4.3, 0.6.4, 0.7.3, 0.7.4, 0.8.2, 0.8.3, 0.9.4).

| Method | Path | Auth | Spec |
|--------|------|------|------|
| POST | `/v1/devices` | `HLREG1` signature | CONN-03 API 1; at most 10 new devices per client IP per hour |
| POST | `/v1/auth/challenge` | — | 0.6.4, CONN-03 API 2 |
| POST | `/v1/auth/token` | — | 0.6.4, CONN-03 API 3 (JWT HS256, 900 s) |
| PUT | `/v1/devices/me/push-token` | JWT | CONN-04 API 1 |
| DELETE | `/v1/devices/me?revoke_pairs=<bool>` | JWT | SET-02 API 2, decision C16; `true` requires one signed `HLREVOKE1` statement per unrevoked pair |
| POST | `/v1/pairs` | JWT | PAIR-01 API 8 (attestation + two signatures) |
| GET | `/v1/pairs[?include_revoked=<bool>]` | JWT | PAIR-02 API 1 |
| POST | `/v1/pairs/{pair_id}/revoke` | JWT | PAIR-03 API 3; body `{revoked_at, sig}` (`HLREVOKE1`, 0.6.2) |
| POST | `/v1/push` | JWT | CONN-04 API 2–4 (FCM wake, APNs alert) |
| GET (WebSocket) | `/v1/relay` | JWT | CONN-03 API 4–6, PAIR-01 API 7, PAIR-03 API 4 |

Every JWT endpoint verifies device existence (404 `DEVICE_NOT_FOUND`, 410 `DEVICE_REVOKED`) and enforces a rate limit of 60 calls per minute per device (429 with `Retry-After`). `POST /v1/push` enforces an additional limit of 30 calls per minute per sender.

### Push proxy (`crates/relay-push`)

- `wake` → FCM HTTP v1 to Android: high-priority data message `{t: "wake", p: <pair_id>, r: <reason>}`, TTL ≤ 60 s, no payload content. OAuth2 access token from Google service account JSON.
- `alert` → APNs over HTTP/2 to Apple devices: `apns-push-type: alert`, `apns-priority: 10`, `aps.alert.loc-key` (`push.sms_new`, `push.call_incoming`, `push.call_missed`), plus encrypted envelope `hl` sealed with `K_push`. ES256 provider token renewed every 50 minutes.
- `ttl_s` defaults to 60 s for wake, 30 s for incoming call, and 86,400 s for new SMS or missed call. Target must belong to an active pair (403) and have a registered push token (409 `PUSH_TOKEN_MISSING`). Duplicate wake requests within 5 minutes return 202 without re-transmitting.

### Relay channel (`/v1/relay`)

- Text frames `{"to","env"}` are forwarded as `{"from","env"}` with byte-identical envelope copying. Binary `HR` frames (`0x48 0x52` ‖ ver ‖ op ‖ device_id ‖ HL frame) substitute destination `device_id` with source ID.
- Traffic is restricted to verified pairs (`error NOT_PAIRED`); disconnected peers yield `error NOT_CONNECTED`; frames exceeding 256 KiB return `error PAYLOAD_TOO_LARGE`. Bandwidth exceeding 2 MiB/s per pair throttles socket reads.
- Control operations: `presence`, `pair_revoked` with signed statement, rendezvous pairing (`rv_join` / `rv_joined` / `rv_msg`), and `error`.
- Close codes: 1000 (clean disconnect), 4400 (malformed stream), 4409 (superseded by newer connection), 4411 (heartbeat timeout after 45 s idle; pings every 15 s), 4500 (internal error).

## Layout

```
relay/
  Cargo.toml              workspace (pins the relay stack)
  docker-compose.yml      dev PostgreSQL 16 + Redis 7
  .env.example            dev placeholders; copy to .env (gitignored)
  migrations/             sqlx migrations, applied at server start
  crates/relay-server/    the server (lib + bin); tests/ holds all tests
  crates/relay-push/      push proxy: APNs (HTTP/2, .p8 token) and FCM (HTTP v1, OAuth2)
    src/routes/           REST handlers and the /v1/relay upgrade
    src/relay/            relay channel: wire formats, Redis bus and hub,
                          presence, rendezvous, bandwidth, connection task
    src/store/            PostgreSQL queries (devices, pairs, usage_daily)
```

## Requirements

- **Rust:** Rust toolchain (edition 2021) on PATH
- **Docker Compose:** Docker & Docker Compose for PostgreSQL 16 + Redis 7 services during integration testing and development

## Development

Requires a Rust toolchain on PATH (e.g. `export PATH=/opt/homebrew/opt/rustup/bin:$PATH`).

```bash
cd relay
cargo fmt --check && cargo clippy --all-targets -- -D warnings && cargo test
```

`cargo test` runs without external dependencies; tests requiring PostgreSQL and Redis are marked `#[ignore]`.

### With PostgreSQL + Redis

Host ports are offset to prevent conflicts with local services: PostgreSQL `127.0.0.1:55432`, Redis `127.0.0.1:56379`.

```bash
cd relay
docker compose up -d --wait
set -a && . ./.env.example && set +a      # or your own .env
cargo test -- --ignored                   # integration tests (real WebSockets, two instances)
cargo run -p relay-server                 # applies migrations, listens on RELAY_BIND
docker compose down -v                    # stop and drop the dev volume
```

Integration tests flush Redis (`tests/relay_redis_restart.rs`); run integration tests against a dev Redis instance only. Push tests use mock APNs/FCM servers with ephemeral keys; no external credentials are required.

Single-machine load test: run `../shared/tools/bench/relay_load.py` against a loopback or trusted proxy setup with elevated `RELAY_MAX_REGISTRATIONS_PER_HOUR`.

## Configuration

| Variable | Meaning |
|----------|---------|
| `DATABASE_URL` | PostgreSQL connection URL |
| `REDIS_URL` | Redis connection URL |
| `RELAY_JWT_SECRET` | HS256 secret key for device JWTs, ≥ 32 bytes (`openssl rand -base64 48`). Never commit this key |
| `RELAY_BIND` | Server listen address, default `127.0.0.1:8080` |
| `RELAY_INSTANCE_ID` | Optional instance name for `presence:<device_id>`; defaults to random UUID per start |
| `RELAY_TRUSTED_PROXIES` | Optional comma-separated reverse proxy IPs trusted for `X-Forwarded-For` headers. Loopback binds trust `127.0.0.1` and `::1` by default |
| `RELAY_MAX_REGISTRATIONS_PER_HOUR` | Cap on new device registrations per hour across the relay, default 1000; excess returns 429 `RATE_LIMITED` |
| `RELAY_APNS_KEY_PATH` | Path to APNs `.p8` provider key file (outside repository) |
| `RELAY_APNS_KEY_ID` | Key ID for APNs `.p8` key (JWT `kid`) |
| `RELAY_APNS_TEAM_ID` | Apple Developer Team ID (JWT `iss`) |
| `RELAY_APNS_TOPIC` | iOS application bundle ID (`app.handlive.ios`) |
| `RELAY_APNS_URL`, `RELAY_APNS_SANDBOX_URL` | APNs endpoints, default `https://api.push.apple.com` and `https://api.sandbox.push.apple.com` |
| `RELAY_FCM_PROJECT_ID` | Firebase project ID |
| `RELAY_FCM_SERVICE_ACCOUNT_PATH` | Path to Google service-account JSON file (outside repository) |
| `RELAY_FCM_URL` | FCM endpoint, default `https://fcm.googleapis.com` |
| `RUST_LOG` | Logging filter, default `info` |

## Documentation and community

- [System Architecture](https://github.com/HandLive/handlive/blob/main/docs/system-architecture.md) — System design and security model
- [Detailed Design](https://github.com/HandLive/handlive/tree/main/docs/detailed-design) — Protocols, formats, and specifications
- [Deployment Guide](https://github.com/HandLive/handlive/blob/main/docs/deployment-guide.md) — Packaging and distribution guidelines
- [CONTRIBUTING](https://github.com/HandLive/.github/blob/main/CONTRIBUTING.md) — PR workflow, small commits, and DCO sign-off (`git commit -s`)
- [SECURITY](https://github.com/HandLive/.github/blob/main/SECURITY.md) — Vulnerability reporting policy
- [CODE_OF_CONDUCT](https://github.com/HandLive/.github/blob/main/CODE_OF_CONDUCT.md) — Community standards

## License

Apache License 2.0 — see [LICENSE](LICENSE).
