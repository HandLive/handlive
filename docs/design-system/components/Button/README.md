# Button

Nút bấm theo ba thuộc tính của HIG — kiểu (style), nội dung (chữ, biểu tượng hoặc cả hai) và vai trò
(role) — cho Mac, iPhone/iPad và Android.

## Kiểu và vai trò

| Kiểu | Khi dùng | macOS / iOS (SwiftUI) | Android (Compose) | Token |
|------|----------|----------------------|-------------------|-------|
| Nổi bật (prominent) | Hành động chính của màn, tối đa một (hiếm khi hai) | `.borderedProminent`; từ 26: `.glassProminent` | `HLButton(style = Prominent)` | `accent-fill`, `on-accent` |
| Kính / viền | Hành động phụ đứng cạnh nút chính | `.bordered`; từ 26: `.glass` | `HLButton(style = Glass)` | `glass-fill`, `glass-stroke`, chữ `label` |
| Nhạt màu nhấn (tinted) | Hành động nên thấy nhưng không phải chính ("Mở cài đặt") | `.bordered` + `.tint(.accentColor)` | `style = Tinted` | `accent-tint`, `accent` |
| Chữ (plain) | Liên kết, lệnh phụ trong câu | `.borderless` / `.plain` | `style = Plain` | `accent` |
| Phá hủy (destructive) | Hủy ghép nối, xóa lịch sử | `role: .destructive` | `style = Destructive` | `destructive-text` trên nền kính (`glass-fill`, `glass-stroke`); nền đỏ đặc `call-decline-fill` chỉ cho nút tròn Từ chối, Kết thúc trong `CallPanel` |

- Vai trò: bình thường, chính (phản hồi Return), hủy (phản hồi Esc), phá hủy. **Không** gán vai trò
  chính cho nút phá hủy.
- Phân biệt mức ưu tiên bằng kiểu, không bằng cỡ. Mỗi màn một nút nổi bật.
- Nhãn bắt đầu bằng động từ, sentence case: "Ghép nối", "Gửi bảng nhớ tạm", "Hủy ghép nối". Nút mở
  cửa sổ hay bước khác kết thúc bằng "…": "Cài đặt…", "Từ chối kèm tin nhắn…".
- Nút chỉ có biểu tượng phải có nhãn trợ năng và (trên Mac) tooltip bắt đầu bằng động từ.

## Cỡ

| Nền tảng | Cỡ dùng trong HandLive | Vùng bấm |
|----------|------------------------|----------|
| macOS | `.controlSize(.regular)` cao ~24 pt trong form và sheet; `.large` cho nút cuối cửa sổ chào | ≥ `size-hit-mac` (28 pt), tối thiểu 20 pt |
| iOS/iPadOS | `.controlSize(.large)` + `.buttonBorderShape(.capsule)`, cao 50 pt, rộng hết lề cho hành động chính của màn | ≥ `size-hit-ios` (44 pt) |
| Android | Capsule cao 50 dp (chính) hoặc 48 dp (phụ), chữ Inter 17 sp Semibold | ≥ `size-hit-android` (48 dp) |

## Trạng thái

Nhấn: tối đi 8%, không gợn sóng (ripple) trên Android. Vô hiệu: độ mờ 40% và luôn có dòng lý do gần
đó. Đang xử lý: đổi nhãn sang tiến trình ("Đang ghép nối…") kèm `ProgressView` nhỏ, không đổi cỡ
nút.

## Nên và không nên

- Nên đặt nút chính ở cạnh phải (Mac) hoặc dưới cùng trong vùng dễ với (iPhone, Android).
- Không đặt hai nút nổi bật cạnh nhau; không dùng đỏ son `brand-fire` cho nút.
- Không dùng "OK", "Có", "Không" làm nhãn; "Hủy" chỉ dành cho nút hủy.
