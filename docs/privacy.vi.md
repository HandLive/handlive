[English](privacy.md) | Tiếng Việt

# HandLive và quyền riêng tư của bạn

HandLive nối điện thoại Android của bạn với Mac, iPhone và iPad. Trang này giải thích HandLive xử lý dữ liệu gì, dữ liệu đi đâu và bạn kiểm soát những gì. Trang áp dụng cho mọi ứng dụng HandLive và máy chủ relay của HandLive. Ứng dụng liên kết tới đây từ màn hình chào (thiết kế chi tiết SET-01 trường 1).

## Tóm tắt

- Không cần tài khoản: HandLive không bao giờ hỏi tên, email hay số điện thoại của bạn.
- Bảng nhớ tạm, tin nhắn, cuộc gọi và camera chỉ đi giữa các thiết bị bạn đã ghép. Mọi thứ rời khỏi thiết bị đều được mã hóa đầu-cuối bằng khóa chỉ các thiết bị của bạn nắm giữ.
- Khi các thiết bị không cùng mạng Wi-Fi, máy chủ relay chuyển dữ liệu đã mã hóa giữa chúng. Máy chủ không đọc được nội dung và không giữ lại.
- Không quảng cáo, không phân tích hành vi, không theo dõi, không SDK bên thứ ba thu thập dữ liệu.

## Những gì ở lại trên thiết bị

- Khóa định danh và khóa ghép nối, trong Android Keystore và Apple Keychain; không bao giờ rời khỏi thiết bị.
- Tin nhắn, nhật ký cuộc gọi và cài đặt đã đồng bộ, trong cơ sở dữ liệu cục bộ (mã hóa bằng SQLCipher trên Mac, iPhone và iPad).
- Nội dung bảng nhớ tạm, gửi khi bạn sao chép hoặc chạm Gửi và mặc định tự xóa sau 60 giây. Nội dung có vẻ là mật khẩu hoặc số thẻ không được gửi, trừ khi bạn chọn Vẫn gửi.

## Máy chủ relay thấy gì

- Một mã thiết bị ngẫu nhiên suy ra từ khóa công khai của thiết bị, thiết bị nào đã ghép với thiết bị nào, và mã push mà iPhone, iPad hoặc điện thoại Android đăng ký để nhận thông báo.
- Thời điểm và kích thước của mỗi tin đã mã hóa, địa chỉ IP của mỗi kết nối — chỉ dùng để giới hạn tần suất và giữ tối đa một giờ.
- Không bao giờ thấy nội dung: mọi tin được mã hóa đầu-cuối trước khi rời khỏi thiết bị.
- Thống kê sử dụng dùng mã băm có muối theo tháng của mã thiết bị và bị xóa sau 30 ngày; tin đã mã hóa chưa giao được bị xóa sau tối đa 30 ngày.
- Tắt Kết nối qua Internet trong Cài đặt để chỉ dùng HandLive trong mạng Wi-Fi; Xóa thiết bị khỏi máy chủ xóa đăng ký của bạn.

## Quyền

HandLive chỉ xin một quyền khi bạn bật tính năng cần nó, sau một màn hình giải thích lý do: thông báo, mạng cục bộ, camera (để quét mã QR ghép nối), SMS và danh bạ (tin nhắn), trạng thái điện thoại và nhật ký cuộc gọi (cuộc gọi), micro và Bluetooth (nghe gọi trên Mac), Hỗ trợ tiếp cận (tự gửi nội dung vừa sao chép trên Android). Tắt tính năng thì tính năng đó ngừng dùng quyền.

## Cuộc gọi

Khi bạn nghe cuộc gọi trên Mac, âm thanh chỉ đi giữa điện thoại và Mac của bạn: qua Bluetooth, được bảo vệ bởi mã hóa liên kết Bluetooth, hoặc qua Wi-Fi, mã hóa đầu-cuối. HandLive không bao giờ ghi âm cuộc gọi. Ở nơi luật yêu cầu mọi bên đồng ý, hãy báo cho người kia biết cuộc gọi đang được nghe trên máy tính.

## Xóa dữ liệu

- Hủy ghép nối một thiết bị xóa khóa của cặp và dữ liệu đã đồng bộ trên cả hai thiết bị.
- Xóa toàn bộ dữ liệu HandLive trong Cài đặt xóa mọi khóa, cơ sở dữ liệu và cài đặt trên thiết bị đó và gỡ đăng ký của thiết bị khỏi máy chủ relay.
- Gỡ ứng dụng xóa dữ liệu cục bộ của ứng dụng.

## Mã nguồn mở và liên hệ

HandLive là mã nguồn mở theo Apache License 2.0, nên ai cũng kiểm được ứng dụng và máy chủ relay làm gì: https://github.com/HandLive. Câu hỏi về quyền riêng tư: me@hxd.vn. Lỗ hổng bảo mật: xem [chính sách bảo mật](https://github.com/HandLive/.github/blob/main/SECURITY.vi.md).

Cập nhật lần cuối: 2026-09-26.
