#!/bin/zsh
# Gan tag release va day len tung repo, sau khi PR cua release-push.sh da merge vao main.
# Chay NGOAI sandbox qua nut run cua sep:
#   zsh handlive/tools/release-tag.sh v0.2.0
#
# Voi tag <tag> (dang vN.N.N):
#   1. git fetch origin cho tung repo
#   2. neu main local la ancestor cua origin/main (PR da merge, lich su khong bi viet lai):
#      git merge --ff-only origin/main de cap nhat main local, roi kiem lai local == origin/main
#   3. kiem tra phan loi cua tag khop versionName (Android) va MARKETING_VERSION (Apple, ca 3 target)
#   4. git tag <tag> roi git push origin <tag>, theo thu tu hub -> shared -> android -> apple
# Dung ngay khi mot buoc loi (khong tiep tuc repo sau, khong tag nhung repo con lai).
#
# QUAN TRONG: tren GitHub phai merge PR bang "Create a merge commit" hoac "Rebase and merge".
# KHONG dung "Squash and merge" — squash viet lai lich su thanh 1 commit moi, main local se
# khong con la ancestor cua origin/main nua va buoc 2 se fail dung nhu thiet ke (khong co cach
# nao --ff-only ma khong mat commit).
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
HUB_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
WORKSPACE_ROOT="$(cd "$HUB_ROOT/.." && pwd)"

ANDROID_DIR="$WORKSPACE_ROOT/handlive-android"
APPLE_DIR="$WORKSPACE_ROOT/handlive-apple"

ANDROID_GRADLE="$ANDROID_DIR/app/build.gradle.kts"
APPLE_PROJECT_YML="$APPLE_DIR/project.yml"

fail() {
  echo "LOI: $1" >&2
  exit 1
}

TAG="${1:-}"
[ -n "$TAG" ] || fail "thieu tham so tag, dung: zsh release-tag.sh <tag> (vi du v0.2.0)"

case "$TAG" in
  v*) TAG_CORE="${TAG#v}" ;;
  *) fail "tag '$TAG' phai bat dau bang 'v' (vi du v0.2.0)" ;;
esac

echo "== Doc version hien tai =="
[ -f "$ANDROID_GRADLE" ] || fail "khong thay $ANDROID_GRADLE"
VERSION_NAME="$(grep -E '^\s*versionName\s*=' "$ANDROID_GRADLE" | head -1 | sed -E 's/.*"([^"]+)".*/\1/')"
[ -n "$VERSION_NAME" ] || fail "khong doc duoc versionName tu $ANDROID_GRADLE"
echo "Android versionName = $VERSION_NAME"

[ -f "$APPLE_PROJECT_YML" ] || fail "khong thay $APPLE_PROJECT_YML"

typeset -a MARKETING_VALUES
MARKETING_VALUES=("${(@f)$(grep -E '^\s*MARKETING_VERSION:' "$APPLE_PROJECT_YML" | sed -E 's/.*"([^"]+)".*/\1/')}")
[ "${#MARKETING_VALUES[@]}" -gt 0 ] || fail "khong doc duoc MARKETING_VERSION tu $APPLE_PROJECT_YML"
MARKETING_VERSION="${MARKETING_VALUES[1]}"
for v in "${MARKETING_VALUES[@]}"; do
  [ "$v" = "$MARKETING_VERSION" ] \
    || fail "$APPLE_PROJECT_YML co nhieu gia tri MARKETING_VERSION khac nhau ('$MARKETING_VERSION' va '$v') — bump version chua dong bo het target"
done
echo "Apple MARKETING_VERSION = $MARKETING_VERSION (${#MARKETING_VALUES[@]} target, deu khop)"

typeset -a PROJECT_VERSION_VALUES
PROJECT_VERSION_VALUES=("${(@f)$(grep -E '^\s*CURRENT_PROJECT_VERSION:' "$APPLE_PROJECT_YML" | sed -E 's/.*"([^"]+)".*/\1/')}")
[ "${#PROJECT_VERSION_VALUES[@]}" -gt 0 ] || fail "khong doc duoc CURRENT_PROJECT_VERSION tu $APPLE_PROJECT_YML"
FIRST_PROJECT_VERSION="${PROJECT_VERSION_VALUES[1]}"
for v in "${PROJECT_VERSION_VALUES[@]}"; do
  [ "$v" = "$FIRST_PROJECT_VERSION" ] \
    || fail "$APPLE_PROJECT_YML co nhieu gia tri CURRENT_PROJECT_VERSION khac nhau ('$FIRST_PROJECT_VERSION' va '$v') — bump version chua dong bo het target"
done
echo "Apple CURRENT_PROJECT_VERSION = $FIRST_PROJECT_VERSION (${#PROJECT_VERSION_VALUES[@]} target, deu khop)"

[ "$TAG_CORE" = "$VERSION_NAME" ] \
  || fail "tag '$TAG' (phan loi '$TAG_CORE') khong khop versionName Android '$VERSION_NAME'"
[ "$TAG_CORE" = "$MARKETING_VERSION" ] \
  || fail "tag '$TAG' (phan loi '$TAG_CORE') khong khop MARKETING_VERSION Apple '$MARKETING_VERSION'"
echo "Tag '$TAG' khop versionName va MARKETING_VERSION ($TAG_CORE)"

typeset -a REPO_NAMES
typeset -a REPO_PATHS
REPO_NAMES=(hub shared android apple)
REPO_PATHS=(
  "$HUB_ROOT"
  "$WORKSPACE_ROOT/handlive-shared"
  "$ANDROID_DIR"
  "$APPLE_DIR"
)

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

  echo "+ git fetch origin"
  (cd "$repo_path" && git fetch origin) || fail "$name: git fetch that bai"

  current_branch="$(cd "$repo_path" && git branch --show-current)"
  [ "$current_branch" = "main" ] || fail "$name: dang o nhanh '$current_branch', can 'main'"

  local_sha="$(cd "$repo_path" && git rev-parse main)"
  remote_sha="$(cd "$repo_path" && git rev-parse origin/main)"
  if [ "$local_sha" != "$remote_sha" ]; then
    if (cd "$repo_path" && git merge-base --is-ancestor main origin/main); then
      echo "+ git merge --ff-only origin/main"
      (cd "$repo_path" && git merge --ff-only origin/main) \
        || fail "$name: git merge --ff-only origin/main that bai"
      local_sha="$(cd "$repo_path" && git rev-parse main)"
    else
      fail "$name: main local co commit chua co tren origin/main, hoac PR vua merge bang squash/rebase lam doi lich su — merge PR bang 'Create a merge commit' hoac 'Rebase and merge' (khong squash), roi chay lai"
    fi
  fi
  [ "$local_sha" = "$remote_sha" ] \
    || fail "$name: main local ($local_sha) khac origin/main ($remote_sha) sau khi merge --ff-only"
  echo "$name: main khop origin/main ($local_sha)"

  if (cd "$repo_path" && git rev-parse "$TAG" >/dev/null 2>&1); then
    fail "$name: tag '$TAG' da ton tai, khong tag lai"
  fi

  echo "+ git tag $TAG"
  (cd "$repo_path" && git tag "$TAG") || fail "$name: git tag that bai"

  echo "+ git push origin $TAG"
  (cd "$repo_path" && git push origin "$TAG") || fail "$name: git push tag that bai"

  echo "$name: da tag va day $TAG"
done

echo
echo "XONG: $TAG da tag va day theo thu tu hub -> shared -> android -> apple."
