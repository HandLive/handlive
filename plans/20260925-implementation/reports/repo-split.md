# Tách kho: năm repo trong một workspace (25/09/2026)

**Lý do:** chủ dự án yêu cầu mỗi phần là một repo riêng để sau này đưa vào một group. Quyết định I1
trong `plan.md` cập nhật từ monorepo sang năm kho.

## Bố cục đã chọn

Kho hub `handlive` (thư mục `HandLive/`) giữ tài liệu, kế hoạch, `tools/docs/`,
`tools/workspace.sh`. Bốn kho thành phần nằm **bên trong** thư mục hub và được hub git-ignore:
`android/` = `handlive-android`, `apple/` = `handlive-apple`, `relay/` = `handlive-relay`, `shared/`
= `handlive-shared`. Chọn bố cục lồng thay vì thư mục anh em vì mọi đường dẫn tương đối hiện có
(`../shared` trong Gradle, test Kotlin, Swift, Rust; `../docs` trong test HLDesignSystem) giữ
nguyên, không phải sửa mã build hay test, và agent làm việc như trước. CI của từng kho dựng lại đúng
bố cục bằng `actions/checkout` (hub ở gốc khi cần tài liệu, phần vào `<phần>/`, `handlive-shared`
vào `shared/`).

Thay đổi kèm theo: `tools/vectors`, `tools/schemas` và venv chuyển sang `shared/tools/` (đi cùng dữ
liệu chúng sinh/kiểm; `check_schemas.py` đọc `../docs/detailed-design`, ghi đè bằng
`HANDLIVE_DOCS_DIR`); mỗi kho có `.gitignore` đầy đủ, `CLAUDE.md`, `README.md`, workflow CI riêng
(`workflow_dispatch` để chạy tay khi `shared/` đổi); hub chỉ còn `ci-docs.yml`; test HLDesignSystem
phát hiện mã Swift sinh sẵn lệch với 4 token thêm sáng nay → sinh lại.

Lịch sử: tách bằng `git subtree split` nên mỗi kho con giữ các commit Phase 0 chạm tới phần mình
(hash mới). Lịch sử của `tools/vectors`, `tools/schemas` trước khi chuyển chỉ còn trong kho hub.
Hash trong `phase-00-*.md` là của kho hub trước khi tách. Lịch sử cả năm kho được viết lại ngày 25/09/2026 (danh tính tác giả `Hồ Xuân Dũng <me@hxd.vn>`, bỏ trailer đồng tác giả) — bảng dưới ghi hash sau khi viết lại.

## Commit

| Kho | Nhánh | Commit |
|-----|-------|--------|
| handlive (hub) | `feat/phase-00-khung` | 5f03540 refactor(shared): move vector and schema tools next to the data they check · 91dd0a1 fix(apple): look for the Python venv under shared/tools · ecd5b32 refactor: extract android, apple, relay and shared into their own repositories · b318923 ci: keep only the documentation workflow in the hub · 7999b79 feat(tools): add workspace script · 4452139 docs: describe the five-repository workspace and its CI layout · 3616199 docs(plans): record the repository split in decision I1 and the report rules |
| handlive-android | `main` (4 commit Phase 0 + 3) | f613216 build(android): ignore Gradle output and local config · 03000cb ci: check out handlive-shared beside the repo · 4e1014e docs: add README and CLAUDE.md |
| handlive-apple | `main` (5 + 4) | 31217a6 build(apple): ignore generated project, build output and signing files · 7d11838 ci: check out the hub and handlive-shared around the repo · 08331f3 docs: describe the standalone repo · bcc7291 feat(apple): regenerate design tokens for the switch-thumb, on-icon-fill and row-icon tokens |
| handlive-relay | `main` (1 + 3) | 01b08b5 build(relay): ignore target and dotenv files · 6060675 ci: check out handlive-shared beside the repo · 9ba4873 docs: describe the standalone repo |
| handlive-shared | `main` (8 + 3) | d4d34e2 build(shared): ignore the tools venv and Python caches · e987fdc ci: check out the hub docs beside the repo · eb67776 docs: add README and CLAUDE.md |

## Kiểm chứng sau khi tách

- Hub: `python3 tools/docs/validate_design_docs.py` → `problems=0`; `tools/workspace.sh status` cả
  năm kho sạch.
- shared (chạy từ `shared/`): `verify_vectors.py` 360 phép kiểm 0 lỗi; `generate_vectors.py --check`
  14 file 0 lệch; `check_schemas.py` XANH (đọc `../docs`); guard `HANDLIVE_DOCS_DIR` sai → thoát có
  thông báo.
- apple: `HL_SWIFT_TESTING_PACKAGE=1 swift test` — HLCrypto 19/19, HLDesignSystem 16/16 (đọc
  `../shared/design-tokens`, `../docs/design-system`, `../shared/tools/.venv`).
- android: `./gradlew :core:protocol:test :core:design:test --offline` xanh (JDK 21 tại
  `/opt/homebrew/opt/openjdk@21`).
- relay: `cargo test` 9 passed, 6 ignored (test tích hợp cần Docker) — cargo tại
  `/opt/homebrew/opt/rustup/bin`.
- Chưa chạy: `./gradlew check` đầy đủ, `xcodebuild` (máy không có Xcode), CI thật (chưa có remote).

## Việc của chủ dự án

1. Tạo group/organization và năm repo **đúng tên**: `handlive`, `handlive-android`,
   `handlive-apple`, `handlive-relay`, `handlive-shared` (CI tra tên kho theo
   `github.repository_owner`).
2. Đẩy lên (thay `<group-url>`, ví dụ `git@github.com:handlive`):

```bash
G=<group-url>; cd /Users/hxd/HandLive
for p in android apple relay shared; do git -C $p remote add origin $G/handlive-$p.git && git -C $p push -u origin main; done
git remote add origin $G/handlive.git && git push -u origin main feat/phase-00-khung
```

3. Kho private: secret `HANDLIVE_REPOS_TOKEN` cấp organization (quyền Contents: read trên năm kho).
   Bật branch protection theo check của từng kho.
4. Khi muốn `main` của hub cập nhật tài liệu:
   `git checkout main && git merge --ff-only feat/phase-00-khung` (hub không còn mã, chỉ tài liệu).

```text
Status: DONE_WITH_CONCERNS
Summary: Năm kho git độc lập trong một workspace, lịch sử giữ nguyên, test ba nền tảng và tools xanh trên bố cục mới.
Concerns/Blockers: CI thật chỉ chạy được sau khi có group; kho private cần HANDLIVE_REPOS_TOKEN; CI nền tảng không tự chạy khi shared đổi (chạy tay).
```
