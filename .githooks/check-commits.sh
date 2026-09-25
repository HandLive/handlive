#!/usr/bin/env bash
# Kiểm một dải commit không mang danh tính hay trailer của công cụ AI (cùng mẫu với hook commit-msg).
# Dùng trong CI (job commit-policy) và tay: .githooks/check-commits.sh [<rev-range> | --max-count=N <commit>]
# Mặc định kiểm origin/main..HEAD.
set -euo pipefail
dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
pattern="$(sed -n '1p' "$dir/ai-identity.pattern")"
if [ $# -eq 0 ]; then set -- origin/main..HEAD; fi
bad=0; n=0
for c in $(git rev-list "$@"); do
  n=$((n + 1))
  if git log -1 --format='%an <%ae>%n%cn <%ce>%n%B' "$c" | grep -iqE "$pattern"; then
    echo "::error::commit $c ($(git log -1 --format=%s "$c")) mang tên công cụ AI"; bad=1
  fi
done
if [ "$bad" -eq 0 ]; then echo "commit sạch: đã kiểm $n commit"; fi
exit "$bad"
