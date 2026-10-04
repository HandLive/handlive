"""Outline brand text (the HandLive wordmark, taglines, promo lines) into SVG paths.

Outlines are cached in text-outlines.json next to this file, so the artwork can be rebuilt without
the font. The font (Be Vietnam Pro Bold, SIL OFL 1.1) is needed only when a string is new or changed:
    --font path/to/BeVietnamPro-Bold.ttf
Paths are in font units with the baseline at y = 0 and y pointing down (SVG orientation).
"""
import json
import os
import unicodedata

CACHE = os.path.join(os.path.dirname(os.path.abspath(__file__)), "text-outlines.json")
TRACKING = -10  # font units per glyph (-0.01 em at 1000 units per em), the wordmark's tight setting


def _pair_kerning(font):
    """Map (left glyph, right glyph) -> x-advance adjustment from the GPOS 'kern' feature."""
    if "GPOS" not in font:
        return lambda a, b: 0
    gpos = font["GPOS"].table
    lookups = set()
    for rec in gpos.FeatureList.FeatureRecord:
        if rec.FeatureTag == "kern":
            lookups.update(rec.Feature.LookupListIndex)
    subtables = []
    for idx in sorted(lookups):
        lookup = gpos.LookupList.Lookup[idx]
        for st in lookup.SubTable:
            if lookup.LookupType == 9:
                st = st.ExtSubTable
            if getattr(st, "LookupType", 2) == 2 or hasattr(st, "PairSet") or hasattr(st, "Class1Record"):
                subtables.append(st)

    def kern(a, b):
        for st in subtables:
            cov = st.Coverage.glyphs
            if a not in cov:
                continue
            if st.Format == 1:
                for rec in st.PairSet[cov.index(a)].PairValueRecord:
                    if rec.SecondGlyph == b:
                        return getattr(rec.Value1, "XAdvance", 0) or 0
            elif st.Format == 2:
                c1 = st.ClassDef1.classDefs.get(a, 0)
                c2 = st.ClassDef2.classDefs.get(b, 0)
                value = st.Class1Record[c1].Class2Record[c2].Value1
                adv = getattr(value, "XAdvance", 0) if value else 0
                if adv:
                    return adv
        return 0

    return kern


def outline(font_path, text, tracking=TRACKING):
    """Return {d, width, upm, cap, ascender, descender} for `text` set in the font."""
    from fontTools.pens.svgPathPen import SVGPathPen
    from fontTools.pens.transformPen import TransformPen
    from fontTools.ttLib import TTFont

    font = TTFont(font_path)
    cmap, glyphs, hmtx = font.getBestCmap(), font.getGlyphSet(), font["hmtx"]
    kern = _pair_kerning(font)
    names = [cmap[ord(ch)] for ch in unicodedata.normalize("NFC", text)]
    pen = SVGPathPen(glyphs, ntos=lambda v: f"{v:.1f}".rstrip("0").rstrip("."))
    x = 0
    for i, name in enumerate(names):
        glyphs[name].draw(TransformPen(pen, (1, 0, 0, -1, x, 0)))
        x += hmtx[name][0] + tracking
        if i + 1 < len(names):
            x += kern(name, names[i + 1])
    os2 = font["OS/2"]
    return {"d": pen.getCommands(), "width": x - tracking, "upm": font["head"].unitsPerEm,
            "cap": os2.sCapHeight, "ascender": os2.sTypoAscender, "descender": os2.sTypoDescender}


def load(texts, font_path=None):
    """Outlines for every string in `texts`, from the cache or (when given) the font."""
    cache = {}
    if os.path.exists(CACHE):
        with open(CACHE, encoding="utf-8") as fh:
            cache = json.load(fh)
    missing = [t for t in texts if t not in cache]
    if font_path:
        for t in texts:
            cache[t] = outline(font_path, t)
        with open(CACHE, "w", encoding="utf-8") as fh:
            json.dump({t: cache[t] for t in sorted(cache) if t in texts}, fh, ensure_ascii=False, indent=1)
            fh.write("\n")
    elif missing:
        raise SystemExit(f"No cached outline for {missing}; rerun with --font BeVietnamPro-Bold.ttf")
    return {t: cache[t] for t in texts}
