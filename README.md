# HandLive

> Biến điện thoại Android thành hub relay **clipboard, SMS, cuộc gọi (kèm audio) và camera/mic** sang macOS (đầy đủ) và iOS/iPadOS (clipboard + SMS + call metadata).
>
> **Phương châm thiết kế:** *"WebSocket cho dữ liệu, Bluetooth cho giọng nói."*

**Trạng thái:** Giai đoạn thiết kế (pre-implementation) — hiện chỉ có tài liệu kiến trúc, chưa có code.

## HandLive giải quyết gì

Tương tự Microsoft Phone Link / Apple Continuity nhưng **xuyên hệ sinh thái**: người dùng Android nghe/gọi, nhắn tin, đồng bộ clipboard, và dùng camera/mic của điện thoại ngay trên máy Mac — với mã hóa đầu-cuối (E2E) không thể tắt.

| Tính năng | macOS | iOS/iPadOS |
|-----------|:-----:|:----------:|
| Clipboard sync (2 chiều) | ✅ | ✅ |
| SMS nhận/gửi | ✅ | ✅ |
| Call metadata + điều khiển (answer/reject/end; hold/DTMF qua Bluetooth HFP) | ✅ | ✅ (metadata + từ chối, không audio) |
| **Call audio relay** (nghe/nói trên máy) | ✅ | ❌ (Apple không expose HFP HF API) |
| Virtual camera + mic (Zoom/Meet/FaceTime/OBS) | ✅ | ❌ |

## Kiến trúc tóm tắt

- **WebSocket** (Ktor server trên Android, discovery qua mDNS) là kênh chính cho *mọi dữ liệu*: clipboard, SMS, call metadata, notifications.
- **Bluetooth HFP SCO** chỉ dùng cho **audio cuộc gọi** (Android 10+ chặn capture call audio qua API công khai; HFP là con đường duy nhất đã được chứng minh). Fallback: **Opus-over-WebSocket** (~100–150ms) khi HFP không khả dụng — cần Shizuku, giới hạn theo phiên bản Android và theo máy (plan §13 D10).
- **E2E encryption** bắt buộc toàn hệ thống: XChaCha20-Poly1305 payload, X25519 + HKDF key exchange, ghép cặp qua **QR code**. Âm thanh qua Opus/WS mã hóa hai lớp; âm thanh HFP dựa vào mã hóa Bluetooth (plan §13 D11).
- **Cloud relay** (Rust/Actix-web) là zero-knowledge, chỉ relay blob đã mã hóa khi thiết bị ngoài LAN.

Chi tiết đầy đủ: [`docs/system-architecture.md`](docs/system-architecture.md) và [`plans/20260924-definitive-architecture/plan.md`](plans/20260924-definitive-architecture/plan.md).

## Lộ trình (xây theo thứ tự)

1. **Clipboard sync** (MVP) — Android ↔ macOS qua WebSocket LAN
2. **SMS bridge** — + app iOS + cloud relay + push
3. **Call metadata + control** — API Telecom công khai (không `InCallService`, D9) + floating call panel
4. **Call audio relay** — HFP/SCO + Opus fallback + echo cancellation
5. **Camera/mic virtual devices** — CMIOExtension + AudioServerPlugin

Chi tiết: [`docs/project-roadmap.md`](docs/project-roadmap.md).

## Cấu trúc repo

```
HandLive/
├── CLAUDE.md            # Hướng dẫn cho Claude Code
├── README.md
├── docs/                # Tài liệu dự án (xem docs/codebase-summary.md)
│   └── detailed-design/ # Tài liệu thiết kế chi tiết theo nhóm chức năng
└── plans/               # Tài liệu kiến trúc & nghiên cứu (nguồn chân lý thiết kế)
    ├── 20260924-definitive-architecture/    # Kiến trúc đã chốt — ĐỌC TRƯỚC
    ├── 20260924-bluetooth-native-architecture/
    ├── 20260924-ipc-research/
    └── 20260924-virtual-camera-mic-research/
```

## Tài liệu

| File | Nội dung |
|------|----------|
| [`docs/project-overview-pdr.md`](docs/project-overview-pdr.md) | Product definition, mục tiêu, phạm vi, ràng buộc |
| [`docs/system-architecture.md`](docs/system-architecture.md) | Kiến trúc hệ thống, transport, protocol, security |
| [`docs/project-roadmap.md`](docs/project-roadmap.md) | 5 phase phát triển + effort estimate |
| [`docs/design-guidelines.md`](docs/design-guidelines.md) | Nguyên tắc thiết kế UX & bảo mật |
| [`docs/code-standards.md`](docs/code-standards.md) | Quy ước code cho từng nền tảng |
| [`docs/deployment-guide.md`](docs/deployment-guide.md) | Đóng gói & phân phối (App Store, PKG, cloud relay) |
| [`docs/codebase-summary.md`](docs/codebase-summary.md) | Bản đồ codebase (cập nhật khi code xuất hiện) |
| [`docs/detailed-design/README.md`](docs/detailed-design/README.md) | Thiết kế chi tiết: 33 chức năng lá, giao thức, mã lỗi, mô hình dữ liệu |
