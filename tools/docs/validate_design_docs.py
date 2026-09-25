"""Validate HandLive detailed-design markdown files against the agreed template.

Each leaf-function file exists in English (`0N-*.md`, canonical) and Vietnamese (`0N-*.vi.md`); the
template labels differ per language (detailed-design README §3.1). A file that is not `.vi.md` but
still carries the Vietnamese labels is validated as Vietnamese, so the check also works while a
translation is pending.
"""
import re
import sys
from pathlib import Path

DOC_DIR = Path(__file__).resolve().parents[2] / "docs" / "detailed-design"
COMMON = DOC_DIR / "00-common-specs.md"
GROUP_FILES = sorted(p for p in DOC_DIR.glob("0[1-8]-*.md"))

TEMPLATES = {
    "vi": {
        "sections": ["Thông tin chung", "Màn hình", "Mô tả chi tiết các thành phần", "Luồng nghiệp vụ", "Đặc tả API/service"],
        "info": ["Tên", "Mô tả", "Tác nhân", "Điều kiện trước", "Điều kiện sau", "Ngoại lệ", "Yêu cầu đặc biệt"],
        "component": ["#", "Trường", "Kiểu dữ liệu", "Input/Output", "Giá trị khởi tạo", "Mô tả"],
        "step": ["Bước", "Tác nhân", "Thành phần", "Mô tả"],
        "screen_na": "N/A — chưa có wireframe được duyệt.",
        "lanes": ('subgraph ND["Người dùng"]', 'subgraph HT["Hệ thống"]'),
        "sql_label": "[Thiết kế]",
    },
    "en": {
        "sections": ["General information", "Screens", "Component details", "Business flow", "API/service specification"],
        "info": ["Name", "Description", "Actors", "Preconditions", "Postconditions", "Exceptions", "Special requirements"],
        "component": ["#", "Field", "Data type", "Input/Output", "Initial value", "Description"],
        "step": ["Step", "Actor", "Component", "Description"],
        "screen_na": "N/A — no approved wireframe yet.",
        "lanes": ('subgraph ND["User"]', 'subgraph HT["System"]'),
        "sql_label": "[Design]",
    },
}


def file_language(path, text):
    """`.vi.md` is Vietnamese; any other file is English unless it still has the Vietnamese labels."""
    if path.name.endswith(".vi.md"):
        return "vi"
    return "vi" if re.search(r"^### \d+\.\d+\.1 Thông tin chung$", text, flags=re.M) else "en"


def load_common_vocab():
    text = COMMON.read_text(encoding="utf-8")
    vi_common = DOC_DIR / "00-common-specs.vi.md"
    if vi_common.exists():
        text += "\n" + vi_common.read_text(encoding="utf-8")
    error_codes = set(re.findall(r"^\| `([A-Z][A-Z0-9_]+)` \|", text, flags=re.M))
    error_codes |= set(re.findall(r"^\| \d{3} \| `([A-Z][A-Z0-9_]+)` \|", text, flags=re.M))
    ops = set()
    for m in re.finditer(r"^\| `([a-z_]+)` \| `([a-z_]+)`(?: / `([a-z_]+)`)? \|", text, flags=re.M):
        ops.add(f"{m.group(1)}/{m.group(2)}")
        if m.group(3):
            ops.add(f"{m.group(1)}/{m.group(3)}")
    for m in re.finditer(r"^\| `call_audio` \| `([^|]+)` \|", text, flags=re.M):
        for op in re.findall(r"`?([a-z_]+)`?", m.group(1)):
            ops.add(f"call_audio/{op}")
    tables = set(re.findall(r"CREATE TABLE (\w+)", text))
    constants = set(re.findall(r"^\| `([A-Z][A-Z0-9_]+)`(?: / `([A-Z][A-Z0-9_]+)`)? \|", text, flags=re.M))
    constants = {c for pair in constants for c in pair if c}
    return error_codes, ops, tables, constants


def first_table_rows(block):
    """Rows of the first contiguous markdown table in block."""
    lines, started = [], False
    for line in block.splitlines():
        if line.strip().startswith("|"):
            started = True
            lines.append(line)
        elif started:
            break
    return table_rows("\n".join(lines))


def split_leaves(text):
    """Return list of (heading, body) for each `## N.M CODE — ...` leaf."""
    parts = re.split(r"^(## \d+\.\d+ [A-Z]+-\d+ — .+)$", text, flags=re.M)
    leaves = []
    for i in range(1, len(parts), 2):
        leaves.append((parts[i].strip(), parts[i + 1]))
    return leaves


def table_rows(block):
    rows = []
    for line in block.splitlines():
        line = line.strip()
        if line.startswith("|") and not re.match(r"^\|[\s:|-]+\|$", line):
            cells = [c.strip() for c in line.strip("|").split("|")]
            rows.append(cells)
    return rows


def check_leaf(fname, heading, body, vocab, problems, lang):
    error_codes, ops, tables, constants = vocab
    tpl = TEMPLATES[lang]
    num = re.match(r"## (\d+\.\d+) ", heading).group(1)
    subs = re.split(rf"^### ({re.escape(num)}\.\d) (.+)$", body, flags=re.M)
    found = [(subs[i], subs[i + 1].strip(), subs[i + 2]) for i in range(1, len(subs), 3)]
    titles = [t for _, t, _ in found]
    if titles != tpl["sections"]:
        problems.append(f"{fname} {heading}: sections {titles} != expected five")
        return
    sec = {i: b for i, (_, _, b) in enumerate(found)}

    info = first_table_rows(sec[0])
    info_keys = [r[0] for r in info[1:]] if info else []
    if info_keys != tpl["info"]:
        problems.append(f"{fname} {heading}: '{tpl['sections'][0]}' rows {info_keys}")

    if tpl["screen_na"] not in sec[1]:
        problems.append(f"{fname} {heading}: '{tpl['sections'][1]}' is not the agreed N/A sentence")

    comp = table_rows(sec[2])
    if not comp or comp[0] != tpl["component"]:
        problems.append(f"{fname} {heading}: component table header {comp[0] if comp else None}")

    flow = sec[3]
    mm = re.search(r"```mermaid\n(.*?)```", flow, flags=re.S)
    if not mm:
        problems.append(f"{fname} {heading}: no mermaid flowchart")
    else:
        chart = mm.group(1)
        if not chart.lstrip().startswith("flowchart TB"):
            problems.append(f"{fname} {heading}: chart must start with 'flowchart TB'")
        nd = chart.find(tpl["lanes"][0])
        ht = chart.find(tpl["lanes"][1])
        if nd < 0 or ht < 0 or nd > ht:
            problems.append(f"{fname} {heading}: lanes ND/HT missing or out of order")
        chart_steps = set(re.findall(r'[\[{]"\((\w+)\) ', chart))
        for bad in re.findall(r'"(\w{1,4})[.)] ', chart):
            problems.append(f"{fname} {heading}: label starts with list marker '{bad}.' (use '({bad}) ')")
        step_word = tpl["step"][0]
        step_rows = [r for r in table_rows(flow) if r and r[0] != step_word]
        header = [r for r in table_rows(flow) if r and r[0] == step_word]
        if not header or header[0][:4] != tpl["step"]:
            problems.append(f"{fname} {heading}: step table header {header[0] if header else None}")
        table_steps = {r[0] for r in step_rows}
        missing = sorted(s for s in chart_steps if s not in table_steps)
        if missing:
            problems.append(f"{fname} {heading}: chart steps not in table: {missing}")
        for label in re.findall(r'"([^"]*)"', chart):
            if ";" in label:
                problems.append(f"{fname} {heading}: ';' inside mermaid label: {label}")

    api = sec[4]
    if "#### Query" not in api and not api.strip().startswith("N/A"):
        problems.append(f"{fname} {heading}: API section lacks '#### Query'")
    for m in re.finditer(r"```sql\n(.*?)```", api, flags=re.S):
        sql = m.group(1)
        stmts = [s for s in re.split(r";\s*\n", sql) if re.search(r"\b(SELECT|INSERT|UPDATE|DELETE|CREATE)\b", s)]
        if stmts and tpl["sql_label"] not in sql:
            problems.append(f"{fname} {heading}: SQL block without {tpl['sql_label']} label")
        for t in re.findall(r"\b(?:FROM|INTO|UPDATE|JOIN)\s+(\w+)", sql):
            if t.lower() not in {x.lower() for x in tables} and t.upper() not in {"EXCLUDED", "SET"}:
                problems.append(f"{fname} {heading}: SQL references unknown table '{t}'")

    error_families = ("BAD_REQUEST", "UNSUPPORTED_", "FEATURE_DISABLED", "PERMISSION_MISSING", "RATE_LIMITED",
                      "PAYLOAD_TOO_LARGE", "NOT_CONNECTED", "NOT_PAIRED", "QR_", "PAIRING_CLOSED", "PIN_INVALID",
                      "AUTH_FAILED", "PAIR_", "DECRYPT_FAILED", "TLS_PIN", "CLIP_", "SMS_", "CALL_", "CAM_", "USB_ADB",
                      "MAC_", "SHIZUKU_", "CHALLENGE_EXPIRED", "SIGNATURE_INVALID", "TOKEN_EXPIRED", "DEVICE_NOT_FOUND",
                      "DEVICE_REVOKED", "PUSH_TOKEN", "PUSH_PROVIDER")
    non_error_prefixes = ("CALL_STATE", "CALL_COMPANION", "CALL_AUDIO_INTERCEPTION", "SMS_RECEIVED", "PAIR_ID")
    for code in set(re.findall(r"`([A-Z][A-Z0-9]+(?:_[A-Z0-9]+)+)`", body)):
        if not code.startswith(error_families) or code.startswith(non_error_prefixes):
            continue
        if code not in error_codes and code not in constants:
            problems.append(f"{fname} {heading}: error-like token `{code}` not in error registry or constants")

    for op in set(re.findall(r"`WS ([a-z_]+/[a-z_]+)`", body)):
        if op not in ops:
            problems.append(f"{fname} {heading}: `WS {op}` not in message catalog")


def main():
    vocab = load_common_vocab()
    problems = []
    leaf_count = 0
    for f in GROUP_FILES:
        text = f.read_text(encoding="utf-8")
        lang = file_language(f, text)
        leaves = split_leaves(text)
        leaf_count += len(leaves)
        if not leaves:
            problems.append(f"{f.name}: no leaf functions found")
        for heading, body in leaves:
            check_leaf(f.name, heading, body, vocab, problems, lang)
    print(f"files={len(GROUP_FILES)} leaves={leaf_count} problems={len(problems)}")
    for p in problems:
        print(" -", p)
    return 1 if problems else 0


if __name__ == "__main__":
    sys.exit(main())
