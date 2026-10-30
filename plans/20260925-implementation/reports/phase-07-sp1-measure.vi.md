[English](phase-07-sp1-measure.md) | Tiếng Việt

# Đo thật SP1: kênh điều khiển Bluetooth (Samsung Galaxy S25 + Mac)

Mục tiêu: đo AC1 (độ trễ gói văn bản) và AC2 (thời gian kết nối lại) của kênh điều khiển Bluetooth trên máy thật,
khi cả hai máy đều mất mạng. Sếp đã chốt đo SP1 trước rồi mới làm tiếp Phase 7. Ngưỡng:
`phase-07-ket-noi-moi-noi.md` AC1/AC2. `reports/phase-07-spike-g7.md` có số đo của spike dùng rồi bỏ; lần này đo
lại trên app thật.

## Kiểm nối dây (đã làm ngày 2026-10-29, trước khi viết runbook này)

Đã xác nhận trên đường chạy thật của app, không phải class có sẵn mà chưa ai gọi:

- Android: `ConnectionRuntime.startLocked()` gọi `bluetooth.start(...)` (`BluetoothAdvertising`) song song với
  server LAN (`handlive-android/feature/connection/src/main/kotlin/app/handlive/android/feature/connection/ConnectionRuntime.kt:213`).
  `ConnectionRuntime` do foreground service thật `HandLiveService.onStartCommand` tạo và chạy
  (`handlive-android/feature/connection/src/main/kotlin/app/handlive/android/feature/connection/HandLiveService.kt:50`).
- macOS: `makeManager` mặc định của `AppModel` dựng `ConnectionManager(localCapability:, relay:)`
  (`handlive-apple/Packages/HLMacUI/Sources/HLMacUI/AppModel.swift:108`); tham số `bluetooth` mặc định của nó là
  `ConnectionManager.defaultBluetoothCentral()`, trên macOS trả về `CoreBluetoothCentral()`
  (`handlive-apple/Packages/HLTransport/Sources/HLTransport/ConnectionManager.swift:91-96`).

Cả hai phía đều đã nối thật. Không có gì cản việc đo AC1.

**Thiếu sót đã biết, không chặn, đã báo riêng cho Lead:** bench event `bt_seen`/`bt_lost` (nêu trong AC2 và
`shared/tools/bench/README.md`) chưa được ghi ở đâu trong code thật, chỉ có trong spike dùng rồi bỏ
(`handlive-apple/Tools/BLESpike`, `handlive-android/tools/ble-spike`). `CoreBluetoothCentral.swift` không có lệnh
`BenchLog.event` nào. Thiếu hai event này, `reconnect_time.py` vẫn ra số dùng được: khi không thấy mốc
`bt_seen`/`wake`/`net up` nào trong khoảng đo, nó dùng `since_loss_ms` (rời Connected → vào lại Connected). Số này
là chặn trên an toàn cho "thời gian từ lúc thấy lại peer" mà AC2 cần. Dùng cột đó.

## Điều kiện

- Cả hai máy **mất mạng**: tắt Wi-Fi trên S25 (Cài đặt → Wi-Fi) và trên Mac (thanh menu), tắt dữ liệu di động
  trên S25. **Bật** Bluetooth trên cả hai.
- Hai máy phải **đã ghép đôi từ một phiên LAN trước đó** (luồng A, đã lưu `pairing_secret`). SP1 chỉ chạy kênh
  điều khiển Bluetooth của một cặp đã ghép, không đo việc ghép đôi (A7.2/M7.2 chưa làm).
- S25 cắm vào chính Mac này qua USB, `adb` thấy máy (đã bật USB debugging). Chạy script trên Mac này, vì Mac cũng
  là máy đo phía Bluetooth.
- Đã cài công cụ dòng lệnh Xcode và `xcodegen` (chưa có thì `brew install xcodegen`).

## Các bước

Bài đo chạy tối đa ba **phiên log**. `clip_latency.py` gộp các lần copy theo loại (text hay ảnh), không theo điều
kiện đo, nên text của lượt không tải, lượt đang tải và lượt Doze phải nằm ở các file log riêng, nếu không số sẽ
lẫn vào nhau. Mỗi lần chạy script là một phiên mới với file log mới.

### Phiên 1: AC1 không tải, AC2, scan response

1. `zsh handlive/tools/measure-sp1.sh [adb_serial]` (bỏ `adb_serial` nếu chỉ cắm một máy). Script sẽ:
   - build và cài APK debug lên S25, cấp quyền `BLUETOOTH_ADVERTISE`/`BLUETOOTH_CONNECT` (app chưa có màn xin quyền
     vì A7.7a/b chưa làm, nên script cấp thẳng bằng `pm grant`), rồi mở app;
   - chạy `xcodegen generate` + `xcodebuild build` cho app macOS (scheme `HandLive`, Debug) rồi mở app;
   - chạy `adb logcat` và `log stream`, ghi các dòng `HLBENCH/1` vào
     `handlive/.build-logs/sp1-<timestamp>-android.log` và `...-mac.log`. Script in ra hai đường dẫn này; giữ lại
     để dùng ở các bước kiểm bên dưới.
2. Xác nhận kết nối đang thật sự đi qua Bluetooth. **Chỉ báo trạng thái trên Mac hiện Wi-Fi kể cả khi đang chạy
   Bluetooth** (nhãn tạm cho tới khi có chuỗi Bluetooth, `AppModel+Link.swift:109`), nên đừng dựa vào nhãn. Mở
   một cửa sổ Terminal thứ hai và chạy:

   ```sh
   grep 'ev=state' <đường dẫn log mac> | tail -n 1
   ```

   Dòng in ra phải kết thúc bằng `to=Connected channel=bluetooth`. Cần kiểm lại kết nối lúc nào trong phiên này
   thì chạy lại lệnh đó.
3. AC1 không tải: copy một đoạn text ngắn trên một máy, xác nhận máy kia nhận được, lặp lại **ít nhất 30 lần**,
   cách nhau vài giây, luân phiên hai chiều. Xong thì chạy lại lệnh `grep` ở bước 2: nếu dòng cuối không phải
   `to=Connected channel=bluetooth`, hoặc log có `to=ConnectingBT` lặp đi lặp lại, ghi lại: đó là một phát hiện,
   không phải nhiễu bình thường.
4. AC2: tắt rồi bật lại Bluetooth trên S25 (Cài đặt → Thiết bị đã kết nối → Bluetooth, hoặc ô Cài đặt nhanh), chờ
   tới khi lệnh `grep` ở bước 2 lại cho `to=Connected channel=bluetooth`, rồi lặp lại **ít nhất 5 lần**. Tắt màn
   hình điện thoại giữa các vòng cũng được, càng giống dùng thật.
5. Kiểm tra scan response (rủi ro đã nêu trong spec, 0.4.5 "Advertisement"): khoá màn hình S25 (vẫn bật
   Bluetooth) và chờ khoảng một phút. Trên Mac, thoát HandLive (Cmd-Q) rồi mở lại bằng `open <đường dẫn app macOS>`
   (script đã in đường dẫn này ở dòng `App macOS:`). Trong lúc điện thoại vẫn tắt màn hình, xác nhận Mac kết nối
   lại được (lệnh `grep` ở bước 2) và log Android có thêm dòng `bt_accept` mới:

   ```sh
   grep -c 'ev=bt_accept' <đường dẫn log android>
   ```

   Số đếm phải tăng ít nhất một. Bước này kiểm điều kiện "service data đọc được trên Mac dù app đang ở nền" trong
   tiêu chí nghiệm thu A7.1b/M7.1c, khi điện thoại đã tắt màn hình.
6. Bấm Ctrl-C ở cửa sổ đang chạy script để dừng ghi log. Script in ra đường dẫn hai file log và số dòng của mỗi
   file.

### Phiên 2 (tuỳ chọn): AC1 khi đang tải

7. Chạy `zsh handlive/tools/measure-sp1.sh --log-only [adb_serial]` — giống bước 1 nhưng bỏ qua build/cài APK và
   build Xcode, dùng lại app đã cài/đã build từ phiên 1, chỉ mở lại app ở hai máy (báo lỗi rõ nếu phiên 1 chưa
   chạy đủ một lần không có `--log-only`). Xác nhận kết nối Bluetooth (bước 2). Copy một ảnh lớn (khoảng 5 MB)
   theo một chiều, trong lúc ảnh đang truyền thì copy vài đoạn text ngắn theo chiều ngược lại. Lặp lại tới khi
   được khoảng 10 lần copy text. Theo spike thì số sẽ **tệ hơn nhiều** (hàng đợi FIFO, chưa có làn ưu tiên vì
   D7.1/A7.4 chưa làm). Cứ ghi số lại, không đạt ở phiên này không tính là chặn. Bấm Ctrl-C để dừng.

### Phiên 3: AC1 khi điện thoại ở Doze

8. Chạy `zsh handlive/tools/measure-sp1.sh --log-only [adb_serial]` (dùng lại app như bước 7) và xác nhận kết nối
   Bluetooth (bước 2). Đưa S25 vào Doze bằng đúng các lệnh spike đã dùng (cắm nhiều máy thì thêm `-s <adb_serial>`
   ngay sau `adb`):

   ```sh
   adb shell dumpsys battery unplug
   adb shell input keyevent KEYCODE_SLEEP
   adb shell dumpsys deviceidle force-idle
   ```

9. Không chạm vào điện thoại. **Chỉ trên Mac**, copy một đoạn text ngắn khoảng 30 giây một lần, **ít nhất 30 lần**
   (khoảng 15 phút, giống lượt Doze của spike). Phiên này chỉ đo chiều Mac → điện thoại, vì màn hình điện thoại
   luôn tắt.
10. Trả điện thoại về trạng thái thường, rồi bấm Ctrl-C để dừng ghi log:

    ```sh
    adb shell dumpsys deviceidle unforce
    adb shell dumpsys battery reset
    adb shell input keyevent KEYCODE_WAKEUP
    ```

## Đọc AC1 / AC2 từ log

Hai công cụ dưới đây đã có sẵn và không phân biệt kênh (đọc `clip_read`/`clip_applied`/`state` bất kể phiên là LAN
hay Bluetooth: `ConnectionRoute.benchChannel` trên macOS, và trường `channel` riêng của event `state`). Chạy trên
cặp log của từng phiên:

```sh
python3 handlive-shared/tools/bench/clip_latency.py \
  handlive/.build-logs/sp1-<ts>-android.log handlive/.build-logs/sp1-<ts>-mac.log --json

python3 handlive-shared/tools/bench/reconnect_time.py \
  handlive/.build-logs/sp1-<ts>-mac.log handlive/.build-logs/sp1-<ts>-android.log --json
```

- AC1: nhóm **"text inline"** của `clip_latency.py`, lấy từ phiên 1 cho lúc không tải, phiên 2 cho lúc đang tải,
  phiên 3 cho Doze. Ngưỡng dựng sẵn của công cụ (50 ms, cờ `--check`) là ngưỡng **LAN** của Phase 1, nên bỏ qua
  kết luận của `--check`. Tự so `p95` in ra với **200 ms** (phiên 1 và 2) hoặc **3000 ms** (phiên 3, Doze; ngưỡng
  nới này sếp đã chấp nhận riêng cho điều kiện đó, vì spike đo được p95 ≈ 664 ms một chiều khi Doze thật).
- AC2: chạy `reconnect_time.py` trên log của phiên 1. Đọc **p95** của `since_loss_ms` qua các vòng ở bước 4
  (không đọc `reconnect_ms`, vì cột đó cần `bt_seen`, xem thiếu sót ở trên), tự so với **3000 ms**.
- Lần copy hoặc vòng kết nối lại nào mà công cụ không ghép được cặp (thiếu `clip_applied`, không thấy quay lại
  `Connected`) sẽ bị bỏ khỏi phép tính phân vị mà không báo gì. Nếu số đếm trong kết quả ít hơn số lần copy hoặc
  số vòng đã làm, ghi rõ điều đó trong kết quả, đừng chỉ báo con số phân vị.

## Kết quả (điền sau khi đo)

| Bài đo | Chỉ số | Ngưỡng | n | p50 | p95 | Đạt? |
|---|---|---|---|---|---|---|
| AC1, không tải, link đã thiết lập (phiên 1) | độ trễ text inline (một chiều, `clip_applied` − `clip_read`) | ≤ 200 ms | | | | |
| AC1, trong lúc truyền ảnh 5 MB (phiên 2) | như trên | ≤ 200 ms | | | | |
| AC1, điện thoại ở Doze, Mac → điện thoại (phiên 3) | như trên | ≤ 3000 ms (nới) | | | | |
| AC2, tắt/bật Bluetooth (phiên 1) | `since_loss_ms` | ≤ 3000 ms | | | | |
| Scan response, điện thoại tắt màn hình (phiên 1, bước 5) | Mac kết nối lại, có dòng `bt_accept` mới | đạt/không | | — | — | |

## Rủi ro đã nêu trong spec, mang theo vào lần đo này

- **Scan response** (0.4.5 "Advertisement"): spike chưa từng thử; tiêu chí nghiệm thu A7.1b/M7.1c yêu cầu "scan
  response chứa service data đọc được trên Mac, dù app đang ở nền". Bước 5 ở trên là lần kiểm thật đầu tiên trên
  code sản phẩm.
- **RTT khi Doze**: spike đo được p95 ≈ 664 ms một chiều trong 15 phút Doze cưỡng ép, trên vòng loopback riêng của
  spike, so với ngưỡng chung 200 ms. Vì vậy mới có ngưỡng riêng 3000 ms, chỉ áp cho điều kiện này. Lần này là lần
  đầu đo trên scheduler/session của app thật thay vì của spike.
- **Xoay hint/PSM** (`BT_HINT_PERIOD` = 15 phút, `00-common-specs.md:1370`): bài đo dài hơn khoảng 15 phút sẽ đi
  qua một mốc xoay. Nếu số AC2 xấu bất thường ở đúng một vòng, kiểm xem vòng đó có trùng lúc xoay không (bộ quảng
  bá và PSM cùng đổi tại mốc xoay, `00-common-specs.md:225`) trước khi coi là hồi quy.
