[English](README.md) | Tiếng Việt

# Toggle

Công tắc và ô chọn cho cài đặt bật/tắt. Mac phân biệt switch (tính năng chính) và checkbox (tùy chọn
phụ); iPhone/iPad và Android chỉ dùng switch trong dòng danh sách.

## Chọn loại

| Nền tảng | Tính năng chính ("Đồng bộ bảng nhớ tạm", "Tin nhắn SMS", "Nghe gọi trên Mac") | Tùy chọn phụ ("Chặn nội dung nhạy cảm", "Đổ chuông trên Mac") |
|----------|------|------|
| macOS | Switch cỡ mini trong form nhóm: `Toggle` + `.toggleStyle(.switch)` + `.controlSize(.mini)` | Checkbox thụt lề dưới tính năng chính: `.toggleStyle(.checkbox)` |
| iOS/iPadOS | Switch ở cuối dòng danh sách: `Toggle` trong `Form`/`List` | Switch ở dòng riêng, có chú thích dưới nhóm |
| Android | `HLSwitch` cỡ 51×31 dp trong dòng 56 dp (cả dòng là vùng chạm) | Như tính năng chính |

- Màu bật: iOS và Android dùng `system-green` như mặc định của iOS; Mac dùng màu nhấn
  (`accent-fill`, hoặc màu người dùng chọn trong Cài đặt hệ thống). Núm công tắc dùng
  `switch-thumb`.
- Tắt tính năng chính thì tùy chọn phụ vẫn hiện nhưng mờ (checkbox trên Mac) — không ẩn, để người
  dùng thấy sẽ bật lại được gì.
- Nhãn nói tác dụng khi bật; chú thích dưới nhóm giải thích hệ quả. Không dùng switch cho hành động
  tức thì — dùng `Button`.
- Công tắc không chỉ đổi màu: vị trí núm cũng đổi. Trạng thái được đọc bằng lời ("Bật"/"Tắt").

## Khi tính năng chưa dùng được

Nếu tính năng tắt ở thiết bị kia hoặc thiếu quyền (so khả năng hai phía, SET-02), switch bị vô hiệu
và dòng có lý do màu `text-orange` kèm cách sửa: "Thiếu quyền SMS trên điện thoại · Cấp quyền". Bật
một tính năng cần công bố (nghe gọi trên Mac, Hỗ trợ tiếp cận trên Android) thì switch chỉ chuyển
sang bật khi `ConsentSheet` hoàn tất.

## Nên và không nên

- Nên để thay đổi có hiệu lực ngay, không có nút "Áp dụng".
- Không đặt switch và checkbox lẫn lộn cho cùng một cấp; đã dùng checkbox cho một nhóm thì giữ
  checkbox.
- Không đặt switch trên toolbar hay trong menu; trong menu dùng dấu kiểm.
