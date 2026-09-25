# tools/vectors — sinh và kiểm test vector mã hóa

Chạy từ gốc kho `shared/` (handlive-shared); venv tại `tools/.venv` của kho này.

Đầu ra: `shared/test-vectors/*.json` (mô tả trường trong `shared/test-vectors/README.md`).

| Script | Việc | Chạy |
|--------|------|------|
| `generate_vectors.py` | Sinh lại toàn bộ file vector từ giá trị cố định; `--check` so byte-exact với file hiện có, lệch thì exit 1 | `tools/.venv/bin/python tools/vectors/generate_vectors.py [--check]` |
| `verify_vectors.py` | Kiểm mọi vector (kể cả RFC) và mọi vector âm bằng thư viện độc lập với phía sinh; XChaCha20 kiểm hai đường (libsodium và HChaCha20 + ChaCha20-Poly1305) | `tools/.venv/bin/python tools/vectors/verify_vectors.py` — phải in `0 lỗi` |

Cài (từ gốc `shared/`): `python3 -m venv tools/.venv && tools/.venv/bin/pip install -r tools/vectors/requirements.txt -r tools/schemas/requirements.txt`.

Mô-đun:

| File | Vai trò |
|------|---------|
| `rfc_source_values.py` | Giá trị chép nguyên văn từ draft-irtf-cfrg-xchacha-03, RFC 8439, 7748, 5869, 8032 (đã đối chiếu với bản .txt tải từ rfc-editor.org / ietf.org) |
| `handlive_protocol_derivations.py` | Phép dẫn xuất HandLive phía sinh (`cryptography` + pynacl) và `test_bytes(label)` |
| `hchacha20_reference.py` | HChaCha20 thuần Python (đường Apple) |
| `build_*_vectors.py` | Dựng nội dung từng file vector |
| `verify_common.py`, `verify_*_checks.py` | Phía kiểm: HKDF/HMAC bằng `hashlib`/`hmac`, X25519/Ed25519/XChaCha bằng libsodium |

Sửa định dạng hay thêm vector: sửa `build_*`, chạy `generate_vectors.py`, rồi `verify_vectors.py`. Không sửa tay file JSON.
