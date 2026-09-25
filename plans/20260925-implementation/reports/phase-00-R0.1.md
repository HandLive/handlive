# Báo cáo R0.1 [relay] — Khung relay, migration 0.9.4, xác thực thiết bị

Ngày: 2026-09-25 · Nhánh: `feat/phase-00-khung` · Chưa commit (điều phối viên commit).

## Việc đã làm

- Cargo workspace `relay/` (edition 2024, `rust-version` 1.88 vì `jsonwebtoken` 11 cần), một crate
  `crates/relay-server` (lib + bin). Stack ghim ở `[workspace.dependencies]`: actix-web 4.15, sqlx
  0.9 (postgres, migrate; chỉ dùng query lúc chạy, không cần `DATABASE_URL` khi build), redis 1.7
  (`ConnectionManager`), jsonwebtoken 11.1 (`rust_crypto`), ed25519-dalek 3.0 (`verify_strict`),
  ring 0.17 (SHA-256, `SystemRandom`), subtle (so hằng thời gian).
- `docker-compose.yml` dev: `postgres:16-alpine` → `127.0.0.1:55432`, `redis:7-alpine` →
  `127.0.0.1:56379` (tránh postgresql@18 của brew ở 5432), có healthcheck, volume `pgdata` riêng.
- Migration `migrations/20260925000000_initial_schema.sql`: chép nguyên lược đồ 0.9.4 (`devices`,
  `pairs`, `usage_daily`, hai index một phần). Server chạy `MIGRATOR.run` lúc khởi động
  (`sqlx::migrate!` nhúng file).
- Endpoint (đúng 0.6.4, 0.7.4, CONN-03 API 1–3):
  - `POST /v1/devices` — spec có endpoint đăng ký (CONN-03 API 1) nên làm đúng nó, không bịa: kiểm
    `platform`, `app_version` ≤ 32 ký tự, `ts` lệch ≤ 5 phút, `device_id` =
    UUIDv8(SHA-256(`ik_sig_pub`)) (C4), chữ ký `"HLREG1"` ‖ device_id(16) ‖ ik_sig_pub(32) ‖
    UTF-8(platform) ‖ ts(int64 BE). Upsert đúng query spec; 201 mới / 200 cập nhật (phân biệt bằng
    `xmax = 0`), 410 `DEVICE_REVOKED`.
  - `POST /v1/auth/challenge` — thiết bị phải có trong `devices` (404/410), rate limit 10/phút/thiết
    bị bằng `rl:<device_id>:chal:<phút>` (TTL 120 s, 429 + `Retry-After`), 32 byte ngẫu nhiên →
    `SET chal:<device_id> EX 60` (ghi đè), trả `{challenge (b64u), expires_at (ms)}`.
  - `POST /v1/auth/token` — `GETDEL chal:<device_id>`; không có/khác → 401 `CHALLENGE_EXPIRED` (so
    hằng thời gian); kiểm Ed25519(`"HLAUTH1"` ‖ challenge 32 byte ‖ device_id 16 byte) bằng
    `ik_sig_pub` trong `devices` → 401 `SIGNATURE_INVALID`; cập nhật `last_seen_at`; trả
    `{access_token, expires_in: 900}`.
- JWT **HS256** (theo quyết định điều phối viên), claim `sub` (device_id), `iat`, `exp` (= iat +
  900), `jti` (UUIDv4), leeway 0. Khóa từ biến môi trường `RELAY_JWT_SECRET` (≥ 32 byte, từ chối nếu
  ngắn). Hết hạn → `TOKEN_EXPIRED`; mọi lỗi khác (sai khóa, `alg: none`, hỏng) →
  `SIGNATURE_INVALID`.
- Extractor `AuthenticatedDevice` (`src/auth_extractor.rs`): `Authorization: Bearer`, kiểm JWT, rồi
  kiểm `sub` còn dòng trong `devices` → 404 `DEVICE_NOT_FOUND` dù JWT còn hạn (0.6.4 bước 4); dòng
  có `revoked_at` → 410. Chưa có endpoint JWT nào thuộc Phase 0, nên extractor được kiểm qua route
  chỉ có trong test (`/test/whoami`).
- Lỗi đúng 0.4.3/0.8.2: `{"error":{"code","message"}}`, message cố định, không lặp lại body. JSON
  hỏng → 400, body > 4 KiB → 413.
- Zero-knowledge: log truy cập chỉ `%U %s %b %D` (đường dẫn, status, kích thước, thời gian — không
  query, không body); lỗi nội bộ chỉ log ngữ cảnh + lỗi hạ tầng.
- Bí mật: `.env.example` chỉ giá trị giả; `relay/.env` bị gitignore (quy tắc gốc `.env`);
  `relay/target/` bị gitignore. Quy tắc gốc `.env.*` nuốt luôn `.env.example` → thêm
  `relay/.gitignore` với `!.env.example`.

## File tạo mới

- `relay/Cargo.toml`, `relay/Cargo.lock`, `relay/.gitignore`, `relay/.env.example`,
  `relay/docker-compose.yml`, `relay/README.md` (cổng, lệnh chạy, biến môi trường)
- `relay/migrations/20260925000000_initial_schema.sql`
- `relay/crates/relay-server/Cargo.toml`
- `relay/crates/relay-server/src/`: `main.rs`, `lib.rs`, `config.rs`, `state.rs`, `error.rs`,
  `b64u.rs`, `clock.rs`, `device_identity.rs`, `signatures.rs`, `challenge.rs`, `jwt.rs`,
  `auth_extractor.rs`, `routes/{mod,auth,devices}.rs`, `store/{mod,challenges,devices}.rs` (file lớn
  nhất 114 dòng)
- `relay/crates/relay-server/tests/`: `common/{mod,http_harness}.rs`, `device_identity_vectors.rs`,
  `signature_verification.rs`, `challenge_and_token_proof.rs`, `jwt_tokens.rs`,
  `registration_validation.rs`, `error_responses.rs` (không cần Docker);
  `db_schema_and_registration.rs`, `db_auth_and_jwt.rs` (`#[ignore]`, cần `DATABASE_URL`,
  `REDIS_URL`)

## Test

Không cần Docker (26 test): vector `shared/test-vectors/device-id.json` (3 vector: device_id, byte,
version 8/variant, seed → pub); chữ ký RFC 8032 §7.1 TEST 1–2 (hằng trong test, cùng khóa với
`device-id.json`) qua `verify_device_signature`, sửa 1 bit → sai; bố cục `HLAUTH1` (55 byte) và
`HLREG1`; chữ ký khóa khác / `device_id` không khớp khóa / challenge khác → `SIGNATURE_INVALID`;
challenge không có (hết hạn hoặc đã dùng) / khác / hỏng → `CHALLENGE_EXPIRED`, thứ tự kiểm
(challenge trước chữ ký); `DEVICE_NOT_FOUND` /`DEVICE_REVOKED`; rate limit 10/phút + `Retry-After`;
JWT HS256 đủ claim, 900 s, `jti` khác nhau, hết hạn → `TOKEN_EXPIRED`, sai khóa / sửa / `alg: none`
→ `SIGNATURE_INVALID`; đăng ký: ts lệch, platform/app_version/b64u sai → 400, chữ ký không phủ
trường bị sửa; bảng status + body của mọi mã; phân tích header Bearer.

Tích hợp (6 test, Postgres 16 + Redis 7 thật): lược đồ (3 bảng + 2 index); đăng ký 201 → 200 cùng
`created_at`, `device_id` giả → 401, dòng thu hồi → 410; challenge thiết bị lạ → 404; luồng đủ
challenge → token → extractor; dùng lại challenge → `CHALLENGE_EXPIRED`; TTL Redis hết thật
(`PEXPIRE` 1 ms) → `CHALLENGE_EXPIRED`; chữ ký khóa khác → `SIGNATURE_INVALID` và challenge bị tiêu;
không header → 401, JWT hết hạn → `TOKEN_EXPIRED`, JWT còn hạn nhưng thiết bị thu hồi → 410, bị xóa
→ 404 `DEVICE_NOT_FOUND`; rate limit 429 + `Retry-After`; JSON hỏng → 400; body 8 KiB → 413.

```
$ cd relay && cargo fmt --check && cargo clippy --all-targets -- -D warnings && cargo test
    Finished `dev` profile [unoptimized + debuginfo] target(s) in 0.17s
     Running tests/challenge_and_token_proof.rs
test result: ok. 6 passed; 0 failed; 0 ignored; 0 measured; 0 filtered out; finished in 0.00s
     Running tests/db_auth_and_jwt.rs
test challenge_token_and_jwt_extractor ... ignored, needs PostgreSQL + Redis (docker compose)
test expired_challenge_and_wrong_signature ... ignored, needs PostgreSQL + Redis (docker compose)
test jwt_rejections ... ignored, needs PostgreSQL + Redis (docker compose)
test rate_limit_and_body_errors ... ignored, needs PostgreSQL + Redis (docker compose)
test result: ok. 0 passed; 0 failed; 4 ignored; 0 measured; 0 filtered out; finished in 0.00s
     Running tests/db_schema_and_registration.rs
test register_then_refresh ... ignored, needs PostgreSQL + Redis (docker compose)
test schema_matches_spec_tables_and_indexes ... ignored, needs PostgreSQL + Redis (docker compose)
test result: ok. 0 passed; 0 failed; 2 ignored; 0 measured; 0 filtered out; finished in 0.00s
     Running tests/device_identity_vectors.rs
test result: ok. 3 passed; 0 failed; 0 ignored; 0 measured; 0 filtered out; finished in 0.00s
     Running tests/error_responses.rs
test result: ok. 3 passed; 0 failed; 0 ignored; 0 measured; 0 filtered out; finished in 0.00s
     Running tests/jwt_tokens.rs
test result: ok. 5 passed; 0 failed; 0 ignored; 0 measured; 0 filtered out; finished in 0.00s
     Running tests/registration_validation.rs
test result: ok. 5 passed; 0 failed; 0 ignored; 0 measured; 0 filtered out; finished in 0.00s
     Running tests/signature_verification.rs
test result: ok. 4 passed; 0 failed; 0 ignored; 0 measured; 0 filtered out; finished in 0.00s
```

```
$ cd relay && docker compose up -d --wait \
    && set -a && . ./.env.example && set +a \
    && cargo test -- --ignored \
    && docker compose down -v
 Container handlive-relay-dev-postgres-1 Healthy
 Container handlive-relay-dev-redis-1 Healthy
test rate_limit_and_body_errors ... ok
test challenge_token_and_jwt_extractor ... ok
test jwt_rejections ... ok
test expired_challenge_and_wrong_signature ... ok
test result: ok. 4 passed; 0 failed; 0 ignored; 0 measured; 0 filtered out; finished in 0.21s
test schema_matches_spec_tables_and_indexes ... ok
test register_then_refresh ... ok
test result: ok. 2 passed; 0 failed; 0 ignored; 0 measured; 0 filtered out; finished in 0.11s
 Volume handlive-relay-dev_pgdata Removed
 Network handlive-relay-dev_default Removed
```

Server khởi động trên DB trống, áp migration (lần chạy đầu), trả lỗi đúng dạng:

```
$ ./target/debug/relay-server        # env từ .env.example
[2026-09-25T01:40:48Z INFO  relay_server] migrations applied; listening on 127.0.0.1:8080
[2026-09-25T01:40:48Z INFO  actix_web::middleware::logger] /v1/auth/challenge 404 71 1.971000ms
[2026-09-25T01:40:48Z INFO  actix_web::middleware::logger] /v1/auth/token 400 67 0.133000ms
$ curl -X POST :8080/v1/auth/challenge -d '{"device_id":"21fe31df-a154-8261-a26b-f854046fd227"}'
{"error":{"code":"DEVICE_NOT_FOUND","message":"Device not registered"}}
$ psql ... -c 'SELECT version, description, success FROM _sqlx_migrations'
 20260925000000 | initial schema | t
```

Sau khi kiểm: `docker compose down -v` (chỉ volume `handlive-relay-dev_pgdata`). Ảnh
`postgres:16-alpine`, `redis:7-alpine` vẫn nằm trong cache Docker.

## Điểm lệch với tài liệu

| # | Chỗ | Làm | Đề xuất |
|---|-----|-----|---------|
| 1 | Thẻ R0.1 ghi "JWT ES256" | HS256 theo 0.6.4 và CONN-03 API 3 (điều phối viên đã quyết) | Sửa thẻ R0.1 trong `phase-00-khung-va-dung-chung.md` thành HS256 |
| 2 | `devices.revoked_at`: không chỗ nào trong spec đặt giá trị (SET-02 xóa hẳn dòng) | Dòng có `revoked_at` → 410 `DEVICE_REVOKED` ở đăng ký, challenge, token và extractor; không có dòng → 404 | Ghi rõ trong 0.6.4 bước 4 hoặc bỏ cột nếu không dùng |
| 3 | Thiếu/sai header `Authorization` không có mã riêng | 401 `SIGNATURE_INVALID` (cùng nhóm "JWT sai" của CONN-03 API 4) | Ghi vào 0.8.2 |
| 4 | 0.8.2 không có mã 5xx | 500 `INTERNAL` (mã của 0.8.1) | Thêm dòng 500 vào 0.8.2 |
| 5 | CONN-03 API 3 chỉ liệt kê 401 | Có thêm 400 `BAD_REQUEST` (`sig` không phải b64u 64 byte), 404/410 khi thiết bị không còn/bị thu hồi | Bổ sung danh sách lỗi API 3 |
| 6 | Byte `challenge` trong `HLAUTH1` | 32 byte thô (đã giải b64u), giống quy ước `T1`/`T_offer` | Ghi rõ trong 0.6.4; thêm vector (xem dưới) |
| 7 | Giới hạn 10 đăng ký mới/giờ/IP (CONN-03 API 1) | **Chưa làm**: khóa Redis theo IP chưa có trong 0.9.4 và IP thật phụ thuộc reverse proxy lúc triển khai | Làm ở Phase 2 cùng cấu hình proxy; thêm khóa `rl:ip:<ip>:reg:<giờ>` vào 0.9.4 |
| 8 | Crate `actix-ws` | Chỉ ghim phiên bản ở `[workspace.dependencies]`, chưa crate nào dùng (YAGNI: `/v1/relay` là Phase 2) | — |
| 9 | Khóa HS256 | Biến môi trường `RELAY_JWT_SECRET`, byte UTF-8 thô, ≥ 32 byte | Ghi vào `docs/deployment-guide.md` phần relay |

## Test vector

- Đã dùng `device-id.json` (đủ 3 vector). Không dùng `hkdf-sha256.json`: relay Phase 0 không có
  HKDF. `shared/` không có file Ed25519 → dùng chữ ký RFC 8032 §7.1 TEST 1–2 (cùng khóa với
  `device-id.json`) viết thẳng trong `signature_verification.rs`.
- **Đề xuất cho S0.1** (không sửa `shared/`): thêm `relay-auth.json` với khóa RFC 8032 TEST 1–3:
  `hlreg1_message` /`hlreg1_sig` (platform, ts cố định) và `hlauth1_message` /`hlauth1_sig`
  (challenge cố định), để Android/Apple ký đúng byte relay kiểm; và `ed25519.json` (RFC 8032 §7.1
  TEST 1–3 + vector âm) cho `attestation` của PAIR-01.

## Gợi ý cho T0.1 (CI relay)

`cargo fmt --check`, `cargo clippy --all-targets -- -D warnings`, `cargo test` chạy không cần dịch
vụ. Muốn chạy test tích hợp: service container `postgres:16` + `redis:7`, đặt `DATABASE_URL`,
`REDIS_URL`, rồi `cargo test -- --ignored`. Toolchain ≥ 1.88.

## Câu hỏi còn mở

- `devices.revoked_at` dùng khi nào (điểm lệch 2)?
- IP rate limit đăng ký: nguồn IP (header `X-Forwarded-For` của proxy nào) — quyết khi triển khai
  Phase 2.

```text
Status: DONE_WITH_CONCERNS
Summary: relay/ đã có workspace, migration 0.9.4, POST /v1/devices, /v1/auth/challenge, /v1/auth/token (JWT HS256) và extractor JWT; fmt/clippy/test xanh, 6 test tích hợp xanh trên Postgres 16 + Redis 7 thật.
Concerns/Blockers: Chưa làm giới hạn đăng ký theo IP (cần quyết định về proxy); ngữ nghĩa devices.revoked_at chưa được spec định nghĩa; đề xuất thêm vector relay-auth.json/ed25519.json vào shared/.
```
