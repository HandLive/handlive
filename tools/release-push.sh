#!/bin/zsh
# Đẩy nhánh release lên origin và mở PR cho từng repo con.
# Chạy NGOÀI sandbox qua nút run của sếp:
#   zsh handlive/tools/release-push.sh            # chạy thực
#   zsh handlive/tools/release-push.sh --dry-run  # chỉ in lệnh, không push/tạo PR
#
# Với từng repo shared, android, apple, hub (theo thứ tự đó):
#   - bỏ qua nếu nhánh main local KHÔNG đi trước origin/main (không có gì để đẩy)
#   - bỏ qua push nếu origin/feat/p07-ghep-bluetooth-offline đã có đúng SHA của main local
#   - dừng và báo lỗi nếu origin/feat/p07-ghep-bluetooth-offline có SHA khác (không --force)
#   - git push origin main:feat/p07-ghep-bluetooth-offline (không đổi upstream của main local)
#   - bỏ qua tạo PR nếu đã có PR open cho nhánh này, chỉ in link
#   - gh pr create --base main --head feat/p07-ghep-bluetooth-offline --title ... --body ...
#   - in link PR
# Dừng ngay khi một bước lỗi (không tiếp tục repo sau). Chạy lại nhiều lần an toàn.
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
HUB_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
WORKSPACE_ROOT="$(cd "$HUB_ROOT/.." && pwd)"

RELEASE_BRANCH="feat/p07-ghep-bluetooth-offline"
PR_TITLE="Phase 7: Bluetooth offline pairing (v0.2.0)"
PR_BODY="Ghép đôi Bluetooth lần đầu không cần mạng (QR luồng B, PIN luồng C dùng CPace-X25519-SHA512), nhãn 'Connected via Bluetooth'. Báo cáo bảo mật PASS ở hub reports/security-scan-0.2.0-2026-10-30.md. Merge bằng 'Create a merge commit'."

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
  echo "LỖI: $1" >&2
  exit 1
}

i=1
while [ "$i" -le "${#REPO_NAMES[@]}" ]; do
  name="${REPO_NAMES[$i]}"
  repo_path="${REPO_PATHS[$i]}"
  i=$((i + 1))

  echo
  echo "== $name ($repo_path) =="
  [ -d "$repo_path" ] || fail "không thấy thư mục $repo_path"

  (cd "$repo_path" && git rev-parse --is-inside-work-tree >/dev/null 2>&1) \
    || fail "$name: không phải git repo"

  current_branch="$(cd "$repo_path" && git branch --show-current)"
  [ "$current_branch" = "main" ] || fail "$name: đang ở nhánh '$current_branch', cần 'main'"

  echo "+ git fetch origin main"
  (cd "$repo_path" && git fetch origin main) || fail "$name: git fetch thất bại"

  ahead="$(cd "$repo_path" && git rev-list --count origin/main..main 2>/dev/null)"
  if [ -z "$ahead" ]; then
    fail "$name: không đọc được số commit đi trước origin/main (fetch trước?)"
  fi
  if [ "$ahead" -eq 0 ]; then
    echo "$name: main không đi trước origin/main, bỏ qua"
    continue
  fi
  echo "$name: main đi trước origin/main $ahead commit"

  local_sha="$(cd "$repo_path" && git rev-parse main)"
  remote_branch_sha="$(cd "$repo_path" && git ls-remote origin "refs/heads/$RELEASE_BRANCH" | awk '{print $1}')"

  echo "+ git ls-remote origin refs/heads/$RELEASE_BRANCH"
  if [ -n "$remote_branch_sha" ] && [ "$remote_branch_sha" = "$local_sha" ]; then
    echo "$name: origin/$RELEASE_BRANCH đã đúng SHA ($local_sha), bỏ qua push"
  elif [ -n "$remote_branch_sha" ]; then
    fail "$name: origin/$RELEASE_BRANCH đã tồn tại với SHA khác ($remote_branch_sha != $local_sha), không tự --force"
  else
    echo "+ git push origin main:$RELEASE_BRANCH"
    if [ "$DRY_RUN" -eq 1 ]; then
      echo "$name: (dry-run) không push"
    else
      (cd "$repo_path" && git push origin "main:$RELEASE_BRANCH") \
        || fail "$name: git push thất bại"
    fi
  fi

  echo "+ gh pr list --head $RELEASE_BRANCH --state open --json url"
  if [ "$DRY_RUN" -eq 1 ]; then
    echo "+ gh pr create --base main --head $RELEASE_BRANCH --title ... --body ..."
    echo "$name: (dry-run) không tạo PR"
    continue
  fi

  existing_pr_url="$(cd "$repo_path" && gh pr list --head "$RELEASE_BRANCH" --state open --json url --jq '.[0].url' 2>/dev/null)"
  if [ -n "$existing_pr_url" ]; then
    echo "$name: PR đã có -> $existing_pr_url"
    continue
  fi

  pr_url="$(cd "$repo_path" && gh pr create --base main --head "$RELEASE_BRANCH" --title "$PR_TITLE" --body "$PR_BODY")" \
    || fail "$name: gh pr create thất bại"

  echo "$name: PR -> $pr_url"
done

echo
echo "XONG. Merge từng PR trên GitHub bằng 'Create a merge commit', rồi chạy: zsh handlive/tools/release-tag.sh <tag>"
