#!/usr/bin/env python3
"""Sinh Color Sets và mã Swift của HLDesignSystem từ shared/design-tokens/tokens.json.

Cách dùng (từ bất kỳ thư mục nào):
    python3 apple/Packages/HLDesignSystem/Scripts/generate-design-tokens.py          # ghi file
    python3 apple/Packages/HLDesignSystem/Scripts/generate-design-tokens.py --check  # exit 1 nếu lệch
"""
from __future__ import annotations

import argparse
import shutil
import sys
from pathlib import Path

SCRIPT_DIR = Path(__file__).resolve().parent
sys.path.insert(0, str(SCRIPT_DIR))
sys.dont_write_bytecode = True  # không để __pycache__ trong kho

from design_tokens_asset_catalog import CATALOG_DIR, render_asset_catalog  # noqa: E402
from design_tokens_model import load_colors, load_metrics, load_text_styles, load_tokens  # noqa: E402
from design_tokens_swift_sources import GENERATED_DIR, render_swift_sources  # noqa: E402

PACKAGE_DIR = SCRIPT_DIR.parent
REPO_ROOT = PACKAGE_DIR.parent.parent.parent
DEFAULT_TOKENS = REPO_ROOT / "shared/design-tokens/tokens.json"
FONTS_DIR = PACKAGE_DIR / "Sources/HLDesignSystem/Resources/Fonts"
OWNED_DIRS = (CATALOG_DIR, GENERATED_DIR)  # thư mục do script sở hữu hoàn toàn


def render_all(tokens_path: Path) -> dict[str, str]:
    tokens = load_tokens(tokens_path)
    colors = load_colors(tokens)
    styles = load_text_styles(tokens)
    metrics = {family: load_metrics(tokens, family) for family in ("spacing", "radius", "size", "duration")}
    missing = sorted(
        {s.postscript_name for s in styles if s.postscript_name}
        - {path.stem for path in FONTS_DIR.glob("*.ttf")}
    )
    if missing:
        raise SystemExit(f"Thiếu file font trong {FONTS_DIR}: {', '.join(missing)}")
    return {**render_asset_catalog(colors), **render_swift_sources(colors, styles, metrics)}


def existing_files() -> set[str]:
    found = set()
    for owned in OWNED_DIRS:
        root = PACKAGE_DIR / owned
        if root.exists():
            found |= {str(p.relative_to(PACKAGE_DIR)) for p in root.rglob("*") if p.is_file()}
    return found


def check(expected: dict[str, str]) -> int:
    problems = []
    for relative, content in sorted(expected.items()):
        path = PACKAGE_DIR / relative
        if not path.exists():
            problems.append(f"thiếu: {relative}")
        elif path.read_text(encoding="utf-8") != content:
            problems.append(f"lệch: {relative}")
    problems += [f"thừa: {relative}" for relative in sorted(existing_files() - expected.keys())]
    if problems:
        print("Token Apple lệch với tokens.json — chạy lại generate-design-tokens.py:", file=sys.stderr)
        print("\n".join(f"  {line}" for line in problems), file=sys.stderr)
        return 1
    print(f"OK: {len(expected)} file khớp tokens.json")
    return 0


def write(expected: dict[str, str]) -> int:
    for owned in OWNED_DIRS:
        shutil.rmtree(PACKAGE_DIR / owned, ignore_errors=True)
    for relative, content in expected.items():
        path = PACKAGE_DIR / relative
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(content, encoding="utf-8")
    print(f"Đã sinh {len(expected)} file vào {PACKAGE_DIR}")
    return 0


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("--check", action="store_true", help="sinh vào bộ nhớ, so với file đã commit")
    parser.add_argument("--tokens", type=Path, default=DEFAULT_TOKENS, help="đường dẫn tokens.json")
    args = parser.parse_args()
    expected = render_all(args.tokens)
    return check(expected) if args.check else write(expected)


if __name__ == "__main__":
    sys.exit(main())
