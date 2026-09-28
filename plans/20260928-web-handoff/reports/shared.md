# S6.1 shared contract for Web Handoff (Continue Browsing): report

Date: 2026-09-28 · Agent: shared-contract agent · Repo: handlive-shared, branch `feat/phase-06-web-handoff` (from `origin/main` 5fc8a3f), pushed, not merged.

## Files

| File | Change |
|------|--------|
| `schemas/envelope.schema.json` | `web` added to `$defs.type.enum` (11 types) |
| `schemas/web-active.schema.json` (new) | `{op: "active", data}`. Required `page_id` (uuid-v7), `url` (pattern `^https?://[^/?#\s]`, so a host character must follow; maxLength 8192), `browser` (`$defs/browser` enum of the 11 ids in 0.7.1 order), `observed_at` (timestamp). Optional `title` (1–256 chars). `additionalProperties: false` |
| `schemas/web-inactive.schema.json` (new) | `{op: "inactive", data: {page_id}}` |
| `schemas/capability-hello.schema.json` | `features.web` → `$defs/feature-web` `{enabled, send, receive}`, all bool and all required, closed. `capability-update` shares it |
| `tools/schemas/doc_examples.py` | `web` in `HEADING_TYPE_OP`, `HEADING_TYPE_ONLY`, `SCOPED_TYPES`. The 09 examples (en + vi, WEB-01 API 1 and 2) are now validated |
| `tools/schemas/web_spec_checks.py` (new) | Checks against 00-common-specs: the `web` ops of 0.7.1 match the `web-*` files; the browser table ids (column 2) match the `browser` enum, in order; the `features.web.*` rows of 0.7.2 match the `feature-web` fields and its required list; `WEB_URL_MAX` and `WEB_TITLE_MAX` (0.10) match the `url` and `title` maxLength |
| `tools/schemas/sample_messages_web.py` (new) | 10 positive samples and 21 negative ones. Negatives: `javascript:`, `file:`, `chrome:` URL, no host, leading space, 8193 chars, 257-char/empty/null title, missing/unknown browser, missing/float `observed_at`, v4 `page_id`, extra field, wrong op, `inactive` with `url` or without `page_id`, and `features.web` missing `receive`, string `send`, or an extra field |
| `tools/schemas/check_schemas.py` | Wires in the new module and the samples. The docs range reads 01–09 |
| `tools/strings/catalog_rules.py`, `strings/ui-strings.schema.json` | Group `web` added between `camera` and `permission`, as in 0.12.1 |
| `strings/ui-strings.json` | 27 new strings. `specs` added to three existing keys |
| `schemas/README(.vi).md`, `tools/schemas/README(.vi).md`, `strings/README(.vi).md`, `CLAUDE.md` | New files, rules, checks and group listed. 11 types. Range 01–09 |

## UI string keys (en + vi exactly as the 09 / SET-02 texts)

New: `web.title`, `web.description`, `web.disclosure.title`, `web.disclosure.purpose`, `web.disclosure.events`, `web.disclosure.turn_off`, `web.disclosure.not_now`, `web.a11y_service.label`, `web.a11y_service.summary`, `web.card.needs_accessibility`, `web.send_phone`, `web.send_mac`, `web.notify`, `web.browsers`, `web.automation.not_allowed`, `infoplist.apple_events_usage` (`plist_key` `NSAppleEventsUsageDescription`), `web.menu_item` (`{title_or_host}`, `{device_name}`), `a11y.web_menu_item`, `a11y.web_badge`, `web.mac_notification_body` (`{host}`, `{device_name}`), `web.open_on_phone`, `notification.channel_web_name`, `notification.channel_web_description`, `web.lock_screen` (`{device_name}`), `error.web_no_app`, `web.ios_banner` (`{title_or_host}`), `a11y.web_ios_banner` (`{title_or_host}`, `{host}`).

Reused (spec added): `common.agree` (+WEB-01), `common.close` (+WEB-05; this is the banner's Close button, so no `a11y.web_banner_close`), `common.open_system_settings` (+WEB-03). On/Off reuse `common.on`/`common.off` as they are.

Deviations from the proposed keys:
- The report proposed a single `web.disclosure.body` for the disclosure. It is now three keys, `web.disclosure.purpose`, `.events` and `.turn_off`, one per paragraph. The catalog has no multi-line strings, and the clipboard disclosure already uses one key per line (`clipboard.consent_*`). With one key per paragraph, each text is found in the spec.
- "Not Now" became the new key `web.disclosure.not_now`. The only existing "Not Now" (`setup.applications_later`) is Mac-only and has a different meaning.

## Checks (local and CI)

- `tools/schemas/check_schemas.py` against the hub checkout → `XANH` (4 new PASS lines for 09/09.vi examples; 50 spec-table matches; 136 positive / 278 negative samples)
- `tools/strings/check_strings.py` → 423 strings, 0 errors, 0 warnings. `--docs`: en 423/423 and vi 423/423 found. `--self-test` 96 passed
- `tools/vectors/verify_vectors.py` → 0 lỗi; `generate_vectors.py --check` → 0 lệch (untouched)
- CI `ci-shared` workflow_dispatch run 36450357698: **success** (hub → main, handlive-shared → feat/phase-06-web-handoff). The push-triggered run 36450346634 was cancelled by the concurrency group because the dispatch run superseded it

## Commits (handlive-shared, signed off, pushed on `feat/phase-06-web-handoff`)

- 567e056 feat(shared): add the web type, web/active, web/inactive and features.web schemas
- ed4d6dc test(shared): check the web examples, browser ids and limits against the specs
- 7c4167d feat(shared): describe the web schemas and checks in the READMEs
- a673600 feat(shared): add the web group to the UI string catalog rules
- 8d43cc5 feat(shared): add the Continue Browsing UI strings

## For the other agents

Android (A6.x), Apple (M6.x, I6.1) and the relay should rerun their schema and string tests against this branch. The platform CIs are not started by changes here. The relay is unaffected: `web` travels only as an E2E envelope. When shared is merged, hub CI's envelope enum failure goes away.

## Open points

- `url` maxLength counts characters. The 8 KiB byte limit (`WEB_URL_MAX`) must also be checked in code on both sides, as the schema description and the README say.
- The `browser` enum is closed, so the schema rejects an unknown id. That fits the "schemas check what a sender emits" rule. Receivers still map unknown ids to `other` (0.5.1 rule 6).
- The 0.7.2 capability JSON example in the hub has no `features.web` yet. It can be added now, because the schema accepts it (spec report choice 11).

Status: DONE
Summary: The S6.1 shared contract is on handlive-shared `feat/phase-06-web-handoff`: the `web` envelope type, the web-active and web-inactive schemas, `features.web`, spec cross-checks, samples, the `web` string group and 27 Continue Browsing strings. All checks pass locally and in ci-shared.
Concerns/Blockers: none. The disclosure is split into three keys (not `web.disclosure.body`), and `web.disclosure.not_now` is a new key. Both are explained above.
