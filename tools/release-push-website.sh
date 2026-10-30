#!/bin/zsh
# Day nhanh website v0.2.0 len origin va mo PR.
# Chay NGOAI sandbox qua nut run cua sep:
#   zsh handlive/tools/release-push-website.sh            # chay thuc
#   zsh handlive/tools/release-push-website.sh --dry-run  # chi in lenh, khong push/tao PR
#
# Kiểm nhánh main, fetch origin main, so ahead (0 thì báo và dừng),
# ls-remote nhánh feat/website-v0-2-0 (đã có đúng SHA thì bỏ qua push, khác SHA thì fail),
# push main:feat/website-v0-2-0 (không -u), gh pr list, có thì in link, chưa có thì create.
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
HUB_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

RELEASE_BRANCH="feat/website-v0-2-0"
PR_TITLE="Website: point to v0.2.0"
PR_BODY="Cap nhat link tai va nhan phien ban tren website sang v0.2.0 (#265). Khong doi ma nguon app, khong anh huong release da tag."

DRY_RUN=0
if [ "${1:-}" = "--dry-run" ]; then
  DRY_RUN=1
fi

fail() {
  echo "LOI: $1" >&2
  exit 1
}

echo
echo "== hub ($HUB_ROOT) =="
[ -d "$HUB_ROOT" ] || fail "khong thay thu muc $HUB_ROOT"

(cd "$HUB_ROOT" && git rev-parse --is-inside-work-tree >/dev/null 2>&1) \
  || fail "hub: khong phai git repo"

current_branch="$(cd "$HUB_ROOT" && git branch --show-current)"
[ "$current_branch" = "main" ] || fail "hub: dang o nhanh '$current_branch', can 'main'"

echo "+ git fetch origin main"
(cd "$HUB_ROOT" && git fetch origin main) || fail "hub: git fetch that bai"

ahead="$(cd "$HUB_ROOT" && git rev-list --count origin/main..main 2>/dev/null)"
if [ -z "$ahead" ]; then
  fail "hub: khong doc duoc so commit di truoc origin/main (fetch truoc?)"
fi
if [ "$ahead" -eq 0 ]; then
  echo "hub: main khong di truoc origin/main, bo qua"
  exit 0
fi
echo "hub: main di truoc origin/main $ahead commit"

local_sha="$(cd "$HUB_ROOT" && git rev-parse main)"
remote_branch_sha="$(cd "$HUB_ROOT" && git ls-remote origin "refs/heads/$RELEASE_BRANCH" | awk '{print $1}')"

echo "+ git ls-remote origin refs/heads/$RELEASE_BRANCH"
if [ -n "$remote_branch_sha" ] && [ "$remote_branch_sha" = "$local_sha" ]; then
  echo "hub: origin/$RELEASE_BRANCH da dung SHA ($local_sha), bo qua push"
elif [ -n "$remote_branch_sha" ]; then
  fail "hub: origin/$RELEASE_BRANCH da ton tai voi SHA khac ($remote_branch_sha != $local_sha), khong tu --force"
else
  echo "+ git push origin main:$RELEASE_BRANCH"
  if [ "$DRY_RUN" -eq 1 ]; then
    echo "hub: (dry-run) khong push"
  else
    (cd "$HUB_ROOT" && git push origin "main:$RELEASE_BRANCH") \
      || fail "hub: git push that bai"
  fi
fi

echo "+ gh pr list --head $RELEASE_BRANCH --state open --json url"
if [ "$DRY_RUN" -eq 1 ]; then
  echo "+ gh pr create --base main --head $RELEASE_BRANCH --title ... --body ..."
  echo "hub: (dry-run) khong tao PR"
  exit 0
fi

existing_pr_url="$(cd "$HUB_ROOT" && gh pr list --head "$RELEASE_BRANCH" --state open --json url --jq '.[0].url' 2>/dev/null)"
if [ -n "$existing_pr_url" ]; then
  echo "hub: PR da co -> $existing_pr_url"
  exit 0
fi

pr_url="$(cd "$HUB_ROOT" && gh pr create --base main --head "$RELEASE_BRANCH" --title "$PR_TITLE" --body "$PR_BODY")" \
  || fail "hub: gh pr create that bai"

echo "hub: PR -> $pr_url"

echo
echo "XONG. Merge PR tren GitHub bang 'Create a merge commit'."
