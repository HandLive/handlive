[English](brand-guidelines.md) | Tiếng Việt

# Hướng dẫn thương hiệu HandLive

Phiên bản 1.0, 2026-10-01. Nguồn chuẩn cho câu chuyện, giọng văn, thông điệp, logo, biểu tượng app, màu
sắc và ảnh quảng bá của HandLive. Thương hiệu xuất hiện thế nào bên trong app (màu thương hiệu được đặt ở
đâu, màn chào, chữ HandLive trên giao diện) nằm trong design system: [Thương hiệu](design-system/1-foundations/11-thuong-hieu.vi.md).

## Tra nhanh

| Thành phần | Giá trị |
|---|---|
| Tên | HandLive: một từ, viết hoa H và L. Không viết "Handlive", "Hand Live" hay "HL" trong nội dung công khai |
| Tagline | Không bỏ lỡ tín hiệu nào. |
| Dòng mô tả | Bảng nhớ tạm, SMS và cuộc gọi của điện thoại Android, ngay trên Mac, iPhone và iPad. |
| Biểu tượng | Ngọn lửa hiệu trên đỉnh núi, tín hiệu đang lan ra |
| Màu thương hiệu | `brand-fire` #e63d1a, `brand-flame` #ff861f, `brand-ember` #33232d, `brand-glow` #fff0e3 |
| Màu hành động | `accent` xanh lá #197934 (Tối #3ddc6c) |
| Font thương hiệu | Be Vietnam Pro Bold (SIL OFL 1.1) |
| Giọng văn | Rõ ràng, điềm tĩnh, ấm áp, trung thực |
| File | `docs/brand/assets/` (logo, biểu tượng app, quảng bá), dựng bằng `tools/brand/build_brand_assets.py` |

## 1. Câu chuyện

HandLive giữ điện thoại Android đồng nhịp với Mac, iPhone và iPad của cùng một người. Ngay khi có chuyện
trên điện thoại (bạn chép một liên kết, có tin nhắn đến, có người gọi), nó hiện lên màn hình trước mặt
bạn. Chỉ thiết bị của bạn đọc được: dữ liệu được mã hóa đầu cuối, máy chủ chuyển tiếp ở giữa không thấy
gì.

Logo vẽ khoảnh khắc đó thành ngọn lửa hiệu trên đỉnh núi, tỏa tín hiệu tới các thiết bị xung quanh, bằng
ba hình:

| Hình | Ý nghĩa |
|---|---|
| Ngọn núi (tím than) | Điện thoại của bạn: vững chãi, luôn ở đó |
| Ngọn lửa (đỏ sang hổ phách) | Điều vừa xảy ra: một lần chép, một tin nhắn, một cuộc gọi |
| Vòng sóng (cam, nhạt dần) | Tín hiệu lan tới các thiết bị khác của bạn |

Màu sắc là màu bình minh: ấm và điềm tĩnh. HandLive nên giống ngọn đèn để sẵn, không phải tiếng còi.

## 2. Định vị

| Mục | HandLive |
|---|---|
| Dành cho | Người dùng điện thoại Android và làm việc trên Mac, thường có thêm iPad hay iPhone |
| Vấn đề | Tính năng liên tục của Apple chỉ chạy giữa thiết bị Apple. Người dùng Android tự gửi email liên kết cho mình, nhìn mã SMS trên điện thoại, lỡ cuộc gọi khi ngồi ở bàn |
| Lời hứa | Điều xảy ra trên điện thoại hiện ngay trên màn hình của bạn, một cách riêng tư |
| Bằng chứng | Mã hóa đầu cuối không tắt được; ghép nối bằng mã QR; chạy trong mạng nội bộ, không cần tài khoản; máy chủ chuyển tiếp không biết nội dung; app gốc theo đúng thiết kế của Apple và Android; mã nguồn mở (Apache-2.0) |
| Không phải | Không phải dịch vụ đám mây, không phải điều khiển từ xa hay chiếu màn hình, không phải sản phẩm của Apple hay Google |

## 3. Tính cách và giọng văn

| Nét tính cách | Chúng tôi là | Chúng tôi không |
|---|---|---|
| Đáng tin | Nói chính xác chuyện gì xảy ra với dữ liệu | Mơ hồ, hay "cứ tin chúng tôi" |
| Kín đáo | Lặng lẽ chạy nền cho tới khi cần | Nói nhiều, gửi thông báo dồn dập |
| Ấm áp | Gần gũi, giản dị, nhẹ nhàng | Làm duyên, đùa trong thông báo lỗi, đầy emoji |
| Chính xác | Con số và sự thật ("dưới 50 ms") | So sánh nhất ("nhanh như chớp", "tốt nhất") |

### Giọng theo ngữ cảnh

| Ngữ cảnh | Giọng | Ví dụ |
|---|---|---|
| Thiết lập, ghép nối | Ấm áp, từng bước một | "Quét mã này bằng điện thoại." |
| Thành công | Ngắn, rồi lui ra | "Đã ghép nối với Pixel 9." |
| Lỗi | Bình tĩnh, nói bước tiếp theo | "Không kết nối được điện thoại. Kiểm tra hai máy cùng một mạng Wi-Fi." |
| Quyền riêng tư, cấp quyền, pháp lý | Rõ và đủ, không dọa | "Tin nhắn được mã hóa trên điện thoại và chỉ giải mã trên Mac của bạn." |
| Ghi chú phát hành | Đúng sự thật, người dùng trước | "Cuộc gọi: giờ bạn có thể từ chối ngay trên Mac." |
| Quảng bá | Tự tin, cụ thể | "Không bỏ lỡ tín hiệu nào. Tin nhắn và cuộc gọi của điện thoại, ngay trên Mac." |

### Quy tắc viết

- Câu ngắn; câu hướng dẫn mở đầu bằng động từ ("Quét", "Cho phép", "Ghép nối").
- Mỗi khi dữ liệu di chuyển, nói rõ chuyện gì xảy ra với nó.
- Con số thay cho tính từ; chỉ nói điều chứng minh được.
- Chữ giao diện tiếng Anh theo văn phong tiếng Anh của Apple (viết hoa kiểu tiêu đề cho nút, menu, tiêu
  đề cửa sổ). Tiếng Việt bỏ dấu kiểu Apple (hủy, xóa, mã hóa) và dùng thuật ngữ của design system
  ("bảng nhớ tạm", không "clipboard"). Chi tiết: [Viết nội dung](design-system/1-foundations/09-viet-noi-dung.vi.md).

### Từ ngữ

| Dùng | Tránh | Lý do |
|---|---|---|
| mã hóa đầu cuối | chuẩn quân đội, không thể hack | Chính xác, và đúng sự thật |
| ghép nối, đã ghép nối | kết bạn, móc nối | Một hành động, một từ |
| điện thoại của bạn, Mac của bạn | thiết bị đầu cuối | Người ta sở hữu thiết bị, không sở hữu "đầu cuối" |
| máy chủ chuyển tiếp (khi buộc phải nhắc) | đồng bộ đám mây | Không có gì được lưu trên đám mây |
| dùng với iPhone và iPad; cho Mac | cho Apple, Apple Continuity cho Android | Quy tắc nhãn hiệu Apple (mục 11) |
| đơn giản, nhanh | liền mạch, cách mạng, kỳ diệu | Sáo mòn, không nói được gì |

## 4. Thông điệp

| Mục | Tiếng Anh | Tiếng Việt |
|---|---|---|
| Tagline | Never miss a signal. | Không bỏ lỡ tín hiệu nào. |
| Câu giới thiệu | Your Android phone's clipboard, SMS, and calls on your Mac, iPhone, and iPad. | Bảng nhớ tạm, SMS và cuộc gọi của điện thoại Android, ngay trên Mac, iPhone và iPad. |
| Phụ đề App Store (≤ 30) | Your phone's texts and calls | Tin nhắn, cuộc gọi của điện thoại |
| Mô tả ngắn Play (≤ 80) | Clipboard, SMS, and calls from your phone on your Mac, iPhone, and iPad. | Bảng nhớ tạm, SMS và cuộc gọi từ điện thoại lên Mac, iPhone và iPad. |

### Giới thiệu trong 30 giây

HandLive đưa điện thoại Android của bạn lên Mac, iPhone và iPad. Chép ở máy này, dán ở máy kia. Đọc và
trả lời tin nhắn, xem ai đang gọi, nghe hay từ chối ngay tại bàn làm việc. Mọi thứ được mã hóa đầu cuối,
chạy trong Wi-Fi của chính bạn mà không cần tài khoản, và mã nguồn mở cho mọi người.

### Trụ cột thông điệp

| Trụ cột | Thông điệp | Bằng chứng |
|---|---|---|
| Ngay nơi bạn đang ở | Điều xảy ra trên điện thoại hiện lên màn hình trước mặt bạn | Bảng nhớ tạm dưới 50 ms trong cùng mạng; SMS và thông tin cuộc gọi trên Mac và iPhone |
| Riêng tư từ thiết kế | Chỉ thiết bị của bạn đọc được dữ liệu của bạn | Luôn mã hóa đầu cuối, ghép nối bằng mã QR, máy chủ chuyển tiếp không biết nội dung |
| Gốc và mở | Như sinh ra cho từng thiết bị; ai cũng đọc được mã nguồn | Apple HIG trên mọi nền tảng, Apache-2.0 |

### Theo đối tượng

| Đối tượng | Mở đầu bằng |
|---|---|
| Người dùng Mac có điện thoại Android | "Tin nhắn và cuộc gọi, ngay trên Mac của bạn." |
| Người coi trọng quyền riêng tư | "Mã hóa đầu cuối. Không tài khoản. Mã nguồn mở." |
| Lập trình viên, người đóng góp | "Mã nguồn mở, WebSocket cho dữ liệu và Bluetooth cho giọng nói; cùng xây với chúng tôi." |

### Đoạn giới thiệu chuẩn

HandLive là app mã nguồn mở giữ điện thoại Android đồng nhịp với Mac, iPhone và iPad: bảng nhớ tạm, SMS
và cuộc gọi, mã hóa đầu cuối, không cần tài khoản. Đây là phần mềm tự do theo giấy phép Apache-2.0.

## 5. Logo

### Thành phần và file

| Thành phần | File (`docs/brand/assets/logo/`) | Dùng cho |
|---|---|---|
| Biểu tượng | `handlive-mark.svg`, `-on-dark.svg` | Huy hiệu app, ảnh đại diện, favicon từ 33 px trở lên |
| Biểu tượng rút gọn | `handlive-mark-compact.svg` | 16–32 px: bỏ vòng sóng ngoài |
| Biểu tượng một màu | `handlive-mark-mono-black.svg`, `-mono-white.svg` | Dập nổi, in một màu, biểu tượng theo chủ đề |
| Chữ HandLive | `handlive-wordmark.svg`, `-on-dark.svg` | Khi biểu tượng đã có ở gần đó |
| Bộ ghép ngang | `handlive-lockup-horizontal.svg`, `-on-dark.svg` | Mặc định: README, đầu trang web, slide |
| Bộ ghép dọc | `handlive-lockup-stacked.svg`, `-on-dark.svg` | Khung vuông, poster, ảnh chào |

Mỗi SVG có PNG đi kèm. Chữ HandLive là Be Vietnam Pro Bold, khoảng chữ −0,01 em, đã chuyển thành đường
nét: file không cần font.

### Cấu trúc

- Một hình học trên lưới 1024 (`tools/brand/brand_geometry.py`): ngọn núi có đỉnh bo tròn và sườn trái
  sáng, ngọn lửa trên đỉnh có lõi nóng, và hai vòng tín hiệu ở ±36°.
- Ở bộ ghép ngang, chân núi nằm trên đường chân chữ của HandLive.
- Không vẽ lại, đồ lại hay đổi khoảng cách trong logo; sửa bộ sinh rồi dựng lại.

### Khoảng trống và kích thước tối thiểu

- Khoảng trống mọi phía: ít nhất bằng bề ngang ngọn lửa (khoảng một phần tư bề ngang biểu tượng).
- Biểu tượng: từ 33 px; biểu tượng rút gọn từ 16 đến 32 px. Bộ ghép ngang: rộng từ 120 px. In ấn: biểu
  tượng 10 mm, bộ ghép 30 mm.

### Phiên bản màu

| Nền | Phiên bản |
|---|---|
| Trắng, `brand-glow`, ảnh sáng | Đủ màu (núi tím than, chữ tím than) |
| Đen, xám đậm, `brand-ember` | Trên nền tối (núi tím nhạt, chữ màu kem) |
| Chỉ một màu mực | Một màu đen hoặc trắng; lõi ngọn lửa được khoét rỗng |

### Không được

- Không đổi màu từng phần, thêm bóng, viền hay hiệu ứng phát sáng, hay đặt logo lên ảnh rối.
- Không xoay, kéo giãn hay sắp xếp lại ngọn lửa, vòng sóng và ngọn núi.
- Không viết "HandLive" bằng font khác, hay dùng chữ HandLive khi tương phản không đủ.
- Không ghép logo với logo, tên sản phẩm hay phần cứng của Apple hoặc Google.

## 6. Biểu tượng app

| Nền tảng | Phát hành | Ở đâu |
|---|---|---|
| iOS, iPadOS | Một cỡ 1024 px, tràn viền, không kênh alpha; ba diện mạo Mặc định, Tối, Phủ màu | `apple/…/Assets.xcassets/AppIcon.appiconset` |
| macOS | Lưới ô của macOS (hình vuông bo góc 824 px trên nền 1024, bóng mềm); 16–512 pt ở 1× và 2×; cỡ 16 và 32 pt dùng biểu tượng rút gọn | Cùng bộ, các mục `mac` |
| Android | Biểu tượng thích ứng: lớp nền bình minh, lớp trước, lớp đơn sắc cho biểu tượng theo chủ đề (Android 13+) | `android/app/src/main/res/` (`mipmap-anydpi`, `drawable`) |
| App Store, Play Store | 1024 px (App Store, lấy từ biểu tượng iOS), 512 px không alpha (Play) | `docs/brand/assets/app-icon/` |
| Icon Composer (Liquid Glass) | Lớp nền và lớp trước hình vuông, chưa cắt khung | `docs/brand/assets/app-icon/icon-composer/` |

- Không chữ, không SF Symbols, không phần cứng Apple trong biểu tượng; trên iOS không tự thêm vệt sáng
  hay bóng: hệ thống tự thêm.
- Biểu tượng Tối giữ nguyên ngọn lửa trên nền tím đêm; biểu tượng Phủ màu là ảnh xám để hệ thống phủ màu.

## 7. Màu sắc

### Màu chính

| Token | Sáng | Tối | Sáng · TP | Tối · TP | Vai trò |
|---|---|---|---|---|---|
| `brand-fire` | #e63d1a | #ff7448 | #b82c10 | #ff8f6b | Nhận diện: gốc ngọn lửa, tiêu đề thương hiệu cỡ lớn, biểu tượng app |
| `brand-flame` | #ff861f | #ffa04a | #f07410 | #ffb066 | Thân ngọn lửa, vòng sóng trong, điểm sáng trong minh họa; không làm màu chữ |

### Màu phụ

| Token | Sáng | Tối | Sáng · TP | Tối · TP | Vai trò |
|---|---|---|---|---|---|
| `brand-ember` | #33232d | #6e5463 | #2a1c25 | #83677a | Tím than: ngọn núi, mực của logo, khối sâu ở bìa; thay cho đen |
| `brand-glow` | #fff0e3 | #2b1e26 | #ffe6d2 | #33242e | Kem bình minh: nền của khoảnh khắc thương hiệu (màn chào, ghép nối) |
| `accent` | #197934 | #3ddc6c | #146b2e | #5be584 | Hành động: một nút chính mỗi màn, liên kết, chưa đọc, bong bóng tin đã gửi |

TP: Tăng tương phản. Giá trị token nằm ở `shared/design-tokens/tokens.json` (bản sao:
`docs/design-system/tokens.json`); các app sinh màu từ file này.

### Màu trung tính

Màu xám và nền hệ thống của Apple, gọi qua API hệ thống trên nền tảng Apple và qua token trên Android.
HandLive không tự thêm mảng đen hay xám: mảng sâu của thương hiệu dùng `brand-ember`.

### Màu riêng của logo

Chỉ dùng trong logo, biểu tượng app và ảnh quảng bá (không phải token):

| Tên | Mã hex | Ở đâu |
|---|---|---|
| Đỉnh lửa | #ffb83d | Đầu gradient ngọn lửa (`brand-fire` → `brand-flame` → đỉnh) |
| Lõi lửa | #fff6e0 | Lõi nóng bên trong ngọn lửa |
| Vòng sóng ngoài | #ffc68c | Vòng ngoài, nhạt dần |
| Sườn núi sáng | #4b3542 | Sườn trái của ngọn núi |
| Trời bình minh | #fff6ee → #ffe3cf | Nền biểu tượng và ảnh quảng bá, từ trên xuống |
| Trời đêm | #2b1e26 → #1c1319 | Nền biểu tượng Tối |
| Núi trên nền tối | #6e5463, sườn sáng #83677a | Biểu tượng trên nền tối |

### Màu ngữ nghĩa

Trạng thái giữ màu hệ thống (`system-red` cho lỗi và thao tác hủy, xóa; `system-orange`,
`system-green`). `brand-fire` không bao giờ là màu nút, trạng thái hay lỗi, để khỏi lẫn với xóa hay hủy.

### Quy tắc và tương phản

- Màu thương hiệu ở lớp nội dung: màn chào, màn ghép nối, trạng thái trống, biểu tượng, logo. Control giữ
  diện mạo hệ thống và `accent` xanh lá.
- Mỗi màn tối đa một khoảnh khắc thương hiệu.
- Màu xanh dương để dành cho hệ thống: liên kết và vùng chọn của HandLive dùng `accent`, thương hiệu không
  thêm mảng xanh dương, nên không bị nhìn như một tiện ích hệ thống.
- `brand-fire` làm màu chữ chỉ cho tiêu đề lớn: 4,16:1 trên nền trắng và 3,73:1 trên `brand-glow` ở diện
  mạo Sáng (tối thiểu 3:1 cho chữ lớn), 5,2–7,8:1 ở diện mạo Tối trên bảy nền hệ thống.
- `brand-ember` làm màu chữ đạt từ 12,5:1 trên nền sáng; chữ nội dung vẫn dùng `label`.

## 8. Kiểu chữ

```css
--font-heading: 'Be Vietnam Pro', Inter, -apple-system, system-ui, sans-serif;
--font-body: -apple-system, system-ui, Inter, sans-serif;
--font-mono: 'SF Mono', ui-monospace, 'JetBrains Mono', monospace;
```

- Be Vietnam Pro Bold: chữ HandLive, `brand-large-title`, `brand-title` và tiêu đề ảnh quảng bá. Thiết kế
  cho tiếng Việt nên dấu vẫn rõ ở cỡ lớn. Đóng gói theo giấy phép SIL OFL 1.1.
- Mọi chữ khác dùng font hệ thống: San Francisco trên nền tảng Apple, Inter trên Android; website dùng bộ font
  hệ thống của máy người đọc.
- San Francisco và SF Symbols không bao giờ có mặt trong logo, biểu tượng app hay ảnh quảng bá (giấy
  phép của Apple chỉ cho dùng trong giao diện chạy trên nền tảng Apple).

## 9. Hình ảnh và minh họa

- Hình khối phẳng lấy từ biểu tượng: núi bo tròn, ngọn lửa, vòng sóng. Nền gradient bình minh; tím than
  tạo chiều sâu.
- Ảnh chụp màn hình thật của app, không dựng mock-up bằng bộ UI kit của Apple; không vẽ phần cứng Apple.
- Không dùng ảnh stock người cầm điện thoại; không dùng hình ổ khóa phát sáng kiểu "cyber" cho mã hóa.
- Prompt nền khi tạo hình bằng mô hình AI: "Flat geometric illustration, dawn palette: cream sky #fff6ee
  to #ffe3cf, plum mountains #33232d and #4b3542, a single flame in #e63d1a, #ff861f and #ffb83d, soft
  orange signal rings; calm, warm, minimal, generous empty space, no text, no devices."

## 10. Ảnh quảng bá

| File (`docs/brand/assets/promo/`) | Cỡ | Dùng cho |
|---|---|---|
| `github-social-preview.png` | 1280 × 640 | Ảnh xem trước khi chia sẻ mọi kho HandLive trên GitHub |
| `readme-hero.en.png`, `readme-hero.vi.png` | 1600 × 600 | Đầu `README.md` và `README.vi.md` |
| `release-banner-beta.en.png`, `release-banner-beta.vi.png` | 1280 × 640 | Ghi chú phát hành và bài đăng cho `v0.1.0-beta.1` |

Bố cục: bộ ghép logo ở góc trên trái; tiêu đề (tagline) Be Vietnam Pro Bold màu tím than; một hai dòng
phụ màu tím nhạt hơn (#6b5562); biểu tượng cỡ lớn tràn ra góc dưới phải.

## 11. Nhãn hiệu Apple và Google

- Tên app là "HandLive". Nội dung trên store dùng "cho Mac", "dùng với iPhone và iPad"; không đưa "Apple"
  vào tên, biểu tượng hay logo.
- Viết đúng nhãn hiệu: iPhone, iPad, Mac, macOS, iOS, iPadOS; Android. Tên tính năng của Apple
  (Continuity, Handoff, AirDrop) mô tả tính năng của Apple, không phải của HandLive.
- Android là nhãn hiệu của Google LLC; chỉ dùng huy hiệu Google Play đúng như Google cung cấp.

## 12. Dựng lại các file

```bash
python3 tools/brand/build_brand_assets.py \
  --android-res android/app/src/main/res \
  --apple-iconset apple/macOS/HandLive/Resources/Assets.xcassets/AppIcon.appiconset
```

- Cần `rsvg-convert` và ImageMagick (`brew install librsvg imagemagick`).
- Đường nét chữ được lưu sẵn ở `tools/brand/text-outlines.json`. Sau khi đổi một chuỗi chữ, chạy lại với
  `--font BeVietnamPro-Bold.ttf` (cần fontTools); bản thân file font không được commit.
- File của từng nền tảng được ghi thẳng vào kho app; commit ở kho đó, mỗi commit một kho.

## Lịch sử thay đổi

| Phiên bản | Ngày | Thay đổi |
|---|---|---|
| 1.0 | 2026-10-01 | Bản hướng dẫn đầu tiên: ngọn lửa hiệu lúc bình minh (logo, biểu tượng app, giọng văn, thông điệp, quảng bá); giá trị bình minh cho các token `brand-*` |
