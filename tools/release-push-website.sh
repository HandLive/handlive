#!/bin/zsh
# Day nhanh website va tai lieu v0.2.0 len origin va mo PR.
# Chay NGOAI sandbox qua nut run cua sep:
#   zsh handlive/tools/release-push-website.sh            # chay thuc
#   zsh handlive/tools/release-push-website.sh --dry-run  # chi in lenh, khong push/tao PR
#
# Voi tung repo hub va .github-org (theo thu tu do):
#   Kiểm nhánh main, fetch origin main, so ahead (0 thì báo và dừng),
#   ls-remote nhánh feat/docs-v0-2-0 (đã có đúng SHA thì bỏ qua push, khác SHA thì fail),
#   push main:feat/docs-v0-2-0 (không -u), gh pr list, có thì in link, chưa có thì create.
# Trước push, kiểm .github-org có remote origin; không có thì dừng.
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
HUB_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
WORKSPACE_ROOT="$(cd "$HUB_ROOT/.." && pwd)"

RELEASE_BRANCH="feat/docs-v0-2-0"
PR_TITLE="docs: v0.2.0 release links and status"
PR_BODY="Website (#265) va tai lieu (README, CLAUDE.md, roadmap, profile to chuc) tro toi v0.2.0 da phat hanh. Khong doi ma nguon app, khong anh huong release da tag."

typeset -a REPO_NAMES
typeset -a REPO_PATHS
REPO_NAMES=(hub github-org)
REPO_PATHS=(
  "$HUB_ROOT"
  "$WORKSPACE_ROOT/.github-org"
)

DRY_RUN=0
if [ "${1:-}" = "--dry-run" ]; then
  DRY_RUN=1
fi

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

  (cd "$repo_path" && git remote get-url origin >/dev/null 2>&1) \
    || fail "$name: khong co remote origin"

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
echo "XONG. Merge PR tren GitHub bang 'Create a merge commit'."
