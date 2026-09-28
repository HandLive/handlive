[English](phase-06-web-handoff.md) | Tiếng Việt

# Phase 6 — Duyệt web tiếp

**Mục tiêu:** trang web đang mở trên một thiết bị được xem tiếp trên thiết bị khác chỉ bằng một lần
bấm hoặc chạm: trang của điện thoại trên Mac (mục menu) và trên iPhone/iPad (banner khi ứng dụng đang
mở), trang của Mac trên điện thoại (thông báo). Trang đang mở được phát hiện tự động; trang riêng tư
không bao giờ được gửi và không trang nào được lưu.

Trạng thái: chủ dự án đề xuất ngày 28/09/2026 (`plans/20260928-web-handoff/plan.md`). Phase 6 chỉ cần
hạ tầng Phase 1 (phiên, E2E, capability) và không phụ thuộc Phase 4 và 5.
Quyết định của chủ dự án ngày 28/09/2026: Phase 5 và 6 làm xong trước khi Phase 4
hoàn tất (Phase 4 chờ spike phần cứng HFP của cổng G4).

## Cổng G6 — spike (3–5 ngày, trước mọi thẻ việc khác)

Câu hỏi: có đọc được ổn định trang đang mở của từng trình duyệt ứng viên không, và có luôn phân biệt
được trang riêng tư không?
- Android: id node thanh địa chỉ và cách nhận biết ẩn danh cho Chrome, Samsung Internet, Firefox, Edge
  và Brave trên API 29 và API 35; cách dịch vụ biết trình duyệt đã rời foreground khi có bộ lọc
  `android:packageNames` (WEB-01 API 3 logic 4); chi phí pin và CPU của dịch vụ khi bật bộ lọc.
- Mac: Apple Events cho Safari, Chrome và Arc trên macOS 13 và macOS 26; nhận biết cửa sổ riêng tư của
  Safari (và của Arc); hộp thoại TCC và mã từ chối với bản ký Developer ID có hardened runtime.
- Google Play: văn bản chính sách Hỗ trợ tiếp cận hiện hành cho mục đích này và khai báo cần có.
- Kết quả trong `reports/phase-06-spike-g6.md`: bảng đạt/không đạt theo trình duyệt và nền tảng, id
  thanh địa chỉ, tín hiệu trạng thái riêng tư, số đo pin. Trình duyệt không đạt được ghi vào
  `docs/detailed-design/09-web-handoff.md` (cả hai ngôn ngữ) trước khi bắt đầu thẻ nào khác. Không
  trình duyệt nào đạt → dừng Phase 6 và viết báo cáo.

## Ngữ cảnh

- Chức năng lá: `09-web-handoff.md` WEB-01…05 (quy tắc nhóm QW1–QW9); `01-setup-settings.md` SET-01
  phần B, SET-02 trường 34–37 và API 1 (ánh xạ capability); common specs 0.7.1 (loại `web`, mã trình
  duyệt), 0.7.2 (`features.web`), 0.9.5 (`feature.web`, `web.*`), 0.10 (`WEB_*`).
- Quyết định: C21 (README §5), C15 (mẫu công bố Hỗ trợ tiếp cận), C20 (chuỗi giao diện).
- Design system: `MenuBarMenu` (dạng có huy hiệu của biểu tượng trạng thái và mục đầu tiên cho trang),
  `Notification` (kênh `hl_web`), `PermissionPrimer`/màn hình công bố, `Toggle` (dòng cài đặt).
- Đề xuất: `plans/20260928-web-handoff/plan.md` W1–W9.

## Yêu cầu và tiêu chí đo

- Chỉ gửi trang khi URL đã ổn định trong `WEB_SETTLE` (1,5 s) và không bao giờ gửi khi thanh địa chỉ
  có focus; Mac đọc mỗi `WEB_POLL_MAC` (1,5 s) chỉ khi một trình duyệt được hỗ trợ ở trước nhất và
  chiều này hiệu lực; khi trang vẫn mở, bên gửi gửi lại mỗi `WEB_REFRESH` (5 phút) với cùng
  `page_id`.
- Không trang riêng tư hay ẩn danh nào được gửi trong toàn bộ ma trận kiểm thử; trạng thái riêng tư
  không xác định thì không bao giờ gửi.
- Bên nhận quên trang sau `WEB_PAGE_TTL` (10 phút) không được làm mới, khi có `web/inactive` và khi
  phiên kết thúc; không ghi gì xuống đĩa hay log (kiểm bằng review và một test tìm trong log).
- Bên nhận chỉ mở `http`/`https`, chỉ khi bấm hoặc chạm, và hiện đầy đủ host, dùng punycode cho nhãn
  trộn nhiều hệ chữ.
- Tính năng mặc định tắt trên mọi nền tảng; chi phí pin của dịch vụ Android được ghi ở G6 và được chủ
  dự án chấp nhận.

## Thẻ việc

| Mã | Việc | Đầu ra | Tiêu chí chấp nhận |
|----|------|--------|--------------------|
| T6.0 [test] | Spike cổng G6 (ở trên): probe dùng một lần cho Android (một `AccessibilityService` in ra node thanh địa chỉ và tín hiệu riêng tư theo trình duyệt) và cho Mac (script của WEB-03 API 1 và `AEDeterminePermissionToAutomateTarget`); kiểm chính sách Play. Đầu vào: plan W8, WEB-01 API 3–4, WEB-03 API 1–3 | `reports/phase-06-spike-g6.md`; probe chỉ nằm trên nhánh spike, không bao giờ gộp | Ghi đạt/không đạt theo trình duyệt; spec liệt kê trình duyệt bị loại; đã chọn cơ chế phát hiện rời foreground trên Android |
| S6.1 [shared] | Dữ liệu đặc tả: `web-active.schema.json`, `web-inactive.schema.json`, `web` trong enum `type` của envelope, `features.web {enabled, send, receive}` trong schema capability, enum mã trình duyệt; mẫu dương và mẫu âm; `check_schemas.py` kiểm các ví dụ `web` của `09-web-handoff.md`; chuỗi giao diện của nhóm 9 và SET-02 trường 34–37 trong `ui-strings.json` (thêm nhóm `web` vào quy tắc catalog). Đầu vào: 0.7.1, 0.7.2, 0.12, WEB-01…05 | `shared/schemas/`, `shared/tools/schemas/`, `shared/strings/` | `check_schemas.py` và `check_strings.py` xanh với `main` của hub; báo các nền tảng khác chạy lại test |
| A6.1 [android] | Giao thức và phía nhận: model `web/active` và `web/inactive`, kiểm hợp lệ (QW7, QW8), kho bản mới nhất thắng theo cặp trong bộ nhớ với `WEB_PAGE_TTL`, kênh `hl_web` và thông báo WEB-04 (`ACTION_VIEW`, bản trên màn hình khóa), khóa cài đặt `feature.web`, `web.notify`, ánh xạ capability (SET-02 API 1). Đầu vào: WEB-04, 0.7, 0.9.5 | `android/feature/web`, `android/core/protocol` | WEB-04 E1–E4 có test; test punycode và scheme; `receive = false` khi tắt thông báo |
| A6.2 [android] | Phía gửi: `BrowserPagesAccessibilityService` (`@xml/a11y_browser_pages`, bộ lọc gói theo G6), một `BrowserAdapter` cho mỗi trình duyệt đạt G6, chuẩn hóa, `WEB_SETTLE`, nhận biết riêng tư, quy tắc `web/inactive`, gửi lại sau trao đổi capability; màn hình công bố (WEB-01 trường 2–4), thẻ tính năng, SET-02 trường 34, 35, 37, `web.a11y_consent_at`. Đầu vào: WEB-01, SET-01 phần B | `android/feature/web`, `android/app` (manifest, xml) | WEB-01 E1–E10 có test hoặc test thủ công được ghi lại; dịch vụ bảng nhớ tạm vẫn có `canRetrieveWindowContent = false`; không xử lý sự kiện nào khi không có phiên hiệu lực |
| M6.1 [macOS] | Phía nhận: WEB-02 — dạng có huy hiệu của biểu tượng thanh menu, mục menu đầu tiên có dòng host và ⌘O, thông báo tùy chọn (`web.notify`), `NSWorkspace.open`, dọn khi hết TTL và khi phiên kết thúc; dòng Cài đặt cho `feature.web` và `web.notify`. Đầu vào: WEB-02, SET-02 | `apple/macOS/HandLive`, `apple/Packages/…` (model web dùng chung với iOS) | WEB-02 E1–E6 có test; VoiceOver đọc được mục menu và nhãn huy hiệu |
| M6.2 [macOS] | Phía gửi: WEB-03 — theo dõi kích hoạt ứng dụng, khóa và ngủ, vòng đời đọc định kỳ, script theo trình duyệt đạt G6, kiểm chế độ riêng tư, `WEB_SETTLE`, trạng thái Tự động hóa và "Mở Cài đặt hệ thống", `NSAppleEventsUsageDescription`, entitlement `com.apple.security.automation.apple-events`; dòng Cài đặt cho `web.send` và `web.browsers`. Đầu vào: WEB-03, SET-02 | `apple/macOS/HandLive`, `apple/project.yml` | WEB-03 E1–E7 có test hoặc test thủ công được ghi lại; không đọc định kỳ khi không có trình duyệt được hỗ trợ ở trước nhất |
| I6.1 [iOS] | WEB-05: banner phủ lên đầu tab đang hiển thị, đóng được cho tới khi có `page_id` mới, `UIApplication.open`, dọn khi xuống nền và hết TTL; công tắc "Duyệt web tiếp"; capability `send = false`, `receive = feature.web`. Đầu vào: WEB-05, SET-02 | `apple/iOS/HandLive` | WEB-05 E1–E3 có test; kiểm Dynamic Type AX5 và VoiceOver |
| T6.1 [test] | Ma trận đầu-cuối: Android → Mac, Android → iPhone, Mac → Android qua LAN và relay; tab riêng tư trên mọi trình duyệt được hỗ trợ; tắt màn hình, khóa, ngủ; gửi lại khi kết nối lại; TTL; trang chỉ mở khi chạm; TalkBack/VoiceOver; en và vi | kịch bản `shared/tools/e2e/`, `reports/phase-06-T6.1.md` | Đạt mọi tiêu chí ở trên; không trang riêng tư nào bị gửi |

## Nhánh và thứ tự làm

- Nhánh `feat/phase-06-web-handoff` trong handlive-shared, handlive-android và handlive-apple (và hub cho
  thay đổi spec phát hiện trong lúc làm). handlive-relay không cần đổi: relay chuyển envelope `web` như
  mọi loại khác và không bao giờ push chúng.
- T6.0 đi trước và đi một mình. Sau đó S6.1 (mọi thẻ giao diện chờ chuỗi của nó), rồi song song Android
  (A6.1 → A6.2) và Apple (model `web` dùng chung, rồi M6.1 → M6.2 → I6.1), cuối cùng T6.1.

## Kiểm thử

- Unit: chuẩn hóa và kiểm hợp lệ URL, hiển thị punycode, bộ hẹn giờ ổn định, bản mới nhất thắng theo
  `observed_at`, hết hạn TTL, ánh xạ capability theo nền tảng.
- Thủ công: từng trình duyệt được hỗ trợ với tab thường và tab riêng tư; bản cập nhật trình duyệt dời
  thanh địa chỉ (E5); Tự động hóa bị từ chối rồi được cho phép trong Cài đặt hệ thống.

## Rủi ro và phương án lùi

- Google Play từ chối việc dùng Hỗ trợ tiếp cận → phía gửi trên Android chỉ có trong bản F-Droid và APK
  (plan W3); phía nhận trên Android vẫn chạy ở mọi bản.
- Bản cập nhật trình duyệt đổi view của thanh địa chỉ → bộ chuyển đổi đóng an toàn (không gửi gì, E5);
  sửa theo từng trình duyệt, không đụng giao thức.
- Không nhận biết được cửa sổ riêng tư của Safari → Safari không được hỗ trợ trên Mac (không bao giờ gửi
  trạng thái không xác định).
