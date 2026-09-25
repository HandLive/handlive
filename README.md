# HandLive

> Kho này là hub tài liệu của HandLive. Điện thoại Android là điểm trung chuyển: nó đưa clipboard, SMS, cuộc gọi kèm âm thanh, camera và mic sang macOS. iPhone và iPad nhận clipboard, SMS và thông tin cuộc gọi.
>
> Phương châm: *"WebSocket cho dữ liệu, Bluetooth cho giọng nói."*

**Trạng thái:** Phase 0 đã xong: khung, giao thức, mã hóa, token và CI. Ứng dụng chưa có tính năng cho người dùng. Mã nguồn nằm ở bốn kho riêng, clone vào thư mục này. Xem mục Cấu trúc.

## HandLive giải quyết gì

Trải nghiệm gần với Microsoft Phone Link và Apple Continuity, nhưng **đi xuyên hệ sinh thái**. Người dùng Android nghe gọi, nhắn tin, đồng bộ clipboard, rồi dùng camera và mic của điện thoại ngay trên máy Mac. Mã hóa đầu-cuối (E2E) luôn bật, không có tùy chọn tắt.

| Tính năng | macOS | iOS/iPadOS |
|-----------|:-----:|:----------:|
| Clipboard hai chiều | ✅ | ✅ |
| SMS nhận và gửi | ✅ | ✅ |
| Thông tin cuộc gọi và điều khiển (nghe, từ chối, kết thúc; giữ máy và DTMF qua Bluetooth HFP) | ✅ | ✅ (thông tin và từ chối, không có âm thanh) |
| **Âm thanh cuộc gọi** (nghe và nói trên máy) | ✅ | ❌ (Apple không mở API HFP phía tai nghe) |
| Camera và mic ảo (Zoom, Meet, FaceTime, OBS) | ✅ | ❌ |

## Kiến trúc tóm tắt

- **WebSocket** là kênh cho mọi dữ liệu: clipboard, SMS, thông tin cuộc gọi, thông báo. Android chạy máy chủ Ktor. Máy trong cùng mạng tự tìm nhau qua mDNS.
- **Bluetooth HFP SCO** chỉ mang **âm thanh cuộc gọi**. Từ Android 10, ứng dụng không thu âm cuộc gọi qua API công khai. HFP là đường đã chứng minh được. Khi HFP bận (tai nghe đang chiếm sóng, hoặc máy ở xa), hệ thống chuyển sang **Opus qua WebSocket**, trễ khoảng 100 đến 150 ms. Đường này cần Shizuku, và chỉ chạy trên một số máy, một số phiên bản Android (plan §13 D10).
- **Mã hóa đầu-cuối** áp dụng toàn hệ thống. Nội dung dùng XChaCha20-Poly1305. Hai máy trao khóa bằng X25519 và HKDF, ghép cặp qua **mã QR**. Âm thanh Opus đi qua hai lớp mã hóa. Âm thanh HFP dựa vào mã hóa của liên kết Bluetooth (plan §13 D11).
- **Cloud relay** (Rust, Actix-web) chỉ chuyển tiếp khối dữ liệu đã mã hóa khi thiết bị ở ngoài mạng nội bộ. Relay không đọc nội dung.

Chi tiết: [`docs/system-architecture.md`](docs/system-architecture.md) và [`plans/20260924-definitive-architecture/plan.md`](plans/20260924-definitive-architecture/plan.md).

## Lộ trình

Xây lần lượt. Mỗi phase là một phần dùng được.

1. **Đồng bộ clipboard** (MVP): Android và macOS qua WebSocket trong mạng nội bộ.
2. **Cầu nối SMS**: thêm ứng dụng iOS, cloud relay và thông báo đẩy.
3. **Thông tin và điều khiển cuộc gọi**: API Telecom công khai (không dùng `InCallService`, quyết định D9), kèm bảng cuộc gọi nổi.
4. **Âm thanh cuộc gọi**: HFP/SCO, dự phòng Opus, khử tiếng vang.
5. **Camera và mic ảo**: CMIOExtension và AudioServerPlugin trên macOS.

Chi tiết: [`docs/project-roadmap.md`](docs/project-roadmap.md).

## Cấu trúc: năm kho, một workspace

Kho này (`handlive`) là **hub**. Hub chỉ giữ tài liệu, kế hoạch và công cụ tài liệu. Mã nguồn nằm ở bốn kho riêng. Clone chúng vào trong thư mục hub. Git của hub bỏ qua bốn thư mục đó. Bố cục này là bắt buộc: build và test đọc `../shared`, test Apple đọc `../docs`.

```
HandLive/                # kho hub "handlive"
├── CLAUDE.md            # Hướng dẫn cho Claude Code (đọc trước)
├── README.md
├── docs/                # Tài liệu dự án (xem docs/codebase-summary.md)
│   ├── detailed-design/ # Thiết kế chi tiết: hợp đồng cho mọi mã
│   └── design-system/   # Design system (bản sao nguồn của artifact)
├── plans/               # Kiến trúc, nghiên cứu, kế hoạch triển khai + reports/
├── tools/docs/          # validate_design_docs.py, apple_diacritics.py, build_design_html.py
├── tools/workspace.sh   # clone <group-url> | status | run <git…>
├── android/             # kho "handlive-android"  (Kotlin, Gradle)
├── apple/               # kho "handlive-apple"    (Swift, macOS + iOS)
├── relay/               # kho "handlive-relay"    (Rust)
├── shared/              # kho "handlive-shared"   (test vector, JSON Schema, design tokens, tools/vectors, tools/schemas)
└── .github-org/         # kho "HandLive/.github": hồ sơ org, CONTRIBUTING, SECURITY, CODE_OF_CONDUCT, mẫu PR/issue
```

```sh
git clone <group-url>/handlive.git HandLive && cd HandLive
tools/workspace.sh clone <group-url>      # ví dụ git@github.com:HandLive
tools/workspace.sh status
```

## Tài liệu

| File | Nội dung |
|------|----------|
| [`docs/project-overview-pdr.md`](docs/project-overview-pdr.md) | Sản phẩm là gì, mục tiêu, phạm vi, ràng buộc |
| [`docs/system-architecture.md`](docs/system-architecture.md) | Kiến trúc, kênh truyền, giao thức, bảo mật |
| [`docs/project-roadmap.md`](docs/project-roadmap.md) | Năm phase và ước lượng công sức |
| [`docs/design-guidelines.md`](docs/design-guidelines.md) | Nguyên tắc trải nghiệm và bảo mật |
| [`docs/code-standards.md`](docs/code-standards.md) | Quy ước code từng nền tảng |
| [`docs/deployment-guide.md`](docs/deployment-guide.md) | Đóng gói và phân phối (App Store, PKG, cloud relay) |
| [`docs/codebase-summary.md`](docs/codebase-summary.md) | Bản đồ codebase, cập nhật khi code đổi |
| [`docs/detailed-design/README.md`](docs/detailed-design/README.md) | Thiết kế chi tiết: 33 chức năng, giao thức, mã lỗi, mô hình dữ liệu |

## Giấy phép

Apache License 2.0. Xem [LICENSE](LICENSE). Giấy phép áp dụng cho cả năm kho của tổ chức [HandLive](https://github.com/HandLive). Cách đóng góp nằm ở [CONTRIBUTING](https://github.com/HandLive/.github/blob/main/CONTRIBUTING.md): commit nhỏ, đứng tên người thật, ký DCO bằng `git commit -s`. Lỗi bảo mật báo kín theo [SECURITY](https://github.com/HandLive/.github/blob/main/SECURITY.md).
