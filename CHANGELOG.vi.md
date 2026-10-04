# Nhật ký thay đổi

Các thay đổi đáng chú ý của kho hub HandLive (tài liệu và kế hoạch) được ghi trong file này.

Định dạng theo [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [Unreleased]

### Added

- CALL-05 (cuộc gọi từ ứng dụng khác): `AppCallListenerService` (`NotificationListenerService`) đọc thông báo cuộc gọi
  của Telegram và các ứng dụng khác trên Android và gửi tới Mac; người dùng có thể trả lời, từ chối hoặc kết thúc từ
  Mac (âm thanh vẫn ở trên điện thoại ở v1). Cần quyền truy cập thông báo, một quyền đặc biệt mà người dùng bật bằng
  tay. Các cuộc gọi di động không thay đổi.

### Changed

- Đã merge các nhánh spike/fix còn lại vào `main`: apple `fix/real-device-pairing`,
  `feat/phase-04-call-audio`, `feat/phase-05-camera-mic`, `feat/phase-06-web-handoff`; android
  `fix/real-device-pairing`. Relay local chuyển sang `main`. Đã cập nhật lộ trình README.
- `CLAUDE.md`: handoff báo cáo tiến độ 01/10/2026 (đã làm / đang làm / kế hoạch) cho agent viết mã.
- Thiết kế chi tiết: CALL-05 (leaves 06-call-control, 00-common-specs, 01-setup-settings); công thức khả năng Mac
  cho cuộc gọi ứng dụng làm rõ.

### Fixed

- Mac và iPhone/iPad: sau khi Keychain mất khóa của HandLive (hoặc chạy một bản build ký bởi team khác), ứng dụng tạo
  khóa mới nhưng vẫn giữ kho cặp và cơ sở dữ liệu SMS niêm phong bằng khóa cũ, nên hiện như chưa có điện thoại trong
  khi mọi lần ghép đôi mới đều không lưu được (điện thoại báo đã ghép: ghép đôi một phía) và SMS tắt. Nay các tệp đó
  được để nguyên và ứng dụng dùng ngăn thứ hai (`*.alt`), nên quay lại bản build kia sẽ thấy lại dữ liệu của nó; với
  khóa thứ ba, tệp lạ cũ hơn nhường chỗ (giữ một thế hệ). Người dùng ghép đôi lại; định dạng SQLCipher được ghim
  (SET-03 API 1 logic 5).

### Ghi chú tương thích

- Phiên bản v0.1.0-beta.1 trở về trước trên Mac và iOS: mục `NOTIFICATION_LISTENER` mới trong `permissions_missing`
  sẽ hiển thị gợi ý "quyền thiếu" chung cho tới khi app được cập nhật để hiểu các cuộc gọi ứng dụng. Không cần hành
  động từ người dùng.

## [0.1.0-beta.1] — 30/09/2026

Bản beta công khai phối hợp đầu tiên trên toàn workspace HandLive.

### Added

- Hub `README.md` / `README.vi.md`: bảng Trạng thái rõ hơn, ô lộ trình ngắn hơn, và liên kết tới bản beta này.
- Tăng phiên bản app cho tag beta: Android `0.1.0-beta.1` (versionCode 2), Apple marketing `0.1.0`.

### Có trong bản beta này (mã trên `main`)

- Phase 0–3: đồng bộ clipboard, cầu SMS, shell app iOS, relay Rust, metadata và điều khiển cuộc gọi.
- Sửa ghép QR máy thật (Galaxy S25 Ultra ↔ Mac, 30/09/2026).
- Sửa HOME leave của spike G6 trên Android 16 (chỉ spike; chưa mở thẻ sản phẩm).

### Chưa có trong bản beta này

- Âm thanh cuộc gọi (Phase 4 / G4), camera/mic ảo (Phase 5 / G5), sản phẩm Duyệt web tiếp (Phase 6).
- Phân phối App Store / Play Store; cổng **G1** và **G2** vẫn mở.
- Thông tin đăng nhập APNs / FCM / relay sản xuất (đầu vào của chủ dự án).

### Commit phối hợp

| Kho | Tag | Commit |
|-----|-----|--------|
| [handlive](https://github.com/HandLive/handlive) | `v0.1.0-beta.1` | `e3c2a63` |
| [handlive-android](https://github.com/HandLive/handlive-android) | `v0.1.0-beta.1` | `60435aa` |
| [handlive-apple](https://github.com/HandLive/handlive-apple) | `v0.1.0-beta.1` | `0ce7f4b` |
| [handlive-shared](https://github.com/HandLive/handlive-shared) | `v0.1.0-beta.1` | `1536980` |
| [handlive-relay](https://github.com/HandLive/handlive-relay) | `v0.1.0-beta.1` | `cda13bf` (`main`) |

## [2026-09-30]

### Changed

- Hub `README.md` / `README.vi.md`: bảng tiến độ lộ trình đối chiếu kế hoạch triển khai, kèm quy định bắt buộc
  cập nhật bảng đó mỗi khi hoàn thành một công việc cụ thể. Ảnh chụp tương ứng trong `docs/project-roadmap*.md`.
- Handoff (`CLAUDE.md`, `real-device-session-2026-09-29.md`): ghép QR máy thật S25 Ultra ↔ Mac ổn định và đã vào
  `main`; cửa sổ Settings/Pair lên trước; G6 HOME trên Android 16 đã xác nhận (`inactive reason=left`).

### Fixed

- Báo cáo spike G6: ghi nhận sửa HOME trên `fix/g6-home-android16` (đã vào android `main`).
