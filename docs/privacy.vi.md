[English](privacy.md) | Tiếng Việt

# HandLive và quyền riêng tư

HandLive là một dự án mã nguồn mở mang các tính năng liền mạch vốn chỉ có trong từng hệ sinh thái riêng biệt (như Apple Handoff) lên nền tảng Android. Thiết bị Android và các thiết bị Apple (Mac, iPhone, iPad) có thể đồng bộ hai chiều với nhau.

Trang này giải thích cách HandLive xử lý dữ liệu, nơi dữ liệu được truyền đến và quyền kiểm soát của bạn. Chính sách này áp dụng cho toàn bộ các ứng dụng HandLive cùng hệ thống máy chủ chuyển tiếp (relay). Bạn có thể truy cập trang này trực tiếp từ màn hình chào mừng của ứng dụng.

## Tóm tắt

- Không yêu cầu tài khoản: HandLive không bao giờ thu thập họ tên, địa chỉ email hay số điện thoại của bạn.
- Bảng nhớ tạm (clipboard), tin nhắn, cuộc gọi, camera và địa chỉ trang web đang mở (khi bật tính năng Tiếp tục duyệt web) chỉ được truyền nội bộ giữa các thiết bị bạn đã ghép nối. Mọi dữ liệu khi rời khỏi thiết bị đều được mã hóa đầu cuối với khóa giải mã chỉ do chính các thiết bị của bạn nắm giữ.
- Khi các thiết bị không ở cùng mạng Wi-Fi, máy chủ chuyển tiếp (relay) sẽ hỗ trợ truyền dữ liệu đã mã hóa. Máy chủ hoàn toàn không thể đọc và không lưu trữ nội dung này.
- Không quảng cáo, không theo dõi, không phân tích hành vi người dùng và không sử dụng bất kỳ SDK bên thứ ba nào để thu thập dữ liệu.

## Dữ liệu được lưu trữ trên thiết bị

- Khóa định danh và khóa ghép nối được lưu trữ an toàn trong Android Keystore và Apple Keychain, tuyệt đối không bao giờ rời khỏi thiết bị.
- Tin nhắn, nhật ký cuộc gọi và các cài đặt đồng bộ được lưu trong cơ sở dữ liệu cục bộ (được mã hóa bằng SQLCipher trên Mac, iPhone và iPad).
- Nội dung bảng nhớ tạm chỉ được gửi khi bạn thực hiện sao chép hoặc chạm nút "Gửi", và mặc định sẽ tự động xóa sau 60 giây. Nếu dữ liệu có định dạng giống mật khẩu hoặc số thẻ ngân hàng, hệ thống sẽ tự động chặn gửi, trừ khi bạn chủ động chọn "Vẫn gửi".

## Máy chủ chuyển tiếp (Relay) xử lý những dữ liệu gì

- Mã định danh thiết bị ngẫu nhiên được tạo từ khóa công khai (public key), danh sách các thiết bị đã ghép nối với nhau và mã push token mà thiết bị đăng ký để nhận thông báo đẩy.
- Thời điểm, dung lượng của từng gói tin mã hóa và địa chỉ IP kết nối: các thông tin này chỉ được sử dụng để giới hạn tần suất yêu cầu (rate limiting) và được lưu giữ tối đa trong 1 giờ.
- Tuyệt đối không xem được nội dung: mọi tin nhắn và dữ liệu đều được mã hóa đầu cuối trước khi rời khỏi thiết bị của bạn.
- Thống kê sử dụng được ẩn danh bằng mã băm bảo mật (salted hash) thay đổi theo tháng của mã thiết bị và sẽ tự động xóa sau 30 ngày. Các gói tin mã hóa chưa được gửi đến thiết bị nhận cũng sẽ bị xóa vĩnh viễn sau tối đa 30 ngày.
- Bạn có thể tắt mục "Kết nối qua Internet" trong phần Cài đặt để giới hạn HandLive chỉ hoạt động trong mạng Wi-Fi nội bộ. Tùy chọn "Xóa thiết bị khỏi máy chủ" sẽ gỡ bỏ hoàn toàn đăng ký của bạn trên relay.

## Quyền hạn ứng dụng

HandLive chỉ yêu cầu cấp quyền khi bạn chủ động kích hoạt tính năng cần đến quyền đó, và luôn có màn hình giải thích rõ lý do trước khi yêu cầu. Các quyền bao gồm:

- **Thông báo & Mạng cục bộ:** duy trì kết nối và nhận tín hiệu giữa các thiết bị.
- **Camera:** quét mã QR khi ghép nối thiết bị.
- **SMS và Danh bạ:** phục vụ tính năng đọc và gửi tin nhắn.
- **Trạng thái điện thoại và Nhật ký cuộc gọi:** hiển thị thông báo và lịch sử cuộc gọi.
- **Microphone và Bluetooth:** đàm thoại cuộc gọi trên Mac.
- **Quyền Trợ năng (Accessibility) trên Android:** tự động phát hiện nội dung sao chép mới và đọc URL trang web đang mở (phục vụ tính năng Tiếp tục duyệt web).
- **Quyền Tự động hóa (Automation) trên Mac:** đọc địa chỉ trang web đang mở trên các trình duyệt được bạn cho phép.

Khi bạn tắt một tính năng, ứng dụng sẽ ngay lập tức ngừng sử dụng quyền hạn tương ứng.

## Trang web (Tiếp tục duyệt web - Handoff, dự kiến)

Tính năng "Tiếp tục duyệt web" (Handoff) được tắt theo mặc định. Khi được kích hoạt, HandLive sẽ gửi tiêu đề và địa chỉ (URL) của trang web đang mở ở màn hình chính sang các thiết bị đã ghép nối để bạn tiếp tục đọc dở: từ Android sang Mac, iPhone, iPad và ngược lại từ Mac về điện thoại.

- Địa chỉ trang web được mã hóa đầu cuối như mọi dữ liệu khác; máy chủ chuyển tiếp hoàn toàn không thể đọc được thông tin này. Địa chỉ web không bao giờ được gửi kèm trong nội dung thông báo đẩy.
- Địa chỉ trang web không bao giờ được lưu trữ cố định: thiết bị nhận chỉ tạm lưu trang gần nhất trong bộ nhớ đệm (RAM) và sẽ tự động xóa sau 10 phút, khi bạn đóng trang hoặc khi hai thiết bị ngắt kết nối. HandLive tuyệt đối không lưu lại lịch sử duyệt web của bạn.
- Các tab hoặc cửa sổ ở chế độ Ẩn danh / Riêng tư (Incognito/Private) sẽ không bao giờ được gửi. Bạn cũng có thể chủ động loại trừ bất kỳ trình duyệt nào trong phần Cài đặt.
- Thiết bị nhận không bao giờ tự ý mở trang web: bạn luôn là người chủ động bấm hoặc chạm để mở.

## Cuộc gọi

Khi bạn nhận cuộc gọi trên Mac, luồng âm thanh chỉ truyền trực tiếp giữa điện thoại và máy Mac đã ghép nối: qua sóng Bluetooth (được bảo vệ bởi mã hóa liên kết Bluetooth) hoặc qua mạng Wi-Fi (được mã hóa đầu cuối). HandLive tuyệt đối không ghi âm cuộc gọi. Tại các khu vực mà pháp luật yêu cầu sự đồng thuận của tất cả các bên tham gia, vui lòng thông báo cho người ở đầu dây bên kia biết rằng bạn đang đàm thoại qua máy tính.

## Xóa dữ liệu

- Khi bạn hủy ghép nối một thiết bị: cặp khóa mã hóa và toàn bộ dữ liệu đã đồng bộ sẽ được xóa sạch trên cả hai thiết bị.
- Tùy chọn "Xóa toàn bộ dữ liệu HandLive" trong Cài đặt: xóa toàn bộ các khóa bảo mật, cơ sở dữ liệu và cấu hình trên thiết bị đó, đồng thời hủy bỏ đăng ký của thiết bị trên máy chủ chuyển tiếp.
- Khi bạn gỡ cài đặt ứng dụng: mọi dữ liệu lưu trữ cục bộ của ứng dụng trên thiết bị sẽ tự động được xóa bỏ hoàn toàn.

## Mã nguồn mở và liên hệ

HandLive được phát hành dưới giấy phép mã nguồn mở Apache License 2.0; bất kỳ ai cũng có thể tự do kiểm tra mã nguồn để biết chính xác cách ứng dụng và máy chủ chuyển tiếp hoạt động: https://github.com/HandLive. Mọi thắc mắc về quyền riêng tư, vui lòng gửi về: me@hxd.vn. Báo cáo lỗ hổng bảo mật: vui lòng xem [chính sách bảo mật](https://github.com/HandLive/.github/blob/main/SECURITY.vi.md).

Cập nhật lần cuối: 2026-09-28.
