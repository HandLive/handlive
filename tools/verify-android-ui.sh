#!/bin/zsh
# Chay NGOAI sandbox: zsh handlive/tools/verify-android-ui.sh
#
# Kiem tra Android UI (nhan Bluetooth trong danh sach thiet bi):
#   1. core:design:check — hieu ung, thanh phan UI
#   2. core:strings:check — chuoi tim kiem, catalog
#   3. feature:pairing:check — logic cap, UI pairing
#   4. app:testFossDebugUnitTest — test toan bo app (Foss flavor, Debug)
# Toan bo output ghi vao handlive/.build-logs/gradle-android-ui.log (gitignore),
# in 60 dong cuoi. Khong dung khi mot buoc do — chay het roi in tom tat;
# thoat 0 chi khi tat ca buoc xanh.
set -uo pipefail

HUB_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
WORKSPACE_ROOT="$(cd "$HUB_ROOT/.." && pwd)"
ANDROID_DIR="$WORKSPACE_ROOT/handlive-android"

LOG_DIR="$HUB_ROOT/.build-logs"
mkdir -p "$LOG_DIR"
GRADLE_LOG="$LOG_DIR/gradle-android-ui.log"

overall_ok=1
TEST_SUMMARY=""

echo "== Android: gradlew check cho core:design, core:strings, feature:pairing va app:testFossDebugUnitTest =="
: "${JAVA_HOME:=/opt/homebrew/opt/openjdk@21/libexec/openjdk.jdk/Contents/Home}"
: "${ANDROID_HOME:=/opt/homebrew/share/android-commandlinetools}"
export JAVA_HOME ANDROID_HOME

GRADLEW="$ANDROID_DIR/gradlew"
if [ ! -f "$GRADLEW" ]; then
  echo "  LOI: khong thay $GRADLEW"
  overall_ok=0
  EXIT=1
else
  env JAVA_HOME="$JAVA_HOME" ANDROID_HOME="$ANDROID_HOME" "$GRADLEW" -p "$ANDROID_DIR" --continue \
    ":core:design:check" ":core:strings:check" ":feature:pairing:check" ":app:testFossDebugUnitTest" \
    > "$GRADLE_LOG" 2>&1
  EXIT=$?
  echo "  == 60 dong cuoi cua $GRADLE_LOG =="
  tail -n 60 "$GRADLE_LOG"

  # Gradle khong in so test ra console theo mac dinh (khong co testLogging trong build.gradle.kts),
  # nen cong thuoc tinh tests= tu cac file JUnit XML ma gradle tu ghi cho moi module.
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
    TEST_SUMMARY="$total_tests test trong $xml_files file XML duoi */build/test-results"
  else
    TEST_SUMMARY="khong tim thay file XML ket qua test duoi */build/test-results, xem $GRADLE_LOG"
  fi
fi

echo
echo "== Tom tat =="
if [ "$EXIT" -eq 0 ]; then
  echo "  core:design:check — XANH"
  echo "  core:strings:check — XANH"
  echo "  feature:pairing:check — XANH"
  echo "  app:testFossDebugUnitTest — XANH ($TEST_SUMMARY)"
  echo "XONG: tat ca buoc xanh."
else
  echo "  Gradle exit $EXIT"
  echo "  Test summary: $TEST_SUMMARY"
  echo "LOI: co buoc do, xem log tren."
  overall_ok=0
fi

echo "EXIT=$EXIT"
exit "$EXIT"
