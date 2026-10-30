#!/bin/zsh
# Chạy NGOÀI sandbox: zsh handlive/tools/verify-phase7.sh
#
# Gộp toàn bộ kiểm tra Phase 7 (Bluetooth/Wi-Fi Direct offline) thành một lần bấm:
#   1. Apple: swift test cho HLProtocol, HLCrypto, HLTransport qua
#      ../handlive-apple/Tools/run-package-tests.sh <gói>
#   2. Android: ../handlive-android/gradlew check cho core/protocol, core/crypto,
#      core/transport và testDebugUnitTest cho feature/connection; toàn bộ output
#      ghi vào handlive/.build-logs/gradle-phase7.log (gitignore), in 60 dòng cuối.
#
# Không dừng khi một bước đỏ — chạy hết rồi in tóm tắt; thoát 0 chỉ khi mọi bước xanh.
set -uo pipefail

HUB_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
WORKSPACE_ROOT="$(cd "$HUB_ROOT/.." && pwd)"
APPLE_DIR="$WORKSPACE_ROOT/handlive-apple"
ANDROID_DIR="$WORKSPACE_ROOT/handlive-android"

LOG_DIR="$HUB_ROOT/.build-logs"
mkdir -p "$LOG_DIR"
GRADLE_LOG="$LOG_DIR/gradle-phase7.log"

typeset -a RESULTS
overall_ok=1

echo "== Apple: swift test cho HLProtocol, HLCrypto, HLTransport =="
RUNNER="$APPLE_DIR/Tools/run-package-tests.sh"
for PKG in HLProtocol HLCrypto HLTransport; do
  echo "-- $PKG --"
  if [ ! -f "$RUNNER" ]; then
    echo "  LỖI: không thấy $RUNNER"
    RESULTS+=("Apple $PKG: LỖI (không thấy run-package-tests.sh)")
    overall_ok=0
    continue
  fi
  if zsh "$RUNNER" "$PKG"; then
    PKG_LOG="$APPLE_DIR/.build-logs/$PKG-test.log"
    COUNT_LINE="$(grep -E 'Test run with [0-9]+ tests? in [0-9]+ suites? (passed|failed)' "$PKG_LOG" 2>/dev/null | tail -1 | sed 's/^[[:space:]]*//')"
    [ -z "$COUNT_LINE" ] && COUNT_LINE="không đọc được số test từ $PKG_LOG"
    RESULTS+=("Apple $PKG: XANH — $COUNT_LINE")
  else
    RESULTS+=("Apple $PKG: ĐỎ (xem $APPLE_DIR/.build-logs/$PKG-test.log)")
    overall_ok=0
  fi
done

echo
echo "== Android: gradlew check cho core/protocol, core/crypto, core/transport, feature/connection =="
: "${JAVA_HOME:=/opt/homebrew/opt/openjdk@21/libexec/openjdk.jdk/Contents/Home}"
: "${ANDROID_HOME:=/opt/homebrew/share/android-commandlinetools}"
export JAVA_HOME ANDROID_HOME

GRADLEW="$ANDROID_DIR/gradlew"
if [ ! -f "$GRADLEW" ]; then
  echo "  LỖI: không thấy $GRADLEW"
  RESULTS+=("Android: LỖI (không thấy gradlew)")
  overall_ok=0
else
  env JAVA_HOME="$JAVA_HOME" ANDROID_HOME="$ANDROID_HOME" "$GRADLEW" -p "$ANDROID_DIR" --continue \
    ":core:protocol:check" ":core:crypto:check" ":core:transport:check" ":feature:connection:testDebugUnitTest" \
    > "$GRADLE_LOG" 2>&1
  GRADLE_EXIT=$?
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
  done < <(find "$ANDROID_DIR/core/protocol" "$ANDROID_DIR/core/crypto" "$ANDROID_DIR/core/transport" "$ANDROID_DIR/feature/connection" \
    -path '*/build/test-results/*' -name 'TEST-*.xml' 2>/dev/null)

  if [ "$xml_files" -gt 0 ]; then
    TEST_SUMMARY="$total_tests test trong $xml_files file XML dưới */build/test-results"
  else
    TEST_SUMMARY="không tìm thấy file XML kết quả test dưới */build/test-results, xem $GRADLE_LOG"
  fi
  if [ "$GRADLE_EXIT" -eq 0 ]; then
    RESULTS+=("Android (4 module): XANH — $TEST_SUMMARY")
  else
    RESULTS+=("Android (4 module): ĐỎ (exit=$GRADLE_EXIT) — $TEST_SUMMARY")
    overall_ok=0
  fi
fi

echo
echo "== Tóm tắt =="
for r in "${RESULTS[@]}"; do
  echo "  $r"
done

if [ "$overall_ok" -eq 1 ]; then
  echo "XONG: tất cả bước xanh."
  exit 0
else
  echo "LỖI: có bước đỏ, xem log trên."
  exit 1
fi
