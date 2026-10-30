#!/bin/zsh
# Chay NGOAI sandbox, voi S25 cam qua USB (adb) va may Mac nay la may do:
#   zsh handlive/tools/measure-sp1.sh [--log-only] [adb_serial]
#
# Chuan bi SP1 (kenh dieu khien Bluetooth) de do AC1/AC2 tren may that, theo
# handlive/plans/20260925-implementation/reports/phase-07-sp1-measure.md:
#   1. Build APK debug (:app:assembleDebug), cai len S25 qua adb, cap quyen
#      BLUETOOTH_ADVERTISE/BLUETOOTH_CONNECT (chua co man xin quyen), mo app.
#   2. Build app macOS (xcodegen generate + xcodebuild, scheme HandLive, cau hinh Debug) va mo app.
#   3. Goi logcat (Android) va `log stream` (Mac) loc dong HLBENCH vao
#      handlive/.build-logs/sp1-<timestamp>-android.log va sp1-<timestamp>-mac.log.
#
# --log-only: bo qua build+cai APK va bo qua xcodegen+xcodebuild; dung lai APK/app macOS cua lan
# chay full gan nhat (danh cho phien 2/3 cua runbook, do lai nhanh khong phai build lai). Van cap
# quyen Bluetooth (idempotent) va mo lai app o hai may. That bai ngay voi thong bao ro neu chua
# chay full it nhat mot lan (chua co .app macOS de mo).
#
# Dung tay: lam cac buoc do trong runbook (phase-07-sp1-measure.md), roi Ctrl-C de dung ghi log.
# Khong dung mang ngoai; chi dung JAVA_HOME/ANDROID_HOME nhu verify-phase7.sh.
set -uo pipefail

LOG_ONLY=0
SERIAL=""
for arg in "$@"; do
  case "$arg" in
    --log-only) LOG_ONLY=1 ;;
    -*) echo "LOI: khong biet tuy chon: $arg" >&2; exit 2 ;;
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
  echo "LOI: $1" >&2
  exit 1
}

command -v adb >/dev/null || fail "khong thay adb (Android platform-tools) trong PATH"
command -v xcodebuild >/dev/null || fail "khong thay xcodebuild trong PATH"

adb "${ADB_ARGS[@]}" get-state >/dev/null 2>&1 || fail "khong thay thiet bi Android qua adb (cam S25, bat USB debugging)"

if [ "$LOG_ONLY" -eq 0 ]; then
  echo "== 1. Build + cai APK debug len S25 =="
  : "${JAVA_HOME:=/opt/homebrew/opt/openjdk@21/libexec/openjdk.jdk/Contents/Home}"
  : "${ANDROID_HOME:=/opt/homebrew/share/android-commandlinetools}"
  export JAVA_HOME ANDROID_HOME

  GRADLEW="$ANDROID_DIR/gradlew"
  [ -f "$GRADLEW" ] || fail "khong thay $GRADLEW"

  env JAVA_HOME="$JAVA_HOME" ANDROID_HOME="$ANDROID_HOME" "$GRADLEW" -p "$ANDROID_DIR" ":app:assembleFossDebug" \
    || fail "gradlew :app:assembleFossDebug that bai"

  APK_PATH="$(find "$ANDROID_DIR/app/build/outputs/apk/foss/debug" -name '*.apk' -print -quit 2>/dev/null)"
  [ -n "$APK_PATH" ] || fail "khong tim thay APK debug duoi $ANDROID_DIR/app/build/outputs/apk/foss/debug"
  echo "APK: $APK_PATH"

  adb "${ADB_ARGS[@]}" install -r "$APK_PATH" || fail "adb install that bai"
else
  echo "== 1. --log-only: bo qua build + cai APK (dung lai ban da cai tu lan chay full) =="
fi

echo "== 2. Cap quyen Bluetooth (chua co man xin quyen trong app) =="
adb "${ADB_ARGS[@]}" shell pm grant "$APP_ID" android.permission.BLUETOOTH_ADVERTISE \
  || echo "  CANH BAO: pm grant BLUETOOTH_ADVERTISE that bai (co the da cap san)"
adb "${ADB_ARGS[@]}" shell pm grant "$APP_ID" android.permission.BLUETOOTH_CONNECT \
  || echo "  CANH BAO: pm grant BLUETOOTH_CONNECT that bai (co the da cap san)"

echo "== 3. Mo app tren S25 =="
adb "${ADB_ARGS[@]}" shell am start -n "$MAIN_ACTIVITY" || fail "adb shell am start that bai"

DERIVED_DATA="$APPLE_DIR/.build-logs/sp1-derived-data"

echo
if [ "$LOG_ONLY" -eq 0 ]; then
  echo "== 4. Build app macOS (debug) =="
  command -v xcodegen >/dev/null || fail "khong thay xcodegen trong PATH (brew install xcodegen)"
  (cd "$APPLE_DIR" && xcodegen generate) || fail "xcodegen generate that bai"

  mkdir -p "$APPLE_DIR/.build-logs"
  xcodebuild build \
    -workspace "$APPLE_DIR/HandLive.xcworkspace" \
    -scheme "HandLive" \
    -configuration Debug \
    -destination "platform=macOS" \
    -derivedDataPath "$DERIVED_DATA" \
    CODE_SIGNING_ALLOWED=NO \
    || fail "xcodebuild build HandLive (macOS) that bai"
else
  echo "== 4. --log-only: bo qua xcodegen + xcodebuild (dung lai ban da build tu lan chay full) =="
fi

MAC_APP_PATH="$(find "$DERIVED_DATA/Build/Products/Debug" -maxdepth 1 -name 'HandLive.app' -print -quit 2>/dev/null)"
if [ -z "$MAC_APP_PATH" ]; then
  if [ "$LOG_ONLY" -eq 1 ]; then
    fail "khong thay HandLive.app duoi $DERIVED_DATA/Build/Products/Debug — chay mot lan khong co --log-only truoc"
  fi
  fail "khong tim thay HandLive.app duoi $DERIVED_DATA/Build/Products/Debug"
fi
echo "App macOS: $MAC_APP_PATH"

echo "Ky ad-hoc de khong can provisioning profile"
codesign --force --deep --sign - "$MAC_APP_PATH" || fail "codesign ad-hoc that bai"

echo "== 5. Mo app tren Mac =="
open "$MAC_APP_PATH" || fail "mo HandLive.app that bai (sandbox chan 'open'; chay script nay ngoai sandbox)"

echo
echo "== 6. Ghi log HLBENCH (Ctrl-C de dung) =="
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
  echo "Da dung ghi log."
  echo "  Android: $(grep -c 'HLBENCH/1 ' "$ANDROID_LOG" 2>/dev/null || echo 0) dong, tai $ANDROID_LOG"
  echo "  Mac:     $(grep -c 'HLBENCH/1 ' "$MAC_LOG" 2>/dev/null || echo 0) dong, tai $MAC_LOG"
  echo "Doc ket qua theo handlive/plans/20260925-implementation/reports/phase-07-sp1-measure.md"
}
trap stop INT TERM

echo "Lam cac buoc do trong runbook (phase-07-sp1-measure.md), roi an Ctrl-C de dung ghi log."
wait
