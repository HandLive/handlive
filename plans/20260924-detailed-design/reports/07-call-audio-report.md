# Báo cáo 07-call-audio

**Trạng thái:** Xong — `docs/detailed-design/07-call-audio.md` (4 lá, 714 dòng). Mỗi lá đủ 5 mục; 4
lưu đồ Mermaid hợp lệ (ND trước HT, nhãn `"(n) …"`, số bước khớp bảng, không dấu chấm phẩy/ký tự
lạ).

## Bám quyết định
- C13/D10: HFP chính (Mac HF `IOBluetoothHandsFreeDevice`, Android AG stack chuẩn); nêu rõ
  `BluetoothHeadsetClient` không dùng cho AG, Shizuku chỉ cho AUDIO-04. Spike D1 (go/no-go, chưa có
  báo cáo trực tiếp) ghi trung thực; không bịa cách macOS đưa SCO tới app.
- C14/D11: HFP chỉ mã hóa liên kết BT (rủi ro KNOB/BIAS công bố ở AUDIO-01); Opus/WS hai lớp.
- Bảng khả thi Android 10/11–12/13+; Pixel 8/9 thu được, S22 Ultra im lặng; injection "chưa kiểm
  chứng"; rủi ro Play "call recorder".

## Trường/mã mới (đề xuất thêm 0.7.1)
- `call_audio/open`: req `direction` {both|downlink}; ack
  `session_id, stream_path, downlink, uplink`.
- `call_audio/close`: `reason`{user|switch_to_hfp|call_ended|error}.
- `call_event/hfp_status` thêm `active_device_name, codec`.
- `consent_record.text_version` = `call-audio-v1`.

## Cần xác nhận
- `consent_record` chỉ ở Mac; Android cần cờ capability để biết đã chấp thuận (đề xuất
  `features.call_audio.consented`)?
- Tên method chuyển âm thanh của `IOBluetoothHandsFreeDevice` bỏ trống chờ spike D1.
- Rủi ro xét duyệt Play cần luật sư/hồ sơ khai báo xác nhận.
