[English](phase-07-ket-noi-moi-noi.md) | Tiếng Việt

# Phase 7 — Kết nối mọi nơi

**Mục tiêu:** sau lần ghép đôi QR đầu tiên, điện thoại và Mac tự kết nối với nhau ở bất cứ đâu — cả hai offline (kịch
bản X), hoặc điện thoại dùng dữ liệu di động còn Mac dùng Wi-Fi công cộng (kịch bản Y) — không có bước mạng thủ công nào
và **không máy nào phải rời hay đổi Wi-Fi hiện tại**.
- Khi không có LAN, một liên kết Bluetooth đã được bảo mật chở kênh điều khiển.
- Một làn dữ liệu lớn chở ảnh qua đường nhanh nhất được phép: LAN, Wi-Fi Direct (chỉ theo nhu cầu, khi Wi-Fi của Mac
  đang rảnh), relay, Bluetooth.
- HandLive cũng tự khởi động ghép đôi Bluetooth cổ điển cho HFP, và Mac chỉ tự xác nhận khi mã đã được kiểm đầu-cuối.

Trạng thái: chủ dự án đề xuất ngày 2026-10-01 (thiết kế trong `reports/phase-07-brainstorm.md`, nghiên cứu trong
`reports/research-direct-wifi-link-2026-10-01.md`); sửa lại cùng ngày sau vòng red team (mục cuối file). **Chỉ bắt
đầu sau khi đóng các gate G4, G5 và G6** (quyết định của chủ dự án 2026-10-01). Lập theo kiểu viết test trước: mọi thẻ
triển khai viết test trước khi viết code.

## Gate G7 — spike (khoảng một tuần, trước mọi thẻ việc khác)

Câu hỏi: lớp mang Bluetooth nào đạt mục tiêu giữa một điện thoại Samsung và một Mac; bảo mật liên kết Bluetooth thế nào;
có kiểm được việc ghép đôi đầu-cuối không; Mac có dùng nhóm Wi-Fi Direct của điện thoại một cách an toàn được không; và
tốn bao nhiêu?
- **Lớp mang:**
  - So BLE L2CAP CoC (`listenUsingInsecureL2capChannel` ↔ `CBPeripheral.openL2CAPChannel`) với RFCOMM cổ điển
    (`listenUsingRfcommWithServiceRecord` ↔ `IOBluetoothDevice.openRFCOMMChannelSync`).
  - Đo độ trễ một chiều 1 KB (p50/p95), tốc độ 1 MB và 5 MB, thời gian nối lại — khi tắt màn hình 10 phút, khi Doze,
    khi đang có cuộc gọi HFP, và khi đang có một lượt truyền bulk.
  - **RFCOMM chỉ được coi là khả thi nếu chứng minh được cách để Mac tới được điện thoại trước khi có bond** (app
    Android không đọc được địa chỉ Bluetooth của chính nó; địa chỉ BLE là ngẫu nhiên). Nếu không, BLE chở SP1/SP2 và
    Bluetooth cổ điển chỉ dùng cho HFP.
- **Chạy nền:** A-SVC (foreground service `connectedDevice`) vẫn quảng bá và nhận kết nối trên One UI khi tắt màn hình;
  central trên Mac nối lại sau khi ngủ/thức.
- **Câu hỏi bảo mật:**
  - L2CAP CoC chưa bond có mã hóa tầng link không (dự kiến: không → lớp bảo mật link của D7.1 là bắt buộc).
  - Một sniffer BLE thấy gì khi có lớp bảo mật link bản thử.
  - macOS có giữ mạng `DIRECT-hl-…` trong danh sách mạng đã biết sau khi rời không, và có xóa được không.
- **Ghép đôi (cho HFP):** thử luồng (b) — điện thoại `createBond` tới địa chỉ Mac gửi qua E2E
  (`IOBluetoothHostController.addressAsString`) — và luồng (c) — suy khóa chéo từ một liên kết BLE đã bond. **Bỏ luồng
  (a)** (bật chế độ cho phép tìm thấy), vì nó phát tên thiết bị và cho phép giả tên. Kiểm tra app Android có đọc được mã
  ghép đôi (`ACTION_PAIRING_REQUEST`) mà không cần quyền hệ thống không; kiểm tra `replyUserConfirmation` trên Mac.
- **Wi-Fi Direct:**
  - S25 tạo nhóm tự trị với SSID `DIRECT-hl-…` cố định, trong lúc điện thoại vẫn giữ Wi-Fi của mình (STA + P2P).
  - Mac join bằng CoreWLAN từ bản đã notarize, có hardened runtime, đã được cấp quyền Location (entitlement
    `com.apple.security.personal-information.location`).
  - Ghi lại: thời gian join; các hộp thoại xuất hiện; macOS có tự quay về mạng khác không.
  - **Tiêu chí đạt:** phân biệt đúng "đang kết nối hay rảnh" và "nhóm của mình hay mạng khác", trên macOS 27 và trên
    macOS 13 hoặc 14, có quyền Location, đo từ chính app (không phải từ CLI).
  - Không dùng `networksetup` với passphrase nằm trong danh sách tham số.
- **Kết quả** ghi vào `reports/phase-07-spike-g7.md`: lớp mang, luồng ghép đôi, cách join, bản thử lớp bảo mật link,
  các số đo so với AC1–AC10 (chủ dự án xác nhận hoặc chỉnh AC5 và AC6). **Không lớp mang nào đạt AC1 trên liên kết đã
  nối sẵn → dừng Phase 7** (giữ LAN + relay) và viết báo cáo.

## Bối cảnh

- Thiết kế: `reports/phase-07-brainstorm.md` (mục 3–8; một phần đã được thay thế bởi vòng red team bên dưới — file này
  là bản có hiệu lực); nghiên cứu: `reports/research-direct-wifi-link-2026-10-01.md`.
- Kênh truyền hiện có:
  - common specs 0.4.1 (LAN, bắt buộc TLS — TLS còn che định danh và metadata); 0.4.3 (relay, TLS tới relay, `rv_id`
    cho rendezvous);
  - 0.6.3 (bắt tay phiên xác thực bằng `PRK`); 0.6.3 bước 7 (khóa stream, hiện chỉ có `camera`/`call-audio`);
  - 0.11 (máy trạng thái: chỉ rời `Idle` khi có mạng, mất mạng thì bỏ mọi phiên);
  - CONN-01 E4 và CONN-03 E9 (lỗi pre-auth: chỉ LAN có TLS ghim mới được hủy ghép đôi); PAIR-01; CLIP-03;
  - AUDIO-01 (quy tắc "không bao giờ tự ghép đôi Bluetooth thay người dùng" — đổi theo quyết định của chủ dự án, xem
    D7.1).
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
| AC1 | Envelope văn bản (văn bản bảng nhớ tạm; SMS và thông báo cuộc gọi đi cùng làn), từ lúc sao chép đến lúc dùng được, phân vị 95: **LAN < 50 ms (mục tiêu Phase 1, giữ nguyên)**; **Bluetooth ≤ 200 ms trên liên kết đã nối sẵn, kể cả khi đang có một lượt truyền bulk**; relay ở mức cố gắng tốt nhất |
| AC2 | Nối lại ≤ 3 s sau khi mạng thay đổi hoặc sau khi lại thấy thiết bị Bluetooth bên kia (sự kiện bench `bt_seen`/`bt_lost`) |
| AC3 | Ảnh 5 MB: ≤ 2 s trên LAN; trong X ảnh đầu tiên ≤ 10 s (gồm cả lúc join Wi-Fi Direct theo nhu cầu) và các ảnh sau ≤ 2 s khi nhóm còn mở; trong Y bị giới hạn bởi upload di động của điện thoại — giữ nguyên giới hạn relay (2 MiB/s mỗi cặp đã cao hơn uplink thông thường), đo và báo cáo; chỉ có Bluetooth: truyền nền, không có mục tiêu thời gian và không có giới hạn dung lượng riêng cho Bluetooth (áp giới hạn ảnh của CLIP-03) <!-- Updated: Validation Session 1 - AC3 relaxed for the first image in X; no size cap over Bluetooth --> |
| AC4 | Bất biến: không máy nào bị đổi hoặc mất kết nối Wi-Fi hiện tại. Mac chỉ join Wi-Fi Direct khi có ảnh đang chờ, Wi-Fi của nó đã không kết nối mạng nào trong ≥ `DIRECT_WIFI_IDLE_MIN`, và quét không thấy mạng quen nào; nó ở lại nhóm cho các ảnh tiếp theo và rời khi một lần quét định kỳ thấy mạng quen, hoặc sau `DIRECT_WIFI_MAX`; HandLive không bao giờ tự bật/tắt radio và không ở lại nhóm khi không có lý do |
| AC5 | Ghép đôi HFP do HandLive khởi động: ≤ 1 chạm trên điện thoại; Mac chỉ tự xác nhận khi mã ghép đôi khớp với mã nhận qua E2E, nếu không thì người dùng so một mã |
| AC6 | Ghép đôi lần đầu khi cả hai offline (QR qua BLE): ≤ 15 s từ lúc quét đến lúc ghép đôi xong (G7 xác nhận hoặc chỉnh) |
| AC7 | Chỉ còn các hộp thoại xin quyền một lần: Mac — Local Network, Bluetooth, Location; Android 12+ — Nearby devices; **Android 10–12 — thêm Location và bật dịch vụ vị trí, cho Wi-Fi Direct (quyết định của chủ dự án 2026-10-01)**; cộng các quyền đã có; cộng một yêu cầu hệ thống một chạm để bật Bluetooth khi không còn đường nào khác, tối đa một lần mỗi ngày <!-- Updated: Validation Session 1 - Bluetooth-off prompt --> |
| AC8 | Không thông điệp pre-auth nào trên một route không có TLS ghim tới điện thoại (Bluetooth, relay) được làm thay đổi trạng thái cặp, xóa cặp hay dừng việc nối lại |
| AC9 | Một sniffer BLE không thấy định danh cố định nào (`pair_id`, `device_id`, khóa, tên, `pr`) và không thấy `type`, `id` hay nhịp thời gian theo loại của envelope |
| AC10 | Không liên kết Bluetooth nào được tự xác nhận nếu chưa có mã ghép đôi đã kiểm qua E2E |

Quy tắc định tuyến (làn điều khiển LAN > Bluetooth > relay; làn dữ liệu lớn LAN > Wi-Fi Direct > relay > Bluetooth):

| Tình huống | Làn điều khiển | Làn dữ liệu lớn |
|---|---|---|
| Chung LAN | LAN | LAN |
| X, Wi-Fi Mac rảnh, có ảnh đang chờ | Bluetooth | Wi-Fi Direct (theo nhu cầu, quy tắc AC4), nếu không được thì Bluetooth (chạy nền) |
| X, Mac đang ở một Wi-Fi không có Internet | Bluetooth | Bluetooth (chạy nền) |
| Y, ở gần nhau | Bluetooth | Relay (lên relay khi có nhu cầu bulk, D7.1), nếu không được thì Bluetooth (chạy nền) |
| Ở xa, cả hai online | Relay | Relay |

## Thẻ việc

Mã chữ cái như mục 3 của plan, thêm **D** = tài liệu trong hub. Cột "Test viết trước" liệt kê những gì phải được viết
và commit (ở trạng thái đỏ) trước code của thẻ đó.

| Mã | Việc | Test viết trước | Đầu ra | Tiêu chí nghiệm thu |
|------|------|-------------|---------|---------------------|
| T7.0 [test] | Spike gate G7 (ở trên): probe dùng một lần trên Android và macOS | — (đo đạc) | `reports/phase-07-spike-g7.md`; probe chỉ ở nhánh spike, không bao giờ merge | Đã chọn lớp mang, luồng ghép đôi, cách join và bản thử lớp bảo mật link; đã đo các con số AC; chủ dự án xác nhận AC5/AC6 |
| D7.1 [docs] | Spec trước, cả hai ngôn ngữ. **0.11 và CONN:** điều kiện khởi động "có mạng hoặc Bluetooth đang bật và đã được cấp quyền"; mất mạng chỉ kết thúc phiên LAN/relay; chỉ phản ứng theo lỗi pre-auth trên route có TLS ghim tới điện thoại (`phoneAuthenticatedByTLS`), viết lại CONN-01 E4 và CONN-03 E9 theo quy tắc đó. **0.4.5 liên kết Bluetooth:** quảng bá (service UUID, gợi ý xoay vòng; đổi địa chỉ cùng lúc với gợi ý); lớp bảo mật link trước bất kỳ định danh nào (ví dụ bắt tay kiểu Noise khóa bằng `K_auth`, hoặc định danh mù hóa trên một nonce do điện thoại cấp) và một mã lỗi pre-auth chung; admission (trần toàn cục, một link pre-auth, nonce challenge từ điện thoại, lỗi xác nhận khóa tính như `AUTH_FAILED`); frame = channel id ‖ độ dài ‖ byte, điều khiển đi trước bulk, mảnh bulk vài KB, không có close code (kết thúc bằng `session/bye` đã mã hóa). **Ghép đôi qua BLE:** `pr` = HMAC(`ps`, …), frame đầu tiên có MAC bằng khóa từ `ps` trước khi cấp slot, một slot toàn cục với timeout ngắn, từ chối PIN theo loại transport. **Bulk:** bắt tay stream cho `bulk` với khóa riêng mỗi kết nối (`K_stream` + cả hai nonce); cả lượt truyền (push, chunk, ack) đi trên làn bulk; bulk nằm trong frame nhị phân HL có byte kênh đã mã hóa (không đổi wire của relay); op nhu cầu bulk và quy tắc giữ relay khi làn điều khiển đi Bluetooth. **Wi-Fi Direct (0.4.6):** suy SSID/passphrase (passphrase ≥ 128 bit), quy tắc vào/ra của AC4, xóa mạng đã lưu sau khi rời, socket HandLive chỉ gắn vào giao diện P2P. **Ghép đôi (AUDIO-01, quyết định của chủ dự án 2026-10-01):** HandLive được khởi động ghép đôi; Mac chỉ tự xác nhận khi mã đã kiểm qua E2E; trao địa chỉ chỉ theo chiều Mac → điện thoại; cập nhật lời giải thích cho người dùng. Cộng: hằng số, khóa cài đặt, mã lỗi, SET-01/02/03, leaf CONN-05/CONN-06, PAIR-01, CLIP-03 | — (hợp đồng; vector của S7.1 là test của nó) | `docs/detailed-design/*.md` + `.vi.md` | `validate_design_docs.py` in `problems=0`; `check_bilingual_docs.py` xanh; mọi loại message, mã lỗi, hằng số và chuỗi mới được định nghĩa trước khi viết code; AC8–AC10 truy được về các quy tắc trong spec |
| S7.1 [shared] | Dữ liệu hợp đồng: test vector — bắt tay lớp bảo mật link, codec frame có channel id, service data quảng bá, HMAC `pr`, SSID/passphrase Wi-Fi Direct, khóa `bulk` riêng mỗi kết nối, việc gắn mã ghép đôi; JSON schema cho các op mới; chuỗi giao diện; sự kiện bench `bt_seen`/`bt_lost`/`wifi_assoc` và trigger cho chúng trong `reconnect_time.py` | Chính các vector và mẫu âm là test: generator tạo ra, `check_*` kiểm tra | `shared/test-vectors/`, `shared/schemas/`, `shared/tools/` (gồm `bench/`), `shared/strings/` | Generator tái tạo được; `check_schemas.py`, `check_strings.py` xanh; báo các nền tảng khác chạy lại test |
| A7.1 [android] | Liên kết Bluetooth cho làn điều khiển: bộ quảng bá trong A-SVC, server cho lớp mang chọn ở G7, lớp bảo mật link, admission cho Bluetooth, `BluetoothPeerSocket` (`WebSocketSession` ảo như `RelayPeerSocket`) phục vụ qua `ControlServer.serveBluetoothPeer`, codec frame có channel id; một **shim loopback chỉ có ở bản debug** cho bộ e2e | Test hồi quy cho `serveRelayPeer`; test vector codec và lớp bảo mật link; test qua ống giả: bắt tay, rekey, hello bị phát lại, địa chỉ xoay vòng, trần pre-auth; test bản release khẳng định không có shim | `android/core/transport`, `android/feature/connection`, `android/app` | Mọi test xanh; phủ các ngoại lệ của CONN-05; đo AC1 (Bluetooth) trên S25 |
| M7.1 [macOS] | Liên kết Bluetooth cho làn điều khiển: central (CoreBluetooth hoặc IOBluetooth theo G7), lớp bảo mật link, `BluetoothChannel: MessageChannel`, đường `.bluetooth`; thay đổi 0.11 (khởi động khi không có mạng, mất mạng theo từng route, `phoneAuthenticatedByTLS` thay cho `route == .relay`); ưu tiên LAN > Bluetooth > relay có nâng cấp; các `switch` theo route trong các package giao diện | Đỏ trước: `networkLost` khi đang `connected(.bluetooth)` vẫn giữ kết nối; `idle(noNetwork)` + thấy thiết bị bên kia → đang kết nối; `PAIR_UNKNOWN`/`PAIR_REVOKED`/`UNSUPPORTED_VERSION`/`AUTH_FAILED` giả mạo trước khi xác thực qua Bluetooth không bao giờ hủy ghép đôi hay dừng nối lại; vector codec; test kênh trong bộ nhớ | `apple/Packages/HLTransport`, `apple/Packages/HLMacUI`, `apple/Packages/HLiOSUI`, `apple/macOS/HandLive` | Mọi test xanh; bản iOS build và chạy như cũ; đo AC1 (Bluetooth), AC2, AC8 |
| A7.2 [android] | Ghép đôi lần đầu khi offline: quảng bá `pr` (dạng HMAC) trong chế độ QR; chỉ cấp slot ghép đôi duy nhất sau một frame đầu có MAC `ps` hợp lệ; PAIR-01 qua liên kết Bluetooth đã bảo mật; từ chối PIN qua Bluetooth một cách tường minh | Vector PAIR-01 qua ống giả; test âm: PIN qua Bluetooth, MAC frame đầu thiếu/sai, chiếm giữ slot, người thứ hai tranh slot | `android/feature/pairing`, `android/core/transport` | Phủ các ngoại lệ PAIR-01 qua Bluetooth; đo AC6 |
| M7.2 [macOS] | Ghép đôi lần đầu khi offline: quét `pr`, thử lần lượt mọi ứng viên có cùng `pr`, chạy PAIR-01 qua `BluetoothChannel` đã bảo mật, rồi ghim và lưu như hiện nay | Cùng bộ vector; timeout, `pr` sai, máy quảng bá giả có đúng `pr` | `apple/Packages/HLTransport` (`Pairing*`) | Đo AC6; không đổi định dạng QR |
| A7.3 [android] | Hạ tầng stream channel: server `/v1/stream/*` trên A-SVC (`stream_hello`/`stream_welcome`, 0.6.3 bước 7) — **dùng lại nếu một thẻ sản phẩm của Phase 4 hoặc 5 đã xây trước** (quyết định I9 của plan) | Test vector bắt tay stream (viết trước) | `android/core/transport`, `android/core/crypto` | Bắt tay stream chạy trên LAN; `camera`/`call-audio` không bị ảnh hưởng |
| M7.3 [macOS] | Client stream channel, cùng phạm vi và quy tắc dùng lại như A7.3 | Như A7.3 | `apple/Packages/HLTransport` | Như A7.3 |
| R7.1 [relay] | Xác nhận relay chở bulk mà không cần sửa: frame nhị phân `HR` cỡ bulk với giới hạn hiện có; không đổi wire hay giới hạn | Test chuyển tiếp cho frame `HR` cỡ bulk (đỏ nếu relay xử lý sai) | Chỉ test trong `relay/` | `cargo test`, `cargo clippy` xanh; không đổi `wire.rs` hay giới hạn |
| A7.4 [android] | Làn bulk: stream `bulk` với khóa riêng mỗi kết nối; cả lượt truyền CLIP-03 đi trên làn bulk; chọn đường theo bảng định tuyến; bulk qua relay là frame nhị phân HL đã mã hóa, được tách trong `RelayPeerMux`; op nhu cầu bulk và quy tắc giữ relay (cả hai flavor, foss không có FCM); bộ lập lịch Bluetooth ưu tiên frame điều khiển | Hồi quy CLIP-03 qua `/v1/ctl` trước; rồi đỏ: chunk tới trước push, bulk qua relay tới phiên bulk chứ không tới phiên điều khiển, lên relay khi có nhu cầu bulk trong lúc làn điều khiển đi Bluetooth, AC1 khi đang truyền bulk 5 MB, một ảnh 10 MiB chỉ qua Bluetooth vẫn truyền xong ở chế độ nền | `android/core/transport` (gồm `relay/`), `android/feature/clipboard` | Các ngoại lệ CLIP-03 qua trên mọi đường; AC1 (LAN) không đổi; AC3 (LAN) không đổi |
| M7.4 [macOS] | Làn bulk phía Mac, cùng phạm vi với A7.4 (tách trong `RelayLink`/`RelayPeerChannel`, điểm cắm `ClipboardPeer`) | Cùng thứ tự như A7.4 | `apple/Packages/HLTransport`, `apple/Packages/HLAppCore` (bảng nhớ tạm) | Như A7.4 |
| A7.5 [android] | Host Wi-Fi Direct (chỉ X, theo nhu cầu): nhóm với SSID/passphrase suy ra, `LEGACY_OR_R2` trên API 36, bật/tắt theo yêu cầu qua làn điều khiển, giữ nguyên STA; `NEARBY_WIFI_DEVICES` (13+), `ACCESS_FINE_LOCATION` + dịch vụ vị trí (10–12); Wi-Fi tắt → báo, không bao giờ tự bật | Vector suy khóa; test vòng đời với `WifiP2pManager` giả (bật, dừng, sập, STA không đổi, dừng sau `DIRECT_WIFI_MAX`) | `android/feature/connection` (hoặc `feature/directlink` mới) | Kiểm AC4 trên S25; đo AC3 trong X |
| M7.5 [macOS] | Join Wi-Fi Direct (chỉ X): quy tắc vào/ra của AC4 (theo nhu cầu, rảnh ≥ `DIRECT_WIFI_IDLE_MIN`, không thấy mạng quen, quét định kỳ, `DIRECT_WIFI_MAX`), join bằng CoreWLAN, kết nối gateway bằng chứng chỉ đã ghim, socket gắn vào giao diện P2P, xóa mạng đã lưu sau khi rời | Đỏ trước: không bao giờ join khi đang kết nối, không bao giờ join khi thấy mạng quen (trường hợp deauth), rời khi thấy mạng quen, rời khi hết thời gian tối đa, đã xóa mạng đã lưu | `apple/Packages/HLTransport`, `apple/macOS/HandLive` | Kiểm AC4, gồm cả kịch bản deauth; AC3 trong X ≤ 2 s |
| A7.6 [android] | Tự ghép đôi Bluetooth cổ điển, **khởi động ngay sau khi ghép đôi QR** (và một lần cho các cặp đã có khi tính năng ra mắt, hoặc bất cứ khi nào thiếu bond) <!-- Updated: Validation Session 1 - bonding trigger -->, luồng từ G7 ((b) hoặc (c)): yêu cầu ghép đôi qua E2E, `createBond` tới địa chỉ Mac nhận qua E2E, gửi mã ghép đôi qua E2E khi đọc được | Test với adapter giả cho từng trạng thái; không bao giờ ghép đôi khi chưa có phiên đã xác thực; không yêu cầu chế độ cho phép tìm thấy | `android/feature/call` hoặc `android/feature/connection` | Đo AC5, AC10; phủ đường bị từ chối và timeout |
| M7.6 [macOS] | Tự ghép đôi Bluetooth cổ điển: `IOBluetoothDevicePair`; chỉ tự xác nhận khi mã khớp với mã E2E, nếu không thì hiện mã để người dùng so một lần; giao thiết bị đã bond cho stack HFP | Test quyết định xác nhận/từ chối với delegate giả (khớp, không khớp, thiếu mã) | `apple/Packages/…` (âm thanh cuộc gọi), `apple/macOS/HandLive` | AC5, AC10; không khớp hoặc thiếu mã thì không bao giờ tự xác nhận |
| A7.7 [android] | Luồng xin quyền (chủ sở hữu AC7 trên Android): SET-01 xin Nearby devices (12+), Location + dịch vụ vị trí (10–12, cho Wi-Fi Direct), có màn hình giải thích trước; yêu cầu bật Bluetooth (`ACTION_REQUEST_ENABLE`) chỉ khi không có đường LAN hay relay, tối đa một lần mỗi ngày | Test đếm số hộp thoại theo từng mức API (29, 31, 33, 37) | `android/app`, `android/feature/connection` | AC7 theo từng mức API |
| M7.7 [macOS] | Luồng xin quyền (chủ sở hữu AC7 trên Mac): màn hình giải thích Bluetooth và Location (SET-03), `NSBluetoothAlwaysUsageDescription`, lời giải thích dùng Location, entitlement `com.apple.security.personal-information.location`, bước ký bản release; dòng trạng thái khi Bluetooth tắt kèm nút mở cài đặt Bluetooth, cùng quy tắc với A7.7 | Test trình tự hộp thoại; kiểm entitlement trên bản release | `apple/macOS/HandLive`, `apple/macOS/HandLive.entitlements`, `docs/deployment-guide.md` (qua D) | AC7 trên Mac; Location chạy được trong bản đã notarize |
| T7.1 [test] | Ma trận đầu-cuối: X và Y với S25 + Mac, chung LAN, ở xa; tắt màn hình, ngủ/thức, tắt Bluetooth, tắt Wi-Fi điện thoại, từ chối Location, relay sập. **Đối kháng:** máy quảng bá nhái, sniff BLE (AC9), hello bị phát lại, lỗi pre-auth giả (AC8), chiếm giữ slot ghép đôi, deauth Wi-Fi của Mac (AC4), thử MITM khi ghép đôi (AC10). Thời gian ảnh đầu và ảnh sau trong X; một ảnh 10 MiB chỉ qua Bluetooth mà vẫn giữ AC1; tắt Bluetooth ở từng phía. Đếm hộp thoại trên Android 10–12; tiếng Anh và tiếng Việt; TalkBack/VoiceOver | Viết trước các kịch bản `shared/tools/e2e` đi qua shim debug của A7.1 | `shared/tools/e2e/`, `reports/phase-07-T7.1.md` | Đạt AC1–AC10; ghi lại kết nối Wi-Fi trước/sau trên cả hai máy từ log debug của app |

## Nhánh và thứ tự làm

- Nhánh `feat/phase-07-connect-anywhere` trong hub, handlive-shared, handlive-android, handlive-apple (và
  handlive-relay chỉ cho test R7.1).
- T7.0 làm trước và làm riêng (sau G4/G5/G6). Rồi D7.1 → S7.1 (mọi thẻ nền tảng chờ spec, vector và chuỗi).
- Sau đó theo thứ tự sub-project:
  1. SP1: A7.1 ∥ M7.1, cùng A7.7 ∥ M7.7 cho các hộp thoại Bluetooth
  2. SP2: A7.2 ∥ M7.2
  3. SP3: A7.3 ∥ M7.3 (nếu chưa có), R7.1, rồi A7.4 ∥ M7.4
  4. SP4: A7.5 ∥ M7.5
  5. SP5: A7.6 ∥ M7.6 (sau các thẻ sản phẩm HFP của Phase 4)
  6. T7.1
- **Nếu G7 chọn RFCOMM và RFCOMM cần bond, SP5 chuyển lên trước SP1** và không chờ Phase 4 nữa.
- Mỗi bước logic một commit, `shared/` trước nền tảng, không bao giờ một commit trải qua hai repository.

## Kiểm thử

- **Test viết trước** (theo từng thẻ, commit ở trạng thái đỏ trước code): vector từ S7.1; test hồi quy cho phần code mà
  thẻ đó refactor (`serveRelayPeer`, CLIP-03 qua `/v1/ctl`, `ConnectionStateMachine`, phần tách peer của relay); rồi
  hành vi mới; rồi các trường hợp đối kháng.
- **Cổng hồi quy** sau mỗi thẻ:
  - Android: `./gradlew check`.
  - Apple: `swift test` trong các package bị đụng, `xcodebuild test` cho các target app.
  - Relay: `cargo test` và `cargo clippy`.
  - Hub: `python3 tools/docs/validate_design_docs.py` và `tools/docs/check_bilingual_docs.py`.
  - Shared: `check_schemas.py`, `check_strings.py`.
- **Thiết bị thật:** S25 Ultra + Mac này (macOS 27) cho X và Y, thêm một Mac chạy macOS 13 hoặc 14 và một điện thoại
  Android 10–12 để kiểm hộp thoại và việc nhận biết Wi-Fi rảnh; số đo AC lấy từ `BenchLog` và các sự kiện bench của
  S7.1.

## Rủi ro và phương án lùi

- G7 thất bại (không lớp mang nào đạt AC1) → dừng Phase 7; LAN + relay vẫn là lời giải của sản phẩm.
- **Bảo mật:** kẻ tấn công trong tầm BLE có thể thử nhái máy quảng bá, phát lại hello, chiếm slot ghép đôi hoặc giả lỗi
  pre-auth → được che bởi lớp bảo mật link, chính sách admission cho Bluetooth và quy tắc pre-auth theo route (AC8, AC9),
  và được test đối kháng trong T7.1. Một liên kết Bluetooth được xác nhận mà không kiểm mã sẽ làm lộ âm thanh cuộc gọi
  → AC10.
- One UI bóp BLE khi chạy nền → dùng đường page-scan cổ điển hoặc một thông báo "ở gần" hiển thị; đo ở G7.
- IOBluetooth dễ vỡ (chung rủi ro với HFP) → đặt lớp mang sau điểm cắm `MessageChannel` / `WebSocketSession`; lùi về
  BLE.
- macOS hỏi người dùng khi join, hoặc tự quay về mạng khác → Wi-Fi Direct chỉ là cơ hội; ảnh lùi về Bluetooth hoặc
  relay; AC3 trong X báo cáo theo số đo thực.
- Upload qua relay bằng dữ liệu di động quá chậm → AC3 trong Y báo cáo theo số đo thực (đã chấp nhận).
- Mỗi sub-project phát hành sau một cài đặt (`link.bluetooth`, `link.direct_wifi`, `link.auto_bond`, tên chốt trong
  D7.1) để có thể tắt mà không cần ra bản mới.

## Đánh giá red team

### Phiên — 2026-10-01

**Phát hiện:** 15 sau khi gộp từ 18 (chấp nhận 15, bác 0) · **Mức:** 2 Critical, 9 High, 4 Medium · Reviewer: Kẻ tấn
công bảo mật (kiểm sự thật), Kẻ phá giả định (kiểm phạm vi); bằng chứng đã được kiểm lại trong code.

| # | Phát hiện | Mức | Quyết định | Áp vào |
|---|---------|----------|-------------|------------|
| 1 | Lỗi pre-auth giả qua Bluetooth có thể hủy ghép đôi hoặc dừng nối lại (code Mac chỉ miễn cho `route == .relay`) | Critical | Chấp nhận | D7.1 (quy tắc route), M7.1, AC8, T7.1 |
| 2 | Kịch bản X bị chặn: Mac chỉ rời `Idle` khi có mạng và bỏ mọi phiên khi mất mạng | Critical | Chấp nhận | D7.1 (0.11), M7.1 |
| 3 | BLE chưa bond làm lộ định danh, metadata và transcript ghép đôi; `pr` là định danh cố định | High | Chấp nhận | D7.1 (lớp bảo mật link, `pr` HMAC), AC9 |
| 4 | Admission pre-auth theo IP hay `device_id` không chạy trên BLE; hello phát lại được | High | Chấp nhận | D7.1 (admission), A7.1 |
| 5 | Tự ghép đôi đảo ngược AUDIO-01; phòng MITM dựa vào một khả năng chưa được chứng minh | High | Chấp nhận (chủ dự án: chỉ tự xác nhận khi đã kiểm mã, bỏ luồng (a)) | G7, D7.1, A7.6, M7.6, AC5, AC10 |
| 6 | Bulk qua relay không tách được kênh; nâng giới hạn là thừa; khóa stream không gắn theo kết nối | High | Chấp nhận | D7.1 (đóng khung bulk, khóa), R7.1 (chỉ test), A7.4, M7.4, AC3 |
| 7 | Trong Y, điện thoại không bao giờ lên relay khi đang có phiên Bluetooth | High | Chấp nhận | D7.1 (nhu cầu bulk), A7.4, M7.4 |
| 8 | Chưa có hạ tầng stream channel; chunk tới trước push bị bỏ | High | Chấp nhận | A7.3, M7.3, quyết định I9 của plan, A7.4, M7.4 |
| 9 | Điều khiển và bulk dùng chung một link Bluetooth không có ưu tiên; AC1 chưa bao giờ được đo khi có tải | High | Chấp nhận | D7.1 (channel id, bộ lập lịch), AC1, A7.4 |
| 10 | RFCOMM cần địa chỉ điện thoại hoặc bond trước SP1/SP2 | High | Chấp nhận | G7, thứ tự làm |
| 11 | "Wi-Fi rảnh" không tin được khi thiếu Location; deauth có thể đẩy Mac lên Wi-Fi Direct và giữ ở đó | High | Chấp nhận | G7, AC4, A7.5, M7.5, M7.7, T7.1 |
| 12 | Ghép đôi offline qua BLE dễ bị chiếm slot; PIN chỉ bị chặn gián tiếp | Medium | Chấp nhận | D7.1, A7.2, M7.2 |
| 13 | Bộ e2e không có đường vào ống Bluetooth trong app thật | Medium | Chấp nhận | A7.1 (shim debug), T7.1 |
| 14 | AC7 vỡ trên Android 10–12 vì Wi-Fi Direct cần Location | Medium | Chấp nhận (chủ dự án: nới AC7 cho Android 10–12) | AC7, A7.5, A7.7 |
| 15 | AC1 vô tình nới mục tiêu LAN; AC2 không đo được cho Bluetooth; thiếu tiêu chí bảo mật | Medium | Chấp nhận | AC1, AC2, AC8–AC10, S7.1, G7, T7.1 |

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
- Ghép đôi HFP khởi động ngay sau ghép đôi QR.

#### Ảnh hưởng tới các phần
- AC3, AC4 (ở lại cho các ảnh sau), AC7 (yêu cầu bật Bluetooth), A7.4 (10 MiB qua Bluetooth), A7.6 (thời điểm), A7.7,
  M7.7 (xử lý khi Bluetooth tắt), T7.1 (kịch bản mới); dòng 7 của `plan.md` và tiêu chí trong `docs/project-roadmap*`.

### Quét nhất quán toàn plan
- Đã tìm trong mọi file plan, roadmap và ghi chú của báo cáo brainstorm các cụm "2 s … offline", "theo nhu cầu", "ghép
  đôi", "Bluetooth tắt"; đã sửa dòng 7 trong `plan.md`/`plan.vi.md`, `docs/project-roadmap*`, ghi chú brainstorm. Mâu
  thuẫn chưa giải quyết: không có.
