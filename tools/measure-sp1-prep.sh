#!/bin/zsh
# Chuan bi ghep doi SP1: go sach ban cu, build va cai ban debug len S25 va Mac,
# giu Wi-Fi bat de ghep qua LAN (luong A).
# Chay NGOAI sandbox qua nut run cua sep (S25 cam qua USB):
#   zsh handlive/tools/measure-sp1-prep.sh
#
# Sau script thoat thanh cong, sxep ghep doi S25 voi Mac qua Wi-Fi 1 lan (quét QR hoac nhap PIN, ~1 phut),
# roi team tu chay phien 1 do qua measure-sp1-auto.sh.
#
# Go sach app + du lieu Android cu va ban HandLive.app cu tren Mac truoc khi cai,
# de dam bao cai sach. Khong tac dong Wi-Fi, khong ghi log, khong la hang xin quyen (pm grant).
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
HUB_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
WORKSPACE_ROOT="$(cd "$HUB_ROOT/.." && pwd)"
ANDROID_DIR="$WORKSPACE_ROOT/handlive-android"
APPLE_DIR="$WORKSPACE_ROOT/handlive-apple"

APP_ID="com.handlive.android"
MAIN_ACTIVITY="$APP_ID/app.handlive.android.MainActivity"

fail() {
  echo "LOI: $1" >&2
  exit 1
}

command -v adb >/dev/null || fail "khong thay adb trong PATH"
command -v xcodebuild >/dev/null || fail "khong thay xcodebuild trong PATH"
adb get-state >/dev/null 2>&1 || fail "khong thay thiet bi Android qua adb (cam S25, bat USB debugging)"

echo "== 1. Go sach ban Android cu (app + du lieu) =="
if adb shell pm list packages "$APP_ID" 2>/dev/null | grep -q "^package:$APP_ID$"; then
  adb uninstall "$APP_ID" || fail "adb uninstall $APP_ID that bai"
  echo "Da go $APP_ID (ca du lieu) tren S25"
else
  echo "$APP_ID chua cai tren S25, bo qua go"
fi

echo "== 2. Build APK debug (flavor foss) =="
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

echo "== 3. Cai APK len S25 =="
adb install "$APK_PATH" || fail "adb install that bai"

echo "== 4. Cap quyen Bluetooth =="
adb shell pm grant "$APP_ID" android.permission.BLUETOOTH_ADVERTISE >/dev/null 2>&1 || true
adb shell pm grant "$APP_ID" android.permission.BLUETOOTH_CONNECT >/dev/null 2>&1 || true

echo "== 5. Mo app tren S25 =="
adb shell am start -n "$MAIN_ACTIVITY" || fail "adb shell am start that bai"

echo
echo "== 6. Go sach ban Mac cu =="
pkill -x HandLive >/dev/null 2>&1 || true
echo "Da dung HandLive dang chay (neu co)"

MAC_APP_SYSTEM="/Applications/HandLive.app"
MAC_APP_USER="$HOME/Applications/HandLive.app"
if [ -d "$MAC_APP_SYSTEM" ]; then
  rm -rf "$MAC_APP_SYSTEM" || fail "khong xoa duoc $MAC_APP_SYSTEM"
  echo "Da xoa $MAC_APP_SYSTEM"
fi
if [ -d "$MAC_APP_USER" ]; then
  rm -rf "$MAC_APP_USER" || fail "khong xoa duoc $MAC_APP_USER"
  echo "Da xoa $MAC_APP_USER"
fi

DERIVED_DATA="$APPLE_DIR/.build-logs/sp1-derived-data"
if [ -d "$DERIVED_DATA" ]; then
  rm -rf "$DERIVED_DATA" || fail "khong xoa duoc $DERIVED_DATA"
  echo "Da xoa DerivedData cu $DERIVED_DATA"
fi

echo
echo "== 7. Build app macOS (debug) =="
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

MAC_APP_PATH="$(find "$DERIVED_DATA/Build/Products/Debug" -maxdepth 1 -name 'HandLive.app' -print -quit 2>/dev/null)"
[ -n "$MAC_APP_PATH" ] || fail "khong tim thay HandLive.app duoi $DERIVED_DATA/Build/Products/Debug"
echo "App macOS: $MAC_APP_PATH"

echo "== 8. Ky ad-hoc de khong can provisioning profile =="
codesign --force --deep --sign - "$MAC_APP_PATH" || fail "codesign ad-hoc that bai"

echo "== 9. Mo app tren Mac =="
open "$MAC_APP_PATH" || fail "mo HandLive.app that bai (sandbox chan 'open'; chay script nay ngoai sandbox)"

echo
echo "SAN SANG: ghep doi S25 voi Mac qua Wi-Fi (luong A) — quét QR hoac nhap PIN tren S25"
