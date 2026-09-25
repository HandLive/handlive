# Báo cáo A0.1 [android] — Khung Gradle, `core/protocol`, `core/crypto`

Ngày: 2026-09-25 · Nhánh: `feat/phase-00-khung` · Chưa commit.

## Việc đã làm

- Dựng khung Gradle Kotlin DSL đa module trong `android/`: wrapper Gradle 9.7.1, version catalog, cấu hình build chung (ktlint + detekt áp cho mọi module ở `build.gradle.kts` gốc).
- Module: `:app` (Compose, gói `app.handlive.android`, chỉ một màn giữ chỗ), `:core:protocol`, `:core:crypto`, cùng khung rỗng dựng được cho `:core:transport` (đã khai báo Ktor server Netty + websockets + chứng chỉ TLS, coroutines, test host) và `:core:design` (Compose BOM, ui, foundation, ui-tooling-preview).
- `core/protocol`: `Envelope` + `EnvelopeCodec` (giới hạn 256 KiB khi ghi và khi đọc, kiểm `v`, `id` UUIDv7, `ts`, `payload` b64), `EnvelopeHeader` (AAD `"<v>|<type>|<id>|<ts>"`), `MessageType` (10 giá trị 0.7.1), `Payload {op, data}` / `OpPayload<T>`, `PlaintextCodec`, `Ack`/`AckError` (ok/error), `ErrorCode` (đúng 49 mã 0.8.1, cùng thứ tự schema), `ProtocolException` + `protocolRequire`, `HlFrame` (0.5.2), `CameraStreamPlaintext`, `ClipboardChunkPlaintext` (plaintext nhị phân `hdr_len ‖ JSON ‖ bytes`), `UuidV7Generator`, `UuidBytes`, `Base64Codecs` (b64/b64u, chỉ nhận dạng chuẩn tắc), model có kiểu cho `session/*`, `capability/*`, `stream_hello/stream_welcome`. JSON dùng kotlinx.serialization.
- `core/crypto`: `XChaCha20Poly1305Aead`, `X25519Keys`, `Ed25519Keys`, `HkdfSha256` (extract/expand), `HmacSha256` (so sánh hằng thời gian), `DeviceIdDerivation` (UUIDv8, 0.2), `PairingKeyDerivation` (`PRK`, 0.6.2), `SessionHandshakeDerivation` (`K_auth`, T1 106 byte, T2 198 byte, MAC, `secret`/`k_c2s`/`k_s2c`), `SessionRekeyDerivation`, `StreamKeyDerivation` (`K_stream` 96 byte, MAC `HLSTREAM1`), `SessionKeys`/`StreamKeys` với `PeerRole` (chọn khóa gửi/nhận theo vai C/S), `EnvelopeCipher`, `HlFrameCipher`. Kho khóa: interface `SecretStore`/`SecretBlobBackend`, `AeadSecretStore` (thuần JVM, có test) và `AndroidKeystoreSecretStore` (`hl_master` AES-256-GCM trong Android Keystore, thử StrongBox trước, bọc keyset Tink AES256-GCM qua `AndroidKeysetManager`; blob lưu trong SharedPreferences riêng). Không có test instrumented (không có thiết bị).
- Test JVM đọc TẤT CẢ 14 file `shared/test-vectors/*.json`, cộng 2 file roundtrip. `VectorFileCoverageTest` đỏ nếu xuất hiện file vector mới mà chưa có test. Test schema nạp cả `shared/schemas/` vào `com.networknt:json-schema-validator` 3.0.7 (draft 2020-12, ánh xạ `$id` về file cục bộ trong bộ nhớ, không tải mạng).
- Ứng dụng: `allowBackup=false` + `dataExtractionRules`/`fullBackupContent` loại mọi miền (khóa gắn Keystore của máy, không được sao lưu), biểu tượng vector giữ chỗ.

### Phiên bản đã chọn

| Thành phần | Phiên bản | Ghi chú |
|------------|-----------|---------|
| Gradle | 9.7.1 (wrapper) | |
| AGP | 9.4.1 | Bản ổn định mới nhất; Kotlin tích hợp sẵn của AGP 9 (không dùng plugin `kotlin-android`) |
| Kotlin | 2.4.20 | Compose compiler plugin cùng phiên bản; kotlinx.serialization 1.11.0; coroutines 1.11.0 |
| JVM | toolchain 21, `sourceCompatibility`/`targetCompatibility` 21 | |
| SDK | compileSdk 35, minSdk 29, targetSdk 35 | |
| Tink | `tink-android` 1.23.0 | |
| Ktor | 3.6.0 (server-core, server-netty, server-websockets, network-tls-certificates) | Khai báo sẵn cho A0.2 |
| Compose BOM | 2026.03.01 (Compose 1.10.6); activity-compose 1.10.1 | Xem điểm lệch 1 |
| ktlint | plugin `org.jlleitschuh.gradle.ktlint` 14.2.0, ktlint 1.8.0, kiểu `ktlint_official`, dòng ≤ 120 | |
| detekt | 1.23.8 (`buildUponDefaultConfig`) | Bản ổn định cuối; 2.0 còn alpha |
| JSON Schema | `com.networknt:json-schema-validator` 3.0.7 (chỉ test) | |

### Thư viện XChaCha20-Poly1305

Tink, không dùng BouncyCastle. `subtle.XChaCha20Poly1305` không nhận nonce từ ngoài nên không kiểm được vector theo từng byte → dùng `com.google.crypto.tink.aead.internal.InsecureNonceXChaCha20Poly1305` (cùng lõi). Chữ "Insecure" chỉ nghĩa là bên gọi tự lo nonce. `seal` mặc định sinh nonce 24 byte bằng `SecureRandom`. Vì nó nằm trong gói `internal` của Tink, API có thể đổi khi nâng Tink; test vector sẽ bắt được thay đổi đó. HChaCha20 của Tink không công khai, nên test có một bản HChaCha20 tham chiếu (`HChaCha20Reference`, chỉ trong test). Test kiểm `hchacha20.json`, đồng thời chứng minh Tink XChaCha = HChaCha20 + ChaCha20-Poly1305 nonce `00000000 ‖ nonce[16:24]`, đúng cấu trúc Apple dùng.

## Đường dẫn tạo/sửa

- Tạo: `android/**` (`settings.gradle.kts`, `build.gradle.kts`, `gradle.properties`, `gradle/libs.versions.toml`, wrapper, `.editorconfig`, `.gitignore` (`.kotlin/`), `config/detekt/detekt.yml`, `app/`, `core/protocol/` (main, test, testFixtures), `core/crypto/` (main, test), `core/transport/build.gradle.kts`, `core/design/build.gradle.kts`). `local.properties` có sẵn trong `.gitignore`.
- `shared/` đã sửa:
  - Tạo `shared/test-vectors/envelope-roundtrip.json` (3 envelope Kotlin: clipboard push s2c tiếng Việt, ack s2c, ping c2s). Đã kiểm độc lập bằng libsodium (`tools/.venv`, PyNaCl): cả 3 giải mã đúng plaintext.
  - Thêm mục `envelope-roundtrip.json` vào `shared/test-vectors/README.md`.
  - Không sửa vector nào khác.
- Tạo báo cáo này.

## Lệnh test và kết quả

Môi trường: `JAVA_HOME=/opt/homebrew/opt/openjdk@21`, `ANDROID_HOME=/opt/homebrew/share/android-commandlinetools`.

Lệnh chấp nhận:

```
cd android && ./gradlew test lint          # unit test JVM + Android Lint
cd android && ./gradlew check              # = test + lint + ktlintCheck + detekt (mọi module)
cd android && HL_WRITE_ROUNDTRIP=1 ./gradlew :core:crypto:test   # ghi lại envelope-roundtrip.json
```

`./gradlew test lint` (sau `clean`, `--no-build-cache`), đầu ra phần cuối:

```
> Task :core:crypto:testDebugUnitTest
> Task :core:protocol:testDebugUnitTest
Wrote HTML report to file:///Users/hxd/HandLive/android/core/crypto/build/reports/lint-results-debug.html
> Task :core:crypto:lintDebug
Wrote HTML report to file:///Users/hxd/HandLive/android/core/transport/build/reports/lint-results-debug.html
> Task :core:transport:lintDebug
Wrote HTML report to file:///Users/hxd/HandLive/android/app/build/reports/lint-results-debug.html
> Task :app:lintDebug
BUILD SUCCESSFUL in 12s
209 actionable tasks: 189 executed, 20 up-to-date
```

`./gradlew check`:

```
> Task :app:detekt FROM-CACHE
> Task :core:crypto:detekt FROM-CACHE
> Task :core:design:detekt NO-SOURCE
> Task :core:protocol:detekt FROM-CACHE
> Task :core:transport:detekt NO-SOURCE
BUILD SUCCESSFUL in 842ms
239 actionable tasks: 5 executed, 30 from cache, 204 up-to-date
```

`HL_WRITE_ROUNDTRIP=1 ./gradlew :core:crypto:test`:

```
> Task :core:crypto:testDebugUnitTest
BUILD SUCCESSFUL in 1s
30 actionable tasks: 1 executed, 29 up-to-date
name="app.handlive.android.core.crypto.EnvelopeRoundtripTest" tests="2" skipped="0" failures="0" errors="0"
```

Kết quả theo lớp test (44 test, 0 lỗi, 0 bỏ qua):

```
core.protocol.ClipboardChunkPlaintextVectorTest tests=2 skip=0 fail=0 err=0
core.protocol.EnvelopeCodecVectorTest           tests=3 skip=0 fail=0 err=0
core.protocol.ErrorCodeAndTypeCatalogTest       tests=3 skip=0 fail=0 err=0
core.protocol.GeneratedMessageSchemaTest        tests=5 skip=0 fail=0 err=0
core.protocol.HlFrameVectorTest                 tests=3 skip=0 fail=0 err=0
core.protocol.IdentifierAndEncodingTest         tests=3 skip=0 fail=0 err=0
core.protocol.TypedMessageVectorTest            tests=3 skip=0 fail=0 err=0
core.crypto.AeadPrimitiveVectorTest             tests=4 skip=0 fail=0 err=0
core.crypto.AeadSecretStoreTest                 tests=2 skip=0 fail=0 err=0
core.crypto.EnvelopeRoundtripTest               tests=2 skip=0 fail=0 err=0
core.crypto.MessageCipherVectorTest             tests=3 skip=0 fail=0 err=0
core.crypto.PairingAndSessionVectorTest         tests=4 skip=0 fail=0 err=0
core.crypto.PrimitiveKdfAndIdentityVectorTest   tests=4 skip=0 fail=0 err=0
core.crypto.StreamKeysVectorTest                tests=2 skip=0 fail=0 err=0
core.crypto.VectorFileCoverageTest              tests=1 skip=0 fail=0 err=0
```

Độ phủ vector (dương + âm): xchacha20-poly1305 3+4, hchacha20 3, chacha20-poly1305 2+4, x25519 6, hkdf-sha256 3, device-id 3, pair-prk 2 (tính từ cả hai phía), session-handshake 2+4, session-rekey 2 (cả bên khởi tạo và bên nhận; epoch 2 nối từ epoch 1), stream-keys 2+3, envelope 5+5, ack 3+2, clipboard-chunk 2+2, hl-frame 4+2. `device_id` tính từ seed Ed25519 mẫu khớp `device-id.json`; chữ ký Ed25519 khớp RFC 8032 TEST 1. Mọi vector âm bị từ chối (envelope/khung HL → `DECRYPT_FAILED`; MAC → `verify` trả `false`).

Schema S0.2: Kotlin sinh ra envelope cho cả 10 `type`, ack thành công và ack lỗi cho cả 49 mã, `session/hello|welcome|error|rekey|bye`, ack của `session/rekey` (`session-rekey.schema.json#/$defs/ack`), `capability/hello|update` (Android đầy đủ theo ví dụ 0.7.2, Mac, iPhone). Tất cả qua schema. Có thêm test chứng minh validator thực sự bắt vi phạm.

Liên nền tảng: `envelope-roundtrip-apple.json` (agent Apple đã ghi, 3 envelope) giải mã đúng trên Android.

Lint: 0 lỗi. Không dùng `@Suppress`, baseline hay `abortOnError=false`. Cảnh báo còn lại (hiện đầy đủ, không giấu): `OldTargetApi` (targetSdk 35 theo spec); `GradleDependency` với compileSdk 35 < 37, Compose BOM, activity-compose (điểm lệch 1); `AndroidGradlePluginVersion` (đã có Gradle 9.8.0, đề bài chốt 9.7.1). detekt.yml chỉ ghi đè hai quy tắc: `FunctionNaming` bỏ qua `@Composable`, `UnusedPrivateMember` bỏ qua `@Preview`.

Không log payload/plaintext: mã chính không gọi `Log`/`println`. Thông điệp của `ProtocolException` chỉ mô tả cấu trúc. Không có khóa thật: mọi khóa trong test lấy từ vector công khai hoặc sinh ngẫu nhiên lúc chạy.

## Điểm lệch với tài liệu và cách xử lý

1. **compileSdk 35 buộc hạ Compose.** Compose BOM mới nhất (2026.09.00, Compose 1.12) kéo `androidx.core` 1.18 và `activity` 1.13, cả hai đòi compileSdk ≥ 36. Máy chỉ có `platforms;android-35`, nên chọn BOM 2026.03.01 (Compose 1.10.6) và activity-compose 1.10.1 (bản cuối có `minCompileSdk=35`). Đề xuất: khi cài `platforms;android-36`, nâng compileSdk (targetSdk vẫn 35 theo spec), rồi nâng BOM.
2. **Ktor + Netty trên Android (cho A0.2).** `ktor-server-netty` 3.6 kéo Netty 4.2 cùng thư viện native QUIC/HTTP3/epoll/kqueue cho desktop. Đã loại `netty-codec-native-quic` và thêm `packaging.resources.excludes` cho các tệp META-INF trùng. APK debug vẫn khoảng 39 MB. Đề xuất A0.2 rà thêm các exclude (epoll/kqueue native, http3) hoặc cân nhắc engine CIO. Spec 0.1 ghi "Ktor 3, engine Netty", nên đổi engine là quyết định của chủ dự án.
3. **HKDF không qua Tink.** 0.6.1 ghi Tink `Hkdf`, nhưng `subtle.Hkdf` không tách được bước extract để kiểm trường `prk` của vector. Đã cài HKDF-SHA256 (RFC 5869) trên JCA `HmacSHA256`; kết quả khớp RFC 5869 A.1–A.3 và mọi dẫn xuất khóa trong vector.
4. **Lưu `ik_sig`/`ik_dh`.** 0.6.1 ghi "Tink keyset bọc bởi khóa AES-256 trong Android Keystore". Tink không có kiểu keyset cho X25519 thô, nên cả hai khóa (và `PRK`) được lưu dạng byte thô, mã hóa bằng một keyset Tink AEAD (AES256-GCM) mà `hl_master` bọc. Mức bảo vệ tương đương, nhưng dạng lưu khác chữ trong spec. Đề xuất sửa câu chữ 0.6.1 cho khớp, hoặc giữ nếu chủ dự án muốn Ed25519 nằm trong keyset chữ ký riêng.
5. **Model có kiểu cho session/capability/stream nằm ở `core/protocol`.** Cần để test schema dùng dữ liệu do Kotlin sinh. A0.2 dùng lại, không định nghĩa lần nữa.
6. **detekt 1.23.8** gọi `ReportingExtension.file(String)`: Gradle 9.7 báo deprecated, sẽ hỏng ở Gradle 10. Cần nâng lên detekt 2.x khi có bản ổn định.

Không thấy vector nào sai. `tools/vectors/verify_vectors.py`: 360 phép kiểm, 0 lỗi (file roundtrip được bỏ qua vì không có bộ kiểm Python, đúng thiết kế).

## Câu hỏi còn mở

- Điểm lệch 4 (dạng lưu `ik_sig`/`ik_dh`): sửa tài liệu hay đổi cài đặt?
- Điểm lệch 2 (engine Ktor): giữ Netty cùng danh sách exclude, hay chuyển sang CIO?

```text
Status: DONE_WITH_CONCERNS
Summary: Khung Gradle 5 module (AGP 9.4.1, Kotlin 2.4.20, Tink 1.23.0) dựng xanh; core/protocol và core/crypto qua mọi vector S0.1 (dương và âm), mọi tin Kotlin sinh ra qua schema S0.2; đã ghi envelope-roundtrip.json và giải mã được envelope-roundtrip-apple.json.
Concerns/Blockers: Compose phải hạ về BOM 2026.03.01 vì compileSdk 35; Ktor Netty làm APK nặng (A0.2 cần xử lý); dùng API internal của Tink cho XChaCha nonce cố định; HKDF tự cài trên JCA; dạng lưu ik_sig/ik_dh lệch chữ 0.6.1.
```
