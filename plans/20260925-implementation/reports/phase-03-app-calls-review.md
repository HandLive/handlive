# Phase 3 extension — CALL-05 code review and fixes (2026-10-01/02)

Scope: uncommitted `feat/phase-03-app-calls` work in hub (`docs/`), `shared/`, `android/`, `apple/`
(A3.3–A3.5, M3.4–M3.5, S3.4, D3.1). Review by a code-reviewer agent, fixes by one agent per repository, spec
gaps closed by the controller. Nothing committed.

## Findings and outcome

| # | Sev | Finding | Outcome |
|---|---|---|---|
| H1 | High | Default/system dialer `CallStyle` notifications became app calls: duplicate events, caller name bypassing `READ_CALL_LOG`/`READ_CONTACTS`, AC6 at risk (not seen in spike: S25 without SIM) | Fixed: `AppCallDialerPackages` drops default + system dialer, every `InCallService` package (`<queries>` added), `com.android.server.telecom`, `com.android.phone`; spec API 1 logic 1 + E6 |
| M1 | Med | Mac advertised `app_calls` with Calls off | Fixed: Mac = `feature.call` ∧ `call.app_calls` (`LocalDevice.swift`), spec 0.7.2, API 6, SET-02 field 38, schema description |
| M2 | Med | Background-start option lent to every PendingIntent, creator never checked | Fixed: intent used only when `creatorPackage` = posting package; option only on `answer`; spec API 4 |
| M3 | Med | In-call linking could link unrelated ongoing notifications, missed in-call posted before removal, compared the wrong times | Fixed: pre-existing keys never linked; new key posted during ringing linked at removal; window by `postTime` vs listener removal time + `APP_CALL_LINK_GRACE` 500 ms (new constant, 0.10); spec logic 3 |
| M4 | Med | Listener callbacks unguarded (process crash) | Fixed: every callback guarded, offending notification skipped, no log (module forbids logs) |
| M5 | Med | AC1/AC2 not measurable | Fixed: phone `app_call_changed`, `app_call_sent`, `app_call_intent_sent`; Mac `app_call_received`, `app_call_panel_shown`; `call_action_*` reused with the app `call_id`; bench README (en, vi). `call_latency.py` support: follow-up |
| M6 | Med | Notification access blocked as "Restricted setting" on sideloaded Android 13+ with no guidance | Fixed: `Route.RestrictedSetting(notificationAccess)` + new string `setup.restricted_settings_help_notification_access` (android only); SET-01 N1/N2/E11 |
| L1 | Low | Title read for non-`CallStyle` notifications | Fixed |
| L2 | Low | Every notification queued; Settings read per notification | Fixed: prefilter on the listener thread; access cached |
| L3 | Low | Mac commands could hit the app call from telephony UI | Fixed: routing by `call_id` on both controllers |
| L4 | Low | User-dismissed in-call notification ends the call early | Deferred (follow-up) |
| L5 | Low | Default setting read before DataStore loaded | Fixed |
| L6 | Low | beta.1 clients show generic "missing permission" | Compatibility note in hub CHANGELOG (en, vi) |
| L7 | Low | Primer shown with Calls off | Fixed |
| L8 | Low | Dead code | Removed |
| L9 | Low | Listener name / access check differ from spec | Fixed: `AppCallListenerService`, `isNotificationListenerAccessGranted(ComponentName)` |
| L10 | Low | Phase file stale (`ALLOWED`, filter) | Fixed (en, vi); T3.3 scenarios added |
| L11 | Low | Spike probe logs action titles | Accepted: debug-only tool |
| L12 | Low | App label may fall back to the package name (package visibility) | Verify in T3.3 ("Telegram" shown) |

## Verification

- Android: `./gradlew ktlintFormat check --offline --continue` → BUILD SUCCESSFUL (lint, detekt, ktlint, unit tests).
- Apple: `swift test` HLProtocol 76, HLAppCore 116, HLMacUI 68, HLiOSUI 24 pass; macOS app built, signed (team
  3S93UPADXV) and installed as `app.handlive.mac.localtest`.
- Hub: `validate_design_docs.py` problems=0; `check_bilingual_docs.py` problems=0.
- Shared: `check_schemas.py` green; `check_strings.py` 434 strings, 0 errors.

## Open

- swiftlint `--strict` fails on two files outside this change (`HLMacUI/AppModel.swift` length,
  `HLTransport/PairingSearch.swift`) — CI lint will be red until fixed.
- Apple bench tests read the process's unified log; not yet proven on the CI runner.
- An unrelated ongoing notification of the same app whose key first appears during ringing is still linked (by design).
- H1 needs a phone with a SIM; T3.3 not run yet (S25 disconnected).

Status: DONE_WITH_CONCERNS
Summary: All High/Medium review findings fixed with tests across android, apple, shared and hub docs; checks green.
Concerns/Blockers: T3.3 on real devices pending (S25 reconnect; SIM phone for H1); swiftlint debt outside scope.
