# Báo cáo quét bảo mật vbsec

**Phạm vi:** Toàn bộ repo (workspace HandLive: `android/`, `apple/`, `relay/`, `shared/` và công cụ của hub; bỏ `apple/ThirdParty/GRDB` vì là mã vendored)
**Số file:** 1.427 (484 .kt, 562 .swift, 78 .rs, 98 .py, còn lại là cấu hình/JSON/XML) + công cụ và CI của hub
**Ngôn ngữ chính:** kotlin + swift (+ rust, python) (dùng rule chung; python dùng rule chuyên sâu)
**Chế độ:** LỚN (chia tải qua sub-agent) (9 chunk, 0 failed)
**Ngày quét:** 2026-09-28
**Ngôn ngữ báo cáo:** vi

## KẾT LUẬN: ĐẠT

Không phát hiện lỗi nghiêm trọng. Có thể deploy.

Không có lỗi NGHIÊM TRỌNG hoặc CAO. Có 8 lỗi TRUNG BÌNH và 9 lỗi THẤP. Nên sửa các lỗi TRUNG BÌNH trước bản phát hành đầu tiên. Nhóm lỗi đáng chú ý nhất là **path traversal khi nhận clipboard trên Android** và **relay không đáng tin nhưng vẫn điều khiển được việc hủy ghép nối và phát lại envelope**.

---

## TRUNG BÌNH (8)

| File:Dòng | Loại lỗi | Mô tả |
|---|---|---|
| `android/feature/clipboard/src/main/kotlin/app/handlive/android/feature/clipboard/module/ClipFiles.kt:17` | PATH-TRAVERSAL | `transfer_id`/`clip_id` do thiết bị đã ghép gửi tới được ghép thẳng vào `File(dir, …)`, không kiểm tra UUID (đã xác nhận: `PushValidator` không kiểm tra). Một Mac/iPhone bị chiếm quyền có thể tạo, ghi đè hoặc xóa file `.part/.png/.jpg/.txt` ở bất kỳ đâu trong sandbox của app. Sửa: từ chối id không phải UUIDv7 (`BAD_REQUEST`) và kiểm tra `canonicalFile` nằm trong `dir`. Phía Apple đã kiểm tra UUIDv7. |
| `android/feature/call/src/main/kotlin/app/handlive/android/feature/call/module/CallActions.kt:43` | BROKEN-ACCESS-CONTROL | `call_event/action` và `log_sync` chỉ xét công tắc chung `feature.call`, không xét `session.isEffective(Feature.CALL)`. Phiên không thỏa thuận tính năng cuộc gọi vẫn đọc được nhật ký cuộc gọi và kết thúc/từ chối cuộc gọi, trái với CALL-04 E1. |
| `android/core/transport/src/main/kotlin/app/handlive/android/core/transport/server/ConnectionAdmission.kt:55` | MISSING-RATE-LIMIT | Giới hạn kết nối chưa xác thực vào `/v1/ctl` là một bộ đếm chung (16), không chia theo IP. Chỉ `AUTH_FAILED` bị tính vào lệnh chặn IP. Một máy lạ trong Wi-Fi giữ đủ 16 kết nối im lặng là mọi thiết bị đã ghép nhận 4429 và không kết nối lại được. |
| `android/core/transport/src/main/kotlin/app/handlive/android/core/transport/server/ControlServer.kt:148` | MISSING-RATE-LIMIT | `/v1/pair` không đi qua bộ giới hạn kết nối. Trong cửa sổ ghép nối, mỗi kết nối có thể chờ 10 s và đệm tới 256 KiB, nên hàng trăm kết nối song song làm cạn heap hoặc chặn thiết bị thật. |
| `android/feature/connection/src/main/kotlin/app/handlive/android/feature/connection/session/SessionRouter.kt:51` | BROKEN-ACCESS-CONTROL | Chống phát lại (replay) chỉ dựa vào cache id 5 phút / 1.000 id; không kiểm tra `ts`, không có bộ đếm, trong khi khóa phiên sống tới 24 h. Relay (vốn không được tin theo mô hình E2E) có thể gửi lại một `sms/send` hoặc `call_event/action` đã bắt được, sau khi id hết hạn trong cache. Đường LAN không bị ảnh hưởng. |
| `apple/Packages/HLTransport/Sources/HLTransport/ConnectionManager+Supervise.swift:81` | BROKEN-ACCESS-CONTROL | Relay có thể buộc Mac/iPhone hủy ghép nối và xóa SMS, nhật ký cuộc gọi đã đồng bộ mà không cần bằng chứng từ điện thoại (`pair_revoked`, hoặc `session/error PAIR_UNKNOWN` giả mạo trước xác thực), kể cả khi đang có phiên LAN. Hành vi này đúng như đặc tả PAIR-03 API 4 và CONN-03 E4, nên là lỗ hổng ở mức thiết kế và cần sửa đặc tả trước. |
| `relay/crates/relay-server/src/routes/auth.rs:67` | MISSING-RATE-LIMIT | `POST /v1/auth/challenge` không cần xác thực. Giới hạn 10 lần/phút tính theo `device_id` của nạn nhân, và mỗi lần gọi ghi đè challenge đang chờ. Ai biết một `device_id` (không phải bí mật) là khóa được thiết bị đó khỏi relay. Đúng đặc tả CONN-03 API 2, nên cần sửa đặc tả trước. |
| `apple/.github/workflows/ci-apple.yml:91` | OUTDATED-DEPENDENCY | Rủi ro chuỗi cung ứng: action bên thứ ba `maxim-lobanov/setup-xcode@v1` dùng tag có thể bị dời, chạy sau các bước checkout vẫn để `HANDLIVE_REPOS_TOKEN` trong `.git/config` (`persist-credentials` mặc định). Tag bị chiếm là PAT đọc kho riêng bị lộ. |

## THẤP (9)

| File:Dòng | Loại lỗi | Mô tả |
|---|---|---|
| `android/feature/pairing/src/main/kotlin/app/handlive/android/feature/pairing/exchange/PairingCoordinator.kt:231` | BROKEN-ACCESS-CONTROL | Máy lạ trong LAN chưa giành cửa sổ ghép nối vẫn hủy được lượt ghép của người dùng bằng một `pair/hello` sai (`AUTH_FAILED`). |
| `android/feature/pairing/src/main/kotlin/app/handlive/android/feature/pairing/exchange/PairingExchange.kt:220` | BRUTE-FORCE | Khi ghép bằng PIN, điện thoại không tự đếm số lần thử và cấp lại `pair/offer` cho cùng một PIN, nên kẻ tấn công có trọn 120 s để bẻ Argon2id(PIN) offline. Đặc tả chấp nhận rủi ro này; về lâu dài nên dùng PAKE. |
| `android/feature/clipboard/src/main/AndroidManifest.xml:31` | BROKEN-ACCESS-CONTROL | `activity-alias` share được export; app khác gọi trực tiếp (API 29–33) sẽ khiến điện thoại đọc clipboard và gửi sang thiết bị đã ghép, kể cả khi `clip.auto_send` tắt. Kẻ tấn công không nhận được nội dung. |
| `android/feature/sms/src/main/kotlin/app/handlive/android/feature/sms/send/SmsSendPipeline.kt:44` | MISSING-RATE-LIMIT | `sms/send` không giới hạn số SMS theo từng cặp ghép; thiết bị đã ghép bị chiếm quyền có thể gửi hàng loạt. Android `SmsUsageMonitor` giảm nhẹ một phần. |
| `apple/Packages/HLTransport/Sources/HLTransport/ControlSession+Receiving.swift:31` | BROKEN-ACCESS-CONTROL | Phía Mac cũng chỉ chống phát lại bằng cache 5 phút / 1.000 id, nên relay phát lại được envelope trong cùng phiên. |
| `relay/crates/relay-server/src/limits.rs:44` | MISSING-RATE-LIMIT | Giới hạn đăng ký 10/IP/giờ tính theo IPv6 /128, nên xoay địa chỉ trong một /64 là vượt được. `trusted_proxies` mặc định rỗng làm mọi client sau proxy dùng chung một hạn mức. |
| `relay/.github/workflows/ci-relay.yml:32` | OUTDATED-DEPENDENCY | Action pin theo tag hoặc nhánh (`dtolnay/rust-toolchain@stable`, `Swatinem/rust-cache@v2`) trong job đọc được `HANDLIVE_REPOS_TOKEN`. |
| `android/.github/workflows/ci-android.yml:98` | OUTDATED-DEPENDENCY | Action pin theo tag (có `android-actions/setup-android@v3` của bên thứ ba) trong job có `HANDLIVE_REPOS_TOKEN`. |
| `shared/.github/workflows/ci-shared.yml:28` | OUTDATED-DEPENDENCY | `actions/checkout@v5`, `actions/setup-python@v6` pin theo tag (action chính chủ, `contents: read`). |

---

## ĐÃ ĐẠT

- ✓ HARDCODED-SECRET — Mã nguồn không chứa khóa thật. Khóa lưu trong Android Keystore/Keychain (`WhenUnlockedThisDeviceOnly`); `PRK` được niêm phong AEAD; chỉ có placeholder dev và vector test.
- ✓ SQL-INJECTION — sqlx (relay), Room và ContentResolver (Android), GRDB (Apple) đều bind tham số.
- ✓ XSS — Không có WebView; SwiftUI `Text` hiển thị chuỗi thuần, SMS dùng `AttributedString` thuần cộng liên kết từ `NSDataDetector`.
- ✓ IDOR — Relay kiểm tra thành viên cặp và chủ thể JWT; phía điện thoại khóa phiên theo `pairId` đã xác thực.
- ✓ SLOPSQUATTING — Mọi dependency đều là gói phổ biến và được khóa (Cargo.lock, version catalog, pin `==`, SQLCipher kiểm SHA-256).
- ✓ MASS-ASSIGNMENT — Dữ liệu được decode vào struct hoặc data class hẹp.
- ✓ INSECURE-DESERIALIZATION — Chỉ dùng serde, kotlinx.serialization và Codable với kiểu cố định, có giới hạn kích thước.
- ✓ SSRF — URL relay, APNs, FCM lấy từ cấu hình; APNs token được kiểm tra dạng hex.
- ✓ WEAK-PASSWORD-HASHING — XChaCha20-Poly1305 với nonce ngẫu nhiên, HKDF-SHA256, Argon2id đúng đặc tả, so sánh MAC thời gian hằng, TLS 1.3 có pin.
- ✓ JWT-NONE-ALGORITHM — Relay chỉ nhận HS256, bắt buộc `exp`/`sub`, secret ≥ 32 byte.
- ✓ UNRESTRICTED-FILE-UPLOAD — Clipboard giới hạn loại, MIME, kích thước, checksum và dung lượng trống.
- ✓ VERBOSE-ERROR-DEBUG-MODE — Không log nội dung hay khóa; BenchLog chỉ bật ở bản debug; mã lỗi cố định.
- ✓ RACE-CONDITION — Relay dùng `ON CONFLICT`, GETDEL, Lua CAS, `FOR UPDATE`; app dùng worker tuần tự, actor, CAS.
- ✓ COMMAND-INJECTION — Không chạy process từ dữ liệu ngoài; công cụ Python chỉ dùng argv list và `shlex.quote`.

## Gợi ý tăng cường (không phải lỗ hổng)

Các điểm dưới đây không khai thác được, chỉ là gợi ý phòng thủ thêm. Không tính vào kết quả.

- `android/core/crypto/.../identity/DeviceIdentity.kt:51` — Lỗi Keystore tạm thời bị coi là "chưa có khóa" nên danh tính bị tạo lại, làm hỏng mọi cặp ghép. Chỉ nên tạo lại khi khóa chắc chắn đã mất hiệu lực.
- `android/feature/sms/.../module/SmsModule.kt:73` — Yêu cầu SMS chỉ kiểm tra `features.sms` phía điện thoại, chưa xét tính năng đã thỏa thuận của phiên; cùng dạng với lỗi cuộc gọi ở trên.
- `apple/Packages/HLiOSUI/.../IOSAppDelegate.swift:26` — Khóa danh tính và `db_key` nằm trong nhóm Keychain chung mà NSE đọc được; nên để riêng cho app.
- `apple/Packages/HLTransport/.../MessageChannel.swift:62` và `android/core/transport/.../relay/RelayPeerSocket.kt:46` — Hàng đợi nhận không giới hạn; nên có giới hạn và backpressure.
- CI của cả năm kho — Token nằm trong URL `git ls-remote`, và `persist-credentials` đang bật; nên dùng `http.extraHeader` và `persist-credentials: false`.

---

## Bước tiếp theo

Sửa 2 lỗi TRUNG BÌNH chỉ nằm trong mã Android trước: path traversal ở clipboard và kiểm tra tính năng cuộc gọi theo phiên. Nhóm liên quan tới relay (chống phát lại trong một kỳ khóa, hủy ghép có chữ ký của điện thoại, giới hạn challenge) cần sửa đặc tả trước rồi mới sửa mã. Cuối cùng pin action CI theo SHA. Sau đó quét lại để xác nhận.

---

🤖 Báo cáo tạo bởi [vbsec](https://github.com/tanviet12/vbsec)

📄 **Báo cáo đã lưu tại:** `vbsec-reports/scan-2026-09-28-085857.md`

> ⚠️ **Khuyến nghị:** Thư mục `vbsec-reports/` chưa có trong `.gitignore`. Để tránh commit báo cáo vào Git, thêm dòng `vbsec-reports/` vào `.gitignore`.

> Báo cáo này tham khảo — không thay thế cho audit bảo mật chuyên nghiệp.

```json
{
  "verdict": "PASS",
  "summary": {"critical": 0, "high": 0, "medium": 8, "low": 9, "passed": 14},
  "scope": "all",
  "files_reviewed": 1427,
  "primary_language": "kotlin",
  "specialized_rules_used": true,
  "mode": "large",
  "date": "2026-09-28",
  "findings": [
    {"file": "android/feature/clipboard/src/main/kotlin/app/handlive/android/feature/clipboard/module/ClipFiles.kt", "line": 17, "rule_id": "PATH-TRAVERSAL", "severity": "MEDIUM", "issue_summary": "Peer-supplied transfer_id/clip_id used in file paths without UUID validation", "fix_summary": "Reject non-UUIDv7 ids and check canonical path stays in the clip dir"},
    {"file": "android/feature/call/src/main/kotlin/app/handlive/android/feature/call/module/CallActions.kt", "line": 43, "rule_id": "BROKEN-ACCESS-CONTROL", "severity": "MEDIUM", "issue_summary": "Call actions and log_sync ignore the session's negotiated call feature", "fix_summary": "Return FEATURE_DISABLED when !session.isEffective(Feature.CALL)"},
    {"file": "android/core/transport/src/main/kotlin/app/handlive/android/core/transport/server/ConnectionAdmission.kt", "line": 55, "rule_id": "MISSING-RATE-LIMIT", "severity": "MEDIUM", "issue_summary": "Global pre-handshake cap without per-IP share lets one LAN host lock out paired clients", "fix_summary": "Per-IP pending limit and count timeouts/PAIR_UNKNOWN toward the IP block"},
    {"file": "android/core/transport/src/main/kotlin/app/handlive/android/core/transport/server/ControlServer.kt", "line": 148, "rule_id": "MISSING-RATE-LIMIT", "severity": "MEDIUM", "issue_summary": "/v1/pair has no connection admission or per-IP limit", "fix_summary": "Own admission for /v1/pair and a small pair/hello read cap"},
    {"file": "android/feature/connection/src/main/kotlin/app/handlive/android/feature/connection/session/SessionRouter.kt", "line": 51, "rule_id": "BROKEN-ACCESS-CONTROL", "severity": "MEDIUM", "issue_summary": "Replay protection limited to a 5-minute id cache; relay can replay envelopes within a key epoch", "fix_summary": "Reject replays for the whole key epoch (ids or ts freshness), spec first"},
    {"file": "apple/Packages/HLTransport/Sources/HLTransport/ConnectionManager+Supervise.swift", "line": 81, "rule_id": "BROKEN-ACCESS-CONTROL", "severity": "MEDIUM", "issue_summary": "Relay can force unpair and data wipe without proof from the phone", "fix_summary": "Require a phone-signed revoke statement; spec change first"},
    {"file": "relay/crates/relay-server/src/routes/auth.rs", "line": 67, "rule_id": "MISSING-RATE-LIMIT", "severity": "MEDIUM", "issue_summary": "Unauthenticated challenge endpoint rate-limited per victim device_id enables lockout", "fix_summary": "Per-IP limits and non-evicting challenges; spec change first"},
    {"file": "apple/.github/workflows/ci-apple.yml", "line": 91, "rule_id": "OUTDATED-DEPENDENCY", "severity": "MEDIUM", "issue_summary": "Third-party action on mutable tag runs with persisted private-repo token", "fix_summary": "Pin actions to commit SHAs and set persist-credentials: false"},
    {"file": "android/feature/pairing/src/main/kotlin/app/handlive/android/feature/pairing/exchange/PairingCoordinator.kt", "line": 231, "rule_id": "BROKEN-ACCESS-CONTROL", "severity": "LOW", "issue_summary": "Unclaimed LAN client can abort the pairing window", "fix_summary": "Only the claim holder may close the window"},
    {"file": "android/feature/pairing/src/main/kotlin/app/handlive/android/feature/pairing/exchange/PairingExchange.kt", "line": 220, "rule_id": "BRUTE-FORCE", "severity": "LOW", "issue_summary": "PIN offers reissued for the same PIN without phone-side attempt count", "fix_summary": "Count offers per PIN window, require a new PIN after failures; PAKE long term"},
    {"file": "android/feature/clipboard/src/main/AndroidManifest.xml", "line": 31, "rule_id": "BROKEN-ACCESS-CONTROL", "severity": "LOW", "issue_summary": "Exported share alias lets other apps trigger clipboard send without ACTION_SEND", "fix_summary": "Accept only ACTION_SEND via the alias and ignore external extras"},
    {"file": "android/feature/sms/src/main/kotlin/app/handlive/android/feature/sms/send/SmsSendPipeline.kt", "line": 44, "rule_id": "MISSING-RATE-LIMIT", "severity": "LOW", "issue_summary": "No per-pair SMS send limit", "fix_summary": "Per-pair token bucket with RATE_LIMITED, spec first"},
    {"file": "apple/Packages/HLTransport/Sources/HLTransport/ControlSession+Receiving.swift", "line": 31, "rule_id": "BROKEN-ACCESS-CONTROL", "severity": "LOW", "issue_summary": "Mac replay protection limited to a 5-minute id cache", "fix_summary": "Reject stale ts or keep ids for the key epoch"},
    {"file": "relay/crates/relay-server/src/limits.rs", "line": 44, "rule_id": "MISSING-RATE-LIMIT", "severity": "LOW", "issue_summary": "Registration limit keyed on full IPv6 address", "fix_summary": "Normalize IPv6 to /64 and add a global cap"},
    {"file": "relay/.github/workflows/ci-relay.yml", "line": 32, "rule_id": "OUTDATED-DEPENDENCY", "severity": "LOW", "issue_summary": "CI actions pinned to mutable tags/branches with repo token in scope", "fix_summary": "Pin actions to commit SHAs"},
    {"file": "android/.github/workflows/ci-android.yml", "line": 98, "rule_id": "OUTDATED-DEPENDENCY", "severity": "LOW", "issue_summary": "CI actions incl. third-party pinned to mutable tags with repo token in scope", "fix_summary": "Pin actions to commit SHAs"},
    {"file": "shared/.github/workflows/ci-shared.yml", "line": 28, "rule_id": "OUTDATED-DEPENDENCY", "severity": "LOW", "issue_summary": "First-party CI actions pinned to mutable tags", "fix_summary": "Pin actions to commit SHAs"}
  ],
  "hardening_notes": [
    {"file": "android/core/crypto/src/main/kotlin/app/handlive/android/core/crypto/identity/DeviceIdentity.kt", "line": 51, "note": "Transient Keystore error regenerates identity and breaks pairs"},
    {"file": "android/feature/sms/src/main/kotlin/app/handlive/android/feature/sms/module/SmsModule.kt", "line": 73, "note": "SMS requests not gated on negotiated capability"},
    {"file": "apple/Packages/HLiOSUI/Sources/HLiOSUI/IOSAppDelegate.swift", "line": 26, "note": "Identity keys and db_key in keychain group shared with the NSE"},
    {"file": "apple/Packages/HLTransport/Sources/HLTransport/MessageChannel.swift", "line": 62, "note": "Unbounded inbound buffer; add backpressure"},
    {"file": "shared/.github/workflows/ci-shared.yml", "line": 59, "note": "Token in git URL; prefer http.extraHeader and persist-credentials false"}
  ],
  "top_rules_by_count": [
    {"rule_id": "BROKEN-ACCESS-CONTROL", "count": 6},
    {"rule_id": "MISSING-RATE-LIMIT", "count": 5},
    {"rule_id": "OUTDATED-DEPENDENCY", "count": 4},
    {"rule_id": "PATH-TRAVERSAL", "count": 1},
    {"rule_id": "BRUTE-FORCE", "count": 1}
  ]
}
```
