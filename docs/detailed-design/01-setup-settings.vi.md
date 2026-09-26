[English](01-setup-settings.md) | Tiếng Việt

# 1. Nhóm chức năng: Thiết lập và cài đặt

> Tham chiếu chung: [`00-common-specs.md`](00-common-specs.vi.md) — thành phần (0.1), định danh
> `device_id` (0.2), kênh LAN và relay (0.4), khóa và nguyên tắc bảo mật (0.6.1, 0.6.5), xác thực
> relay (0.6.4), capability và `permissions_missing` (0.7.2), tin điều khiển và REST của relay
> (0.7.3, 0.7.4), mã lỗi (0.8), lược đồ (0.9), khóa cài đặt (0.9.5), hằng số (0.10). Quyết định áp
> dụng: README §5 C7, C10, C11, C12, C13, C15. Khóa mới của nhóm (đề xuất bổ sung 0.9.5):
> `setup.started_at`, `setup.completed_at` (mọi nền tảng), `perm.requested` (Android).

## 1.1 SET-01 — Thiết lập ban đầu và cấp quyền trên Android

### 1.1.1 Thông tin chung

| Mục | Nội dung |
|-----|----------|
| Tên | SET-01 — Thiết lập ban đầu và cấp quyền trên Android |
| Mô tả | Gồm hai phần.<br>**Phần A — lần chạy đầu:** màn hình chào mừng kèm giải thích ngắn về quyền riêng tư; tạo khóa định danh, `device_id` và chứng chỉ TLS (0.6.1); xin `POST_NOTIFICATIONS` (Android 13+); khởi động `HandLiveService` (A-SVC) dạng foreground service type `connectedDevice` với thông báo thường trực mức thấp; xin miễn tối ưu pin (`ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS`) và hướng dẫn cho phép tự khởi chạy theo hãng (Xiaomi, OPPO/realme, Samsung "Ứng dụng không bao giờ ngủ"); rồi chuyển sang PAIR-01.<br>**Phần B — cấp quyền đúng lúc theo tính năng:** quyền của một tính năng chỉ được xin khi người dùng bật hoặc dùng tính năng đó: quét QR cần `CAMERA`; tự gửi clipboard cần công bố, đồng ý và bật dịch vụ Hỗ trợ tiếp cận (C15, CLIP-01); SMS cần `READ_SMS`, `SEND_SMS`, `READ_CONTACTS`, `READ_PHONE_STATE` (không xin `RECEIVE_SMS`); cuộc gọi cần `READ_PHONE_STATE`, `READ_CALL_LOG`, `ANSWER_PHONE_CALLS`, `READ_CONTACTS` (C12, không dùng `InCallService`); âm thanh cuộc gọi cần `BLUETOOTH_CONNECT`, Shizuku tùy chọn cho đường Opus/WS (AUDIO-01, C13); phát camera cần `CAMERA`, `RECORD_AUDIO`.<br>Quyền bị từ chối làm tính năng đó không hiệu lực (hoặc hiệu lực một phần) và được liệt kê trong `permissions_missing`; tính năng khác không bị ảnh hưởng. |
| Tác nhân | Chính: Người dùng (chủ điện thoại). Hệ thống: A-UI, A-SVC, A-CLIP (`ClipboardAccessibilityService`), OS (trình cấp quyền của Android, `PowerManager`, Cài đặt hệ thống và cài đặt riêng của hãng), R-API (đăng ký thiết bị). |
| Điều kiện trước | **Phần A:** HandLive vừa được cài (Google Play, F-Droid hoặc APK) trên Android 10+ (API 29+); chưa có `setup.completed_at`.<br>**Phần B:** phần A đã xong; người dùng bấm "Quét mã QR" (PAIR-01), bật một tính năng (SET-02), bấm "Cấp quyền" trên thẻ tính năng, hoặc chạm thông báo gợi ý cấp quyền. |
| Điều kiện sau | **Phần A:** có khóa định danh, `device_id`, chứng chỉ TLS; A-SVC chạy foreground với thông báo thường trực, lắng nghe cổng 47800 (0.4.1) và quảng bá mDNS; miễn tối ưu pin đã được hỏi; `setup.completed_at` được ghi; thiết bị đã đăng ký relay nếu `relay.enabled = true` và có mạng (hoặc chờ thử lại nền); giao diện chuyển sang PAIR-01.<br>**Phần B:** mỗi quyền của tính năng ở trạng thái cấp hoặc từ chối; `permissions_missing` và các cờ con của capability (`can_send`, `sims`, `caller_id`, `can_answer`, `can_end`, `auto_send`) khớp thực tế; mọi client đang kết nối đã nhận `capability/update` nếu có thay đổi. |
| Ngoại lệ | E1 — Từ chối `POST_NOTIFICATIONS`: A-SVC vẫn chạy (thông báo dịch vụ chỉ còn trong Trình quản lý tác vụ của Android) nhưng không hiện trạng thái kết nối, gợi ý cấp quyền và yêu cầu xác nhận camera (CAM-02); ứng dụng hiện dải cảnh báo "Thông báo đang tắt: không thấy trạng thái kết nối và yêu cầu từ Mac." kèm nút mở cài đặt thông báo.<br>E2 — Không khởi động được foreground service (`ForegroundServiceStartNotAllowedException` khi ứng dụng không ở foreground và chưa được miễn tối ưu pin, hoặc `SecurityException` do thiếu khai báo type): thử lại khi A-UI ở foreground; vẫn lỗi → báo "Không khởi động được dịch vụ kết nối", nút "Thử lại".<br>E3 — Từ chối miễn tối ưu pin hoặc bỏ qua hướng dẫn hãng: vẫn dùng được nhưng kết nối có thể bị ngắt khi máy ngủ (CONN-02 E6); cảnh báo giữ trong Cài đặt › Quyền và chạy nền.<br>E4 — Quyền của một tính năng bị từ chối: tính năng không hiệu lực hoặc hiệu lực một phần (ví dụ `can_send = false`), quyền vào `permissions_missing`.<br>E5 — Quyền bị từ chối vĩnh viễn (hệ thống không hiện hộp thoại nữa): hiện nút "Mở cài đặt" tới trang Thông tin ứng dụng.<br>E6 — Không đồng ý công bố Hỗ trợ tiếp cận: `clip.auto_send = false`; gửi thủ công (nút trên thông báo, ô Cài đặt nhanh, menu Chia sẻ) vẫn hoạt động (CLIP-01 E1).<br>E7 — Bản cài ngoài Google Play trên Android 13+ bị chặn bật dịch vụ Hỗ trợ tiếp cận ("Chế độ cài đặt bị hạn chế"): hướng dẫn cho phép trong Thông tin ứng dụng rồi quay lại.<br>E8 — Quay lại từ cài đặt Hỗ trợ tiếp cận mà dịch vụ chưa bật: giữ trạng thái "Chưa bật tự gửi", cho thử lại.<br>E9 — Tạo khóa thất bại (Keystore lỗi): thử lại với khóa trong TEE khi StrongBox không khả dụng; vẫn lỗi → báo lỗi, không cho sang PAIR-01.<br>E10 — Không có mạng hoặc relay lỗi khi đăng ký thiết bị: bỏ qua, thử lại nền (CONN-03), không chặn thiết lập. |
| Yêu cầu đặc biệt | **Tuân thủ Google Play:** nộp Permissions Declaration Form cho `READ_SMS`, `SEND_SMS`, `READ_CALL_LOG` theo ngoại lệ "Cross-device synchronization or transfer of SMS or calls"; không khai báo `RECEIVE_SMS` (tin mới phát hiện bằng `ContentObserver`); khai báo dùng Accessibility API (`isAccessibilityTool = false`) kèm công bố nổi bật và đồng ý trong ứng dụng — rủi ro bị từ chối đã được chủ dự án chấp nhận (C15); khai báo foreground service type `connectedDevice` trong Play Console; dùng `REQUEST_IGNORE_BATTERY_OPTIMIZATIONS` với lý do ứng dụng đồng hành phải giữ kết nối với thiết bị đã ghép.<br>**Quyền riêng tư:** không xin quyền tính năng trong phần A; mỗi hộp thoại hệ thống đi sau một câu giải thích; mỗi lần chỉ xin quyền của một tính năng.<br>**Khả dụng:** phần A ≤ 5 màn hình, hoàn tất ≤ 60 s (không tính thao tác trong cài đặt của hãng); đọc được bằng TalkBack; mọi bước sau màn hình chào mừng đều bỏ qua được; không cần ADB, USB hay Shizuku.<br>**Tương thích:** minSdk 29, targetSdk 35 — `POST_NOTIFICATIONS` chỉ có từ API 33; `BLUETOOTH_CONNECT` từ API 31 (API 29–30 dùng `BLUETOOTH` cấp lúc cài); `FOREGROUND_SERVICE_CONNECTED_DEVICE` bắt buộc từ API 34.<br>**Độc lập tính năng:** thiếu quyền một tính năng không chặn tính năng khác (CONN-01 API 7). |

### 1.1.2 Màn hình

N/A — chưa có wireframe được duyệt.

### 1.1.3 Mô tả chi tiết các thành phần

| # | Trường | Kiểu dữ liệu | Input/Output | Giá trị khởi tạo | Mô tả |
|---|--------|--------------|--------------|------------------|-------|
| 1 | Giới thiệu và quyền riêng tư | string | Output | Nội dung cố định | "HandLive nối điện thoại này với Mac, iPhone, iPad của bạn. Dữ liệu được mã hóa đầu-cuối và chỉ đi giữa các thiết bị bạn đã ghép; máy chủ không đọc được nội dung. Không cần tài khoản." Kèm liên kết "HandLive và quyền riêng tư của bạn" mở trang theo ngôn ngữ đang hiển thị: https://github.com/HandLive/handlive/blob/main/docs/privacy.vi.md (tiếng Việt), https://github.com/HandLive/handlive/blob/main/docs/privacy.md (tiếng Anh) |
| 2 | Nút "Bắt đầu" | action | Input | — | Sang bước 3 |
| 3 | Quyền thông báo | enum{granted\| denied\| not_required} | Input/Output | `not_required` (API 29–32) hoặc theo `checkSelfPermission` | Android 13+ hỏi ở bước 3; `denied` hiện dải cảnh báo và nút "Mở cài đặt thông báo" (E1) |
| 4 | Trạng thái dịch vụ kết nối | enum{running\| stopped\| failed} | Output | `stopped` | `running` sau bước 5; `failed` theo E2 |
| 5 | Thông báo thường trực của A-SVC | string | Output | "Đang chờ kết nối" | Kênh `hl_service` ("Dịch vụ kết nối", mô tả "Trạng thái kết nối với Mac, iPhone, iPad và nút Gửi bảng nhớ tạm."), `IMPORTANCE_LOW`; nội dung cập nhật theo CONN-01 trường 6; có nút "Gửi bảng nhớ tạm" (CLIP-01 trường 4) |
| 6 | Chạy nền không bị giới hạn | enum{exempt\| not_exempt} | Input/Output | Theo `PowerManager.isIgnoringBatteryOptimizations` | Nút "Tiếp tục" mở hộp thoại hệ thống (API 4); `not_exempt` giữ cảnh báo ở Cài đặt › Quyền và chạy nền (E3) |
| 7 | Tạm dừng hoạt động nếu không dùng | enum{enabled\| disabled\| not_available} | Input/Output | Theo `PackageManagerCompat.getUnusedAppRestrictionsStatus` | Android 11+: gợi ý tắt để hệ thống không tự thu hồi quyền khi người dùng lâu không mở HandLive trên điện thoại (API 4) |
| 8 | Hướng dẫn tự khởi chạy theo hãng | string | Output | Theo `Build.MANUFACTURER` | Các bước riêng cho Xiaomi/Redmi/POCO, OPPO/realme/OnePlus, Samsung (API 5); ẩn với hãng khác |
| 9 | Nút "Mở cài đặt của hãng", "Đã xong", "Bỏ qua" | action | Input | — | "Mở cài đặt của hãng" mở màn hình của hãng (API 5); "Đã xong" và "Bỏ qua" sang bước 7 |
| 10 | Danh sách tính năng | array\<object> | Output | Theo khóa `feature.*` (0.9.5) và quyền hiện có | Mỗi thẻ: tên tính năng, trạng thái `ready` \| `needs_permission` \| `permanently_denied` \| `off` \| `unsupported`, quyền còn thiếu. Hiện sau PAIR-01 lần đầu và ở Cài đặt › Quyền và chạy nền<br>Tên thẻ là nhãn công tắc của SET-02: "Tự gửi khi sao chép", "Tin nhắn SMS", "Cuộc gọi", "Nghe gọi trên Mac", "Dùng điện thoại làm webcam". Chữ trạng thái: `ready` "Bật", `needs_permission` "Cần cấp quyền" (kèm trường 11), `permanently_denied` "Quyền bị từ chối" (kèm trường 16), `off` "Tắt", `unsupported` "Điện thoại này không hỗ trợ". Thẻ "Tự gửi khi sao chép" lấy trạng thái từ trường 15: `needs_accessibility` hiện "Chưa bật tự gửi" (E8) |
| 11 | Nút "Cấp quyền" trên thẻ tính năng | action | Input | Hiện khi thẻ ở `needs_permission` | Chạy phần B cho đúng tính năng đó |
| 12 | Giải thích trước khi xin quyền | string | Output | Theo tính năng (API 2) | Ví dụ SMS: "Để xem và trả lời SMS trên Mac hoặc iPhone, HandLive cần đọc và gửi SMS, đọc danh bạ để hiện tên người gửi và đọc trạng thái điện thoại để chọn SIM."<br>Tiêu đề: SMS "Dùng SMS trên Mac và iPhone", thông báo "Nhận thông báo về kết nối và yêu cầu", chạy nền "Chạy trong nền", tự khởi chạy của hãng "Giữ HandLive luôn chạy", camera "Quét mã ghép nối" (nội dung "HandLive dùng camera để quét mã QR trên Mac, iPhone hoặc iPad.") |
| 13 | Công bố Hỗ trợ tiếp cận | string | Output | Văn bản CLIP-01 trường 2 | Hiện toàn màn hình, lựa chọn "Gửi thủ công" / "Đồng ý" theo CLIP-01 trường 3 |
| 14 | Hướng dẫn "Chế độ cài đặt bị hạn chế" | string | Output | Ẩn | Hiện khi Android 13+ và nguồn cài không phải Google Play (API 6, E7) |
| 15 | Trạng thái tự gửi clipboard | enum{on\| off\| needs_accessibility} | Output | `needs_accessibility` | `on` khi `clip.auto_send = true`, đã có `clip.a11y_consent_at` và dịch vụ Hỗ trợ tiếp cận đang chạy; `off` khi `clip.auto_send = false` |
| 16 | Nút "Mở cài đặt" | action | Input | Hiện khi có quyền bị từ chối vĩnh viễn | Mở trang Thông tin ứng dụng của HandLive (E5) |
| 17 | Thông báo gợi ý cấp quyền | string | Output | — | A-SVC đăng khi trả `PERMISSION_MISSING` cho client: "MacBook của Lan cần quyền đọc SMS trên điện thoại — chạm để cho phép"; tối đa 1 lần mỗi tính năng mỗi 24 h; kênh `permission` ("Quyền", mô tả "Gợi ý cấp quyền khi Mac hoặc iPhone cần một tính năng trên điện thoại.", `IMPORTANCE_LOW`) |
| 18 | Thông báo lỗi | string | Output | Rỗng | Nội dung theo E1–E10 |

### 1.1.4 Luồng nghiệp vụ

```mermaid
flowchart TB
  subgraph ND["Người dùng"]
    U1["(1) Mở HandLive lần đầu, bấm Bắt đầu"]
    U4["(4) Cho phép hoặc từ chối thông báo"]
    U6["(6) Cho phép chạy nền, làm theo hướng dẫn hãng"]
    U8["(8) Quét QR, bật tính năng hoặc bấm Cấp quyền"]
    U11["(11) Cho phép hoặc từ chối trong hộp thoại hệ thống"]
    U13["(13) Đồng ý công bố, bật HandLive trong Hỗ trợ tiếp cận"]
  end
  subgraph HT["Hệ thống"]
    S2["(2) Tạo khóa định danh, device_id, chứng chỉ TLS"]
    S3["(3) Giải thích, hỏi POST_NOTIFICATIONS nếu Android 13+"]
    S5["(5) Khởi động HandLiveService connectedDevice, xin miễn tối ưu pin"]
    S7["(7) Lưu setup.completed_at, đăng ký relay nền, chuyển PAIR-01"]
    D9{"(9) Tính năng cần gì?"}
    S10["(10) Lọc quyền còn thiếu, giải thích, mở hộp thoại hệ thống"]
    S12["(12) Hiện công bố, hướng dẫn cài đặt bị hạn chế, mở Hỗ trợ tiếp cận"]
    S14["(14) Tính lại permissions_missing và auto_send, gửi capability/update"]
    X1(["Kết thúc: báo lỗi, cho thử lại"])
  end
  U1 --> S2
  S2 -- "Lỗi Keystore (E9)" --> X1
  S2 --> S3
  S3 -- "Android 13+" --> U4
  S3 -- "Android 10 đến 12" --> S5
  U4 -- "Cho phép hoặc từ chối (E1)" --> S5
  S5 -- "Lỗi dịch vụ (E2)" --> X1
  S5 --> U6
  U6 -- "Xong hoặc bỏ qua (E3)" --> S7
  S7 --> U8 --> D9
  D9 -- "Quyền runtime" --> S10 --> U11
  S10 -- "Từ chối vĩnh viễn (E5)" --> S14
  U11 -- "Cho phép hoặc từ chối (E4)" --> S14
  D9 -- "Tự gửi khi sao chép" --> S12 --> U13
  U13 -- "Bật, chưa bật hoặc không đồng ý (E6, E7, E8)" --> S14
```

| Bước | Tác nhân | Thành phần | Mô tả | Ngoại lệ / Ghi chú |
|------|----------|-----------|-------|--------------------|
| 1 | Người dùng | A-UI | Mở HandLive. A-UI đọc `setup.completed_at`: rỗng → màn hình chào mừng (trường 1); đã có → màn hình chính (bỏ qua phần A). Người dùng đọc giới thiệu, bấm "Bắt đầu" (trường 2). | Phần A bị gián đoạn → lần mở sau chạy lại từ đầu; mỗi bước tự bỏ qua nếu đã đạt (quyền đã cấp, dịch vụ đang chạy, đã được miễn tối ưu pin). |
| 2 | Hệ thống | A-UI | Chạy nền ngay khi màn hình chào mừng hiện: chưa có keyset → tạo `ik_sig` (Ed25519), `ik_dh` (X25519) bằng Tink, bọc bởi khóa master AES-256 trong Android Keystore (StrongBox nếu có); tính `device_id` = UUIDv8(SHA-256(`ik_sig_pub`)) (0.2); tạo khóa ECDSA P-256 và chứng chỉ TLS tự ký hạn 20 năm (API 1).<br>Ghi `setup.started_at`. | Keyset đã có → nạp, không tạo lại. StrongBox lỗi → TEE; vẫn lỗi → E9. |
| 3 | Hệ thống | A-UI | Android 13+ và chưa có `POST_NOTIFICATIONS`: hiện giải thích "Thông báo cho bạn biết trạng thái kết nối và để bạn xác nhận yêu cầu từ Mac, ví dụ bật camera", rồi xin quyền (API 2). Android 10–12: thông báo được phép sẵn, sang bước 5. |  |
| 4 | Người dùng | OS | Chọn "Cho phép" hoặc "Không cho phép" trong hộp thoại hệ thống. | Từ chối → E1, vẫn sang bước 5. |
| 5 | Hệ thống | A-UI → A-SVC, OS | (a) Khởi động A-SVC: `startForegroundService`, trong 5 s gọi `startForeground` với type `connectedDevice` và thông báo kênh `hl_service` (API 3); A-SVC mở WSS trên cổng 47800–47809 và quảng bá mDNS (CONN-01 API 1). (b) Chưa được miễn tối ưu pin → giải thích "Để Mac và iPhone luôn tới được điện thoại, HandLive cần chạy nền mà không bị hệ thống ngắt", mở hộp thoại `ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS` (API 4). (c) Android 11+ và trường 7 = `enabled` → gợi ý tắt "Tạm dừng hoạt động nếu không dùng" (API 4). (d) Hãng thuộc bảng cấu hình → hiện hướng dẫn tự khởi chạy (trường 8, API 5). | Không khởi động được → E2. |
| 6 | Người dùng | OS, A-UI | Cho phép chạy nền trong hộp thoại hệ thống; làm theo hướng dẫn của hãng rồi bấm "Đã xong", hoặc bấm "Bỏ qua". | Từ chối hoặc bỏ qua → E3, vẫn sang bước 7. |
| 7 | Hệ thống | A-UI, A-SVC → R-API | Ghi `setup.completed_at`. Nếu `relay.enabled = true` và có Internet: chạy nền `POST /v1/devices` (CONN-03 API 1), rồi đăng ký push token FCM (CONN-04 bước 2). Chuyển sang PAIR-01 (màn hình "Ghép nối thiết bị" với "Quét mã QR" và "Nhập mã PIN"). | Relay lỗi → E10. |
| 8 | Người dùng | A-UI | Bắt đầu phần B: bấm "Quét mã QR" (PAIR-01 bước 3), bật một tính năng ở SET-02, bấm "Cấp quyền" trên thẻ tính năng (trường 11) hoặc chạm thông báo gợi ý (trường 17).<br>Sau PAIR-01 lần đầu, A-UI mở danh sách tính năng (trường 10) để người dùng cấp quyền cho các tính năng mặc định bật: clipboard (tự gửi), SMS, cuộc gọi. | Máy không có `FEATURE_TELEPHONY` → thẻ SMS, cuộc gọi ở `unsupported` và capability báo `enabled = false`; không có camera (`FEATURE_CAMERA_ANY`) → tương tự với camera. |
| 9 | Hệ thống | A-UI | Tra bảng quyền theo tính năng (API 2): quét QR, SMS, cuộc gọi, âm thanh cuộc gọi (chỉ `BLUETOOTH_CONNECT`; Shizuku thuộc AUDIO-01 bước 10–11), camera → bước 10; tự gửi clipboard → bước 12. |  |
| 10 | Hệ thống | A-UI | Lọc quyền chưa cấp (`checkSelfPermission`).<br>Quyền có trong `perm.requested`, chưa cấp và `shouldShowRequestPermissionRationale = false` → từ chối vĩnh viễn: hiện trường 16 thay cho hộp thoại.<br>Còn lại: hiện giải thích (trường 12), gọi `RequestMultiplePermissions` cho các quyền còn thiếu của tính năng, thêm chúng vào `perm.requested`. | E5 → bước 14 khi người dùng quay lại từ cài đặt. |
| 11 | Người dùng | OS | Cho phép hoặc từ chối từng nhóm quyền; hệ thống gộp hộp thoại theo nhóm (SMS, Danh bạ, Điện thoại, Nhật ký cuộc gọi, Camera, Micro, Thiết bị ở gần). | Từ chối → E4. |
| 12 | Hệ thống | A-UI | Chạy CLIP-01 A2: hiện công bố (trường 13); "Đồng ý" → ghi `clip.a11y_consent_at`. Trước khi mở `ACTION_ACCESSIBILITY_SETTINGS`: Android 13+ và nguồn cài không phải Google Play → hiện trường 14 (API 6). | "Không" → E6, sang bước 14. |
| 13 | Người dùng | OS | Trong Cài đặt › Hỗ trợ tiếp cận chọn HandLive, bật dịch vụ, xác nhận hộp thoại cấp quyền kiểm soát của hệ thống, rồi quay lại HandLive. | Hệ thống báo "Chế độ cài đặt bị hạn chế" → E7. Quay lại mà chưa bật → E8. |
| 14 | Hệ thống | A-UI, A-SVC, A-CLIP | Tính lại `permissions_missing` và các cờ con theo bảng API 2; cập nhật trường 10, 15.<br>Có thay đổi và có client đang kết nối → gửi `capability/update` (SET-02 API 1); hai bên tính lại tính năng hiệu lực (CONN-01 API 7).<br>Với quét QR: có `CAMERA` → mở khung quét (PAIR-01 bước 3); bị từ chối → PAIR-01 E9 (dùng PIN). | A-SVC cũng tính lại khi khởi động, khi A-UI `onResume` và khi dịch vụ Hỗ trợ tiếp cận nối/ngắt (CLIP-01 A3). |

### 1.1.5 Đặc tả API/service

**Danh sách lời gọi**

| # | API/service | Kênh | Chiều | Dùng ở bước |
|---|-------------|------|-------|-------------|
| 1 | Tạo khóa định danh và chứng chỉ TLS (Tink, Android Keystore) | Cục bộ | — | 2 |
| 2 | Xin quyền runtime: `ActivityResultContracts.RequestPermission` / `RequestMultiplePermissions` | Cục bộ | — | 3, 4, 10, 11, 14 |
| 3 | `ServiceCompat.startForeground(…, FOREGROUND_SERVICE_TYPE_CONNECTED_DEVICE)` | Cục bộ | — | 5 |
| 4 | `Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS`, `IntentCompat.createManageUnusedAppRestrictionsIntent` | Cục bộ | — | 5, 6 |
| 5 | Màn hình tự khởi chạy của hãng, dự phòng `Settings.ACTION_APPLICATION_DETAILS_SETTINGS` | Cục bộ | — | 5, 6, 10 |
| 6 | `Settings.ACTION_ACCESSIBILITY_SETTINGS`, `AccessibilityManager.getEnabledAccessibilityServiceList`, `PackageManager.getInstallSourceInfo` | Cục bộ | — | 12, 13, 14 |
| 7 | `WS capability/update` | `/v1/ctl` (LAN, USB hoặc relay) | S→C | 14 |
| 8 | `POST /v1/devices` | REST relay | A-SVC → R-API | 7 |

#### API 1 — Tạo khóa định danh và chứng chỉ TLS

- **URL:** N/A
- **Method:** `KeyGenerator.getInstance("AES", "AndroidKeyStore")` với
  `KeyGenParameterSpec.Builder("hl_master", PURPOSE_ENCRYPT or PURPOSE_DECRYPT).setIsStrongBoxBacked(true)`;
  `AndroidKeysetManager.Builder().withSharedPref(context, "hl_secret_keyset", "handlive_keyset").withMasterKeyUri("android-keystore://hl_master")`;
  `Ed25519Sign.KeyPair.newKeyPair()`; `X25519.generatePrivateKey()`;
  `KeyPairGenerator.getInstance("EC")` với `ECGenParameterSpec("secp256r1")`.
- **Request:**

| Thành phần | Thuật toán / thuộc tính | Nơi lưu |
|-----------|------------------------|---------|
| Khóa master | AES-256-GCM, alias `hl_master`; StrongBox khi có `FEATURE_STRONGBOX_KEYSTORE` | Android Keystore |
| Keyset AEAD | Tink `AES256_GCM`, bọc bởi `hl_master` | SharedPreferences `handlive_keyset` |
| `ik_sig` | Ed25519 | Khóa riêng mã hóa bằng keyset AEAD |
| `ik_dh` | X25519 | Như `ik_sig` |
| Khóa TLS | ECDSA P-256, chứng chỉ X.509 tự ký `CN=HandLive`, hạn 20 năm | PKCS#12 trong bộ nhớ trong; mật khẩu 32 byte ngẫu nhiên mã hóa bằng keyset AEAD (0.6.1) |

- **Response:** `device_id` (uuid); SHA-256 chứng chỉ TLS dạng DER (dùng làm `tls_sha256` ở PAIR-01
  API 3).
- **Ví dụ:** `ik_sig_pub` = `Zm9vYmFyYmF6cXV4cXV1eHh5enp6MTIzNDU2Nzg5MDE` → `device_id` =
  `8c7d6e5f-4a3b-8c2d-9e1f-0a1b2c3d4e5f` (điện thoại trong ví dụ PAIR-01).
- **Logic nghiệp vụ:**
  1. Idempotent: keyset và PKCS#12 đã có → nạp, không tạo lại. Đổi `ik_sig` đồng nghĩa đổi
     `device_id` và làm hỏng mọi cặp.
  2. `StrongBoxUnavailableException` → tạo lại `hl_master` không StrongBox (TEE); lỗi khác → E9.
  3. Không ghi log khóa, mật khẩu PKCS#12 hay `device_id` đầy đủ.
  4. Gỡ ứng dụng xóa cả khóa Keystore lẫn keyset → cài lại có `device_id` mới (0.2).

#### API 2 — Xin quyền runtime theo tính năng

- **URL:** N/A
- **Method:** `registerForActivityResult(ActivityResultContracts.RequestMultiplePermissions())` rồi
  `launch(arrayOf(...))`; `POST_NOTIFICATIONS` dùng `RequestPermission`. Kiểm trước bằng
  `ContextCompat.checkSelfPermission` và `shouldShowRequestPermissionRationale`.
- **Request — bảng quyền theo tính năng** (nguồn tính `permissions_missing`, khớp CONN-01 API 7):

| Tính năng | Quyền (`android.permission.*`) | API | Thiếu thì | Google Play |
|-----------|-------------------------------|-----|-----------|-------------|
| Chung | `POST_NOTIFICATIONS` | 33+ | Không tính năng nào mất hiệu lực; không có thông báo (E1) | — |
| Ghép nối (quét QR) | `CAMERA` | 29+ | PAIR-01 E9, dùng PIN | — |
| `sms` | `READ_SMS` | 29+ | `sms` không hiệu lực | Declaration Form |
| `sms` | `SEND_SMS` | 29+ | `can_send = false` | Declaration Form |
| `sms`, `call` | `READ_CONTACTS` | 29+ | Không có tên hiển thị (SMS-01 E3, CALL-01 E2) | — |
| `sms`, `call` | `READ_PHONE_STATE` | 29+ | `sms`: `sims = []`; `call`: không hiệu lực | — |
| `call` | `READ_CALL_LOG` | 29+ | `caller_id = false`, không có CALL-04 | Declaration Form |
| `call` | `ANSWER_PHONE_CALLS` | 29+ | `can_answer = can_end = false` | — |
| `call_audio` | `BLUETOOTH_CONNECT` | 31+ (API 29–30: `BLUETOOTH` cấp lúc cài) | `call_audio` không hiệu lực | — |
| `call_audio` (Opus/WS) | Quyền Shizuku (AUDIO-01 API 6) | 30+ | `opus_fallback.available = false` | — |
| `camera` | `CAMERA`, `RECORD_AUDIO` | 29+ | `camera` không hiệu lực | — |
| `clipboard` (tự gửi) | Dịch vụ Hỗ trợ tiếp cận (API 6) | 29+ | `auto_send = false`, chỉ gửi thủ công | Khai báo Accessibility |

- **Response:** `Map<String, Boolean>` — kết quả từng quyền.
- **Ví dụ:** SMS: `launch(arrayOf(READ_SMS, SEND_SMS, READ_CONTACTS, READ_PHONE_STATE))` →
  `{READ_SMS=true, SEND_SMS=true, READ_CONTACTS=false, READ_PHONE_STATE=true}` →
  `permissions_missing = ["READ_CONTACTS"]`, `features.sms.can_send = true`, `sims` có dữ liệu.
- **Logic nghiệp vụ:**
  1. `permissions_missing` gồm tên ngắn (bỏ tiền tố `android.permission.`) của quyền còn thiếu thuộc
     tính năng đang bật (`feature.<tên>` = `true`), cộng `POST_NOTIFICATIONS` khi thiếu trên Android
     13+; tính năng đang tắt không góp quyền. `ack` lỗi `PERMISSION_MISSING` ghi tên đầy đủ trong
     `details.permission` (như SMS-01 E2).
  2. Android không cho biết một quyền đã bị từ chối vĩnh viễn; suy ra bằng `perm.requested`: đã từng
     hỏi, chưa cấp và `shouldShowRequestPermissionRationale = false` → vĩnh viễn (Android 11+ tự
     chặn sau hai lần từ chối). Khi đó không gọi `launch` (hộp thoại sẽ không hiện) mà mở
     `ACTION_APPLICATION_DETAILS_SETTINGS` (E5).
  3. Mỗi lần `launch` chỉ chứa quyền của một tính năng.
  4. Người dùng thu hồi quyền trong Cài đặt → hệ thống dừng tiến trình; A-SVC khởi động lại
     (`START_STICKY`) và tính lại khi khởi động. Người dùng cấp quyền trong Cài đặt → tính lại khi
     A-UI `onResume` hoặc khi phiên mới gửi `capability/hello`. Mọi yêu cầu từ client vẫn kiểm quyền
     tại chỗ và trả `PERMISSION_MISSING` nếu thiếu; khi đó A-SVC đăng thông báo gợi ý (trường 17).
  5. `CAMERA`, `RECORD_AUDIO` là quyền "khi đang dùng"; việc mở camera khi ứng dụng ở nền và
     foreground service type `camera` /`microphone` thuộc CAM-02.

#### API 3 — Khởi động foreground service `connectedDevice`

- **URL:** N/A
- **Method:**
  `ContextCompat.startForegroundService(context, Intent(context, HandLiveService::class.java))`;
  trong `onStartCommand`:
  `ServiceCompat.startForeground(this, NOTIF_SERVICE_ID, notification, ServiceInfo.FOREGROUND_SERVICE_TYPE_CONNECTED_DEVICE)`,
  trả `START_STICKY`.
- **Request — khai báo:**

| Mục | Giá trị |
|-----|---------|
| `<service>` | `.HandLiveService`, `android:foregroundServiceType="connectedDevice"`, `android:exported="false"` |
| Quyền cấp lúc cài | `FOREGROUND_SERVICE`, `FOREGROUND_SERVICE_CONNECTED_DEVICE` (API 34+), `CHANGE_NETWORK_STATE` (điều kiện tiên quyết của type `connectedDevice`), `INTERNET`, `ACCESS_NETWORK_STATE`, `RECEIVE_BOOT_COMPLETED`, `REQUEST_IGNORE_BATTERY_OPTIMIZATIONS` |
| Kênh thông báo | id `hl_service`, tên "Dịch vụ kết nối", `IMPORTANCE_LOW` (không âm thanh, không rung), `setShowBadge(false)` |
| Thông báo | `CATEGORY_SERVICE`, `setOngoing(true)`, nội dung theo trường 5, nút "Gửi bảng nhớ tạm" (CLIP-01 trường 4) |
| Khởi động lại | `BroadcastReceiver` cho `BOOT_COMPLETED` và `MY_PACKAGE_REPLACED` gọi lại `startForegroundService` |

- **Response:** dịch vụ ở trạng thái foreground; `ForegroundServiceStartNotAllowedException` (API
  31+) hoặc `SecurityException` (thiếu quyền của type) → E2.
- **Ví dụ:** thông báo không đặt tiêu đề riêng (Android hiện tên app), nội dung "Đang chờ kết nối",
  nút "Gửi bảng nhớ tạm"; sau CONN-01: "Đã kết nối với MacBook của Lan".
- **Logic nghiệp vụ:**
  1. Phải gọi `startForeground` trong 5 s sau `startForegroundService`, nếu không hệ thống báo lỗi
     và dừng ứng dụng.
  2. Khởi động từ nền (hệ thống dừng dịch vụ rồi khởi động lại, đổi mạng) chỉ hợp lệ khi có ngoại lệ
     của Android 12+: đã được miễn tối ưu pin (API 4), `BOOT_COMPLETED` /`MY_PACKAGE_REPLACED`, hoặc
     FCM ưu tiên cao (CONN-04). Android 15 cấm khởi động các type `dataSync`, `camera`,
     `microphone`, `mediaPlayback`, `phoneCall`, `mediaProjection` từ `BOOT_COMPLETED` nhưng không
     cấm `connectedDevice`; `connectedDevice` cũng không bị giới hạn 6 giờ như `dataSync`.
  3. Từ Android 14 người dùng vuốt bỏ được thông báo của foreground service; dịch vụ vẫn chạy, thông
     báo hiện lại khi trạng thái kết nối đổi.
  4. Thiếu `POST_NOTIFICATIONS` (E1): dịch vụ vẫn chạy, hệ thống chỉ liệt kê nó trong Trình quản lý
     tác vụ.

#### API 4 — Miễn tối ưu pin và tạm dừng khi không dùng

- **URL:** N/A
- **Method:** `PowerManager.isIgnoringBatteryOptimizations(packageName)`;
  `startActivity(Intent(Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS, Uri.parse("package:" + packageName)))`;
  Android 11+: `PackageManagerCompat.getUnusedAppRestrictionsStatus(context)` và
  `startActivity(IntentCompat.createManageUnusedAppRestrictionsIntent(context, packageName))`.
- **Request:** URI `package:<tên gói>`; không có tham số khác.
- **Response:** hộp thoại hệ thống không trả kết quả tin cậy; A-UI đọc lại
  `isIgnoringBatteryOptimizations` và `getUnusedAppRestrictionsStatus` ở `onResume`.
- **Ví dụ:** `isIgnoringBatteryOptimizations("app.handlive.android")` = `false` → mở hộp thoại →
  người dùng chọn "Cho phép" → `onResume` đọc lại `true` → trường 6 = `exempt`.
- **Logic nghiệp vụ:**
  1. Lý do khai báo với Google Play: chức năng cốt lõi là ứng dụng đồng hành phải giữ kết nối với
     thiết bị đã ghép; A-SVC là WSS server phải nhận kết nối cả khi máy đang Doze — ứng dụng trong
     danh sách miễn được dùng mạng trong Doze và App Standby.
  2. Máy không hỗ trợ intent (`ActivityNotFoundException`) → mở
     `Settings.ACTION_IGNORE_BATTERY_OPTIMIZATION_SETTINGS`.
  3. `getUnusedAppRestrictionsStatus` ∈ {`API_30`, `API_30_BACKPORT`, `API_31` } → trường 7 =
     `enabled`, gợi ý tắt; `DISABLED` → `disabled`; `FEATURE_NOT_AVAILABLE`, `ERROR` →
     `not_available`, ẩn gợi ý.
  4. Được miễn tối ưu pin cũng là điều kiện để A-SVC tự khởi động lại foreground service từ nền (API
     3, logic 2).
  5. Không tự hỏi lại sau khi người dùng từ chối; chỉ giữ cảnh báo trong Cài đặt › Quyền và chạy nền
     (E3).

#### API 5 — Hướng dẫn tự khởi chạy theo hãng

- **URL:** N/A
- **Method:** `startActivity(Intent().setComponent(ComponentName(<gói>, <activity>)))` theo bảng cấu
  hình; `ActivityNotFoundException` hoặc `SecurityException` →
  `startActivity(Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS, Uri.fromParts("package", packageName, null)))`.
- **Request — bảng cấu hình, chọn theo `Build.MANUFACTURER` viết thường:**

| Hãng | Hướng dẫn hiển thị | Màn hình mở |
|------|-------------------|-------------|
| `xiaomi`, `redmi`, `poco` (MIUI, HyperOS) | "Bật Tự khởi chạy cho HandLive; trong Tiết kiệm pin của HandLive chọn Không hạn chế" | `com.miui.securitycenter/com.miui.permcenter.autostart.AutoStartManagementActivity` |
| `oppo`, `realme`, `oneplus` (ColorOS, realme UI, OxygenOS) | "Trong Sử dụng pin của HandLive, bật Cho phép hoạt động nền và Cho phép tự khởi chạy" | Trang Thông tin ứng dụng |
| `samsung` (One UI) | "Pin › Giới hạn sử dụng nền › Ứng dụng không bao giờ ngủ › thêm HandLive" | Trang Thông tin ứng dụng |
| Hãng khác | Ẩn hướng dẫn | — |

- **Response:** màn hình của hãng mở, hoặc trang Thông tin ứng dụng (dự phòng).
- **Ví dụ:** `Build.MANUFACTURER = "Xiaomi"` → hiện hướng dẫn Xiaomi; "Mở cài đặt của hãng" mở
  `AutoStartManagementActivity`.
- **Logic nghiệp vụ:**
  1. Không có API công khai đọc trạng thái tự khởi chạy của hãng → dựa vào người dùng bấm "Đã xong";
     không tự hỏi lại.
  2. Tên màn hình và đường dẫn thay đổi theo phiên bản ROM; bảng nằm trong tài nguyên ứng dụng, cập
     nhật theo bản phát hành; mọi lỗi mở đều rơi về trang Thông tin ứng dụng.
  3. Hướng dẫn luôn mở lại được từ Cài đặt › Quyền và chạy nền.

#### API 6 — Cài đặt Hỗ trợ tiếp cận cho tự gửi clipboard

- **URL:** N/A
- **Method:** `startActivity(Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS))`; kiểm bằng
  `AccessibilityManager.getEnabledAccessibilityServiceList(AccessibilityServiceInfo.FEEDBACK_ALL_MASK)`;
  nguồn cài: `packageManager.getInstallSourceInfo(packageName).installingPackageName` (API 30+) hoặc
  `getInstallerPackageName(packageName)` (API 29); hướng dẫn hạn chế mở
  `ACTION_APPLICATION_DETAILS_SETTINGS`.
- **Request — khai báo:**
  `<service android:name=".ClipboardAccessibilityService" android:permission="android.permission.BIND_ACCESSIBILITY_SERVICE" android:exported="false">`
  với intent-filter `android.accessibilityservice.AccessibilityService` và cấu hình
  `@xml/a11y_clipboard` (`android:isAccessibilityTool="false"`; loại sự kiện do CLIP-01 API 1 quy
  định).
- **Response:** danh sách dịch vụ đang bật có `ClipboardAccessibilityService` → trường 15 = `on`;
  A-CLIP nhận `onServiceConnected` (CLIP-01 A3).
- **Ví dụ:** trường 14: "Nếu Android báo 'Chế độ cài đặt bị hạn chế': mở Cài đặt › Ứng dụng ›
  HandLive, chạm ⋮ ở góc trên, chọn 'Cho phép chế độ cài đặt bị hạn chế', xác thực, rồi quay lại bật
  HandLive trong Hỗ trợ tiếp cận."
- **Logic nghiệp vụ:**
  1. Chỉ mở cài đặt Hỗ trợ tiếp cận sau khi có `clip.a11y_consent_at` (đồng ý bằng thao tác chủ
     động, không chọn sẵn); nội dung công bố theo CLIP-01 trường 2.
  2. Android 13+ và `installingPackageName` khác `com.android.vending` (APK, F-Droid) → hiện trường
     14 trước khi mở. Quay lại mà dịch vụ chưa bật → hiện lại hướng dẫn (E7, E8).
  3. Dịch vụ nối (`onServiceConnected`) → `auto_send = true`, ngắt (`onUnbind`) → `false`; mỗi lần
     đổi gửi `capability/update` (CLIP-01 A3).
  4. Bản cập nhật ứng dụng mở rộng phạm vi dữ liệu trong công bố → xóa `clip.a11y_consent_at` để hỏi
     lại.
  5. Người dùng tắt "Tự gửi khi sao chép" (SET-02) → dịch vụ gọi `disableSelf()` để trả lại quyền Hỗ
     trợ tiếp cận.

#### API 7 — `WS capability/update`

Đặc tả ở SET-02 API 1 (1.2.5). Trong SET-01, Android gửi khi `permissions_missing` hoặc một cờ con
phụ thuộc quyền (`can_send`, `sims`, `caller_id`, `can_answer`, `can_end`, `auto_send`) thay đổi.

#### API 8 — `POST /v1/devices`

Đặc tả ở CONN-03 API 1. Android gọi ở bước 7 khi `relay.enabled = true`; idempotent (upsert). Lỗi
mạng hoặc 5xx → thử lại nền theo `RECONNECT_BACKOFF` khi có mạng (E10). Push token FCM đăng ký sau
đó theo CONN-04 API 1.

#### Query

Không truy vấn cơ sở dữ liệu Room; chỉ đọc/ghi DataStore (khóa 0.9.5 và khóa mới của nhóm).

```text
# [Thiết kế] DataStore<Preferences> của Android (A-UI, A-SVC)
prefs[longPreferencesKey("setup.completed_at")]                                   # bước 1: null → chạy phần A
dataStore.edit { it[longPreferencesKey("setup.started_at")] = now }                 # bước 2
dataStore.edit { it[longPreferencesKey("setup.completed_at")] = now }               # bước 7
prefs[booleanPreferencesKey("relay.enabled")] ?: true                             # bước 7
prefs[stringSetPreferencesKey("perm.requested")] ?: emptySet()                    # bước 10
dataStore.edit { it[stringSetPreferencesKey("perm.requested")] = requested + asked }   # bước 10
dataStore.edit { it[longPreferencesKey("clip.a11y_consent_at")] = now }             # bước 12
dataStore.edit { it[booleanPreferencesKey("clip.auto_send")] = false }              # E6
prefs[booleanPreferencesKey("feature.sms")] ?: true                               # bước 14: chỉ tính quyền của tính năng đang bật (tương tự feature.call, feature.camera, feature.call_audio)
```

---

## 1.2 SET-02 — Bật/tắt tính năng và tùy chọn đồng bộ

### 1.2.1 Thông tin chung

| Mục | Nội dung |
|-----|----------|
| Tên | SET-02 — Bật/tắt tính năng và tùy chọn đồng bộ |
| Mô tả | Màn hình Cài đặt trên mỗi thiết bị quản lý các khóa ở 0.9.5.<br>Cài đặt thuộc về thiết bị (toàn cục), áp dụng cho mọi cặp của thiết bị đó và không đồng bộ sang thiết bị khác; đối phương chỉ biết qua capability.<br>Đổi khóa `feature.*` hoặc khóa ảnh hưởng capability → gửi `capability/update` (cùng cấu trúc `capability/hello`) tới mọi đối phương đang kết nối; hai bên tính lại tính năng hiệu lực; tắt một tính năng dừng các tác vụ đang chạy của nó (ví dụ phiên camera).<br>Bật tính năng có điều kiện đi qua luồng riêng: `feature.call_audio` qua AUDIO-01, `feature.camera` trên Mac qua CAM-01, quyền Android qua SET-01 phần B, `clip.auto_send` qua công bố Hỗ trợ tiếp cận (CLIP-01 A1–A3).<br>Kèm ba hành động: "Đồng bộ lại toàn bộ SMS" (SMS-01 A1–A2); "Xóa thiết bị khỏi máy chủ" (`DELETE /v1/devices/me?revoke_pairs=false` — relay xóa đăng ký của thiết bị và các cặp của nó trên relay, không báo `pair_revoked`; mọi cặp cục bộ giữ nguyên, vẫn dùng được trong LAN hoặc qua USB — C16); "Xóa toàn bộ dữ liệu HandLive" (`revoke_pairs=true`: hủy mọi cặp và báo `pair_revoked` cho đối phương, xóa khỏi máy chủ, xóa khóa, cơ sở dữ liệu và cài đặt). |
| Tác nhân | Chính: Người dùng. Hệ thống: A-UI, A-SVC, A-CLIP, M-APP, I-APP, R-API, R-DB, R-KV. |
| Điều kiện trước | Thiết bị đã hoàn tất SET-01 (Android) hoặc SET-03 (Mac/iOS). Hành động với relay cần Internet. "Đồng bộ lại toàn bộ SMS" cần phiên tới điện thoại. |
| Điều kiện sau | **Đổi tùy chọn:** giá trị mới nằm trong DataStore/`UserDefaults`; nếu khóa ảnh hưởng capability thì mọi đối phương đang kết nối đã nhận `capability/update`, tính năng hiệu lực ở hai bên khớp cấu hình mới và tác vụ của tính năng mất hiệu lực đã dừng.<br>**Xóa thiết bị khỏi máy chủ:** relay không còn dòng `devices`, `pairs` của thiết bị; đối phương không nhận `pair_revoked`, chỉ thấy cặp biến mất khỏi relay và tiếp tục dùng LAN (C16); mọi cặp cục bộ, khóa định danh và các cài đặt khác giữ nguyên; `relay.enabled = false`.<br>**Xóa toàn bộ:** relay không còn dòng `devices`, `pairs` của thiết bị; đối phương đã hoặc sẽ nhận `pair_revoked`; thiết bị không còn cặp nào; khóa định danh, `PRK`, cơ sở dữ liệu, cài đặt và thông báo đã hiển thị bị xóa; ứng dụng quay về SET-01/SET-03. |
| Ngoại lệ | E1 — Luồng kích hoạt không hoàn tất (từ chối công bố AUDIO-01, lỗi CAM-01): khóa giữ `false`.<br>E2 — Android: bật tính năng nhưng quyền bị từ chối: khóa lưu `true`, tính năng không hiệu lực, quyền vào `permissions_missing` (SET-01 E4, E5).<br>E3 — Không có phiên tới đối phương: chỉ lưu cục bộ; `capability/hello` của phiên kế tiếp mang giá trị mới.<br>E4 — Ghi DataStore/`UserDefaults` lỗi: giữ giá trị cũ, báo lỗi.<br>E5 — "Xóa thiết bị khỏi máy chủ" khi không có mạng hoặc relay lỗi (5xx, hết thời gian): không thay đổi gì, báo "Không kết nối được máy chủ, hãy thử lại sau."<br>E6 — Relay trả 401 `TOKEN_EXPIRED`: lấy JWT mới (0.6.4) rồi thử lại một lần; `POST /v1/auth/challenge` trả 404 `DEVICE_NOT_FOUND` → thiết bị đã bị xóa trước đó, coi như thành công.<br>E7 — "Xóa toàn bộ dữ liệu" khi relay không truy cập được: hỏi "Không kết nối được máy chủ.<br>Vẫn xóa trên thiết bị này?" với nút "Xóa" (phá hủy) và "Hủy"; chọn "Xóa" → xóa cục bộ, bản ghi trên relay tự xóa sau 180 ngày không hoạt động (0.9.4).<br>E8 — Người dùng hủy ở hộp thoại xác nhận: không thay đổi.<br>E9 — Tắt tính năng khi tác vụ của nó đang chạy (đang phát camera, âm thanh cuộc gọi đang ở Mac): hỏi xác nhận, rồi dừng êm theo chức năng tương ứng (CAM-02, AUDIO-03). |
| Yêu cầu đặc biệt | **Hiệu năng:** trong LAN, đối phương áp dụng thay đổi ≤ 1 s sau khi người dùng gạt công tắc; ghi khóa không chặn giao diện.<br>**Bảo mật:** capability chỉ đi trong envelope mã hóa, relay chỉ thấy `type = capability`; `DELETE /v1/devices/me` chỉ xóa chính thiết bị gọi (theo `sub` của JWT); hành động phá hủy có nút màu cảnh báo, nêu rõ hậu quả, không hoàn tác; khóa bị xóa khỏi Keystore/Keychain trước khi báo xong.<br>**Quyền riêng tư:** "Xóa thiết bị khỏi máy chủ" xóa mọi dữ liệu relay giữ về thiết bị (khóa công khai, push token, cặp); thống kê `usage_daily` chỉ theo `device_hash` có muối theo tháng, tự hết sau 30 ngày.<br>**Khả dụng:** mỗi công tắc có mô tả một dòng và lý do khi không hiệu lực; đọc được bằng TalkBack/VoiceOver.<br>**Độc lập tính năng:** đổi một tính năng không làm gián đoạn tính năng khác. |

### 1.2.2 Màn hình

N/A — chưa có wireframe được duyệt.

### 1.2.3 Mô tả chi tiết các thành phần

Cột Mô tả ghi nền tảng có khóa, rồi **Capability** (trường capability mà khóa quyết định, đổi → gửi
`capability/update`) hoặc **Cục bộ** (chỉ ảnh hưởng thiết bị này).

| # | Trường | Kiểu dữ liệu | Input/Output | Giá trị khởi tạo | Mô tả |
|---|--------|--------------|--------------|------------------|-------|
| 1 | Đồng bộ bảng nhớ tạm (`feature.clipboard`) | bool | Input/Output | `true` | Tất cả.<br>**Capability** `features.clipboard.enabled`. Tắt → ngừng theo dõi và gửi clipboard, hủy truyền ảnh đang dở (`clipboard/cancel`); `clipboard/*` đến bị trả `FEATURE_DISABLED`<br>Mô tả dưới công tắc (Android): "Sao chép trên một thiết bị, dán trên các thiết bị khác." |
| 2 | Tự gửi khi sao chép (`clip.auto_send`) | bool | Input/Output | `true` | Android.<br>**Capability** `features.clipboard.auto_send` (= khóa này và dịch vụ Hỗ trợ tiếp cận đang chạy). Bật khi chưa có đồng ý hoặc dịch vụ chưa chạy → CLIP-01 A1–A3 (SET-01 bước 12–14). Tắt → dịch vụ gọi `disableSelf()`<br>Mô tả dưới công tắc (Android): "Gửi ngay nội dung vừa sao chép, qua một dịch vụ Hỗ trợ tiếp cận." |
| 3 | Thời điểm đồng ý công bố (`clip.a11y_consent_at`) | timestamp | Output | Rỗng | Android. "Đã đồng ý lúc 14:05, 24/09/2026"; chỉ luồng công bố ghi khóa này |
| 4 | Đồng bộ ảnh (`clip.send_images`) | bool | Input/Output | `true` | Tất cả. **Capability** `features.clipboard.mimes`: `false` → bỏ `image/png`, `image/jpeg`, chỉ còn `text/plain` (CLIP QC1)<br>Mô tả dưới công tắc (Android): "Gửi cả ảnh đã sao chép, tối đa 10 MB." |
| 5 | Chặn nội dung nhạy cảm (`clip.block_sensitive`) | bool | Input/Output | `true` | Tất cả, có tác dụng ở bên gửi Android và Mac. **Cục bộ** (CLIP QC3)<br>Mô tả dưới công tắc (Android): "Nội dung có vẻ là mật khẩu hoặc số thẻ chỉ được gửi khi bạn chọn Vẫn gửi." |
| 6 | Tự xóa bảng nhớ tạm đã nhận (`clip.auto_clear_s`) | int32 (enum{0\| 60\| 300}, giây) | Input/Output | `60` | Tất cả. **Cục bộ** ở bên nhận (CLIP-05); `0` = tắt |
| 7 | Tin nhắn SMS (`feature.sms`) | bool | Input/Output | `true` | Tất cả.<br>**Capability** `features.sms.enabled`. Android bật khi thiếu quyền → SET-01 phần B; tắt → gỡ `ContentObserver`, `sms/*` bị trả `FEATURE_DISABLED`. Mac/iOS tắt → ẩn mục Tin nhắn, dừng SMS-01; dữ liệu đã đồng bộ giữ tới khi hủy ghép nối hoặc xóa toàn bộ |
| 8 | Thông báo SMS mới (`sms.notify`) | bool | Input/Output | `true` | Mac, iOS. iOS: **Capability** `features.sms.notify` (Android chỉ push SMS mới khi `true`). Mac: **Cục bộ** |
| 9 | Hiện nội dung trong thông báo (`sms.preview`) | bool | Input/Output | `true` | Mac, iOS. **Cục bộ**; I-NSE đọc từ `UserDefaults` của App Group |
| 10 | Cuộc gọi (`feature.call`) | bool | Input/Output | `true` | Tất cả. **Capability** `features.call.enabled`. Android bật khi thiếu quyền → SET-01 phần B; tắt → ngừng theo dõi cuộc gọi. Mac/iOS tắt → không hiện panel, thông báo cuộc gọi |
| 11 | Thông báo cuộc gọi (`call.notify`) | bool | Input/Output | `true` | Mac, iOS. iOS: **Capability** `features.call.notify` (Android chỉ push cuộc gọi khi `true` — CALL-01 bước 5). Mac: **Cục bộ** |
| 12 | Đổ chuông trên Mac (`call.ringtone`) | bool | Input/Output | `true` | Mac. **Cục bộ** (CALL-01 trường 14; khóa do CALL-01 đề xuất, chờ bổ sung 0.9.5) |
| 13 | Nghe gọi trên Mac (`feature.call_audio`) | bool | Input/Output | `false` | Android, Mac.<br>**Capability** `features.call_audio.enabled` (Mac kèm `bt_address`).<br>Mac bật → AUDIO-01, chỉ lưu `true` khi người dùng chấp thuận công bố.<br>Android bật → SET-01 phần B (`BLUETOOTH_CONNECT`); Shizuku tùy chọn theo AUDIO-01 bước 10–11.<br>Tắt khi đang gọi → âm thanh về điện thoại (AUDIO-03, E9) |
| 14 | Dự phòng qua Wi-Fi, cần Shizuku (`call_audio.allow_opus_fallback`) | bool | Input/Output | `true` | Android, Mac. Android `false` → không bind Shizuku UserService; **Capability** `features.call_audio.opus_fallback` với `available = false`, `reason = "disabled"`. Mac `false` → không mở `call_audio/open`; **Cục bộ** |
| 15 | Điện thoại dùng cho HFP (`call_audio.phone_bt_address`) | string | Input/Output | Rỗng | Mac. Chọn ở AUDIO-01 bước 7; **Cục bộ** |
| 16 | Dùng điện thoại làm webcam (`feature.camera`) | bool | Input/Output | `false` | Android, Mac.<br>**Capability** `features.camera.enabled`. Mac bật → CAM-01 (lưu `true` khi camera ảo `active`). Android bật → SET-01 phần B (`CAMERA`, `RECORD_AUDIO`). Tắt → dừng phiên đang phát (`camera/stop`, CAM-02, E9) |
| 17 | Camera mặc định (`cam.default_camera`) | enum{front\| back} | Input/Output | `front` | Mac. **Cục bộ** (CAM-02) |
| 18 | Chất lượng mặc định (`cam.default_quality`) | enum{auto\| 480p\| 720p\| 1080p} | Input/Output | `auto` | Mac. **Cục bộ** (CAM-02, CAM-05) |
| 19 | Tự chuyển USB khi cắm cáp (`cam.usb_boost`) | bool | Input/Output | `true` | Mac. **Cục bộ** (CAM-04) |
| 20 | Không hỏi lại wizard USB (`cam.usb_wizard_dismissed`) | bool | Input/Output | `false` | Mac. **Cục bộ** (CAM-04); đặt lại `false` để wizard hiện lại |
| 21 | Kết nối qua Internet (`relay.enabled`) | bool | Input/Output | `true` | Tất cả.<br>**Capability** `features.relay.enabled`. Tắt → sau `capability/update`, đóng phiên đi qua relay (`session/bye`, `reason = shutdown`) và kết nối `/v1/relay`; không gửi push. Bật → đăng ký relay (CONN-03 API 1) và các cặp còn `relay_registered = 0` (PAIR-01 API 8)<br>Mô tả dưới công tắc (Android): "Kết nối với thiết bị đã ghép nối khi không cùng mạng Wi-Fi; nội dung vẫn được mã hóa đầu cuối." |
| 22 | Mở khi đăng nhập | bool | Input/Output | `SMAppService.mainApp.status == .enabled` | Mac. Không phải khóa cài đặt; đọc/ghi qua `SMAppService` (SET-03 API 3) |
| 23 | Mục "Quyền và chạy nền" | action | Input | — | Android. Mở danh sách tính năng và quyền (SET-01 trường 10) cùng trạng thái chạy nền (SET-01 trường 6–9)<br>Gồm các dòng "Thông báo", "Chạy trong nền" và từng tính năng |
| 24 | Tính năng hiệu lực theo thiết bị đã ghép | array\<object> | Output | Từ capability đã lưu (`features_json`) | Mỗi cặp: tính năng hiệu lực và lý do nếu không ("Tắt trên <thiết bị>", "Thiếu quyền trên điện thoại", "Kết nối qua Internet đang tắt trên điện thoại") |
| 25 | Nút "Đồng bộ lại toàn bộ SMS" | action | Input | Vô hiệu khi không có phiên | Mac, iOS. Chạy SMS-01 A1–A2 (bước B1) |
| 26 | Nút "Xóa thiết bị khỏi máy chủ" | action | Input | — | Tất cả. Luồng A1–A4, A6: gỡ đăng ký khỏi relay; giữ khóa định danh, cài đặt và mọi cặp ghép nối (vẫn dùng được trong LAN hoặc qua USB) |
| 27 | Nút "Xóa toàn bộ dữ liệu HandLive" | action | Input | — | Tất cả. Luồng A1–A6 |
| 28 | Xác nhận hành động phá hủy | enum{Xóa khỏi máy chủ\| Xóa toàn bộ\| Hủy} | Input | — | Nút xác nhận nêu đúng hành động, đi cùng "Hủy": "Xóa khỏi máy chủ" cho trường 26, "Xóa toàn bộ" cho trường 27; nút có màu cảnh báo |
| 29 | Nội dung cảnh báo | string | Output | Theo hành động | Xóa khỏi máy chủ: "Xóa đăng ký của thiết bị này khỏi máy chủ HandLive.<br>Các thiết bị đã ghép vẫn dùng được khi ở cùng mạng Wi-Fi; kết nối qua Internet sẽ tắt cho tới khi bạn bật lại." Xóa toàn bộ: "Xóa khóa bảo mật, thiết bị đã ghép, tin nhắn và nhật ký cuộc gọi đã đồng bộ cùng mọi cài đặt trên thiết bị này.<br>Không thể hoàn tác." |
| 30 | Thông báo kết quả, lỗi | string | Output | Rỗng | "Đã xóa khỏi máy chủ" hoặc nội dung theo E1–E9 |
| 31 | Hiện HandLive trên thanh menu (`mac.menu_bar_extra`) | bool | Input/Output | `true` | Mac.<br>**Cục bộ**. `true` → biểu tượng trên thanh menu (`MenuBarExtra`, `isInserted`), app ở chế độ `.accessory` khi không mở cửa sổ chính; `false` → gỡ biểu tượng, app chuyển `.regular` (biểu tượng Dock, thanh menu của app, Dock menu) làm lối vào chính.<br>Hỏi lúc thiết lập (SET-03 trường 16, bước 6) |
| 32 | Ngôn ngữ | enum{Theo hệ thống\| English\| Tiếng Việt} | Input/Output | Theo hệ thống | Android.<br>**Cục bộ**, không phải khóa cài đặt (C20, 0.12.3). Android 13+: mở trang ngôn ngữ ứng dụng của hệ thống (`Settings.ACTION_APP_LOCALE_SETTINGS`); Android 10–12: chọn trong app, áp dụng bằng `AppCompatDelegate.setApplicationLocales` (tự lưu). Tên ngôn ngữ viết bằng chính ngôn ngữ đó. Mac, iPhone, iPad dùng cài đặt ngôn ngữ theo ứng dụng của hệ thống |

### 1.2.4 Luồng nghiệp vụ

```mermaid
flowchart TB
  subgraph ND["Người dùng"]
    U1["(1) Mở Cài đặt, đổi một tùy chọn"]
    U8["(8) Thấy trạng thái tính năng cập nhật"]
    UA1["(A1) Chọn Xóa khỏi máy chủ hoặc Xóa toàn bộ, xác nhận"]
    UA6["(A6) Thấy kết quả hoặc màn hình chào mừng"]
  end
  subgraph HT["Hệ thống"]
    D2{"(2) Bật khóa cần luồng kích hoạt?"}
    S3["(3) Chạy SET-01 phần B, AUDIO-01, CAM-01 hoặc công bố Hỗ trợ tiếp cận"]
    S4["(4) Ghi khóa, áp dụng tác động cục bộ"]
    D5{"(5) Khóa ảnh hưởng capability?"}
    S6["(6) Gửi capability/update tới mọi phiên đang mở"]
    S7["(7) Hai bên tính lại tính năng hiệu lực, dừng hoặc khởi chạy tác vụ"]
    SA2["(A2) Xác thực relay, gọi DELETE /v1/devices/me"]
    SA3["(A3) Relay xóa thiết bị, chỉ báo pair_revoked khi xóa toàn bộ"]
    SA4["(A4) Xóa toàn bộ: pair/revoke qua LAN, dọn cặp. Chỉ xóa khỏi máy chủ: giữ cặp, tắt relay"]
    SA5["(A5) Xóa khóa, cơ sở dữ liệu, cài đặt"]
    X1(["Kết thúc: giữ nguyên"])
  end
  U1 --> D2
  D2 -- "Có" --> S3
  D2 -- "Không" --> S4
  S3 -- "Hoàn tất hoặc quyền bị từ chối (E2)" --> S4
  S3 -- "Không hoàn tất (E1)" --> X1
  S4 --> D5
  D5 -- "Có" --> S6 --> S7 --> U8
  D5 -- "Không" --> U8
  UA1 -- "Xác nhận" --> SA2
  UA1 -- "Hủy (E8)" --> X1
  SA2 --> SA3
  SA3 -- "204" --> SA4
  SA2 -- "Relay lỗi, chỉ xóa khỏi máy chủ (E5)" --> X1
  SA2 -- "Relay lỗi, xóa toàn bộ, người dùng vẫn xóa (E7)" --> SA4
  SA4 -- "Xóa toàn bộ" --> SA5 --> UA6
  SA4 -- "Chỉ xóa khỏi máy chủ" --> UA6
```

| Bước | Tác nhân | Thành phần | Mô tả | Ngoại lệ / Ghi chú |
|------|----------|-----------|-------|--------------------|
| 1 | Người dùng | A-UI / M-APP / I-APP | Mở Cài đặt (Android: tab Cài đặt; Mac: menu bar › Cài đặt; iOS: tab Cài đặt), gạt công tắc hoặc chọn giá trị (trường 1–22). | Tắt tính năng đang có tác vụ chạy → hỏi xác nhận trước (E9). |
| 2 | Hệ thống | như trên | Khóa cần luồng kích hoạt khi **bật**: `feature.call_audio` (Mac: AUDIO-01; Android: `BLUETOOTH_CONNECT`), `feature.camera` (Mac: CAM-01; Android: `CAMERA`, `RECORD_AUDIO`), `feature.sms`, `feature.call` trên Android khi còn thiếu quyền (SET-01 phần B), `clip.auto_send` khi chưa có `clip.a11y_consent_at` hoặc dịch vụ Hỗ trợ tiếp cận chưa chạy.<br>Khóa khác và mọi thao tác tắt → bước 4. |  |
| 3 | Hệ thống, Người dùng | như trên | Chạy luồng tương ứng. AUDIO-01, CAM-01 tự lưu `true` khi hoàn tất (AUDIO-01 bước 5, CAM-01 bước 11). SET-01 phần B: khóa lưu `true` kể cả khi quyền bị từ chối (tính năng khi đó không hiệu lực). Không đồng ý công bố Hỗ trợ tiếp cận → `clip.auto_send = false`. | E1, E2. |
| 4 | Hệ thống | như trên | Ghi khóa (Query) và áp dụng tác động cục bộ: tắt tính năng → dừng tác vụ của nó trên thiết bị này (API 1, logic 4); `clip.auto_send = false` → `disableSelf()`; `relay.enabled = true` → đăng ký relay nền (API 6); khóa **Cục bộ** (`clip.auto_clear_s`, `cam.*`, `sms.preview`, `call.ringtone`…) áp dụng từ lần dùng kế tiếp. | Ghi lỗi → E4, giữ giá trị cũ. |
| 5 | Hệ thống | như trên | Kiểm khóa có ghi **Capability** ở 1.2.3 hoặc làm `permissions_missing` đổi. | Không → bước 8. |
| 6 | Hệ thống | như trên | Dựng capability đầy đủ (0.7.2) và gửi `capability/update` (API 1) trên mọi phiên `/v1/ctl` đang mở: Android gửi tới mọi client, Mac/iOS gửi tới điện thoại.<br>Riêng `relay.enabled = false`: gửi xong mới đóng phiên đi qua relay (`session/bye`, `reason = shutdown`) và kết nối `/v1/relay`. | Không có phiên → E3. |
| 7 | Hệ thống | Hai bên | Bên nhận thay `features_json`, tính lại tính năng hiệu lực (CONN-01 API 7): mất hiệu lực → dừng tác vụ (API 1, logic 4); có hiệu lực mới → khởi chạy như sau `capability/hello` (SMS-01, CALL-04).<br>Đối phương bật một tính năng mà thiết bị này đang tắt (ví dụ Mac bật camera, điện thoại chưa bật) → hiện gợi ý bật, không tự bật. |  |
| 8 | Người dùng | như trên | Thấy trạng thái mới trên cả hai thiết bị (trường 24; PAIR-02 trường 8). |  |
| A1 | Người dùng | như trên | Chọn "Xóa thiết bị khỏi máy chủ" (trường 26) hoặc "Xóa toàn bộ dữ liệu HandLive" (trường 27), đọc cảnh báo (trường 29), xác nhận (trường 28). | "Hủy" → E8. |
| A2 | Hệ thống | như trên → R-API | Lấy JWT (API 3) rồi gọi `DELETE /v1/devices/me` (API 2) với `revoke_pairs=false` (chỉ xóa khỏi máy chủ) hoặc `revoke_pairs=true` (xóa toàn bộ). | Không có mạng hoặc 5xx: chỉ xóa khỏi máy chủ → E5; xóa toàn bộ → E7. 401 hoặc 404 khi lấy challenge → E6. |
| A3 | Hệ thống | R-API, R-DB, R-KV | Relay xóa dòng `devices` (các dòng `pairs` của thiết bị xóa theo CASCADE), đóng kết nối relay của thiết bị, trả 204 (API 2).<br>Chỉ khi `revoke_pairs=true`: gửi `pair_revoked` cho đối phương đang online và ghi `revoked_notice` cho đối phương offline.<br>Khi `revoke_pairs=false` relay không báo ai: đối phương chỉ thấy cặp không còn trên relay và tự chuyển sang chỉ dùng LAN (PAIR-02 API 1, logic 3). |  |
| A4 | Hệ thống | Thiết bị khởi tạo | **Xóa toàn bộ:** mỗi cặp đang có phiên LAN hoặc USB gửi `pair/revoke` (API 4, `reason = reinstall`), chờ `ack` tối đa 10 s, song song; dọn mọi cặp cục bộ như PAIR-03 bước 7 nhưng xóa hẳn bản ghi, không giữ bia mộ (relay đã xóa cặp); Android đăng ký lại mDNS không còn TXT `h`; sang A5.<br>**Chỉ xóa khỏi máy chủ:** giữ mọi cặp, đặt `relay_registered = 0` cho mọi cặp, ghi `relay.enabled = false`, gửi `capability/update` (`features.relay.enabled = false`), sang A6. | Xóa toàn bộ: phiên đi qua relay đã đóng ở A3, đối phương đó nhận `pair_revoked`. E7: vẫn gửi `pair/revoke` qua LAN. |
| A5 | Hệ thống | Thiết bị khởi tạo | Xóa toàn bộ (API 7): Android dừng A-SVC, gọi `disableSelf()` cho dịch vụ Hỗ trợ tiếp cận; xóa khóa (Keystore/Keychain), cơ sở dữ liệu, DataStore/`UserDefaults`, thông báo đã hiển thị; Mac hủy mục đăng nhập. | Không gỡ camera/micro ảo (CAM-01 A1), không thu hồi quyền hệ điều hành đã cấp. |
| A6 | Người dùng | như trên | Thấy "Đã xóa khỏi máy chủ" (thiết bị đã ghép vẫn dùng được trong LAN, kết nối qua Internet tắt), hoặc ứng dụng quay về màn hình chào mừng (SET-01/SET-03). |  |
| B1 | Người dùng | M-APP / I-APP | Chọn "Đồng bộ lại toàn bộ SMS" (trường 25) → SMS-01 A1–A2. | Chỉ khi có phiên tới điện thoại. |

### 1.2.5 Đặc tả API/service

**Danh sách lời gọi**

| # | API/service | Kênh | Chiều | Dùng ở bước |
|---|-------------|------|-------|-------------|
| 1 | `WS capability/update` | `/v1/ctl` (LAN, USB hoặc relay) | Hai chiều | 6, 7 |
| 2 | `DELETE /v1/devices/me` | REST relay | Thiết bị → R-API | A2, A3 |
| 3 | `POST /v1/auth/challenge`, `POST /v1/auth/token` | REST relay | Thiết bị → R-API | A2 |
| 4 | `WS pair/revoke` | `/v1/ctl` (LAN, USB) | Hai chiều | A4 |
| 5 | Relay op `pair_revoked` | `wss://{RELAY_HOST}/v1/relay` (text) | R-API → thiết bị | A3 |
| 6 | `POST /v1/devices`, `POST /v1/pairs` | REST relay | Thiết bị → R-API | 4 (bật `relay.enabled`) |
| 7 | Dịch vụ hệ điều hành xóa khóa và dữ liệu: `disableSelf`, `KeyStore.deleteEntry`, `SecItemDelete`, `removePersistentDomain`, `removeAllDeliveredNotifications`, `SMAppService.mainApp.unregister` | Cục bộ | — | 4, A4, A5 |

#### API 1 — `WS capability/update`

- **URL:** `wss://{android_host}:{port}/v1/ctl` (LAN hoặc USB) hoặc qua relay
  (`wss://{RELAY_HOST}/v1/relay`, lớp bọc `to` /`from`)
- **Method:** `WS capability/update` (hai chiều), envelope mã hóa, không ack (0.7.1).
- **Request (`data`):** ảnh chụp đầy đủ, cùng cấu trúc `capability/hello` (0.7.2). Ánh xạ khóa cài
  đặt → trường:

| Khóa cài đặt / trạng thái | Trường capability | Bên gửi |
|--------------------------|-------------------|---------|
| `feature.clipboard`, `feature.sms`, `feature.call` | `features.<tên>.enabled` | Tất cả |
| `feature.call_audio`, `feature.camera` | `features.call_audio.enabled`, `features.camera.enabled` | Android, Mac |
| `clip.auto_send` và dịch vụ Hỗ trợ tiếp cận đang chạy | `features.clipboard.auto_send` | Android (client luôn `true`) |
| `clip.send_images` | `features.clipboard.mimes` (`false` → chỉ `text/plain`) | Tất cả |
| `sms.notify` | `features.sms.notify` | iOS/iPadOS |
| `call.notify` | `features.call.notify` | iOS/iPadOS |
| `call_audio.allow_opus_fallback` | `features.call_audio.opus_fallback` (`false` → `available = false`, `reason = "disabled"`) | Android |
| `relay.enabled` | `features.relay.enabled` | Tất cả |
| Quyền Android (SET-01 API 2) | `permissions_missing`, `features.sms.can_send`, `features.sms.sims`, `features.call.can_answer`, `features.call.can_end`, `features.call.caller_id` | Android |

- **Response:** N/A (không ack). Bên nhận chỉ gửi `capability/update` của mình khi cấu hình của
  chính nó đổi.
- **Ví dụ:** điện thoại tắt SMS:

```json
{"op":"update","data":{"protocol":1,"app_version":"1.0.0 (100)","platform":"android","os_version":"15","model":"Pixel 8","features":{"clipboard":{"enabled":true,"auto_send":true,"max_text_bytes":1048576,"max_image_bytes":10485760,"mimes":["text/plain","image/png","image/jpeg"]},"sms":{"enabled":false,"can_send":true,"sims":[{"sub_id":1,"slot":0,"label":"SIM 1"}],"default_sub_id":1},"call":{"enabled":true,"can_answer":true,"can_end":true,"caller_id":true},"call_audio":{"enabled":false,"bt_address":null,"hfp_connected":false,"opus_fallback":{"available":false,"downlink":false,"uplink":false,"reason":"shizuku_not_running"}},"camera":{"enabled":false,"cameras":["front","back"],"max_width":1920,"max_height":1080,"max_fps":30,"codecs":["h264"]},"relay":{"enabled":true}},"permissions_missing":[]}}
```

iPhone tắt thông báo cuộc gọi:

```json
{"op":"update","data":{"protocol":1,"app_version":"1.0.0 (100)","platform":"ios","os_version":"18.6","model":"iPhone16,1","features":{"clipboard":{"enabled":true,"auto_send":true,"max_text_bytes":1048576,"max_image_bytes":10485760,"mimes":["text/plain","image/png","image/jpeg"]},"sms":{"enabled":true,"notify":true},"call":{"enabled":true,"notify":false},"relay":{"enabled":true}}}}
```

- **Logic nghiệp vụ:**
  1. Thời điểm gửi: khóa có ghi **Capability** (1.2.3) đổi; quyền Android hoặc trạng thái dịch vụ Hỗ
     trợ tiếp cận đổi (SET-01 bước 14); danh sách SIM đổi
     (`SubscriptionManager.OnSubscriptionsChangedListener`); `hfp_connected` đổi (AUDIO-02); khả
     năng Opus/WS đổi (AUDIO-01 bước 11).
  2. Luôn gửi ảnh chụp đầy đủ; bên nhận thay toàn bộ bản đã lưu, không gộp từng phần. Nhiều thay đổi
     trong 300 ms được gom thành một bản. Tính năng nền tảng không có (ví dụ `camera` trên iOS) vắng
     mặt trong `features` và được coi là `enabled = false`.
  3. Gửi trên mọi phiên `/v1/ctl` đang `Connected`; không xếp hàng khi không có phiên — phiên kế
     tiếp mở bằng `capability/hello` mang giá trị mới (E3).
  4. Bên nhận cập nhật `features_json` (Query), tính lại tính năng hiệu lực (CONN-01 API 7) và dừng
     tác vụ của tính năng mất hiệu lực:

| Tính năng mất hiệu lực | Tác vụ bị dừng |
|------------------------|----------------|
| `clipboard` | Hủy truyền ảnh đang dở (`clipboard/cancel`); ngừng gửi clip mới tới thiết bị đó |
| `sms` | Dừng SMS-01 sau trang đang xử lý; dòng `sms_outbox` còn `pending` được giữ, gửi khi hiệu lực trở lại |
| `call` | Đóng panel và thông báo cuộc gọi đang hiện trên Mac/iOS |
| `call_audio` | Đóng luồng Opus/WS (`call_audio/close`, AUDIO-04) hoặc trả âm thanh HFP về điện thoại (AUDIO-03) |
| `camera` | `camera/stop` phiên đang phát (CAM-02) |
| `relay` (đối phương báo `features.relay.enabled = false`) | Không dùng relay tới thiết bị đó: client không chạy CONN-03, không gửi push `wake`; Android không gửi push `alert` |

  5. Tính năng hiệu lực trở lại → khởi chạy như sau `capability/hello` (CONN-01 bước 10: SMS-01,
     CALL-04).
  6. Không log nội dung capability; log chỉ gồm `type`, `op`, kích thước (0.5.1 quy tắc 5).

#### API 2 — `DELETE /v1/devices/me`

- **URL:** `https://{RELAY_HOST}/v1/devices/me?revoke_pairs=<true|false>`
- **Method:** `DELETE`, header `Authorization: Bearer <jwt>`
- **Request:** không có body; thiết bị bị xóa là `sub` của JWT. Tham số truy vấn:

| Tham số | Kiểu | Bắt buộc | Mô tả |
|---------|------|----------|-------|
| `revoke_pairs` | bool | Có | `false` — "Xóa thiết bị khỏi máy chủ": gỡ đăng ký im lặng, các cặp vẫn dùng được trong LAN. `true` — "Xóa toàn bộ dữ liệu HandLive": thu hồi mọi cặp và báo đối phương |
- **Response:**

| HTTP | Body | Khi nào |
|------|------|---------|
| 204 | — | Đã xóa, hoặc thiết bị không còn trên relay (gọi lặp) |
| 401 `TOKEN_EXPIRED` | lỗi | JWT hết hạn → lấy token mới rồi thử lại một lần (E6) |
| 429 `RATE_LIMITED` | lỗi | Chờ `Retry-After` |

- **Ví dụ:**

```http
DELETE /v1/devices/me?revoke_pairs=true HTTP/1.1
Host: relay.example.com
Authorization: Bearer eyJhbGciOiJIUzI1NiJ9.eyJzdWIiOiI1YjFmOGMyZS05YTRkLThlNmYtYTFiMi1jM2Q0ZTVmNjA3MTgifQ.sig

HTTP/1.1 204 No Content
```

Với `revoke_pairs=true`, relay báo cho điện thoại đang online:

```json
{"op":"pair_revoked","pair_id":"3f2b1c4d-5e6f-4a7b-8c9d-0e1f2a3b4c5d","by":"5b1f8c2e-9a4d-8e6f-a1b2-c3d4e5f60718"}
```

- **Logic nghiệp vụ:**
  1. Chỉ xóa chính thiết bị gọi (`sub`); không có biến thể nhận `device_id` trong đường dẫn.
  2. Một giao dịch: đọc các cặp chưa thu hồi và đối phương của chúng, rồi `DELETE FROM devices` —
     `pairs` bị xóa theo `ON DELETE CASCADE` (kể cả cặp đã thu hồi). Không còn dòng → vẫn 204.
  3. `revoke_pairs=true`: sau commit, với mỗi đối phương, thêm `<pair_id>|<device_id>` vào
     `revoked_notice:<peer_device_id>` (TTL 30 ngày); nếu có `presence:<peer_device_id>` → publish
     `pair_revoked` lên `dev:<peer_device_id>` ngay. Đối phương offline nhận `pair_revoked` khi kết
     nối relay lần sau (CONN-03 API 4) — cần khóa này vì dòng `pairs` đã bị xóa nên truy vấn "cặp đã
     thu hồi trong 30 ngày" của PAIR-03 API 4 không còn thấy. Thiết bị nhận xử lý như PAIR-03 API 4
     (nhận lặp thì bỏ qua).
  4. `revoke_pairs=false`: không báo ai. Đối phương giữ cặp; lần gọi `GET /v1/pairs` kế tiếp thấy
     cặp không còn trên relay và chuyển sang chỉ dùng LAN (PAIR-02 API 1, logic 3).
  5. Xóa `presence:<device_id>` và `chal:<device_id>` trước, rồi đóng kết nối `/v1/relay` của thiết bị
     (lệnh đóng nội bộ qua `dev:<device_id>`, mã 1000). Presence đã bị xóa nên đối phương không nhận
     `presence` offline. Với `revoke_pairs=false`, kết nối relay của đối phương chỉ bỏ cặp đó (C16).
  6. JWT cũ còn hạn (≤ 15 phút) không dùng tiếp được: endpoint dùng JWT kiểm `devices` còn dòng của
     `sub`, không còn → 404 `DEVICE_NOT_FOUND`; `/v1/relay` từ chối nâng cấp. Muốn dùng relay lại
     phải `POST /v1/devices` (tạo dòng mới).
  7. `usage_daily` không bị xóa (không chứa `device_id`, chỉ `device_hash` có muối theo tháng, tự
     hết sau 30 ngày); log relay chỉ ghi `device_hash`.
  8. Áp hạn mức chung của REST (`RELAY_RATE_LIMIT`).

#### API 3 — Xác thực relay

Đặc tả ở 0.6.4 và CONN-03 API 2–3 (`POST /v1/auth/challenge`, `POST /v1/auth/token`). Token còn hạn > 60 s thì dùng lại. `POST /v1/auth/challenge` trả 404 `DEVICE_NOT_FOUND` → thiết bị đã bị xóa trước
đó, coi A2 là thành công (E6).

#### API 4 — `WS pair/revoke`

Đặc tả như PAIR-03 API 1. Chỉ dùng khi xóa toàn bộ, `reason = reinstall`; gửi trên phiên LAN hoặc
USB (phiên qua relay đã bị đóng ở A3). "Xóa thiết bị khỏi máy chủ" không gửi `pair/revoke`. Phải gửi
trước khi xóa khóa, vì sau khi xóa `PRK` không mã hóa được nữa.

#### API 5 — Relay op `pair_revoked`

Đặc tả như PAIR-03 API 4, `by` = `device_id` của thiết bị vừa xóa. Ở chức năng này relay phát theo
API 2 logic 3: ngay khi xóa (đối phương online) và khi đối phương kết nối lại relay.

#### API 6 — `POST /v1/devices`, `POST /v1/pairs`

Đặc tả ở CONN-03 API 1 và PAIR-01 API 8. Gọi khi `relay.enabled` chuyển sang `true`: đăng ký thiết
bị (upsert), rồi `POST /v1/pairs` cho từng cặp `relay_registered = 0` (Query); Android và iOS đăng
ký lại push token (CONN-04 API 1). Lỗi → thử lại nền, không chặn công tắc.

#### API 7 — Xóa khóa và dữ liệu cục bộ

- **URL:** N/A
- **Method:**
  - Android: `ClipboardAccessibilityService.disableSelf()`; `stopForeground(STOP_FOREGROUND_REMOVE)`
    rồi `stopSelf()`; `NotificationManagerCompat.cancelAll()`;
    `KeyStore.getInstance("AndroidKeyStore").deleteEntry("hl_master")`;
    `context.deleteSharedPreferences("hl_keys")`; xóa tệp PKCS#12;
    `context.deleteDatabase("handlive.db")`; `dataStore.edit { it.clear() }`.
  - Mac/iOS: `SecItemDelete` theo service `app.handlive.keys` (xóa `ik_sig`, `ik_dh`, `db_key` và
    mọi `PRK`); đóng `DatabasePool` rồi xóa `handlive.sqlite`, `-wal`, `-shm`;
    `UserDefaults.standard.removePersistentDomain(forName: "app.handlive.mac")` (Mac) hoặc
    `UserDefaults(suiteName: "group.app.handlive")?.removePersistentDomain(forName: "group.app.handlive")`
    (iOS); `UNUserNotificationCenter.current().removeAllDeliveredNotifications()` và
    `removeAllPendingNotificationRequests()`; Mac: `try SMAppService.mainApp.unregister()`.
- **Request:** N/A.
- **Response:** mã kết quả từng lời gọi; `errSecItemNotFound` hoặc tệp không tồn tại coi như thành
  công; lỗi khác thử lại một lần rồi báo.
- **Ví dụ:** Mac:
  `SecItemDelete([kSecClass: kSecClassGenericPassword, kSecAttrService: "app.handlive.keys"])` →
  `errSecSuccess`; sau đó `handlive.sqlite` bị xóa; lần mở sau chạy SET-03 và sinh `device_id` mới.
- **Logic nghiệp vụ:**
  1. Thứ tự: mọi bước cần khóa chạy trước (A2 ký challenge bằng `ik_sig`, A4 mã hóa `pair/revoke`
     bằng khóa phiên dẫn từ `PRK`) → xóa khóa → xóa cơ sở dữ liệu (SQL ở Query, rồi xóa tệp) → xóa
     cài đặt và thông báo → về màn hình chào mừng.
  2. Xóa `db_key` làm mọi trang SQLCipher còn sót không đọc được, kể cả khi xóa tệp lỗi. Trên
     Android, xóa `hl_master` làm keyset và mật khẩu PKCS#12 còn sót không giải mã được.
  3. Android: dừng A-SVC trước để không còn kết nối; gọi `disableSelf()` vì trạng thái bật dịch vụ
     Hỗ trợ tiếp cận nằm trong cài đặt hệ thống, không mất theo dữ liệu ứng dụng.
  4. Không gỡ M-CAMX, M-MIC; không thu hồi quyền hệ điều hành đã cấp.
  5. Chỉ xóa khỏi máy chủ: chỉ dọn cặp (Query, A4) và ghi `relay.enabled = false`; không gọi các API
     xóa khóa và cài đặt.

#### Query

```text
# [Thiết kế] Đọc/ghi khóa cài đặt (bước 1, 4, A4, A5)
dataStore.data.map { it[booleanPreferencesKey("feature.sms")] ?: true }            # Android, đọc trường 7
dataStore.edit { it[booleanPreferencesKey("feature.sms")] = false }                 # Android, bước 4
dataStore.edit { it[intPreferencesKey("clip.auto_clear_s")] = 300 }                 # Android, bước 4
UserDefaults.standard.set(false, forKey: "relay.enabled")                           # Mac, bước 4 hoặc A4 (chỉ xóa khỏi máy chủ)
UserDefaults(suiteName: "group.app.handlive")?.set(false, forKey: "call.notify")    # iOS, bước 4
dataStore.edit { it.clear() }                                                        # Android, A5
```

```sql
-- [Thiết kế] Hai phía, bước 7: lưu capability mới của đối phương
UPDATE paired_device SET features_json = :features_json WHERE pair_id = :pair_id;

-- [Thiết kế] Mọi thiết bị, bước 4 (bật relay.enabled): cặp chưa đăng ký relay
SELECT pair_id FROM paired_device WHERE revoked_at IS NULL AND relay_registered = 0;

-- [Thiết kế] Android, A4 (một giao dịch): dọn mọi cặp, không giữ bia mộ
DELETE FROM push_outbox;
DELETE FROM paired_device;

-- [Thiết kế] Mac/iOS, A4 (một giao dịch): dọn dữ liệu đồng bộ và cặp (PRK xóa riêng trong Keychain)
DELETE FROM sms_message;
DELETE FROM sms_thread;
DELETE FROM sms_outbox;
DELETE FROM call_log_entry;
DELETE FROM sync_cursor;
DELETE FROM paired_device;

-- [Thiết kế] Android, A5 (một giao dịch, trước khi xóa tệp handlive.db)
DELETE FROM push_outbox;
DELETE FROM sms_observer_state;
DELETE FROM paired_device;

-- [Thiết kế] Mac, A5: bảng chấp thuận (chỉ có trên Mac), trước khi xóa tệp handlive.sqlite
DELETE FROM consent_record;

-- [Thiết kế] Relay, API 2 (một giao dịch): đối phương của các cặp hiệu lực, rồi xóa thiết bị
SELECT pair_id,
       CASE WHEN device_a = $1 THEN device_b ELSE device_a END AS peer_device_id
FROM pairs
WHERE (device_a = $1 OR device_b = $1) AND revoked_at IS NULL;
DELETE FROM devices WHERE device_id = $1;   -- pairs xóa theo ON DELETE CASCADE

-- [Thiết kế] Relay, API 2 logic 5: thiết bị của JWT còn tồn tại (dùng ở các endpoint JWT khác)
SELECT 1 FROM devices WHERE device_id = $1 AND revoked_at IS NULL;
```

```text
# [Thiết kế] Redis, API 2
SADD     revoked_notice:<peer_device_id> "<pair_id>|<device_id>"      # mỗi đối phương, chỉ khi revoke_pairs=true
EXPIRE   revoked_notice:<peer_device_id> 2592000                       # 30 ngày
EXISTS   presence:<peer_device_id>
PUBLISH  dev:<peer_device_id> {"op":"pair_revoked","pair_id":"<pair_id>","by":"<device_id>"}
DEL      presence:<device_id> chal:<device_id>                          # trước: đối phương không nhận presence offline
PUBLISH  dev:<device_id> <lệnh đóng kết nối nội bộ>
# [Thiết kế] Redis, khi một thiết bị kết nối relay (bổ sung CONN-03 API 4)
SMEMBERS revoked_notice:<device_id>
```

---

## 1.3 SET-03 — Thiết lập ban đầu trên Mac và iOS

### 1.3.1 Thông tin chung

| Mục | Nội dung |
|-----|----------|
| Tên | SET-03 — Thiết lập ban đầu trên Mac và iOS |
| Mô tả | Lần chạy đầu của HandLive for Mac (M-APP, ứng dụng menu bar) và HandLive for iOS/iPadOS (I-APP).<br>**Chung:** màn hình chào mừng kèm giải thích quyền riêng tư; tạo khóa định danh `ik_sig`, `ik_dh`, tính `device_id` và tạo khóa SQLCipher `db_key` trong Keychain (0.6.1, 0.6.5); xin quyền thông báo (`UNUserNotificationCenter`, kèm mức nhạy cảm thời gian — time-sensitive — cho cuộc gọi đến); gợi hộp thoại quyền mạng cục bộ bằng lần duyệt Bonjour đầu tiên; cuối cùng đăng ký thiết bị với relay khi `relay.enabled = true` (CONN-03 API 1) và chuyển sang PAIR-01.<br>**Mac:** kiểm ứng dụng chạy từ `/Applications` (bắt buộc cho camera ảo — C11) và đề nghị chuyển; hỏi "Hiện HandLive trên thanh menu"; "Mở khi đăng nhập" bằng `SMAppService.mainApp.register()`; hướng dẫn quyền dán theo C10 (`NSPasteboard.accessBehavior`, macOS 15.4+).<br>Quyền Bluetooth và camera không hỏi ở đây mà ở AUDIO-01 và CAM-01.<br>**iOS/iPadOS:** giải thích giới hạn nền tảng — clipboard chỉ đồng bộ khi ứng dụng ở foreground, không có âm thanh cuộc gọi, SMS và cuộc gọi đến tới qua push khi ứng dụng đóng (C7). |
| Tác nhân | Chính: Người dùng. Hệ thống: M-APP hoặc I-APP, OS (Keychain, quyền riêng tư/TCC, Notification Center, Service Management, Bonjour), R-API (đăng ký thiết bị), PUSH (APNs, chỉ iOS/iPadOS). |
| Điều kiện trước | M-APP (Developer ID, đã notarize, macOS 13+) hoặc I-APP (App Store, iOS/iPadOS 16+) vừa được cài; chưa có `setup.completed_at`. |
| Điều kiện sau | **Thành công:** Keychain có `ik_sig`, `ik_dh`, `db_key`; `handlive.sqlite` đã tạo với lược đồ 0.9.3; quyền thông báo và quyền mạng cục bộ đã được hỏi; Mac: biểu tượng thanh menu và mục đăng nhập theo lựa chọn của người dùng, đã biết vị trí ứng dụng và trạng thái quyền dán; iOS/iPadOS: người dùng đã đọc giới hạn; `setup.completed_at` được ghi; thiết bị đã đăng ký relay (nếu bật) hoặc chờ thử lại nền; giao diện chuyển sang PAIR-01.<br>**Thất bại (E1):** không ghi `setup.completed_at`, không sang PAIR-01. |
| Ngoại lệ | E1 — Tạo khóa hoặc ghi Keychain lỗi (`errSecInteractionNotAllowed`, `errSecMissingEntitlement`): báo lỗi, cho thử lại; không sang PAIR-01.<br>E2 — Mac: ứng dụng không chạy từ `/Applications` (mở thẳng từ ảnh đĩa hoặc thư mục Tải về, bị App Translocation, hoặc không có quyền ghi thư mục Ứng dụng): đề nghị chuyển; người dùng để sau hoặc chuyển lỗi → tiếp tục, ghi chú camera ảo chưa dùng được (CAM-01 E1).<br>E3 — Từ chối thông báo: vẫn dùng được; Mac không có thông báo SMS và cuộc gọi nhỡ (panel cuộc gọi vẫn hiện khi ứng dụng chạy); iOS/iPadOS không nhận SMS, cuộc gọi khi ứng dụng đóng (CONN-04 trường 1 = `denied`); hiện hướng dẫn bật lại. Mac: "Thông báo đang tắt nên không thấy SMS mới và cuộc gọi nhỡ. Bật lại trong Cài đặt hệ thống › Thông báo › HandLive." iPhone, iPad: "Thông báo đang tắt nên không thấy SMS mới và cuộc gọi đến khi HandLive đóng. Bật lại trong Cài đặt › Thông báo › HandLive."<br>Mức nhạy cảm thời gian bị tắt → thông báo cuộc gọi có thể bị chế độ Tập trung chặn.<br>E4 — Từ chối mạng cục bộ: không tìm được điện thoại trong LAN (CONN-01 E8); ghép nối và kết nối chỉ qua relay (PAIR-01 bằng QR có `rv`, không dùng được PIN); hiện hướng dẫn bật lại. Mac: "HandLive không tìm được điện thoại trong mạng Wi-Fi. Bật HandLive trong Cài đặt hệ thống › Quyền riêng tư & Bảo mật › Mạng cục bộ." iPhone, iPad: "HandLive không tìm được điện thoại trong mạng Wi-Fi. Bật HandLive trong Cài đặt › Quyền riêng tư & Bảo mật › Mạng cục bộ."<br>E5 — Mac: `SMAppService` trả `.requiresApproval` hoặc lỗi: hướng dẫn bật trong Cài đặt hệ thống › Cài đặt chung › Mục đăng nhập; không chặn.<br>E6 — macOS 15.4+: `accessBehavior` là `.ask` hoặc `.alwaysDeny`: hướng dẫn Cài đặt hệ thống › Quyền riêng tư & Bảo mật › Dán từ ứng dụng khác (C10); Apple không có API xin "Luôn cho phép"; không chặn.<br>E7 — Không có mạng hoặc relay lỗi khi đăng ký thiết bị hoặc push token: bỏ qua, thử lại nền (CONN-03, CONN-04); không chặn. |
| Yêu cầu đặc biệt | **Khai báo nền tảng:** Info.plist `NSLocalNetworkUsageDescription` ("HandLive tìm điện thoại Android của bạn trong mạng Wi-Fi để kết nối trực tiếp, không qua Internet.") và `NSBonjourServices` = `["_handlive._tcp"]`; entitlement `com.apple.developer.usernotifications.time-sensitive`; Mac: `LSUIElement` = `YES` (khởi động không có biểu tượng Dock); app đổi `NSApplication.setActivationPolicy(_:)` giữa `.accessory` (chỉ biểu tượng thanh menu) và `.regular` (biểu tượng Dock, thanh menu HandLive · Tệp · Sửa · Xem · Cửa sổ · Trợ giúp, Dock menu) khi mở cửa sổ Tin nhắn, Xem trước camera hoặc khi tắt "Hiện HandLive trên thanh menu"; `NSMicrophoneUsageDescription` ("HandLive dùng micro để bạn nói trong cuộc gọi chuyển từ điện thoại.") và `NSFocusStatusUsageDescription` ("HandLive đọc trạng thái Tập trung để không đổ chuông và không hiện cuộc gọi khi bạn đang tập trung.") dùng ở AUDIO-01 và CALL-01; iOS/iPadOS: `aps-environment`, App Group `group.app.handlive` và keychain access group dùng chung với I-NSE.<br>**Quyền riêng tư:** chỉ hỏi quyền cần cho chức năng cốt lõi; Bluetooth (AUDIO-01) và camera (CAM-01) chỉ hỏi khi người dùng bật tính năng; mỗi hộp thoại hệ thống đi sau một màn hình giải thích chỉ có một nút "Tiếp tục" (HIG); người dùng từ chối ngay trong hộp thoại hệ thống.<br>**Khả dụng:** ≤ 6 màn hình, hoàn tất ≤ 60 s; đọc được bằng VoiceOver; mọi bước sau tạo khóa đều đi tiếp được mà không chặn; iOS/iPadOS đặt kỳ vọng rõ, không hứa tính năng không có.<br>**Bảo mật:** Keychain `kSecAttrAccessibleWhenUnlockedThisDeviceOnly` (0.6.1); khóa riêng chỉ nằm trong Keychain và bộ nhớ tiến trình; cài lại ứng dụng sinh `device_id` mới (0.2). |

### 1.3.2 Màn hình

N/A — chưa có wireframe được duyệt.

### 1.3.3 Mô tả chi tiết các thành phần

| # | Trường | Kiểu dữ liệu | Input/Output | Giá trị khởi tạo | Mô tả |
|---|--------|--------------|--------------|------------------|-------|
| 1 | Giới thiệu và quyền riêng tư | string | Output | Nội dung cố định | "HandLive đưa bảng nhớ tạm, tin nhắn SMS và cuộc gọi từ điện thoại Android lên máy này. Dữ liệu được mã hóa đầu-cuối, chỉ đi giữa các thiết bị của bạn; máy chủ không đọc được nội dung. Không cần tài khoản." |
| 2 | Nút "Bắt đầu" | action | Input | — | Sang bước 4 |
| 3 | Mở HandLive khi đăng nhập | bool | Input/Output | `true` | Mac. Hộp chọn trên màn hình chào mừng; `true` → `SMAppService.mainApp.register()` ở bước 6 |
| 4 | Vị trí ứng dụng | enum{applications\| other\| translocated} | Output | Theo `Bundle.main.bundleURL` | Mac. `other`, `translocated` hiện trường 5 |
| 5 | Đề nghị chuyển vào thư mục Ứng dụng | enum{Chuyển\| Để sau} | Input | — | Mac. "Camera ảo chỉ hoạt động khi HandLive nằm trong thư mục Ứng dụng. Chuyển ngay?" |
| 6 | Trạng thái mục đăng nhập | enum{enabled\| requires_approval\| not_registered\| not_found} | Output | `SMAppService.mainApp.status` | Mac. `requires_approval` hiện trường 12, 13 (E5) |
| 7 | Quyền thông báo | enum{allowed\| denied\| not_determined} | Input/Output | `not_determined` | Theo `authorizationStatus`; `denied` hiện hướng dẫn (E3); trên iOS là CONN-04 trường 1 |
| 8 | Mức nhạy cảm thời gian | enum{enabled\| disabled\| not_supported} | Output | Theo `timeSensitiveSetting` | `disabled` hiện cảnh báo "Thông báo cuộc gọi có thể bị chế độ Tập trung chặn" |
| 9 | Quyền mạng cục bộ | enum{allowed\| denied\| unknown\| not_required} | Output | `unknown`; `not_required` trên macOS 13–14 | Suy ra từ trạng thái `NWBrowser` (API 5); `denied` hiện hướng dẫn (E4) |
| 10 | Quyền dán từ ứng dụng khác | enum{default\| ask\| always_allow\| always_deny\| not_applicable} | Output | `not_applicable` trước macOS 15.4 | Mac. `ask`, `always_deny` hiện hướng dẫn (E6) |
| 11 | Giới hạn trên iPhone/iPad | string | Output | Nội dung cố định | iOS/iPadOS. "Bảng nhớ tạm đồng bộ khi HandLive đang mở trên máy này: chạm nút Dán để gửi, không bị hỏi quyền dán. iPhone/iPad không nghe gọi được. Khi HandLive đóng, SMS và cuộc gọi đến hiện dưới dạng thông báo." |
| 12 | Hướng dẫn mở Cài đặt hệ thống | string | Output | Ẩn | Nội dung theo E3–E6, nêu đúng đường dẫn cài đặt của phiên bản hệ điều hành |
| 13 | Nút "Mở Cài đặt hệ thống" (Mac), "Mở cài đặt" (iPhone, iPad) | action | Input | Hiện cùng trường 12 | Mở trang cài đặt tương ứng (API 3–6) |
| 14 | Nút "Tiếp tục" | action | Input | — | Nút duy nhất trên mỗi màn hình giải thích quyền và hướng dẫn; không có "Bỏ qua" — người dùng từ chối ngay trong hộp thoại hệ thống (HIG, design system) |
| 15 | Thông báo lỗi | string | Output | Rỗng | Theo E1–E7 |
| 16 | Hiện HandLive trên thanh menu | bool | Input/Output | `true` | Mac. Hộp chọn trên màn hình chào mừng → `mac.menu_bar_extra` (SET-02 trường 31); `false` → app giữ biểu tượng Dock làm lối vào chính (bước 6) |

### 1.3.4 Luồng nghiệp vụ

```mermaid
flowchart TB
  subgraph ND["Người dùng"]
    U1["(1) Mở HandLive lần đầu"]
    U3["(3) Đọc giới thiệu, bấm Bắt đầu"]
    U5["(5) Chuyển vào thư mục Ứng dụng hoặc để sau"]
    U8["(8) Cho phép hoặc từ chối thông báo"]
    U10["(10) Cho phép hoặc từ chối mạng cục bộ"]
    U12["(12) Đọc hướng dẫn, bấm Tiếp tục"]
  end
  subgraph HT["Hệ thống"]
    S2["(2) Tạo khóa định danh, device_id, khóa SQLCipher"]
    D4{"(4) Mac chạy từ /Applications?"}
    S6["(6) Mac: đăng ký Mở khi đăng nhập, đặt biểu tượng thanh menu"]
    S7["(7) Giải thích, xin quyền thông báo"]
    S9["(9) Giải thích, duyệt Bonjour để hệ thống hỏi mạng cục bộ"]
    S11["(11) Mac: kiểm quyền dán. iOS: giải thích giới hạn"]
    S13["(13) Lưu setup.completed_at, đăng ký relay nền, chuyển PAIR-01"]
    X1(["Kết thúc: báo lỗi, cho thử lại"])
  end
  U1 --> S2
  S2 -- "Lỗi Keychain (E1)" --> X1
  S2 --> U3 --> D4
  D4 -- "Có" --> S6
  D4 -- "Không (E2)" --> U5
  D4 -- "iOS" --> S7
  U5 -- "Để sau hoặc chuyển lỗi" --> S6
  U5 -- "Chuyển, ứng dụng mở lại" --> U1
  S6 --> S7 --> U8
  U8 -- "Cho phép hoặc từ chối (E3)" --> S9
  S9 -- "macOS 13 đến 14" --> S11
  S9 --> U10
  U10 -- "Cho phép hoặc từ chối (E4)" --> S11
  S11 --> U12 --> S13
```

| Bước | Tác nhân | Thành phần | Mô tả | Ngoại lệ / Ghi chú |
|------|----------|-----------|-------|--------------------|
| 1 | Người dùng | M-APP / I-APP | Mở HandLive (Mac: Finder, Launchpad; iOS/iPadOS: màn hình chính).<br>Ứng dụng đọc `setup.completed_at`: có → khởi động bình thường; không → thiết lập ban đầu.<br>Mac tạo biểu tượng thanh menu (`MenuBarExtra` kiểu menu) ngay khi khởi động với trạng thái "Chưa ghép nối" và mở cửa sổ thiết lập. | Thiết lập bị gián đoạn hoặc Mac vừa chuyển ứng dụng → chạy lại từ đầu; mỗi bước tự bỏ qua nếu đã đạt. |
| 2 | Hệ thống | M-APP / I-APP, OS (Keychain) | Chưa có `setup.started_at` (cài mới) → xóa mục Keychain còn sót của lần cài trước (service `app.handlive.keys` — iOS/macOS giữ Keychain sau khi gỡ ứng dụng), tạo `ik_sig`, `ik_dh` (CryptoKit) và `db_key` 32 byte (`SecRandomCopyBytes`), lưu Keychain (API 1); tạo `handlive.sqlite` với lược đồ 0.9.3 (iOS/iPadOS: trong App Group container); ghi `setup.started_at`.<br>Đã có `setup.started_at` → nạp khóa sẵn có.<br>Tính `device_id` (0.2).<br>Hiện màn hình chào mừng (trường 1). | Lỗi → E1. |
| 3 | Người dùng | M-APP / I-APP | Đọc giới thiệu; Mac: giữ hoặc bỏ chọn "Mở HandLive khi đăng nhập" (trường 3) và "Hiện HandLive trên thanh menu" (trường 16); bấm "Bắt đầu". |  |
| 4 | Hệ thống | M-APP | Mac: kiểm `Bundle.main.bundleURL` nằm dưới `/Applications/`; đường dẫn chứa `/AppTranslocation/` → `translocated` (trường 4). iOS/iPadOS → bước 7. | Không nằm dưới `/Applications/` → E2, bước 5. |
| 5 | Người dùng | M-APP | Chọn "Chuyển" hoặc "Để sau" (trường 5). "Chuyển": M-APP chép bundle vào `/Applications`, mở bản mới, thoát bản cũ (API 2); bản mới chạy lại từ bước 1. | `translocated` hoặc không có quyền ghi → hướng dẫn kéo HandLive vào thư mục Ứng dụng trong Finder rồi mở lại (E2). |
| 6 | Hệ thống | M-APP, OS | Trường 3 = `true` → `SMAppService.mainApp.register()` (API 3), đọc `status` cho trường 6.<br>Ghi trường 16 vào `mac.menu_bar_extra`: `true` → biểu tượng thanh menu hiện, app ở `.accessory`; `false` → app `.regular` với biểu tượng Dock.<br>App chuyển `.regular` khi mở cửa sổ Tin nhắn hoặc Xem trước camera và về `.accessory` khi đóng chúng nếu biểu tượng thanh menu đang hiện.<br>Mở lại HandLive khi đang chạy (Finder, Launchpad) hiện cửa sổ chính. | `.requiresApproval` hoặc lỗi → E5. |
| 7 | Hệ thống | M-APP / I-APP | Hiện giải thích "Thông báo cho bạn biết có SMS mới và cuộc gọi đến; cuộc gọi đến dùng mức nhạy cảm thời gian để đến kịp lúc", rồi `requestAuthorization(options: [.alert, .sound, .badge])` (API 4); đăng ký các category thông báo do SMS-02, CALL-01 định nghĩa. | Đã quyết định từ trước → không hỏi lại, chỉ đọc trạng thái. |
| 8 | Người dùng | OS | Chọn "Cho phép" hoặc "Không cho phép". | Từ chối → E3. |
| 9 | Hệ thống | M-APP / I-APP | iOS/iPadOS và macOS 15+: hiện giải thích quyền mạng cục bộ ("HandLive tìm điện thoại Android trong mạng Wi-Fi để kết nối trực tiếp."), rồi chạy `NWBrowser` cho `_handlive._tcp` (API 5) — lần duyệt Bonjour đầu tiên làm hệ thống hiện hộp thoại. macOS 13–14 không có quyền này → trường 9 = `not_required`, sang bước 11. |  |
| 10 | Người dùng | OS | Chọn "Cho phép" hoặc "Không cho phép" trong hộp thoại hệ thống hỏi cho HandLive tìm và kết nối với thiết bị trên mạng cục bộ. | Từ chối → E4. |
| 11 | Hệ thống | M-APP / I-APP | Mac, macOS 15.4+: đọc `NSPasteboard.general.accessBehavior` (API 6); `.ask` hoặc `.alwaysDeny` → hiện hướng dẫn (trường 12, E6). iOS/iPadOS: hiện giới hạn nền tảng (trường 11). |  |
| 12 | Người dùng | M-APP / I-APP | Đọc hướng dẫn, có thể bấm "Mở Cài đặt" (trường 13), rồi bấm "Tiếp tục". |  |
| 13 | Hệ thống | M-APP / I-APP → R-API | Ghi `setup.completed_at`. Nếu `relay.enabled = true` và có Internet: chạy nền `POST /v1/devices` (CONN-03 API 1); iOS/iPadOS: `registerForRemoteNotifications()` rồi `PUT /v1/devices/me/push-token` (CONN-04 API 1). Chuyển sang PAIR-01 bước 1 ("Thêm điện thoại…"). | Relay lỗi → E7. |

### 1.3.5 Đặc tả API/service

**Danh sách lời gọi**

| # | API/service | Kênh | Chiều | Dùng ở bước |
|---|-------------|------|-------|-------------|
| 1 | Tạo khóa và lưu Keychain: CryptoKit `Curve25519.Signing.PrivateKey()`, `Curve25519.KeyAgreement.PrivateKey()`, `SecRandomCopyBytes`, `SecItemAdd`, `SecItemDelete` | Cục bộ | — | 2 |
| 2 | Chuyển ứng dụng vào `/Applications`: `FileManager.copyItem`, `NSWorkspace.openApplication` | Cục bộ | — | 5 |
| 3 | `SMAppService.mainApp.register()`, `status`, `SMAppService.openSystemSettingsLoginItems()` | Cục bộ | — | 6 |
| 4 | `UNUserNotificationCenter.requestAuthorization`, `getNotificationSettings` | Cục bộ | — | 7, 8 |
| 5 | `NWBrowser` — lời nhắc quyền mạng cục bộ | Multicast LAN | — | 9, 10 |
| 6 | `NSPasteboard.accessBehavior` | Cục bộ | — | 11 |
| 7 | `POST /v1/devices` | REST relay | Thiết bị → R-API | 13 |
| 8 | `UIApplication.registerForRemoteNotifications`, `PUT /v1/devices/me/push-token` | APNs, REST relay | I-APP → R-API | 13 |

#### API 1 — Tạo khóa và lưu Keychain

- **URL:** N/A
- **Method:** `Curve25519.Signing.PrivateKey()`, `Curve25519.KeyAgreement.PrivateKey()`,
  `SecRandomCopyBytes(kSecRandomDefault, 32, &bytes)`; `SecItemAdd`, `SecItemCopyMatching`,
  `SecItemDelete`.
- **Request — thuộc tính mục Keychain:**

| Thuộc tính | Giá trị |
|-----------|---------|
| `kSecClass` | `kSecClassGenericPassword` |
| `kSecAttrService` | `app.handlive.keys` |
| `kSecAttrAccount` | `ik_sig`, `ik_dh`, `db_key` (`PRK` dùng account = `pair_id`, PAIR-01) |
| `kSecValueData` | `rawRepresentation` 32 byte của khóa riêng; `db_key` 32 byte ngẫu nhiên |
| `kSecAttrAccessible` | `kSecAttrAccessibleWhenUnlockedThisDeviceOnly` |
| `kSecAttrAccessGroup` | iOS/iPadOS: nhóm dùng chung với I-NSE; Mac: nhóm mặc định của ứng dụng |
| `kSecUseDataProtectionKeychain` | Mac: `true` (cần để dùng lớp bảo vệ `WhenUnlockedThisDeviceOnly` trên macOS) |

- **Response:** `errSecSuccess`; `errSecDuplicateItem` → đọc mục sẵn có (thiết lập chạy lại);
  `errSecInteractionNotAllowed` hoặc `errSecMissingEntitlement` → E1.
- **Ví dụ:** `ik_sig_pub` = `7Kx9vQ2mTn4pL8rWz1YcHd6fJb3gSa5eUo0iVtNkQxA` → `device_id` =
  `5b1f8c2e-9a4d-8e6f-a1b2-c3d4e5f60718` (Mac trong ví dụ PAIR-01).
- **Logic nghiệp vụ:**
  1. Cài mới (không có `setup.started_at`) → `SecItemDelete` theo service `app.handlive.keys` trước
     khi tạo: Keychain của iOS/macOS còn giữ mục sau khi gỡ ứng dụng; không dọn thì bản cài lại giữ
     `device_id` cũ và `PRK` của cặp không còn, trái 0.2.
  2. Tạo khóa khi ứng dụng ở foreground (máy đang mở khóa) nên `WhenUnlockedThisDeviceOnly` không
     cản; lỗi → E1.
  3. `device_id` = UUIDv8(SHA-256(`ik_sig_pub`)) (0.2), tính lại mỗi lần khởi động, không lưu riêng.
  4. Mở `handlive.sqlite` bằng `db_key` (Query) rồi chạy migration tạo lược đồ 0.9.3; M-APP, I-APP
     nạp khóa vào bộ nhớ khi khởi động (0.6.1).

#### API 2 — Chuyển ứng dụng vào `/Applications` (Mac)

- **URL:** N/A
- **Method:**
  `FileManager.default.copyItem(at: Bundle.main.bundleURL, to: URL(fileURLWithPath: "/Applications/HandLive.app"))`;
  `NSWorkspace.shared.openApplication(at:configuration:completionHandler:)`; `NSApp.terminate(nil)`;
  ở bản mới: `FileManager.default.trashItem(at:resultingItemURL:)` cho bản cũ.
- **Request:** nguồn = bundle đang chạy; đích = `/Applications/HandLive.app`;
  `NSWorkspace.OpenConfiguration.arguments` mang đường dẫn bản cũ.
- **Response:** bản mới chạy; lỗi `NSFileWriteNoPermissionError`, đích đã tồn tại hoặc nguồn bị App
  Translocation → E2.
- **Ví dụ:** `~/Downloads/HandLive.app` → `/Applications/HandLive.app`; bản mới chuyển bản cũ vào
  Thùng rác rồi chạy lại từ bước 1.
- **Logic nghiệp vụ:**
  1. Đích đã có bản khác: hỏi thay thế; nếu bản trong `/Applications` mới hơn thì mở bản đó và thoát
     bản hiện tại.
  2. Đang bị App Translocation (bundle chạy từ vị trí tạm chỉ đọc, đường dẫn chứa
     `/AppTranslocation/`): không biết vị trí gốc để chép → chỉ hướng dẫn kéo thả (E2).
  3. Người dùng chọn "Để sau": nhắc lại khi bật camera (CAM-01 bước 2).
  4. Đăng ký mục đăng nhập (API 3) sau bước này để mục trỏ tới bản trong `/Applications`.

#### API 3 — `SMAppService` (Mở khi đăng nhập, Mac)

- **URL:** N/A
- **Method:** `try SMAppService.mainApp.register()`; `SMAppService.mainApp.status`;
  `SMAppService.openSystemSettingsLoginItems()`; tắt: `try SMAppService.mainApp.unregister()`.
- **Request:** không có tham số.
- **Response:** `status` ∈ {`.enabled`, `.requiresApproval`, `.notRegistered`, `.notFound` };
  `register()` ném lỗi khi bị người dùng hoặc chính sách MDM chặn.
- **Ví dụ:** `register()` thành công → `status = .enabled`, trường 6 = `enabled`; macOS hiện thông
  báo hệ thống về mục đăng nhập mới.
- **Logic nghiệp vụ:**
  1. Chỉ đăng ký khi người dùng giữ lựa chọn trường 3; không tự bật ngầm.
  2. Trạng thái thật luôn đọc từ `status`, không lưu khóa cài đặt riêng; SET-02 trường 22 dùng cùng
     API.
  3. `.requiresApproval` → nút mở `openSystemSettingsLoginItems()` (E5).

#### API 4 — `UNUserNotificationCenter` (quyền thông báo)

- **URL:** N/A
- **Method:**
  `UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge])`;
  `getNotificationSettings()` đọc `authorizationStatus`, `timeSensitiveSetting`;
  `setNotificationCategories(_:)`.
- **Request:** tùy chọn `[.alert, .sound, .badge]`. Mức nhạy cảm thời gian không có tùy chọn xin
  riêng: cần entitlement `com.apple.developer.usernotifications.time-sensitive`, và mỗi thông báo
  đặt `interruptionLevel = .timeSensitive` (thông báo cục bộ trên Mac) hoặc
  `interruption-level: time-sensitive` trong APNs (CONN-04 API 4).
- **Response:** `granted` (bool), `error`; `authorizationStatus` ∈ {`.notDetermined`, `.denied`,
  `.authorized`, `.provisional`, `.ephemeral` }; `timeSensitiveSetting` ∈ {`.enabled`, `.disabled`,
  `.notSupported` }.
- **Ví dụ:** `granted = true`, `timeSensitiveSetting = .enabled` → trường 7 = `allowed`, trường 8 =
  `enabled`.
- **Logic nghiệp vụ:**
  1. Hỏi một lần; `.denied` → không gọi lại (hệ thống không hiện nữa), chỉ hướng dẫn: iOS/iPadOS mở
     `UIApplication.openNotificationSettingsURLString`; Mac hướng dẫn Cài đặt hệ thống › Thông báo ›
     HandLive.
  2. Không dùng `.provisional` (thông báo cuộc gọi phải hiện ngay) và không xin `.criticalAlert`.
  3. iOS/iPadOS: device token vẫn lấy được ở bước 13 khi người dùng từ chối, nhưng alert không hiện
     (E3).

#### API 5 — `NWBrowser` (lời nhắc quyền mạng cục bộ)

- **URL:** N/A (mDNS `224.0.0.251:5353`, `ff02::fb`)
- **Method:**
  `NWBrowser(for: .bonjourWithTXTRecord(type: "_handlive._tcp", domain: nil), using: .tcp)`;
  `stateUpdateHandler`, `browseResultsChangedHandler`; `start(queue:)`, `cancel()`.
- **Request:** không có tham số ngoài kiểu dịch vụ; Info.plist phải có
  `NSLocalNetworkUsageDescription` và `_handlive._tcp` trong `NSBonjourServices` (thiếu → duyệt lỗi
  `NoAuth`, −65555).
- **Response:** trạng thái `.ready`, `.waiting(NWError.dns(-65570))` (`kDNSServiceErr_PolicyDenied`
  — người dùng từ chối) hoặc `.failed(error)`; tập kết quả duyệt.
- **Ví dụ:** người dùng từ chối → `.waiting(.dns(-65570))` → trường 9 = `denied`.
- **Logic nghiệp vụ:**
  1. Hệ thống chỉ hỏi một lần mỗi lần cài; không có API đọc trực tiếp trạng thái quyền.
  2. Suy ra trạng thái: `.waiting` với `PolicyDenied` → `denied`; có kết quả duyệt, hoặc ở `.ready`
     mà không có lỗi sau khi người dùng đóng hộp thoại (ứng dụng active trở lại) → `allowed`; còn
     lại `unknown` (CONN-01 E8 xử lý sau).
  3. Dừng browser (`cancel()`) khi rời bước; PAIR-01 và CONN-01 chạy browser riêng.
  4. Hướng dẫn khi `denied`: iOS/iPadOS — Cài đặt › Quyền riêng tư & Bảo mật › Mạng cục bộ › bật
     HandLive; Mac — Cài đặt hệ thống › Quyền riêng tư & Bảo mật › Mạng cục bộ.

#### API 6 — `NSPasteboard.accessBehavior` (Mac)

- **URL:** N/A
- **Method:** `NSPasteboard.general.accessBehavior` (trong `if #available(macOS 15.4, *)`).
- **Request:** không có.
- **Response:** `NSPasteboard.AccessBehavior` ∈ {`.default`, `.ask`, `.alwaysAllow`, `.alwaysDeny`}.
- **Ví dụ:** `.ask` → trường 10 = `ask`, trường 12: "Để tự gửi bảng nhớ tạm, mở Cài đặt hệ thống › Quyền riêng tư & Bảo mật › Dán từ ứng dụng khác và chọn Luôn cho phép cho HandLive."
- **Logic nghiệp vụ (C10):**
  1. Apple không có API xin "Luôn cho phép": chỉ hướng dẫn và mở
     `x-apple.systempreferences:com.apple.preference.security`.
  2. `.default` hoặc `.alwaysAllow` → không hiện gì; trước macOS 15.4 → `not_applicable`.
  3. Đọc lại mỗi khi M-APP được kích hoạt để cập nhật trường 10; CLIP-02 chỉ đọc nội dung khi
     `changeCount` đổi.

#### API 7 — `POST /v1/devices`

Đặc tả ở CONN-03 API 1. Gọi ở bước 13 khi `relay.enabled = true`; idempotent (upsert). Lỗi → E7, thử
lại nền khi có mạng.

#### API 8 — Đăng ký push (iOS/iPadOS)

`UIApplication.shared.registerForRemoteNotifications()` →
`application(_:didRegisterForRemoteNotificationsWithDeviceToken:)` → `PUT /v1/devices/me/push-token`
với `provider = apns` (bản phát triển: `apns_sandbox`) và `topic` = bundle id của I-APP. Đặc tả ở
CONN-04 API 1 và bước 2; chạy sau API 7. Mac không đăng ký push (0.4.4).

#### Query

```text
# [Thiết kế] UserDefaults — Mac: UserDefaults.standard; iOS/iPadOS: UserDefaults(suiteName: "group.app.handlive")
defaults.register(defaults: ["feature.clipboard": true, "feature.sms": true, "feature.call": true,
                             "relay.enabled": true, "clip.send_images": true, "clip.block_sensitive": true,
                             "clip.auto_clear_s": 60, "sms.notify": true, "sms.preview": true,
                             "call.notify": true])                              # mỗi lần khởi động: mặc định 0.9.5
# Mac đăng ký thêm: feature.call_audio = false, call_audio.allow_opus_fallback = true,
# call_audio.phone_bt_address = "", feature.camera = false, cam.default_camera = "front",
# cam.default_quality = "auto", cam.usb_boost = true, cam.usb_wizard_dismissed = false
# (và call.ringtone = true nếu khóa này được bổ sung vào 0.9.5)
defaults.object(forKey: "setup.completed_at") as? Int64                         # bước 1
defaults.object(forKey: "setup.started_at") as? Int64                           # bước 2: nil → cài mới
defaults.set(now, forKey: "setup.started_at")                                   # bước 2
defaults.bool(forKey: "relay.enabled")                                          # bước 13
defaults.set(now, forKey: "setup.completed_at")                                 # bước 13
```

```text
# [Thiết kế] Keychain, service "app.handlive.keys"
SecItemDelete([kSecClass: kSecClassGenericPassword, kSecAttrService: "app.handlive.keys"])   # bước 2, chỉ khi cài mới
SecItemAdd([kSecClass: kSecClassGenericPassword, kSecAttrService: "app.handlive.keys",
            kSecAttrAccount: "ik_sig", kSecValueData: <32 byte>,
            kSecAttrAccessible: kSecAttrAccessibleWhenUnlockedThisDeviceOnly])               # bước 2; tương tự "ik_dh", "db_key"
SecItemCopyMatching([... kSecAttrAccount: "db_key", kSecReturnData: true])                   # mỗi lần khởi động
```

```sql
-- [Thiết kế] Mac/iOS, bước 2: mở handlive.sqlite bằng khóa thô 32 byte (SQLCipher qua GRDB), rồi chạy lược đồ 0.9.3
PRAGMA key = "x'<64 ký tự hex của db_key>'";

-- [Thiết kế] Mac/iOS, bước 13: xác nhận chưa có cặp hiệu lực trước khi mở PAIR-01
SELECT COUNT(*) AS active_pairs FROM paired_device WHERE revoked_at IS NULL;
```
