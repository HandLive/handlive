# MessageBubble

Bong bóng một tin SMS trong hội thoại và ô soạn tin ở cuối (SMS-03, SMS-04). Theo quy ước Tin nhắn của Apple: tin SMS mình gửi màu xanh lá — ở HandLive là `bubble-outgoing` (đậm hơn xanh SMS của Apple để chữ trắng đạt 4.5:1), tin đến màu `bubble-incoming`.

## Bong bóng

| Phần | Quy cách |
|------|---------|
| Tin đến | Trái, nền `bubble-incoming`, chữ `label`, bo 18 pt |
| Tin gửi | Phải, nền `bubble-outgoing`, chữ `on-bubble-outgoing` |
| Liên kết, số điện thoại | Nhận diện tự động, gạch chân, cùng màu chữ; số không ngắt dòng |
| Mốc ngày | "Hôm nay", "Hôm qua", "12/09" ở giữa, khi sang ngày khác |
| Giờ và trạng thái | Dưới tin cuối của một cụm, `ios-caption-1` / `mac-caption-2` |

Trạng thái tin gửi chỉ đi tiến, mỗi trạng thái có biểu tượng riêng:

| Trạng thái | Chữ | SF Symbol ↔ Material |
|-----------|-----|----------------------|
| `pending` | "Đang chờ điện thoại" | `clock` ↔ `schedule` |
| `sending` | "Đang gửi…" | `ProgressView` nhỏ |
| `sent` | "Đã gửi" | `checkmark` ↔ `check` |
| `delivered` | "Đã nhận" | `checkmark.circle` ↔ `done_all` |
| `failed` | "Gửi lỗi · <lý do>" + nút "Thử lại"; biểu tượng `exclamationmark.circle.fill` đỏ cạnh bong bóng | ↔ `error` |

Lý do theo mã lỗi: `SMS_NO_SERVICE` "Không có sóng" · `SMS_RADIO_OFF` "Điện thoại đang ở chế độ máy bay" · `SMS_LIMIT_EXCEEDED` "Đã gửi quá nhiều tin, thử lại sau" · `SMS_INVALID_ADDRESS` "Số nhận không hợp lệ" · `SMS_SIM_UNAVAILABLE` "SIM này không hoạt động, hãy chọn SIM khác" · `NOT_CONNECTED` "Không kết nối được điện thoại trong 24 giờ" · khác "Không gửi được".

## Ô soạn tin

Ô nhập capsule "Tin nhắn SMS" trên nền kính, nút gửi tròn `accent-fill` (`arrow.up`). Máy hai SIM: chip "SIM 1" mở menu chọn SIM. Tin dài hơn một phần: hiện "2 tin SMS" (mỗi phần tính cước). Tối đa 1 600 ký tự. Mac: Return gửi, ⇧Return xuống dòng. Hội thoại nhiều người nhận: không có ô soạn, thay bằng dòng "Trả lời hội thoại nhóm trên điện thoại". Điện thoại không cho gửi SMS: ẩn ô soạn.

## Nên và không nên

- Nên hiện bong bóng tạm ngay khi bấm gửi (≤ 100 ms) với "Đang chờ điện thoại".
- Không tự gửi lại tin lỗi; người dùng quyết định bằng "Thử lại".
- Không đổi màu bong bóng theo màu nhấn của hệ thống.
