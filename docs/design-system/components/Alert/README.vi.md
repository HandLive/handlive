[English](README.md) | Tiếng Việt

# Alert

Hỏi xác nhận trước hành động không hoàn tác được, hoặc báo lỗi mà app không tự phục hồi được.
HandLive dùng rất ít: mất kết nối, gửi lỗi hay thiếu quyền đều hiện tại chỗ (`StatusIndicator`,
`GroupedList`), không bằng alert.

## Khi nào dùng

| Tình huống | macOS | iOS/iPadOS và Android |
|-----------|-------|-----------------------|
| Hủy ghép nối (PAIR-03) — người dùng chủ động chọn | Alert dạng sheet gắn cửa sổ Cài đặt: "Hủy" + "Hủy ghép nối" (mặc định, bên phải) | Hộp chọn hành động (action sheet) mọc từ dòng vừa chạm: "Hủy ghép nối" màu đỏ ở trên, "Hủy" ở dưới |
| Xóa toàn bộ dữ liệu HandLive, xóa thiết bị khỏi máy chủ (SET-02 trường 28) | Như trên, với "Xóa toàn bộ" hoặc "Xóa khỏi máy chủ" | Như trên, với "Xóa toàn bộ" hoặc "Xóa khỏi máy chủ" |
| Lỗi không tự phục hồi (ví dụ cài camera ảo thất bại) | Alert có nút dẫn tới cách sửa | Alert |
| Mất kết nối, gửi lỗi, thiếu quyền | Không dùng alert | Không dùng alert |

## Nội dung

- Tiêu đề nói đúng tình huống, tối đa hai dòng; câu hỏi hoàn chỉnh có dấu hỏi: "Hủy ghép nối với
  Pixel 8 của Lan?". Không dùng "Lỗi", không mã lỗi.
- Nội dung chỉ khi có ích: nói hệ quả và cách quay lại ("Muốn dùng lại, bạn cần quét mã QR mới.").
- Tối đa ba nút, 1–2 từ, động từ. Nút hủy luôn là "Hủy", đặt bên trái (hàng ngang) hoặc dưới cùng
  (cột), không bao giờ là mặc định. "OK" chỉ cho alert thuần thông tin.
- Kiểu phá hủy (đỏ) trên Mac chỉ dành cho hành động người dùng **không** chủ động chọn; hành động họ
  vừa chọn thì là nút mặc định thường. Trong action sheet trên iPhone/Android, hành động phá hủy
  luôn đỏ và nằm trên.

## API

SwiftUI `alert(_:isPresented:actions:message:)`,
`confirmationDialog(_:isPresented:titleVisibility:actions:)` (iOS 16, macOS 13) với
`ButtonRole.destructive` /`.cancel`; AppKit `NSAlert.beginSheetModal(for:)`. Android: `HLAlert`,
`HLActionSheet` dựng theo cùng quy cách (kính, capsule), không dùng `AlertDialog` của Material.

## Nên và không nên

- Nên để Esc (Mac) và chạm ra ngoài (action sheet) tương đương "Hủy".
- Không hiện alert ngay lúc mở app; không xếp hai alert chồng nhau.
