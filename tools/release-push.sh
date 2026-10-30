#!/bin/zsh
# Day nhanh release len origin va mo PR cho tung repo con.
# Chay NGOAI sandbox qua nut run cua sep:
#   zsh handlive/tools/release-push.sh            # chay thuc
#   zsh handlive/tools/release-push.sh --dry-run  # chi in lenh, khong push/tao PR
#
# Voi tung repo shared, android, apple, hub (theo thu tu do):
#   - bo qua neu nhanh main local KHONG di truoc origin/main (khong co gi de day)
#   - git push -u origin main:feat/p07-ghep-bluetooth-offline
#   - gh pr create --base main --head feat/p07-ghep-bluetooth-offline
#   - in link PR
# Dung ngay khi mot buoc loi (khong tiep tuc repo sau).
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
HUB_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
WORKSPACE_ROOT="$(cd "$HUB_ROOT/.." && pwd)"

RELEASE_BRANCH="feat/p07-ghep-bluetooth-offline"

DRY_RUN=0
if [ "${1:-}" = "--dry-run" ]; then
  DRY_RUN=1
fi

typeset -a REPO_NAMES
typeset -a REPO_PATHS
REPO_NAMES=(shared android apple hub)
REPO_PATHS=(
  "$WORKSPACE_ROOT/handlive-shared"
  "$WORKSPACE_ROOT/handlive-android"
  "$WORKSPACE_ROOT/handlive-apple"
  "$HUB_ROOT"
)

fail() {
  echo "LOI: $1" >&2
  exit 1
}

i=1
while [ "$i" -le "${#REPO_NAMES[@]}" ]; do
  name="${REPO_NAMES[$i]}"
  repo_path="${REPO_PATHS[$i]}"
  i=$((i + 1))

  echo
  echo "== $name ($repo_path) =="
  [ -d "$repo_path" ] || fail "khong thay thu muc $repo_path"

  (cd "$repo_path" && git rev-parse --is-inside-work-tree >/dev/null 2>&1) \
    || fail "$name: khong phai git repo"

  current_branch="$(cd "$repo_path" && git branch --show-current)"
  [ "$current_branch" = "main" ] || fail "$name: dang o nhanh '$current_branch', can 'main'"

  echo "+ git fetch origin main"
  (cd "$repo_path" && git fetch origin main) || fail "$name: git fetch that bai"

  ahead="$(cd "$repo_path" && git rev-list --count origin/main..main 2>/dev/null)"
  if [ -z "$ahead" ]; then
    fail "$name: khong doc duoc so commit di truoc origin/main (fetch truoc?)"
  fi
  if [ "$ahead" -eq 0 ]; then
    echo "$name: main khong di truoc origin/main, bo qua"
    continue
  fi
  echo "$name: main di truoc origin/main $ahead commit"

  echo "+ git push -u origin main:$RELEASE_BRANCH"
  echo "+ gh pr create --base main --head $RELEASE_BRANCH --fill"

  if [ "$DRY_RUN" -eq 1 ]; then
    echo "$name: (dry-run) khong push, khong tao PR"
    continue
  fi

  (cd "$repo_path" && git push -u origin "main:$RELEASE_BRANCH") \
    || fail "$name: git push that bai"

  pr_url="$(cd "$repo_path" && gh pr create --base main --head "$RELEASE_BRANCH" --fill)" \
    || fail "$name: gh pr create that bai"

  echo "$name: PR -> $pr_url"
done

echo
echo "XONG."
