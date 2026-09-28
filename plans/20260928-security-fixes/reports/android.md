# Android: security scan fixes (D1, D2 phone side, D5–D11)

Repo `handlive-android`, branch `fix/security-scan-findings` from `origin/main` (`16429ca`), pushed. `shared` stayed on
`fix/security-scan-findings` (no change made there).

## Changes per decision

- **D8 clipboard ids** — new `engine/ClipIds` (canonical UUIDv7 via `EnvelopeCodec.isUuidV7`). `PushValidator` checks
  `clip_id` and `transfer.transfer_id` first → `BAD_REQUEST` (before `FEATURE_DISABLED`). `clipboard/cancel` and
  `clipboard/conflict` (events, no ack) with a bad id are dropped in `ClipboardModule`. `ClipFiles` builds every file
  through `inside()`: canonical parent must equal the clip dir, else `IllegalArgumentException`; `IncomingTransfers`
  opens the `.part` inside its `runCatching` (→ `INTERNAL`).
- **D7 per-session features** — `CallRequests`: `action` and `log_sync` → `FEATURE_DISABLED` unless
  `session.isEffective(Feature.CALL)` (covers `READ_PHONE_STATE` missing), checked before permissions. `SmsModule`:
  every `sms/sync|history|send` → `FEATURE_DISABLED` unless SMS is enabled in the client's latest `capability`
  (`peerCapability`). I did not use `isEffective(SMS)` there because it also drops on missing `READ_SMS`, which must
  stay `PERMISSION_MISSING`; the phone's own `feature.sms` is still checked by `SmsRequests`/pipeline.
- **D5 admission** — `ConnectionAdmission`: per-address pending cap (4) next to the global 16; new
  `recordPreHandshakeFailure` (10 within 5 min → 5-min block, separate counter from `AUTH_FAILED`, rule unchanged).
  `ControlConnectionHandler` records handshake timeouts (4408), `PAIR_UNKNOWN` rejections and any pre-handshake close
  with 4400 (malformed hello, bad first capability, binary/oversized frame). `/v1/pair` has its own
  `ConnectionAdmission` (4 total, 2 per IP, ticket held for the whole connection, over → close 4429).
  `RawTextMessageSocket` reads the first message with an 8 KiB cap, over → close 4400. Limits grouped as
  `ControlServerLimits(pending, authFailures, preHandshakeFailures, ipBlockDuration, idleTimeout, pairConnections)`;
  constants in `TransportConstants`. Relay peers are counted by `relay:<device_id>` as before.
- **D1 replay** — `SessionCipher.accept()` decrypts, then checks the id against the current epoch's set and the
  previous epoch's (kept while the old key is accepted, dropped with it); ids stored as `UUID`, recorded only after
  decrypt, recorded in the epoch whose key opened it (also for repeats, so a copy sealed with the new key stays a
  replay after the old epoch ends). `install()` rotates the sets. The channel returns `Opened(plaintext, replayed)`;
  the dispatcher drops repeated `capability`/`session`/`ack` envelopes and delivers application ones flagged
  `InboundEnvelope.replayed`; `SessionRouter` then only resends the old ack if the per-pair ledger (5 min / 1,000,
  kept for cross-session retries) still has it — never processes again. Same code path for LAN and relay sessions.
- **D6 pairing window** — `PairingCoordinator.handle`: a connection that never claimed the window returns without
  touching the window or state, whatever its failure (AUTH_FAILED included). `PairingWindow.Pin` counts offers
  (`takeOffer`, max 3, taken in `PairingExchange.sendOffer` after the PIN is known; a 4th gets `PAIRING_CLOSED`); when
  the claim holder ends with no offers left and no pair, the window closes as `PIN_EXPIRED`. `EnterPin.attemptsLeft`
  now shows the phone's own count; the client's `attempts_left` is ignored.
- **D2 phone side** — `core/crypto` `RevocationStatement` (49-byte `HLREVOKE1` message, strict `isFromPeer` check).
  Protocol models: `PairRevokeRequest{revoked_at, sig, reason?}`, `Revocation`, `DevicesDeleteRequest`,
  `RelayPairRevoked{…, revoked_at?, sig?}`, `RelayPairEntry{revoked_by?, revoke_sig?}`. New `RelayRevocations`:
  signs a fresh statement per `POST /v1/pairs/{id}/revoke` attempt (retries after E3 re-sign with the current time)
  and, for `DELETE /v1/devices/me?revoke_pairs=true`, one statement per local pair (active + tombstones) plus every
  unrevoked pair from `GET /v1/pairs` (fetched with `registerIfUnknown=false`; a gone device ends as DONE; other list
  errors fall back to local pairs). Receiving: `pair_revoked` (RelayOwner now gets the whole frame) and revoked
  `GET /v1/pairs` rows unpair only when `by` = stored peer `device_id` and the sig verifies with the stored peer
  `ik_sig` pub; otherwise ignored. `RelayAuth.sign()` exposes the identity signer.
  Pre-auth relay `session/error PAIR_UNKNOWN|PAIR_REVOKED` (CONN-03 E9): the phone is always the `/v1/ctl` server and
  never receives `session/error`, so nothing to change on Android; noted only.
- **D9 SMS limit** — `send/SendLimiter`: per pair, rolling 60 s ≤ 10 and 24 h ≤ 100 accepted sends; checked last in
  `SmsSendPipeline.admit` (after address and SIM); duplicates (`local_id` in the registry, envelope id in the router)
  never reach it, refusals are not counted. `SmsError.rateLimited` → `RATE_LIMITED` with `details.retry_after_ms`
  (time until the slot frees, ≥ 1). First refusal per pair per rolling day calls `SendLimitListener`;
  `SmsSendLimitNotifier` posts `sms.send_rate_limited_body` (`R.string.sms_send_rate_limited_body`) on channel
  `permission`.
- **D10 share alias** — `ClipboardReadActivity.launchOf`: `ACTION_SEND` → share (only `EXTRA_TEXT`, source `share`);
  the alias component with any other action → finish without reading; `source`/`mode` extras honoured only on intents
  naming the non-exported activity (HandLive's own).
- **D11 CI** — `ci-android.yml`: checkout `fbc6f39… # v5.1.0` (×4, all `persist-credentials: false`), setup-java
  `b6effb0… # v5.7.0`, setup-android `9fc6c4e… # v3.2.2`, setup-gradle `0723195… # v5.0.2`, upload-artifact
  `ea165f8… # v4.6.2` (SHAs from `git ls-remote`, each equal to the floating major tag today). Branch lookup via
  `gh api …/git/matching-refs/heads/<branch>` with `GH_TOKEN` from env, as in shared.

## Commits (handlive-android, `fix/security-scan-findings`)

| Hash | Message |
|------|---------|
| `5483ceb` | fix(android): refuse clipboard ids that are not UUIDv7 and keep clip files in their directory |
| `02817c3` | fix(android): check calls and SMS for the session that sent the request |
| `759d4d2` | fix(android): limit pending connections per address and give /v1/pair its own admission |
| `f7e6af4` | fix(android): reject replayed envelopes for the whole key epoch |
| `f177d27` | fix(android): keep the pairing window from strangers and count PIN offers on the phone |
| `081ea99` | fix(android): sign revocations and act on relay revocations only with the peer's signature |
| `e326838` | feat(android): cap sms/send per pair and tell the user once a day |
| `e7b9414` | fix(android): handle only shares through the exported Share alias |
| `2501f73` | ci(android): pin actions to commit SHAs and keep the token out of git URLs |
| `04feb63` | refactor(android): keep the security fixes within the detekt limits |
| `7a741b5` | test(android): wait for the relay side of the socket in RelayLinkTest |

All signed off, no AI trailers.

## Tests (written first, seen red where the code already compiled)

- clipboard: `PushValidatorTest.idsThatAreNotCanonicalUuidV7AreBadRequest`, `ClipFilesTest` (new),
  `ChunkedTransferTest.idsThatAreNotUuidV7AreBadRequestAndNoFileIsCreated`, `ClipboardShareTargetTest` (new).
- call/sms: `CallActionTest.aSessionWithoutCallsIsRefusedWhateverOtherSessionsAllow` (action + log_sync),
  `SmsModuleTest.everyRequestFromASessionWithoutSmsIsFeatureDisabledWhateverOtherSessionsAllow`,
  `SmsSendTest.aPairMaySendTenMessagesAMinuteAndRetriesAreNotCounted` (schema `sms-send#ack-failure`),
  `…AHundredMessagesADayAndIsToldOncePerDay`, `SmsSendLimitNotifierTest` (new).
- transport: `ConnectionAdmissionTest` (per-IP cap, pre-handshake block and window, pairing caps),
  `ControlChannelLimitsTest` (5th pending from one IP → 4429; 10 silent/`PAIR_UNKNOWN` handshakes → 4429 even for a
  valid hello; `/v1/pair` 3rd from one IP → 4429; 8 KiB+1 hello → 4400), `SessionCipherReplayTest` (new: replay after
  23 h, forged envelope takes no id, previous-epoch ids, retry across rekey), `ControlChannelHandshakeTest`
  (repeat flagged, repeated capability dropped), `SessionRouterTest` (replay after ledger expiry not processed;
  flagged retry gets old ack).
- pairing: `PairingCoordinatorTest.aStrangerThatNeverClaimedTheWindowCannotCloseIt`,
  `theThirdPinOfferWithoutPairDoneClosesTheWindowAsPinExpired` (client claims 9 attempts left; ignored).
- revocation: `RevokeStatementVectorTest` (new; `revoke.json`: 3 vectors — message, deterministic signature, wire
  `revoke_request`/`revocation`/`pair_revoked`, DELETE body; 7 receiver negatives rejected); `VectorFileCoverageTest`
  now maps `revoke.json`. `RelayRegistrarTest`: fresh signed statement per attempt (schema `pair-revoke-request`),
  delete-all signs local + tombstone + relay-only pairs (schema `devices-delete-request`), revoked rows without a valid
  peer statement ignored, `pair_revoked` accepted only when the peer signed it. The relay test kit now signs with the
  RFC 8032 TEST 1 key of `PHONE_DEVICE_ID`.

Local: `./gradlew check` (JDK 21, `--offline`) → BUILD SUCCESSFUL.

## CI

- Run 36373101943 (`04feb63`, dispatch): failed in `RelayLinkTest.framesFlowBothWaysWithTheBearerToken` — NPE from a
  race between the client's Opened event and MockWebServer's `onOpen`; test not touched by these fixes. Fixed in
  `7a741b5`.
- Run 36373550277 (`7a741b5`, dispatch): **success** (resolved hub `main`, shared `fix/security-scan-findings`).

## Notes for others

- No change in `shared/`. Android now consumes `revoke.json`, `relay-rest` `pair-revoke-request` and
  `devices-delete-request`, `sms-send#ack-failure`, string `sms.send_rate_limited_body`.
- The hub spec commits are on local hub `main`, not pushed (per the specs report); CI used the remote hub `main`, which
  Android's tests only read for the design-system docs.

## Unresolved questions

- `ControlServerLimits` constructor shape changed (grouped caps/rules); only tests and `ControlServer` used it.
- The SMS limit notice reuses channel `permission` (spec says so); its channel description is about permission
  suggestions (same concern as the specs report).
- `revocationsForDelete` falls back to local pairs when `GET /v1/pairs` fails with a non-"gone" error; the relay then
  answers 400 if it still holds a pair we could not list (deletion reported as UNREACHABLE, user retries).

## Review fixes (2026-09-28, hub spec e885957)

| # | Point | Change | Commit |
|---|-------|--------|--------|
| 1 | CI branch spliced into jq/API path | `enc="$(jq -rn --arg b "$BRANCH" '$b|@uri')"`, path uses `$enc`, filter `jq --arg r "refs/heads/$BRANCH" 'map(select(.ref == $r)) | length'` (as shared d7e9761). CI log shows `handlive-shared → fix/security-scan-findings`, so a branch with `/` resolves. | `9f3fef7` |
| 2 | D1 hard cap | New `session/ReplayWindow`: a direction reaching `MAX_TRACKED_IDS` (20,000 = 2 × `REKEY_AFTER`) sets `Opened.overflow`; `ControlConnectionHandler` closes 4410 before dispatch. The cap is derived from `rekeyAfterEnvelopes` in `SessionCipher`. | `e4cb41c`, `a1ecd1a` |
| 3 | D1 acks for the whole epoch | `ReplayWindow` keeps, per id of the current/previous epoch, the ack plaintext the phone sent (recorded in `EncryptedEnvelopeChannel.writeLocked` for every `ack`). A repeated id is answered by the transport with that ack, re-sealed under current keys with a new envelope id, and is never delivered to features. `InboundEnvelope.replayed` and the router's replay branch are gone; the per-pair 5-min ledger stays for retries across sessions. Ack bodies also have a byte bound (`MAX_TRACKED_ACK_BYTES` = 8 MiB, oldest dropped first; a repeat whose ack was dropped is still never processed). | `e4cb41c` |
| 4 | D5 count only unauthenticated failures | `Progress.macVerified` is set when the hello passes the mac check; timeouts and 4400 count toward `CTL_IP_BLOCK` only before that (`PAIR_UNKNOWN` still counts). An established session calls `ConnectionAdmission.clearPreHandshakeFailures`. | `a11682e` |
| 5 | D6 race | `PairingExchange.run` resets the PIN entry before `window.release()` on `PIN_INVALID`; the coordinator no longer resets it (a PIN typed meanwhile is kept). | `2462073` |
| 6 | D10 deny by default | `launchOf`: `ACTION_SEND` → SHARE; component = `ClipboardReadActivity` → OWN; anything else → REFUSED. Robolectric test resolves the alias through `PackageManager.queryIntentActivities` and checks a non-SEND start of it is refused. | `0860e92` |
| 7 | D9 monotonic clock | `SmsSendPipeline` takes a `SendLimiter`; the app builds it on `SystemClock::elapsedRealtime`; wall clock comes from the registry. | `545ba9c`, `be99dc2` |
| 8 | D8 nit | `files.clip(...)` inside the `runCatching` of `ClipReceiver.onVerified`. No new test: ids are validated before this point, so a refused name cannot reach it from the wire. | `1a64203` |
| 9 | Nit | `InboundFrames.receive` loop simplified. | `69b1698` |

Tests added/changed: `SessionCipherReplayTest` (earlier ack after 23 h and across rekey; 20,000th id overflows),
`ControlChannelHandshakeTest.aRepeatedEnvelopeGetsItsEarlierAckAndIsNeverDeliveredAgain`,
`ControlChannelLimitsTest.aDirectionThatReachesTheTrackedIdCapIsClosedWith4410` (closes before the 10 s rekey timeout)
and `onlyFailuresBeforeTheMacCheckCountAndASessionClearsThem`, `ConnectionAdmissionTest.anEstablishedSessionClears…`,
`PairingExchangeTest` (PIN entry reset before the claim is released), `ClipboardShareTargetTest` (deny by default,
alias via PackageManager), `SmsSendTest.settingThePhonesClockDoesNotResetTheSendLimit`. The two router replay tests
were removed with the router branch.

Checks: `./gradlew check` green locally; ci-android run 36375437906 **success** on `be99dc2`.

Review-fix notes:
- The 8 MiB ack-byte bound is my addition (the spec bounds ids only): large sync pages × 10,000 ids would not fit in
  memory. Only the resend of very old large acks is lost, never the dedup.

## Review fixes, round 2 (review: APPROVE with follow-ups)

| # | Point | Change | Commit |
|---|-------|--------|--------|
| 1 | `ackOrder` grew for the session's life | Each `ackOrder` entry now names the epoch map that holds the ack; `dropPrevious()` (also called by `rotate()`) removes that epoch's entries and releases their bytes. Found on the way: an id present in both epochs (a retry under the new key) lost its newer ack when the old epoch went; the release now only touches the dropped epoch. | `b5f305c` |
| 2 | Tests | New `ReplayWindowTest` (`maxAckBytes = 10`): oldest-first eviction; `storedAckBytes`/`storedAcks` back to 0 after `rotate` + `dropPrevious` over three rounds, and bounded after two rotations; id in both epochs. `SessionCipherReplayTest`: an ack for an id never accepted → `earlierAck == null` (replaces the `trackedIds == 1` check). | `b5f305c`, `ee6adde` |
| 3 | Cap overflow | `rekeyAfterEnvelopes` is clamped to `1..Int.MAX_VALUE / 2` before × 2 (a `Long` × 2 overflows too, found by the new test). Test: `rekeyAfterEnvelopes = Long.MAX_VALUE` does not overflow on the first envelope. | `ee6adde` |

The ReplayWindow tests and the overflow test failed before the fixes. Checks: `./gradlew check` green locally;
ci-android run 36377853375 **success** on `ee6adde`.

Status: DONE_WITH_CONCERNS
Summary: Review round 2 fixed in 2 signed-off commits (head `ee6adde`); `./gradlew check` green locally and ci-android run 36377853375 green.
Concerns/Blockers: unchanged from round 1: the 8 MiB bound on stored ack bodies is not in the spec.
