# HandLive — Deployment & Distribution

> Chưa có build pipeline. Đây là kế hoạch phân phối theo quyết định D5/D7/D8 trong plan gốc.

## Android app

- **Play Store:** cần Permissions Declaration Form cho `READ_SMS`/`SEND_SMS`/`InCallService` — chuẩn bị video demo + use-case doc + privacy policy, nộp sớm (P1 milestone 2) để biết kết quả trước ship.
- **Fallback phân phối** (nếu Play Store reject SMS): F-Droid + direct APK. Đọc SMS qua Notification Listener nếu mất `SEND_SMS`.
- `BluetoothHeadsetClient` @SystemApi cần Shizuku (ADB-level grant) — wizard hướng dẫn cài Shizuku.

## macOS app

- **Virtual mic (AudioServerPlugin):** không thể cài qua Mac App Store (sandbox chặn `/Library/Audio/Plug-Ins/HAL/`). Phân phối:
  - PKG installer **signed + notarized** (`xcrun notarytool submit` + `stapler staple`), embed trong app; first-run detect thiếu plugin → `SMAppService`/`SMJobBless` privileged helper → copy + `killall -9 coreaudiod`.
  - Song song: `brew install --cask handlive` (cài cả app + plugin).
- **Virtual camera (CMIOExtension):** system extension trong app bundle — App Store compatible. User approve trong System Settings > Login Items & Extensions.
- macOS 13+.

## iOS/iPadOS app

- App Store bình thường. APNs cho push. iOS 16+.

## Cloud relay (Rust)

- **D5:** self-host 1 VPS (Hetzner/OVH, ~$20/tháng) cho Phase 2. Docker + systemd. Stateless.
- Scale: monitor CPU/bandwidth, alert >70% → thêm VPS. Migrate managed (fly.io/Railway) khi >500 concurrent users.
- TLS: Let's Encrypt + cert pinning phía client.
- Ước tính: 100 concurrent Opus calls ≈ 12GB/giờ; commodity VPS 20TB/tháng đủ ~1000 users.

## USB boost (tùy chọn)

ADB port-forward (`adb forward tcp:PORT tcp:PORT`), auto-detect qua IOKit `IOServiceAddMatchingNotification`. Wizard 3 bước bật USB Debugging lần đầu; sau đó auto-switch. UVC native để dành v2.
