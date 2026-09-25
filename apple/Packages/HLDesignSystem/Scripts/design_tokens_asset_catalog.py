"""Sinh Asset Catalog Color Sets (Any, Dark, High Contrast, Dark + High Contrast) từ token màu."""
from __future__ import annotations

import json

from design_tokens_model import THEMES, ColorToken, RGBA

CATALOG_DIR = "Sources/HLDesignSystem/Resources/Colors.xcassets"
ACCENT_COLOR_SOURCE = "accent"
_INFO = {"author": "xcode", "version": 1}

# Giao diện trong asset catalog tương ứng với từng theme của tokens.json.
_APPEARANCES = {
    "light": [],
    "dark": [{"appearance": "luminosity", "value": "dark"}],
    "light-hc": [{"appearance": "contrast", "value": "high"}],
    "dark-hc": [
        {"appearance": "luminosity", "value": "dark"},
        {"appearance": "contrast", "value": "high"},
    ],
}


def _dump(document: dict) -> str:
    return json.dumps(document, indent=2, sort_keys=True, ensure_ascii=False) + "\n"


def _components(color: RGBA) -> dict:
    return {
        "alpha": f"{color.alpha / 255:.3f}",
        "blue": f"0x{color.blue:02X}",
        "green": f"0x{color.green:02X}",
        "red": f"0x{color.red:02X}",
    }


def _color_set(values: dict) -> str:
    entries = []
    for theme in THEMES:
        entry = {
            "color": {"color-space": "srgb", "components": _components(values[theme])},
            "idiom": "universal",
        }
        if _APPEARANCES[theme]:
            entry["appearances"] = _APPEARANCES[theme]
        entries.append(entry)
    return _dump({"colors": entries, "info": _INFO})


def render_asset_catalog(colors: list[ColorToken]) -> dict[str, str]:
    """Trả về {đường dẫn tương đối trong package: nội dung}."""
    files = {f"{CATALOG_DIR}/Contents.json": _dump({"info": _INFO})}
    for token in colors:
        files[f"{CATALOG_DIR}/{token.name}.colorset/Contents.json"] = _color_set(token.values)
    accent = next(token for token in colors if token.name == ACCENT_COLOR_SOURCE)
    files[f"{CATALOG_DIR}/AccentColor.colorset/Contents.json"] = _color_set(accent.values)
    return files
