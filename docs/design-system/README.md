HandLive nối điện thoại Android với Mac, iPhone và iPad: bảng nhớ tạm, tin nhắn, cuộc gọi và camera đi qua một liên kết mã hóa đầu-cuối. Design system này dựng theo **Human Interface Guidelines (HIG) của Apple** cho cả ba nền tảng. Trên Mac, iPhone và iPad, HandLive dùng control, font San Francisco, SF Symbols và vật liệu Liquid Glass của hệ thống. Trên Android, app dựng lại cùng ngôn ngữ đó bằng Jetpack Compose — như cách Apple làm Apple Music cho Android — và để nguyên những phần do Android quản lý: thông báo, hộp thoại xin quyền, ô Cài đặt nhanh, cử chỉ quay lại.

Tài liệu bám HIG bản 24/9/2026 (Liquid Glass, macOS 27, iOS và iPadOS 27). App hỗ trợ từ macOS 13 và iOS 16: control hệ thống tự hiển thị đúng từng phiên bản; thành phần tự dựng có cách hiển thị riêng cho bản trước 26 (xem mục Vật liệu).

## Cách đọc

Các mục xếp theo cấu trúc của HIG:

1. **Nền tảng thiết kế** — màu sắc, Chế độ Tối, kiểu chữ, bố cục, vật liệu, biểu tượng, chuyển động, khả năng tiếp cận, viết nội dung, quyền riêng tư, thương hiệu.
2. **Mẫu tương tác** — thiết lập ban đầu, xin quyền, thông báo, cài đặt, phản hồi và tải.
3. **Từng nền tảng** — macOS, iOS và iPadOS, Android.
4. **Thành phần** — mỗi thành phần có preview cho từng nền tảng, tên API cần dùng và chỗ lấy câu chữ trong tài liệu thiết kế chi tiết.

Mỗi mục ghi trang HIG gốc để đối chiếu. Chỗ nào HandLive làm khác HIG thì mục đó nói rõ lý do.

## Tám nguyên tắc

Theo trang Design principles của HIG, áp vào HandLive:

| Nguyên tắc | Với HandLive |
|-----------|--------------|
| Mục đích | Mỗi màn hình phục vụ một việc: xem liên kết, gửi bảng nhớ tạm, đọc tin, nghe máy. |
| Quyền chủ động | Người dùng quyết định hiện hay ẩn biểu tượng trên thanh menu, bật từng tính năng, bỏ qua phần giới thiệu. |
| Trách nhiệm | Nói rõ dữ liệu đi đâu trước khi xin quyền; mã hóa đầu-cuối không tắt được. |
| Quen thuộc | Dùng control và thuật ngữ của hệ thống; cuộc gọi đến trên Mac trông như cuộc gọi Continuity. |
| Linh hoạt | Chạy đúng ở bốn giao diện Sáng, Tối và hai bản tương phản cao, cỡ chữ lớn, VoiceOver, TalkBack, bàn phím. |
| Giản dị | Ít chữ, một nút chính mỗi màn; tùy chọn nâng cao nằm sau một nút mở rộng. |
| Tỉ mỉ | Góc bo đồng tâm, chữ tiếng Việt không bị cắt dấu, số đếm giờ không nhảy. |
| Niềm vui | Dành cho khoảnh khắc đúng chỗ: ghép nối xong, lần đầu chép từ điện thoại sang Mac. |

## Thương hiệu: lửa hiệu trên đỉnh núi

Bảng màu chọn theo phong thủy mệnh **Sơn Đầu Hỏa** — lửa trên đỉnh núi. Người xưa đốt lửa trên đỉnh núi để truyền tin từ trạm này sang trạm khác; HandLive làm việc tương tự giữa điện thoại và máy tính.

| Vai trò | Màu | Ngũ hành |
|---------|-----|----------|
| Nhận diện | Đỏ son `brand-fire`, đỏ than `brand-ember`, cam lửa `brand-flame` | Hỏa — màu bản mệnh |
| Thao tác (AccentColor) | Xanh lá `accent`, `accent-fill` | Mộc sinh Hỏa — màu tương sinh |
| Nền thương hiệu | Hồng đào `brand-glow` | Hỏa |
| Trung tính | Xám hệ thống của Apple | Kim — Hỏa khắc Kim, dùng được |
| Không dùng | Đen, xanh dương, xanh nước biển: systemBlue, Cyan, Teal, Mint, Indigo | Thủy khắc Hỏa |

- Đỏ son chỉ có ở biểu tượng app, chữ HandLive, màn chào và minh họa; không ở nút hay trạng thái, để không lẫn với màu hủy và xóa của hệ thống.
- Xanh lá là AccentColor: nút chính, liên kết, dấu chưa đọc, bong bóng tin mình gửi. Theo HIG, tô màu control tiết chế — mỗi màn một, tối đa hai nút tô màu.
- Liên kết và vùng chọn dùng xanh lá thay cho xanh dương mặc định của Apple. Trên Mac, khi người dùng chọn màu nhấn khác Multicolor, control theo màu người dùng chọn.
- Nền tối của hệ thống (đen trên iPhone, xám trên Mac) thuộc về Apple; HandLive không thêm mảng đen hay xanh dương nào của riêng mình.
- Chưa có logo. Cho tới khi có, dùng chữ HandLive kiểu `wordmark`. Không dùng SF Symbol hay font San Francisco trong logo và biểu tượng app — giấy phép của Apple không cho phép.

## Tóm tắt nhanh

| Việc | Cách làm |
|------|----------|
| Chữ | San Francisco qua text style của hệ thống (Dynamic Type trên iOS). Android dùng Inter cùng thang cỡ. Be Vietnam Pro chỉ cho tiêu đề thương hiệu. |
| Màu | Màu ngữ nghĩa của Apple (`label`, `systemBackground`…) gọi qua API. Token trong trang này là giá trị tham chiếu cho Android và preview. |
| Biểu tượng | SF Symbols trên Apple; Material Symbols Rounded trên Android (bảng đối chiếu ở mục Biểu tượng). |
| Vật liệu | Liquid Glass cho lớp điều khiển: menu, panel cuộc gọi, thanh tab, nút nổi. Không cho lớp nội dung. |
| Vùng chạm | iOS ≥ 44 pt, macOS ≥ 28 pt (tối thiểu 20 pt), Android ≥ 48 dp. |
| Tương phản | Chữ đến 17 pt đạt 4.5:1, chữ lớn hoặc đậm đạt 3:1. Mọi cặp token đã được kiểm ở bốn giao diện. |

## Tài nguyên của Apple

- Human Interface Guidelines: developer.apple.com/design/human-interface-guidelines
- Apple Design Resources: UI Kit macOS 27 và iOS/iPadOS 27 (Figma, Sketch), template biểu tượng app, Icon Composer.
- Ứng dụng SF Symbols; font SF Pro và SF Mono.

Giấy phép: UI Kit, font San Francisco và SF Symbols chỉ dùng cho giao diện chạy trên nền tảng Apple. Không dùng chúng để dựng mock-up hay app Android, và không dùng trong logo.
