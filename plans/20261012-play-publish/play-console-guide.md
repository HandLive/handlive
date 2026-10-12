# Hướng dẫn điền Play Console: Thông tin đăng nhập & mapping R8 (2026-10-12)

Tài liệu một lần, không phải spec sản phẩm. Dẫn chứng lấy từ `docs/detailed-design/01-setup-settings.md`,
`docs/detailed-design/02-pairing.md` và `docs/deployment-guide.md` (mục G2).

## 1. Mục "Thông tin đăng nhập" (App access)

**Chọn "Có" (Yes, this app requires login credentials), không chọn "Không".**

### Vì sao

HandLive không có tài khoản hay mật khẩu, nhưng tính năng chính — xem bảng nhớ tạm, SMS, cuộc gọi của
Android trên Mac/iPhone/iPad — chỉ hoạt động sau khi ghép đôi (PAIR-01), và việc ghép đôi bắt buộc có
**một thiết bị thứ hai** (Mac hoặc iPhone/iPad chạy app HandLive) quét mã QR hoặc nhập PIN hiển thị trên
thiết bị đó (`docs/detailed-design/02-pairing.md` §2.1.1 Description, field 1, field 6). Google Play liệt
"Yêu cầu mã QR" và "Yêu cầu thao tác trên một thiết bị khác" là hai lý do hợp lệ để chọn "Có" dù không có
đăng nhập thật. App không có chế độ demo/giả lập ghép đôi — người duyệt không tự vượt qua được bước này
nếu khai "Không".

### Đoạn tiếng Anh dán vào ô hướng dẫn cho người duyệt

```
HandLive has no account, username, or password. Its core feature — mirroring an Android phone's
clipboard, SMS, and calls to a Mac, iPhone, or iPad — only works after the phone is paired with that
second device, and pairing requires either:
  (a) scanning a QR code shown on the Mac/iPhone/iPad app, or
  (b) typing a 6-digit PIN shown on that same second-device app (LAN only, 120-second validity).

There is no demo mode and no way to pair with only the Android phone, because the second device must
generate the QR code or PIN (docs/detailed-design/02-pairing.md, PAIR-01). To review every screen:

1. Install HandLive on an Android device (API 29+). On first launch it shows a welcome screen, asks for
   notification permission (Android 13+), and starts a foreground connection service — no login at this
   point (docs/detailed-design/01-setup-settings.md, SET-01 Part A).
2. Without a second device, the reviewer can see: the welcome/privacy screen, the "Pair a Device" screen
   with "Scan QR Code" and "Enter PIN" buttons (SET-01 step 7), and the Settings screen listing feature
   cards ("Auto-Send on Copy", "SMS Messages", "Calls", "Calls from Other Apps", "Take Calls on Mac", "Use
   Phone as Webcam") each showing "Needs permission" or "Not supported" (SET-01 field 10). None of these
   screens require login.
3. To reach the paired, functional screens (clipboard/SMS/call mirroring), a second device running the
   HandLive Mac or iOS app must generate a QR code or PIN for the Android app to consume. We can provide a
   short screen-recorded video of a full pairing + mirroring session on request if the reviewer cannot
   pair two devices during review.

Permissions requested, and why (all requested just-in-time per feature, never at first launch):
  - CAMERA: only to scan the pairing QR code, or to stream the phone as a webcam if the user turns that
    feature on.
  - READ_SMS, SEND_SMS, READ_CONTACTS, READ_PHONE_STATE: only if the user turns on "SMS Messages", to show
    and send SMS from the paired Mac/iPhone/iPad and pick the right SIM.
  - READ_PHONE_STATE, READ_CALL_LOG, ANSWER_PHONE_CALLS, READ_CONTACTS: only if the user turns on "Calls",
    to show caller ID and call history and let the user answer/decline from the paired device.
  - Notification access (special access, granted by hand in system Settings): only if the user turns on
    "Calls from Other Apps"; HandLive reads call notifications from calling apps only, nothing else.
  - Accessibility service: only if the user turns on "Auto-Send on Copy", to detect a new clipboard copy
    and send it automatically; a manual "Send Clipboard" button works without it.
A denied or skipped permission simply leaves that one feature off; it never blocks the rest of the app
(docs/detailed-design/01-setup-settings.md, SET-01 "Feature independence").
```

### Nếu Google vẫn yêu cầu xem được toàn bộ app

Phương án, **sếp chọn**, đội không tự thêm chế độ demo vào app:
- Gửi kèm video quay màn hình một lượt ghép đôi + xem thử clipboard/SMS/cuộc gọi thật (dùng 2 máy có sẵn).
- Trả lời email App Review của Google (nếu họ hỏi thêm) dẫn lại đúng đoạn hướng dẫn trên.
- Việc thêm chế độ demo/tài khoản giả lập để tự chạy hết app là đổi hành vi sản phẩm — ngoài phạm vi
  hướng dẫn này, cần sếp quyết riêng nếu Google từ chối sau khi đã gửi video.

## 2. Tệp mapping R8

Bản phát hành dùng Android App Bundle (`.aab`) của flavor `gms`, build type `release`, task Gradle
`:app:bundleGmsRelease`. Theo quy ước AGP, R8 sinh file tại:

```
android/app/build/outputs/mapping/gmsRelease/mapping.txt
```

Nộp lên Play Console theo một trong hai cách:

- **Tải AAB qua Play Console (khuyến nghị):** khi upload `.aab` được ký ở trang "App bundle explorer" của
  release, Play Console tự lấy `mapping.txt` đi kèm trong bundle — không cần tải tay.
- **Tải tay (nếu dùng công cụ ký ngoài hoặc Play Console chưa nhận mapping tự động):** vào release đã
  tạo → **App bundle explorer** → chọn đúng version code → mục **Downloads** → **Upload mapping file**
  (ReTrace) → chọn file `mapping.txt` ở đường dẫn trên.

Lưu ý: file này chỉ sinh ra **sau khi** R8 (`isMinifyEnabled = true`) được bật cho build type release của
flavor `gms` (việc này thuộc task Android #22, đang làm riêng). Trước khi R8 bật, `app/build.gradle.kts`
đặt `isMinifyEnabled = false` nên không có `mapping.txt` để nộp.

## 3. Khai báo liên quan quyền nhạy cảm (Permissions Declaration, Data safety)

Theo `docs/deployment-guide.md` mục G2 (Gate G2 checklist):

1. **Permissions Declaration Form:** nộp cho `READ_SMS`, `SEND_SMS` và `READ_CALL_LOG` (quyền này đã có
   trong `android/feature/call/src/main/AndroidManifest.xml:8`, nên khai cùng lúc), chọn lý do **"Cross-
   device synchronization or transfer of SMS or calls"**. Không khai `RECEIVE_SMS` — app không xin quyền
   này, tin nhắn mới được phát hiện bằng `ContentObserver` (`android/feature/sms/src/main/AndroidManifest.xml:4-5`).
2. **Video minh hoạ kèm form:** quay cảnh hiện lời giải thích SMS trước khi xin quyền (SET-01 field 12),
   hộp thoại hệ thống xin quyền, một SMS mới xuất hiện trên Mac, và một tin trả lời gửi từ Mac; nếu bản
   phát hành này đã có tính năng Calls thì quay thêm một cuộc gọi tới hiện trên Mac, bấm nhận/từ chối từ
   Mac, và một cuộc gọi nhỡ.
3. **Quyền khác không cần form riêng** (là quyền runtime, hệ thống tự hỏi): `READ_PHONE_STATE`,
   `READ_CONTACTS`, `ANSWER_PHONE_CALLS`.
4. **Accessibility API declaration:** khai có dùng Accessibility, đặt `isAccessibilityTool = false`, kèm
   mô tả ngắn và màn hình xin sự đồng ý trong app (CLIP-01, đoạn text ở SET-01 field 13) — rủi ro bị từ
   chối đã được sếp chấp nhận trước (quyết định C15, `docs/detailed-design/01-setup-settings.md` mục
   "Special requirements").
5. **Foreground service type:** khai `connectedDevice` trong Play Console (Play Console hỏi riêng mục này
   khi app dùng `FOREGROUND_SERVICE_TYPE_CONNECTED_DEVICE`, SET-01 API 3).
6. **`REQUEST_IGNORE_BATTERY_OPTIMIZATIONS`:** lý do khai là "app đồng hành (companion app) cần giữ kết
   nối liên tục với thiết bị đã ghép đôi" (SET-01 mục "Special requirements").
7. **Privacy policy URL (cả Store listing và Data safety form):** `https://github.com/HandLive/handlive/blob/main/docs/privacy.md`
   (bản tiếng Anh; `docs/privacy.vi.md` là bản tiếng Việt, không cần link riêng trừ khi Play Console hỏi
   bản ngôn ngữ khác). Điền **Data safety** từ chính nội dung `docs/privacy.md` (dữ liệu nào được đọc,
   có rời khỏi thiết bị không — toàn bộ qua kênh E2E, server không đọc được).

Mục G2 trong `docs/deployment-guide.md` ghi rõ: **sếp là người nộp các form này và ghi lại kết quả** vào
chính mục đó sau khi nộp.
