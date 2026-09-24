# HandLive — Code Standards

> Chưa có code. Đây là quy ước sẽ áp dụng khi implement. Bổ sung/điều chỉnh khi codebase hình thành.

## Chung

- Ưu tiên YAGNI, KISS, DRY (theo thứ tự đó).
- File >200 dòng → cân nhắc modular hóa theo ranh giới logic (function/class/concern).
- File mới: kebab-case, tên dài mô tả rõ (self-documenting cho công cụ LLM). Không áp dụng cho markdown/config/script.
- Không fake data/mock/shortcut chỉ để pass check. Implement hành vi thật.
- Không commit secret, dotenv, token, key, credential.
- Conventional commits, không tham chiếu AI trong message.

## Wire protocol (ổn định — mọi nền tảng phải khớp)

- Envelope JSON: `{v, type, id (uuid-v7), ts (ms), payload (base64 XChaCha20-Poly1305)}`.
- Audio binary frame: `[0x48 0x4C][ver:1B][seq:4B][ts:4B][encrypted_opus:NB]`.
- Magic bytes `0x484C` ("HL"). Không đổi format tùy tiện giữa các platform.

## Android (Kotlin)

- minSdk 29, targetSdk 35. Foreground Service đúng type (`FOREGROUND_SERVICE_CONNECTED_DEVICE` / `camera|microphone`).
- Crypto qua Tink; audio codec libopus qua JNI.
- Mọi BT-HFP call sau abstraction `CallAudioRelay` (impl: `HfpCallAudioRelay`, `CdmCallAudioRelay` tương lai).
- OEM fragmentation → strategy pattern (`BtAdapterStrategy`: Samsung/Pixel/Generic).

## macOS / iOS (Swift 6)

- Crypto qua CryptoKit (`Curve25519`, `ChaChaPoly`).
- Bọc mọi `IOBluetooth*` call trong protocol abstraction (API legacy, rủi ro deprecate).
- CMIOExtension / AudioServerPlugin ký Developer ID (bắt buộc; ad-hoc bị reject).
- Key vào Keychain với `kSecAttrAccessibleWhenUnlockedThisDeviceOnly`.

## Rust (cloud relay)

- Actix-web + actix-ws. Stateless để scale horizontal.
- Zero-knowledge: không decrypt, không log payload. Chỉ metadata tối thiểu.

## Test

- Chạy test hẹp nhất trước, mở rộng khi đụng contract chung.
- Audio: verify dual-layer encryption. BT: test matrix ≥6 device thật (Samsung/Pixel/Xiaomi/OPPO).
- Không giấu test/lint/type/build fail.
