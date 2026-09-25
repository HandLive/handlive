# Báo cáo A0.2 [android]: `core/transport` (WSS `/v1/ctl`, bắt tay phiên, capability, rekey)

Ngày: 2026-09-25 · Nhánh: `feat/phase-00-khung` · Chưa commit.

## Việc đã làm

- **WSS server** `ControlServer`: Ktor 3.6 engine **Netty** (giữ đúng 0.1), `sslConnector` **chỉ TLSv1.3**, tắt HTTP/2 và h2c (WebSocket chỉ cần HTTP/1.1, khỏi phụ thuộc ALPN trên Android), route duy nhất `/v1/ctl` (đường khác thì 404), `maxFrameSize` = 256 KiB. Cổng thử lần lượt 47800–47809, trả về cổng thực đang nghe (để Phase 1 quảng bá qua SRV). Chưa có mDNS, chưa nối UI hay service.
- **Khóa TLS** (0.4.1, 0.6.1): `SelfSignedCertificateGenerator` tự ghi DER X.509 v3 tối giản: ECDSA P-256, `ecdsa-with-SHA256` (không kèm tham số NULL), CN cố định `HandLive` (không lộ tên máy), hạn 20 năm (năm ≥ 2050 thì dùng GeneralizedTime). JCA không có API dựng chứng chỉ và Android không công khai BouncyCastle, nên mới phải tự ghi DER. `TlsIdentity` lưu dạng PKCS#12; `certificateSha256()` là giá trị client ghim.
  - Kho lưu tách ra interface `TlsIdentityStorage`. `InMemoryTlsIdentityStorage` dùng cho test JVM. `SecretStoreTlsIdentityStorage` giữ mật khẩu PKCS#12 trong `SecretStore`, còn file `.p12` ghi atomic qua file tạm. `AndroidTlsIdentityStorage.create(context)` nối vào `AndroidKeystoreSecretStore` (khóa `hl_master`, 0.2) và đặt file trong `noBackupFilesDir`. `TlsIdentityProvider.loadOrCreate` nạp khóa đã lưu, nếu chưa có thì sinh mới.
- **Bắt tay phía S** `ServerHandshake` (0.6.3 bước 1–3 và 8; CONN-01 API 4–6) là hàm thuần, khóa tạm và nonce truyền vào được nên test tất định. Thứ tự kiểm đúng CONN-01 API 4:
  1. `protocol` được đọc trước mọi trường khác. Khác major → `session/error UNSUPPORTED_VERSION` (`min_protocol: 1`) rồi đóng **4426**.
  2. Cấu trúc sai (JSON, uuid, b64u, độ dài) → đóng **4400**, không gửi `session/error`, vì enum của API 6 không có `BAD_REQUEST`.
  3. Cặp không tồn tại → `PAIR_UNKNOWN`, đóng **4401**.
  4. Cặp đã thu hồi → `PAIR_REVOKED`, đóng **4403**.
  5. `device_id` không khớp → `AUTH_FAILED`, đóng **4401**.
  6. `mac` sai (so sánh hằng thời gian, dùng lại `SessionHandshakeDerivation.verifyMac` / `HmacSha256`) → `AUTH_FAILED`, đóng **4401**.

  `eph` của client là điểm bậc thấp → `AUTH_FAILED`. Mỗi lần welcome sinh khóa tạm mới.
- **Kết nối** `ControlConnectionHandler`:
  - Toàn bộ bắt tay nằm trong `HANDSHAKE_TIMEOUT` 5 s, từ lúc mở kết nối đến khi giải mã được `capability/hello` của client. Quá hạn → đóng **4408**.
  - S gửi `welcome` rồi gửi ngay `capability/hello` đã mã hóa.
  - Envelope mã hóa đầu tiên từ C không giải mã được → **4401** (CONN-01 API 5). Giải mã được nhưng không phải `capability/hello` → **4400**.
  - Sau bắt tay: gặp `DECRYPT_FAILED` → **4400** (CONN-02 E5); `session/bye` → đóng 1000.
- **Máy trạng thái**: 0.11 là máy của client Mac/iOS (Discovering, Backoff, relay…). Android chỉ nhận kết nối nên không có các trạng thái đó. Đã cài phần phía S tương ứng là `ControlConnectionState` cho từng kết nối: `AWAITING_HELLO → AWAITING_CAPABILITY → ESTABLISHED → CLOSED`, xem qua `ControlSession.state` (StateFlow).
- **Một phiên cho mỗi cặp** (0.4.1, CONN-01 bước 7): `ActiveSessionRegistry`. Khi phiên mới đã xác nhận khóa, phiên cũ nhận `session/bye {reason: replaced}` đã mã hóa rồi bị đóng **4409**.
- **Capability** (0.7.2, CONN-01 API 7): `EffectiveFeatures.compute`. Tính năng F có hiệu lực khi `enabled` ở cả hai phía **và** Android không thiếu quyền bắt buộc của F (bảng CONN-01 API 7; chấp nhận cả tên quyền ngắn lẫn đầy đủ). Tính năng vắng mặt thì coi là tắt. `capability/update` thay toàn bộ ảnh chụp, không gộp. `capability.protocol` khác → 4426. `ControlSession.effectiveFeatures` (StateFlow) và `sendCapabilityUpdate()` để gửi `capability/update` khi cấu hình Android đổi.
- **Rekey** (0.6.3 bước 6, CONN-02 API 3) chạy cả hai vai:
  - `SessionCipher` quản lý khóa theo chiều, `epoch`, bộ đếm envelope mỗi chiều và tuổi khóa (ngưỡng 24 h / 10 000). Khóa nhận cũ còn dùng được 30 s.
  - `SessionRekeyCoordinator`: bên nhận `ack` bằng khóa cũ rồi mới đổi khóa; bên khởi tạo đổi khóa ngay khi nhận `ack`. `epoch` sai → `ack` lỗi `BAD_REQUEST`. Khi hai bên cùng khởi tạo, bên có `device_id` nhỏ hơn thắng.
  - `EncryptedEnvelopeChannel` gom mọi thao tác trên khóa dưới một `Mutex`. S tự khởi tạo rekey khi chạm ngưỡng; không có `ack` trong 10 s thì đóng phiên.
  - Dùng lại `SessionRekeyDerivation`, `SessionHandshakeDerivation`, `EnvelopeCipher`; không viết lại hàm mã hóa nào.
- **Envelope ứng dụng**: `ControlSession.send(type, plaintext)` mã hóa rồi gửi. Envelope đến có `type` khác `session`/`capability`/ack-của-rekey thì được giải mã và chuyển qua `ControlSession.inbound` cho mô-đun tính năng (Phase 1).
- **Không log**: mã `main` không gọi log nào. `CloseReason` chỉ chứa tên mã lỗi, không chứa nội dung.
- Không sửa `:core:protocol` hay `:core:crypto`; API có sẵn đã đủ.

## Giảm APK

Kích thước `app-debug.apk`:

| Đo | Kích thước | dex (chưa nén) |
|----|-----------|----------------|
| Đầu phiên (trạng thái A0.1, trước mọi thay đổi của A0.2 và phần Compose/font mới của A0.3) | 39 802 116 B | — |
| **Trước**: cùng cây mã ở thời điểm đo, bộ dependency của A0.1 (chỉ loại `netty-codec-native-quic`) | **45 878 133 B** | 44 404 896 B |
| **Sau**: bộ exclude của A0.2 | **41 977 711 B** | 40 507 268 B |
| Chênh lệch | **−3 900 422 B (−8,5 %)** | −3 897 628 B |

Hai dòng Trước/Sau được đo liền nhau trên cùng cây mã, mỗi lần chạy `:app:assembleDebug` rồi `:app:packageDebug --rerun`. Hai lần đo "Sau" cho cùng một số. Lưu ý khi đo: đóng gói debug của AGP là incremental và để lại khoảng trống trong zip, nên APK có nội dung giống hệt từng lệch tới 3,9 MB. Muốn so sánh thì phải đóng gói lại toàn bộ. Phần tăng từ 39,8 lên khoảng 42 MB là của A0.3 (Compose/material3, font) cộng mã transport.

Đã loại gì (trong `android/core/transport/build.gradle.kts`):
- `configurations.named("implementation") { exclude kotlin-reflect, com.typesafe:config }`. Hai thư viện này đến từ `ktor-server-core` qua ba đường (core, netty, websockets), nên exclude trên từng dependency không đủ. Chỉ áp cho `implementation`: lần đầu áp cho mọi configuration thì trình biên dịch Kotlin hỏng, vì nó cũng cần kotlin-reflect.
  - Đã kiểm bytecode: Ktor chỉ dùng kotlin-reflect ở chế độ phát triển (`developmentMode`, tự nạp lại module) và `call.receive<T>()`; typesafe config chỉ dùng cho HOCON từ file. Server này không dùng cả ba.
- Trên `ktor-server-netty`: `netty-codec-http3`, `netty-codec-classes-quic` (Ktor chỉ chạm tới khi bật `enableHttp3`), `netty-codec-protobuf`, `netty-codec-marshalling` (gói gom `netty-codec` 4.2 kéo vào), `alpn-api` của Jetty (ALPN cho JDK 8; server đã tắt HTTP/2).
- **Giữ** `netty-transport-classes-epoll/kqueue`: `EventLoopGroupProxy` gọi `Epoll.isAvailable()`/`KQueue.isAvailable()` vô điều kiện, bỏ đi là `NoClassDefFoundError`. Hai jar này không kèm `.so`.
- Kiểm trong dex (số type descriptor khác nhau, Trước → Sau): http3 141 → 9, quic 196 → 12, `kotlin/reflect/jvm/internal` 2291 → 0, typesafe config 184 → 6, protobuf 6 → 0, marshalling 15 → 0, jetty alpn 4 → 0. Phần còn sót chỉ là tham chiếu kiểu nằm trong lớp của Ktor, không phải lớp.
- Không làm hỏng Netty: test JVM chạy **server Netty thật** (TLS 1.3, bắt tay, rekey) trên đúng classpath đã loại (đã kiểm `debugUnitTestRuntimeClasspath`, `app` debug/release runtime classpath: 0 dòng kotlin-reflect, typesafe, http3, quic, protobuf, marshalling, alpn).
- `app/build.gradle.kts`, khối `packaging`: APK không còn tệp `.so` nào của Netty (chỉ còn `libandroidx.graphics.path.so` của Compose), nên không cần exclude `jniLibs`. Chỉ thêm một chú thích giải thích điều này. Đã thử exclude `META-INF/services/io.ktor.server.config.ConfigLoader` nhưng không có tác dụng, vì AGP luôn gộp `META-INF/services/**` và bỏ qua excludes với nhóm này. Đã hoàn tác. Mục đó vô hại: test chạy với nó mà Ktor không hỏi tới `ConfigLoader`.

## Đường dẫn tạo/sửa

Tạo trong `android/core/transport/src/main/kotlin/app/handlive/android/core/transport/`:
- `TransportConstants.kt` (hằng 0.10, `WsCloseCode` 0.8.3)
- `tls/SelfSignedCertificateGenerator.kt`, `tls/TlsIdentity.kt`, `tls/TlsIdentityStorage.kt` (interface, bản bộ nhớ, bản `SecretStore`, provider), `tls/AndroidTlsIdentityStorage.kt`
- `handshake/PairRegistry.kt`, `handshake/HandshakeEnvelopes.kt`, `handshake/ServerHandshake.kt`
- `session/SessionCipher.kt`, `session/SessionRekeyCoordinator.kt`
- `capability/EffectiveFeatures.kt`
- `server/ControlServer.kt` (+ `ControlServerConfig`, `ControlServerOptions`), `server/ControlConnectionHandler.kt`, `server/ControlSession.kt`, `server/EncryptedEnvelopeChannel.kt`, `server/ControlSessionDispatcher.kt`, `server/ActiveSessionRegistry.kt`, `server/ControlConnectionState.kt`

Test trong `android/core/transport/src/test/kotlin/app/handlive/android/core/transport/`:
- `ControlChannelHandshakeTest.kt`, `ControlChannelRejectionTest.kt`, `ControlChannelRekeyAndReplaceTest.kt`
- `handshake/ServerHandshakeVectorTest.kt`, `capability/EffectiveFeaturesTest.kt`, `session/SessionRekeyCoordinatorTest.kt`, `tls/TlsIdentityTest.kt`
- `testing/PinnedTrustManager.kt` (client Ktor engine Java với ghim SHA-256, không kiểm hostname), `testing/TestClientPeer.kt` (phía C: hello, kiểm welcome, kênh mã hóa), `testing/LoopbackServerFixture.kt`

Sửa:
- `android/core/transport/build.gradle.kts`: dependency, exclude, test đọc `shared/test-vectors/session-handshake.json`, test fixtures của `:core:protocol`.
- `android/gradle/libs.versions.toml`, chỉ các dòng Ktor: thêm `ktor-client-java`; bỏ `ktor-network-tls-certificates` và `ktor-server-test-host`, không còn nơi dùng. Bộ sinh chứng chỉ của Ktor ghi `KeyStore.getDefaultType()` (JKS không có trên Android) và mặc định RSA/SHA1.
- `android/app/build.gradle.kts`: chỉ thêm chú thích trong khối `packaging`.

## Lệnh test và kết quả

Môi trường: `JAVA_HOME=/opt/homebrew/opt/openjdk@21`, `ANDROID_HOME=/opt/homebrew/share/android-commandlinetools`.

`cd android && ./gradlew :core:transport:check --rerun-tasks` (chạy lại mọi task):

```
> Task :core:transport:lintReportDebug
Wrote HTML report to file:///Users/hxd/HandLive/android/core/transport/build/reports/lint-results-debug.html
Wrote SARIF report to file:///Users/hxd/HandLive/android/core/transport/build/reports/lint-results-debug.sarif

> Task :core:transport:lintDebug
> Task :core:transport:lint
> Task :core:transport:testDebugUnitTest
> Task :core:transport:test
> Task :core:transport:check

BUILD SUCCESSFUL in 28s
131 actionable tasks: 131 executed
```

Kết quả theo lớp (33 test, 0 lỗi, 0 bỏ qua):

```
core.transport.capability.EffectiveFeaturesTest          tests="4"  skipped="0" failures="0" errors="0"
core.transport.ControlChannelHandshakeTest               tests="3"  skipped="0" failures="0" errors="0"
core.transport.ControlChannelRejectionTest               tests="10" skipped="0" failures="0" errors="0"
core.transport.ControlChannelRekeyAndReplaceTest         tests="3"  skipped="0" failures="0" errors="0"
core.transport.handshake.ServerHandshakeVectorTest       tests="3"  skipped="0" failures="0" errors="0"
core.transport.session.SessionRekeyCoordinatorTest       tests="6"  skipped="0" failures="0" errors="0"
core.transport.tls.TlsIdentityTest                       tests="4"  skipped="0" failures="0" errors="0"
```

Đối chiếu tiêu chí chấp nhận. Mọi test loopback chạy Netty thật, TLS 1.3 thật, client Ktor tin chứng chỉ bằng ghim SHA-256:
- Hai phía dẫn ra cùng `k_c2s`/`k_s2c` và trao `capability/hello` đã mã hóa theo cả hai chiều: `bothSidesDeriveSameKeysAndExchangeEncryptedCapabilityHello`. Envelope ứng dụng đi được cả hai chiều: `applicationEnvelopesAreDecryptedAndDeliveredInBothDirections`.
- Sai MAC → `session/error AUTH_FAILED` + 4401. `pair` lạ → `PAIR_UNKNOWN` + 4401. Cặp đã thu hồi → `PAIR_REVOKED` + 4403. `protocol` 2 → `UNSUPPORTED_VERSION` (`min_protocol` 1) + 4426, kiểm trước cả cặp lạ. `device_id` sai → 4401. Hello hỏng → 4400, không có `session/error`. Im lặng → 4408 sau khoảng 5,1 s (test đo ≥ 4,8 s). Envelope đầu mã hóa sai khóa → 4401. Ghim sai → client từ chối TLS. Client chỉ TLS 1.2 → handshake thất bại.
- Tính năng chỉ bật khi cả hai phía bật và Android đủ quyền. Kiểm qua mạng thật (kết quả `{clipboard, call}`, sau `capability/update` bật SMS thì thêm `sms`) và 4 test đơn vị.
- Bắt tay tất định theo `session-handshake.json`: `welcome_plaintext`, `k_c2s`, `k_s2c` khớp từng byte; `PRK` sai hoặc `nonce` bị sửa → `AUTH_FAILED`.
- Rekey do client khởi tạo và rekey do S tự khởi tạo khi chạm ngưỡng: hai bên cùng lên `epoch` 1, `secret` trùng nhau, envelope sau rekey đi được hai chiều. Thay phiên → phiên cũ nhận `bye replaced` + 4409.

`cd android && ./gradlew test lint`:

```
BUILD SUCCESSFUL in 5s
232 actionable tasks: 29 executed, 203 up-to-date
```

`cd android && ./gradlew check`:

```
> Task :core:crypto:lint
> Task :app:lint
> Task :core:crypto:check
> Task :core:design:lint
> Task :core:protocol:lint
> Task :core:protocol:check
> Task :core:transport:lint
> Task :core:transport:check
> Task :core:design:check
> Task :app:check
BUILD SUCCESSFUL in 2s
272 actionable tasks: 6 executed, 266 up-to-date
```

`cd android && ./gradlew :app:assembleDebug && ls -l app/build/outputs/apk/debug/`:

```
BUILD SUCCESSFUL in 1s
112 actionable tasks: 1 executed, 111 up-to-date
total 82000
-rw-r--r--@ 1 hxd  staff  41977711 Sep 25 09:34 app-debug.apk
-rw-r--r--@ 1 hxd  staff       404 Sep 25 09:34 output-metadata.json
```

Lint của `:core:transport` còn đúng 1 cảnh báo, `GradleDependency` (đã có compileSdk 37), giống các module khác. Không dùng `@Suppress`, baseline hay nới cấu hình detekt; các lỗi detekt (ReturnCount, LongParameterList, TooManyFunctions, MagicNumber) được sửa bằng cách tách hàm và tách lớp (`EncryptedEnvelopeChannel`, `ControlServerOptions`).

## Điểm lệch với tài liệu và cách xử lý

1. **Mã đóng khi rekey thất bại.** CONN-02 E4 chỉ ghi "đóng phiên, kết nối lại" khi rekey không có `ack` trong 10 s, `ack` lỗi, hoặc dữ liệu `ack` sai. Không có mã đóng nào được chỉ định. Đang dùng **4500** (`INTERNAL`). Đề xuất ghi rõ mã trong 0.8.3/CONN-02.
2. **Va chạm rekey.** CONN-02 API 3 ghi: bên có `device_id` nhỏ hơn thắng, bên thua hủy yêu cầu của mình và trả `ack`. Tài liệu không nói bên thắng làm gì với yêu cầu của bên thua. Đang cài: bỏ qua, không `ack`, vì bên thua đã hủy nên không chờ. Đề xuất bổ sung một câu.
3. **Thời điểm thay phiên cũ (4409).** CONN-01 bước 7 ghi "sau khi phiên mới bắt tay xong". Đang hiểu "xong" là đã **xác nhận khóa**, tức là giải mã được `capability/hello` của phiên mới, chứ không phải ngay sau `welcome`. Lý do: một `hello` bị phát lại vẫn nhận được `welcome` (API 4 logic 3) nhưng không bao giờ gửi được envelope mã hóa hợp lệ, nên không thể đá phiên thật ra. Đề xuất ghi rõ như vậy.
4. **`session/hello` sai cấu trúc** chỉ đóng 4400, không gửi `session/error`, vì enum `code` của API 6 không có `BAD_REQUEST`. Envelope bắt tay có `v` khác 1 → `UNSUPPORTED_VERSION` + 4426.
5. **Kho lưu TLS hỏng hoặc mất mật khẩu** (ví dụ Keystore bị xóa): `TlsIdentityProvider` sinh khóa mới, khiến mọi ghim `tls_sha256` của client mất hiệu lực (client báo `TLS_PIN_MISMATCH`, phải ghép nối lại). Tài liệu chưa nói trường hợp này. Đề xuất: Phase 1 báo lên UI và xóa các cặp.
6. **Máy trạng thái 0.11** là của client, nên Android chỉ cài vòng đời kết nối phía S (`ControlConnectionState`). Không lệch, chỉ ghi lại cách hiểu.
7. **Phase plan ghi "chứng chỉ tự ký trong Keystore"**, còn 0.6.1 ghi "PKCS#12, mật khẩu bọc bởi Keystore". Đã làm theo 0.6.1, và đúng bảng 0.2: `hl_master` bọc cả mật khẩu PKCS#12. Đề xuất sửa câu chữ trong phase plan.
8. **Loại kotlin-reflect và typesafe config**: từ nay `:core:transport` không dùng được `developmentMode` của Ktor, `call.receive<T>()` hay cấu hình HOCON. Nếu Phase sau cần thì phải bỏ exclude tương ứng. Test JVM sẽ báo nếu một bản Ktor mới bắt đầu cần tới chúng trên đường chạy chính.

## Chưa làm (ngoài phạm vi A0.2 hoặc thuộc Phase 1)

- CONN-01 API 3 logic 2: giới hạn 16 kết nối chưa bắt tay. CONN-01 API 4 logic 2: sai `mac` 5 lần/phút cùng IP thì chặn 5 phút. Cả hai đều chưa có mã đóng hay cách từ chối được chỉ định; nên thêm cùng A-SVC ở Phase 1.
- CONN-02: đóng phiên im lặng quá 45 s (chưa có mã đóng chỉ định). Dedup `id` (LRU 5 phút). Trả `ack UNSUPPORTED_TYPE` cho yêu cầu lạ: việc này thuộc bộ điều phối mô-đun tính năng nhận từ `inbound`.
- mDNS, foreground service, nối UI, Room `paired_device` (hiện `PairRegistry` là `fun interface`).
- Chưa chạy trên thiết bị hay emulator (máy không có). Netty + TLS 1.3 (Conscrypt) trên Android 10+ mới chỉ được kiểm gián tiếp: APK dex được, Android Lint sạch, test JVM chạy đúng classpath. Cần một smoke test instrumented ở Phase 1.

## Câu hỏi còn mở

- Mã đóng cho rekey thất bại (điểm lệch 1) và cho giới hạn kết nối / chặn IP: dùng 4500, 4400, hay thêm mã mới vào 0.8.3?
- Mất khóa TLS (điểm lệch 5): tự sinh lại rồi buộc ghép nối lại, hay chặn và báo lỗi?

```text
Status: DONE_WITH_CONCERNS
Summary: core/transport có WSS server Ktor/Netty chỉ TLS 1.3 với chứng chỉ ECDSA P-256 tự ký (PKCS#12, mật khẩu trong SecretStore gắn Keystore), bắt tay S đúng thứ tự và mã đóng, capability/tính năng hiệu lực, rekey hai vai, thay phiên 4409; 33 test JVM qua loopback thật và `./gradlew check` xanh toàn dự án. APK debug giảm 3,90 MB (45,88 → 41,98 MB, đo cùng cây mã).
Concerns/Blockers: chưa chạy Netty trên thiết bị thật; mã đóng cho rekey thất bại (tạm dùng 4500) và việc sinh lại khóa TLS khi kho hỏng cần chủ dự án quyết; giới hạn 16 kết nối, chặn IP, đóng khi im lặng 45 s để lại cho Phase 1.
```
