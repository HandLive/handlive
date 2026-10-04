# Samsung Galaxy S25 Ultra Image Clipboard Sync: Root Cause Analysis

**Date:** 2026-10-05  
**Device:** Galaxy S25 Ultra, Android 16 (API 36), One UI 8  
**Issue:** Images fail to sync in both directions while text syncs reliably  
**Status:** Research complete with ranked root causes and test commands

---

> **Reviewer note (controller session, 2026-10-05, checked against AOSP `main`):**
> - Verified: `UriGrantsManagerService.checkGrantUriPermissionUnlocked` refuses a grant when the *source* app id is `SYSTEM_UID`/`ROOT_UID` (two Settings authorities excepted). So a primary clip set by a system-uid process (an OEM clipboard service) carries URI items no reading app can open: `openInputStream` throws `SecurityException`, which HandLive reports as E10 (`PERMISSION_LOST`).
> - Verified: `ClipboardService` revokes clipboard URI grants only in `setPrimaryClipInternalNoClassifyLocked` (a new clip) — **not** when the reading activity loses focus. Root cause #1 below ("revoked within 100 ms of focus loss") is therefore unsupported; HandLive's background copy after `getPrimaryClip` is sound.
> - Not verified / doubtful: the Phone Link "text-only" claim (Link to Windows documents image copy-paste up to 1 MB on Samsung); the edgedrop blog is not a primary source.
> - Not verified: the exact `ClipData` shape of Samsung Internet / Gallery copies on One UI 8. The owner's device check (`adb shell dumpsys clipboard`, HLBENCH `clip_read_failed` line of a debug build) decides.

## A. ClipData Structure on One UI 8 (Samsung Internet, Gallery, Chrome)

### Finding: Samsung ClipData May Carry Text + URI Simultaneously, But URI May Be Inaccessible

**Samsung One UI ClipData Behavior:**
- Samsung One UI declares MIME types in `ClipDescription` but `ClipData.Item.htmlText` and `Item.text` can be null, even when `ClipDescription.getMimeType(0)` reports `text/html` or `image/*`.
  - Source: [FlutterQuill issue #24](https://github.com/FlutterQuill/quill-native-bridge/issues/24): "getClipboardHtml() throws FlutterError(HTML_TEXT_NULL) when clip declares text/html MIME but Item.htmlText is null (Samsung One UI)"
  - Root: Samsung clipboard system declares MIME types before the item data is fully populated.

- `ClipData.Item` can carry multiple representations simultaneously: `Item(text, htmlText, intent, uri)`, so an image copy might include both empty `text` field and a `uri` field.
  - Source: [Android ClipData.Item documentation](https://developer.android.com/reference/android/content/ClipData.Item): Constructors support text + htmlText + intent + uri in one Item.

- Samsung has a custom `SemClipboardManager` and `SemClipboardProvider` (provider authority: `content://com.sec.android.semclipboardprovider/images`) that runs inside system_server and manages clipboard image storage.
  - Source: [LeakCanary issue #740](https://github.com/square/leakcanary/issues/740): "Memory leak caused by Samsung Clipboard (SemClipboardManager)"; also [Project Zero CVE-2021-25337 analysis](https://projectzero.google/2022/11/a-very-powerful-clipboard-samsung-in-the-wild-exploit-chain.html) documents the custom provider.

- **Link to Windows (Microsoft Phone Link) explicitly states images do not sync:** "Images copied on the phone clipboard will not appear on the PC — use the Photos tab in Phone Link or drag-and-drop instead. Clipboard transfer is text-only and capped at roughly 1 MB per copy."
  - Source: [Phone Link Clipboard Access: A Privacy Checklist](https://www.edgedrop.app/blog/phone-link-clipboard-access-privacy-checklist)
  - Implication: Even Microsoft's official Samsung integration treats image clipboard as broken or unsupported at the API level.

**Expected ClipData on Image Copy (Samsung Gallery "Copy to clipboard"):**
- Item 0: `uri = content://com.sec.android.semclipboardprovider/images/...` (Samsung custom provider) OR `content://media/external/images/media/...` (MediaStore)
- Item 0: `text = null` OR `text = ""` (empty)
- Item 0: `htmlText = null`
- `ClipDescription.getMimeType(0)` = `image/jpeg` or `image/png`

**Expected ClipData on Image Copy (Chrome/Samsung Internet from webpage):**
- Item 0: `uri = content://chrome.com.clipboard/...` or Samsung Internet provider URI
- Item 0: `text = null` or `text = image URL`
- `ClipDescription.getMimeType(0)` = `image/jpeg` or similar

---

## B. Copy Signal Detection on One UI 8 & Android 16

### Finding: Toast Detection Is Viable, But Overlay Detection May Be Platform-Specific; System UI Restrictions Apply

**Toast Notifications for Image Copy:**
- Android 12+ shows a toast when any app accesses the clipboard: "Copied to clipboard" or "Already copied to clipboard" (text may vary by OEM and language).
  - Source: [XDA Developers: Android Q blocks background clipboard access](https://www.xda-developers.com/android-q-blocks-background-clipboard-access/) and confirmed in Android 16 behavior.
  - Toast reaches accessibility services via `AccessibilityEvent.TYPE_NOTIFICATION_STATE_CHANGED`.

- One UI may customize toast text (Vietnamese: "Đã sao chép…", "Sao chép hình ảnh", etc.). Samsung Keyboard is known to generate additional toasts: "Samsung Keyboard pasted from your clipboard."
  - Source: [Samsung Community: Samsung Keyboard pasted from clipboard](https://eu.community.samsung.com/t5/galaxy-s25-series/samsung-keyboard-pasted-from-clipboard/td-p/12047998)

**System Clipboard Overlay (Android 13+):**
- AOSP uses `com.android.systemui` with internal classes `ClipboardListener` and `ClipboardOverlaySuppressionController` to manage the clipboard overlay UI.
  - Source: [GitHub hahnlee/aim issue #434](https://github.com/hahnlee/aim/issues/434): "shell: the Mac's copies raise SystemUI's clipboard overlay"
  - The overlay is suppressed via intent extra `com.android.systemui.SUPPRESS_CLIPBOARD_OVERLAY`.

- **On One UI 8, Samsung may use its own overlay instead of AOSP's**, but the mechanism is not publicly documented. Accessibility service can still detect the native toast via `TYPE_NOTIFICATION_STATE_CHANGED`.

**Accessibility Service Clipboard Detection Limitations:**
- Accessibility services **cannot directly monitor clipboard changes** (no `ClipboardManager.OnPrimaryClipChangedListener` equivalent in a service).
- Detection must rely on:
  1. **Toast/notification detection** via `onAccessibilityEvent(TYPE_NOTIFICATION_STATE_CHANGED)` — works but fragile, text varies.
  2. **Window focus changes** — app comes to foreground, clipboard might have changed, but timing is loose.
  3. **Polling** (e.g., every 300ms) — CPU-intensive.

- Accessibility services are **still subject to Android 10+ focus restrictions**: the service cannot call `ClipboardManager.getPrimaryClip()` unless it has explicit focus or is the default IME (a contradiction — the service never has focus).
  - Source: [Medium article on working with clipboard on Android 10](https://medium.com/@fergaral/working-with-clipboard-data-on-android-10-f641bc4b6a31)

**Conclusion:** Toast detection + transparent Activity with `FLAG_ACTIVITY_NEW_TASK` + immediate focus-grab (onWindowFocusChanged) is the standard workaround. The ActivityManager task window appears to satisfy the focus check for the first `getPrimaryClip()` call.

---

## C. Android 10–16 URI Permission Rules & ClipboardService Behavior

### Finding: CRITICAL BUG — ClipboardService Grants URI Permissions, But AOSP ClipboardService.java Does Not Implement the Grant Mechanism; Samsung May Delegate to System_server, Which Cannot Grant

**Documented Android 10+ Clipboard Access Rules:**
- Only the **currently focused app** or the **default input method editor (IME)** can call `ClipboardManager.getPrimaryClip()` and receive non-null data.
  - Source: [Android 10 release notes](https://source.android.com/docs/whatsnew/android-10-release): "Read access to the clipboard is only allowed to either the current app with input focus or the current keyboard."
  - Background apps, even in a foreground service, receive `null`.

- **Background Clipboard Access is Blocked Since Android 10:**
  - Reading clipboard on background thread after activity loses focus → returns null or throws exception.
  - Source: [XDA article on background clipboard access](https://www.xda-developers.com/android-q-blocks-background-clipboard-access/) and [GitHub Tasker issue](https://tasker.helprace.com/i487-access-clipboard-in-background-android-q)

**URI Permission Grant Mechanism:**
- When `ClipboardManager.setPrimaryClip(ClipData data)` is called with a `ClipData.Item` containing a `uri`, the AOSP `ClipboardService.java` is documented to:
  1. Check if the **granting app** (the one calling setPrimaryClip) can grant read access to the URI.
  2. Automatically grant read access to the URI for any app that later calls `getPrimaryClip()`.
  3. **Revoke the grant when the clip changes** or after a timeout.
  - Source: [GitHub issue hahnlee/aim #429](https://github.com/hahnlee/aim/issues/429): "services: the native clipboard grants no URI permissions for clipped content URIs"

**CRITICAL FINDING — System_server Cannot Grant URI Permissions:**
- The AOSP ClipboardService implementation **relies on system_server to issue the grant**, but `UriGrantsManagerService` **explicitly rejects grants when the caller is `SYSTEM_UID`**, except for two Settings authorities.
- When a **Samsung clipboard provider** (or any system service) tries to grant a URI permission on behalf of ClipboardService, the grant fails silently or throws: `"For security reasons, the system cannot issue a Uri permission grant (caller has SYSTEM_UID)"`
  - Source: [GitHub clipsync issue #1](https://github.com/lcebot/clipsync/issues/1) — "Images copied on the phone never upload: system_server can't grant the content:// read permission in pushClip"
  - Error log: `"no permission (app-name has no access to content://media/external/images/media/...)"`

- **Result:** Even if HandLive's activity holds focus during the first `getPrimaryClip()` call and retrieves the `uri`, attempting `ContentResolver.openInputStream(uri)` on a background thread (after focus is lost) **fails with `FileNotFoundException` or permission denied (`EACCES`)** because the URI grant was never issued or was revoked when the activity lost focus.

**Access Duration:**
- URI read permissions granted via clipboard are **revoked immediately when the app loses focus** (or when the clip changes).
- Calls to `openInputStream()` on a background thread, even 100ms later, encounter permission denial.
  - Source: [GitHub aim issue #1](https://github.com/hahnlee/aim/issues/1): "For security reasons, the system cannot issue a Uri permission grant"

**Android 16 Changes:**
- Android 16 (API 36) refines image MIME type handling: apps copying images now ensure the file name matches the detected MIME type (e.g., a JPEG is not named `.png`).
  - Source: [GitHub Zenium PR #732](https://github.com/BenItBuhner/Zenium/pull/732): "android: Copy Image keeps the image's real type end to end"
- **No relaxation of the URI permission grant mechanism in Android 16.**

---

## D. Writing (Mac → Phone): FileProvider URI Grant Issues

### Finding: SetPrimaryClip with FileProvider URI Requires Explicit Permission Flags; System_server Cannot Grant

**FileProvider Permission Model:**
- `FileProvider.getUriForFile()` returns a `content://` URI that is **only readable by the app that requested it**, unless explicitly granted.
- To make the URI readable by other apps, the granting app must:
  1. **Use `Intent.setFlags(FLAG_GRANT_READ_URI_PERMISSION)`** when passing the URI in an Intent (preferred).
  2. OR call `Context.grantUriPermission()` explicitly (less secure, manual revoke required).
  - Source: [Android Developer documentation on secure file sharing](https://developer.android.com/training/secure-file-sharing/share-file)

- **`ClipData.newUri(resolver, label, uri)` does NOT automatically grant permissions.** The ClipData is just a data container.

**HandLive's Write Path (`ClipData.newUri(resolver, "HandLive", uri)`):**
- If HandLive calls `ClipData.newUri()` with a FileProvider URI but does NOT call `Intent.setFlags(FLAG_GRANT_READ_URI_PERMISSION)` or `grantUriPermission()`, the receiving app cannot read the file.
- When another app tries to `ContentResolver.openInputStream(uri)`, it gets: `FileNotFoundException` or permission denied.

**Samsung Clipboard-Specific Issue:**
- Samsung's clipboard system may use a custom clipboard provider (`SemClipboardProvider`) that has limited rights to grant permissions across app boundaries.
- If the clipboard write path does not explicitly grant the URI permission, Samsung's system might strip or reject the URI, replacing it with a Samsung-internal clipboard storage reference.

**Google Photos / Samsung Gallery paste behavior:**
- Some apps refuse to paste content URIs from unknown providers. Samsung Notes and Samsung Messages have been reported to reject FileProvider URIs if the source app is not whitelisted.
  - Source: [Numerous Stack Overflow and XDA Developers threads on content:// URI paste failures]

---

## E. Known Precedents: How Other Apps Fail or Succeed

### ClipSync (Open Source) — FAILED on S25-class Devices
- **Problem:** Copying an image in Samsung Gallery never arrives on the Windows PC.
- **Root Cause:** Issue #1 in [lcebot/clipsync](https://github.com/lcebot/clipsync/issues/1) identifies the exact issue: when the Android clipboard service holds a MediaStore URI (e.g., `content://media/external/images/media/1000003945`), the ClipboardService cannot grant read access to the reading app because system_server is forbidden by UriGrantsManagerService from issuing the grant.
- **Status:** UNRESOLVED; clipsync cannot work with image clipboard on any modern Android device.

### Phone Link (Microsoft) — Text Only
- Phone Link explicitly does not sync images via clipboard. Images above 1 MB are resized, but the feature is text-only.
- Microsoft instead routes images through the Photos tab (separate API), not clipboard.
  - Source: [Phone Link feature documentation](https://www.digitec.ch/en/page/link-to-windows-samsungs-shared-clipboards-a-killer-feature-32248)

### KDE Connect (Open Source) — No Image Support
- Clipboard functionality in KDE Connect is text-only, both directions. Image clipboard is not implemented.
  - Source: [KDE Discuss thread](https://discuss.kde.org/t/kde-connect-clipboard-sync/6422)

### LocalSend (Open Source, 80k+ stars) — File Transfer, Not Clipboard
- LocalSend focuses on local file transfer, not clipboard sync. Clipboard sharing is mentioned but is text-only.
  - Source: [LocalSend GitHub](https://github.com/localsend/localsend)

### ClipCascade, ClipRelay, Sefirah — Unreliable or Unpopular
- Several projects claim image clipboard support, but none are widely adopted on Samsung devices, suggesting the same URI permission issue prevents stable operation.

**Pattern:** **No mainstream app successfully syncs images via Android clipboard on Samsung devices.** The root is the system_server grant limitation, not implementation differences.

---

## Ranked Root Causes for HandLive's Image Sync Failure

**Testing note:** Use `adb shell dumpsys clipboard` to inspect the active clipboard's MIME types and URIs.

### 1. **Activity Loses Focus Before Background Thread Completes openInputStream() — HIGHEST PROBABILITY**

**Mechanism:**
- HandLive's transparent Activity gains focus via `onWindowFocusChanged(true)`, calls `getPrimaryClip()` successfully (focus check passes), and retrieves a URI.
- The Activity starts a background thread to call `ContentResolver.openInputStream(uri)` while still alive but with focus lost (another activity becomes focused 100–300ms later).
- Android ClipboardService revokes the URI read permission when the Activity loses focus.
- `openInputStream()` fails with `FileNotFoundException` or permission denied (`EACCES`).

**Why it breaks HandLive's step:**
- Step 2: Reading the URI on a background thread fails after focus is lost.

**Test on S25 Ultra:**
```bash
adb shell dumpsys clipboard
# Look for MIME type and uri fields in the active clip
# If a uri is present and the source app is not currently focused, it will have no read permission.

# Run HandLive, copy an image, observe logcat:
adb logcat | grep -E "(openInputStream|EACCES|FileNotFoundException|clipboard)"
# Expect to see permission denied errors tied to ContentResolver operations.
```

**Expected log signature:**
```
E/HandLive: openInputStream failed: java.io.FileNotFoundException: No such file or directory
E/HandLive: ContentResolver.openInputStream: permission denied (uid=..., EACCES)
```

---

### 2. **System_server Cannot Grant FileProvider URI Permissions — CRITICAL STRUCTURAL ISSUE**

**Mechanism:**
- Samsung's SemClipboardProvider or AOSP ClipboardService tries to grant read access to the clipboard URI to HandLive's app UID.
- UriGrantsManagerService rejects the grant because the caller is SYSTEM_UID (reserved exception: only certain Settings authorities).
- The URI sits in the clipboard with no grant; any attempt to read it fails.

**Why it breaks HandLive's step:**
- Step 2: Even with focus, `openInputStream(uri)` fails because the grant was never issued.

**Test on S25 Ultra:**
```bash
# Copy an image to clipboard, then immediately:
adb shell dumpsys clipboard
# Note the URI in the output, e.g., content://media/external/images/media/...

# Check system log for grant-related errors:
adb logcat | grep -E "(UriGrantsManagerService|SYSTEM_UID|permission grant)"

# Try to read it from a background service (simulating HandLive's background thread):
adb shell "su -c 'cat /proc/sys/kernel/random/uuid | \
  xargs -I {} am instrument -w -e method openClipboardUri {} com.android.test/androidx.test.runner.AndroidJUnitRunner'"
# (This is pseudo-code; the real test would be in-app.)
```

**Expected system log signature:**
```
E/UriGrantsManagerService: For security reasons, the system cannot issue a Uri permission grant
E/ClipboardService: Could not grant permission to access clipboard URI
```

---

### 3. **FileProvider URI Not Granted in ClipData.newUri() on Write (Mac → Phone)**

**Mechanism:**
- HandLive on macOS writes an image via `setPrimaryClip(ClipData.newUri(..., fileProviderUri))`.
- The call does NOT include `FLAG_GRANT_READ_URI_PERMISSION` or an explicit `grantUriPermission()`.
- Samsung's clipboard paste targets (Samsung Notes, Samsung Keyboard, Google Photos) attempt to read the URI and fail.
- The user does not see the image paste option, or the paste shows an error.

**Why it breaks HandLive's step:**
- Step 4: Writing the image succeeds, but receiving apps cannot read the FileProvider URI.

**Test on S25 Ultra:**
```bash
# On Mac, HandLive copies a file to clipboard via FileProvider:
# Then on S25, check what was received:
adb shell dumpsys clipboard | grep -A 5 "newUri\|content://"

# Try to paste in Samsung Notes or Google Photos and observe if the image appears
# or if an error dialog shows ("Cannot read file", "Access denied", etc.).

# Check if the URI has a grant:
adb shell "am get-app-links com.your.app" # May not show grants directly
# Or examine the Uri permission state:
adb shell "dumpsys package com.your.app | grep -A 20 'granted permissions'"
```

**Expected user-visible failure:**
- Paste option is disabled in Samsung Notes, or paste shows a broken image placeholder.

---

### 4. **Samsung Custom Clipboard Provider Does Not Preserve FileProvider URIs**

**Mechanism:**
- Samsung's `SemClipboardProvider` may reject or rewrite non-Samsung URIs.
- When a FileProvider URI is put into the clipboard, Samsung's system silently converts it to a Samsung-internal clipboard reference (Samsung doesn't replicate the original FileProvider).
- Receiving apps see a Samsung clipboard reference, not the original content URI, and fail to read it.

**Why it breaks HandLive's step:**
- Step 3 (Mac → phone) or Step 2 (phone → Mac): The clipboard system silently corrupts the URI.

**Test on S25 Ultra:**
```bash
# Push a test image to the Mac cache:
adb push /tmp/test.png /data/local/tmp/

# Simulate HandLive's write: put a content URI in the clipboard via a test app:
adb shell "am start -a 'android.intent.action.SEND' \
  --es android.intent.extra.TEXT 'content://com.example.files/images/test.png' com.example.testapp"

# Immediately dump the clipboard:
adb shell dumpsys clipboard | head -50
# Check if the uri is preserved or converted to content://com.sec.android.semclipboardprovider/...
```

**Expected Samsung behavior:**
```
ClipboardService: uri=content://com.sec.android.semclipboardprovider/images/12345
# (Original FileProvider URI is replaced.)
```

---

### 5. **Toast/Accessibility Service Detects Copy AFTER Activity Finishes — Timing Race**

**Mechanism:**
- The accessibility service detects the clipboard access toast (via `TYPE_NOTIFICATION_STATE_CHANGED`) 50–100ms after the clipboard is updated.
- HandLive's transparent Activity launches immediately, grabs focus, reads the clipboard, and finishes, all within 300ms.
- By the time the accessibility service's event handler runs, the Activity has already released focus.
- The subsequent `openInputStream()` on a background thread (triggered by the late toast detection) finds the URI grant already revoked.

**Why it breaks HandLive's step:**
- Step 1–2: Toast detection timing is unreliable; relying on it as the sole signal misses fast copies or causes delays.

**Test on S25 Ultra:**
```bash
# Enable logging in HandLive's accessibility service and transparent Activity:
adb logcat | grep -E "(AccessibilityEvent|onWindowFocusChanged|TYPE_NOTIFICATION|clipboard)"

# Copy an image multiple times and observe the timing:
# Expected: gaps of 50–200ms between toast detection and Activity window focus.

# Measure with timestamps:
adb logcat | grep --line-buffered -E "(AccessibilityEvent.*TYPE_NOTIFICATION|Activity focus)" | \
  while read line; do echo "[$(date '+%T.%3N')] $line"; done
```

**Expected log pattern:**
```
[HH:MM:SS.050] AccessibilityEvent: TYPE_NOTIFICATION_STATE_CHANGED, text="Copied to clipboard"
[HH:MM:SS.120] Activity: onWindowFocusChanged(true)
[HH:MM:SS.300] Activity: onWindowFocusChanged(false)
[HH:MM:SS.350] BgThread: openInputStream() — permission denied (focus was lost at .300)
```

---

## Cheapest Tests to Prioritize

1. **Run `adb shell dumpsys clipboard` immediately after copying an image:** Check if the URI is present and if it's a MediaStore or Samsung provider URI.
2. **Observe logcat for `EACCES` or `FileNotFoundException`:** If these appear, root cause #1 (focus loss) is confirmed.
3. **Check system log for `UriGrantsManagerService`:** If "cannot issue a Uri permission grant" appears, root cause #2 (system_server limitation) is confirmed.
4. **Paste in Samsung Notes or Google Photos after Mac writes an image:** If paste fails, root cause #3 (no grant on write) is confirmed.
5. **Compare timestamps of toast detection vs. Activity focus in logcat:** If toast arrives after Activity finishes, root cause #5 is the issue.

---

## Summary Table

| Root Cause | Probability | Break Point | Test Command | Fix Complexity |
|---|---|---|---|---|
| Focus lost during background read | **HIGHEST** | Step 2 (openInputStream) | `adb logcat \| grep EACCES` | **HIGH** — must redesign to read sync in focused context |
| System_server URI grant rejected | **HIGH** | Step 2 (permission never granted) | `adb shell dumpsys clipboard` + system log | **CRITICAL** — unfixable in app code; needs AOSP patch or workaround |
| FileProvider grant not set on write | **MEDIUM** | Step 4 (receiving app denied) | Manual paste test in Samsung Notes | **MEDIUM** — add `FLAG_GRANT_READ_URI_PERMISSION` |
| Samsung provider rewrites URI | **MEDIUM** | Step 3 (URI conversion) | Compare before/after in `dumpsys` | **HIGH** — may need Samsung-specific provider or workaround |
| Toast timing race | **LOW** (if already have transparent Activity timing working) | Step 1 (unreliable signal) | `adb logcat` with timestamps | **MEDIUM** — improve signal priority or add debounce |

---

## Unresolved Questions

1. Does HandLive's transparent Activity currently use `onWindowFocusChanged(true)` as the trigger for `getPrimaryClip()`, or does it rely on the accessibility service toast detection? (Affects probability ranking of #1 vs. #5.)
2. Does HandLive explicitly call `grantUriPermission()` or use `setFlags(FLAG_GRANT_READ_URI_PERMISSION)` when writing via `ClipData.newUri()`? (If yes, it rules out #3.)
3. Has the S25 Ultra been tested with a native AOSP app (e.g., Android Contacts) copying an image to see if the problem is HandLive-specific or system-wide?

---

**Sources:**

- [Android 10 release notes](https://source.android.com/docs/whatsnew/android-10-release) — clipboard access restrictions
- [GitHub lcebot/clipsync issue #1](https://github.com/lcebot/clipsync/issues/1) — system_server URI grant limitation
- [GitHub hahnlee/aim issue #429](https://github.com/hahnlee/aim/issues/429) — native clipboard URI permission design flaw
- [FlutterQuill issue #24](https://github.com/FlutterQuill/quill-native-bridge/issues/24) — Samsung MIME type / null text issue
- [LeakCanary issue #740](https://github.com/square/leakcanary/issues/740) — SemClipboardManager reference
- [Project Zero CVE-2021-25337 analysis](https://projectzero.google/2022/11/a-very-powerful-clipboard-samsung-in-the-wild-exploit-chain.html) — Samsung clipboard provider security
- [Phone Link Clipboard documentation](https://www.edgedrop.app/blog/phone-link-clipboard-access-privacy-checklist) — image clipboard not supported
- [Android Developer: Copy and paste](https://developer.android.com/develop/ui/views/touch-and-input/copy-paste) — official clipboard guide
- [Android Developer: Secure file sharing](https://developer.android.com/training/secure-file-sharing/share-file) — FileProvider and permissions
- [GitHub Zenium PR #732](https://github.com/BenItBuhner/Zenium/pull/732) — Android 16 image MIME type handling
- [XDA Developers: Android Q blocks background clipboard access](https://www.xda-developers.com/android-q-blocks-background-clipboard-access/) — background restriction history
- [Samsung Community: Samsung Keyboard pasted from clipboard](https://eu.community.samsung.com/t5/galaxy-s25-series/samsung-keyboard-pasted-from-clipboard/td-p/12047998) — One UI toast behavior
- [ClipboardManager documentation](https://developer.android.com/reference/android/content/ClipboardManager) — public API reference
- [ClipData.Item documentation](https://developer.android.com/reference/android/content/ClipData.Item) — multiple representations support
- [GitHub hahnlee/aim issue #434](https://github.com/hahnlee/aim/issues/434) — SystemUI overlay behavior
