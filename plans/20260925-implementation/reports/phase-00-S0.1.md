# Báo cáo S0.1 [shared] — Test vector liên nền tảng

Ngày: 2026-09-25 · Nhánh: `feat/phase-00-khung` · Chưa commit (điều phối viên commit).

## Việc đã làm

- Tải bản gốc `.txt` của draft-irtf-cfrg-xchacha-03, RFC 8439, RFC 7748, RFC 5869, RFC 8032
  (rfc-editor.org, ietf.org), trích hex **tự động** bằng script rồi đối chiếu với hằng trong
  `tools/vectors/rfc_source_values.py` — mọi giá trị RFC chép nguyên văn, không gõ tay.
- 14 file vector, mỗi file ≥ 2 vector; 26 vector âm cho mọi thao tác AEAD/MAC (tag sai, AAD sai,
  ciphertext sai, payload ngắn, mac sai, thông điệp bị sửa, đảo nonce).
- Vector tự sinh dùng khóa công khai: `ik_sig` = khóa RFC 8032 §7.1 TEST 1–3, `ik_dh` = Alice/Bob
  của RFC 7748 §6.1, còn lại `SHA-256("HL-TEST|<nhãn>|<i>")`.
- Vector nối chuỗi: `device-id` → `pair-prk` → `session-handshake` → `session-rekey` (epoch 1 → 2)
  và `stream-keys` → `envelope` /`ack`/`clipboard-chunk` (khóa `k_c2s` /`k_s2c`) và `hl-frame` (khóa
  stream). Mỗi vector vẫn ghi đủ khóa hex, đọc độc lập được.
- Phía kiểm độc lập với phía sinh: sinh dùng `cryptography` (HKDF, HMAC, X25519, Ed25519) +
  libsodium (XChaCha); kiểm dùng `hashlib` /`hmac` (HKDF/HMAC tự cài), libsodium (X25519, Ed25519),
  `cryptography` + libsodium (ChaCha20-Poly1305). XChaCha20-Poly1305 kiểm theo **hai đường**:
  libsodium `crypto_aead_xchacha20poly1305_ietf_*` và HChaCha20 thuần Python + ChaCha20-Poly1305
  (nonce 12 = `00000000` ‖ nonce[16:24]), cả mã hóa lẫn giải mã; hai đường phải ra cùng byte và cùng
  từ chối vector âm.
- Đã thử đột biến (sửa `k_auth`, biến vector âm thành đúng tag, sửa `pts_us`): `verify_vectors.py`
  báo 3 lỗi, exit 1; `generate_vectors.py --check` báo 3 file lệch, exit 1. Sau đó sinh lại, sạch.

## File tạo mới

- `shared/test-vectors/README.md` — quy ước, diễn giải, mô tả từng file/từng trường.
- `shared/test-vectors/`: `xchacha20-poly1305.json`, `hchacha20.json`, `chacha20-poly1305.json`,
  `x25519.json`, `hkdf-sha256.json`, `device-id.json`, `pair-prk.json`, `session-handshake.json`,
  `session-rekey.json`, `stream-keys.json`, `envelope.json`, `ack.json`, `clipboard-chunk.json`,
  `hl-frame.json`.
- `tools/vectors/`: `README.md`, `requirements.txt` (`cryptography==50.0.1`, `PyNaCl==1.6.2` — đúng
  bản đã có trong `tools/.venv`, không cài thêm), `generate_vectors.py`, `verify_vectors.py`,
  `rfc_source_values.py`, `handlive_protocol_derivations.py`, `hchacha20_reference.py`,
  `build_primitive_vectors.py`, `build_identity_session_vectors.py`, `build_message_vectors.py`,
  `verify_common.py`, `verify_primitive_checks.py`, `verify_session_checks.py`,
  `verify_message_checks.py` (mỗi file < 200 dòng).

## Lệnh test và kết quả

```
$ tools/.venv/bin/python tools/vectors/verify_vectors.py; echo "exit=$?"
OK  ack.json                    3 vector,  2 vector âm,  33 phép kiểm
OK  chacha20-poly1305.json      2 vector,  4 vector âm,  10 phép kiểm
OK  clipboard-chunk.json        2 vector,  2 vector âm,  24 phép kiểm
OK  device-id.json              3 vector,  0 vector âm,  15 phép kiểm
OK  envelope.json               5 vector,  5 vector âm,  38 phép kiểm
OK  hchacha20.json              3 vector,  0 vector âm,   6 phép kiểm
OK  hkdf-sha256.json            3 vector,  0 vector âm,   6 phép kiểm
OK  hl-frame.json               4 vector,  2 vector âm,  32 phép kiểm
OK  pair-prk.json               2 vector,  0 vector âm,  23 phép kiểm
OK  session-handshake.json      2 vector,  4 vector âm,  44 phép kiểm
OK  session-rekey.json          2 vector,  0 vector âm,  18 phép kiểm
OK  stream-keys.json            2 vector,  3 vector âm,  27 phép kiểm
OK  x25519.json                 6 vector,  0 vector âm,   6 phép kiểm
OK  xchacha20-poly1305.json     3 vector,  4 vector âm,  22 phép kiểm
Tổng: 360 phép kiểm, 0 lỗi
exit=0

$ tools/.venv/bin/python tools/vectors/generate_vectors.py --check; echo "exit=$?"
check: 14 file, 0 lệch
exit=0
```

## Nguồn vector và mức kiểm độc lập

| File | Nguồn | Kiểm độc lập |
|------|-------|--------------|
| xchacha20-poly1305 | #1 draft §A.3.1; #2, #3 tự sinh | libsodium + đường HChaCha20/ChaCha20-Poly1305 (`cryptography`) |
| hchacha20 | #1 draft §2.2.1; #2 input §A.3.1; #3 tự sinh | bản tham chiếu Python; và với **mọi** vector: libsodium XChaCha(key, nonce16 ‖ 0⁸) = ChaCha20-Poly1305(subkey, 0¹²) — không phụ thuộc bản Python |
| chacha20-poly1305 | RFC 8439 §2.8.2, §A.5 | `cryptography` + libsodium |
| x25519 | RFC 7748 §5.2, §6.1 | libsodium |
| hkdf-sha256 | RFC 5869 A.1–A.3 | HKDF tự cài bằng `hmac` |
| còn lại | tự sinh | tính lại toàn bộ từ input bằng hashlib/hmac + libsodium |

Draft xchacha-03 chỉ có **một** vector AEAD và **một** vector HChaCha20 nên vector thứ hai trở đi là
tự sinh — không có vector nào không kiểm được bằng thư viện độc lập. Lưu ý: bản HChaCha20 Python
dùng chung cho sinh và kiểm, nên tính độc lập của HChaCha20 dựa vào phép so với libsodium ở trên.

## Điểm lệch/diễn giải với tài liệu (không sửa `docs/`)

1. **`T1`/`T2` mơ hồ về dạng trường** (0.6.3 bước 1–2). Chọn ghép byte thô: `pair_id` /`device_id`
   16 byte, `eph` 32 byte, `nonce` 32 byte (T1 = 106 byte, T2 = 198 byte), giống `T_offer` ở
   02-pairing. *Đề xuất sửa 0.6.3:* "`T1` = `"HL1|hello|"` ‖ `pair_id` (16) ‖ `device_id` C(16) ‖
   `eph` C(32) ‖ `nonce` C(32), các trường ở dạng byte thô (không phải chuỗi uuid hay b64u); `T2`
   tương tự".
2. **MAC `HLSTREAM1`** (0.6.3 bước 7, CAM-02, AUDIO-04): cùng mơ hồ; chọn `session_id` (16) ‖
   `nonce_c` (32) [‖ `nonce_s` (32)] byte thô. Riêng `info` của `K_stream` là chuỗi văn bản với
   `session_id` 36 ký tự và `<kênh>` = `camera` | `call-audio`. *Đề xuất:* ghi độ dài byte như
   T_offer.
3. **HKDF thiếu salt/L**: `K_auth`, `K_push`, `K_stream`, (`K_auth` thiếu cả L). Chọn salt rỗng,
   `K_auth` L = 32. *Đề xuất:* thêm vào 0.6.1 câu "HKDF không ghi salt dùng salt rỗng; không ghi L
   thì L = 32".
4. **Rekey** (0.6.3 bước 6, CONN-02 API 3) thiếu: thứ tự hai nonce trong salt, `k_c2s` /`k_s2c` theo
   vai hay theo bên khởi tạo, `secret` mới có thay `secret` cũ cho lần sau không. Chọn: salt =
   SHA-256(nonce bên khởi tạo ‖ nonce bên nhận); tách theo vai C/S; 64 byte mới thay `secret`. *Đề
   xuất* ghi rõ ba điểm này. Thêm: `epoch` có trong tin nhưng không vào KDF — cân nhắc đưa `epoch`
   vào `info` (ví dụ `"handlive/v1/rekey|" ‖ epoch`) để hai bên lệch epoch thất bại ngay.
5. **`K_stream` sau rekey**: spec không nói dùng `secret` epoch nào; kênh stream mở lại (CAM-02 E9)
   sau một lần rekey sẽ lệch khóa nếu hai bên hiểu khác. Vector chỉ phủ epoch 0. *Đề xuất:*
   "`K_stream` dẫn từ `secret` đang hiệu lực lúc gửi `stream_hello` " hoặc cố định "`secret` của bắt
   tay" — cần chủ dự án chọn.
6. **`protocol` trong `session/hello` không nằm trong `T1`** (CONN-01 API 4): kẻ đứng giữa có thể
   sửa `protocol` mà MAC vẫn đúng (hạ cấp phiên bản khi có protocol 2). *Đề xuất:* thêm `protocol`
   (uint16 BE) vào `T1` trước khi có phiên bản 2.
7. **AAD envelope**: spec viết `"<v>|<type>|<id>|<ts>"`; vector dùng `v`, `ts` dạng số thập phân
   không số 0 đầu, `id` chữ thường 36 ký tự. Bên nhận phải dựng AAD từ giá trị đã parse và in lại
   đúng dạng này. *Đề xuất* ghi rõ trong 0.5.1.
8. `clipboard/chunk`: đã xác nhận ví dụ CLIP-03 (`hdr_len` = 86) khớp JSON gọn. Khối trong vector
   ngắn hơn `CHUNK_SIZE` (chỉ để giữ file nhỏ).
9. Ví dụ b64 của `session/hello` trong CONN-01 là b64 chuẩn có padding hợp lệ — khớp 0.3.

Status: DONE_WITH_CONCERNS
Summary: Đã tạo 14 file vector (≥ 2 vector mỗi file, 26 vector âm) kèm script sinh lại/kiểm;
`verify_vectors.py` (360 phép kiểm, XChaCha hai đường) và `generate_vectors.py --check` đều exit 0.
Concerns/Blockers: Định dạng T1/T2/HLSTREAM1, salt HKDF, chi tiết rekey và `K_stream` sau rekey là
diễn giải của agent (mục 1–5) — cần chủ dự án duyệt và cập nhật 00-common-specs trước khi A0.2/M0.1
cài bắt tay; `protocol` chưa được MAC bảo vệ (mục 6).
