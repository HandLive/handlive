#!/bin/zsh
# Chay NGOAI sandbox: zsh handlive/tools/verify-phase7.sh
#
# Gop toan bo kiem tra Phase 7 (Bluetooth/Wi-Fi Direct offline) thanh mot lan bam:
#   1. Apple: swift test cho HLProtocol, HLCrypto, HLTransport qua
#      ../handlive-apple/Tools/run-package-tests.sh <goi>
#   2. Android: ../handlive-android/gradlew check cho core/protocol, core/crypto,
#      core/transport va testDebugUnitTest cho feature/connection; toan bo output
#      ghi vao handlive/.build-logs/gradle-phase7.log (gitignore), in 60 dong cuoi.
#
# Khong dung khi mot buoc do — chay het roi in tom tat; thoat 0 chi khi moi buoc xanh.
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
    echo "  LOI: khong thay $RUNNER"
    RESULTS+=("Apple $PKG: LOI (khong thay run-package-tests.sh)")
    overall_ok=0
    continue
  fi
  if zsh "$RUNNER" "$PKG"; then
    PKG_LOG="$APPLE_DIR/.build-logs/$PKG-test.log"
    COUNT_LINE="$(grep -E 'Test run with [0-9]+ tests? in [0-9]+ suites? (passed|failed)' "$PKG_LOG" 2>/dev/null | tail -1 | sed 's/^[[:space:]]*//')"
    [ -z "$COUNT_LINE" ] && COUNT_LINE="khong doc duoc so test tu $PKG_LOG"
    RESULTS+=("Apple $PKG: XANH — $COUNT_LINE")
  else
    RESULTS+=("Apple $PKG: DO (xem $APPLE_DIR/.build-logs/$PKG-test.log)")
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
  echo "  LOI: khong thay $GRADLEW"
  RESULTS+=("Android: LOI (khong thay gradlew)")
  overall_ok=0
else
  env JAVA_HOME="$JAVA_HOME" ANDROID_HOME="$ANDROID_HOME" "$GRADLEW" -p "$ANDROID_DIR" --continue \
    ":core:protocol:check" ":core:crypto:check" ":core:transport:check" ":feature:connection:testDebugUnitTest" \
    > "$GRADLE_LOG" 2>&1
  GRADLE_EXIT=$?
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
  done < <(find "$ANDROID_DIR/core/protocol" "$ANDROID_DIR/core/crypto" "$ANDROID_DIR/core/transport" "$ANDROID_DIR/feature/connection" \
    -path '*/build/test-results/*' -name 'TEST-*.xml' 2>/dev/null)

  if [ "$xml_files" -gt 0 ]; then
    TEST_SUMMARY="$total_tests test trong $xml_files file XML duoi */build/test-results"
  else
    TEST_SUMMARY="khong tim thay file XML ket qua test duoi */build/test-results, xem $GRADLE_LOG"
  fi
  if [ "$GRADLE_EXIT" -eq 0 ]; then
    RESULTS+=("Android (4 module): XANH — $TEST_SUMMARY")
  else
    RESULTS+=("Android (4 module): DO (exit=$GRADLE_EXIT) — $TEST_SUMMARY")
    overall_ok=0
  fi
fi

echo
echo "== Tom tat =="
for r in "${RESULTS[@]}"; do
  echo "  $r"
done

if [ "$overall_ok" -eq 1 ]; then
  echo "XONG: tat ca buoc xanh."
  exit 0
else
  echo "LOI: co buoc do, xem log tren."
  exit 1
fi
