[English](README.md) | Tiếng Việt

# HandLive — Tài liệu thiết kế chi tiết

| Mục | Nội dung |
|-----|----------|
| Phiên bản | 1.2 (bản để triển khai; đồng bộ design system theo Apple HIG; đa ngôn ngữ en/vi — C20) |
| Ngày | 2026-09-25 |
| Nguồn | `plans/20260924-definitive-architecture/plan.md`, `docs/system-architecture.md`, `docs/code-standards.md`; giao diện: design system HandLive (Apple HIG) https://claude.ai/artifact/2rsmYxBjxXrd12FByTd9vT |
| Phạm vi | Android (hub), macOS, iOS/iPadOS, Cloud relay — Phase 1 đến Phase 5 |

## 1. Cấu trúc tài liệu

| File | Mục | Nội dung |
|------|-----|----------|
| [`00-common-specs.md`](00-common-specs.vi.md) | 0 | Đặc tả dùng chung: thành phần, định danh, kiểu dữ liệu, khung tin, bảo mật, danh mục loại tin, mã lỗi, mô hình dữ liệu, hằng số |
| [`01-setup-settings.md`](01-setup-settings.vi.md) | 1 | Nhóm chức năng Thiết lập và cài đặt |
| [`02-pairing.md`](02-pairing.vi.md) | 2 | Nhóm chức năng Ghép nối và quản lý thiết bị |
| [`03-connectivity.md`](03-connectivity.vi.md) | 3 | Nhóm chức năng Kết nối |
| [`04-clipboard.md`](04-clipboard.vi.md) | 4 | Nhóm chức năng Đồng bộ clipboard |
| [`05-sms.md`](05-sms.vi.md) | 5 | Nhóm chức năng Tin nhắn SMS |
| [`06-call-control.md`](06-call-control.vi.md) | 6 | Nhóm chức năng Thông tin và điều khiển cuộc gọi |
| [`07-call-audio.md`](07-call-audio.vi.md) | 7 | Nhóm chức năng Âm thanh cuộc gọi |
| [`08-camera-mic.md`](08-camera-mic.vi.md) | 8 | Nhóm chức năng Camera và micro |

Mỗi nhóm chức năng là một mục. Mỗi chức năng lá có đúng năm mục con theo khuôn mẫu ở phần 3.

Mỗi file có hai bản cùng cấu trúc (C20): tiếng Anh `X.md` là bản chuẩn, tiếng Việt `X.vi.md`; sửa
một bản thì sửa bản kia trong cùng commit (`tools/docs/check_bilingual_docs.py`).

## 2. Danh mục chức năng

| Mã | Chức năng lá | Nhóm | Giai đoạn | Nền tảng | Tác nhân chính |
|----|--------------|------|-----------|----------|----------------|
| SET-01 | Thiết lập ban đầu và cấp quyền trên Android | 1 | P1+ | Android | Người dùng |
| SET-02 | Bật/tắt tính năng và tùy chọn đồng bộ | 1 | P1+ | Android, Mac, iOS | Người dùng |
| SET-03 | Thiết lập ban đầu trên Mac và iOS | 1 | P1+ | Mac, iOS | Người dùng |
| PAIR-01 | Ghép nối thiết bị bằng mã QR (dự phòng: PIN) | 2 | P1 (qua relay: P2) | Android, Mac, iOS | Người dùng |
| PAIR-02 | Xem danh sách thiết bị và trạng thái kết nối | 2 | P1 | Android, Mac, iOS | Người dùng |
| PAIR-03 | Hủy ghép nối thiết bị (tại chỗ và từ xa) | 2 | P1 (từ xa: P2) | Android, Mac, iOS, Relay | Người dùng |
| CONN-01 | Tự khám phá và kết nối trong mạng LAN | 3 | P1 | Mac, iOS, Android | Hệ thống |
| CONN-02 | Duy trì kết nối và tự kết nối lại | 3 | P1 | Mac, iOS, Android | Hệ thống |
| CONN-03 | Kết nối qua relay khi ngoài LAN | 3 | P2 | Mac, iOS, Android, Relay | Hệ thống |
| CONN-04 | Đăng ký push và đánh thức thiết bị | 3 | P2 | Android, iOS, Relay | Hệ thống |
| CLIP-01 | Gửi văn bản clipboard từ Android sang Mac/iOS | 4 | P1 | Android → Mac, iOS | Người dùng |
| CLIP-02 | Gửi văn bản clipboard từ Mac sang Android | 4 | P1 | Mac → Android | Người dùng |
| CLIP-03 | Đồng bộ ảnh clipboard giữa Android và Mac | 4 | P1 | Android ↔ Mac | Người dùng |
| CLIP-04 | Đồng bộ clipboard trên iPhone/iPad | 4 | P2 | iOS ↔ Android | Người dùng |
| CLIP-05 | Tự xóa clipboard đã nhận | 4 | P1 | Mac, iOS, Android | Hệ thống |
| SMS-01 | Đồng bộ hội thoại và lịch sử SMS | 5 | P2 | Android → Mac, iOS | Hệ thống |
| SMS-02 | Nhận thông báo SMS mới | 5 | P2 | Android → Mac, iOS | Người dùng |
| SMS-03 | Xem hội thoại và tải tin cũ hơn | 5 | P2 | Mac, iOS | Người dùng |
| SMS-04 | Gửi và trả lời SMS từ Mac/iOS | 5 | P2 | Mac, iOS → Android | Người dùng |
| SMS-05 | Đồng bộ trạng thái đã đọc | 5 | P2 | Android → Mac, iOS | Hệ thống |
| CALL-01 | Thông báo cuộc gọi đến trên Mac/iOS | 6 | P3 | Android → Mac, iOS | Người dùng, Người gọi |
| CALL-02 | Trả lời hoặc từ chối cuộc gọi đến | 6 | P3 | Mac (trả lời, từ chối), iOS (từ chối) → Android | Người dùng |
| CALL-03 | Điều khiển cuộc gọi đang diễn ra | 6 | P3 (giữ máy, DTMF, tắt tiếng: P4 qua HFP) | Mac → Android | Người dùng |
| CALL-04 | Đồng bộ nhật ký cuộc gọi và cuộc gọi nhỡ | 6 | P3 | Android → Mac, iOS | Hệ thống |
| AUDIO-01 | Bật nghe gọi trên Mac và chấp thuận công bố | 7 | P4 | Mac, Android | Người dùng |
| AUDIO-02 | Nghe và nói cuộc gọi trên Mac qua Bluetooth HFP | 7 | P4 | Mac ↔ Android | Người dùng |
| AUDIO-03 | Chuyển âm thanh cuộc gọi giữa Mac và điện thoại | 7 | P4 | Mac, Android | Người dùng |
| AUDIO-04 | Âm thanh cuộc gọi qua Opus/WebSocket (dự phòng, cần Shizuku) | 7 | P4 | Mac ↔ Android | Người dùng |
| CAM-01 | Cài đặt camera ảo và micro ảo trên Mac | 8 | P5 | Mac | Người dùng |
| CAM-02 | Bắt đầu và dừng phát camera/micro | 8 | P5 | Mac ↔ Android | Người dùng, Ứng dụng họp |
| CAM-03 | Điều khiển luồng camera | 8 | P5 | Mac → Android | Người dùng |
| CAM-04 | Tự tăng tốc qua USB khi cắm cáp | 8 | P5 | Mac, Android | Hệ thống |
| CAM-05 | Điều chỉnh chất lượng thích ứng | 8 | P5 | Android, Mac | Hệ thống |

## 3. Quy ước trình bày

### 3.1 Khuôn mẫu chức năng lá

Mỗi chức năng lá có đúng năm mục con, đánh số `<nhóm>.<chức năng>.<1..5>`:

1. **Thông tin chung** — bảng hai cột với đúng các dòng: Tên, Mô tả, Tác nhân, Điều kiện trước, Điều
   kiện sau, Ngoại lệ, Yêu cầu đặc biệt. Ngoại lệ đánh mã `E1`, `E2` … để luồng nghiệp vụ tham
   chiếu.
2. **Màn hình** — `N/A` khi chưa có wireframe được duyệt. Tại phiên bản này
   **chưa có wireframe nào được duyệt**, nên mọi chức năng ghi `N/A`.
3. **Mô tả chi tiết các thành phần** — bảng: `#`, Trường, Kiểu dữ liệu, Input/Output, Giá trị khởi
   tạo, Mô tả. Chỉ gồm trường người dùng nhập hoặc hệ thống trả về/hiển thị; kiểu dữ liệu và giá trị
   Input/Output theo 0.3.
4. **Luồng nghiệp vụ** — lưu đồ Mermaid hai cột `Người dùng` và `Hệ thống`, kèm bảng bước: Bước, Tác
   nhân, Thành phần (mã theo 0.1), Mô tả, Ngoại lệ/Ghi chú. Số bước trong lưu đồ trùng số bước trong
   bảng.
5. **Đặc tả API/service** — danh sách lời gọi, rồi từng lời gọi gồm URL, Method, Request, Response,
   Ví dụ, Logic nghiệp vụ; cuối cùng là Query. Không có lời gọi thì ghi `N/A`.

Nhãn của khuôn mẫu ở hai bản (validator đọc đúng các nhãn này):

| Tiếng Việt (`X.vi.md`) | Tiếng Anh (`X.md`) |
|------------------------|--------------------|
| Thông tin chung · Màn hình · Mô tả chi tiết các thành phần · Luồng nghiệp vụ · Đặc tả API/service | General information · Screens · Component details · Business flow · API/service specification |
| Tên, Mô tả, Tác nhân, Điều kiện trước, Điều kiện sau, Ngoại lệ, Yêu cầu đặc biệt | Name, Description, Actors, Preconditions, Postconditions, Exceptions, Special requirements |
| `#`, Trường, Kiểu dữ liệu, Input/Output, Giá trị khởi tạo, Mô tả | `#`, Field, Data type, Input/Output, Initial value, Description |
| Bước, Tác nhân, Thành phần, Mô tả, Ngoại lệ / Ghi chú | Step, Actor, Component, Description, Exceptions / Notes |
| "N/A — chưa có wireframe được duyệt." | "N/A — no approved wireframe yet." |
| Làn `ND["Người dùng"]`, `HT["Hệ thống"]` | Lanes `ND["User"]`, `HT["System"]` |
| URL, Method, Request, Response, Ví dụ, Logic nghiệp vụ, Query | URL, Method, Request, Response, Example, Business logic, Query |
| Nhãn `[Thiết kế]` trong SQL | Label `[Design]` in SQL |

### 3.2 Cách ghi URL và Method

| Loại lời gọi | URL | Method |
|--------------|-----|--------|
| Envelope thiết bị ↔ thiết bị | `wss://{android_host}:{port}/v1/ctl` (LAN); qua relay: `wss://{RELAY_HOST}/v1/relay` với lớp bọc `to`/`from` | `WS <type>/<op>`, ví dụ `WS sms/send` |
| Khung nhị phân | `wss://{android_host}:{port}/v1/stream/<kênh>` | `WS binary HL` |
| REST relay | `https://{RELAY_HOST}/v1/...` | `GET`, `POST`, `PUT`, `DELETE` |
| Push | `https://fcm.googleapis.com/v1/projects/{project}/messages:send` hoặc `https://api.push.apple.com/3/device/{token}` (relay gọi) | `POST` |
| Dịch vụ hệ điều hành | `N/A` | Tên API, ví dụ `SmsManager.sendMultipartTextMessage` |

Request/Response của envelope mô tả phần `data` trong plaintext của payload; envelope bao ngoài và
`ack` theo 0.5.1, không lặp lại.

### 3.3 Query

Repo chưa có mã nguồn (2026-09-24), nên **không có query nào trích được từ mã**. Query trong tài
liệu là thiết kế, gắn nhãn `[Thiết kế]`, dựa trên lược đồ ở 0.9. Query tới ContentProvider của
Android ghi dưới dạng `ContentResolver.query(uri, projection, selection, args, sortOrder)`.

### 3.4 Lưu đồ

- `flowchart TB`, khai báo `subgraph ND["Người dùng"]` trước `subgraph HT["Hệ thống"]` để cột Người
  dùng nằm bên trái.
- Nút người dùng `U<n>`, nút hệ thống `S<n>`, nút rẽ nhánh `D<n>`; nhãn bắt đầu bằng số bước trong
  ngoặc, ví dụ `"(4) Mã hóa và gửi"`. Không viết `"4. …"`: Mermaid 11 hiểu `4. ` ở đầu nhãn là danh
  sách markdown và hiển thị lỗi.
- Nhánh ngoại lệ ghi mã `E<k>` trên cạnh.
- Tối đa khoảng 15 nút; chi tiết đưa vào bảng bước.

### 3.5 Câu chữ giao diện

- Đa ngôn ngữ (C20, 0.12): tiếng Anh là ngôn ngữ mặc định, tiếng Việt là ngôn ngữ thứ hai. Bản
  tiếng Anh của tài liệu (`X.md`) ghi chuỗi tiếng Anh, bản tiếng Việt (`X.vi.md`) ghi chuỗi tiếng
  Việt. Mỗi chuỗi có khóa ổn định trong catalog `shared/strings/ui-strings.json`; tài liệu và
  catalog phải khớp — sửa câu chữ thì sửa tài liệu trước, catalog sau, mã không viết cứng câu chữ.
- Tiếng Anh theo văn phong tiếng Anh của Apple: viết hoa kiểu tiêu đề cho nút, mục menu, tiêu đề
  cửa sổ và tab; viết hoa kiểu câu cho mô tả, nội dung alert, thông báo, trạng thái. Tiếng Việt
  viết hoa đầu câu theo các quy tắc dưới.

- Chuỗi hiển thị cho người dùng theo design system HandLive (Apple HIG), mục "Viết nội dung":
  https://claude.ai/artifact/2rsmYxBjxXrd12FByTd9vT
- Bỏ dấu theo bản tiếng Việt của Apple: hóa, xóa, hủy, tùy, thủy, khỏe (không viết hoá, xoá, huỷ,
  tuỳ). Toàn bộ tài liệu chuyển sang cách này ngày 2026-09-25.
- Thuật ngữ trên giao diện: "bảng nhớ tạm" (chữ "clipboard" trong tài liệu chỉ là thuật ngữ kỹ
  thuật), "kết nối qua Internet" (không "relay"), "cùng mạng Wi-Fi" (LAN chỉ trong nhãn ngắn), "Hủy"
  luôn là nút hủy, nút bắt đầu bằng động từ, viết hoa đầu câu.
- Màn hình giải thích trước hộp thoại xin quyền chỉ có một nút "Tiếp tục"; chỉ công bố cần đồng ý
  pháp lý (AUDIO-01, Hỗ trợ tiếp cận) mới có hai lựa chọn.

## 4. Phạm vi

**Trong phạm vi:** các chức năng ở phần 2. Mỗi Mac/iPhone/iPad ghép với một điện thoại Android tại
một thời điểm; mỗi điện thoại ghép tối đa 8 thiết bị.

**Ngoài phạm vi phiên bản này:**
- MMS, RCS, tin nhắn nhóm có ảnh.
- Gọi đi (khởi tạo cuộc gọi) từ Mac/iOS.
- Lưu lịch sử clipboard (chỉ truyền tức thời).
- Phát camera qua relay (chỉ LAN hoặc USB).
- Đồng bộ toàn bộ danh bạ (chỉ tên hiển thị gắn với hội thoại và cuộc gọi).
- Máy khách Windows/Linux.

## 5. Điều chỉnh và quyết định

Mục này liệt kê các điểm tài liệu thiết kế chi tiết làm rõ hoặc khác với kiến trúc gốc, kèm lý do và
bằng chứng. Điểm nào đụng tới quyết định đã chốt thì không đổi âm thầm: chủ dự án đã quyết định từng
điểm ngày 2026-09-24 (C12–C15).

| # | Nội dung | Loại | Trạng thái |
|---|----------|------|------------|
| C1 | `type` của envelope giữ tập đã chốt; thao tác chi tiết nằm trong trường `op` của payload đã mã hóa, nên relay chỉ thấy nhóm tin. Thêm hai nhóm `session` (bắt tay phiên) và `camera` (Phase 5). Phản hồi dùng `type = ack`. | Làm rõ | Áp dụng |
| C2 | XChaCha20-Poly1305 trên Apple: CryptoKit không có XChaCha20 → HChaCha20 tự cài + `ChaChaPoly`, có test vector liên nền tảng. | Làm rõ | Áp dụng |
| C3 | Keychain giữ `WhenUnlockedThisDeviceOnly`; ứng dụng nạp `PRK` vào bộ nhớ lúc khởi động để kết nối lại khi màn hình khóa. Thông báo push trên iPhone đang khóa hiển thị nội dung chung chung. | Làm rõ | Áp dụng |
| C4 | `device_id` tự chứng thực (UUIDv8 từ SHA-256 khóa ký) để relay chống giả mạo định danh mà không cần tài khoản. | Bổ sung | Áp dụng |
| C5 | Relay dùng thêm Redis 7 (presence, pub/sub) để giữ đúng nguyên tắc "stateless để scale horizontal". | Bổ sung | Áp dụng |
| C6 | Hint mDNS đổi theo giờ, tên instance ngẫu nhiên, để người lạ trong LAN không theo dõi được điện thoại. | Bổ sung | Áp dụng |
| C7 | iOS không dùng PushKit VoIP (kiến trúc §3.3): từ iOS 13 mỗi VoIP push bắt buộc phải báo một cuộc gọi cho CallKit, HandLive không phải ứng dụng VoIP. Thay bằng APNs alert (`time-sensitive` cho cuộc gọi đến) + Notification Service Extension giải mã nội dung. | Bắt buộc theo nền tảng | Áp dụng |
| C8 | Micro ảo dùng mô hình loopback của BlackHole (đã kiểm chứng trong mã nguồn BlackHole): M-MIC có một thiết bị ra bị ẩn (`kAudioDevicePropertyIsHidden`) và một thiết bị vào hiển thị "HandLive Microphone", dùng chung ring buffer trong tiến trình driver; M-APP phát PCM vào thiết bị ẩn như một client CoreAudio bình thường.<br>Thay cho POSIX shm (kiến trúc §10.3, `docs/system-architecture.md` §8): driver chạy dưới user `_coreaudiod`, nên vùng shm do ứng dụng tạo phải mở quyền 0666, khi đó mọi tiến trình cục bộ đọc/ghi được âm thanh micro. | Điều chỉnh có bằng chứng | Áp dụng |
| C9 | Cài driver micro: PKG ký + notarize nhúng trong ứng dụng, mở bằng Installer (Installer tự xin quyền quản trị), script `postinstall` chạy `killall coreaudiod` với quyền root.<br>Không cần privileged helper: `SMJobBless` đã deprecated từ macOS 13; `launchctl kickstart -k` bị chặn với tiến trình hệ thống từ macOS 14.4.<br>Đúng tinh thần D7 ("run embedded PKG"). | Làm rõ D7 | Áp dụng |
| C10 | Quyền dán trên macOS (preview từ macOS 15.4, chưa bật mặc định ở macOS 26): nếu `NSPasteboard.accessBehavior` là `.ask` hoặc `.alwaysDeny`, onboarding hướng người dùng tới Cài đặt › Quyền riêng tư & Bảo mật › Dán từ ứng dụng khác; Apple không có API xin "Luôn cho phép".<br>Phát hiện thay đổi bằng `changeCount` trước khi đọc nội dung. | Bổ sung | Áp dụng |
| C11 | Camera Extension: cập nhật extension có thể cần khởi động lại máy (lỗi Apple ghi nhận từ macOS 14.5); ứng dụng phải chạy từ `/Applications` mới kích hoạt được extension.<br>Rủi ro R6 về Discord chỉ đúng với DAL plug-in cũ (bị tắt từ macOS 14.1), không áp dụng cho CMIOExtension.<br>Ứng dụng đẩy khung vào sink stream khai báo thêm quyền camera cho chắc chắn (chưa có tài liệu Apple khẳng định có cần hay không). | Bổ sung | Áp dụng |
| C12 | **Điều khiển cuộc gọi không dùng `InCallService`.** Bằng chứng (mã nguồn AOSP Telecom, android10 → main): quyền `CALL_COMPANION_APP` không khiến Telecom gắn `InCallService` của ứng dụng; đường duy nhất là `MANAGE_ONGOING_CALLS` (Android 12+) qua vai trò "đồng hồ" của CompanionDeviceManager.<br>**Quyết định:** qua Wi-Fi dùng API công khai — trạng thái và số gọi đến (`READ_PHONE_STATE`, `READ_CALL_LOG`), trả lời (`TelecomManager.acceptRingingCall`), từ chối/kết thúc (`TelecomManager.endCall`, quyền `ANSWER_PHONE_CALLS`; hai hàm đã deprecated từ API 29 nhưng vẫn hoạt động); giữ máy, DTMF, tắt tiếng chỉ qua lệnh HFP khi Mac nối Bluetooth. | Quyết định của chủ dự án | Áp dụng |
| C13 | **Giữ D1/D3 (Opus/WS + Shizuku).** Bằng chứng: ứng dụng thường không thu được âm cuộc gọi (`VOICE_CALL`/`VOICE_UPLINK`/`VOICE_DOWNLINK` cần `CAPTURE_AUDIO_OUTPUT`) và không có API công khai chèn âm vào cuộc gọi.<br>Qua Shizuku (uid shell): Android 10 không thu được; Android 11+ thu được trên một số máy (Pixel 8/9 có, Galaxy S22 Ultra Android 14 ra im lặng); chèn giọng chỉ có `AudioManager.getCallUplinkInjectionAudioTrack()` (Android 13, `@SystemApi`, chưa ai kiểm chứng); Shizuku phải khởi động lại sau mỗi lần bật máy. `BluetoothHeadsetClient` là API của vai trò HF, không phục vụ điện thoại ở vai trò AG — chức năng AG do stack Bluetooth chuẩn của Android đảm nhiệm.<br>**Quyết định:** giữ Opus/WS là đường dự phòng chính thức (AUDIO-04), tài liệu ghi rõ giới hạn theo phiên bản và theo máy; Shizuku dùng cho đường này. | Quyết định của chủ dự án | Áp dụng, kèm cảnh báo khả thi |
| C14 | **Mã hóa âm thanh HFP.** Bằng chứng: với cuộc gọi di động, âm thanh SCO đi thẳng modem ↔ chip Bluetooth, ứng dụng không chạm tới từng khung, nên không mã hóa tầng ứng dụng được.<br>**Quyết định:** đường HFP dựa vào mã hóa liên kết Bluetooth của hệ điều hành; rủi ro KNOB/BIAS còn lại được ghi và công bố trong AUDIO-01.<br>Đường Opus/WS vẫn mã hóa hai lớp (TLS + E2E). | Quyết định của chủ dự án | Áp dụng |
| C15 | **Giữ D4 (Accessibility mặc định).** Bằng chứng: Accessibility không được miễn chặn đọc clipboard nền từ Android 10; cách hoạt động được là Accessibility phát hiện thao tác sao chép rồi mở `ClipboardReadActivity` trong suốt để đọc (như ClipRelay); Android 12+ hiện toast mỗi lần đọc.<br>Chính sách Google Play cấm dùng Accessibility API để lách kiểm soát quyền riêng tư của Android → rủi ro bị từ chối.<br>**Quyết định:** tự gửi qua Accessibility là mặc định, có công bố và xin đồng ý rõ ràng; dự phòng là gửi thủ công (nút trên thông báo, ô Cài đặt nhanh, menu Chia sẻ) thay cho Notification Listener (Notification Listener không đọc được clipboard). | Quyết định của chủ dự án | Áp dụng |
| C16 | "Xóa thiết bị khỏi máy chủ" chỉ gỡ đăng ký trên relay, giữ mọi cặp (vẫn dùng trong LAN/USB); "Xóa toàn bộ dữ liệu HandLive" mới thu hồi cặp và báo đối phương — `DELETE /v1/devices/me?revoke_pairs=false | true`. Đối phương thấy cặp biến mất khỏi relay thì chỉ chuyển sang dùng LAN, không hủy cặp. | Quyết định thiết kế (SET-02) | Áp dụng |
| C17 | Tự xóa clipboard trên Android: mã nguồn AOSP cho thấy `OnPrimaryClipChangedListener` không được gọi khi ứng dụng ở nền.<br>Chỉ xóa khi đọc được `ClipDescription` của chính clip HandLive đã ghi (khi có focus, hoặc lấy focus thoáng qua bằng `ClipboardReadActivity` khi Accessibility đang chạy); không bao giờ suy ra "còn nguyên" từ việc không thấy tín hiệu sao chép, nên không xóa nhầm nội dung người dùng. | Điều chỉnh có bằng chứng | Áp dụng |
| C18 | Tin SMS mới phát hiện bằng `ContentObserver` trên provider, không cần `RECEIVE_SMS` — bớt một quyền bị Google Play hạn chế. | Điều chỉnh | Áp dụng |
| C19 | **Đồng bộ với design system theo Apple HIG** (chủ dự án duyệt 2026-09-25): màn hình giải thích quyền chỉ có "Tiếp tục" (SET-01, SET-03); Mac: biểu tượng thanh menu mở menu, không popover (CONN-01), cài đặt "Hiện HandLive trên thanh menu" (`mac.menu_bar_extra`) và đổi activation policy `.accessory` ↔ `.regular` khi mở cửa sổ (SET-02, SET-03); cuộc gọi đến trên Mac kèm thông báo liên lạc `INStartCallIntent`, chế độ Tập trung bật thì không hiện panel — panel nổi là lệch có chủ đích so với HIG (CALL-01); nhật ký cuộc gọi ở thanh bên cửa sổ Tin nhắn (CALL-04); dòng hội thoại chỉ có chấm chưa đọc (SMS-03); lỗi bảng nhớ tạm báo tại chỗ, không đẩy thông báo (CLIP-01…03); kênh thông báo Android `clipboard`, `permission`; Mac khai báo `NSMicrophoneUsageDescription`, `NSFocusStatusUsageDescription` (SET-03, AUDIO-01, CALL-01); hộp thoại hủy ghép nối theo alert (Mac) và hộp chọn hành động (iPhone, Android) (PAIR-03); câu chữ theo 3.5. | Quyết định của chủ dự án | Áp dụng |
| C20 | **Đa ngôn ngữ và tài liệu song ngữ** (chủ dự án quyết định 2026-09-25): tiếng Anh (`en`) là ngôn ngữ mặc định, ngôn ngữ nguồn và dự phòng; tiếng Việt (`vi`) là ngôn ngữ thứ hai. Giao diện theo ngôn ngữ ưu tiên của hệ thống; chọn riêng cho HandLive bằng cài đặt ngôn ngữ theo ứng dụng của hệ điều hành (Android 13+, iOS/iPadOS, macOS) và SET-02 trường 32 trên Android 10–12.<br>Mọi chuỗi giao diện có khóa ổn định trong catalog `shared/strings/ui-strings.json`, sinh ra tài nguyên của từng nền tảng (0.12); mã không viết cứng câu chữ. Tin giữa các thiết bị, relay và push không mang câu chữ hiển thị — chỉ mã, khóa và tham số; máy nhận hiển thị bằng ngôn ngữ của nó (APNs dùng `loc-key`, CONN-04).<br>Tài liệu song ngữ: `X.md` tiếng Anh (bản chuẩn khi hai bản lệch nhau), `X.vi.md` tiếng Việt, cùng cấu trúc, cập nhật trong cùng commit. | Quyết định của chủ dự án | Áp dụng |
