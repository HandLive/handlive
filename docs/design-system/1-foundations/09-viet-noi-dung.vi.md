[English](09-viet-noi-dung.md) | Tiếng Việt

# Viết nội dung

Câu chữ của HandLive ngắn, rõ và bình tĩnh như một công cụ của hệ thống. Giao diện có tiếng Anh
(ngôn ngữ mặc định) và tiếng Việt (C20); các mục đầu nói về tiếng Việt, mục "Tiếng Anh" ở cuối. Mục này quy định giọng văn,
cách viết hoa và bỏ dấu, cách viết từng thành phần, thuật ngữ, định dạng số và ngày, và những chỗ
cần đồng bộ với tài liệu thiết kế chi tiết.

Nguồn HIG: https://developer.apple.com/design/human-interface-guidelines/writing

## Giọng văn

- Rõ ràng, bình tĩnh, đáng tin. Nói việc đang xảy ra và việc cần làm; điều quan trọng nhất đặt
  trước.
- Giọng đổi theo ngữ cảnh: lỗi và quyền riêng tư thì trung tính, cụ thể; ghép nối xong thì ấm và
  ngắn ("Đã ghép nối với Pixel 8 của Lan"); cuộc gọi thì tối giản.
- Không "chúng tôi", không dấu chấm than, không emoji, không "Rất tiếc" hay "Úi". Không tiếng lóng,
  thành ngữ.
- Tránh đại từ và sở hữu thừa ("Thiết bị" thay "Thiết bị của bạn"); chỉ xưng "bạn" khi thiếu chủ ngữ
  gây hiểu lầm.
- "Chạm" cho màn hình cảm ứng (iPhone, iPad, Android), "bấm" cho chuột và bàn phím (Mac).

## Viết hoa và dấu

- Sentence case cho mọi thành phần: nút, mục menu, tiêu đề cửa sổ, tab, alert, thông báo. Chỉ viết
  hoa chữ đầu và tên riêng: "Hủy ghép nối", "Gửi bảng nhớ tạm sang điện thoại".
- Lệch có chủ đích: HIG dùng title-style cho nút, menu, tab theo tiếng Anh; tiếng Việt không có lối
  viết hoa từng từ nên HandLive dùng sentence case.
- Tên riêng giữ nguyên: HandLive, Mac, iPhone, iPad, Android, Wi-Fi, Bluetooth, USB, SIM. Tên cài
  đặt hệ thống viết đúng bản tiếng Việt của hệ thống: "Cài đặt hệ thống", "Quyền riêng tư & Bảo
  mật", "Tập trung", "Trung tâm thông báo"; Apple gọi Accessibility là "Trợ năng", Android gọi là
  "Hỗ trợ tiếp cận".
- Không viết HOA TOÀN BỘ.
- Bỏ dấu kiểu Apple, dấu nằm trên nguyên âm chính của vần oa, oe, uy: hóa, xóa, hủy, tùy, thủy,
  khỏe, lũy, khóa, hòa, họa, thỏa. Không viết hoá, xoá, huỷ, tuỳ.

## Từng thành phần

| Thành phần | Quy tắc | Ví dụ |
|---|---|---|
| Nút | Bắt đầu bằng động từ, 1–3 từ; không dùng "Có", "Không" | "Gửi", "Trả lời", "Ghép nối" |
| Nút hủy | Luôn là "Hủy" | "Hủy" |
| OK | Chỉ cho alert thuần thông báo | — |
| Luồng nhiều bước | "Bắt đầu" → "Tiếp tục" → "Xong" | `Onboarding` |
| Alert | Tiêu đề nêu tình huống cụ thể, tối đa 2 dòng; nội dung là câu hoàn chỉnh, chỉ khi thêm giá trị; tối đa 3 nút | "Hủy ghép nối với Pixel 8 của Lan?"; nút "Hủy" (trái), "Hủy ghép nối" (phải) |
| Mục menu | Động từ; mục bật tắt dùng dấu kiểm | "Gửi bảng nhớ tạm sang điện thoại" |
| Thông báo | Tiêu đề ngắn, không dấu chấm, không chèn "HandLive"; nội dung là câu hoàn chỉnh | "Cuộc gọi nhỡ" |
| Tooltip (Mac) | Bắt đầu bằng động từ, tối đa 60–75 ký tự, không lặp tên control | "Tắt tiếng micro trên Mac" |
| Tiêu đề cửa sổ | Danh từ, dưới 15 ký tự | "Tin nhắn" |
| Mô tả cài đặt | Nói tác dụng khi bật | "Thông báo tin nhắn hiện cả nội dung tin." |

Purpose string xin quyền: xem mục Quyền riêng tư.

## Thuật ngữ

| Dùng | Không dùng |
|---|---|
| Bảng nhớ tạm | Clipboard, bộ nhớ đệm |
| Ghép nối, Hủy ghép nối | Pair, kết đôi |
| Kết nối qua Internet | Relay, máy chủ relay |
| Cùng mạng Wi-Fi (nhãn ngắn: LAN) | LAN trong câu |
| Hỗ trợ tiếp cận (Android), Trợ năng (Apple) | Accessibility |
| Gỡ lỗi USB | USB debugging |
| Micro | Microphone, mic |
| Cuộc gọi nhỡ | Cuộc gọi lỡ |
| Mã an toàn | Vân tay, fingerprint |
| Tập trung | Focus, Không làm phiền |
| Ngoại tuyến | Offline |

## Số, ngày, giờ

Dùng formatter của hệ thống với locale tiếng Việt, không tự ghép chuỗi.

| Loại | Dạng | API |
|---|---|---|
| Giờ | "14:05" | `Date.FormatStyle`; Android `DateFormat.getTimeFormat` |
| Ngày | "24/09"; khác năm "24/09/2025"; "Hôm qua" | `Date.FormatStyle` |
| Thời lượng | "02:15" khi đang đếm; lịch sử "2 phút 5 giây" | `DateComponentsFormatter` |
| Tương đối | "5 phút trước" | `RelativeDateTimeFormatter` |
| Số điện thoại | "090 000 0123" | Android `PhoneNumberUtils.formatNumber` |
| Số | "1.500"; thập phân "0,5" | `.formatted()`, `NumberFormatter` |
| Dung lượng | "5 MB" | `ByteCountFormatStyle`; Android `Formatter.formatShortFileSize` |

## Lỗi

Mẫu: chuyện gì xảy ra, rồi cách xử lý. Đặt ngay cạnh chỗ lỗi; không đổ lỗi cho người dùng; không mã
lỗi, không tiêu đề chung chung "Lỗi".

| Viết | Tránh |
|---|---|
| "Mã PIN không đúng. Kiểm tra mã trên Mac rồi nhập lại." | "PIN_INVALID" |
| "Cần cùng mạng Wi-Fi hoặc cắm cáp USB" | "Không hỗ trợ kênh truyền" |
| "Chưa gửi được. Điện thoại đang ở chế độ máy bay." | "Gửi thất bại" |

## Trạng thái trống

Luôn có bước tiếp theo: tiêu đề `brand-title`, một câu, một nút; không đặt thông tin quan trọng ở
đây. Ví dụ: "Chưa có điện thoại" · "Ghép điện thoại Android để nhận bảng nhớ tạm, tin nhắn và cuộc
gọi." · nút "Thêm điện thoại…".

## Dấu "…"

- Dùng ký tự "…" (một ký tự), không gõ ba dấu chấm.
- Cho lệnh cần thêm bước nhập hoặc chọn ("Cài đặt…", "Từ chối kèm tin nhắn…") và nút Mac mở cửa sổ
  hay sheet khác ("Thêm điện thoại…").
- Cho trạng thái đang diễn ra: "Đang kết nối…", "Đang gửi…".
- Không dùng cho lệnh chạy ngay ("Gửi", "Trả lời").

## Đã đồng bộ với tài liệu chi tiết

Đã áp dụng toàn bộ vào `docs/detailed-design/` ngày 25/09/2026 (README §3.5, C19). Tên mục hệ thống
("Quyền riêng tư & Bảo mật") lấy theo bản tiếng Việt của Apple; kế hoạch triển khai có việc đối
chiếu trên máy thật.

| Tài liệu chi tiết | Design system | Nơi |
|---|---|---|
| huỷ, xoá, tuỳ, hoá, khoá, hoà, hoạ, thoả | hủy, xóa, tùy, hóa, khóa, hòa, họa, thỏa | Khoảng 800 chỗ: khoá 253, xoá 238, hoá 155, huỷ 95, tuỳ 46, hoà 6, hoạ 4, thoả 2 |
| "Gửi clipboard", "Đồng bộ clipboard", "Tự xoá clipboard đã nhận", "Clipboard trống hoặc không phải văn bản" | "Gửi bảng nhớ tạm", "Đồng bộ bảng nhớ tạm", "Tự xóa bảng nhớ tạm đã nhận", "Bảng nhớ tạm trống hoặc không phải văn bản" | CLIP-01 đến CLIP-04, SET-01, SET-03 |
| "máy chủ relay không đọc được nội dung" | "máy chủ không đọc được nội dung" | SET-01, SET-03 trường 1 |
| "Đã kết nối (LAN)", "Đã kết nối (qua Internet)" | "Đã kết nối qua Wi-Fi", "Đã kết nối qua Internet" | 0.11, CONN-01, PAIR-02; nhãn ngắn vẫn được "LAN" |
| "Quyền riêng tư và bảo mật" | "Quyền riêng tư & Bảo mật" | SET-03, CLIP-02, AUDIO-01, CAM-01 |
| "Không, tôi sẽ gửi thủ công" | "Gửi thủ công" | CLIP-01 trường 3; nút bắt đầu bằng động từ |
| "Thêm điện thoại" (nút Mac mở sheet mã QR) | "Thêm điện thoại…" | PAIR-01 |
| "Đã tải 1 500 tin" | "Đã tải 1.500 tin" | SMS-01; dấu ngăn nghìn của tiếng Việt |

## Tiếng Anh — ngôn ngữ mặc định

HandLive viết tiếng Anh theo Apple Style Guide và bản tiếng Anh của HIG. Tiếng Anh là ngôn ngữ nguồn
của catalog chuỗi (`shared/strings/ui-strings.json`, tài liệu chi tiết 0.12); mỗi chuỗi có bản tiếng
Việt theo các mục trên (C20).

- Viết hoa kiểu tiêu đề (title-style) cho nút, mục menu, tiêu đề cửa sổ và sheet, tab, nhãn dòng
  cài đặt, tiêu đề alert: "Send Clipboard to Phone", "Unpair", "Add Phone…". Viết hoa mọi từ trừ mạo
  từ (a, an, the), liên từ (and, but, or, nor) và giới từ từ bốn chữ cái trở xuống (at, by, for, from, in, into, of, off, on, onto, out, over, to, up, via, with) khi không đứng đầu hay cuối.
- Viết hoa kiểu câu (sentence-style) cho mô tả, chú thích, nội dung alert, nội dung thông báo, chuỗi
  trạng thái, tooltip: "Connected via Wi-Fi", "Keep the phone and this Mac on the same Wi-Fi
  network."
- Giọng ngắn, chủ động, thì hiện tại; không "please", "sorry", "oops", dấu chấm than, emoji; chỉ dùng
  "you" khi câu thiếu chủ ngữ gây hiểu lầm. "Tap" cho màn hình cảm ứng, "click" cho Mac.
- Tên mục của hệ điều hành viết đúng bản tiếng Anh: "System Settings", "Privacy & Security",
  "Focus", "Notification Center", "Accessibility" (cả Apple và Android), "Paste from Other Apps".
- "internet" viết thường trong câu ("Connected over the internet"), viết hoa khi cả chuỗi viết hoa
  kiểu tiêu đề.
- Số, ngày, giờ theo locale tiếng Anh qua formatter của hệ thống ("2:05 PM" ở en-US, "Sep 24",
  "1,500", "0.5", "5 MB"); không tự ghép chuỗi.
- Lỗi: chuyện gì xảy ra rồi cách xử lý — "The PIN is incorrect. Check the code on your Mac and try
  again."; không mã lỗi, không tiêu đề chung chung "Error".
- Dấu "…" và các quy tắc về nút, alert, thông báo, trạng thái trống như bản tiếng Việt.

| Tiếng Anh | Tiếng Việt | Ghi chú |
|-----------|------------|---------|
| Clipboard | Bảng nhớ tạm | |
| Pair, Unpair | Ghép nối, Hủy ghép nối | |
| Internet connection ("Connected over the internet") | Kết nối qua Internet | Không dùng "relay" ở cả hai ngôn ngữ |
| Same Wi-Fi network (nhãn ngắn: LAN) | Cùng mạng Wi-Fi (nhãn ngắn: LAN) | |
| Accessibility | Hỗ trợ tiếp cận (Android), Trợ năng (Apple) | |
| USB debugging | Gỡ lỗi USB | |
| Microphone | Micro | |
| Missed Call | Cuộc gọi nhỡ | |
| Security Code | Mã an toàn | |
| Focus | Tập trung | |
| Offline | Ngoại tuyến | |
| Phone | Điện thoại | Điện thoại Android đã ghép |

## Nên và không nên

| Nên | Không nên |
|---|---|
| "Hủy ghép nối" | "Huỷ Ghép Nối" |
| "Bảng nhớ tạm" | "Clipboard" |
| "Không gửi được ảnh lớn hơn 10 MB." | "Ảnh quá lớn" |
| "Đang kết nối…" | "Đang kết nối..." |
