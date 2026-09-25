"""Trích ví dụ JSON từ tài liệu thiết kế, thay placeholder và phân loại theo schema.

Quy tắc (ghi lại trong tools/schemas/README.md):
- Khối ```json: thử parse cả khối; không được thì parse từng dòng khác rỗng.
  Dòng không parse được là lỗi tài liệu (phải nằm trong KNOWN_SPEC_ISSUES).
- Inline code `{"...}`: chỉ nhận khi parse được; inline không phải JSON là ký hiệu,
  không phải ví dụ, nên bỏ qua.
- Placeholder = chuỗi dạng "<...>", chuỗi chứa "…", hoặc đúng "...". Thay theo TÊN
  KHÓA chứa nó (PLACEHOLDER_BY_KEY); khóa không có quy tắc -> lỗi, không bỏ qua.
"""

from __future__ import annotations

import base64
import json
import re
from dataclasses import dataclass, field
from pathlib import Path

# Giá trị thay cho placeholder, chọn theo tên khóa. Mỗi giá trị hợp lệ theo kiểu 0.3.
PLACEHOLDER_BY_KEY = {
    "id": "01920000-0000-7000-8000-000000000000",  # uuid-v7
    "re": "01920000-0000-7000-8000-000000000000",  # uuid-v7 (id của yêu cầu)
    "pair_id": "00000000-0000-4000-8000-000000000000",  # uuid-v4
    "device_id": "00000000-0000-8000-8000-000000000000",  # uuid-v8
    "payload": base64.b64encode(bytes(40)).decode(),  # b64 có padding: nonce(24)+tag(16)
    "eph": base64.urlsafe_b64encode(bytes(32)).decode().rstrip("="),  # b64u 32 byte
    "nonce": base64.urlsafe_b64encode(bytes(32)).decode().rstrip("="),
    "mac": base64.urlsafe_b64encode(bytes(32)).decode().rstrip("="),
}

# Ví dụ trong tài liệu biết là sai so với đặc tả (spec tự mâu thuẫn). Khóa: (file, dòng).
# Không sửa docs/ ở thẻ S0.2; đề xuất sửa nằm trong báo cáo phase-00-S0.2.md.
KNOWN_SPEC_ISSUES: dict[tuple[str, int], str] = {}

HEADING_TYPE_OP = re.compile(r"WS (session|capability)/([a-z_]+)")
HEADING_TYPE_ONLY = re.compile(r"`(session|capability)` op")
PLACEHOLDER = re.compile(r"^<[^<>]+>$")
SCOPED_TYPES = ("session", "capability")


@dataclass
class Example:
    file: str
    line: int
    heading: str
    source: str  # "block" | "inline"
    obj: object = None
    parse_error: str | None = None
    substitutions: list[str] = field(default_factory=list)

    @property
    def where(self) -> str:
        return f"{self.file}:{self.line}"


def _is_placeholder(value: str) -> bool:
    return bool(PLACEHOLDER.match(value)) or "…" in value or value == "..."


def substitute_placeholders(obj, subs: list[str], key: str | None = None):
    """Thay placeholder đệ quy theo tên khóa; ghi lại từng lần thay vào subs."""
    if isinstance(obj, dict):
        return {k: substitute_placeholders(v, subs, k) for k, v in obj.items()}
    if isinstance(obj, list):
        return [substitute_placeholders(v, subs, key) for v in obj]
    if isinstance(obj, str) and _is_placeholder(obj):
        if key not in PLACEHOLDER_BY_KEY:
            raise ValueError(f"placeholder {obj!r} ở khóa {key!r} không có quy tắc thay")
        subs.append(f"{key}: {obj!r} -> {PLACEHOLDER_BY_KEY[key]!r}")
        return PLACEHOLDER_BY_KEY[key]
    return obj


def extract_examples(path: Path) -> list[Example]:
    """Mọi đối tượng JSON trong khối ```json và inline code của một file markdown."""
    examples: list[Example] = []
    lines = path.read_text(encoding="utf-8").splitlines()
    heading, in_block, block_start, block = "", False, 0, []
    for no, text in enumerate(lines, start=1):
        if in_block:
            if text.strip().startswith("```"):
                examples.extend(_block_examples(path.name, heading, block_start, block))
                in_block = False
            else:
                block.append((no, text))
            continue
        if text.startswith("```json"):
            in_block, block_start, block = True, no, []
            continue
        if text.startswith("#"):
            heading = text
        for span in re.findall(r"`(\{\"[^`]*\})`", text):
            try:
                examples.append(Example(path.name, no, heading, "inline", json.loads(span)))
            except json.JSONDecodeError:
                pass  # ký hiệu kiểu {"op":"<tên>", ...}, không phải ví dụ
    return examples


def _block_examples(file: str, heading: str, start: int, block) -> list[Example]:
    try:
        return [Example(file, start + 1, heading, "block", json.loads("\n".join(t for _, t in block)))]
    except json.JSONDecodeError:
        pass
    out = []
    for no, text in block:
        if not text.strip():
            continue
        try:
            out.append(Example(file, no, heading, "block", json.loads(text)))
        except json.JSONDecodeError as exc:
            out.append(Example(file, no, heading, "block", parse_error=str(exc)))
    return out


def classify(ex: Example, strict_payload: bool) -> str | None:
    """Tên schema cần kiểm (tên file bỏ .schema.json, '#ack' cho ack của op) hoặc None nếu ngoài phạm vi.

    strict_payload=True (00-common-specs): {op, data} ngoài mục session/capability kiểm bằng payload.schema.
    """
    obj = ex.obj
    if not isinstance(obj, dict):
        return None
    scoped_type, scoped_op = _heading_scope(ex.heading)
    if "v" in obj and "type" in obj:
        return "envelope"
    if "re" in obj and "ok" in obj:
        if scoped_type == "session" and scoped_op == "rekey" and obj.get("ok") is True:
            return "session-rekey#ack"
        return "ack"
    if "op" in obj:
        if scoped_type and (scoped_op is None or scoped_op == obj["op"]):
            return f"{scoped_type}-{obj['op']}"
        if strict_payload:
            return "payload"
    return None


def _heading_scope(heading: str) -> tuple[str | None, str | None]:
    m = HEADING_TYPE_OP.search(heading)
    if m:
        return m.group(1), m.group(2)
    m = HEADING_TYPE_ONLY.search(heading)
    if m:
        return m.group(1), None
    return None, None


def decode_handshake_payload(envelope: dict):
    """Envelope session mang b64 của JSON chưa mã hóa (0.5.1): trả plaintext đã parse, hoặc None."""
    if envelope.get("type") != "session":
        return None
    try:
        return json.loads(base64.b64decode(envelope["payload"], validate=True))
    except (ValueError, KeyError, TypeError):
        return None
