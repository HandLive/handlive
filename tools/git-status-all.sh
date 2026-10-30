#!/bin/zsh
# In trạng thái git của tất cả 6 repo (hub, shared, android, apple, relay, .github-org)
# theo bố cục cạnh nhau: mọi repo nằm ngang hàng trong thư mục cha của hub.
#
#   zsh handlive/tools/git-status-all.sh
#
# Với mỗi repo: in '== <tên>' rồi git status -sb, log -1 --oneline.
# Repo nào không có .git thì in 'không có repo' và đi tiếp.
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
HUB_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
WORKSPACE_ROOT="$(cd "$HUB_ROOT/.." && pwd)"

typeset -a REPO_NAMES
typeset -a REPO_PATHS
REPO_NAMES=(hub shared android apple relay github-org)
REPO_PATHS=(
  "$HUB_ROOT"
  "$WORKSPACE_ROOT/handlive-shared"
  "$WORKSPACE_ROOT/handlive-android"
  "$WORKSPACE_ROOT/handlive-apple"
  "$WORKSPACE_ROOT/handlive-relay"
  "$WORKSPACE_ROOT/.github-org"
)

i=1
while [ "$i" -le "${#REPO_NAMES[@]}" ]; do
  name="${REPO_NAMES[$i]}"
  repo_path="${REPO_PATHS[$i]}"
  i=$((i + 1))

  echo "== $name ($repo_path) =="

  if [ ! -d "$repo_path/.git" ]; then
    echo "không có repo"
    continue
  fi

  echo "$(cd "$repo_path" && git status -sb)"
  echo "$(cd "$repo_path" && git log -1 --oneline)"
  echo
done
