# Web Handoff (Continue Browsing): spec write-up report

Date: 2026-09-28 · Agent: spec agent · Repo: hub `main` (11 commits, not pushed) · Source: `plans/20260928-web-handoff/plan.md` W1–W9.

## Files and sections changed (every file changed together with its `.vi.md` twin)

| File | Change |
|------|--------|
| `docs/detailed-design/09-web-handoff(.vi).md` | New group 9: group rules QW1–QW9, WEB-01 (Android sends), WEB-02 (Mac shows), WEB-03 (Mac sends), WEB-04 (Android shows), WEB-05 (iPhone/iPad shows). Each leaf has the 5 subsections, Mermaid chart plus step table, API list and Query. Every leaf is P6 and depends on G6. `web/active` and `web/inactive` are specified in WEB-01 API 1 and API 2 |
| `docs/detailed-design/00-common-specs(.vi).md` | 0.1 new component A-WEB. 0.2 `page_id`. 0.7.1 `web` type in the intro, rows `web/active` and `web/inactive` (both ways, no ack), payload rules, browser id table. 0.7.2 rows `features.web.enabled/send/receive`. 0.9.5 keys `feature.web`, `web.send`, `web.notify`, `web.browsers`, `web.a11y_consent_at`. 0.10 `WEB_SETTLE`, `WEB_POLL_MAC`, `WEB_PAGE_TTL`, `WEB_URL_MAX`, `WEB_TITLE_MAX`. 0.12.1 string group `web`. No new error codes |
| `docs/detailed-design/README(.vi).md` | Version 1.3, date 2026-09-28, scope Phase 1 to Phase 6. File row 09. Catalog rows WEB-01…05. §4 out of scope: sending from iPhone/iPad. C21 (automatic detection, separate Accessibility service, no Apple Handoff surface, latest wins without ack, never stored) |
| `docs/detailed-design/01-setup-settings(.vi).md` | SET-01 description part B. SET-01 API 2 rows `web` (send: Accessibility service; receive: `POST_NOTIFICATIONS`). SET-02 fields 34–37. Step 2 activation (Android disclosure + service; Mac Automation asked per browser). API 1 capability mapping row. Stopped-task row `web` |
| `docs/project-roadmap(.vi).md` | Phase 6 section with gate G6. Effort row P6. Total-effort sentence |
| `docs/project-overview-pdr(.vi).md` | Goals line |
| `docs/privacy(.vi).md` | "In short" bullet, Permissions (Accessibility for browser pages, Mac Automation), new section "Web pages (Continue Browsing, planned)" per W7. Date 2026-09-28 |
| `docs/system-architecture(.vi).md` | Transport table row. `type` list gains `session`, `camera`, `web` |
| `README(.vi).md` (root) | Feature table row (planned), roadmap item 6 |
| `plans/20260925-implementation/phase-06-web-handoff(.vi).md` | New phase file. Gate G6 section, then cards T6.0 (spike), S6.1, A6.1, A6.2, M6.1, M6.2, I6.1, T6.1. Branch and order, tests, risks |
| `plans/20260925-implementation/plan(.vi).md` | Status line, sources v1.3 (38 leaves, C1–C21), I3/I4, phase row 6, effort P6 1.5, reading order C1–C21, gate row G6 |
| `tools/docs/validate_design_docs.py` | The glob went from `0[1-8]-*.md` to `0[1-9]-*.md`. Before this change the validator skipped group 9 |

## Checks

- `python3 tools/docs/validate_design_docs.py` → `files=18 leaves=76 problems=0`
- `python3 tools/docs/check_bilingual_docs.py` → `pairs=70 missing=0 problems=0 warnings=0`
- `python3 tools/docs/apple_diacritics.py` on every changed `.vi.md` → `DRY RUN 0 files, 0 words`
- `shared/tools/.venv/bin/python3 shared/tools/schemas/check_schemas.py` (shared `main` d7e9761) → one FAIL, as expected: `envelope.type lệch 0.7.1: spec [... 'web'], schema [...]`. The first run also read the browser id table as envelope types, because the checker takes every `| \`x\` |` row in 0.7.1 as a type. Commit 323142e fixed this on the hub side by putting the browser name in the first column. The 09 JSON examples are skipped for now because `web` is not in `SCOPED_TYPES`.

## What shared must add (card S6.1)

1. `schemas/envelope.schema.json`: add `web` to `$defs.type.enum`. This is the only failing check now.
2. New `schemas/web-active.schema.json`. Required: `page_id` (uuid v7), `url` (string, `^https?://`, at most 8192 bytes of UTF-8; JSON Schema counts characters, so the byte limit is also checked in code), `browser` (enum `chrome, samsung, firefox, edge, brave, opera, vivaldi, duckduckgo, safari, arc, other`), `observed_at` (timestamp). Optional: `title` (maxLength 256). `additionalProperties: false`.
3. New `schemas/web-inactive.schema.json`: `{page_id}` only.
4. `schemas/capability-hello.schema.json` `$defs/features`: add `web` = `{enabled, send, receive}`, all bool, all required, `additionalProperties: false`. `capability-update` shares it.
5. `tools/schemas/doc_examples.py`: add `web` to `HEADING_TYPE_OP`, `HEADING_TYPE_ONLY` and `SCOPED_TYPES`, so the two JSON examples in `09-web-handoff.md` get validated. Optional: a spec check of the browser enum against the 0.7.1 table (the id is now in column 2).
6. Positive and negative samples, for example `url` with `javascript:` or `file:`, a 257-character title, an unknown extra field, and a missing `browser`.
7. `tools/strings/catalog_rules.py` `GROUPS`: add `web`, to match 0.12.1.
8. `strings/ui-strings.json`: the strings below, with `specs` WEB-0x and SET-02.

## New UI texts (en / vi) with proposed catalog keys

| Proposed key | en | vi | Where |
|---|---|---|---|
| `web.title` | Continue Browsing | Duyệt web tiếp | SET-02 f34, WEB-01 f1, WEB-05 f4, feature card |
| `web.description` | Continue on one device the web page you're viewing on another. | Xem tiếp trên thiết bị này trang web đang xem trên thiết bị khác. | SET-02 f34 (Android) |
| `web.disclosure.title` | Continue Browsing on Your Other Devices | Duyệt web tiếp trên thiết bị khác | WEB-01 f2 |
| `web.disclosure.body` | HandLive uses a separate Accessibility service, HandLive Browser Pages, only to read the address and title of the page open in supported browsers, then sends them (end-to-end encrypted) to your paired Mac, iPhone, and iPad. / The service receives events only from those browsers. It never reads other apps or what you type, and never sends pages from incognito or private tabs. Addresses are never stored. / You can turn this off at any time. | HandLive dùng một dịch vụ Hỗ trợ tiếp cận riêng, Trang trình duyệt HandLive, chỉ để đọc địa chỉ và tiêu đề của trang đang mở trong các trình duyệt được hỗ trợ, rồi gửi (mã hóa đầu-cuối) tới Mac, iPhone, iPad đã ghép nối. / Dịch vụ chỉ nhận sự kiện từ các trình duyệt đó. Dịch vụ không đọc ứng dụng khác hay nội dung bạn gõ, và không gửi trang trong tab ẩn danh hoặc riêng tư. Địa chỉ không bao giờ được lưu. / Bạn có thể tắt bất cứ lúc nào. | WEB-01 f3 (3 paragraphs) |
| existing "Agree" key / `web.disclosure.not_now` (or existing "Not Now") | Agree / Not Now | Đồng ý / Để sau | WEB-01 f4 |
| `web.a11y_service.label` | HandLive Browser Pages | Trang trình duyệt HandLive | WEB-01 f5 (service label) |
| `web.a11y_service.summary` | Reads the address of the page open in supported browsers so you can continue on your Mac, iPhone, or iPad. | Đọc địa chỉ trang đang mở trong các trình duyệt được hỗ trợ để bạn xem tiếp trên Mac, iPhone, iPad. | WEB-01 f5 |
| `web.card.needs_accessibility` | Browser pages aren't on yet | Chưa bật trang trình duyệt | WEB-01 f6 |
| `web.send_phone` | Send Pages from This Phone | Gửi trang từ điện thoại này | SET-02 f35 (Android) |
| `web.send_mac` | Send Pages from This Mac | Gửi trang từ Mac này | SET-02 f35 (Mac) |
| `web.notify` | Page Notifications | Thông báo trang | SET-02 f36 |
| `web.browsers` | Browsers | Trình duyệt | SET-02 f37 |
| `web.automation.not_allowed` | Not allowed | Không được phép | WEB-03 f3 |
| existing "Open System Settings" | Open System Settings | Mở Cài đặt hệ thống | WEB-03 f3 |
| `infoplist.apple_events_usage` (`NSAppleEventsUsageDescription`) | HandLive reads the address of the page open in your browser so you can continue on your phone. | HandLive đọc địa chỉ trang đang mở trong trình duyệt để bạn xem tiếp trên điện thoại. | WEB-03 f4 |
| `web.menu_item` (args `title_or_host`, `device_name`) | {title_or_host} — from {device_name} | {title_or_host} — từ {device_name} | WEB-02 f2 |
| `a11y.web_menu_item` | Page from {device_name}: {title_or_host} | Trang từ {device_name}: {title_or_host} | WEB-02 VoiceOver |
| `a11y.web_badge` | HandLive, page from your phone available | HandLive, có trang từ điện thoại | WEB-02 badge label |
| `web.mac_notification_body` (args `host`, `device_name`) | {host} — from {device_name} | {host} — từ {device_name} | WEB-02 f4 |
| `web.open_on_phone` | Open on this phone | Mở trên điện thoại này | WEB-04 f2 |
| `notification.channel_web_name` | Pages from your devices | Trang từ thiết bị của bạn | WEB-04 f4 (`hl_web`) |
| `notification.channel_web_description` | The web page open on your Mac, to continue on this phone. | Trang web đang mở trên Mac, để xem tiếp trên điện thoại này. | WEB-04 f4 |
| `web.lock_screen` (arg `device_name`) | Page from {device_name} | Trang từ {device_name} | WEB-04 f6 |
| `error.web_no_app` | No app can open this page. | Không có ứng dụng nào mở được trang này. | WEB-04 E4 (toast) |
| `web.ios_banner` (arg `title_or_host`) | Continue browsing: {title_or_host} | Duyệt web tiếp: {title_or_host} | WEB-05 f1 |
| `a11y.web_ios_banner` (args `title_or_host`, `host`) | Continue browsing: {title_or_host}, {host} | Duyệt web tiếp: {title_or_host}, {host} | WEB-05 VoiceOver |

Browser names (Chrome, Samsung Internet, …) are proper names and are not translated. Feature-card statuses reuse the existing "On"/"Off" keys.

## Choices where the plan was silent (smallest consistent option)

1. Component code **A-WEB** (0.1) and identifier **`page_id`** in 0.2. Step tables need a component code.
2. Key **`web.a11y_consent_at`**. It mirrors `clip.a11y_consent_at`, so the disclosure consent can be recorded and asked again when the scope widens.
3. **Capability mapping.** `enabled` = `feature.web`. `send`: on Android, `web.send` plus the service running; on the Mac, `web.send`; on iOS, always `false`. `receive`: on Android, `web.notify` plus notifications allowed, because the notification is Android's only place to show a page; on the Mac and iOS, `true`. As a result, the Mac does not poll when the phone cannot show anything.
4. **`page_id` rules.** A new `page_id` for each new URL. The same `page_id` when only the title changes, and when the page is re-sent after a reconnect. The receiver resolves "latest wins" by the largest `observed_at`.
5. **No periodic refresh.** The TTL restarts only with a new `web/active`. A page left open and unchanged for more than 10 minutes therefore disappears from the receiver (see the questions).
6. **Android leaving the foreground.** With `packageNames` filtering and only two event types, the service cannot see other apps' events, so the mechanism is left to G6. The required result is fixed: `web/inactive` within `WEB_SETTLE`.
7. **Mac details.** The page item has ⌘O while the menu is open (my reading of "Shortcut in the menu"). The host shows as the menu item subtitle, or as a disabled second line on systems without subtitles. The notification is passive, with the id `web:<pair_id>` and the body "{host} — from {phone}". Each script has a 1 s time limit.
8. **Android notification details.** `VISIBILITY_PRIVATE` with the public version "Page from \<Mac>". The host goes in the sub-text. One notification per Mac (tag `web:<pair_id>`). `CATEGORY_RECOMMENDATION`. A toast when no app handles the URL.
9. **Candidate lists.** Package names and bundle ids are marked "confirmed in G6". Opera, Vivaldi and DuckDuckGo on Android are marked "Later" (W8 does not name them).
10. **Effort row P6.** `0.6 / 0.4 / 0.1 / — / 0.4 / 1.5` converts W9's weeks at 5 weeks per person-month. That is the only conversion that adds up to W9's "about 1.5": 7.5 person-weeks is 1.75 person-months at 4.3 weeks per month.
11. **Capability JSON example in 0.7.2 not extended with `web`.** The strict 00 example check would fail until shared adds the schema. Shared (or a later hub commit) can add it once S6.1 lands.
12. **Out of scope, not touched:** hub `CLAUDE.md` (still says C1–C20 and five phases), `docs/codebase-summary*.md`, and `docs/design-system/` (a `MenuBarMenu` badge variant and the `hl_web` channel in `Notification` are needed; they are listed in the phase-06 context).

## Unresolved questions

- TTL without refresh: should the sender re-send the same page periodically, for example every 5 minutes while it stays in the foreground, so a long read does not disappear after 10 minutes? The plan says "without a refresh" but defines no refresh.
- WEB-05 banner location: the plan says "Devices screen". On iOS that is Settings tab › Phone (PAIR-02). The owner may prefer a more visible place, such as the top of every tab.
- Should Android also show the Mac's page somewhere when `web.notify = false`? As specified, `receive = false` in that case.
- ⌘O as the menu shortcut is an interpretation. A global hotkey would need its own setting.

## Commits (hub `main`, signed off, not pushed)

a53f687, 0c74a3b, 7b7ec6f, a99bcc7, 5c69555, b13c5bd, e5fa771, a219dbd, bd084f1, 0e3d513, 323142e.

Status: DONE_WITH_CONCERNS
Summary: The Web Handoff proposal (W1–W9) is written into the detailed design (new group 9, 00, README C21, SET-01/SET-02), the roadmap, the PDR, privacy, the architecture summary, the root README and the implementation plan (phase-06 plus G6), in both languages. The hub checks are green.
Concerns/Blockers: the hub CI schema check fails until shared adds `web` to the envelope enum (the S6.1 list above). There are four open product questions (TTL refresh, iOS banner place, Android with notifications off, ⌘O). The validator glob was extended, because group 9 was previously skipped.

## Round 2 (coordinator decisions, 2026-09-28)

| # | Decision | Applied in |
|---|----------|------------|
| 1 | Refresh: while the same page stays open, the sender re-sends `web/active` with the same `page_id` every `WEB_REFRESH` = 5 minutes | 0.10 new constant `WEB_REFRESH`; 09 header refs, QW3, WEB-01 step 7, WEB-01 API 1 logic 1, WEB-03 step 8; phase-06 requirements |
| 2 | iPhone/iPad banner is an overlay at the top of whichever tab is visible and can be closed; closing hides it until a new `page_id` arrives | WEB-05 description, postconditions, field 1, new field 5 ("Close" button), chart labels U6/S5, steps 5 and 6; phase-06 card I6.1 |
| 3 | Android `web.notify` off → `receive = false` is intended | SET-02 field 36: turning it off stops showing pages from other devices on this phone |
| 4 | ⌘O stays | No change |
| 5 | Owner decision: Phases 5 and 6 are done before Phase 4 finishes (Phase 4 waits for the G4 HFP hardware spike) | Roadmap intro (exception to "built in order") and Phase 6 section; plan status line, I3 exception list (phase dependency column still holds), I4 (G5/G6 spikes run while G4 waits); phase-06 status. phase-05 files say nothing about waiting for Phase 4, so they are unchanged. CLAUDE.md not touched |

New UI string: the close button reuses the common "Close" / "Đóng" key if the catalog has one; otherwise `a11y.web_banner_close`.

Checks: `validate_design_docs.py` problems=0 (files=18, leaves=76); `check_bilingual_docs.py` pairs=70 problems=0; `apple_diacritics.py` dry run 0 files. `check_schemas.py` against shared main: still only the expected `web` envelope enum FAIL. Shared S6.1 needs nothing new for Round 2, apart from optionally mirroring `WEB_REFRESH` in its samples.

Round 2 commits (hub `main`, signed off, not pushed): deaacfc, c1f1304, 1582d98, 50599e2.

Status: DONE
Summary: Round 2 applied in both languages: WEB_REFRESH (5 min), the closable iPhone/iPad overlay banner, the SET-02 note for `web.notify` on Android, and the owner decision that Phases 5 and 6 are done before Phase 4 finishes, recorded in the roadmap, the plan and phase-06.
Concerns/Blockers: the hub CI schema check still fails on the `web` envelope enum until shared S6.1 lands.
