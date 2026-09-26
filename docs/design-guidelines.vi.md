[English](design-guidelines.md) | Tiếng Việt

# HandLive — Design Guidelines

> HandLive đưa các tính năng native riêng trong từng hệ sinh thái, như Handoff trên Apple, lên Android. Máy Android đồng bộ với thiết bị Apple, và chiều ngược lại cũng vậy. Mục này ghi nguyên tắc trải nghiệm và bảo mật. Chi tiết bảo mật: `docs/system-architecture.vi.md` §6, plan gốc §6.

## Nguyên tắc UX

- **Mặc định không cấu hình, không dây.** Người dùng phổ thông dùng được ngay sau khi ghép cặp QR. Không cần ADB, USB hay terminal. Shizuku và USB debugging chỉ là lối tăng tốc, có wizard hướng dẫn từng bước.
- **Mỗi tính năng đứng riêng.** Một tính năng hỏng không kéo theo tính năng khác. Khi kênh chính lỗi, hệ thống tự chuyển đường dự phòng: HFP sang Opus/WS, mạng nội bộ sang cloud relay. Hệ thống báo cho người dùng, không im lặng.
- **Ghép cặp qua mã QR.** Không dùng PIN 6 số làm đường chính. QR có 256 bit entropy. PIN khoảng 20 bit, chỉ là dự phòng. Camera xác thực ngoài băng.
- **iOS có phạm vi hẹp, có chủ đích.** Không đưa âm thanh cuộc gọi lên iOS. Giao diện nói rõ: clipboard, SMS và thông tin cuộc gọi.
- **Giao diện cuộc gọi trên macOS** là `NSPanel` nổi (level `.floating`). macOS native không có CallKit.

## Design system giao diện

- Nguồn: artifact "HandLive Design System", https://claude.ai/artifact/2rsmYxBjxXrd12FByTd9vT. Bản sao nằm trong `docs/design-system/`. Token nằm ở `shared/design-tokens/tokens.json`. Theo **Apple Human Interface Guidelines** (bản 24/09/2026, Liquid Glass) cho mọi nền tảng. Mac, iPhone và iPad dùng control, font San Francisco, SF Symbols và vật liệu sẵn trên hệ thống. Android dựng lại cùng ngôn ngữ bằng Compose (font Inter, Material Symbols Rounded). Android giữ nguyên phần hệ thống quản lý: thông báo, hộp thoại quyền, ô Cài đặt nhanh, cử chỉ quay lại. Giấy phép Apple không cho dùng SF Pro, SF Symbols và UI Kit trên Android.
- Màu thương hiệu theo phong thủy mệnh Sơn Đầu Hỏa: đỏ son, đỏ than, cam lửa cho nhận diện; xanh lá
  (Mộc sinh Hỏa) là AccentColor; không dùng đen, xanh dương cho thương hiệu. Bốn giao diện Sáng, Tối
  và hai bản tương phản cao; mọi cặp chữ–nền ≥ 4.5:1.
- Quyết định, nghiên cứu HIG và danh sách điểm đã đồng bộ với `docs/detailed-design/` (25/09/2026):
  `plans/20260924-apple-hig-design-system/`. Câu chữ giao diện: `docs/detailed-design/README.md`
  §3.5.

## Nguyên tắc bảo mật

- **Mã hóa đầu-cuối luôn bật.** Không có lựa chọn gửi không mã hóa. Quy tắc này áp dụng toàn hệ thống.
- **Âm thanh.** Đường Opus/WS mã hóa hai lớp: TLS và E2E XChaCha20. Đường HFP chỉ có mã hóa liên kết Bluetooth. Ứng dụng không chạm khung SCO của cuộc gọi di động (plan §13 D11). Khi người dùng bật nghe gọi trên Mac, giao diện công bố rủi ro KNOB/BIAS.
- **Cloud relay không đọc nội dung.** Máy chủ không giữ khóa, không giải mã, không ghi payload vào log.
- **Khóa nằm trên phần cứng** khi máy có StrongBox hoặc Secure Enclave. Máy mất thì cần sinh trắc hoặc mã khóa màn hình, rồi hủy ghép từ xa.
- **Clipboard nhạy cảm.** Hệ thống nhận dạng thẻ tín dụng và nội dung từ trình quản lý mật khẩu. Hệ thống không đồng bộ nội dung đó, chỉ báo. Bên nhận tự xóa sau 60 giây.

## Pháp lý và quyền riêng tư

- Âm thanh cuộc gọi: **công bố trước khi bật**. Hộp thoại hiện ra. Hệ thống ghi thời điểm người dùng đồng ý. Một số bang (CA, FL, IL) yêu cầu mọi bên trong cuộc gọi đều biết. Không ghi âm.
- Relay chỉ nối các thiết bị của cùng một người, như Continuity và Phone Link. Rủi ro pháp lý thấp hơn relay cho bên thứ ba.

## Performance targets

Xem `docs/project-overview-pdr.md` §7. Nguyên tắc: đo được, không "cảm giác nhanh". Latency budget
chi tiết cho camera/mic ở plan gốc §10.5.
