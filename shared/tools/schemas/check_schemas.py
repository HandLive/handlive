"""Kiểm JSON Schema trong shared/schemas/ với ví dụ của tài liệu thiết kế.

Chạy: tools/.venv/bin/python tools/schemas/check_schemas.py
1. Mọi schema hợp lệ theo metaschema draft 2020-12, $id khớp tên file, mọi $ref phân giải được;
   enum mã lỗi và enum type khớp bảng 0.8.1 và 0.7.1.
2. Ví dụ JSON trong 00-common-specs.md (bắt buộc, mọi khối ```json phải được phân loại) và
   ví dụ envelope/ack/session/capability trong 01–08 phải qua schema tương ứng.
3. Mẫu dương tự viết phải qua; mẫu âm phải bị từ chối.
Thoát 0 khi mọi mục xanh.
"""

from __future__ import annotations

import json
import re
import os
import sys
from pathlib import Path

from jsonschema import Draft202012Validator
from jsonschema.exceptions import best_match
from referencing import Registry, Resource

sys.dont_write_bytecode = True  # không để lại __pycache__ trong kho
sys.path.insert(0, str(Path(__file__).resolve().parent))
import doc_examples  # noqa: E402
import sample_messages  # noqa: E402

SHARED_ROOT = Path(__file__).resolve().parents[2]  # gốc kho shared/
SCHEMA_DIR = SHARED_ROOT / "schemas"
# Tài liệu thiết kế nằm ở kho hub (thư mục cha của shared/ trong workspace); ghi đè bằng HANDLIVE_DOCS_DIR.
DOCS_DIR = Path(os.environ.get("HANDLIVE_DOCS_DIR") or SHARED_ROOT.parent / "docs" / "detailed-design")
COMMON_SPECS = DOCS_DIR / "00-common-specs.md"
if not COMMON_SPECS.is_file():
    sys.exit(f"Không thấy {COMMON_SPECS}: đặt HANDLIVE_DOCS_DIR trỏ tới docs/detailed-design của kho hub")
ID_BASE = "https://handlive.app/schemas/v1/"


class Report:
    def __init__(self) -> None:
        self.failures: list[str] = []
        self.counts: dict[str, int] = {}

    def ok(self, bucket: str) -> None:
        self.counts[bucket] = self.counts.get(bucket, 0) + 1

    def fail(self, message: str) -> None:
        self.failures.append(message)
        print(f"  FAIL {message}")


def load_schemas(report: Report) -> tuple[dict[str, dict], Registry]:
    schemas: dict[str, dict] = {}
    for path in sorted(SCHEMA_DIR.glob("*.schema.json")):
        schema = json.loads(path.read_text(encoding="utf-8"))
        name = path.name.removesuffix(".schema.json")
        try:
            Draft202012Validator.check_schema(schema)
        except Exception as exc:  # SchemaError
            report.fail(f"{path.name}: không hợp lệ theo metaschema: {exc}")
            continue
        if schema.get("$id") != ID_BASE + path.name:
            report.fail(f"{path.name}: $id = {schema.get('$id')!r}, cần {ID_BASE + path.name!r}")
            continue
        schemas[name] = schema
        report.ok("schema hợp lệ metaschema")
    registry = Registry().with_resources(
        (s["$id"], Resource.from_contents(s)) for s in schemas.values()
    )
    return schemas, registry


def check_refs(schemas: dict[str, dict], registry: Registry, report: Report) -> None:
    for name, schema in schemas.items():
        resolver = registry.resolver(base_uri=schema["$id"])
        for ref in _collect_refs(schema):
            try:
                resolver.lookup(ref)
                report.ok("$ref phân giải được")
            except Exception as exc:
                report.fail(f"{name}: $ref {ref!r} không phân giải được: {exc}")


def _collect_refs(node) -> list[str]:
    if isinstance(node, dict):
        refs = [node["$ref"]] if isinstance(node.get("$ref"), str) else []
        return refs + [r for v in node.values() for r in _collect_refs(v)]
    if isinstance(node, list):
        return [r for v in node for r in _collect_refs(v)]
    return []


def check_enums_match_spec(schemas: dict[str, dict], report: Report) -> None:
    text = COMMON_SPECS.read_text(encoding="utf-8")
    table = text.split("### 0.8.1", 1)[1].split("### 0.8.2", 1)[0]
    spec_codes = re.findall(r"^\| `([A-Z0-9_]+)` \|", table, re.M)
    schema_codes = schemas["error"]["$defs"]["code"]["enum"]
    if spec_codes == schema_codes:
        report.ok("enum khớp bảng spec")
    else:
        report.fail(f"error.code lệch 0.8.1: thiếu {set(spec_codes) - set(schema_codes)}, "
                    f"thừa {set(schema_codes) - set(spec_codes)}")
    section = text.split("### 0.7.1", 1)[1].split("### 0.7.2", 1)[0]
    spec_types = set(re.findall(r"^\| `([a-z_]+)` \|", section, re.M))
    schema_types = set(schemas["envelope"]["$defs"]["type"]["enum"])
    if spec_types == schema_types:
        report.ok("enum khớp bảng spec")
    else:
        report.fail(f"envelope.type lệch 0.7.1: spec {sorted(spec_types)}, schema {sorted(schema_types)}")


def make_validators(schemas: dict[str, dict], registry: Registry) -> dict[str, Draft202012Validator]:
    validators = {n: Draft202012Validator(s, registry=registry) for n, s in schemas.items()}
    # Ack của op có data riêng: "<schema>#ack" trỏ tới $defs/ack của schema đó.
    for name, schema in schemas.items():
        if "ack" in schema.get("$defs", {}):
            ack_ref = {"$ref": schema["$id"] + "#/$defs/ack"}
            validators[f"{name}#ack"] = Draft202012Validator(ack_ref, registry=registry)
    return validators


def validate_docs(validators, report: Report) -> None:
    doc_files = sorted(DOCS_DIR.glob("0*.md"))
    for path in doc_files:
        strict = path == COMMON_SPECS
        for ex in doc_examples.extract_examples(path):
            _check_example(ex, strict, validators, report)


def _check_example(ex, strict: bool, validators, report: Report) -> None:
    known = doc_examples.KNOWN_SPEC_ISSUES.get((ex.file, ex.line))
    if ex.parse_error:
        if known:
            report.ok("known spec issue (đúng như ghi nhận)")
            print(f"  KNOWN {ex.where}: {known}")
        else:
            report.fail(f"{ex.where}: khối ```json không parse được: {ex.parse_error}")
        return
    schema = doc_examples.classify(ex, strict_payload=strict)
    if schema is None:
        if strict and ex.source == "block":
            report.fail(f"{ex.where}: khối ```json trong 00-common-specs không phân loại được")
        else:
            report.ok("ngoài phạm vi S0.2 (bỏ qua)")
        return
    try:
        instance = doc_examples.substitute_placeholders(ex.obj, ex.substitutions)
    except ValueError as exc:
        report.fail(f"{ex.where}: {exc}")
        return
    _validate_one(f"{ex.where} [{schema}]", schema, instance, validators, report, known,
                  bucket="ví dụ 00-common-specs" if strict else "ví dụ 01–08",
                  subs=ex.substitutions)
    if schema == "envelope":
        inner = doc_examples.decode_handshake_payload(instance)
        if inner is not None:
            inner_schema = f"session-{inner.get('op')}"
            subs: list[str] = []
            inner = doc_examples.substitute_placeholders(inner, subs)
            _validate_one(f"{ex.where} [payload đã giải b64 -> {inner_schema}]", inner_schema, inner,
                          validators, report, known=None, bucket="payload bắt tay giải từ envelope", subs=subs)


def _validate_one(label, schema, instance, validators, report, known, bucket, subs) -> None:
    if schema not in validators:
        report.fail(f"{label}: không có schema {schema!r}")
        return
    error = best_match(validators[schema].iter_errors(instance))
    if error is None and not known:
        report.ok(bucket)
        note = f" (placeholder: {'; '.join(subs)})" if subs else ""
        print(f"  PASS {label}{note}")
    elif error is None and known:
        report.fail(f"{label}: đã qua schema nhưng còn trong KNOWN_SPEC_ISSUES — xóa mục đó")
    elif known:
        report.ok("known spec issue (đúng như ghi nhận)")
        print(f"  KNOWN {label}: {known}")
    else:
        path = "/".join(str(p) for p in error.absolute_path) or "(gốc)"
        report.fail(f"{label}: {path}: {error.message}")


def validate_samples(validators, report: Report) -> None:
    for name, schema, instance in sample_messages.POSITIVE:
        error = best_match(validators[schema].iter_errors(instance))
        if error is None:
            report.ok("mẫu dương tự viết")
        else:
            report.fail(f"mẫu dương '{name}' bị từ chối: {error.message}")
    for name, schema, instance in sample_messages.NEGATIVE:
        error = best_match(validators[schema].iter_errors(instance))
        if error is None:
            report.fail(f"mẫu âm '{name}' lại được chấp nhận")
        else:
            report.ok("mẫu âm bị từ chối")
            print(f"  REJECT {name}: {error.message[:110]}")


def main() -> int:
    report = Report()
    print("== 1. Metaschema, $id, $ref, enum khớp spec")
    schemas, registry = load_schemas(report)
    check_refs(schemas, registry, report)
    check_enums_match_spec(schemas, report)
    validators = make_validators(schemas, registry)
    print("== 2. Ví dụ trong docs/detailed-design")
    validate_docs(validators, report)
    print("== 3. Mẫu tự viết")
    validate_samples(validators, report)
    print("== Tổng kết")
    for bucket, count in report.counts.items():
        print(f"  {bucket}: {count}")
    if report.failures:
        print(f"  THẤT BẠI: {len(report.failures)}")
        return 1
    print("  XANH: mọi kiểm tra đạt")
    return 0


if __name__ == "__main__":
    sys.exit(main())
