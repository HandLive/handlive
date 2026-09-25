# CallPanel

Cửa sổ nổi nhỏ trên Mac cho cuộc gọi đến và cuộc gọi đang diễn ra (CALL-01…03, AUDIO-03). Trông như thông báo cuộc gọi Continuity của Apple: tấm kính ở góc trên bên phải, không lấy focus của app người dùng đang làm việc.

**Lệch có chủ đích so với HIG:** HIG muốn panel ẩn khi app không active; cuộc gọi đến thì phải hiện đúng lúc đó. Panel vì thế là `NSPanel` non-activating nổi trên mọi Space. Mỗi cuộc gọi còn có một thông báo liên lạc (`INStartCallIntent`): mức passive khi panel đang hiện (chỉ vào Trung tâm thông báo, không hiện chồng banner), mức time-sensitive khi Tập trung bật và panel không hiện.

## Trạng thái

| Trạng thái | Nội dung | Điều khiển |
|-----------|---------|-----------|
| Đổ chuông | Avatar, tên hoặc số ("Số ẩn", "Không rõ số"), "Cuộc gọi đến · SIM 1" (nhãn SIM khi có hai SIM) | Từ chối (`call-decline-fill`, trái) · Trả lời (`call-accept-fill`, phải); nút chữ "Từ chối kèm tin nhắn…", "Bỏ qua" |
| Đổ chuông, đã bật nghe gọi trên Mac | Như trên | Trả lời tách thành "Nghe trên điện thoại" và "Nghe trên Mac" |
| Đang gọi | "Đang gọi · 02:15" (`timer`), "Âm thanh: Điện thoại" hoặc "Âm thanh: Mac" | "Nghe trên Mac" / "Chuyển về điện thoại"; Kết thúc (đỏ) |
| Đang gọi, Mac nối Bluetooth với điện thoại | Như trên | Thêm Tắt tiếng, Giữ máy / Tiếp tục, Bàn phím (nút bật tắt, không phải switch) |
| Có cuộc gọi chờ | Dòng dưới: tên hoặc số người chờ | Khi nối Bluetooth: "Từ chối cuộc gọi chờ", "Kết thúc và nghe", "Giữ và nghe"; không nối: "Xử lý trên điện thoại hoặc nối Bluetooth" |

Tắt tiếng, Giữ máy, Bàn phím chỉ có qua Bluetooth HFP. Khi Mac chưa nối, **ẩn** ba nút này và thay bằng dòng "Nối Bluetooth với điện thoại để giữ máy, bấm số, tắt tiếng" (CALL-03 E2). Lỗi hiện ngay trong panel: "Điện thoại không thực hiện được thao tác này", "Mất kết nối với điện thoại".

## Hành vi

- Rộng 340 pt, góc trên phải màn hình đang dùng, cách mép 16 pt; kéo được; vật liệu kính (`.hudWindow`/`.popover` trước macOS 26); góc `radius-panel`.
- Phím: Return = Trả lời, ⌘⌫ = Từ chối, Esc = Bỏ qua (đóng panel, tắt chuông trên Mac, không từ chối).
- Tập trung đang bật → không hiện panel, không đổ chuông; thông báo time-sensitive để hệ thống quyết định theo người gọi; cuộc gọi vẫn có trong `MenuBarMenu`. Chưa đọc được trạng thái Tập trung (thiếu quyền) → hiện panel, không đổ chuông. Lệch so với CALL-01 E4.
- Panel đóng khi cuộc gọi kết thúc; không tự đóng theo giờ.
- Nút tròn chỉ có biểu tượng phải có nhãn trợ năng và tooltip ("Tắt tiếng micro trên Mac").

## Nên và không nên

- Nên giữ Từ chối bên trái, Trả lời bên phải ở mọi trạng thái; khác cả màu, biểu tượng (`phone.down.fill` / `phone.fill`) và vị trí.
- Không tự trả lời; bấm vào vùng trống không làm gì.
- Không đổi màu hai nút theo màu nhấn của hệ thống.
