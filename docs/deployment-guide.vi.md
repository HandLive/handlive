[English](deployment-guide.md) | Tiếng Việt

# HandLive: Đóng gói và phân phối

> Kế hoạch phân phối theo quyết định D5, D7 và D8 trong plan gốc. Tệp phát hành do các workflow chạy theo tag tạo ra:
> xem Bản phát hành.

## Ứng dụng Android

- **Play Store.** Cần Permissions Declaration Form cho `READ_SMS`, `SEND_SMS` và `READ_CALL_LOG`, theo ngoại lệ "Cross-device synchronization or transfer of SMS or calls". Khai báo dùng Accessibility API (D4/D12). Chuẩn bị video demo, tài liệu use-case và privacy policy. Nộp sớm ở mốc P1 milestone 2 để biết kết quả trước khi phát hành.
- **Phân phối dự phòng.** Nếu Play Store từ chối quyền SMS, phát hành qua F-Droid và APK trực tiếp. Khi mất `SEND_SMS`, đọc SMS qua Notification Listener.
- **Flavor (plan I8).** `foss` là bản mặc định. Bản này không có Play Services và Firebase, dùng cho F-Droid và APK trực tiếp. `gms` thêm lệnh đánh thức qua FCM cho Play Store. Cấu hình Firebase của `gms` lấy từ thuộc tính Gradle `handlive.fcm.applicationId`, `handlive.fcm.apiKey`, `handlive.fcm.projectId`, `handlive.fcm.senderId`, hoặc biến môi trường `HANDLIVE_FCM_APPLICATION_ID`, `HANDLIVE_FCM_API_KEY`, `HANDLIVE_FCM_PROJECT_ID`, `HANDLIVE_FCM_SENDER_ID`. Kho không chứa `google-services.json`. Để trống cấu hình thì app vẫn build được, chỉ không nhận push.
- **Danh sách cho cổng G2 (trước khi phát hành Phase 2).** Trong Play Console, nộp Permissions Declaration Form cho `READ_SMS` và `SEND_SMS`. `READ_CALL_LOG` thêm vào ở Phase 3. Kèm một video ngắn gồm: màn giới thiệu quyền SMS (SET-01 phần B), hộp thoại xin quyền của hệ thống, tin SMS mới hiện trên Mac, và một tin trả lời gửi từ Mac. Từ Phase 3, video có thêm: cuộc gọi đến hiện trên panel của Mac, trả lời và từ chối cuộc gọi từ Mac, và một cuộc gọi nhỡ. `READ_PHONE_STATE`, `READ_CONTACTS` và `ANSWER_PHONE_CALLS` là quyền runtime, không cần form. URL chính sách quyền riêng tư là trang `docs/privacy.md` đã công bố. Form Data safety điền theo cùng trang đó. Chủ dự án tự nộp form rồi ghi kết quả vào đây.
- **Shizuku** là tùy chọn cho đường âm thanh cuộc gọi Opus/WS. Wizard hướng dẫn cài. Người dùng khởi động lại Shizuku sau mỗi lần bật máy (plan §13 D10).
- **Điều khiển cuộc gọi theo máy (Phase 3).** `TelecomManager.acceptRingingCall()` và `endCall()` đã deprecated từ API 29 nhưng vẫn hoạt động (C12). ROM của hãng có thể chặn chúng; khi đó trả lời và kết thúc cuộc gọi phải chờ HFP (Phase 4). Phần rủi ro của Phase 3 yêu cầu ghi kết quả từng dòng máy ở đây.

| Dòng máy | Phiên bản Android | `acceptRingingCall()` | `endCall()` |
|---|---|---|---|
| Pixel | — | Chưa kiểm | Chưa kiểm |
| Samsung | — | Chưa kiểm | Chưa kiểm |

## Ứng dụng macOS

- Entitlement `keychain-access-groups` (data-protection keychain, 0.6.1). Ký Developer ID cho app, extension camera và driver micro. Target app đặt `ASSETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME = AccentColor`.
- **Cuộc gọi (Phase 3).** `macOS/HandLive.entitlements` có thêm capability Communication Notifications (`com.apple.developer.usernotifications.communication`), dùng cho thông báo liên lạc của cuộc gọi và để đọc trạng thái Tập trung bằng `INFocusStatusCenter`. File cũng có entitlement Time Sensitive Notifications (`com.apple.developer.usernotifications.time-sensitive`). Thiếu entitlement này, thông báo cuộc gọi mức time-sensitive đến ở mức active và không vượt qua chế độ Tập trung. `macOS/Info.plist` khai `INSendMessageIntent` và `INStartCallIntent` trong `NSUserActivityTypes`, cùng `NSFocusStatusUsageDescription` lấy chữ từ khóa catalog `infoplist.focus_status_usage` (bên cạnh `NSBonjourServices` = `_handlive._tcp`, `NSLocalNetworkUsageDescription` và `NSMicrophoneUsageDescription`). Bật cả hai capability cho App ID `app.handlive.mac` trước khi ký.
- **Micro ảo (AudioServerPlugin).** Mac App Store không cài plugin này. Sandbox chặn `/Library/Audio/Plug-Ins/HAL/`. Phân phối theo hai đường:
  - PKG **đã ký và notarized** (`xcrun notarytool submit`, rồi `stapler staple`), nhúng trong app. Lần chạy đầu, app thấy thiếu plugin thì mở PKG bằng Installer. Installer tự xin quyền quản trị. `postinstall` chạy `killall coreaudiod` với quyền root. Không cần privileged helper. `SMJobBless` deprecated từ macOS 13. `launchctl kickstart` bị chặn từ macOS 14.4.
  - Song song: `brew install --cask handlive`. Lệnh này cài cả app và plugin.
- **Camera ảo (CMIOExtension).** System extension nằm trong app bundle, tương thích App Store. Người dùng chấp thuận trong System Settings, mục Login Items & Extensions.
- Yêu cầu macOS 13 trở lên.

## Ứng dụng iOS và iPadOS

Phát hành App Store thông thường. Push đi qua APNs. Yêu cầu iOS 16 trở lên.

- **Định danh.** Bundle id là `app.handlive.ios`. App có thêm target Notification Service Extension. App và extension dùng chung App Group `group.app.handlive`. App Group này cũng là Keychain access group của service `app.handlive.keys` (0.6.1). Nhờ vậy extension đọc được `PRK` khi máy đang mở khóa (C3).
- **Capability của app (tài khoản Apple Developer và `iOS/HandLive.entitlements`).** Cần Push Notifications (`aps-environment`; file ghi `development`, bản ký để phân phối dùng production), App Groups (`group.app.handlive`), Keychain Sharing (`$(AppIdentifierPrefix)app.handlive.ios`, `group.app.handlive`), Communication Notifications (`com.apple.developer.usernotifications.communication`) và Time Sensitive Notifications (`com.apple.developer.usernotifications.time-sensitive`). Communication Notifications dùng cho thông báo liên lạc của SMS-02 (`INSendMessageIntent`) và CALL-01 (`INStartCallIntent`). Time Sensitive Notifications dùng cho cuộc gọi đến. `iOS/Info.plist` khai `INSendMessageIntent` và `INStartCallIntent` trong `NSUserActivityTypes`. Chuỗi mục đích mạng cục bộ (`NSLocalNetworkUsageDescription`, `NSBonjourServices` = `_handlive._tcp`) lấy từ catalog chuỗi (khóa `infoplist.*`, 0.12).
- **Notification Service Extension (`app.handlive.ios.nse`, `iOS/NotificationService.entitlements`, `iOS/NotificationService-Info.plist`).** Cần App Groups và Keychain Sharing (`group.app.handlive`), entitlement Communication Notifications, và `IntentsSupported` = `INSendMessageIntent`, `INStartCallIntent` trong `NSExtension` › `NSExtensionAttributes` (extension point `com.apple.usernotifications.service`). Phase 3 mới thêm entitlement Communication Notifications và `IntentsSupported` cho extension. Thông báo liên lạc của SMS cũng cần hai mục này, nên bản build Phase 2 có thể chưa hiện SMS dưới dạng thông báo liên lạc trên máy thật. App ID `app.handlive.ios` và `app.handlive.ios.nse` đều cần capability Communication Notifications; app cần thêm Time Sensitive Notifications.
- **Khóa APNs.** Tạo một khóa `.p8` trong tài khoản Apple Developer, mục Keys, dịch vụ Apple Push Notifications. Khóa chỉ nằm trên máy chủ relay (`RELAY_APNS_KEY_PATH`, `RELAY_APNS_KEY_ID`, `RELAY_APNS_TEAM_ID`, `RELAY_APNS_TOPIC` = `app.handlive.ios`). Bản build phát triển đăng ký token sandbox.
- **App Review.** Trả lời App Privacy theo `docs/privacy.md`. Ghi chú cho người duyệt rằng app chạy cùng điện thoại Android của chính người dùng có cài HandLive. Kèm video ghép nối và nhận SMS.
- **Tên thiết bị.** Từ iOS 16, điện thoại chỉ thấy tên "iPhone" hoặc "iPad", trừ khi Apple cấp entitlement tên thiết bị do người dùng đặt (`com.apple.developer.device-information.user-assigned-device-name`). Xin entitlement này trước khi phát hành (PAIR-01 trường 3).
- **Biểu tượng app.** Bộ AppIcon (macOS và iOS) và biểu tượng thích ứng Android đã có trong kho app, sinh từ `docs/brand-guidelines.md` bằng `tools/brand/build_brand_assets.py`; trang store dùng file 1024 px và 512 px trong `docs/brand/assets/app-icon/`.

## Cloud relay (Rust)

- Biến môi trường: `DATABASE_URL`, `REDIS_URL`, `RELAY_JWT_SECRET` (byte UTF-8 thô, từ 32 byte, xoay theo lịch). Giới hạn theo IP chỉ tin `X-Forwarded-For` từ reverse proxy đặt trước relay, Caddy hoặc nginx.
- **Push (Phase 2).** APNs bật khi đặt đủ `RELAY_APNS_KEY_PATH`, `RELAY_APNS_KEY_ID`, `RELAY_APNS_TEAM_ID` và `RELAY_APNS_TOPIC`. FCM bật khi đặt `RELAY_FCM_PROJECT_ID` và `RELAY_FCM_SERVICE_ACCOUNT_PATH`. Biến sau trỏ tới file JSON của một service account Google có quyền dùng Firebase Cloud Messaging API. Để file khóa ngoài kho mã, chỉ user chạy relay đọc được. Danh sách biến đầy đủ nằm trong relay/README.md.
- **Giới hạn.** Mỗi IP đăng ký tối đa 10 thiết bị mới mỗi giờ (IPv6 tính theo /64), toàn relay tối đa `RELAY_MAX_REGISTRATIONS_PER_HOUR` (mặc định 1 000). `/v1/auth/*` cho phép 30 yêu cầu mỗi phút mỗi IP. Khi relay lắng nghe trên địa chỉ loopback và `RELAY_TRUSTED_PROXIES` rỗng, relay tin `X-Forwarded-For` từ `127.0.0.1` và `::1` (reverse proxy trên cùng máy). Reverse proxy ở máy khác cần đặt `RELAY_TRUSTED_PROXIES` là địa chỉ của nó; relay ghi cảnh báo khi khởi động nếu biến này rỗng mà relay lắng nghe trên địa chỉ không phải loopback, và khi một peer không được tin gửi `X-Forwarded-For`.
- **Nhiều instance.** Mọi instance dùng chung PostgreSQL và Redis. Redis giữ presence và chuyển khung giữa các instance (C5). `RELAY_INSTANCE_ID` đặt tên instance trong `presence:<device_id>`.
- **D5.** Tự host một VPS (Hetzner hoặc OVH, khoảng 20 USD mỗi tháng) cho Phase 2. Docker và systemd. Relay không giữ trạng thái.
- Mở rộng: theo dõi CPU và băng thông. Cảnh báo khi vượt 70 phần trăm, rồi thêm VPS. Chuyển sang nền tảng managed (fly.io hoặc Railway) khi quá 500 người dùng cùng lúc.
- TLS: Let's Encrypt, kèm cert pinning phía client.
- Ước tính: 100 cuộc gọi Opus cùng lúc khoảng 12 GB mỗi giờ. VPS thông thường, 20 TB mỗi tháng, đủ cho khoảng 1000 người dùng.

## Bản phát hành

Một tag phiên bản build các tệp cài đặt và gắn chúng, mỗi tệp kèm một `.sha256`, vào GitHub Release của tag đó (tạo
mới khi chưa có; tag có hậu tố như `-beta.1` thành bản pre-release). Relay phát hành từ mã nguồn (D5).

| Kho | Workflow | Tệp |
|---|---|---|
| handlive-android | `release-android` | `HandLive-<version>-android-foss.apk`: flavor `foss`, ký bằng khóa release |
| handlive-apple | `release-apple` | `HandLive-<version>-ios-unsigned.ipa`; `HandLive-<version>-macos.zip` (Developer ID, đã notarize) khi đã có secret macOS |

**Ra một bản phát hành:** đặt phiên bản ở mọi kho (Android: `versionName` và một `versionCode` lớn hơn trong
`app/build.gradle.kts`; Apple: `MARKETING_VERSION`, phần số không có hậu tố, và `CURRENT_PROJECT_VERSION` trong
`project.yml`), commit, rồi tạo tag `vX.Y.Z` hoặc `vX.Y.Z-hậu-tố` ở từng kho và push tag của hub và handlive-shared
trước: các workflow checkout hai kho này tại cùng tag, kho nào chưa có tag thì dùng `main` kèm cảnh báo. Workflow dừng
khi tag không khớp phiên bản của kho và cảnh báo khi số build (`versionCode`, `CURRENT_PROJECT_VERSION`) không lớn hơn
của tag trước. Để build lại tệp của một tag đã có, chạy workflow bằng tay: GitHub › Actions › `release-android` hoặc
`release-apple` › Run workflow, hoặc
`gh workflow run release-android.yml --repo HandLive/handlive-android -f tag=v0.1.0-beta.1 -f publish=false`
(`publish=false` giữ tệp làm artifact của workflow và không đụng tới Release; tệp đã gắn chỉ bị thay khi có
`replace=true`).

**Ai giữ khóa:** mỗi workflow build trong một job chỉ có quyền đọc và không có secret, rồi ký và phát hành trong một job
riêng thuộc environment `release`, job này chỉ chạy công cụ ký của nền tảng và `gh`: mã build của bên thứ ba không bao
giờ chạy cạnh khóa ký hay token ghi được Release. Giữ các secret ký trong environment đó (Settings › Environments ›
`release` › Environment secrets), thêm chính mình làm người duyệt bắt buộc và giới hạn cho tag `v*`, và bảo vệ tag bằng
một ruleset (Settings › Rules › Rulesets › Tag, `v*`, hạn chế tạo, sửa và xóa).

**Ký Android (chủ dự án, một lần):** APK được ký sau khi build bằng `apksigner`; thiếu secret thì job ký dừng (bản build
chưa ký vẫn là artifact của workflow) thay vì phát hành một APK không cài hay cập nhật được. Tạo khóa và cất keystore
cùng mật khẩu ở nơi an toàn ngoài máy: ứng dụng đã cài chỉ nhận bản cập nhật ký bằng đúng khóa đó.

```sh
keytool -genkeypair -v -keystore handlive-release.jks -alias handlive -keyalg RSA -keysize 4096 -validity 10000
base64 -i handlive-release.jks | gh secret set ANDROID_RELEASE_KEYSTORE_BASE64 --repo HandLive/handlive-android
gh secret set ANDROID_RELEASE_KEYSTORE_PASSWORD --repo HandLive/handlive-android
gh secret set ANDROID_RELEASE_KEY_ALIAS --repo HandLive/handlive-android --body handlive
```

`gh secret set` không có `--body` sẽ hỏi giá trị, nên mật khẩu không nằm trong lịch sử shell; thêm `--env release` để
giữ secret trong environment. `keytool` tạo keystore PKCS12, có mật khẩu key trùng mật khẩu keystore;
`ANDROID_RELEASE_KEY_PASSWORD` chỉ cần cho keystore JKS cũ có mật khẩu key riêng. Biến kho
`HANDLIVE_RELAY_HOST` và `HANDLIVE_RELAY_EXTRA_PINS` (Settings › Secrets and variables › Variables) cấu hình relay cho
bản phát hành; không có chúng thì bản phát hành không có relay.

**iOS và iPadOS:** IPA là bản build Release cho thiết bị, kèm Notification Service Extension, và chưa ký: các công cụ
sideload ký lại bằng Apple ID của người cài. TestFlight và App Store cần team Apple Developer Program trả phí (ký, mã
định danh App Group và Keychain Sharing, `aps-environment` = production).

**macOS (cần team Apple Developer Program trả phí):** app Mac không ký hoặc ký ad-hoc không mở được data-protection
Keychain (`errSecMissingEntitlement`, -34018) và dừng ở bước tạo khóa, nên workflow chỉ phát hành app Mac khi có đủ
bảy secret; không có secret nào thì chỉ biên dịch, có một phần thì báo lỗi. Nó ký bản Release universal từ trong ra ngoài (`SQLCipher.framework` nhúng
kèm, rồi app với `macOS/HandLive.entitlements`, hardened runtime và dấu thời gian an toàn), notarize bằng
`notarytool`, staple, kiểm app vẫn chạy sau mười giây rồi nén zip. Trước khi ký, nó kiểm profile là profile Developer ID
của `app.handlive.mac`, làm cho đúng chứng chỉ đó và cấp đủ ba capability. Secret của handlive-apple:

| Secret | Nội dung |
|---|---|
| `APPLE_TEAM_ID` | team ID (10 ký tự) |
| `APPLE_DEVELOPER_ID_P12_BASE64`, `APPLE_DEVELOPER_ID_P12_PASSWORD` | chứng chỉ "Developer ID Application" kèm khóa riêng, xuất từ Keychain Access thành `.p12`, base64 |
| `APPLE_MAC_PROFILE_BASE64` | provisioning profile Developer ID của App ID `app.handlive.mac` có Keychain Sharing, Communication Notifications và Time Sensitive Notifications, base64 |
| `APPLE_NOTARY_KEY_P8_BASE64`, `APPLE_NOTARY_KEY_ID`, `APPLE_NOTARY_ISSUER_ID` | một App Store Connect API key (vai trò Developer) để notarize: tệp `.p8` dạng base64, key ID và issuer ID |

Khi app Mac dùng tới tài nguyên mà hardened runtime canh giữ (micro cho âm thanh cuộc gọi, Apple Events cho Xem tiếp
trang web), thêm entitlement tương ứng (`com.apple.security.device.audio-input`,
`com.apple.security.automation.apple-events`) vào `macOS/HandLive.entitlements`; một app extension hay system
extension cần bước ký riêng, và workflow sẽ báo khi gặp.

## CI

Mỗi kho có một workflow CI GitHub Actions trong `.github/workflows/` của kho đó (cộng các workflow phát hành ở mục Bản
phát hành).

- `ci-android` chạy `./gradlew check`.
- `ci-apple` chạy bốn lane macOS song song: test các package lõi; test các package tính năng rồi build app Mac; build
  app iOS; và lane công cụ gồm SwiftLint, kiểm import của package nằm trong dependency đã khai báo, build app Mac cho
  Intel (x86_64) và các công cụ dev. Mỗi lane test build các package của nó một lần qua một scheme chung của
  `HandLive.xcworkspace`.
- `ci-relay` chạy fmt, clippy và test. Test tích hợp dùng PostgreSQL 16 và Redis 7.
- `ci-shared` kiểm vector, vector sinh lại, và schema đối chiếu ví dụ trong tài liệu.
- `ci-docs` ở hub kiểm khuôn tài liệu và schema.

Mỗi workflow dựng lại bố cục workspace bằng `actions/checkout`. Hub nằm ở gốc, checkout trước khi cần tài liệu. Phần mã vào `<phần>/`. `handlive-shared` vào `shared/`. Tên kho lấy theo `${{ github.repository_owner }}/handlive-<phần>`. Cả năm kho phải nằm cùng một organization và giữ đúng tên: `handlive`, `handlive-android`, `handlive-apple`, `handlive-relay`, `handlive-shared`.

Kho private: tạo secret `HANDLIVE_REPOS_TOKEN` ở cấp organization. Token là fine-grained PAT hoặc token GitHub App, quyền Contents: read trên năm kho. Kho public thì `github.token` đủ.

Sửa `shared/` hoặc tài liệu không tự kích hoạt CI nền tảng. Chạy tay bằng `workflow_dispatch`. Mỗi workflow lấy nhánh trùng tên của `handlive-shared` và hub nếu có, ví dụ `feat/phase-01-clipboard` ở mọi kho. Không có nhánh đó thì dùng `main`. Bật branch protection. Nhánh `main` mỗi kho phải qua check tương ứng.

handlive-apple tải XCFramework của SQLCipher bằng `ThirdParty/SQLCipher/fetch.sh`, có kiểm SHA-256. Framework không được commit. Chạy script này một lần sau khi clone. CI tự chạy script và cho job tối đa 90 phút.

## Tăng tốc USB (tùy chọn)

ADB port-forward (`adb forward tcp:PORT tcp:PORT`). Tự nhận cáp qua IOKit `IOServiceAddMatchingNotification`. Wizard ba bước bật USB Debugging lần đầu. Các lần sau tự chuyển. UVC native để dành cho v2.
