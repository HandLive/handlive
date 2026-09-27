# Phase 3 — design-system sync 1: call previews, call permission alert, artifact Version 15

Hub `main`, pushed (`7423123..1a7e6ad`). Nothing touched in `android/`, `apple/`, `relay/`, `shared/`
(`shared/strings/ui-strings.json` and the Mac panel code in `apple/` read only, as reference).

## Job 1 — hub edits

| Commit | Subject |
|---|---|
| 65b5f11 | docs(design-system): match the CallPanel preview with the call specs |
| aebaafc | docs(design-system): show a missed call in the MenuBarMenu preview as CALL-04 does |
| 1a7e6ad | docs(design-system): add the call permission instructions alert to the feedback page |

All three signed off (`-s`), identity Hồ Xuân Dũng <me@hxd.vn>, no AI trailer, hooks on. `git pull --rebase`: up to
date; push OK.

### 1. `components/CallPanel/preview.html` (65b5f11)

Every visible text, `title` and `aria-label` now maps to a catalog key (checked by script against
`ui-strings.json` vi), except the AUDIO-03 routing buttons "Nghe trên Mac" / "Chuyển về điện thoại" (in the README
and 07-call-audio AUDIO-03 field 1; no catalog key yet, Phase 4).

| Before | After | Source |
|---|---|---|
| Sub line "Cuộc gọi đến · SIM 1" | Title "Cuộc gọi đến", name, number "090 000 0123", SIM label "SIM 1" as separate lines | CALL-01 fields 1–4, API 5 example; `call.incoming_title` |
| Answer/Decline `title` "Trả lời"/"Từ chối" | `title` "Trả lời cuộc gọi"/"Từ chối cuộc gọi"; `aria-label` "Trả lời"/"Từ chối" | CALL-01 fields 6, 7; `call.*_tooltip`, `call.answer`, `call.decline` |
| Dialog `aria-label` "Cuộc gọi đến từ Nguyễn Văn A, SIM 1" | "Cuộc gọi đến từ Nguyễn Văn A" | `a11y.call_incoming_from` |
| "Đang gọi · 02:15 · Âm thanh: …" in one line | Status "Đang gọi" above the name; timer and "Âm thanh: …" as two items below | CALL-03 fields 2–4; `call.status_on_call` |
| End `title` "Kết thúc" | "Kết thúc cuộc gọi" | CALL-03 field 5; `call.end_tooltip` |
| Keypad `aria-label` "Bàn phím", `title` "Mở bàn phím số", caption "Bàn phím" | "Bàn phím số" everywhere, no `title` | CALL-03 field 7; `call.keypad` |
| Hold `title` "Giữ máy" | No `title` (catalog has no tooltip; a tooltip must not repeat the control name, 09-viet-noi-dung) | `call.hold` |
| In-call dialogs `aria-label` "Đang gọi với …" (invented) | `aria-labelledby` status + name | — |
| — | Hold and Keypad get `aria-pressed="false"` (toggle buttons per README) | CallPanel README |
| No waiting example | New panel "Có cuộc gọi chờ, chưa nối Bluetooth": status "Có cuộc gọi chờ", waiting caller "Trần Thị B" + "Xử lý trên điện thoại hoặc nối Bluetooth", no End button | CALL-01 field 5 (Mac), CALL-03 field 3, E7 |
| No lost-connection text | "Mất kết nối với điện thoại" (orange, `text-orange`) in the Bluetooth panel, caption "Đang gọi qua Bluetooth, mất phiên với điện thoại" — E6 says HFP actions keep working | CALL-03 E6; `call.connection_lost` |

`@dsCard` height 440 → 520: rendered locally with headless Chrome (light tokens from `tokens.json` + `bundle.css`),
two columns need ~495 px at ≥ 770 px width. Icon font could not load offline; layout otherwise checked.

### 2. `2-patterns/05-phan-hoi-va-tai` (+ `.vi`), "Alerts: only three jobs" (1a7e6ad)

The instructions bullet now names both alerts: SMS ("Grant SMS Permission on Your Phone" / "Cấp quyền SMS trên điện
thoại") and the PAIR-02 field 9 call alert, title and message verbatim from `02-pairing` field 9 and
`call.permission_instructions_title` / `_body` (en and vi).

### 3. Other Phase 3 previews (aebaafc)

- `MenuBarMenu/preview.html`: recent missed call was "Cuộc gọi nhỡ · Nguyễn Văn A" + "14:01"; now caller "Nguyễn Văn A"
  with "Cuộc gọi nhỡ · 14:01" under it (CALL-04 API 4 logic 5, `call.missed_body`; same two-line item as the Mac app's
  `MissedCallItem`). Messages item "2 chưa đọc" → "2" (README "số chưa đọc ở bên phải", `menu.messages`; "chưa đọc"
  suffix was not a catalog text). Card height 560 still fits.
- `Notification/preview.html`: no difference with its README or CALL-01 field 11 ("Cuộc gọi đến · SIM 1", "Từ chối");
  unchanged.
- `StatusIndicator/preview.html`: shows no call text; unchanged.

### 4. Checks

```text
$ python3 tools/docs/check_bilingual_docs.py
pairs=67 missing=0 problems=0 warnings=0
$ python3 tools/docs/validate_design_docs.py
files=16 leaves=66 problems=0
```

`tools/docs/apple_diacritics.py` dry run on the changed files: 0 words.

## Job 2 — artifact republish

Artifact https://claude.ai/artifact/2rsmYxBjxXrd12FByTd9vT. Before: Version 14, `1790419128-af38` (lastChange
2026-09-26T10:38:30Z, hub `8ed34a7`). **After: Version 15, `1790496717-2d45`.**

Method as in the Phase 2 syncs: plain `read` (type instructions), file list (75), read the index and all 61 mapped
`project/` pages, compared each with the hub source (Vietnamese file minus switcher line and blank line, soft-wrapped
lines joined; previews, `tokens.json`, `bundle.css` as is) using `scratchpad/ds-tools/dsmap.py`, then searched hub
history for every differing page. Result: 51 identical, 9 stale (each matched an older hub version exactly),
1 whitespace-only.

### Pages updated (9) + index, one publish call

| Page (`project/…`) | Artifact matched hub version | Change brought in |
|---|---|---|
| `2-patterns/02-xin-quyen.md` | `7af56df` | Calls primer title "Xem cuộc gọi trên Mac và iPhone" (SET-01 field 12) (`b212c12`) |
| `2-patterns/03-thong-bao.md` | `d7ed548` | "CALL-02 E8, trường 11" (`b212c12`) |
| `2-patterns/05-phan-hoi-va-tai.md` | `8ed34a7` | Call permission instructions alert (`1a7e6ad`) |
| `3-platforms/01-macos.md` | `432eeec` | Communication Notifications capability for Focus, Time Sensitive entitlement (`ce955f3`) |
| `3-platforms/02-ios-ipados.md` | `432eeec` | Open app: no banners, missed calls to Notification Center only (`2991fe2`) |
| `components/CallPanel/README.md` | `4533b42` | Title and SIM label, "Đang gọi" + timer, "Bàn phím số", E6, tooltips, Focus passive, keys after click (`b212c12`, `ce955f3`) |
| `components/CallPanel/preview.html` | `96097a6` | Job 1 item 1 (`65b5f11`) |
| `components/MenuBarMenu/README.md` | `4533b42` | Last three recent items, call list empties missed calls (`ce955f3`) |
| `components/MenuBarMenu/preview.html` | `96097a6` | Job 1 item 3 (`aebaafc`) |

Index `project/design-system.json`: read again right before the publish (unchanged), every key kept, only `lastChange`
set: `{"by": "Hồ Xuân Dũng", "at": "2026-09-27T08:11:24Z", "via": "Claude Code", "note": "Đồng bộ design system với
đặc tả cuộc gọi Phase 3 tới hub commit 1a7e6ad: cập nhật 9 trang, trong đó preview CallPanel và MenuBarMenu khớp
CALL-01, CALL-03, CALL-04 và trang Phản hồi, tải và lỗi thêm alert hướng dẫn cấp quyền cuộc gọi của PAIR-02."}`.

Verification: publish succeeded first call; all 10 files read back from `1790496717-2d45` have the same sha256 as
the local copies (`scratchpad/ds-sync-p3/`). No `capabilities`/`contract` passed, generated files not written,
uploads untouched. `git fetch` right before the publish: no newer design-system commit on `origin/main`.

### Pages skipped because of artifact-only content

None. Not sent: `1-foundations/01-mau-sac.md`, whitespace only, as in the Phase 2 syncs — the hub has a space before
"…" in two places (`` `NSColor.windowBackgroundColor` …`` and `` `glass-fill` …``), the artifact has none.

## Unresolved questions

1. **Waiting-call label on the Mac.** CALL-01 field 1 says the title becomes "Cuộc gọi chờ" when `waiting = true`;
   CALL-03 field 3 gives the in-call status "Có cuộc gọi chờ". The preview uses "Có cuộc gọi chờ" (panel is in
   in-call mode, README state name). The Mac app (`apple/…/HLMacUI/CallPanelView.swift`, `title(_:)`) shows
   `call.waiting_title` in that slot and never uses `call.status_waiting`. Spec should say which one the in-call panel
   shows.
2. **Foreground notifications wording.** `components/Notification/README` ("Không gửi thông báo khi app đang mở ở phía
   trước") and `2-patterns/03-thong-bao` § Quy tắc ("App đang ở phía trước thì không gửi thông báo…"), both languages,
   now conflict with CALL-04 API 4 logic 1 and `02-ios-ipados` after `2991fe2` (missed calls still go to Notification
   Center while the iPhone app is open). Needs a wording fix in a later sync.
3. **Catalog comment (shared, read only here).** `call.incoming_body_sim` comment says "the design system's call panel
   shows the same line under the caller"; the panel now shows the SIM label as its own field (CALL-01 field 4). The
   shared agent may update the comment.
4. Not changed (not visible text, not Phase 3): the MenuBarMenu icon `aria-label` "HandLive, 2 hội thoại chưa đọc";
   SMS-02 field 6 puts the count after the connection status.

Status: DONE_WITH_CONCERNS
Summary: CallPanel and MenuBarMenu previews and the feedback page's Alerts now match the Phase 3 call specs and the
catalog (3 signed commits pushed to hub main, both doc checks problems=0), and the artifact was republished as
Version 15 with 9 pages and the index, verified by hash.
Concerns/Blockers: waiting-call label ambiguous between CALL-01 field 1 and CALL-03 field 3 (Mac app differs from the
preview); Notification/03-thong-bao foreground wording now conflicts with CALL-04 API 4 (questions 1–2).
