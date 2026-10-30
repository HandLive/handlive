[English](phase-07-ket-noi-moi-noi.md) | Tiếng Việt

# Phase 7 — Kết nối mọi nơi

**Mục tiêu:** sau lần ghép đôi QR đầu tiên, điện thoại và Mac ở gần nhau tự kết nối với nhau khi cả hai đều không có
mạng (kịch bản X, trường hợp chủ dự án cần giải) — không có bước mạng thủ công nào và **không máy nào phải rời hay đổi
Wi-Fi hiện tại**.
- Khi không có LAN, một liên kết Bluetooth đã được bảo mật chở kênh điều khiển.
- Một làn dữ liệu lớn chở ảnh qua đường nhanh nhất được phép: LAN, Wi-Fi Direct (chỉ theo nhu cầu, khi Wi-Fi của Mac
  đang rảnh), Bluetooth (chạy nền).
- Cùng đường Bluetooth đó cũng phủ kịch bản Y (điện thoại dùng dữ liệu di động, Mac ở một Wi-Fi khác) khi hai máy ở gần
  nhau. Phase này không có relay và không có ghép đôi HFP (xem phần thu gọn phạm vi bên dưới).

Trạng thái: **bắt đầu ngày 2026-10-28 theo quyết định của chủ dự án, không chờ các gate G4, G5 và G6** (Phiên xác thực 2). Chủ dự án đề xuất ngày 2026-10-01 (thiết kế trong `reports/phase-07-brainstorm.md`, nghiên cứu trong `reports/research-direct-wifi-link-2026-10-01.md`); sửa lại cùng ngày sau vòng red team (mục cuối file). Bỏ quy tắc ngày 2026-10-01 "chỉ bắt đầu sau khi đóng G4, G5 và G6". Lập theo kiểu viết test trước: mọi thẻ triển khai viết test trước khi viết code.

**Thu gọn phạm vi 2026-10-28** (quyết định của chủ dự án: không deploy relay; Phase 4 đã dừng ngày 2026-10-12 nên không
có HFP):
- **Bỏ — relay:** R7.1; đường relay bảng định tuyến; phần relay kịch bản Y AC3; phần relay A7.4/M7.4 (bulk qua relay, op nhu cầu bulk, quy tắc giữ relay) và D7.1. Code relay hiện tại (CONN-03) giữ nguyên, phase không test.
- **Bỏ — ghép đôi HFP:** SP5 (A7.6/M7.6), AC5, AC10, câu hỏi ghép đôi G7, phép đo "trong cuộc gọi HFP" G7, thay đổi AUDIO-01 D7.1 và `link.auto_bond`. Mở lại khi Phase 4 tiếp tục.
- Dòng dưới giữ và đánh dấu, lịch sử red-team còn đọc được.

## Gate G7 — spike (khoảng một tuần, trước mọi thẻ việc khác)

Câu hỏi: lớp mang Bluetooth nào đạt mục tiêu giữa điện thoại Samsung và Mac; bảo mật liên kết Bluetooth thế nào; Mac có dùng nhóm Wi-Fi Direct của điện thoại an toàn được không; và tốn chi phí bao nhiêu?
- **Lớp mang:**
  - So sánh BLE L2CAP CoC (`listenUsingInsecureL2capChannel` ↔ `CBPeripheral.openL2CAPChannel`) với RFCOMM cổ điển (`listenUsingRfcommWithServiceRecord` ↔ `IOBluetoothDevice.openRFCOMMChannelSync`).
  - Đo trễ một chiều 1 KB (p50/p95), tốc độ 1 MB và 5 MB, thời gian nối lại — khi tắt màn hình 10 phút, khi Doze, khi có lượt truyền bulk. (*Bỏ 2026-10-28:* "khi có cuộc gọi HFP" — không HFP sau Phase 4 dừng.)
  - **RFCOMM chỉ được coi là khả thi khi đã chứng minh được cách để Mac tới điện thoại mà không cần bond nào** (app Android không đọc được địa chỉ Bluetooth của chính nó; địa chỉ BLE là ngẫu nhiên; HandLive không còn tạo bond vì đã bỏ SP5). Nếu không, BLE chở SP1/SP2.
- **Chạy nền:** A-SVC (foreground service `connectedDevice`) quảng bá và nhận kết nối trên One UI khi tắt màn hình; central trên Mac nối lại sau ngủ/thức.
- **Câu hỏi bảo mật:**
  - L2CAP CoC chưa bond có mã hóa tầng link không (dự kiến: không → lớp bảo mật link của D7.1 là bắt buộc).
  - Một sniffer BLE thấy gì khi có lớp bảo mật link bản thử.
  - macOS có giữ mạng `DIRECT-hl-…` trong danh sách mạng đã biết sau khi rời không, và có xóa được không.
- **Ghép đôi (cho HFP) — Bỏ 2026-10-28 (đã bỏ SP5, Phase 4 đã dừng; giữ lại làm lịch sử):** thử luồng (b) — điện thoại `createBond` tới địa chỉ Mac gửi qua E2E
  (`IOBluetoothHostController.addressAsString`) — và luồng (c) — suy khóa chéo từ một liên kết BLE đã bond. **Bỏ luồng
  (a)** (bật chế độ cho phép tìm thấy), vì nó phát tên thiết bị và cho phép giả tên. Kiểm tra app Android có đọc được mã
  ghép đôi (`ACTION_PAIRING_REQUEST`) mà không cần quyền hệ thống không; kiểm tra `replyUserConfirmation` trên Mac.
- **Wi-Fi Direct:**
  - S25 tạo nhóm tự trị với SSID `DIRECT-hl-…` cố định, trong khi điện thoại giữ Wi-Fi của mình (STA + P2P).
  - Mac join bằng CoreWLAN từ bản đã notarize, hardened runtime, cấp quyền Location (entitlement `com.apple.security.personal-information.location`).
  - Đo: thời gian join; hộp thoại nào hiện lên; macOS có quay về mạng khác không.
  - **Tiêu chí đạt:** phân biệt đúng "kết nối hay rảnh" và "nhóm của mình hay mạng khác", trên macOS 27 và 13 hoặc 14, có quyền Location, từ chính app (không CLI).
  - Không dùng `networksetup` với passphrase trong danh sách tham số.
- **Kết quả** ghi vào `reports/phase-07-spike-g7.md`: lớp mang, cách join, bản thử lớp bảo mật link, các số đo so với
  AC1–AC4 và AC6–AC9 (chủ dự án xác nhận hoặc chỉnh AC6). **Không lớp mang nào đạt AC1 trên liên kết đã nối sẵn → dừng
  Phase 7** và viết báo cáo; khi đó sản phẩm chỉ còn LAN (không deploy relay nên không có đường dự phòng).

## Bối cảnh

- Thiết kế: `reports/phase-07-brainstorm.md` (mục 3–8; một phần đã được thay thế bởi vòng red team bên dưới — file này
  là bản có hiệu lực); nghiên cứu: `reports/research-direct-wifi-link-2026-10-01.md`.
- Kênh truyền hiện có:
  - common specs 0.4.1 (LAN, bắt buộc TLS — TLS còn che định danh và metadata); 0.4.3 (relay, TLS tới relay, `rv_id`
    cho rendezvous);
  - 0.6.3 (bắt tay phiên xác thực bằng `PRK`); 0.6.3 bước 7 (khóa stream, hiện chỉ có `camera`/`call-audio`);
  - 0.11 (máy trạng thái: chỉ rời `Idle` khi có mạng, mất mạng thì bỏ mọi phiên);
  - CONN-01 E4 và CONN-03 E9 (lỗi pre-auth: chỉ LAN có TLS ghim mới được hủy ghép đôi); PAIR-01; CLIP-03;
  - AUDIO-01 (quy tắc "không bao giờ tự ghép đôi Bluetooth thay người dùng" — thay đổi ngày 2026-10-01 đã bỏ cùng SP5
    ngày 2026-10-28, nên quy tắc giữ nguyên).
- **Mô hình tin cậy của relay không mang nguyên sang Bluetooth được:** relay che định danh sau TLS và xác thực
  `device_id` trước khi chuyển tiếp; liên kết BLE chưa bond thì không làm được việc nào. D7.1 thêm một lớp bảo mật link,
  một chính sách admission cho Bluetooth và một quy tắc pre-auth theo route.
- Điểm cắm trong code:
  - Apple: `MessageChannel` (`WebSocketChannel`, `RelayPeerChannel`) trong `HLTransport`.
  - Android: peer qua relay là một `WebSocketSession` ảo của Ktor (`RelayPeerSocket`), phục vụ qua
    `ControlServer.serveRelayPeer`.
  - Chưa nền tảng nào có server hay client `/v1/stream/*` (A7.3/M7.3).
- Giới hạn nền tảng (đã kiểm chứng):
  - Mac chỉ có một radio Wi-Fi, không có API Wi-Fi Direct/Wi-Fi Aware; CoreWLAN không trả SSID nếu thiếu Location.
  - App Android không tự bật/tắt Wi-Fi/Bluetooth âm thầm được, không tự xác nhận ghép đôi được nếu thiếu quyền hệ
    thống, không đọc được địa chỉ Bluetooth của chính nó.
  - Địa chỉ group owner của P2P không cố định (dùng gateway).

## Yêu cầu và tiêu chí đo được

| # | Tiêu chí |
|---|---|
| AC1 | Envelope văn bản (văn bản bảng nhớ tạm; SMS và thông báo cuộc gọi đi cùng làn), từ lúc sao chép đến lúc dùng được, phân vị 95: **LAN < 50 ms (mục tiêu Phase 1, giữ nguyên)**; **Bluetooth ≤ 200 ms trên liên kết đã nối sẵn, kể cả khi đang truyền bulk**; ~~relay ở mức cố gắng tốt nhất~~ (bỏ relay 2026-10-28) |
| AC2 | Nối lại ≤ 3 s sau khi mạng thay đổi hoặc sau khi lại thấy thiết bị Bluetooth bên kia (sự kiện bench `bt_seen`/`bt_lost`) |
| AC3 | Ảnh 5 MB: ≤ 2 s trên LAN; trong X, ảnh đầu ≤ 10 s (gồm cả thời gian join Wi-Fi Direct theo nhu cầu) và các ảnh sau ≤ 2 s khi nhóm còn mở; ~~trong Y bị giới hạn bởi tốc độ upload di động của điện thoại qua relay~~ (bỏ 2026-10-28, không có relay: trong Y, khi hai máy ở gần nhau, ảnh đi qua Bluetooth); chỉ còn Bluetooth: truyền nền, không có mục tiêu thời gian và không có giới hạn dung lượng riêng cho Bluetooth (vẫn áp giới hạn ảnh của CLIP-03) <!-- Updated: Validation Session 1 - AC3 relaxed for the first image in X; no size cap over Bluetooth --> |
| AC4 | Bất biến: không máy nào bị đổi hay mất kết nối Wi-Fi hiện tại. Mac chỉ join Wi-Fi Direct khi có ảnh đang chờ, Wi-Fi của Mac đã không kết nối mạng nào trong ≥ `DIRECT_WIFI_IDLE_MIN` và lượt quét không thấy mạng quen nào; Mac ở lại nhóm cho các ảnh tiếp theo và rời khi một lượt quét định kỳ thấy mạng quen, hoặc sau `DIRECT_WIFI_MAX`; HandLive không bao giờ tự bật/tắt radio và không ở lại nhóm khi không có lý do |
| AC5 | **Bỏ 2026-10-28 (đã bỏ SP5, không có HFP).** Trước đây: ghép đôi HFP do HandLive khởi động: ≤ 1 chạm trên điện thoại; Mac chỉ tự xác nhận khi mã ghép đôi khớp với mã nhận qua E2E, nếu không thì người dùng so một mã |
| AC6 | Ghép đôi lần đầu khi cả hai offline (QR qua BLE): ≤ 15 s từ lúc quét đến lúc ghép đôi xong (G7 xác nhận hoặc chỉnh) |
| AC7 | Chỉ còn các hộp thoại xin quyền một lần: Mac — Local Network, Bluetooth, Location; Android 12+ — Nearby devices; **Android 10–12 — thêm Location và bật dịch vụ vị trí, cho Wi-Fi Direct (quyết định của chủ dự án 2026-10-01)**; cộng các quyền đã có; cộng một yêu cầu hệ thống một chạm để bật Bluetooth khi không còn đường nào khác, tối đa một lần mỗi ngày <!-- Updated: Validation Session 1 - Bluetooth-off prompt --> |
| AC8 | Thông điệp pre-auth trên route không TLS ghim tới điện thoại (Bluetooth; cũng relay hiện tại) không làm đổi trạng thái cặp, xóa cặp hay dừng nối |
| AC9 | Sniffer BLE không thấy định danh cố định nào (`pair_id`, `device_id`, khóa, tên, `pr`) và không thấy `type`, `id` hay nhịp thời gian theo từng loại envelope |
| AC10 | **Bỏ 2026-10-28 (đã bỏ SP5, HandLive không tạo bond nào).** Trước đây: không bond Bluetooth nào được tự xác nhận nếu chưa có mã ghép đôi đã kiểm qua E2E |

Quy tắc định tuyến (2026-10-28: làn điều khiển LAN > Bluetooth; làn dữ liệu lớn LAN > Wi-Fi Direct (chỉ X, theo quy tắc AC4) > Bluetooth chạy nền). Bỏ các bậc relay ngày 2026-10-01 (điều khiển "> relay", dữ liệu lớn "> relay >").

| Tình huống | Làn điều khiển | Làn dữ liệu lớn |
|---|---|---|
| Chung LAN | LAN | LAN |
| X, Wi-Fi Mac rảnh, có ảnh đang chờ | Bluetooth | Wi-Fi Direct (theo nhu cầu, quy tắc AC4), nếu không được thì Bluetooth (chạy nền) |
| X, Mac đang ở một Wi-Fi không có Internet | Bluetooth | Bluetooth (chạy nền) |
| Y, ở gần nhau | Bluetooth | Bluetooth (chạy nền) — *trước đây là relay khi có nhu cầu bulk, bỏ 2026-10-28* |
| Ở xa nhau | Phase này không có đường nào — *trước đây là relay, bỏ 2026-10-28* | Không có đường |

## Thẻ việc

Mã chữ cái như mục 3 của plan, thêm **D** = tài liệu trong hub. Cột "Test viết trước" liệt kê những gì phải được viết
và commit (ở trạng thái đỏ) trước code của thẻ đó.

| Mã | Việc | Test viết trước | Đầu ra | Tiêu chí nghiệm thu |
|------|------|-------------|---------|---------------------|
| T7.0 [test] | Spike gate G7 (ở trên): probe dùng một lần trên Android và macOS | — (đo đạc) | `reports/phase-07-spike-g7.md`; probe chỉ ở nhánh spike, không bao giờ merge | Đã chọn lớp mang, cách join và bản thử lớp bảo mật link; đã đo các con số AC; chủ dự án xác nhận AC6 (bỏ luồng ghép đôi và AC5 ngày 2026-10-28) |
| ~~T7.0a~~ [test] | *(Thêm 2026-10-28 theo quyết định của Lead.)* Probe scan response: các probe dùng một lần của T7.0, với bố cục của 0.4.5 (`BT_SERVICE_UUID` 128-bit trong gói quảng bá, service data trong scan response) trên S25 + Mac, Mac quét cả khi ở tiền cảnh lẫn chạy nền | — (đo đạc) | Một mục trong `reports/phase-07-spike-g7.md`; probe chỉ nằm trên nhánh spike, không bao giờ merge | **Bỏ 2026-10-28 (sếp quyết định): scan response được kiểm trong A7.1b/M7.1c trên máy thật.** Trước đây: Mac nhận được service data trong cả hai trường hợp; nếu không, bố cục quảng bá của 0.4.5 đổi (D) trước khi S7.1a chốt vector |
| D7.1 [docs] | Spec trước, cả hai ngôn ngữ. **0.11 và CONN:** điều kiện khởi động "có mạng hoặc Bluetooth đang bật và đã được cấp quyền"; mất mạng chỉ kết thúc phiên LAN/relay; chỉ phản ứng theo lỗi pre-auth trên route có TLS ghim tới điện thoại (`phoneAuthenticatedByTLS`), viết lại CONN-01 E4 và CONN-03 E9 theo quy tắc đó. **0.4.5 liên kết Bluetooth:** quảng bá (service UUID, gợi ý xoay vòng; đổi địa chỉ cùng lúc với gợi ý); lớp bảo mật link trước bất kỳ định danh nào (ví dụ bắt tay kiểu Noise khóa bằng `K_auth`, hoặc định danh mù hóa trên một nonce do điện thoại cấp) và một mã lỗi pre-auth chung; admission (trần toàn cục, một link pre-auth, nonce challenge từ điện thoại, lỗi xác nhận khóa tính như `AUTH_FAILED`); frame = channel id ‖ độ dài ‖ byte, điều khiển đi trước bulk, mảnh bulk vài KB, không có close code (kết thúc bằng `session/bye` đã mã hóa). **Ghép đôi qua BLE:** `pr` = HMAC(`ps`, …), frame đầu tiên có MAC bằng khóa từ `ps` trước khi cấp slot, một slot toàn cục với timeout ngắn; ~~từ chối PIN theo loại transport~~ *đổi ngày 2026-10-28 (sếp quyết định): PIN ghép qua Bluetooth bằng CPace (`CPACE-X25519-SHA512`), một lần đoán trực tuyến mỗi kênh, 3 lần mỗi PIN, có khóa tạm (D7.1e, luồng C của PAIR-01)*. **Bulk:** bắt tay stream cho `bulk` với khóa riêng mỗi kết nối (`K_stream` + cả hai nonce); cả lượt truyền (push, chunk, ack) đi trên làn bulk qua LAN, Wi-Fi Direct hoặc Bluetooth (*bỏ 2026-10-28:* bulk trong frame nhị phân HL của relay, op nhu cầu bulk, quy tắc giữ relay). **Wi-Fi Direct (0.4.6):** SSID/passphrase (sinh ngẫu nhiên cho mỗi group, passphrase ≥ 128 bit), quy tắc vào/ra của AC4, xóa mạng đã lưu sau khi rời, socket HandLive chỉ gắn vào giao diện P2P. ~~**Ghép đôi (AUDIO-01)**~~ *bỏ 2026-10-28 cùng SP5; AUDIO-01 giữ nguyên.* Cộng: hằng số, khóa cài đặt, mã lỗi, SET-01/02/03, leaf CONN-05/CONN-06, PAIR-01, CLIP-03 | — (hợp đồng; vector của S7.1 là test của nó) | `docs/detailed-design/*.md` + `.vi.md` | `validate_design_docs.py` in `problems=0`; `check_bilingual_docs.py` xanh; mọi loại message, mã lỗi, hằng số và chuỗi mới được định nghĩa trước khi viết code; AC8–AC9 truy được về các quy tắc trong spec |
| S7.1a [shared] | *(Tách 2026-10-28 theo quyết định của Lead; trước là S7.1.)* Cho SP1, hợp đồng link: bắt tay lớp bảo mật link (`challenge`, `noise1`, `noise2`, prologue gắn `n_s`, `K_bt_disc`/`K_bt_link`), codec bản ghi (giới hạn `rlen`; 272, 1 040, 4 112) và codec frame (channel id, `more`/`long`, làn ngắn và làn dài của kênh điều khiển, đệm) kèm mẫu âm (`rlen` vượt giới hạn, `chan` lạ, `more` mà không có `long`, mảnh của làn dài vượt `BT_BULK_FRAGMENT_MAX`, message vượt `BT_MESSAGE_MAX`), service data quảng bá (chốt ngay theo bảng 0.4.5; kiểm trên máy thật ở A7.1b/M7.1c); chuỗi giao diện cho hộp thoại Bluetooth và dòng báo Bluetooth tắt; sự kiện bench `bt_seen`/`bt_lost` và trigger cho chúng trong `reconnect_time.py` | Chính các vector và mẫu âm là test: generator tạo ra, `check_*` kiểm tra | `shared/test-vectors/`, `shared/strings/`, `shared/tools/` (gồm `bench/`) | Generator tái tạo được; `check_schemas.py`, `check_strings.py` xanh; báo các nền tảng khác chạy lại test |
| S7.1b [shared] | Cho SP2, làm trong lúc SP1 chạy: HMAC `pr_bt`, `K_bt_pdisc`/`K_bt_plink`, `BT_PIN_HINT`; CPace cho PIN qua Bluetooth (`cpace.json`, Kotlin và Swift: vector `CPACE-X25519-SHA512` của chính bản draft, rồi các ca HandLive và mẫu âm của 0.6.1), `K_bt_pinlink`/`K_bt_pin`; schema cho envelope ghép đôi trên link Bluetooth; chuỗi cho PIN qua Bluetooth và `BT_PIN_LOCKOUT` | Chính các vector và mẫu âm là test: generator tạo ra, `check_*` kiểm tra | `shared/test-vectors/`, `shared/schemas/`, `shared/strings/` | Generator tái tạo được; `check_schemas.py`, `check_strings.py` xanh; báo các nền tảng khác chạy lại test; pentester đã duyệt `cpace.json` trước khi A7.2a/M7.2a bắt đầu |
| S7.1c [shared] | Cho SP3: khóa `bulk` riêng mỗi kết nối (`K_bulk` từ `K_stream` và hai nonce, 0.4.7); schema cho `bulk/stream_hello` và `bulk/stream_welcome` | Chính các vector và mẫu âm là test: generator tạo ra, `check_*` kiểm tra | `shared/test-vectors/`, `shared/schemas/` | Generator tái tạo được; `check_schemas.py`, `check_strings.py` xanh; báo các nền tảng khác chạy lại test |
| S7.1d [shared] | Cho SP4: `ssid` và `passphrase` Wi-Fi Direct sinh ngẫu nhiên cho mỗi group (0.4.6), nên không có vector suy khóa: mẫu kiểm định dạng và bộ ký tự, cả dương lẫn âm (tiền tố `DIRECT-`, độ dài, bảng chữ, entropy của passphrase); schema cho `direct/start`, `direct/stop`, `direct/want` và ack của `direct/start` `{ssid, passphrase, host, port}` (00-common-specs 0.7.1); sự kiện bench `wifi_assoc`; chuỗi cho hộp thoại Location | Chính các vector và mẫu âm là test: generator tạo ra, `check_*` kiểm tra | `shared/test-vectors/`, `shared/schemas/`, `shared/strings/`, `shared/tools/bench/` | Generator tái tạo được; `check_schemas.py`, `check_strings.py` xanh; báo các nền tảng khác chạy lại test |
| A7.1a [android] | *(Tách 2026-10-28 theo quyết định của Lead; trước là A7.1.)* Lõi link, chưa có radio: codec bản ghi và codec frame, mọi độ dài được kiểm trước khi cấp phát; làn ngắn và làn dài của kênh điều khiển cùng việc ráp mảnh; bộ lập lịch của 0.4.5 "Ưu tiên" (điều khiển ngắn > điều khiển dài > bulk, `BT_BULK_INFLIGHT`; chuyển từ A7.4 sang đây vì điều kiện 1 của G7 coi nó là một phần của làn điều khiển); lớp bảo mật link (bên đáp Noise, thử psk của từng cặp, rekey link); admission Bluetooth cho cả listener (`BT_LINK_LIMIT`, `BT_PREAUTH_LIMIT`, `BT_PREAUTH_TIMEOUT`, `BT_AUTH_FAIL_BLOCK`; không bao giờ theo địa chỉ) | Vector codec và lớp bảo mật link của S7.1a; test qua ống giả: bắt tay, `noise1` phát lại trên kênh mới, rekey link, trần pre-auth, chặn sau `BT_AUTH_FAIL_BLOCK`, `rlen` quá cỡ, envelope ngắn gửi sau một envelope 256 KiB vẫn tới trước, hai envelope cùng `type` giữ thứ tự, giới hạn số bản ghi chưa đi hết | `android/core/transport` | Mọi test xanh |
| A7.1b [android] | Radio và nối dây: bộ quảng bá và L2CAP server trong A-SVC (xoay vòng mỗi `BT_HINT_PERIOD`, dựng lại khi `STATE_ON`, độc lập với server LAN và với mạng), `SessionTransport.BLUETOOTH` và mọi `when` theo nó (`PeerSession.Channel` và nơi dùng nó trong các module feature), `BluetoothPeerSocket` (`WebSocketSession` ảo như `RelayPeerSocket`) phục vụ qua `ControlServer.serveBluetoothPeer`, `session/bye` trước mọi lần đóng trên Bluetooth; một **shim loopback chỉ có ở bản debug** cho bộ e2e (không cần cho phép đo SP1, có thể làm sau cùng) | Test hồi quy cho `serveRelayPeer`; test phiên qua ống giả; xoay vòng và dựng lại khi `STATE_ON` với adapter giả; test bản release khẳng định không có shim | `android/core/transport`, `android/feature/connection`, `android/feature/*` (chỉ phần ánh xạ route), `android/app` | Mọi test xanh; phủ các ngoại lệ của CONN-05; đo AC1 (Bluetooth) trên S25, khi rảnh và khi có tải điều khiển dài giả (chỉ bản debug) qua bộ lập lịch; scan response chứa service data đọc được trên Mac, kể cả khi app ở nền |
| M7.1a [macOS] | *(Tách 2026-10-28 theo quyết định của Lead; trước là M7.1.)* Máy trạng thái 0.11, thuần logic, thẻ đầu tiên của SP1: route `.bluetooth` và `ConnectingBT`; khởi động khi không có mạng nếu Bluetooth dùng được; mất mạng chỉ kết thúc phiên LAN/relay; `phoneAuthenticatedByTLS` thay cho `route == .relay` (`ConnectionManager+Run`, `ConnectionManager+Supervise`, `ControlSession`); ưu tiên LAN > Bluetooth có nâng cấp (route relay hiện có giữ nguyên trong code, xếp cuối, không deploy); các `switch` theo route đầy đủ trong các package đọc route (`HLMacUI`, `HLiOSUI`, `HLSMS`, `HLDesignSystem`, `Tools/HandLiveDevClient`) | Đỏ trước: `networkLost` khi đang `connected(.bluetooth)` vẫn giữ kết nối; `idle(noNetwork)` + thấy thiết bị bên kia → đang kết nối; `PAIR_UNKNOWN`/`PAIR_REVOKED`/`UNSUPPORTED_VERSION`/`AUTH_FAILED` giả mạo trước khi xác thực qua Bluetooth không bao giờ hủy ghép đôi hay dừng nối lại; phiên LAN thay phiên Bluetooth | `apple/Packages/HLTransport`, `apple/Packages/HLMacUI`, `apple/Packages/HLiOSUI`, `apple/Packages/HLSMS`, `apple/Packages/HLDesignSystem`, `apple/Tools/HandLiveDevClient` | Mọi test xanh; bản iOS build và chạy như cũ |
| M7.1b [macOS] | Lõi link, chưa có radio, phía khởi tạo của A7.1a: codec bản ghi và codec frame, làn ngắn và làn dài của kênh điều khiển, bộ lập lịch, bên khởi tạo lớp bảo mật link (`noise1`, kiểm `noise2`, rekey link), `BluetoothChannel: MessageChannel` trên ống trong bộ nhớ | Vector codec và lớp bảo mật link của S7.1a; test kênh trong bộ nhớ (danh sách của A7.1a, phía khởi tạo) | `apple/Packages/HLTransport` | Mọi test xanh |
| M7.1c [macOS] | Radio và nối dây: central CoreBluetooth (quét với bộ lọc `BT_SERVICE_UUID`, so hint trong `e − 4`…`e + 4`, `openL2CAPChannel`), chỉ app macOS tạo và inject (iOS không bao giờ tạo), route `.bluetooth` chạy thật trong `ConnectionManager` | Test với central giả: khớp hint, PSM đã xoay, ứng viên kế tiếp sau khi `noise2` hỏng (CONN-05 E3), mất kết nối → `Backoff` | `apple/Packages/HLTransport`, `apple/macOS/HandLive` | Mọi test xanh; bản iOS build và chạy như cũ; đo AC1 (Bluetooth), AC2, AC8; scan response chứa service data đọc được trên Mac, kể cả khi app ở nền |
| A7.2a [android] | *(Thêm 2026-10-28 theo quyết định của Lead.)* Primitive CPace `CPACE-X25519-SHA512`, chưa có Bluetooth: tự viết số học trường mod 2^255 − 19 chạy thời gian hằng (không `BigInteger`, không rẽ nhánh hay tra bảng theo dữ liệu bí mật), ánh xạ Elligator2 của RFC 9380, `calculate_generator`, `ISK` | Toàn bộ vector `cpace.json` của S7.1b, gồm cả mẫu âm | `android/core/crypto` | Mọi vector qua; pentester đã duyệt phần code thời gian hằng |
| A7.2 [android] | Ghép đôi lần đầu khi offline: quảng bá `pr` (dạng HMAC) trong chế độ QR; chỉ cấp slot ghép đôi duy nhất sau một frame đầu có MAC `ps` hợp lệ; PAIR-01 qua liên kết Bluetooth đã bảo mật; PIN qua Bluetooth bằng CPace trên primitive của A7.2a (luồng C của PAIR-01: quảng bá `BT_PIN_HINT`, `cpace1`/`cpace2`, đếm lần thử, `BT_PIN_LOCKOUT`) — *đổi ngày 2026-10-28 theo quyết định của sếp, trước là "từ chối PIN qua Bluetooth một cách tường minh"* | Vector PAIR-01 qua ống giả; vector CPace của S7.1 (`cpace.json`); test âm: PIN sai (3 lần rồi khóa tạm), `Ya` bậc thấp, `cpace1` ngoài cửa sổ PIN, `mode` không khớp loại link, MAC frame đầu thiếu/sai, chiếm giữ slot, người thứ hai tranh slot | `android/feature/pairing`, `android/core/transport` | Phủ các ngoại lệ PAIR-01 qua Bluetooth; đo AC6 |
| M7.2a [macOS] | *(Thêm 2026-10-28 theo quyết định của Lead.)* Primitive CPace, cùng phạm vi với A7.2a (CryptoKit không có số học trường) | Như A7.2a | `apple/Packages/HLCrypto` | Như A7.2a |
| M7.2 [macOS] | Ghép đôi lần đầu khi offline: quét `pr`, thử lần lượt mọi ứng viên có cùng `pr`, chạy PAIR-01 qua `BluetoothChannel` đã bảo mật, rồi ghim và lưu như hiện nay; PIN: quét `BT_PIN_HINT`, làm bên khởi tạo CPace trên primitive của M7.2a, đếm số lần sai PIN, sinh PIN mới khi tới 3 (*thêm ngày 2026-10-28, sếp quyết định*) | Cùng bộ vector cộng `cpace.json`; timeout, `pr` sai, máy quảng bá giả có đúng `pr`, điện thoại ở chế độ PIN với PIN khác, kẻ tấn công trả lời `cpace1` | `apple/Packages/HLTransport` (`Pairing*`) | Đo AC6; không đổi định dạng QR |
| A7.3 [android] | Hạ tầng stream channel: server `/v1/stream/*` trên A-SVC (`stream_hello`/`stream_welcome`, 0.6.3 bước 7) — **dùng lại nếu một thẻ sản phẩm của Phase 4 hoặc 5 đã xây trước** (quyết định I9 của plan) | Test vector bắt tay stream (viết trước) | `android/core/transport`, `android/core/crypto` | Bắt tay stream chạy trên LAN; `camera`/`call-audio` không bị ảnh hưởng |
| M7.3 [macOS] | Client stream channel, cùng phạm vi và quy tắc dùng lại như A7.3 | Như A7.3 | `apple/Packages/HLTransport` | Như A7.3 |
| R7.1 [relay] | **Bỏ 2026-10-28 (không deploy relay).** Trước đây: xác nhận relay chở bulk mà không cần sửa: frame nhị phân `HR` cỡ bulk với giới hạn hiện có; không đổi wire hay giới hạn | Test chuyển tiếp cho frame `HR` cỡ bulk (đỏ nếu relay xử lý sai) | Chỉ test trong `relay/` | `cargo test`, `cargo clippy` xanh; không đổi `wire.rs` hay giới hạn |
| A7.4 [android] | Làn bulk: stream `bulk` với khóa riêng mỗi kết nối; cả lượt truyền CLIP-03 đi trên làn bulk; chọn đường theo bảng định tuyến (LAN > Wi-Fi Direct > Bluetooth); cắm kênh bulk `0x02` vào bộ lập lịch của A7.1a (bộ lập lịch chuyển sang A7.1a ngày 2026-10-28). *Bỏ 2026-10-28:* bulk qua relay tách trong `RelayPeerMux`, op nhu cầu bulk, quy tắc giữ relay | Hồi quy CLIP-03 qua `/v1/ctl` trước; rồi đỏ: chunk tới trước push, AC1 khi đang truyền bulk 5 MB, một ảnh 10 MiB chỉ qua Bluetooth vẫn truyền xong ở chế độ nền (*bỏ:* hai test về relay) | `android/core/transport`, `android/feature/clipboard` | Các ngoại lệ CLIP-03 qua trên mọi đường; AC1 (LAN) không đổi; AC3 (LAN) không đổi |
| M7.4 [macOS] | Làn bulk phía Mac, cùng phạm vi với A7.4, trên bộ lập lịch của M7.1b (điểm cắm `ClipboardPeer`; bỏ phần tách trong `RelayLink`/`RelayPeerChannel` 2026-10-28) | Cùng thứ tự như A7.4 | `apple/Packages/HLTransport`, `apple/Packages/HLAppCore` (bảng nhớ tạm) | Như A7.4 |
| A7.5 [android] | Host Wi-Fi Direct (chỉ X, theo nhu cầu): nhóm với SSID và passphrase sinh ngẫu nhiên cho mỗi group (0.4.6), `LEGACY_OR_R2` trên API 36, bật/tắt theo yêu cầu qua làn điều khiển, giữ nguyên STA; `NEARBY_WIFI_DEVICES` (13+), `ACCESS_FINE_LOCATION` + dịch vụ vị trí (10–12); Wi-Fi tắt → báo, không bao giờ tự bật | Vector kiểm định dạng và bộ ký tự của S7.1d (*đổi 2026-10-28: không có suy khóa*); test vòng đời với `WifiP2pManager` giả (bật, dừng, sập, STA không đổi, dừng sau `DIRECT_WIFI_MAX`) | `android/feature/connection` (hoặc `feature/directlink` mới) | Kiểm AC4 trên S25; đo AC3 trong X |
| M7.5 [macOS] | Join Wi-Fi Direct (chỉ X): quy tắc vào/ra của AC4 (theo nhu cầu, rảnh ≥ `DIRECT_WIFI_IDLE_MIN`, không thấy mạng quen, quét định kỳ, `DIRECT_WIFI_MAX`), join bằng CoreWLAN, kết nối gateway bằng chứng chỉ đã ghim, socket gắn vào giao diện P2P, xóa mạng đã lưu sau khi rời | Đỏ trước: không bao giờ join khi đang kết nối, không bao giờ join khi thấy mạng quen (trường hợp deauth), rời khi thấy mạng quen, rời khi hết thời gian tối đa, đã xóa mạng đã lưu | `apple/Packages/HLTransport`, `apple/macOS/HandLive` | Kiểm AC4, gồm cả kịch bản deauth; AC3 trong X ≤ 2 s |
| A7.6 [android] | **Bỏ 2026-10-28 (SP5; Phase 4 đã dừng, không có HFP).** Trước đây: tự ghép đôi Bluetooth cổ điển, **khởi động ngay sau khi ghép đôi QR** (và một lần cho các cặp đã có khi tính năng ra mắt, hoặc bất cứ khi nào thiếu bond) <!-- Updated: Validation Session 1 - bonding trigger -->, luồng từ G7 ((b) hoặc (c)): yêu cầu ghép đôi qua E2E, `createBond` tới địa chỉ Mac nhận qua E2E, gửi mã ghép đôi qua E2E khi đọc được | Test với adapter giả cho từng trạng thái; không bao giờ ghép đôi khi chưa có phiên đã xác thực; không yêu cầu chế độ cho phép tìm thấy | `android/feature/call` hoặc `android/feature/connection` | Đo AC5, AC10; phủ đường bị từ chối và timeout |
| M7.6 [macOS] | **Bỏ 2026-10-28 (SP5; Phase 4 đã dừng, không có HFP).** Trước đây: tự ghép đôi Bluetooth cổ điển: `IOBluetoothDevicePair`; chỉ tự xác nhận khi mã khớp với mã E2E, nếu không thì hiện mã để người dùng so một lần; giao thiết bị đã bond cho stack HFP | Test quyết định xác nhận/từ chối với delegate giả (khớp, không khớp, thiếu mã) | `apple/Packages/…` (âm thanh cuộc gọi), `apple/macOS/HandLive` | AC5, AC10; không khớp hoặc thiếu mã thì không bao giờ tự xác nhận |
| A7.7a [android] | *(Tách 2026-10-28 theo quyết định của Lead; trước là A7.7.)* Hộp thoại Bluetooth, SP1 (chủ sở hữu AC7 trên Android, phần Bluetooth): SET-01 xin Nearby devices (12+) kèm màn hình giải thích; yêu cầu bật Bluetooth (`ACTION_REQUEST_ENABLE`) chỉ khi không có đường LAN, tối đa một lần mỗi ngày | Test đếm số hộp thoại theo từng mức API (31, 33, 37) | `android/app`, `android/feature/connection` | AC7 (Bluetooth) theo từng mức API |
| A7.7b [android] | Hộp thoại Location, SP4 (Wi-Fi Direct): Location + dịch vụ vị trí (10–12) kèm màn hình giải thích | Test đếm số hộp thoại theo từng mức API (29, 31, 33, 37) | `android/app`, `android/feature/connection` | AC7 theo từng mức API |
| M7.7a [macOS] | *(Tách 2026-10-28 theo quyết định của Lead; trước là M7.7.)* Hộp thoại Bluetooth, SP1 (chủ sở hữu AC7 trên Mac, phần Bluetooth): màn hình giải thích Bluetooth (SET-03), `NSBluetoothAlwaysUsageDescription`; dòng trạng thái khi Bluetooth tắt kèm nút mở cài đặt Bluetooth, cùng quy tắc với A7.7a | Test trình tự hộp thoại (Bluetooth) | `apple/macOS/HandLive` | AC7 (Bluetooth) trên Mac |
| M7.7b [macOS] | Hộp thoại Location, SP4: màn hình giải thích Location (SET-03), lời giải thích dùng Location, entitlement `com.apple.security.personal-information.location`, bước ký bản release | Test trình tự hộp thoại; kiểm entitlement trên bản release | `apple/macOS/HandLive`, `apple/macOS/HandLive.entitlements`, `docs/deployment-guide.md` (qua D) | AC7 trên Mac; Location chạy được trong bản đã notarize |
| T7.1 [test] | Ma trận đầu-cuối: X và Y (ở gần nhau) với S25 + Mac, chung LAN; tắt màn hình, ngủ/thức, tắt Bluetooth, tắt Wi-Fi điện thoại, từ chối Location. **Đối kháng:** máy quảng bá nhái, sniff BLE (AC9), hello bị phát lại, lỗi pre-auth giả (AC8), chiếm giữ slot ghép đôi, deauth Wi-Fi của Mac (AC4). Thời gian ảnh đầu và ảnh sau trong X; một ảnh 10 MiB chỉ qua Bluetooth mà vẫn giữ AC1; tắt Bluetooth ở từng phía. Đếm hộp thoại trên Android 10–12; tiếng Anh và tiếng Việt; TalkBack/VoiceOver. *Bỏ 2026-10-28:* ở xa, relay sập, thử MITM khi ghép đôi (AC10) | Viết trước các kịch bản `shared/tools/e2e` đi qua shim debug của A7.1 | `shared/tools/e2e/`, `reports/phase-07-T7.1.md` | Đạt AC1–AC4 và AC6–AC9; ghi lại kết nối Wi-Fi trước/sau trên cả hai máy từ log debug của app |

## Nhánh và thứ tự làm

- Nhánh `feat/phase-07-connect-anywhere` trong hub, handlive-shared, handlive-android, handlive-apple (handlive-relay
  không còn tham gia: đã bỏ R7.1 ngày 2026-10-28).
- T7.0 làm trước và làm riêng (từ 2026-10-28, không chờ G4/G5/G6). Rồi D7.1, rồi mỗi thẻ shared S7.1a–d làm ngay
  trước sub-project dùng nó (mọi thẻ nền tảng chờ spec, vector và chuỗi). Thẻ nền tảng chỉ được tạo sau khi có số đo
  của G7.
- Sau đó theo thứ tự sub-project (*tách 2026-10-28 theo quyết định của Lead*):
  1. SP1: S7.1a (đã bỏ T7.0a ngày 2026-10-28); M7.1a làm ngay (máy trạng thái thuần, không cần vector); rồi A7.1a ∥ M7.1b, rồi
     A7.1b ∥ M7.1c, cùng A7.7a ∥ M7.7a. Trên Android, A7.1b và A7.7a cùng sửa `android/app` và
     `feature/connection`: làm lần lượt. S7.1b chạy trong SP1 để `cpace.json` được duyệt trước SP2.
  2. SP2: A7.2a ∥ M7.2a (bắt đầu được ngay khi S7.1b đã được duyệt), rồi A7.2 ∥ M7.2.
  3. SP3: S7.1c; A7.3 ∥ M7.3 (nếu chưa có), rồi A7.4 ∥ M7.4.
  4. SP4: S7.1d; A7.5 ∥ M7.5, cùng A7.7b ∥ M7.7b.
  5. T7.1.
- Mỗi sub-project kết thúc bằng một lượt đo trên S25 + Mac rồi mới mở sub-project sau: SP1 đo AC1 (rảnh và khi có
  tải), AC2, scan response; SP2 đo AC6.
- *Bỏ 2026-10-28:* SP5 (A7.6 ∥ M7.6) và quy tắc "nếu RFCOMM cần bond thì SP5 chuyển lên trước SP1" — lớp mang RFCOMM
  cần bond giờ coi là không đạt G7 (xem mục Lớp mang ở trên).
- Mỗi bước logic một commit, `shared/` trước nền tảng, không bao giờ một commit trải qua hai repository.

## Kiểm thử

- **Test viết trước** (theo từng thẻ, commit ở trạng thái đỏ trước code): vector từ S7.1a–d; test hồi quy cho phần code mà
  thẻ đó refactor (`serveRelayPeer`, CLIP-03 qua `/v1/ctl`, `ConnectionStateMachine`); rồi hành vi mới; rồi các
  trường hợp đối kháng.
- **Cổng hồi quy** sau mỗi thẻ:
  - Android: `./gradlew check`.
  - Apple: `swift test` trong các package bị đụng, `xcodebuild test` cho các target app.
  - Hub: `python3 tools/docs/validate_design_docs.py` và `tools/docs/check_bilingual_docs.py`.
  - Shared: `check_schemas.py`, `check_strings.py`.
- **Thiết bị thật:** S25 Ultra + Mac này (macOS 27) cho X và Y khi ở gần nhau, thêm một Mac chạy macOS 13 hoặc 14 và một điện thoại
  Android 10–12 để kiểm hộp thoại và việc nhận biết Wi-Fi rảnh; số đo AC lấy từ `BenchLog` và các sự kiện bench của
  S7.1.

## Rủi ro và phương án lùi

- **G7 thất bại (không lớp mang nào đạt AC1) → dừng Phase 7, và không có đường dự phòng:** relay không được deploy
  (quyết định của chủ dự án 2026-10-28), nên sản phẩm chỉ còn LAN và kịch bản X, Y vẫn "không kết nối được". Báo chủ dự
  án kèm số đo của G7.
- **Bảo mật:** kẻ tấn công trong tầm BLE có thể thử nhái máy quảng bá, phát lại hello, chiếm slot ghép đôi hoặc giả lỗi
  pre-auth → được che bởi lớp bảo mật link, chính sách admission cho Bluetooth và quy tắc pre-auth theo route (AC8, AC9),
  và được test đối kháng trong T7.1. (Rủi ro bond đứng sau AC10 không còn, vì đã bỏ SP5.)
- One UI bóp BLE khi chạy nền → dùng đường page-scan cổ điển hoặc một thông báo "ở gần" hiển thị; đo ở G7.
- IOBluetooth dễ vỡ → đặt lớp mang sau điểm cắm `MessageChannel` / `WebSocketSession`; lùi về BLE.
- macOS hỏi người dùng khi join, hoặc tự quay về mạng khác → Wi-Fi Direct chỉ là cơ hội; ảnh lùi về Bluetooth; AC3
  trong X báo cáo theo số đo thực.
- *Bỏ 2026-10-28:* "upload qua relay bằng dữ liệu di động quá chậm" (không có relay).
- Mỗi sub-project phát hành sau một cài đặt (`link.bluetooth`, `link.direct_wifi`, tên chốt trong D7.1; bỏ
  `link.auto_bond` cùng SP5) để có thể tắt mà không cần ra bản mới.

## Đánh giá red team

### Phiên — 2026-10-01

**Phát hiện:** 15 sau khi gộp từ 18 (chấp nhận 15, bác 0) · **Mức:** 2 Critical, 9 High, 4 Medium · Reviewer: Kẻ tấn
công bảo mật (kiểm sự thật), Kẻ phá giả định (kiểm phạm vi); bằng chứng đã được kiểm lại trong code.

| # | Phát hiện | Mức | Quyết định | Áp vào |
|---|---------|----------|-------------|------------|
| 1 | Lỗi pre-auth giả qua Bluetooth có thể hủy ghép đôi hoặc dừng nối lại (code Mac chỉ miễn cho `route == .relay`) | Critical | Chấp nhận | D7.1 (quy tắc route), M7.1a, AC8, T7.1 |
| 2 | Kịch bản X bị chặn: Mac chỉ rời `Idle` khi có mạng và bỏ mọi phiên khi mất mạng | Critical | Chấp nhận | D7.1 (0.11), M7.1a |
| 3 | BLE chưa bond làm lộ định danh, metadata và transcript ghép đôi; `pr` là định danh cố định | High | Chấp nhận | D7.1 (lớp bảo mật link, `pr` HMAC), AC9 |
| 4 | Admission pre-auth theo IP hay `device_id` không chạy trên BLE; hello phát lại được | High | Chấp nhận | D7.1 (admission), A7.1a |
| 5 | Tự ghép đôi đảo ngược AUDIO-01; phòng MITM dựa vào một khả năng chưa được chứng minh | High | Chấp nhận (chủ dự án: chỉ tự xác nhận khi đã kiểm mã, bỏ luồng (a)) | G7, D7.1, A7.6, M7.6, AC5, AC10 |
| 6 | Bulk qua relay không tách được kênh; nâng giới hạn là thừa; khóa stream không gắn theo kết nối | High | Chấp nhận | D7.1 (đóng khung bulk, khóa), R7.1 (chỉ test), A7.4, M7.4, AC3 |
| 7 | Trong Y, điện thoại không bao giờ lên relay khi đang có phiên Bluetooth | High | Chấp nhận | D7.1 (nhu cầu bulk), A7.4, M7.4 |
| 8 | Chưa có hạ tầng stream channel; chunk tới trước push bị bỏ | High | Chấp nhận | A7.3, M7.3, quyết định I9 của plan, A7.4, M7.4 |
| 9 | Điều khiển và bulk dùng chung một link Bluetooth không có ưu tiên; AC1 chưa bao giờ được đo khi có tải | High | Chấp nhận | D7.1 (channel id, bộ lập lịch, làn điều khiển), AC1, A7.1a, M7.1b |
| 10 | RFCOMM cần địa chỉ điện thoại hoặc bond trước SP1/SP2 | High | Chấp nhận | G7, thứ tự làm |
| 11 | "Wi-Fi rảnh" không tin được khi thiếu Location; deauth có thể đẩy Mac lên Wi-Fi Direct và giữ ở đó | High | Chấp nhận | G7, AC4, A7.5, M7.5, M7.7b, T7.1 |
| 12 | Ghép đôi offline qua BLE dễ bị chiếm slot; PIN chỉ bị chặn gián tiếp (2026-10-28: PIN nay chạy qua Bluetooth bằng CPace, chỉ dò được trực tuyến, 3 lần mỗi PIN cộng khóa tạm) | Medium | Chấp nhận | D7.1, A7.2, M7.2 |
| 13 | Bộ e2e không có đường vào ống Bluetooth trong app thật | Medium | Chấp nhận | A7.1b (shim debug), T7.1 |
| 14 | AC7 vỡ trên Android 10–12 vì Wi-Fi Direct cần Location | Medium | Chấp nhận (chủ dự án: nới AC7 cho Android 10–12) | AC7, A7.5, A7.7b |
| 15 | AC1 vô tình nới mục tiêu LAN; AC2 không đo được cho Bluetooth; thiếu tiêu chí bảo mật | Medium | Chấp nhận | AC1, AC2, AC8–AC10, S7.1a, G7, T7.1 |

*Ghi chú 2026-10-28:* phát hiện 5 (ghép đôi) và 6, 7 (bulk qua relay) không còn áp dụng — các thẻ chúng đã sửa nay bị
bỏ (Phiên xác thực 2). Phát hiện 10 giờ được giải bằng "RFCOMM cần bond thì không đạt G7". Bảng giữ nguyên.

### Quét nhất quán toàn plan

- Thay đổi quyết định: Bluetooth không dùng nguyên mô hình tin cậy của relay; giữ nguyên wire và giới hạn của relay; ghép
  đôi chỉ tự xác nhận khi mã đã kiểm qua E2E; Wi-Fi Direct chỉ theo nhu cầu; nới AC7 cho Android 10–12; mục tiêu văn bản
  trên LAN giữ < 50 ms; đánh số lại thẻ (hạ tầng stream A/M7.3, bulk A/M7.4, Wi-Fi Direct A/M7.5, ghép đôi A/M7.6, quyền
  A/M7.7).
- Đã kiểm: `plan.md` và `plan.vi.md` (dòng 7, gate G7, quyết định I9), file này và bản tiếng Anh, báo cáo brainstorm (đã
  ghi chú là bị thay thế một phần), README và `docs/project-roadmap*` (không còn khẳng định cũ). Mâu thuẫn chưa giải
  quyết: không có.

## Nhật ký xác thực (Validation Log)

### Phiên 1 — 2026-10-01
**Lý do:** `/ck:plan validate` sau vòng red team. **Số câu hỏi:** 4. Bước kiểm chứng: chỉ kiểm các tên mới xuất hiện sau
khi viết lại theo red team (mục Đánh giá red team đã có bằng chứng) — kiểm 8 khẳng định, đúng 8, sai 0, chưa kiểm 0;
mức Light.

#### Câu hỏi và trả lời

1. **[Giả định]** AC3 (ảnh 5 MB ≤ 2 s trong kịch bản X) mâu thuẫn với AC4 (Mac chỉ join Wi-Fi Direct khi đã có ảnh chờ,
   mà join mất 3–8 s). Gỡ thế nào?
   - Lựa chọn: Join sẵn khi an toàn (Wi-Fi Mac rảnh ≥ N giây và không thấy mạng quen) | Chỉ theo nhu cầu, nới AC3
   - **Trả lời:** Chỉ theo nhu cầu, nới AC3
   - **Lý do:** giữ quy tắc vào chống được deauth; ảnh đầu tiên trong X chịu thời gian join.
2. **[Phạm vi]** Khi Bluetooth đang tắt trên điện thoại hoặc Mac (nên không có liên kết gần), HandLive làm gì?
   - Lựa chọn: Nhắc một chạm khi cần | Im lặng
   - **Trả lời:** Nhắc một chạm khi cần
   - **Lý do:** không bật radio âm thầm được; một yêu cầu hệ thống, tối đa một lần mỗi ngày, chỉ khi không có LAN/relay.
3. **[Đánh đổi]** Khi ảnh chỉ còn đường Bluetooth (vài chục KB/s, ảnh 5 MB mất 1–4 phút), gửi thế nào?
   - Lựa chọn: Giới hạn 1 MiB, lớn hơn thì chờ đường tốt | Gửi đủ 10 MiB chạy nền | Không gửi ảnh qua Bluetooth
   - **Trả lời:** Khác — **Nhập tự do:** "không giới hạn dung lượng"
   - **Lý do:** ghi nhận là "không có giới hạn riêng cho Bluetooth"; giới hạn ảnh chung của CLIP-03 (10 MiB) vẫn áp
     dụng — đổi giới hạn đó là một quyết định của CLIP-03, nằm ngoài phase này.
4. **[Kiến trúc]** HandLive nên khởi động ghép đôi Bluetooth cho HFP (1 chạm trên điện thoại) vào lúc nào?
   - Lựa chọn: Khi bật tính năng âm thanh cuộc gọi | Ngay sau ghép đôi QR
   - **Trả lời:** Ngay sau ghép đôi QR
   - **Lý do:** gom mọi việc thiết lập vào một lần; các cặp đã có nhận một yêu cầu một lần khi tính năng ra mắt.

#### Quyết định đã xác nhận
- AC3: LAN ≤ 2 s; trong X ảnh đầu ≤ 10 s, các ảnh sau ≤ 2 s khi nhóm còn mở; Wi-Fi Direct vẫn chỉ theo nhu cầu.
- Bluetooth tắt: yêu cầu hệ thống một chạm (Android) / dòng trạng thái kèm nút mở cài đặt (Mac), chỉ khi không có
  LAN/relay, tối đa một lần mỗi ngày.
- Ảnh qua Bluetooth: không có giới hạn dung lượng riêng; bộ lập lịch giữ AC1 trong các lượt truyền dài.
- Ghép đôi HFP khởi động ngay sau ghép đôi QR. *(Không còn hiệu lực từ 2026-10-28: đã bỏ SP5, xem Phiên 2.)*

#### Ảnh hưởng tới các phần
- AC3, AC4 (ở lại cho các ảnh sau), AC7 (yêu cầu bật Bluetooth), A7.4 (10 MiB qua Bluetooth), A7.6 (thời điểm), A7.7,
  M7.7 (xử lý khi Bluetooth tắt), T7.1 (kịch bản mới); dòng 7 của `plan.md` và tiêu chí trong `docs/project-roadmap*`.

### Quét nhất quán toàn plan
- Đã tìm trong mọi file plan, roadmap và ghi chú của báo cáo brainstorm các cụm "2 s … offline", "theo nhu cầu", "ghép
  đôi", "Bluetooth tắt"; đã sửa dòng 7 trong `plan.md`/`plan.vi.md`, `docs/project-roadmap*`, ghi chú brainstorm. Mâu
  thuẫn chưa giải quyết: không có.

### Phiên 2 — 2026-10-28 (quyết định của chủ dự án)
**Lý do:** chủ dự án báo HandLive không dùng được khi một máy mất mạng; lead hỏi ba câu (chat của đội, 2026-10-28).
**Số câu hỏi:** 3.

#### Câu hỏi và trả lời (nguyên văn câu trả lời của chủ dự án)

1. Chủ dự án đang gặp trường hợp nào? — Lựa chọn: Mac/iPhone mất mạng hẳn, điện thoại có 4G | Điện thoại mất mạng, Mac
   có mạng | Hai máy cùng Wi-Fi nhưng Wi-Fi đó không có Internet | Điện thoại dùng 4G, Mac ở một Wi-Fi khác | Cả hai
   đều không có mạng
   - **Trả lời:** «Cả hai đều không có mạng».
2. Muốn đi hướng nào? — Lựa chọn: Ngắn hạn: deploy relay + hướng dẫn bật hotspot / ứng viên gateway | Chỉ hotspot, chưa
   deploy relay | Mở lại Phase 7 BLE ngay, bỏ qua điều kiện G4/G5/G6 | Chỉ cần báo cáo, chưa làm gì
   - **Trả lời:** «Mở lại Phase 7 BLE ngay, bỏ qua điều kiện G4/G5/G6».
3. Nếu deploy relay: đã có VPS, khóa APNs, dự án Firebase (FCM) chưa? — Lựa chọn: Có đủ, sẽ gửi | Chưa có, đội viết
   hướng dẫn chuẩn bị | Không deploy relay
   - **Trả lời:** «Không deploy relay».

#### Quyết định đã xác nhận
- Mục tiêu là kịch bản X (cả hai offline); Y chỉ phủ khi hai máy ở gần nhau, qua Bluetooth.
- Phase 7 bắt đầu ngày 2026-10-28; bỏ quy tắc ngày 2026-10-01 "chỉ bắt đầu sau G4, G5 và G6".
- Phase này không relay: bỏ R7.1, đường relay, phần relay AC1/AC3, A7.4/M7.4 và D7.1.
- Phase 4 đã dừng (2026-10-12) → bỏ SP5 (A7.6/M7.6), AC5, AC10, câu hỏi ghép đôi, phép đo "trong cuộc gọi HFP" của G7; câu 4 Phiên 1 vô hiệu.
- Thứ tự: T7.0 → D7.1 → S7.1 → SP1 (kèm A7.7/M7.7) → SP2 → SP3 → SP4 → T7.1; tạo thẻ nền tảng sau G7.

#### Ảnh hưởng tới các phần
- File này (mục tiêu, trạng thái, G7, AC1/AC3/AC5/AC8/AC10, định tuyến, D7.1, S7.1, M7.1, R7.1, A7.4, M7.4, A7.6, M7.6,
  A7.7, T7.1, thứ tự làm, rủi ro); trạng thái, dòng 7, dòng ước lượng công và gate G7 trong `plan.md`/`plan.vi.md`;
  dòng 7 và mục Phase 7 trong `docs/project-roadmap*`.
- Rủi ro đã chấp nhận: nếu G7 thất bại thì không có relay dự phòng; sản phẩm chỉ còn LAN.

### Tách thẻ — 2026-10-28 (quyết định của Lead, chat của đội)
- Bộ lập lịch (điều khiển trước bulk) thuộc về làn điều khiển (điều kiện 1 của G7): chuyển từ A7.4/M7.4 sang
  A7.1a/M7.1b. Envelope điều khiển dài (tới 256 KiB, khoảng 20 s chiếm sóng) có làn dài riêng trong 0.4.5, nên không
  bao giờ làm một envelope ngắn chờ quá ngưỡng AC1.
- SP1 tách thành M7.1a → A7.1a ∥ M7.1b → A7.1b ∥ M7.1c; S7.1 tách thành S7.1a–d, mỗi thẻ cho một sub-project;
  primitive CPace thành thẻ riêng A7.2a/M7.2a; A7.7/M7.7 tách phần Bluetooth (SP1) và phần Location (SP4); thêm T7.0a
  (probe scan response) trước khi chốt vector quảng bá.
- `ssid`/`passphrase` Wi-Fi Direct sinh ngẫu nhiên cho mỗi group (0.4.6): S7.1d và A7.5 kiểm định dạng và bộ ký tự,
  không có vector suy khóa.
