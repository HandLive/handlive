# Phase 3 — Android fixes for the e2e open items (2026-09-28)

Scope: the three Android failures that `phase-03-e2e-1.md` handed off (rows 2–4), found by `shared/tools/e2e` against
android `eccf499`. Work done on handlive-android `feat/phase-03-calls`, from `728b43f`, in a separate worktree.
Unit tests only: no emulator or device was used (emulator-5580 is reserved for live tests), and the e2e scenarios were
not rerun.

| # | Check | Spec | Outcome |
|---|-------|------|---------|
| 1 | A new session's `capability/hello` still lists SMS and call permissions granted after start as missing | SET-01 API 2 logic 4 | Still present at `728b43f`. Fixed: `a509ed1` test, `9415777` fix |
| 2 | After the first pairing the app showed Devices, not the feature list | SET-01 step 8 | Still present at `728b43f`. Fixed: `a399dab` test, `cf567c8` fix |
| 3 | A LAN connection that never sends `session/hello` ended with 1006, not 4408 | CONN-01 API 3 logic 2, 0.8.3 | Not an app bug: the API 29 emulator had stopped responding. No change |

## 1. Capability ignored permissions granted later

- **Spec check.** SET-01 API 2 logic 4 says: "The user grants a permission in Settings → recompute on A-UI `onResume`
  or when a new session sends `capability/hello`." Step 14 adds: "Something changed and a client is connected → send
  `capability/update`." The harness expects exactly this.
- **Still present at `728b43f`.**
  - `d3cf558` does not touch this path. It only covers the *peer's* capability written to `features_json`.
  - A scratch Robolectric test (not committed) built the capability as `ConnectionRuntime` does, then granted all six
    permissions with no signal. The value handed to a new session was still
    `[READ_SMS, SEND_SMS, READ_CONTACTS, READ_PHONE_STATE, READ_CALL_LOG, ANSWER_PHONE_CALLS]`.
  - That matches the harness output `still missing [...]`.
- **Cause.** The value was cached, and nothing recomputed it when a session started.
  - `ConnectionRuntime.startLocked()` passed `localCapability = { capabilityState.value }` to the server.
  - `capabilityState` came from `CapabilityPublisher.state()`. It was recomputed only when a setting changed, the
    Accessibility service changed, or `refreshEnvironment()` was called (A-UI `onResume`, SIM change, the call feature).
  - `pm grant` and the App info page send the app no signal. The harness reconnected without bringing the app on
    screen. Every `capability/hello` therefore carried the value computed at service start.
- **Fix.**
  - **core/transport:**
    - `ControlServerConfig` has a new `helloCapability` hook. It defaults to `localCapability`.
    - `ControlSession.sendCapabilityHello()` calls it once for each new session, on the LAN and through the relay.
  - **feature/connection:**
    - `CapabilityPublisher.state()` now returns a `LocalCapability`: a `state` StateFlow plus a synchronized `refresh()`.
      `refresh()` reads the latest settings, the permissions and the SIMs again, publishes the result and returns it.
    - The existing triggers (settings, Accessibility, `environmentVersion`) now call `refresh()`.
    - `ConnectionRuntime` wires `helloCapability = phoneCapability::refresh`.
  - **What follows from it:**
    - The new session's hello is current.
    - The SMS and call modules, which follow `runtime.localCapability`, start their observers.
    - `publishUpdates` sends `capability/update` to the open sessions when the value changed.
- **Side effect.** When a refresh finds a change, the new session may also get one `capability/update` equal to its
  hello. The debounced publisher sends to every registered session 300 ms later. This is harmless: an update is a full
  snapshot that replaces the stored copy (0.7.2). I did not deduplicate it: `closeRelayedSessions()` deliberately
  re-sends the current capability before `bye` (SET-02 API 1, `RelayPeerMuxTest`).
- **Tests:**
  - `CapabilityPublisherTest` (new, Robolectric, SDK 35):
    - A new session reads SMS permissions, then call permissions, granted with no signal. It checks
      `permissions_missing`, `can_send` and `call`, and that `state` follows.
    - The app coming back on screen still rebuilds the capability.
    - A setting change still rebuilds it.
  - `ControlChannelHandshakeTest.eachNewSessionReadsTheCapabilityOfItsHelloAgain`: two sessions each read
    `helloCapability` once, and the hello carries that value, not the snapshot.

## 2. Feature list after the first pairing

- **Spec check.** SET-01 step 8 says: "After the first PAIR-01, A-UI opens the feature list (field 10)…". Field 10
  says: "Shown after the first PAIR-01 and in Settings › Permissions & Background". The harness expects this.
- **Still present at `728b43f`.** `PairingRoute.onPaired` only showed the "Paired" feedback and popped the pairing
  route, so the app landed on the Devices tab. This is the known deviation 8 in `phase-03-A3.1.md`.
- **Decisions** (the spec leaves these open):
  - **What counts as "first".** The phone had no active pair when the pairing began. The count comes from the limit
    check the coordinator already runs on scan (`onScanned`) and on "Enter PIN" (`startPin`).
    - Re-pairing the same client is not "first". Its new pair replaces the old one, per PAIR-01 API 4 rule 4.
    - Adding a second device is not "first" either.
    - After every device has been unpaired, the next pairing counts as first again. No "ever paired" key exists in
      0.9.5, and adding one would be a spec change.
    - I first counted inside `handle()`, but the Room query there let virtual time run past the window in an existing
      test. Counting at the start of the flow avoids that and means the same thing.
  - **Where the list opens.** Over the Devices tab, where pairing starts. Back then returns to the device list showing
    the new Mac. The header's back button reads "Devices" there, and "Settings" when the list is opened from Settings.
    This follows 03-android.md "Navigation": the back button carries the previous screen's name.
  - **No new UI strings.** The labels reuse `pairing_devices` and `settings_title`.
- **Fix.**
  - **feature/pairing:** `PairingState.Paired.firstPair` is filled from `PairingCoordinator.noPairBefore`.
  - **app:**
    - `Route.Permissions(afterFirstPairing)` plus a `backLabel` extension.
    - `MutableList<Route>.closePairing(firstPair)`: pops the pairing screen and pushes the list after the first pair.
      A second tap on Done does nothing.
    - `PairingFlow.onPaired` now receives the `Paired` state.
    - `PermissionsScreen` takes `backLabel` (default "Settings").
- **Tests:**
  - `PairingCoordinatorTest`, three new tests: the first pair is first; a pair added next to another is not; re-pairing
    the same client is not. The existing PIN reconnect test now also checks `firstPair` on the PIN path, which is the
    path the harness uses.
  - `PairingNavigationTest` (new):
    - The first pair opens `Permissions(afterFirstPairing = true)` with back label "Devices".
    - A double tap opens it once. This test failed against the first version of the fix, with two copies stacked.
    - Other pairs go back to the tabs.
    - The list opened from Settings goes back to Settings.

## 3. 1006 instead of 4408 without `session/hello`

- **Spec check.** CONN-01 API 3 logic 2 says a connection that sends no `session/hello` within 5 s is closed with
  4408. The harness expectation is right.
- **The app closes with 4408.**
  - The code: `ControlConnectionHandler.handle()` runs the handshake inside
    `withTimeoutOrNull(HANDSHAKE_TIMEOUT = 5 s)`. On timeout it sends `CloseReason(4408, "handshake timeout")`. The
    file has not changed between `eccf499` and `728b43f`.
  - The unit test: `ControlChannelRejectionTest.silentClientIsClosedWith4408AfterHandshakeTimeout` passes at `728b43f`
    (10/10 in the class; this test took 5.55 s).
  - The same harness check **passed** on emulator-5556 (API 35) with the same APK: close 4408 after 5,011 ms. The
    4411 idle check passed there too.
- **Why emulator-5558 (API 29) got 1006.** The harness waited 30,015 ms and never saw a frame from the phone: no 4408
  at 5 s and no pong. The 1006 came from the harness's own keepalive: a ping at 15 s, a 10 s pong timeout, then a 5 s
  close timeout. The log reads "sent 1011 (internal error) keepalive ping timeout; no close frame received". At the same
  time the whole emulator stopped responding:
  - The session the harness had opened just before (connected 16:53:51.74) missed its first keepalive pong as well. It
    dropped at 16:54:21.74, 30 s later, on the same timeout path (`hlbench-mac.log`).
  - The next connection's TLS handshake timed out.
  - `adb logcat -d -b crash` timed out after 30 s, so adbd was unresponsive too.
  - `phase-03-e2e-1.md` row 6 records a host load average above 100 at that time.
  - An app bug would have closed at 5 s or dropped the TCP connection. It would not have left an open, silent
    connection for 30 s while adb also hung.
- **No change.** This check should be rerun on API 29 on a quiet host.

## Commits (handlive-android, `feat/phase-03-calls`, pushed `728b43f..cf567c8`)

| Hash | Message |
|------|---------|
| `a509ed1` | test(android): a new session's capability/hello carries permissions granted while the service runs |
| `9415777` | fix(android): read the phone's permissions again when a session starts |
| `a399dab` | test(android): the phone's first pairing opens the feature list |
| `cf567c8` | fix(android): open the feature list after the phone's first pairing |

- Each test commit precedes its fix and is red on its own. Both test commits reference API that their fix adds
  (`helloCapability`, `LocalCapability.refresh`, `PairingState.Paired.firstPair`, `closePairing`), so they do not
  compile without the fix. This follows the same pattern as the earlier `3914eba` → `c0d2d51` pair.
- All four commits are signed off as Hồ Xuân Dũng <me@hxd.vn> and have no co-author trailer.
  `.githooks/check-commits.sh 728b43f..HEAD` reports them clean.
- No shared, spec or doc change. The Apple and relay agents have nothing to re-run.

## Verification

- `./gradlew :core:transport:testDebugUnitTest --tests '*ControlChannelRejectionTest*'` at `728b43f`: 10/10 pass,
  including 4408.
- Red:
  - `./gradlew :core:transport:compileDebugUnitTestKotlin :feature:connection:compileDebugUnitTestKotlin` and
    `:feature:pairing:compileDebugUnitTestKotlin :app:compileFossDebugUnitTestKotlin` fail on exactly the missing
    symbols.
  - `PairingNavigationTest.aSecondTapOnDoneOpensTheFeatureListOnce` failed at runtime against the unguarded
    `closePairing`.
- Narrow green:
  - `:core:transport:testDebugUnitTest --tests '*ControlChannelHandshakeTest*'`: 4/4.
  - `:feature:connection:testDebugUnitTest --tests '*CapabilityPublisherTest*'`: 3/3.
  - `:feature:pairing:testDebugUnitTest --tests '*PairingCoordinatorTest*'`: 17/17.
  - `:app:testFossDebugUnitTest --tests '*PairingNavigationTest*'`: 4/4.
- Module tests, `ktlintCheck` and `detekt` of core/transport, feature/connection, feature/pairing and app: green.
- `./gradlew check --continue` at `cf567c8`: BUILD SUCCESSFUL. That covers 650 unit tests in 13 modules with 0
  failures, plus ktlint, detekt, Android lint (every module, app `lintFossDebug`) and `compileGmsDebugKotlin`.
- Not run: emulator or device checks, and the e2e scenarios.

## Open items

1. **The harness needs one Back press.** In `shared/tools/e2e/scenario_setup.py`, `check_session()` checks "the Mac is
   listed on the Devices tab" (PAIR-02 field 1) right after `_paired()` has seen the feature list. The Permissions
   screen is now on top, so that check will fail unless the harness first presses Back (`KEYCODE_BACK`) or taps the
   "Devices" back button. Later UI steps may also start on that screen. I did not change `shared/`, which is out of
   scope.
2. **Rerun on a quiet host:** the API 29 setup scenario, including the 4408 check.
3. **Rerun the e2e checks** for items 1 and 2 (`pm grant`, then a new session; first pairing, then the feature list)
   on an emulator or phone.
4. **Optional spec wording in SET-01 step 8, both languages:**
   - "First pairing" means the phone had no active pair, and the list shows again after every device was unpaired.
   - The list opens over the Devices tab, and Back returns there.

   Only needed if the owner wants these behaviours written down.
5. **A redundant `capability/update`** may follow a hello whose refresh found a change (see bug 1). Harmless.
6. **The main checkout is behind.** `/Users/hxd/HandLive/android` (branch `feat/phase-03-calls`) is still at
   `728b43f`. Pull there before building the next APK for the harness. I did not touch that checkout.

Status: DONE_WITH_CONCERNS
Summary: Fixed the stale capability in a new session's hello (permissions are read again at each session start and published) and opened the feature list after the phone's first pairing, each with a failing test first; the 4408 failure is an unresponsive API 29 emulator, not an app bug (test passes, API 35 run passed). 4 commits pushed to handlive-android `feat/phase-03-calls` (`728b43f..cf567c8`); `./gradlew check` green.
Concerns/Blockers: no emulator or e2e rerun; the setup harness must press Back after the feature-list check before it looks for the Mac on the Devices tab; the 4408 check on API 29 should be rerun on a quiet host.
