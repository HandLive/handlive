"""SVG compositions built from brand_geometry: logo lockups, app icons and promo images.

Every function returns a complete SVG document as a string. Text comes in as outlines from
text_outlines (dict with d, width, cap, ascender, descender in 1000-unit font space).
"""
from brand_geometry import (DARK, MARK_BASE_ROUND, MARK_BASE_Y, MARK_BOX, PALETTE, WAVE_RADII, WAVE_STROKE,
                            flame_paths, fmt, gradient_bg, mark_layers, mono_layers, mountain, wave_paths)

SVG_OPEN = '<svg xmlns="http://www.w3.org/2000/svg" viewBox="{vb}" width="{w}" height="{h}">'
INK_SOFT = "#6b5562"        # secondary promo text on the dawn background
GROUND = 1024               # the mountain bleeds off the bottom of the 1024 icon grid


def _doc(w, h, defs, body, vb=None):
    vb = vb or f"0 0 {fmt(w)} {fmt(h)}"
    return SVG_OPEN.format(vb=vb, w=fmt(w), h=fmt(h)) + f"<defs>{defs}</defs>{body}</svg>\n"


def _text(outline, x, baseline, size, color):
    s = size / 1000
    return f'<path transform="translate({fmt(x)} {fmt(baseline)}) scale({s:.4f})" d="{outline["d"]}" fill="{color}"/>'


def _mark_group(x, y, height, dark=False, compact=False, uid="m"):
    """Standalone mark scaled so its box is `height` tall, top-left at (x, y). Returns (defs, g, width)."""
    bx, by, bw, bh = MARK_BOX
    s = height / bh
    defs, body = mark_layers(MARK_BASE_Y, MARK_BASE_ROUND, outer_waves=not compact, dark=dark, uid=uid)
    g = f'<g transform="translate({fmt(x - bx * s)} {fmt(y - by * s)}) scale({s:.5f})">{body}</g>'
    return defs, g, bw * s


def mark(dark=False, compact=False):
    x, y, w, h = MARK_BOX
    defs, body = mark_layers(MARK_BASE_Y, MARK_BASE_ROUND, outer_waves=not compact, dark=dark)
    return _doc(w, h, defs, body, vb=f"{x} {y} {w} {h}")


def mark_mono(color):
    x, y, w, h = MARK_BOX
    return _doc(w, h, "", mono_layers(MARK_BASE_Y, MARK_BASE_ROUND, color=color), vb=f"{x} {y} {w} {h}")


def wordmark(word, dark=False, size=200):
    color = DARK["wordmark"] if dark else PALETTE["brand-ember"]
    pad = size * 0.08
    h = (word["ascender"] - word["descender"]) * size / 1000
    w = word["width"] * size / 1000
    body = _text(word, pad, pad + word["ascender"] * size / 1000, size, color)
    return _doc(w + 2 * pad, h + 2 * pad, "", body)


def lockup_horizontal(word, dark=False, size=200):
    """Mark left, wordmark right; the mountain base sits on the text baseline."""
    color = DARK["wordmark"] if dark else PALETTE["brand-ember"]
    pad = size * 0.12
    mark_h = size * 1.24
    baseline = pad + mark_h * (MARK_BASE_Y - MARK_BOX[1]) / MARK_BOX[3]
    defs, g, mw = _mark_group(pad, pad, mark_h, dark=dark, uid="lh")
    tx = pad + mw + size * 0.26
    body = g + _text(word, tx, baseline, size, color)
    w = tx + word["width"] * size / 1000 + pad
    h = max(pad + mark_h, baseline - word["descender"] * size / 1000 * 0.2) + pad
    return _doc(w, h, defs, body)


def lockup_stacked(word, dark=False, size=200):
    color = DARK["wordmark"] if dark else PALETTE["brand-ember"]
    pad = size * 0.16
    text_w = word["width"] * size / 1000
    mark_h = text_w * 0.62 * MARK_BOX[3] / MARK_BOX[2]
    w = text_w + 2 * pad
    defs, g, mw = _mark_group((w - text_w * 0.62) / 2, pad, mark_h, dark=dark, uid="ls")
    baseline = pad + mark_h + size * 0.22 + word["cap"] * size / 1000
    h = baseline + size * 0.08 + pad
    return _doc(w, h, defs, g + _text(word, pad, baseline, size, color))


def app_icon(appearance="default", ground=GROUND):
    """Full-bleed 1024 square icon (iOS, Android source, store listings). appearance: default|dark|tinted."""
    if appearance == "tinted":
        defs, bg = gradient_bg("bg", "#1c1c1e", "#000000")
        return _doc(1024, 1024, defs, bg + f'<path d="{mountain(ground)}" fill="#636366"/>' + _tinted_fire())
    dark = appearance == "dark"
    top, bottom = (DARK["night-top"], DARK["night-bottom"]) if dark else (PALETTE["dawn-top"], PALETTE["dawn-bottom"])
    d1, bg = gradient_bg("bg", top, bottom)
    d2, body = mark_layers(ground, dark=dark, uid="ic")
    return _doc(1024, 1024, d1 + d2, bg + body)


def _tinted_fire():
    """Flame (core cut out) and rings for the tinted icon: light gray, outer ring dimmer."""
    outer, core = flame_paths()
    out = f'<path d="{outer} {core}" fill="#f2f2f7" fill-rule="evenodd"/>'
    for radius, color in zip(WAVE_RADII, ("#e5e5ea", "#8e8e93")):
        for d in wave_paths(radius):
            out += (f'<path d="{d}" fill="none" stroke="{color}" stroke-width="{WAVE_STROKE}" '
                    f'stroke-linecap="round"/>')
    return out


def app_icon_layers():
    """Icon Composer inputs: square, unmasked background and foreground layers."""
    d1, bg = gradient_bg("bg", PALETTE["dawn-top"], PALETTE["dawn-bottom"])
    d2, body = mark_layers(GROUND, uid="fg")
    return _doc(1024, 1024, d1, bg), _doc(1024, 1024, d2, body)


def app_icon_macos(compact=False):
    """macOS 11+ grid: an 824 pt rounded square centered on 1024 with a soft drop shadow."""
    d1, bg = gradient_bg("bg", PALETTE["dawn-top"], PALETTE["dawn-bottom"])
    d2, body = mark_layers(GROUND, outer_waves=not compact, uid="mac")
    s = 824 / 1024
    defs = (d1 + d2 + '<clipPath id="tile"><rect x="100" y="100" width="824" height="824" rx="185.4"/></clipPath>'
            '<filter id="shadow" x="-10%" y="-10%" width="120%" height="125%">'
            '<feDropShadow dx="0" dy="10" stdDeviation="10" flood-color="#000" flood-opacity=".3"/></filter>')
    tile = (f'<rect x="100" y="100" width="824" height="824" rx="185.4" fill="{PALETTE["dawn-bottom"]}" '
            f'filter="url(#shadow)"/><g clip-path="url(#tile)"><g transform="translate(100 100) scale({s})">'
            f'{bg}{body}</g></g>')
    return _doc(1024, 1024, defs, tile)


def promo(w, h, word, title, lines, badge=None):
    """Dawn background, big mark bleeding off the bottom right, lockup + headline + lines on the left."""
    d1, bg = gradient_bg("bg", PALETTE["dawn-top"], PALETTE["dawn-bottom"], w, h)
    art_scale = h * 0.86 / 1024
    d2, art = mark_layers(GROUND, uid="art")
    art_g = (f'<g transform="translate({fmt(w - 1024 * art_scale * 0.92)} {fmt(h - 1024 * art_scale)}) '
             f'scale({art_scale:.5f})">{art}</g>')
    left = h * 0.15
    size = h * 0.075
    d3, lock, mw = _mark_group(left, h * 0.13, size * 1.24, uid="pl")
    base = h * 0.13 + size * 1.24 * (MARK_BASE_Y - MARK_BOX[1]) / MARK_BOX[3]
    body = bg + art_g + lock + _text(word, left + mw + size * 0.26, base, size, PALETTE["brand-ember"])
    y = h * 0.47
    if badge:
        bw = badge["width"] * h * 0.032 / 1000 + h * 0.05
        body += (f'<rect x="{fmt(left)}" y="{fmt(h * 0.31)}" width="{fmt(bw)}" height="{fmt(h * 0.06)}" '
                 f'rx="{fmt(h * 0.03)}" fill="{PALETTE["brand-fire"]}"/>')
        body += _text(badge, left + h * 0.025, h * 0.352, h * 0.032, "#ffffff")
        y = h * 0.52
    title_size = h * 0.11
    for t in title:
        body += _text(t, left, y, title_size, PALETTE["brand-ember"])
        y += title_size * 1.1
    y += h * 0.03
    for line in lines:
        body += _text(line, left, y, h * 0.04, INK_SOFT)
        y += h * 0.058
    return _doc(w, h, d1 + d2 + d3, body)
