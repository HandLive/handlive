# Team follow-ups: app-call label, swiped in-call notification, app-call bench, Apple call-test flakiness (2026-10-05)

Owner request (15:19): "build a team to carry out the next plans". Every gate (G1, G2, G4, G5, G6) and the iPhone
relay + APNs (owner: last) wait on the owner's hardware or decisions, so a forum team took the four open items that need
neither. Team: lead, Phong (Android), Vy (Apple), Tuấn (tooling), reviewers Huy / Linh (BA), Trang / Nam (Tester),
Khoa / Quân (Pentester). Owner decisions (15:58): push branches and open PRs, the owner merges; Phase 7 stays proposed.

## Outcome

| Item | What changed | PR | Review |
|------|--------------|----|--------|
| CALL-05 app label | `feature/call` declares a launcher-intent `<queries>` so `PackageManager` can read the calling app's label where Android hides it; the Mac shows "Telegram Call", not `org.telegram.messenger Call`. Correction (2026-10-07, e2e with a fake calling app): on an Android 15 emulator the notification listener already sees an app once it posts, even without the query, so the package-name label was inferred in review and never seen on the S25; the query stays as a safeguard (Android 11–14 and OEM builds not measured). No `QUERY_ALL_PACKAGES`, no hidden notification extras. Spec: one line in CALL-05 API 1 (`app.label`). | android #8 (first commit), hub #15 | BA, Tester, Pentester approve, 0 findings |
| CALL-05 swiped in-call notification | Android 14+ lets the user swipe an ongoing non-`CallStyle` notification (Telegram's). Before: any removal → `ended`, the Mac panel closed mid-call. Now only `REASON_APP_CANCEL(_ALL)` → `ended`; any other reason while the audio mode is `MODE_IN_COMMUNICATION` → the call stays `ongoing`, `controls.end = false`, and ends `unknown` when the mode leaves (`AudioManager.addOnModeChangedListener`, API 31+); below API 31 or outside that mode → `unknown` at once. Only a later in-call notification of the same app (`CallStyle` type 2 / category `call`) re-attaches the call and brings End back; a generic ongoing one (an upload with Cancel) leaves the call detached and is never fired. Spec: step 7, API 1 logic 4, API 3 logic 4, new E11, flowchart (en + vi). | android #8, hub #15 | all approve; 3 low fixed on the same PR (see below) |
| Call bench | `call_latency.py` reads app calls: delivery (200 ms LAN / 1 s relay), panel shown (≤ 400 ms), decline / end and direct answer (phone-only, ≤ 500 ms / ≤ 1 s), tap-to-answer counted, `… back` rows (tap → Mac sees the result). Fixed: `bench_log.py` dropped every `app_call_*` event as unknown; app-call taps produced `phone=?` cellular rows. README en + vi match the apps' logs. | shared #6 | all approve twice; 5 low fixed |
| Apple call-test flakiness | `CallController`, `AppCallController`, `CallActionSender` time their waits on an injected `any Clock<Duration>` (default `ContinuousClock()`); test-only `ManualClock` whose sleepers are awaited by event. | apple #5 | BA, Tester, Pentester approve; 3 low noted as follow-ups; Tester reran the whole suite in parallel ×30: the three call tests 90/90 |

### Measurements (Apple)

Local, Xcode 27.0, whole `HLAppCoreTests`, `-parallel-testing-enabled YES -test-iterations 200`:

| Test | `main` `3f8c4cd` | branch |
|------|------------------|--------|
| `CallCommandTests/resendAfterReconnect` | 68/200 fail (34 %) | 0/200 |
| `AppCallCommandTests/resendAfterReconnect` | 68/200 (34 %) | 0/200 |
| `CallNotificationDeclineTests/sentWhenConnected` | 97/200 (48.5 %) | 0/200 |

Alone (×200 each) the three never failed on `main`: they fail only when other suites compete for the MainActor. A
first fix that awaited sleepers with a bounded `Task.yield()` loop still failed (80/80/35): a bounded yield loop is a
real-time timeout in disguise. CI keeps `-parallel-testing-enabled NO`: CI timing showed the parallel switch saves
about 0 s of wall clock (the features lane, with the Mac app, is the critical path), and clipboard tests also use real
time (`ClipboardIOSTests/sendPastedWithHtml` 200/200 in parallel, `replayWindow` ~18 %, `ackErrors` ~16 %).

## Decisions taken in the thread

- A detached call ends with `end_reason = unknown`, an existing value (CALL-05 API 1 logic 4 uses it when the signal is
  lost), so the wire and the shared schema do not change. The schema forces `answered_at = null` for `unknown`, as E10
  already does; the spec line saying so stays.
- The removal rule is inverted for safety: only the app's own cancel means `ended`; listing "user" reasons would miss
  some (`CHANNEL_BANNED`, `SNOOZED`, …).
- The Apple goal moved from "parallel CI again" to "no flaky call tests", scoped to three types.

## Review findings fixed before merge

- Android (android `7c436d5`, `e5797ae`, hub `ebc7168`): an ongoing non-call notification of the same app (an upload
  with Cancel) re-attached the call and its only action became End; a default `byApp = true` kept the old behaviour one forgotten argument away; no test held a
  detached call next to a normal one when the mode changes.
- Bench: delivery measured from a stale `app_call_changed` when Android resent without a change; a resent action was
  measured twice; a non-numeric `os` crashed the run; README now says the decline / end target is phone-only.

## Follow-ups (not done)

- Apple clipboard tests on the same virtual clock, then retry parallel CI.
- Android: a distinct `reason` for an app call resent after a setting or exemption change, so the bench skips it.
- Bench self-test: two Macs; a resent tap-to-answer.
- Apple tests (low, from review): `ManualClock.waitForSleepers` is unbounded and ignores cancellation, so a controller
  that stops sleeping hangs the test until the CI step's 20 min timeout instead of failing by name; the test helpers'
  `clock:` (ms `now`) and `timer:` (the injected `Clock`) names are swapped against the product's.
- Product: should an app call that ended `unknown` keep `answered_at` (duration on the Mac)? Needs the shared schema first.
- shared CI: one run of the e2e harness with the fake phone failed (`websockets InvalidMessage`) and passed on rerun.
- Owner on the S25: "Telegram Call" on the Mac; swipe Telegram's in-call notification → the panel stays, End hidden,
  hanging up closes it; then T3.3 numbers with `call_latency.py`.

## Unresolved questions

- `answered_at` for `unknown` app calls (above): product call for the owner.

Status: DONE_WITH_CONCERNS
Summary: Four PRs open for the owner (android #8 + hub #15, shared #6, apple #5) plus this docs PR; all reviewed by
BA, Tester and Pentester.
Concerns/Blockers: behaviour on the S25 is unverified until the owner's device check.
