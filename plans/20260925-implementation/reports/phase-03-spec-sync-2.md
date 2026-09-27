# Phase 3 — spec sync 2: how the phone follows calls and sends their pushes

Applies the coordinator's decisions 1–11, taken from the "Spec deviations and proposals" of `phase-03-A3.1.md` and
`phase-03-A3.2.md`, to the hub specs. Both languages go in the same commit. The Android code already behaves this way;
the specs now say so. Hub `main`, pushed (`ff795ea..476764e`). No nested repository was edited.

## Decisions applied

| # | Decision | Where (EN + VI) |
|---|----------|-----------------|
| 1 | A withheld caller is also recognized from two ringing copies without the number key (`READ_CALL_LOG` granted), because AOSP adds the extra only for a non-empty number; `presentation = restricted`, the push leaves then; to be checked on devices | `06-call-control` CALL-01 API 3 logic 3 |
| 2 | An `OFFHOOK` copy's number fills only an `incoming` context whose ringing copy never came; `outgoing` / `unknown` keep `number = null`; outgoing numbers reach the Mac through the call log (CALL-04) | CALL-01 API 3 logic 2 |
| 3 | `sub_id` comes from the SIM whose transition created the context; a waiting call's SIM is not tracked | CALL-01 API 2 logic 3 |
| 4 | A queued `call_incoming` is dropped when the call stops ringing; a retry keeps `ttl_s = 30`; iOS removes stale incoming notifications itself (API 6) | CALL-01 E5; API 4 new logic 5 "Retries"; CALL-01 Query (new `DELETE FROM push_outbox … reason = 'call_incoming'`) |
| 5 | Without `READ_CALL_LOG` the push leaves at once, no 300 ms wait | CALL-01 API 4 logic 2; step 5 ("no wait without `READ_CALL_LOG`") |
| 6 | First `log_sync` with no entry in the 90-day window but older entries: cursor = the largest existing `_ID`; name cache per page (one `ack`) | CALL-04 API 1 logic 3 and 7 |
| 7 | `entry.display_name` falls back to `CACHED_NAME` also when `PhoneLookup` finds nothing | CALL-04 shared object `entry` |
| 8 | A ringing call is a relay demand: the relay is held from `RINGING`, for as long as the call rings, and serves a Mac waiting on the relay too | `03-connectivity` CONN-03 step 2; CALL-01 step 5 and API 4 logic 4 aligned |
| 9 | Name cut of call pushes: 64 code points with "…", then dropped | CONN-04 step 5b |
| 10 | `reason` in the `push_outbox` INSERT | CONN-04 Query |
| 11 | `push_outbox.reason TEXT NOT NULL DEFAULT 'sms_new'`, why it exists, Room schema version 3 | `00-common-specs` 0.9.1 |

### Closest-correct changes and interpretations (please confirm)

1. **Decision 9: length of the cut.** I wrote what the code does: `String.cut(64)` in `PushEnvelopeBuilder`
   gives at most 64 code points, and the last one is "…" (the first 63 code points + "…"). Names of 64 code
   points or fewer stay unchanged. This matches the A3.2 wording ("cut to 64 code points with '…'") and the style
   of the SMS rule ("first 999 code points + '…'"). Read literally, the decision's "64 code points plus '…'"
   would allow 65. The rule covers the names the builder cuts: `display_name` and `waiting_display_name` of
   `call_event/state`, and `entry.display_name` of `call_event/log_new`. The order is: as is → cut → names
   `null` → no push.
2. **Decision 10:** `reason` was also added to the retry `SELECT` of CONN-04 Query. Without it, a retry cannot
   read the reason back. The Android DAO uses `SELECT *`.
3. **Decision 4:** the drop is written as a design query in the CALL-01 Query section, mirroring the Android
   DAO's `deleteQueued`: `DELETE FROM push_outbox WHERE collapse_key = :collapse_key AND reason =
   'call_incoming'`.
4. **Decision 8:** the hold needs the idle rule too. CONN-03 step 2 now reconnects while "a call is ringing", and
   the phone leaves after 5 minutes without "a relayed session, a rendezvous, a ringing call or traffic". I aligned
   the 0.10 note of `RELAY_IDLE_DISCONNECT` in the same way, since its definition points to CONN-03 step 2. This
   matches A3.2: the hold counts as activity, and the 5 idle minutes start after the ringing.
5. **Decisions 1 and 5 and the push target:** CALL-01 API 4 logic 2 now says when the push leaves: as soon as the
   number is settled (the copy with the number, or a withheld caller recognized under API 3 logic 3), or at once
   without `READ_CALL_LOG`. The < 300 ms target therefore starts "from that moment": the broadcast that settled
   the number, `RINGING` without `READ_CALL_LOG`, or `RINGING` + 300 ms when no number came. The old wording
   ("from the broadcast that brought the number, or `RINGING` + 300 ms") left the two new cases undefined.
6. **Decision 11:** the column is appended after `expires_at` with no CHECK constraint, as in the Android entity
   (Room auto-migration 2 → 3). The comment says why the column exists and that Room schema version 3 adds it.
7. **Decision 2:** this answers A3.1 deviation 2 with "no": outgoing calls keep `number = null`. The schema rule
   "`outgoing` → `presentation = unknown`" is unchanged.
8. **Left unchanged:** CALL-02 B2 ("the phone has usually opened the relay after the push"), CALL-02 special
   requirements and the phase file I3.1 row ("when the phone already opened the relay after the push"). These are
   still true, because the relay is open once the push leaves, but the relay now opens at `RINGING`. The wording
   can be aligned in a later sync if wanted.

## Commits (hub `main`, pushed)

| Hash | Subject |
|------|---------|
| e24c0d2 | docs(spec): keep the push reason in push_outbox |
| b6e518e | docs(spec): write down how the phone follows calls and sends their pushes |
| 476764e | docs(spec): hold the relay for a ringing call and fit call names in pushes |

All three are signed off (`Hồ Xuân Dũng <me@hxd.vn>`), have no AI attribution, and passed the hooks. Only
explicit paths were staged. The 06 commit was made first. I re-made it locally (soft reset, before any push) so
that 0.9.1 defines `push_outbox.reason` before the call spec uses it.

## Checks (real output)

```text
$ python3 tools/docs/validate_design_docs.py
files=16 leaves=66 problems=0

$ python3 tools/docs/check_bilingual_docs.py
pairs=67 missing=0 problems=0 warnings=0

$ cd shared && tools/.venv/bin/python tools/schemas/check_schemas.py   (exit 0)
== Tổng kết
  schema hợp lệ metaschema: 45
  $ref phân giải được: 250
  enum khớp bảng spec: 41
  loc-key có trong catalog: 3
  ví dụ 00-common-specs: 6
  ngoài phạm vi S0.2 (bỏ qua): 39
  ví dụ 01–08: 215
  payload bắt tay giải từ envelope: 2
  envelope trong env_b64/hl: 39
  mẫu dương tự viết: 117
  mẫu âm bị từ chối: 232
  ví dụ catalog chuỗi giao diện: 1
  tin trong test vector: 65
  XANH: mọi kiểm tra đạt

$ cd shared && tools/.venv/bin/python tools/strings/check_strings.py --docs
  en: 393 of 393 texts found in 50 English docs
  vi: 393 of 393 texts found in 50 Vietnamese docs
== 393 strings, 0 errors, 0 warnings
OK
```

- **Shared checker:** no follow-up needed. No JSON example changed. The one table `call_spec_checks.py` compares
  that I touched is the CALL-04 `entry` object, and only the description cell of `display_name` changed; the
  checker reads only the field names and the `type` enum there. All 41 table checks pass. The shared checkers
  do not read `push_outbox`.

## New or changed UI texts for the catalog

None. This sync changes no user-facing text.

## Unresolved questions

1. **Bench follow-up (shared, T3.1).** The `incoming push` row of `shared/tools/bench/call_latency.py` starts at
   `call_changed number=known`, or at `RINGING` + 300 ms when no number came. Under logic 2 the push now leaves at
   the second copy for a withheld caller, and at `RINGING` without `READ_CALL_LOG`. Measured from `RINGING` +
   300 ms, both cases give a negative or meaningless latency. Proposal: start at the `call_changed` that settled
   the number (known, or `restricted`), or at `RINGING` without `READ_CALL_LOG`. `call_changed` may need a
   `presentation` field for that (Android bench line).
2. Device checks named by the decisions are still open: a withheld caller seen as two copies without the key
   (decision 1), the dialed number in `OFFHOOK` copies (decision 2), and `sub_id` per SIM (decision 3).
3. Deviations of A3.1 not in this sync, and not decided:
   - 7: the Material `call` symbols in `core/design`.
   - 8: SET-01 step 8, the feature list after the first pairing.
   - 9: no one-line description under the Calls switch.
   - 10: `call_changed` is written only for visible changes.
4. Optional wording alignment of CALL-02 B2, CALL-02 special requirements and phase file I3.1 with the relay hold
   from `RINGING` (interpretation 8). CONN-04 E2 could also mention the dropped `call_incoming` (it is in CALL-01
   E5 and API 4 logic 5).

Status: DONE_WITH_CONCERNS
Summary: All 11 decisions are written into 00 (0.9.1, 0.10), 03 (CONN-03 step 2, CONN-04 step 5b and Query) and 06 (CALL-01 E5, step 5, API 2–4, Query; CALL-04 entry, API 1), in both languages, in 3 signed commits pushed to hub main; validate_design_docs, check_bilingual_docs, check_schemas and check_strings --docs are all green.
Concerns/Blockers: the bench's incoming-push start point no longer matches the new push timing for withheld callers and phones without READ_CALL_LOG (unresolved question 1); the device checks of decisions 1–3 are still open.
