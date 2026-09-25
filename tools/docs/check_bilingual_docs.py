"""Check that HandLive documents exist in English (`X.md`, canonical) and Vietnamese (`X.vi.md`) and match.

Scope: `README.md`, `docs/**/*.md`, `plans/20260925-implementation/*.md` and its `reports/README.md`.
Archive kept in Vietnamese only (not checked): `plans/2026092[0-4]-*` and task reports.

Checks for every pair:
  1. both files exist (`--allow-missing` turns a missing twin into a warning);
  2. line 1 is the language switcher: `English | [Tiếng Việt](X.vi.md)` or `[English](X.md) | Tiếng Việt`;
  3. the English file reads as English and the Vietnamese file as Vietnamese (share of Vietnamese letters
     in prose; a page that quotes the other language on purpose carries `<!-- i18n: mixed -->`);
  4. same headings: levels, section numbers and leaf IDs (`CLIP-02`) in the same order;
  5. same tables: count, rows and columns;
  6. same fenced code blocks: same language tags; `json`/`jsonc` equal once string values are masked,
     `sql` equal without comments, `mermaid` equal once labels are masked;
  7. same technical tokens in inline code: UPPER_SNAKE codes, `type/op` pairs, dotted keys;
  8. links: `X.vi.md` links to the Vietnamese twin of a page when it exists, `X.md` never links to a
     `.vi.md` page (except the switcher), relative targets and `#anchors` resolve.

Usage: python3 tools/docs/check_bilingual_docs.py [--allow-missing] [path ...]
"""
import argparse
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
SCOPE_GLOBS = ("README.md", "docs/**/*.md", "plans/20260925-implementation/*.md",
               "plans/20260925-implementation/reports/README.md")
EXTERNAL_PREFIXES = ("android/", "apple/", "relay/", "shared/", ".github-org/")
VI_LETTERS = set("ăâđêôơưáàảãạấầẩẫậắằẳẵặéèẻẽẹếềểễệíìỉĩịóòỏõọốồổỗộớờởỡợúùủũụứừửữựýỳỷỹỵ")
MIXED_MARKER = "<!-- i18n: mixed -->"
FENCE = re.compile(r"^```(\S*)\s*$")
LINK = re.compile(r"(?<!!)\[[^\]]*\]\(([^)\s]+)(?:\s+\"[^\"]*\")?\)")
INLINE_CODE = re.compile(r"`([^`\n]+)`")
TECH_TOKEN = re.compile(r"^(?:[A-Z][A-Z0-9]*(?:_[A-Z0-9]+)+|[a-z_]+/[a-z_]+|[a-z][a-z0-9_]*(?:\.[a-z0-9_]+)+)$")
LEAF_ID = re.compile(r"\b[A-Z]{2,6}-\d{2}\b")


def vi_twin(path):
    return path.with_name(path.name[:-3] + ".vi.md")


def en_twin(path):
    return path.with_name(path.name[:-6] + ".md")


def scope_pairs():
    bases = set()
    for pattern in SCOPE_GLOBS:
        for f in ROOT.glob(pattern):
            bases.add(en_twin(f) if f.name.endswith(".vi.md") else f)
    return sorted(bases)


def parse(path):
    """Split a markdown file into prose lines, headings, tables, code blocks and links."""
    lines = path.read_text(encoding="utf-8").splitlines()
    doc = {"lines": lines, "prose": [], "headings": [], "tables": [], "code": [], "links": [], "inline": []}
    in_code, lang, block, table = False, "", [], []

    def close_table():
        if table:
            rows = [r for r in table if not re.match(r"^\|[\s:|-]+\|$", r.strip())]
            cols = len(re.split(r"(?<!\\)\|", rows[0].strip().strip("|"))) if rows else 0
            doc["tables"].append((len(rows), cols))
            table.clear()

    for no, line in enumerate(lines, start=1):
        m = FENCE.match(line.strip())
        if in_code:
            if line.strip() == "```":
                doc["code"].append((lang, block[:], no))
                in_code = False
            else:
                block.append(line)
            continue
        if m:
            close_table()
            in_code, lang, block = True, m.group(1).lower(), []
            continue
        if line.lstrip().startswith("|"):
            table.append(line)
        else:
            close_table()
        if line.startswith("#"):
            level = len(line) - len(line.lstrip("#"))
            text = line[level:].strip()
            num = re.match(r"(\d+(?:\.\d+)*)\b", text)
            doc["headings"].append((level, num.group(1) if num else "", tuple(LEAF_ID.findall(text)), text, no))
        for target in LINK.findall(INLINE_CODE.sub(" ", line)):  # a link written inside `code` is an example
            doc["links"].append((target, no))
        doc["inline"].extend(INLINE_CODE.findall(line))
        doc["prose"].append(INLINE_CODE.sub(" ", LINK.sub(" ", line)))
    close_table()
    return doc


def slugs(doc):
    """GitHub heading anchors of a parsed document."""
    seen, out = {}, set()
    for _, _, _, text, _ in doc["headings"]:
        s = re.sub(r"[^\w\- ]", "", text.lower().replace("`", "")).replace(" ", "-")
        n = seen.get(s, 0)
        seen[s] = n + 1
        out.add(s if n == 0 else f"{s}-{n}")
    return out


def vi_share(doc):
    text = "\n".join(doc["prose"])
    text = re.sub(r"<!--.*?-->", " ", text, flags=re.S)
    letters = [c for c in text.lower() if c.isalpha()]
    if len(letters) < 200:
        return None
    return sum(c in VI_LETTERS for c in letters) / len(letters)


def normalize_code(lang, lines):
    text = "\n".join(lines)
    if lang in ("json", "jsonc"):
        text = re.sub(r'"(?:[^"\\]|\\.)*"(?!\s*:)', '"S"', text)
        text = re.sub(r"//[^\n]*", "", text)
        return re.sub(r"\s+", "", text)
    if lang == "sql":
        text = re.sub(r"--[^\n]*", "", text)
        return re.sub(r"\s+", " ", text).strip()
    if lang == "mermaid":
        out = []
        for raw in text.splitlines():
            line = raw.strip()
            if not line or line.startswith("%%"):
                continue
            line = re.sub(r'"(?:[^"\\]|\\.)*"', '"S"', line)
            line = re.sub(r"\|[^|]*\|", "|S|", line)
            line = re.sub(r"\[[^\]]*\]", "[S]", line)
            line = re.sub(r"\{[^}]*\}", "{S}", line)
            line = re.sub(r"\((?!\()[^)]*\)", "(S)", line)
            line = re.sub(r"^((?:state\s+)?\S+\s*-->\s*\S+)\s*:.*$", r"\1", line)
            line = re.sub(r"^(note\s+\w+\s+of\s+\S+)\s*:.*$", r"\1", line)
            out.append(re.sub(r"\s+", " ", line))
        return "\n".join(out)
    return None


def rel(path):
    return path.relative_to(ROOT).as_posix()


def check_pair(en, vi, docs_cache, problems, warnings):
    en_doc, vi_doc = docs_cache(en), docs_cache(vi)
    where = rel(en)

    expected_en = f"English | [Tiếng Việt]({vi.name})"
    expected_vi = f"[English]({en.name}) | Tiếng Việt"
    if not en_doc["lines"] or en_doc["lines"][0].strip() != expected_en:
        problems.append(f"{where}: line 1 must be `{expected_en}`")
    if not vi_doc["lines"] or vi_doc["lines"][0].strip() != expected_vi:
        problems.append(f"{rel(vi)}: line 1 must be `{expected_vi}`")

    for doc, path, want_vi in ((en_doc, en, False), (vi_doc, vi, True)):
        if MIXED_MARKER in "\n".join(doc["lines"]):
            continue
        share = vi_share(doc)
        if share is None:
            continue
        if not want_vi and share > 0.08:
            problems.append(f"{rel(path)}: reads as Vietnamese ({share:.0%} Vietnamese letters) — not translated?")
        elif not want_vi and share > 0.03:
            warnings.append(f"{rel(path)}: {share:.1%} Vietnamese letters in prose")
        elif want_vi and share < 0.03:
            problems.append(f"{rel(path)}: reads as English ({share:.1%} Vietnamese letters) — not Vietnamese?")

    en_h = [(lvl, num, ids) for lvl, num, ids, _, _ in en_doc["headings"]]
    vi_h = [(lvl, num, ids) for lvl, num, ids, _, _ in vi_doc["headings"]]
    if en_h != vi_h:
        for i, (a, b) in enumerate(zip(en_h, vi_h)):
            if a != b:
                problems.append(f"{where}: heading {i + 1} differs: en {a} (line {en_doc['headings'][i][4]}) "
                                f"vs vi {b} (line {vi_doc['headings'][i][4]})")
                break
        else:
            problems.append(f"{where}: {len(en_h)} headings in English vs {len(vi_h)} in Vietnamese")

    if en_doc["tables"] != vi_doc["tables"]:
        problems.append(f"{where}: tables (rows, columns) differ: en {en_doc['tables']} vs vi {vi_doc['tables']}")

    en_code, vi_code = en_doc["code"], vi_doc["code"]
    if [c[0] for c in en_code] != [c[0] for c in vi_code]:
        problems.append(f"{where}: code block languages differ: en {[c[0] for c in en_code]} vs vi {[c[0] for c in vi_code]}")
    else:
        for (lang, a, line_en), (_, b, line_vi) in zip(en_code, vi_code):
            na, nb = normalize_code(lang, a), normalize_code(lang, b)
            if na is not None and na != nb:
                problems.append(f"{where}: ```{lang} block ending at line {line_en} differs from the Vietnamese one "
                                f"(line {line_vi}) beyond translatable text")

    en_tok = {t for t in en_doc["inline"] if TECH_TOKEN.match(t)}
    vi_tok = {t for t in vi_doc["inline"] if TECH_TOKEN.match(t)}
    if en_tok != vi_tok:
        only_en, only_vi = sorted(en_tok - vi_tok)[:8], sorted(vi_tok - en_tok)[:8]
        problems.append(f"{where}: inline code tokens differ — only in en: {only_en}; only in vi: {only_vi}")


def check_links(path, doc, docs_cache, allow_missing, problems, warnings):
    is_vi = path.name.endswith(".vi.md")
    for target, no in doc["links"]:
        if re.match(r"^[a-z]+:", target) or target.startswith("/"):
            continue
        file_part, _, anchor = target.partition("#")
        dest = (path.parent / file_part).resolve() if file_part else path
        try:
            dest_rel = dest.relative_to(ROOT).as_posix()
        except ValueError:
            continue
        if dest_rel.startswith(EXTERNAL_PREFIXES):
            continue
        if no == 1:
            continue
        if not is_vi and dest.name.endswith(".vi.md"):
            problems.append(f"{rel(path)}:{no}: English page links to the Vietnamese page {file_part}")
        if is_vi and dest.suffix == ".md" and not dest.name.endswith(".vi.md") and file_part:
            twin = vi_twin(dest)
            if twin.exists():
                problems.append(f"{rel(path)}:{no}: link {file_part} should point to {twin.name}")
        if not dest.exists():
            if dest.name.endswith(".vi.md") and allow_missing and en_twin(dest).exists():
                warnings.append(f"{rel(path)}:{no}: {file_part} does not exist yet")
            else:
                problems.append(f"{rel(path)}:{no}: broken link {target}")
            continue
        if anchor and dest.suffix == ".md":
            if anchor.lower() not in slugs(docs_cache(dest)):
                problems.append(f"{rel(path)}:{no}: anchor #{anchor} not found in {dest_rel}")


def main():
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument("--allow-missing", action="store_true", help="report a missing twin as a warning")
    ap.add_argument("paths", nargs="*", help="limit the check to these files (either language)")
    args = ap.parse_args()

    cache = {}

    def docs_cache(p):
        if p not in cache:
            cache[p] = parse(p)
        return cache[p]

    bases = scope_pairs()
    if args.paths:
        wanted = {en_twin(Path(p).resolve()) if p.endswith(".vi.md") else Path(p).resolve() for p in args.paths}
        bases = [b for b in bases if b.resolve() in wanted]
    problems, warnings, missing, pairs = [], [], 0, 0
    for en in bases:
        vi = vi_twin(en)
        present = [p for p in (en, vi) if p.exists()]
        for p in present:
            check_links(p, docs_cache(p), docs_cache, args.allow_missing, problems, warnings)
        if len(present) < 2:
            missing += 1
            gone = rel(vi) if en.exists() else rel(en)
            (warnings if args.allow_missing else problems).append(f"{gone}: missing twin")
            continue
        pairs += 1
        check_pair(en, vi, docs_cache, problems, warnings)
    print(f"pairs={pairs} missing={missing} problems={len(problems)} warnings={len(warnings)}")
    for p in problems:
        print(" -", p)
    for w in warnings[:40]:
        print(" ~", w)
    if len(warnings) > 40:
        print(f" ~ … {len(warnings) - 40} more warnings")
    return 1 if problems else 0


if __name__ == "__main__":
    sys.exit(main())
