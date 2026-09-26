[English](code-standards.md) | Tiếng Việt

# HandLive — Code Standards

> Quy ước cho mọi kho trong workspace. Bổ sung khi có quy ước mới.

## Chung

- Ưu tiên YAGNI, KISS, DRY (theo thứ tự đó).
- File >200 dòng → cân nhắc modular hóa theo ranh giới logic (function/class/concern).
- File mới: kebab-case, tên dài mô tả rõ (self-documenting cho công cụ LLM) cho script, tài liệu,
  tài nguyên, web. Mã nguồn theo quy ước của nền tảng: Kotlin và Swift đặt tên file theo kiểu chính
  bên trong (PascalCase), Rust snake_case.
- Không fake data/mock/shortcut chỉ để pass check. Implement hành vi thật.
- Không commit secret, dotenv, token, key, credential.
- Conventional commits, không tham chiếu AI trong message.

## Wire protocol (ổn định — mọi nền tảng phải khớp)

- Envelope JSON: `{v, type, id (uuid-v7), ts (ms), payload (base64 XChaCha20-Poly1305)}`.
- Audio binary frame: `[0x48 0x4C][ver:1B][seq:4B][ts:4B][encrypted_opus:NB]`.
- Magic bytes `0x484C` ("HL"). Không đổi format tùy tiện giữa các platform.

## Android (Kotlin)

- minSdk 29, targetSdk 35, compileSdk 37 (Compose 1.12 trở lên cần). Foreground Service đúng type
  (`FOREGROUND_SERVICE_CONNECTED_DEVICE` / `camera|microphone`).
- Crypto qua Tink (HKDF có thể tự cài trên `HmacSHA256`, kiểm bằng vector); audio codec libopus qua
  JNI.
- WSS server: Ktor 3 engine Netty (CIO không hỗ trợ TLS phía server); loại thư viện native không
  dùng (QUIC, HTTP/3, epoll, kqueue) và tệp META-INF trùng để giữ APK nhỏ.
- Mọi BT-HFP call sau abstraction `CallAudioRelay` (impl: `HfpCallAudioRelay`,
  `OpusWsCallAudioRelay` qua Shizuku, `CdmCallAudioRelay` tương lai).
- Điều khiển cuộc gọi bằng API công khai (`TelecomManager`, `TelephonyCallback`), không dùng
  `InCallService` (plan §13 D9).
- OEM fragmentation → strategy pattern (`BtAdapterStrategy`: Samsung/Pixel/Generic).
- Thư viện đóng gói trong app phải là mã nguồn mở, không thành phần độc quyền (ML Kit, Play
  Services); ngoại lệ duy nhất là FCM ở flavor riêng (Phase 2). Quét QR: CameraX + ZXing core
  (Apache-2.0).

## macOS / iOS (Swift 6)

- Crypto qua CryptoKit (`Curve25519`, `ChaChaPoly`). XChaCha20-Poly1305 = HChaCha20 tự cài +
  `ChaChaPoly`, kiểm bằng test vector liên nền tảng (`docs/detailed-design/00-common-specs.md`
  §0.6.1).
- Bọc mọi `IOBluetooth*` call trong protocol abstraction (API legacy, rủi ro deprecate).
- CMIOExtension / AudioServerPlugin ký Developer ID (bắt buộc; ad-hoc bị reject).
- Key vào Keychain với `kSecAttrAccessibleWhenUnlockedThisDeviceOnly`; macOS dùng data-protection
  keychain (`kSecUseDataProtectionKeychain`) và entitlement `keychain-access-groups`.

## Bản địa hóa (C20, `docs/detailed-design/00-common-specs.md` 0.12)

- Tiếng Anh là ngôn ngữ mặc định, tiếng Việt là ngôn ngữ thứ hai. Mọi chuỗi hiển thị lấy từ catalog
  `shared/strings/ui-strings.json` qua tài nguyên sinh ra: Android `R.string`/`R.plurals`
  (`stringResource`, `pluralStringResource`), Apple accessor sinh từ String Catalog. Không viết
  cứng câu chữ hiển thị trong mã.
- Thêm hay sửa chuỗi: sửa tài liệu chi tiết (cả hai bản), rồi catalog trong `shared` (commit riêng),
  rồi mã.
- Log, mã lỗi, tên sự kiện, thông điệp commit, báo cáo công việc: tiếng Anh, không dịch.
- Định dạng ngày, giờ, số, dung lượng bằng formatter theo locale; không ghép chuỗi.
- Android: lint `HardcodedText`, `MissingTranslation` là lỗi; `locales_config.xml`,
  `androidResources.localeFilters` = en, vi. Apple: `developmentLanguage: en`, `knownRegions` en,
  vi; purpose string qua `InfoPlist.xcstrings`.

## Tài liệu

- Song ngữ: `X.md` tiếng Anh (bản chuẩn), `X.vi.md` tiếng Việt, cùng cấu trúc; sửa cả hai trong
  cùng commit; dòng đầu là thanh chọn ngôn ngữ (`English | [Tiếng Việt](X.vi.md)` /
  `[English](X.md) | Tiếng Việt`). Kiểm: `python3 tools/docs/check_bilingual_docs.py`.
- Kế hoạch và báo cáo trước 2026-09-25 (`plans/20260924-*`, `reports/phase-00-*`) giữ tiếng Việt
  làm lưu trữ; tên file giữ nguyên làm định danh.

## Rust (cloud relay)

- Actix-web + actix-ws. Stateless để scale horizontal.
- Zero-knowledge: không decrypt, không log payload. Chỉ metadata tối thiểu.

## Test

- Chạy test hẹp nhất trước, mở rộng khi đụng contract chung.
- Audio: verify E2E trên đường Opus/WS; đường HFP dựa vào mã hóa Bluetooth (plan §13 D11). BT và
  Shizuku capture: test matrix ≥6 device thật (Samsung/Pixel/Xiaomi/OPPO).
- Không giấu test/lint/type/build fail.

## Giấy phép và phụ thuộc

- Mọi kho: Apache License 2.0 (`LICENSE`); không cần header giấy phép trong từng file nguồn.
- Phụ thuộc mới chỉ dùng giấy phép tương thích Apache-2.0: Apache, MIT, BSD, ISC, MPL-2.0, OFL (font). Không GPL, LGPL, AGPL dưới mọi hình thức (kể cả liên kết động).
- Tài nguyên bên thứ ba đóng gói trong app (font, biểu tượng) ghi vào `NOTICE` của kho kèm bản quyền và đường dẫn file giấy phép.
- Commit đứng tên người thật, ký DCO (`git commit -s`); không ghi công cụ AI làm tác giả hay đồng tác giả (hook `.githooks/commit-msg`, job CI `commit-policy`).
