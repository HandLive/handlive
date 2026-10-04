#!/usr/bin/env bash
# Copy the brand files the theme needs from docs/brand/assets (the single source, built by
# tools/brand/build_brand_assets.py) into theme/handlive/assets/img. Rerun after the brand changes.
#   website/bin/sync-brand-assets.sh [path/to/dir/with/BeVietnamPro-*.ttf]
# With a font directory it also rebuilds assets/fonts/be-vietnam-pro-{bold,extrabold,black}.woff2
# (needs fontTools + brotli).
set -euo pipefail
cd "$(dirname "$0")/.."
brand=../docs/brand/assets
img=theme/handlive/assets/img
mkdir -p "$img" theme/handlive/assets/fonts

cp "$brand/logo/handlive-lockup-horizontal.svg" "$img/lockup.svg"
cp "$brand/logo/handlive-lockup-horizontal-on-dark.svg" "$img/lockup-on-dark.svg"
cp "$brand/logo/handlive-mark-compact.svg" "$img/favicon.svg"
magick "$brand/logo/handlive-mark-on-dark.png" -resize 520x -strip "$img/mark-on-dark.png"
cp "$brand/promo/github-social-preview.png" "$img/social-preview.png"
magick "$brand/app-icon/handlive-app-icon.png" -resize 180x180 -strip "$img/apple-touch-icon.png"

if [ "${1:-}" != "" ]; then
  python3 - "$1" theme/handlive/assets/fonts <<'PY'
import os, sys
from fontTools.ttLib import TTFont
for weight in ("Bold", "ExtraBold", "Black"):
    font = TTFont(os.path.join(sys.argv[1], f"BeVietnamPro-{weight}.ttf"))
    font.flavor = "woff2"
    font.save(os.path.join(sys.argv[2], f"be-vietnam-pro-{weight.lower()}.woff2"))
PY
fi
echo "brand assets synced into $img"
