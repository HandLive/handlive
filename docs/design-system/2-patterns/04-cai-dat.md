# Cài đặt

Mục này quy định màn Cài đặt trên từng nền tảng: cửa sổ nhiều pane trên Mac, tab Cài đặt kiểu danh
sách nhóm trên iPhone, iPad và Android, cùng nhãn chính xác của các khóa SET-02. Cài đặt thuộc từng
thiết bị, không đồng bộ sang thiết bị khác; đối phương chỉ biết qua capability.

Nguồn HIG: https://developer.apple.com/design/human-interface-guidelines/settings ·
https://developer.apple.com/design/human-interface-guidelines/toggles

## Quy tắc chung

- Ít cài đặt, mặc định tốt (0.9.5); tùy chọn gắn với một việc để ngay chỗ việc đó.
- Thay đổi có hiệu lực ngay, không nút "Áp dụng". Khóa ảnh hưởng capability thì gửi
  `capability/update`; đối phương áp dụng trong ≤ 1 s khi cùng mạng Wi-Fi.
- Nhãn nói điều xảy ra khi bật; chú thích dưới nhóm nói hệ quả.
- Bật tính năng cần luồng kích hoạt (`ConsentSheet` nghe gọi trên Mac, CAM-01, công bố Hỗ trợ tiếp
  cận) thì công tắc chỉ bật hẳn khi luồng xong. Tắt tính năng đang chạy (đang phát camera, âm thanh
  cuộc gọi đang ở Mac) thì hỏi xác nhận bằng `Alert` (SET-02 E9).
- Không lặp cài đặt của hệ thống (giao diện, cỡ chữ); dẫn tới đó bằng nút.
- Hành động phá hủy ở nhóm cuối, luôn qua `Alert`. Nút mở alert hoặc sheet có "…" trên Mac, không có
  trên iPhone, Android.

## macOS: cửa sổ Cài đặt

- Mở bằng ⌘, hoặc "Cài đặt…" trong menu HandLive và `MenuBarMenu`, không bằng nút trên toolbar.
  `Settings` scene; `SettingsLink` chỉ có từ macOS 14.
- Toolbar pane không tùy biến, luôn hiện, luôn đánh dấu pane đang mở; tiêu đề cửa sổ là tên pane; mở
  lại pane xem gần nhất.
- Nút thu nhỏ và phóng to mờ; cửa sổ co theo pane.
- Mỗi pane là `Form` với `.formStyle(.grouped)`. Tính năng chính dùng switch mini
  (`.toggleStyle(.switch)` + `.controlSize(.mini)`); tùy chọn phụ dùng checkbox thụt lề dưới nó, mờ
  khi tính năng chính tắt. Chú thích nhóm kiểu `mac-footnote`.

| Pane | Dòng (kiểu · khóa) |
|---|---|
| Chung `gearshape` | Switch "Hiện HandLive trên thanh menu" (tắt thì app có biểu tượng Dock) · switch "Mở HandLive khi đăng nhập" (`SMAppService`) · switch "Kết nối qua Internet" (`relay.enabled`) · nút "Xóa thiết bị khỏi máy chủ…" · nút phá hủy "Xóa toàn bộ dữ liệu HandLive…" |
| Thiết bị `candybarphone` | `DeviceRow` của điện thoại với "Chi tiết…" và "Hủy ghép nối…"; chưa có thì "Ghép điện thoại…" (PAIR-02) |
| Bảng nhớ tạm `doc.on.clipboard` | Switch "Đồng bộ bảng nhớ tạm" (`feature.clipboard`) › checkbox "Đồng bộ ảnh" (`clip.send_images`), "Chặn nội dung nhạy cảm" (`clip.block_sensitive`) · pop-up "Tự xóa bảng nhớ tạm đã nhận": Tắt, Sau 1 phút, Sau 5 phút (`clip.auto_clear_s`), chú thích "Chỉ xóa nội dung nhận từ thiết bị khác, và chỉ khi bạn chưa sao chép gì mới." · macOS 15.4+: dòng "Dán từ ứng dụng khác" với "Mở Cài đặt hệ thống" (CLIP-02 trường 2–3) |
| Tin nhắn `message` | Switch "Tin nhắn SMS" (`feature.sms`) › checkbox "Thông báo SMS mới" (`sms.notify`) › checkbox "Hiện nội dung trong thông báo" (`sms.preview`) · "Lần đồng bộ cuối: 5 phút trước" và nút "Đồng bộ lại toàn bộ SMS…" · chú thích "Đánh dấu đã đọc trên máy này không đổi trạng thái trên điện thoại." |
| Cuộc gọi `phone` | Switch "Cuộc gọi" (`feature.call`) › checkbox "Thông báo cuộc gọi" (`call.notify`), "Đổ chuông trên Mac" (`call.ringtone`) · danh sách "Tin trả lời nhanh", tối đa 6 mẫu (`call.quick_replies`) · switch "Nghe gọi trên Mac" (`feature.call_audio`) › pop-up "Điện thoại dùng cho Bluetooth" (`call_audio.phone_bt_address`), checkbox "Dự phòng qua Wi-Fi (cần Shizuku)" (`call_audio.allow_opus_fallback`), danh sách kiểm tra AUDIO-01 bước 12 |
| Camera `web.camera` | Switch "Dùng điện thoại làm webcam" (`feature.camera`) › danh sách kiểm tra CAM-01 kèm "Cài driver micro" · pop-up "Camera mặc định": Camera trước, Camera sau (`cam.default_camera`) · pop-up "Chất lượng mặc định": Tự động, 480p, 720p, 1080p (`cam.default_quality`) · checkbox "Tự tăng tốc qua USB" (`cam.usb_boost`) · nút "Hiện lại hướng dẫn gỡ lỗi USB" (`cam.usb_wizard_dismissed`) · nút "Gỡ camera và micro ảo…" |

Xác nhận "Đồng bộ lại toàn bộ SMS…": "Xóa tin nhắn đã lưu trên MacBook của Lan và tải lại từ điện
thoại? Tin đang chờ gửi được giữ lại." với "Hủy" và "Đồng bộ lại" (SMS-01 trường 6).

## iOS và iPadOS: tab Cài đặt

- `List` kiểu `.insetGrouped` (`GroupedList`), large title "Cài đặt"; header nhóm sentence case,
  trên iOS 16–18 đặt `.textCase(nil)` để không bị viết hoa toàn bộ.
- Thứ tự nhóm: Điện thoại (`DeviceRow`, mở chi tiết PAIR-02) · Bảng nhớ tạm ("Đồng bộ bảng nhớ tạm",
  "Đồng bộ ảnh", "Tự xóa bảng nhớ tạm đã nhận" mở danh sách chọn có dấu kiểm) · Tin nhắn ("Tin nhắn
  SMS", "Thông báo SMS mới", "Hiện nội dung trong thông báo", "Đồng bộ lại toàn bộ SMS") · Cuộc gọi
  ("Cuộc gọi", "Thông báo cuộc gọi") · "Kết nối qua Internet" · Quyền ("Thông báo", "Mạng cục bộ",
  giá trị Bật/Tắt) · Dữ liệu ("Xóa thiết bị khỏi máy chủ", "Xóa toàn bộ dữ liệu HandLive").
- Không có "Chặn nội dung nhạy cảm": iPhone chỉ gửi khi người dùng chạm Dán (QC3).
- Quyền bị tắt: dòng có lý do `text-orange` và "Mở cài đặt" (`UIApplication.openSettingsURLString`).
  Time-sensitive bị tắt: "Thông báo cuộc gọi có thể bị chế độ Tập trung chặn" (SET-03 trường 8).

## Android: tab Cài đặt

- Cùng danh sách nhóm kiểu Apple (`HLGroupedList`, `HLSwitch` màu `system-green`) với các khóa của
  Android: "Đồng bộ bảng nhớ tạm", "Tự gửi khi sao chép" (`clip.auto_send`, chú thích "Đã đồng ý lúc
  14:05, 24/09/2026"), "Đồng bộ ảnh", "Chặn nội dung nhạy cảm", "Tự xóa bảng nhớ tạm đã nhận", "Tin
  nhắn SMS", "Cuộc gọi", "Nghe gọi trên Mac" và "Dự phòng qua Wi-Fi (cần Shizuku)" kèm trạng thái
  Shizuku, "Dùng điện thoại làm webcam", "Kết nối qua Internet", nhóm Dữ liệu.
- Dòng "Quyền và chạy nền" mở thẻ từng tính năng (SET-01 trường 10) và trạng thái chạy nền (trường
  6–9).
- Dẫn thẳng tới trang của hệ thống, không làm lại: thông tin app
  `ACTION_APPLICATION_DETAILS_SETTINGS`; thông báo `ACTION_APP_NOTIFICATION_SETTINGS`, từng kênh
  `ACTION_CHANNEL_NOTIFICATION_SETTINGS`; `ACTION_ACCESSIBILITY_SETTINGS`; miễn tối ưu pin. Quyền bị
  từ chối thì khóa vẫn lưu `true` và dòng hiện lý do (SET-02 E2).

## Khi tính năng chưa dùng được

Tính năng chỉ hiệu lực khi bật ở cả hai phía và điện thoại đủ quyền. Lý do nằm dưới tiêu đề dòng,
màu `text-orange`; switch vô hiệu nhưng vẫn thấy.

| Nguyên nhân | Chữ | Hành động |
|---|---|---|
| Tắt ở thiết bị kia | "Tắt trên Pixel 8 của Lan" | — |
| Thiếu quyền trên điện thoại | "Thiếu quyền SMS trên điện thoại" | "Xem hướng dẫn" (Mac, iPhone), "Cấp quyền" (Android) |
| Relay tắt ở phía kia | "Kết nối qua Internet đang tắt trên điện thoại" | — |
| Tự gửi tắt trên điện thoại | "Tự gửi đang tắt trên điện thoại — dùng nút Gửi bảng nhớ tạm trên điện thoại" | — |
| Camera khi đang qua Internet | "Cần cùng mạng Wi-Fi hoặc cắm cáp USB" | — |

## Điểm lệch

- Đã đồng bộ với tài liệu chi tiết (25/09/2026): nhãn SET-02 "Đồng bộ bảng nhớ tạm", "Tự xóa bảng
  nhớ tạm đã nhận".
- Đã đồng bộ với tài liệu chi tiết (25/09/2026): SET-02 trường 14 "Dự phòng qua Wi-Fi, cần Shizuku".
  Còn cần đồng bộ: AUDIO-01 bước 1 ghi pane "Âm thanh cuộc gọi" (design system: pane Cuộc gọi); "Tự
  chuyển USB khi cắm cáp" (trường 19) theo CAM-04: "Tự tăng tốc qua USB".
- Đã đồng bộ với tài liệu chi tiết (25/09/2026): khóa `mac.menu_bar_extra` (SET-02 trường 31,
  0.9.5). Còn cần đồng bộ: nút xác nhận "Xóa" (trường 28) đổi thành động từ cụ thể ("Xóa khỏi máy
  chủ", "Xóa toàn bộ"), đi cùng "Hủy".

## Nên và không nên

| Nên | Không nên |
|---|---|
| Lưu ngay khi gạt công tắc | Nút "Lưu" hay "Áp dụng" |
| Nói lý do và cách sửa ngay dưới dòng | Vô hiệu công tắc mà không giải thích |
