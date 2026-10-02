# Phase 3 extension — CALL-05 contract brief (agreed 2026-10-01)

Hand-off for the agents of `phase-03-cuoc-goi-app.md`. Evidence: `phase-03-app-calls-spike.md`. Owner decisions:
AC1 ≤ 400 ms; Answer uses the background-start exemption when HandLive's accessibility service is bound, otherwise a
"tap to answer" notification on the phone; End = `hangUpIntent`, else the single action of the same app's ongoing
notification posted after the call was answered; v1 audio always on the phone; Mac only (iOS reports `false`).

## Message `call_event` op `app_call` (S→C, `/v1/ctl`, no ack, also through the relay)

Sent by A-CALL to every session for which app calls are in effect, on every change of an app-call context (latest
wins per `call_id`); `ended` is sent once, then the context is forgotten. Every field is always present (null where
allowed).

| Field | Type | Rules |
|---|---|---|
| `call_id` | uuid-v7 | One per app call; stays the same from ringing to ongoing to ended |
| `app.package` | string(255) | Android package name of the calling app |
| `app.label` | string(64) | The app's label from PackageManager (display only) |
| `caller` | string(128) \| null | `callPerson.name` or the notification title; null when absent. Personal data: E2E only, never logged, never stored |
| `state` | enum{`ringing`, `ongoing`, `ended`} | |
| `controls.answer` | bool | ringing and the notification has an answer intent |
| `controls.decline` | bool | ringing and the notification has a decline intent |
| `controls.end` | bool | ongoing and an end action exists (rule below) |
| `answer_mode` | enum{`direct`, `tap`} | `direct` when HandLive holds a background-activity-start exemption (its accessibility service is bound); `tap` otherwise |
| `audio` | enum{`phone`} | v1 constant; reserved for `mac` later |
| `started_at` | int64 ms | Android clock, when the context was created |
| `answered_at` | int64 ms \| null | |
| `ended_at` | int64 ms \| null | only when `state = ended` |
| `end_reason` | enum{`declined`, `ended`, `missed`, `unknown`} \| null | only when `state = ended` |

## Detection on Android (A-CALL, `AppCallListenerService` — `NotificationListenerService`)

- Notifications from the default dialer, system dialer, any InCallService apps, and telecom services are dropped first
  (cellular calls stay in CALL-01…04).
- A call notification is `CallStyle` (extra `android.callType`: 1 incoming → ringing, 2 ongoing → ongoing, 3
  screening → ignored) or category `call`. Only `CallStyle` creates a context; category `call` without `CallStyle`
  can only become an in-call notification by linking (rule below).
- After a ringing context's notification is removed, the context becomes `ongoing` when the same package posts an
  ongoing notification (`FLAG_ONGOING_EVENT`, `CallStyle` type 2 or not) whose key first appeared after the ringing
  context was created and whose `postTime` ≤ removal time (seen by the listener) + `APP_CALL_LINK_WINDOW` (3 s); one
  posted before the removal is linked at the removal. Keys that existed before the context (media, downloads, FGS) and
  their updates are never linked. That notification is the context's in-call notification. Otherwise it ends: `declined` when HandLive
  sent the decline, `missed` when nothing answered it, `unknown` otherwise.
- `ended` when the in-call notification is removed.
- End action: the in-call notification's `android.hangUpIntent`, else its only action when it has exactly one; else
  `controls.end = false`. Titles are never matched as text.

## Actions

- `call_event/action` with an app `call_id`: `answer` (with `audio` absent or `phone`), `reject`, `end`. A-CALL routes
  by `call_id` (telephony contexts keep their current handling). A PendingIntent is used only when its creator package
  equals the posting package; otherwise the action is unavailable (control absent). It sends the app's PendingIntent
  with the background-activity-start option (ALLOW_ALWAYS on API 36+, ALLOWED on 34–35; API 29–33 use the
  exemption) only for `answer`; decline and end need no option. For `answer` with `answer_mode = tap`, it posts a
  HandLive notification on the phone whose content intent is the app's answer intent, and acks `ok`.
- New error `CALL_APP_ACTION_UNAVAILABLE` (group Call): the app's notification no longer offers that action (or is
  gone); the client refreshes from the latest `app_call`. `audio = mac` for an app call → `CALL_ROUTE_FAILED`
  (existing). Unknown `call_id` → `CALL_NOT_FOUND` (existing). Not in effect → `FEATURE_DISABLED` (existing rule).

## Capability, settings, permission, constants

- `features.call.app_calls` (bool): Android = `call.app_calls` ∧ notification access granted ∧ `feature.call`; Mac =
  `feature.call` ∧ `call.app_calls`; iOS/iPadOS = `false`. In effect for a session when both sides report `true`.
- Settings key `call.app_calls` (bool, default `true`, Android + Mac): "Calls from other apps".
- Android permission entry in `permissions_missing`: `NOTIFICATION_LISTENER` (special access "Notification access",
  granted by hand; SET-01 shows a primer and a deep link).
- Constants: `APP_CALL_LINK_WINDOW` = 3 s; `APP_CALL_TAP_NOTIFICATION_TTL` = 60 s (the tap-to-answer notification is
  removed when the call leaves ringing or after this).

## UI strings (catalog, en + vi; reuse first)

Reuse: `call.answer`, `call.decline`, `call.end`, `call.unknown_caller`, `call.audio_on_phone`, `call.answer_on_phone`.
New (wording per the design system; Apple title case in English buttons/titles):

| Key | en | vi | Where |
|---|---|---|---|
| `call.app_incoming_title` | `%@ Call` | `Cuộc gọi %@` | Mac panel title (app label) |
| `call.app_tap_to_answer_hint` | `Tap the notification on your phone to answer.` | `Chạm vào thông báo trên điện thoại để nghe.` | Mac panel after Answer when `answer_mode = tap` |
| `call.app_tap_to_answer_title` | `Answer %@ Call` | `Nghe cuộc gọi %@` | Android tap-to-answer notification |
| `settings.call_app_calls` | `Calls from Other Apps` | `Cuộc gọi từ ứng dụng khác` | Settings row, both platforms |
| `settings.call_app_calls_footer` | `Show calls from apps like Telegram on your Mac. Audio stays on your phone.` | `Hiện cuộc gọi từ các ứng dụng như Telegram trên Mac. Âm thanh vẫn ở trên điện thoại.` | Settings footer |
| `permission.notification_access_title` | `Allow Notification Access` | `Cho phép truy cập thông báo` | Android primer |
| `permission.notification_access_body` | `HandLive reads only call notifications from calling apps, to show them on your Mac. Other notifications are ignored and never leave your phone.` | `HandLive chỉ đọc thông báo cuộc gọi của các ứng dụng gọi điện để hiện trên Mac. Các thông báo khác bị bỏ qua và không bao giờ rời khỏi điện thoại.` | Android primer |

## Repositories and order

`feat/phase-03-app-calls` in hub (`docs/`), `shared/`, `android/`, `apple/` (worktrees inside this hub worktree, so
`../shared` and `../docs` resolve). Order: hub spec → shared schema/strings → Android ∥ Apple. Do not commit unless
the controller says so.
