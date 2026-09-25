"""Đọc shared/design-tokens/tokens.json và chuẩn hóa thành dữ liệu cho bộ sinh Apple.

Chỉ dùng thư viện chuẩn. Mọi quy tắc suy diễn (bí danh màu, text style, tên PostScript)
nằm ở đây để bộ sinh asset catalog và bộ sinh Swift dùng chung một nguồn.
"""
from __future__ import annotations

import json
import re
from dataclasses import dataclass
from pathlib import Path

# Thứ tự 4 giao diện; khớp `color.themes` trong tokens.json.
THEMES = ("light", "dark", "light-hc", "dark-hc")

# Màu hệ thống có API SwiftUI tương ứng (01-mau-sac.md: "Không hard-code màu hệ thống trên Apple").
# Token (hoặc bí danh trỏ tới token) trong bảng này gọi API hệ thống thay vì giá trị hex.
SYSTEM_SWIFTUI_COLORS = {
    "system-red": "Color.red",
    "system-orange": "Color.orange",
    "system-yellow": "Color.yellow",
    "system-green": "Color.green",
    "system-pink": "Color.pink",
    "system-purple": "Color.purple",
    "system-brown": "Color.brown",
    "system-gray": "Color.gray",
    "label": "Color.primary",
    "secondary-label": "Color.secondary",
}

# Text style "phóng theo" của chữ thương hiệu và chữ số (03-kieu-chu.md, mục Chữ thương hiệu, Số và mã).
RELATIVE_TEXT_STYLES = {
    "brand-large-title": "largeTitle",
    "brand-title": "title2",
    "wordmark": "title3",
    "code-pin": "title",
    "timer": "body",
}
# Đuôi tên token mac-*/ios-* → Font.TextStyle (03-kieu-chu.md, bảng macOS và iOS).
SUFFIX_TEXT_STYLES = {
    "large-title": "largeTitle", "title-1": "title", "title-2": "title2", "title-3": "title3",
    "headline": "headline", "body": "body", "callout": "callout", "subheadline": "subheadline",
    "footnote": "footnote", "caption-1": "caption", "caption-2": "caption2",
}
MONOSPACED_DIGIT_STYLES = {"timer"}
BRAND_POSTSCRIPT_NAMES = {600: "BeVietnamPro-SemiBold", 700: "BeVietnamPro-Bold"}
APPLE_TYPE_PREFIXES = ("brand-", "mac-", "ios-")
APPLE_TYPE_EXTRA = {"wordmark", "code-pin", "timer"}


@dataclass(frozen=True)
class RGBA:
    red: int
    green: int
    blue: int
    alpha: int  # 0…255

    @staticmethod
    def parse(hex_value: str) -> "RGBA":
        match = re.fullmatch(r"#([0-9a-fA-F]{6})([0-9a-fA-F]{2})?", hex_value)
        if not match:
            raise ValueError(f"Màu không hợp lệ: {hex_value}")
        rgb, alpha = match.group(1), match.group(2) or "ff"
        return RGBA(int(rgb[0:2], 16), int(rgb[2:4], 16), int(rgb[4:6], 16), int(alpha, 16))


@dataclass(frozen=True)
class ColorToken:
    name: str
    usage: str
    values: dict  # theme → RGBA
    system_color: str | None  # biểu thức SwiftUI nếu token là màu hệ thống


@dataclass(frozen=True)
class TextStyleToken:
    name: str
    family: str  # brand | system | mono
    size: float
    line_height: float
    weight: int
    letter_spacing_em: float
    text_style: str
    postscript_name: str | None
    monospaced_digit: bool
    usage: str


@dataclass(frozen=True)
class MetricToken:
    name: str
    value: float
    usage: str


def _alias(value):
    match = re.fullmatch(r"\{([a-z0-9-]+)\}", value) if isinstance(value, str) else None
    return match.group(1) if match else None


def _resolve_color(name: str, raw: dict, seen: tuple = ()) -> tuple[dict, str | None]:
    """Trả về (theme → RGBA, API hệ thống) sau khi lần theo chuỗi bí danh."""
    if name in seen:
        raise ValueError(f"Bí danh màu vòng lặp: {' → '.join(seen + (name,))}")
    system = SYSTEM_SWIFTUI_COLORS.get(name)
    value = raw[name]
    target = _alias(value)
    if target:
        values, target_system = _resolve_color(target, raw, seen + (name,))
        return values, system or target_system
    if isinstance(value, str):
        return {theme: RGBA.parse(value) for theme in THEMES}, system
    return {theme: RGBA.parse(value[theme]) for theme in THEMES}, system


def load_colors(tokens: dict) -> list[ColorToken]:
    themes = tuple(theme["id"] for theme in tokens["color"]["themes"])
    if themes != THEMES:
        raise ValueError(f"tokens.json đổi bộ giao diện: {themes}")
    raw = {item["name"]: item["value"] for item in tokens["color"]["tokens"]}
    result = []
    for item in tokens["color"]["tokens"]:
        values, system = _resolve_color(item["name"], raw)
        result.append(ColorToken(item["name"], item["usage"], values, system))
    return result


def _px(value: str) -> float:
    return float(value.removesuffix("px"))


def _is_apple_style(name: str) -> bool:
    return name.startswith(APPLE_TYPE_PREFIXES) or name in APPLE_TYPE_EXTRA


def load_text_styles(tokens: dict) -> list[TextStyleToken]:
    result = []
    for group in tokens["type"]["groups"]:
        for style in group["styles"]:
            name = style["name"]
            if not _is_apple_style(name):
                continue
            suffix = name.split("-", 1)[1] if name.startswith(("mac-", "ios-")) else None
            text_style = RELATIVE_TEXT_STYLES.get(name) or SUFFIX_TEXT_STYLES[suffix]
            weight = int(style["fontWeight"])
            family = style["family"]
            postscript = BRAND_POSTSCRIPT_NAMES[weight] if family == "brand" else None
            result.append(TextStyleToken(
                name, family, _px(style["fontSize"]), _px(style["lineHeight"]), weight,
                float(style["letterSpacing"].removesuffix("em")), text_style, postscript,
                name in MONOSPACED_DIGIT_STYLES, style["usage"],
            ))
    return result


def load_metrics(tokens: dict, family: str) -> list[MetricToken]:
    result = []
    for item in tokens[family]["tokens"]:
        value = item["value"]
        number = float(value.removesuffix("ms")) / 1000 if value.endswith("ms") else _px(value)
        result.append(MetricToken(item["name"], number, item["usage"]))
    return result


def load_tokens(path: Path) -> dict:
    return json.loads(path.read_text(encoding="utf-8"))
