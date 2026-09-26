English | [Tiếng Việt](09-viet-noi-dung.vi.md)

# Writing
<!-- i18n: mixed -->

HandLive's copy is short, clear, and calm, like a tool that's part of the system. The interface comes
in English (the default language) and Vietnamese (C20); the first sections cover Vietnamese, and the
section "English — the default language" comes at the end. This section sets the voice and tone,
capitalization and diacritics, how to write each component, terminology, number and date formats, and
the places that must stay in sync with the detailed design. Vietnamese examples are quoted verbatim,
with English glosses in parentheses.

HIG source: https://developer.apple.com/design/human-interface-guidelines/writing

## Voice and tone

- Clear, calm, trustworthy. Say what's happening and what to do; put the most important thing first.
- The tone shifts with the context: errors and privacy are neutral and specific; a completed pairing is
  warm and short ("Đã ghép nối với Pixel 8 của Lan" — Paired with Lan's Pixel 8); calls are minimal.
- No "chúng tôi" (we), no exclamation marks, no emoji, no "Rất tiếc" (Sorry) or "Úi" (Oops). No slang
  or idioms.
- Avoid unnecessary pronouns and possessives ("Thiết bị" rather than "Thiết bị của bạn" — Devices
  rather than Your Devices); address the user as "bạn" (you) only when a missing subject would be
  misleading.
- "Chạm" (tap) for touchscreens (iPhone, iPad, Android), "bấm" (click) for the mouse and keyboard
  (Mac).

## Capitalization and diacritics

- Vietnamese uses sentence case for every component: buttons, menu items, window titles, tabs, alerts,
  notifications. Capitalize only the first word and proper nouns: "Hủy ghép nối" (Unpair), "Gửi bảng
  nhớ tạm sang điện thoại" (Send Clipboard to Phone).
- Intentional deviation: the HIG uses title-style capitalization for buttons, menus, and tabs in
  English; Vietnamese has no convention of capitalizing every word, so HandLive uses sentence case.
- Proper nouns stay as they are: HandLive, Mac, iPhone, iPad, Android, Wi-Fi, Bluetooth, USB, SIM.
  System setting names are written exactly as the system's Vietnamese version shows them: "Cài đặt hệ
  thống" (System Settings), "Quyền riêng tư & Bảo mật" (Privacy & Security), "Tập trung" (Focus),
  "Trung tâm thông báo" (Notification Center); Apple calls Accessibility "Trợ năng", Android calls it
  "Hỗ trợ tiếp cận".
- No ALL CAPS.
- Apple-style tone marks: the mark sits on the main vowel of the rhymes oa, oe, uy: hóa, xóa, hủy, tùy,
  thủy, khỏe, lũy, khóa, hòa, họa, thỏa. Don't write hoá, xoá, huỷ, tuỳ.

## Component by component

| Component | Rule | Example |
|---|---|---|
| Button | Starts with a verb, 1–3 words; never "Có" (Yes) or "Không" (No) | "Gửi" (Send), "Trả lời" (Answer), "Ghép nối" (Pair) |
| Cancel button | Always "Hủy" | "Hủy" (Cancel) |
| OK | Only for purely informational alerts | — |
| Multi-step flow | "Bắt đầu" → "Tiếp tục" → "Xong" (Get Started → Continue → Done) | `Onboarding` |
| Alert | The title states the specific situation, 2 lines at most; the message is a complete sentence, used only when it adds value; 3 buttons at most | "Hủy ghép nối với Pixel 8 của Lan?" (Unpair Lan's Pixel 8?); buttons "Hủy" (left), "Hủy ghép nối" (right) |
| Menu item | A verb; toggle items use a checkmark | "Gửi bảng nhớ tạm sang điện thoại" (Send Clipboard to Phone) |
| Notification | Short title, no period, no "HandLive"; the body is a complete sentence | "Cuộc gọi nhỡ" (Missed call) |
| Tooltip (Mac) | Starts with a verb, 60–75 characters at most, doesn't repeat the control's name | "Tắt tiếng micro trên Mac" (Mute the microphone on the Mac) |
| Window title | A noun, under 15 characters | "Tin nhắn" (Messages) |
| Setting description | Says what happens when it's on | "Thông báo tin nhắn hiện cả nội dung tin." (Message notifications include the message text.) |

Permission purpose strings: see Privacy.

## Terminology

| Use | Don't use |
|---|---|
| Bảng nhớ tạm (clipboard) | Clipboard, bộ nhớ đệm (buffer) |
| Ghép nối, Hủy ghép nối (pair, unpair) | Pair, kết đôi (couple) |
| Kết nối qua Internet (internet connection) | Relay, máy chủ relay (relay server) |
| Cùng mạng Wi-Fi (same Wi-Fi network; short label: LAN) | LAN inside a sentence |
| Hỗ trợ tiếp cận (Android), Trợ năng (Apple) — Accessibility | Accessibility |
| Gỡ lỗi USB (USB debugging) | USB debugging |
| Micro (microphone) | Microphone, mic |
| Cuộc gọi nhỡ (missed call) | Cuộc gọi lỡ (a less common variant) |
| Mã an toàn (Security Code) | Vân tay (fingerprint), fingerprint |
| Tập trung (Focus) | Focus, Không làm phiền (Do Not Disturb) |
| Ngoại tuyến (offline) | Offline |

## Numbers, dates, times

Use the system formatters with the Vietnamese locale; don't build strings by hand.

| Type | Format | API |
|---|---|---|
| Time | "14:05" | `Date.FormatStyle`; Android `DateFormat.getTimeFormat` |
| Date | "24/09"; a different year "24/09/2025"; "Hôm qua" (Yesterday) | `Date.FormatStyle` |
| Duration | "02:15" while counting; in history "2 phút 5 giây" (2 min 5 s) | `DateComponentsFormatter` |
| Relative | "5 phút trước" (5 minutes ago) | `RelativeDateTimeFormatter` |
| Phone number | "090 000 0123" | Android `PhoneNumberUtils.formatNumber` |
| Number | "1.500"; decimal "0,5" | `.formatted()`, `NumberFormatter` |
| File size | "5 MB" | `ByteCountFormatStyle`; Android `Formatter.formatShortFileSize` |

A count inside a plural string is the exception: the string catalog passes it as a plain integer, so
it has no thousands separator, for example "Đã tải 1500 tin" (Downloaded 1500 messages); detailed
design 0.12.1.

## Errors

Pattern: what happened, then how to fix it. Show it right next to where the error happened; don't blame
the user; no error codes, no generic "Lỗi" (Error) title.

| Write | Avoid |
|---|---|
| "Mã PIN không đúng. Kiểm tra mã trên Mac rồi nhập lại." (The PIN is incorrect. Check the code on your Mac and try again.) | "PIN_INVALID" |
| "Cần cùng mạng Wi-Fi hoặc cắm cáp USB" (Requires the same Wi-Fi network or a USB cable) | "Không hỗ trợ kênh truyền" (Transport not supported) |
| "Chưa gửi được. Điện thoại đang ở chế độ máy bay." (Not sent yet. The phone is in airplane mode.) | "Gửi thất bại" (Send failed) |

## Empty states

Always offer a next step: a `brand-title` title, one sentence, one button; don't put important
information here. Example: "Chưa có điện thoại" (No Phone Yet) · "Ghép điện thoại Android để nhận bảng
nhớ tạm, tin nhắn và cuộc gọi." (Pair an Android phone to get its clipboard, messages, and calls.)
· button "Thêm điện thoại…" (Add Phone…).

## The "…" character

- Use the "…" character (a single character); don't type three periods.
- For commands that need more input or a choice ("Cài đặt…" — Settings…, "Từ chối kèm tin nhắn…" —
  Decline with Message…) and for Mac buttons that open another window or sheet ("Thêm điện thoại…" —
  Add Phone…).
- For states in progress: "Đang kết nối…" (Connecting…), "Đang gửi…" (Sending…).
- Not for commands that run immediately ("Gửi" — Send, "Trả lời" — Answer).

## Synced with the detailed design

Applied in full to `docs/detailed-design/` on September 25, 2026 (README §3.5, C19). System section
names ("Quyền riêng tư & Bảo mật") follow Apple's Vietnamese localization; the implementation plan
includes a task to check them on real devices.

| Detailed design | Design system | Where |
|---|---|---|
| huỷ, xoá, tuỳ, hoá, khoá, hoà, hoạ, thoả | hủy, xóa, tùy, hóa, khóa, hòa, họa, thỏa | About 800 places: khoá 253, xoá 238, hoá 155, huỷ 95, tuỳ 46, hoà 6, hoạ 4, thoả 2 |
| "Gửi clipboard", "Đồng bộ clipboard", "Tự xoá clipboard đã nhận", "Clipboard trống hoặc không phải văn bản" | "Gửi bảng nhớ tạm", "Đồng bộ bảng nhớ tạm", "Tự xóa bảng nhớ tạm đã nhận", "Bảng nhớ tạm trống hoặc không phải văn bản" (Send Clipboard, Sync Clipboard, Auto-Clear Received Clipboard, The clipboard is empty or doesn't contain text) | CLIP-01 to CLIP-04, SET-01, SET-03 |
| "máy chủ relay không đọc được nội dung" | "máy chủ không đọc được nội dung" (the server can't read the content) | SET-01, SET-03 field 1 |
| "Đã kết nối (LAN)", "Đã kết nối (qua Internet)" | "Đã kết nối qua Wi-Fi", "Đã kết nối qua Internet" (Connected via Wi-Fi, Connected over the internet) | 0.11, CONN-01, PAIR-02; "LAN" is still allowed as a short label |
| "Quyền riêng tư và bảo mật" | "Quyền riêng tư & Bảo mật" (Privacy & Security) | SET-03, CLIP-02, AUDIO-01, CAM-01 |
| "Không, tôi sẽ gửi thủ công" (No, I'll send manually) | "Gửi thủ công" (Send Manually) | CLIP-01 field 3; buttons start with a verb |
| "Thêm điện thoại" (the Mac button that opens the QR code sheet) | "Thêm điện thoại…" (Add Phone…) | PAIR-01 |
| "Đã tải 1 500 tin" | "Đã tải 1500 tin" (Downloaded 1500 messages) | SMS-01; a count inside a plural string has no grouping (detailed design 0.12.1) |

## English — the default language

HandLive writes English following the Apple Style Guide and the English edition of the HIG. English is
the source language of the string catalog (`shared/strings/ui-strings.json`, detailed design 0.12);
every string has a Vietnamese version that follows the sections above (C20).

- Title-style capitalization for buttons, menu items, window and sheet titles, tabs, settings row
  labels, and alert titles: "Send Clipboard to Phone", "Unpair", "Add Phone…". Capitalize every word
  except articles (a, an, the), coordinating conjunctions (and, but, or, nor), and prepositions of four letters or fewer (at, by, for, from, in, into, of, off, on, onto, out, over, to, up, via, with) unless they come first or last.
- Sentence-style capitalization for descriptions, captions, alert messages, notification bodies,
  status strings, and tooltips: "Connected via Wi-Fi", "Keep the phone and this Mac on the same Wi-Fi
  network."
- Short, active, present tense; no "please", "sorry", "oops", exclamation marks, or emoji; use "you"
  only when a missing subject would be misleading. "Tap" for touchscreens, "click" for the Mac.
- Operating system section names are written exactly as the English system shows them: "System
  Settings", "Privacy & Security", "Focus", "Notification Center", "Accessibility" (on both Apple and
  Android), "Paste from Other Apps".
- "internet" is lowercase in sentences ("Connected over the internet") and capitalized when the whole
  string uses title-style capitalization.
- Numbers, dates, and times follow the English locale through the system formatters ("2:05 PM" in
  en-US, "Sep 24", "1,500", "0.5", "5 MB"); don't build strings by hand. A count inside a plural string
  has no grouping ("Downloaded 1500 messages").
- Errors: what happened, then how to fix it — "The PIN is incorrect. Check the code on your Mac and try
  again."; no error codes, no generic "Error" title.
- The "…" character and the rules for buttons, alerts, notifications, and empty states are the same as
  in Vietnamese.

| English | Vietnamese | Notes |
|-----------|------------|---------|
| Clipboard | Bảng nhớ tạm | |
| Pair, Unpair | Ghép nối, Hủy ghép nối | |
| Internet connection ("Connected over the internet") | Kết nối qua Internet | Don't use "relay" in either language |
| Same Wi-Fi network (short label: LAN) | Cùng mạng Wi-Fi (nhãn ngắn: LAN) | |
| Accessibility | Hỗ trợ tiếp cận (Android), Trợ năng (Apple) | |
| USB debugging | Gỡ lỗi USB | |
| Microphone | Micro | |
| Missed Call | Cuộc gọi nhỡ | |
| Security Code | Mã an toàn | |
| Focus | Tập trung | |
| Offline | Ngoại tuyến | |
| Phone | Điện thoại | The paired Android phone |

## Dos and don'ts

| Do | Don't |
|---|---|
| "Hủy ghép nối" (Unpair) | "Huỷ Ghép Nối" (old-style tone mark, every word capitalized) |
| "Bảng nhớ tạm" (clipboard) | "Clipboard" |
| "Không gửi được ảnh lớn hơn 10 MB." (Can't send images larger than 10 MB.) | "Ảnh quá lớn" (Image too large) |
| "Đang kết nối…" (one "…" character) | "Đang kết nối..." (three periods) |
