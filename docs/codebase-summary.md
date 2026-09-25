# HandLive — Codebase Summary

> **Cập nhật file này mỗi khi cấu trúc code thay đổi đáng kể.**

## Trạng thái hiện tại (25/09/2026)

**Chưa có code.** Repo chứa tài liệu, design system, token và công cụ:

```
HandLive/
├── CLAUDE.md                      # Hướng dẫn Claude Code, mục hand-off cho agent viết mã
├── README.md
├── docs/
│   ├── detailed-design/           # 00-common-specs + 8 nhóm (33 chức năng lá), v1.1 đã đồng bộ design system
│   ├── design-system/             # Bản sao artifact Design System (Apple HIG): nền tảng, mẫu, từng nền tảng, thành phần
│   └── *.md                       # PDR, kiến trúc, chuẩn mã, triển khai, roadmap, hướng dẫn thiết kế
├── plans/
│   ├── 20260925-implementation/           # KẾ HOẠCH TRIỂN KHAI — thẻ việc cho agent, Phase 0–5, cổng, reports/
│   ├── 20260924-definitive-architecture/  # Kiến trúc đã chốt (D1–D12) — nguồn chân lý thiết kế
│   ├── 20260924-apple-hig-design-system/  # Quyết định, nghiên cứu HIG, báo cáo đồng bộ
│   ├── 20260924-detailed-design/          # Kế hoạch và báo cáo viết tài liệu chi tiết
│   ├── 20260924-bluetooth-native-architecture/, 20260924-ipc-research/, 20260924-virtual-camera-mic-research/
├── shared/design-tokens/tokens.json # Token giao diện — nguồn sinh mã cho Compose và Asset Catalog
└── tools/docs/                      # validate_design_docs.py, apple_diacritics.py, build_design_html.py
```

## Cấu trúc code (đã quyết: monorepo — quyết định I1 trong kế hoạch triển khai)

| Thư mục | Nền tảng | Vai trò |
|---------|----------|---------|
| `android/` | Kotlin, Gradle KTS | Hub: `app/`, `core/{protocol,crypto,transport,design}`, `feature/{pairing,clipboard,sms,call,callaudio,camera}` |
| `apple/` | Swift 6 | `Packages/{HLProtocol,HLCrypto,HLTransport,HLDesignSystem,HLCallAudio}` dùng chung; `macOS/HandLive` (menu bar, extension camera, driver micro); `iOS/HandLive` + `iOS/NotificationService` |
| `relay/` | Rust | Cargo workspace: `crates/relay-server`, `crates/relay-push`, `migrations/` |
| `shared/` | — | `test-vectors/`, `schemas/`, `design-tokens/` — nguồn: `docs/detailed-design/00-common-specs.md` và design system |
| `tools/` | Python | `docs/` (tài liệu), `bench/` (đo trễ), `vectors/` (sinh test vector) |

Chi tiết module và thẻ việc: `plans/20260925-implementation/phase-00-khung-va-dung-chung.md`.

## Điểm bắt đầu implement

Phase 0 (khung kho, giao thức, mã hóa, token, CI) → cổng G0 → Phase 1 (bảng nhớ tạm MVP). Xem `plans/20260925-implementation/plan.md` và `docs/project-roadmap.md`.
