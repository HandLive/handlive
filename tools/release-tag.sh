#!/bin/zsh
# Gắn tag release và đẩy lên từng repo, sau khi PR của release-push.sh đã merge vào main.
# Chạy NGOÀI sandbox qua nút run của sếp:
#   zsh handlive/tools/release-tag.sh v0.2.0
#
# Với tag <tag> (dạng vN.N.N):
#   1. git fetch origin cho từng repo
#   2. nếu main local khác origin/main: nội dung cây (tree) của hai bên phải giống hệt nhau,
#      khác là dừng (origin/main có thứ chưa kiểm, hoặc main local có commit chưa vào PR).
#      Cây giống nhau thì đưa main local về origin/main:
#        - main local là ancestor (merge commit): git merge --ff-only origin/main
#        - lịch sử bị viết lại (rebase/squash, SHA mới): git reset --soft origin/main
#          (cây giống hệt nên index và working tree không đổi; commit cũ vẫn còn trong reflog)
#   3. kiểm tag chưa tồn tại ở local và trên origin (git ls-remote)
#   Bước 1-3 (Pha 1) chạy đủ 4 repo trước; repo nào lỗi thì dừng, KHÔNG repo nào được gắn tag.
#   4. (Pha 2) chỉ khi cả 4 repo qua Pha 1: git tag <tag> rồi git push, thứ tự hub -> shared -> android -> apple
# Trước Pha 1: phần lõi của tag phải khớp versionName (Android) và MARKETING_VERSION (Apple, cả 3 target).
#
# Merge PR trên GitHub nên dùng "Create a merge commit" (giữ nguyên SHA của commit đã kiểm).
# "Rebase and merge" và "Squash and merge" đều tạo SHA mới; script vẫn chạy được nhờ bước so
# cây ở trên, nhưng commit trên GitHub sẽ không trùng SHA với commit đã review.
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
HUB_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
WORKSPACE_ROOT="$(cd "$HUB_ROOT/.." && pwd)"

ANDROID_DIR="$WORKSPACE_ROOT/handlive-android"
APPLE_DIR="$WORKSPACE_ROOT/handlive-apple"

ANDROID_GRADLE="$ANDROID_DIR/app/build.gradle.kts"
APPLE_PROJECT_YML="$APPLE_DIR/project.yml"

fail() {
  echo "LỖI: $1" >&2
  exit 1
}

TAG="${1:-}"
[ -n "$TAG" ] || fail "thiếu tham số tag, dùng: zsh release-tag.sh <tag> (ví dụ v0.2.0)"

case "$TAG" in
  v*) TAG_CORE="${TAG#v}" ;;
  *) fail "tag '$TAG' phải bắt đầu bằng 'v' (ví dụ v0.2.0)" ;;
esac

echo "== Đọc version hiện tại =="
[ -f "$ANDROID_GRADLE" ] || fail "không thấy $ANDROID_GRADLE"
VERSION_NAME="$(grep -E '^\s*versionName\s*=' "$ANDROID_GRADLE" | head -1 | sed -E 's/.*"([^"]+)".*/\1/')"
[ -n "$VERSION_NAME" ] || fail "không đọc được versionName từ $ANDROID_GRADLE"
echo "Android versionName = $VERSION_NAME"

[ -f "$APPLE_PROJECT_YML" ] || fail "không thấy $APPLE_PROJECT_YML"

typeset -a MARKETING_VALUES
MARKETING_VALUES=("${(@f)$(grep -E '^\s*MARKETING_VERSION:' "$APPLE_PROJECT_YML" | sed -E 's/.*"([^"]+)".*/\1/')}")
[ "${#MARKETING_VALUES[@]}" -gt 0 ] || fail "không đọc được MARKETING_VERSION từ $APPLE_PROJECT_YML"
MARKETING_VERSION="${MARKETING_VALUES[1]}"
for v in "${MARKETING_VALUES[@]}"; do
  [ "$v" = "$MARKETING_VERSION" ] \
    || fail "$APPLE_PROJECT_YML có nhiều giá trị MARKETING_VERSION khác nhau ('$MARKETING_VERSION' và '$v') — bump version chưa đồng bộ hết target"
done
echo "Apple MARKETING_VERSION = $MARKETING_VERSION (${#MARKETING_VALUES[@]} target, đều khớp)"

typeset -a PROJECT_VERSION_VALUES
PROJECT_VERSION_VALUES=("${(@f)$(grep -E '^\s*CURRENT_PROJECT_VERSION:' "$APPLE_PROJECT_YML" | sed -E 's/.*"([^"]+)".*/\1/')}")
[ "${#PROJECT_VERSION_VALUES[@]}" -gt 0 ] || fail "không đọc được CURRENT_PROJECT_VERSION từ $APPLE_PROJECT_YML"
FIRST_PROJECT_VERSION="${PROJECT_VERSION_VALUES[1]}"
for v in "${PROJECT_VERSION_VALUES[@]}"; do
  [ "$v" = "$FIRST_PROJECT_VERSION" ] \
    || fail "$APPLE_PROJECT_YML có nhiều giá trị CURRENT_PROJECT_VERSION khác nhau ('$FIRST_PROJECT_VERSION' và '$v') — bump version chưa đồng bộ hết target"
done
echo "Apple CURRENT_PROJECT_VERSION = $FIRST_PROJECT_VERSION (${#PROJECT_VERSION_VALUES[@]} target, đều khớp)"

[ "$TAG_CORE" = "$VERSION_NAME" ] \
  || fail "tag '$TAG' (phần lõi '$TAG_CORE') không khớp versionName Android '$VERSION_NAME'"
[ "$TAG_CORE" = "$MARKETING_VERSION" ] \
  || fail "tag '$TAG' (phần lõi '$TAG_CORE') không khớp MARKETING_VERSION Apple '$MARKETING_VERSION'"
echo "Tag '$TAG' khớp versionName và MARKETING_VERSION ($TAG_CORE)"

typeset -a REPO_NAMES
typeset -a REPO_PATHS
REPO_NAMES=(hub shared android apple)
REPO_PATHS=(
  "$HUB_ROOT"
  "$WORKSPACE_ROOT/handlive-shared"
  "$ANDROID_DIR"
  "$APPLE_DIR"
)

typeset -a TAG_SHAS

# Pha 1: kiểm đủ 4 repo, chưa gắn tag nào. Repo nào lỗi thì dừng, không repo nào có tag.
echo
echo "==== Pha 1: kiểm 4 repo ===="
i=1
while [ "$i" -le "${#REPO_NAMES[@]}" ]; do
  name="${REPO_NAMES[$i]}"
  repo_path="${REPO_PATHS[$i]}"

  echo
  echo "== $name ($repo_path) =="
  [ -d "$repo_path" ] || fail "không thấy thư mục $repo_path"
  (cd "$repo_path" && git rev-parse --is-inside-work-tree >/dev/null 2>&1) \
    || fail "$name: không phải git repo"

  echo "+ git fetch origin"
  (cd "$repo_path" && git fetch origin) || fail "$name: git fetch thất bại"

  current_branch="$(cd "$repo_path" && git branch --show-current)"
  [ "$current_branch" = "main" ] || fail "$name: đang ở nhánh '$current_branch', cần 'main'"

  local_sha="$(cd "$repo_path" && git rev-parse main)"
  remote_sha="$(cd "$repo_path" && git rev-parse origin/main)"
  if [ "$local_sha" != "$remote_sha" ]; then
    (cd "$repo_path" && git diff --quiet main origin/main) \
      || fail "$name: nội dung main local khác origin/main — PR chưa merge, origin/main có commit khác, hoặc main local có commit chưa vào PR"
    if (cd "$repo_path" && git merge-base --is-ancestor main origin/main); then
      echo "+ git merge --ff-only origin/main"
      (cd "$repo_path" && git merge --ff-only origin/main) \
        || fail "$name: git merge --ff-only origin/main thất bại"
    else
      echo "+ git reset --soft origin/main  (PR merge bằng rebase/squash, cây giống hệt)"
      (cd "$repo_path" && git reset --soft origin/main) \
        || fail "$name: git reset --soft origin/main thất bại"
    fi
    local_sha="$(cd "$repo_path" && git rev-parse main)"
  fi
  [ "$local_sha" = "$remote_sha" ] \
    || fail "$name: main local ($local_sha) khác origin/main ($remote_sha) sau khi đồng bộ"
  echo "$name: main khớp origin/main ($local_sha)"

  if (cd "$repo_path" && git rev-parse -q --verify "refs/tags/$TAG" >/dev/null); then
    fail "$name: tag '$TAG' đã tồn tại ở local"
  fi
  (cd "$repo_path" && git ls-remote --exit-code --tags origin "refs/tags/$TAG" >/dev/null)
  ls_code=$?
  case "$ls_code" in
    2) ;;
    0) fail "$name: tag '$TAG' đã tồn tại trên origin" ;;
    *) fail "$name: git ls-remote thất bại (mã $ls_code)" ;;
  esac
  echo "$name: tag '$TAG' chưa có ở local và origin"

  TAG_SHAS[$i]="$local_sha"
  i=$((i + 1))
done

# Pha 2: cả 4 repo đã qua Pha 1, mới gắn tag và đẩy.
echo
echo "==== Pha 2: tag và đẩy ===="
i=1
while [ "$i" -le "${#REPO_NAMES[@]}" ]; do
  name="${REPO_NAMES[$i]}"
  repo_path="${REPO_PATHS[$i]}"
  sha="${TAG_SHAS[$i]}"
  i=$((i + 1))

  echo
  echo "== $name =="
  echo "+ git tag $TAG $sha"
  (cd "$repo_path" && git tag "$TAG" "$sha") || fail "$name: git tag thất bại"

  echo "+ git push origin refs/tags/$TAG"
  (cd "$repo_path" && git push origin "refs/tags/$TAG") \
    || fail "$name: git push tag thất bại — các repo trước đã có tag trên origin; sửa lỗi rồi đẩy tay: git -C $repo_path push origin refs/tags/$TAG"

  echo "$name: đã tag và đẩy $TAG"
done

echo
echo "XONG: $TAG đã tag và đẩy theo thứ tự hub -> shared -> android -> apple."
