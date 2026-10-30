#!/bin/zsh
# Gan tag release va day len tung repo, sau khi PR cua release-push.sh da merge vao main.
# Chay NGOAI sandbox qua nut run cua sep:
#   zsh handlive/tools/release-tag.sh v0.2.0
#
# Voi tag <tag> (dang vN.N.N):
#   1. git fetch origin cho tung repo
#   2. neu main local khac origin/main: noi dung cay (tree) cua hai ben phai giong het nhau,
#      khac la dung (origin/main co thu chua kiem, hoac main local co commit chua vao PR).
#      Cay giong nhau thi dua main local ve origin/main:
#        - main local la ancestor (merge commit): git merge --ff-only origin/main
#        - lich su bi viet lai (rebase/squash, SHA moi): git reset --soft origin/main
#          (cay giong het nen index va working tree khong doi; commit cu van con trong reflog)
#   3. kiem tra phan loi cua tag khop versionName (Android) va MARKETING_VERSION (Apple, ca 3 target)
#   4. git tag <tag> roi git push origin <tag>, theo thu tu hub -> shared -> android -> apple
# Dung ngay khi mot buoc loi (khong tiep tuc repo sau, khong tag nhung repo con lai).
#
# Merge PR tren GitHub nen dung "Create a merge commit" (giu nguyen SHA cua commit da kiem).
# "Rebase and merge" va "Squash and merge" deu tao SHA moi; script van chay duoc nho buoc so
# cay o tren, nhung commit tren GitHub se khong trung SHA voi commit da review.
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
    (cd "$repo_path" && git diff --quiet main origin/main) \
      || fail "$name: noi dung main local khac origin/main — PR chua merge, origin/main co commit khac, hoac main local co commit chua vao PR"
    if (cd "$repo_path" && git merge-base --is-ancestor main origin/main); then
      echo "+ git merge --ff-only origin/main"
      (cd "$repo_path" && git merge --ff-only origin/main) \
        || fail "$name: git merge --ff-only origin/main that bai"
    else
      echo "+ git reset --soft origin/main  (PR merge bang rebase/squash, cay giong het)"
      (cd "$repo_path" && git reset --soft origin/main) \
        || fail "$name: git reset --soft origin/main that bai"
    fi
    local_sha="$(cd "$repo_path" && git rev-parse main)"
  fi
  [ "$local_sha" = "$remote_sha" ] \
    || fail "$name: main local ($local_sha) khac origin/main ($remote_sha) sau khi dong bo"
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
