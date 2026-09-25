# Rà soát Phase 0 — quyết định cho các điểm lệch agent nêu

Ngày 25/09/2026. Nguồn: chín báo cáo `phase-00-*.md`, kiểm chứng độc lập (`verify_vectors.py` 360 phép kiểm, `check_schemas.py`, `swift test` HLCrypto 19 test). Nhiều điểm đã được điều phối viên chốt ngay trong Phase 0 (byte hóa `T1`/`T2`/`HLSTREAM1`, HKDF mặc định, rekey, `K_stream` epoch 0, `protocol` xác thực lại trong `capability/hello`, HS256, sửa hai ví dụ AUDIO-04, `scheme` cho target). Bảng dưới là phần còn lại, đã áp dụng vào tài liệu cùng ngày.

| # | Điểm (báo cáo) | Quyết định | Áp dụng ở |
|---|----------------|------------|-----------|
| 1 | Dạng chuẩn tắc AAD envelope (S0.1-7) | `v`, `ts` thập phân không số 0 đầu, `id` chữ thường; bên nhận dựng lại từ giá trị đã parse | 00 §0.5.1 |
| 2 | Mã lỗi lạ trong `ack` (M0.1-3) | Quy tắc tương thích tiến đã có (0.5.1 quy tắc 6); ghi rõ xử lý như `INTERNAL` và ghi log mã lạ | 00 §0.5.1 quy tắc 6 |
| 3 | Mã đóng cho rekey thất bại, giới hạn kết nối, chặn IP, im lặng (A0.2-1, A0.2 chưa làm) | 4410 `REKEY_FAILED`, 4411 `IDLE_TIMEOUT`, 4429 `RATE_LIMITED` | 00 §0.8.3; CONN-01 API 3–4; CONN-02 API 3 |
| 4 | Va chạm rekey (A0.2-2) | Bên thắng bỏ qua yêu cầu của bên thua, không `ack` | CONN-02 API 3 |
| 5 | Thời điểm thay phiên 4409 (A0.2-3) | Sau khi giải mã được `capability/hello` đầu tiên của phiên mới | CONN-01 bước 7 |
| 6 | Mất kho TLS (A0.2-5) | Sinh lại khóa; client thấy lệch ghim ở mọi instance → "Cần ghép nối lại", dừng thử | 00 §0.6.1; CONN-01 E2; 0.11 |
| 7 | Máy trạng thái 0.11 thiếu cạnh lỗi (M0.1-1) | Thêm cạnh `Connecting*`/`WaitingPeer` → `Backoff`, `Discovering` → `Backoff` khi relay tắt, → `Idle` khi hủy cặp cuối | 00 §0.11 |
| 8 | Keychain macOS (M0.1-2) | Data-protection keychain, entitlement `keychain-access-groups`; test không ký dùng kho trong bộ nhớ | 00 §0.6.1; code-standards; deployment-guide |
| 9 | Câu chữ 0.11 (M0.1-5) | "Đã kết nối qua Wi-Fi / Internet / USB" | 00 §0.11 |
| 10 | `generate_vectors.py --check` báo THỪA file roundtrip (M0.1-6) | Bỏ qua `envelope-roundtrip*.json` | tools/vectors |
| 11 | `revoked_at` của `devices` (R0.1-2) | Chỉ vận hành đặt khi khóa thiết bị lạm dụng; mọi endpoint trả 410 | 00 §0.6.4, §0.9.4 |
| 12 | Mã lỗi relay thiếu (R0.1-3, 4, 5) | 401 `SIGNATURE_INVALID` cho header sai; thêm 500 `INTERNAL`; API 3 liệt kê 400/404/410/500 | 00 §0.8.2; CONN-03 API 3 |
| 13 | Byte `challenge` (R0.1-6) | 32 byte thô đã giải b64u | 00 §0.6.4 |
| 14 | Giới hạn đăng ký theo IP (R0.1-7) | Phase 2, khóa Redis `rl:ip:<ip>:reg:<giờ>`, chỉ tin `X-Forwarded-For` từ reverse proxy | 00 §0.9.4; deployment-guide |
| 15 | `RELAY_JWT_SECRET` (R0.1-9) | Biến môi trường ≥ 32 byte, xoay theo lịch | deployment-guide |
| 16 | Vector `relay-auth.json`, `ed25519.json` (R0.1) | Làm ở Phase 1 | phase-01 S1.1 |
| 17 | `min_protocol` (S0.2) | Bắt buộc khi `UNSUPPORTED_VERSION`; schema cập nhật ở Phase 1 | CONN-01 API 6; phase-01 S1.1 |
| 18 | Ví dụ 0.7.2 thiếu `default_sub_id`; định dạng `bt_address` (S0.2-5, 6) | Thêm vào ví dụ; `AA:BB:CC:DD:EE:FF` chữ hoa, M-APP chuẩn hóa | 00 §0.7.2 |
| 19 | compileSdk (A0.1-1, A0.3-1) | Nâng 37, targetSdk giữ 35, Compose BOM mới nhất | code-standards; phase-01 A1.0 |
| 20 | Engine Ktor (A0.1-2) | Giữ Netty (CIO không có TLS phía server), tiếp tục loại native không dùng | code-standards |
| 21 | Cách lưu `ik_sig`/`ik_dh`, HKDF trên JCA (A0.1-3, 4) | Giữ cài đặt; 0.6.1 đã ghi đúng | — |
| 22 | Nút Destructive và Glass (A0.3-2) | Chữ đỏ trên nền kính là đúng; nền đỏ đặc chỉ cho nút tròn CallPanel; Glass chữ `label` | Button README |
| 23 | Token thiếu (A0.3-3, M0.2-2, 3) | Thêm `switch-thumb`, `on-icon-fill`, `size-row-icon`, `radius-row-icon`; `relativeTo`/`emphasisWeight`/`fontFeatures` trong `type-extras.json` | tokens.json; type-extras.json; 03-kieu-chu, GroupedList, Toggle |
| 24 | Kiểu chữ StatusIndicator (A0.3-8) | `*-subheadline` cho cả hai dạng | StatusIndicator README |
| 25 | Biểu tượng, Chữ đậm, Material Symbols (A0.3-4, 5; M0.2-4) | Phase 1: đóng gói Material Symbols, Inter 700, Be Vietnam Pro ExtraBold | phase-01 A1.0, M1.0 |
| 26 | Nút chính trên Mac và tương phản `accent` tối (M0.2-1) | `AccentColor` = `accent-fill`; `accent` chỉ cho chữ, liên kết, biểu tượng | 01-mau-sac; tokens usage; phase-01 M1.0 |
| 27 | Biểu tượng "phân biệt không dùng màu" (M0.2-5) | `ellipsis.circle.fill` đang kết nối, `record.circle` đang phát | 01-mau-sac |
| 28 | Màu ngữ nghĩa qua API, `AccentColor` toàn app (M0.2-6, 7) | Phase 1 | phase-01 M1.0 |
| 29 | Tên file Swift (M0.2-8) | Mã nguồn theo quy ước nền tảng (PascalCase); kebab-case cho script, tài liệu, tài nguyên | code-standards; phase-01 M1.0 |
| 30 | CI chưa chạy thật (T0.1) | Cần remote GitHub và branch protection — việc của chủ dự án; cổng G0 đánh dấu khi bốn workflow xanh | deployment-guide |
| 31 | Câu chữ phase-00 (A0.2-7, T0.1-1) | `./gradlew check`; PKCS#12 | phase-00 |

Không còn câu hỏi mở từ Phase 0. Việc cần chủ dự án tự làm: tạo remote GitHub, đẩy nhánh, bật branch protection; cài `platforms;android-37`; máy có Xcode để chạy `xcodebuild test`.
