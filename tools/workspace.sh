#!/usr/bin/env bash
# Workspace HandLive = kho hub này + bốn kho thành phần clone vào bên trong (android/, apple/, relay/, shared/).
# Bố cục là bắt buộc: build và test đọc ../shared, test Apple và tools/schemas đọc ../docs.
#
#   tools/workspace.sh clone <group-url> [nhánh]   clone kho còn thiếu; <group-url> là tiền tố của group,
#                                                  ví dụ git@github.com:handlive hoặc https://github.com/handlive
#   tools/workspace.sh status                       nhánh và git status của cả năm kho
#   tools/workspace.sh run <lệnh git…>              chạy một lệnh git trong cả năm kho, ví dụ: run fetch --all
#   tools/workspace.sh remotes <group-url>         đặt origin cho cả năm kho: <group-url>/handlive[-phần].git
#   tools/workspace.sh push                         đẩy main của bốn kho thành phần; hub đẩy main và nhánh hiện tại
#   tools/workspace.sh hooks                        bật hook .githooks (từ chối commit mang tên công cụ AI) cho cả năm kho
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
  remotes)
    GROUP="${2:?thiếu <group-url>, ví dụ git@github.com:HandLive}"
    for repo in hub "${PARTS[@]}"; do
      dir="$(repo_dir "$repo")"; [ -d "$dir/.git" ] || continue
      name=handlive; [ "$repo" != hub ] && name="handlive-$repo"
      url="${GROUP%/}/$name.git"
      if git -C "$dir" remote get-url origin >/dev/null 2>&1; then git -C "$dir" remote set-url origin "$url"; else git -C "$dir" remote add origin "$url"; fi
      echo "$repo → $url"
    done ;;
  push)
    for repo in hub "${PARTS[@]}"; do
      dir="$(repo_dir "$repo")"; [ -d "$dir/.git" ] || continue
      echo "== $repo"
      if [ "$repo" = hub ]; then
        cur="$(git -C "$dir" rev-parse --abbrev-ref HEAD)"; branches=main; [ "$cur" != main ] && branches="main $cur"
        git -C "$dir" push -u origin $branches
      else
        git -C "$dir" push -u origin main
      fi
    done ;;
  hooks)
    for repo in hub "${PARTS[@]}"; do
      dir="$(repo_dir "$repo")"; [ -f "$dir/.githooks/commit-msg" ] || continue
      chmod +x "$dir/.githooks/commit-msg" "$dir/.githooks/check-commits.sh"
      git -C "$dir" config core.hooksPath .githooks && echo "$repo: core.hooksPath = .githooks"
    done ;;
  *) sed -n '2,11p' "$0"; exit 2 ;;
esac
