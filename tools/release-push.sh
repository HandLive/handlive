#!/bin/zsh
# Day nhanh release len origin va mo PR cho tung repo con.
# Chay NGOAI sandbox qua nut run cua sep:
#   zsh handlive/tools/release-push.sh            # chay thuc
#   zsh handlive/tools/release-push.sh --dry-run  # chi in lenh, khong push/tao PR
#
# Voi tung repo shared, android, apple, hub (theo thu tu do):
#   - bo qua neu nhanh main local KHONG di truoc origin/main (khong co gi de day)
#   - bo qua push neu origin/feat/p07-ghep-bluetooth-offline da co dung SHA cua main local
#   - dung va bao loi neu origin/feat/p07-ghep-bluetooth-offline co SHA khac (khong --force)
#   - git push origin main:feat/p07-ghep-bluetooth-offline (khong doi upstream cua main local)
#   - bo qua tao PR neu da co PR open cho nhanh nay, chi in link
#   - gh pr create --base main --head feat/p07-ghep-bluetooth-offline --title ... --body ...
#   - in link PR
# Dung ngay khi mot buoc loi (khong tiep tuc repo sau). Chay lai nhieu lan an toan.
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
HUB_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
WORKSPACE_ROOT="$(cd "$HUB_ROOT/.." && pwd)"

RELEASE_BRANCH="feat/p07-ghep-bluetooth-offline"
PR_TITLE="Phase 7: Bluetooth offline pairing (v0.2.0)"
PR_BODY="Ghep doi Bluetooth lan dau khong can mang (QR luong B, PIN luong C dung CPace-X25519-SHA512), nhan 'Connected via Bluetooth'. Bao cao bao mat PASS o hub reports/security-scan-0.2.0-2026-10-30.md. Merge bang 'Create a merge commit'."

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

  local_sha="$(cd "$repo_path" && git rev-parse main)"
  remote_branch_sha="$(cd "$repo_path" && git ls-remote origin "refs/heads/$RELEASE_BRANCH" | awk '{print $1}')"

  echo "+ git ls-remote origin refs/heads/$RELEASE_BRANCH"
  if [ -n "$remote_branch_sha" ] && [ "$remote_branch_sha" = "$local_sha" ]; then
    echo "$name: origin/$RELEASE_BRANCH da dung SHA ($local_sha), bo qua push"
  elif [ -n "$remote_branch_sha" ]; then
    fail "$name: origin/$RELEASE_BRANCH da ton tai voi SHA khac ($remote_branch_sha != $local_sha), khong tu --force"
  else
    echo "+ git push origin main:$RELEASE_BRANCH"
    if [ "$DRY_RUN" -eq 1 ]; then
      echo "$name: (dry-run) khong push"
    else
      (cd "$repo_path" && git push origin "main:$RELEASE_BRANCH") \
        || fail "$name: git push that bai"
    fi
  fi

  echo "+ gh pr list --head $RELEASE_BRANCH --state open --json url"
  if [ "$DRY_RUN" -eq 1 ]; then
    echo "+ gh pr create --base main --head $RELEASE_BRANCH --title ... --body ..."
    echo "$name: (dry-run) khong tao PR"
    continue
  fi

  existing_pr_url="$(cd "$repo_path" && gh pr list --head "$RELEASE_BRANCH" --state open --json url --jq '.[0].url' 2>/dev/null)"
  if [ -n "$existing_pr_url" ]; then
    echo "$name: PR da co -> $existing_pr_url"
    continue
  fi

  pr_url="$(cd "$repo_path" && gh pr create --base main --head "$RELEASE_BRANCH" --title "$PR_TITLE" --body "$PR_BODY")" \
    || fail "$name: gh pr create that bai"

  echo "$name: PR -> $pr_url"
done

echo
echo "XONG. Merge tung PR tren GitHub bang 'Create a merge commit', roi chay: zsh handlive/tools/release-tag.sh <tag>"
