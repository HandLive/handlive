# SegmentedControl

Nhóm hai đến năm lựa chọn loại trừ nhau, liên quan chặt với cùng một nội dung. HandLive dùng cho camera Trước/Sau, bộ lọc hội thoại và tab của menu popover (nếu có).

## Dùng khi nào

| Tình huống | Dùng | Không dùng |
|-----------|------|------------|
| Camera "Trước" / "Sau" trong Xem trước camera | `SegmentedControl` | — |
| Lọc "Tất cả" / "Chưa đọc" trong danh sách hội thoại (iOS) | `SegmentedControl` dưới large title | Tab bar |
| Chất lượng "Tự động / 480p / 720p / 1080p" | Pop-up (`Picker` kiểu `.menu`) vì có mặc định và nhiều mức | Segmented |
| Chuyển giữa khu vực chính của app | Tab bar (iOS/Android), toolbar pane (Cài đặt Mac) | Segmented |

- Tối đa ~5 đoạn trên iPhone và Android, ~5–7 trên Mac. Các đoạn rộng bằng nhau; nhãn là danh từ, sentence case; chữ **hoặc** biểu tượng, không trộn.
- Đoạn đang chọn: nền `tertiary-system-background` nổi trên rãnh `tertiary-system-fill`, chữ đậm hơn — không chỉ đổi màu.
- API: `Picker(...).pickerStyle(.segmented)` (SwiftUI), `NSSegmentedControl`, Android `HLSegmented` (mỗi đoạn cao ≥ 36 dp, cả nhóm cao 48 dp vùng chạm).

## Nên và không nên

- Nên đặt nhãn giới thiệu trước control trên Mac khi ý nghĩa chưa rõ ("Camera:").
- Không dùng segmented cho hành động tức thì (đó là nút); không để một đoạn vô hiệu mà không nói lý do — ẩn hẳn khi điện thoại chỉ có một camera.
