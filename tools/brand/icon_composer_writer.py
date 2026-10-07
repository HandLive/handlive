"""Icon Composer document (AppIcon.icon) for Liquid Glass app icons (iOS 26+, macOS 26+).

A `.icon` is a folder: `icon.json` plus the layer artwork in `Assets/`. Apple publishes no schema for
icon.json; the keys below are the ones Icon Composer writes and actool/ictool of Xcode 27 accept.
The system adds the glass, the specular highlight and the mask, so the layers are flat, square and
unmasked, on the 1024 grid with the mountain bleeding off the bottom (same geometry as app_icon()).

Groups, front to back: the signal rings, the fire (flame and core), the mountain. The background is a
fill, not a layer: dawn gradient in Default, night gradient in Dark. Dark swaps the mountain artwork
for its on-dark colors; Tinted and Clear are derived by the system from the same layers.
"""
import json
import os

from brand_compositions import GROUND, svg_doc
from brand_geometry import (DARK, PALETTE, WAVE_RADII, WAVE_STROKE, flame_paths, lit_face, mountain,
                            wave_paths)


def _srgb(hex_rgb):
    h = hex_rgb.lstrip("#")
    return "srgb:" + ",".join(f"{int(h[i:i + 2], 16) / 255:.5f}" for i in (0, 2, 4)) + ",1.00000"


def _mountain(ember, lit):
    peak = mountain(GROUND)
    defs = f'<clipPath id="lit"><path d="{peak}"/></clipPath>'
    return svg_doc(1024, 1024, defs, f'<path d="{peak}" fill="{ember}"/>'
                f'<path clip-path="url(#lit)" d="{lit_face(GROUND)}" fill="{lit}"/>')


def _flame():
    outer, core = flame_paths()
    defs = (f'<linearGradient id="flame" x1="0" y1="1" x2="0" y2="0">'
            f'<stop offset="0" stop-color="{PALETTE["brand-fire"]}"/>'
            f'<stop offset=".55" stop-color="{PALETTE["brand-flame"]}"/>'
            f'<stop offset="1" stop-color="{PALETTE["flame-tip"]}"/></linearGradient>')
    return svg_doc(1024, 1024, defs, f'<path d="{outer}" fill="url(#flame)"/>'
                f'<path d="{core}" fill="{PALETTE["flame-core"]}"/>')


def _rings():
    body = ""
    for radius, color in zip(WAVE_RADII, (PALETTE["brand-flame"], PALETTE["wave-outer"])):
        for d in wave_paths(radius):
            body += (f'<path d="{d}" fill="none" stroke="{color}" stroke-width="{WAVE_STROKE}" '
                     f'stroke-linecap="round"/>')
    return svg_doc(1024, 1024, "", body)


ASSETS = {
    "rings.svg": _rings,
    "flame.svg": _flame,
    "mountain.svg": lambda: _mountain(PALETTE["brand-ember"], PALETTE["mountain-lit"]),
    "mountain-dark.svg": lambda: _mountain(DARK["brand-ember"], DARK["mountain-lit"]),
}


def icon_json():
    def group(name, layer, glass, shadow, translucency):
        return {"name": name, "layers": [{"name": name.lower(), "glass": glass, **layer}],
                "shadow": {"kind": shadow, "opacity": 0.5},
                # translucency 0 turns it off; Icon Composer still saves a value then, and 0.5 is its default.
                "translucency": {"enabled": translucency > 0, "value": translucency or 0.5}}

    doc = {
        "fill-specializations": [
            {"value": {"linear-gradient": [_srgb(PALETTE["dawn-top"]), _srgb(PALETTE["dawn-bottom"])]}},
            {"appearance": "dark",
             "value": {"linear-gradient": [_srgb(DARK["night-top"]), _srgb(DARK["night-bottom"])]}},
        ],
        "groups": [
            group("Signal", {"image-name": "rings.svg"}, True, "neutral", 0.4),
            group("Fire", {"image-name": "flame.svg"}, True, "layer-color", 0.2),
            # The mountain is the ground: opaque, not glass, so the fire reads as sitting on it.
            group("Mountain", {"image-name-specializations": [
                {"value": "mountain.svg"}, {"appearance": "dark", "value": "mountain-dark.svg"}]},
                False, "neutral", 0),
        ],
        # macOS is listed so the same document serves the Mac once its target switches to it.
        "supported-platforms": {"squares": ["iOS", "macOS"]},
    }
    return json.dumps(doc, indent=2) + "\n"


def write_icon(icon_dir):
    """(Re)write an AppIcon.icon folder; returns the relative paths written."""
    assets = os.path.join(icon_dir, "Assets")
    os.makedirs(assets, exist_ok=True)
    files = {"icon.json": icon_json(), **{f"Assets/{n}": make() for n, make in ASSETS.items()}}
    for rel, text in files.items():
        with open(os.path.join(icon_dir, rel), "w", encoding="utf-8") as fh:
            fh.write(text)
    return sorted(files)
