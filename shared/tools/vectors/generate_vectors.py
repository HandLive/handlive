"""Sinh lại shared/test-vectors/*.json từ giá trị cố định.

    tools/.venv/bin/python tools/vectors/generate_vectors.py          # ghi file
    tools/.venv/bin/python tools/vectors/generate_vectors.py --check  # so byte-exact, exit 1 nếu lệch
"""
import json
import sys
from pathlib import Path

sys.dont_write_bytecode = True  # không để lại __pycache__ trong kho
sys.path.insert(0, str(Path(__file__).resolve().parent))

import build_identity_session_vectors  # noqa: E402
import build_message_vectors  # noqa: E402
import build_primitive_vectors  # noqa: E402

OUT_DIR = Path(__file__).resolve().parents[2] / "test-vectors"  # gốc kho shared/


def render_all() -> dict[str, str]:
    files = build_primitive_vectors.build()
    session_files, ctx = build_identity_session_vectors.build()
    files.update(session_files)
    files.update(build_message_vectors.build(ctx))
    return {name: json.dumps(doc, indent=2, ensure_ascii=False) + "\n" for name, doc in sorted(files.items())}


def main() -> int:
    check = "--check" in sys.argv[1:]
    rendered = render_all()
    bad = []
    for name, text in rendered.items():
        path = OUT_DIR / name
        if check:
            if not path.exists() or path.read_bytes() != text.encode():
                bad.append(name)
        else:
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_bytes(text.encode())
    extra = sorted(p.name for p in OUT_DIR.glob("*.json") if p.name not in rendered and not p.name.startswith("envelope-roundtrip")) if check else []
    for name in bad:
        print(f"LỆCH: {name}")
    for name in extra:
        print(f"THỪA (không do script sinh): {name}")
    print(f"{'check' if check else 'write'}: {len(rendered)} file, {len(bad)} lệch")
    return 1 if bad else 0


if __name__ == "__main__":
    sys.exit(main())
