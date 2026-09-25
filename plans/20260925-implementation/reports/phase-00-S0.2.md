# Báo cáo S0.2 [shared] — JSON Schema envelope, ack, lỗi, session, capability

Ngày: 2026-09-25 · Nhánh: `feat/phase-00-khung` · Chưa commit.

## Việc đã làm

- Viết 12 JSON Schema draft 2020-12 trong `shared/schemas/`, `$id` ổn định `https://handlive.app/schemas/v1/<file>`, `$ref` tương đối giữa các file, kiểu chung trong `common.schema.json#/$defs` (`uuid`, `uuid-v4|v7|v8`, `int32`, `int64`, `timestamp`, `b64`, `b64u`, `b64u-32`).
- Tách một file mỗi op theo tên gợi ý (không gộp): mỗi op là một hợp đồng riêng mà A0.1/M0.1 kiểm độc lập; phần dùng chung đặt ở `$defs` (`capability-hello#/$defs/capability-data`, `ack#/$defs/success|failure`, `session-rekey#/$defs/ack`).
- Thêm `session-bye.schema.json` dù thẻ việc không liệt kê: `bye` là op `session` trong 0.7.1, phiên Phase 0 (A0.2) cần đóng êm; đặc tả ở PAIR-03 API 2. Không thêm op/mã lỗi nào ngoài spec.
- Ràng buộc chặt: `v` const 1; `type` enum đúng 10 giá trị 0.7.1; `id`/`re` UUIDv7 chữ thường 36 ký tự (kiểm cả nibble version và variant); `device_id` UUIDv8, `pair_id` UUIDv4 (0.2); `ts` int64 ≥ 0; `payload` Base64 chuẩn có padding; `eph`/`nonce`/`mac` b64u đúng 32 byte; `additionalProperties: false` ở mọi đối tượng spec liệt kê đủ trường (kể cả từng tính năng trong `features`, `opus_fallback`, phần tử `sims`).
- `ack` dùng `if ok=true then success else failure` (thay vì `oneOf`) để thông báo lỗi chỉ đúng chỗ sai.
- Script `tools/schemas/check_schemas.py` (+ `doc_examples.py` trích/thay placeholder/phân loại, `sample_messages.py` mẫu dương và âm):
  1. metaschema, `$id` khớp tên file, mọi `$ref` phân giải được; enum mã lỗi và enum `type` so thẳng với bảng 0.8.1 và 0.7.1 trong tài liệu (phát hiện trôi);
  2. mọi khối ```json của `00-common-specs.md` phải phân loại được và qua; mở rộng thêm mọi envelope, ack và op session/capability (theo tiêu đề `WS session/<op>`, `WS capability/<op>`) trong 01–08; envelope `session` có payload giải b64 ra JSON thì kiểm cả plaintext bắt tay;
  3. 13 mẫu dương tự viết, 36 mẫu âm (mỗi mẫu hỏng đúng một chỗ).
- Placeholder (`"<b64>"`, `"<id của yêu cầu>"`, `"…"`, `"..."`, `"0192f4a0-…"`) thay theo tên khóa chứa nó, quy tắc ghi trong `tools/schemas/README.md`, mỗi lần thay in ra; khóa không có quy tắc → lỗi.

## File tạo

- `shared/schemas/common.schema.json`, `envelope.schema.json`, `payload.schema.json`, `ack.schema.json`, `error.schema.json`
- `shared/schemas/session-hello.schema.json`, `session-welcome.schema.json`, `session-error.schema.json`, `session-rekey.schema.json`, `session-bye.schema.json`
- `shared/schemas/capability-hello.schema.json`, `capability-update.schema.json`
- `shared/schemas/README.md`
- `tools/schemas/check_schemas.py`, `tools/schemas/doc_examples.py`, `tools/schemas/sample_messages.py`, `tools/schemas/requirements.txt` (`jsonschema==4.26.0`, `referencing==0.37.0` — đã có sẵn trong venv), `tools/schemas/README.md`

## Test

```
$ tools/.venv/bin/python tools/schemas/check_schemas.py; echo EXIT=$?
== 1. Metaschema, $id, $ref, enum khớp spec
== 2. Ví dụ trong docs/detailed-design
  PASS 00-common-specs.md:142 [envelope] (placeholder: payload: '<b64>' -> 'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA==')
  PASS 00-common-specs.md:160 [payload]
  PASS 00-common-specs.md:171 [ack] (placeholder: re: '<id của yêu cầu>' -> '01920000-0000-7000-8000-000000000000')
  PASS 00-common-specs.md:172 [ack] (placeholder: re: '<id của yêu cầu>' -> '01920000-0000-7000-8000-000000000000')
  PASS 00-common-specs.md:313 [capability-hello]
  PASS 01-setup-settings.md:418 [capability-update]
  PASS 01-setup-settings.md:424 [capability-update]
  PASS 02-pairing.md:643 [ack]
  PASS 02-pairing.md:657 [session-bye]
  PASS 03-connectivity.md:155 [envelope]
  PASS 03-connectivity.md:155 [payload đã giải b64 -> session-hello] (placeholder: eph: '...' -> 'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA'; nonce: '...' -> 'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA'; mac: '...' -> 'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA')
  PASS 03-connectivity.md:158 [session-hello] (placeholder: eph: '…' -> 'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA'; nonce: '…' -> 'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA'; mac: '…' -> 'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA')
  PASS 03-connectivity.md:179 [session-welcome] (placeholder: eph: '…' -> 'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA'; nonce: '…' -> 'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA'; mac: '…' -> 'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA')
  PASS 03-connectivity.md:190 [session-error]
  PASS 03-connectivity.md:343 [ack] (placeholder: re: '0192f4a0-…' -> '01920000-0000-7000-8000-000000000000')
  PASS 03-connectivity.md:359 [session-rekey] (placeholder: eph: '…' -> 'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA'; nonce: '…' -> 'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA')
  PASS 03-connectivity.md:359 [session-rekey#ack] (placeholder: re: '…' -> '01920000-0000-7000-8000-000000000000'; eph: '…' -> 'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA'; nonce: '…' -> 'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA')
  PASS 04-clipboard.md:295 [ack]
  PASS 04-clipboard.md:296 [ack]
  PASS 04-clipboard.md:297 [ack]
  PASS 04-clipboard.md:537 [ack]
  PASS 04-clipboard.md:787 [ack]
  PASS 04-clipboard.md:1095 [ack]
  PASS 05-sms.md:161 [ack]
  PASS 05-sms.md:171 [ack]
  PASS 05-sms.md:658 [ack]
  PASS 05-sms.md:659 [ack]
  PASS 05-sms.md:868 [ack]
  PASS 05-sms.md:869 [ack]
  PASS 06-call-control.md:457 [ack]
  PASS 06-call-control.md:462 [ack]
  PASS 06-call-control.md:686 [ack]
  PASS 06-call-control.md:691 [ack]
  PASS 06-call-control.md:894 [ack]
  PASS 06-call-control.md:904 [ack]
  PASS 07-call-audio.md:150 [capability-update]
  KNOWN 07-call-audio.md:154: Khối JSON capability/update (Android) thiếu một dấu '}' đóng cuối dòng.
  KNOWN 07-call-audio.md:654 [ack]: ack của call_audio/open có re = 0192f5a1-9c8b-7a6d-5e4f-… : nhóm thứ tư bắt đầu bằng '5', sai variant RFC 9562 (phải 8/9/a/b) nên không phải UUIDv7 hợp lệ.
  PASS 08-camera-mic.md:252 [capability-update]
  PASS 08-camera-mic.md:492 [ack]
  PASS 08-camera-mic.md:493 [ack]
  PASS 08-camera-mic.md:745 [ack]
  PASS 08-camera-mic.md:912 [ack]
== 3. Mẫu tự viết
  REJECT envelope thiếu payload: 'payload' is a required property
  REJECT envelope v = 2: 1 was expected
  REJECT envelope v là chuỗi "1": 1 was expected
  REJECT envelope type lạ: 'notification' is not one of ['clipboard', 'sms', 'call_event', 'call_audio', 'pair', 'ack', 'ping', 'capabili
  REJECT envelope id chữ hoa: '0192F3C1-7C1E-7A55-9D0B-3F4C2A1B9E10' does not match '^[0-9a-f]{8}-[0-9a-f]{4}-7[0-9a-f]{3}-[89ab][0-9a-f]{3}
  REJECT envelope id không phải v7 (v4): '3f2b1c4d-5e6f-4a7b-8c9d-0e1f2a3b4c5d' does not match '^[0-9a-f]{8}-[0-9a-f]{4}-7[0-9a-f]{3}-[89ab][0-9a-f]{3}
  REJECT envelope id không gạch: '0192f3c17c1e7a559d0b3f4c2a1b9e10' does not match '^[0-9a-f]{8}-[0-9a-f]{4}-7[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-
  REJECT envelope ts âm: -1 is less than the minimum of 0
  REJECT envelope ts số thực: 1727151000000.5 is not of type 'integer'
  REJECT envelope payload thiếu padding: 'AAECAwQFBgcICQoLDA0ODxAREhMUFRYXGBkaGxwdHh8gISIjJCUmJygpKissLS4vMDEyMzQ1Njc4OQ' does not match '^(?:[A-Za-z0-
  REJECT envelope payload là b64url: 'ab-_ab-_ab-_ab-_' does not match '^(?:[A-Za-z0-9+/]{4})*(?:[A-Za-z0-9+/]{2}==|[A-Za-z0-9+/]{3}=)?$'
  REJECT envelope thêm trường lạ: Additional properties are not allowed ('to' was unexpected)
  REJECT payload thiếu data: 'data' is a required property
  REJECT ack ok=true kèm error: Additional properties are not allowed ('error' was unexpected)
  REJECT ack thiếu re: 're' is a required property
  REJECT ack lỗi mã lạ: 'SMS_UNKNOWN_ERROR' is not one of ['BAD_REQUEST', 'UNSUPPORTED_TYPE', 'UNSUPPORTED_VERSION', 'FEATURE_DISABLED
  REJECT ack lỗi dùng mã relay HTTP: 'TOKEN_EXPIRED' is not one of ['BAD_REQUEST', 'UNSUPPORTED_TYPE', 'UNSUPPORTED_VERSION', 'FEATURE_DISABLED', '
  REJECT ack lỗi thiếu message: 'message' is a required property
  REJECT session/hello thiếu mac: 'mac' is a required property
  REJECT session/hello eph 31 byte: 'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA' does not match '^[A-Za-z0-9_-]{42}[AEIMQUYcgkosw048]$'
  REJECT session/hello eph có padding: 'AAECAwQFBgcICQoLDA0ODxAREhMUFRYXGBkaGxwdHh8=' does not match '^[A-Za-z0-9_-]{42}[AEIMQUYcgkosw048]$'
  REJECT session/hello device_id không phải v8: '0192f3c1-7c1e-7a55-9d0b-3f4c2a1b9e10' does not match '^[0-9a-f]{8}-[0-9a-f]{4}-8[0-9a-f]{3}-[89ab][0-9a-f]{3}
  REJECT session/hello op sai: 'hello' was expected
  REJECT session/welcome thêm pair_id: Additional properties are not allowed ('pair_id' was unexpected)
  REJECT session/error mã ngoài tập bắt tay: 'BAD_REQUEST' is not one of ['AUTH_FAILED', 'PAIR_UNKNOWN', 'PAIR_REVOKED', 'UNSUPPORTED_VERSION', 'RATE_LIMIT
  REJECT session/error mã lạ: 'NOPE' is not one of ['BAD_REQUEST', 'UNSUPPORTED_TYPE', 'UNSUPPORTED_VERSION', 'FEATURE_DISABLED', 'PERMISSIO
  REJECT session/error min_protocol với AUTH_FAILED: {'code': 'AUTH_FAILED', 'message': 'Sai MAC', 'min_protocol': 2} should not be valid under {'required': ['min_
  REJECT session/rekey thiếu epoch: 'epoch' is a required property
  REJECT ack rekey thiếu eph: 'eph' is a required property
  REJECT session/bye reason lạ: 'sleep' is not one of ['revoked', 'shutdown', 'replaced', 'update']
  REJECT capability tính năng lạ: Additional properties are not allowed ('notifications' was unexpected)
  REJECT capability platform windows: 'windows' is not one of ['android', 'macos', 'ios', 'ipados']
  REJECT capability thiếu features: 'features' is a required property
  REJECT capability feature thiếu enabled: 'enabled' is a required property
  REJECT capability opus_fallback reason lạ: 'unknown' is not one of ['ok', 'disabled', 'android_10', 'shizuku_not_running', 'capture_silent', 'uplink_unsu
  REJECT capability/update mang op hello: 'update' was expected
== Tổng kết
  schema hợp lệ metaschema: 12
  $ref phân giải được: 47
  enum khớp bảng spec: 2
  ngoài phạm vi S0.2 (bỏ qua): 83
  ví dụ 00-common-specs: 5
  ví dụ 01–08: 35
  payload bắt tay giải từ envelope: 1
  known spec issue (đúng như ghi nhận): 2
  mẫu dương tự viết: 13
  mẫu âm bị từ chối: 36
  XANH: mọi kiểm tra đạt
EXIT=0
```

Mọi ví dụ của `00-common-specs.md` (5 đối tượng trong 4 khối ```json) qua schema. 83 đối tượng ngoài phạm vi (op clipboard/sms/call…, REST, push, relay control) chỉ được đếm.

## Điểm lệch với tài liệu

Không sửa `docs/`. Đề xuất sửa cho chủ dự án:

| # | Chỗ | Lệch | Schema xử lý | Đề xuất sửa |
|---|-----|------|--------------|-------------|
| 1 | 00 §0.6.3 bước 1 và §0.7.1 | `session/hello` data ghi `{pair_id, device_id, eph, nonce, mac}`, thiếu `protocol`; CONN-01 API 4 có `protocol` (bắt buộc, kiểm đầu tiên → 4426) | Theo CONN-01: `protocol` bắt buộc | Sửa 0.6.3 bước 1 thành `{protocol, pair_id, device_id, eph, nonce, mac}` |
| 2 | 00 §0.6.3 bước 6 | `session/rekey` ghi `{eph, nonce}`, ack `{eph, nonce}`; CONN-02 API 3 có thêm `epoch` bắt buộc | Theo CONN-02: `{epoch, eph, nonce}` cả yêu cầu và ack | Sửa 0.6.3 bước 6 thành `{epoch, eph, nonce}` |
| 3 | `07-call-audio.md:154` | Khối JSON `capability/update` (Android) thiếu một `}` cuối — không parse được | Known spec issue trong script | Thêm `}` cuối dòng |
| 4 | `07-call-audio.md:654` | ack của `call_audio/open` có `re` = `0192f5a1-9c8b-7a6d-5e4f-3d2c1b0a9f8e`: variant `5` không hợp lệ RFC 9562, không phải UUIDv7 | Known spec issue trong script | Đổi thành `0192f5a1-9c8b-7a6d-8e4f-3d2c1b0a9f8e` |
| 5 | 00 §0.7.2 ví dụ | Ví dụ Android thiếu `features.sms.default_sub_id` trong khi bảng liệt kê và ví dụ SET-02 (`01-setup-settings.md:418`) có | Trường tùy chọn → vẫn qua | Thêm `"default_sub_id": 1` vào ví dụ 0.7.2 cho thống nhất |
| 6 | 00 §0.7.2 | `features.call_audio.bt_address` không nêu định dạng; chỉ có ví dụ `"A1:B2:C3:D4:E5:F6"` (AUDIO-01). `IOBluetoothDevice.addressString` thường trả dạng chữ thường, gạch ngang (cần kiểm trên máy thật) | Chặt theo ví dụ: `^[0-9A-F]{2}(:[0-9A-F]{2}){5}$` hoặc `null`; M-APP phải chuẩn hóa | Ghi định dạng vào bảng 0.7.2: "chữ hoa, phân tách bằng `:`" |
| 7 | 07:150, 08:252 | Ví dụ `capability/update` chỉ trích một tính năng, trái "luôn mang ảnh chụp đầy đủ" — đã ghi rõ "trích" | Schema không ép đủ tính năng (tính năng vắng = tắt), nên vẫn qua | Không cần sửa; ghi nhận |

Quyết định cần biết khi dùng schema:
- `session/error.min_protocol`: CONN-01 API 6 ghi "chỉ với `UNSUPPORTED_VERSION`" → schema **cấm** ở mã khác, **không bắt buộc** khi `UNSUPPORTED_VERSION`.
- Trong `capability`, mỗi tính năng chỉ bắt buộc `enabled`; trường "Chỉ Android/Mac/iOS" để tùy chọn, không ép theo `platform` (KISS).
- `error.code` chỉ gồm mã ứng dụng 0.8.1; mã relay HTTP (0.8.2) không thuộc ack nên không có schema ở thẻ này.
- Regex dùng cú pháp chung ECMA/Python (`^…$`); với Python `re`, `$` chấp nhận một `\n` cuối chuỗi — validator Kotlin/Swift nên dùng khớp toàn chuỗi.

## Câu hỏi mở

- `min_protocol` có nên bắt buộc khi `code = UNSUPPORTED_VERSION` (client cần để hiển thị "cập nhật lên…")?
- Chủ dự án duyệt đề xuất 1–6 để sửa `docs/detailed-design/`; khi sửa 3 và 4, xóa hai mục tương ứng trong `KNOWN_SPEC_ISSUES` (`tools/schemas/doc_examples.py`) — script sẽ báo nếu quên.

```text
Status: DONE_WITH_CONCERNS
Summary: 12 JSON Schema (envelope, payload, ack, error, session hello/welcome/error/rekey/bye, capability hello/update) và script kiểm xanh: mọi ví dụ 00-common-specs qua, 35 ví dụ 01–08 qua, 36 mẫu âm bị từ chối.
Concerns/Blockers: 0.6.3 thiếu protocol (hello) và epoch (rekey) so với CONN-01/CONN-02 — schema theo CONN; hai ví dụ lỗi trong 07-call-audio.md ghi là known spec issue; cần chủ dự án duyệt sửa docs.
```
