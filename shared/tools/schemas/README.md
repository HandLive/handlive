# Kiểm JSON Schema

Chạy từ gốc kho `shared/` (handlive-shared). Ví dụ được đọc từ `docs/detailed-design/` của kho hub — mặc định là thư mục cha của `shared/` trong workspace, ghi đè bằng `HANDLIVE_DOCS_DIR`.

```sh
tools/.venv/bin/python -m pip install -r tools/schemas/requirements.txt   # nếu venv chưa có
tools/.venv/bin/python tools/schemas/check_schemas.py
```

Thoát 0 khi xanh. Các bước:

1. Mọi `shared/schemas/*.schema.json` hợp lệ theo metaschema draft 2020-12, `$id` khớp tên file, mọi `$ref` phân giải được; enum mã lỗi khớp bảng 0.8.1 và enum `type` khớp bảng 0.7.1 (đọc thẳng từ `00-common-specs.md`).
2. Ví dụ trong `docs/detailed-design/`:
   - `00-common-specs.md`: **mọi** khối ```json phải phân loại được và qua schema; `{op, data}` ngoài mục session/capability kiểm bằng `payload.schema.json`.
   - `01`–`08`: kiểm mọi envelope (`v` + `type`), mọi ack (`re` + `ok`) và mọi `{op, data}` nằm dưới tiêu đề `WS session/<op>` hoặc `WS capability/<op>`. Envelope `session` có payload giải base64 ra JSON thì kiểm cả plaintext bắt tay. Đối tượng khác (op của clipboard, sms…, REST, push) ngoài phạm vi, chỉ đếm.
   - Khối ```json không parse cả khối thì parse từng dòng; dòng không parse được là lỗi tài liệu. Inline code chỉ tính khi là JSON hợp lệ.
3. Mẫu dương tự viết (`sample_messages.py`) phải qua; mẫu âm (mỗi mẫu làm hỏng đúng một chỗ: thiếu trường, sai `v`, `type` lạ, mã lỗi lạ, uuid sai dạng, b64 sai…) phải bị từ chối.

## Quy tắc thay placeholder

Placeholder là chuỗi dạng `"<...>"` (ví dụ `"<b64>"`, `"<id của yêu cầu>"`), chuỗi chứa `…` (ví dụ `"…"`, `"0192f4a0-…"`) hoặc đúng `"..."`. Thay theo **tên khóa** chứa nó, và in ra mỗi lần thay:

| Khóa | Giá trị thay |
|------|--------------|
| `id`, `re` | `01920000-0000-7000-8000-000000000000` (UUIDv7) |
| `pair_id` | `00000000-0000-4000-8000-000000000000` (UUIDv4) |
| `device_id` | `00000000-0000-8000-8000-000000000000` (UUIDv8) |
| `payload` | Base64 có padding của 40 byte 0 (nonce 24 + tag 16) |
| `eph`, `nonce`, `mac` | b64u không padding của 32 byte 0 |

Placeholder ở khóa khác → lỗi, không bỏ qua.

## Known spec issues

`KNOWN_SPEC_ISSUES` trong `doc_examples.py` liệt kê ví dụ trong tài liệu sai so với chính đặc tả, kèm lý do (không sửa `docs/` từ công cụ này). Mục đó phải tiếp tục hỏng; khi tài liệu được sửa và ví dụ qua, script báo lỗi để xóa mục khỏi danh sách.
