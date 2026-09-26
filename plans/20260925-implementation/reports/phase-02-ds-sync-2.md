# Phase 2 — design-system sync 2: stale "Huỷ" notes, artifact republish after spec batches 5–7

Hub `main`, pushed `f461d68..432eeec`. Nested repos (`android/`, `apple/`, `relay/`, `shared/`) untouched
(`shared/strings/ui-strings.json` only read). This report is not committed.

## Hub commit

| Repository | Hash | Subject |
|---|---|---|
| hub (handlive) | `432eeec` | docs(design-system): drop the notes that the detailed design writes Huỷ |

Identity Hồ Xuân Dũng <me@hxd.vn>, `git commit -s`, hooks active, no AI trailers, 8 explicit paths staged. The tree
was clean after the commit, so `git pull --rebase` ran ("Current branch main is up to date"), then `git push origin main`.

## Job 1 — stale "Huỷ" notes

Evidence that the note no longer holds: `tools/docs/apple_diacritics.py docs/detailed-design/*.vi.md` (dry run)
reports only the README rule "không viết hoá, xoá, huỷ, tuỳ"; every other grep hit for old-style forms in
`docs/detailed-design` is "thoát" or "thoáng" (false positives).

Removed (one bullet each, in the Deviations / Điểm lệch section; each section keeps its other bullets):

| File | Removed bullet |
|---|---|
| `3-platforms/01-macos.md`, `02-ios-ipados.md`, `03-android.md` | "The Vietnamese detailed design writes "Huỷ"; the Vietnamese version of this page uses the Apple style "Hủy"." |
| `3-platforms/01-macos.vi.md`, `02-ios-ipados.vi.md`, `03-android.vi.md` | "Tài liệu chi tiết viết "Huỷ"; ở đây viết kiểu Apple "Hủy"." |
| `2-patterns/01-thiet-lap-ban-dau.md` (found by grep) | "The Vietnamese detailed design writes "huỷ, xoá, tuỳ"; the Vietnamese version of this section uses the Apple style "hủy, xóa, tùy"." |
| `2-patterns/01-thiet-lap-ban-dau.vi.md` (found by grep) | "Tài liệu chi tiết viết "huỷ, xoá, tuỳ"; mục này viết kiểu Apple "hủy, xóa, tùy"." |

Grep afterwards (`writes "huỷ|hủy`, `detailed design writes`, `Tài liệu chi tiết viết`, old-style forms): no claim that the
detailed design uses old-style tone marks remains. What is left is intended: the rule and the September 25 sync record
in `1-foundations/09-viet-noi-dung` (en, vi) and its Do/Don't example "Huỷ Ghép Nối". The note in
`2-patterns/02-xin-quyen` that the detailed design writes "Quyền riêng tư & Bảo mật" is accurate (15 uses) and stays.

Also checked: the MessageBubble draft changed in `775fb5e` ("Em ơi … anh để sẵn vé …") still has 95 characters, so the
counter "95/134 · 2 tin" stays correct.

### Checks

```text
$ python3 tools/docs/check_bilingual_docs.py
pairs=67 missing=0 problems=0 warnings=0
$ python3 tools/docs/validate_design_docs.py
files=16 leaves=66 problems=0
```

## Job 2 — artifact republish

Artifact https://claude.ai/artifact/2rsmYxBjxXrd12FByTd9vT. Before: Version 12, `1790405532-4772` (lastChange
2026-09-26T06:51:40Z, the MessageBubble publish from hub `775fb5e`). **After: Version 13, `1790418964-6bb0`.**

Method as in sync 1: listed the files (75), plain `read` of the artifact, read the index and all 61 mapped `project/`
pages, compared each with the hub's Vietnamese source (switcher removed, soft-wrapped lines joined), and searched the hub
history for every page that differed. Result: 52 identical, 1 whitespace-only, 8 stale.

### Pages updated (8) + index, one publish call

| Page (`project/…`) | Artifact matched hub version | Change brought in |
|---|---|---|
| `2-patterns/01-thiet-lap-ban-dau.md` | `cf41267` | "huỷ, xoá, tuỳ" note dropped (`432eeec`) |
| `2-patterns/03-thong-bao.md` | `db40a53` | `permission` channel text "… cần quyền SMS trên điện thoại — chạm để cho phép" (`d7ed548`, batch 5 E7) |
| `2-patterns/04-cai-dat.md` | `db40a53` | Question titles for Remove from Server and Delete All (`95852fd`, G1); "Xem hướng dẫn" opens the SMS-01 field 7 alert (`a3fc27b`, G2) |
| `2-patterns/05-phan-hoi-va-tai.md` | `32af250` | "Alert: chỉ ba việc", with the instructions alert of SMS-01 field 7 and PAIR-02 field 9 (`bfbb8e2`, F2; `a3fc27b`, G2) |
| `3-platforms/01-macos.md` | `2a8f0a6` | "Huỷ" note dropped (`432eeec`) |
| `3-platforms/02-ios-ipados.md` | `58a650a` | PAIR-02 field 9 instructions sheet row dropped (`a3fc27b`, G2); "Huỷ" note dropped (`432eeec`) |
| `3-platforms/03-android.md` | `58a650a` | "Huỷ" note dropped (`432eeec`) |
| `components/Alert/README.md` | `32af250` | "Xóa toàn bộ dữ liệu HandLive?" / "Xóa thiết bị này khỏi máy chủ?" with their buttons (`95852fd`, G1) |

Index `project/design-system.json`: read again right before the publish (unchanged), every key kept, only `lastChange`
set: `{"by": "Hồ Xuân Dũng", "at": "2026-09-26T10:35:50Z", "via": "Claude Code", "note": "Đồng bộ design system với
hub tới commit 432eeec: cập nhật 8 trang theo đợt đồng bộ đặc tả 5–7 và bỏ ghi chú cũ rằng tài liệu chi tiết viết
\"Huỷ\"."}`.

### Pages skipped because of artifact-only content

None. Not sent: `1-foundations/01-mau-sac.md`, whitespace-only as in sync 1 (the two spaces before "…" that the hub's
re-wrap commit `d3b1584` added).

### Verification

The publish succeeded on the first call. All 9 files read back from `1790418964-6bb0` have the same sha256 as the local
copies (`/private/tmp/claude-501/-Users-hxd-HandLive/eb0896b6-0c7b-46cb-890d-f09828ae138f/scratchpad/ds-sync-2/`). No
`capabilities` or `contract` passed, generated files not written, uploads untouched.

## Follow-up found (not changed here)

`docs/design-system/2-patterns/05-phan-hoi-va-tai.vi.md` lines 77–78 (§ Mất kết nối) still say the "Cần ghép nối lại"
state comes with "Ghép điện thoại…". The English says "Add Phone…", and the catalog's `Add Phone…` is "Thêm điện
thoại…". The phrase is wrapped across two lines, which is why the one-label change `2a8f0a6` missed it. Fix: "Thêm điện
thoại…" in the `.vi.md`, then republish that page. I left it for the next sync so this one stays within its scope and
a single publish; the artifact currently matches the hub, this line included.

```text
Status: DONE
Summary: Hub commit 432eeec (pushed) drops the stale notes that the Vietnamese detailed design writes "Huỷ" from the three platform pages and the onboarding pattern; both checkers report problems=0. The artifact is republished as Version 13 (1790418964-6bb0) with the 8 pages that differed and the index; no artifact-only content was found.
Concerns/Blockers: One follow-up — "Ghép điện thoại…" in 05-phan-hoi-va-tai.vi.md lines 77–78 should be "Thêm điện thoại…".
```
