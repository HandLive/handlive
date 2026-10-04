# Nghiên cứu: Android ↔ Mac khi không chung mạng — Wi-Fi Direct, hotspot, BLE (2026-10-01)

Bản tiếng Việt của `research-direct-wifi-link-2026-10-01.md`, cùng cấu trúc và nội dung.

Báo cáo này tiếp nối session cloud `session_01QqwiGV7S1RZWgFATr95MYp` ("Android-Mac WiFi kết nối trực tiếp"). Chỉ đọc
được phần tóm tắt cuối của session đó (Chrome chỉ cho đọc màn hình), nên báo cáo kiểm chứng lại các kết luận và đóng
các câu hỏi còn mở. Phương pháp: đọc mã nguồn AOSP nhánh `main`, đặc tả và code HandLive, chạy probe CoreWLAN chỉ-đọc
trên Mac này (macOS 27.0, MacBookPro18,3), soi các SDK Xcode đã cài (macOS 27.0, iOS 27.0), và nguồn web. **Không có
điện thoại nào cắm vào** (`adb devices` trống) và Mac chỉ ra Internet qua Wi-Fi `en0`, nên không chạy thử join mạng (sẽ
cắt mạng của chính máy này).

## 1. Kết luận

Kịch bản của chủ dự án (xác nhận 2026-10-01): **X** — cả hai máy offline; **Y** — điện thoại dùng dữ liệu di động, Mac
dùng Wi-Fi công cộng.

- **Wi-Fi Direct là công cụ sai cho Y** và chỉ có lợi chút ít cho X. Trong Y, Mac phải rời Wi-Fi công cộng (chỉ có một
  radio) và mất Internet. Trong X thì chạy được, nhưng hotspot của chính điện thoại cho ra cùng một mạng LAN mà không
  cần code mới.
- **Y đã có thiết kế sẵn: relay (CONN-03).** Cả hai máy đều online; code relay đã merge (Phase 2) nhưng **chưa triển
  khai** (G2 / thông tin chủ dự án cần cung cấp), nên Y chưa chạy được trong bản beta hiện tại. Triển khai relay là cách
  gỡ nhanh nhất.
- **Về nguyên tắc, X đã chạy được ngay qua hotspot của điện thoại** (bật hotspot, có thể tắt dữ liệu di động; Mac join
  một lần, các lần sau tự join): A-SVC lắng nghe trên mọi giao diện, và Android 14+ quảng bá mDNS trên giao diện hotspot.
  Cần kiểm tra trên thiết bị (T1, T5), sau đó nhiều nhất là thêm ứng viên gateway vào CONN-01.
- **Cuộc gọi đã được chính Phase 4 lo:** HFP qua Bluetooth mang âm thanh cuộc gọi, nghe/kết thúc và số người gọi mà
  không cần mạng dữ liệu, trong cả X lẫn Y (khi qua được G4).
- **Kênh truyền mới duy nhất đáng làm spike là "liên kết gần" BLE** (L2CAP CoC), chở đúng các envelope như relay đang
  chở: tự động, chạy được trong **cả X lẫn Y mà không đụng đến mạng của máy nào**, đủ cho văn bản bảng nhớ tạm, SMS và
  thông tin cuộc gọi; ảnh bị giới hạn qua cơ chế thương lượng capability (vài chục KB/s).
- Độc lập với tất cả những điều trên: **quyền mạng cục bộ của Android 17** sẽ làm hỏng server LAN hiện tại khi
  targetSdk lên 37 (R2).
- Wi-Fi Direct chỉ còn là một bản "nâng băng thông" tùy chọn về sau, chỉ trong X (sau BLE), không bao giờ trong Y.

## 2. Đính chính cho session trước

| Nhận định cũ / điểm còn mở | Phát hiện | Bằng chứng |
|---|---|---|
| Flying Carpet cho thấy Wi-Fi Direct hoạt động thế nào | Flying Carpet dùng **LocalOnlyHotspot**, không phải Wi-Fi Direct; các lỗi trên Xiaomi/MIUI/HarmonyOS là lỗi của LOHS. Dự án dùng **GPL-3.0** → không tái dùng code được trong HandLive (Apache-2.0) | README của FlyingCarpet; cây mã nguồn (`ViewController.swift` import CoreWLAN + CoreLocation) |
| "`192.168.49.1` có giống nhau trên mọi hãng không?" | Không bảo đảm. AOSP chỉ dùng `192.168.49.1/24` khi hãng bật `config_tether_enable_legacy_wifi_p2p_dedicated_ip` (mặc định **false**); nếu không, `RoutingCoordinator.requestDownstreamAddress` chọn một dải private. Phải đọc `WifiP2pInfo.groupOwnerAddress`, hoặc phía Mac đọc gateway của mạng vừa join | `IpServer.java` (`LEGACY_WIFI_P2P_IFACE_ADDRESS`, `shouldUseWifiP2pDedicatedIp()`), `TetheringConfiguration.java` (mặc định `false`) |
| "mDNS có chạy trong nhóm Wi-Fi Direct không?" | Với stack mDNS của module Connectivity (mặc định từ Android 14), một đăng ký không chỉ định `Network` sẽ mở socket trên mọi mạng đang hoạt động, **cộng thêm** giao diện local-only (LOHS), giao diện tethering (hotspot) và giao diện Wi-Fi P2P. HandLive đăng ký không gọi `setNetwork` → dịch vụ sẽ được quảng bá trên tất cả các giao diện đó. Android 10–13 (mdnsresponder native) chưa kiểm chứng | `MdnsSocketProvider.requestSocket(null)`; `NsdMdnsRegistrar.kt` (không có `setNetwork`) |
| "CoreWLAN trên macOS 13+ cần quyền gì?" | Đo trên macOS 27: chưa cấp quyền Location thì `scanForNetworks` trả về các mạng với **SSID và BSSID nil**; `ssid()` nil; `networksetup -getairportnetwork` báo "not associated"; `ipconfig getsummary` hiện `<redacted>`. Vì vậy muốn chọn đúng `CWNetwork` để gọi `associate(to:password:)` thì cần quyền Location ("Allow While Using"). Từ 15.1, tiến trình dòng lệnh có thể vẫn bị ẩn SSID dù đã cấp quyền; app có giao diện với run loop chạy liên tục thì được (Apple DTS) | probe bên dưới; Apple forum 769950 |
| Sandbox / App Store cho CoreWLAN | Không phải trở ngại: app Mac ký Developer ID + notarize, **không chạy sandbox** (`macOS/HandLive.entitlements` không có `app-sandbox`; deployment guide) | entitlements, `docs/deployment-guide.md` |

Kết quả probe (macOS 27.0, trạng thái quyền Location `notDetermined`):

```text
iface: en0  security: 4  channel: 157 band=5GHz width=40MHz
ssid(): nil  bssid(): nil
scan count: 10 withSSID: 0
```

## 3. Các sự thật khác đã kiểm chứng

- **F1 — Quyền mạng cục bộ của Android 17 (ảnh hưởng chế độ LAN hiện nay).** App target SDK 37 cần quyền runtime
  `ACCESS_LOCAL_NETWORK` (nhóm `NEARBY_DEVICES`) cho kết nối TCP đi ra LAN, **chấp nhận kết nối TCP đi vào**, UDP
  multicast (mDNS) và phân giải tên `.local`; thiếu quyền thì gói tin bị bỏ âm thầm (kết nối timeout, `EPERM`). App
  target < 37 có quyền `INTERNET` được cấp ngầm. Thử trước trên Android 16 (opt-in): `adb shell am compat enable
  RESTRICT_LOCAL_NETWORK <pkg>` + khởi động lại; quyền truy cập trở lại khi cấp `NEARBY_WIFI_DEVICES`. HandLive đang
  target 35 (`app/build.gradle.kts:30`) nên hiện chưa sao, nhưng khi nâng lên 37 thì server và NSD của A-SVC sẽ hỏng
  nếu SET-01 không xin quyền "Nearby devices". Ngoại lệ dùng bộ chọn NSD (`FLAG_SHOW_PICKER`) không áp dụng được vì
  điện thoại là server. Hệ quả phụ: Wi-Fi Direct/LOHS cần `NEARBY_WIFI_DEVICES`, cùng nhóm → trên Android 17+ chế độ
  trực tiếp không thêm hộp thoại xin quyền mới; trên Android 10–12 nó cần `ACCESS_FINE_LOCATION` và phải bật dịch vụ
  vị trí.
- **F2 — Wi-Fi Aware chỉ có trên iOS/iPadOS.** SDK macOS 27.0 có `WiFiAware.framework`, nhưng mọi khai báo cấp cao nhất
  (25/25) đều là `@available(macOS, unavailable)`; `swiftc` trên Mac này từ chối `WAPairedDevice` ("unavailable in
  macOS"). Trên iOS 26+ nó cần ghép đôi qua hệ thống (`WAPairedDevice`); iOS 26.4 thêm
  `WAConnection.deriveSharedSecret(for: .tlsPSK …)`. Chỉ là phương án tương lai cho app iOS (vốn là hạng hai); phía
  Android cần Wi-Fi Aware pairing (Android 14+). Chưa nghiên cứu thêm.
- **F3 — HandLive đã khớp sẵn với một liên kết trực tiếp.** A-SVC lắng nghe trên `0.0.0.0` (`ControlServer.kt:45`);
  TLS được ghim bằng SHA-256 của chứng chỉ và **không kiểm tra hostname** (0.4.1); Mac vốn đã thử một ứng viên
  `host:port` thô trước khi dùng mDNS (đường nhanh `last_host`, `ConnectionManager+Run.swift:75-82`). Một liên kết
  trực tiếp chỉ cần thêm một host ứng viên.
- **F4 — Chế độ PCC (API 36).** `WifiP2pConfig.Builder.setPccModeConnectionType`: `LEGACY_ONLY`, `LEGACY_OR_R2`,
  `R2_ONLY` (chỉ thiết bị R2). Mac join như một client WPA2 kiểu cũ → không bao giờ dùng `R2_ONLY`. Passphrase 8–63
  ký tự.
- **F5 — `networksetup -setairportnetwork en0 <ssid> <pass>`** được báo là vẫn join được trên Sonoma/Sequoia mà không
  cần đọc SSID (chỉ `-getairportnetwork` bị vô hiệu). Chưa kiểm chứng trên macOS 27; nếu chạy được thì tránh được hộp
  thoại xin quyền Location.
- **F6 — Các dự án tương tự.** NearDrop: chỉ Wi-Fi LAN (việc nâng cấp sang Wi-Fi Direct/hotspot của Quick Share không
  hỗ trợ trên macOS). KDE Connect: đã có backend Bluetooth, bật mặc định ở các bản gần đây. LocalSend: chỉ LAN. Không
  dự án nào chạy Wi-Fi Direct với Mac.
- **F7 — BLE L2CAP CoC.** Android API 29+ (`listenUsingInsecureL2capChannel`, khớp minSdk 29) ↔ CoreBluetooth
  `openL2CAPChannel`; kênh insecure tương thích chéo được, kênh secure được báo là chập chờn. Tốc độ thực tế từ vài chục
  đến ~100 KB/s: đủ cho văn bản bảng nhớ tạm, SMS, thông tin cuộc gọi; quá chậm cho ảnh 5 MB hay camera.

## 4. Liên kết trực tiếp thực sự giải quyết vấn đề gì?

| # | Tình huống | Hiện nay (beta) | Phương án tốt nhất |
|---|---|---|---|
| **X** | **Cả hai offline** (chủ dự án) | Không có gì | Ngay bây giờ: **hotspot điện thoại (A)** với dữ liệu di động tắt. Tiếp theo: **liên kết gần BLE (D)**, tự động. Về sau, tùy chọn: Wi-Fi Direct để nâng băng thông cho ảnh (B) |
| **Y** | **Điện thoại dùng dữ liệu di động, Mac dùng Wi-Fi công cộng** (chủ dự án) | Không có gì — relay chưa triển khai | Ngay bây giờ: **triển khai relay (G)**; hoặc người dùng chuyển Mac sang hotspot điện thoại (A). Tiếp theo: **BLE (D)**, không cần relay hay dữ liệu di động. Không bao giờ dùng B/C (Mac sẽ mất Wi-Fi công cộng) |
| S1 | Chung Wi-Fi, mDNS chạy | LAN (CONN-01) | — |
| S2 | Chung Wi-Fi nhưng cách ly client / chặn mDNS (khách sạn, văn phòng, mạng khách) | Không có gì cho đến khi triển khai relay | Relay; BLE khi ở gần |
| S3 | Điện thoại dùng di động, Mac không có mạng nào | Không có gì | Hotspot (A): Mac có Internet *và* một mạng LAN chung với điện thoại |
| S5 | Camera/micro (P5) khi không chung LAN | Đã lên kế hoạch USB | **USB (E)**; liên kết Wi-Fi Direct sẽ cắt Internet của cuộc gọi video |

Theo từng tính năng trong X và Y:

| Tính năng | X (cả hai offline) | Y (di động + Wi-Fi công cộng) |
|---|---|---|
| Âm thanh cuộc gọi, nghe/kết thúc, số người gọi | HFP qua Bluetooth (Phase 4, G4) — không cần mạng dữ liệu | Như X |
| Thông báo/thông tin cuộc gọi (CALL-04) | Hotspot hoặc BLE | Relay, hotspot hoặc BLE |
| SMS | Hotspot hoặc BLE | Relay, hotspot hoặc BLE |
| Văn bản bảng nhớ tạm | Hotspot hoặc BLE | Relay, hotspot hoặc BLE |
| Ảnh bảng nhớ tạm (≤ 10 MiB) | Hotspot (BLE quá chậm; về sau nâng cấp Wi-Fi Direct) | Relay (giới hạn 2 MiB/s, tốn dữ liệu di động) hoặc hotspot |
| Camera/micro | USB | USB |

## 5. Các phương án

| Phương án | Mac giữ được Internet | App Android tự điều khiển | Mac join bằng | Băng thông | Chi phí |
|---|---|---|---|---|---|
| A. Hotspot điện thoại (người dùng bật chia sẻ mạng) | **Có** (qua di động) | Không — app bên thứ ba không bật/tắt được tethering | Người dùng, một lần; macOS tự join các mạng đã biết | Wi-Fi | Thấp: kiểm chứng + ứng viên gateway |
| B. Wi-Fi Direct, GO tự trị | Không (trừ khi có Ethernet) | Có, đặt được SSID/passphrase (API 29+) | CoreWLAN + quyền Location, hoặc `networksetup` | Wi-Fi, không qua AP trung gian | Cao: spec mới, cả hai app, hay rớt (macOS tự quay lại Wi-Fi có Internet) |
| C. LocalOnlyHotspot | Không | Có, nhưng SSID/passphrase ngẫu nhiên | Như B, phải gửi thông tin đăng nhập | Wi-Fi | Cao; một số hãng không hỗ trợ (Xiaomi/HarmonyOS) |
| D. BLE L2CAP | Có — không máy nào phải đổi mạng | Có | CoreBluetooth | vài chục KB/s | Trung bình–cao: kênh truyền mới + đóng khung dữ liệu |
| E. USB adb forward (0.4.2) | Có | không áp dụng | giao thức adb host | Cao nhất | Đã lên kế hoạch (P5); phải bật USB debugging |
| F. Wi-Fi Aware | Có (chạy song song) | Có | — | Wi-Fi | **Không thể trên Mac** (F2) |
| G. Relay (CONN-03) | Có | Có | Internet ở cả hai máy | 2 MiB/s mỗi cặp | Code đã merge; **chưa triển khai** (VPS, APNs, FCM) |

Chỉ **D** phục vụ được cả hai kịch bản của chủ dự án một cách tự động mà không đổi mạng nào; **A** phục vụ được cả hai
ngay hôm nay nhưng phải bật tay; **G** chỉ phục vụ Y; **B/C** chỉ phục vụ X.

## 6. Đề xuất

Thứ tự: R0–R2 không cần kênh truyền mới; R3 là kênh truyền mới; R4 là tùy chọn.

- **R0 — Triển khai relay (Y, S2).** Đã thiết kế và merge; đang chờ thông tin từ chủ dự án (`phase-02-merge.md`: host
  relay và pin, khóa APNs, Firebase). Lưu ý về Wi-Fi công cộng: captive portal chặn relay cho đến khi người dùng đăng
  nhập (CONN-02 đã có cơ chế thử lại khi đường mạng thay đổi); relay chạy cổng 443, hiếm khi bị chặn.
- **R1 — Hotspot điện thoại là lời giải không cần code cho X (và là lựa chọn của người dùng trong Y).**
  1. Kiểm chứng trên S25 (T1, T5): hotspot bật được khi **tắt dữ liệu di động** (kiểm tra entitlement của nhà mạng có
     thể từ chối), Mac thấy được `_handlive._tcp`, và A-SVC nhận kết nối trên giao diện tethering.
  2. Chỉ khi T1/T2 cho thấy có lỗ hổng: thêm ứng viên thứ ba vào bước 2 của CONN-01 là **gateway mặc định của đường
     Wi-Fi trên Mac** (`NWPath.gateways`), đi qua cùng TLS ghim chứng chỉ (timeout 1–2 s). Ứng viên này che được trường
     hợp mDNS của Android 10–13 bỏ qua giao diện tethering, và trường hợp dải địa chỉ hotspot đổi theo mỗi phiên; về
     sau nó cũng phục vụ luôn B/C (gateway *chính là* điện thoại).
  3. Trải nghiệm: thông báo E3 trên Mac ("Đặt cả hai thiết bị trên cùng một mạng Wi-Fi…") gợi ý thêm hotspot của điện
     thoại; Android có nút "Mở cài đặt hotspot" (app bên thứ ba không bật/tắt được tethering); tôn trọng
     `NWPath.isExpensive` khi gửi ảnh.
- **R2 — Quyền mạng cục bộ của Android 17 (độc lập, áp dụng cho mọi tính năng LAN).** Thêm `ACCESS_LOCAL_NETWORK` vào mô
  hình quyền và luồng giới thiệu SET-01 trước khi lên targetSdk 37; thử ngay trên S25 (Android 16) bằng cờ compat (T3).
  Ghi vào `00-common-specs` và deployment guide.
- **R3 — Liên kết gần BLE: spike trước, rồi viết spec (X và Y, tự động, không đổi mạng).**
  - Kênh truyền: A-SVC trên Android là BLE peripheral (quảng bá + `listenUsingInsecureL2capChannel`, minSdk 29 đáp
    ứng); Mac là central (`CBPeripheral.openL2CAPChannel`). PSM được công bố trong một GATT characteristic (hoặc trong
    service data).
  - Khám phá và quyền riêng tư: một service UUID cố định của HandLive (giống `_handlive._tcp` cố định) cộng với **gợi ý
    xoay vòng mỗi giờ** của 0.4.1 nằm trong service data; Android tự ngẫu nhiên hóa địa chỉ BLE.
  - Bảo mật: **dùng lại mô hình tin cậy của relay** — không ghép đôi Bluetooth, dùng L2CAP insecure, rồi chạy bắt tay
    phiên 0.6.3 (HMAC từ PRK + X25519 tạm thời), vốn chưa bao giờ dựa vào TLS. Lỗi xảy ra trước khi bắt tay xác thực
    xong theo quy tắc CONN-03 E9 (không bao giờ hủy ghép đôi).
  - Đóng khung: các frame có tiền tố độ dài trên luồng L2CAP, chở envelope dạng văn bản hoặc frame nhị phân HL (giống
    lớp bọc của relay nhưng bỏ phần định tuyến).
  - Băng thông: khai báo giới hạn thấp hơn trong `capability/hello` cho phiên BLE (tắt ảnh hoặc đặt `max_image_bytes`
    nhỏ; không có luồng âm thanh cuộc gọi/camera); cơ chế bật/tắt theo tính năng hiện có đã xử lý được việc này.
  - Ưu tiên: vẫn giữ quy tắc mỗi cặp chỉ có một phiên `/v1/ctl`; LAN > relay > BLE, tự nâng cấp khi có đường tốt hơn
    (như CONN-02 đang làm cho relay → LAN). Chủ dự án có thể muốn ưu tiên BLE hơn relay trong Y để tiết kiệm dữ liệu di
    động.
  - Quyền: Android 12+ cần `BLUETOOTH_ADVERTISE` + `BLUETOOTH_CONNECT` (nhóm "Nearby devices", cùng hộp thoại với R2);
    Android 10–11 chỉ cần quyền lúc cài đặt. Mac: hộp thoại xin quyền Bluetooth (TCC) mà HFP ở Phase 4 vốn đã cần.
  - Spike (T6): đo tốc độ và độ ổn định L2CAP giữa Android ↔ Mac, việc A-SVC quảng bá khi chạy nền trên One UI, và
    việc chạy song song với một cuộc gọi HFP đang diễn ra. Sau đó viết `00-common-specs` 0.4.5 + một leaf CONN trước
    khi viết code sản phẩm.
- **R4 — Tùy chọn về sau: nâng băng thông bằng Wi-Fi Direct, chỉ trong X** (mô hình của Quick Share: BLE trước, Wi-Fi
  cho dữ liệu lớn):
  - Chỉ khi Wi-Fi của Mac đang không kết nối mạng nào (X) — không bao giờ trong Y.
  - SSID `DIRECT-hl-<hint>` và passphrase được suy ra từ khóa của cặp, ví dụ `HKDF(PRK, info =
    "handlive/v1/direct-wifi" ‖ giờ)`: không cần trao đổi thông tin đăng nhập, không có gì cố định phát ra không khí, và
    một AP giả mạo không thể hoàn tất bắt tay 4 bước của WPA2. Liên kết BLE có thể yêu cầu điện thoại tạo nhóm.
  - Mac join (CoreWLAN + quyền Location, hoặc `networksetup`, T4) rồi kết nối tới gateway; dùng `LEGACY_OR_R2` trên
    API 36.
  - Wi-Fi Aware cho iPhone/iPad là một hạng mục nghiên cứu riêng (F2).

## 7. Kiểm tra trên phần cứng (chủ dự án + S25 + Mac này)

| # | Kiểm tra | Các bước | Đạt khi |
|---|---|---|---|
| T1 | Đường hotspot (an toàn: Mac vẫn online qua di động) | Bật hotspot trên S25, cho Mac join; `dns-sd -B _handlive._tcp`; `route -n get default`; `nc -vz <gateway> 47800`; mở HandLive | Thấy instance; cổng mở; HandLive kết nối mà không sửa code |
| T2 | Như T1 trên một điện thoại hoặc emulator Android 10–13 có tethering | Như T1 | Biết được có cần ứng viên gateway hay không |
| T3 | Diễn tập quyền mạng cục bộ của Android 17 trên Android 16 | `adb shell am compat enable RESTRICT_LOCAL_NETWORK <pkg>`; khởi động lại; kết nối từ Mac; rồi cấp quyền Nearby devices | Thất bại khi chưa có quyền, phục hồi khi cấp quyền |
| T4 | Wi-Fi Direct (chỉ khi làm R4; cần Ethernet trên Mac hoặc chấp nhận mất mạng một lúc) | App probe tạo nhóm với `DIRECT-hl-…` cố định; Mac join bằng `networksetup -setairportnetwork`; kết nối tới gateway | Join được mà không hỏi quyền Location; liên kết giữ được 30 phút; ghi nhận việc macOS tự quay lại Wi-Fi có Internet |
| T5 | Diễn tập kịch bản X | S25: tắt dữ liệu di động, tắt Wi-Fi, bật hotspot; Mac: join vào (Mac offline trong lúc thử) | Hotspot bật được khi không có dữ liệu; HandLive kết nối; văn bản + ảnh bảng nhớ tạm + SMS chạy được |
| T6 | Spike BLE (R3) | Cặp probe: peripheral Android + server L2CAP, central trên Mac; truyền 1 KB và 1 MB; tắt màn hình 10 phút; trong lúc có cuộc gọi HFP | Ghi lại tốc độ và tỉ lệ rớt; việc quảng bá khi chạy nền vẫn sống trên One UI |

## 8. Tài liệu cần sửa nếu chủ dự án đồng ý (chưa sửa gì)

- `docs/detailed-design/00-common-specs.md` (+ `.vi.md`): ghi chú ở 0.4.1 về hotspot/ứng viên gateway; thêm dòng
  `ACCESS_LOCAL_NETWORK` vào bảng quyền; sau T6, thêm 0.4.5 liên kết gần BLE (frame, quảng bá, PSM, giới hạn) và một
  trạng thái cho nó trong máy trạng thái 0.11.
- `docs/detailed-design/03-connectivity.md` (+ `.vi.md`): bước 2 (c) của CONN-01 cho ứng viên gateway, câu chữ E3/E7;
  sau T6, thêm một leaf mới cho liên kết BLE.
- `plans/20260925-implementation/plan.md` (+ `.vi.md`): một gate cho spike BLE bên cạnh G4–G6, nếu chủ dự án đồng ý.
- `docs/detailed-design/01-setup-settings.md` (+ `.vi.md`): SET-01 xin quyền Nearby devices trên Android 17+.
- `docs/deployment-guide.md` (+ `.vi.md`): điều kiện tiên quyết khi lên targetSdk 37.
- `shared/strings/ui-strings.json`: dòng trạng thái hotspot (en + vi).

## Nguồn

- [Android — Local network permission](https://developer.android.com/privacy-and-security/local-network-permission)
- AOSP Connectivity `main`: [`IpServer.java`](https://android.googlesource.com/platform/packages/modules/Connectivity/+/refs/heads/main/Tethering/src/android/net/ip/IpServer.java),
  [`TetheringConfiguration.java`](https://android.googlesource.com/platform/packages/modules/Connectivity/+/refs/heads/main/Tethering/src/com/android/networkstack/tethering/TetheringConfiguration.java),
  [`MdnsSocketProvider.java`](https://android.googlesource.com/platform/packages/modules/Connectivity/+/refs/heads/main/service-t/src/com/android/server/connectivity/mdns/MdnsSocketProvider.java)
- [WifiP2pConfig.Builder](https://developer.android.com/reference/android/net/wifi/p2p/WifiP2pConfig.Builder)
- [Apple forum 769950 — CoreWLAN trả SSID nil trên 15.1](https://developer.apple.com/forums/thread/769950);
  [Apple forum 787701 — macOS 26 không có Wi-Fi Aware](https://developer.apple.com/forums/thread/787701)
- SDK trên máy: swiftinterface của `WiFiAware.framework` trong `MacOSX27.0.sdk` / `iPhoneOS27.0.sdk`
- [Flying Carpet](https://github.com/spieglt/FlyingCarpet) (GPL-3.0), [NearDrop](https://github.com/grishka/NearDrop),
  [Backend Bluetooth của KDE Connect](https://www.phoronix.com/news/KDE-Connect-Bluetooth-Backend)
- [Apple forum 89644 — tốc độ L2CAP](https://developer.apple.com/forums/thread/89644);
  [Cross-platform offline-first apps with BLE](https://octet-stream.net/b/scb/building-cross-platform-offline-first-apps-with-ble.html)

## Câu hỏi còn mở

1. Chủ dự án: trong Y, liên kết BLE ở gần có nên được ưu tiên hơn relay (tiết kiệm dữ liệu di động, không gửi được ảnh)
   hay chỉ làm đường dự phòng?
2. Chủ dự án: mở gate spike BLE ngay bây giờ, hay chờ sau G4 (vì dùng chung quyền Bluetooth trên Mac và radio với HFP)?
3. Hotspot của S25 có bật được khi tắt dữ liệu di động không (entitlement của nhà mạng)? (T5)
4. Android 10–13 (mdnsresponder native) có quảng bá trên giao diện tethering không? (T2)
5. Samsung One UI có cách ly client hotspot với chính điện thoại không? (T1)
6. Chỉ khi làm R4: `networksetup -setairportnetwork` có join được trên macOS 27 mà không cần quyền Location không? (T4)

```text
Status: DONE_WITH_CONCERNS
Summary: Với hai kịch bản của chủ dự án (cả hai offline; điện thoại dùng di động + Mac dùng Wi-Fi công cộng), Wi-Fi
Direct bị loại khỏi vai trò đường chính: triển khai relay (Y), dùng hotspot điện thoại ngay (X), làm spike liên kết gần
BLE L2CAP cho cả hai, chuẩn bị quyền mạng cục bộ của Android 17.
Concerns/Blockers: chưa thử trên thiết bị (không có điện thoại cắm vào, Mac chỉ có Wi-Fi); tốc độ BLE giữa Android ↔ Mac
chưa đo.
```
