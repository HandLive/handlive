[English](02-pairing.md) | Tiếng Việt

# 2. Nhóm chức năng: Ghép nối và quản lý thiết bị

> Tham chiếu chung: [`00-common-specs.md`](00-common-specs.vi.md) — thành phần (0.1), định danh (0.2),
> khung tin (0.5), khóa và ghép nối (0.6.1–0.6.2), mã lỗi (0.8), lược đồ (0.9).

## 2.1 PAIR-01 — Ghép nối thiết bị bằng mã QR (dự phòng: PIN)

### 2.1.1 Thông tin chung

| Mục | Nội dung |
|-----|----------|
| Tên | PAIR-01 — Ghép nối thiết bị bằng mã QR (dự phòng: PIN) |
| Mô tả | Thiết lập quan hệ tin cậy giữa điện thoại Android và một Mac/iPhone/iPad: trao đổi khóa định danh, sinh khóa gốc của cặp `PRK`, ghim chứng chỉ TLS của điện thoại, lưu bản chứng thực có chữ ký của cả hai bên.<br>Mac/iOS hiển thị QR, Android quét.<br>Khi không quét được QR thì dùng PIN 6 số (chỉ trong LAN).<br>Từ P2, nếu hai thiết bị không thấy nhau trong LAN, bước trao đổi đi qua điểm hẹn trên relay (chỉ với QR). |
| Tác nhân | Chính: Người dùng (sở hữu cả hai thiết bị). Hệ thống: A-UI, A-SVC, M-APP hoặc I-APP, R-API và R-KV (điểm hẹn, đăng ký cặp). |
| Điều kiện trước | 1.<br>Android đã hoàn tất SET-01 (có quyền camera để quét QR) và A-SVC đang chạy.<br>2.<br>Mac/iOS đã hoàn tất SET-03 (quyền mạng cục bộ).<br>3.<br>Hai thiết bị cùng LAN; hoặc (từ P2) cả hai có Internet và `relay.enabled = true`.<br>4.<br>Mac/iOS chưa có cặp hiệu lực nào.<br>5.<br>Android có ít hơn 8 cặp hiệu lực. |
| Điều kiện sau | **Thành công:** hai bên có bản ghi `paired_device` cùng `pair_id`; `PRK` nằm trong kho khóa; Mac/iOS ghim `peer_tls_sha256`; cặp được đăng ký lên relay nếu relay bật (hoặc đánh dấu chờ đăng ký); CONN-01 tự chạy.<br>**Thất bại:** không bên nào lưu gì; `pairing_secret` hoặc PIN bị hủy khỏi bộ nhớ. |
| Ngoại lệ | E1 — QR không phải của HandLive hoặc sai định dạng (`QR_INVALID`): Android báo "Mã QR này không phải của HandLive."<br>E2 — QR đã hết hạn vì Mac/iOS đã làm mới (`PAIRING_CLOSED`): Android báo "Mã QR đã đổi. Quét mã mới trên Mac hoặc iPhone."<br>E3 — Không tìm thấy nhau trong 20 s và relay không khả dụng: Mac/iOS báo "Không tìm thấy điện thoại. Để hai máy cùng mạng Wi-Fi rồi thử lại."<br>E4 — HMAC, chữ ký hoặc ràng buộc TLS sai, có thể đang bị tấn công xen giữa (`AUTH_FAILED`).<br>E5 — Người dùng bấm Hủy trên Android.<br>E6 — Android đã đủ 8 cặp: Android báo "Điện thoại đã ghép đủ 8 thiết bị. Hủy ghép nối một thiết bị rồi thử lại."<br>E7 — PIN sai (`PIN_INVALID`); quá 3 lần thì Mac/iOS sinh PIN mới.<br>E8 — Đăng ký cặp lên relay lỗi: cặp vẫn dùng được trong LAN, `relay_registered = 0`, thử lại nền.<br>E9 — Quyền camera bị từ chối: Android báo "Không dùng được camera. Dùng mã PIN để ghép nối." và chuyển sang PIN. |
| Yêu cầu đặc biệt | **Bảo mật:** `pairing_secret` 256 bit, chỉ sống 120 s, không bao giờ rời thiết bị ngoài QR, không ghi log; so sánh HMAC hằng thời gian; relay không nhìn thấy `pairing_secret` và không được dùng cho PIN.<br>PIN là đường dự phòng: kẻ tấn công chủ động nằm giữa đúng lúc ghép có thể dò PIN ngoại tuyến — giảm thiểu bằng Argon2id (t=3, m=64 MiB, p=4), giới hạn 3 lần và chỉ cho phép trong LAN.<br>**Hiệu năng:** từ lúc quét tới "Đã ghép nối" ≤ 5 s trong LAN, ≤ 8 s qua relay.<br>**Khả dụng:** QR đủ tương phản ở cả giao diện sáng và tối; hướng dẫn đọc được bằng VoiceOver/TalkBack; nhận diện QR chạy hoàn toàn trên máy (ML Kit bản đóng gói). |

### 2.1.2 Màn hình

N/A — chưa có wireframe được duyệt.

### 2.1.3 Mô tả chi tiết các thành phần

| # | Trường | Kiểu dữ liệu | Input/Output | Giá trị khởi tạo | Mô tả |
|---|--------|--------------|--------------|------------------|-------|
| 1 | Mã QR ghép nối | string (URI) | Output | Sinh khi mở màn hình ghép nối | Mac/iOS hiển thị `handlive://pair?v=1&pk=…&ps=…&d=…[&rv=…]`; mức sửa lỗi M; tự làm mới sau 120 s |
| 2 | Thời gian hiệu lực còn lại | int32 (giây) | Output | 120 | Đếm ngược dưới QR; về 0 thì sinh QR mới |
| 3 | Tên thiết bị client | string(64) | Output | Tên máy (`Host.current().localizedName` / `UIDevice.current.name`) | Nằm trong QR (`d`), hiển thị trên Android khi xác nhận |
| 4 | Khung quét QR | camera preview | Input | Camera sau | Android quét bằng CameraX + ML Kit |
| 5 | Xác nhận ghép nối | enum{Ghép nối\| Hủy} | Input | — | Android hỏi "Ghép nối với <tên thiết bị client>?"; "Ghép nối" là nút mặc định, "Hủy" bên trái |
| 6 | Mã PIN | string(6), chỉ chữ số | Output (Mac/iOS), Input (Android) | Sinh khi chọn "Dùng mã PIN" | Dự phòng khi không quét được QR |
| 7 | Số lần nhập PIN còn lại | int32 | Output | 3 | Hiển thị trên Android sau lần nhập sai: "Còn {count} lần thử" |
| 8 | Trạng thái ghép nối | enum{waiting_scan\| connecting\| verifying\| done\| failed} | Output | `waiting_scan` | Hiển thị trên cả hai thiết bị |
| 9 | Tên điện thoại | string(64) | Output | `Settings.Global.DEVICE_NAME` | Hiển thị trên Mac/iOS khi ghép xong |
| 10 | Thông báo lỗi | string | Output | Rỗng | Nội dung theo E1–E9 |

### 2.1.4 Luồng nghiệp vụ

```mermaid
flowchart TB
  subgraph ND["Người dùng"]
    U1["(1) Chọn Thêm điện thoại trên Mac/iOS"]
    U3["(3) Mở Ghép nối trên Android, quét QR"]
    U5["(5) Xác nhận ghép nối"]
    U12["(12) Thấy Đã ghép nối trên hai thiết bị"]
  end
  subgraph HT["Hệ thống"]
    S2["(2) Sinh pairing_secret, hiển thị QR 120 s"]
    D4{"(4) QR hợp lệ và còn chỗ?"}
    S6["(6) Android mở cửa sổ ghép nối, quảng bá TXT pr"]
    D7{"(7) Tìm thấy nhau trong 20 s?"}
    S8["(8) Mở /v1/pair (LAN) hoặc điểm hẹn relay"]
    S9["(9) pair/hello và pair/offer"]
    D10{"(10) HMAC, device_id, TLS hợp lệ?"}
    S11["(11) pair/confirm và pair/done, lưu cặp, đăng ký relay"]
    X1(["Kết thúc: báo lỗi"])
  end
  U1 --> S2 --> U3 --> D4
  D4 -- "Có" --> U5
  D4 -- "Không (E1, E2, E6)" --> X1
  U5 -- "Đồng ý" --> S6 --> D7
  U5 -- "Hủy (E5)" --> X1
  D7 -- "LAN hoặc relay" --> S8 --> S9 --> D10
  D7 -- "Không (E3)" --> X1
  D10 -- "Đúng" --> S11 --> U12
  D10 -- "Sai (E4)" --> X1
```

| Bước | Tác nhân | Thành phần | Mô tả | Ngoại lệ / Ghi chú |
|------|----------|-----------|-------|--------------------|
| 1 | Người dùng | M-APP / I-APP | Chọn "Thêm điện thoại…" (lần đầu mở ứng dụng hoặc từ PAIR-02). | Đã có cặp hiệu lực → hỏi hủy cặp cũ trước (PAIR-03). |
| 2 | Hệ thống | M-APP / I-APP | Nạp hoặc tạo `ik_dh`, `ik_sig`; sinh `pairing_secret` 32 byte (`SecRandomCopyBytes`).<br>Nếu relay bật: sinh `rv_id` 16 byte, xác thực relay (0.6.4), gửi `rv_join`.<br>Dựng URI QR, vẽ QR (`CIFilter.qrCodeGenerator`).<br>Bắt đầu duyệt mDNS `_handlive._tcp`.<br>Hẹn 120 s: hủy secret cũ, quay lại bước 2. | Relay lỗi → QR không có `rv`, chỉ ghép trong LAN. |
| 3 | Người dùng | A-UI | Mở "Ghép nối thiết bị" và quét QR. | Không có quyền camera → E9, chuyển luồng PIN (A1). |
| 4 | Hệ thống | A-UI | Kiểm scheme `handlive`, host `pair`, `v = 1`, `pk` và `ps` giải mã đủ 32 byte, `d` ≤ 64 ký tự, `rv` (nếu có) đủ 16 byte. Đếm cặp hiệu lực < 8. | Sai định dạng → E1. Đủ 8 cặp → E6. |
| 5 | Người dùng | A-UI | Chọn "Ghép nối" hoặc "Hủy" ở hộp thoại "Ghép nối với \<d>?". | "Hủy" → E5. |
| 6 | Hệ thống | A-SVC | Mở cửa sổ ghép nối 120 s: nhận kết nối `/v1/pair`; đăng ký lại dịch vụ mDNS với TXT `pr` = 8 hex đầu SHA-256(`pk`). Nếu có `rv`: kết nối relay, gửi `rv_join`. |  |
| 7 | Hệ thống | M-APP / I-APP | Chờ tối đa 20 s: thấy instance có `pr` khớp → đi LAN; nhận `rv_joined` với `peer_present = true` → đi relay. LAN được ưu tiên nếu cả hai cùng có. | Không có đường nào → E3. |
| 8 | Hệ thống | M-APP / I-APP | LAN: mở `wss://<ip>:<port>/v1/pair`, chấp nhận chứng chỉ tự ký nhưng ghi lại SHA-256 chứng chỉ thấy được. Relay: gói envelope `pair` trong `rv_msg`. |  |
| 9 | Hệ thống | M-APP ↔ A-SVC | Client gửi `pair/hello`. Android kiểm `ik_dh_pub` trùng `pk` trong QR, sinh `nonce_s`, tính `K_pa`, trả `pair/offer` có `mac`. | `ik_dh_pub` khác `pk` → `pair/error AUTH_FAILED` (E4). |
| 10 | Hệ thống | M-APP / I-APP | Kiểm `mac` của offer; kiểm `device_id` Android = UUIDv8(SHA-256(`ik_sig_pub`)); trong LAN kiểm `tls_sha256` = chứng chỉ của kết nối hiện tại. | Sai → gửi `pair/error AUTH_FAILED`, đóng, báo "Ghép nối không an toàn, thử lại" (E4). |
| 11 | Hệ thống | M-APP ↔ A-SVC, R-API | Client tính `PRK`, sinh `pair_id`, `created_at`, bản chứng thực, ký `sig_c`, gửi `pair/confirm`.<br>Android kiểm `mac`, `prk_check`, `device_id` và `sig_c`; ký `sig_s`; lưu `paired_device`; trả `pair/done`.<br>Client kiểm `sig_s`, `prk_check`; lưu `paired_device`, `PRK` vào Keychain, ghim chứng chỉ.<br>Cả hai hủy secret; Android đóng `/v1/pair`, bỏ TXT `pr`, thêm hint của cặp mới vào TXT `h`.<br>Nếu relay bật, mỗi bên gọi `POST /v1/pairs` (idempotent). | Relay lỗi → E8, thử lại nền khi có mạng. |
| 12 | Người dùng | A-UI, M-APP / I-APP | Thấy "Đã ghép nối với <tên>" trên cả hai thiết bị; client chuyển sang CONN-01. |  |
| A1 | Người dùng | M-APP / I-APP | Luồng PIN: chọn "Không quét được? Dùng mã PIN". | Chỉ LAN. |
| A2 | Hệ thống | M-APP / I-APP | Sinh PIN 6 số (CSPRNG, phân bố đều), hiển thị 120 s; duyệt mDNS tìm instance có `pm = 1`. |  |
| A3 | Người dùng | A-UI | Chọn "Nhập mã PIN", nhập 6 số, xác nhận ghép nối. |  |
| A4 | Hệ thống | A-SVC | Mở cửa sổ ghép nối với TXT `pm = 1`. Client kết nối `/v1/pair`, gửi `pair/hello` với `mode = "pin"`. Hai bên dùng `K_pin` = Argon2id(PIN, `nonce_c` ‖ `nonce_s`) thay cho `pairing_secret` ở bước 9–11. |  |
| A5 | Hệ thống | M-APP / I-APP | Kiểm `mac` của offer bằng PIN của mình. Sai → `pair/error PIN_INVALID` kèm số lần còn lại; lần thứ 3 sai → hủy PIN, sinh PIN mới (E7). Đúng → tiếp bước 10–12. |  |

### 2.1.5 Đặc tả API/service

**Danh sách lời gọi**

| # | API/service | Kênh | Chiều | Dùng ở bước |
|---|-------------|------|-------|-------------|
| 1 | URI QR `handlive://pair` | Quang học (QR) | Client → Android | 2, 3, 4 |
| 2 | `WS pair/hello` | `/v1/pair` hoặc `rv_msg` | C→S | 9, A4 |
| 3 | `WS pair/offer` | như trên | S→C | 9 |
| 4 | `WS pair/confirm` | như trên | C→S | 11 |
| 5 | `WS pair/done` | như trên | S→C | 11 |
| 6 | `WS pair/error` | như trên | Hai chiều | 9, 10, A5 |
| 7 | Relay `rv_join` / `rv_joined` / `rv_msg` | `wss://{RELAY_HOST}/v1/relay` (text) | Thiết bị ↔ R-API | 2, 6, 7, 8 |
| 8 | `POST /v1/pairs` | REST relay | Thiết bị → R-API | 11 |
| 9 | Dịch vụ hệ điều hành: `NsdManager.registerService`, `NWBrowser`, ML Kit `BarcodeScanning`, `CIFilter.qrCodeGenerator`, Keychain `SecItemAdd` | Cục bộ | — | 2, 3, 6, 7, 11 |

Chuỗi xác thực dùng chung trong các API dưới đây:
- `K_pa` = HKDF-SHA256(ikm = `pairing_secret` (hoặc `K_pin`), salt = `nonce_c` ‖ `nonce_s`, info =
  `"handlive/v1/pair-auth"`, L = 32).
- `T_offer` = `"HL1|offer|"` ‖ các trường theo thứ tự cố định: `device_id` C(16) ‖ `nonce_c` (32) ‖
  `ik_sig_pub` C(32) ‖ `ik_dh_pub` C(32) ‖ str(`name`C) ‖ `device_id` S(16) ‖ `nonce_s` (32) ‖
  `ik_sig_pub` S(32) ‖ `ik_dh_pub` S(32) ‖ `tls_sha256` (32) ‖ str(`name`S), với str(x) = uint16 BE
  độ dài ‖ UTF-8.
- Không dùng JSON làm dữ liệu ký/HMAC (tránh sai khác chuẩn hóa giữa Kotlin và Swift).

#### API 1 — URI QR `handlive://pair`

- **URL:** `handlive://pair?v=1&pk=<b64u>&ps=<b64u>&d=<tên, percent-encoded>[&rv=<b64u>]`
- **Method:** Hiển thị QR (Mac/iOS) → quét bằng ML Kit (Android).
- **Request (tham số):**

| Tham số | Kiểu | Bắt buộc | Mô tả |
|---------|------|----------|-------|
| `v` | int32 | Có | Phiên bản định dạng, `1` |
| `pk` | b64u (32 byte) | Có | `ik_dh_pub` của client |
| `ps` | b64u (32 byte) | Có | `pairing_secret` |
| `d` | string(64) | Có | Tên thiết bị client |
| `rv` | b64u (16 byte) | Không | Mã điểm hẹn relay (P2) |

- **Response:** N/A (không có phản hồi trực tiếp; kết quả đi qua API 2–6).
- **Ví dụ:**
  `handlive://pair?v=1&pk=q83vEjRWeJC7zN3u_wARIjNEVWZ3iJmqu8zd7v8AESI&ps=AAECAwQFBgcICQoLDA0ODxAREhMUFRYXGBkaGxwdHh8&d=MacBook%20c%E1%BB%A7a%20Lan&rv=Eh8kKS4zOD1CR0xRVltgZQ`
- **Logic nghiệp vụ:**
  1. Chuỗi URI ≤ 300 ký tự để QR ở mức phiên bản ≤ 10, quét tốt trên màn hình Retina.
  2. Android bỏ qua tham số không biết (tương thích tiến); chỉ từ chối khi thiếu tham số bắt buộc,
     sai độ dài hoặc `v` khác `1`.
  3. Mỗi lần làm mới QR tạo `pairing_secret` và `rv_id` mới; secret cũ bị xóa khỏi bộ nhớ ngay.

#### API 2 — `WS pair/hello`

- **URL:** `wss://{android_host}:{port}/v1/pair` (LAN) hoặc envelope trong `rv_msg` qua
  `wss://{RELAY_HOST}/v1/relay`
- **Method:** `WS pair/hello` (C→S), payload chưa mã hóa (0.5.1), phản hồi là `pair/offer`.
- **Request (`data`):**

| Trường | Kiểu | Bắt buộc | Mô tả |
|--------|------|----------|-------|
| `mode` | enum{qr\| pin} | Có |  |
| `device_id` | uuid | Có | `device_id` của client |
| `nonce` | b64u (32 byte) | Có | `nonce_c` ngẫu nhiên |
| `name` | string(64) | Có | Tên client |
| `platform` | enum{macos\| ios\| ipados} | Có |  |
| `model` | string(64) | Không | Ví dụ `Mac15,3`, `iPhone16,1` |
| `ik_sig_pub` | b64u (32 byte) | Có | Khóa ký Ed25519 của client |
| `ik_dh_pub` | b64u (32 byte) | Có | Phải trùng `pk` khi `mode = qr` |

- **Response:** `WS pair/offer` (API 3) hoặc `WS pair/error` (API 6).
- **Ví dụ (plaintext của payload):**

```json
{"op":"hello","data":{"mode":"qr","device_id":"5b1f8c2e-9a4d-8e6f-a1b2-c3d4e5f60718","nonce":"xLwqX2J3v3mYqk9jR0l5b0Y4WmR2bUxHQ3N0RU9mZ1U","name":"MacBook của Lan","platform":"macos","model":"Mac15,3","ik_sig_pub":"7Kx9vQ2mTn4pL8rWz1YcHd6fJb3gSa5eUo0iVtNkQxA","ik_dh_pub":"q83vEjRWeJC7zN3u_wARIjNEVWZ3iJmqu8zd7v8AESI"}}
```

- **Logic nghiệp vụ:**
  1. Chỉ nhận khi cửa sổ ghép nối đang mở; ngoài cửa sổ → `pair/error PAIRING_CLOSED` và đóng.
  2. `mode = qr`: `ik_dh_pub` phải trùng `pk` đã quét, sai → `AUTH_FAILED`. `mode = pin`: chỉ nhận
     khi cửa sổ mở ở chế độ PIN và kết nối đến từ LAN (không qua relay).
  3. Kiểm `device_id` = UUIDv8(SHA-256(`ik_sig_pub`)); sai → `AUTH_FAILED`.
  4. Một cửa sổ ghép nối chỉ phục vụ một client: kết nối thứ hai trong cùng cửa sổ →
     `PAIRING_CLOSED`.

#### API 3 — `WS pair/offer`

- **URL:** như API 2
- **Method:** `WS pair/offer` (S→C), payload chưa mã hóa.
- **Request (`data`):**

| Trường | Kiểu | Bắt buộc | Mô tả |
|--------|------|----------|-------|
| `device_id` | uuid | Có | `device_id` của Android |
| `nonce` | b64u (32 byte) | Có | `nonce_s` |
| `name` | string(64) | Có | Tên điện thoại |
| `model` | string(64) | Có | `Build.MODEL` |
| `os_version` | string | Có | `Build.VERSION.RELEASE` |
| `ik_sig_pub` | b64u (32 byte) | Có |  |
| `ik_dh_pub` | b64u (32 byte) | Có |  |
| `tls_sha256` | b64u (32 byte) | Có | SHA-256 chứng chỉ TLS (DER) của A-SVC |
| `mac` | b64u (32 byte) | Có | HMAC-SHA256(`K_pa`, `T_offer`) |

- **Response:** client gửi `pair/confirm` (API 4) hoặc `pair/error` (API 6).
- **Ví dụ:**

```json
{"op":"offer","data":{"device_id":"8c7d6e5f-4a3b-8c2d-9e1f-0a1b2c3d4e5f","nonce":"n3Jz0b1QdX9pVw8yKq2mLc4tRe6uHs5aGf7iJk0oPlM","name":"Pixel của Lan","model":"Pixel 8","os_version":"15","ik_sig_pub":"Zm9vYmFyYmF6cXV4cXV1eHh5enp6MTIzNDU2Nzg5MDE","ik_dh_pub":"cXdlcnR5dWlvcGFzZGZnaGprbHp4Y3Zibm0xMjM0NTY","tls_sha256":"3q2-7wAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA","mac":"hM8Qe1vV0x3bKpZ9aLr2sT5wYc7uJd4nFg6iHk8oPqA"}}
```

- **Logic nghiệp vụ:**
  1. Android chỉ gửi offer sau khi kiểm xong API 2.
  2. `tls_sha256` được bảo vệ bởi `mac`, nên kể cả qua relay (không có kênh TLS trực tiếp) client
     vẫn ghim đúng chứng chỉ thật của điện thoại.
  3. Client kiểm theo thứ tự: `mac` → `device_id` khớp `ik_sig_pub` → (LAN) `tls_sha256` trùng chứng
     chỉ của kết nối hiện tại. Bất kỳ bước nào sai → `AUTH_FAILED`, không tiết lộ bước nào sai.

#### API 4 — `WS pair/confirm`

- **URL:** như API 2
- **Method:** `WS pair/confirm` (C→S), payload chưa mã hóa, phản hồi là `pair/done`.
- **Request (`data`):**

| Trường | Kiểu | Bắt buộc | Mô tả |
|--------|------|----------|-------|
| `pair_id` | uuid | Có | UUIDv4 do client sinh |
| `created_at` | timestamp | Có | Thời điểm tạo cặp (đồng hồ client) |
| `sig` | b64u (64 byte) | Có | Ed25519(`ik_sig` client, `attestation`) — cấu trúc `attestation` ở 0.6.2 |
| `prk_check` | b64u (32 byte) | Có | HMAC-SHA256(`PRK`, `"HL1 | prk-check-c | "` ‖ `pair_id`) |
| `mac` | b64u (32 byte) | Có | HMAC-SHA256(`K_pa`, `"HL1 | confirm | "` ‖ `T_offer` ‖ `pair_id` ‖ `created_at` ‖ `sig`) |

- **Response:** `WS pair/done` (API 5) hoặc `WS pair/error` (API 6).
- **Ví dụ:**

```json
{"op":"confirm","data":{"pair_id":"3f2b1c4d-5e6f-4a7b-8c9d-0e1f2a3b4c5d","created_at":1727150003210,"sig":"<b64u 64 byte>","prk_check":"<b64u 32 byte>","mac":"<b64u 32 byte>"}}
```

- **Logic nghiệp vụ:**
  1. Android kiểm `mac` trước, rồi tự tính `PRK` (0.6.2) và so `prk_check` — phát hiện sớm mọi sai
     lệch cài đặt giữa hai nền tảng.
  2. Dựng lại `attestation` từ dữ liệu đã có, kiểm `sig` bằng `ik_sig_pub` của client.
  3. `|created_at − giờ Android| > 10 phút` → vẫn nhận (đồng hồ có thể lệch) nhưng dùng nguyên giá
     trị client gửi trong `attestation`.
  4. Lưu cặp trong một giao dịch: nếu đã có bản ghi cùng `peer_device_id` (client ghép lại) thì xóa
     bản cũ rồi chèn bản mới.

#### API 5 — `WS pair/done`

- **URL:** như API 2
- **Method:** `WS pair/done` (S→C), payload chưa mã hóa.
- **Request (`data`):**

| Trường | Kiểu | Bắt buộc | Mô tả |
|--------|------|----------|-------|
| `sig` | b64u (64 byte) | Có | Ed25519(`ik_sig` Android, `attestation`) |
| `prk_check` | b64u (32 byte) | Có | HMAC-SHA256(`PRK`, `"HL1 | prk-check-s | "` ‖ `pair_id`) |
| `mac` | b64u (32 byte) | Có | HMAC-SHA256(`K_pa`, `"HL1 | done | "` ‖ `pair_id` ‖ `sig`) |

- **Response:** N/A (kết thúc giao thức; client đóng kết nối với mã 1000).
- **Ví dụ:**

```json
{"op":"done","data":{"sig":"<b64u 64 byte>","prk_check":"<b64u 32 byte>","mac":"<b64u 32 byte>"}}
```

- **Logic nghiệp vụ:**
  1. Client kiểm `mac`, `prk_check`, `sig`; sai → xóa mọi dữ liệu tạm, báo E4 (Android đã lưu cặp sẽ
     tự dọn khi CONN-01 thất bại với `PAIR_UNKNOWN` phía client — xem PAIR-03 bước dọn dẹp).
  2. Đúng → client lưu `paired_device`, lưu `PRK` vào Keychain (account = `pair_id`), rồi mới báo
     thành công cho người dùng.

#### API 6 — `WS pair/error`

- **URL:** như API 2
- **Method:** `WS pair/error` (hai chiều), payload chưa mã hóa; bên gửi đóng kết nối ngay sau đó.
- **Request (`data`):**

| Trường | Kiểu | Bắt buộc | Mô tả |
|--------|------|----------|-------|
| `code` | enum{QR_INVALID\| PAIRING_CLOSED\| PIN_INVALID\| AUTH_FAILED\| INTERNAL} | Có | Mã lỗi (0.8.1) |
| `message` | string | Có | Mô tả ngắn, không chứa dữ liệu nhạy cảm |
| `attempts_left` | int32 | Chỉ với `PIN_INVALID` | Số lần nhập còn lại |

- **Response:** N/A.
- **Ví dụ:**
  `{"op":"error","data":{"code":"PIN_INVALID","message":"PIN does not match","attempts_left":2}}`
- **Logic nghiệp vụ:** Không tiết lộ chi tiết bước kiểm nào sai với `AUTH_FAILED`; ghi log cục bộ
  chỉ gồm mã lỗi.

#### API 7 — Điểm hẹn relay `rv_join` / `rv_joined` / `rv_msg`

- **URL:** `wss://{RELAY_HOST}/v1/relay` (sau xác thực JWT — CONN-03)
- **Method:** WS text frame điều khiển relay (0.7.3).
- **Request:**

| op | Trường | Kiểu | Mô tả |
|----|--------|------|-------|
| `rv_join` | `rv_id` | b64u (16 byte) | Tham gia điểm hẹn |
| `rv_msg` | `rv_id` | b64u (16 byte) |  |
| `rv_msg` | `env` | object | Envelope `pair` (API 2–6) |

- **Response:**

| op | Trường | Kiểu | Mô tả |
|----|--------|------|-------|
| `rv_joined` | `rv_id` | b64u |  |
| `rv_joined` | `peer_present` | bool | Đã có đủ hai thành viên |
| `error` | `code` | string | `BAD_REQUEST` khi điểm hẹn đã đủ 2 thành viên hoặc hết hạn |

- **Ví dụ:**

```json
{"op":"rv_join","rv_id":"Eh8kKS4zOD1CR0xRVltgZQ"}
{"op":"rv_joined","rv_id":"Eh8kKS4zOD1CR0xRVltgZQ","peer_present":true}
{"op":"rv_msg","rv_id":"Eh8kKS4zOD1CR0xRVltgZQ","env":{"v":1,"type":"pair","id":"0192f3c1-7c1e-7a55-9d0b-3f4c2a1b9e10","ts":1727150001000,"payload":"eyJvcCI6ImhlbGxvIiwiZGF0YSI6e319"}}
```

- **Logic nghiệp vụ:**
  1. Điểm hẹn sống 180 s, tối đa 2 thành viên; thành viên thứ ba bị từ chối.
  2. Khi thành viên thứ hai vào, relay gửi `rv_joined` (`peer_present = true`) cho cả hai.
  3. Relay chuyển nguyên `env` sang thành viên còn lại, không đọc nội dung; chỉ chấp nhận
     `env.type = "pair"`.
  4. Envelope `pair/hello` có `mode = "pin"` qua điểm hẹn bị relay chặn và Android cũng từ chối (PIN
     chỉ trong LAN).

#### API 8 — `POST /v1/pairs`

- **URL:** `https://{RELAY_HOST}/v1/pairs`
- **Method:** `POST`, header `Authorization: Bearer <jwt>`
- **Request:**

| Trường | Kiểu | Bắt buộc | Mô tả |
|--------|------|----------|-------|
| `pair_id` | uuid | Có |  |
| `device_a` | uuid | Có | Android |
| `device_b` | uuid | Có | Mac/iOS |
| `created_at` | timestamp | Có |  |
| `attestation` | b64u | Có | Cấu trúc 0.6.2 |
| `sig_a` | b64u (64 byte) | Có | Chữ ký của Android |
| `sig_b` | b64u (64 byte) | Có | Chữ ký của client |

- **Response:**

| HTTP | Body | Khi nào |
|------|------|---------|
| 201 | `{"pair_id":"…","created_at":1727150003210}` | Tạo mới |
| 200 | như trên | Đã tồn tại với dữ liệu giống hệt (gọi lặp) |
| 403 `NOT_PAIRED` | lỗi | Người gọi không phải `device_a` hoặc `device_b` |
| 404 `DEVICE_NOT_FOUND` | lỗi | Một bên chưa đăng ký thiết bị → thử lại sau |
| 409 `PAIR_EXISTS` | lỗi | `pair_id` đã có với dữ liệu khác |
| 401 `SIGNATURE_INVALID` | lỗi | Một trong hai chữ ký sai |

- **Ví dụ:**

```http
POST /v1/pairs HTTP/1.1
Host: relay.example.com
Authorization: Bearer eyJhbGciOiJIUzI1NiJ9.eyJzdWIiOiI1YjFmOGMyZS05YTRkLThlNmYtYTFiMi1jM2Q0ZTVmNjA3MTgifQ.sig
Content-Type: application/json

{"pair_id":"3f2b1c4d-5e6f-4a7b-8c9d-0e1f2a3b4c5d","device_a":"8c7d6e5f-4a3b-8c2d-9e1f-0a1b2c3d4e5f","device_b":"5b1f8c2e-9a4d-8e6f-a1b2-c3d4e5f60718","created_at":1727150003210,"attestation":"SExQQUlSMT8rHE1ebz9…","sig_a":"<b64u>","sig_b":"<b64u>"}
```

```json
{"pair_id":"3f2b1c4d-5e6f-4a7b-8c9d-0e1f2a3b4c5d","created_at":1727150003210}
```

- **Logic nghiệp vụ:**
  1. `sub` của JWT phải là `device_a` hoặc `device_b`.
  2. Hai thiết bị phải tồn tại và chưa bị xóa; lấy `ik_sig_pub` từ `devices`.
  3. Phân tích `attestation`, đối chiếu `pair_id`, `device_a`, `device_b`, `created_at` và hai khóa
     công khai; kiểm `sig_a`, `sig_b`.
  4. Ghi idempotent: chèn nếu chưa có; nếu đã có thì so `attestation` — giống → 200, khác → 409.
  5. Thành công → thiết bị đặt `relay_registered = 1`.

#### Query

```sql
-- [Thiết kế] Android, bước 4: đếm cặp hiệu lực (giới hạn 8)
SELECT COUNT(*) AS active_pairs
FROM paired_device
WHERE revoked_at IS NULL;

-- [Thiết kế] Android, bước 11 (một giao dịch): thay cặp cũ của cùng client rồi chèn cặp mới
DELETE FROM paired_device WHERE peer_device_id = :peer_device_id;
INSERT INTO paired_device (pair_id, peer_device_id, peer_name, peer_platform, peer_model,
                           peer_ik_sig_pub, peer_ik_dh_pub, prk_enc, attestation,
                           sig_self, sig_peer, created_at)
VALUES (:pair_id, :peer_device_id, :peer_name, :peer_platform, :peer_model,
        :peer_ik_sig_pub, :peer_ik_dh_pub, :prk_enc, :attestation,
        :sig_self, :sig_peer, :created_at);

-- [Thiết kế] Mac/iOS, bước 1: kiểm đã có cặp hiệu lực chưa
SELECT pair_id, peer_name
FROM paired_device
WHERE revoked_at IS NULL
LIMIT 1;

-- [Thiết kế] Mac/iOS, bước 11: lưu cặp (PRK lưu riêng trong Keychain)
INSERT INTO paired_device (pair_id, peer_device_id, peer_name, peer_model, peer_ik_sig_pub,
                           peer_ik_dh_pub, peer_tls_sha256, attestation, sig_self, sig_peer,
                           last_host, last_port, created_at)
VALUES (:pair_id, :peer_device_id, :peer_name, :peer_model, :peer_ik_sig_pub,
        :peer_ik_dh_pub, :peer_tls_sha256, :attestation, :sig_self, :sig_peer,
        :last_host, :last_port, :created_at);

-- [Thiết kế] Relay, API 8: lấy khóa công khai của hai thiết bị
SELECT device_id, ik_sig_pub
FROM devices
WHERE device_id IN ($1, $2) AND revoked_at IS NULL;

-- [Thiết kế] Relay, API 8: ghi cặp idempotent
INSERT INTO pairs (pair_id, device_a, device_b, attestation, sig_a, sig_b, created_at)
VALUES ($1, $2, $3, $4, $5, $6, to_timestamp($7 / 1000.0))
ON CONFLICT (pair_id) DO NOTHING
RETURNING pair_id;

-- [Thiết kế] Relay, API 8: khi INSERT không trả dòng, so bản ghi hiện có
SELECT device_a, device_b, attestation
FROM pairs
WHERE pair_id = $1;
```

```text
# [Thiết kế] Redis, API 7: điểm hẹn ghép nối
SADD    rv:<rv_id> <device_id>
EXPIRE  rv:<rv_id> 180
SCARD   rv:<rv_id>          # > 2 → từ chối và SREM thành viên vừa thêm
SMEMBERS rv:<rv_id>         # tìm thành viên còn lại để chuyển rv_msg
```

---

## 2.2 PAIR-02 — Xem danh sách thiết bị và trạng thái kết nối

### 2.2.1 Thông tin chung

| Mục | Nội dung |
|-----|----------|
| Tên | PAIR-02 — Xem danh sách thiết bị và trạng thái kết nối |
| Mô tả | Hiển thị các thiết bị đã ghép nối cùng trạng thái kết nối trực tiếp, kênh đang dùng (LAN, Internet, USB), lần kết nối cuối, phiên bản, tính năng đang hiệu lực và quyền còn thiếu trên điện thoại.<br>Android thấy danh sách tối đa 8 client; Mac/iOS thấy một điện thoại.<br>Từ màn hình này người dùng đi tới PAIR-01 (thêm), PAIR-03 (hủy) hoặc SET-02 (tùy chọn).<br>Đồng thời đối chiếu với relay để phát hiện cặp đã bị thu hồi từ thiết bị khác. |
| Tác nhân | Chính: Người dùng. Hệ thống: A-UI, A-SVC, M-APP / I-APP, R-API. |
| Điều kiện trước | Ứng dụng đã hoàn tất thiết lập ban đầu (SET-01 hoặc SET-03). |
| Điều kiện sau | Danh sách hiển thị khớp dữ liệu cục bộ và trạng thái kết nối hiện tại; cặp bị thu hồi từ xa (nếu phát hiện) được dọn theo PAIR-03. Không thay đổi dữ liệu nào khác. |
| Ngoại lệ | E1 — Chưa có cặp nào: hiển thị trạng thái trống và nút "Thêm thiết bị".<br>E2 — Relay không truy cập được: chỉ hiển thị dữ liệu cục bộ, không báo lỗi chặn.<br>E3 — Relay báo một cặp đã thu hồi: dọn cặp đó (PAIR-03, luồng B) và báo "Thiết bị <tên> đã được hủy ghép nối từ thiết bị khác".<br>E4 — Lỗi đọc cơ sở dữ liệu: báo lỗi và cho thử lại. |
| Yêu cầu đặc biệt | Trạng thái cập nhật trong ≤ 1 s sau khi kết nối thay đổi (theo dõi luồng trạng thái, không hỏi vòng).<br>Không hiển thị khóa, `pair_id` hay dấu vân tay đầy đủ; "Mã an toàn" chỉ là 8 ký tự hex đầu SHA-256(`attestation`) để người dùng đối chiếu giữa hai thiết bị nếu muốn.<br>Đọc được bằng VoiceOver/TalkBack. |

### 2.2.2 Màn hình

N/A — chưa có wireframe được duyệt.

### 2.2.3 Mô tả chi tiết các thành phần

| # | Trường | Kiểu dữ liệu | Input/Output | Giá trị khởi tạo | Mô tả |
|---|--------|--------------|--------------|------------------|-------|
| 1 | Tên thiết bị | string(64) | Output | `peer_name` | Tên đối phương lúc ghép nối |
| 2 | Loại thiết bị | enum{android\| macos\| ios\| ipados} | Output | `peer_platform` hoặc `android` | Kèm biểu tượng |
| 3 | Model | string(64) | Output | `peer_model` |  |
| 4 | Trạng thái kết nối | enum{connected\| connecting\| peer_offline\| disconnected} | Output | Theo 0.11 | "Đã kết nối qua Wi-Fi" (hoặc "qua Internet", "qua USB"), "Đang kết nối…", "Điện thoại ngoại tuyến", "Mất kết nối" |
| 5 | Kênh kết nối | enum{lan\| relay\| usb} | Output | Rỗng khi chưa kết nối | "LAN", "Qua Internet", "USB" |
| 6 | Lần kết nối cuối | timestamp | Output | `last_seen_at` | Hiển thị tương đối ("2 phút trước") |
| 7 | Phiên bản ứng dụng đối phương | string | Output | Từ `capability.app_version` | Cảnh báo nếu khác phiên bản giao thức |
| 8 | Tính năng hiệu lực | array<enum{clipboard\| sms\| call\| call_audio\| camera}> | Output | Giao của hai capability | Mỗi mục kèm lý do nếu không hiệu lực ("Tắt trên Mac", "Thiếu quyền SMS trên điện thoại") |
| 9 | Quyền còn thiếu trên điện thoại | array\<string> | Output | `permissions_missing` | Chỉ trên Mac/iOS; nhấn để xem hướng dẫn |
| 10 | Mã an toàn | string(8) | Output | 8 hex đầu SHA-256(`attestation`) | Giống nhau trên hai thiết bị của cùng cặp |
| 11 | Nút "Thêm thiết bị" | action | Input | — | Mở PAIR-01; ẩn trên Mac/iOS khi đã có cặp |
| 12 | Nút "Hủy ghép nối" | action | Input | — | Mở PAIR-03 |

### 2.2.4 Luồng nghiệp vụ

```mermaid
flowchart TB
  subgraph ND["Người dùng"]
    U1["(1) Mở màn hình Thiết bị"]
    U6["(6) Xem chi tiết hoặc chọn thao tác"]
  end
  subgraph HT["Hệ thống"]
    S2["(2) Đọc paired_device và trạng thái kết nối"]
    D3{"(3) Có cặp nào?"}
    S4["(4) Relay bật và có mạng: GET /v1/pairs"]
    D5{"(5) Có cặp bị thu hồi?"}
    S5a["(5a) Dọn cặp theo PAIR-03 luồng B, báo người dùng"]
    S5b["(5b) Hiển thị danh sách, theo dõi thay đổi trạng thái"]
    X1(["Hiển thị trống và nút Thêm thiết bị"])
  end
  U1 --> S2 --> D3
  D3 -- "Không (E1)" --> X1
  D3 -- "Có" --> S4 --> D5
  D5 -- "Có (E3)" --> S5a --> S5b
  D5 -- "Không hoặc relay lỗi (E2)" --> S5b
  S5b --> U6
```

| Bước | Tác nhân | Thành phần | Mô tả | Ngoại lệ / Ghi chú |
|------|----------|-----------|-------|--------------------|
| 1 | Người dùng | A-UI / M-APP / I-APP | Mở "Thiết bị" (Android: tab Thiết bị; Mac: menu bar → Thiết bị; iOS: tab Cài đặt → Điện thoại). |  |
| 2 | Hệ thống | A-UI / M-APP / I-APP | Đọc `paired_device` hiệu lực; lấy trạng thái từ bộ quản lý kết nối (Android: phiên đang mở theo `pair_id`; client: máy trạng thái 0.11) và capability gần nhất (`features_json`). | Lỗi đọc DB → E4. |
| 3 | Hệ thống | như trên | Không có cặp → hiển thị trạng thái trống. | E1. |
| 4 | Hệ thống | A-SVC / M-APP / I-APP, R-API | Nếu `relay.enabled` và có Internet: gọi `GET /v1/pairs` (tối đa 1 lần mỗi 60 s để tránh gọi thừa). | Lỗi mạng → E2, bỏ qua. |
| 5 | Hệ thống | như trên | So từng cặp cục bộ với kết quả relay: có cặp `revoked_at` khác null → 5a; không có → 5b. | Relay lỗi → E2, sang 5b. |
| 5a | Hệ thống | như trên | Dọn cặp bị thu hồi theo PAIR-03 luồng B (xóa khóa, dữ liệu đồng bộ), báo "Thiết bị <tên> đã được hủy ghép nối từ thiết bị khác". | E3. |
| 5b | Hệ thống | như trên | Hiển thị danh sách và đăng ký nhận thay đổi trạng thái kết nối, capability để cập nhật ≤ 1 s. |  |
| 6 | Người dùng | như trên | Xem chi tiết một thiết bị; chọn "Thêm thiết bị" (PAIR-01), "Hủy ghép nối" (PAIR-03) hoặc "Tùy chọn" (SET-02). |  |

### 2.2.5 Đặc tả API/service

**Danh sách lời gọi**

| # | API/service | Kênh | Chiều | Dùng ở bước |
|---|-------------|------|-------|-------------|
| 1 | `GET /v1/pairs` | REST relay | Thiết bị → R-API | 4 |
| 2 | Luồng trạng thái kết nối nội bộ (Kotlin `StateFlow`, Swift `AsyncStream`) | Cục bộ | — | 2, 5 |

Capability hiển thị ở trường 7–9 lấy từ `capability/hello` và `capability/update` đã nhận trong
CONN-01 và SET-02, không phát sinh lời gọi mới.

#### API 1 — `GET /v1/pairs`

- **URL:** `https://{RELAY_HOST}/v1/pairs`
- **Method:** `GET`, header `Authorization: Bearer <jwt>`
- **Request:** không có body. Tham số truy vấn tùy chọn `include_revoked` (bool, mặc định `true`).
- **Response 200:**

| Trường | Kiểu | Mô tả |
|--------|------|-------|
| `pairs` | array\<object> | Các cặp có thiết bị gọi là thành viên |
| `pairs[].pair_id` | uuid |  |
| `pairs[].peer_device_id` | uuid | Thiết bị còn lại |
| `pairs[].peer_platform` | enum{android\| macos\| ios\| ipados} |  |
| `pairs[].created_at` | timestamp |  |
| `pairs[].revoked_at` | timestamp \| null | Khác null nghĩa là đã thu hồi |
| `pairs[].peer_online` | bool | Đối phương đang nối relay (theo presence) |

- **Ví dụ:**

```json
{"pairs":[{"pair_id":"3f2b1c4d-5e6f-4a7b-8c9d-0e1f2a3b4c5d","peer_device_id":"8c7d6e5f-4a3b-8c2d-9e1f-0a1b2c3d4e5f","peer_platform":"android","created_at":1727150003210,"revoked_at":null,"peer_online":true}]}
```

- **Logic nghiệp vụ:**
  1. Chỉ trả cặp mà `sub` của JWT là `device_a` hoặc `device_b`.
  2. `peer_online` đọc từ khóa `presence:<peer_device_id>` trong Redis.
  3. Cặp có trên thiết bị nhưng **không có** trên relay (khác với có `revoked_at`) không bị coi là
     thu hồi. Nếu `relay_registered = 1` thì đối phương đã tự gỡ khỏi relay ("Xóa thiết bị khỏi máy
     chủ", SET-02) → đặt `relay_registered = 0`, giữ cặp và chỉ dùng LAN/USB. Mọi cặp
     `relay_registered = 0` được thử lại `POST /v1/pairs` (PAIR-01 API 8) khi có mạng; nhận 404
     `DEVICE_NOT_FOUND` (đối phương chưa đăng ký lại) thì thử lại sau 24 h.

#### Query

```sql
-- [Thiết kế] Android, bước 2: danh sách client đã ghép
SELECT pair_id, peer_device_id, peer_name, peer_platform, peer_model,
       features_json, attestation, last_seen_at
FROM paired_device
WHERE revoked_at IS NULL
ORDER BY COALESCE(last_seen_at, created_at) DESC;

-- [Thiết kế] Mac/iOS, bước 2: điện thoại đã ghép
SELECT pair_id, peer_device_id, peer_name, peer_model, features_json,
       attestation, last_seen_at, last_host
FROM paired_device
WHERE revoked_at IS NULL
LIMIT 1;

-- [Thiết kế] Relay, API 1
SELECT p.pair_id,
       CASE WHEN p.device_a = $1 THEN p.device_b ELSE p.device_a END AS peer_device_id,
       d.platform AS peer_platform,
       p.created_at, p.revoked_at
FROM pairs p
JOIN devices d ON d.device_id = CASE WHEN p.device_a = $1 THEN p.device_b ELSE p.device_a END
WHERE (p.device_a = $1 OR p.device_b = $1)
  AND ($2::boolean OR p.revoked_at IS NULL)
ORDER BY p.created_at DESC;
```

```text
# [Thiết kế] Redis, API 1: presence của từng đối phương
MGET presence:<peer_device_id_1> presence:<peer_device_id_2> ...
```

---

## 2.3 PAIR-03 — Hủy ghép nối thiết bị (tại chỗ và từ xa)

### 2.3.1 Thông tin chung

| Mục | Nội dung |
|-----|----------|
| Tên | PAIR-03 — Hủy ghép nối thiết bị (tại chỗ và từ xa) |
| Mô tả | Chấm dứt quan hệ tin cậy của một cặp.<br>**Luồng A (cả hai đang kết nối):** bên khởi tạo gửi `pair/revoke`, bên kia xác nhận, cả hai xóa khóa và dữ liệu.<br>**Luồng B (đối phương không kết nối được, ví dụ máy bị mất):** bên khởi tạo xóa cục bộ và thu hồi trên relay; đối phương tự dọn khi quay lại mạng (relay báo `pair_revoked`, hoặc Android trả `PAIR_UNKNOWN` trong LAN).<br>Dữ liệu đã đồng bộ (SMS, nhật ký cuộc gọi) trên Mac/iOS bị xóa cùng cặp. |
| Tác nhân | Chính: Người dùng. Hệ thống: A-UI, A-SVC, M-APP / I-APP, R-API, R-KV. |
| Điều kiện trước | Có ít nhất một cặp hiệu lực; người dùng đang ở PAIR-02. |
| Điều kiện sau | **Bên khởi tạo:** không còn `PRK`, bản ghi cặp và dữ liệu đồng bộ của cặp; Android bỏ hint của cặp khỏi TXT `h`; relay đánh dấu `revoked_at` (ngay hoặc khi có mạng).<br>**Đối phương:** dọn giống hệt khi nhận được tín hiệu thu hồi. Phiên `/v1/ctl` của cặp bị đóng. |
| Ngoại lệ | E1 — Người dùng hủy ở hộp thoại xác nhận.<br>E2 — Đối phương không phản hồi `ack` trong 10 s → chuyển luồng B.<br>E3 — Relay không truy cập được → giữ bản ghi "bia mộ" (`revoked_at` đặt, dữ liệu và khóa đã xóa), thử thu hồi lại nền mỗi lần có mạng.<br>E4 — Cặp đã bị thu hồi từ trước trên relay → coi là thành công. |
| Yêu cầu đặc biệt | Bảo mật: xóa `PRK` khỏi Keychain/Keystore trước khi báo thành công; không cho hoàn tác (muốn dùng lại phải ghép nối mới).<br>Hộp thoại xác nhận nêu rõ dữ liệu sẽ bị xóa.<br>Hiệu năng: luồng A hoàn tất ≤ 2 s.<br>Thu hồi từ xa có hiệu lực trên relay ngay khi `POST` thành công: relay ngừng chuyển tiếp và push cho cặp đó. |

### 2.3.2 Màn hình

N/A — chưa có wireframe được duyệt.

### 2.3.3 Mô tả chi tiết các thành phần

| # | Trường | Kiểu dữ liệu | Input/Output | Giá trị khởi tạo | Mô tả |
|---|--------|--------------|--------------|------------------|-------|
| 1 | Thiết bị cần hủy | string(64) | Output | Tên thiết bị đang chọn ở PAIR-02 |  |
| 2 | Nội dung cảnh báo | string | Output | "Hủy ghép nối sẽ xóa khóa bảo mật và dữ liệu SMS, nhật ký cuộc gọi đã đồng bộ trên <thiết bị client>. Không thể hoàn tác." |  |
| 3 | Xác nhận hủy | enum{Hủy ghép nối\| Hủy} | Input | — | Mac: alert dạng sheet, "Hủy ghép nối" là nút mặc định (không tô đỏ vì người dùng chủ động chọn), "Hủy" bên trái; iPhone/iPad và Android: hộp chọn hành động, "Hủy ghép nối" màu đỏ ở trên, "Hủy" ở dưới |
| 4 | Kết quả | enum{done\| done_pending_remote} | Output | — | `done`: cả hai bên đã dọn, hiện "Đã hủy ghép nối"; `done_pending_remote`: đã dọn cục bộ, thiết bị kia sẽ tự dọn khi kết nối lại, hiện "Đã hủy ghép nối; <thiết bị> sẽ tự dọn khi kết nối lại" |
| 5 | Thông báo trên đối phương | string | Output | — | "<tên> đã hủy ghép nối với thiết bị này" |

### 2.3.4 Luồng nghiệp vụ

```mermaid
flowchart TB
  subgraph ND["Người dùng"]
    U1["(1) Chọn Hủy ghép nối"]
    U2["(2) Xác nhận trong hộp thoại"]
    U10["(10) Thấy kết quả"]
  end
  subgraph HT["Hệ thống"]
    D3{"(3) Đang có phiên /v1/ctl?"}
    S4["(4) Gửi pair/revoke"]
    D5{"(5) Nhận ack trong 10 s?"}
    S6["(6) Đối phương dọn khóa, dữ liệu, đóng phiên"]
    S7["(7) Bên khởi tạo xóa PRK, dữ liệu, đặt bia mộ"]
    S8["(8) POST /v1/pairs/id/revoke"]
    S9["(9) Relay báo pair_revoked cho đối phương nếu online, xóa bia mộ"]
    X1(["Kết thúc: giữ nguyên"])
  end
  U1 --> U2
  U2 -- "Hủy (E1)" --> X1
  U2 -- "Hủy ghép nối" --> D3
  D3 -- "Có" --> S4 --> D5
  D5 -- "Có" --> S6 --> S7
  D5 -- "Không (E2)" --> S7
  D3 -- "Không (luồng B)" --> S7
  S7 --> S8 --> S9 --> U10
```

| Bước | Tác nhân | Thành phần | Mô tả | Ngoại lệ / Ghi chú |
|------|----------|-----------|-------|--------------------|
| 1 | Người dùng | A-UI / M-APP / I-APP | Tại PAIR-02 chọn "Hủy ghép nối" cho một thiết bị. |  |
| 2 | Người dùng | như trên | Đọc cảnh báo, chọn "Hủy ghép nối". | "Hủy" → E1. |
| 3 | Hệ thống | như trên | Kiểm phiên `/v1/ctl` của cặp (LAN, USB hoặc relay). | Không có → luồng B, sang bước 7. |
| 4 | Hệ thống | như trên | Gửi `pair/revoke` `{pair_id, reason: "user"}` (envelope mã hóa). |  |
| 5 | Hệ thống | như trên | Chờ `ack` tối đa 10 s. | Hết hạn → E2, luồng B. |
| 6 | Hệ thống | Thiết bị đối phương | Trả `ack`, rồi dọn như bước 7 phía mình; hiển thị trường 5; gửi `session/bye` và đóng 1000. |  |
| 7 | Hệ thống | Bên khởi tạo | Xóa `PRK` (Keychain `SecItemDelete` / xóa cột `prk_enc`), xóa dữ liệu đồng bộ của cặp (client), đặt `revoked_at`; Android đăng ký lại mDNS không còn hint của cặp. |  |
| 8 | Hệ thống | Bên khởi tạo, R-API | Nếu cặp đã đăng ký relay: `POST /v1/pairs/{pair_id}/revoke`. | Không có mạng → E3, giữ bia mộ, thử lại nền. Relay trả đã thu hồi → E4. |
| 9 | Hệ thống | R-API, R-KV | Relay đặt `revoked_at`, ngừng chuyển tiếp và push; nếu đối phương đang nối relay, gửi op `pair_revoked` để nó dọn ngay. Bên khởi tạo xóa hẳn bản ghi bia mộ. | Đối phương offline: sẽ nhận `pair_revoked` khi kết nối relay, hoặc thấy qua `GET /v1/pairs` (PAIR-02), hoặc bị Android từ chối `session/hello` với `PAIR_UNKNOWN` trong LAN. |
| 10 | Người dùng | như trên | Thấy kết quả `done` hoặc `done_pending_remote`. |  |

### 2.3.5 Đặc tả API/service

**Danh sách lời gọi**

| # | API/service | Kênh | Chiều | Dùng ở bước |
|---|-------------|------|-------|-------------|
| 1 | `WS pair/revoke` | `/v1/ctl` (LAN, USB hoặc relay) | Hai chiều | 4, 5, 6 |
| 2 | `WS session/bye` | `/v1/ctl` | Hai chiều | 6 |
| 3 | `POST /v1/pairs/{pair_id}/revoke` | REST relay | Thiết bị → R-API | 8 |
| 4 | Relay op `pair_revoked` | `wss://{RELAY_HOST}/v1/relay` (text) | R-API → thiết bị | 9 |
| 5 | Dịch vụ hệ điều hành: `SecItemDelete` (Keychain), `NsdManager.unregisterService` + `registerService` | Cục bộ | — | 7 |

#### API 1 — `WS pair/revoke`

- **URL:** `wss://{android_host}:{port}/v1/ctl` hoặc qua relay
- **Method:** `WS pair/revoke` (hai chiều), envelope mã hóa, có ack.
- **Request (`data`):**

| Trường | Kiểu | Bắt buộc | Mô tả |
|--------|------|----------|-------|
| `pair_id` | uuid | Có | Phải trùng cặp của phiên hiện tại |
| `reason` | enum{user\| reinstall\| limit} | Có | `user`: người dùng chủ động; `reinstall`: xóa dữ liệu ứng dụng; `limit`: thay cặp cũ khi ghép mới |

- **Response (`ack.data`):** `{}` khi `ok = true`. Lỗi: `BAD_REQUEST` nếu `pair_id` không khớp
  phiên.
- **Ví dụ:**

```json
{"op":"revoke","data":{"pair_id":"3f2b1c4d-5e6f-4a7b-8c9d-0e1f2a3b4c5d","reason":"user"}}
{"re":"0192f3d8-2b11-7c42-8e5a-6b7c8d9e0f12","ok":true,"data":{}}
```

- **Logic nghiệp vụ:**
  1. Bên nhận trả `ack` **trước** khi xóa khóa (vì sau khi xóa không mã hóa được nữa).
  2. Sau `ack`, bên nhận dọn dữ liệu và gửi `session/bye` `{reason: "revoked"}`, đóng mã 1000.
  3. Không cho phép "từ chối" hủy ghép nối: bất kỳ bên nào cũng có quyền đơn phương hủy.

#### API 2 — `WS session/bye`

- **URL:** như API 1
- **Method:** `WS session/bye` (hai chiều), envelope mã hóa, không ack.
- **Request (`data`):** `reason` — enum{revoked\|shutdown\|replaced\|update}.
- **Response:** N/A; bên gửi đóng WebSocket với mã 1000.
- **Ví dụ:** `{"op":"bye","data":{"reason":"revoked"}}`
- **Logic nghiệp vụ:** Bên nhận `reason = revoked` dọn cặp nếu chưa dọn (phòng khi mất
  `pair/revoke`).

#### API 3 — `POST /v1/pairs/{pair_id}/revoke`

- **URL:** `https://{RELAY_HOST}/v1/pairs/{pair_id}/revoke`
- **Method:** `POST`, header `Authorization: Bearer <jwt>`
- **Request:**

| Trường | Kiểu | Bắt buộc | Mô tả |
|--------|------|----------|-------|
| `reason` | enum{user\| reinstall\| lost_device} | Có | `lost_device` khi người dùng chọn hủy từ xa lúc đối phương offline |

- **Response:**

| HTTP | Body | Khi nào |
|------|------|---------|
| 204 | — | Thu hồi thành công hoặc đã thu hồi từ trước (idempotent) |
| 403 `NOT_PAIRED` | lỗi | Người gọi không thuộc cặp |
| 404 `DEVICE_NOT_FOUND` | lỗi | `pair_id` không tồn tại → coi như thành công ở phía thiết bị |

- **Ví dụ:**

```http
POST /v1/pairs/3f2b1c4d-5e6f-4a7b-8c9d-0e1f2a3b4c5d/revoke HTTP/1.1
Host: relay.example.com
Authorization: Bearer <jwt>
Content-Type: application/json

{"reason":"lost_device"}
```

- **Logic nghiệp vụ:**
  1. Chỉ thành viên của cặp được thu hồi.
  2. Cập nhật `revoked_at`, `revoked_by`; nếu đã thu hồi thì không đổi, vẫn trả 204.
  3. Tra `presence:<đối phương>`; nếu online, publish `pair_revoked` lên kênh `dev:<đối phương>`.
  4. Từ thời điểm này relay từ chối mọi khung `to` /`from` giữa hai thiết bị của cặp (`relay.error
     NOT_PAIRED`) và từ chối `POST /v1/push` cho cặp.

#### API 4 — Relay op `pair_revoked`

- **URL:** `wss://{RELAY_HOST}/v1/relay`
- **Method:** WS text frame điều khiển (R-API → thiết bị). Bổ sung vào danh mục 0.7.3.
- **Request:** `{"op":"pair_revoked","pair_id":"<uuid>","by":"<device_id>"}`
- **Response:** N/A.
- **Ví dụ:**
  `{"op":"pair_revoked","pair_id":"3f2b1c4d-5e6f-4a7b-8c9d-0e1f2a3b4c5d","by":"8c7d6e5f-4a3b-8c2d-9e1f-0a1b2c3d4e5f"}`
- **Logic nghiệp vụ:**
  1. Thiết bị nhận dọn cặp như bước 7 và hiển thị trường 5; nhận lặp lại thì bỏ qua.
  2. Ngay sau khi một thiết bị kết nối relay, relay gửi `pair_revoked` cho mọi cặp đã thu hồi trong
     30 ngày mà thiết bị là thành viên, để thiết bị offline lúc bị thu hồi vẫn tự dọn.

#### Query

```sql
-- [Thiết kế] Android, bước 7: đặt bia mộ và xóa khóa
UPDATE paired_device
SET revoked_at = :now, prk_enc = X'', features_json = '{}'
WHERE pair_id = :pair_id;

-- [Thiết kế] Android, bước 9: xóa hẳn khi relay đã xác nhận hoặc cặp chưa từng đăng ký relay
DELETE FROM paired_device
WHERE pair_id = :pair_id AND revoked_at IS NOT NULL;

-- [Thiết kế] Mac/iOS, bước 7 (một giao dịch): xóa dữ liệu đồng bộ và đặt bia mộ
DELETE FROM sms_message    WHERE pair_id = :pair_id;
DELETE FROM sms_thread     WHERE pair_id = :pair_id;
DELETE FROM sms_outbox     WHERE pair_id = :pair_id;
DELETE FROM call_log_entry WHERE pair_id = :pair_id;
DELETE FROM sync_cursor    WHERE pair_id = :pair_id;
UPDATE paired_device SET revoked_at = :now WHERE pair_id = :pair_id;

-- [Thiết kế] Mọi nền tảng: tìm bia mộ cần thu hồi lại trên relay (chạy khi có mạng)
SELECT pair_id FROM paired_device
WHERE revoked_at IS NOT NULL AND relay_registered = 1;

-- [Thiết kế] Relay, API 3
UPDATE pairs
SET revoked_at = now(), revoked_by = $2
WHERE pair_id = $1
  AND (device_a = $2 OR device_b = $2)
  AND revoked_at IS NULL
RETURNING CASE WHEN device_a = $2 THEN device_b ELSE device_a END AS peer_device_id;

-- [Thiết kế] Relay, API 4: cặp đã thu hồi trong 30 ngày của thiết bị vừa kết nối
SELECT pair_id, revoked_by
FROM pairs
WHERE (device_a = $1 OR device_b = $1)
  AND revoked_at > now() - INTERVAL '30 days';
```

```text
# [Thiết kế] Redis, API 3: báo đối phương đang online
GET     presence:<peer_device_id>
PUBLISH dev:<peer_device_id> {"op":"pair_revoked","pair_id":"<pair_id>","by":"<device_id>"}
```
