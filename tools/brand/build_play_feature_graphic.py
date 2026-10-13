#!/usr/bin/env python3
"""Write only the Play feature graphic (1024×500, no alpha). The full brand build calls the same code."""
import os
import struct
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

import build_brand_assets as brand  # noqa: E402


def png_facts(path):
    """Width, height, and whether the PNG has an alpha channel (color type or tRNS)."""
    with open(path, "rb") as fh:
        if fh.read(8) != b"\x89PNG\r\n\x1a\n":
            raise SystemExit(f"{path}: not a png")
        width = height = color = None
        trns = False
        while True:
            raw = fh.read(8)
            if len(raw) < 8:
                break
            length, kind = struct.unpack(">I4s", raw)
            data = fh.read(length)
            fh.read(4)
            if kind == b"IHDR":
                width, height, _bit, color = struct.unpack(">IIBB", data[:10])
            elif kind == b"tRNS":
                trns = True
            elif kind == b"IEND":
                break
    alpha = color in (4, 6) or trns
    return width, height, alpha


outlines = brand.text_outlines.load(brand.all_strings())
word = outlines[brand.WORD]
for _lang, copy in brand.COPY.items():
    title = [outlines[s] for s in copy["title"]]
    lines = [outlines[s] for s in copy["lines"]]
    rel = brand.write(
        f"promo/play-feature-graphic.{_lang}.svg",
        brand.comp.promo(1024, 500, word, title, lines),
        1024,
        opaque=True,
    )
    png = os.path.join(brand.OUT, rel[:-4] + ".png")
    width, height, alpha = png_facts(png)
    if (width, height, alpha) != (1024, 500, False):
        raise SystemExit(f"{png}: expected 1024x500 without alpha, got {width}x{height} alpha={alpha}")
    print(f"{rel} {width}x{height} hasAlpha=no")
