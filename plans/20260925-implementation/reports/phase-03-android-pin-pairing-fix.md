# Phase 3 — Android PIN pairing fixes (2026-09-27)

Scope: four Android pairing bugs found by the e2e harness (`shared/tools/e2e`, `setup` scenario) and the
Mac↔Android session. Branch `feat/phase-03-calls` (android, shared); hub `main`. Unit tests only; no
emulator used (host overloaded, emulator-5580 belongs to another session), so no device check.

## Bugs, causes and fixes

### 1. Phone advertised `pm = 1` and opened `/v1/pair` before the PIN was typed

- **Cause:** `PairingCoordinator.startPin()` opened the 120 s `PairingWindow.Pin` and advertised
  `PairingAdvert(pinMode = true)` as soon as "Enter PIN" was chosen. Spec PAIR-01 A3 → A4 opens the window
  after the PIN is confirmed. The Mac retries every 1–2 s (`PairingSearch.retryDelay` = 1 s; Mac log
  18:52:11–18:52:35 "pair/hello sent (mode pin)"), so it connected while the user was still typing.
- **Evidence:** test `pinWindowOpensWithPmOnlyOnceThePinIsConfirmed` failed (pm advertised, early
  connection served); `pinWindowLasts120SecondsFromTheConfirmedPin` failed with
  `Failed(PAIRING_CLOSED)` instead of `EnterPin` (timer started while typing).
- **Fix:** `startPin()` only shows the PIN entry; the first `submitPin()` opens the window and advertises
  `pm = 1`; after `PIN_INVALID` the still-open window takes the new PIN.

### 2. (Original bug) A connected Mac turned the PIN screen into "Pairing…"

- **Cause:** `PairingCoordinator.handle()` set `PairingState.Verifying` the moment any `/v1/pair`
  connection arrived, while `PairingExchange` blocks in `PairingWindow.Pin.awaitPin()` until the PIN is
  typed. The UI (`PairingFlow`) swaps `PinEntryScreen` for `PairingProgressScreen` on `Verifying`, so the
  PIN could no longer be typed and the exchange waited forever (until the window expired). After fix 1
  this still happens on the retry path: after `PIN_INVALID` the window stays open and the Mac reconnects
  at once while the new PIN is typed.
- **Evidence:** first reproduced with the original ordering (`expected:<EnterPin(attemptsLeft=null)> but
  was:<Verifying>`); after fix 1, `aMacThatReconnectsBeforeTheNewPinIsTypedKeepsThePinEntryOpenAndPairs`
  failed with `expected:<EnterPin(attemptsLeft=2)> but was:<Verifying>`.
- **Fix:** `PairingExchange` takes an `onClaimed` callback (called when the connection takes the window).
  The coordinator shows `Verifying` there only when the key material is at hand (`PairingWindow.hasSecret`:
  always for QR, for PIN once confirmed); otherwise the PIN entry stays and `submitPin()` switches to
  `Verifying` because a client is waiting (both under one lock). A client lost while the PIN is typed
  leaves the PIN entry on screen.

### 3. A second client closed the whole window

- **Cause:** `claimOrClosed()` correctly refuses a second connection with `PAIRING_CLOSED` (API 2 rule 4),
  but the coordinator's `else` branch treated that outcome as the window's and called `closeWindow()` —
  the user typing the PIN lost it.
- **Evidence:** `aSecondClientIsTurnedAwayWithoutClosingTheWindow` failed with
  `expected:<EnterPin(attemptsLeft=2)> but was:<Failed(PAIRING_CLOSED)>`.
- **Fix:** a connection that never took the window and ends with `PAIRING_CLOSED` or `DISCONNECTED`
  changes nothing (`notServed`); `AUTH_FAILED` still closes the window (E4, conservative).

### 4. Claim leak on unexpected errors

- **Cause:** `PairingExchange.run()` caught only its own `Abort`. Any other exception (socket I/O, a bug)
  escaped: the claim was never released, no close frame was sent (Mac log 19:00:21 "channel ended:
  closed(-, remote, end of stream)"), the coordinator never updated the window, and every later attempt
  got `PAIRING_CLOSED` until the app restarted.
- **Evidence:** `aBrokenConnectionGivesTheWindowBackAsALostClient` and
  `anUnexpectedErrorEndsTheExchangeWithInternalAndClosesTheSocket` failed with the raw
  `IOException` / `IllegalStateException`.
- **Fix:** `IOException` → `DISCONNECTED` (claim released, window goes on); any other exception →
  `pair/error INTERNAL` + close frame, outcome `INTERNAL` (coordinator closes the window, generic text);
  cancellation releases the claim and rethrows.

### 5. PIN flow showed the QR sentence for `PAIRING_CLOSED`

- **Cause:** only one text existed ("The QR code has changed…").
- **Fix:** spec first (E2 gets a PIN sentence), catalog key `error.pin_expired` (en/vi, android only),
  new phone-only `PairingFailure.PIN_EXPIRED` used when a PIN window closes (timer or a claimed exchange
  whose PIN never came). Tests: `pinWindowThatEndsWithoutAPairSaysThePinExpired`,
  `PairingFailureMessageTest`.

## Spec changes (hub)

`02-pairing.md` / `.vi.md`: A4 opens the window only once the PIN is confirmed, plus the retry-path rule
(client waits for the PIN, field stays editable, `verifying` starts on confirm); API 2 rule 4: refusing
a second connection leaves the window and its client alone; E2 PIN sentence. `00-common-specs.md` /
`.vi.md`: `PAIRING_CLOSED` action mentions a new PIN. `validate_design_docs.py` problems=0,
`check_bilingual_docs.py` problems=0.

## Verification

- `./gradlew testDebugUnitTest testFossDebugUnitTest ktlintCheck detekt :app:lintFossDebug
  :feature:pairing:lintDebug --offline` — all green.
- `shared/tools/strings/check_strings.py` — 394 strings, 0 errors.
- Not run: device/emulator check, e2e `setup` scenario rerun (left to the Mac↔Android session).

## Commits

| Repo | Hash | Message |
|------|------|---------|
| handlive (hub) | 4091655 | docs(spec): open the PIN window after the PIN, keep it on a second client and say when the PIN expired |
| handlive-shared | cc2e1f8 | feat(shared): add the PIN expired pairing string |
| handlive-android | 0cd3a61 | test(android): the PIN window opens only once the PIN is confirmed |
| handlive-android | cee0581 | fix(android): open the PIN pairing window and advertise pm only after the PIN is confirmed |
| handlive-android | e45702e | test(android): a Mac that reconnects while the new PIN is typed keeps the PIN entry open |
| handlive-android | 8b60b81 | fix(android): keep the PIN entry open while a connected Mac waits for the PIN |
| handlive-android | b0911c8 | test(android): a second pairing client is turned away without closing the window |
| handlive-android | a59f39e | fix(android): turn a second pairing client away without closing the window |
| handlive-android | 3db1d8d | test(android): an unexpected error in the pairing exchange gives the window back |
| handlive-android | a75a10c | fix(android): end the pairing exchange cleanly on unexpected errors and free the window |
| handlive-android | 3914eba | test(android): a PIN window that ends without a pair says the PIN expired |
| handlive-android | c0d2d51 | fix(android): say the PIN expired when a PIN pairing window closes |

Test commits precede their fixes and are red on their own (the PIN_EXPIRED test commit does not compile
without its fix).

**Shared changed** (`strings/ui-strings.json`, android-only key): Android regenerates resources on build;
Apple is unaffected but may re-run the catalog check.

## Unresolved questions

- Mac side: the Mac waits 10 s for `pair/offer` (`TransportConstants.requestTimeout`). If retyping the PIN
  after `PIN_INVALID` takes longer, the Mac drops that connection; the phone only notices once the PIN is
  confirmed (the exchange blocks in `awaitPin`), so Mac retries meanwhile get `PAIRING_CLOSED` (window held).
  After the PIN is confirmed the stale connection ends as `DISCONNECTED`, the claim is released and the
  next Mac retry pairs. This relies on the Mac treating `PAIRING_CLOSED` during a PIN search as retryable —
  the Apple side should confirm, or wait for the offer until its PIN expires.
- Whether a bad `pair/hello` (`AUTH_FAILED`) from a stranger should close a window held by another
  client; kept as closing (E4) for now.

Status: DONE_WITH_CONCERNS
Summary: Fixed four Android PIN pairing bugs (window opened before the PIN, "Pairing…" on early connect, a second client closing the window, claim leak on unexpected errors) and added the PIN-expired text. Each bug has a failing test first; spec, shared and android are committed and pushed.
Concerns/Blockers: no device or e2e rerun (emulator reserved by another session); Mac-side timeout while waiting for a retyped PIN not verified.
