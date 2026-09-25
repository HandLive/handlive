# HandLive relay

Cloud relay (Rust, actix-web 4, sqlx/PostgreSQL 16, Redis 7). Zero-knowledge:
it never decrypts or logs payloads — logs carry only path, status, size and
error code.

Phase 0 scope: Cargo workspace, schema migration (spec
`docs/detailed-design/00-common-specs.md` 0.9.4), device registration and
authentication:

| Method | Path | Spec |
|--------|------|------|
| POST | `/v1/devices` | CONN-03 API 1 (self-signed `HLREG1`) |
| POST | `/v1/auth/challenge` | 0.6.4, CONN-03 API 2 |
| POST | `/v1/auth/token` | 0.6.4, CONN-03 API 3 (JWT HS256, 900 s) |

`AuthenticatedDevice` (`src/auth_extractor.rs`) is the JWT extractor for
later JWT endpoints (checks `sub` still exists in `devices`).

## Layout

```
relay/
  Cargo.toml              workspace (pins the relay stack)
  docker-compose.yml      dev PostgreSQL 16 + Redis 7
  .env.example            dev placeholders; copy to .env (gitignored)
  migrations/             sqlx migrations, applied at server start
  crates/relay-server/    the server (lib + bin); tests/ holds all tests
```

## Development

Rust toolchain on PATH (e.g. `export PATH=/opt/homebrew/opt/rustup/bin:$PATH`).

```bash
cd relay
cargo fmt --check && cargo clippy --all-targets -- -D warnings && cargo test
```

`cargo test` needs no Docker: DB-backed tests are `#[ignore]`d.

### With PostgreSQL + Redis

Host ports are shifted to avoid clashing with a local PostgreSQL/Redis:
PostgreSQL `127.0.0.1:55432`, Redis `127.0.0.1:56379`.

```bash
cd relay
docker compose up -d --wait
set -a && . ./.env.example && set +a      # or your own .env
cargo test -- --ignored                   # DB-backed integration tests
cargo run -p relay-server                 # applies migrations, listens on RELAY_BIND
docker compose down -v                    # stop and drop the dev volume
```

## Configuration

| Variable | Meaning |
|----------|---------|
| `DATABASE_URL` | PostgreSQL URL |
| `REDIS_URL` | Redis URL |
| `RELAY_JWT_SECRET` | HS256 key for device JWTs, ≥ 32 bytes (`openssl rand -base64 48`). Never commit it |
| `RELAY_BIND` | Listen address, default `127.0.0.1:8080` |
| `RUST_LOG` | Log filter, default `info` |
