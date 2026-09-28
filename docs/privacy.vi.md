[English](privacy.md) | Tiếng Việt

# HandLive và quyền riêng tư

HandLive là dự án mã nguồn mở. Dự án đưa các tính năng native riêng trong từng hệ sinh thái, như Handoff trên Apple, lên Android. Máy Android đồng bộ với Mac, iPhone và iPad. Máy Apple đồng bộ ngược lại.

Trang này giải thích HandLive xử lý dữ liệu gì, dữ liệu đi đâu, và người dùng kiểm soát những gì. Trang áp dụng cho mọi ứng dụng HandLive và máy chủ relay. Ứng dụng liên kết tới đây từ màn hình chào (thiết kế chi tiết SET-01 trường 1).

## Tóm tắt

- Không cần tài khoản. HandLive không hỏi tên, email hay số điện thoại.
- Clipboard, tin nhắn, cuộc gọi, camera và, khi bật Duyệt web tiếp, địa chỉ trang web đang mở chỉ đi giữa các thiết bị đã ghép. Dữ liệu rời thiết bị đều mang mã hóa đầu-cuối. Chỉ các thiết bị đã ghép giữ khóa.
- Khi các thiết bị không cùng mạng Wi-Fi, máy chủ relay chuyển dữ liệu đã mã hóa. Máy chủ không đọc nội dung và không giữ nội dung.
- Không quảng cáo, không phân tích hành vi, không theo dõi. Không SDK bên thứ ba thu thập dữ liệu.

## Dữ liệu ở lại trên thiết bị

- Khóa định danh và khóa ghép nối nằm trong Android Keystore và Apple Keychain. Khóa không rời thiết bị.
- Tin nhắn, nhật ký cuộc gọi và cài đặt đã đồng bộ nằm trong cơ sở dữ liệu cục bộ. Mac, iPhone và iPad mã hóa cơ sở dữ liệu bằng SQLCipher.
- Nội dung clipboard gửi khi người dùng sao chép hoặc chạm Gửi. Mặc định, nội dung tự xóa sau 60 giây. Nội dung có vẻ là mật khẩu hoặc số thẻ thì hệ thống không gửi, trừ khi người dùng chọn Vẫn gửi.

## Relay thấy gì

- Một mã thiết bị ngẫu nhiên, suy ra từ khóa công khai. Relay thấy thiết bị nào đã ghép với thiết bị nào, và mã push mà iPhone, iPad hoặc điện thoại Android đăng ký để nhận thông báo.
- Relay thấy thời điểm, kích thước mỗi tin đã mã hóa, và địa chỉ IP mỗi kết nối. Relay dùng các dữ liệu này để giới hạn tần suất, rồi giữ tối đa một giờ.
- Relay không thấy nội dung. Thiết bị mã hóa đầu-cuối trước khi dữ liệu rời máy.
- Thống kê sử dụng dùng mã băm có muối theo tháng của mã thiết bị. Hệ thống xóa thống kê sau 30 ngày. Tin đã mã hóa mà chưa giao, hệ thống xóa sau tối đa 30 ngày.
- Tắt Kết nối qua Internet trong Cài đặt thì HandLive chỉ chạy trong mạng Wi-Fi. Xóa thiết bị khỏi máy chủ thì hệ thống xóa đăng ký đó.

## Quyền

HandLive chỉ xin một quyền khi người dùng bật tính năng cần quyền đó, sau một màn hình giải thích lý do. Các quyền gồm: thông báo, mạng cục bộ, camera (quét mã QR ghép nối), SMS và danh bạ (tin nhắn), trạng thái điện thoại và nhật ký cuộc gọi, micro và Bluetooth (nghe gọi trên Mac), Hỗ trợ tiếp cận (tự gửi nội dung vừa sao chép trên Android, và đọc địa chỉ trang đang mở trong các trình duyệt được hỗ trợ cho Duyệt web tiếp), Tự động hóa trên Mac (đọc địa chỉ trang đang mở trong từng trình duyệt người dùng cho phép). Tắt tính năng thì tính năng đó ngừng dùng quyền.

## Trang web (Duyệt web tiếp, dự kiến)

Duyệt web tiếp mặc định tắt. Khi bật, HandLive gửi địa chỉ và tiêu đề của trang web đang mở trong trình duyệt ở foreground tới các thiết bị đã ghép, để người dùng xem tiếp ở đó: từ điện thoại Android sang Mac, iPhone và iPad, và từ Mac sang điện thoại.

- Địa chỉ đi dưới mã hóa đầu-cuối như mọi dữ liệu khác, kể cả qua relay, relay không đọc được. Địa chỉ không bao giờ đi trong thông báo đẩy.
- Địa chỉ không bao giờ được lưu: thiết bị nhận chỉ giữ trang mới nhất trong bộ nhớ và quên sau 10 phút, khi người dùng rời trang, hoặc khi các thiết bị ngắt kết nối. HandLive không bao giờ giữ lịch sử duyệt web.
- Trang trong tab hoặc cửa sổ ẩn danh, riêng tư không bao giờ được gửi. Người dùng có thể loại bất kỳ trình duyệt nào trong Cài đặt.
- Thiết bị nhận không bao giờ tự mở trang: người dùng luôn bấm hoặc chạm trước.

## Cuộc gọi

Khi người dùng nghe cuộc gọi trên Mac, âm thanh chỉ đi giữa điện thoại và Mac đã ghép. Qua Bluetooth, liên kết Bluetooth mã hóa âm thanh. Qua Wi-Fi, mã hóa đầu-cuối bảo vệ âm thanh. HandLive không ghi âm cuộc gọi. Ở nơi luật yêu cầu mọi bên đồng ý, hãy báo cho người kia biết máy tính đang nghe cuộc gọi.

## Xóa dữ liệu

- Hủy ghép nối một thiết bị thì hệ thống xóa khóa cặp và dữ liệu đã đồng bộ trên cả hai thiết bị.
- Xóa toàn bộ dữ liệu HandLive trong Cài đặt thì hệ thống xóa mọi khóa, cơ sở dữ liệu và cài đặt trên thiết bị đó, rồi gỡ đăng ký thiết bị khỏi máy chủ relay.
- Gỡ ứng dụng thì hệ thống xóa dữ liệu cục bộ ứng dụng.

## Mã nguồn mở và liên hệ

HandLive dùng Apache License 2.0. Ai cũng kiểm được ứng dụng và máy chủ relay làm gì: https://github.com/HandLive. Câu hỏi về quyền riêng tư: me@hxd.vn. Lỗ hổng bảo mật: xem [chính sách bảo mật](https://github.com/HandLive/.github/blob/main/SECURITY.vi.md).

Cập nhật lần cuối: 2026-09-28.
