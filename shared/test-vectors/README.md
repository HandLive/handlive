# Test vector liên nền tảng (Kotlin ↔ Swift ↔ Rust)

Nguồn đặc tả: `docs/detailed-design/00-common-specs.md` (0.2, 0.3, 0.5, 0.6). File do `tools/vectors/generate_vectors.py` sinh — **không sửa tay**; kiểm bằng `tools/vectors/verify_vectors.py`. Mọi khóa là giá trị test công khai (khóa RFC hoặc `SHA-256("HL-TEST|<nhãn>|<i>")`), không phải khóa thật.

## Quy ước chung

- Mỗi file: `{"description", "source", "vectors": [...], "invalid_vectors": [...]?}`. Mỗi vector có `name` (duy nhất trong file). Mọi file có ≥ 2 vector.
- `vectors`: phải tính ra đúng từng trường. `invalid_vectors` (vector âm): thao tác AEAD/MAC **phải thất bại**; trường `reason` ∈ `tag_mismatch`, `aad_mismatch`, `ciphertext_mismatch`, `payload_too_short`, `mac_mismatch`, `message_tampered`.
- Byte: hex chữ thường, không tiền tố. Số nguyên: số JSON. Chuỗi hiển thị/UTF-8: chuỗi JSON.
- Chuỗi wire giữ đúng dạng spec (0.3): `payload` của envelope là **b64** (RFC 4648 §4, có padding); `eph`, `nonce`, `mac` bên trong JSON là **b64u** (RFC 4648 §5, không padding); uuid 36 ký tự thường.
- Chuỗi JSON (plaintext, envelope) là dạng gọn (không khoảng trắng), giữ thứ tự khóa, UTF-8 không escape. Mã hóa phải dùng **đúng byte** của chuỗi trong vector; khi nhận, parse JSON chứ không so chuỗi.
- `direction`: `c2s` = Mac/iOS → Android (khóa `k_c2s`), `s2c` = Android → Mac/iOS (`k_s2c`). `key_source` chỉ ra khóa lấy từ vector nào (để test nối chuỗi); trường `key` luôn có đủ giá trị.
- HKDF = HKDF-SHA256. Khi spec không ghi salt → **salt rỗng** (≡ 32 byte 0).

## Diễn giải đã chốt cho chỗ spec chưa ghi rõ

| Chỗ | Chọn | Lý do |
|-----|------|-------|
| `T1`, `T2` (0.6.3) | Ghép **byte thô**: `"HL1|hello|"` (ASCII) ‖ `pair_id` 16 byte ‖ `device_id`C 16 byte ‖ `eph`C 32 byte ‖ `nonce`C 32 byte (= 106 byte). `T2` = `"HL1|welcome|"` ‖ `T1` ‖ `device_id`S 16 ‖ `eph`S 32 ‖ `nonce`S 32 (= 198 byte). Không dùng dạng chuỗi 36 ký tự hay b64u | Giống `T_offer` ở 02-pairing (ghép trường byte độ dài cố định) |
| MAC `HLSTREAM1` (0.6.3 bước 7) | `"HLSTREAM1|"` ‖ `session_id` 16 byte ‖ `nonce_c` 32 byte; welcome: `"HLSTREAM1|welcome|"` ‖ `session_id` 16 ‖ `nonce_c` 32 ‖ `nonce_s` 32 | Như trên |
| `info` của `K_stream` | Chuỗi UTF-8 `"handlive/v1/stream/<kênh>/<session_id 36 ký tự>"`, `<kênh>` = đoạn đường dẫn: `camera`, `call-audio` | `info` là văn bản; 07-call-audio ghi đúng dạng này |
| `K_auth` | HKDF(ikm = `PRK`, salt rỗng, info `"handlive/v1/session-auth"`, L = 32) | Spec không ghi salt, L |
| Salt của `PRK` | So `device_id` theo 16 byte, thứ tự byte không dấu (= so chuỗi uuid chữ thường) | |
| Rekey | `X25519(eph bên khởi tạo, eph bên nhận)`; ikm = shared ‖ `secret` cũ (64 byte); salt = SHA-256(`nonce` bên khởi tạo ‖ `nonce` bên nhận); `k_c2s` = 32 byte đầu, `k_s2c` = 32 byte sau theo vai C/S (không theo bên khởi tạo); kết quả 64 byte thay `secret` cho lần rekey sau. `epoch` không vào KDF | Spec ghi "hai nonce" không nói thứ tự |
| `K_stream` | Dẫn từ `secret` của bắt tay (epoch 0) trong vector | Spec chưa nói sau rekey dùng `secret` nào |

## Từng file

### `xchacha20-poly1305.json`
AEAD_XChaCha20_Poly1305. `key` 32, `nonce` 24, `aad`, `plaintext`, `ciphertext` (cùng độ dài plaintext), `tag` 16. Trường phụ cho Apple: `hchacha20_subkey` = HChaCha20(key, nonce[0:16]); `chacha20_nonce` = `00000000` ‖ nonce[16:24]; ChaCha20-Poly1305(subkey, chacha20_nonce) phải cho đúng ciphertext ‖ tag. Vector 1 = draft-irtf-cfrg-xchacha-03 §A.3.1; còn lại tự sinh bằng libsodium. `invalid_vectors`: cùng trường, không có `plaintext`.

### `hchacha20.json`
`key` 32, `nonce` 16, `subkey` 32. Vector 1 = draft §2.2.1; vector 2 = input §A.3.1 (subkey tự tính, kiểm bằng libsodium); vector 3 tự sinh.

### `chacha20-poly1305.json`
AEAD_ChaCha20_Poly1305 nonce 12 byte (CryptoKit `ChaChaPoly`). RFC 8439 §2.8.2 (`nonce` = fixed-common `07000000` ‖ IV) và §A.5. Trường như XChaCha.

### `x25519.json`
`scalar` 32 (chưa clamp, hàm tự clamp), `u` 32, `output` 32. RFC 7748 §5.2 (2 vector) và §6.1 (khóa công khai Alice/Bob với `u` = 9, bí mật chung K từ hai phía).

### `hkdf-sha256.json`
`ikm`, `salt` (rỗng = `""`), `info`, `length` (byte), `prk` (extract), `okm`. RFC 5869 A.1–A.3.

### `device-id.json`
`ik_sig_seed` (khóa bí mật Ed25519 32 byte, RFC 8032 §7.1 TEST 1–3), `ik_sig_pub`, `sha256` = SHA-256(pub), `device_id_bytes` = 16 byte đầu sau khi đặt byte 6 = `(b & 0x0f) | 0x80`, byte 8 = `(b & 0x3f) | 0x80`, `device_id` = dạng uuid.

### `pair-prk.json`
Hai cặp, một cặp `device_id` client nhỏ hơn, một cặp lớn hơn (`client_id_is_smaller`). `ik_dh` = khóa Alice/Bob RFC 7748 §6.1. `dh_shared` = X25519(ik_dh mình, ik_dh đối phương) (hai phía như nhau); `ikm` = `dh_shared` ‖ `pairing_secret` (64 byte); `salt_input` = id nhỏ ‖ id lớn (32 byte); `salt` = SHA-256(salt_input); `info` (chuỗi UTF-8), `length` = 32; `prk`.

### `session-handshake.json`
Nối từ `pair-prk.json` theo `pair_id`. `k_auth`; `client_eph_priv/pub`, `client_nonce` (32); `t1`, `hello_mac` = HMAC-SHA256(k_auth, t1); `server_eph_*`, `server_nonce`, `t2`, `welcome_mac`; `eph_shared` = X25519(eph C, eph S); `secret_salt` = SHA-256(t2); `secret` (64) = HKDF(eph_shared ‖ prk, secret_salt, `"handlive/v1/session"`, 64); `k_c2s` = secret[0:32], `k_s2c` = secret[32:64]. `hello_plaintext`/`welcome_plaintext`: JSON `{op, data}` với `eph`/`nonce`/`mac` dạng b64u; `hello_envelope`/`welcome_envelope`: envelope `type = session`, `payload` = b64 của plaintext (chưa mã hóa). `invalid_vectors`: `{key, message, mac}` — HMAC(key, message) so hằng thời gian với `mac` phải **khác**.

### `session-rekey.json`
Epoch 1 (client khởi tạo, `secret_old` = `secret` bắt tay cặp 1) và epoch 2 (server khởi tạo, `secret_old` = `secret_new` của epoch 1). `initiator_*`/`responder_*` (eph priv/pub, nonce), `eph_shared`, `ikm` (96 byte), `salt_input` (64 byte), `salt`, `info`, `length` = 64, `secret_new`, `k_c2s`, `k_s2c`. `request_plaintext` = plaintext của `session/rekey`; `ack_data` = `data` của `ack` (bên nhận).

### `stream-keys.json`
Kênh `camera` (từ bắt tay cặp 1) và `call-audio` (cặp 2). `secret`, `info`, `length` = 96, `k_stream` = `k_auth`(32) ‖ `k_c2s`(32) ‖ `k_s2c`(32); `nonce_c`, `nonce_s` (32); `hello_message`/`hello_mac`, `welcome_message`/`welcome_mac`; envelope `stream_hello`/`stream_welcome` (`envelope_type` = `camera` hoặc `call_audio`, payload chưa mã hóa). `invalid_vectors` như file bắt tay (có ca đảo thứ tự hai nonce).

### `envelope.json`
`encrypted` = true: `key`, `v`, `type`, `id`, `ts`, `aad` (chuỗi `"<v>|<type>|<id>|<ts>"`), `aad_hex`, `plaintext` (JSON), `nonce` 24, `ciphertext`, `tag` 16, `payload_b64` = b64(nonce ‖ ciphertext ‖ tag), `envelope` (chuỗi wire). `encrypted` = false (tin bắt tay): `key`/`aad`/`nonce`/`ciphertext`/`tag` = null, `payload_b64` = b64(UTF-8 của `plaintext`). `invalid_vectors`: `{key, envelope}` — bên nhận dựng AAD từ chính các trường của envelope rồi giải mã, phải thất bại (tag sai, `ts`/`type` bị sửa, payload < 40 byte).

### `ack.json`
Như envelope mã hóa, `type = ack`, thêm `re`, `ok`. Có ack ok có `data`, ack ok `data` rỗng, ack lỗi `SMS_NO_SERVICE` (`error.code`, `message`, `details`).

### `clipboard-chunk.json`
Như envelope mã hóa nhưng plaintext nhị phân: `plaintext_hex` = `hdr_len` (uint16 BE) ‖ `header_json` (UTF-8) ‖ `chunk_data`. Thêm `transfer_id`, `index`, `header_json`, `hdr_len` (byte của JSON), `chunk_data`. Byte đầu plaintext là `0x00`. Khối trong vector ngắn hơn `CHUNK_SIZE` cho gọn.

### `hl-frame.json`
`channel`, `direction`, `key`, `seq`, `ts` (uint32), `header` (11 byte = `484c01` ‖ seq BE ‖ ts BE = AAD), `plaintext`, `nonce`, `ciphertext`, `tag`, `encrypted_part` = nonce ‖ ciphertext ‖ tag, `frame` = header ‖ encrypted_part. Kênh camera thêm `track`, `flags`, `pts_us` (int64 BE), `data` (plaintext = track ‖ flags ‖ pts_us ‖ data). Một vector dùng `seq` = `ts` = 2³²−1 để kiểm biên. `invalid_vectors`: `{key, frame}` — `seq` bị sửa (AAD sai), tag sai.

### `envelope-roundtrip.json` (liên nền tảng, Android ghi)
Envelope do Android (`android/core/crypto`, Tink XChaCha20-Poly1305) mã hóa bằng khóa cố định của `envelope.json` (`k_c2s`/`k_s2c` cặp 1), `id` UUIDv7 và nonce ngẫu nhiên mới. **Cùng trường với vector `encrypted = true` của `envelope.json`** (`name`, `encrypted`, `direction`, `key`, `key_source`, `v`, `type`, `id`, `ts`, `aad`, `aad_hex`, `plaintext`, `nonce`, `ciphertext`, `tag`, `payload_b64`, `envelope`). Không sinh bằng `tools/vectors/`: chỉ ghi lại khi chạy `cd android && HL_WRITE_ROUNDTRIP=1 ./gradlew :core:crypto:test`; test thường chỉ đọc và giải mã lại. Phía Apple (M0.1) giải mã từng `envelope` bằng `key` và so với `plaintext`. Ngược lại, test Android giải mã `envelope-roundtrip-apple.json` nếu file đó có.

### `envelope-roundtrip-apple.json` (liên nền tảng, Apple ghi)
Envelope do Apple (`apple/Packages/HLCrypto`: HChaCha20 tự cài + CryptoKit `ChaChaPoly`) mã hóa bằng khóa cố định của `envelope.json` (`k_c2s`/`k_s2c` cặp 1), `id` UUIDv7 và nonce ngẫu nhiên mới; plaintext lấy nguyên byte từ các vector `encrypted = true` của `envelope.json`. Cùng trường và thứ tự trường như `envelope-roundtrip.json`. Không sinh bằng `tools/vectors/`: chỉ ghi lại khi chạy `cd apple/Packages/HLCrypto && HL_WRITE_ROUNDTRIP=1 swift test` (thêm `HL_SWIFT_TESTING_PACKAGE=1` nếu máy chỉ có Command Line Tools); test thường chỉ đọc và giải mã lại. Android (A0.1) và relay giải mã từng `envelope` bằng `key` và so với `plaintext`.

## Dùng trong CI

Mỗi nền tảng đọc thẳng các file này trong test đơn vị: tính lại mọi trường của `vectors`, và kiểm mọi `invalid_vectors` bị từ chối. Trên Apple, `xchacha20-poly1305.json` phải qua bằng HChaCha20 tự cài + `ChaChaPoly`.
