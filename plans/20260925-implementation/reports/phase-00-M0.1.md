# Phase 0 — M0.1 [apple]: khung `apple/`, HLProtocol, HLCrypto, HLTransport

Ngày: 2026-09-25 · Nhánh: `feat/phase-00-khung` · Chưa commit.

## Việc đã làm

- **Khung `apple/`**: `project.yml` (XcodeGen) tối giản, 4 local package (kể cả
  `Packages/HLDesignSystem` chỉ tham chiếu) + target app macOS `HandLive` (menu bar `MenuBarExtra`
  kiểu menu, `LSUIElement`, bundle `app.handlive.mac`, không cấu hình ký, Info.plist sinh bằng
  `GENERATE_INFOPLIST_FILE`). `HandLive.xcworkspace/contents.xcworkspacedata` tham chiếu
  `HandLive.xcodeproj` và 4 package. `.swiftlint.yml`, `README.md` (có lệnh `xcodegen generate`).
- **Quyết định `.xcodeproj`**: không commit; thêm đúng dòng `apple/*.xcodeproj` vào `.gitignore`
  gốc. `apple/.gitignore` bỏ qua `Packages/*/Package.resolved` (chỉ sinh khi
  `HL_SWIFT_TESTING_PACKAGE=1`, phụ thuộc môi trường).
- **Swift-testing có điều kiện**: mỗi `Package.swift` (tools 6.0) chỉ thêm `swift-testing` (branch
  `release/6.2`) khi `Context.environment["HL_SWIFT_TESTING_PACKAGE"] == "1"`; không có biến → dùng
  Testing của Xcode.
- **HLProtocol** (không phụ thuộc): `Envelope` (parse chặt: `v` =1, `type` đã biết, `id` UUIDv7 chữ
  thường, `ts` nguyên ≥ 0, `payload` b64 chuẩn tắc, không trường lạ, ≤ 256 KiB; `wireString()` đúng
  thứ tự khóa 0.5.1; `aad`), `Payload {op, data}` + `TypedPayload<T>`, `JSONValue`, `Ack`
  /`AckError`, `ErrorCode` (49 mã, đúng thứ tự bảng 0.8.1), `MessageType` (10 giá trị 0.7.1),
  `HLFrameHeader` /`HLFrame`/`CameraFramePayload` (0.5.2), `ClipboardChunkPlaintext` (hdr_len BE ‖
  JSON ‖ khối), `HLUUID` (UUIDv7, uuid ↔ 16 byte, kiểm version/variant), `Base64Coding` (b64 có
  padding, b64u không padding, giải mã chặt + chuẩn tắc), kiểu `data` của `session`
  hello/welcome/error/rekey/bye, `stream_hello/welcome`, `capability` hello/update (đủ trường
  0.7.2).
- **HLCrypto** (→ HLProtocol): `HChaCha20` tự cài (draft-03 §2.2), `XChaCha20Poly1305` = HChaCha20 +
  CryptoKit `ChaChaPoly` nonce `00000000 ‖ nonce[16:24]`; `X25519`, `Ed25519`, `HKDFSHA256`
  (extract/expand/derive, salt rỗng mặc định), `HMACSHA256` (verify hằng thời gian qua
  `HMAC.isValidAuthenticationCode`), `DeviceIdentity` (UUIDv8, 0.2), `PairingKeyDerivation` (PRK
  0.6.2), `SessionHandshakeCrypto` (K_auth, T1 106 byte, T2 198 byte, secret), `SessionKeys.rekeyed`
  (bước 6/8), `StreamKeys` (K_stream 96 byte, thông điệp `HLSTREAM1|` /`HLSTREAM1|welcome|`),
  `EnvelopeCipher`, `HLFrameCipher`; `SecretStore` protocol + `InMemorySecretStore` +
  `KeychainSecretStore` (generic password, service `app.handlive.keys`,
  `kSecAttrAccessibleWhenUnlockedThisDeviceOnly`).
- **HLTransport** (→ HLCrypto, HLProtocol), giữ nhỏ: `ConnectionStateMachine` đúng từng cạnh 0.11
  (`ConnectionState`, `ConnectionEvent`, `ConnectionStatus` + câu chữ PAIR-02), `ReconnectBackoff`
  (0,5→30 s, ±20 %), `ClientSessionHandshake` thuần logic (dựng `session/hello`, kiểm `welcome`:
  `device_id` đúng đối phương, MAC hằng thời gian, trả `SessionKeys`; `session/error` → `rejected`).
  Chưa có `URLSessionWebSocketTask` /`NWBrowser` (Phase 1).
- **Vector liên nền tảng**: sinh `shared/test-vectors/envelope-roundtrip-apple.json` (3 vector, khóa
  cố định của `envelope.json`, nonce + id mới, cùng trường/thứ tự trường như `envelope.json`) và
  thêm mục mô tả trong `shared/test-vectors/README.md`. Kiểm chéo độc lập: libsodium (`tools/.venv`)
  giải mã đủ 3 vector. Test Apple giải mã được `envelope-roundtrip.json` do Android ghi (3 vector:
  clipboard, ack, ping).

## Đường dẫn tạo/sửa

- `apple/project.yml`, `apple/README.md`, `apple/.swiftlint.yml`, `apple/.gitignore`,
  `apple/HandLive.xcworkspace/contents.xcworkspacedata`,
  `apple/macOS/HandLive/handlive-mac-app.swift`
- `apple/Packages/HLProtocol/` — `Package.swift`; `Sources/HLProtocol/`: `ack.swift`,
  `base64-coding.swift`, `capability-features.swift`, `capability-messages.swift`,
  `clipboard-chunk-plaintext.swift`, `envelope.swift`, `error-code.swift`, `hl-frame.swift`,
  `json-value.swift`, `message-type.swift`, `payload.swift`, `protocol-error.swift`,
  `session-messages.swift`, `uuid-helpers.swift`; `Tests/HLProtocolTests/`:
  `envelope-vector-tests.swift`, `frame-and-chunk-vector-tests.swift`,
  `primitive-encoding-tests.swift`, `schema-conformance-tests.swift`,
  `json-schema-subset-validator.swift`, `test-vector-loader.swift`
- `apple/Packages/HLCrypto/` — `Package.swift`; `Sources/HLCrypto/`: `crypto-error.swift`,
  `curve25519-keys.swift`, `device-identity.swift`, `hchacha20.swift`, `key-derivation.swift`,
  `keychain-secret-store.swift`, `message-ciphers.swift`, `pairing-key-derivation.swift`,
  `secret-store.swift`, `session-key-schedule.swift`, `stream-channel-keys.swift`,
  `xchacha20-poly1305.swift`; `Tests/HLCryptoTests/`: `primitive-vector-tests.swift`,
  `key-schedule-vector-tests.swift`, `message-cipher-vector-tests.swift`,
  `envelope-roundtrip-tests.swift`, `chacha-poly-reference.swift`, `test-vector-loader.swift`
- `apple/Packages/HLTransport/` — `Package.swift`; `Sources/HLTransport/`:
  `connection-state-machine.swift`, `reconnect-backoff.swift`, `client-session-handshake.swift`;
  `Tests/HLTransportTests/`: `connection-state-machine-tests.swift`,
  `client-session-handshake-tests.swift`, `test-vector-loader.swift`
- `.gitignore` (thêm `apple/*.xcodeproj`), `shared/test-vectors/envelope-roundtrip-apple.json`,
  `shared/test-vectors/README.md` (mục mới)

## Phạm vi test đã phủ

- Đọc **mọi** file vector liên quan: `hchacha20` (vector 1 = draft §2.2.1), `xchacha20-poly1305`
  (vector 1 = draft §A.3.1; kiểm cả `hchacha20_subkey`, `chacha20_nonce`), `chacha20-poly1305`
  (CryptoKit trực tiếp), `x25519`, `hkdf-sha256` (prk + okm), `device-id` (Ed25519 seed → pub →
  `device_id`), `pair-prk` (tính từ hai phía), `session-handshake`, `session-rekey` (nối epoch 1 →
  2), `stream-keys`, `envelope`, `ack`, `clipboard-chunk`, `hl-frame`. Vector dương khớp byte (seal
  với nonce cố định ra đúng chuỗi wire/khung); **mọi** `invalid_vectors` bị từ chối (AEAD →
  `authenticationFailed` /`payloadTooShort`, MAC → verify sai).
- Kiểm đột biến: đổi hằng quay 7→8 trong HChaCha20 thì 9 kỳ vọng hỏng (XChaCha, envelope, khung HL)
  — test thật sự bắt lỗi.
- **Đối chiếu schema S0.2 — lựa chọn**: không có thư viện JSON Schema gọn cho Swift, nên viết bộ
  kiểm draft 2020-12 **rút gọn** trong test (`json-schema-subset-validator.swift`, 184 dòng) đọc
  thẳng `shared/schemas/*.json`, hỗ trợ đúng các từ khóa đang dùng (`$ref` giữa file + JSON pointer,
  `type`, `enum`, `const`, `required`, `properties`, `additionalProperties`, `items`, `uniqueItems`,
  `minimum`, `maximum`, `minLength`, `pattern`, `allOf`, `anyOf`, `not`, `if/then/else`); gặp từ
  khóa lạ thì báo lỗi, không lặng lẽ bỏ qua. Kiểm: envelope/plaintext trong vector; JSON do Swift
  sinh (envelope, ack ok/lỗi, session hello/welcome/error/rekey + ack rekey/bye, capability
  hello/update); ví dụ capability 0.7.2 decode → encode lại vẫn qua; 8 mẫu hỏng phải bị từ chối (tự
  kiểm bộ kiểm).
- `ErrorCode` so với **bảng 0.8.1 đọc thẳng từ `00-common-specs.md`** và enum `error.schema.json`;
  `MessageType` so với enum `envelope.schema.json`.

## Lệnh test và kết quả (đầu ra thật, phần cuối)

```
$ cd apple/Packages/HLCrypto && HL_SWIFT_TESTING_PACKAGE=1 swift test
➜ Test "Ghi envelope-roundtrip-apple.json" skipped.
✔ Test "Giải mã file roundtrip của Apple và Android (nếu có)" with 2 test cases passed after 0.008 seconds.
✔ Suite "Kho bí mật" passed after 0.008 seconds.
✔ Suite "Envelope liên nền tảng" passed after 0.009 seconds.
✔ Suite "Vector lịch khóa phiên" passed after 0.010 seconds.
✔ Suite "Vector nguyên thủy mã hóa" passed after 0.010 seconds.
✔ Suite "Vector mã hóa envelope và khung HL" passed after 0.011 seconds.
✔ Test run with 19 tests in 5 suites passed after 0.011 seconds.

$ cd apple/Packages/HLProtocol && HL_SWIFT_TESTING_PACKAGE=1 swift test
✔ Suite "Khung HL và chunk clipboard theo vector S0.1" passed after 0.007 seconds.
✔ Suite "b64/b64u, UUID, danh mục type và mã lỗi" passed after 0.007 seconds.
✔ Suite "Envelope theo vector S0.1" passed after 0.009 seconds.
✔ Suite "Đối chiếu JSON Schema S0.2" passed after 0.013 seconds.
✔ Test run with 18 tests in 4 suites passed after 0.013 seconds.

$ cd apple/Packages/HLTransport && HL_SWIFT_TESTING_PACKAGE=1 swift test
✔ Test "Mọi cạnh của lưu đồ" with 16 test cases passed after 0.001 seconds.
✔ Suite "Máy trạng thái kết nối 0.11" passed after 0.002 seconds.
✔ Suite "Bắt tay phía client (0.6.3) theo session-handshake.json" passed after 0.004 seconds.
✔ Test run with 8 tests in 2 suites passed after 0.004 seconds.

$ cd apple && xcodegen generate
⚙️  Generating plists...
⚙️  Generating project...
⚙️  Writing project...
Created project at /Users/hxd/HandLive/apple/HandLive.xcodeproj

$ cd apple/Packages/HLCrypto && HL_WRITE_ROUNDTRIP=1 HL_SWIFT_TESTING_PACKAGE=1 swift test
✔ Test "Ghi envelope-roundtrip-apple.json" passed after 0.009 seconds.
✔ Test run with 19 tests in 5 suites passed after 0.012 seconds.

$ tools/.venv/bin/python (libsodium giải mã envelope-roundtrip-apple.json)
OK Apple: clipboard push Mac→Android
OK Apple: clipboard push Android→Mac (tiếng Việt)
OK Apple: sms send Mac→Android

$ tools/.venv/bin/python tools/vectors/verify_vectors.py      → Tổng: 360 phép kiểm, 0 lỗi
$ tools/.venv/bin/python tools/vectors/generate_vectors.py --check
THỪA (không do script sinh): envelope-roundtrip-apple.json
THỪA (không do script sinh): envelope-roundtrip.json
check: 14 file, 0 lệch            (exit 0)
```

**App macOS**: không build được (máy không có Xcode). Đã typecheck:
`swiftc -parse-as-library -typecheck -target arm64-apple-macos13.0 macOS/HandLive/handlive-mac-app.swift`
→ exit 0. `xcodebuild test -scheme HLCrypto` (tiêu chí trong phase-00) chưa chạy được tại máy; để CI
(T0.1).

**SwiftLint**: `swiftlint` (brew 0.65.1) mặc định lỗi
`Loading sourcekitdInProc.framework ... failed` vì thiếu Xcode; chạy được với
`TOOLCHAIN_DIR=/Library/Developer/CommandLineTools`:

```
$ cd apple && TOOLCHAIN_DIR=/Library/Developer/CommandLineTools swiftlint lint --strict
Packages/HLDesignSystem/Package.swift:28:1: error: Line Length Violation: ... 146 characters (line_length)
Packages/HLDesignSystem/Tests/HLDesignSystemTests/generator-check-tests.swift:16:19: error: Optional Data -> String Conversion Violation ...
Packages/HLDesignSystem/Tests/HLDesignSystemTests/color-set-tests.swift:64:30: error: Empty Count Violation ...
Done linting! Found 3 violations, 3 serious in 63 files.
```

Mã của M0.1 (HLProtocol, HLCrypto, HLTransport, app) sạch lint. 3 lỗi còn lại thuộc `HLDesignSystem`
(M0.2) — không sửa theo phân quyền. Để hợp phong cách M0.2 đã tắt `trailing_comma`; loại trừ mã sinh
`Packages/*/Sources/*/Generated`.

## Điểm lệch với tài liệu và đề xuất (không sửa `docs/`)

1. **Máy trạng thái 0.11 thiếu cạnh lỗi.** Cài đúng từng cạnh của lưu đồ; sự kiện không có cạnh bị
   bỏ qua. Lưu đồ không nói: `ConnectingLAN` lỗi mạng/TLS khác ghim (không phải `TLS_PIN_MISMATCH`),
   `ConnectingRelay` lỗi (relay không tới được, 401/404), `WaitingPeer` /`ConnectingRelay` mất kết
   nối relay, `Discovering` khi relay tắt (đứng mãi), hủy ghép nối khi chưa `Connected`, hết
   `HANDSHAKE_TIMEOUT` ở phía client. Đề xuất bổ sung vào 0.11: các trạng thái `Connecting*`
   /`WaitingPeer` → `Backoff` khi lỗi; mọi trạng thái → `Idle` khi hủy cặp cuối cùng; `Discovering`
   → `Backoff` sau `LAN_DISCOVERY_GRACE` nếu `relay.enabled = false`.
2. **Keychain trên macOS**: 0.6.1 không nói keychain nào. Đã chọn data-protection keychain
   (`kSecUseDataProtectionKeychain`) để `kSecAttrAccessibleWhenUnlockedThisDeviceOnly` có hiệu lực
   như iOS; cần app ký có keychain access group (tiến trình test không ký nhận -34018), nên unit
   test chỉ kiểm thuộc tính truy vấn và `InMemorySecretStore`. Đề xuất ghi rõ vào 0.6.1 /
   `docs/deployment-guide.md` (entitlement `keychain-access-groups`).
3. **Ack có mã lỗi lạ**: `Ack` decode chặt, mã ngoài 0.8.1 → lỗi parse. 0.5.1 chưa nói bên nhận xử
   lý mã lỗi mới (tương thích tiến) thế nào. Đề xuất: ghi quy tắc (ví dụ coi như `INTERNAL`) trước
   Phase 1.
4. **Trường null của capability**: Android gửi `bt_address: null`, `default_sub_id: null`; Swift bỏ
   hẳn trường khi `nil`. Schema chấp nhận cả hai; không đổi gì, chỉ ghi lại.
5. **Câu chữ "Đã kết nối (LAN)"** (0.11) khác quy ước 3.5 ("cùng mạng Wi-Fi", LAN chỉ trong nhãn
   ngắn). Dùng đúng chuỗi 0.11; đề xuất design system chốt lại khi làm PAIR-02.
6. `generate_vectors.py --check` in "THỪA" cho hai file roundtrip (exit 0, không lỗi). Đề xuất cho
   script bỏ qua `envelope-roundtrip*.json`.

## Ghi chú kỹ thuật

- `test-vector-loader.swift` (đọc vector, hex) được chép vào 3 test target thay vì tạo product
  test-support dùng chung — tránh xuất thư viện chỉ dùng cho test; ~90 dòng mỗi bản.
- `JSONEncoder` trên SDK này không giữ thứ tự khóa, nên file roundtrip ghi bằng bộ ghi thứ tự khóa
  nhỏ trong test; envelope wire và header chunk được dựng thủ công để khớp byte với vector.
- Không log plaintext/khóa; lỗi (`ProtocolError`, `CryptoError`, `HandshakeFailure`) không mang nội
  dung.

Status: DONE_WITH_CONCERNS
Summary: Khung `apple/` (XcodeGen, workspace, SwiftLint) và ba package
HLProtocol/HLCrypto/HLTransport đã dựng, 45 test swift-testing xanh với CLT, qua toàn bộ vector S0.1
(dương khớp byte, âm bị từ chối), đối chiếu schema S0.2 bằng bộ kiểm rút gọn, giải mã được roundtrip
của Android và ghi `envelope-roundtrip-apple.json` (libsodium giải mã được).
Concerns/Blockers: Chưa build app/`xcodebuild test` vì máy không có Xcode (để CI xác nhận); lưu đồ
0.11 thiếu cạnh lỗi (mục lệch 1); Keychain macOS cần entitlement khi ký (mục 2);
`swiftlint --strict` còn 3 lỗi trong `HLDesignSystem` (M0.2).
