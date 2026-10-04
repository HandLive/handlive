# Brief: viết lại nội dung website và phần giới thiệu HandLive

Ngày 2026-10-04. Tài liệu này cung cấp thông tin nền để một người viết độc lập viết lại toàn bộ nội dung
website và đoạn giới thiệu HandLive theo góc nhìn của riêng họ. Nó không kèm mẫu, không kèm hướng dẫn giọng
văn: chỉ gồm sự thật về sản phẩm, các ràng buộc có sẵn của dự án, phản hồi của chủ dự án, nội dung hiện tại
và danh sách những chỗ cần chữ.

---

## 1. Yêu cầu của chủ dự án

- Nội dung website và phần giới thiệu HandLive hiện tại "giọng điệu quá khô khan và cứng nhắc, cho người đọc
  cảm giác rất khó hiểu".
- Muốn viết lại toàn bộ, bằng cả tiếng Anh và tiếng Việt, với góc nhìn mới.
- Phản hồi về hai bản nháp tiêu đề gần đây (để tránh lặp lại, không phải để định hướng):
  - *"Điện thoại vừa rung. Khỏi phải đứng dậy."*: "không có một tí điểm nhấn thương hiệu nào".
  - *"Điện thoại vừa rung. Mac đã sáng lên."*: "tập trung vào tin nhắn và các cuộc gọi quá, trong khi phần
    cuộc gọi thực tế làm chưa tốt".

## 2. Sản phẩm

HandLive là app mã nguồn mở (giấy phép Apache-2.0) giữ một điện thoại Android đồng bộ với Mac, iPhone và
iPad của cùng một người. Dành cho người dùng điện thoại Android nhưng có Mac, iPhone hoặc iPad.

| Tính năng | Trên Mac | Trên iPhone, iPad | Tình trạng (10/2026) |
|---|---|---|---|
| Sao chép ở máy này, dán ở máy kia, cả hai chiều (chữ và ảnh) | Có | Có | Hoạt động ổn định; chữ đến dưới 50 ms khi cùng Wi-Fi |
| Đọc và trả lời tin nhắn SMS của điện thoại, xem trọn cuộc trò chuyện | Có | Có | Hoạt động; thông báo đẩy khi không cùng Wi-Fi còn đang kiểm tra trên hạ tầng thật |
| Cuộc gọi đến: thấy tên người gọi; từ chối; kết thúc | Thấy, nghe (điều khiển), từ chối, kết thúc | Thấy và từ chối | Mã đã có nhưng chủ dự án đánh giá phần này "thực tế làm chưa tốt"; chưa kiểm tra đủ trên máy thật |
| Âm thanh cuộc gọi phát trên Mac | Chưa có | Không có kế hoạch | Đang thử nghiệm kỹ thuật |
| Camera và micro của điện thoại dùng cho Mac | Chưa có | Không có kế hoạch | Đang thử nghiệm kỹ thuật |
| Duyệt web tiếp: trang đang mở ở máy này hiện ở máy kia | Chưa có | Chưa có | Đang thử nghiệm kỹ thuật |

Các sự thật khác:

- Không có tài khoản. Các máy tự tìm nhau trong cùng mạng Wi-Fi; ghép nối bằng cách quét mã QR (có đường
  dự phòng bằng mã PIN 6 số).
- Mã hóa đầu cuối luôn bật, không có tùy chọn tắt. Khóa mã hóa chỉ nằm trên thiết bị của người dùng.
- Khi hai máy không cùng Wi-Fi, có thể dùng máy chủ chuyển tiếp (tùy chọn; tự host được): nó chuyển dữ liệu
  đã mã hóa, không đọc được nội dung, không lưu nội dung; chỉ giữ thời gian, kích thước gói và địa chỉ IP
  tối đa một giờ để chống lạm dụng.
- Không quảng cáo, không thống kê, không theo dõi, không SDK bên thứ ba.
- Nội dung bảng nhớ tạm nhận được tự xóa sau 60 giây (mặc định); nội dung giống mật khẩu hay số thẻ không
  được gửi, chỉ báo.
- Mỗi app dùng thành phần giao diện gốc của nền tảng mình (AppKit/SwiftUI trên Mac, SwiftUI trên iOS,
  Compose trên Android), có tiếng Anh và tiếng Việt.
- Bản beta công khai `v0.1.0-beta.1` phát hành 30/09/2026, tải từ GitHub; chưa có trên App Store hay
  Google Play.
- Yêu cầu: Android 10 trở lên; macOS 13 trở lên; iOS 16 và iPadOS 16 trở lên.
- Mã nguồn: https://github.com/HandLive. Trang tải bản beta:
  https://github.com/HandLive/handlive/releases/tag/v0.1.0-beta.1

## 3. Thương hiệu (những gì đã quyết định)

- **Tên:** HandLive. Một từ, H và L viết hoa.
- **Tagline (chủ dự án đã chọn):** *Never miss a signal.* / *Không bỏ lỡ tín hiệu nào.* Vị trí đặt trên
  trang chưa quyết.
- **Logo:** ngọn lửa hiệu trên đỉnh núi với các vòng sóng lan ra. Ý nghĩa trong tài liệu thương hiệu: điều
  xảy ra trên điện thoại hiện lên màn hình trước mặt người dùng; ngọn núi là điện thoại, ngọn lửa là điều
  vừa xảy ra, vòng sóng là tín hiệu lan tới các thiết bị khác.
- **Màu:** đỏ lửa, cam, hổ phách trên nền tím than và kem (bảng màu bình minh). Nút bấm màu xanh lá.
- **Tính cách** ghi trong tài liệu thiết kế: đáng tin, kín đáo, ấm.
- **Font:** tiêu đề Be Vietnam Pro Bold; chữ thân font hệ thống.

## 4. Ràng buộc có sẵn của dự án

- **Song ngữ:** mọi nội dung có bản tiếng Anh và bản tiếng Việt, cùng cấu trúc; tiếng Anh là bản gốc.
- **Tiếng Anh:** theo văn phong tiếng Anh của Apple; nút, menu, tiêu đề cửa sổ viết hoa kiểu tiêu đề.
- **Tiếng Việt:** bỏ dấu kiểu Apple (hủy, xóa, mã hóa, tùy, hòa; không huỷ, xoá, hoá, tuỳ, hoà).
- **Thuật ngữ trong giao diện app** (đã cố định cho nút và menu trong app): "bảng nhớ tạm" (clipboard),
  "SMS", "ghép nối" (pairing), "mã hóa đầu cuối", "máy chủ chuyển tiếp" (relay), "Duyệt web tiếp" (Continue
  Browsing). Website có bắt buộc dùng đúng các từ này hay không là việc chưa quyết; người viết tự đề xuất.
- **Nhãn hiệu:** viết đúng iPhone, iPad, Mac, macOS, iOS, iPadOS, Android. Không dùng tên tính năng của Apple
  (Continuity, Handoff, AirDrop, Universal Clipboard) để gọi tính năng của HandLive; không ghép "Apple" vào
  tên app; mô tả trên store dùng "cho Mac", "dùng với iPhone và iPad". Android là nhãn hiệu của Google LLC.
- **Đúng sự thật:** không khẳng định điều chưa có trong bảng ở mục 2 (âm thanh cuộc gọi trên Mac, nghe máy
  trên iPhone/iPad, có trên App Store/Google Play).

## 5. Nội dung hiện tại

### 5.1 Trang chủ, tiếng Anh

```
[nhãn] Public beta · v0.1.0-beta.1
[H1] Never miss a signal.
[phụ] Your Android phone's clipboard, SMS, and calls on your Mac, iPhone, and iPad. End-to-end encrypted, no account needed, open source.
[nút] Get the Beta · View on GitHub
[chú thích] Android 10 or later · macOS 13 or later · iOS and iPadOS 16 or later

[H2] Your phone, right where you work
HandLive brings what happens on your Android phone to the screen in front of you, and keeps it private.
- Clipboard, both ways — Copy on your phone, paste on your Mac. Copy on your iPad, paste on your phone. Text arrives right away on the same Wi-Fi.
- Texts at your desk — Read and answer the SMS on your Android phone from your Mac, iPhone, or iPad, with the whole conversation in view.
- Know who's calling — Incoming calls show up on your Mac with the caller's name. Answer, decline, or end them from your desk; your iPhone and iPad show who's calling too.
- Private by design — Everything is end-to-end encrypted, and you can't turn that off. Only your own devices can read your data.
- No account to make — Your devices find each other on your Wi-Fi and pair with a QR code. Away from home, an optional relay forwards data it can't read.
- Open and native — Built with each platform's own tools and design, so it feels at home on every device. The code is open source under Apache-2.0.

[H2] Set up in three steps — No account, no cables.
1. Install — Install HandLive on your Android phone and on your Mac, iPhone, or iPad.
2. Pair — Your Mac, iPhone, or iPad shows a QR code; scan it with your phone. The keys never leave your devices.
3. Carry on — Copy, text, and take calls as usual. HandLive stays quietly in the background.

[H2] On every screen you use — Each app follows the design of its own platform, in English and Vietnamese.
[ảnh] Mac: texts and calls in one window · iPhone: answer your phone's texts · Android: paired with your Mac over Wi-Fi

[H2] What works where
[bảng] Two-way clipboard: Yes / Yes · Read and send SMS: Yes / Yes · Calls: Details, answer, decline, end / Details and decline · Call audio on the computer: Coming / — · Camera and microphone for the Mac: Coming / — · Continue Browsing: Coming / Coming
Requires Android 10 or later, and macOS 13, iOS 16, or iPadOS 16 or later.

[H2] Your data stays yours — HandLive moves your texts, calls, and clipboard between your own devices, and nowhere else.
- End-to-end encryption you can't turn off
- QR pairing; the keys stay on your devices
- Works on your own Wi-Fi, with no account
- The optional relay can't read what it forwards
- Open source, so anyone can check
[nút] Read the Privacy Notice

[H2] Try the public beta — The beta is for early testers. It isn't on the App Store or Google Play yet: the builds are on GitHub.
[nút] Get the Beta · Read the Announcement

[chân trang] Never miss a signal.
```

### 5.2 Trang chủ, tiếng Việt

```
[nhãn] Bản beta công khai · v0.1.0-beta.1
[H1] Không bỏ lỡ tín hiệu nào.
[phụ] Bảng nhớ tạm, SMS và cuộc gọi của điện thoại Android, ngay trên Mac, iPhone và iPad. Mã hóa đầu cuối, không cần tài khoản, mã nguồn mở.
[nút] Dùng bản beta · Xem trên GitHub
[chú thích] Android 10 trở lên · macOS 13 trở lên · iOS và iPadOS 16 trở lên

[H2] Điện thoại của bạn, ngay nơi bạn làm việc
HandLive đưa điều xảy ra trên điện thoại Android lên màn hình trước mặt bạn, và giữ nó riêng tư.
- Bảng nhớ tạm hai chiều — Chép trên điện thoại, dán trên Mac. Chép trên iPad, dán trên điện thoại. Chữ đến ngay khi hai máy cùng mạng Wi-Fi.
- Tin nhắn ngay tại bàn — Đọc và trả lời SMS của điện thoại Android từ Mac, iPhone hay iPad, thấy trọn cả cuộc trò chuyện.
- Biết ai đang gọi — Cuộc gọi đến hiện trên Mac kèm tên người gọi. Nghe, từ chối hay kết thúc ngay tại bàn; iPhone và iPad cũng cho biết ai đang gọi.
- Riêng tư từ thiết kế — Mọi thứ được mã hóa đầu cuối, và không thể tắt. Chỉ thiết bị của bạn đọc được dữ liệu của bạn.
- Không cần tạo tài khoản — Các thiết bị tự tìm nhau trong Wi-Fi và ghép nối bằng mã QR. Khi ra ngoài, máy chủ chuyển tiếp (tùy chọn) chuyển dữ liệu mà nó không đọc được.
- Mở và gốc — Làm bằng công cụ và thiết kế của từng nền tảng, nên dùng tự nhiên trên mọi thiết bị. Mã nguồn mở theo giấy phép Apache-2.0.

[H2] Thiết lập trong ba bước — Không tài khoản, không dây cáp.
1. Cài đặt — Cài HandLive trên điện thoại Android và trên Mac, iPhone hay iPad.
2. Ghép nối — Mac, iPhone hay iPad hiện một mã QR; quét bằng điện thoại. Khóa mã hóa không bao giờ rời khỏi thiết bị của bạn.
3. Dùng như thường — Chép, nhắn tin và nghe gọi như mọi khi. HandLive lặng lẽ chạy nền.

[H2] Trên mọi màn hình bạn dùng — Mỗi app theo đúng thiết kế của nền tảng mình, bằng tiếng Anh và tiếng Việt.
[ảnh] Mac: tin nhắn và cuộc gọi trong một cửa sổ · iPhone: trả lời tin nhắn của điện thoại · Android: đã ghép nối với Mac qua Wi-Fi

[H2] Có gì trên từng thiết bị
[bảng] như bản tiếng Anh; "Sắp có" thay cho "Coming"
Cần Android 10 trở lên, và macOS 13, iOS 16 hay iPadOS 16 trở lên.

[H2] Dữ liệu của bạn là của bạn — HandLive chuyển tin nhắn, cuộc gọi và bảng nhớ tạm giữa các thiết bị của chính bạn, không đi đâu khác.
- Mã hóa đầu cuối, không thể tắt
- Ghép nối bằng mã QR; khóa ở lại trên thiết bị của bạn
- Chạy trong Wi-Fi của bạn, không cần tài khoản
- Máy chủ chuyển tiếp (tùy chọn) không đọc được những gì nó chuyển
- Mã nguồn mở, ai cũng kiểm tra được
[nút] Đọc thông báo quyền riêng tư

[H2] Dùng thử bản beta công khai — Bản beta dành cho người dùng thử sớm. Bản này chưa có trên App Store hay Google Play: các bản dựng nằm trên GitHub.
[nút] Dùng bản beta · Đọc bài giới thiệu

[chân trang] Không bỏ lỡ tín hiệu nào.
```

### 5.3 Giới thiệu ngắn và chữ cho store

| Mục | Tiếng Anh | Tiếng Việt |
|---|---|---|
| Câu giới thiệu một dòng | Your Android phone's clipboard, SMS, and calls on your Mac, iPhone, and iPad. | Bảng nhớ tạm, SMS và cuộc gọi của điện thoại Android, ngay trên Mac, iPhone và iPad. |
| Boilerplate (README, About) | HandLive is an open-source app that keeps an Android phone in step with a Mac, iPhone, and iPad: clipboard, SMS, and calls, end-to-end encrypted, with no account required. It is free software under the Apache-2.0 license. | HandLive là app mã nguồn mở giữ điện thoại Android đồng nhịp với Mac, iPhone và iPad: bảng nhớ tạm, SMS và cuộc gọi, mã hóa đầu cuối, không cần tài khoản. Đây là phần mềm tự do theo giấy phép Apache-2.0. |
| App Store subtitle | Your phone's texts and calls | Tin nhắn, cuộc gọi của điện thoại |
| Play short description | Clipboard, SMS, and calls from your phone on your Mac, iPhone, and iPad. | Bảng nhớ tạm, SMS và cuộc gọi từ điện thoại lên Mac, iPhone và iPad. |

### 5.4 Hai bài blog hiện có (đoạn mở)

- *HandLive's first public beta* (30/09/2026): "Today we're publishing v0.1.0-beta.1, the first public beta
  of HandLive. It's for early testers who want their Android phone's clipboard, texts, and calls on a Mac,
  iPhone, or iPad, and who are happy to tell us what breaks."
- *A new look for HandLive* (04/10/2026): "HandLive now has a logo, an app icon, and a voice of its own.
  Here is what they stand for."

## 6. Những chỗ cần chữ

Trang chủ hiện có các khối dưới đây. Giữ nguyên, bỏ bớt, gộp hay sắp xếp lại đều được; nếu đổi cấu trúc,
ghi rõ để người dựng trang làm theo.

| Khối | Hiện có | Giới hạn vật lý |
|---|---|---|
| Hero | nhãn nhỏ, H1, câu phụ, 2 nút, dòng chú thích | H1 hiển thị rất lớn; trên màn hình điện thoại 375 px mỗi dòng chứa khoảng 13–16 ký tự |
| Tính năng | tiêu đề, câu dẫn, 6 thẻ (tiêu đề + đoạn) | Số thẻ tùy ý |
| Cài đặt | tiêu đề, câu dẫn, 3 bước | |
| Ảnh chụp màn hình | tiêu đề, câu dẫn, 3 chú thích (Mac, iPhone, Android) | Ảnh có sẵn, nội dung ảnh như mô tả ở 5.1 |
| Bảng tính năng theo thiết bị | tiêu đề, bảng, dòng yêu cầu hệ điều hành | Nội dung bảng là sự thật, giữ nguyên |
| Quyền riêng tư | tiêu đề, câu dẫn, 5 gạch đầu dòng, nút sang trang Privacy | |
| Lời mời beta | tiêu đề, đoạn, 2 nút | |
| Chân trang | tagline, liên kết | |

Ngoài trang chủ:

| Mục | Giới hạn |
|---|---|
| Câu giới thiệu một dòng | |
| Boilerplate | |
| App Store subtitle | tối đa 30 ký tự |
| Google Play short description | tối đa 80 ký tự |
| Đoạn đầu mô tả trên App Store / Google Play | |
| Đoạn mở của hai bài blog ở 5.4 | |

Các nút hiện có (Get the Beta / Dùng bản beta; View on GitHub / Xem trên GitHub; Read the Privacy Notice / Đọc
thông báo quyền riêng tư; Read the Announcement / Đọc bài giới thiệu) có thể đổi chữ; đích liên kết giữ
nguyên.

Mỗi mục giao đủ hai bản tiếng Anh và tiếng Việt.
