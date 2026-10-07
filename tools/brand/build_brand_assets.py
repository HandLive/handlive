#!/usr/bin/env python3
"""Build the HandLive brand artwork from one geometry (tools/brand/brand_geometry.py).

Writes SVG sources and PNG renders to docs/brand/assets/ in the hub, and optionally the platform app
icons straight into the app repositories of the workspace:

    python3 tools/brand/build_brand_assets.py \
        [--font BeVietnamPro-Bold.ttf] \
        [--android-res android/app/src/main/res] \
        [--apple-iconset apple/macOS/HandLive/Resources/Assets.xcassets/AppIcon.appiconset] \
        [--apple-icon apple/iOS/HandLive/Resources/AppIcon.icon] [--icon-preview] \
        [--android-design-res android/core/design/src/main/res] \
        [--apple-imageset apple/Packages/HLDesignSystem/Sources/HLDesignSystem/Resources/Images.xcassets]

The last two write the in-app brand mark (welcome screens): an Android vector drawable with a night
variant, and an Apple image set with light and dark PDFs.

The hub always gets the Icon Composer document docs/brand/assets/app-icon/icon-composer/AppIcon.icon;
--apple-icon copies it into the app repository, and --icon-preview renders its Liquid Glass preview sheet
with Icon Composer's ictool (needs Xcode 26 or later).

Needs rsvg-convert and ImageMagick (`brew install librsvg imagemagick`); --font needs fontTools and is only
required when a text string changed (outlines are cached in tools/brand/text-outlines.json).
"""
import argparse
import os
import shutil
import subprocess
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

import brand_compositions as comp  # noqa: E402
import icon_composer_writer as icon_doc  # noqa: E402
import platform_icon_writers as plat  # noqa: E402
import platform_mark_writers as marks  # noqa: E402
import text_outlines  # noqa: E402

ICTOOL = "/Applications/Xcode.app/Contents/Applications/Icon Composer.app/Contents/Executables/ictool"
ICON_DOC = os.path.join("app-icon", "icon-composer", "AppIcon.icon")
HUB = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
OUT = os.path.join(HUB, "docs", "brand", "assets")

WORD = "HandLive"
COPY = {
    "en": {"title": ["Never miss", "a signal."],
           "lines": ["Clipboard, SMS and calls from your Android phone,", "on your Mac, iPhone and iPad.",
                     "Open source · End-to-end encrypted"],
           "badge": "Public beta · v0.1.0-beta.1"},
    "vi": {"title": ["Không bỏ lỡ", "tín hiệu nào."],
           "lines": ["Bảng nhớ tạm, SMS và cuộc gọi từ điện thoại Android,", "trên Mac, iPhone và iPad.",
                     "Mã nguồn mở · Mã hóa đầu cuối"],
           "badge": "Bản beta công khai · v0.1.0-beta.1"},
}


def all_strings():
    out = [WORD]
    for c in COPY.values():
        out += c["title"] + c["lines"] + [c["badge"]]
    return out


def write(rel, svg, png_width=None, opaque=False):
    """Write an SVG under docs/brand/assets and, when png_width is set, its PNG render next to it."""
    path = os.path.join(OUT, rel)
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, "w", encoding="utf-8") as fh:
        fh.write(svg)
    if png_width:
        render(path, path[:-4] + ".png", png_width, opaque)
    return rel


def render(svg_path, png_path, width, opaque=False):
    subprocess.run(["rsvg-convert", "-w", str(width), svg_path, "-o", png_path], check=True)
    # Store icons (iOS, Play) must have no alpha channel; `-strip` drops timestamps so reruns are byte-stable.
    flags = ["-background", "white", "-alpha", "remove", "-alpha", "off"] if opaque else []
    subprocess.run(["magick", png_path, *flags, "-strip", png_path], check=True)


def build_hub(t):
    word = t[WORD]
    made = [
        write("logo/handlive-mark.svg", comp.mark(), 1024),
        write("logo/handlive-mark-on-dark.svg", comp.mark(dark=True), 1024),
        write("logo/handlive-mark-compact.svg", comp.mark(compact=True), 256),
        write("logo/handlive-mark-mono-black.svg", comp.mark_mono("#000000")),
        write("logo/handlive-mark-mono-white.svg", comp.mark_mono("#ffffff")),
        write("logo/handlive-wordmark.svg", comp.wordmark(word), 1200),
        write("logo/handlive-wordmark-on-dark.svg", comp.wordmark(word, dark=True), 1200),
        write("logo/handlive-lockup-horizontal.svg", comp.lockup_horizontal(word), 1600),
        write("logo/handlive-lockup-horizontal-on-dark.svg", comp.lockup_horizontal(word, dark=True), 1600),
        write("logo/handlive-lockup-stacked.svg", comp.lockup_stacked(word), 1000),
        write("logo/handlive-lockup-stacked-on-dark.svg", comp.lockup_stacked(word, dark=True), 1000),
        write("app-icon/handlive-app-icon.svg", comp.app_icon(), 1024, opaque=True),
        write("app-icon/handlive-app-icon-dark.svg", comp.app_icon("dark"), 1024, opaque=True),
        write("app-icon/handlive-app-icon-tinted.svg", comp.app_icon("tinted"), 1024, opaque=True),
        write("app-icon/handlive-app-icon-macos.svg", comp.app_icon_macos(), 1024),
    ]
    background, foreground = comp.app_icon_layers()
    made += [write("app-icon/icon-composer/background.svg", background),
             write("app-icon/icon-composer/foreground.svg", foreground)]
    made += [os.path.join(ICON_DOC, rel) for rel in icon_doc.write_icon(os.path.join(OUT, ICON_DOC))]
    render(os.path.join(OUT, "app-icon/handlive-app-icon.svg"),
           os.path.join(OUT, "app-icon/handlive-play-store-512.png"), 512, opaque=True)
    en = COPY["en"]
    made.append(write("promo/github-social-preview.svg",
                      comp.promo(1280, 640, word, [t[s] for s in en["title"]], [t[s] for s in en["lines"]]), 1280))
    for lang, c in COPY.items():
        title, lines = [t[s] for s in c["title"]], [t[s] for s in c["lines"]]
        made.append(write(f"promo/readme-hero.{lang}.svg", comp.promo(1600, 600, word, title, lines[:2]), 1600))
        made.append(write(f"promo/release-banner-beta.{lang}.svg",
                          comp.promo(1280, 640, word, title, lines, badge=t[c["badge"]]), 1280))
    return made


def build_apple(iconset):
    os.makedirs(iconset, exist_ok=True)
    tmp = os.path.join(iconset, ".src.svg")
    for appearance, name in (("default", "icon-ios-1024.png"), ("dark", "icon-ios-1024-dark.png"),
                             ("tinted", "icon-ios-1024-tinted.png")):
        with open(tmp, "w", encoding="utf-8") as fh:
            fh.write(comp.app_icon(appearance))
        render(tmp, os.path.join(iconset, name), 1024, opaque=True)
    for pt, scale, compact in plat.MAC_SIZES:
        with open(tmp, "w", encoding="utf-8") as fh:
            fh.write(comp.app_icon_macos(compact))
        render(tmp, os.path.join(iconset, plat.mac_filename(pt, scale)), pt * scale)
    os.remove(tmp)
    with open(os.path.join(iconset, "Contents.json"), "w", encoding="utf-8") as fh:
        fh.write(plat.apple_contents())


def icon_preview():
    """Preview sheet of the Liquid Glass icon: rows iOS, macOS; columns Default, Dark, Tinted light, Tinted dark."""
    if not os.path.exists(ICTOOL):
        raise SystemExit(f"{ICTOOL} not found: --icon-preview needs Xcode 26 or later")
    src, sheet = os.path.join(OUT, ICON_DOC), os.path.join(OUT, "app-icon", "icon-composer", "AppIcon-preview.png")
    rows = []
    for platform in ("iOS", "macOS"):
        cells = []
        for rendition in ("Default", "Dark", "TintedLight", "TintedDark"):
            cell = f"{sheet[:-4]}-{platform}-{rendition}.png"
            subprocess.run([ICTOOL, src, "--export-image", "--output-file", cell, "--platform", platform,
                            "--rendition", rendition, "--width", "256", "--height", "256", "--scale", "1"],
                           check=True, stdout=subprocess.DEVNULL)
            cells.append(cell)
        rows.append(cells)
    args = []
    for cells in rows:
        args += ["("] + cells + ["+append", ")"]
    subprocess.run(["magick", *args, "-append", "-background", "#8e8e93", "-alpha", "remove", "-bordercolor",
                    "#8e8e93", "-border", "8", "+repage", "-strip", sheet], check=True)
    for cells in rows:
        for cell in cells:
            os.remove(cell)
    return os.path.relpath(sheet, OUT)


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--font", help="Be Vietnam Pro Bold TTF, to (re)outline text")
    ap.add_argument("--android-res", help="Android res/ directory to receive the adaptive icon")
    ap.add_argument("--apple-iconset", help="AppIcon.appiconset directory to (re)write")
    ap.add_argument("--apple-icon", help="AppIcon.icon directory to (re)write (Icon Composer, Liquid Glass)")
    ap.add_argument("--icon-preview", action="store_true", help="render the AppIcon.icon preview sheet (ictool)")
    ap.add_argument("--android-design-res", help="Android res/ directory to receive the in-app brand mark drawable")
    ap.add_argument("--apple-imageset", help="Asset catalog (.xcassets) to receive the brand-mark image set")
    args = ap.parse_args()
    for tool in ("rsvg-convert", "magick"):
        if not shutil.which(tool):
            raise SystemExit(f"{tool} not found: brew install librsvg imagemagick")
    outlines = text_outlines.load(all_strings(), args.font)
    for rel in build_hub(outlines):
        print("hub  ", rel)
    if args.android_res:
        for rel in plat.write_android(args.android_res):
            print("android", rel)
    if args.apple_iconset:
        build_apple(args.apple_iconset)
        print("apple ", args.apple_iconset)
    if args.icon_preview:
        print("hub  ", icon_preview())
    if args.apple_icon:
        for rel in icon_doc.write_icon(args.apple_icon):
            print("apple ", os.path.join(args.apple_icon, rel))
    if args.android_design_res:
        for rel in marks.write_android_mark(args.android_design_res):
            print("android", rel)
    if args.apple_imageset:
        print("apple ", marks.write_apple_mark_imageset(args.apple_imageset))


if __name__ == "__main__":
    main()
