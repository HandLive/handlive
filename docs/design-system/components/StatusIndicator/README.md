# StatusIndicator

Cho biết liên kết giữa hai máy đang ra sao: biểu tượng tô màu trạng thái đi kèm chữ. Là chỉ báo trong ngữ cảnh — HIG khuyên dùng chỉ báo thay cho alert khi mất kết nối.

## Trạng thái

| Trạng thái | Chữ | SF Symbol ↔ Material | Màu biểu tượng |
|-----------|-----|----------------------|----------------|
| Kết nối qua cùng mạng Wi-Fi | "Đã kết nối qua Wi-Fi" (nhãn ngắn "LAN") | `wifi` ↔ `wifi` | `status-connected` |
| Kết nối qua Internet | "Đã kết nối qua Internet" | `globe` ↔ `public` | `status-connected` |
| Kết nối qua USB (camera) | "Đang dùng USB" | `cable.connector` ↔ `usb` | `status-connected` |
| Đang kết nối | "Đang kết nối…" | chấm nhấp nháy | `status-connecting` |
| Điện thoại ngoại tuyến | "Điện thoại ngoại tuyến · lần cuối 14:05" | `antenna.radiowaves.left.and.right.slash` ↔ `mobile_off` | `status-offline` |
| Máy này mất mạng | "Mất kết nối" | `wifi.slash` ↔ `wifi_off` | `status-offline` |
| Cần ghép nối lại | "Cần ghép nối lại" | `exclamationmark.triangle.fill` ↔ `warning` | `status-error` |
| Đang phát camera | "Đang phát camera" | chấm nhấp nháy | `status-connected` |

- Đã đồng bộ với tài liệu chi tiết (25/09/2026): CONN-01 và PAIR-02 dùng "Đã kết nối qua Wi-Fi", "Đã kết nối qua Internet"; "LAN" chỉ còn trong nhãn ngắn dạng viên.
- Chữ dùng `secondary-label`; chỉ biểu tượng hoặc chấm mang màu. Không bao giờ chỉ có chấm màu.
- Dạng viên (`pill`) dùng cho nhãn ngắn trên đầu popover, cửa sổ: nền `tertiary-system-fill`, biểu tượng màu trạng thái, chữ `label`.
- VoiceOver/TalkBack đọc câu đầy đủ: "Đã kết nối qua Wi-Fi với Pixel 8 của Lan".
- Nhấp nháy chỉ cho "Đang kết nối" và "Đang phát camera", tắt khi bật Giảm chuyển động (`duration-pulse`).

## Ở đâu

Menu của thanh menu Mac (dòng đầu), đầu cửa sổ Tin nhắn khi mất kết nối, dòng `DeviceRow`, màn Thiết bị trên Android và iPhone, panel cuộc gọi khi mất phiên ("Mất kết nối với điện thoại").

## Nên và không nên

- Nên cập nhật tại chỗ, không đẩy thông báo mỗi lần kết nối lại.
- Không dùng đỏ cho ngoại tuyến thông thường — ngoại tuyến là xám; đỏ chỉ khi người dùng phải làm gì đó.
