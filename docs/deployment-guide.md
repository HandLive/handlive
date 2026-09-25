# HandLive — Deployment & Distribution

> Chưa có build pipeline. Đây là kế hoạch phân phối theo quyết định D5/D7/D8 trong plan gốc.

## Android app

- **Play Store:** cần Permissions Declaration Form cho `READ_SMS`/`SEND_SMS`/`READ_CALL_LOG` theo ngoại lệ "Cross-device synchronization or transfer of SMS or calls", và khai báo dùng Accessibility API (D4/D12) — chuẩn bị video demo + use-case doc + privacy policy, nộp sớm (P1 milestone 2) để biết kết quả trước ship.
- **Fallback phân phối** (nếu Play Store reject SMS): F-Droid + direct APK. Đọc SMS qua Notification Listener nếu mất `SEND_SMS`.
- Shizuku (tùy chọn) cho đường âm thanh cuộc gọi Opus/WS — wizard hướng dẫn cài; phải khởi động lại Shizuku sau mỗi lần bật máy (plan §13 D10).

## macOS app

- Entitlement `keychain-access-groups` (data-protection keychain, 0.6.1); ký Developer ID cho app, extension camera và driver micro; target app đặt `ASSETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME = AccentColor`.

- **Virtual mic (AudioServerPlugin):** không thể cài qua Mac App Store (sandbox chặn `/Library/Audio/Plug-Ins/HAL/`). Phân phối:
  - PKG installer **signed + notarized** (`xcrun notarytool submit` + `stapler staple`), embed trong app; first-run detect thiếu plugin → mở PKG bằng Installer (Installer tự xin quyền quản trị) → `postinstall` chạy `killall coreaudiod` với quyền root. Không cần privileged helper (`SMJobBless` deprecated từ macOS 13; `launchctl kickstart` bị chặn từ macOS 14.4).
  - Song song: `brew install --cask handlive` (cài cả app + plugin).
- **Virtual camera (CMIOExtension):** system extension trong app bundle — App Store compatible. User approve trong System Settings > Login Items & Extensions.
- macOS 13+.

## iOS/iPadOS app

- App Store bình thường. APNs cho push. iOS 16+.

## Cloud relay (Rust)

- Biến môi trường: `DATABASE_URL`, `REDIS_URL`, `RELAY_JWT_SECRET` (byte UTF-8 thô, ≥ 32 byte, xoay theo lịch). Giới hạn theo IP chỉ tin `X-Forwarded-For` từ reverse proxy đặt trước relay (Caddy hoặc nginx).

- **D5:** self-host 1 VPS (Hetzner/OVH, ~$20/tháng) cho Phase 2. Docker + systemd. Stateless.
- Scale: monitor CPU/bandwidth, alert >70% → thêm VPS. Migrate managed (fly.io/Railway) khi >500 concurrent users.
- TLS: Let's Encrypt + cert pinning phía client.
- Ước tính: 100 concurrent Opus calls ≈ 12GB/giờ; commodity VPS 20TB/tháng đủ ~1000 users.

## CI

Bốn workflow GitHub Actions (`.github/workflows/`): `ci-android` (`./gradlew check`), `ci-apple` (`xcodebuild test` từng package và build app), `ci-relay` (fmt, clippy, test; service PostgreSQL 16 và Redis 7 cho test tích hợp), `ci-shared` (script kiểm vector, schema, tài liệu). Cần remote GitHub; bật branch protection bắt buộc bốn check trên `main`.

## USB boost (tùy chọn)

ADB port-forward (`adb forward tcp:PORT tcp:PORT`), auto-detect qua IOKit `IOServiceAddMatchingNotification`. Wizard 3 bước bật USB Debugging lần đầu; sau đó auto-switch. UVC native để dành v2.
