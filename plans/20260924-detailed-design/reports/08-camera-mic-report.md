# Báo cáo 08-camera-mic (phần tiếp)

**Trạng thái:** Xong — thêm 8.2.5 (14 API, khớp số API trong bảng bước CAM-02), CAM-03, CAM-04, CAM-05; file ~1 425 dòng, không sửa nội dung cũ.

## Cần hợp nhất vào 00-common-specs

1. `camera/start` thêm `video.quality` (auto|480p|720p|1080p): Android cần biết chế độ để CAM-05 thích ứng.
2. `camera/config` thêm `consumer_format {width,height}`: trần khi `hlaf` đổi giữa phiên.
3. 0.6.3 bước 7: `stream_welcome.mac` = HMAC(k_auth, "HLSTREAM1|welcome|" ‖ session_id ‖ nonce_c ‖ nonce_s) — nên áp dụng cả `call_audio`.
4. Enum mới: `camera/stop.reason`, `camera/state.state/reason`, `camera/keyframe.reason`; `camera/start` trả được `CAM_THERMAL_LIMIT`.

## Lựa chọn thiết kế

- IDR theo bộ hẹn (`KEY_I_FRAME_INTERVAL` = 3600) để đổi 1 s/2 s khi chuyển kênh, không cấu hình lại encoder.
- M-APP nói giao thức host adb qua 5037, tránh client khác phiên bản tắt server của người dùng.
- FGS luôn nâng cả `camera|microphone`; khung "Đã tạm dừng hình" do M-APP tạo; kênh stream cũ đóng 4409.

## Câu hỏi mở

- Xoay hình khi điện thoại dựng đứng chưa có quyết định.
- 480p 16:9 (≈848×480) tùy camera hỗ trợ.
- Lọc theo vendor ID có thể nhận nhầm (SSD Samsung) — wizard hỏi xác nhận trước.
