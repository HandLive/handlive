# Đẩy HandLive Android lên Google Play (Internal testing)

**Status:** in progress. Owner đã có Play Console dev account + handlive-android repo local
(`/Users/hxd/HandLive/android`, branch `main`, sạch trước khi sửa). Mục tiêu: lên track **Internal
testing** trước (owner chọn), Production để sau.

## Quyết định owner đã chốt (2026-10-07)

1. **Package name:** `com.handlive.android` (owner chọn, khác namespace code `app.handlive.android`).
   Đã đổi `applicationId` trong `app/build.gradle.kts`; `namespace` giữ nguyên `app.handlive.android`
   (manifest dùng `${applicationId}` cho provider authorities/permission nên không cần sửa gì khác
   trong source). Đã cập nhật 4 chỗ hardcode package trong `shared/tools/e2e/` (`adb_device.py`,
   `scenario_app_calls.py`, `scenario_clipboard.py`, `self_test.py`) — chỉ phần package trước `/`,
   phần class name sau `/` vẫn `app.handlive.android.*` vì dùng namespace.
2. **Privacy policy URL — đã giải quyết (2026-10-09):** site WordPress đã deploy ở staging
   `handlive.hxd.app`, verify trực tiếp còn sống: `https://handlive.hxd.app/privacy/` và
   `https://handlive.hxd.app/vi/quyen-rieng-tu/`, nội dung khớp `docs/privacy.md`/`.vi.md` mới nhất.
   Dùng 2 URL này cho Play Console/App Store Connect, không cần link GitHub blob tạm nữa.
3. **Commit targetSdk + applicationId:** đã tạo nhánh `fix/google-play-submission-readiness` ở cả
   `android/` và `shared/`, commit xong (chi tiết dưới). **Chưa push, chưa tạo PR** — chờ owner
   duyệt trước khi push (xem "Việc tiếp theo").

## Việc đã làm (code side)

- [x] Xác nhận quyền hạn (manifest) thật: `READ_SMS`, `SEND_SMS`, `READ_CONTACTS`, `READ_PHONE_STATE`,
  `READ_CALL_LOG`, `ANSWER_PHONE_CALLS`, Accessibility (`ClipboardAccessibilityService`), Notification
  Listener (`AppCallListenerService`, không cần form khai báo riêng).
- [x] `targetSdk 35 → 36`: Google Play bắt app **mới nộp lần đầu** target API 36 (Android 16) từ
  31/8/2026, không có extension cho app mới (chỉ app cũ được gia hạn tới 1/11/2026).
- [x] `applicationId app.handlive.android → com.handlive.android` (namespace giữ nguyên).
- [x] Build `assembleFossRelease` (APK) và `bundleFossRelease` (AAB) sau cả 2 đổi: **BUILD
  SUCCESSFUL** cả hai lần. Xác nhận bằng cách unzip AAB đọc `AndroidManifest.xml` binary: package =
  `com.handlive.android`, provider authorities/permission tự theo `${applicationId}` đúng, class
  name (Activity/Service) vẫn `app.handlive.android.*` đúng như kỳ vọng.
- [x] `shared/tools/e2e/self_test.py` sau khi sửa: **0 failed** (37 test, kể cả `uiautomator dump
  parsed`).
- [x] Commit, nhánh `fix/google-play-submission-readiness`:
  - `android/`: `bb34c50` — "fix(android): Play Store submission readiness (applicationId, target API 36)"
  - `shared/`: `23ead03` — "fix(e2e): follow android's new applicationId com.handlive.android"
- [x] Soát ảnh chụp màn hình `docs/screenshots/android/*.en.png`: 540×1200 px, tỉ lệ 2.22:1 —
  **vượt giới hạn Play (tối đa 2:1)**. Không chặn Internal testing (Play cho bắt đầu test trước khi
  hoàn thiện store listing) nhưng phải chụp lại/resize trước khi làm store listing đầy đủ cho
  Production.
- [x] Store copy có sẵn, không cần viết lại: `docs/brand-guidelines.md` §4 (one-liner, Play short
  description ≤80 ký tự, đoạn mở đầu, boilerplate).
- [x] AAB chưa ký ở `android/app/build/outputs/bundle/fossRelease/app-foss-release.aab` (16.5 MB) —
  Play Console chỉ nhận AAB đã ký; lệnh ký ở `play-console-checklist.md`.

## Đã merge vào main (2026-10-07, owner nói "em hãy tự merge đi, chốt")

- `android`: PR [#14](https://github.com/HandLive/handlive-android/pull/14) → merge `94ee21b`.
  CI lần đầu fail (`gradlew check`): `AppLanguageSettingTest` còn hardcode package cũ
  (`"package:app.handlive.android"`), và 1 test không ghim `@Config(sdk=...)` rơi vào SDK 36 mặc
  định theo targetSdk mới, Robolectric 4.17 chưa shadow sạch API 36
  (`IllegalAccessException` trong `AndroidInterceptors`, không liên quan logic test đó). Sửa:
  cập nhật package literal + ghim `@Config(sdk = [35])` giống 2 test láng giềng trong cùng file.
  Commit fix `21a2e74`, CI xanh lại, đã merge.
- `shared`: PR [#9](https://github.com/HandLive/handlive-shared/pull/9) → merge `cc36bf2`. CI xanh
  ngay từ đầu.
- GitHub `git push` lúc đầu bị lỗi `Internal Server Error` (500) 3 lần liên tiếp cả 2 repo —
  GitHub tạm trục trặc phía server, không phải lỗi từ phía mình; thử lại thì qua.

## Việc tiếp theo (thứ tự ưu tiên, chỉ owner làm được — Play Console cần tài khoản/thao tác tay)

1. Ký AAB bằng `jarsigner` với keystore riêng (lệnh ở `play-console-checklist.md`, không gõ
   password vào chat agent). **Lưu ý:** build lại AAB từ `main` mới nhất trước khi ký (code đã đổi
   sau lần build thử ban đầu).
2. Tạo app trong Play Console với package `com.handlive.android`, upload AAB vào Internal
   testing, add email owner làm tester trước.
3. Nộp song song (không chặn Internal testing nhưng chặn Production/Closed/Open mở rộng sau):
   Data safety form, Permissions Declaration Form (use case "Cross-device synchronization or
   transfer of SMS or calls"), Accessibility API declaration form, Content rating questionnaire —
   nội dung draft ở `play-console-checklist.md`. Privacy policy URL dùng `handlive.hxd.app` ở trên.
4. ~~Chụp lại screenshots đúng tỉ lệ ≤2:1~~ — **xong** (1080×1920, 8 màn × 2 ngôn ngữ, merged
   2026-10-09, PR hub #23).

Chi tiết nộp form, script video demo, data-safety mapping: [play-console-checklist.md](play-console-checklist.md).

## Câu hỏi còn mở

- (không còn — owner đã chốt mọi quyết định code-side; phần còn lại nằm hoàn toàn trong Play
  Console, chỉ owner thao tác được)
