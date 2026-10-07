#!/usr/bin/env python3
"""Build the HandLive brand artwork from one geometry (tools/brand/brand_geometry.py).

Writes SVG sources and PNG renders to docs/brand/assets/ in the hub, and optionally the platform app
icons straight into the app repositories of the workspace:

    python3 tools/brand/build_brand_assets.py \
        [--font BeVietnamPro-Bold.ttf] \
        [--android-res android/app/src/main/res] \
        [--apple-icon apple/macOS/HandLive/Resources/AppIcon.icon] [--icon-preview] \
        [--android-design-res android/core/design/src/main/res] \
        [--apple-imageset apple/Packages/HLDesignSystem/Sources/HLDesignSystem/Resources/Images.xcassets]

The last two write the in-app brand mark (welcome screens): an Android vector drawable with a night
variant, and an Apple image set with light and dark PDFs.

The hub always gets the Icon Composer document docs/brand/assets/app-icon/icon-composer/AppIcon.icon;
--apple-icon copies it into the app repository (one document for the Mac and iOS apps), and --icon-preview renders its Liquid Glass preview sheet
with Icon Composer's ictool (Xcode 26 or later, the one xcode-select points at, or $ICTOOL).

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


def ictool_path():
    """Icon Composer's ictool: $ICTOOL, else the one inside the Xcode that xcode-select points at."""
    if os.environ.get("ICTOOL"):
        return os.environ["ICTOOL"]
    developer = subprocess.run(["xcode-select", "-p"], capture_output=True, text=True).stdout.strip()
    return os.path.join(os.path.dirname(developer), "Applications", "Icon Composer.app", "Contents", "Executables",
                        "ictool")


RENDITIONS = ("Default", "Dark", "TintedLight", "TintedDark")
MAC_PREVIEW_SIZES = (16, 32, 128, 512)


def icon_preview():
    """Preview sheets of the Liquid Glass icon, rendered by ictool: AppIcon-preview.png (rows iOS, macOS at 256 px;
    columns Default, Dark, Tinted light, Tinted dark) and AppIcon-preview-mac-sizes.png (the Mac icon at 16, 32,
    128 and 512 pt, actual size at 1x; one row per appearance)."""
    ictool = ictool_path()
    if not os.path.exists(ictool):
        raise SystemExit(f"{ictool} not found: --icon-preview needs Xcode 26 or later (xcode-select -s, or set ICTOOL)")
    made = [_sheet(ictool, "AppIcon-preview.png",
                   [[(platform, rendition, 256) for rendition in RENDITIONS] for platform in ("iOS", "macOS")]),
            _sheet(ictool, "AppIcon-preview-mac-sizes.png",
                   [[("macOS", rendition, size) for size in MAC_PREVIEW_SIZES] for rendition in RENDITIONS])]
    return made


def _sheet(ictool, name, rows):
    """Render each (platform, rendition, size) cell with ictool and lay the rows out on a neutral gray sheet."""
    src = os.path.join(OUT, ICON_DOC)
    sheet = os.path.join(OUT, "app-icon", "icon-composer", name)
    args, cells = [], []
    for row in rows:
        args.append("(")
        for platform, rendition, size in row:
            cell = f"{sheet[:-4]}-{platform}-{rendition}-{size}.png"
            subprocess.run([ictool, src, "--export-image", "--output-file", cell, "--platform", platform,
                            "--rendition", rendition, "--width", str(size), "--height", str(size), "--scale", "1"],
                           check=True, stdout=subprocess.DEVNULL)
            cells.append(cell)
            args += [cell, "-bordercolor", "#8e8e93", "-border", "8"]
        args += ["-gravity", "center", "+append", ")"]
    subprocess.run(["magick", "-background", "#8e8e93", *args, "-gravity", "center", "-append", "-alpha", "remove",
                    "-bordercolor", "#8e8e93", "-border", "8", "+repage", "-strip", sheet], check=True)
    for cell in cells:
        os.remove(cell)
    return os.path.relpath(sheet, OUT)


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--font", help="Be Vietnam Pro Bold TTF, to (re)outline text")
    ap.add_argument("--android-res", help="Android res/ directory to receive the adaptive icon")
    ap.add_argument("--apple-icon", help="AppIcon.icon directory to (re)write (Icon Composer, Liquid Glass; Mac and iOS app icon)")
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
    if args.icon_preview:
        for rel in icon_preview():
            print("hub  ", rel)
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
