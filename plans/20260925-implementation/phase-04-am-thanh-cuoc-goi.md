# Phase 4 — Nghe gọi trên Mac

**Mục tiêu:** nghe và nói cuộc gọi di động trên Mac qua Bluetooth HFP (đường chính), dự phòng
Opus/WebSocket qua Shizuku; chuyển âm thanh qua lại giữa Mac và điện thoại; giữ máy, DTMF, tắt tiếng
bằng lệnh HFP.

## Cổng G4 — spike D1 (tuần đầu, làm trước mọi thẻ việc khác)

Câu hỏi: `IOBluetoothHandsFreeDevice` ở vai HF trên macOS có nhận và phát được âm thanh SCO của cuộc
gọi di động không, và macOS phơi bày luồng đó cho ứng dụng bằng cách nào?
- Máy: Mac Apple silicon macOS 26, Mac macOS 13 hoặc 14; điện thoại Pixel và Samsung; kèm AirPods để
  thử xung đột.
- Kết quả cần ghi (`reports/phase-04-spike-d1.md`): kết nối service-level, mở SCO, nghe được âm hai
  chiều, tên thiết bị âm thanh xuất hiện, độ trễ, lỗi theo phiên bản macOS.
- Đi tiếp khi nghe và nói được trên ít nhất một cặp Mac–điện thoại ở macOS 26 và một ở macOS 13/14.
  Không đạt → Opus/WS thành đường chính (D1 dual-path), HFP chỉ giữ lệnh AT cho điều khiển; cập nhật
  AUDIO-02, plan D1, roadmap.

## Ngữ cảnh

- Chức năng lá: `07-call-audio.md` AUDIO-01 (công bố `call-audio-v1`, quyền Bluetooth và micro),
  AUDIO-02, AUDIO-03, AUDIO-04; `06-call-control.md` CALL-03 (hold, DTMF, mute qua HFP).
- Design system: `ConsentSheet` (nghe gọi trên Mac), `CallPanel` trạng thái nối Bluetooth,
  `PermissionPrimer`.
- Quyết định: D1, D2, D3, D10/C13, D11/C14; `docs/code-standards.md` (abstraction `CallAudioRelay`,
  strategy OEM).

## Yêu cầu và tiêu chí đo

- MOS ≥ 3,5 qua HFP, ≥ 3,0 qua Opus/WS; echo return loss > 40 dB với loa ngoài; trễ SCO ~40 ms,
  Opus/WS 100–150 ms.
- Công bố hiển thị trước lần bật đầu, lưu `text_version`, `accepted_at`; không ghi âm ở bất kỳ thành
  phần nào.
- Đường HFP: chỉ mã hóa liên kết Bluetooth (D11), rủi ro KNOB/BIAS đã công bố; đường Opus/WS: TLS +
  E2E.

## Thẻ việc

| Mã | Việc | Đầu ra | Tiêu chí chấp nhận |
|----|------|--------|--------------------|
| M4.1 [macOS] | AUDIO-01: `ConsentSheet` với văn bản `call-audio-v1`, xin quyền Bluetooth và micro (mỗi quyền một màn "Tiếp tục"), chọn điện thoại HFP, lưu `consent_record` | `apple/macOS/HandLive` | Đổi `text_version` thì hỏi lại; từ chối micro → chỉ nghe (E7) |
| M4.2 [macOS] | `CallAudioRelay` protocol + `HfpCallAudioRelay` bọc `IOBluetoothHandsFreeDevice` (theo kết quả spike), `AUVoiceProcessingIO` (AEC, NS, AGC), chuyển âm thanh (AUDIO-03), lệnh AT cho hold/DTMF/mute (CALL-03) | `apple/Packages/HLCallAudio` | Không gọi `IOBluetooth*` ngoài package; MOS và ERL đo được |
| M4.3 [macOS] | `OpusWsCallAudioRelay`: libopus qua SwiftPM/C bridge, jitter buffer thích ứng 20–60 ms, kênh `/v1/stream/callaudio` khung HL, chuyển tự động khi HFP lỗi (E3, E4) | package | Trễ đầu-cuối ≤ 150 ms; chuyển đường không rớt cuộc gọi |
| A4.1 [android] | `bt-hfp-manager`: `BluetoothHeadset` proxy và broadcast, `call_event/hfp_status`, so khớp Mac theo địa chỉ; strategy OEM (`SamsungBtAdapter`, `PixelBtAdapter`, `GenericBtAdapter`) | `android/feature/callaudio` | Trạng thái đúng trên Pixel, Samsung, Xiaomi |
| A4.2 [android] | AUDIO-01 phía Android: bật `feature.call_audio`, `BLUETOOTH_CONNECT`, capability `opus_fallback` với `reason` | `android/feature/callaudio` | Capability đúng theo phiên bản Android và Shizuku |
| A4.3 [android] | `OpusWsCallAudioRelay` qua Shizuku UserService: `AudioRecord` `VOICE_CALL`/`VOICE_DOWNLINK` (Android 11+), dò 2 giây im lặng (`capture_silent`), chèn giọng `getCallUplinkInjectionAudioTrack` (Android 13, kiểm chứng trên máy thật), Opus 16 kHz 32 kbps; giới hạn ghi vào deployment-guide theo máy | `android/feature/callaudio` | Ma trận ≥ 6 máy: bảng thu được/không; không bao giờ để rơi cuộc gọi khi thất bại |
| T4.1 [test] | Đo MOS (POLQA hoặc PESQ với mẫu chuẩn), ERL, trễ; kịch bản AirPods giữ SCO, ra khỏi tầm Bluetooth (E5), mất phiên WebSocket giữa cuộc gọi | `tools/bench/`, `reports/` | Đạt mục tiêu; mọi kịch bản kết thúc với âm thanh về điện thoại, không mất cuộc gọi |

## Kiểm thử

- Đơn vị: máy trạng thái tuyến âm thanh (`phone`, `mac_hfp`, `mac_ws`), hàng đợi DTMF chờ `OK`,
  jitter buffer.
- Pháp lý: ảnh chụp công bố và bản ghi `consent_record` trong báo cáo; không có đường "gửi không mã
  hóa" (Opus/WS).

## Rủi ro và quay lui

- Spike D1 thất bại → xem cổng G4. `IOBluetoothHandsFreeDevice` bị deprecate về sau → chỉ
  `HLCallAudio` phải đổi.
- Android 10 không thu được (E2) → tính năng ẩn với máy đó, thông báo rõ.
