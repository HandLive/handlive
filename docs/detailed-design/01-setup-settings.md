English | [Tiếng Việt](01-setup-settings.vi.md)

# 1. Function group: Setup and settings

> Shared references: [`00-common-specs.md`](00-common-specs.md) — components (0.1), the `device_id`
> identifier (0.2), LAN and relay channels (0.4), keys and security principles (0.6.1, 0.6.5), relay
> authentication (0.6.4), capability and `permissions_missing` (0.7.2), relay control messages and
> REST (0.7.3, 0.7.4), error codes (0.8), schema (0.9), settings keys (0.9.5), constants (0.10).
> Decisions applied: README §5 C7, C10, C11, C12, C13, C15. New keys of this group (proposed
> addition to 0.9.5): `setup.started_at`, `setup.completed_at` (all platforms), `perm.requested`
> (Android).

## 1.1 SET-01 — Initial setup and permissions on Android

### 1.1.1 General information

| Item | Content |
|-----|----------|
| Name | SET-01 — Initial setup and permissions on Android |
| Description | Two parts.<br>**Part A — first run:** a welcome screen with a short privacy explanation; create the identity keys, `device_id` and TLS certificate (0.6.1); request `POST_NOTIFICATIONS` (Android 13+); start `HandLiveService` (A-SVC) as a foreground service of type `connectedDevice` with a low-importance ongoing notification; request the battery optimization exemption (`ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS`) and show manufacturer-specific instructions for allowing autostart (Xiaomi, OPPO/realme, Samsung "Never sleeping apps"); then move on to PAIR-01.<br>**Part B — just-in-time permissions per feature:** a feature's permissions are requested only when the user turns on or uses that feature: QR scanning needs `CAMERA`; sending the clipboard automatically needs the disclosure, consent and turning on the Accessibility service (C15, CLIP-01); SMS needs `READ_SMS`, `SEND_SMS`, `READ_CONTACTS`, `READ_PHONE_STATE` (`RECEIVE_SMS` is not requested); calls need `READ_PHONE_STATE`, `READ_CALL_LOG`, `ANSWER_PHONE_CALLS`, `READ_CONTACTS` (C12, no `InCallService`); call audio needs `BLUETOOTH_CONNECT`, with Shizuku optional for the Opus/WS path (AUDIO-01, C13); camera streaming needs `CAMERA`, `RECORD_AUDIO`.<br>A denied permission leaves that feature inactive (or partially active) and is listed in `permissions_missing`; other features are not affected. |
| Actors | Primary: User (the phone's owner). System: A-UI, A-SVC, A-CLIP (`ClipboardAccessibilityService`), OS (Android's permission controller, `PowerManager`, system Settings and the manufacturer's own settings), R-API (device registration). |
| Preconditions | **Part A:** HandLive has just been installed (Google Play, F-Droid or APK) on Android 10+ (API 29+); `setup.completed_at` is not set.<br>**Part B:** part A is done; the user taps "Scan QR Code" (PAIR-01), turns on a feature (SET-02), taps "Grant Permission" on a feature card, or taps a permission suggestion notification. |
| Postconditions | **Part A:** the identity keys, `device_id` and TLS certificate exist; A-SVC runs in the foreground with its ongoing notification, listens on port 47800 (0.4.1) and advertises over mDNS; the battery optimization exemption has been asked for; `setup.completed_at` is written; the device is registered with the relay if `relay.enabled = true` and a network is available (or a background retry is pending); the UI moves on to PAIR-01.<br>**Part B:** each of the feature's permissions is granted or denied; `permissions_missing` and the capability sub-flags (`can_send`, `sims`, `caller_id`, `can_answer`, `can_end`, `auto_send`) match reality; every connected client has received `capability/update` if anything changed. |
| Exceptions | E1 — `POST_NOTIFICATIONS` denied: A-SVC still runs (its service notification only appears in Android's Task Manager), but connection status, permission suggestions and camera confirmation requests (CAM-02) are not shown; the app shows the warning banner "Notifications are off, so connection status and requests from your Mac don't appear." with a button that opens the notification settings.<br>E2 — The foreground service cannot start (`ForegroundServiceStartNotAllowedException` when the app is not in the foreground and not exempt from battery optimization, or `SecurityException` because a type declaration is missing): retry when A-UI is in the foreground; still failing → show "Couldn't Start the Connection Service" with a "Try Again" button.<br>E3 — Battery optimization exemption denied or manufacturer instructions skipped: HandLive still works, but the connection may drop while the phone sleeps (CONN-02 E6); the warning stays in Settings › Permissions & Background.<br>E4 — A feature's permission is denied: the feature is inactive or partially active (for example `can_send = false`); the permission goes into `permissions_missing`.<br>E5 — Permission permanently denied (the system no longer shows the dialog): show an "Open Settings" button that goes to the App info page.<br>E6 — Accessibility disclosure declined: `clip.auto_send = false`; manual sending (a button in the notification, a Quick Settings tile, the Share menu) still works (CLIP-01 E1).<br>E7 — An install from outside Google Play on Android 13+ is blocked from turning on the Accessibility service ("Restricted setting"): guide the user to allow it in App info, then come back.<br>E8 — The user comes back from the Accessibility settings without the service turned on: keep the "Auto-send isn't on yet" status and allow another try.<br>E9 — Key generation fails (Keystore error): retry with a TEE-backed key when StrongBox is unavailable; still failing → show an error and do not continue to PAIR-01.<br>E10 — No network or relay error during device registration: skip, retry in the background (CONN-03), do not block setup. |
| Special requirements | **Google Play compliance:** submit the Permissions Declaration Form for `READ_SMS`, `SEND_SMS`, `READ_CALL_LOG` under the "Cross-device synchronization or transfer of SMS or calls" exception; do not declare `RECEIVE_SMS` (new messages are detected with a `ContentObserver`); declare use of the Accessibility API (`isAccessibilityTool = false`) with a prominent disclosure and in-app consent — the project owner has accepted the rejection risk (C15); declare the `connectedDevice` foreground service type in Play Console; use `REQUEST_IGNORE_BATTERY_OPTIMIZATIONS` on the grounds that a companion app must stay connected to its paired devices.<br>**Privacy:** no feature permissions are requested in part A; every system dialog is preceded by an explanation; each request covers the permissions of one feature only.<br>**Usability:** part A ≤ 5 screens, completed in ≤ 60 s (not counting actions in the manufacturer's settings); readable with TalkBack; every step after the welcome screen can be skipped; no ADB, USB or Shizuku needed.<br>**Compatibility:** minSdk 29, targetSdk 35 — `POST_NOTIFICATIONS` exists only from API 33; `BLUETOOTH_CONNECT` from API 31 (API 29–30 use `BLUETOOTH`, granted at install); `FOREGROUND_SERVICE_CONNECTED_DEVICE` is required from API 34.<br>**Feature independence:** a missing permission for one feature does not block the others (CONN-01 API 7). |

### 1.1.2 Screens

N/A — no approved wireframe yet.

### 1.1.3 Component details

| # | Field | Data type | Input/Output | Initial value | Description |
|---|--------|--------------|--------------|------------------|-------|
| 1 | Introduction and privacy | string | Output | Fixed text | "HandLive connects this phone to your Mac, iPhone, and iPad. Data is end-to-end encrypted and travels only between devices you've paired; the server can't read it. No account needed." With the link "HandLive and Your Privacy", which opens the page in the display language: https://github.com/HandLive/handlive/blob/main/docs/privacy.md (English), https://github.com/HandLive/handlive/blob/main/docs/privacy.vi.md (Vietnamese) |
| 2 | "Get Started" button | action | Input | — | Goes to step 3 |
| 3 | Notification permission | enum{granted\| denied\| not_required} | Input/Output | `not_required` (API 29–32) or from `checkSelfPermission` | Android 13+ asks at step 3; `denied` shows a warning banner and an "Open Notification Settings" button (E1) |
| 4 | Connection service status | enum{running\| stopped\| failed} | Output | `stopped` | `running` after step 5; `failed` per E2 |
| 5 | A-SVC ongoing notification | string | Output | "Waiting for a connection" | Channel `hl_service` ("Connection service", description "Connection status with your Mac, iPhone, and iPad, and the Send Clipboard button."), `IMPORTANCE_LOW`; text updated per CONN-01 field 6; has a "Send Clipboard" button (CLIP-01 field 4) |
| 6 | Unrestricted background running | enum{exempt\| not_exempt} | Input/Output | From `PowerManager.isIgnoringBatteryOptimizations` | The "Continue" button opens the system dialog (API 4); `not_exempt` keeps a warning in Settings › Permissions & Background (E3) |
| 7 | Pause app activity if unused | enum{enabled\| disabled\| not_available} | Input/Output | From `PackageManagerCompat.getUnusedAppRestrictionsStatus` | Android 11+: suggest turning it off so the system does not revoke permissions automatically when the user hasn't opened HandLive on the phone for a long time (API 4) |
| 8 | Manufacturer autostart instructions | string | Output | From `Build.MANUFACTURER` | Specific steps for Xiaomi/Redmi/POCO, OPPO/realme/OnePlus, Samsung (API 5); hidden for other manufacturers |
| 9 | "Open Manufacturer Settings", "Done", "Skip" buttons | action | Input | — | "Open Manufacturer Settings" opens the manufacturer's screen (API 5); "Done" and "Skip" go to step 7 |
| 10 | Feature list | array\<object> | Output | From the `feature.*` keys (0.9.5) and current permissions | Each card: feature name, status `ready` \| `needs_permission` \| `permanently_denied` \| `off` \| `unsupported`, missing permissions. Shown after the first PAIR-01 and in Settings › Permissions & Background<br>Card names are the SET-02 switch labels: "Auto-Send on Copy", "SMS Messages", "Calls", "Take Calls on Mac", "Use Phone as Webcam". Status texts: `ready` "On", `needs_permission` "Needs permission" (with field 11), `permanently_denied` "Permission denied" (with field 16), `off` "Off", `unsupported` "Not supported on this phone". The "Auto-Send on Copy" card takes its status from field 15: `needs_accessibility` shows "Auto-send isn't on yet" (E8) |
| 11 | "Grant Permission" button on a feature card | action | Input | Shown when the card is `needs_permission` | Runs part B for that feature only |
| 12 | Explanation before the permission request | string | Output | Per feature (API 2) | SMS example: "To view and reply to SMS messages on your Mac or iPhone, HandLive needs to read and send SMS, read your contacts to show sender names, and read the phone state to choose a SIM."<br>Titles: SMS "Use SMS on Your Mac and iPhone", notifications "Get Notified About Connections and Requests", background "Run in the Background", manufacturer autostart "Keep HandLive Running", camera "Scan the Pairing Code" (body "HandLive uses the camera to scan the QR code on your Mac, iPhone, or iPad.") |
| 13 | Accessibility disclosure | string | Output | Text of CLIP-01 field 2 | Shown full screen, with the choices "Send Manually" / "Agree" per CLIP-01 field 3 |
| 14 | "Restricted setting" instructions | string | Output | Hidden | Shown on Android 13+ when the install source is not Google Play (API 6, E7) |
| 15 | Automatic clipboard sending status | enum{on\| off\| needs_accessibility} | Output | `needs_accessibility` | `on` when `clip.auto_send = true`, `clip.a11y_consent_at` is set and the Accessibility service is running; `off` when `clip.auto_send = false` |
| 16 | "Open Settings" button | action | Input | Shown when a permission is permanently denied | Opens HandLive's App info page (E5) |
| 17 | Permission suggestion notification | string | Output | — | Posted by A-SVC when it returns `PERMISSION_MISSING` to a client: "Lan's MacBook needs SMS permission on this phone — tap to allow" (the same text whichever SMS permission is missing); at most once per feature per 24 h; channel `permission` ("Permissions", description "Suggestions to grant a permission when a Mac or iPhone needs a feature of this phone.", `IMPORTANCE_LOW`) |
| 18 | Error message | string | Output | Empty | Text per E1–E10 |

### 1.1.4 Business flow

```mermaid
flowchart TB
  subgraph ND["User"]
    U1["(1) Open HandLive for the first time, tap Get Started"]
    U4["(4) Allow or deny notifications"]
    U6["(6) Allow background running, follow the manufacturer instructions"]
    U8["(8) Scan QR, turn on a feature or tap Grant Permission"]
    U11["(11) Allow or deny in the system dialog"]
    U13["(13) Agree to the disclosure, turn on HandLive in Accessibility"]
  end
  subgraph HT["System"]
    S2["(2) Create identity keys, device_id, TLS certificate"]
    S3["(3) Explain, request POST_NOTIFICATIONS on Android 13+"]
    S5["(5) Start HandLiveService connectedDevice, request battery optimization exemption"]
    S7["(7) Save setup.completed_at, register with relay in background, go to PAIR-01"]
    D9{"(9) What does the feature need?"}
    S10["(10) Filter missing permissions, explain, open system dialog"]
    S12["(12) Show disclosure, restricted setting instructions, open Accessibility"]
    S14["(14) Recompute permissions_missing and auto_send, send capability/update"]
    X1(["End: show error, allow retry"])
  end
  U1 --> S2
  S2 -- "Keystore error (E9)" --> X1
  S2 --> S3
  S3 -- "Android 13+" --> U4
  S3 -- "Android 10 to 12" --> S5
  U4 -- "Allow or deny (E1)" --> S5
  S5 -- "Service error (E2)" --> X1
  S5 --> U6
  U6 -- "Done or skipped (E3)" --> S7
  S7 --> U8 --> D9
  D9 -- "Runtime permissions" --> S10 --> U11
  S10 -- "Permanently denied (E5)" --> S14
  U11 -- "Allow or deny (E4)" --> S14
  D9 -- "Auto-send on copy" --> S12 --> U13
  U13 -- "On, not on, or declined (E6, E7, E8)" --> S14
```

| Step | Actor | Component | Description | Exceptions / Notes |
|------|----------|-----------|-------|--------------------|
| 1 | User | A-UI | Opens HandLive. A-UI reads `setup.completed_at`: empty → welcome screen (field 1); set → main screen (part A is skipped). The user reads the introduction and taps "Get Started" (field 2). | Part A interrupted → the next launch starts over; each step skips itself if already satisfied (permission granted, service running, battery optimization exemption granted). |
| 2 | System | A-UI | Runs in the background as soon as the welcome screen appears: no keyset yet → create `ik_sig` (Ed25519) and `ik_dh` (X25519) with Tink, wrapped by an AES-256 master key in Android Keystore (StrongBox if available); compute `device_id` = UUIDv8(SHA-256(`ik_sig_pub`)) (0.2); create an ECDSA P-256 key and a self-signed TLS certificate valid for 20 years (API 1).<br>Write `setup.started_at`. | Keyset already exists → load it, do not recreate it. StrongBox error → TEE; still failing → E9. |
| 3 | System | A-UI | Android 13+ without `POST_NOTIFICATIONS`: show the explanation "Notifications show the connection status and let you confirm requests from your Mac, such as turning on the camera", then request the permission (API 2). Android 10–12: notifications are already allowed; go to step 5. |  |
| 4 | User | OS | Chooses "Allow" or "Don't allow" in the system dialog. | Denied → E1, still goes to step 5. |
| 5 | System | A-UI → A-SVC, OS | (a) Start A-SVC: `startForegroundService`, then within 5 s call `startForeground` with type `connectedDevice` and a notification on channel `hl_service` (API 3); A-SVC opens WSS on ports 47800–47809 and advertises over mDNS (CONN-01 API 1). (b) Not yet exempt from battery optimization → explain "So your Mac and iPhone can always reach this phone, HandLive needs to run in the background without being stopped by the system", then open the `ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS` dialog (API 4). (c) Android 11+ and field 7 = `enabled` → suggest turning off "Pause app activity if unused" (API 4). (d) Manufacturer listed in the configuration table → show the autostart instructions (field 8, API 5). | Cannot start → E2. |
| 6 | User | OS, A-UI | Allows background running in the system dialog; follows the manufacturer instructions and taps "Done", or taps "Skip". | Denied or skipped → E3, still goes to step 7. |
| 7 | System | A-UI, A-SVC → R-API | Write `setup.completed_at`. If `relay.enabled = true` and the internet is available: run `POST /v1/devices` in the background (CONN-03 API 1), then register the FCM push token (CONN-04 step 2). Go to PAIR-01 (the "Pair a Device" screen with "Scan QR Code" and "Enter PIN"). | Relay error → E10. |
| 8 | User | A-UI | Starts part B: taps "Scan QR Code" (PAIR-01 step 3), turns on a feature in SET-02, taps "Grant Permission" on a feature card (field 11) or taps a suggestion notification (field 17).<br>After the first PAIR-01, A-UI opens the feature list (field 10) so the user can grant permissions to the features that are on by default: clipboard (automatic sending), SMS, calls. | Device without `FEATURE_TELEPHONY` → the SMS and call cards are `unsupported` and the capability reports `enabled = false`; no camera (`FEATURE_CAMERA_ANY`) → the same for the camera. |
| 9 | System | A-UI | Looks up the per-feature permission table (API 2): QR scanning, SMS, calls, call audio (only `BLUETOOTH_CONNECT`; Shizuku belongs to AUDIO-01 steps 10–11), camera → step 10; automatic clipboard sending → step 12. |  |
| 10 | System | A-UI | Filters out the permissions not yet granted (`checkSelfPermission`).<br>A permission in `perm.requested`, not granted and with `shouldShowRequestPermissionRationale = false` → permanently denied: show field 16 instead of the dialog.<br>Otherwise: show the explanation (field 12), call `RequestMultiplePermissions` for the feature's missing permissions and add them to `perm.requested`. | E5 → step 14 when the user comes back from Settings. |
| 11 | User | OS | Allows or denies each permission group; the system groups the dialogs by permission group (SMS, Contacts, Phone, Call logs, Camera, Microphone, Nearby devices). | Denied → E4. |
| 12 | System | A-UI | Runs CLIP-01 A2: show the disclosure (field 13); "Agree" → write `clip.a11y_consent_at`. Before opening `ACTION_ACCESSIBILITY_SETTINGS`: Android 13+ and the install source is not Google Play → show field 14 (API 6). | Declined → E6, go to step 14. |
| 13 | User | OS | In Settings › Accessibility, selects HandLive, turns the service on, confirms the system's full-control permission dialog, then returns to HandLive. | The system reports "Restricted setting" → E7. Returns without turning it on → E8. |
| 14 | System | A-UI, A-SVC, A-CLIP | Recomputes `permissions_missing` and the sub-flags from the API 2 table; updates fields 10 and 15.<br>Something changed and a client is connected → send `capability/update` (SET-02 API 1); both sides recompute the active features (CONN-01 API 7).<br>For QR scanning: `CAMERA` granted → open the scanner (PAIR-01 step 3); denied → PAIR-01 E9 (use the PIN). | A-SVC also recomputes at startup, on A-UI `onResume` and when the Accessibility service connects or disconnects (CLIP-01 A3). |

### 1.1.5 API/service specification

**List of calls**

| # | API/service | Channel | Direction | Used in step |
|---|-------------|------|-------|-------------|
| 1 | Create the identity keys and TLS certificate (Tink, Android Keystore) | Local | — | 2 |
| 2 | Runtime permission requests: `ActivityResultContracts.RequestPermission` / `RequestMultiplePermissions` | Local | — | 3, 4, 10, 11, 14 |
| 3 | `ServiceCompat.startForeground(…, FOREGROUND_SERVICE_TYPE_CONNECTED_DEVICE)` | Local | — | 5 |
| 4 | `Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS`, `IntentCompat.createManageUnusedAppRestrictionsIntent` | Local | — | 5, 6 |
| 5 | Manufacturer autostart screen, fallback `Settings.ACTION_APPLICATION_DETAILS_SETTINGS` | Local | — | 5, 6, 10 |
| 6 | `Settings.ACTION_ACCESSIBILITY_SETTINGS`, `AccessibilityManager.getEnabledAccessibilityServiceList`, `PackageManager.getInstallSourceInfo` | Local | — | 12, 13, 14 |
| 7 | `WS capability/update` | `/v1/ctl` (LAN, USB or relay) | S→C | 14 |
| 8 | `POST /v1/devices` | Relay REST | A-SVC → R-API | 7 |

#### API 1 — Create the identity keys and TLS certificate

- **URL:** N/A
- **Method:** `KeyGenerator.getInstance("AES", "AndroidKeyStore")` with
  `KeyGenParameterSpec.Builder("hl_master", PURPOSE_ENCRYPT or PURPOSE_DECRYPT).setIsStrongBoxBacked(true)`;
  `AndroidKeysetManager.Builder().withSharedPref(context, "hl_secret_keyset", "handlive_keyset").withMasterKeyUri("android-keystore://hl_master")`;
  `Ed25519Sign.KeyPair.newKeyPair()`; `X25519.generatePrivateKey()`;
  `KeyPairGenerator.getInstance("EC")` with `ECGenParameterSpec("secp256r1")`.
- **Request:**

| Item | Algorithm / attributes | Stored in |
|-----------|------------------------|---------|
| Master key | AES-256-GCM, alias `hl_master`; StrongBox when `FEATURE_STRONGBOX_KEYSTORE` is present | Android Keystore |
| AEAD keyset | Tink `AES256_GCM`, wrapped by `hl_master` | SharedPreferences `handlive_keyset` |
| `ik_sig` | Ed25519 | Private key encrypted with the AEAD keyset |
| `ik_dh` | X25519 | Same as `ik_sig` |
| TLS key | ECDSA P-256, self-signed X.509 certificate `CN=HandLive`, valid for 20 years | PKCS#12 in internal storage; a 32-byte random password encrypted with the AEAD keyset (0.6.1) |

- **Response:** `device_id` (uuid); the SHA-256 of the TLS certificate in DER form (used as `tls_sha256`
  in PAIR-01 API 3).
- **Example:** `ik_sig_pub` = `Zm9vYmFyYmF6cXV4cXV1eHh5enp6MTIzNDU2Nzg5MDE` → `device_id` =
  `8c7d6e5f-4a3b-8c2d-9e1f-0a1b2c3d4e5f` (the phone in the PAIR-01 example).
- **Business logic:**
  1. Idempotent: keyset and PKCS#12 already exist → load them, do not recreate them. Changing
     `ik_sig` means changing `device_id` and breaks every pair.
  2. `StrongBoxUnavailableException` → recreate `hl_master` without StrongBox (TEE); any other
     error → E9.
  3. Never log keys, the PKCS#12 password or the full `device_id`.
  4. Uninstalling the app deletes both the Keystore key and the keyset → a reinstall gets a new
     `device_id` (0.2).

#### API 2 — Runtime permission requests per feature

- **URL:** N/A
- **Method:** `registerForActivityResult(ActivityResultContracts.RequestMultiplePermissions())`, then
  `launch(arrayOf(...))`; `POST_NOTIFICATIONS` uses `RequestPermission`. Check first with
  `ContextCompat.checkSelfPermission` and `shouldShowRequestPermissionRationale`.
- **Request — per-feature permission table** (the source for computing `permissions_missing`,
  consistent with CONN-01 API 7):

| Feature | Permission (`android.permission.*`) | API | If missing | Google Play |
|-----------|-------------------------------|-----|-----------|-------------|
| General | `POST_NOTIFICATIONS` | 33+ | No feature becomes inactive; no notifications (E1) | — |
| Pairing (QR scan) | `CAMERA` | 29+ | PAIR-01 E9, use the PIN | — |
| `sms` | `READ_SMS` | 29+ | `sms` inactive | Declaration Form |
| `sms` | `SEND_SMS` | 29+ | `can_send = false` | Declaration Form |
| `sms`, `call` | `READ_CONTACTS` | 29+ | No display names (SMS-01 E3, CALL-01 E2) | — |
| `sms`, `call` | `READ_PHONE_STATE` | 29+ | `sms`: `sims = []`; `call`: inactive | — |
| `call` | `READ_CALL_LOG` | 29+ | `caller_id = false`, no CALL-04 | Declaration Form |
| `call` | `ANSWER_PHONE_CALLS` | 29+ | `can_answer = can_end = false` | — |
| `call_audio` | `BLUETOOTH_CONNECT` | 31+ (API 29–30: `BLUETOOTH` granted at install) | `call_audio` inactive | — |
| `call_audio` (Opus/WS) | Shizuku permission (AUDIO-01 API 6) | 30+ | `opus_fallback.available = false` | — |
| `camera` | `CAMERA`, `RECORD_AUDIO` | 29+ | `camera` inactive | — |
| `clipboard` (automatic sending) | Accessibility service (API 6) | 29+ | `auto_send = false`, manual sending only | Accessibility declaration |

- **Response:** `Map<String, Boolean>` — the result for each permission.
- **Example:** SMS: `launch(arrayOf(READ_SMS, SEND_SMS, READ_CONTACTS, READ_PHONE_STATE))` →
  `{READ_SMS=true, SEND_SMS=true, READ_CONTACTS=false, READ_PHONE_STATE=true}` →
  `permissions_missing = ["READ_CONTACTS"]`, `features.sms.can_send = true`, `sims` has data.
- **Business logic:**
  1. `permissions_missing` holds the short names (without the `android.permission.` prefix) of the
     missing permissions that belong to enabled features (`feature.<name>` = `true`), plus
     `POST_NOTIFICATIONS` when it is missing on Android 13+; disabled features contribute no
     permissions. An `ack` with the error `PERMISSION_MISSING` carries the full name in
     `details.permission` (as in SMS-01 E2).
  2. Android does not say whether a permission has been permanently denied; infer it from
     `perm.requested`: asked before, not granted and `shouldShowRequestPermissionRationale = false`
     → permanent (Android 11+ blocks the dialog on its own after two denials). In that case do not
     call `launch` (the dialog would not appear) but open `ACTION_APPLICATION_DETAILS_SETTINGS`
     (E5).
  3. Each `launch` contains the permissions of one feature only.
  4. The user revokes a permission in Settings → the system kills the process; A-SVC restarts
     (`START_STICKY`) and recomputes at startup. The user grants a permission in Settings →
     recompute on A-UI `onResume` or when a new session sends `capability/hello`. Every client
     request is still checked locally and gets `PERMISSION_MISSING` if a permission is missing; A-SVC
     then posts the suggestion notification (field 17).
  5. `CAMERA` and `RECORD_AUDIO` are "while in use" permissions; opening the camera while the app is
     in the background and the `camera`/`microphone` foreground service types belong to CAM-02.

#### API 3 — Start the `connectedDevice` foreground service

- **URL:** N/A
- **Method:**
  `ContextCompat.startForegroundService(context, Intent(context, HandLiveService::class.java))`;
  in `onStartCommand`:
  `ServiceCompat.startForeground(this, NOTIF_SERVICE_ID, notification, ServiceInfo.FOREGROUND_SERVICE_TYPE_CONNECTED_DEVICE)`,
  return `START_STICKY`.
- **Request — declarations:**

| Item | Value |
|-----|---------|
| `<service>` | `.HandLiveService`, `android:foregroundServiceType="connectedDevice"`, `android:exported="false"` |
| Install-time permissions | `FOREGROUND_SERVICE`, `FOREGROUND_SERVICE_CONNECTED_DEVICE` (API 34+), `CHANGE_NETWORK_STATE` (a prerequisite of the `connectedDevice` type), `INTERNET`, `ACCESS_NETWORK_STATE`, `RECEIVE_BOOT_COMPLETED`, `REQUEST_IGNORE_BATTERY_OPTIMIZATIONS` |
| Notification channel | id `hl_service`, name "Connection service", `IMPORTANCE_LOW` (no sound, no vibration), `setShowBadge(false)` |
| Notification | `CATEGORY_SERVICE`, `setOngoing(true)`, text per field 5, "Send Clipboard" button (CLIP-01 field 4) |
| Restart | A `BroadcastReceiver` for `BOOT_COMPLETED` and `MY_PACKAGE_REPLACED` calls `startForegroundService` again |

- **Response:** the service is in the foreground; `ForegroundServiceStartNotAllowedException` (API
  31+) or `SecurityException` (a permission required by the type is missing) → E2.
- **Example:** the notification sets no title of its own (Android shows the app name), text "Waiting
  for a connection", button "Send Clipboard"; after CONN-01: "Connected to Lan's MacBook".
- **Business logic:**
  1. `startForeground` must be called within 5 s of `startForegroundService`; otherwise the system
     reports an error and stops the app.
  2. Starting from the background (the system stopped the service and restarts it, a network
     change) is only allowed under an Android 12+ exemption: exempt from battery optimization (API
     4), `BOOT_COMPLETED`/`MY_PACKAGE_REPLACED`, or a high-priority FCM message (CONN-04). Android 15
     forbids starting the `dataSync`, `camera`, `microphone`, `mediaPlayback`, `phoneCall`,
     `mediaProjection` types from `BOOT_COMPLETED` but does not forbid `connectedDevice`;
     `connectedDevice` also has no 6-hour limit like `dataSync`.
  3. From Android 14 the user can swipe away a foreground service notification; the service keeps
     running and the notification comes back when the connection status changes.
  4. Without `POST_NOTIFICATIONS` (E1): the service keeps running; the system only lists it in the
     Task Manager.

#### API 4 — Battery optimization exemption and pausing when unused

- **URL:** N/A
- **Method:** `PowerManager.isIgnoringBatteryOptimizations(packageName)`;
  `startActivity(Intent(Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS, Uri.parse("package:" + packageName)))`;
  Android 11+: `PackageManagerCompat.getUnusedAppRestrictionsStatus(context)` and
  `startActivity(IntentCompat.createManageUnusedAppRestrictionsIntent(context, packageName))`.
- **Request:** URI `package:<package name>`; no other parameters.
- **Response:** the system dialog returns no reliable result; A-UI reads
  `isIgnoringBatteryOptimizations` and `getUnusedAppRestrictionsStatus` again in `onResume`.
- **Example:** `isIgnoringBatteryOptimizations("app.handlive.android")` = `false` → open the dialog →
  the user chooses "Allow" → `onResume` reads `true` → field 6 = `exempt`.
- **Business logic:**
  1. Reason declared to Google Play: the core function is a companion app that must stay connected
     to its paired devices; A-SVC is a WSS server that must accept connections even while the phone
     is in Doze — apps on the exemption list may use the network during Doze and App Standby.
  2. The device does not support the intent (`ActivityNotFoundException`) → open
     `Settings.ACTION_IGNORE_BATTERY_OPTIMIZATION_SETTINGS`.
  3. `getUnusedAppRestrictionsStatus` ∈ {`API_30`, `API_30_BACKPORT`, `API_31` } → field 7 =
     `enabled`, suggest turning it off; `DISABLED` → `disabled`; `FEATURE_NOT_AVAILABLE`, `ERROR` →
     `not_available`, hide the suggestion.
  4. The battery optimization exemption is also what allows A-SVC to restart the foreground service
     from the background on its own (API 3, logic 2).
  5. Do not ask again after the user denies; only keep the warning in Settings › Permissions &
     Background (E3).

#### API 5 — Manufacturer autostart instructions

- **URL:** N/A
- **Method:** `startActivity(Intent().setComponent(ComponentName(<package>, <activity>)))` from the
  configuration table; `ActivityNotFoundException` or `SecurityException` →
  `startActivity(Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS, Uri.fromParts("package", packageName, null)))`.
- **Request — configuration table, chosen by the lowercase `Build.MANUFACTURER`:**

| Manufacturer | Instructions shown | Screen opened |
|------|-------------------|-------------|
| `xiaomi`, `redmi`, `poco` (MIUI, HyperOS) | "Turn on Autostart for HandLive; in HandLive's Battery saver, choose No restrictions" | `com.miui.securitycenter/com.miui.permcenter.autostart.AutoStartManagementActivity` |
| `oppo`, `realme`, `oneplus` (ColorOS, realme UI, OxygenOS) | "In HandLive's Battery usage, turn on Allow background activity and Allow auto launch" | App info page |
| `samsung` (One UI) | "Battery › Background usage limits › Never sleeping apps › add HandLive" | App info page |
| Other manufacturers | Instructions hidden | — |

- **Response:** the manufacturer's screen opens, or the App info page (fallback).
- **Example:** `Build.MANUFACTURER = "Xiaomi"` → show the Xiaomi instructions; "Open Manufacturer
  Settings" opens `AutoStartManagementActivity`.
- **Business logic:**
  1. There is no public API to read the manufacturer's autostart state → rely on the user tapping
     "Done"; do not ask again.
  2. Screen names and paths change with ROM versions; the table lives in the app's resources and is
     updated with each release; any failure to open falls back to the App info page.
  3. The instructions can always be reopened from Settings › Permissions & Background.

#### API 6 — Accessibility settings for automatic clipboard sending

- **URL:** N/A
- **Method:** `startActivity(Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS))`; check with
  `AccessibilityManager.getEnabledAccessibilityServiceList(AccessibilityServiceInfo.FEEDBACK_ALL_MASK)`;
  install source: `packageManager.getInstallSourceInfo(packageName).installingPackageName` (API 30+) or
  `getInstallerPackageName(packageName)` (API 29); the restricted setting instructions open
  `ACTION_APPLICATION_DETAILS_SETTINGS`.
- **Request — declaration:**
  `<service android:name=".ClipboardAccessibilityService" android:permission="android.permission.BIND_ACCESSIBILITY_SERVICE" android:exported="false">`
  with the intent filter `android.accessibilityservice.AccessibilityService` and the configuration
  `@xml/a11y_clipboard` (`android:isAccessibilityTool="false"`; the event types are defined by
  CLIP-01 API 1).
- **Response:** the list of enabled services contains `ClipboardAccessibilityService` → field 15 =
  `on`; A-CLIP receives `onServiceConnected` (CLIP-01 A3).
- **Example:** field 14: "If Android shows 'Restricted setting': open Settings › Apps › HandLive, tap ⋮ at
  the top, choose 'Allow restricted settings', authenticate, then come back and turn on HandLive in
  Accessibility."
- **Business logic:**
  1. Open the Accessibility settings only after `clip.a11y_consent_at` is set (consent given by an
     explicit action, never preselected); the disclosure text follows CLIP-01 field 2.
  2. Android 13+ and `installingPackageName` other than `com.android.vending` (APK, F-Droid) → show
     field 14 before opening. The user comes back without the service turned on → show the
     instructions again (E7, E8).
  3. Service connected (`onServiceConnected`) → `auto_send = true`; disconnected (`onUnbind`) →
     `false`; every change sends `capability/update` (CLIP-01 A3).
  4. An app update that widens the data scope in the disclosure → delete `clip.a11y_consent_at` so
     consent is asked again.
  5. The user turns off "Auto-Send on Copy" (SET-02) → the service calls
     `disableSelf()` to give back the Accessibility permission.

#### API 7 — `WS capability/update`

Specified in SET-02 API 1 (1.2.5). In SET-01, Android sends it when `permissions_missing` or a
permission-dependent sub-flag (`can_send`, `sims`, `caller_id`, `can_answer`, `can_end`,
`auto_send`) changes.

#### API 8 — `POST /v1/devices`

Specified in CONN-03 API 1. Android calls it at step 7 when `relay.enabled = true`; idempotent
(upsert). Network error or 5xx → retry in the background with `RECONNECT_BACKOFF` when a network is
available (E10). The FCM push token is registered afterwards per CONN-04 API 1.

#### Query

No Room database queries; only DataStore reads and writes (the keys in 0.9.5 and the group's new
keys).

```text
# [Design] Android DataStore<Preferences> (A-UI, A-SVC)
prefs[longPreferencesKey("setup.completed_at")]                                   # step 1: null → run part A
dataStore.edit { it[longPreferencesKey("setup.started_at")] = now }                 # step 2
dataStore.edit { it[longPreferencesKey("setup.completed_at")] = now }               # step 7
prefs[booleanPreferencesKey("relay.enabled")] ?: true                             # step 7
prefs[stringSetPreferencesKey("perm.requested")] ?: emptySet()                    # step 10
dataStore.edit { it[stringSetPreferencesKey("perm.requested")] = requested + asked }   # step 10
dataStore.edit { it[longPreferencesKey("clip.a11y_consent_at")] = now }             # step 12
dataStore.edit { it[booleanPreferencesKey("clip.auto_send")] = false }              # E6
prefs[booleanPreferencesKey("feature.sms")] ?: true                               # step 14: only permissions of enabled features count (likewise feature.call, feature.camera, feature.call_audio)
```

---

## 1.2 SET-02 — Turn features and sync options on or off

### 1.2.1 General information

| Item | Content |
|-----|----------|
| Name | SET-02 — Turn features and sync options on or off |
| Description | The Settings screen on each device manages the keys in 0.9.5.<br>Settings belong to the device (global), apply to every pair of that device and are not synced to other devices; peers learn about them only through the capability.<br>Changing a `feature.*` key or a key that affects the capability → send `capability/update` (same structure as `capability/hello`) to every connected peer; both sides recompute the active features; turning a feature off stops its running tasks (for example a camera session).<br>Turning on a conditional feature goes through its own flow: `feature.call_audio` through AUDIO-01, `feature.camera` on the Mac through CAM-01, Android permissions through SET-01 part B, `clip.auto_send` through the Accessibility disclosure (CLIP-01 A1–A3).<br>Plus three actions: "Resync All SMS" (SMS-01 A1–A2); "Remove Device from Server" (`DELETE /v1/devices/me?revoke_pairs=false` — the relay deletes the device's registration and its pairs on the relay without sending `pair_revoked`; every local pair is kept and still works on the LAN or over USB — C16); "Delete All HandLive Data" (`revoke_pairs=true`: unpair everything and send `pair_revoked` to the peers, remove the device from the server, delete the keys, database and settings). |
| Actors | Primary: User. System: A-UI, A-SVC, A-CLIP, M-APP, I-APP, R-API, R-DB, R-KV. |
| Preconditions | The device has completed SET-01 (Android) or SET-03 (Mac/iOS). Actions involving the relay need the internet. "Resync All SMS" needs a session to the phone. |
| Postconditions | **Option changed:** the new value is in DataStore/`UserDefaults`; if the key affects the capability, every connected peer has received `capability/update`, the active features on both sides match the new configuration and the tasks of features that became inactive have stopped.<br>**Remove Device from Server:** the relay no longer has the device's `devices` and `pairs` rows; peers do not receive `pair_revoked`, they only see the pair disappear from the relay and keep using the LAN (C16); every local pair, the identity keys and other settings are unchanged; `relay.enabled = false`.<br>**Delete all:** the relay no longer has the device's `devices` and `pairs` rows; peers have received or will receive `pair_revoked`; the device has no pairs left; the identity keys, `PRK`, the database, settings and displayed notifications are deleted; the app returns to SET-01/SET-03. |
| Exceptions | E1 — The activation flow does not complete (AUDIO-01 disclosure declined, CAM-01 error): the key stays `false`.<br>E2 — Android: a feature is turned on but its permission is denied: the key is saved as `true`, the feature is inactive and the permission goes into `permissions_missing` (SET-01 E4, E5).<br>E3 — No session to the peer: save locally only; the next session's `capability/hello` carries the new value.<br>E4 — Writing DataStore/`UserDefaults` fails: keep the old value and show an error.<br>E5 — "Remove Device from Server" with no network or a relay error (5xx, timeout): nothing changes; show "Couldn't connect to the server. Try again later."<br>E6 — The relay returns 401 `TOKEN_EXPIRED`: get a new JWT (0.6.4) and retry once; `POST /v1/auth/challenge` returns 404 `DEVICE_NOT_FOUND` → the device was already deleted earlier; treat it as success.<br>E7 — "Delete All HandLive Data" while the relay is unreachable: ask "Couldn't connect to the server.<br>Delete from this device anyway?" with "Delete" (destructive) and "Cancel"; "Delete" → delete locally; the relay's records are deleted automatically after 180 days of inactivity (0.9.4).<br>E8 — The user cancels in the confirmation dialog: nothing changes.<br>E9 — Turning a feature off while its task is running (camera streaming, call audio on the Mac): ask for confirmation, then stop gracefully through the corresponding function (CAM-02, AUDIO-03). |
| Special requirements | **Performance:** on the LAN, the peer applies a change ≤ 1 s after the user flips the switch; writing a key does not block the UI.<br>**Security:** the capability only travels inside encrypted envelopes, the relay only sees `type = capability`; `DELETE /v1/devices/me` only deletes the calling device itself (by the JWT's `sub`); destructive actions have a warning-colored button, state the consequences clearly and cannot be undone; the keys are deleted from Keystore/Keychain before completion is reported.<br>**Privacy:** "Remove Device from Server" deletes all the data the relay holds about the device (public keys, push token, pairs); `usage_daily` statistics are kept only per `device_hash`, salted monthly, and expire after 30 days.<br>**Usability:** every switch has a one-line description and a reason when it is inactive; readable with TalkBack/VoiceOver.<br>**Feature independence:** changing one feature does not interrupt the others. |

### 1.2.2 Screens

N/A — no approved wireframe yet.

### 1.2.3 Component details

The Description column names the platforms that have the key, then **Capability** (the capability
field the key determines; a change → send `capability/update`) or **Local** (affects only this
device).

| # | Field | Data type | Input/Output | Initial value | Description |
|---|--------|--------------|--------------|------------------|-------|
| 1 | Sync Clipboard (`feature.clipboard`) | bool | Input/Output | `true` | All.<br>**Capability** `features.clipboard.enabled`. Off → stop watching and sending the clipboard, cancel an image transfer in progress (`clipboard/cancel`); incoming `clipboard/*` gets `FEATURE_DISABLED`<br>Description under the switch (Android): "Copy on one device and paste on the others." |
| 2 | Auto-Send on Copy (`clip.auto_send`) | bool | Input/Output | `true` | Android.<br>**Capability** `features.clipboard.auto_send` (= this key and the Accessibility service running). Turned on without consent yet or while the service is not running → CLIP-01 A1–A3 (SET-01 steps 12–14). Off → the service calls `disableSelf()`<br>Description under the switch (Android): "Sends what you copy right away, through an Accessibility service." |
| 3 | Disclosure consent time (`clip.a11y_consent_at`) | timestamp | Output | Empty | Android. "Agreed on Sep 24, 2026 at 2:05 PM"; only the disclosure flow writes this key |
| 4 | Sync Images (`clip.send_images`) | bool | Input/Output | `true` | All. **Capability** `features.clipboard.mimes`: `false` → drop `image/png`, `image/jpeg`, leaving only `text/plain` (CLIP QC1)<br>Description under the switch (Android): "Copied images up to 10 MB are sent too." |
| 5 | Block Sensitive Content (`clip.block_sensitive`) | bool | Input/Output | `true` | All; takes effect on the sending side on Android and Mac. **Local** (CLIP QC3)<br>Description under the switch (Android): "Content that looks like a password or card number is sent only if you choose Send Anyway." |
| 6 | Auto-Clear Received Clipboard (`clip.auto_clear_s`) | int32 (enum{0\| 60\| 300}, seconds) | Input/Output | `60` | All. **Local** on the receiving side (CLIP-05); `0` = off |
| 7 | SMS Messages (`feature.sms`) | bool | Input/Output | `true` | All.<br>**Capability** `features.sms.enabled`. Android: turned on with permissions missing → SET-01 part B; off → unregister the `ContentObserver`, `sms/*` gets `FEATURE_DISABLED`. Mac/iOS off → hide the Messages section, stop SMS-01; synced data is kept until unpairing or deleting all data |
| 8 | New SMS Notifications (`sms.notify`) | bool | Input/Output | `true` | Mac, iOS. iOS: **Capability** `features.sms.notify` (Android only pushes new SMS when `true`). Mac: **Local** |
| 9 | Show Content in Notifications (`sms.preview`) | bool | Input/Output | `true` | Mac, iOS. **Local**; I-NSE reads it from the App Group's `UserDefaults` |
| 10 | Calls (`feature.call`) | bool | Input/Output | `true` | All. **Capability** `features.call.enabled`. Android: turned on with permissions missing → SET-01 part B; off → stop watching calls. Mac/iOS off → no call panel or call notifications |
| 11 | Call Notifications (`call.notify`) | bool | Input/Output | `true` | Mac, iOS. iOS: **Capability** `features.call.notify` (Android only pushes calls when `true` — CALL-01 step 5). Mac: **Local** |
| 12 | Ring on Mac (`call.ringtone`) | bool | Input/Output | `true` | Mac. **Local** (CALL-01 field 14; key proposed by CALL-01, pending addition to 0.9.5) |
| 13 | Take Calls on Mac (`feature.call_audio`) | bool | Input/Output | `false` | Android, Mac.<br>**Capability** `features.call_audio.enabled` (the Mac adds `bt_address`).<br>Mac on → AUDIO-01; `true` is saved only when the user accepts the disclosure.<br>Android on → SET-01 part B (`BLUETOOTH_CONNECT`); Shizuku optional per AUDIO-01 steps 10–11.<br>Off during a call → the audio goes back to the phone (AUDIO-03, E9) |
| 14 | Wi-Fi Fallback, Requires Shizuku (`call_audio.allow_opus_fallback`) | bool | Input/Output | `true` | Android, Mac. Android `false` → do not bind the Shizuku UserService; **Capability** `features.call_audio.opus_fallback` with `available = false`, `reason = "disabled"`. Mac `false` → never opens `call_audio/open`; **Local** |
| 15 | Phone Used for HFP (`call_audio.phone_bt_address`) | string | Input/Output | Empty | Mac. Chosen in AUDIO-01 step 7; **Local** |
| 16 | Use Phone as Webcam (`feature.camera`) | bool | Input/Output | `false` | Android, Mac.<br>**Capability** `features.camera.enabled`. Mac on → CAM-01 (saves `true` once the virtual camera is `active`). Android on → SET-01 part B (`CAMERA`, `RECORD_AUDIO`). Off → stop the streaming session (`camera/stop`, CAM-02, E9) |
| 17 | Default Camera (`cam.default_camera`) | enum{front\| back} | Input/Output | `front` | Mac. **Local** (CAM-02) |
| 18 | Default Quality (`cam.default_quality`) | enum{auto\| 480p\| 720p\| 1080p} | Input/Output | `auto` | Mac. **Local** (CAM-02, CAM-05) |
| 19 | Switch to USB When Plugged In (`cam.usb_boost`) | bool | Input/Output | `true` | Mac. **Local** (CAM-04) |
| 20 | Don't Show USB Wizard Again (`cam.usb_wizard_dismissed`) | bool | Input/Output | `false` | Mac. **Local** (CAM-04); reset to `false` to show the wizard again |
| 21 | Internet Connection (`relay.enabled`) | bool | Input/Output | `true` | All.<br>**Capability** `features.relay.enabled`. Off → after `capability/update`, close the sessions that go through the relay (`session/bye`, `reason = shutdown`) and the `/v1/relay` connection; no push is sent. On → register with the relay (CONN-03 API 1) together with the pairs still at `relay_registered = 0` (PAIR-01 API 8)<br>Description under the switch (Android): "Reaches paired devices that aren't on the same Wi-Fi network; content stays end-to-end encrypted."<br>After CONN-03 E3 or E7 the relay error message (CONN-03 field 4) replaces that description. |
| 22 | Open at Login | bool | Input/Output | `SMAppService.mainApp.status == .enabled` | Mac. Not a settings key; read and written through `SMAppService` (SET-03 API 3) |
| 23 | "Permissions & Background" row | action | Input | — | Android. Opens the feature and permission list (SET-01 field 10) together with the background running status (SET-01 fields 6–9)<br>Holds the rows "Notifications", "Run in Background" and one per feature |
| 24 | Active features per paired device | array\<object> | Output | From the stored capability (`features_json`) | For each pair: the active features and, for an inactive one, the reason ("Off on \<device>", "Missing permission on the phone", "Internet connection is off on the phone") |
| 25 | "Resync All SMS" button | action | Input | Disabled when there is no session | Mac, iOS. Runs SMS-01 A1–A2 (step B1) |
| 26 | "Remove Device from Server" button | action | Input | — | All. Flow A1–A4, A6: deregister from the relay; keep the identity keys, settings and every pairing (still usable on the LAN or over USB) |
| 27 | "Delete All HandLive Data" button | action | Input | — | All. Flow A1–A6 |
| 28 | Destructive action confirmation | enum{Remove from Server\| Delete All\| Cancel} | Input | — | The confirm button names the action and sits next to "Cancel": "Remove from Server" for field 26, "Delete All" for field 27; it is warning-colored |
| 29 | Warning text | string | Output | Per action | Remove from server: "This device's registration will be removed from the HandLive server.<br>Paired devices keep working on the same Wi-Fi network; the internet connection stays off until you turn it back on." Delete all: "The security keys, paired devices, synced messages and call history, and all settings on this device will be deleted.<br>This can't be undone." |
| 30 | Result or error message | string | Output | Empty | "Removed from the server" or text per E1–E9 |
| 31 | Show HandLive in Menu Bar (`mac.menu_bar_extra`) | bool | Input/Output | `true` | Mac.<br>**Local**. `true` → an icon in the menu bar (`MenuBarExtra`, `isInserted`), and the app is in `.accessory` mode while its main window is not open; `false` → remove the icon; the app switches to `.regular` (Dock icon, the app's menu bar, Dock menu) as its main entry point.<br>Asked during setup (SET-03 field 16, step 6) |
| 32 | Language | enum{System Default\| English\| Tiếng Việt} | Input/Output | System Default | Android.<br>**Local**, not a settings key (C20, 0.12.3). Android 13+: opens the system's app language page (`Settings.ACTION_APP_LOCALE_SETTINGS`); Android 10–12: chosen in the app and applied with `AppCompatDelegate.setApplicationLocales` (saved automatically). Language names are written in their own language. Mac, iPhone and iPad use the system's per-app language setting |

### 1.2.4 Business flow

```mermaid
flowchart TB
  subgraph ND["User"]
    U1["(1) Open Settings, change an option"]
    U8["(8) See the updated feature status"]
    UA1["(A1) Choose Remove from Server or Delete All, confirm"]
    UA6["(A6) See the result or the welcome screen"]
  end
  subgraph HT["System"]
    D2{"(2) Turning on a key that needs an activation flow?"}
    S3["(3) Run SET-01 part B, AUDIO-01, CAM-01 or the Accessibility disclosure"]
    S4["(4) Write the key, apply local effects"]
    D5{"(5) Key affects the capability?"}
    S6["(6) Send capability/update on every open session"]
    S7["(7) Both sides recompute active features, stop or start tasks"]
    SA2["(A2) Authenticate with the relay, call DELETE /v1/devices/me"]
    SA3["(A3) Relay deletes the device, sends pair_revoked only for delete all"]
    SA4["(A4) Delete all: pair/revoke over LAN, clean up pairs. Remove from server only: keep pairs, turn off relay"]
    SA5["(A5) Delete keys, database, settings"]
    X1(["End: nothing changes"])
  end
  U1 --> D2
  D2 -- "Yes" --> S3
  D2 -- "No" --> S4
  S3 -- "Completed or permission denied (E2)" --> S4
  S3 -- "Not completed (E1)" --> X1
  S4 --> D5
  D5 -- "Yes" --> S6 --> S7 --> U8
  D5 -- "No" --> U8
  UA1 -- "Confirm" --> SA2
  UA1 -- "Cancel (E8)" --> X1
  SA2 --> SA3
  SA3 -- "204" --> SA4
  SA2 -- "Relay error, remove from server only (E5)" --> X1
  SA2 -- "Relay error, delete all, user deletes anyway (E7)" --> SA4
  SA4 -- "Delete all" --> SA5 --> UA6
  SA4 -- "Remove from server only" --> UA6
```

| Step | Actor | Component | Description | Exceptions / Notes |
|------|----------|-----------|-------|--------------------|
| 1 | User | A-UI / M-APP / I-APP | Opens Settings (Android: Settings tab; Mac: menu bar › Settings; iOS: Settings tab) and flips a switch or picks a value (fields 1–22). | Turning off a feature that has a running task → ask for confirmation first (E9). |
| 2 | System | Same as above | Keys that need an activation flow when turned **on**: `feature.call_audio` (Mac: AUDIO-01; Android: `BLUETOOTH_CONNECT`), `feature.camera` (Mac: CAM-01; Android: `CAMERA`, `RECORD_AUDIO`), `feature.sms` and `feature.call` on Android while permissions are missing (SET-01 part B), `clip.auto_send` when `clip.a11y_consent_at` is not set or the Accessibility service is not running.<br>Other keys and every turn-off → step 4. |  |
| 3 | System, User | Same as above | Runs the corresponding flow. AUDIO-01 and CAM-01 save `true` themselves when they complete (AUDIO-01 step 5, CAM-01 step 11). SET-01 part B: the key is saved as `true` even if the permission is denied (the feature is then inactive). Accessibility disclosure declined → `clip.auto_send = false`. | E1, E2. |
| 4 | System | Same as above | Writes the key (Query) and applies the local effects: feature off → stop its tasks on this device (API 1, logic 4); `clip.auto_send = false` → `disableSelf()`; `relay.enabled = true` → register with the relay in the background (API 6); **Local** keys (`clip.auto_clear_s`, `cam.*`, `sms.preview`, `call.ringtone`…) apply from the next use. | Write error → E4, keep the old value. |
| 5 | System | Same as above | Checks whether the key is marked **Capability** in 1.2.3 or changes `permissions_missing`. | No → step 8. |
| 6 | System | Same as above | Builds the full capability (0.7.2) and sends `capability/update` (API 1) on every open `/v1/ctl` session: Android sends to every client, Mac/iOS send to the phone.<br>For `relay.enabled = false` only: close the sessions that go through the relay (`session/bye`, `reason = shutdown`) and the `/v1/relay` connection only after sending. | No session → E3. |
| 7 | System | Both sides | The receiver replaces `features_json` and recomputes the active features (CONN-01 API 7): a feature becomes inactive → stop its tasks (API 1, logic 4); a feature becomes active → start it as after `capability/hello` (SMS-01, CALL-04).<br>The peer turns on a feature that is off on this device (for example the Mac turns on the camera and the phone has not) → show a suggestion to turn it on; never turn it on automatically. |  |
| 8 | User | Same as above | Sees the new status on both devices (field 24; PAIR-02 field 8). |  |
| A1 | User | Same as above | Chooses "Remove Device from Server" (field 26) or "Delete All HandLive Data" (field 27), reads the warning (field 29) and confirms (field 28). | "Cancel" → E8. |
| A2 | System | Same as above → R-API | Gets a JWT (API 3), then calls `DELETE /v1/devices/me` (API 2) with `revoke_pairs=false` (remove from server only) or `revoke_pairs=true` (delete all). | No network or 5xx: remove from server only → E5; delete all → E7. 401 or 404 while getting the challenge → E6. |
| A3 | System | R-API, R-DB, R-KV | The relay deletes the `devices` row (the device's `pairs` rows are deleted by CASCADE), closes the device's relay connection and returns 204 (API 2).<br>Only when `revoke_pairs=true`: send `pair_revoked` to online peers and write `revoked_notice` for offline peers.<br>With `revoke_pairs=false` the relay notifies nobody: peers only see that the pair is no longer on the relay and switch to using the LAN only on their own (PAIR-02 API 1, logic 3). |  |
| A4 | System | Initiating device | **Delete all:** for each pair with a LAN or USB session, send `pair/revoke` (API 4, `reason = reinstall`) and wait up to 10 s for the `ack`, in parallel; clean up every local pair as in PAIR-03 step 7 but delete the records outright, keeping no tombstone (the relay has already deleted the pairs); Android re-registers mDNS without the TXT `h`; go to A5.<br>**Remove from server only:** keep every pair, set `relay_registered = 0` on every pair, write `relay.enabled = false`, send `capability/update` (`features.relay.enabled = false`), go to A6. | Delete all: the sessions going through the relay were closed at A3; those peers receive `pair_revoked`. E7: `pair/revoke` is still sent over the LAN. |
| A5 | System | Initiating device | Delete all (API 7): Android stops A-SVC and calls `disableSelf()` for the Accessibility service; delete the keys (Keystore/Keychain), database, DataStore/`UserDefaults` and displayed notifications; the Mac removes the login item. | The virtual camera/microphone are not uninstalled (CAM-01 A1); operating system permissions already granted are not revoked. |
| A6 | User | Same as above | Sees "Removed from the server" (paired devices still work on the LAN, the internet connection is off), or the app returns to the welcome screen (SET-01/SET-03). |  |
| B1 | User | M-APP / I-APP | Chooses "Resync All SMS" (field 25) → SMS-01 A1–A2. | Only when there is a session to the phone. |

### 1.2.5 API/service specification

**List of calls**

| # | API/service | Channel | Direction | Used in step |
|---|-------------|------|-------|-------------|
| 1 | `WS capability/update` | `/v1/ctl` (LAN, USB or relay) | Both directions | 6, 7 |
| 2 | `DELETE /v1/devices/me` | Relay REST | Device → R-API | A2, A3 |
| 3 | `POST /v1/auth/challenge`, `POST /v1/auth/token` | Relay REST | Device → R-API | A2 |
| 4 | `WS pair/revoke` | `/v1/ctl` (LAN, USB) | Both directions | A4 |
| 5 | Relay op `pair_revoked` | `wss://{RELAY_HOST}/v1/relay` (text) | R-API → device | A3 |
| 6 | `POST /v1/devices`, `POST /v1/pairs` | Relay REST | Device → R-API | 4 (turning on `relay.enabled`) |
| 7 | Operating system services that delete keys and data: `disableSelf`, `KeyStore.deleteEntry`, `SecItemDelete`, `removePersistentDomain`, `removeAllDeliveredNotifications`, `SMAppService.mainApp.unregister` | Local | — | 4, A4, A5 |

#### API 1 — `WS capability/update`

- **URL:** `wss://{android_host}:{port}/v1/ctl` (LAN or USB) or through the relay
  (`wss://{RELAY_HOST}/v1/relay`, with the `to`/`from` wrapper)
- **Method:** `WS capability/update` (both directions), encrypted envelope, no ack (0.7.1).
- **Request (`data`):** a full snapshot with the same structure as `capability/hello` (0.7.2).
  Mapping of settings keys → fields:

| Settings key / state | Capability field | Sender |
|--------------------------|-------------------|---------|
| `feature.clipboard`, `feature.sms`, `feature.call` | `features.<name>.enabled` | All |
| `feature.call_audio`, `feature.camera` | `features.call_audio.enabled`, `features.camera.enabled` | Android, Mac |
| `clip.auto_send` and the Accessibility service running | `features.clipboard.auto_send` | Android (clients always `true`) |
| `clip.send_images` | `features.clipboard.mimes` (`false` → `text/plain` only) | All |
| `sms.notify` | `features.sms.notify` | iOS/iPadOS |
| `call.notify` | `features.call.notify` | iOS/iPadOS |
| `call_audio.allow_opus_fallback` | `features.call_audio.opus_fallback` (`false` → `available = false`, `reason = "disabled"`) | Android |
| `relay.enabled` | `features.relay.enabled` | All |
| Android permissions (SET-01 API 2) | `permissions_missing`, `features.sms.can_send`, `features.sms.sims`, `features.call.can_answer`, `features.call.can_end`, `features.call.caller_id` | Android |

- **Response:** N/A (no ack). The receiver sends its own `capability/update` only when its own
  configuration changes.
- **Example:** the phone turns SMS off:

```json
{"op":"update","data":{"protocol":1,"app_version":"1.0.0 (100)","platform":"android","os_version":"15","model":"Pixel 8","features":{"clipboard":{"enabled":true,"auto_send":true,"max_text_bytes":1048576,"max_image_bytes":10485760,"mimes":["text/plain","image/png","image/jpeg"]},"sms":{"enabled":false,"can_send":true,"sims":[{"sub_id":1,"slot":0,"label":"SIM 1"}],"default_sub_id":1},"call":{"enabled":true,"can_answer":true,"can_end":true,"caller_id":true},"call_audio":{"enabled":false,"bt_address":null,"hfp_connected":false,"opus_fallback":{"available":false,"downlink":false,"uplink":false,"reason":"shizuku_not_running"}},"camera":{"enabled":false,"cameras":["front","back"],"max_width":1920,"max_height":1080,"max_fps":30,"codecs":["h264"]},"relay":{"enabled":true}},"permissions_missing":[]}}
```

The iPhone turns call notifications off:

```json
{"op":"update","data":{"protocol":1,"app_version":"1.0.0 (100)","platform":"ios","os_version":"18.6","model":"iPhone16,1","features":{"clipboard":{"enabled":true,"auto_send":true,"max_text_bytes":1048576,"max_image_bytes":10485760,"mimes":["text/plain","image/png","image/jpeg"]},"sms":{"enabled":true,"notify":true},"call":{"enabled":true,"notify":false},"relay":{"enabled":true}}}}
```

- **Business logic:**
  1. When to send: a key marked **Capability** (1.2.3) changes; the Android permissions or the
     Accessibility service state change (SET-01 step 14); the SIM list changes
     (`SubscriptionManager.OnSubscriptionsChangedListener`); `hfp_connected` changes (AUDIO-02); the
     Opus/WS capability changes (AUDIO-01 step 11).
  2. Always send a full snapshot; the receiver replaces the whole stored copy and never merges piece
     by piece. Several changes within 300 ms are coalesced into one update. A feature the platform
     does not have (for example `camera` on iOS) is absent from `features` and treated as
     `enabled = false`.
  3. Send on every `/v1/ctl` session that is `Connected`; nothing is queued when there is no session —
     the next session opens with a `capability/hello` that carries the new values (E3).
  4. The receiver updates `features_json` (Query), recomputes the active features (CONN-01 API 7)
     and stops the tasks of the features that became inactive:

| Feature that became inactive | Task stopped |
|------------------------|----------------|
| `clipboard` | Cancel an image transfer in progress (`clipboard/cancel`); stop sending new clips to that device |
| `sms` | Stop SMS-01 after the page being processed; `sms_outbox` rows still `pending` are kept and sent once the feature is active again |
| `call` | Close the call panel and the call notifications currently shown on Mac/iOS |
| `call_audio` | Close the Opus/WS stream (`call_audio/close`, AUDIO-04) or return the HFP audio to the phone (AUDIO-03) |
| `camera` | `camera/stop` for the streaming session (CAM-02) |
| `relay` (the peer reports `features.relay.enabled = false`) | Do not use the relay to reach that device: the client does not run CONN-03 and does not send `wake` pushes; Android does not send `alert` pushes |

  5. A feature becomes active again → start it as after `capability/hello` (CONN-01 step 10: SMS-01,
     CALL-04).
  6. Do not log the capability content; logs only contain `type`, `op` and the size (0.5.1 rule 5).

#### API 2 — `DELETE /v1/devices/me`

- **URL:** `https://{RELAY_HOST}/v1/devices/me?revoke_pairs=<true|false>`
- **Method:** `DELETE`, header `Authorization: Bearer <jwt>`
- **Request:** no body; the device deleted is the JWT's `sub`. Query parameters:

| Parameter | Type | Required | Description |
|---------|------|----------|-------|
| `revoke_pairs` | bool | Yes | `false` — "Remove Device from Server": silent deregistration; the pairs keep working on the LAN. `true` — "Delete All HandLive Data": revoke every pair and notify the peers |
- **Response:**

| HTTP | Body | When |
|------|------|---------|
| 204 | — | Deleted, or the device no longer exists on the relay (repeated call) |
| 401 `TOKEN_EXPIRED` | error | JWT expired → get a new token and retry once (E6) |
| 429 `RATE_LIMITED` | error | Wait for `Retry-After` |

- **Example:**

```http
DELETE /v1/devices/me?revoke_pairs=true HTTP/1.1
Host: relay.example.com
Authorization: Bearer eyJhbGciOiJIUzI1NiJ9.eyJzdWIiOiI1YjFmOGMyZS05YTRkLThlNmYtYTFiMi1jM2Q0ZTVmNjA3MTgifQ.sig

HTTP/1.1 204 No Content
```

With `revoke_pairs=true`, the relay notifies the phone, which is online:

```json
{"op":"pair_revoked","pair_id":"3f2b1c4d-5e6f-4a7b-8c9d-0e1f2a3b4c5d","by":"5b1f8c2e-9a4d-8e6f-a1b2-c3d4e5f60718"}
```

- **Business logic:**
  1. Only the calling device itself is deleted (`sub`); there is no variant that takes a `device_id`
     in the path.
  2. One transaction: read the unrevoked pairs and their peers, then `DELETE FROM devices` — the
     `pairs` rows are deleted by `ON DELETE CASCADE` (revoked pairs included). No row → still 204.
  3. `revoke_pairs=true`: after the commit, for each peer add `<pair_id>|<device_id>` to
     `revoked_notice:<peer_device_id>` (TTL 30 days); if `presence:<peer_device_id>` exists → publish
     `pair_revoked` on `dev:<peer_device_id>` right away. An offline peer receives `pair_revoked` the
     next time it connects to the relay (CONN-03 API 4) — this key is needed because the `pairs`
     rows are gone, so the "pairs revoked within 30 days" query of PAIR-03 API 4 can no longer see
     them. The receiving device handles it as in PAIR-03 API 4 (repeats are ignored).
  4. `revoke_pairs=false`: nobody is notified. Peers keep the pair; their next `GET /v1/pairs` call
     sees that the pair is no longer on the relay and switches to using the LAN only (PAIR-02 API 1,
     logic 3).
  5. Delete `presence:<device_id>` and `chal:<device_id>` first, then close the device's `/v1/relay`
     connection (an internal close command through `dev:<device_id>`, code 1000). Presence is already
     gone, so the peers get no `presence` offline message; with `revoke_pairs=false` their relay
     connections simply drop the pair (C16).
  6. An old JWT that is still valid (≤ 15 minutes) can no longer be used: the endpoints that use a
     JWT check that `devices` still has a row for `sub`; none → 404 `DEVICE_NOT_FOUND`; `/v1/relay`
     refuses the upgrade. To use the relay again the device must call `POST /v1/devices` (which
     creates a new row).
  7. `usage_daily` is not deleted (it holds no `device_id`, only a `device_hash` salted monthly that
     expires after 30 days); relay logs only record `device_hash`.
  8. The general REST rate limit applies (`RELAY_RATE_LIMIT`).

#### API 3 — Relay authentication

Specified in 0.6.4 and CONN-03 API 2–3 (`POST /v1/auth/challenge`, `POST /v1/auth/token`). A token
that is still valid for more than 60 s is reused. `POST /v1/auth/challenge` returns 404
`DEVICE_NOT_FOUND` → the device was already deleted earlier; A2 counts as successful (E6).

#### API 4 — `WS pair/revoke`

Specified as in PAIR-03 API 1. Used only for delete all, with `reason = reinstall`; sent on the LAN
or USB session (the session through the relay was closed at A3). "Remove Device from Server" does
not send `pair/revoke`. It must be sent before the keys are deleted, because once `PRK` is deleted
nothing can be encrypted anymore.

#### API 5 — Relay op `pair_revoked`

Specified as in PAIR-03 API 4, with `by` = the `device_id` of the device that was just deleted. In
this function the relay emits it per API 2 logic 3: right at deletion (online peers) and when a peer
reconnects to the relay.

#### API 6 — `POST /v1/devices`, `POST /v1/pairs`

Specified in CONN-03 API 1 and PAIR-01 API 8. Called when `relay.enabled` switches to `true`:
register the device (upsert), then `POST /v1/pairs` for each pair with `relay_registered = 0`
(Query); Android and iOS register the push token again (CONN-04 API 1). Errors → retry in the
background; the switch is not blocked.

#### API 7 — Delete local keys and data

- **URL:** N/A
- **Method:**
  - Android: `ClipboardAccessibilityService.disableSelf()`; `stopForeground(STOP_FOREGROUND_REMOVE)`
    then `stopSelf()`; `NotificationManagerCompat.cancelAll()`;
    `KeyStore.getInstance("AndroidKeyStore").deleteEntry("hl_master")`;
    `context.deleteSharedPreferences("hl_keys")`; delete the PKCS#12 file;
    `context.deleteDatabase("handlive.db")`; `dataStore.edit { it.clear() }`.
  - Mac/iOS: `SecItemDelete` for the service `app.handlive.keys` (deletes `ik_sig`, `ik_dh`, `db_key`
    and every `PRK`); close the `DatabasePool`, then delete `handlive.sqlite`, `-wal`, `-shm`;
    `UserDefaults.standard.removePersistentDomain(forName: "app.handlive.mac")` (Mac) or
    `UserDefaults(suiteName: "group.app.handlive")?.removePersistentDomain(forName: "group.app.handlive")`
    (iOS); `UNUserNotificationCenter.current().removeAllDeliveredNotifications()` and
    `removeAllPendingNotificationRequests()`; Mac: `try SMAppService.mainApp.unregister()`.
- **Request:** N/A.
- **Response:** the result code of each call; `errSecItemNotFound` or a file that does not exist
  counts as success; other errors are retried once, then reported.
- **Example:** Mac:
  `SecItemDelete([kSecClass: kSecClassGenericPassword, kSecAttrService: "app.handlive.keys"])` →
  `errSecSuccess`; then `handlive.sqlite` is deleted; the next launch runs SET-03 and generates a new
  `device_id`.
- **Business logic:**
  1. Order: every step that needs the keys runs first (A2 signs the challenge with `ik_sig`, A4
     encrypts `pair/revoke` with the session key derived from `PRK`) → delete the keys → delete the
     database (the SQL in Query, then delete the file) → delete settings and notifications → back to
     the welcome screen.
  2. Deleting `db_key` makes any leftover SQLCipher pages unreadable, even if deleting the file
     fails. On Android, deleting `hl_master` makes any leftover keyset and PKCS#12 password
     impossible to decrypt.
  3. Android: stop A-SVC first so no connection remains; call `disableSelf()` because the on/off
     state of the Accessibility service lives in the system settings and is not removed with the
     app data.
  4. Do not uninstall M-CAMX, M-MIC; do not revoke operating system permissions already granted.
  5. Remove from server only: only tidy up the pairs (Query, A4) and write `relay.enabled = false`;
     do not call the APIs that delete keys and settings.

#### Query

```text
# [Design] Read/write settings keys (steps 1, 4, A4, A5)
dataStore.data.map { it[booleanPreferencesKey("feature.sms")] ?: true }            # Android, reads field 7
dataStore.edit { it[booleanPreferencesKey("feature.sms")] = false }                 # Android, step 4
dataStore.edit { it[intPreferencesKey("clip.auto_clear_s")] = 300 }                 # Android, step 4
UserDefaults.standard.set(false, forKey: "relay.enabled")                           # Mac, step 4 or A4 (remove from server only)
UserDefaults(suiteName: "group.app.handlive")?.set(false, forKey: "call.notify")    # iOS, step 4
dataStore.edit { it.clear() }                                                        # Android, A5
```

```sql
-- [Design] Both sides, step 7: store the peer's new capability
UPDATE paired_device SET features_json = :features_json WHERE pair_id = :pair_id;

-- [Design] Every device, step 4 (turning on relay.enabled): pairs not yet registered with the relay
SELECT pair_id FROM paired_device WHERE revoked_at IS NULL AND relay_registered = 0;

-- [Design] Android, A4 (one transaction): clean up every pair, keep no tombstone
DELETE FROM push_outbox;
DELETE FROM paired_device;

-- [Design] Mac/iOS, A4 (one transaction): clean up synced data and pairs (PRK is deleted separately in the Keychain)
DELETE FROM sms_message;
DELETE FROM sms_thread;
DELETE FROM sms_outbox;
DELETE FROM call_log_entry;
DELETE FROM sync_cursor;
DELETE FROM paired_device;

-- [Design] Android, A5 (one transaction, before deleting the handlive.db file)
DELETE FROM push_outbox;
DELETE FROM sms_observer_state;
DELETE FROM paired_device;

-- [Design] Mac, A5: consent table (Mac only), before deleting the handlive.sqlite file
DELETE FROM consent_record;

-- [Design] Relay, API 2 (one transaction): peers of the active pairs, then delete the device
SELECT pair_id,
       CASE WHEN device_a = $1 THEN device_b ELSE device_a END AS peer_device_id
FROM pairs
WHERE (device_a = $1 OR device_b = $1) AND revoked_at IS NULL;
DELETE FROM devices WHERE device_id = $1;   -- pairs are deleted by ON DELETE CASCADE

-- [Design] Relay, API 2 logic 5: the JWT's device still exists (used by the other JWT endpoints)
SELECT 1 FROM devices WHERE device_id = $1 AND revoked_at IS NULL;
```

```text
# [Design] Redis, API 2
SADD     revoked_notice:<peer_device_id> "<pair_id>|<device_id>"      # each peer, only when revoke_pairs=true
EXPIRE   revoked_notice:<peer_device_id> 2592000                       # 30 days
EXISTS   presence:<peer_device_id>
PUBLISH  dev:<peer_device_id> {"op":"pair_revoked","pair_id":"<pair_id>","by":"<device_id>"}
DEL      presence:<device_id> chal:<device_id>                          # first: peers get no presence offline
PUBLISH  dev:<device_id> <internal close-connection command>
# [Design] Redis, when a device connects to the relay (addition to CONN-03 API 4)
SMEMBERS revoked_notice:<device_id>
```

---

## 1.3 SET-03 — Initial setup on Mac and iOS

### 1.3.1 General information

| Item | Content |
|-----|----------|
| Name | SET-03 — Initial setup on Mac and iOS |
| Description | First run of HandLive for Mac (M-APP, a menu bar app) and HandLive for iOS/iPadOS (I-APP).<br>**Common:** a welcome screen with a privacy explanation; create the identity keys `ik_sig`, `ik_dh`, compute `device_id` and create the SQLCipher key `db_key` in the Keychain (0.6.1, 0.6.5); request notification permission (`UNUserNotificationCenter`, with the time-sensitive interruption level for incoming calls); trigger the local network permission dialog with the first Bonjour browse; finally register the device with the relay when `relay.enabled = true` (CONN-03 API 1) and move on to PAIR-01.<br>**Mac:** check that the app runs from `/Applications` (required for the virtual camera — C11) and offer to move it; ask about "Show HandLive in Menu Bar"; "Open at Login" with `SMAppService.mainApp.register()`; paste permission guidance per C10 (`NSPasteboard.accessBehavior`, macOS 15.4+).<br>Bluetooth and camera permissions are not requested here but in AUDIO-01 and CAM-01.<br>**iOS/iPadOS:** explain the platform limits — the clipboard only syncs while the app is in the foreground, there is no call audio, and SMS and incoming calls arrive through push when the app is closed (C7). |
| Actors | Primary: User. System: M-APP or I-APP, OS (Keychain, privacy/TCC, Notification Center, Service Management, Bonjour), R-API (device registration), PUSH (APNs, iOS/iPadOS only). |
| Preconditions | M-APP (Developer ID, notarized, macOS 13+) or I-APP (App Store, iOS/iPadOS 16+) has just been installed; `setup.completed_at` is not set. |
| Postconditions | **Success:** the Keychain holds `ik_sig`, `ik_dh`, `db_key`; `handlive.sqlite` has been created with the 0.9.3 schema; notification and local network permissions have been asked for; Mac: the menu bar icon and the login item follow the user's choices, and the app location and the paste permission state are known; iOS/iPadOS: the user has read the limits; `setup.completed_at` is written; the device is registered with the relay (if enabled) or a background retry is pending; the UI moves on to PAIR-01.<br>**Failure (E1):** `setup.completed_at` is not written and the app does not move on to PAIR-01. |
| Exceptions | E1 — Key generation or the Keychain write fails (`errSecInteractionNotAllowed`, `errSecMissingEntitlement`): show "Couldn't create the security keys on this device. Try again." with a "Try Again" button; do not continue to PAIR-01.<br>E2 — Mac: the app is not running from `/Applications` (opened straight from the disk image or the Downloads folder, under App Translocation, or no write permission to the Applications folder): offer to move it; the user postpones or the move fails → continue, with a note that the virtual camera can't be used yet (CAM-01 E1).<br>E3 — Notifications denied: HandLive still works; the Mac gets no SMS or missed call notifications (the call panel still appears while the app is running); iOS/iPadOS receive no SMS or calls while the app is closed (CONN-04 field 1 = `denied`); show instructions for turning them back on. Mac: "Notifications are off, so new SMS messages and missed calls don't appear. Turn them on in System Settings › Notifications › HandLive." iPhone, iPad: "Notifications are off, so new SMS messages and incoming calls don't appear while HandLive is closed. Turn them on in Settings › Notifications › HandLive."<br>Time-sensitive notifications turned off → Focus may silence call notifications.<br>E4 — Local network denied: the phone can't be found on the LAN (CONN-01 E8); pairing and connecting only go through the relay (PAIR-01 with a QR code that carries `rv`; the PIN can't be used); show instructions for turning it back on. Mac: "HandLive can't look for the phone on Wi-Fi. Turn on HandLive in System Settings › Privacy & Security › Local Network." iPhone, iPad: "HandLive can't look for the phone on Wi-Fi. Turn on HandLive in Settings › Privacy & Security › Local Network."<br>E5 — Mac: `SMAppService` returns `.requiresApproval` or an error: show "To open HandLive at login, allow it in System Settings › General › Login Items." with "Open System Settings"; do not block.<br>E6 — macOS 15.4+: `accessBehavior` is `.ask` or `.alwaysDeny`: point to System Settings › Privacy & Security › Paste from Other Apps (C10); Apple has no API to request "Always Allow"; do not block.<br>E7 — No network or relay error while registering the device or the push token: skip, retry in the background (CONN-03, CONN-04); do not block. |
| Special requirements | **Platform declarations:** Info.plist `NSLocalNetworkUsageDescription` ("HandLive looks for your Android phone on your Wi-Fi network to connect to it directly, not over the internet.") and `NSBonjourServices` = `["_handlive._tcp"]`; entitlement `com.apple.developer.usernotifications.time-sensitive`; Mac: `LSUIElement` = `YES` (launches without a Dock icon); the app switches `NSApplication.setActivationPolicy(_:)` between `.accessory` (menu bar icon only) and `.regular` (Dock icon, the menu bar HandLive · File · Edit · View · Window · Help, Dock menu) when the Messages or Camera Preview window opens or when "Show HandLive in Menu Bar" is turned off; `NSMicrophoneUsageDescription` ("HandLive uses the microphone so you can talk during calls transferred from your phone.") and `NSFocusStatusUsageDescription` ("HandLive reads your Focus status so it doesn't ring or show calls while a Focus is on.") are used in AUDIO-01 and CALL-01; iOS/iPadOS: `aps-environment`, the App Group `group.app.handlive` and a keychain access group shared with I-NSE.<br>**Privacy:** only ask for the permissions the core functions need; Bluetooth (AUDIO-01) and camera (CAM-01) are asked only when the user turns the feature on; every system dialog is preceded by an explanation screen with a single "Continue" button (HIG); the user declines right in the system dialog.<br>**Usability:** ≤ 6 screens, completed in ≤ 60 s; readable with VoiceOver; every step after key generation can move on without blocking; iOS/iPadOS set clear expectations and never promise features that don't exist.<br>**Security:** Keychain `kSecAttrAccessibleWhenUnlockedThisDeviceOnly` (0.6.1); private keys only live in the Keychain and in process memory; reinstalling the app generates a new `device_id` (0.2). |

### 1.3.2 Screens

N/A — no approved wireframe yet.

### 1.3.3 Component details

| # | Field | Data type | Input/Output | Initial value | Description |
|---|--------|--------------|--------------|------------------|-------|
| 1 | Introduction and privacy | string | Output | Fixed text | "HandLive brings the clipboard, SMS messages, and calls from your Android phone to this device. Data is end-to-end encrypted and travels only between your devices; the server can't read it. No account needed." |
| 2 | "Get Started" button | action | Input | — | Goes to step 4 |
| 3 | Open HandLive at Login | bool | Input/Output | `true` | Mac. Checkbox on the welcome screen; `true` → `SMAppService.mainApp.register()` at step 6 |
| 4 | App location | enum{applications\| other\| translocated} | Output | From `Bundle.main.bundleURL` | Mac. `other`, `translocated` show field 5 |
| 5 | Offer to move to the Applications folder | enum{Move\| Not Now} | Input | — | Mac. "The virtual camera works only when HandLive is in the Applications folder. Move it now?" |
| 6 | Login item status | enum{enabled\| requires_approval\| not_registered\| not_found} | Output | `SMAppService.mainApp.status` | Mac. `requires_approval` shows fields 12, 13 (E5) |
| 7 | Notification permission | enum{allowed\| denied\| not_determined} | Input/Output | `not_determined` | From `authorizationStatus`; `denied` shows instructions (E3); on iOS this is CONN-04 field 1 |
| 8 | Time-sensitive level | enum{enabled\| disabled\| not_supported} | Output | From `timeSensitiveSetting` | `disabled` shows the warning "Focus may silence call notifications" |
| 9 | Local network permission | enum{allowed\| denied\| unknown\| not_required} | Output | `unknown`; `not_required` on macOS 13–14 | Inferred from the `NWBrowser` state (API 5); `denied` shows instructions (E4) |
| 10 | Paste from other apps permission | enum{default\| ask\| always_allow\| always_deny\| not_applicable} | Output | `not_applicable` before macOS 15.4 | Mac. `ask`, `always_deny` show instructions (E6) |
| 11 | Limits on iPhone/iPad | string | Output | Fixed text | iOS/iPadOS. "The clipboard syncs while HandLive is open on this device: tap the Paste button to send, with no paste permission prompt. iPhone and iPad can't take calls. When HandLive is closed, SMS messages and incoming calls appear as notifications." |
| 12 | Instructions for opening system settings | string | Output | Hidden | Text per E3–E6, giving the exact settings path for the operating system version |
| 13 | "Open System Settings" (Mac), "Open Settings" (iPhone, iPad) button | action | Input | Shown with field 12 | Opens the corresponding settings page (API 3–6) |
| 14 | "Continue" button | action | Input | — | The only button on each permission primer and instruction screen; there is no "Skip" — the user declines right in the system dialog (HIG, design system) |
| 15 | Error message | string | Output | Empty | Per E1–E7 |
| 16 | Show HandLive in Menu Bar | bool | Input/Output | `true` | Mac. Checkbox on the welcome screen → `mac.menu_bar_extra` (SET-02 field 31); `false` → the app keeps its Dock icon as the main entry point (step 6) |

### 1.3.4 Business flow

```mermaid
flowchart TB
  subgraph ND["User"]
    U1["(1) Open HandLive for the first time"]
    U3["(3) Read the introduction, choose Get Started"]
    U5["(5) Move to the Applications folder or choose Not Now"]
    U8["(8) Allow or deny notifications"]
    U10["(10) Allow or deny local network"]
    U12["(12) Read the instructions, choose Continue"]
  end
  subgraph HT["System"]
    S2["(2) Create identity keys, device_id, SQLCipher key"]
    D4{"(4) Mac running from /Applications?"}
    S6["(6) Mac: register Open at Login, set up the menu bar icon"]
    S7["(7) Explain, request notification permission"]
    S9["(9) Explain, browse Bonjour so the system asks for local network"]
    S11["(11) Mac: check paste permission. iOS: explain the limits"]
    S13["(13) Save setup.completed_at, register with relay in background, go to PAIR-01"]
    X1(["End: show error, allow retry"])
  end
  U1 --> S2
  S2 -- "Keychain error (E1)" --> X1
  S2 --> U3 --> D4
  D4 -- "Yes" --> S6
  D4 -- "No (E2)" --> U5
  D4 -- "iOS" --> S7
  U5 -- "Not now or move failed" --> S6
  U5 -- "Moved, the app reopens" --> U1
  S6 --> S7 --> U8
  U8 -- "Allow or deny (E3)" --> S9
  S9 -- "macOS 13 to 14" --> S11
  S9 --> U10
  U10 -- "Allow or deny (E4)" --> S11
  S11 --> U12 --> S13
```

| Step | Actor | Component | Description | Exceptions / Notes |
|------|----------|-----------|-------|--------------------|
| 1 | User | M-APP / I-APP | Opens HandLive (Mac: Finder, Launchpad; iOS/iPadOS: Home Screen).<br>The app reads `setup.completed_at`: set → normal startup; not set → initial setup.<br>The Mac creates the menu bar icon (`MenuBarExtra`, menu style) right at launch with the status "Not paired" and opens the setup window. | Setup interrupted or the Mac just moved the app → start over; each step skips itself if already satisfied. |
| 2 | System | M-APP / I-APP, OS (Keychain) | No `setup.started_at` (fresh install) → delete Keychain items left over from a previous install (service `app.handlive.keys` — iOS/macOS keep the Keychain after the app is removed), create `ik_sig`, `ik_dh` (CryptoKit) and a 32-byte `db_key` (`SecRandomCopyBytes`) and store them in the Keychain (API 1); create `handlive.sqlite` with the 0.9.3 schema (iOS/iPadOS: in the App Group container); write `setup.started_at`.<br>`setup.started_at` already set → load the existing keys.<br>Compute `device_id` (0.2).<br>Show the welcome screen (field 1). | Error → E1. |
| 3 | User | M-APP / I-APP | Reads the introduction; Mac: keeps or clears "Open HandLive at Login" (field 3) and "Show HandLive in Menu Bar" (field 16); chooses "Get Started". |  |
| 4 | System | M-APP | Mac: checks that `Bundle.main.bundleURL` is under `/Applications/`; a path containing `/AppTranslocation/` → `translocated` (field 4). iOS/iPadOS → step 7. | Not under `/Applications/` → E2, step 5. |
| 5 | User | M-APP | Chooses "Move" or "Not Now" (field 5). "Move": M-APP copies the bundle to `/Applications`, opens the new copy and quits the old one (API 2); the new copy starts again from step 1. | `translocated` or no write permission → "Drag HandLive into the Applications folder in Finder, then open it again." (E2). |
| 6 | System | M-APP, OS | Field 3 = `true` → `SMAppService.mainApp.register()` (API 3); read `status` for field 6.<br>Write field 16 to `mac.menu_bar_extra`: `true` → the menu bar icon shows and the app is `.accessory`; `false` → the app is `.regular` with a Dock icon.<br>The app switches to `.regular` when the Messages or Camera Preview window opens and back to `.accessory` when they close, if the menu bar icon is showing.<br>Opening HandLive again while it is running (Finder, Launchpad) shows the main window. | `.requiresApproval` or an error → E5. |
| 7 | System | M-APP / I-APP | Shows the explanation "Notifications tell you about new SMS messages and incoming calls; incoming calls are Time Sensitive so they arrive on time", then `requestAuthorization(options: [.alert, .sound, .badge])` (API 4); registers the notification categories defined by SMS-02 and CALL-01. | Already decided earlier → do not ask again, only read the state. |
| 8 | User | OS | Chooses "Allow" or "Don't Allow". | Denied → E3. |
| 9 | System | M-APP / I-APP | iOS/iPadOS and macOS 15+: show the local network explanation ("HandLive looks for your Android phone on your Wi-Fi network to connect to it directly."), then run `NWBrowser` for `_handlive._tcp` (API 5) — the first Bonjour browse makes the system show its dialog. macOS 13–14 have no such permission → field 9 = `not_required`, go to step 11. |  |
| 10 | User | OS | Chooses "Allow" or "Don't Allow" in the system dialog that asks to let HandLive find and connect to devices on the local network. | Denied → E4. |
| 11 | System | M-APP / I-APP | Mac, macOS 15.4+: read `NSPasteboard.general.accessBehavior` (API 6); `.ask` or `.alwaysDeny` → show instructions (field 12, E6). iOS/iPadOS: show the platform limits (field 11). |  |
| 12 | User | M-APP / I-APP | Reads the instructions, optionally chooses "Open Settings" (field 13), then chooses "Continue". |  |
| 13 | System | M-APP / I-APP → R-API | Writes `setup.completed_at`. If `relay.enabled = true` and the internet is available: run `POST /v1/devices` in the background (CONN-03 API 1); iOS/iPadOS: `registerForRemoteNotifications()`, then `PUT /v1/devices/me/push-token` (CONN-04 API 1). Go to PAIR-01 step 1 ("Add Phone…"). | Relay error → E7. |

### 1.3.5 API/service specification

**List of calls**

| # | API/service | Channel | Direction | Used in step |
|---|-------------|------|-------|-------------|
| 1 | Create keys and store them in the Keychain: CryptoKit `Curve25519.Signing.PrivateKey()`, `Curve25519.KeyAgreement.PrivateKey()`, `SecRandomCopyBytes`, `SecItemAdd`, `SecItemDelete` | Local | — | 2 |
| 2 | Move the app to `/Applications`: `FileManager.copyItem`, `NSWorkspace.openApplication` | Local | — | 5 |
| 3 | `SMAppService.mainApp.register()`, `status`, `SMAppService.openSystemSettingsLoginItems()` | Local | — | 6 |
| 4 | `UNUserNotificationCenter.requestAuthorization`, `getNotificationSettings` | Local | — | 7, 8 |
| 5 | `NWBrowser` — local network permission prompt | LAN multicast | — | 9, 10 |
| 6 | `NSPasteboard.accessBehavior` | Local | — | 11 |
| 7 | `POST /v1/devices` | Relay REST | Device → R-API | 13 |
| 8 | `UIApplication.registerForRemoteNotifications`, `PUT /v1/devices/me/push-token` | APNs, relay REST | I-APP → R-API | 13 |

#### API 1 — Create keys and store them in the Keychain

- **URL:** N/A
- **Method:** `Curve25519.Signing.PrivateKey()`, `Curve25519.KeyAgreement.PrivateKey()`,
  `SecRandomCopyBytes(kSecRandomDefault, 32, &bytes)`; `SecItemAdd`, `SecItemCopyMatching`,
  `SecItemDelete`.
- **Request — Keychain item attributes:**

| Attribute | Value |
|-----------|---------|
| `kSecClass` | `kSecClassGenericPassword` |
| `kSecAttrService` | `app.handlive.keys` |
| `kSecAttrAccount` | `ik_sig`, `ik_dh`, `db_key` (`PRK` uses account = `pair_id`, PAIR-01) |
| `kSecValueData` | the private key's 32-byte `rawRepresentation`; `db_key` is 32 random bytes |
| `kSecAttrAccessible` | `kSecAttrAccessibleWhenUnlockedThisDeviceOnly` |
| `kSecAttrAccessGroup` | iOS/iPadOS: the group shared with I-NSE; Mac: the app's default group |
| `kSecUseDataProtectionKeychain` | Mac: `true` (needed to use the `WhenUnlockedThisDeviceOnly` protection class on macOS) |

- **Response:** `errSecSuccess`; `errSecDuplicateItem` → read the existing item (setup is running
  again); `errSecInteractionNotAllowed` or `errSecMissingEntitlement` → E1.
- **Example:** `ik_sig_pub` = `7Kx9vQ2mTn4pL8rWz1YcHd6fJb3gSa5eUo0iVtNkQxA` → `device_id` =
  `5b1f8c2e-9a4d-8e6f-a1b2-c3d4e5f60718` (the Mac in the PAIR-01 example).
- **Business logic:**
  1. Fresh install (no `setup.started_at`) → `SecItemDelete` for the service `app.handlive.keys`
     before creating anything: the iOS/macOS Keychain keeps items after the app is removed; without
     this cleanup a reinstall would keep the old `device_id` and the `PRK` of pairs that no longer
     exist, contrary to 0.2.
  2. The keys are created while the app is in the foreground (the device is unlocked), so
     `WhenUnlockedThisDeviceOnly` does not get in the way; error → E1.
  3. `device_id` = UUIDv8(SHA-256(`ik_sig_pub`)) (0.2), recomputed at every launch and never stored
     separately.
  4. Open `handlive.sqlite` with `db_key` (Query), then run the migration that creates the 0.9.3
     schema; M-APP and I-APP load the keys into memory at launch (0.6.1).

#### API 2 — Move the app to `/Applications` (Mac)

- **URL:** N/A
- **Method:**
  `FileManager.default.copyItem(at: Bundle.main.bundleURL, to: URL(fileURLWithPath: "/Applications/HandLive.app"))`;
  `NSWorkspace.shared.openApplication(at:configuration:completionHandler:)`; `NSApp.terminate(nil)`;
  in the new copy: `FileManager.default.trashItem(at:resultingItemURL:)` for the old copy.
- **Request:** source = the running bundle; destination = `/Applications/HandLive.app`;
  `NSWorkspace.OpenConfiguration.arguments` carries the path of the old copy.
- **Response:** the new copy runs; `NSFileWriteNoPermissionError`, a destination that already exists
  or a source under App Translocation → E2.
- **Example:** `~/Downloads/HandLive.app` → `/Applications/HandLive.app`; the new copy moves the old
  one to the Trash, then starts again from step 1.
- **Business logic:**
  1. The destination already holds another copy: ask whether to replace it; if the copy in
     `/Applications` is newer, open that one and quit the current one.
  2. Under App Translocation (the bundle runs from a temporary read-only location whose path
     contains `/AppTranslocation/`): the original location to copy from is unknown → only give
     drag-and-drop instructions (E2).
  3. The user chooses "Not Now": remind them when they turn on the camera (CAM-01 step 2).
  4. Register the login item (API 3) after this step so that the item points to the copy in
     `/Applications`.

#### API 3 — `SMAppService` (Open at Login, Mac)

- **URL:** N/A
- **Method:** `try SMAppService.mainApp.register()`; `SMAppService.mainApp.status`;
  `SMAppService.openSystemSettingsLoginItems()`; to turn it off: `try SMAppService.mainApp.unregister()`.
- **Request:** no parameters.
- **Response:** `status` ∈ {`.enabled`, `.requiresApproval`, `.notRegistered`, `.notFound` };
  `register()` throws when the user or an MDM policy blocks it.
- **Example:** `register()` succeeds → `status = .enabled`, field 6 = `enabled`; macOS shows a
  system notification about the new login item.
- **Business logic:**
  1. Register only when the user keeps the field 3 choice; never turn it on silently.
  2. The actual state is always read from `status`; no separate settings key is stored; SET-02 field
     22 uses the same API.
  3. `.requiresApproval` → a button that calls `openSystemSettingsLoginItems()` (E5).

#### API 4 — `UNUserNotificationCenter` (notification permission)

- **URL:** N/A
- **Method:**
  `UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge])`;
  `getNotificationSettings()` reads `authorizationStatus`, `timeSensitiveSetting`;
  `setNotificationCategories(_:)`.
- **Request:** options `[.alert, .sound, .badge]`. The time-sensitive level has no option of its own
  to request: it needs the entitlement `com.apple.developer.usernotifications.time-sensitive`, and
  each notification sets `interruptionLevel = .timeSensitive` (local notifications on the Mac) or
  `interruption-level: time-sensitive` in APNs (CONN-04 API 4).
- **Response:** `granted` (bool), `error`; `authorizationStatus` ∈ {`.notDetermined`, `.denied`,
  `.authorized`, `.provisional`, `.ephemeral` }; `timeSensitiveSetting` ∈ {`.enabled`, `.disabled`,
  `.notSupported` }.
- **Example:** `granted = true`, `timeSensitiveSetting = .enabled` → field 7 = `allowed`, field 8 =
  `enabled`.
- **Business logic:**
  1. Ask once; `.denied` → never ask again (the system would not show the dialog anymore), only give
     instructions: iOS/iPadOS open `UIApplication.openNotificationSettingsURLString`; the Mac points
     to System Settings › Notifications › HandLive.
  2. Do not use `.provisional` (call notifications must show immediately) and do not request
     `.criticalAlert`.
  3. iOS/iPadOS: a device token can still be obtained at step 13 when the user denies, but alerts are
     not shown (E3).

#### API 5 — `NWBrowser` (local network permission prompt)

- **URL:** N/A (mDNS `224.0.0.251:5353`, `ff02::fb`)
- **Method:**
  `NWBrowser(for: .bonjourWithTXTRecord(type: "_handlive._tcp", domain: nil), using: .tcp)`;
  `stateUpdateHandler`, `browseResultsChangedHandler`; `start(queue:)`, `cancel()`.
- **Request:** no parameters besides the service type; Info.plist must have
  `NSLocalNetworkUsageDescription` and `_handlive._tcp` in `NSBonjourServices` (missing → the browse
  fails with `NoAuth`, −65555).
- **Response:** the state `.ready`, `.waiting(NWError.dns(-65570))` (`kDNSServiceErr_PolicyDenied`
  — the user denied) or `.failed(error)`; the set of browse results.
- **Example:** the user denies → `.waiting(.dns(-65570))` → field 9 = `denied`.
- **Business logic:**
  1. The system asks only once per installation; there is no API to read the permission state
     directly.
  2. Inferring the state: `.waiting` with `PolicyDenied` → `denied`; browse results found, or
     `.ready` with no error after the user closes the dialog (the app becomes active again) →
     `allowed`; otherwise `unknown` (handled later by CONN-01 E8).
  3. Stop the browser (`cancel()`) when leaving the step; PAIR-01 and CONN-01 run their own
     browsers.
  4. Instructions when `denied`: iOS/iPadOS — Settings › Privacy & Security › Local Network › turn
     on HandLive; Mac — System Settings › Privacy & Security › Local Network.

#### API 6 — `NSPasteboard.accessBehavior` (Mac)

- **URL:** N/A
- **Method:** `NSPasteboard.general.accessBehavior` (inside `if #available(macOS 15.4, *)`).
- **Request:** none.
- **Response:** `NSPasteboard.AccessBehavior` ∈ {`.default`, `.ask`, `.alwaysAllow`, `.alwaysDeny`}.
- **Example:** `.ask` → field 10 = `ask`, field 12: "To send the clipboard automatically, open System Settings › Privacy & Security › Paste from Other Apps and choose Always Allow for HandLive."
- **Business logic (C10):**
  1. Apple has no API to request "Always Allow": only give instructions and open
     `x-apple.systempreferences:com.apple.preference.security`.
  2. `.default` or `.alwaysAllow` → show nothing; before macOS 15.4 → `not_applicable`.
  3. Read it again every time M-APP is activated to update field 10; CLIP-02 only reads the content
     when `changeCount` changes.

#### API 7 — `POST /v1/devices`

Specified in CONN-03 API 1. Called at step 13 when `relay.enabled = true`; idempotent (upsert).
Error → E7, retry in the background when a network is available.

#### API 8 — Push registration (iOS/iPadOS)

`UIApplication.shared.registerForRemoteNotifications()` →
`application(_:didRegisterForRemoteNotificationsWithDeviceToken:)` → `PUT /v1/devices/me/push-token`
with `provider = apns` (development builds: `apns_sandbox`) and `topic` = the bundle id of I-APP.
Specified in CONN-04 API 1 and step 2; runs after API 7. The Mac does not register for push (0.4.4).

#### Query

```text
# [Design] UserDefaults — Mac: UserDefaults.standard; iOS/iPadOS: UserDefaults(suiteName: "group.app.handlive")
defaults.register(defaults: ["feature.clipboard": true, "feature.sms": true, "feature.call": true,
                             "relay.enabled": true, "clip.send_images": true, "clip.block_sensitive": true,
                             "clip.auto_clear_s": 60, "sms.notify": true, "sms.preview": true,
                             "call.notify": true])                              # at every launch: the 0.9.5 defaults
# The Mac also registers: feature.call_audio = false, call_audio.allow_opus_fallback = true,
# call_audio.phone_bt_address = "", feature.camera = false, cam.default_camera = "front",
# cam.default_quality = "auto", cam.usb_boost = true, cam.usb_wizard_dismissed = false
# (and call.ringtone = true if that key is added to 0.9.5)
defaults.object(forKey: "setup.completed_at") as? Int64                         # step 1
defaults.object(forKey: "setup.started_at") as? Int64                           # step 2: nil → fresh install
defaults.set(now, forKey: "setup.started_at")                                   # step 2
defaults.bool(forKey: "relay.enabled")                                          # step 13
defaults.set(now, forKey: "setup.completed_at")                                 # step 13
```

```text
# [Design] Keychain, service "app.handlive.keys"
SecItemDelete([kSecClass: kSecClassGenericPassword, kSecAttrService: "app.handlive.keys"])   # step 2, fresh install only
SecItemAdd([kSecClass: kSecClassGenericPassword, kSecAttrService: "app.handlive.keys",
            kSecAttrAccount: "ik_sig", kSecValueData: <32 bytes>,
            kSecAttrAccessible: kSecAttrAccessibleWhenUnlockedThisDeviceOnly])               # step 2; likewise "ik_dh", "db_key"
SecItemCopyMatching([... kSecAttrAccount: "db_key", kSecReturnData: true])                   # at every launch
```

```sql
-- [Design] Mac/iOS, step 2: open handlive.sqlite with the raw 32-byte key (SQLCipher via GRDB), then run the 0.9.3 schema
PRAGMA key = "x'<64 ký tự hex của db_key>'";   -- placeholder: the 64 hex characters of db_key

-- [Design] Mac/iOS, step 13: confirm that there is no active pair yet before opening PAIR-01
SELECT COUNT(*) AS active_pairs FROM paired_device WHERE revoked_at IS NULL;
```
