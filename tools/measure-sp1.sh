#!/bin/zsh
# Chạy NGOÀI sandbox, với S25 cắm qua USB (adb) và máy Mac này là máy đo:
#   zsh handlive/tools/measure-sp1.sh [--log-only] [adb_serial]
#
# Chuẩn bị SP1 (kênh điều khiển Bluetooth) để đo AC1/AC2 trên máy thật, theo
# handlive/plans/20260925-implementation/reports/phase-07-sp1-measure.md:
#   1. Build APK debug (:app:assembleDebug), cài lên S25 qua adb, cấp quyền
#      BLUETOOTH_ADVERTISE/BLUETOOTH_CONNECT (chưa có màn xin quyền), mở app.
#   2. Build app macOS (xcodegen generate + xcodebuild, scheme HandLive, cấu hình Debug) và mở app.
#   3. Gọi logcat (Android) và `log stream` (Mac) lọc dòng HLBENCH vào
#      handlive/.build-logs/sp1-<timestamp>-android.log và sp1-<timestamp>-mac.log.
#
# --log-only: bỏ qua build+cài APK và bỏ qua xcodegen+xcodebuild; dùng lại APK/app macOS của lần
# chạy full gần nhất (dành cho phiên 2/3 của runbook, đo lại nhanh không phải build lại). Vẫn cấp
# quyền Bluetooth (idempotent) và mở lại app ở hai máy. Thất bại ngay với thông báo rõ nếu chưa
# chạy full ít nhất một lần (chưa có .app macOS để mở).
#
# Dùng tay: làm các bước đo trong runbook (phase-07-sp1-measure.md), rồi Ctrl-C để dừng ghi log.
# Không dùng mạng ngoài; chỉ dùng JAVA_HOME/ANDROID_HOME như verify-phase7.sh.
set -uo pipefail

LOG_ONLY=0
SERIAL=""
for arg in "$@"; do
  case "$arg" in
    --log-only) LOG_ONLY=1 ;;
    -*) echo "LỖI: không biết tùy chọn: $arg" >&2; exit 2 ;;
    *) SERIAL="$arg" ;;
  esac
done

HUB_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
WORKSPACE_ROOT="$(cd "$HUB_ROOT/.." && pwd)"
APPLE_DIR="$WORKSPACE_ROOT/handlive-apple"
ANDROID_DIR="$WORKSPACE_ROOT/handlive-android"

LOG_DIR="$HUB_ROOT/.build-logs"
mkdir -p "$LOG_DIR"
TS="$(date +%Y%m%d-%H%M%S)"
ANDROID_LOG="$LOG_DIR/sp1-$TS-android.log"
MAC_LOG="$LOG_DIR/sp1-$TS-mac.log"

APP_ID="com.handlive.android"
MAIN_ACTIVITY="$APP_ID/app.handlive.android.MainActivity"

typeset -a ADB_ARGS
if [ -n "$SERIAL" ]; then
  ADB_ARGS=(-s "$SERIAL")
fi

fail() {
  echo "LỖI: $1" >&2
  exit 1
}

command -v adb >/dev/null || fail "không thấy adb (Android platform-tools) trong PATH"
command -v xcodebuild >/dev/null || fail "không thấy xcodebuild trong PATH"

adb "${ADB_ARGS[@]}" get-state >/dev/null 2>&1 || fail "không thấy thiết bị Android qua adb (cắm S25, bật USB debugging)"

if [ "$LOG_ONLY" -eq 0 ]; then
  echo "== 1. Build + cài APK debug lên S25 =="
  : "${JAVA_HOME:=/opt/homebrew/opt/openjdk@21/libexec/openjdk.jdk/Contents/Home}"
  : "${ANDROID_HOME:=/opt/homebrew/share/android-commandlinetools}"
  export JAVA_HOME ANDROID_HOME

  GRADLEW="$ANDROID_DIR/gradlew"
  [ -f "$GRADLEW" ] || fail "không thấy $GRADLEW"

  env JAVA_HOME="$JAVA_HOME" ANDROID_HOME="$ANDROID_HOME" "$GRADLEW" -p "$ANDROID_DIR" ":app:assembleFossDebug" \
    || fail "gradlew :app:assembleFossDebug thất bại"

  APK_PATH="$(find "$ANDROID_DIR/app/build/outputs/apk/foss/debug" -name '*.apk' -print -quit 2>/dev/null)"
  [ -n "$APK_PATH" ] || fail "không tìm thấy APK debug dưới $ANDROID_DIR/app/build/outputs/apk/foss/debug"
  echo "APK: $APK_PATH"

  adb "${ADB_ARGS[@]}" install -r "$APK_PATH" || fail "adb install thất bại"
else
  echo "== 1. --log-only: bỏ qua build + cài APK (dùng lại bản đã cài từ lần chạy full) =="
fi

echo "== 2. Cấp quyền Bluetooth (chưa có màn xin quyền trong app) =="
adb "${ADB_ARGS[@]}" shell pm grant "$APP_ID" android.permission.BLUETOOTH_ADVERTISE \
  || echo "  CẢNH BÁO: pm grant BLUETOOTH_ADVERTISE thất bại (có thể đã cấp sẵn)"
adb "${ADB_ARGS[@]}" shell pm grant "$APP_ID" android.permission.BLUETOOTH_CONNECT \
  || echo "  CẢNH BÁO: pm grant BLUETOOTH_CONNECT thất bại (có thể đã cấp sẵn)"

echo "== 3. Mở app trên S25 =="
adb "${ADB_ARGS[@]}" shell am start -n "$MAIN_ACTIVITY" || fail "adb shell am start thất bại"

DERIVED_DATA="$APPLE_DIR/.build-logs/sp1-derived-data"

echo
if [ "$LOG_ONLY" -eq 0 ]; then
  echo "== 4. Build app macOS (debug) =="
  command -v xcodegen >/dev/null || fail "không thấy xcodegen trong PATH (brew install xcodegen)"
  (cd "$APPLE_DIR" && xcodegen generate) || fail "xcodegen generate thất bại"

  mkdir -p "$APPLE_DIR/.build-logs"
  xcodebuild build \
    -workspace "$APPLE_DIR/HandLive.xcworkspace" \
    -scheme "HandLive" \
    -configuration Debug \
    -destination "platform=macOS" \
    -derivedDataPath "$DERIVED_DATA" \
    CODE_SIGNING_ALLOWED=NO \
    || fail "xcodebuild build HandLive (macOS) thất bại"
else
  echo "== 4. --log-only: bỏ qua xcodegen + xcodebuild (dùng lại bản đã build từ lần chạy full) =="
fi

MAC_APP_PATH="$(find "$DERIVED_DATA/Build/Products/Debug" -maxdepth 1 -name 'HandLive.app' -print -quit 2>/dev/null)"
if [ -z "$MAC_APP_PATH" ]; then
  if [ "$LOG_ONLY" -eq 1 ]; then
    fail "không thấy HandLive.app dưới $DERIVED_DATA/Build/Products/Debug — chạy một lần không có --log-only trước"
  fi
  fail "không tìm thấy HandLive.app dưới $DERIVED_DATA/Build/Products/Debug"
fi
echo "App macOS: $MAC_APP_PATH"

echo "Ký ad-hoc để không cần provisioning profile"
codesign --force --deep --sign - "$MAC_APP_PATH" || fail "codesign ad-hoc thất bại"

echo "== 5. Mở app trên Mac =="
open "$MAC_APP_PATH" || fail "mở HandLive.app thất bại (sandbox chặn 'open'; chạy script này ngoài sandbox)"

echo
echo "== 6. Ghi log HLBENCH (Ctrl-C để dừng) =="
echo "Android: $ANDROID_LOG"
echo "Mac:     $MAC_LOG"

adb "${ADB_ARGS[@]}" logcat -c
adb "${ADB_ARGS[@]}" logcat -v raw -s HLBENCH:I > "$ANDROID_LOG" &
android_pid=$!
log stream --style compact --level info \
  --predicate 'subsystem == "app.handlive.mac" AND category == "bench"' > "$MAC_LOG" &
mac_pid=$!

stop() {
  kill "$android_pid" "$mac_pid" 2>/dev/null || true
  wait 2>/dev/null || true
  echo
  echo "Đã dừng ghi log."
  echo "  Android: $(grep -c 'HLBENCH/1 ' "$ANDROID_LOG" 2>/dev/null || echo 0) dòng, tại $ANDROID_LOG"
  echo "  Mac:     $(grep -c 'HLBENCH/1 ' "$MAC_LOG" 2>/dev/null || echo 0) dòng, tại $MAC_LOG"
  echo "Đọc kết quả theo handlive/plans/20260925-implementation/reports/phase-07-sp1-measure.md"
}
trap stop INT TERM

echo "Làm các bước đo trong runbook (phase-07-sp1-measure.md), rồi ấn Ctrl-C để dừng ghi log."
wait
