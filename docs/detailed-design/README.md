English | [Tiếng Việt](README.vi.md)

# HandLive — Detailed design documentation

| Item | Content |
|-----|----------|
| Version | 1.2 (version for implementation; design system aligned with Apple HIG; multilingual en/vi — C20) |
| Date | 2026-09-25 |
| Sources | `plans/20260924-definitive-architecture/plan.md`, `docs/system-architecture.md`, `docs/code-standards.md`; UI: HandLive design system (Apple HIG) https://claude.ai/artifact/2rsmYxBjxXrd12FByTd9vT |
| Scope | Android (hub), macOS, iOS/iPadOS, Cloud relay — Phase 1 to Phase 5 |

## 1. Document structure

| File | Section | Content |
|------|-----|----------|
| [`00-common-specs.md`](00-common-specs.md) | 0 | Common specifications: components, identifiers, data types, message frames, security, message type catalog, error codes, data model, constants |
| [`01-setup-settings.md`](01-setup-settings.md) | 1 | Setup and settings function group |
| [`02-pairing.md`](02-pairing.md) | 2 | Pairing and device management function group |
| [`03-connectivity.md`](03-connectivity.md) | 3 | Connectivity function group |
| [`04-clipboard.md`](04-clipboard.md) | 4 | Clipboard sync function group |
| [`05-sms.md`](05-sms.md) | 5 | SMS messaging function group |
| [`06-call-control.md`](06-call-control.md) | 6 | Call information and control function group |
| [`07-call-audio.md`](07-call-audio.md) | 7 | Call audio function group |
| [`08-camera-mic.md`](08-camera-mic.md) | 8 | Camera and microphone function group |

Each function group is one section. Each leaf function has exactly five subsections following the
template in section 3.

Every file exists in two versions with the same structure (C20): English `X.md` is the canonical
version, Vietnamese `X.vi.md`; a change to one version changes the other in the same commit
(`tools/docs/check_bilingual_docs.py`).

## 2. Function catalog

| ID | Leaf function | Group | Phase | Platform | Primary actor |
|----|--------------|------|-----------|----------|----------------|
| SET-01 | Initial setup and permissions on Android | 1 | P1+ | Android | User |
| SET-02 | Turn features and sync options on or off | 1 | P1+ | Android, Mac, iOS | User |
| SET-03 | Initial setup on Mac and iOS | 1 | P1+ | Mac, iOS | User |
| PAIR-01 | Pair devices with a QR code (fallback: PIN) | 2 | P1 (via relay: P2) | Android, Mac, iOS | User |
| PAIR-02 | View the device list and connection status | 2 | P1 | Android, Mac, iOS | User |
| PAIR-03 | Unpair a device (locally and remotely) | 2 | P1 (remote: P2) | Android, Mac, iOS, Relay | User |
| CONN-01 | Automatic discovery and connection on the LAN | 3 | P1 | Mac, iOS, Android | System |
| CONN-02 | Keep the connection alive and reconnect automatically | 3 | P1 | Mac, iOS, Android | System |
| CONN-03 | Connect through the relay outside the LAN | 3 | P2 | Mac, iOS, Android, Relay | System |
| CONN-04 | Push registration and device wake-up | 3 | P2 | Android, iOS, Relay | System |
| CLIP-01 | Send clipboard text from Android to Mac/iOS | 4 | P1 | Android → Mac, iOS | User |
| CLIP-02 | Send clipboard text from Mac to Android | 4 | P1 | Mac → Android | User |
| CLIP-03 | Sync clipboard images between Android and Mac | 4 | P1 | Android ↔ Mac | User |
| CLIP-04 | Clipboard sync on iPhone/iPad | 4 | P2 | iOS ↔ Android | User |
| CLIP-05 | Automatically clear the received clipboard | 4 | P1 | Mac, iOS, Android | System |
| SMS-01 | Sync SMS conversations and history | 5 | P2 | Android → Mac, iOS | System |
| SMS-02 | Receive new SMS notifications | 5 | P2 | Android → Mac, iOS | User |
| SMS-03 | View conversations and load older messages | 5 | P2 | Mac, iOS | User |
| SMS-04 | Send and reply to SMS from Mac/iOS | 5 | P2 | Mac, iOS → Android | User |
| SMS-05 | Sync read status | 5 | P2 | Android → Mac, iOS | System |
| CALL-01 | Incoming call notification on Mac/iOS | 6 | P3 | Android → Mac, iOS | User, Caller |
| CALL-02 | Answer or reject an incoming call | 6 | P3 | Mac (answer, reject), iOS (reject) → Android | User |
| CALL-03 | Control an ongoing call | 6 | P3 (hold, DTMF, mute: P4 via HFP) | Mac → Android | User |
| CALL-04 | Sync the call log and missed calls | 6 | P3 | Android → Mac, iOS | System |
| AUDIO-01 | Turn on calls on the Mac and accept the disclosure | 7 | P4 | Mac, Android | User |
| AUDIO-02 | Listen and talk on calls on the Mac over Bluetooth HFP | 7 | P4 | Mac ↔ Android | User |
| AUDIO-03 | Move call audio between the Mac and the phone | 7 | P4 | Mac, Android | User |
| AUDIO-04 | Call audio over Opus/WebSocket (fallback, requires Shizuku) | 7 | P4 | Mac ↔ Android | User |
| CAM-01 | Install the virtual camera and virtual microphone on the Mac | 8 | P5 | Mac | User |
| CAM-02 | Start and stop camera/microphone streaming | 8 | P5 | Mac ↔ Android | User, Meeting app |
| CAM-03 | Control the camera stream | 8 | P5 | Mac → Android | User |
| CAM-04 | Automatic USB boost when a cable is plugged in | 8 | P5 | Mac, Android | System |
| CAM-05 | Adaptive quality adjustment | 8 | P5 | Android, Mac | System |

## 3. Presentation conventions

### 3.1 Leaf function template

Each leaf function has exactly five subsections, numbered `<group>.<function>.<1..5>`:

1. **General information** — a two-column table with exactly these rows: Name, Description, Actors,
   Preconditions, Postconditions, Exceptions, Special requirements. Exceptions are numbered `E1`,
   `E2` … so the business flow can refer to them.
2. **Screens** — `N/A` when there is no approved wireframe yet. At this version **no wireframe has
   been approved**, so every function says `N/A`.
3. **Component details** — a table: `#`, Field, Data type, Input/Output, Initial value,
   Description. Only fields the user enters or the system returns/displays; data types and
   Input/Output values follow 0.3.
4. **Business flow** — a two-column Mermaid flowchart, `User` and `System`, plus a step table:
   Step, Actor, Component (codes per 0.1), Description, Exceptions/Notes. The step numbers in the
   chart match the step numbers in the table.
5. **API/service specification** — the list of calls, then for each call: URL, Method, Request,
   Response, Example, Business logic; Query comes last. With no calls, write `N/A`.

Template labels in the two versions (the validator reads exactly these labels):

| Vietnamese (`X.vi.md`) | English (`X.md`) |
|------------------------|--------------------|
| Thông tin chung · Màn hình · Mô tả chi tiết các thành phần · Luồng nghiệp vụ · Đặc tả API/service | General information · Screens · Component details · Business flow · API/service specification |
| Tên, Mô tả, Tác nhân, Điều kiện trước, Điều kiện sau, Ngoại lệ, Yêu cầu đặc biệt | Name, Description, Actors, Preconditions, Postconditions, Exceptions, Special requirements |
| `#`, Trường, Kiểu dữ liệu, Input/Output, Giá trị khởi tạo, Mô tả | `#`, Field, Data type, Input/Output, Initial value, Description |
| Bước, Tác nhân, Thành phần, Mô tả, Ngoại lệ / Ghi chú | Step, Actor, Component, Description, Exceptions / Notes |
| "N/A — chưa có wireframe được duyệt." | "N/A — no approved wireframe yet." |
| Làn `ND["Người dùng"]`, `HT["Hệ thống"]` | Lanes `ND["User"]`, `HT["System"]` |
| URL, Method, Request, Response, Ví dụ, Logic nghiệp vụ, Query | URL, Method, Request, Response, Example, Business logic, Query |
| Nhãn `[Thiết kế]` trong SQL | Label `[Design]` in SQL |

### 3.2 Writing URL and Method

| Call type | URL | Method |
|--------------|-----|--------|
| Device ↔ device envelope | `wss://{android_host}:{port}/v1/ctl` (LAN); via relay: `wss://{RELAY_HOST}/v1/relay` with the `to`/`from` wrapper | `WS <type>/<op>`, e.g. `WS sms/send` |
| Binary frame | `wss://{android_host}:{port}/v1/stream/<channel>` | `WS binary HL` |
| Relay REST | `https://{RELAY_HOST}/v1/...` | `GET`, `POST`, `PUT`, `DELETE` |
| Push | `https://fcm.googleapis.com/v1/projects/{project}/messages:send` or `https://api.push.apple.com/3/device/{token}` (called by the relay) | `POST` |
| Operating system service | `N/A` | API name, e.g. `SmsManager.sendMultipartTextMessage` |

An envelope's Request/Response describes the `data` part of the payload plaintext; the outer
envelope and the `ack` follow 0.5.1 and are not repeated.

### 3.3 Query

The repo has no source code yet (2026-09-24), so **no query could be extracted from code**. The
queries in the documents are designs, labeled `[Design]`, based on the schema in 0.9. Queries
against Android ContentProviders are written as
`ContentResolver.query(uri, projection, selection, args, sortOrder)`.

### 3.4 Flowcharts

- `flowchart TB`; declare `subgraph ND["User"]` before `subgraph HT["System"]` so the User column
  is on the left.
- User nodes `U<n>`, system nodes `S<n>`, decision nodes `D<n>`; a label starts with the step
  number in parentheses, e.g. `"(4) Encrypt and send"`. Do not write `"4. …"`: Mermaid 11 reads
  `4. ` at the start of a label as a markdown list and renders an error.
- Exception branches carry the code `E<k>` on the edge.
- At most about 15 nodes; details go into the step table.

### 3.5 UI wording

- Multilingual (C20, 0.12): English is the default language, Vietnamese the second language. The
  English version of a document (`X.md`) contains the English strings, the Vietnamese version
  (`X.vi.md`) the Vietnamese strings. Every string has a stable key in the catalog
  `shared/strings/ui-strings.json`; documents and catalog must match — to change wording, change
  the documents first and the catalog after; code never hard-codes wording.
- English follows Apple's English style: title-style capitalization for buttons, menu items, window
  titles and tabs; sentence-style capitalization for descriptions, alert messages, notifications,
  status. Vietnamese capitalizes only the first word, following the rules below.

- User-facing strings follow the HandLive design system (Apple HIG), section "Writing":
  https://claude.ai/artifact/2rsmYxBjxXrd12FByTd9vT
- Vietnamese tone marks follow Apple's Vietnamese localization: hóa, xóa, hủy, tùy, thủy, khỏe (not
  hoá, xoá, huỷ, tuỳ). All documents switched to this style on 2026-09-25.
- UI terminology: "bảng nhớ tạm" (clipboard; the word "clipboard" in the documents is only a
  technical term), "kết nối qua Internet" (internet connection, never "relay"), "cùng mạng Wi-Fi"
  (same Wi-Fi network; LAN only in short labels); "Hủy" (Cancel) is always the cancel button;
  buttons start with a verb and capitalize only the first word.
- A permission primer (the explanation screen shown before the permission dialog) has a single
  "Continue" button ("Tiếp tục"); only disclosures that require legal consent (AUDIO-01,
  Accessibility) offer two choices.

## 4. Scope

**In scope:** the functions in section 2. Each Mac/iPhone/iPad is paired with one Android phone at a
time; each phone pairs with at most 8 devices.

**Out of scope for this version:**
- MMS, RCS, group messages with images.
- Outgoing calls (placing a call) from Mac/iOS.
- Clipboard history (instant transfer only).
- Camera streaming over the relay (LAN or USB only).
- Full contacts sync (only the display names attached to conversations and calls).
- Windows/Linux clients.

## 5. Adjustments and decisions

This section lists the points where the detailed design clarifies or departs from the original
architecture, with the reasons and evidence. Points that touch an agreed decision are not changed
silently: the project owner decided each of them on 2026-09-24 (C12–C15).

| # | Content | Type | Status |
|---|----------|------|------------|
| C1 | The envelope `type` keeps the agreed set; the fine-grained operation sits in the `op` field of the encrypted payload, so the relay only sees the message group. Two groups are added: `session` (session handshake) and `camera` (Phase 5). Responses use `type = ack`. | Clarification | Applied |
| C2 | XChaCha20-Poly1305 on Apple: CryptoKit has no XChaCha20 → in-house HChaCha20 + `ChaChaPoly`, with cross-platform test vectors. | Clarification | Applied |
| C3 | The Keychain keeps `WhenUnlockedThisDeviceOnly`; the app loads `PRK` into memory at launch so it can reconnect while the screen is locked. Push notifications on a locked iPhone show generic content. | Clarification | Applied |
| C4 | Self-certifying `device_id` (UUIDv8 from the SHA-256 of the signing key) so the relay can prevent identity spoofing without accounts. | Addition | Applied |
| C5 | The relay additionally uses Redis 7 (presence, pub/sub) to stay true to the "stateless to scale horizontally" principle. | Addition | Applied |
| C6 | mDNS hints change every hour and the instance name is random, so strangers on the LAN cannot track the phone. | Addition | Applied |
| C7 | iOS does not use PushKit VoIP (architecture §3.3): since iOS 13 every VoIP push must report a call to CallKit, and HandLive is not a VoIP app. Replaced by APNs alerts (`time-sensitive` for incoming calls) + a Notification Service Extension that decrypts the content. | Platform requirement | Applied |
| C8 | The virtual microphone uses BlackHole's loopback model (verified in the BlackHole source code): M-MIC has one hidden output device (`kAudioDevicePropertyIsHidden`) and one visible input device, "HandLive Microphone", sharing a ring buffer inside the driver process; M-APP plays PCM into the hidden device like any ordinary CoreAudio client.<br>Replaces POSIX shm (architecture §10.3, `docs/system-architecture.md` §8): the driver runs as user `_coreaudiod`, so a shm region created by the app would need 0666 permissions, and then every local process could read/write the microphone audio. | Evidence-based change | Applied |
| C9 | Microphone driver installation: a signed + notarized PKG embedded in the app, opened with Installer (Installer asks for administrator rights itself); a `postinstall` script runs `killall coreaudiod` as root.<br>No privileged helper is needed: `SMJobBless` is deprecated since macOS 13; `launchctl kickstart -k` is blocked for system processes since macOS 14.4.<br>True to the spirit of D7 ("run embedded PKG"). | Clarification of D7 | Applied |
| C10 | Paste permission on macOS (preview since macOS 15.4, not on by default in macOS 26): if `NSPasteboard.accessBehavior` is `.ask` or `.alwaysDeny`, onboarding points the user to System Settings › Privacy & Security › Paste from Other Apps; Apple has no API to request "Always Allow".<br>Changes are detected with `changeCount` before the content is read. | Addition | Applied |
| C11 | Camera Extension: updating the extension may require a restart (an Apple bug reported since macOS 14.5); the app must run from `/Applications` to be able to activate the extension.<br>Risk R6 about Discord only holds for the old DAL plug-ins (disabled since macOS 14.1) and does not apply to CMIOExtension.<br>The app that pushes frames into the sink stream also declares the camera permission to be safe (no Apple documentation confirms whether it is needed). | Addition | Applied |
| C12 | **Call control does not use `InCallService`.** Evidence (AOSP Telecom source, android10 → main): the `CALL_COMPANION_APP` permission does not make Telecom bind the app's `InCallService`; the only path is `MANAGE_ONGOING_CALLS` (Android 12+) through the CompanionDeviceManager "watch" role.<br>**Decision:** over Wi-Fi use public APIs — state and incoming number (`READ_PHONE_STATE`, `READ_CALL_LOG`), answer (`TelecomManager.acceptRingingCall`), reject/end (`TelecomManager.endCall`, permission `ANSWER_PHONE_CALLS`; both methods are deprecated since API 29 but still work); hold, DTMF and mute only through HFP commands when the Mac is connected over Bluetooth. | Project owner's decision | Applied |
| C13 | **Keep D1/D3 (Opus/WS + Shizuku).** Evidence: an ordinary app cannot capture call audio (`VOICE_CALL`/`VOICE_UPLINK`/`VOICE_DOWNLINK` require `CAPTURE_AUDIO_OUTPUT`) and there is no public API to inject audio into a call.<br>Through Shizuku (shell uid): Android 10 cannot capture; Android 11+ captures on some devices (Pixel 8/9 yes, Galaxy S22 Ultra on Android 14 records silence); voice injection only has `AudioManager.getCallUplinkInjectionAudioTrack()` (Android 13, `@SystemApi`, not verified by anyone); Shizuku must be restarted after every reboot. `BluetoothHeadsetClient` is an API of the HF role and does not serve a phone in the AG role — the AG function is handled by Android's stock Bluetooth stack.<br>**Decision:** keep Opus/WS as the official fallback path (AUDIO-04), with the documentation stating the limits per Android version and per device; Shizuku is used for this path. | Project owner's decision | Applied, with a feasibility warning |
| C14 | **HFP audio encryption.** Evidence: for cellular calls, SCO audio goes straight modem ↔ Bluetooth chip and the app never touches individual frames, so application-layer encryption is not possible.<br>**Decision:** the HFP path relies on the operating system's Bluetooth link encryption; the residual KNOB/BIAS risk is recorded and disclosed in AUDIO-01.<br>The Opus/WS path is still encrypted in two layers (TLS + E2E). | Project owner's decision | Applied |
| C15 | **Keep D4 (Accessibility by default).** Evidence: Accessibility is not exempt from the background clipboard-read block since Android 10; what works is Accessibility detecting the copy action and then opening a transparent `ClipboardReadActivity` to read (like ClipRelay); Android 12+ shows a toast on every read.<br>Google Play policy forbids using the Accessibility API to bypass Android's privacy controls → risk of rejection.<br>**Decision:** automatic sending through Accessibility is the default, with a disclosure and explicit consent; the fallback is manual sending (a button in the notification, a Quick Settings tile, the Share menu) instead of Notification Listener (Notification Listener cannot read the clipboard). | Project owner's decision | Applied |
| C16 | "Remove Device from Server" only deregisters from the relay and keeps every pair (still usable over LAN/USB); only "Delete All HandLive Data" revokes the pairs and notifies the peer — `DELETE /v1/devices/me?revoke_pairs=false | true`. A peer that sees the pair disappear from the relay just switches to the LAN and does not unpair. | Design decision (SET-02) | Applied |
| C17 | Automatic clipboard clearing on Android: the AOSP source shows that `OnPrimaryClipChangedListener` is not called while the app is in the background.<br>Clear only when the app can read the `ClipDescription` of the very clip HandLive wrote (while it has focus, or by briefly taking focus with `ClipboardReadActivity` while Accessibility is running); never infer "still untouched" from the absence of a copy signal, so the user's content is never cleared by mistake. | Evidence-based change | Applied |
| C18 | New SMS messages are detected with a `ContentObserver` on the provider, without `RECEIVE_SMS` — one fewer permission restricted by Google Play. | Change | Applied |
| C19 | **Alignment with the Apple HIG design system** (approved by the project owner 2026-09-25): permission primers only have "Continue" (SET-01, SET-03); Mac: the menu bar icon opens a menu, not a popover (CONN-01), a "Show HandLive in Menu Bar" setting (`mac.menu_bar_extra`) and switching the activation policy `.accessory` ↔ `.regular` when a window opens (SET-02, SET-03); an incoming call on the Mac comes with an `INStartCallIntent` communication notification, and no panel is shown while a Focus is on — the floating panel is a deliberate deviation from the HIG (CALL-01); the call log lives in the sidebar of the Messages window (CALL-04); conversation rows only carry an unread dot (SMS-03); clipboard errors are reported in place, not pushed as notifications (CLIP-01…03); Android notification channels `clipboard`, `permission`; the Mac declares `NSMicrophoneUsageDescription`, `NSFocusStatusUsageDescription` (SET-03, AUDIO-01, CALL-01); the unpair dialog is an alert (Mac) and an action sheet (iPhone, Android) (PAIR-03); wording per 3.5. | Project owner's decision | Applied |
| C20 | **Multilingual product and bilingual documentation** (decided by the project owner 2026-09-25): English (`en`) is the default, source and fallback language; Vietnamese (`vi`) is the second language. The UI follows the system's preferred languages; a separate language for HandLive is chosen with the operating system's per-app language setting (Android 13+, iOS/iPadOS, macOS) and with SET-02 field 32 on Android 10–12.<br>Every UI string has a stable key in the catalog `shared/strings/ui-strings.json`, from which each platform's resources are generated (0.12); code never hard-codes wording. Messages between devices, the relay and push carry no display text — only codes, keys and parameters; the receiving device displays them in its own language (APNs uses `loc-key`, CONN-04).<br>Bilingual documentation: `X.md` in English (canonical when the two versions differ), `X.vi.md` in Vietnamese, same structure, updated in the same commit. | Project owner's decision | Applied |
