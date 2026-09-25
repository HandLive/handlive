# Kế hoạch triển khai HandLive — giao cho agent viết mã

**Trạng thái:** Sẵn sàng giao việc (25/09/2026) · **Nguồn:** `plans/20260924-definitive-architecture/plan.md` (kiến trúc, D1–D12), `docs/detailed-design/` v1.1 (33 chức năng lá, C1–C19), `docs/design-system/` (Apple HIG, bản 6), `docs/code-standards.md`, `docs/project-roadmap.md`.

## 1. Quyết định lập kế hoạch

| # | Quyết định | Lý do |
|---|-----------|-------|
| I1 | **Monorepo** một kho: `android/`, `apple/` (macOS + iOS + Swift packages dùng chung), `relay/`, `shared/` (test vector, schema, design tokens), `tools/` | Ba nền tảng phải khớp một wire protocol; test vector và schema chỉ có một bản |
| I2 | **Phase 0** dựng khung, thư viện giao thức và mã hóa, test vector liên nền tảng trước mọi tính năng | Mọi phase sau dùng lại; sai lệch mã hóa giữa Tink và CryptoKit phải lộ ngay từ đầu |
| I3 | Thứ tự phase 1 → 5 như roadmap; mỗi phase một nhánh `feat/phase-0N-<slug>`, gộp vào `main` khi đạt tiêu chí đo | Mỗi phase là sản phẩm dùng được |
| I4 | Phase 4 và 5 mở đầu bằng **spike một tuần** có cổng go/no-go (D1, D6) trước khi viết tính năng | Rủi ro R1, R6 |
| I5 | Chuỗi giao diện lấy nguyên văn từ tài liệu chi tiết; giao diện dựng theo design system (thành phần, token, câu chữ) | Không viết chuỗi trong mã |
| I6 | Khi mã và tài liệu lệch nhau: sửa tài liệu trước (00-common-specs → chức năng lá), chạy `tools/docs/validate_design_docs.py`, rồi mới sửa mã | Tài liệu là hợp đồng giữa các nền tảng |

## 2. Phase

| Phase | Mục tiêu | Chức năng lá | Nền tảng | Phụ thuộc | Tiêu chí đo | File |
|-------|---------|--------------|----------|-----------|-------------|------|
| 0 | Khung kho, giao thức, mã hóa, token, CI | 0.2–0.8 của common specs | Cả ba | — | Test vector liên nền tảng xanh; CI xanh | [phase-00-khung-va-dung-chung.md](phase-00-khung-va-dung-chung.md) |
| 1 | Bảng nhớ tạm Android ↔ Mac trong LAN (MVP) | SET-01, SET-02, SET-03, PAIR-01 (LAN), PAIR-02, PAIR-03 (luồng A), CONN-01, CONN-02, CLIP-01, CLIP-02, CLIP-03, CLIP-05 | Android, macOS | 0 | Văn bản < 50 ms LAN; ảnh 5 MB < 2 s; kết nối lại < 3 s | [phase-01-bang-nho-tam-mvp.md](phase-01-bang-nho-tam-mvp.md) |
| 2 | SMS, app iPhone/iPad, relay, push | SMS-01…05, CONN-03, CONN-04, CLIP-04, PAIR-01 (relay), PAIR-03 (từ xa), SET-02 (phần còn lại) | Cả ba + relay | 1 | Thông báo SMS < 500 ms; trả lời xác nhận < 2 s | [phase-02-sms-ios-relay.md](phase-02-sms-ios-relay.md) |
| 3 | Thông tin và điều khiển cuộc gọi | CALL-01…04 | Android, macOS, iOS | 2 | Cuộc gọi đến < 200 ms; trả lời < 500 ms đầu-cuối | [phase-03-cuoc-goi.md](phase-03-cuoc-goi.md) |
| 4 | Nghe gọi trên Mac | AUDIO-01…04, CALL-03 (giữ máy, DTMF, tắt tiếng qua HFP) | Android, macOS | 3, spike D1 | MOS ≥ 3,5 (HFP), ≥ 3,0 (Opus/WS); ERL > 40 dB | [phase-04-am-thanh-cuoc-goi.md](phase-04-am-thanh-cuoc-goi.md) |
| 5 | Điện thoại làm webcam và micro | CAM-01…05 | Android, macOS | 1, spike D6 | Trễ < 120 ms Wi-Fi, < 70 ms USB ở 720p30 | [phase-05-camera-micro.md](phase-05-camera-micro.md) |

Ước lượng công (roadmap): P1 3,5 · P2 4 · P3 3 · P4 6 · P5 5,5 người-tháng; Phase 0 khoảng 0,5.

## 3. Cách giao việc cho agent

Mỗi thẻ việc trong file phase có: mã (`A1.3`, `M2.1`…, chữ đầu = nền tảng: A Android, M macOS, I iOS, R relay, S shared, T test), đầu vào (mục tài liệu phải đọc), đầu ra (đường dẫn được tạo/sửa), tiêu chí chấp nhận, kiểm thử. Prompt giao việc gồm đúng các mục theo `~/.claude/rules/orchestration-protocol.md`: task, files to read, files it may modify, acceptance criteria, constraints, work context path (`/Users/hxd/HandLive`), reports path (`plans/20260925-implementation/reports/`).

**Thứ tự đọc bắt buộc trước khi viết mã:** `CLAUDE.md` → `docs/detailed-design/README.md` (danh mục, quy ước §3, quyết định C1–C19) → `docs/detailed-design/00-common-specs.md` → file phase → các chức năng lá được nêu → `docs/code-standards.md`. Việc có giao diện đọc thêm `docs/design-system/README.md`, mục nền tảng tương ứng trong `docs/design-system/3-platforms/` và README của thành phần liên quan.

**Ranh giới sửa file:** agent Android chỉ sửa `android/` và `shared/`; agent Apple chỉ `apple/` và `shared/`; agent relay chỉ `relay/` và `shared/`. Sửa `shared/` (test vector, schema) phải nêu trong báo cáo để agent nền tảng khác chạy lại. Sửa `docs/detailed-design/` chỉ khi phát hiện lệch, kèm chạy validator.

**Định nghĩa "xong" chung cho mọi thẻ việc:**
1. Mã dựng và test xanh trên toolchain của nền tảng (lệnh ghi trong file phase); không giấu lỗi lint, type, build.
2. Mọi ngoại lệ `E<k>` của chức năng lá liên quan có test hoặc kiểm thử tay ghi trong báo cáo.
3. Chuỗi giao diện đúng nguyên văn tài liệu chi tiết; thành phần theo design system; VoiceOver/TalkBack đọc được trạng thái.
4. Không có secret, khóa, chứng chỉ, dotenv trong commit.
5. `docs/codebase-summary.md` cập nhật khi cấu trúc mã thay đổi.
6. Báo cáo trong `reports/<phase>-<mã việc>.md`, kết thúc bằng khối `Status:` / `Summary:` / `Concerns/Blockers:`.

## 4. Cổng và rủi ro

| Cổng | Khi nào | Tiêu chí đi tiếp | Nếu không đạt |
|------|---------|------------------|---------------|
| G0 | Cuối Phase 0 | Test vector mã hóa và envelope xanh trên Android và Apple; CI ba nền tảng xanh | Không mở Phase 1 |
| G1 | Cuối Phase 1 | Đủ tiêu chí đo trên ≥ 2 điện thoại Android thật (Pixel, Samsung) và 1 Mac | Sửa trước khi mở Phase 2 |
| G2 | Trước Phase 2 phát hành | Play Console: Permissions Declaration Form cho SMS và nhật ký cuộc gọi đã nộp (`docs/deployment-guide.md`) | Kích hoạt Plan B (Notification Listener cho SMS đến; phân phối F-Droid/APK) |
| G4 (spike D1) | Tuần đầu Phase 4 | `IOBluetoothHandsFreeDevice` nhận được âm thanh SCO ở vai HF trên macOS 13, 14, 15, 26 với Pixel và Samsung | Opus/WS thành đường chính; HFP chỉ giữ điều khiển; cập nhật AUDIO-02, plan D1 |
| G5 (spike D6) | Tuần đầu Phase 5 | CMIOExtension xuất khung vào Zoom/Meet/FaceTime; AudioServerPlugin loopback nghe được trong ứng dụng họp | Dừng Phase 5, ghi báo cáo |

Điểm phải kiểm trên máy thật (không phải câu hỏi mở, là việc trong phase): tên mục hệ thống tiếng Việt ("Quyền riêng tư & Bảo mật", "Tập trung", "Dán từ ứng dụng khác") — A1.4, M1.1; hiệu ứng Magic Replace trên biểu tượng thanh menu — M1.4; `AudioRecord` thu được âm cuộc gọi qua Shizuku trên từng máy — A4.3.

## 5. Kiểm thử và thiết bị

- Đơn vị: mã hóa, envelope, chunking, máy trạng thái kết nối (0.11), chống trùng `clip_id`, quy tắc xung đột QC8.
- Tích hợp: Android (máy thật hoặc emulator) ↔ Mac trên cùng Wi-Fi; kịch bản đo trễ có script trong `tools/bench/`.
- Ma trận máy thật: Android — Pixel 8 (14/15), Galaxy S22/S23 (14), Xiaomi hoặc OPPO (Android 13); Apple — Mac Apple silicon macOS 26, Mac Intel macOS 13 hoặc 14; iPhone iOS 16 và 26. Phase 4, 5 thêm AirPods (xung đột HFP) và cáp USB.

## 6. Tài liệu phải cập nhật trong lúc làm

`docs/codebase-summary.md` (cấu trúc mã), `docs/deployment-guide.md` (ký, notarize, PKG, Play Console), `docs/code-standards.md` (khi có quy ước mới), tài liệu chi tiết khi lệch (theo I6), `docs/design-system/` khi đổi giao diện (rồi xuất bản lại artifact).

## 7. Câu hỏi mở

Không còn. Mọi điểm chưa chắc đã chuyển thành cổng (mục 4) hoặc việc kiểm trên máy thật trong file phase.
