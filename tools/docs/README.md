# tools/docs — công cụ cho tài liệu thiết kế

| Script | Việc | Chạy |
|--------|------|------|
| `validate_design_docs.py` | Kiểm 33 chức năng lá trong `docs/detailed-design/` theo khuôn năm mục, bảng bước khớp lưu đồ, nhãn Mermaid hợp lệ | `python3 tools/docs/validate_design_docs.py` — phải in `problems=0` |
| `apple_diacritics.py` | Chuyển dấu kiểu Apple (hoá→hóa, huỷ→hủy, thuỷ→thủy) cho vần mở oa/oe/uy; không đụng "hoàn", "ngoài", "quỷ" | `python3 tools/docs/apple_diacritics.py docs/**/*.md` (chạy thử); thêm `--write` để ghi |
| `build_design_html.py` | Xuất `docs/detailed-design/` thành một trang HTML (Mermaid) vào `build/docs/handlive-detailed-design.html` | `$HOME/.claude/skills/.venv/bin/python3 tools/docs/build_design_html.py` (cần gói `markdown`) |

Chạy `validate_design_docs.py` sau mỗi lần sửa `docs/detailed-design/`.
