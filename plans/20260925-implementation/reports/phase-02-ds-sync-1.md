# Phase 2 — design-system sync 1: positioning wording, MessageBubble and PasteCard previews, artifact republish

Hub `main`, pushed `e92c057..1a57620`. Nested repos (`android/`, `apple/`, `relay/`, `shared/`) untouched
(`shared/strings/ui-strings.json` only read to cross-check texts). This report is not committed.

## Hub commits

| Repository | Hash | Subject |
|---|---|---|
| hub (handlive) | `cf41267` | docs(design-system): stop calling the Android phone the hub |
| hub (handlive) | `298544d` | docs(design-system): match the MessageBubble preview with SMS-04 |
| hub (handlive) | `1a57620` | docs(design-system): use the CLIP-04 hint in the PasteCard preview |

Identity Hồ Xuân Dũng <me@hxd.vn>, `git commit -s`, hooks active (`core.hooksPath=.githooks`), no AI trailers,
explicit paths staged, `git pull --rebase` (up to date), `git push origin main`.

## Job 1 — hub edits

### 1. Positioning (`cf41267`)

| File | Before | After |
|---|---|---|
| `components/PasteCard/README.md` § Android | "Android is the hub, so it has no such tab: manual sending goes through …" | "Android has no such tab: people send by hand from anywhere on the phone, through the "Send Clipboard" Quick Settings tile, …" |
| `components/PasteCard/README.vi.md` § Android | "Android là máy trung tâm nên không có tab này: gửi thủ công bằng …" | "Android không có tab này: người dùng gửi thủ công từ bất cứ đâu trên máy, bằng …" |
| `components/PasteCard/preview.html` note | "Android là máy trung tâm: gửi thủ công qua …" | "Android không có tab này: gửi thủ công từ bất cứ đâu trên máy qua …" |
| `2-patterns/01-thiet-lap-ban-dau.md` Android step 1 | "The phone's role as the hub, a privacy summary (SET-01 field 1)" | "The phone syncs with a Mac, iPhone, and iPad; a privacy summary (SET-01 field 1)" |
| `2-patterns/01-thiet-lap-ban-dau.vi.md` Android step 1 | "Vai trò trung tâm, tóm tắt quyền riêng tư (SET-01 trường 1)" | "Điện thoại đồng bộ với Mac, iPhone và iPad; tóm tắt quyền riêng tư (SET-01 trường 1)" |
| `components/Onboarding/README.md` feature rows (found by search) | "Android: the phone's role as the hub, privacy" | "Android: syncing with Apple devices, privacy" |
| `components/Onboarding/README.vi.md` feature rows (found by search) | "Android: vai trò trung tâm, riêng tư" | "Android: đồng bộ với thiết bị Apple, riêng tư" |

Search over `docs/design-system` (`hub`, `trung tâm`, `trung chuyển`, `central`, `bridge`, `cầu nối`, `trung gian`,
`vai trò`, `role`): the remaining hits are "Trung tâm thông báo" / Notification Center, Xcode's "Device Hub" and the
brand story's signal-fire "trạm" (stations). None of them calls the phone a hub.

### 2. MessageBubble preview (`298544d`)

- Counter (SMS-04 field 3, catalog `sms.char_counter` + `sms.part_count`): the sample draft has 95 characters (NFC)
  and letters outside GSM-7 (ã í đ ơ ư ả ầ ẵ ể ễ ệ ố ồ ờ ở ử), so UCS-2 applies: 95 > 70, parts = ceil(95 / 67) = 2,
  limit = 67 × 2 = 134. "2 tin SMS" → **"95/134 · 2 tin"**.
- Status texts already matched README.vi.md and SMS-04 field 7: "Đã nhận", "Gửi lỗi · Không có sóng" + "Thử lại"
  (format `sms.status_failed_reason`, reason of field 8 for `SMS_NO_SERVICE`), "Đang chờ điện thoại".
- Pending line icon: spinner → `schedule` (README status table: `clock` ↔ `schedule`; the spinner belongs to
  `sending`). The unused `.spin` CSS was removed.
- Day marker "Hôm nay 13:58" → "Hôm nay" (README date markers); the time "13:58" now sits under the incoming
  message (README: time under the last message of a cluster).

### 3. PasteCard preview (`1a57620`)

- Hint under the Paste button: "Chạm Dán để gửi nội dung bạn vừa sao chép trên iPhone." → "Chạm Dán để gửi nội
  dung vừa sao chép." (CLIP-04 field 1, catalog `clipboard.paste_hint`).
- Other visible texts already matched ("Gửi sang Pixel 8 của Lan", "Từ Pixel 8 của Lan · 14:05", "Sao chép", tab
  labels). The empty and not-connected states are not shown in this preview, so nothing changed there.

Visual check: both previews rendered with headless Chrome (tokens as CSS variables + `components/bundle.css`); the
new lines lay out correctly.

### Checks

```text
$ python3 tools/docs/check_bilingual_docs.py
pairs=67 missing=0 problems=0 warnings=0
$ python3 tools/docs/validate_design_docs.py
files=16 leaves=66 problems=0
```

Both run before each commit with the same result. `tools/docs/apple_diacritics.py` dry run on the changed
Vietnamese files: only the intentional quote "huỷ, xoá, tuỳ" in the deviation note of `01-thiet-lap-ban-dau.vi.md`.

## Job 2 — artifact republish

Artifact https://claude.ai/artifact/2rsmYxBjxXrd12FByTd9vT (type Design System, contract 0.2.47).
Before: version `1790389911-9478` (lastChange 2026-09-26T02:31:40Z). **After: Version 11, `1790405269-674c`.**

Method: listed the files (75), read `SKILL.md`, the index and all 61 mapped `project/` files, and compared each with
its hub source (Vietnamese file without the switcher line and blank line, soft-wrapped lines joined; this rule
reproduces the 43 unchanged artifact pages byte for byte). For every page that differed, the hub history (including
the pre-bilingual `X.md` paths) was searched for a matching version, ignoring whitespace.

### Pages updated (17) + index, one publish call

| Page (`project/…`) | Artifact matched hub version | Main change brought in |
|---|---|---|
| `1-foundations/09-viet-noi-dung.md` | `c9a711e^` (pre-bilingual `09-viet-noi-dung.md`) | en/vi intro sentence, plural-count exception, row "Đã tải 1500 tin", section "Tiếng Anh — ngôn ngữ mặc định" |
| `1-foundations/10-quyen-rieng-tu.md` | `e4cc3c9` | Final Bluetooth and microphone purpose strings |
| `2-patterns/01-thiet-lap-ban-dau.md` | `e356c67` | "Thêm điện thoại…", Android step 1 positioning |
| `2-patterns/02-xin-quyen.md` | `e356c67` | Final Bluetooth, microphone, Focus purpose strings |
| `2-patterns/03-thong-bao.md` | `e356c67` | "Đang chờ kết nối", SMS-04 E8 final period |
| `2-patterns/04-cai-dat.md` | `e356c67` | "Thêm điện thoại…", SET-02 field 28 note resolved |
| `2-patterns/05-phan-hoi-va-tai.md` | `e356c67` | SET-02 E5 period, "Đã tải 1500 tin", "Thêm điện thoại…", SMS-03 E1 and CLIP-04 field 10 empty states |
| `3-platforms/01-macos.md` | `58a650a` | "Thêm điện thoại…" (2 places) |
| `components/Alert/README.md` | `32af250^` | SET-02 field 28 buttons |
| `components/ConsentSheet/README.md` | `4533b42` | Android disclosure full screen |
| `components/MessageBubble/README.md` | `4533b42` | Reasons = SMS-04 field 8, counter = field 3 |
| `components/MessageBubble/preview.html` | `96097a6` | Job 1 item 2 |
| `components/Onboarding/README.md` | `6283cb8` | Android feature row, privacy link, "Thêm điện thoại…" |
| `components/PairingCard/README.md` | `6283cb8` | Security Code shown after pairing |
| `components/PasteCard/README.md` | `6283cb8` | Hint, E5 state, empty state, Android paragraph |
| `components/PasteCard/preview.html` | `96097a6` | Job 1 items 1 and 3 |
| `components/StatusIndicator/README.md` | `6283cb8` | "Đã kết nối qua USB" |

Index `project/design-system.json`: read again right before the publish, every key kept, only `lastChange` set:
`{"by": "Hồ Xuân Dũng", "at": "2026-09-26T06:47:32Z", "via": "Claude Code", "note": "Đồng bộ design system với hub
tới commit 1a57620: cập nhật 17 trang còn cũ, trong đó không còn gọi điện thoại Android là máy trung tâm và preview
MessageBubble, PasteCard khớp SMS-04, CLIP-04."}`.

### Pages skipped because of artifact-only content

None. Every differing page matched an earlier hub version.

- Not republished although not byte-identical: `1-foundations/01-mau-sac.md`. Only two spaces differ: after
  `NSColor.windowBackgroundColor` and after `glass-fill` the artifact has "…" directly, the hub has a space before
  "…". The hub's re-wrap commit `d3b1584` inserted those spaces; no content change.
- Side effect of the same re-wrap: `components/Alert/README.md` now shows "`ButtonRole.destructive` /`.cancel`"
  (the artifact had no space), because that page had a real change and was published from the hub as is.

### Publish notes and verification

- The first publish call was refused ("You haven't viewed the latest version"), because only path reads had been
  made. A plain `read` showed the version unchanged (`1790389911-9478`); the same single call then succeeded.
- Read back 7 files from `1790405269-674c` (index, both previews, PasteCard README, `01-thiet-lap-ban-dau`,
  `09-viet-noi-dung`, Onboarding README): sha256 identical to the local copies.
- Not written: `tokens.css`, `api/`, `manifest.json`; no `capabilities` or `contract`; no uploads touched;
  `project/README.md` not sent (identical), so its generated tail is untouched.
- Local copies: `/private/tmp/claude-501/-Users-hxd-HandLive/eb0896b6-0c7b-46cb-890d-f09828ae138f/scratchpad/ds-sync/`
  (published files), `…/scratchpad/ds-tools/dsmap.py` (mapping and comparison).

## Unresolved questions

1. SMS-04 E3 says the failure reason for `PERMISSION_MISSING` / `can_send = false` is "Thiếu quyền SMS trên điện
   thoại" / "Missing SMS permission on the phone", but field 8's reason list (and therefore the MessageBubble README,
   which follows field 8) leaves it out. Add it to field 8 and to both READMEs?
2. The MessageBubble sample draft is written from the other person's side ("Anh ơi … em để sẵn vé ở bảo vệ"), while
   the user's own earlier bubbles call the user "anh". The text was kept, as asked, and the counter computed for it;
   rewriting the sample later means recomputing the counter.

```text
Status: DONE
Summary: Hub design system no longer calls the Android phone the hub, and the MessageBubble and PasteCard previews match SMS-04 and CLIP-04 (3 commits, pushed, both checks problems=0). The artifact was republished to Version 11 (1790405269-674c) with 17 stale pages and the index; no artifact-only edits were found.
Concerns/Blockers: Two open questions above (SMS-04 E3 reason missing from field 8; sample draft pronouns).
```
