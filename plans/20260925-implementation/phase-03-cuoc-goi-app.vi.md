[English](phase-03-cuoc-goi-app.md) | Tiếng Việt

# Phần mở rộng Phase 3 — Cuộc gọi của app khác trên Mac (CALL-05)

**Mục tiêu:** khi một app gọi điện đổ chuông trên điện thoại (trước mắt là Telegram; Zalo, WhatsApp làm sau), Mac hiện
ai đang gọi và từ app nào. Người dùng nghe, từ chối hoặc kết thúc được ngay trên Mac. Âm thanh sang Mac khi Bluetooth
HFP cho phép, nếu không thì ở lại điện thoại.

Trạng thái: chủ dự án duyệt thiết kế ngày 2026-10-01 (`reports/phase-03-app-calls-brainstorm.vi.md`). Nhánh
`feat/phase-03-app-calls`. Không bị chặn bởi G4/G5/G6; chỉ phần âm thanh trên Mac phụ thuộc vào spike bên dưới và vào
đường âm thanh HFP của Phase 4. Lập theo kiểu viết test trước.

## Spike T3.2 (1–2 ngày, trước mọi thẻ khác; chủ dự án gọi Telegram để thử)

Mỗi câu hỏi có go/no-go riêng:
1. Một `NotificationListenerService` thấy được các thông báo `CallStyle` của Telegram (đổ chuông `callType=1`, đang
   gọi `callType=2`): người gọi, `declineIntent`, `answerIntent`, `hangUpIntent`, và thấy thông báo bị gỡ khi cuộc gọi
   kết thúc. Theo dõi ngày 2026-10-01 cho thấy lúc đang gọi, Telegram dùng thông báo kênh `Other3` không có `CallStyle`
   → phải kiểm nút Kết thúc trong các action thường của thông báo đó.
2. HandLive gửi được `declineIntent`, `answerIntent` (mở activity, gửi kèm
   `ActivityOptions.setPendingIntentBackgroundActivityStartMode(ALLOW_ALWAYS trên API 36+, ALLOWED trên 34–35)`) và nút kết thúc khi đang chạy nền — với màn
   hình bật, tắt, và khi đã khóa.
3. Sau khi nghe máy, HandLive gọi `AudioManager.setCommunicationDevice(<thiết bị bt_sco là Mac>)` trong lúc Telegram
   đang giữ cuộc gọi, và kênh SCO tới Mac mở được (`HFPSpike` đang kết nối: có `sco_opened`, có thiết bị Core Audio),
   hai bên nghe được nhau.
4. Đo thời gian cho AC1–AC4: thông báo đăng → listener nhận; gửi intent → trạng thái đổi; yêu cầu chuyển tuyến → SCO
   mở.

Kết quả ghi vào `reports/phase-03-app-calls-spike.md`. Probe: `android/tools/call-spike/` (chỉ bản debug, giống
`tools/web-spike`). Câu 1 hoặc 2 thất bại → dừng và báo cáo. Câu 3 thất bại → v1 phát hành với âm thanh trên điện thoại
(phương án lùi của AC4), phần âm thanh chờ một đường khác.

## Bối cảnh

- Thiết kế: `reports/phase-03-app-calls-brainstorm.vi.md`.
- Leaf function:
  - `06-call-control.md` CALL-01…04 (quy tắc nhóm, không dùng `InCallService`, C12);
  - common specs 0.7.1 (các op của `call_event`), 0.7.2 (`features.call`), 0.8 (lỗi `CALL_*`), 0.9.5 (`feature.call`,
    `call.notify`);
  - SET-01/SET-02; `07-call-audio.md` AUDIO-02 (HFP trên Mac).
- Code:
  - Android `feature/call` (`module/CallActions.kt`, `CallBroadcaster.kt`, `CallModule.kt`, `CallAccess.kt`) và
    capability trong `core/transport` (`EffectiveFeatures.kt`);
  - Apple `Packages/HLCalls` (`CallsModel.swift`) và các panel cuộc gọi trên macOS;
  - `shared/schemas/call_event-*.schema.json`, schema `capability`, `shared/strings/ui-strings.json`.
- Bằng chứng (2026-10-01, S25 Android 16 + macOS 27):
  - Telegram đăng `CallStyle` có intent từ chối (broadcast) và nghe (activity).
  - Cuộc gọi của nó không được báo qua HFP, và âm thanh ở lại điện thoại.
  - App khác không thu được âm thanh VoIP.

## Yêu cầu và tiêu chí đo được (LAN, phân vị 95)

| # | Tiêu chí |
|---|---|
| AC1 | Panel trên Mac hiện ≤ 400 ms sau khi app đăng thông báo cuộc gọi (riêng Android đã mất 215–232 ms để chuyển thông báo, spike T3.2), có tên app và tên người gọi |
| AC2 | Từ chối hoặc Kết thúc từ Mac có hiệu lực trên điện thoại ≤ 500 ms |
| AC3 | Nghe từ Mac làm điện thoại bắt máy ≤ 1 s khi HandLive được miễn hạn chế mở activity từ nền (Accessibility service của nó đang bật); nếu không, điện thoại hiện thông báo "chạm để nghe" của HandLive |
| AC4 | Có HFP và câu 3 của spike đạt: âm thanh trên Mac ≤ 1,5 s sau khi bấm Nghe; nếu không thì âm thanh ở điện thoại và panel ghi rõ |
| AC5 | Không thông báo nào khác rời điện thoại; log không bao giờ chứa tên hay số |
| AC6 | Thiếu quyền Truy cập thông báo thì tính năng tắt và có giải thích; tính năng cuộc gọi di động (CALL-01…04) không bị ảnh hưởng |

Relay: cố gắng tốt nhất. Ngoài phạm vi: iPhone/iPad, gọi đi từ Mac, nhật ký cuộc gọi app, cuộc gọi video.

## Thẻ việc

Cột "Test viết trước" liệt kê những gì phải được viết và commit (ở trạng thái đỏ) trước code của thẻ đó.

| Mã | Việc | Test viết trước | Đầu ra | Tiêu chí nghiệm thu |
|------|------|-------------|---------|---------------------|
| T3.2 [test] | Spike (ở trên) | — (đo đạc) | `reports/phase-03-app-calls-spike.md`; `android/tools/call-spike/` | Go/no-go cho từng câu; đã ghi thời gian |
| D3.1 [docs] | Spec, cả hai ngôn ngữ. **Leaf:** CALL-05 trong `06-call-control.md` (5 mục; ngoại lệ trong quy tắc nhóm cho cuộc gọi app: chỉ dùng thông báo, không `InCallService`). **Common specs:** op `call_event/app_call` (S→C) và dữ liệu của nó; `call_event/action` cho `call_id` của cuộc gọi app; capability `features.call.app_calls`; mã lỗi khi thông báo thiếu nút; cài đặt `call.app_calls`; hằng số (timeout chuyển tuyến). Màn hình giải thích quyền Truy cập thông báo ở SET-01, dòng cài đặt ở SET-02, chuỗi giao diện | — (hợp đồng) | `docs/detailed-design/06-call-control*.md`, `00-common-specs*.md`, `01-setup-settings*.md` | `validate_design_docs.py` `problems=0`; `check_bilingual_docs.py` xanh |
| S3.4 [shared] | `call_event-app_call.schema.json`, enum capability và lỗi, mẫu dương/âm, chuỗi giao diện (en, vi) | Chính các mẫu là test; `check_schemas.py`, `check_strings.py` | `shared/schemas/`, `shared/strings/` | Cả hai kiểm tra xanh; báo các nền tảng chạy lại |
| A3.3 [android] | `AppCallListenerService` (`NotificationListenerService`): bộ lọc bỏ trình gọi điện mặc định, trình gọi điện hệ thống, các ứng dụng `InCallService` và dịch vụ telecom (cuộc gọi di động thuộc CALL-01…04); với các gói khác chỉ `CallStyle` mới tạo ngữ cảnh, `category=call` chỉ được ghép làm thông báo đang gọi; bộ đọc ra ngữ cảnh cuộc gọi app (package, tên app, người gọi, trạng thái, các nút có sẵn); lưu theo khóa thông báo; kết thúc khi thông báo bị gỡ | Test bộ đọc trên fixture đóng gói sẵn (Telegram đổ chuông/đang gọi, `category=call` không có `CallStyle`, thông báo thường bị bỏ qua); test quyền riêng tư (log không có tên người gọi) | `android/feature/call` (gói mới `appcall/`), service trong manifest với `BIND_NOTIFICATION_LISTENER_SERVICE` | Test xanh; thông báo không phải cuộc gọi không bao giờ ra khỏi listener |
| A3.4 [android] | Bộ phát và broadcast: gửi `call_event/app_call` tới các phiên có `app_calls` hiệu lực; định tuyến `call_event/action` theo `call_id` (telephony hay app); gửi PendingIntent kèm tùy chọn mở từ nền; nghe với `audio = mac` → `setCommunicationDevice` (nếu câu 3 của T3.2 đạt), có timeout và phương án lùi | Test hồi quy cho action telephony (`CallActions`) trước khi đổi phần định tuyến; test bộ phát với intent giả; test chặn theo capability (`FEATURE_DISABLED`) | `android/feature/call`, `android/core/transport` (capability) | Test cuộc gọi telephony không đổi; đo AC2/AC3 trên S25 |
| A3.5 [android] | Luồng thiết lập và cài đặt: màn hình giải thích quyền Truy cập thông báo và đường dẫn sâu tới cài đặt, công tắc `call.app_calls`; capability `app_calls` = cài đặt ∧ quyền | Test tính capability (có/không quyền, bật/tắt cài đặt) | `android/app`, `android/feature/call` | AC6 |
| M3.4 [macOS] | `HLCalls`: giải mã `call_event/app_call`, model cuộc gọi app và chuyển trạng thái, gửi action, khai báo `app_calls` | Test giải mã trên mẫu của `shared`; test chuyển trạng thái | `apple/Packages/HLCalls`, `apple/Packages/HLTransport` (capability) | Test xanh; iOS khai báo `app_calls = false` |
| M3.5 [macOS] | Panel: biến thể cuộc gọi đến/đang gọi có tên app; Nghe (âm thanh trên Mac khi có HFP và chuyển tuyến được, nếu không thì có ghi chú), Từ chối, Kết thúc; dòng cài đặt; chuỗi; VoiceOver | Test model giao diện cho việc nút nào có theo từng trạng thái và từng nút sẵn có | `apple/macOS/HandLive`, `apple/Packages/HLMacUI` | AC1, ghi chú của AC4; VoiceOver đọc được panel |
| T3.3 [test] | Đầu-cuối với Telegram trên S25 và Mac này: đo AC1–AC6 bằng bench log; grep log tìm tên; trường hợp thiếu quyền (cả bản cài ngoài Play trên Android 13+: cài đặt bị hạn chế); đường relay. Kịch bản: từ chối ngay trên điện thoại; người gọi cúp máy khi đang đổ chuông; thông báo đang diễn ra không liên quan của cùng ứng dụng trong lúc đổ chuông không bị ghép; panel hiện tên ứng dụng ("Telegram"), không phải tên gói; trên điện thoại **có SIM**, cuộc gọi di động không sinh `app_call` | Viết trước các kịch bản e2e | `reports/phase-03-app-calls-T3.3.md` | Đạt AC1–AC6, hoặc báo cáo phần thiếu theo số đo |

## Nhánh và thứ tự làm

- `feat/phase-03-app-calls` trong hub, handlive-shared, handlive-android, handlive-apple.
- T3.2 làm trước và làm riêng → D3.1 → S3.4 → A3.3 ∥ M3.4 → A3.4 → A3.5 ∥ M3.5 → T3.3.
- Mỗi bước logic một commit; `shared/` trước các nền tảng; không bao giờ một commit trải qua hai repository.

## Kiểm thử

- Viết test trước cho từng thẻ (commit đỏ trước code); test hồi quy cho hành vi cuộc gọi telephony trước mọi thay đổi ở
  `CallActions`/định tuyến.
- Cổng hồi quy sau mỗi thẻ:
  - Android: `./gradlew check`.
  - Apple: `swift test` (HLCalls, HLMacUI, HLTransport) và `xcodebuild test`.
  - Hub: `validate_design_docs.py`, `check_bilingual_docs.py`.
  - Shared: `check_schemas.py`, `check_strings.py`.

## Rủi ro và phương án lùi

- Không được mở activity từ nền cho `answerIntent` → dùng một trampoline activity của HandLive, hoặc thông báo toàn màn
  hình trên điện thoại; T3.2 quyết định.
- Android bỏ qua yêu cầu chuyển thiết bị liên lạc của HandLive → cuộc gọi app không có âm thanh trên Mac (phương án lùi
  của AC4).
- App không dùng `CallStyle` → không hỗ trợ cho tới khi có adapter riêng cho app đó; liệt kê trong báo cáo spike.
- Truy cập thông báo là quyền rộng → lọc chặt, có lời giải thích, có văn bản khai báo cho Play; có thể tắt tính năng
  bằng `call.app_calls`.
