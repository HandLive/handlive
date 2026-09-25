# Phase 1 — Bảng nhớ tạm Android ↔ Mac trong LAN (MVP)

**Mục tiêu:** ghép nối bằng QR, tự tìm nhau trong Wi-Fi, gửi văn bản và ảnh của bảng nhớ tạm hai chiều với mã hóa đầu-cuối, tự xóa sau 60 giây. Sản phẩm dùng được cho một điện thoại và một Mac.

## Ngữ cảnh

- Chức năng lá: `01-setup-settings.md` SET-01, SET-02 (trường 1–6, 21–23, 31), SET-03 (Mac); `02-pairing.md` PAIR-01 (QR và PIN trong LAN), PAIR-02, PAIR-03 (luồng A); `03-connectivity.md` CONN-01, CONN-02; `04-clipboard.md` CLIP-01, CLIP-02, CLIP-03, CLIP-05 và quy tắc chung QC1–QC9.
- Design system: `docs/design-system/3-platforms/03-android.md`, `01-macos.md`; `2-patterns/01-thiet-lap-ban-dau.md`, `02-xin-quyen.md`, `04-cai-dat.md`, `05-phan-hoi-va-tai.md`; thành phần `Onboarding`, `PermissionPrimer`, `ConsentSheet`, `PairingCard`, `DeviceRow`, `GroupedList`, `Toggle`, `MenuBarMenu`, `StatusIndicator`, `Feedback`, `Alert`.
- Quyết định: D4/D12 (Accessibility), C6 (hint mDNS), C10 (quyền dán Mac), C15, C16, C17.

## Yêu cầu và tiêu chí đo

- Văn bản < 50 ms từ lúc sao chép tới lúc dán được ở máy kia (LAN); ảnh 5 MB < 2 s; kết nối lại < 3 s sau khi Wi-Fi đổi.
- Không đọc bảng nhớ tạm khi chưa có đồng ý (CLIP-01 trường 2, 3); nội dung nhạy cảm bị chặn (QC3); vòng lặp và xung đột theo QC4, QC8.
- Android 12+ hiện toast hệ thống khi đọc — chấp nhận, đã công bố.

## Thẻ việc

| Mã | Việc | Đầu ra | Tiêu chí chấp nhận |
|----|------|--------|--------------------|
| A1.1 [android] | `HandLiveService`: FGS `connectedDevice`, kênh `hl_service`, khởi động WSS 47800–47809, quảng bá mDNS với hint theo giờ (CONN-01 API 1, C6), giữ phiên và kết nối lại (CONN-02) | `android/feature/…`, `android/app` | Mac tìm thấy trong < 2 s; hint đổi theo giờ; thông báo thường trực đúng chuỗi CONN-01 trường 6 |
| A1.2 [android] | Ghép nối: quét QR (CameraX + ML Kit Barcode), ECDH X25519 + HKDF → `PRK`, chứng thực ký hai bên, ghim chứng chỉ TLS, PIN 6 số + Argon2id (PAIR-01 LAN); danh sách thiết bị và Mã an toàn (PAIR-02); hủy ghép nối luồng A (PAIR-03) | `android/feature/pairing` | Mọi E của PAIR-01…03 có test; Mã an toàn giống trên hai máy |
| A1.3 [android] | Bảng nhớ tạm: `ClipboardAccessibilityService` + `ClipboardReadActivity` + công bố (CLIP-01), đường thủ công (nút thông báo, ô Cài đặt nhanh, Chia sẻ), nhận và ghi (CLIP-02 API 3), ảnh theo chunk (CLIP-03), tự xóa an toàn (CLIP-05, C17), chặn nhạy cảm QC3, xung đột QC8, chuyển tiếp tới client khác QC6 | `android/feature/clipboard` | Đo trễ bằng `tools/bench/clip-latency` đạt mục tiêu; không xóa nhầm nội dung người dùng (test C17) |
| A1.4 [android] | Giao diện: thiết lập ban đầu SET-01 (màn giải thích quyền một nút "Tiếp tục"), Cài đặt SET-02 (nhóm Bảng nhớ tạm, Kết nối qua Internet tắt được), Thiết bị, công bố Hỗ trợ tiếp cận (`ConsentSheet`), phản hồi (toast/HUD) — theo `03-android.md`; đối chiếu tên mục hệ thống tiếng Việt trên máy thật | `android/app` | Chuỗi đúng tài liệu; TalkBack đọc trạng thái; font scale 200% không cắt chữ |
| M1.1 [macOS] | App menu bar: `MenuBarExtra` kiểu menu, đổi activation policy `.accessory` ↔ `.regular` (SET-03 bước 6, SET-02 trường 31), cửa sổ chào (`Onboarding`), `Settings` scene sáu pane, mục đăng nhập `SMAppService`, màn giải thích mạng cục bộ, kiểm quyền dán C10 | `apple/macOS/HandLive` | Menu đúng `MenuBarMenu`; tắt "Hiện HandLive trên thanh menu" thì có Dock và thanh menu Tệp/Sửa/Xem/Cửa sổ/Trợ giúp |
| M1.2 [macOS] | `HLTransport` dùng thật: `NWBrowser` `_handlive._tcp`, WSS ghim chứng chỉ, bắt tay, capability, backoff CONN-02, chỉ báo trạng thái `StatusIndicator` | `apple/Packages/HLTransport`, app | Kết nối lại < 3 s sau khi đổi Wi-Fi; máy trạng thái 0.11 có test |
| M1.3 [macOS] | Ghép nối: sheet `PairingCard` hiện QR (nội dung PAIR-01 API 1), đếm ngược đổi mã, PIN dự phòng, dòng thiết bị và Mã an toàn, hủy ghép nối với alert (Alert README) | app | Ghép được với A1.2 trên máy thật; Esc/Return đúng HIG |
| M1.4 [macOS] | Bảng nhớ tạm: đọc `changeCount` mỗi 500 ms, ghi `NSPasteboard` kèm kiểu `app.handlive.clip-id`, ảnh PNG/JPEG theo chunk, tự xóa (CLIP-05), chặn nhạy cảm (kiểu `org.nspasteboard.*` + Luhn), xung đột QC8, phản hồi bằng dấu kiểm trên thanh menu (`Feedback`; kiểm Magic Replace trên máy thật, có đường lùi tĩnh) | app | Đo trễ đạt mục tiêu; không đọc nội dung khi `changeCount` không đổi |
| T1.1 [test] | `tools/bench/`: script đo trễ văn bản/ảnh và thời gian kết nối lại (log dấu thời gian hai phía, đồng bộ bằng NTP hoặc `ts` envelope); kịch bản kiểm thử tay theo ma trận máy | `tools/bench/`, `reports/phase-01-T1.1.md` | Bảng số đo cho Pixel, Samsung, Mac Intel và Apple silicon |

## Kiểm thử

- Đơn vị: chunking 64 KiB, SHA-256, chống trùng `clip_id` 256 mục/10 phút, Luhn, so `origin_ts`.
- Tích hợp: Android emulator (API 34) + app Mac trên cùng máy qua loopback không đủ (mDNS) → dùng máy thật; JVM test giả lập client Mac bằng Ktor client cho phần giao thức.
- Chấp nhận cuối phase: cổng G1 trong `plan.md`.

## Rủi ro và quay lui

- OEM chặn dịch vụ Hỗ trợ tiếp cận hoặc `ClipboardReadActivity` không lấy được focus → đường thủ công luôn có; ghi máy lỗi vào `docs/deployment-guide.md`.
- macOS 15.4+ `accessBehavior` `.ask` → mục menu "Gửi bảng nhớ tạm sang điện thoại" vẫn gửi được.
- Google Play từ chối Accessibility (C15 đã chấp nhận rủi ro) → phân phối APK trực tiếp cho bản có Accessibility.
