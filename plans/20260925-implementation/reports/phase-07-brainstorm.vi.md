---
type: brainstorm-report
date: 2026-10-01
status: approved-design
modes: none (không --html, không --wiki)
inputs:
  - plans/20260925-implementation/reports/research-direct-wifi-link-2026-10-01.vi.md
roadmap: sau khi đóng các gate G4, G5, G6 (quyết định của chủ dự án 2026-10-01)
---

# Brainstorm: "Kết nối mọi nơi" — Android ↔ Mac tự kết nối mà không đổi Wi-Fi

Bản tiếng Anh (bản chuẩn): `phase-07-brainstorm.md`.

> **Ghi chú (2026-10-01, sau vòng red team):** một phần thiết kế này đã được thay thế — liên kết Bluetooth cần lớp bảo mật link, chính sách admission và quy tắc pre-auth theo route của riêng nó (không dùng nguyên mô hình tin cậy của relay); không nâng giới hạn relay; ghép đôi chỉ tự xác nhận khi mã đã được kiểm qua E2E và bỏ luồng (a); Wi-Fi Direct chỉ bật theo nhu cầu; AC1 giữ mục tiêu LAN < 50 ms; AC7 được nới cho Android 10–12; thêm AC8–AC10; sau bước xác thực, AC3 trong X cho phép ảnh đầu ≤ 10 s và ghép đôi HFP khởi động ngay sau ghép đôi QR. Plan có hiệu lực là `../phase-07-ket-noi-moi-noi.vi.md`.

## 1. Tóm tắt

Chủ dự án muốn HandLive tự kết nối điện thoại với Mac ở mọi nơi, không có bước mạng thủ công nào, và **không máy nào
bao giờ phải rời mạng Wi-Fi đang dùng**. Thiết kế đã duyệt là một thang kênh truyền tự động, chia hai làn:
- **Làn điều khiển** (`/v1/ctl`: văn bản bảng nhớ tạm, SMS, cuộc gọi) đi LAN → Bluetooth → relay.
- **Làn dữ liệu lớn** mới (`/v1/stream/bulk`, ảnh) đi LAN → Wi-Fi Direct (chỉ khi Wi-Fi của Mac đang không kết nối
  mạng nào) → relay → Bluetooth.

Năm thành phần mới, chia thành các sub-project SP0–SP5, bắt đầu sau khi G4/G5/G6 đóng.

## 2. Đi từ vấn đề (problem first)

- **Lời giải chọn sẵn:** "tự mở host, tự connect" là điểm xuất phát của chủ dự án.
- **Vấn đề thật:** sau lần quét QR đầu tiên, HandLive phải tiếp tục chạy ở bất cứ đâu người dùng có mặt, không cần
  thao tác nào, và không bao giờ làm người dùng mất mạng đang dùng.
- **Phát biểu vấn đề:** người dùng di chuyển giữa nhà, văn phòng, quán cà phê và máy bay sẽ mất HandLive mỗi khi điện
  thoại và Mac không chung một LAN. Hiện chỉ LAN chạy được; relay đã merge nhưng chưa triển khai. Các cách gỡ tìm được
  đến giờ (hotspot, tự join Wi-Fi) hoặc cần thao tác tay, hoặc cắt Internet của Mac. Thành công là: trong kịch bản X và
  Y, các tính năng chạy mà không cần thao tác nào và không đổi Wi-Fi.
- **Ba cách nhìn đã cân nhắc:**
  - A — "vấn đề mạng": đưa hai máy vào chung một mạng (hotspot, Wi-Fi Direct). Bị loại khỏi vai trò đường chính: Mac
    chỉ có một radio Wi-Fi, join bất kỳ mạng nào của điện thoại cũng làm Mac rớt Wi-Fi hiện tại.
  - B — "vấn đề server": cho mọi thứ đi qua relay. Cần cho trường hợp ở xa, vô dụng khi cả hai offline.
  - C — "vấn đề ở gần": khi hai máy ở gần nhau, dùng một loại radio không đụng đến Wi-Fi (Bluetooth), và chỉ dùng
    Wi-Fi Direct khi Wi-Fi của Mac đang rảnh. **Được chọn**, kết hợp với B.
- **Mức bằng chứng:** trung bình — kịch bản sử dụng hằng ngày của chính chủ dự án (X, Y) cộng các giới hạn nền tảng đã
  kiểm chứng; chưa có dữ liệu người dùng.
- **Tiêu chí hủy:** nếu SP0 cho thấy Bluetooth giữa S25 và Mac không đạt mục tiêu 200 ms cho văn bản trên liên kết đã
  nối sẵn, hoặc việc quảng bá khi chạy nền trên One UI không sống được → lùi về chỉ dùng relay + LAN.

## 3. Yêu cầu (đã thống nhất)

**Kịch bản:** X — cả hai máy offline. Y — điện thoại dùng dữ liệu di động, Mac dùng Wi-Fi công cộng. Cộng thêm các
trường hợp hiện có: chung LAN và ở xa nhau.

**Tiêu chí nghiệm thu:**

| # | Tiêu chí |
|---|---|
| AC1 | Văn bản (bảng nhớ tạm; SMS và thông báo cuộc gọi đi cùng làn): **≤ 200 ms** từ lúc sao chép đến lúc dùng được trên máy kia, trên liên kết đã nối sẵn (LAN, Bluetooth; relay ở mức cố gắng tốt nhất) |
| AC2 | Nối lại **≤ 3 s** sau khi hai máy vào tầm với nhau hoặc khi mạng thay đổi |
| AC3 | Ảnh 5 MB: **≤ 2 s** trên LAN và trong X (giữ sẵn Wi-Fi Direct khi Wi-Fi Mac rảnh). Y: bị giới hạn bởi tốc độ upload di động của điện thoại; nâng giới hạn relay; đo và báo cáo. Chỉ có Bluetooth: truyền nền, không cam kết thời gian |
| AC4 | Không máy nào bị đổi hoặc mất kết nối Wi-Fi hiện tại; Mac chỉ join Wi-Fi Direct khi Wi-Fi của nó đang không kết nối mạng nào; HandLive không bao giờ tự bật/tắt radio |
| AC5 | Ghép đôi Bluetooth cho HFP do HandLive khởi động: mục tiêu tối đa 1 chạm trên điện thoại, 0 click trên Mac (xác nhận ở SP0) |
| AC6 | Ghép đôi lần đầu khi cả hai offline (QR qua BLE): mục tiêu ≤ 15 s từ lúc quét đến lúc ghép đôi xong (cần xác nhận) |
| AC7 | Chỉ còn các hộp thoại xin quyền một lần lúc thiết lập: Mac — Local Network, Bluetooth, Location; Android — Nearby devices (cộng các quyền đã có) |

**Trong phạm vi:** liên kết Bluetooth, ghép đôi lần đầu khi offline, tự ghép đôi HFP, nâng băng thông bằng Wi-Fi
Direct, làn dữ liệu lớn đa đường. **Ngoài phạm vi:** iPhone/iPad (Wi-Fi Aware), camera/micro (đi USB), vận hành relay.
**Các việc chạy song song, không thuộc phase này:** triển khai relay (thông tin cho G2), quyền `ACCESS_LOCAL_NETWORK`
của Android 17.

**Ràng buộc:** viết spec trước trong hub (`00-common-specs`, các leaf spec, song ngữ); chỉ dùng mã nguồn tương thích
Apache-2.0; minSdk 29, macOS 13+; E2E luôn bật; mỗi cặp chỉ một phiên `/v1/ctl`; chuỗi giao diện lấy từ catalog.

## 4. Các sự thật nền tảng quyết định thiết kế (đã kiểm chứng)

| Sự thật | Hệ quả | Bằng chứng |
|---|---|---|
| Mac có một radio Wi-Fi; macOS không có API Wi-Fi Direct/P2P cho thiết bị không phải của Apple; Wi-Fi Aware `unavailable` trên macOS 27 | Wi-Fi Direct chỉ dùng khi Wi-Fi của Mac đang rảnh | swiftinterface trong SDK; lỗi biên dịch của `swiftc` |
| Android giữ được Wi-Fi trong lúc làm host nhóm P2P (chạy song song STA + P2P); app không bật được tethering | Điện thoại làm host Wi-Fi Direct, không bao giờ là hotspot thật | API Android |
| CoreWLAN khi không có quyền Location: quét trả SSID nil, quét theo tên trả 0 kết quả kể cả với mạng đang kết nối | Mac muốn tự join cần quyền Location (đã chấp nhận) hoặc `networksetup` | probe trên Mac này, macOS 27 |
| Bắt tay phiên 0.6.3 xác thực bằng `PRK`, không bằng TLS | Bất kỳ ống byte nào (BLE, RFCOMM) cũng chở được `/v1/ctl`, như relay đang làm | `00-common-specs` 0.6.3 |
| SDK macOS 27: `IOBluetoothDevicePair` có `devicePairingUserConfirmationRequest:numericValue:` + `replyUserConfirmation:`; có `openRFCOMMChannelSync` và `openL2CAPChannelSync` cổ điển | Mac tự khởi động ghép đôi và tự xác nhận được | header của SDK |
| Android `setPairingConfirmation` cần quyền hệ thống | Ghép đôi cần ít nhất một chạm trên điện thoại | API Android |
| App không tự bật Wi-Fi được (API 29+) và không bật Bluetooth âm thầm được (API 33+) | Radio tắt → giảm chức năng, có thể hiện panel hệ thống một chạm | API Android |
| mDNS của AOSP quảng bá trên giao diện P2P/tethering (Android 14+); địa chỉ GO của P2P không cố định | Dùng gateway của mạng vừa join, không dùng `192.168.49.1` | AOSP `MdnsSocketProvider`, `IpServer` |

## 5. Các hướng đã đánh giá

| Hướng | Ưu điểm | Nhược điểm | Kết luận |
|---|---|---|---|
| 1. Thang đầy đủ (LAN → Bluetooth → relay; nâng băng thông bằng Wi-Fi Direct) | Đáp ứng X và Y mà không đổi mạng; mô hình đã được Quick Share chứng minh | Hai kênh truyền mới, đa đường | **Được chọn**, làm theo giai đoạn |
| 2. Chỉ Bluetooth + relay | Một kênh mới, không cần quyền Location | Không gửi ảnh nhanh khi cả hai offline (trượt AC3 trong X) | Loại vì AC3 |
| 3. Wi-Fi Direct host thường trực, không Bluetooth | Ít loại radio hơn | Tốn pin, vô dụng trong Y, vi phạm AC4 khi Mac đang có Wi-Fi, không có kênh báo hiệu | Loại |
| Hotspot / join tay | Không cần code | Có thao tác tay, Mac mất Wi-Fi | Loại (quy tắc của chủ dự án) |

## 6. Thiết kế cuối cùng

**Bất biến:** HandLive không bao giờ đưa một máy ra khỏi Wi-Fi hiện tại và không bao giờ tự bật/tắt radio.

**Định tuyến:**

| Tình huống | Làn điều khiển | Làn dữ liệu lớn (ảnh) |
|---|---|---|
| Chung LAN | LAN | LAN |
| X, Wi-Fi Mac rảnh | Bluetooth | Wi-Fi Direct (giữ sẵn suốt thời gian ở X), nếu không được thì Bluetooth chạy nền |
| X, Mac đang ở một Wi-Fi không có Internet | Bluetooth | Bluetooth chạy nền (Wi-Fi Mac không rảnh) |
| Y, hai máy ở gần nhau | Bluetooth | Relay (đã nâng giới hạn), nếu không được thì Bluetooth chạy nền |
| Chung Wi-Fi nhưng bị cách ly client, ở gần | Bluetooth | Relay |
| Ở xa, cả hai online | Relay | Relay |

Thứ tự ưu tiên của làn điều khiển: LAN > Bluetooth > relay (chủ dự án chọn Bluetooth trước relay để tiết kiệm dữ liệu
di động). Tự nâng cấp khi có đường tốt hơn, như CONN-02 đang làm cho relay → LAN.

**Các thành phần:**

1. **Liên kết Bluetooth (làn điều khiển).**
   - A-SVC trên Android quảng bá một service UUID cố định của HandLive, kèm gợi ý xoay vòng mỗi giờ (`h` của 0.4.1)
     trong service data. Mac quét, khớp gợi ý rồi tự nối.
   - Liên kết chở các frame có tiền tố độ dài (envelope dạng văn bản hoặc frame nhị phân HL — lớp bọc của relay nhưng
     bỏ phần định tuyến) và chạy bắt tay 0.6.3 không cần TLS.
   - Lỗi xảy ra trước khi xác thực không bao giờ dẫn tới hủy ghép đôi (quy tắc CONN-03 E9).
   - Lớp mang dữ liệu — **BLE L2CAP CoC hay RFCOMM cổ điển — chọn theo số đo của SP0.**
   - Liên kết được giữ thường trực khi không có phiên LAN (AC1/AC2).
2. **Ghép đôi lần đầu khi offline (QR qua BLE).**
   - Không đổi mã QR. Trong lúc ở chế độ ghép đôi QR, điện thoại quảng bá gợi ý `pr` (SHA-256 của `pk`) qua BLE.
   - Mac tìm thấy gợi ý đó và chạy PAIR-01 theo biến thể rendezvous (như khi đi qua relay, không TLS).
   - Ghép đôi bằng PIN vẫn chỉ dùng trên LAN.
3. **Tự ghép đôi Bluetooth cổ điển (HFP).**
   - Sau khi ghép đôi HandLive, nếu chưa có liên kết Bluetooth cổ điển, HandLive tự khởi động ghép đôi Bluetooth.
   - Mac dùng `IOBluetoothDevicePair` và tự xác nhận mã số, sau khi đối chiếu với mã điện thoại gửi qua kênh E2E.
   - Ba luồng sẽ thử ở SP0, chọn luồng đạt AC5:
     - (a) Mac khởi động, sau khi điện thoại bật chế độ cho phép tìm thấy;
     - (b) điện thoại khởi động tới địa chỉ Bluetooth của Mac (`IOBluetoothHostController.addressAsString`);
     - (c) suy khóa chéo (cross-transport key derivation) từ một liên kết BLE đã ghép đôi.
4. **Nâng băng thông bằng Wi-Fi Direct (chỉ trong X).**
   - Điều kiện: Wi-Fi của Mac đang không kết nối mạng nào và hai máy đang nối với nhau qua Bluetooth.
   - Làn điều khiển yêu cầu điện thoại làm host một nhóm: SSID `DIRECT-hl-<hint>`, passphrase
     `HKDF(PRK, "handlive/v1/direct-wifi" ‖ giờ)`, dùng `LEGACY_OR_R2` trên API 36.
   - Mac tự join (CoreWLAN với quyền Location), rồi kết nối tới gateway bằng chứng chỉ TLS đã ghim.
   - Nhóm được giữ suốt thời gian còn ở X (AC3), và bỏ ngay khi Wi-Fi của chính Mac kết nối vào mạng khác.
5. **Làn dữ liệu lớn đa đường.**
   - Kênh stream mới `/v1/stream/bulk`, khóa lấy từ `K_stream` (0.6.3 bước 7, kênh `bulk`), chở các envelope chia
     mảnh của bảng nhớ tạm như hiện nay.
   - Chạy qua LAN, Wi-Fi Direct, relay (frame nhị phân `HR`; nâng giới hạn tốc độ relay để đạt AC3) hoặc Bluetooth.
   - Cơ chế thương lượng capability cho máy bên kia biết đang có những đường bulk nào.

**Xử lý lỗi:**
- Bluetooth tắt → không có liên kết gần, chỉ dùng relay/LAN; trên Android có thể hiện lời nhắc bật một chạm, trên Mac
  hiện ghi chú trạng thái.
- Wi-Fi điện thoại tắt trong X → ảnh đi Bluetooth chạy nền; có thể hiện panel Wi-Fi một chạm.
- Mac từ chối quyền Location → không có Wi-Fi Direct, ảnh đi Bluetooth.
- Relay chưa triển khai → ảnh trong Y đi Bluetooth.

**Bảo mật và quyền riêng tư:**
- Không phát ra tên thiết bị hay định danh cố định: service UUID cố định + gợi ý đổi mỗi giờ, Android dùng địa chỉ
  ngẫu nhiên, SSID đổi mỗi giờ.
- Mọi thứ đều mã hóa đầu-cuối bằng khóa hiện có; L2CAP/RFCOMM insecure được xác thực bằng bắt tay phiên.
- Passphrase WPA2 của nhóm suy ra từ `PRK`, nên một AP giả mạo không hoàn tất được bắt tay 4 bước.
- Mã số khi ghép đôi Bluetooth được gắn với kênh E2E.
- Giới hạn tần suất các kết nối chưa xác thực.

**Quyền (một lần, đã chấp nhận):**
- Mac: Local Network, Bluetooth, Location.
- Android 12+: `BLUETOOTH_ADVERTISE`, `BLUETOOTH_CONNECT`, `BLUETOOTH_SCAN` nếu cần, `NEARBY_WIFI_DEVICES` (gộp chung
  một hộp thoại "Nearby devices").
- Android 10–12: `ACCESS_FINE_LOCATION` cho Wi-Fi Direct.

## 7. Sub-project và thứ tự (sau G4/G5/G6)

| SP | Nội dung | Phụ thuộc | Gate / đầu ra |
|---|---|---|---|
| SP0 | Spike: tốc độ/độ trễ BLE L2CAP so với RFCOMM giữa S25 ↔ Mac, quảng bá khi chạy nền trên One UI, chạy song song với cuộc gọi HFP, các luồng ghép đôi (a)(b)(c), Mac join Wi-Fi Direct (CoreWLAN + `networksetup`), mức tốn pin khi giữ nhóm | G4 đã đóng | Báo cáo spike; chọn lớp mang; xác nhận các con số AC |
| SP1 | Liên kết Bluetooth cho làn điều khiển + đường `.bluetooth` trong các máy trạng thái | SP0 | Spec 0.4.5 + leaf CONN, rồi code |
| SP2 | Ghép đôi lần đầu khi offline qua BLE | SP1 | Biến thể PAIR-01 |
| SP3 | Làn bulk `/v1/stream/bulk` đa đường (+ đổi giới hạn relay) | SP1 | Spec + thay đổi relay |
| SP4 | Nâng băng thông bằng Wi-Fi Direct (X) | SP3 | Spec + cả hai app |
| SP5 | Tự ghép đôi Bluetooth cổ điển cho HFP | SP0, các thẻ sản phẩm Phase 4 | Cập nhật 07-call-audio |

## 8. Rủi ro

| Rủi ro | Ảnh hưởng | Giảm thiểu |
|---|---|---|
| One UI bóp việc quảng bá BLE khi chạy nền | Trượt AC2 | Foreground service đã là `connectedDevice`; SP0 đo; page-scan cổ điển làm phương án thay thế |
| IOBluetooth là API cũ, dễ vỡ (chung rủi ro với HFP) | Không dùng được lớp mang cổ điển | SP0 so sánh với BLE; đặt lớp mang sau một interface, giống `CallAudioRelay` |
| macOS hỏi người dùng trước khi join mạng lạ, hoặc tự quay lại mạng khác | Trượt AC3 trong X | SP0 thử cả hai đường join; coi Wi-Fi Direct là cơ hội, không phải bảo đảm |
| Upload qua relay bằng dữ liệu di động quá chậm cho 5 MB | Trượt AC3 trong Y | Đã chấp nhận: Y bị giới hạn bởi uplink; báo cáo số đo thực tế |
| Đa đường làm trạng thái phức tạp hơn | Lỗi, chậm tiến độ | Làn bulk dùng lại cơ chế stream channel; vẫn giữ một phiên điều khiển cho mỗi cặp |
| Android không cho app thường đọc mã ghép đôi từ broadcast nếu thiếu quyền hệ thống | AC5 (phải so mã bằng mắt) | SP0 kiểm tra; phương án lùi: người dùng so mã một lần |

## 9. Kiểm chứng

Cho từng sub-project:
- Unit test cho frame và cho việc suy khóa (viết shared test vector trước).
- Mở rộng bộ e2e hiện có với một ống Bluetooth giả.
- Chạy trên thiết bị thật S25 + Mac này cho X và Y: đo AC1 và AC3 bằng bench log (`BenchLog`); kiểm AC4 bằng cách ghi
  lại trạng thái kết nối Wi-Fi trước và sau trên cả hai máy.

## 10. Tài liệu cần sửa (spec trước, chưa sửa gì)

- `00-common-specs`: 0.4.5 (liên kết Bluetooth), 0.4.6 (bulk qua Wi-Fi Direct), 0.6.3 bước 7 (kênh `bulk`), máy
  trạng thái 0.11.
- `02-pairing` (rendezvous qua BLE); `03-connectivity` (các leaf CONN mới); `04-clipboard` CLIP-03 (làn bulk);
  `07-call-audio` (ghép đôi Bluetooth); `01-setup-settings` (quyền).
- Giới hạn tốc độ relay; phase mới trong `plan.md`; chuỗi giao diện.

## 11. Bước tiếp theo

1. Đóng G4/G5/G6 (cần phần cứng của chủ dự án).
2. Đã lập plan: `plans/20260925-implementation/phase-07-ket-noi-moi-noi.vi.md` (viết test trước).
3. Song song: tiếp tục triển khai relay và quyền của Android 17.

## Câu hỏi còn mở

1. Ngưỡng AC5 và AC6 là đề xuất, chủ dự án chưa xác nhận rõ.
2. Khi một radio đang tắt, HandLive có nên hiện lời nhắc hệ thống một chạm (bật Bluetooth/Wi-Fi) hay im lặng?
3. Mục tiêu 200 ms có áp dụng cho cả SMS và thông báo cuộc gọi như văn bản bảng nhớ tạm không (đang giả định là có)?
4. Mức tốn pin chấp nhận được trên điện thoại khi giữ nhóm Wi-Fi Direct trong X (SP0 sẽ đo).
