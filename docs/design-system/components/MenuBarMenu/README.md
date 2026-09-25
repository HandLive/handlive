# MenuBarMenu

Biểu tượng HandLive trên thanh menu Mac và **menu** mở ra khi bấm vào — theo HIG, menu bar extra mở menu chứ không mở popover. Nội dung giống các menu Wi-Fi, Bluetooth của macOS: trạng thái ở trên, lệnh ở giữa, Cài đặt và Thoát ở cuối.

## Biểu tượng trên thanh menu

Ảnh template đơn sắc (hệ thống tự tô theo nền thanh menu), cao theo thanh menu 24 pt.

| Trạng thái | SF Symbol |
|-----------|-----------|
| Đã kết nối | `antenna.radiowaves.left.and.right` |
| Đang kết nối | như trên, hiệu ứng variable color (tắt khi Giảm chuyển động) |
| Ngoại tuyến, mất kết nối | `antenna.radiowaves.left.and.right.slash` |
| Có cuộc gọi đến | `phone.fill` |
| Vừa gửi bảng nhớ tạm | `checkmark` ~1 giây (Magic Replace) — xem `Feedback` |
| Có tin chưa đọc | Số hội thoại chưa đọc ngay sau biểu tượng ("2", trên 99 là "99+") |

## Nội dung menu

1. **Điện thoại:** tên máy làm tiêu đề nhóm; dòng trạng thái không bấm được có biểu tượng màu trạng thái; khi mất kết nối thêm "Kết nối lại ngay".
2. **Cuộc gọi đang đổ chuông** (nếu có, kể cả khi đã "Bỏ qua" panel): "Trả lời", "Từ chối".
3. **Lệnh:** "Gửi bảng nhớ tạm sang điện thoại", "Tin nhắn" (số chưa đọc ở bên phải), "Xem trước camera".
4. **Camera** (khi đang phát): trạng thái, dấu kiểm "Micro điện thoại" và "Tạm dừng hình", menu con "Chất lượng" (Tự động, 480p, 720p, 1080p), "Đổi camera", "Dừng camera".
5. **Gần đây:** tối đa ba mục (cuộc gọi nhỡ, tin mới); chọn mục mở đúng chỗ.
6. "Cài đặt…" ⌘, · "Thoát HandLive" ⌘Q.

Menu con sâu một cấp. Trong một nhóm, hoặc mọi mục có biểu tượng, hoặc không mục nào có. Mục chưa dùng được thì mờ đi, không ẩn.

## Hiện hay ẩn

Người dùng quyết định: cài đặt "Hiện HandLive trên thanh menu" (Chung), hỏi lúc thiết lập, mặc định bật. Khi ẩn — hoặc khi hệ thống giấu bớt biểu tượng vì chật — app có biểu tượng Dock, Dock menu và thanh menu riêng để vẫn vào được mọi chức năng.

## API

`MenuBarExtra(_:systemImage:isInserted:content:)` (macOS 13) với `.menuBarExtraStyle(.menu)`; `Section`, `Toggle` (hiện thành dấu kiểm), `Picker` (menu con), `Divider`, `.keyboardShortcut`. Cần dòng hai tầng hoặc biểu tượng màu → `NSStatusItem` + `NSMenu`.

## Nên và không nên

- Nên để mọi lệnh trong menu cũng có ở cửa sổ app hoặc thanh menu của app.
- Không nhét panel cuộc gọi, xem trước camera hay ô soạn tin vào menu.
