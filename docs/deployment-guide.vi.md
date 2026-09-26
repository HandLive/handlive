[English](deployment-guide.md) | Tiếng Việt

# HandLive: Đóng gói và phân phối

> Chưa có pipeline build. Đây là kế hoạch phân phối theo quyết định D5, D7 và D8 trong plan gốc.

## Ứng dụng Android

- **Play Store.** Cần Permissions Declaration Form cho `READ_SMS`, `SEND_SMS` và `READ_CALL_LOG`, theo ngoại lệ "Cross-device synchronization or transfer of SMS or calls". Khai báo dùng Accessibility API (D4/D12). Chuẩn bị video demo, tài liệu use-case và privacy policy. Nộp sớm ở mốc P1 milestone 2 để biết kết quả trước khi phát hành.
- **Phân phối dự phòng.** Nếu Play Store từ chối quyền SMS, phát hành qua F-Droid và APK trực tiếp. Khi mất `SEND_SMS`, đọc SMS qua Notification Listener.
- **Shizuku** là tùy chọn cho đường âm thanh cuộc gọi Opus/WS. Wizard hướng dẫn cài. Người dùng khởi động lại Shizuku sau mỗi lần bật máy (plan §13 D10).

## Ứng dụng macOS

- Entitlement `keychain-access-groups` (data-protection keychain, 0.6.1). Ký Developer ID cho app, extension camera và driver micro. Target app đặt `ASSETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME = AccentColor`.
- **Micro ảo (AudioServerPlugin).** Mac App Store không cài plugin này. Sandbox chặn `/Library/Audio/Plug-Ins/HAL/`. Phân phối theo hai đường:
  - PKG **đã ký và notarized** (`xcrun notarytool submit`, rồi `stapler staple`), nhúng trong app. Lần chạy đầu, app thấy thiếu plugin thì mở PKG bằng Installer. Installer tự xin quyền quản trị. `postinstall` chạy `killall coreaudiod` với quyền root. Không cần privileged helper. `SMJobBless` deprecated từ macOS 13. `launchctl kickstart` bị chặn từ macOS 14.4.
  - Song song: `brew install --cask handlive`. Lệnh này cài cả app và plugin.
- **Camera ảo (CMIOExtension).** System extension nằm trong app bundle, tương thích App Store. Người dùng chấp thuận trong System Settings, mục Login Items & Extensions.
- Yêu cầu macOS 13 trở lên.

## Ứng dụng iOS và iPadOS

Phát hành App Store thông thường. Push đi qua APNs. Yêu cầu iOS 16 trở lên.

## Cloud relay (Rust)

- Biến môi trường: `DATABASE_URL`, `REDIS_URL`, `RELAY_JWT_SECRET` (byte UTF-8 thô, từ 32 byte, xoay theo lịch). Giới hạn theo IP chỉ tin `X-Forwarded-For` từ reverse proxy đặt trước relay, Caddy hoặc nginx.
- **D5.** Tự host một VPS (Hetzner hoặc OVH, khoảng 20 USD mỗi tháng) cho Phase 2. Docker và systemd. Relay không giữ trạng thái.
- Mở rộng: theo dõi CPU và băng thông. Cảnh báo khi vượt 70 phần trăm, rồi thêm VPS. Chuyển sang nền tảng managed (fly.io hoặc Railway) khi quá 500 người dùng cùng lúc.
- TLS: Let's Encrypt, kèm cert pinning phía client.
- Ước tính: 100 cuộc gọi Opus cùng lúc khoảng 12 GB mỗi giờ. VPS thông thường, 20 TB mỗi tháng, đủ cho khoảng 1000 người dùng.

## CI

Mỗi kho có một workflow GitHub Actions trong `.github/workflows/` của kho đó.

- `ci-android` chạy `./gradlew check`.
- `ci-apple` chạy `xcodebuild test` từng package, SwiftLint, rồi build app.
- `ci-relay` chạy fmt, clippy và test. Test tích hợp dùng PostgreSQL 16 và Redis 7.
- `ci-shared` kiểm vector, vector sinh lại, và schema đối chiếu ví dụ trong tài liệu.
- `ci-docs` ở hub kiểm khuôn tài liệu và schema.

Mỗi workflow dựng lại bố cục workspace bằng `actions/checkout`. Hub nằm ở gốc, checkout trước khi cần tài liệu. Phần mã vào `<phần>/`. `handlive-shared` vào `shared/`. Tên kho lấy theo `${{ github.repository_owner }}/handlive-<phần>`. Cả năm kho phải nằm cùng một organization và giữ đúng tên: `handlive`, `handlive-android`, `handlive-apple`, `handlive-relay`, `handlive-shared`.

Kho private: tạo secret `HANDLIVE_REPOS_TOKEN` ở cấp organization. Token là fine-grained PAT hoặc token GitHub App, quyền Contents: read trên năm kho. Kho public thì `github.token` đủ.

Sửa `shared/` hoặc tài liệu không tự kích hoạt CI nền tảng. Chạy tay bằng `workflow_dispatch`. Mỗi workflow lấy nhánh trùng tên của `handlive-shared` và hub nếu có, ví dụ `feat/phase-01-clipboard` ở mọi kho. Không có nhánh đó thì dùng `main`. Bật branch protection. Nhánh `main` mỗi kho phải qua check tương ứng.

## Tăng tốc USB (tùy chọn)

ADB port-forward (`adb forward tcp:PORT tcp:PORT`). Tự nhận cáp qua IOKit `IOServiceAddMatchingNotification`. Wizard ba bước bật USB Debugging lần đầu. Các lần sau tự chuyển. UVC native để dành cho v2.
