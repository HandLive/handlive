# Thông báo

Mục này liệt kê mọi thông báo HandLive gửi, loại và mức ngắt quãng của từng cái, câu chữ, hành động
và cách tôn trọng Tập trung. Thông báo trên Android dùng mẫu và kênh của Android; trên Mac, iPhone,
iPad dùng thông báo của Apple.

Nguồn HIG: https://developer.apple.com/design/human-interface-guidelines/notifications ·
https://developer.apple.com/design/human-interface-guidelines/managing-notifications

## Mac, iPhone, iPad

| Thông báo | Nền tảng | Loại · mức | Tiêu đề · nội dung | Hành động |
|---|---|---|---|---|
| Tin SMS mới (SMS-02) | Mac, iOS | Liên lạc `INSendMessageIntent`, active | "Nguyễn Văn A" · "Nhớ mang theo tài liệu" | "Trả lời" (ô nhập, nút "Gửi"), "Đánh dấu đã đọc" |
| Cuộc gọi đến (CALL-01) | iOS | Liên lạc `INStartCallIntent`, time-sensitive | "Nguyễn Văn A" · "Cuộc gọi đến · SIM 1" | "Từ chối" (phá hủy, cần mở khóa máy) |
| Cuộc gọi đến | Mac | Liên lạc `INStartCallIntent`: passive khi `CallPanel` đang hiện (chỉ vào Trung tâm thông báo); time-sensitive khi Tập trung bật và không hiện panel | Như trên | "Trả lời", "Từ chối" |
| Cuộc gọi nhỡ (CALL-04) | Mac, iOS | Active | Tên, số hoặc "Số ẩn" · "Cuộc gọi nhỡ · 14:05" (kèm "· SIM 1") | "Nhắn tin" (ô nhập) — chỉ khi có số và gửi được SMS |
| Đã chặn nội dung nhạy cảm (QC3) | Mac | Passive | "Đã chặn nội dung nhạy cảm" · "HandLive không gửi nội dung có vẻ là mật khẩu hoặc số thẻ." | "Vẫn gửi" (hết hạn sau 2 phút) |
| Xung đột bảng nhớ tạm (QC8) | Mac | Active | "Chưa ghi lên Pixel 8 của Lan" · "Thiết bị này vừa có nội dung sao chép mới." | "Gửi lại" (hết hạn sau 2 phút) |
| Camera (CAM-05) | Mac | Active (quá nóng), passive (pin yếu) | Không tiêu đề riêng. Quá nóng: "Điện thoại quá nóng — đã dừng camera. Hãy để máy nguội rồi thử lại." Pin yếu: "Pin điện thoại dưới 20 % — HandLive giảm chất lượng xuống 720p. Cắm sạc hoặc cáp USB để giữ chất lượng." | — |

- Nội dung ẩn: `sms.preview` tắt thì nội dung là "Tin nhắn SMS mới" (SMS-02 trường 2). Người dùng
  tắt bản xem trước trong cài đặt hệ thống thì hệ thống dùng `hiddenPreviewsBodyPlaceholder`: "Tin
  nhắn SMS mới" (`HL_SMS`), "Cuộc gọi đến" (`HL_CALL_INCOMING`), "Cuộc gọi nhỡ" (`HL_CALL_MISSED`).
- iPhone đang khóa, extension không đọc được khóa: nội dung chung "Tin nhắn SMS mới", "Cuộc gọi đến
  trên điện thoại", "Cuộc gọi nhỡ trên điện thoại", không có hành động (C3).
- Mỗi hành động có SF Symbol: Trả lời tin `arrowshape.turn.up.left`, Đánh dấu đã đọc
  `envelope.open`, Trả lời cuộc gọi `phone.fill`, Từ chối `phone.down.fill`, Nhắn tin `message`, Vẫn
  gửi `paperplane`, Gửi lại `arrow.clockwise`.
- Nhóm: `threadIdentifier` theo hội thoại (`sms:<pair_id>:<thread_id>`) và `calls`; push dùng
  `apns-collapse-id` để không lặp.

## Android

| Kênh (id) | Mức | Thông báo | Hành động |
|---|---|---|---|
| `hl_service` "Dịch vụ kết nối" | `IMPORTANCE_LOW`, thường trực, không huy hiệu | "HandLive đang chờ kết nối" · "Đã kết nối với MacBook của Lan" · "Đã kết nối với 2 thiết bị" | "Gửi bảng nhớ tạm" |
| `camera_request` | `IMPORTANCE_HIGH` (heads-up), tự hủy sau 60 s | "MacBook của Lan muốn dùng camera và micro" | "Bật", "Từ chối" |
| `camera_live` | `IMPORTANCE_LOW`, thường trực | "Đang dùng camera cho MacBook của Lan" | "Đổi camera", "Tắt micro" hoặc "Bật micro", "Dừng" (tối đa 3) |
| `camera_alert` | `IMPORTANCE_DEFAULT` | Quá nóng, pin yếu — cùng câu như Mac | — |
| `clipboard` (đề xuất) | `IMPORTANCE_LOW` (không âm, như passive) | Đã chặn nội dung nhạy cảm; xung đột; tiến trình ảnh trên 1 MiB "Đang gửi ảnh tới MacBook của Lan — 45 %" | "Vẫn gửi"; "Gửi lại"; "Hủy" |
| `permission` (đề xuất) | `IMPORTANCE_LOW` | "MacBook của Lan cần quyền đọc SMS trên điện thoại — chạm để cho phép" (SET-01 trường 17) | — |

- Mẫu, biểu tượng nhỏ và cách hiện là của Android: `NotificationCompat`, biểu tượng nhỏ đơn sắc
  (Material Symbols), hành động là `PendingIntent` mở thẳng activity hoặc service (Android 12+ chặn
  trampoline).
- Người dùng tắt từng kênh trong cài đặt thông báo của Android; HandLive dẫn tới bằng
  `ACTION_CHANNEL_NOTIFICATION_SETTINGS`, không tự làm công tắc riêng.

## Tập trung

- Thông báo liên lạc (tin nhắn, cuộc gọi) để hệ thống lọc theo người gửi, người gọi mà người dùng
  cho phép; HandLive không tự quyết.
- Time-sensitive chỉ cho cuộc gọi đang đổ chuông: sự kiện đang xảy ra, vượt Tập trung và tóm tắt
  theo lịch. Lần đầu hệ thống hỏi người dùng có giữ kiểu này không; người dùng tắt được. Không dùng
  time-sensitive cho gì khác.
- Mac: Tập trung đang lọc người gọi thì `CallPanel` không hiện, không đổ chuông; cuộc gọi vẫn có
  trong `MenuBarMenu` (quyết định 10). Chưa được cấp quyền đọc Tập trung thì không đổ chuông, panel
  vẫn hiện (CALL-01 API 5).
- Thông báo không phải liên lạc ở mức passive, active vào tóm tắt theo lịch khi người dùng bật tóm
  tắt; tin nhắn trực tiếp và time-sensitive đến ngay.

## Quy tắc

- Một sự kiện, một thông báo. Cuộc gọi nhỡ mỗi thiết bị báo một lần; thông báo nhạy cảm, xung đột
  mới thay cái cũ; tin đến qua đồng bộ bù (SMS-01) chỉ cập nhật danh sách và huy hiệu; mất kết nối,
  kết nối lại không có thông báo.
- Lỗi không đi bằng thông báo: lỗi hiện ngay chỗ gây ra nó (mục Phản hồi, tải và lỗi). Ngoại lệ duy
  nhất: kết quả của hành động làm ngay trên thông báo khi app không mở.
- Huy hiệu chỉ đếm việc chưa xem: số hội thoại chưa đọc trên biểu tượng app iOS, tab Tin nhắn và
  ngay sau biểu tượng thanh menu Mac; tab Cuộc gọi đếm cuộc gọi nhỡ chưa xem. Xem xong thì giảm
  ngay. Không vẽ huy hiệu giả.
- App đang ở phía trước thì không gửi thông báo mà cập nhật giao diện: hội thoại đang mở không báo
  tin của chính nó (SMS-02 bước 7); iPhone đang mở HandLive khi có cuộc gọi thì hiện banner trong
  app (CALL-01 bước 8); iPhone nhận xung đột bảng nhớ tạm lúc đang mở app thì báo ngay trên thẻ gửi
  (CLIP-04 E6).
- Câu chữ: tiêu đề ngắn, không dấu chấm, không chữ "HandLive"; nội dung là câu đầy đủ, không tự cắt;
  không lộ nội dung vừa sao chép. Tối đa 4 hành động, mỗi hành động là động từ ngắn; không có hành
  động chỉ để mở app.
- Không dùng thông báo để bảo người dùng làm việc; ngoại lệ là gợi ý cấp quyền trên Android, tối đa
  một lần mỗi tính năng mỗi 24 h.

## Điểm lệch

- Lệch có chủ đích: iPhone báo lỗi của hành động làm từ thông báo bằng thông báo cục bộ, vì app
  không mở: "Không gửi được lệnh từ chối. Cuộc gọi vẫn đổ chuông trên điện thoại." (CALL-02 E8),
  "Chưa gửi được, mở HandLive để thử lại" (SMS-04 E8).
- Đã đồng bộ với tài liệu chi tiết (25/09/2026): SMS-02 API 4 có `HL_SMS_REPLY` và
  `HL_SMS_MARK_READ` ("Đánh dấu đã đọc", chỉ trên máy này theo SMS-05).
- Đã đồng bộ với tài liệu chi tiết (25/09/2026): CALL-01 API 6 (I-NSE) và API 7 (Mac) dùng
  `INStartCallIntent`; kênh `clipboard` (CLIP-01 trường 8, 12) và `permission` (SET-01 trường 17).
- Đã đồng bộ với tài liệu chi tiết (25/09/2026): CONN-04 API 4 và CALL-01 trường 11 không đặt tiêu
  đề push, hệ thống tự hiện tên app.
- Đã đồng bộ với tài liệu chi tiết (25/09/2026): SET-01 trường 5 "Gửi bảng nhớ tạm"; dấu kiểu Apple.

## Nên và không nên

| Nên | Không nên |
|---|---|
| Để hệ thống lọc tin và cuộc gọi theo người trong Tập trung | Tự vượt Tập trung cho tin nhắn thường |
| Gộp tin cùng hội thoại vào một nhóm | Mỗi lần kết nối lại xả hàng loạt thông báo cũ |
| Hành động làm xong việc mà không cần mở app | Nút "Mở" trùng với chạm vào thông báo |
