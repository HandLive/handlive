[English](README.md) | Tiếng Việt

# handlive-relay

[![License: Apache-2.0](https://img.shields.io/badge/License-Apache_2.0-blue.svg)](LICENSE)

Dịch vụ máy chủ chuyển tiếp (relay) đám mây không lưu dữ liệu của HandLive, viết bằng Rust (actix-web 4, actix-ws, sqlx/PostgreSQL 16, Redis 7). Dịch vụ định tuyến lưu lượng đã mã hóa đầu-cuối giữa các thiết bị HandLive đã ghép nối khi khác mạng. Relay không bao giờ đọc, giải mã hay lưu trữ nội dung dữ liệu truyền qua.

## Tổng quan

- **Chuyển tiếp không lưu dữ liệu:** Chuyển tiếp dữ liệu đã mã hóa đầu-cuối mà không giải mã hay ghi log nội dung. Log chỉ ghi nhận đường dẫn HTTP, mã trạng thái, kích thước byte và mã lỗi.
- **Dịch vụ không giao diện:** Không có giao diện người dùng và không phát ra chuỗi hiển thị bản địa hóa. Lỗi được trả về dưới dạng mã máy chuẩn hóa; ứng dụng phía máy khách tự hiển thị theo ngôn ngữ tương ứng.
- **Điều phối nhiều instance:** Các instance mở rộng theo chiều ngang, chia sẻ trạng thái kết nối qua Redis (`dev:<device_id>`). Khi Redis khởi động lại, các instance tự động đăng ký lại kênh và khôi phục presence mà không ngắt các máy khách đang kết nối.
- **Proxy điều phối push:** Chuyển tiếp an toàn thông báo đánh thức tới Android qua FCM HTTP v1 và thông báo cảnh báo tới thiết bị Apple qua APNs trên nền HTTP/2.

## Bối cảnh workspace

Kho lưu trữ này là một thành phần trong workspace HandLive:
- Kho hub [`handlive`](https://github.com/HandLive/handlive) (tài liệu, kế hoạch) là thư mục cha.
- [`handlive-shared`](https://github.com/HandLive/handlive-shared) (`../shared`) cung cấp JSON schema và test vector dùng chung (test tích hợp đọc `../shared/test-vectors`).
- Clone toàn bộ workspace từ hub bằng lệnh `tools/workspace.sh clone <group-url>`. Xem [`CLAUDE.md`](CLAUDE.md) để biết quy trình làm việc trong workspace.

## Endpoint

Đặc tả: [`docs/detailed-design/00-common-specs.md`](https://github.com/HandLive/handlive/blob/main/docs/detailed-design/00-common-specs.md) (0.4.3, 0.6.4, 0.7.3, 0.7.4, 0.8.2, 0.8.3, 0.9.4).

| Method | Đường dẫn | Xác thực | Đặc tả |
|--------|-----------|----------|--------|
| POST | `/v1/devices` | Chữ ký `HLREG1` | CONN-03 API 1; tối đa 10 thiết bị mới mỗi giờ cho một IP máy khách |
| POST | `/v1/auth/challenge` | — | 0.6.4, CONN-03 API 2 |
| POST | `/v1/auth/token` | — | 0.6.4, CONN-03 API 3 (JWT HS256, 900 s) |
| PUT | `/v1/devices/me/push-token` | JWT | CONN-04 API 1 |
| DELETE | `/v1/devices/me?revoke_pairs=<bool>` | JWT | SET-02 API 2, quyết định C16; `true` cần một tuyên bố `HLREVOKE1` đã ký cho mỗi cặp chưa thu hồi |
| POST | `/v1/pairs` | JWT | PAIR-01 API 8 (chứng thực + hai chữ ký) |
| GET | `/v1/pairs[?include_revoked=<bool>]` | JWT | PAIR-02 API 1 |
| POST | `/v1/pairs/{pair_id}/revoke` | JWT | PAIR-03 API 3; thân `{revoked_at, sig}` (`HLREVOKE1`, 0.6.2) |
| POST | `/v1/push` | JWT | CONN-04 API 2–4 (đánh thức FCM, cảnh báo APNs) |
| GET (WebSocket) | `/v1/relay` | JWT | CONN-03 API 4–6, PAIR-01 API 7, PAIR-03 API 4 |

Mọi endpoint dùng JWT đều kiểm tra thiết bị còn tồn tại (404 `DEVICE_NOT_FOUND`, 410 `DEVICE_REVOKED`) và áp dụng giới hạn 60 lượt gọi mỗi phút cho mỗi thiết bị (429 kèm `Retry-After`). `POST /v1/push` có giới hạn riêng 30 lượt gọi mỗi phút cho mỗi thiết bị gửi.

### Proxy push (`crates/relay-push`)

- `wake` → FCM HTTP v1 tới Android: tin dữ liệu ưu tiên cao `{t: "wake", p: <pair_id>, r: <reason>}`, TTL ≤ 60 s, không chứa nội dung tin nhắn. Token truy cập OAuth2 lấy từ file JSON service account của Google.
- `alert` → APNs qua HTTP/2 tới thiết bị Apple: `apns-push-type: alert`, `apns-priority: 10`, `aps.alert.loc-key` (`push.sms_new`, `push.call_incoming`, `push.call_missed`), cùng envelope mã hóa `hl` niêm phong bằng `K_push`. Token nhà cung cấp ES256 được làm mới mỗi 50 phút.
- `ttl_s` mặc định 60 s cho wake, 30 s cho cuộc gọi đến, và 86.400 s cho SMS mới hoặc cuộc gọi nhỡ. Đích đến phải thuộc về một cặp hợp lệ (403) và đã đăng ký push token (409 `PUSH_TOKEN_MISSING`). Yêu cầu wake trùng lặp cùng lý do trong 5 phút sẽ trả về 202 mà không gửi lại.

### Kênh relay (`/v1/relay`)

- Khung văn bản `{"to","env"}` được chuyển tiếp thành `{"from","env"}` với phần envelope được sao chép nguyên từng byte. Khung nhị phân `HR` (`0x48 0x52` ‖ ver ‖ op ‖ device_id ‖ khung HL) thay thế `device_id` đích bằng ID nguồn.
- Lưu lượng bị giới hạn trong các cặp đã xác thực (`error NOT_PAIRED`); máy kia mất kết nối sẽ nhận `error NOT_CONNECTED`; khung vượt quá 256 KiB trả về `error PAYLOAD_TOO_LARGE`. Băng thông vượt quá 2 MiB/s cho mỗi cặp sẽ làm chậm tốc độ đọc socket.
- Thao tác điều khiển: `presence`, `pair_revoked` kèm tuyên bố đã ký, điểm hẹn ghép nối (`rv_join` / `rv_joined` / `rv_msg`), và `error`.
- Mã đóng kết nối: 1000 (ngắt kết nối chủ động), 4400 (luồng dữ liệu sai định dạng), 4409 (bị kết nối mới hơn thay thế), 4411 (hết thời gian chờ sau 45 s nhàn rỗi; ping mỗi 15 s), 4500 (lỗi nội bộ).

## Bố cục

```
relay/
  Cargo.toml              workspace (ghim phiên bản bộ thư viện relay)
  docker-compose.yml      PostgreSQL 16 + Redis 7 cho dev
  .env.example            giá trị giữ chỗ cho dev; chép thành .env (gitignore)
  migrations/             migration sqlx, chạy khi server khởi động
  crates/relay-server/    server (lib + bin); tests/ chứa mọi test
  crates/relay-push/      proxy push: APNs (HTTP/2, token .p8) và FCM (HTTP v1, OAuth2)
    src/routes/           handler REST và phần nâng cấp /v1/relay
    src/relay/            kênh relay: định dạng khung, bus và hub Redis,
                          presence, điểm hẹn, băng thông, tác vụ kết nối
    src/store/            truy vấn PostgreSQL (devices, pairs, usage_daily)
```

## Yêu cầu

- **Rust:** Rust toolchain (edition 2021) trên PATH
- **Docker Compose:** Docker & Docker Compose để chạy dịch vụ PostgreSQL 16 + Redis 7 khi test tích hợp và phát triển

## Phát triển

Yêu cầu Rust toolchain trên PATH (ví dụ `export PATH=/opt/homebrew/opt/rustup/bin:$PATH`).

```bash
cd relay
cargo fmt --check && cargo clippy --all-targets -- -D warnings && cargo test
```

`cargo test` chạy không cần dịch vụ ngoài; các test cần PostgreSQL và Redis được đánh dấu `#[ignore]`.

### Với PostgreSQL + Redis

Cổng máy host được đổi để tránh xung đột với dịch vụ cục bộ: PostgreSQL `127.0.0.1:55432`, Redis `127.0.0.1:56379`.

```bash
cd relay
docker compose up -d --wait
set -a && . ./.env.example && set +a      # hoặc file .env của bạn
cargo test -- --ignored                   # test tích hợp (WebSocket thật, hai instance)
cargo run -p relay-server                 # chạy migration, lắng nghe ở RELAY_BIND
docker compose down -v                    # dừng và xóa volume dev
```

Test tích hợp sẽ xóa sạch Redis (`tests/relay_redis_restart.rs`); chỉ chạy test tích hợp trên instance Redis dành cho dev. Test push sử dụng máy chủ APNs/FCM giả lập kèm khóa tạm thời; không yêu cầu thông tin xác thực thật từ nhà cung cấp.

Kiểm thử tải trên một máy: chạy `../shared/tools/bench/relay_load.py` trên cấu hình loopback hoặc proxy tin cậy với mức `RELAY_MAX_REGISTRATIONS_PER_HOUR` được nâng cao.

## Cấu hình

| Biến | Ý nghĩa |
|------|---------|
| `DATABASE_URL` | URL kết nối PostgreSQL |
| `REDIS_URL` | URL kết nối Redis |
| `RELAY_JWT_SECRET` | Khóa bí mật HS256 cho JWT thiết bị, ≥ 32 byte (`openssl rand -base64 48`). Tuyệt đối không commit khóa này |
| `RELAY_BIND` | Địa chỉ lắng nghe của máy chủ, mặc định `127.0.0.1:8080` |
| `RELAY_INSTANCE_ID` | Tùy chọn tên instance ghi vào `presence:<device_id>`; mặc định là một UUID ngẫu nhiên mỗi lần khởi động |
| `RELAY_TRUSTED_PROXIES` | Danh sách IP reverse proxy tin cậy (phân tách bằng dấu phẩy) cho header `X-Forwarded-For`. Khi lắng nghe ở loopback, mặc định tin `127.0.0.1` và `::1` |
| `RELAY_MAX_REGISTRATIONS_PER_HOUR` | Giới hạn đăng ký thiết bị mới mỗi giờ trên toàn bộ relay, mặc định 1000; vượt quá trả về 429 `RATE_LIMITED` |
| `RELAY_APNS_KEY_PATH` | Đường dẫn file khóa nhà cung cấp APNs `.p8` (nằm ngoài kho lưu trữ) |
| `RELAY_APNS_KEY_ID` | ID khóa cho file `.p8` của APNs (JWT `kid`) |
| `RELAY_APNS_TEAM_ID` | Apple Developer Team ID (JWT `iss`) |
| `RELAY_APNS_TOPIC` | Bundle ID của ứng dụng iOS (`app.handlive.ios`) |
| `RELAY_APNS_URL`, `RELAY_APNS_SANDBOX_URL` | Endpoint APNs, mặc định `https://api.push.apple.com` và `https://api.sandbox.push.apple.com` |
| `RELAY_FCM_PROJECT_ID` | Project ID Firebase |
| `RELAY_FCM_SERVICE_ACCOUNT_PATH` | Đường dẫn file JSON service account của Google (nằm ngoài kho lưu trữ) |
| `RELAY_FCM_URL` | Endpoint FCM, mặc định `https://fcm.googleapis.com` |
| `RUST_LOG` | Bộ lọc log, mặc định `info` |

## Tài liệu và cộng đồng

- [Kiến trúc hệ thống](https://github.com/HandLive/handlive/blob/main/docs/system-architecture.vi.md) — Thiết kế hệ thống và mô hình bảo mật
- [Thiết kế chi tiết](https://github.com/HandLive/handlive/tree/main/docs/detailed-design) — Giao thức, định dạng và đặc tả kỹ thuật
- [Hướng dẫn triển khai](https://github.com/HandLive/handlive/blob/main/docs/deployment-guide.vi.md) — Đóng gói và phát hành ứng dụng
- [CONTRIBUTING](https://github.com/HandLive/.github/blob/main/CONTRIBUTING.vi.md) — Quy trình gửi PR, commit nhỏ và ký xác nhận DCO (`git commit -s`)
- [SECURITY](https://github.com/HandLive/.github/blob/main/SECURITY.vi.md) — Chính sách báo cáo lỗ hổng bảo mật
- [CODE_OF_CONDUCT](https://github.com/HandLive/.github/blob/main/CODE_OF_CONDUCT.vi.md) — Quy tắc ứng xử cộng đồng

## Giấy phép

Apache License 2.0 — xem [LICENSE](LICENSE).
