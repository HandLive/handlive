"""Kiểm MỌI vector trong shared/test-vectors/*.json bằng thư viện độc lập với phía sinh.

    tools/.venv/bin/python tools/vectors/verify_vectors.py

Exit 0 khi mọi phép kiểm đạt; in từng lỗi và exit 1 nếu có sai.
"""
import json
import sys
from pathlib import Path

sys.dont_write_bytecode = True  # không để lại __pycache__ trong kho
sys.path.insert(0, str(Path(__file__).resolve().parent))

import verify_message_checks  # noqa: E402
import verify_primitive_checks  # noqa: E402
import verify_session_checks  # noqa: E402
from verify_common import Checker  # noqa: E402

VEC_DIR = Path(__file__).resolve().parents[2] / "test-vectors"  # gốc kho shared/
REQUIRED_KEYS = {"description", "source", "vectors"}


def main() -> int:
    docs = {p.name: json.loads(p.read_text(encoding="utf-8")) for p in sorted(VEC_DIR.glob("*.json"))}
    checks = {**verify_primitive_checks.CHECKS, **verify_session_checks.CHECKS, **verify_message_checks.CHECKS}
    c = Checker()
    for name in checks:
        c.true(f"{name} tồn tại", name in docs)
    for name, doc in docs.items():
        if name not in checks:
            print(f"bỏ qua (không có bộ kiểm): {name}")
            continue
        c.true(f"{name} có description/source/vectors", REQUIRED_KEYS <= set(doc))
        c.true(f"{name} có ≥ 2 vector", len(doc["vectors"]) >= 2)
        c.true(f"{name} tên vector duy nhất", len({v["name"] for v in doc["vectors"]}) == len(doc["vectors"]))
        before_count, before_fail = c.count, len(c.failures)
        fn = checks[name]
        try:
            fn(c, doc, docs) if fn.__code__.co_argcount == 3 else fn(c, doc)
        except Exception as exc:  # lỗi cấu trúc file cũng là lỗi kiểm
            c.failures.append(f"{name}: ngoại lệ {type(exc).__name__}: {exc}")
        n_inv = len(doc.get("invalid_vectors", []))
        status = "OK " if len(c.failures) == before_fail else "SAI"
        print(f"{status} {name:26s} {len(doc['vectors']):2d} vector, {n_inv:2d} vector âm, {c.count - before_count:3d} phép kiểm")
    for f in c.failures:
        print(f"  LỖI: {f}")
    print(f"Tổng: {c.count} phép kiểm, {len(c.failures)} lỗi")
    return 1 if c.failures else 0


if __name__ == "__main__":
    sys.exit(main())
