#!/bin/zsh
# Chạy NGOÀI sandbox qua nút run của sếp (S25 cắm qua USB, Mac này là máy đo), không có người ngồi theo dõi:
#   zsh handlive/tools/measure-sp1-auto.sh --session 1|2|3 [adb_serial]
#
# Làm trọn một phiên của runbook handlive/plans/20260925-implementation/reports/phase-07-sp1-measure.md mà
# không cần thao tác tay: gọi measure-sp1.sh nền để build/mở app + ghi log HLBENCH, chờ link lên Bluetooth,
# tự làm các bước copy/toggle/doze của phiên, rồi dừng ghi log và chạy clip_latency.py/reconnect_time.py.
# Sandbox của agent chặn mọi kết nối adb (xem #3717-#3720), nên toàn bộ khối này phải chạy qua nút run.
#
#   --session 1: phiên đầy đủ (không --log-only) — build + cài lại APK/app macOS từ đầu.
#   --session 2|3: dùng lại APK/app macOS của lần --session 1 gần nhất (thêm --log-only vào measure-sp1.sh).
#
# Chiều S25->Mac tự động hóa bằng broadcast của app "Clipper" (ca.zgrs.clipper, trick quen thuộc để set
# clipboard Android qua adb mà không cần UI — Android chặn ClipboardManager từ background từ Android 10).
# Không có app đó trên S25 thì bước này tự bỏ qua và in rõ, chỉ còn chiều Mac->S25 (pbcopy) như runbook cho phép.
set -uo pipefail
zmodload zsh/datetime

epoch_ms() {
  printf '%.0f' $(( EPOCHREALTIME * 1000 ))
}

SESSION=""
SERIAL=""
while [ $# -gt 0 ]; do
  case "$1" in
    --session)
      shift
      SESSION="${1:-}"
      shift
      ;;
    -*)
      echo "LỖI: không biết tùy chọn: $1" >&2
      exit 2
      ;;
    *)
      SERIAL="$1"
      shift
      ;;
  esac
done

case "$SESSION" in
  1|2|3) ;;
  *)
    echo "Dùng: zsh $0 --session 1|2|3 [adb_serial]" >&2
    exit 2
    ;;
esac

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
HUB_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
WORKSPACE_ROOT="$(cd "$HUB_ROOT/.." && pwd)"
SHARED_DIR="$WORKSPACE_ROOT/handlive-shared"
MEASURE_SH="$HUB_ROOT/tools/measure-sp1.sh"
LOG_DIR="$HUB_ROOT/.build-logs"
mkdir -p "$LOG_DIR"
TS="$(date +%Y%m%d-%H%M%S)"
: "${TMPDIR:=/tmp}"

[ -f "$MEASURE_SH" ] || { echo "LỖI: không thấy $MEASURE_SH" >&2; exit 1; }
command -v adb >/dev/null || { echo "LỖI: không thấy adb trong PATH" >&2; exit 1; }
command -v osascript >/dev/null || { echo "LỖI: không thấy osascript trong PATH" >&2; exit 1; }
command -v pbcopy >/dev/null || { echo "LỖI: không thấy pbcopy trong PATH" >&2; exit 1; }

typeset -a ADB_ARGS
if [ -n "$SERIAL" ]; then
  ADB_ARGS=(-s "$SERIAL")
fi

ANDROID_LOG=""
MAC_LOG=""
MAC_APP_PATH=""
MEASURE_PID=""
LOGGING_STOPPED=0

fail() {
  echo "LỖI: $1" >&2
  if [ -n "$ANDROID_LOG" ] && [ -f "$ANDROID_LOG" ]; then
    echo "--- 20 dòng cuối $ANDROID_LOG ---" >&2
    tail -n 20 "$ANDROID_LOG" >&2
  fi
  if [ -n "$MAC_LOG" ] && [ -f "$MAC_LOG" ]; then
    echo "--- 20 dòng cuối $MAC_LOG ---" >&2
    tail -n 20 "$MAC_LOG" >&2
  fi
  exit 1
}

cleanup() {
  echo
  echo "== Dọn dẹp: dừng ghi log (nếu còn) và khôi phục S25 =="
  if [ -n "$MEASURE_PID" ] && [ "$LOGGING_STOPPED" -eq 0 ]; then
    kill -INT "$MEASURE_PID" 2>/dev/null || true
    wait "$MEASURE_PID" 2>/dev/null || true
    LOGGING_STOPPED=1
  fi
  adb "${ADB_ARGS[@]}" shell dumpsys deviceidle unforce >/dev/null 2>&1 || true
  adb "${ADB_ARGS[@]}" shell dumpsys battery reset >/dev/null 2>&1 || true
  adb "${ADB_ARGS[@]}" shell svc wifi enable >/dev/null 2>&1 || true
  adb "${ADB_ARGS[@]}" shell svc data enable >/dev/null 2>&1 || true
  adb "${ADB_ARGS[@]}" shell input keyevent KEYCODE_WAKEUP >/dev/null 2>&1 || true
}
trap cleanup EXIT

wait_for_connected() {
  local timeout="${1:-120}" waited=0
  while [ "$waited" -lt "$timeout" ]; do
    if grep 'ev=state' "$MAC_LOG" 2>/dev/null | tail -n 1 | grep -q 'to=Connected channel=bluetooth'; then
      return 0
    fi
    sleep 2
    waited=$((waited + 2))
  done
  return 1
}

# Trick "Clipper" (ca.zgrs.clipper): `am broadcast -a clipper.set -e text VALUE` set được clipboard Android từ
# adb mà không cần UI. `am broadcast` luôn trả "result=0" dù có receiver nhận hay không (không có cách phân
# biệt qua mã kết quả), nên kiểm trước bằng pm list packages (gọi 1 lần trong session 1, biến CLIPPER_INSTALLED
# dưới đây): không cài app này thì bỏ qua ngay, có cài thì gửi broadcast và coi là thành công (không có cách
# nào xác nhận sau hơn từ phía adb).
CLIPPER_INSTALLED=0

android_copy_text() {
  local text="$1"
  [ "$CLIPPER_INSTALLED" -eq 1 ] || return 1
  adb "${ADB_ARGS[@]}" shell am broadcast -a clipper.set -e text "$text" >/dev/null 2>&1
}

# Tạo một ảnh ~5 MB (BMP ghi tay bằng python3 stdlib rồi đổi sang PNG bằng sips, không cần PIL) để đưa lên
# pasteboard Mac bằng osascript — không dùng nội dung chép từ đâu khác vì không có file ảnh sẵn có đúng kích cỡ.
make_bench_image() {
  local out_bmp="$1" out_png="$2"
  python3 - "$out_bmp" <<'PYEOF'
import os
import struct
import sys

path = sys.argv[1]
width, height = 1700, 1024  # 24-bit BMP, hàng không cần padding (1700*3=5100 chia hết cho 4) -> khoảng 5.2 MB.
row_bytes = width * 3
pixel_data_size = row_bytes * height
file_size = 54 + pixel_data_size
with open(path, "wb") as f:
    f.write(b"BM")
    f.write(struct.pack("<IHHI", file_size, 0, 0, 54))
    f.write(struct.pack("<IiiHHIIiiII", 40, width, height, 1, 24, 0, pixel_data_size, 0, 0, 0, 0))
    row = os.urandom(row_bytes)
    for _ in range(height):
        f.write(row)
PYEOF
  sips -s format png "$out_bmp" --out "$out_png" >/dev/null
}

set_mac_image_clipboard() {
  local png_path="$1"
  osascript -e "set the clipboard to (read (POSIX file \"$png_path\") as «class PNGf»)"
}

echo "== 1. adb devices =="
adb devices

echo "== 2. Tắt Wi-Fi + dữ liệu di động trên S25 (Mac vẫn bật Wi-Fi) =="
adb "${ADB_ARGS[@]}" shell svc wifi disable || fail "svc wifi disable thất bại"
adb "${ADB_ARGS[@]}" shell svc data disable || fail "svc data disable thất bại"

typeset -a MEASURE_ARGS
if [ "$SESSION" != "1" ]; then
  MEASURE_ARGS+=(--log-only)
fi
if [ -n "$SERIAL" ]; then
  MEASURE_ARGS+=("$SERIAL")
fi

MEASURE_OUT="$LOG_DIR/sp1-auto-session${SESSION}-$TS-measure.out"
echo "== 3. Chạy measure-sp1.sh nền (session $SESSION, args: ${MEASURE_ARGS[*]:-<không>}) =="
zsh "$MEASURE_SH" "${MEASURE_ARGS[@]}" > "$MEASURE_OUT" 2>&1 &
MEASURE_PID=$!
echo "measure-sp1.sh PID=$MEASURE_PID, output đầy đủ tại: $MEASURE_OUT"

echo "== 4. Đợi measure-sp1.sh in đường dẫn log (tối đa 600s, có build app) =="
waited=0
while [ "$waited" -lt 600 ]; do
  if ! kill -0 "$MEASURE_PID" 2>/dev/null; then
    fail "measure-sp1.sh đã thoát trước khi in đường dẫn log, xem $MEASURE_OUT"
  fi
  ANDROID_LOG="$(grep -m1 '^Android: ' "$MEASURE_OUT" 2>/dev/null | sed 's/^Android: //')"
  MAC_LOG="$(grep -m1 '^Mac:' "$MEASURE_OUT" 2>/dev/null | sed -E 's/^Mac:[[:space:]]*//')"
  MAC_APP_PATH="$(grep -m1 '^App macOS: ' "$MEASURE_OUT" 2>/dev/null | sed 's/^App macOS: //')"
  if [ -n "$ANDROID_LOG" ] && [ -n "$MAC_LOG" ]; then
    break
  fi
  sleep 2
  waited=$((waited + 2))
done
[ -n "$ANDROID_LOG" ] && [ -n "$MAC_LOG" ] || fail "quá 600s không thấy measure-sp1.sh in đường dẫn log, xem $MEASURE_OUT"
echo "Android log: $ANDROID_LOG"
echo "Mac log:     $MAC_LOG"
[ -n "$MAC_APP_PATH" ] && echo "App macOS:   $MAC_APP_PATH"

echo "== 5. Chờ link lên Bluetooth (tối đa 120s) =="
wait_for_connected 120 || fail "quá 120s không thấy 'to=Connected channel=bluetooth' trong $MAC_LOG"
echo "Đã thấy Bluetooth Connected."

case "$SESSION" in
  1)
    echo "== 6. AC1 idle: 30 lần copy text, đối chiều, cách 3-4s =="
    ANDROID_COPY_OK=0
    if adb "${ADB_ARGS[@]}" shell pm list packages ca.zgrs.clipper 2>/dev/null | grep -q 'package:ca\.zgrs\.clipper'; then
      CLIPPER_INSTALLED=1
      ANDROID_COPY_OK=1
    else
      echo "CẢNH BÁO: không thấy app Clipper (ca.zgrs.clipper) trên S25 — không có cách set clipboard Android" \
           "từ adb mà không có UI, bỏ qua chiều S25->Mac, chỉ copy chiều Mac->S25 cả 30 lần." >&2
    fi
    for (( i = 1; i <= 30; i++ )); do
      if [ "$ANDROID_COPY_OK" -eq 1 ] && (( i % 2 == 0 )); then
        if ! android_copy_text "sp1 auto s25->mac $i $(epoch_ms)"; then
          echo "CẢNH BÁO: lần $i copy từ S25 thất bại, bỏ qua lần này" >&2
        fi
      else
        print -n -- "sp1 auto mac->s25 $i $(epoch_ms)" | pbcopy
      fi
      sleep $(( 3 + (RANDOM % 2) ))
    done

    echo "== 7. 5 vòng tắt/bật Bluetooth trên S25, mỗi vòng chờ Connected lại (tối đa 30s) =="
    for (( round = 1; round <= 5; round++ )); do
      echo "-- vòng $round/5: tắt bluetooth_manager --"
      adb "${ADB_ARGS[@]}" shell cmd bluetooth_manager disable || true
      sleep 2
      echo "-- vòng $round/5: bật lại bluetooth_manager --"
      adb "${ADB_ARGS[@]}" shell cmd bluetooth_manager enable || true
      if ! wait_for_connected 30; then
        echo "CẢNH BÁO: vòng $round không thấy Connected lại trong 30s" >&2
      fi
    done

    echo "== 8. Scan response: khóa màn hình S25, chờ 60s, Cmd-Q + mở lại app Mac =="
    BT_ACCEPT_BEFORE="$(grep -c 'ev=bt_accept' "$ANDROID_LOG" 2>/dev/null || true)"
    : "${BT_ACCEPT_BEFORE:=0}"
    adb "${ADB_ARGS[@]}" shell input keyevent KEYCODE_SLEEP || true
    sleep 60
    osascript -e 'quit app "HandLive"' || echo "CẢNH BÁO: osascript quit app HandLive thất bại" >&2
    if [ -n "$MAC_APP_PATH" ]; then
      open "$MAC_APP_PATH" || echo "CẢNH BÁO: mở lại app Mac thất bại" >&2
    else
      echo "CẢNH BÁO: không đọc được đường dẫn app macOS từ $MEASURE_OUT, bỏ qua mở lại app" >&2
    fi
    sleep 5
    adb "${ADB_ARGS[@]}" shell input keyevent KEYCODE_WAKEUP || true
    wait_for_connected 30 || echo "CẢNH BÁO: sau bước scan-response không thấy Connected lại trong 30s" >&2
    BT_ACCEPT_AFTER="$(grep -c 'ev=bt_accept' "$ANDROID_LOG" 2>/dev/null || true)"
    : "${BT_ACCEPT_AFTER:=0}"
    echo "bt_accept trước=$BT_ACCEPT_BEFORE sau=$BT_ACCEPT_AFTER"
    if [ "$BT_ACCEPT_AFTER" -le "$BT_ACCEPT_BEFORE" ]; then
      echo "CẢNH BÁO: bt_accept không tăng sau bước scan-response (xem 00-common-specs.md 0.4.5)" >&2
    fi
    ;;

  2)
    echo "== 6. AC1 dưới tải: ảnh ~5MB lên pasteboard Mac, xen 10 lần copy text =="
    IMG_BMP="$TMPDIR/handlive-sp1-bench-$TS.bmp"
    IMG_PNG="$TMPDIR/handlive-sp1-bench-$TS.png"
    make_bench_image "$IMG_BMP" "$IMG_PNG" || fail "tạo ảnh bench thất bại"
    rm -f "$IMG_BMP"
    for (( i = 1; i <= 10; i++ )); do
      if (( i == 1 || i % 3 == 0 )); then
        set_mac_image_clipboard "$IMG_PNG" || echo "CẢNH BÁO: set ảnh lên pasteboard Mac thất bại (lần $i)" >&2
        sleep 1
      fi
      print -n -- "sp1 auto load mac->s25 $i $(epoch_ms)" | pbcopy
      sleep $(( 3 + (RANDOM % 2) ))
    done
    rm -f "$IMG_PNG"
    ;;

  3)
    echo "== 6. Doze: ép S25 vào Doze =="
    adb "${ADB_ARGS[@]}" shell dumpsys battery unplug || true
    adb "${ADB_ARGS[@]}" shell input keyevent KEYCODE_SLEEP || true
    adb "${ADB_ARGS[@]}" shell dumpsys deviceidle force-idle || true

    echo "== 7. 30 lần copy text Mac->S25, cách 30s, màn hình S25 không đụng vào =="
    for (( i = 1; i <= 30; i++ )); do
      print -n -- "sp1 auto doze mac->s25 $i $(epoch_ms)" | pbcopy
      sleep 30
    done

    echo "== 8. Khôi phục S25 sau Doze =="
    adb "${ADB_ARGS[@]}" shell dumpsys deviceidle unforce || true
    adb "${ADB_ARGS[@]}" shell dumpsys battery reset || true
    adb "${ADB_ARGS[@]}" shell input keyevent KEYCODE_WAKEUP || true
    ;;
esac

echo "== 9. Dừng ghi log =="
kill -INT "$MEASURE_PID" 2>/dev/null || true
wait "$MEASURE_PID" 2>/dev/null || true
LOGGING_STOPPED=1

echo "Android log: $ANDROID_LOG"
echo "Mac log:     $MAC_LOG"

command -v python3 >/dev/null || fail "không thấy python3 trong PATH"

echo "== 10. clip_latency.py (AC1) =="
python3 "$SHARED_DIR/tools/bench/clip_latency.py" "$ANDROID_LOG" "$MAC_LOG" --json \
  || echo "CẢNH BÁO: clip_latency.py trả mã lỗi khác 0" >&2

echo "== 11. reconnect_time.py (AC2) =="
python3 "$SHARED_DIR/tools/bench/reconnect_time.py" "$MAC_LOG" "$ANDROID_LOG" --json \
  || echo "CẢNH BÁO: reconnect_time.py trả mã lỗi khác 0" >&2

echo "Xong session $SESSION."
