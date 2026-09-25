# Phase 1 — S1.2: UI string catalog

Card S1.2 of `phase-01-bang-nho-tam-mvp.md`: catalog `shared/strings/ui-strings.json` (00-common-specs 0.12, decision C20), its JSON Schema, the checker of 0.12.5, a CI step, and the documentation. Branch `feat/phase-01-clipboard` of handlive-shared, pushed; CI `ci-shared` green (run 36154875995 on a665b91, later pushes too).

## What was done

- **Schema** `strings/ui-strings.schema.json` (Draft 2020-12, `$id` `https://handlive.app/schemas/v1/ui-strings.schema.json`): fields exactly as 0.12.1 (`key`, `en`, `vi`, `comment`, `platforms`, `specs`, `args`, `plist_key`); key pattern with the 17 groups and 2–5 segments; translations as a string or a CLDR plural object; `plist_key` required in group `infoplist` and forbidden elsewhere. A future language needs no schema change (translation fields are matched by a language-code pattern).
- **Checker** `tools/strings/check_strings.py` (+ `catalog_rules.py`, `spec_docs.py`, `self_test.py`, `requirements.txt` → the pinned jsonschema of `tools/schemas`). Errors: schema; repeated JSON field; unique keys, also after `.` → `_`; entries sorted by key; every language present, no unlisted language; placeholders `{name}` declared and identical in every translation (a plural's `one` variant may omit `{count}`), no stray brace; plurals en `one`+`other`, vi `other`, all translations plural, an `int` argument `count`; non-empty, no edge whitespace, NFC, no control characters, "…" not "..."; Apple-style tone marks in `vi` (rejects hoá, xoá, huỷ, tuỳ, thuỷ, khoẻ, khoá, hoà, hoạ, thoả, luỹ…, accepts quý, quả, hoàn, ngoài…; suggests the fix); `plist_key` only in `infoplist`; `specs` IDs exist as headings in `../docs/detailed-design` (`HANDLIVE_DOCS_DIR` or `--docs DIR` override). Warning: translations ending with different punctuation. `--docs`: looks for each `vi` text in the Vietnamese docs and each `en` text in the English docs of `docs/detailed-design` and `docs/design-system`; `X.md` counts as English when `X.vi.md` exists, a lone `X.md` is classified by its share of Vietnamese letters (same measure as the hub's `check_bilingual_docs.py`), so it works before, during and after the translation. Placeholders match the spec's example or `<name>`, quotes compare equal whatever their shape, `<br>`, blockquotes and line wraps are ignored, a final period is optional. `--self-test`: 83 checks, each rule against its own mistake plus docs matching on temporary files; I also confirmed the tests fail when a rule is broken.
- **check_schemas.py** now validates the catalog excerpt of 0.12.1 (the ```jsonc block) against the catalog schema and rules (order free) — the "mở rộng check_schemas.py để nhận ví dụ catalog" part of the card.
- **Catalog**: 169 strings (pairing 33, settings 27, clipboard 21, setup 17, status 16, error 13, common 11, notification 10, permission 9, menu 5, push 4, infoplist 3), covering SET-01, SET-02 fields 1–6, 21–23, 31, 32, SET-03 (Mac, plus the shared Mac/iOS texts), PAIR-01 (QR and PIN), PAIR-02, PAIR-03 flow A, CONN-01, CONN-02, CLIP-01, CLIP-02, CLIP-03, CLIP-05, the 0.11 states, FEATURE_DISABLED of 0.8.1, the Mac purpose strings (`NSMicrophoneUsageDescription`, `NSFocusStatusUsageDescription`, `NSLocalNetworkUsageDescription`), Android channels `hl_service`, `clipboard`, `permission` (name + description), and `push.sms_new`, `push.call_incoming`, `push.call_missed` (+ `push.generic`, the CONN-04 fallback body). The Phase 1 component texts of the design system that the leaf specs rely on without quoting (Settings pane names, `MenuBarMenu` items, `PairingCard`, `PermissionPrimer` titles and footer, empty states, `DeviceRow` buttons) are included with the leaf ID that uses them. `vi` is quoted from the specs (165 of 169 texts are found verbatim by `--docs`; the 4 others are listed below). `en` follows the design system's English rules (title-style for buttons, menu items, window/sheet/alert/notification titles, settings rows; sentence-style for statuses, bodies, footnotes; OS names as the OS shows them).
- **CI** `ci-shared.yml`: installs `tools/strings/requirements.txt`, runs `check_strings.py --self-test` and `check_strings.py --docs`.
- **Docs**: `strings/README.md` (English) and `strings/README.vi.md`: fields, repository conventions, writing rules, platform mapping (0.12.2), change order, lock procedure, checker. Top-level README tables list `strings/` and `tools/strings/`; `tools/schemas/README.md` gains step 4.

**Update after the controller's correction (title-style).** English title-style now follows Apple's rule: articles (a, an, the), coordinating conjunctions (and, but, or, nor, for, so, yet) and prepositions of four or fewer letters (at, by, for, from, in, into, of, off, on, onto, out, over, to, up, via, with) stay lowercase unless first or last. The sweep changed one value: `pairing.confirm_title` "Pair With {device_name}?" → "Pair with {device_name}?" (Android-only key; **the Apple agent should still regenerate its String Catalogs from the current catalog**, and the Android agent its resources). The READMEs state the word list, and `check_strings.py` now warns when such a word is capitalized inside an English title-style text (self-test 96 checks). Meanwhile the Android agent added ten Android-only keys from the proposals of item 13 (commit c3ac31a: `error.qr_invalid`, `error.pairing_closed`, `pairing.camera_denied`, `pairing.limit_reached`, `pairing.pin_attempts_left`, `pairing.unpaired`, `pairing.unpaired_pending`, `status.connected_internet_to`, `status.connected_usb_to`, `common.app_name`); the catalog now has 179 strings.

Keys the platforms will use first: `status.*` (0.11), `menu.*` and `settings.*` (Mac menu bar and Settings), `setup.*` / `permission.*` (first run), `pairing.*`, `clipboard.*` and `error.clip_*`, `notification.*` (Android service and channels), `infoplist.*` (`plist_key` = Info.plist key).

**State after the hub translation merged** (hub `main` 00561f8: detailed design and design system now English `X.md` + Vietnamese `X.vi.md`): `check_strings.py --docs` finds 168 of 179 `en` texts in the English specs and 166 of 179 `vi` texts in the Vietnamese specs. The remaining warnings are exactly the texts the specs do not define yet: the three channel descriptions, `error.update_this_app` (vi), and the ten Android-only keys added from the proposals of item 13 (`error.qr_invalid`, `error.pairing_closed`, `pairing.camera_denied`, `pairing.limit_reached`, `pairing.pin_attempts_left`, `pairing.unpaired`, `pairing.unpaired_pending`, `status.connected_internet_to`, `status.connected_usb_to`; `common.app_name` is found). Adding those texts to the specs clears every warning.

**Shared README translation (task 5 of the brief, same branch):** `test-vectors/`, `schemas/`, `design-tokens/`, `tools/vectors/` and `tools/schemas/` now have an English `README.md` and a Vietnamese `README.vi.md` (language switcher on line 1); the top-level README tables list `strings/`, `tools/strings/` and `tools/bench/`, and the Vietnamese one links the Vietnamese twins. All eight README pairs of the repository pass the pair checks of the hub's `tools/docs/check_bilingual_docs.py` (0 problems, 0 warnings, run through its `check_pair`/`check_links` because the script's scope excludes `shared/`). Commits: f8e76f2, 843dd7c, e798c3c, b3e2c5a, 29a351d (one per folder), aa000e5 (links); CI run 36158487418 green.

## Commits (handlive-shared, branch `feat/phase-01-clipboard`)

| Hash | Subject |
|------|---------|
| 0f8ba84 | feat(shared): add JSON Schema for the UI string catalog |
| 25a961b | feat(shared): add check_strings.py for the UI string catalog |
| b562afc | feat(shared): add the Phase 1 UI string catalog |
| 75c6825 | feat(shared): check the catalog example of 0.12.1 in check_schemas |
| a665b91 | ci: check the UI string catalog in ci-shared |
| a2c8ad6 | docs: document the UI string catalog and its checker |
| 19472f6 | fix(shared): apply Apple title-style capitalization to catalog strings |
| 80db08c | feat(shared): warn about capitalized minor words in English title-style strings |

## Files

Created: `shared/strings/ui-strings.json`, `shared/strings/ui-strings.schema.json`, `shared/strings/README.md`, `shared/strings/README.vi.md`, `shared/tools/strings/check_strings.py`, `shared/tools/strings/catalog_rules.py`, `shared/tools/strings/spec_docs.py`, `shared/tools/strings/self_test.py`, `shared/tools/strings/requirements.txt`.
Changed: `shared/tools/schemas/check_schemas.py`, `shared/tools/schemas/README.md`, `shared/.github/workflows/ci-shared.yml`, `shared/README.md`, `shared/README.vi.md`.

**Shared change for other platforms:** new files only; test vectors and schemas unchanged. Android (A1.5) and Apple (M1.5) generate their resources from `strings/ui-strings.json`.

## Tests (real output, from `shared/`)

```text
$ tools/.venv/bin/python tools/strings/check_strings.py
== strings/ui-strings.json: 169 strings, languages en, vi
== 169 strings, 0 errors, 0 warnings
OK

$ tools/.venv/bin/python tools/strings/check_strings.py --self-test
self-test: 83 passed, 0 failed          # 96 passed, 0 failed after the title-style check (80db08c)

$ tools/.venv/bin/python tools/strings/check_strings.py --docs | tail -9
== --docs: texts quoted in /Users/hxd/HandLive/docs/detailed-design, /Users/hxd/HandLive/docs/design-system (warnings only)
  SKIP en: no English spec yet
  vi: 165 of 169 texts found in 50 Vietnamese docs
  WARN error.update_this_app [vi]: not quoted in the Vietnamese specs
  WARN notification.channel_clipboard_description [vi]: not quoted in the Vietnamese specs
  WARN notification.channel_permission_description [vi]: not quoted in the Vietnamese specs
  WARN notification.channel_service_description [vi]: not quoted in the Vietnamese specs
== 169 strings, 0 errors, 4 warnings
OK

$ tools/.venv/bin/python tools/schemas/check_schemas.py | tail -3
  mẫu âm bị từ chối: 36
  ví dụ catalog chuỗi giao diện: 1
  XANH: mọi kiểm tra đạt

$ tools/.venv/bin/python tools/vectors/verify_vectors.py | tail -1
Tổng: 360 phép kiểm, 0 lỗi
$ tools/.venv/bin/python tools/vectors/generate_vectors.py --check | tail -1
check: 14 file, 0 lệch

$ gh run list -R HandLive/handlive-shared --branch feat/phase-01-clipboard
completed success ci: check the UI string catalog in ci-shared          ci-shared feat/phase-01-clipboard push 36154875995
completed success feat(shared): add the Phase 1 UI string catalog       ci-shared feat/phase-01-clipboard push 36154771679
```

## Spec deviations and proposals

Nothing in the hub was edited. Where the docs disagree, the catalog follows the leaf spec (then 00-common-specs, then the design system):

1. **Microphone purpose string.** 0.12.1's example has "HandLive dùng micro để gửi giọng nói của bạn trong cuộc gọi nghe trên Mac này." / "HandLive uses the microphone to send your voice during calls taken on this Mac."; SET-03, AUDIO-01 API 3 and design system 02-xin-quyen have "HandLive dùng micro để bạn nói trong cuộc gọi chuyển từ điện thoại." (design system 10-quyen-rieng-tu proposes a third). Catalog uses SET-03. Proposal: align the 0.12.1 example and 10-quyen-rieng-tu with SET-03. *Resolved in the hub since (0.12.1 now quotes the catalog text).*
2. **Add/pair action on Mac and iPhone.** "Thêm điện thoại…" (PAIR-01 step 1, SET-03 step 13, design system 09) vs "Ghép điện thoại…" (design system macOS app menu, Settings › Devices, empty state of 05, action of "Cần ghép nối lại"). Both are in the catalog (`pairing.add_phone`, `pairing.pair_phone`). Proposal: keep one label.
3. **Mac/iPhone empty state.** Design system 05: "Chưa ghép nối" + "Ghép điện thoại…"; design system 09: "Chưa có điện thoại" · "Ghép điện thoại Android để nhận bảng nhớ tạm, tin nhắn và cuộc gọi." · "Thêm điện thoại…". Catalog: 09 for the empty state, "Chưa ghép nối" (`status.not_paired`) for the menu bar status of SET-03 step 1.
4. **Idle service notification.** SET-01 field 5 and CONN-01 field 6 "Đang chờ kết nối"; design system 03-thong-bao "HandLive đang chờ kết nối" (against its own rule of no "HandLive" in notifications). Catalog follows SET-01.
5. **USB state.** 0.11 "Đã kết nối qua USB" vs StatusIndicator "Đang dùng USB". Catalog follows 0.11 (`status.connected_usb`).
6. **"Mở Cài đặt" (SET-03 field 13).** Design system: Mac "Mở Cài đặt hệ thống", iPhone/Android "Mở cài đặt". Catalog: `common.open_system_settings` (Mac), `common.open_settings` (Android, iOS). Proposal: SET-03 field 13 names both.
7. **One spec sentence, several UI strings.** Notifications need a title and a body, so CLIP-01 fields 8 and 12 are split as the design system's Notification component does (`clipboard.sensitive_blocked_title`/`_body`, `clipboard.conflict_title`/`_body`); the Accessibility disclosure (CLIP-01 field 2) is split into its four sentences because `ConsentSheet` shows one sentence per row. Proposal: write them as separate quoted strings in CLIP-01.
8. **Punctuation and quotes.** Primer bodies end with a period (the design system has it for SET-01 steps 3 and 5b; SET-03 step 7 has none anywhere — proposal: add it). Nested quotes are typographic “…” in the catalog; the specs use straight quotes (the checker compares quote-insensitively).
9. **Composed or missing texts (the 4 `--docs` warnings).** `error.update_this_app` "Cập nhật HandLive trên máy này": CONN-01 API 6 writes '"Cập nhật HandLive trên điện thoại" hoặc "trên máy này"' — proposal: spell the full second string. The three channel descriptions (`notification.channel_*_description`) are proposed texts: the specs name the channels ("Dịch vụ kết nối", "Bảng nhớ tạm", "Quyền") but give no description — proposal: add them to SET-01 API 3, CLIP-01 field 8, SET-01 field 17. Also, the `clipboard` channel importance differs: CLIP-01 field 8 `IMPORTANCE_DEFAULT`, design system 03-thong-bao `IMPORTANCE_LOW` (not a string; the Android agent has to pick).
10. **Camera primer for QR scanning** (`permission.camera_qr_primer`) comes from design system 02-xin-quyen where it is marked "Đề xuất"; SET-01 API 2 has no text yet — proposal: add it there.
11. **Vietnamese `message` in protocol examples** contradicts 0.12.4 (English diagnostics): 02-pairing API 6 `"Mã PIN không đúng"`, 03-connectivity API 6 `"Thiết bị chưa được ghép nối"`, 04-clipboard `"Vượt giới hạn văn bản"`, `"SHA-256 không khớp"`. Proposal: English messages in the examples.
12. **English wording is mine** and was written while the hub docs are being translated (no English spec exists yet, `--docs` skips `en`). Proposal: the translators copy the `en` texts of the catalog into the English specs, or run `tools/strings/check_strings.py --docs` after the translation and reconcile (docs first, catalog second). Title-style follows Apple's rule (see the update above); design system 09-viet-noi-dung still says "three letters or fewer" and the controller fixes it after the translation merges.
13. **Texts the Phase 1 UI needs but the specs do not spell out** — not in the catalog (proposed wording below; add them to the specs, then the platform agents add the keys):

| Where | Proposed key | vi | en |
|-------|--------------|----|----|
| PAIR-01 E1 (Android) | `error.qr_invalid` | Mã QR này không phải của HandLive. | This QR code isn't a HandLive code. |
| PAIR-01 E2 (Android) | `error.pairing_closed` | Mã QR đã đổi. Quét mã mới trên Mac hoặc iPhone. | The QR code has changed. Scan the new code on your Mac or iPhone. |
| PAIR-01 E3 (client) | `pairing.phone_not_found` | Không tìm thấy điện thoại. Để hai máy cùng mạng Wi-Fi rồi thử lại. | Couldn't find the phone. Put both devices on the same Wi-Fi network and try again. |
| PAIR-01 E6 (Android) | `pairing.limit_reached` | Điện thoại đã ghép đủ 8 thiết bị. Hủy ghép nối một thiết bị rồi thử lại. | This phone is already paired with 8 devices. Unpair one and try again. |
| PAIR-01 field 7 | `pairing.pin_attempts_left` | {other: Còn {count} lần thử} | {one: {count} attempt left, other: {count} attempts left} |
| PAIR-01 E9 | `pairing.camera_denied` | Không dùng được camera. Dùng mã PIN để ghép nối. | The camera isn't available. Use a PIN to pair. |
| PAIR-03 field 4 | `pairing.unpaired`, `pairing.unpaired_pending` | Đã hủy ghép nối · Đã hủy ghép nối; {device_name} sẽ tự dọn khi kết nối lại | Unpaired · Unpaired; {device_name} will clean up when it reconnects |
| CLIP-03 field 2 (receiver) | `clipboard.image_receiving` | Đang nhận ảnh từ {device_name} — {percent} | Receiving image from {device_name} — {percent} |
| StatusIndicator a11y | `status.connected_internet_to` | Đã kết nối qua Internet với {device_name} | Connected over the internet to {device_name} |
| SET-01 E1 banner | `setup.notifications_denied` | Thông báo đang tắt: không thấy trạng thái kết nối và yêu cầu từ Mac. | Notifications are off, so connection status and requests from your Mac don't appear. |

Also unspecified: PermissionPrimer titles on Android (notifications, background, autostart screen), SET-01 feature-card state texts (ready, needs permission, permanently denied, off, unsupported) and E3/E9 texts, PAIR-02 detail row labels (model, app version, last connected, features, missing permissions) and E4, SET-03 local network primer body and the E1–E5 guidance texts (translocated app, notifications denied, local network denied, login item approval), CONN-01 E4 and E8.

## Pending manual checks

- System names on real devices, both languages: Android "Pause app activity if unused" / "Tạm dừng hoạt động nếu không dùng", "Restricted setting" / "Allow restricted settings", the Xiaomi, OPPO/realme/OnePlus and Samsung autostart paths, the Android 12+ read toast; macOS "Paste from Other Apps" and "Always Allow" with their Vietnamese names (A1.4 and M1.1 already plan this check).
- Largest text size in `en` and `vi` for the long strings (consent lines, `setup.restricted_settings_help`, `settings.paste_permission_hint`).

Status: DONE_WITH_CONCERNS
Summary: The Phase 1 catalog (169 strings, en + vi), its schema, check_strings.py with --docs and --self-test, the 0.12.1 example check in check_schemas.py, the CI step and the READMEs are committed and pushed on feat/phase-01-clipboard of handlive-shared; the checker and CI are green.
Concerns/Blockers: English texts were written before the English specs exist and must be reconciled with the translation; four catalog texts are not yet in the specs (three proposed channel descriptions, one composed string) and the specs disagree in a few places (items 1–6); several UI texts the Phase 1 screens need are still unspecified (item 13).
