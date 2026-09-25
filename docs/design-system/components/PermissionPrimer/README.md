# PermissionPrimer

Màn giải thích ngắn ngay trước hộp thoại xin quyền của hệ thống. Theo HIG: **đúng một nút "Tiếp tục"**, không có "Bỏ qua", "Hủy" hay nút đóng — người dùng đồng ý hoặc từ chối trong hộp thoại của hệ thống, ngay sau đó.

Đã đồng bộ với tài liệu chi tiết (25/09/2026): SET-03 trường 14 chỉ còn "Tiếp tục". Bước không phải xin quyền (ví dụ hướng dẫn tự khởi chạy của hãng trên Android) vẫn có "Bỏ qua".

## Khi nào hiện

Chỉ khi hộp thoại của hệ thống chưa đủ ngữ cảnh, và chỉ lúc người dùng sắp dùng tính năng cần quyền. Lúc thiết lập ban đầu chỉ hỏi quyền cần để app chạy.

| Quyền | Nền tảng | Lúc hỏi | Tiêu đề màn |
|-------|---------|---------|------------|
| Mạng cục bộ | macOS, iOS | Thiết lập ban đầu | "Tìm điện thoại trong mạng Wi-Fi" |
| Thông báo | macOS, iOS | Thiết lập ban đầu | "Báo khi có tin nhắn và cuộc gọi" |
| Bluetooth, micro | macOS | Khi bật Nghe gọi trên Mac, sau `ConsentSheet` | "Kết nối Bluetooth với điện thoại" |
| SMS, điện thoại, danh bạ, thông báo | Android | Khi bật tính năng tương ứng (thiết lập ban đầu nếu người dùng chọn bật) | "Đọc và gửi tin nhắn từ máy tính"… |
| Camera, micro | Android | Lần đầu Mac xin dùng camera | "Dùng camera cho cuộc họp trên Mac" |

## Cấu tạo

Biểu tượng lớn trong vòng tròn `accent-tint`, tiêu đề `ios-title-2` đậm (Mac `mac-title-2`), một–hai câu nói lợi ích và dữ liệu đi đâu, câu nói hệ thống sẽ hỏi ở bước sau, nút "Tiếp tục" nổi bật rộng hết lề. Chữ nhỏ cuối: "Bạn có thể đổi lại trong Cài đặt bất cứ lúc nào."

Quyền đã bị từ chối: không hiện màn này nữa; trong Cài đặt, dòng tính năng có lý do màu `text-orange` và nút "Mở cài đặt" dẫn thẳng tới trang của app trong Cài đặt hệ thống.

## Nên và không nên

- Nên viết purpose string chủ động, sentence case, có dấu chấm: "HandLive tìm điện thoại Android của bạn trong mạng Wi-Fi để kết nối trực tiếp, không qua Internet."
- Không dùng nhãn "Cho phép" trên màn giải thích (nhãn đó thuộc hộp thoại hệ thống); không vẽ lại hộp thoại hệ thống; không hứa quà để đổi lấy quyền.
