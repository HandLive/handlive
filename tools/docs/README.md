# tools/docs — công cụ cho tài liệu thiết kế

| Script | Việc | Chạy |
|--------|------|------|
| `validate_design_docs.py` | Kiểm 33 chức năng lá trong `docs/detailed-design/` (bản tiếng Anh `0N-*.md` và tiếng Việt `0N-*.vi.md`, nhãn khuôn mẫu theo README §3.1) theo khuôn năm mục, bảng bước khớp lưu đồ, nhãn Mermaid hợp lệ | `python3 tools/docs/validate_design_docs.py` — phải in `problems=0` |
| `check_bilingual_docs.py` | Kiểm tài liệu song ngữ (C20): mỗi `X.md` (tiếng Anh, bản chuẩn) có `X.vi.md` (tiếng Việt); dòng 1 là thanh chọn ngôn ngữ; cùng tiêu đề, bảng, khối mã (json, sql, mermaid so khung), token kỹ thuật trong inline code; liên kết đúng bản ngôn ngữ và anchor tồn tại | `python3 tools/docs/check_bilingual_docs.py [--allow-missing] [file …]` — phải in `problems=0` |
| `apple_diacritics.py` | Chuyển dấu kiểu Apple (hoá→hóa, huỷ→hủy, thuỷ→thủy) cho vần mở oa/oe/uy; không đụng "hoàn", "ngoài", "quỷ" | `python3 tools/docs/apple_diacritics.py docs/**/*.md` (chạy thử); thêm `--write` để ghi |
| `build_design_html.py` | Xuất `docs/detailed-design/` thành một trang HTML (Mermaid) theo từng ngôn ngữ: `build/docs/handlive-detailed-design.html` (tiếng Anh, `X.md`) và `handlive-detailed-design.vi.html` (tiếng Việt, `X.vi.md`) | `$HOME/.claude/skills/.venv/bin/python3 tools/docs/build_design_html.py [--lang en\|vi]` (cần gói `markdown`) |

Chạy `validate_design_docs.py` sau mỗi lần sửa `docs/detailed-design/`.
