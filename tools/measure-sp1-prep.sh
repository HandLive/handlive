#!/bin/zsh
# Chuẩn bị ghép đôi SP1: gỡ sạch bản cũ, build và cài bản debug lên S25 và Mac,
# tắt Wi-Fi, ghép qua Bluetooth.
# Chạy NGOÀI sandbox qua nút run của sếp (S25 cắm qua USB):
#   zsh handlive/tools/measure-sp1-prep.sh
#
# Sau script thoát thành công, sếp tắt Wi-Fi cả hai máy, bật Bluetooth, rồi ghép đôi S25 với Mac 1 lần (quét QR hoặc nhập PIN, ~1 phút),
# rồi team tự chạy phiên 1 đo qua measure-sp1-auto.sh.
#
# Gỡ sạch app + dữ liệu Android cũ và bản HandLive.app cũ trên Mac trước khi cài,
# để đảm bảo cài sạch. Không tác động Wi-Fi, không ghi log.
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
HUB_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
WORKSPACE_ROOT="$(cd "$HUB_ROOT/.." && pwd)"
ANDROID_DIR="$WORKSPACE_ROOT/handlive-android"
APPLE_DIR="$WORKSPACE_ROOT/handlive-apple"

APP_ID="com.handlive.android"
MAIN_ACTIVITY="$APP_ID/app.handlive.android.MainActivity"

fail() {
  echo "LỖI: $1" >&2
  exit 1
}

command -v adb >/dev/null || fail "không thấy adb trong PATH"
command -v xcodebuild >/dev/null || fail "không thấy xcodebuild trong PATH"
adb get-state >/dev/null 2>&1 || fail "không thấy thiết bị Android qua adb (cắm S25, bật USB debugging)"

echo "== 1. Gỡ sạch bản Android cũ (app + dữ liệu) =="
if adb shell pm list packages "$APP_ID" 2>/dev/null | grep -q "^package:$APP_ID$"; then
  adb uninstall "$APP_ID" || fail "adb uninstall $APP_ID thất bại"
  echo "Đã gỡ $APP_ID (cả dữ liệu) trên S25"
else
  echo "$APP_ID chưa cài trên S25, bỏ qua gỡ"
fi

echo "== 2. Build APK debug (flavor foss) =="
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

echo "== 3. Cài APK lên S25 =="
adb install "$APK_PATH" || fail "adb install thất bại"

echo "== 4. Cấp quyền Bluetooth =="
adb shell pm grant "$APP_ID" android.permission.BLUETOOTH_ADVERTISE >/dev/null 2>&1 || true
adb shell pm grant "$APP_ID" android.permission.BLUETOOTH_CONNECT >/dev/null 2>&1 || true

echo "== 5. Mở app trên S25 =="
adb shell am start -n "$MAIN_ACTIVITY" || fail "adb shell am start thất bại"

echo
echo "== 6. Gỡ sạch bản Mac cũ =="
pkill -x HandLive >/dev/null 2>&1 || true
echo "Đã dừng HandLive đang chạy (nếu có)"

MAC_APP_SYSTEM="/Applications/HandLive.app"
MAC_APP_USER="$HOME/Applications/HandLive.app"
if [ -d "$MAC_APP_SYSTEM" ]; then
  rm -rf "$MAC_APP_SYSTEM" || fail "không xóa được $MAC_APP_SYSTEM"
  echo "Đã xóa $MAC_APP_SYSTEM"
fi
if [ -d "$MAC_APP_USER" ]; then
  rm -rf "$MAC_APP_USER" || fail "không xóa được $MAC_APP_USER"
  echo "Đã xóa $MAC_APP_USER"
fi

DERIVED_DATA="$APPLE_DIR/.build-logs/sp1-derived-data"
if [ -d "$DERIVED_DATA" ]; then
  rm -rf "$DERIVED_DATA" || fail "không xóa được $DERIVED_DATA"
  echo "Đã xóa DerivedData cũ $DERIVED_DATA"
fi

echo
echo "== 7. Build app macOS (debug) =="
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

MAC_APP_PATH="$(find "$DERIVED_DATA/Build/Products/Debug" -maxdepth 1 -name 'HandLive.app' -print -quit 2>/dev/null)"
[ -n "$MAC_APP_PATH" ] || fail "không tìm thấy HandLive.app dưới $DERIVED_DATA/Build/Products/Debug"
echo "App macOS: $MAC_APP_PATH"

echo "== 8. Ký ad-hoc để không cần provisioning profile =="
codesign --force --deep --sign - "$MAC_APP_PATH" || fail "codesign ad-hoc thất bại"

echo "== 9. Mở app trên Mac =="
open "$MAC_APP_PATH" || fail "mở HandLive.app thất bại (sandbox chặn 'open'; chạy script này ngoài sandbox)"

echo
echo "SẴN SÀNG: tắt Wi-Fi cả hai máy, bật Bluetooth, mở màn ghép đôi trên Mac rồi quét QR (hoặc nhập PIN) trên S25 — ghép qua Bluetooth"
