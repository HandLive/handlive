#!/usr/bin/env bash
# Copy the brand files the theme needs from docs/brand/assets (the single source, built by
# tools/brand/build_brand_assets.py) into theme/handlive/assets/img. Rerun after the brand changes.
#   website/bin/sync-brand-assets.sh [path/to/BeVietnamPro-Bold.ttf]
# With a font path it also rebuilds assets/fonts/be-vietnam-pro-bold.woff2 (needs fontTools + brotli).
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
  python3 - "$1" theme/handlive/assets/fonts/be-vietnam-pro-bold.woff2 <<'PY'
import sys
from fontTools.ttLib import TTFont
font = TTFont(sys.argv[1])
font.flavor = "woff2"
font.save(sys.argv[2])
PY
fi
echo "brand assets synced into $img"
