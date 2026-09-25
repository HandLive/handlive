# Design tokens

`tokens.json` — nguồn token của design system (bốn giao diện `light`, `dark`, `light-hc`, `dark-hc`; màu, kiểu chữ, khoảng cách, bo góc, bóng, kích thước, thời lượng). Định dạng theo artifact Design System (mỗi họ là danh sách `{name, value, usage}`; màu có thể là bí danh `{token}`). Sinh mã từ đây, không chép giá trị tay: Compose `HandLiveTheme` (Android), Asset Catalog Color Sets + `Font` (Apple). Trên Apple, màu ngữ nghĩa (`label`, `systemBackground`…) luôn gọi API hệ thống; giá trị trong file chỉ là tham chiếu.
