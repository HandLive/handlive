[English](website.md) | Tiếng Việt

# Website

Trang giới thiệu sản phẩm và blog của HandLive, bằng tiếng Anh và tiếng Việt. Website chạy WordPress trên nginx
và PHP-FPM với MariaDB, tất cả trong Docker; mã nằm ở `website/` của kho này.

## Tổng quan

| Thành phần | Là gì |
|---|---|
| Stack | `website/docker-compose.yml`: `nginx:alpine` → `wordpress:php8.3-fpm-alpine` → `mariadb:10.11`; dịch vụ `wpcli` để dựng |
| Theme | `website/theme/handlive/`: theme cổ điển có `theme.json`; trang và bài viết soạn bằng trình soạn thảo khối |
| Ngôn ngữ | Polylang: tiếng Anh ở `/`, tiếng Việt ở `/vi/`; mỗi trang, mỗi bài được liên kết với bản dịch của nó |
| Nội dung | `website/seed/content/`: trang chủ và bài blog dạng mã khối theo từng ngôn ngữ, `site.json` liệt kê chúng |
| Trang quyền riêng tư | Sinh từ `docs/privacy.md` và `docs/privacy.vi.md` bằng `website/bin/build_privacy_content.py` |
| File thương hiệu | Chép từ `docs/brand/assets/` bằng `website/bin/sync-brand-assets.sh` |
| Giấy phép | `website/` theo GPL-2.0-or-later, như WordPress yêu cầu với theme; phần còn lại của HandLive vẫn là Apache-2.0 |

## Chạy trên máy

```bash
website/bin/setup.sh
```

- Cần Docker (OrbStack hoặc Docker Desktop) và Python 3.
- Lần chạy đầu tạo `website/.env` từ `.env.example` với mật khẩu ngẫu nhiên (git bỏ qua), khởi động stack,
  cài WordPress và Polylang, bật theme và nạp nội dung.
- Website ở http://localhost:8080; trang quản trị ở `/wp-admin/` với tài khoản và mật khẩu trong
  `website/.env`.
- Chạy lại an toàn: trang và bài viết được nhận theo slug và cập nhật tại chỗ, ảnh theo đường dẫn gốc. Chỉnh
  sửa trong trang quản trị với các trang được nạp sẵn sẽ bị lần chạy sau ghi đè.

## Trang và URL

| Trang | Tiếng Anh | Tiếng Việt |
|---|---|---|
| Trang chủ | `/` | `/vi/` |
| Quyền riêng tư | `/privacy/` | `/vi/quyen-rieng-tu/` |
| Blog | `/blog/` | `/vi/bai-viet/` |
| Bài viết | `/<slug>/` | `/vi/<slug>/` |

Polylang thêm liên kết `hreflang` giữa các bản dịch; theme thêm thẻ mô tả và Open Graph (ảnh social preview
của GitHub, hoặc ảnh đại diện của bài viết).

## Viết và dịch

- Bài blog: viết trong trang quản trị (Bài viết → Viết bài mới), chọn ngôn ngữ ở hộp Languages, rồi bấm dấu +
  cạnh ngôn ngữ kia để tạo bản dịch. Dùng chuyên mục "News" / "Tin tức".
- Chữ của theme (menu, chân trang, nút): tiếng Anh trong template PHP, tiếng Việt trong
  `website/theme/handlive/languages/vi.l10n.php`; mỗi chuỗi mới thêm một dòng ở đó.
- Câu chữ tiếng Việt theo hướng dẫn thương hiệu: dấu kiểu Apple và thuật ngữ của design system
  ([Hướng dẫn thương hiệu](brand-guidelines.vi.md)).
- Trang chủ dùng các class khối của theme: `hl-hero`, `hl-section`, `hl-section--tint`, `hl-grid`, `hl-card`,
  `hl-feature`, `hl-steps`, `hl-step`, `hl-shots`, `hl-table`, `hl-checks`, `hl-cta`.

## Thiết kế

- Màu, chữ và giọng văn theo [hướng dẫn thương hiệu](brand-guidelines.vi.md): nền bình minh, chữ tím than,
  tiêu đề Be Vietnam Pro Bold, chữ thân dùng font hệ thống, nút xanh lá; có diện mạo sáng và tối.
- Không gọi tới bên thứ ba: font và ảnh do chính website phục vụ, không có công cụ thống kê.

## Đưa lên mạng

Chưa triển khai. Trước khi chạy thật ở `handlive.app`:

1. Một máy chủ có Docker; đặt `SITE_URL=https://handlive.app` và `WP_ENVIRONMENT_TYPE=production` trong `.env`.
2. TLS phía trước nginx (một reverse proxy như Caddy, hoặc gắn chứng chỉ vào nginx).
3. Sao lưu hai volume `db` và `wordpress`.
4. Chạy `website/bin/setup.sh` một lần, sau đó quản lý nội dung trong trang quản trị; chỉ chạy lại phần nạp
   nội dung khi thật sự muốn.
