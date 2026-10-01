"""HandLive brand geometry and palette: the single source for every logo, icon and promo image.

The mark is a signal fire on a mountaintop: a plum mountain, a flame above its summit, and two
pairs of arcs around the flame (the signal going out). Everything is drawn on a 1024-unit grid.
All shapes are emitted with transforms baked into absolute coordinates, so the same path data
can feed SVG files and Android vector drawables.
"""
import math
import re

# Dawn palette. Token names match shared/design-tokens/tokens.json; the rest are artwork-only colors.
PALETTE = {
    "brand-fire": "#e63d1a",    # flame base, identity red-orange
    "brand-flame": "#ff861f",   # flame body, inner signal arcs
    "flame-tip": "#ffb83d",     # flame tip (gradient end)
    "flame-core": "#fff6e0",    # the hot core inside the flame
    "wave-outer": "#ffc68c",    # outer signal arcs, fading out
    "brand-ember": "#33232d",   # mountain, shadow face; wordmark ink
    "mountain-lit": "#4b3542",  # mountain, lit face
    "dawn-top": "#fff6ee",      # icon background, top
    "dawn-bottom": "#ffe3cf",   # icon background, bottom
}
# Mountain colors for dark backgrounds (lockups on dark, the Dark app icon).
DARK = {
    "brand-ember": "#6e5463",
    "mountain-lit": "#83677a",
    "wordmark": "#fff6ee",
    "night-top": "#2b1e26",
    "night-bottom": "#1c1319",
}

# Flame in its own 280x440 box; the core is the same outline scaled down and sitting low inside it.
FLAME = ("M150 0 C190 80 280 140 280 280 C280 376 218 440 140 440 C62 440 0 378 0 296 "
         "C0 222 44 176 78 140 C78 190 96 222 126 236 C112 156 124 70 150 0 Z")
CORE_IN_FLAME = (72.8, 206.8, 0.48)          # translate x, y, scale inside the flame box
FLAME_ON_GRID = (400, 210, 0.8)              # flame box placed on the 1024 grid
SUMMIT = (512, 640)                          # mountain apex
SLOPE = 560 / 384                            # horizontal run per unit of drop
APEX_ROUND = 70                              # distance cut from each edge at a rounded corner
WAVE_CENTER = (512, 410)
WAVE_RADII = (200, 300)
WAVE_HALF_ANGLE = 36                         # degrees above and below horizontal
WAVE_STROKE = 36

_TOKEN = re.compile(r"[MLCQAZ]|-?\d*\.?\d+")


def fmt(v):
    """Short number: one decimal, no trailing zero."""
    s = f"{v:.1f}"
    return s[:-2] if s.endswith(".0") else s


def transform_path(d, tx=0.0, ty=0.0, s=1.0):
    """Apply scale then translate to an absolute path using only M L C Q A Z commands."""
    toks = _TOKEN.findall(d)
    out, i, cmd = [], 0, None
    arity = {"M": 2, "L": 2, "C": 6, "Q": 4, "A": 7, "Z": 0}
    while i < len(toks):
        if toks[i].isalpha():
            cmd = toks[i]
            out.append(cmd)
            i += 1
            if cmd == "Z":
                continue
        args = [float(t) for t in toks[i:i + arity[cmd]]]
        i += arity[cmd]
        if cmd == "A":
            rx, ry, rot, large, sweep, x, y = args
            out += [fmt(rx * s), fmt(ry * s), fmt(rot), str(int(large)), str(int(sweep)),
                    fmt(x * s + tx), fmt(y * s + ty)]
        else:
            out += [fmt(v * s + (tx if k % 2 == 0 else ty)) for k, v in enumerate(args)]
    return " ".join(out).replace(" Z", " Z")


def rounded_polygon(points, cut):
    """Closed polygon whose corners are rounded by cutting `cut` units along each edge."""
    n = len(points)
    segs = []
    for k in range(n):
        p0, p1, p2 = points[k - 1], points[k], points[(k + 1) % n]
        c = cut[k] if isinstance(cut, (list, tuple)) else cut

        def toward(a, b):
            dx, dy = b[0] - a[0], b[1] - a[1]
            length = math.hypot(dx, dy)
            return (a[0] + dx / length * c, a[1] + dy / length * c)

        segs.append((toward(p1, p0), p1, toward(p1, p2)))
    d = f"M{fmt(segs[0][2][0])} {fmt(segs[0][2][1])}"
    for a, ctrl, b in segs[1:] + segs[:1]:
        d += f" L{fmt(a[0])} {fmt(a[1])} Q{fmt(ctrl[0])} {fmt(ctrl[1])} {fmt(b[0])} {fmt(b[1])}"
    return d + " Z"


def mountain(base_y, base_round=0):
    """Mountain from the summit down to base_y; base corners rounded only when it doesn't bleed."""
    sx, sy = SUMMIT
    half = (base_y - sy) * SLOPE
    pts = [(sx - half, base_y), (sx, sy), (sx + half, base_y)]
    if not base_round:
        ax, ay = sx, sy
        length = math.hypot(half, base_y - sy)
        ux, uy = half / length * APEX_ROUND, (base_y - sy) / length * APEX_ROUND
        return (f"M{fmt(sx - half)} {fmt(base_y)} L{fmt(ax - ux)} {fmt(ay + uy)} "
                f"Q{fmt(ax)} {fmt(ay)} {fmt(ax + ux)} {fmt(ay + uy)} L{fmt(sx + half)} {fmt(base_y)} Z")
    return rounded_polygon(pts, [base_round, APEX_ROUND, base_round])


def lit_face(base_y):
    """Polygon left of the ridge line; clip it with the mountain to get the lit face."""
    sx, sy = SUMMIT
    ridge_x = sx + (base_y + 16 - sy) * 0.32
    return f"M-600 {fmt(base_y + 16)} L-600 {fmt(sy - 40)} L{sx} {sy} L{fmt(ridge_x)} {fmt(base_y + 16)} Z"


def flame_paths():
    """(outer flame, core) on the 1024 grid."""
    fx, fy, fs = FLAME_ON_GRID
    cx, cy, cs = CORE_IN_FLAME
    outer = transform_path(FLAME, fx, fy, fs)
    core = transform_path(FLAME, fx + cx * fs, fy + cy * fs, cs * fs)
    return outer, core


def wave_paths(radius):
    """Left and right arcs of one signal ring."""
    cx, cy = WAVE_CENTER
    a = math.radians(WAVE_HALF_ANGLE)
    dx, dy = radius * math.cos(a), radius * math.sin(a)
    r = fmt(radius)
    right = f"M{fmt(cx + dx)} {fmt(cy - dy)} A{r} {r} 0 0 1 {fmt(cx + dx)} {fmt(cy + dy)}"
    left = f"M{fmt(cx - dx)} {fmt(cy - dy)} A{r} {r} 0 0 0 {fmt(cx - dx)} {fmt(cy + dy)}"
    return left, right


def mark_layers(base_y=1024, base_round=0, outer_waves=True, dark=False, uid="m"):
    """SVG elements for the mark (no background). Returns (defs, body)."""
    ember = DARK["brand-ember"] if dark else PALETTE["brand-ember"]
    lit = DARK["mountain-lit"] if dark else PALETTE["mountain-lit"]
    outer, core = flame_paths()
    mpath = mountain(base_y, base_round)
    defs = (f'<linearGradient id="{uid}-flame" x1="0" y1="1" x2="0" y2="0">'
            f'<stop offset="0" stop-color="{PALETTE["brand-fire"]}"/>'
            f'<stop offset=".55" stop-color="{PALETTE["brand-flame"]}"/>'
            f'<stop offset="1" stop-color="{PALETTE["flame-tip"]}"/></linearGradient>'
            f'<clipPath id="{uid}-clip"><path d="{mpath}"/></clipPath>')
    body = [f'<path d="{mpath}" fill="{ember}"/>',
            f'<path clip-path="url(#{uid}-clip)" d="{lit_face(base_y)}" fill="{lit}"/>',
            f'<path d="{outer}" fill="url(#{uid}-flame)"/>',
            f'<path d="{core}" fill="{PALETTE["flame-core"]}"/>']
    rings = [(WAVE_RADII[0], PALETTE["brand-flame"])]
    if outer_waves:
        rings.append((WAVE_RADII[1], PALETTE["wave-outer"]))
    for radius, color in rings:
        for d in wave_paths(radius):
            body.append(f'<path d="{d}" fill="none" stroke="{color}" stroke-width="{WAVE_STROKE}" '
                        f'stroke-linecap="round"/>')
    return defs, "".join(body)


def mono_layers(base_y=1024, base_round=0, outer_waves=True, color="#000000"):
    """One-color silhouette (themed and tinted icons): the core is cut out of the flame."""
    outer, core = flame_paths()
    body = [f'<path d="{mountain(base_y, base_round)}" fill="{color}"/>',
            f'<path d="{outer} {core}" fill="{color}" fill-rule="evenodd"/>']
    radii = WAVE_RADII if outer_waves else WAVE_RADII[:1]
    for radius in radii:
        for d in wave_paths(radius):
            body.append(f'<path d="{d}" fill="none" stroke="{color}" stroke-width="{WAVE_STROKE}" '
                        f'stroke-linecap="round"/>')
    return "".join(body)


def gradient_bg(uid, top, bottom, w=1024, h=1024):
    """(defs, rect) for a vertical background gradient."""
    defs = (f'<linearGradient id="{uid}" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="{top}"/>'
            f'<stop offset="1" stop-color="{bottom}"/></linearGradient>')
    return defs, f'<rect width="{w}" height="{h}" fill="url(#{uid})"/>'


# Bounding box of the standalone mark (mountain base at MARK_BASE_Y, rounded base corners).
MARK_BASE_Y = 930
MARK_BASE_ROUND = 48
MARK_BOX = (60, 190, 904, 760)               # x, y, width, height on the 1024 grid
