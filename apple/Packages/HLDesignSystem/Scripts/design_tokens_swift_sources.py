"""Sinh mã Swift (màu, kiểu chữ, khoảng cách, bo góc, kích thước, thời lượng) từ token."""
from __future__ import annotations

from design_tokens_model import THEMES, ColorToken, MetricToken, RGBA, TextStyleToken

GENERATED_DIR = "Sources/HLDesignSystem/Generated"
_HEADER = (
    "// Tệp sinh tự động bởi Scripts/generate-design-tokens.py từ shared/design-tokens/tokens.json.\n"
    "// Không sửa tay: sửa tokens.json rồi chạy lại script (kiểm bằng --check).\n"
)
_PALETTE_ARGS = ("light", "dark", "lightHighContrast", "darkHighContrast")
_FAMILY_ENUMS = {"brand": ".brand", "system": ".system", "mono": ".monospaced"}
# Tiền tố bỏ khỏi tên thành viên Swift để gọi gọn (HLRadius.card thay HLRadius.radiusCard).
_METRIC_ENUMS = (
    ("spacing", "HLSpacing", "", "CGFloat", "Khoảng cách (pt), lưới 4 pt."),
    ("radius", "HLRadius", "radius-", "CGFloat", "Bo góc (pt) cho control tự dựng, macOS 13–15 / iOS 16–18."),
    ("size", "HLSize", "size-", "CGFloat", "Kích thước tối thiểu và kích thước cố định (pt)."),
    ("duration", "HLDuration", "duration-", "Double", "Thời lượng (giây); Apple ưu tiên spring của hệ thống."),
)


def swift_identifier(name: str) -> str:
    head, *rest = name.split("-")
    return head + "".join(part[:1].upper() + part[1:] for part in rest)


def _number(value: float) -> str:
    return f"{value:g}"


def _doc(text: str, indent: str = "    ") -> str:
    return f"{indent}/// {' '.join(text.split())}\n"


def _rgba(color: RGBA) -> str:
    return f"HLRGBA(0x{color.red:02X}, 0x{color.green:02X}, 0x{color.blue:02X}, 0x{color.alpha:02X})"


def render_colors(colors: list[ColorToken]) -> str:
    out = [_HEADER, "import SwiftUI\n\n"]
    out.append("/// Token màu của HandLive, mỗi token có đủ 4 giao diện.\n")
    out.append("public enum HLColorToken: String, CaseIterable, Sendable {\n")
    for token in colors:
        out.append(_doc(token.usage))
        out.append(f'    case {swift_identifier(token.name)} = "{token.name}"\n')
    out.append("\n    /// Giá trị hex theo tokens.json cho Sáng, Tối, Sáng · tương phản cao, Tối · tương phản cao.\n")
    out.append("    public var palette: HLColorPalette {\n        switch self {\n")
    for token in colors:
        args = ", ".join(
            f"{label}: {_rgba(token.values[theme])}" for label, theme in zip(_PALETTE_ARGS, THEMES)
        )
        out.append(f"        case .{swift_identifier(token.name)}: return HLColorPalette({args})\n")
    out.append("        }\n    }\n\n")
    out.append("    /// Màu hệ thống thay cho hex (01-mau-sac.md: không hard-code màu hệ thống trên Apple).\n")
    out.append("    public var systemColor: Color? {\n        switch self {\n")
    by_api: dict[str, list[str]] = {}
    for token in colors:
        if token.system_color:
            by_api.setdefault(token.system_color, []).append(f".{swift_identifier(token.name)}")
    for api, cases in by_api.items():
        out.append(f"        case {', '.join(cases)}: return {api}\n")
    out.append("        default: return nil\n        }\n    }\n}\n")
    return "".join(out)


def render_text_styles(styles: list[TextStyleToken]) -> str:
    out = [_HEADER, "import SwiftUI\n\n"]
    out.append("/// Kiểu chữ Apple theo 03-kieu-chu.md: SF qua text style, Be Vietnam Pro cho chữ thương hiệu.\n")
    out.append("public enum HLTextStyle: String, CaseIterable, Sendable {\n")
    for style in styles:
        out.append(_doc(style.usage))
        out.append(f'    case {swift_identifier(style.name)} = "{style.name}"\n')
    out.append("\n    public var spec: HLTextStyleSpec {\n        switch self {\n")
    for style in styles:
        postscript = f'"{style.postscript_name}"' if style.postscript_name else "nil"
        out.append(
            f"        case .{swift_identifier(style.name)}: return HLTextStyleSpec("
            f"family: {_FAMILY_ENUMS[style.family]}, size: {_number(style.size)}, "
            f"lineHeight: {_number(style.line_height)}, weight: {style.weight}, "
            f"letterSpacingEm: {_number(style.letter_spacing_em)}, textStyle: .{style.text_style}, "
            f"postScriptName: {postscript}, monospacedDigit: {str(style.monospaced_digit).lower()})\n"
        )
    out.append("        }\n    }\n}\n\n")
    names = sorted({s.postscript_name for s in styles if s.postscript_name})
    out.append("/// Tên PostScript của các file Be Vietnam Pro được đóng gói (chỉ weight token dùng).\n")
    out.append("public enum HLBrandFontFiles {\n")
    listed = ", ".join(f'"{name}"' for name in names)
    out.append(f"    public static let postScriptNames: [String] = [{listed}]\n}}\n")
    return "".join(out)


def render_metrics(metrics: dict[str, list[MetricToken]]) -> str:
    out = [_HEADER, "import CoreGraphics\n"]
    for family, enum_name, prefix, swift_type, summary in _METRIC_ENUMS:
        out.append(f"\n/// {summary}\npublic enum {enum_name} {{\n")
        for token in metrics[family]:
            member = swift_identifier(token.name.removeprefix(prefix))
            out.append(_doc(token.usage))
            out.append(f"    public static let {member}: {swift_type} = {_number(token.value)}\n")
        out.append("}\n")
    return "".join(out)


def render_swift_sources(colors, styles, metrics) -> dict[str, str]:
    return {
        f"{GENERATED_DIR}/hl-color-token-generated.swift": render_colors(colors),
        f"{GENERATED_DIR}/hl-text-style-generated.swift": render_text_styles(styles),
        f"{GENERATED_DIR}/hl-metrics-generated.swift": render_metrics(metrics),
    }
