# Nhật ký thay đổi

Các thay đổi đáng chú ý của kho hub HandLive (tài liệu và kế hoạch) được ghi trong file này.

Định dạng theo [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [Unreleased]

### Added

- iPhone và iPad giữ phiên tối đa `IOS_BACKGROUND_GRACE` (25 giây, hoặc thời gian iOS cho trừ 5 giây) sau khi ứng dụng
  vào nền, thay vì đóng ngay (CONN-02 E3, 00-common-specs): chuyển nhanh sang ứng dụng khác không còn làm mất kết nối.
  Thao tác từ thông báo dùng chung việc giữ phiên này; clip đến trong lúc giữ chỉ được ghi khi người dùng chưa sao chép
  gì mới (CLIP-04 E2, `changeCount`); SMS và cuộc gọi trong khoảng đó hiện thông báo cục bộ theo cùng luật nội dung như
  đường push. Đồng bộ nền lâu hơn thì iOS không cho phép: báo SMS và cuộc gọi khi ở xa cần relay và APNs (gate G2).
  Mã: apple #4.
- Android, Tự gửi khi sao chép (SET-02 trường 39, E10): bấm công tắc khi đang báo "Chưa bật tự gửi" sẽ mở bảng tác vụ
  (Bật, Gửi thủ công, Hủy) thay vì lặng lẽ tắt tự gửi. Chuỗi: handlive-shared#5; mã: android #7.

- Bảng nhớ tạm HTML (CLIP-01 API 5 `html`, 0.7.2 `text/html` trong `features.clipboard.mimes`, 0.10 `CLIP_MAX_HTML`): clip
  chữ mang kèm HTML đã lọc của chính nó khi đối phương liệt kê `text/html`, nên bài báo sao chép trong trình duyệt trên điện
  thoại dán vào Notes, Pages, Word hay Mail có đủ tiêu đề, liên kết và ảnh (ứng dụng dán tự tải từ URL). Hai đầu chạy cùng
  `HtmlClipSanitizer`, chốt bằng `shared/test-vectors/clipboard-html.json`; định danh, vòng lặp, xung đột và luật nội dung nhạy
  cảm vẫn chỉ nhìn chữ thuần. Kế hoạch: `plans/20261005-clipboard-html/plan.md`.
- `release-collect` (workflow của hub): APK, IPA iOS và DMG Mac của một tag phiên bản, kèm SHA-256, được chép từ
  Release của handlive-android và handlive-apple sang Release của hub sau khi kiểm checksum, để người dùng tải mọi
  nền tảng ở một trang (`docs/deployment-guide.vi.md`, Bản phát hành). Đã làm cho `v0.1.0-beta.2`.

### Changed

- Website: huy hiệu trang chủ ghi `v0.1.0-beta.2` và mở trang phát hành của nó; `docs/website.vi.md` thêm nó vào các
  chỗ cần đổi mỗi lần phát hành.

### Fixed

- Thiết lập, SET-01 (en và vi): điện thoại Android 13+ cài HandLive ngoài Google Play không còn im lặng khi chế độ cài
  đặt hạn chế của Android giữ dịch vụ Hỗ trợ tiếp cận (tự gửi bảng nhớ tạm) hoặc Truy cập thông báo (cuộc gọi từ ứng
  dụng khác) ở trạng thái tắt. Người dùng quay về từ trang hệ thống đó mà chưa bật HandLive sẽ thấy lại trường 14, mỗi
  lượt quay về một lần, với nút Mở cài đặt tới Thông tin ứng dụng; lời giải thích chỉ hỏi đồng ý một lần (SET-02
  trường 2, CLIP-01 A1), và lần Đồng ý đầu tiên không còn bị mất khi màn giải thích đóng. HandLive không đọc được kết
  luận của Android (app op cần `GET_APP_OPS_STATS`, Android 15 trả `SecurityException`), nên quy tắc vẫn dựa vào nguồn
  cài. Mã: android #6. Báo cáo:
  `plans/20260925-implementation/reports/restricted-settings-detect-2026-10-05.md`.
- Bảng nhớ tạm, CLIP-01 API 2 logic 2 và CLIP-03 API 1 logic 1 (en và vi): item Android có URI là ảnh thì là bức
  ảnh đã sao chép, kể cả khi ứng dụng nguồn đặt URL ảnh, chữ thay thế hay chuỗi rỗng bên cạnh; trước đây luật văn
  bản đứng trước nên các bản sao như vậy bị gửi thành chữ hoặc bị bỏ. CLIP-03 E10: URI mà clipboard không cho điện
  thoại đọc được báo khi bấm Gửi bảng nhớ tạm ("Không đọc được ảnh") và ghi `clip_read_failed` ở bản debug. Mã:
  android `fix/clipboard-image-item-precedence`; e2e cho ảnh điện thoại → Mac: shared `feat/e2e-phone-to-mac-image`.
  Điều tra: `plans/20261005-clipboard-image-sync-fix/plan.md`.
- Xóa tất cả trên Mac xóa khóa HandLive ở cả hai keychain (SET-02 API 7 logic 6, en và vi), nên người dùng đã chạy cả
  bản tải về ký ad-hoc (login keychain) lẫn bản ký team (data-protection keychain) không còn `ik_sig`, `ik_dh`,
  `db_key` hay khóa cặp của bản nào; mục trong login keychain đi theo bản sao lưu và Migration Assistant (quét bảo
  mật ngày 04/10/2026, mức LOW). 0.6.1: login keychain được xóa bằng `SecKeychainItemDelete`, vì `SecItemDelete` trả
  errSecInvalidOwnerEdit (-25244) với mục do chữ ký mã khác tạo, lỗi này cũng khiến bản ad-hoc đã cập nhật không xóa
  được dữ liệu hay cài đặt lại; SET-03 API 1 logic 1 giữ bước dọn khi cài mới trong keychain của bản build này;
  PAIR-03 nêu lời gọi. Mã: apple `fix/erase-both-keychains`.

### Security

- Cuộc gọi từ ứng dụng khác (CALL-05 API 1 logic 6): "Trả lời" từ Mac chỉ mở ứng dụng từ nền với cuộc gọi mà Android
  bảo đảm (từ Android 14: foreground service, user-initiated job hoặc full-screen intent đã được cấp; Android 12–13:
  mọi thông báo `CallStyle`; Android 10–11: không bao giờ); cuộc gọi khác được trả lời qua thông báo "chạm để nghe"
  trên điện thoại.
- Ký bản phát hành Android: các secret chuyển vào environment `release`, chỉ cho tag `v*` và `main`; khóa phát hành
  mới (`CN=Ho Xuan Dung, O=HandLive, C=VN`) thay khóa đầu tiên trước khi có người dùng cài.

## [0.1.0-beta.2] — 04/10/2026

### Added

- Biểu tượng thương hiệu trên màn chào của app Mac, iPhone/iPad và Android (apple và android
  `feat/brand-in-app`), sinh vào cả hai kho bằng `tools/brand/build_brand_assets.py`.

- `docs/deployment-guide.md` (en, vi): Bản phát hành — `release-android` chạy theo tag (APK `foss` đã ký) và
  `release-apple` (IPA iOS chưa ký; DMG Mac ký ad-hoc, hoặc ký Developer ID và notarize khi có secret của team trả
  phí); bản Mac không có chữ ký team giữ khóa trong login keychain (0.6.1); cách ra một bản phát hành, build lại một
  tag đã có, và các secret chủ dự án cần tạo.
- CALL-05 (cuộc gọi từ ứng dụng khác): `AppCallListenerService` (`NotificationListenerService`) đọc thông báo cuộc gọi
  của Telegram và các ứng dụng khác trên Android và gửi tới Mac; người dùng có thể trả lời, từ chối hoặc kết thúc từ
  Mac (âm thanh vẫn ở trên điện thoại ở v1). Cần quyền truy cập thông báo, một quyền đặc biệt mà người dùng bật bằng
  tay. Các cuộc gọi di động không thay đổi.
- Website sản phẩm và blog (`website/`, `docs/website.vi.md`): WordPress trên nginx + PHP-FPM + MariaDB trong
  Docker, tiếng Anh ở `/` và tiếng Việt ở `/vi/` qua Polylang, theme màu bình minh của thương hiệu với diện mạo
  sáng và tối, trang chủ, trang Quyền riêng tư sinh từ `docs/privacy.vi.md`, và hai bài blog mỗi ngôn ngữ.
  `website/` theo GPL-2.0-or-later.
- Bộ nhận diện thương hiệu 1.0: `docs/brand-guidelines.vi.md` (câu chuyện: ngọn lửa hiệu lúc bình minh;
  giọng văn, thông điệp, logo, biểu tượng app, màu sắc, ảnh quảng bá) và các file trong `docs/brand/assets/`,
  sinh bằng `tools/brand/build_brand_assets.py`. Tagline: "Không bỏ lỡ tín hiệu nào." Ảnh hero README tiếng
  Anh và tiếng Việt.
- Biểu tượng app từ bộ thương hiệu: bộ AppIcon macOS và iOS (apple `feat/brand-identity`) và biểu tượng
  thích ứng Android thay cho biểu tượng xanh dương giữ chỗ (android `feat/brand-identity`).

### Changed

- Bảng màu thương hiệu: các token `brand-*` nhận giá trị bình minh (handlive-shared `feat/brand-identity`,
  token Apple đã sinh lại); các trang thương hiệu trong design system mô tả logo và bảng màu mới.
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
- Android: các dòng cuối của Cài đặt và các danh sách nhóm khác nằm dưới thanh tab nổi; tab Thiết bị khi chưa ghép
  điện thoại bị crash lúc có banner trạng thái, và nút Thêm thiết bị có thể bị thanh tab che trong cửa sổ thấp.
- Mac và iPhone/iPad: "Lần đồng bộ cuối" hiện "sau 0 giây nữa" ngay sau khi đồng bộ; nay hiện "bây giờ" khi dưới một
  phút.

### Security

Quét bảo mật mọi thay đổi từ v0.1.0-beta.1 (không có lỗi nghiêm trọng hay mức cao):

- Android, cuộc gọi từ ứng dụng khác: một thông báo chỉ được tính là cuộc gọi khi có template `CallStyle` của nền
  tảng (API 31+), thứ Android chỉ đăng kèm foreground service, user-initiated job hoặc yêu cầu full-screen intent.
  Trước đây, ứng dụng bất kỳ có thể giả cuộc gọi bằng extra `android.callType` trần và, khi được trả lời từ Mac, được
  mở activity của chính nó từ nền bằng quyền miễn trừ của HandLive. Còn mở: dưới API 31, và ứng dụng đăng thông báo
  `CallStyle` thật. Đã cập nhật CALL-05 API 3 logic 1.
- Website: nginx chặn trình cài WordPress qua web và `setup.sh` chỉ bật nginx sau khi WP-CLI đã cài WordPress, nên
  không ai tạo được tài khoản admin trong lần cài đầu; tên đăng nhập của admin không còn hiện trong feed hay oEmbed;
  Polylang tự cập nhật; `docs/website.vi.md` giải thích giới hạn đăng nhập khi đứng sau reverse proxy.
- Workflow phát hành Apple: DMG ad hoc được ký và chạy thử trong job build chỉ có quyền đọc; bản Developer ID chỉ
  được chạy thử sau khi xóa keychain ký và khóa notary, môi trường không có secret (job vẫn giữ chúng trong bộ nhớ:
  sẽ tách job trước khi có các secret đó); XcodeGen được ghim bằng checksum. Đã cập nhật
  `docs/deployment-guide.vi.md`.

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
