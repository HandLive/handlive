#!/bin/zsh
# Chay NGOAI sandbox qua nut run cua sep (S25 cam qua USB, Mac nay la may do), khong co nguoi ngoi theo doi:
#   zsh handlive/tools/measure-sp1-auto.sh --session 1|2|3 [adb_serial]
#
# Lam tron mot phien cua runbook handlive/plans/20260925-implementation/reports/phase-07-sp1-measure.md ma
# khong can thao tac tay: goi measure-sp1.sh nen de build/mo app + ghi log HLBENCH, cho link len Bluetooth,
# tu lam cac buoc copy/toggle/doze cua phien, roi dung ghi log va chay clip_latency.py/reconnect_time.py.
# Sandbox cua agent chan moi ket noi adb (xem #3717-#3720), nen toan bo khoi nay phai chay qua nut run.
#
#   --session 1: phien day du (khong --log-only) — build + cai lai APK/app macOS tu dau.
#   --session 2|3: dung lai APK/app macOS cua lan --session 1 gan nhat (them --log-only vao measure-sp1.sh).
#
# Chieu S25->Mac tu dong hoa bang broadcast cua app "Clipper" (ca.zgrs.clipper, trick quen thuoc de set
# clipboard Android qua adb ma khong can UI — Android chan ClipboardManager tu background tu Android 10).
# Khong co app do tren S25 thi buoc nay tu bo qua va in ro, chi con chieu Mac->S25 (pbcopy) nhu runbook cho phep.
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
      echo "LOI: khong biet tuy chon: $1" >&2
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
    echo "Dung: zsh $0 --session 1|2|3 [adb_serial]" >&2
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

[ -f "$MEASURE_SH" ] || { echo "LOI: khong thay $MEASURE_SH" >&2; exit 1; }
command -v adb >/dev/null || { echo "LOI: khong thay adb trong PATH" >&2; exit 1; }
command -v osascript >/dev/null || { echo "LOI: khong thay osascript trong PATH" >&2; exit 1; }
command -v pbcopy >/dev/null || { echo "LOI: khong thay pbcopy trong PATH" >&2; exit 1; }

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
  echo "LOI: $1" >&2
  if [ -n "$ANDROID_LOG" ] && [ -f "$ANDROID_LOG" ]; then
    echo "--- 20 dong cuoi $ANDROID_LOG ---" >&2
    tail -n 20 "$ANDROID_LOG" >&2
  fi
  if [ -n "$MAC_LOG" ] && [ -f "$MAC_LOG" ]; then
    echo "--- 20 dong cuoi $MAC_LOG ---" >&2
    tail -n 20 "$MAC_LOG" >&2
  fi
  exit 1
}

cleanup() {
  echo
  echo "== Don dep: dung ghi log (neu con) va khoi phuc S25 =="
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

# Trick "Clipper" (ca.zgrs.clipper): `am broadcast -a clipper.set -e text VALUE` set duoc clipboard Android tu
# adb ma khong can UI. `am broadcast` luon tra "result=0" du co receiver nhan hay khong (khong co cach phan
# biet qua ma ket qua), nen kiem truoc bang pm list packages (goi 1 lan trong session 1, bien CLIPPER_INSTALLED
# duoi day): khong cai app nay thi bo qua ngay, co cai thi gui broadcast va coi la thanh cong (khong co cach
# nao xac nhan sau hon tu phia adb).
CLIPPER_INSTALLED=0

android_copy_text() {
  local text="$1"
  [ "$CLIPPER_INSTALLED" -eq 1 ] || return 1
  adb "${ADB_ARGS[@]}" shell am broadcast -a clipper.set -e text "$text" >/dev/null 2>&1
}

# Tao mot anh ~5 MB (BMP ghi tay bang python3 stdlib roi doi sang PNG bang sips, khong can PIL) de dua len
# pasteboard Mac bang osascript — khong dung noi dung chep tu dau khac vi khong co file anh san co dung kich co.
make_bench_image() {
  local out_bmp="$1" out_png="$2"
  python3 - "$out_bmp" <<'PYEOF'
import os
import struct
import sys

path = sys.argv[1]
width, height = 1700, 1024  # 24-bit BMP, hang khong can padding (1700*3=5100 chia het cho 4) -> khoang 5.2 MB.
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

echo "== 2. Tat Wi-Fi + du lieu di dong tren S25 (Mac van bat Wi-Fi) =="
adb "${ADB_ARGS[@]}" shell svc wifi disable || fail "svc wifi disable that bai"
adb "${ADB_ARGS[@]}" shell svc data disable || fail "svc data disable that bai"

typeset -a MEASURE_ARGS
if [ "$SESSION" != "1" ]; then
  MEASURE_ARGS+=(--log-only)
fi
if [ -n "$SERIAL" ]; then
  MEASURE_ARGS+=("$SERIAL")
fi

MEASURE_OUT="$LOG_DIR/sp1-auto-session${SESSION}-$TS-measure.out"
echo "== 3. Chay measure-sp1.sh nen (session $SESSION, args: ${MEASURE_ARGS[*]:-<khong>}) =="
zsh "$MEASURE_SH" "${MEASURE_ARGS[@]}" > "$MEASURE_OUT" 2>&1 &
MEASURE_PID=$!
echo "measure-sp1.sh PID=$MEASURE_PID, output day du tai: $MEASURE_OUT"

echo "== 4. Doi measure-sp1.sh in duong dan log (toi da 600s, co build app) =="
waited=0
while [ "$waited" -lt 600 ]; do
  if ! kill -0 "$MEASURE_PID" 2>/dev/null; then
    fail "measure-sp1.sh da thoat truoc khi in duong dan log, xem $MEASURE_OUT"
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
[ -n "$ANDROID_LOG" ] && [ -n "$MAC_LOG" ] || fail "qua 600s khong thay measure-sp1.sh in duong dan log, xem $MEASURE_OUT"
echo "Android log: $ANDROID_LOG"
echo "Mac log:     $MAC_LOG"
[ -n "$MAC_APP_PATH" ] && echo "App macOS:   $MAC_APP_PATH"

echo "== 5. Cho link len Bluetooth (toi da 120s) =="
wait_for_connected 120 || fail "qua 120s khong thay 'to=Connected channel=bluetooth' trong $MAC_LOG"
echo "Da thay Bluetooth Connected."

case "$SESSION" in
  1)
    echo "== 6. AC1 idle: 30 lan copy text, doi chieu, cach 3-4s =="
    ANDROID_COPY_OK=0
    if adb "${ADB_ARGS[@]}" shell pm list packages ca.zgrs.clipper 2>/dev/null | grep -q 'package:ca\.zgrs\.clipper'; then
      CLIPPER_INSTALLED=1
      ANDROID_COPY_OK=1
    else
      echo "CANH BAO: khong thay app Clipper (ca.zgrs.clipper) tren S25 — khong co cach set clipboard Android" \
           "tu adb ma khong co UI, bo qua chieu S25->Mac, chi copy chieu Mac->S25 ca 30 lan." >&2
    fi
    for (( i = 1; i <= 30; i++ )); do
      if [ "$ANDROID_COPY_OK" -eq 1 ] && (( i % 2 == 0 )); then
        if ! android_copy_text "sp1 auto s25->mac $i $(epoch_ms)"; then
          echo "CANH BAO: lan $i copy tu S25 that bai, bo qua lan nay" >&2
        fi
      else
        print -n -- "sp1 auto mac->s25 $i $(epoch_ms)" | pbcopy
      fi
      sleep $(( 3 + (RANDOM % 2) ))
    done

    echo "== 7. 5 vong tat/bat Bluetooth tren S25, moi vong cho Connected lai (toi da 30s) =="
    for (( round = 1; round <= 5; round++ )); do
      echo "-- vong $round/5: tat bluetooth_manager --"
      adb "${ADB_ARGS[@]}" shell cmd bluetooth_manager disable || true
      sleep 2
      echo "-- vong $round/5: bat lai bluetooth_manager --"
      adb "${ADB_ARGS[@]}" shell cmd bluetooth_manager enable || true
      if ! wait_for_connected 30; then
        echo "CANH BAO: vong $round khong thay Connected lai trong 30s" >&2
      fi
    done

    echo "== 8. Scan response: khoa man hinh S25, cho 60s, Cmd-Q + mo lai app Mac =="
    BT_ACCEPT_BEFORE="$(grep -c 'ev=bt_accept' "$ANDROID_LOG" 2>/dev/null || true)"
    : "${BT_ACCEPT_BEFORE:=0}"
    adb "${ADB_ARGS[@]}" shell input keyevent KEYCODE_SLEEP || true
    sleep 60
    osascript -e 'quit app "HandLive"' || echo "CANH BAO: osascript quit app HandLive that bai" >&2
    if [ -n "$MAC_APP_PATH" ]; then
      open "$MAC_APP_PATH" || echo "CANH BAO: mo lai app Mac that bai" >&2
    else
      echo "CANH BAO: khong doc duoc duong dan app macOS tu $MEASURE_OUT, bo qua mo lai app" >&2
    fi
    sleep 5
    adb "${ADB_ARGS[@]}" shell input keyevent KEYCODE_WAKEUP || true
    wait_for_connected 30 || echo "CANH BAO: sau buoc scan-response khong thay Connected lai trong 30s" >&2
    BT_ACCEPT_AFTER="$(grep -c 'ev=bt_accept' "$ANDROID_LOG" 2>/dev/null || true)"
    : "${BT_ACCEPT_AFTER:=0}"
    echo "bt_accept truoc=$BT_ACCEPT_BEFORE sau=$BT_ACCEPT_AFTER"
    if [ "$BT_ACCEPT_AFTER" -le "$BT_ACCEPT_BEFORE" ]; then
      echo "CANH BAO: bt_accept khong tang sau buoc scan-response (xem 00-common-specs.md 0.4.5)" >&2
    fi
    ;;

  2)
    echo "== 6. AC1 duoi tai: anh ~5MB len pasteboard Mac, xen 10 lan copy text =="
    IMG_BMP="$TMPDIR/handlive-sp1-bench-$TS.bmp"
    IMG_PNG="$TMPDIR/handlive-sp1-bench-$TS.png"
    make_bench_image "$IMG_BMP" "$IMG_PNG" || fail "tao anh bench that bai"
    rm -f "$IMG_BMP"
    for (( i = 1; i <= 10; i++ )); do
      if (( i == 1 || i % 3 == 0 )); then
        set_mac_image_clipboard "$IMG_PNG" || echo "CANH BAO: set anh len pasteboard Mac that bai (lan $i)" >&2
        sleep 1
      fi
      print -n -- "sp1 auto load mac->s25 $i $(epoch_ms)" | pbcopy
      sleep $(( 3 + (RANDOM % 2) ))
    done
    rm -f "$IMG_PNG"
    ;;

  3)
    echo "== 6. Doze: ep S25 vao Doze =="
    adb "${ADB_ARGS[@]}" shell dumpsys battery unplug || true
    adb "${ADB_ARGS[@]}" shell input keyevent KEYCODE_SLEEP || true
    adb "${ADB_ARGS[@]}" shell dumpsys deviceidle force-idle || true

    echo "== 7. 30 lan copy text Mac->S25, cach 30s, man hinh S25 khong dong vao =="
    for (( i = 1; i <= 30; i++ )); do
      print -n -- "sp1 auto doze mac->s25 $i $(epoch_ms)" | pbcopy
      sleep 30
    done

    echo "== 8. Khoi phuc S25 sau Doze =="
    adb "${ADB_ARGS[@]}" shell dumpsys deviceidle unforce || true
    adb "${ADB_ARGS[@]}" shell dumpsys battery reset || true
    adb "${ADB_ARGS[@]}" shell input keyevent KEYCODE_WAKEUP || true
    ;;
esac

echo "== 9. Dung ghi log =="
kill -INT "$MEASURE_PID" 2>/dev/null || true
wait "$MEASURE_PID" 2>/dev/null || true
LOGGING_STOPPED=1

echo "Android log: $ANDROID_LOG"
echo "Mac log:     $MAC_LOG"

command -v python3 >/dev/null || fail "khong thay python3 trong PATH"

echo "== 10. clip_latency.py (AC1) =="
python3 "$SHARED_DIR/tools/bench/clip_latency.py" "$ANDROID_LOG" "$MAC_LOG" --json \
  || echo "CANH BAO: clip_latency.py tra ma loi khac 0" >&2

echo "== 11. reconnect_time.py (AC2) =="
python3 "$SHARED_DIR/tools/bench/reconnect_time.py" "$MAC_LOG" "$ANDROID_LOG" --json \
  || echo "CANH BAO: reconnect_time.py tra ma loi khac 0" >&2

echo "Xong session $SESSION."
