"""The in-app brand mark (the signal fire shown on the welcome screens) as platform assets.

Android: a vector drawable of the standalone mark with a night variant (core/design res/).
Apple: a PDF image set with light and dark appearances for the HLDesignSystem asset catalog.
"""
import json
import os
import subprocess

import brand_compositions as comp
from brand_geometry import (DARK, MARK_BASE_ROUND, MARK_BASE_Y, MARK_BOX, PALETTE, flame_paths, lit_face,
                            mountain)
from platform_icon_writers import HEADER, NS, _argb, _gradient, _rings

MARK_DP = (86, 72)       # display size on Android: 72 dp tall, the box's 904:760 ratio
MARK_PT = 72             # natural height of the Apple PDF, in points


def android_mark_vector(dark=False):
    """Vector drawable of the mark on its own box (rounded base), light or night colors."""
    bx, by, bw, bh = MARK_BOX
    ember = DARK["brand-ember"] if dark else PALETTE["brand-ember"]
    lit = DARK["mountain-lit"] if dark else PALETTE["mountain-lit"]
    outer, core = flame_paths()
    peak = mountain(MARK_BASE_Y, MARK_BASE_ROUND)
    flame_stops = [(0, PALETTE["brand-fire"]), (0.55, PALETTE["brand-flame"]), (1, PALETTE["flame-tip"])]
    return (HEADER
            + f'<vector {NS}\n    android:width="{MARK_DP[0]}dp" android:height="{MARK_DP[1]}dp"\n'
              f'    android:viewportWidth="{bw}" android:viewportHeight="{bh}">\n'
            + f'  <group android:translateX="{-bx}" android:translateY="{-by}">\n'
            + f'    <path android:fillColor="{_argb(ember)}" android:pathData="{peak}"/>\n'
            + f'    <group>\n      <clip-path android:pathData="{peak}"/>\n'
              f'      <path android:fillColor="{_argb(lit)}" android:pathData="{lit_face(MARK_BASE_Y)}"/>\n    </group>\n'
            + f'    <path android:pathData="{outer}">{_gradient(512, 562, 512, 210, flame_stops)}</path>\n'
            + f'    <path android:fillColor="{_argb(PALETTE["flame-core"])}" android:pathData="{core}"/>\n'
            + _rings(PALETTE["brand-flame"], PALETTE["wave-outer"])
            + "  </group>\n</vector>\n")


def write_android_mark(res_dir):
    """drawable/hl_brand_mark.xml and its drawable-night twin under an Android res/ directory."""
    files = {"drawable/hl_brand_mark.xml": android_mark_vector(False),
             "drawable-night/hl_brand_mark.xml": android_mark_vector(True)}
    for rel, text in files.items():
        path = os.path.join(res_dir, rel)
        os.makedirs(os.path.dirname(path), exist_ok=True)
        with open(path, "w", encoding="utf-8") as fh:
            fh.write('<?xml version="1.0" encoding="utf-8"?>\n' + text)
    return sorted(files)


def write_apple_mark_imageset(catalog_dir):
    """brand-mark.imageset (PDF, light + dark) inside an asset catalog; creates the catalog's Contents.json."""
    imageset = os.path.join(catalog_dir, "brand-mark.imageset")
    os.makedirs(imageset, exist_ok=True)
    root_contents = os.path.join(catalog_dir, "Contents.json")
    if not os.path.exists(root_contents):
        with open(root_contents, "w", encoding="utf-8") as fh:
            fh.write(json.dumps({"info": {"author": "xcode", "version": 1}}, indent=2) + "\n")
    for name, dark in (("brand-mark.pdf", False), ("brand-mark-dark.pdf", True)):
        svg = os.path.join(imageset, ".src.svg")
        with open(svg, "w", encoding="utf-8") as fh:
            fh.write(comp.mark(dark=dark))
        subprocess.run(["rsvg-convert", "-f", "pdf", "-h", str(MARK_PT), "-a", svg, "-o", os.path.join(imageset, name)],
                       check=True)
        os.remove(svg)
    contents = {
        "images": [
            {"filename": "brand-mark.pdf", "idiom": "universal"},
            {"appearances": [{"appearance": "luminosity", "value": "dark"}], "filename": "brand-mark-dark.pdf",
             "idiom": "universal"},
        ],
        "info": {"author": "xcode", "version": 1},
        "properties": {"preserves-vector-representation": True},
    }
    with open(os.path.join(imageset, "Contents.json"), "w", encoding="utf-8") as fh:
        fh.write(json.dumps(contents, indent=2) + "\n")
    return imageset
