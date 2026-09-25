# GroupedList

Danh sách nhóm kiểu Cài đặt của iPhone — các nhóm bo góc trên nền `system-grouped-background`, có tiêu đề và chú thích — dùng cho Cài đặt, Thiết bị và các màn quyền trên iOS/iPadOS và Android. Trên Mac, cùng cấu trúc là `Form` kiểu `.grouped` (xem `Toggle`).

## Cấu tạo

| Phần | Quy cách | Token |
|------|---------|-------|
| Tiêu đề nhóm | Sentence case (không còn viết hoa toàn bộ từ Liquid Glass), 13 pt Semibold | `secondary-label` |
| Nhóm | Nền ô, góc bo đồng tâm (`radius-sheet` từ iOS 26, `radius-row` trên iOS 16–18) | `secondary-system-grouped-background` |
| Dòng | Cao ≥ 44 pt (Android 56 dp); biểu tượng vuông `size-row-icon` (30 pt) bo `radius-row-icon` (8 pt), glyph `on-icon-fill` trên màu; chữ `ios-body` | `label`, `separator` |
| Giá trị | Bên phải, trước mũi tên | `secondary-label` |
| Mũi tên | `chevron.forward` ↔ `chevron_right` khi dòng mở màn con | `tertiary-label` |
| Chú thích nhóm | Câu hoàn chỉnh giải thích hệ quả | `secondary-label` |
| Lý do chưa dùng được | Dưới tiêu đề dòng, có biểu tượng thông tin | `text-orange` |

Loại dòng: điều hướng (tiêu đề + giá trị + mũi tên), công tắc (`Toggle`), hành động (chữ `accent`, ví dụ "Đồng bộ lại toàn bộ SMS"), phá hủy (chữ `destructive-text`, luôn ở nhóm cuối, luôn hỏi xác nhận bằng `Alert`).

Màu ô biểu tượng theo nhóm chức năng, tránh xanh dương: Thiết bị `system-gray`, Bảng nhớ tạm `system-orange`, Tin nhắn `system-green`, Cuộc gọi `call-accept-fill`, Thông báo `system-red`, Kết nối qua Internet `system-purple`.

## API

SwiftUI `Form` hoặc `List` với `.listStyle(.insetGrouped)`, `Section(header:footer:)`, `LabeledContent`, `NavigationLink`. Android: `HLGroupedList { section(title, footer) { row(...) } }` dựng bằng `LazyColumn`; dòng là một vùng chạm, có `Modifier.semantics { role = Role.Switch }` cho dòng công tắc.

## Nên và không nên

- Nên để nhãn nói điều sẽ xảy ra khi bật; để chú thích nói hệ quả khi tắt nếu không hiển nhiên.
- Không đặt hai hành động phá hủy trong một nhóm; không đặt hành động phá hủy ở đầu danh sách.
- Không lặp lại cài đặt của hệ thống; dẫn tới đó bằng nút "Mở cài đặt".
