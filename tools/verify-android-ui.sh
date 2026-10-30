#!/bin/zsh
# Chạy NGOÀI sandbox: zsh handlive/tools/verify-android-ui.sh
#
# Kiểm tra Android UI (nhãn Bluetooth trong danh sách thiết bị):
#   1. core:design:check — hiệu ứng, thành phần UI
#   2. core:strings:check — chuỗi tìm kiếm, catalog
#   3. feature:pairing:check — logic ghép, UI pairing
#   4. app:testFossDebugUnitTest — test toàn bộ app (Foss flavor, Debug)
# Toàn bộ output ghi vào handlive/.build-logs/gradle-android-ui.log (gitignore),
# in 60 dòng cuối. Không dừng khi một bước đỏ — chạy hết rồi in tóm tắt;
# thoát 0 chỉ khi tất cả bước xanh.
set -uo pipefail

HUB_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
WORKSPACE_ROOT="$(cd "$HUB_ROOT/.." && pwd)"
ANDROID_DIR="$WORKSPACE_ROOT/handlive-android"

LOG_DIR="$HUB_ROOT/.build-logs"
mkdir -p "$LOG_DIR"
GRADLE_LOG="$LOG_DIR/gradle-android-ui.log"

overall_ok=1
TEST_SUMMARY=""

echo "== Android: gradlew check cho core:design, core:strings, feature:pairing và app:testFossDebugUnitTest =="
: "${JAVA_HOME:=/opt/homebrew/opt/openjdk@21/libexec/openjdk.jdk/Contents/Home}"
: "${ANDROID_HOME:=/opt/homebrew/share/android-commandlinetools}"
export JAVA_HOME ANDROID_HOME

GRADLEW="$ANDROID_DIR/gradlew"
if [ ! -f "$GRADLEW" ]; then
  echo "  LỖI: không thấy $GRADLEW"
  overall_ok=0
  EXIT=1
else
  env JAVA_HOME="$JAVA_HOME" ANDROID_HOME="$ANDROID_HOME" "$GRADLEW" -p "$ANDROID_DIR" --continue \
    ":core:design:check" ":core:strings:check" ":feature:pairing:check" ":app:testFossDebugUnitTest" \
    > "$GRADLE_LOG" 2>&1
  EXIT=$?
  echo "  == 60 dòng cuối của $GRADLE_LOG =="
  tail -n 60 "$GRADLE_LOG"

  # Gradle không in số test ra console theo mặc định (không có testLogging trong build.gradle.kts),
  # nên cộng thuộc tính tests= từ các file JUnit XML mà gradle tự ghi cho mỗi module.
  total_tests=0
  xml_files=0
  while IFS= read -r xml; do
    [ -z "$xml" ] && continue
    n="$(grep -o 'tests="[0-9]*"' "$xml" | head -1 | grep -o '[0-9]*')"
    [ -n "$n" ] && total_tests=$((total_tests + n))
    xml_files=$((xml_files + 1))
  done < <(find "$ANDROID_DIR/core/design" "$ANDROID_DIR/core/strings" "$ANDROID_DIR/feature/pairing" "$ANDROID_DIR/app" \
    -path '*/build/test-results/*' -name 'TEST-*.xml' 2>/dev/null)

  if [ "$xml_files" -gt 0 ]; then
    TEST_SUMMARY="$total_tests test trong $xml_files file XML dưới */build/test-results"
  else
    TEST_SUMMARY="không tìm thấy file XML kết quả test dưới */build/test-results, xem $GRADLE_LOG"
  fi
fi

echo
echo "== Tóm tắt =="
if [ "$EXIT" -eq 0 ]; then
  echo "  core:design:check — XANH"
  echo "  core:strings:check — XANH"
  echo "  feature:pairing:check — XANH"
  echo "  app:testFossDebugUnitTest — XANH ($TEST_SUMMARY)"
  echo "XONG: tất cả bước xanh."
else
  echo "  Gradle exit $EXIT"
  echo "  Test summary: $TEST_SUMMARY"
  echo "LỖI: có bước đỏ, xem log trên."
  overall_ok=0
fi

echo "EXIT=$EXIT"
exit "$EXIT"
