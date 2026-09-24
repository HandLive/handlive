# Báo cáo 01-setup-settings

**Trạng thái:** Xong — `docs/detailed-design/01-setup-settings.md` (SET-01, SET-02, SET-03; ~810 dòng).

## Cần bổ sung vào 00-common-specs

1. 0.9.5: `setup.started_at`, `setup.completed_at` (timestamp, mọi nền tảng); `perm.requested` (set<string>, Android). SET-02 đã liệt kê `call.ringtone` do CALL-01 đề xuất.
2. 0.7.2: `features.call.notify` (iOS); `opus_fallback.reason` thêm `disabled`; `capability/update` luôn là ảnh chụp đầy đủ, tính năng vắng mặt = tắt.
3. 0.9.4 và CONN-03 API 4: khóa Redis `revoked_notice:<device_id>` (set, TTL 30 ngày) để báo `pair_revoked` cho đối phương offline sau `DELETE /v1/devices/me` (cặp đã bị CASCADE).
4. Relay: endpoint dùng JWT trả 404 `DEVICE_NOT_FOUND` khi `sub` không còn trong `devices`.
5. Định danh: Keychain account `ik_sig`, `ik_dh`, `db_key`; App Group `group.app.handlive`; gói `app.handlive.android`; alias Keystore `hl_master`.

## Mâu thuẫn

- Ví dụ `capability/update` ở CAM-01 API 7 và AUDIO-01 API 2 chỉ gửi một phần `features`.

## Câu hỏi mở

- "Xóa thiết bị khỏi máy chủ" kéo theo hủy mọi cặp và tắt `relay.enabled` — đúng ý chủ dự án?
- Điện thoại bật `feature.call_audio`, `feature.camera` bằng công tắc riêng, kèm gợi ý khi đối phương bật — cần xác nhận.
