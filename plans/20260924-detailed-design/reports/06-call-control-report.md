# Báo cáo 06-call-control

**Trạng thái:** Xong — `docs/detailed-design/06-call-control.md` (4 chức năng lá, ~1 070 dòng).

## Cần bổ sung vào 00-common-specs

1. `call_event/state` thêm `sub_id`, `sim_label`, `waiting_number`, `waiting_display_name`;
   `log_new` thêm `call_id`; ack `log_sync` thêm `reset`.
2. 0.7.2: `features.call.notify` (iOS gửi; Android chỉ push cuộc gọi khi `true`).
3. 0.8.1: `CALL_ACTION_NOT_ALLOWED.details.reason` ∈ {state, waiting, platform, system};
   `CALL_HFP_REQUIRED.details.action`.
4. 0.9.5: `call.ringtone` (Mac, `true`), `call.quick_replies` (Mac, ≤ 6 mẫu × 160 ký tự).
5. 0.10 đề xuất: `CALL_REJECT_BG_TIMEOUT` 15 s, `CALL_HFP_CMD_TIMEOUT` 2 s, khóa thao tác 3 s, ghép
   nhật ký ±5 s/60 s.
6. CONN-04 API 4: nội dung mặc định theo `reason`; collapse `calllog:<entry_id>`.

## Giả định

- Thông báo nhỡ: có `READ_CALL_LOG` → từ `log_new`; không → từ `state`.
- Một `state` idle hiệu chỉnh (`rejected`/`answered_elsewhere`) từ nhật ký.
- Khi `waiting`, mọi lệnh WS bị chặn.
- Danh mục thông báo iOS do I-NSE đặt (như SMS-02).

## Cần xác nhận

- Listener theo từng SIM có báo đúng SIM đổ chuông trên máy thật?
- `_ID` của CallLog không bị cấp lại?
- `INFocusStatusCenter` trên macOS cần capability nào?
