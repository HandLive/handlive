# HandLive — Design Guidelines

> UX & bảo mật nguyên tắc. Chi tiết security: `docs/system-architecture.md` §6, plan gốc §6.

## Nguyên tắc UX

- **Zero-config, không dây là mặc định.** User mass-market phải dùng được ngay sau khi ghép cặp QR, không cần ADB/USB/terminal. Mọi thứ cần setup kỹ thuật (Shizuku, USB debugging) là "boost" tùy chọn có wizard hướng dẫn từng bước.
- **Feature độc lập, degrade duyên dáng.** Một feature hỏng không làm hỏng feature khác. Khi transport chính fail → tự fallback (HFP→Opus/WS, LAN→cloud relay) và *thông báo* user thay vì im lặng chết.
- **Ghép cặp qua QR code**, không phải PIN 6 số (256-bit entropy vs ~20-bit; xác thực out-of-band qua camera). PIN chỉ là fallback.
- **iOS là công dân hạng hai có chủ đích** — đừng cố nhồi call audio; đặt kỳ vọng rõ trong UI (clipboard + SMS + call metadata).
- **macOS call UI** là floating `NSPanel` (level `.floating`) — CallKit không có trên macOS native.

## Design system giao diện

- Nguồn: artifact "HandLive Design System" — https://claude.ai/artifact/2rsmYxBjxXrd12FByTd9vT (bản sao trong `docs/design-system/`, token ở `shared/design-tokens/tokens.json`). Theo **Apple Human Interface Guidelines** (bản 24/09/2026, Liquid Glass) cho **mọi nền tảng**: Mac, iPhone, iPad dùng control, font San Francisco, SF Symbols và vật liệu của hệ thống; Android dựng lại cùng ngôn ngữ bằng Compose (font Inter, Material Symbols Rounded) và giữ nguyên phần do Android quản lý (thông báo, hộp thoại quyền, ô Cài đặt nhanh, cử chỉ quay lại). Giấy phép Apple không cho dùng SF Pro, SF Symbols, UI Kit trên Android.
- Màu thương hiệu theo phong thủy mệnh Sơn Đầu Hỏa: đỏ son, đỏ than, cam lửa cho nhận diện; xanh lá (Mộc sinh Hỏa) là AccentColor; không dùng đen, xanh dương cho thương hiệu. Bốn giao diện Sáng, Tối và hai bản tương phản cao; mọi cặp chữ–nền ≥ 4.5:1.
- Quyết định, nghiên cứu HIG và danh sách điểm đã đồng bộ với `docs/detailed-design/` (25/09/2026): `plans/20260924-apple-hig-design-system/`. Câu chữ giao diện: `docs/detailed-design/README.md` §3.5.

## Nguyên tắc bảo mật (không đàm phán)

- **E2E không thể tắt.** Không có option "gửi không mã hóa". Nhất quán toàn hệ thống.
- **Audio.** Đường Opus/WS mã hóa hai lớp (TLS + E2E XChaCha20). Đường HFP chỉ có mã hóa liên kết Bluetooth vì ứng dụng không chạm được khung SCO của cuộc gọi di động (plan §13 D11); rủi ro KNOB/BIAS phải được công bố khi người dùng bật nghe gọi trên Mac.
- **Cloud relay zero-knowledge.** Server không bao giờ có key, không decrypt, không log payload.
- **Key hardware-backed** khi khả dụng (StrongBox / Secure Enclave). Stolen device → cần biometric/passcode + remote unpair.
- **Clipboard nhạy cảm:** detect pattern (thẻ tín dụng, password-manager) → không sync, chỉ notify. Auto-clear receiver sau 60s.

## Legal / privacy

- Call audio relay: **disclosure trước khi bật** (dialog + log consent timestamp). Two-party-consent states (CA/FL/IL) yêu cầu "all parties aware". Không ghi âm.
- Relay giữa các thiết bị của *cùng một user* (như Continuity/Phone Link) → rủi ro pháp lý thấp hơn relay bên thứ ba.

## Performance targets

Xem `docs/project-overview-pdr.md` §7. Nguyên tắc: đo được, không "cảm giác nhanh". Latency budget chi tiết cho camera/mic ở plan gốc §10.5.
