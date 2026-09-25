# Notification

Thông báo hệ thống của HandLive. Trên Mac, iPhone và iPad là thông báo của Apple (tin nhắn và cuộc gọi dùng kiểu **thông báo liên lạc** có avatar người gửi); trên Android là thông báo của Android với kênh riêng — không dựng lại theo kiểu Apple, vì đó là giao diện của hệ điều hành.

## Danh mục

| Sự kiện | Nền tảng | Kiểu / mức | Tiêu đề · nội dung | Hành động |
|--------|---------|-----------|---------------------|-----------|
| Tin SMS mới (SMS-02) | Mac, iOS | Liên lạc (`INSendMessageIntent`), active | Tên người gửi · nội dung tin; ẩn nội dung thì "Tin nhắn SMS mới" | "Trả lời" (ô nhập), "Đánh dấu đã đọc" |
| Cuộc gọi đến (CALL-01) | iOS | Liên lạc (`INStartCallIntent`), time-sensitive | Tên hoặc số · "Cuộc gọi đến · SIM 1" | "Từ chối" |
| Cuộc gọi đến (CALL-01) | Mac | Liên lạc; passive khi `CallPanel` đang hiện, time-sensitive khi Tập trung bật và không có panel | Như trên | "Trả lời", "Từ chối" |
| Cuộc gọi nhỡ | Mac, iOS | Active | Tên hoặc số · "Cuộc gọi nhỡ · 14:05" | "Nhắn tin" |
| Chặn nội dung nhạy cảm (CLIP-01) | Mac, Android | Passive | "Đã chặn nội dung nhạy cảm" · "HandLive không gửi nội dung có vẻ là mật khẩu hoặc số thẻ." | "Vẫn gửi" (hết hạn sau 2 phút) |
| Xung đột bảng nhớ tạm | Mac, Android | Active | "Chưa ghi lên MacBook của Lan" · "Thiết bị này vừa có nội dung sao chép mới." | "Gửi lại" |
| Mac xin dùng camera (CAM-02) | Android | Kênh `camera_request`, mức cao | "MacBook của Lan muốn dùng camera và micro" | "Bật", "Từ chối" (tự hủy sau 60 giây) |
| Đang phát camera | Android | Kênh `camera_live`, thường trực | "Đang dùng camera cho MacBook của Lan" | "Đổi camera", "Tắt micro", "Dừng" |
| Dịch vụ kết nối | Android | Kênh `hl_service`, thấp | "Đã kết nối với MacBook của Lan" | "Gửi bảng nhớ tạm" |

## Nội dung

- Tiêu đề ngắn, không dấu chấm, không có chữ "HandLive" (hệ thống đã hiện tên app). Nội dung là câu hoàn chỉnh, không tự cắt.
- Tối đa bốn hành động, mỗi hành động là động từ ngắn, có SF Symbol; không có hành động chỉ để mở app.
- Không gửi thông báo khi app đang mở ở phía trước — cập nhật giao diện thay vào đó. Không thông báo lặp cho cùng một việc; lỗi không đi bằng thông báo.
- Huy hiệu biểu tượng app chỉ đếm tin chưa đọc.
- Tôn trọng Tập trung: thông báo liên lạc để hệ thống lọc theo người gửi hoặc người gọi.

## Nên và không nên

- Nên để thông báo tin nhắn hiện nội dung theo tùy chọn "Hiện nội dung trong thông báo".
- Không dùng time-sensitive cho gì ngoài cuộc gọi đang đổ chuông.
- Không vẽ lại thông báo trong app; preview ở đây chỉ minh họa nội dung.
