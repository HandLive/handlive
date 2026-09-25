#!/usr/bin/env bash
# Workspace HandLive = kho hub này + bốn kho thành phần clone vào bên trong (android/, apple/, relay/, shared/).
# Bố cục là bắt buộc: build và test đọc ../shared, test Apple và tools/schemas đọc ../docs.
#
#   tools/workspace.sh clone <group-url> [nhánh]   clone kho còn thiếu; <group-url> là tiền tố của group,
#                                                  ví dụ git@github.com:handlive hoặc https://github.com/handlive
#   tools/workspace.sh status                       nhánh và git status của cả năm kho
#   tools/workspace.sh run <lệnh git…>              chạy một lệnh git trong cả năm kho, ví dụ: run fetch --all
set -euo pipefail

HUB="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PARTS=(android apple relay shared)

repo_dir() { if [ "$1" = hub ]; then echo "$HUB"; else echo "$HUB/$1"; fi; }

case "${1:-}" in
  clone)
    GROUP="${2:?thiếu <group-url>, ví dụ git@github.com:handlive}"; BRANCH="${3:-main}"
    for part in "${PARTS[@]}"; do
      if [ -d "$HUB/$part/.git" ]; then echo "đã có: $part"; continue; fi
      git clone --branch "$BRANCH" "${GROUP%/}/handlive-$part.git" "$HUB/$part"
    done ;;
  status)
    for repo in hub "${PARTS[@]}"; do
      dir="$(repo_dir "$repo")"
      if [ ! -d "$dir/.git" ]; then echo "== $repo: chưa clone ($dir)"; continue; fi
      echo "== $repo"; git -C "$dir" status -sb | head -20
    done ;;
  run)
    shift; [ $# -gt 0 ] || { echo "thiếu lệnh git" >&2; exit 2; }
    for repo in hub "${PARTS[@]}"; do
      dir="$(repo_dir "$repo")"; [ -d "$dir/.git" ] || continue
      echo "== $repo"; git -C "$dir" "$@"
    done ;;
  *) sed -n '2,8p' "$0"; exit 2 ;;
esac
