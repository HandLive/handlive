# JSON Schema giao thức HandLive

JSON Schema draft 2020-12 cho khung tin thiết bị ↔ thiết bị, sinh từ `docs/detailed-design/00-common-specs.md` (0.3, 0.5.1, 0.6.3, 0.7.1, 0.7.2, 0.8.1) và đặc tả chi tiết CONN-01/CONN-02/PAIR-03. Android (`core/protocol`), Apple (`HLProtocol`) và relay dùng làm nguồn đối chiếu trong test.

`$id` = `https://handlive.app/schemas/v1/<file>`: chỉ là định danh, không tải qua mạng. `$ref` giữa các file dùng đường dẫn tương đối (`common.schema.json#/$defs/uuid-v7`), nên nạp cả thư mục vào registry của thư viện validator.

| File | Đối tượng | Nguồn |
|------|-----------|-------|
| `common.schema.json` | Chỉ `$defs`: `uuid`, `uuid-v4` (`pair_id`), `uuid-v7` (`id`, `re`), `uuid-v8` (`device_id`), `int32`, `int64`, `timestamp`, `b64`, `b64u`, `b64u-32` | 0.2, 0.3 |
| `envelope.schema.json` | Envelope `{v, type, id, ts, payload}`; `$defs/type` = enum `type` | 0.5.1, 0.7.1 |
| `payload.schema.json` | Plaintext chung `{op, data}` | 0.5.1 |
| `ack.schema.json` | Plaintext ack; `$defs/success`, `$defs/failure` | 0.5.1 |
| `error.schema.json` | `ack.error` `{code, message, details?}`; `$defs/code` = enum mã lỗi | 0.8.1 |
| `session-hello.schema.json` | `session/hello` | 0.6.3; CONN-01 API 4 |
| `session-welcome.schema.json` | `session/welcome` | 0.6.3; CONN-01 API 5 |
| `session-error.schema.json` | `session/error` | 0.6.3; CONN-01 API 6 |
| `session-rekey.schema.json` | `session/rekey`; `$defs/ack` = ack thành công mang `{epoch, eph, nonce}` | 0.6.3; CONN-02 API 3 |
| `session-bye.schema.json` | `session/bye` | 0.7.1; PAIR-03 API 2 |
| `capability-hello.schema.json` | `capability/hello`; `$defs/capability-data` dùng chung | 0.7.2 |
| `capability-update.schema.json` | `capability/update` (cùng `data` với hello) | 0.7.2 |

## Cách dùng

1. Kiểm envelope bằng `envelope.schema.json`.
2. Giải mã `payload` (tin bắt tay `session` hello/welcome/error: chỉ giải base64).
3. `type = ack` → `ack.schema.json` (hoặc `<op>#/$defs/ack` nếu op có ack riêng, ví dụ `session-rekey`); `type` khác → `<type>-<op>.schema.json` nếu có, không thì `payload.schema.json`.

## Quy ước chặt

- `v` = 1; `type` đúng 10 giá trị của 0.7.1; `id`, `re` là UUIDv7 chữ thường 36 ký tự (nibble version `7`, variant `8|9|a|b`); `device_id` UUIDv8, `pair_id` UUIDv4.
- `ts` int64 ≥ 0; `payload` Base64 chuẩn có padding; `eph`, `nonce`, `mac` là b64u đúng 32 byte (43 ký tự, dạng chuẩn tắc).
- `additionalProperties: false` ở mọi đối tượng mà spec liệt kê đủ trường, gồm cả từng tính năng trong `features`.
- Capability: chỉ `enabled` bắt buộc trong mỗi tính năng; trường ghi "Chỉ Android/Mac/iOS" là tùy chọn. `bt_address` dạng `A1:B2:C3:D4:E5:F6` (hoa, dấu hai chấm, theo ví dụ AUDIO-01) hoặc `null`.
- `session/error`: `code` ∈ {`AUTH_FAILED`, `PAIR_UNKNOWN`, `PAIR_REVOKED`, `UNSUPPORTED_VERSION`, `RATE_LIMITED`}; `min_protocol` chỉ được có khi `code = UNSUPPORTED_VERSION`.

Thêm op hoặc mã lỗi: sửa `00-common-specs.md` trước, rồi schema, rồi chạy `tools/.venv/bin/python tools/schemas/check_schemas.py` (xem `tools/schemas/README.md`).
