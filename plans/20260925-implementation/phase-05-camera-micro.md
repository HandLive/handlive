# Phase 5 — Điện thoại làm webcam và micro cho Mac

**Mục tiêu:** ứng dụng họp trên Mac chọn "HandLive Camera" và "HandLive Microphone"; hình và tiếng
từ điện thoại qua Wi-Fi, tự tăng tốc qua USB khi cắm cáp; chất lượng thích ứng theo mạng, nhiệt,
pin.

## Cổng G5 — spike D6 (tuần đầu)

- CMIOExtension: extension ký Developer ID kích hoạt từ app trong `/Applications`, xuất khung 720p30
  từ sink stream, Zoom/Meet/FaceTime nhận được; kiểm cập nhật extension cần khởi động lại (C11).
- AudioServerPlugin loopback theo mô hình BlackHole (C8): thiết bị ẩn + "HandLive Microphone", cài
  bằng PKG nhúng + `postinstall` `killall coreaudiod` (C9); ứng dụng họp nghe được PCM app phát.
- Kết quả trong `reports/phase-05-spike-d6.md`; không đạt → dừng Phase 5.

## Ngữ cảnh

- Chức năng lá: `08-camera-mic.md` CAM-01…05 (kể cả "Quy tắc hình ảnh": `rotation_deg`, center-crop,
  chọn kích thước mã hóa); common specs 0.5 khung HL, kênh `/v1/stream/camera`, MAC `HLSTREAM1`.
- Nghiên cứu: `plans/20260924-virtual-camera-mic-research/plan.md`,
  `plans/20260924-ipc-research/plan.md`; kiến trúc §10.
- Design system: `CameraPreview`, `MenuBarMenu` (menu con Camera), `Notification` (kênh
  `camera_request`, `camera_live`, `camera_alert`).
- Quyết định: D6, D7/C9, D8, C8, C11.

## Yêu cầu và tiêu chí đo

- Trễ kính-tới-kính 720p30 < 120 ms Wi-Fi, < 70 ms USB; khung đầu là IDR kèm SPS/PPS; chu kỳ IDR 1–2
  s khi đổi kênh.
- Điện thoại hiện chỉ báo quyền riêng tư và thông báo thường trực có "Dừng"; yêu cầu bật tự hủy sau
  60 s.
- Mac: nút "Dừng" không phải phá hủy; không có lật gương.

## Thẻ việc

| Mã | Việc | Đầu ra | Tiêu chí chấp nhận |
|----|------|--------|--------------------|
| M5.1 [macOS] | CAM-01: kích hoạt CMIOExtension (`OSSystemExtensionRequest`), cài PKG micro ảo, hướng dẫn cho phép trong Cài đặt hệ thống, gỡ; extension target `HandLiveCameraExtension`, driver `HandLiveMic` | `apple/macOS/…Extension`, `apple/macOS/HandLiveMic`, `docs/deployment-guide.md` | Cài, gỡ, cập nhật (kể cả cần khởi động lại) đúng E của CAM-01 |
| M5.2 [macOS] | CAM-02: nhu cầu từ consumer (`app.handlive.camera.demand`, `DeviceIsRunningSomewhere`), `camera/start` với `hlaf`, kênh stream, `VTDecompressionSession` → `VTPixelTransferSession` → sink stream; Opus decode → AUHAL `app.handlive.mic.feed`; khung chờ "Đang chờ điện thoại…" | app, packages | Trễ đạt mục tiêu qua Wi-Fi; mất khung → `camera/keyframe` |
| M5.3 [macOS] | Cửa sổ `CameraPreview`, menu con Camera trong `MenuBarMenu`, CAM-03 điều khiển (`camera/config`), CAM-04 USB: phát hiện IOKit, adb nhúng `forward`, wizard bật gỡ lỗi USB (D8), chuyển kênh có IDR | app | Chuyển Wi-Fi ↔ USB không đứt hình quá 1 khung IDR |
| A5.1 [android] | CAM-02: FGS type `camera | microphone` (thông báo `camera_request` "Bật"/"Từ chối" là ngoại lệ Android 14+), Camera2 + `MediaCodec` H.264 (bậc 1080p/720p/480p), `AudioRecord` 48 kHz + Opus 32 kbps, khung HL, xoay theo `rotation_deg` và center-crop | `android/feature/camera` | Khung đầu IDR; FGS khởi động từ thông báo trên Android 14+ |
| A5.2 [android] | CAM-03 áp cấu hình (đổi camera, chất lượng, micro, tạm dừng hình), CAM-05 thích ứng: giảm bitrate 75 %, hạ bậc, hạ fps, nhiệt (`PowerManager.thermalStatus`), pin < 20 %; `camera/state` với `reason` | `android/feature/camera` | Kịch bản mạng nghẽn hạ và nâng đúng thứ tự; quá nóng → dừng với thông báo `camera_alert` |
| A5.3 [android] | CAM-04 phía Android: chấp nhận kết nối `127.0.0.1` là kênh `usb`, đóng kết nối Wi-Fi mã 4409, `camera/state reason = transport` | `android/core/transport` | Chuyển kênh < 1 s |
| T5.1 [test] | Đo trễ kính-tới-kính (đồng hồ mili giây quay trước camera), fps, bitrate; ma trận Zoom, Meet, FaceTime, Teams; máy nóng 15 phút | `tools/bench/`, `reports/` | Đạt mục tiêu; không rơi khung liên tục quá 2 s |

## Kiểm thử

- Đơn vị: chọn kích thước mã hóa theo `hlaf` và bậc, máy trạng thái CAM-05, phân tích Annex-B.
- Tay: cập nhật extension từ bản cũ, gỡ sạch, cài lại; máy chưa vào `/Applications` (E1 của CAM-01).

## Rủi ro và quay lui

- Extension cần khởi động lại sau cập nhật (C11) → thông báo rõ, không chặn phần còn lại.
- `killall coreaudiod` làm ứng dụng họp mất âm thanh vài giây → cài khi không có cuộc họp, cảnh báo
  trước.
- USB: adb không hoạt động trên vài OEM → luôn còn Wi-Fi.
