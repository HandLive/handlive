# Báo cáo của agent

Mỗi thẻ việc một file `phase-0N-<mã việc>.md` (ví dụ `phase-01-A1.3.md`), spike: `phase-04-spike-d1.md`, `phase-05-spike-d6.md`. Nội dung: việc đã làm, **danh sách commit (kho + hash + tiêu đề) của thẻ việc — mỗi bước hợp lý một commit, không gom; một commit không bao giờ trải hai kho**, đường dẫn tạo/sửa, lệnh test và kết quả (dán đầu ra thật), số đo (nếu có), điểm lệch với tài liệu và cách xử lý, và kết thúc bằng:

```text
Status: DONE | DONE_WITH_CONCERNS | BLOCKED | NEEDS_CONTEXT
Summary: một hai câu
Concerns/Blockers: nếu có
```

Hash trong các báo cáo `phase-00-*` là của kho hub trước khi tách kho (25/09/2026, xem `repo-split.md`); lịch sử tương ứng nằm trong `main` của từng kho thành phần.
