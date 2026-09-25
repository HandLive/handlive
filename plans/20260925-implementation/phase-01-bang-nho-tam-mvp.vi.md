[English](phase-01-bang-nho-tam-mvp.md) | Tiếng Việt

# Phase 1 — Bảng nhớ tạm Android ↔ Mac trong LAN (MVP)

**Mục tiêu:** ghép nối bằng QR, tự tìm nhau trong Wi-Fi, gửi văn bản và ảnh của bảng nhớ tạm hai
chiều với mã hóa đầu-cuối, tự xóa sau 60 giây. Sản phẩm dùng được cho một điện thoại và một Mac, giao
diện tiếng Anh (mặc định) và tiếng Việt (C20).

## Ngữ cảnh

- Chức năng lá: `01-setup-settings.md` SET-01, SET-02 (trường 1–6, 21–23, 31), SET-03 (Mac);
  `02-pairing.md` PAIR-01 (QR và PIN trong LAN), PAIR-02, PAIR-03 (luồng A); `03-connectivity.md`
  CONN-01, CONN-02; `04-clipboard.md` CLIP-01, CLIP-02, CLIP-03, CLIP-05 và quy tắc chung QC1–QC9.
- Design system: `docs/design-system/3-platforms/03-android.md`, `01-macos.md`;
  `2-patterns/01-thiet-lap-ban-dau.md`, `02-xin-quyen.md`, `04-cai-dat.md`, `05-phan-hoi-va-tai.md`;
  thành phần `Onboarding`, `PermissionPrimer`, `ConsentSheet`, `PairingCard`, `DeviceRow`,
  `GroupedList`, `Toggle`, `MenuBarMenu`, `StatusIndicator`, `Feedback`, `Alert`.
- Quyết định: D4/D12 (Accessibility), C6 (hint mDNS), C10 (quyền dán Mac), C15, C16, C17, C20 (đa
  ngôn ngữ); kế hoạch I7, I8.
- Bản địa hóa: `00-common-specs.md` 0.12; design system `1-foundations/09-viet-noi-dung.md` (mục
  "Tiếng Anh" và các mục tiếng Việt).

## Yêu cầu và tiêu chí đo

- Văn bản < 50 ms từ lúc sao chép tới lúc dán được ở máy kia (LAN; đo theo QC9, không tính thời gian phát hiện sao chép; mọi
  mục tiêu tính ở phân vị 95); ảnh 5 MB < 2 s; kết nối lại < 3
  s sau khi Wi-Fi đổi.
- Không đọc bảng nhớ tạm khi chưa có đồng ý (CLIP-01 trường 2, 3); nội dung nhạy cảm bị chặn (QC3);
  vòng lặp và xung đột theo QC4, QC8.
- Android 12+ hiện toast hệ thống khi đọc — chấp nhận, đã công bố.

## Thẻ việc

| Mã | Việc | Đầu ra | Tiêu chí chấp nhận |
|----|------|--------|--------------------|
| S1.1 [shared] | Việc còn lại từ Phase 0: vector `relay-auth.json` (`HLREG1`/`HLAUTH1` với khóa RFC 8032 TEST 1–3) và `ed25519.json` (§7.1 TEST 1–3 kèm vector âm) cho chữ ký `attestation`; schema `session/error` bắt buộc `min_protocol` khi `UNSUPPORTED_VERSION`; mã đóng 4410/4411/4429 vào schema và catalog | `shared/test-vectors`, `shared/schemas` | Relay, Android, Apple cùng qua vector mới |
| S1.2 [shared] | Catalog chuỗi giao diện (0.12, C20): `shared/strings/ui-strings.json`, schema `ui-strings.schema.json`, `shared/tools/strings/check_strings.py` (kiểm 0.12.5; `--docs` đối chiếu tài liệu, chỉ cảnh báo), bước kiểm trong `ci-shared`; nạp mọi chuỗi giao diện của chức năng lá Phase 1 (SET-01…03, PAIR-01…03, CONN-01/02, CLIP-01/02/03/05, trạng thái 0.11, purpose string Mac, kênh thông báo Android, khóa `push.*` của CONN-04): `vi` nguyên văn tài liệu, `en` theo design system mục "Tiếng Anh"; mở rộng `check_schemas.py` để nhận ví dụ catalog | `shared/strings`, `shared/tools/strings`, `shared/tools/schemas` | `check_strings.py` xanh; mọi chuỗi giao diện Phase 1 có khóa, đủ `en` và `vi`; commit và đẩy sớm vì Android và Apple dùng |
| A1.0 [android] | Việc còn lại từ Phase 0: nâng compileSdk 37 (`platforms;android-37`) và Compose BOM mới nhất; mã đóng 4410/4411/4429; giới hạn 16 kết nối chưa bắt tay, chặn IP, đóng im lặng 45 s (CONN-01 API 3–4, CONN-02); smoke test instrumented Netty + TLS 1.3 trên máy thật; đóng gói Material Symbols Rounded và Inter 700 (Chữ đậm); Room `paired_device` | `android/` | `./gradlew check` xanh; test instrumented qua trên Pixel |
| M1.0 [macOS] | Việc còn lại từ Phase 0: tên file Swift theo PascalCase (code-standards); ánh xạ mọi token màu ngữ nghĩa sang API hệ thống khi có (hex chỉ cho macOS 13); `AccentColor` = `accent-fill` và `ASSETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME` trong `project.yml`; Be Vietnam Pro ExtraBold cho Chữ đậm; cạnh lỗi mới của 0.11 và mã đóng 4410/4411/4429 phía client | `apple/` | `swift test` các package xanh; xem trước 4 giao diện |
| A1.1 [android] | `HandLiveService`: FGS `connectedDevice`, kênh `hl_service`, khởi động WSS 47800–47809, quảng bá mDNS với hint theo giờ (CONN-01 API 1, C6), giữ phiên và kết nối lại (CONN-02) | `android/feature/…`, `android/app` | Mac tìm thấy trong < 2 s; hint đổi theo giờ; thông báo thường trực đúng chuỗi CONN-01 trường 6 |
| A1.2 [android] | Ghép nối: quét QR (CameraX + ZXing core, không ML Kit — I8), ECDH X25519 + HKDF → `PRK`, chứng thực ký hai bên, ghim chứng chỉ TLS, PIN 6 số + Argon2id (PAIR-01 LAN); danh sách thiết bị và Mã an toàn (PAIR-02); hủy ghép nối luồng A (PAIR-03) | `android/feature/pairing` | Mọi E của PAIR-01…03 có test; Mã an toàn giống trên hai máy |
| A1.3 [android] | Bảng nhớ tạm: `ClipboardAccessibilityService` + `ClipboardReadActivity` + công bố (CLIP-01), đường thủ công (nút thông báo, ô Cài đặt nhanh, Chia sẻ), nhận và ghi (CLIP-02 API 3), ảnh theo chunk (CLIP-03), tự xóa an toàn (CLIP-05, C17), chặn nhạy cảm QC3, xung đột QC8, chuyển tiếp tới client khác QC6 | `android/feature/clipboard` | Đo trễ bằng `tools/bench/clip-latency` đạt mục tiêu; không xóa nhầm nội dung người dùng (test C17) |
| A1.4 [android] | Giao diện: thiết lập ban đầu SET-01 (màn giải thích quyền một nút "Tiếp tục"), Cài đặt SET-02 (nhóm Bảng nhớ tạm, Kết nối qua Internet tắt được), Thiết bị, công bố Hỗ trợ tiếp cận (`ConsentSheet`), phản hồi (toast/HUD) — theo `03-android.md`; đối chiếu tên mục hệ thống tiếng Anh và tiếng Việt trên máy thật | `android/app` | Chuỗi từ catalog, đủ `en` và `vi`; TalkBack đọc trạng thái; font scale 200% không cắt chữ ở cả hai ngôn ngữ |
| M1.1 [macOS] | App menu bar: `MenuBarExtra` kiểu menu, đổi activation policy `.accessory` ↔ `.regular` (SET-03 bước 6, SET-02 trường 31), cửa sổ chào (`Onboarding`), `Settings` scene sáu pane, mục đăng nhập `SMAppService`, màn giải thích mạng cục bộ, kiểm quyền dán C10 | `apple/macOS/HandLive` | Menu đúng `MenuBarMenu`; tắt "Hiện HandLive trên thanh menu" thì có Dock và thanh menu File/Edit/View/Window/Help (Tệp/Sửa/Xem/Cửa sổ/Trợ giúp khi chạy tiếng Việt) |
| M1.2 [macOS] | `HLTransport` dùng thật: `NWBrowser` `_handlive._tcp`, WSS ghim chứng chỉ, bắt tay, capability, backoff CONN-02, chỉ báo trạng thái `StatusIndicator` | `apple/Packages/HLTransport`, app | Kết nối lại < 3 s sau khi đổi Wi-Fi; máy trạng thái 0.11 có test |
| M1.3 [macOS] | Ghép nối: sheet `PairingCard` hiện QR (nội dung PAIR-01 API 1), đếm ngược đổi mã, PIN dự phòng, dòng thiết bị và Mã an toàn, hủy ghép nối với alert (Alert README) | app | Ghép được với A1.2 trên máy thật; Esc/Return đúng HIG |
| M1.4 [macOS] | Bảng nhớ tạm: đọc `changeCount` mỗi 500 ms, ghi `NSPasteboard` kèm kiểu `app.handlive.clip-id`, ảnh PNG/JPEG theo chunk, tự xóa (CLIP-05), chặn nhạy cảm (kiểu `org.nspasteboard.*` + Luhn), xung đột QC8, phản hồi bằng dấu kiểm trên thanh menu (`Feedback`; kiểm Magic Replace trên máy thật, có đường lùi tĩnh) | app | Đo trễ đạt mục tiêu; không đọc nội dung khi `changeCount` không đổi |
| A1.5 [android] | Bản địa hóa (0.12.2–0.12.3): task Gradle trong `buildSrc` sinh `values/strings.xml` (en) và `values-vi/strings.xml` từ catalog vào thư mục build; `locales_config.xml` + `android:localeConfig`; `androidResources.localeFilters` en, vi; AppCompat `setApplicationLocales` cho SET-02 trường 32 (Android 10–12) và mở trang ngôn ngữ ứng dụng của hệ thống (13+); lint `HardcodedText`, `MissingTranslation` là lỗi; pseudo-locale cho debug; chuyển chuỗi có sẵn của app sang catalog | `android/buildSrc`, `android/app`, `android/core/design` | `./gradlew check` xanh; test đối chiếu tài nguyên sinh ra với catalog; đổi ngôn ngữ en ↔ vi đổi toàn bộ giao diện |
| M1.5 [macOS] | Bản địa hóa (0.12.2–0.12.3): script sinh `Localizable.xcstrings`, `InfoPlist.xcstrings` và accessor Swift an toàn kiểu từ catalog (như bộ sinh token: file sinh được commit, `--check` trong test); `project.yml` `developmentLanguage: en`, `knownRegions` en, vi; chuyển purpose string (micro, Tập trung, mạng cục bộ) và chuỗi có sẵn sang catalog | `apple/` | `swift test` xanh; `--check` khớp catalog; app chạy tiếng Anh mặc định, tiếng Việt với `-AppleLanguages (vi)` |
| T1.1 [test] | `shared/tools/bench/`: script đo trễ văn bản/ảnh và thời gian kết nối lại (log dấu thời gian hai phía, đồng bộ bằng NTP hoặc `ts` envelope); kịch bản kiểm thử tay theo ma trận máy | `shared/tools/bench/`, `reports/phase-01-T1.1.md` | Bảng số đo cho Pixel, Samsung, Mac Intel và Apple silicon |

Thứ tự: S1.2 trước mọi việc giao diện; A1.5 trước A1.4; M1.5 trước M1.1 và M1.3. S1.1 và S1.2
commit và đẩy lên nhánh `feat/phase-01-clipboard` của `handlive-shared` sớm vì Android và Apple
đọc chúng.

## Kiểm thử

- Bản debug của app ghi dòng log `HLBENCH/1` theo `shared/tools/bench/README.md` (A1.1, A1.3, M1.2, M1.4) để
  T1.1 đo trễ và thời gian kết nối lại.

- Đơn vị: chunking 64 KiB, SHA-256, chống trùng `clip_id` 256 mục/10 phút, Luhn, so `origin_ts`.
- Tích hợp: Android emulator (API 34) + app Mac trên cùng máy qua loopback không đủ (mDNS) → dùng
  máy thật; JVM test giả lập client Mac bằng Ktor client cho phần giao thức.
- Giao diện ở `en` và `vi`: Android đổi ngôn ngữ ứng dụng (`adb shell cmd locale set-app-locales`
  hoặc SET-02 trường 32), pseudo-locale `en-XA` cho bản debug; macOS chạy với `-AppleLanguages (vi)`.
- Chấp nhận cuối phase: cổng G1 trong `plan.md`.

## Rủi ro và quay lui

- OEM chặn dịch vụ Hỗ trợ tiếp cận hoặc `ClipboardReadActivity` không lấy được focus → đường thủ
  công luôn có; ghi máy lỗi vào `docs/deployment-guide.md`.
- macOS 15.4+ `accessBehavior` `.ask` → mục menu "Gửi bảng nhớ tạm sang điện thoại" vẫn gửi được.
- Google Play từ chối Accessibility (C15 đã chấp nhận rủi ro) → phân phối APK trực tiếp cho bản có
  Accessibility.
