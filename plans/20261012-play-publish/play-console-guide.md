# Hướng dẫn điền Play Console: Thông tin đăng nhập và mapping R8 (2026-10-12)

Tài liệu dùng một lần, không phải spec sản phẩm. Dẫn chứng kỹ thuật lấy từ `docs/detailed-design/01-setup-settings.md`,
`docs/detailed-design/02-pairing.md` và `docs/deployment-guide.md` (mục G2).

## 1. Trạng thái các mục trên Play Console (sếp đã hoàn tất)

Trong **«Nội dung ứng dụng»** và **«Cài đặt cửa hàng»**:

- **Mục 2 «Thông tin đăng nhập» (App access):** Đã chọn **«Có»**. Đoạn tiếng Anh để dán nằm ở mục 2.
- **Loại ứng dụng:** **«Ứng dụng»**. **Danh mục:** **«Năng suất»**.
- **Thẻ:** **«Công cụ»**, **«Liên lạc»**, **«Nhắn tin văn bản»**, **«Năng suất»**. Không dùng **«Trình quét mã vạch»**.
- **Xếp loại nội dung (IARC):** Đã nộp. Kết quả **IARC 3+** (PEGI 3, ESRB Mọi người, USK 0, L). Nhãn duy nhất: **«Người dùng tương tác»**.
- **An toàn dữ liệu (Data safety):** Đã khai báo theo `docs/privacy.md` (mã hóa đầu cuối, không lưu trên máy chủ trung gian).

## 2. Hướng dẫn mục «Thông tin đăng nhập» (App access)

Chọn **«Có»**. Không chọn **«Không»**. Sếp đã chọn **«Có»**.

### Lý do kỹ thuật

HandLive không dùng tài khoản hay mật khẩu. Tính năng cốt lõi (xem bảng nhớ tạm, SMS và cuộc gọi từ Android trên Mac, iPhone hoặc iPad) chỉ chạy sau khi ghép đôi thiết bị (PAIR-01). Ghép đôi cần thiết bị thứ hai (Mac, iPhone hoặc iPad đang chạy HandLive) để hiện mã QR hoặc mã PIN 6 số (`docs/detailed-design/02-pairing.md` §2.1.1).

Chính sách Google Play coi «Yêu cầu mã QR» và «Cần thao tác trên thiết bị thứ hai» là lý do hợp lệ để chọn **«Có»**. App không có chế độ demo. Người duyệt không mở được màn hình đồng bộ nếu khai báo **«Không»**.

### Đoạn tiếng Anh dán vào ô hướng dẫn cho người duyệt (tối đa 500 ký tự)

Dán đoạn sau (440 ký tự, đã tính khoảng trắng):

```text
HandLive requires no login credentials. Core features (syncing clipboard, SMS, and calls to Mac/iOS) require pairing with a second device by scanning a QR code or entering a 6-digit PIN generated on that device (same LAN). Without a second device, reviewers can inspect the welcome, pairing, and settings screens. All permissions are requested just-in-time when enabling features. A pairing and feature demo video is available upon request.
```

### Bản giải trình chi tiết (dùng khi phúc khảo, hoặc khi Google hỏi qua email)

```text
HandLive has no account, username, or password. Its core feature — mirroring an Android phone's clipboard, SMS, and calls to a Mac, iPhone, or iPad — only works after the phone is paired with that second device, and pairing requires either:
  (a) scanning a QR code shown on the Mac/iPhone/iPad app, or
  (b) typing a 6-digit PIN shown on that same second-device app (LAN only, 120-second validity).

There is no demo mode and no way to pair with only the Android phone, because the second device must generate the QR code or PIN (docs/detailed-design/02-pairing.md, PAIR-01).

To review every screen:
1. Install HandLive on an Android device (API 29+). On first launch it shows a welcome screen, asks for notification permission (Android 13+), and starts a foreground connection service — no login at this point (docs/detailed-design/01-setup-settings.md, SET-01 Part A).
2. Without a second device, the reviewer can inspect: the welcome/privacy screen, the "Pair a Device" screen with "Scan QR Code" and "Enter PIN" buttons (SET-01 step 7), and the Settings screen listing feature cards ("Auto-Send on Copy", "SMS Messages", "Calls", "Calls from Other Apps", "Take Calls on Mac", "Use Phone as Webcam") each showing "Needs permission" or "Not supported" (SET-01 field 10). None of these screens requires a login.
3. To reach the paired, functional screens (clipboard, SMS, and call mirroring), a second device running the HandLive Mac or iOS app must generate a QR code or a PIN. The Android app then scans the code, or the user enters the PIN. A demo video can be provided on request if the reviewer cannot pair two devices during review.

Permissions requested, and why (all requested just-in-time per feature, never at first launch):
  - CAMERA: only to scan the pairing QR code, or to stream the phone as a webcam if enabled.
  - READ_SMS, SEND_SMS, READ_CONTACTS, READ_PHONE_STATE: only if the user turns on "SMS Messages", to show and send SMS from the paired device and select the active SIM.
  - READ_PHONE_STATE, READ_CALL_LOG, ANSWER_PHONE_CALLS, READ_CONTACTS: only if the user turns on "Calls", to show caller ID and call history and let the user answer/decline from the paired device.
  - Notification access (special access granted in system Settings): only if the user turns on "Calls from Other Apps" (reads call notifications from calling apps only).
  - Accessibility service: only if the user turns on "Auto-Send on Copy", to detect new clipboard copies and send automatically; manual sending works without it.
A denied or skipped permission simply leaves that one feature off; it never blocks the rest of the app (docs/detailed-design/01-setup-settings.md, SET-01 "Feature independence").
```

### Nếu Google vẫn yêu cầu xem toàn bộ ứng dụng

Phương án (chờ sếp duyệt, không sửa mã nguồn):

- Gửi video quay màn hình: ghép đôi hai thiết bị, rồi dùng bảng nhớ tạm, SMS và cuộc gọi.
- Trả lời email Google App Review bằng các luận điểm kỹ thuật ở trên.
- Thêm chế độ demo làm đổi hành vi sản phẩm. Sếp quyết riêng nếu video không được chấp thuận.

## 3. Tệp mapping R8

Bản phát hành dùng Android App Bundle (`.aab`) của flavor `gms`, build type `release` (task Gradle `:app:bundleGmsRelease`). R8 xuất file mapping tại:

```
android/app/build/outputs/mapping/gmsRelease/mapping.txt
```

Nộp lên Play Console theo một trong hai cách:

- **Tự động qua tệp AAB (khuyến nghị):** Tải tệp `.aab` đã ký lên trang phát hành. Play Console tự lấy `mapping.txt` trong gói. Không cần tải tay.
- **Tải thủ công:** Vào bản phát hành đã tạo, mở **Khám phá gói ứng dụng** (App bundle explorer), chọn đúng mã phiên bản (version code), rồi **Tải xuống** (Downloads) và **Tải tệp ánh xạ lên** (Upload mapping file, ReTrace). Chọn `mapping.txt` theo đường dẫn trên.

*Lưu ý:* R8 chỉ ghi tệp này khi flavor `gms`, build type `release`, bật `isMinifyEnabled = true` (task #22).

## 4. Khai báo quyền nhạy cảm trong «Nội dung ứng dụng»

Theo `docs/deployment-guide.md` mục G2 (Gate G2 checklist):

1. **Biểu mẫu khai báo quyền (Permissions Declaration Form):** Khai báo `READ_SMS`, `SEND_SMS` và `READ_CALL_LOG`. `READ_CALL_LOG` đã có trong `android/feature/call/src/main/AndroidManifest.xml:8`, nên nộp cùng lúc. Lý do chọn: **"Cross-device synchronization or transfer of SMS or calls"**. Không khai báo `RECEIVE_SMS`: app không dùng quyền này. Tin nhắn mới đi qua `ContentObserver` (`android/feature/sms/src/main/AndroidManifest.xml:4-5`).
2. **Video minh họa kèm biểu mẫu:** Quay màn hình giải thích quyền SMS trước khi xin cấp quyền (SET-01 field 12), hộp thoại xin quyền của hệ thống, SMS mới hiện trên Mac, và tin trả lời gửi từ Mac. Nếu bản phát hành có Calls: quay thêm cuộc gọi đến trên Mac, nhận hoặc từ chối trên Mac, và thông báo cuộc gọi nhỡ.
3. **Quyền thường, không cần biểu mẫu riêng** (quyền lúc chạy): `READ_PHONE_STATE`, `READ_CONTACTS`, `ANSWER_PHONE_CALLS`.
4. **Khai báo Accessibility API:** Khai báo có dùng Hỗ trợ tiếp cận, đặt `isAccessibilityTool = false`, kèm mô tả ngắn và màn hình xin chấp thuận trong app (CLIP-01, văn bản tại SET-01 field 13). Sếp đã duyệt rủi ro này (quyết định C15, `docs/detailed-design/01-setup-settings.md`, mục "Special requirements").
5. **Khai báo Foreground service:** Khai báo loại `connectedDevice` trong Play Console (Play Console yêu cầu giải trình riêng khi app khai báo `FOREGROUND_SERVICE_TYPE_CONNECTED_DEVICE`, SET-01 API 3).
6. **Yêu cầu bỏ qua tối ưu hóa pin (`REQUEST_IGNORE_BATTERY_OPTIMIZATIONS`):** Lý do: "Ứng dụng đồng hành (companion app) cần duy trì kết nối nền liên tục với thiết bị đã ghép đôi" (SET-01 mục "Special requirements").
7. **Đường dẫn chính sách quyền riêng tư (Privacy policy URL):** `https://github.com/HandLive/handlive/blob/main/docs/privacy.md` (bản tiếng Anh; bản tiếng Việt tại `docs/privacy.vi.md` khi Play Console yêu cầu ngôn ngữ tương ứng). Khai báo **An toàn dữ liệu** (Data safety) theo `docs/privacy.md` (mã hóa đầu cuối, không lưu trên máy chủ trung gian).

Mục G2 trong `docs/deployment-guide.md`: sếp nộp các biểu mẫu này và ghi kết quả vào tài liệu sau khi xong.
