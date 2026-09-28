# Apple — security scan fixes (D1, D2 client side, D11)

Repo handlive-apple, branch `fix/security-scan-findings` (from `origin/main` 13da56a), pushed. Not merged.
`shared/` stayed on `fix/security-scan-findings` (no changes to it).

## D1 — replay protection over the key epoch (ControlSession+Receiving.swift:31)

- `RecentEnvelopeIDs` (SessionCipher.swift) rewritten: every id accepted in the current epoch, with its ack.
  No 5-minute window and no 1,000-id eviction. `REKEY_AFTER` bounds the set (10,000 per direction), so nothing is
  evicted inside an epoch; an evicted id could be replayed.
- `lookup` no longer records. `record` runs only after `cipher.open` succeeded (receive loop and the first
  `capability/hello`), so a forged envelope never takes an id.
- At rekey (`installKeys`, both initiator and responder paths) the set moves to "previous" and stays for
  `rekeyOldKeyGrace` (30 s), the time the old keys are still accepted. `remember(ackWire:)` also finds ids of the
  previous epoch.
- Duplicate handling unchanged: the earlier ack is resent, nothing is processed again.
- Removed the now unused `SessionConfiguration.dedupWindow` / `dedupCapacity` and `TransportConstants.dedupWindow` /
  `dedupCapacity` (no users outside HLTransport).

## D2 — signed revocation (ConnectionManager+Supervise.swift:81)

Signing:
- HLCrypto `RevokeStatement`: `message` / `sign` / `verify` for `"HLREVOKE1"` ‖ pair_id ‖ by ‖ revoked_at (u64 BE),
  strict Ed25519 verification (existing `Ed25519.verify`, S < L).
- HLProtocol: `RelayPairRevokeRequest {revoked_at, sig, reason?}`, `RelayRevocation`, `RelayDeviceDeleteRequest
  {revocations}`, `RelayPairEntry.revokedBy/revokeSig` (+ `revocation`), `RelayControl.pairRevoked(RelayPairRevocation)`
  — `revoked_at`/`sig` parsed as optional so an unsigned notice parses and is then ignored.
- `RelayAPIClient.revokePair` signs a statement at call time (`now()`), so every retry of a tombstone (PAIR-03 E3)
  signs a fresh one. `deleteDevice(revokePairs: true)` lists `GET /v1/pairs?include_revoked=false` and sends one
  statement per unrevoked pair; `revokePairs: false` sends no body. `RelayAPI` protocol signatures unchanged, so the
  Mac/iOS app models (unpair, "Delete All HandLive Data") needed no change.

Verifying:
- `PairedPhone` gains `peerSigningPublicKey` (from `PairedDeviceRecord.peerSigningPublicKey`) and
  `acceptsRevocation(_:)`: pair_id matches, `by` == phone device_id, statement present, sig verifies with the stored key.
- Used for `pair_revoked` in all three states (first presence, WaitingPeer, Connected — whatever the session's route,
  so a live LAN session no longer lets an unverified notice through) and for revoked rows in `checkPairOnRelay`
  (GET /v1/pairs). Anything else is ignored: no unpair, no data deletion.
- `handshakeFailed(_:route:)`: over the relay, a pre-auth `session/error` PAIR_UNKNOWN / PAIR_REVOKED → Backoff, never
  removePair (CONN-03 E9). LAN keeps CONN-01 E4 (unpair). Relay channels carry no close codes, and post-handshake
  `session/bye {revoked}` is encrypted, so no other relay path can unpair.

## D11 — ci-apple.yml:91

- `actions/checkout@fbc6f39… # v5.1.0` (4×), `maxim-lobanov/setup-xcode@ed7a3b1… # v1.7.0`,
  `actions/cache@0057852… # v4.3.0` (SHAs via `git ls-remote`, lightweight tags).
- `persist-credentials: false` on every checkout; branch lookup uses `gh api …/git/matching-refs` with `GH_TOKEN`
  in the env (pattern of ci-shared.yml) — no token in a git URL.

## Skipped

- ChannelInbox bound (optional item 4): bounding needs a policy (close on overflow, limit per channel); not trivial,
  left out.

## Commits (handlive-apple)

- 2ec16f3 test(apple): keep envelope ids for the whole key epoch
- 977ee7d fix(apple): keep accepted envelope ids for the whole key epoch
- 14b9dd8 test(apple): sign revocations and act only on the phone's signed statement
- 3407c91 test(apple): check the emptied de-duplication set with isEmpty
- 761b5f4 feat(apple): sign and verify the HLREVOKE1 revoke statement
- 68cd071 feat(apple): carry the signed revoke statement in the relay messages
- ef138ab fix(apple): sign every revocation sent to the relay
- 3f4fd66 fix(apple): never unpair on the relay's word alone
- 9d1bd76 ci(apple): pin actions to commit SHAs and keep the token out of git URLs

## Tests

- New: `RecentEnvelopeIDsTests` (5), `ControlSessionRekeyTests.replayAcrossRekey`, `RevokeStatementVectorTests`
  (HLCrypto, revoke.json valid vectors + tampering), `RelayFramesTests.revokeVectors` (wire form of pair_revoked,
  revoke body, revocations[]), `RevocationCheckTests` (all 7 receiver invalid vectors ignored, valid ones accepted only
  for their pair, GET /v1/pairs row), `ConnectionManagerRevocationTests` (signed notice unpairs; 4 forged/unsigned
  notices ignored while Connected and WaitingPeer; GET /v1/pairs row needs the statement; relay PAIR_UNKNOWN /
  PAIR_REVOKED → Backoff with pair kept), `RelayAPIRevocationTests` (signed revoke body, retry re-signs, delete body).
- Mutation check: removing the relay route guard or the GET /v1/pairs guard makes the new manager tests fail.
- Local (`HL_SWIFT_TESTING_PACKAGE=1 swift test`): HLProtocol 65, HLCrypto 48, HLTransport 116, HLAppCore 84,
  HLMacUI 43, HLiOSUI 23 — all pass; dev client builds; `swiftlint lint --strict` clean.
- CI: ci-apple dispatched on the branch, run 36371231424 — green (all packages, swiftlint, macOS and iOS app builds).
  It resolved hub → main, handlive-shared → fix/security-scan-findings. No flaky WebSocket reruns needed.

Status: DONE
Summary: D1 (epoch-wide dedup, record after decrypt), D2 client side (signed revoke/delete, verified pair_revoked and
GET /v1/pairs, relay pre-auth pair errors → Backoff) and D11 (pinned actions, no persisted credentials, no token in
URLs) are on handlive-apple `fix/security-scan-findings`; local tests and ci-apple are green.
Concerns/Blockers: ci-apple on this branch needs handlive-shared `fix/security-scan-findings` (revoke.json) until
shared merges to main — merge shared first. ChannelInbox bound not done (optional).

## Review fixes

Review verdict: APPROVE with minors. All four fixed on `fix/security-scan-findings`, TDD (tests committed first).

1. **Delete All signs every local pair.** `RelayAPI.deleteDevice(revokePairs:localPairIds:)`. The body signs the union
   of every pair in the local store (tombstones included) and every pair `GET /v1/pairs?include_revoked=false` lists
   as unrevoked. Ids are de-duplicated and non-canonical ids dropped. On `400 BAD_REQUEST` the client lists, signs
   again and retries once; a second 400 is reported. Callers pass `store.all()` ids: `AppModel.deleteAllData` (Mac)
   and `IOSAppModel.deleteAllData` (iOS). "Remove from server" passes `[]`.
2. **ci-apple.yml branch lookup.** The branch name is URL-encoded per path segment (`jq @uri`) in the API path and
   given to `jq --arg r`; it is no longer spliced into the jq program. Checked locally with the step script
   (resolves this branch, and returns `main` for `x"y z`).
3. **CONN-03 E9 (hub 56a7c44).** Over the relay before authentication, `AUTH_FAILED` and `UNSUPPORTED_VERSION` still
   set their issue (message) but use the normal `RECONNECT_BACKOFF` delay. The 5-minute wait and the stop apply only
   on the LAN (`scheduleBackoff(…, keepSchedule: route == .relay)`). With the fix removed, the new test fails
   (checked).
4. **First-presence state tests.** `FakeRelay.replacePresenceOnOpen(with:)` sends frames instead of the first
   presence. Four forged or unsigned notices → no unpair, and the client reaches WaitingPeer after `presenceWait`;
   the phone's signed notice → pair removed.

Commits (handlive-apple):
- fde48c4 test(apple): sign every local pair on Delete All, keep the relay schedule after forged errors
- 12c0317 fix(apple): sign every local pair on Delete All and retry once after 400
- fb39293 fix(apple): keep the backoff schedule after forged errors over the relay
- b05718d test(apple): keep the fake relay's delete record within the line limit
- 9599f88 ci(apple): pass the branch name to the ref lookup as data

Tests: HLTransport 119 (was 116), HLMacUI 43, HLiOSUI 23, HLAppCore 84, all passing; the dev client builds;
`swiftlint --strict` clean. ci-apple run 36372745669 (started by hand) is green. The new lookup resolved hub → main
and handlive-shared → fix/security-scan-findings.

### Review fixes, round 2 (hub e885957, 5aea806; 00 §0.10 DEDUP_WINDOW)

5. **Epoch id set limit.** `RecentEnvelopeIDs.limit` is 20,000 (`SessionConfiguration.dedupLimit`, so tests can
   shorten it). When a recorded id brings the current epoch's set to the limit, the rekey has not completed, and the
   session ends with 4410 REKEY_FAILED (`SessionEnd.rekeyFailed`). The receive path's lookup → decrypt → record →
   limit check moved into `ControlSession.accept(_:)`, which keeps the receive function under swiftlint's complexity
   limit. Tests: a unit test of the limit, and a session test where a limit of 3 closes with 4410.
6. **Ack bound.** The acks kept for duplicates were unbounded (up to 20,000 acks). They are now limited to 8 MiB of
   UTF-8 per session across both epochs, oldest dropped first. A dropped ack leaves the id recorded, so the duplicate
   is not processed again and gets no answer. An epoch that expires or is replaced releases its bytes. Test:
   `RecentEnvelopeIDsTests.ackBudget`.

Commits (handlive-apple): e2958a5 test, 5d8331d fix (20,000 limit), 966d445 refactor (the swiftlint fix for
5d8331d; ci run 36374632570 on 5d8331d was cancelled because swiftlint would have failed), 2754539 test, a05074d fix (8 MiB ack bound). Tests: HLTransport 122 passing locally; swiftlint clean. ci-apple on
966d445: run 36374788834, green. ci-apple on a05074d: run 36376170672, green.


Status: DONE
Summary: all review fixes are in, with tests. Delete All signs local and relay pairs and retries once after a 400;
the branch name goes to jq as data; forged pre-auth errors over the relay keep the normal backoff; the first-presence
tests are added; the epoch id set closes the session with 4410 at 20,000 ids; kept acks are bounded to 8 MiB.
Pushed; ci-apple green on a05074d (run 36376170672).
Concerns/Blockers: merge handlive-shared before apple (revoke.json).
