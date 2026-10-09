# Play Console — nội dung nộp (draft, owner tự điền trong Console)

## 1. Ký AAB (owner tự chạy, không gõ password vào chat agent)

```sh
cd /Users/hxd/HandLive/android
jarsigner -verbose -sigalg SHA256withRSA -digestalg SHA-256 \
  -keystore ~/Documents/HandLive-keys/handlive-release.jks \
  app/build/outputs/bundle/fossRelease/app-foss-release.aab handlive
jarsigner -verify app/build/outputs/bundle/fossRelease/app-foss-release.aab
```

`jarsigner` tự hỏi password keystore, không echo ra terminal, không vào shell history. Alias key là
`handlive` (theo `docs/deployment-guide.md`). File `.aab` sau khi ký là file upload vào Play Console
(Release > Internal testing > Create new release).

Play App Signing: khi upload lần đầu, chọn để Google quản lý signing key (khuyến nghị, bắt buộc với
app mới) — keystore của owner chỉ là **upload key**.

## 2. Store listing copy (có sẵn, lấy từ `docs/brand-guidelines.md`)

- App name: HandLive
- Short description (≤80 ký tự): "Clipboard, SMS, and calls from your phone on your Mac, iPhone,
  and iPad."
- Full description, đoạn mở: "Your Android phone, within reach. HandLive brings clipboard, SMS, and
  calls to your Mac, iPhone, and iPad — end-to-end encrypted, no account needed, open source."
  (ghép thêm elevator pitch + 3 message pillars trong brand-guidelines.md §4 nếu cần dài hơn)
- Icon: `docs/brand/assets/app-icon/handlive-play-store-512.png`
- Feature graphic: `docs/brand/assets/promo/feature-graphic-play.en.png` (+ `.vi.png`), 1024×500 — đã có.
- Screenshots: `docs/screenshots/android/*.en.png` (+ `.vi.png`) — đã chụp lại đúng 1080×1920, 8 màn × 2
  ngôn ngữ, merged.
- Privacy policy URL: **`https://handlive.hxd.app/privacy/`** (`https://handlive.hxd.app/vi/quyen-rieng-tu/`
  cho bản VI) — site đã live, verify trực tiếp 2026-10-09, nội dung khớp `docs/privacy.md`/`.vi.md` mới
  nhất. Không cần dùng link GitHub tạm nữa.

## 3. Data safety form (map từ `docs/privacy.md`)

| Mục Play hỏi | Trả lời |
|---|---|
| Thu thập dữ liệu nào | Messages (SMS content), Call logs, Contacts, Photos/videos hoặc clipboard content (tạm thời, không lưu lại) |
| Có chia sẻ cho bên thứ 3 | Không |
| Dữ liệu có mã hóa khi truyền | Có, end-to-end (XChaCha20-Poly1305), relay chỉ thấy ciphertext |
| Người dùng xóa được dữ liệu | Có — "Remove Device from Server" xóa đăng ký trên relay; clipboard tự xóa sau 60s |
| Mục đích thu thập | App functionality (đồng bộ 2 chiều điện thoại ↔ Mac/iPhone/iPad), không dùng cho ads/analytics |
| Có bắt buộc | SMS/Call log/Clipboard chỉ xin quyền khi user bật tính năng tương ứng (just-in-time) |

## 4. Permissions Declaration Form — SMS & Call Log

- **Use case khai báo:** "Cross-device synchronization or transfer of SMS or calls" (Play liệt kê
  sẵn use case này, đúng với HandLive).
- **Core functionality cần ghi:** "HandLive mirrors SMS messages and call history from the user's
  own Android phone to their own paired Mac/iPhone/iPad, so the user can read and reply from
  whichever device they're using. No SMS/call data leaves the user's paired devices; the relay only
  forwards end-to-end-encrypted bytes it cannot read."
- **Video demo cần quay** (owner quay, ~1–2 phút):
  1. Mở app → màn hình permission primer SMS (`02-sms-permission-primer`) → bấm Allow → hệ thống
     hỏi quyền READ_SMS/SEND_SMS → Allow.
  2. Nhận SMS mới trên điện thoại → SMS hiện trên Mac trong vài giây.
  3. Trả lời SMS từ Mac → tin gửi đi từ điện thoại, hiện trên app SMS gốc của máy.
  4. (Call log, nếu app đã xin quyền) cuộc gọi tới → hiện trên Mac panel, trả lời/từ chối từ Mac.
- Google review mất vài ngày; có thể bị từ chối nếu không rõ app không phải default SMS/Phone
  handler — HandLive dùng use case "cross-device sync" nên **không cần** là default handler, nhưng
  mô tả app trong Play listing phải nói rõ tính năng này (đã có trong store copy ở mục 2).

## 5. Accessibility API declaration — `ClipboardAccessibilityService`

- App **không** phải accessibility tool (không khai `isAccessibilityTool`), nên phải nộp Permission
  Declaration Form riêng cho Accessibility API.
- **Core use case ghi:** "Detects when the user copies text/content on their phone (copy event only,
  never reads screen content or other app data) so it can automatically offer to send that clip to
  the user's paired Mac/iPhone/iPad. The service only receives TYPE_VIEW_TEXT_CHANGED-class copy
  events, nothing else."
- **In-app disclosure + consent bắt buộc:** đã có sẵn — màn hình `07-auto-send-consent.en.png`
  (consent trước khi bật accessibility cho auto-send). Nêu màn hình này trong form.
- Video demo: bật accessibility trong Settings Android → quay lại app → consent screen → copy text
  trên điện thoại → clip hiện trên Mac.

## 6. Content rating / Target audience / Ads

- Content rating questionnaire: không có nội dung người lớn, không có UGC công khai, không có mua
  hàng trong app → kỳ vọng rating thấp nhất (Everyone/3+ tùy khung Play hiện hành, owner tự làm
  questionnaire trong Console).
- Target audience: không hướng tới trẻ em (app cần SIM/điện thoại Android thật, không phải app trẻ
  em) → chọn "not primarily for children", không áp dụng quy định privacy trẻ em bổ sung.
- Ads: không có quảng cáo → chọn "No ads".

## 7. Internal testing track — bước upload

1. Play Console → Tạo app mới → package `com.handlive.android`.
2. Testing → Internal testing → Create new release → upload `.aab` đã ký ở mục 1.
3. Release name/notes: version `0.1.0-beta.3` (hoặc bump version nếu muốn tách bản Play riêng).
4. Testers → tạo email list, add Google account của owner + người test.
5. Lưu, Review release, Start rollout to Internal testing (không cần qua full review).
6. Gửi opt-in link cho tester cài qua Play Store (không cần sideload APK).

## Đã xác minh, không cần hỏi lại

- `targetSdk` 36 build + bundle OK (xem `plan.md`).
- Store copy (tên, short/long description) đã có sẵn trong `docs/brand-guidelines.md`.
- Data an toàn/privacy policy content đã có sẵn trong `docs/privacy.md`; URL public đã live
  (`https://handlive.hxd.app/privacy/`), không còn thiếu gì ở mục này.
