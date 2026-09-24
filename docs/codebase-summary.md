# HandLive — Codebase Summary

> **Cập nhật file này mỗi khi cấu trúc code thay đổi đáng kể.**

## Trạng thái hiện tại

**Chưa có code.** Repo chỉ chứa tài liệu:

```
HandLive/
├── CLAUDE.md                # Hướng dẫn Claude Code
├── README.md
├── docs/                    # Tài liệu dự án (file này + 6 file khác)
│   └── detailed-design/     # Thiết kế chi tiết: 00-common-specs + 8 nhóm chức năng (33 chức năng lá)
└── plans/                   # Kiến trúc & nghiên cứu (nguồn chân lý thiết kế)
    ├── 20260924-definitive-architecture/plan.md      # Kiến trúc đã CHỐT — đọc trước
    ├── 20260924-bluetooth-native-architecture/plan.md # Đề xuất Bluetooth-Native (bối cảnh)
    ├── 20260924-ipc-research/plan.md                   # IPC macOS app↔extension
    └── 20260924-virtual-camera-mic-research/plan.md    # CMIOExtension + AudioServerPlugin
```

## Cấu trúc code dự kiến (khi implement)

Chưa quyết mono-repo hay tách repo theo nền tảng. Dự kiến 4 nhánh code:

| Thư mục (dự kiến) | Nền tảng | Vai trò |
|-------------------|----------|---------|
| `android/` | Kotlin | Audio Gateway: WS server, clipboard/SMS/call, camera/mic capture |
| `macos/` | Swift 6 | Hands-Free: WS client, BT HFP, virtual cam/mic, UI |
| `ios/` | Swift 6 | WS client: clipboard + SMS + call metadata |
| `relay/` | Rust | Zero-knowledge cloud relay |
| `shared/` | — | Định nghĩa protocol dùng chung (envelope, message types) — nguồn: `docs/detailed-design/00-common-specs.md` |

## Điểm bắt đầu implement

Phase 1 (Clipboard MVP): dựng WS server (Ktor) + pairing (QR/X25519) + crypto (XChaCha20) trên Android, và menu-bar app + clipboard polling trên macOS. Hạ tầng này (WS + pairing + crypto + capability negotiation) tái sử dụng cho mọi phase sau.

Xem `docs/project-roadmap.md`.
