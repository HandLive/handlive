#!/usr/bin/env python3
"""Print width, height, and whether a PNG has an alpha channel (color type or tRNS)."""
import struct
import sys

def info(path):
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
    print(f"{path} pixelWidth={width} pixelHeight={height} colorType={color} hasAlpha={'yes' if alpha else 'no'}")

for path in sys.argv[1:]:
    info(path)
