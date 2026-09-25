# Báo cáo 04-clipboard

**Trạng thái:** Xong, có điểm cần xác nhận — `docs/detailed-design/04-clipboard.md` (5 chức năng lá;
quy tắc chung QC1–QC9 đầu file).

## Cần bổ sung 00-common-specs
1. 0.10: `CLIP_INLINE_MAX` 180 KiB plaintext, `CLIP_LOOP_WINDOW` 5 s, `CLIP_DETECT_DEBOUNCE` 300 ms,
   `CLIP_TRANSFER_IDLE_TIMEOUT` 30 s.
2. 0.9.5: `clip.seen_change_count` (iOS, nội bộ).
3. 0.7.1: `chunk`, `cancel`, `conflict` dùng cả ở CLIP-04; `ack` của `push`: `status`
   applied|ignored (`reason` conflict|duplicate|cancelled), lỗi kèm `details.status = rejected`.
4. 0.1: `ClipboardTileService`, `ClipboardShareTarget` (activity-alias).

## Lệch quyết định được giao (có bằng chứng)
- Ngưỡng inline 200 → 180 KiB: 200 KiB sau base64 ≈ 267 KiB, vượt giới hạn envelope 256 KiB.
- CLIP-05 Android: AOSP android10/android14 (`sendClipChangedBroadcast`) chỉ gọi listener khi ứng
  dụng có focus. Thay bằng tín hiệu Accessibility, và `getPrimaryClipDescription().getTimestamp()`
  khi có focus; Accessibility tắt → hoãn xóa.
- Mac ghi bằng `prepareForNewContents(with: .currentHostOnly)` (chặn Universal Clipboard).
- QC8 thêm nhánh theo `origin_ts` cho clip gửi chéo; iOS không ghi đè nội dung tại chỗ chưa gửi.

## Chưa chắc
- Nhận diện sao chép/overlay theo OEM; ngoại lệ mở activity nền cho Accessibility trên Android 15+.
- Android ghi văn bản lớn qua URI (giới hạn binder) — cần thử thực tế.
