#!/usr/bin/env bash
# Workspace HandLive = kho hub này + các kho thành phần clone vào bên trong: android/, apple/, relay/, shared/
# (handlive-<phần>) và .github-org/ (kho HandLive/.github: hồ sơ org, file cộng đồng).
# Bố cục là bắt buộc: build và test đọc ../shared, test Apple và tools/schemas đọc ../docs.
#
#   tools/workspace.sh clone <group-url> [nhánh]   clone kho còn thiếu; <group-url> là tiền tố của group,
#                                                  ví dụ git@github.com:HandLive hoặc https://github.com/HandLive
#   tools/workspace.sh status                       nhánh và git status của mọi kho
#   tools/workspace.sh run <lệnh git…>              chạy một lệnh git trong mọi kho, ví dụ: run fetch --all
#   tools/workspace.sh remotes <group-url>         đặt origin cho mọi kho theo tên kho trên group
#   tools/workspace.sh push                         đẩy main của các kho thành phần; hub đẩy main và nhánh hiện tại
#   tools/workspace.sh hooks                        bật hook .githooks (từ chối commit mang tên công cụ AI) cho mọi kho
set -euo pipefail

HUB="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
REPOS=(hub android apple relay shared .github-org)

repo_dir() { if [ "$1" = hub ]; then echo "$HUB"; else echo "$HUB/$1"; fi; }
repo_name() { case "$1" in hub) echo handlive ;; .github-org) echo .github ;; *) echo "handlive-$1" ;; esac; }

case "${1:-}" in
  clone)
    GROUP="${2:?thiếu <group-url>, ví dụ git@github.com:HandLive}"; BRANCH="${3:-main}"
    for repo in "${REPOS[@]}"; do
      [ "$repo" = hub ] && continue
      dir="$(repo_dir "$repo")"
      if [ -d "$dir/.git" ]; then echo "đã có: $repo"; continue; fi
      git clone --branch "$BRANCH" "${GROUP%/}/$(repo_name "$repo").git" "$dir"
    done ;;
  status)
    for repo in "${REPOS[@]}"; do
      dir="$(repo_dir "$repo")"
      if [ ! -d "$dir/.git" ]; then echo "== $repo: chưa clone ($dir)"; continue; fi
      echo "== $repo"; git -C "$dir" status -sb | head -20
    done ;;
  run)
    shift; [ $# -gt 0 ] || { echo "thiếu lệnh git" >&2; exit 2; }
    for repo in "${REPOS[@]}"; do
      dir="$(repo_dir "$repo")"; [ -d "$dir/.git" ] || continue
      echo "== $repo"; git -C "$dir" "$@"
    done ;;
  remotes)
    GROUP="${2:?thiếu <group-url>, ví dụ git@github.com:HandLive}"
    for repo in "${REPOS[@]}"; do
      dir="$(repo_dir "$repo")"; [ -d "$dir/.git" ] || continue
      url="${GROUP%/}/$(repo_name "$repo").git"
      if git -C "$dir" remote get-url origin >/dev/null 2>&1; then git -C "$dir" remote set-url origin "$url"; else git -C "$dir" remote add origin "$url"; fi
      echo "$repo → $url"
    done ;;
  push)
    for repo in "${REPOS[@]}"; do
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
    for repo in "${REPOS[@]}"; do
      dir="$(repo_dir "$repo")"; [ -f "$dir/.githooks/commit-msg" ] || continue
      chmod +x "$dir/.githooks/commit-msg" "$dir/.githooks/check-commits.sh"
      git -C "$dir" config core.hooksPath .githooks && echo "$repo: core.hooksPath = .githooks"
    done ;;
  *) sed -n '2,12p' "$0"; exit 2 ;;
esac
