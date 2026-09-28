# Security fixes from the vbsec scan of 2026-09-28

**Status:** done, merged into `main` on 2026-09-28 · **Source:** `reports/vbsec-scan-2026-09-28.md` (8 MEDIUM, 9 LOW, verdict PASS) ·
**Branch:** `fix/security-scan-findings` in android, apple, relay and shared; hub changes on `main`.

The project owner asked to fix every finding and then review the fixes. The decisions below are the single source
for all agents. Specs change first (hub, English and Vietnamese in the same commit), then shared (vectors, schemas),
then the platforms.

## Decisions

### D1 — Replay protection covers the whole key epoch (findings 5, 13)

- `DEDUP_WINDOW` (00-common-specs 0.10) becomes: every envelope `id` accepted in the current key epoch, per direction.
  The epoch ends at rekey (`REKEY_AFTER`: 24 h or 10,000 envelopes per direction), so the set holds at most 10,000
  ids. While the previous epoch's keys are still accepted after a rekey, its ids are kept too.
- A duplicate `id` is handled exactly as today (acked as a duplicate, not processed again).
- An id is recorded only after the envelope decrypted successfully (a forged envelope never poisons an id).
- Sessions over the LAN and over the relay behave the same.

### D2 — Revocation is signed by the device that revokes (finding 6, Android hardening `RelayConnection.kt:218`)

- Revoke statement: `sig_r` = Ed25519(`ik_sig` of the revoking device,
  `"HLREVOKE1"` ‖ `pair_id` (16 bytes) ‖ `by` = revoking `device_id` (16 bytes) ‖ `revoked_at` (u64 big-endian ms)).
- `POST /v1/pairs/{pair_id}/revoke` body: `{revoked_at, sig}`. `DELETE /v1/devices/me?revoke_pairs=true` body:
  `{revocations: [{pair_id, revoked_at, sig}]}` — one statement per pair. The relay verifies each statement with the
  caller's stored key (`by` = the JWT subject, `revoked_at` within ±10 min of the relay clock), and refuses a missing
  or bad statement with `400 BAD_REQUEST`.
- The relay stores the statement (`revoked_by`, `revoked_at`, `revoke_sig` on the `pairs` row; the `revoked_notice`
  entry carries the same three fields) and forwards it: `pair_revoked` `{pair_id, by, revoked_at, sig}`;
  `GET /v1/pairs` returns `revoked_by`, `revoked_at`, `revoke_sig` for revoked pairs.
- Every client and the phone act on a relay revocation only when `by` is the peer's `device_id` of that pair and
  `sig` verifies with the peer's stored `ik_sig` public key. Otherwise the notice is ignored (no unpair, no data
  deleted); the user can still unpair by hand.
- Over the relay, a pre-authentication `session/error` `PAIR_UNKNOWN` or `PAIR_REVOKED` leads to `Backoff`, never to
  unpairing. Over the LAN (pinned TLS to the phone) it keeps its current meaning.
- Rows revoked before this change have no statement: clients ignore them (manual unpair).
- Test vectors: `shared/test-vectors/` gets a `revoke` vector (keys, inputs, message bytes, signature) that every
  platform checks.

### D3 — Relay auth challenge cannot be used to lock a device out (finding 7)

- `POST /v1/auth/challenge` and `POST /v1/auth/token` get a per-client-IP limit: 30 per minute for both together
  (IPv6 counted per /64, see D4), checked before any database lookup.
- The per-device quota becomes per (`device_id`, client IP): 10 per minute.
- Challenges are stored per nonce (`chal:<device_id>:<challenge>`, 60 s, GETDEL on use); a new challenge never
  replaces another pending one. `/auth/token` already echoes `challenge`, so clients do not change.

### D4 — Relay registration limits (finding 14)

- The per-IP registration limit (10 per hour) counts IPv6 addresses per /64.
- A global cap of new device registrations: `RELAY_MAX_REGISTRATIONS_PER_HOUR`, default 1,000 → `429 RATE_LIMITED`.
- At startup the relay logs a warning when `RELAY_TRUSTED_PROXIES` is empty and it binds a non-loopback address.

### D5 — Phone connection admission (findings 3, 4)

- `/v1/ctl`: next to the global cap of 16 connections without a handshake, at most 4 per IP. Besides `AUTH_FAILED`
  (current rule unchanged), handshake timeouts (4408), `PAIR_UNKNOWN` and `BAD_REQUEST` before the handshake count
  toward an IP block too: 10 of them within 5 minutes block the IP for 5 minutes (4429).
- `/v1/pair`: its own admission — at most 4 connections at once, 2 per IP, over the cap → close 4429. The first
  message (`pair/hello`) is read with an 8 KiB cap.

### D6 — Pairing window (findings 9, 10)

- A connection that has not claimed the pairing window can never close it, whatever its failure (`AUTH_FAILED`
  included): only its own socket is refused.
- PIN mode: the phone sends at most 3 `pair/offer` per PIN (the client's 3 attempts). When the third offer ends
  without `pair/done` (`PIN_INVALID`, disconnect, timeout), the window closes as "PIN expired" and the user makes a
  new PIN. The phone ignores the client's `attempts_left`. The spec records the remaining offline-guess risk of a
  single offer and a PAKE (CPace) as the long-term fix (open decision, not in this change).

### D7 — Feature checks per session (finding 2, Android hardening `SmsModule.kt:73`)

- `call_event/action` and `call_event/log_sync` answer `FEATURE_DISABLED` when calls are not in effect for the
  requesting session (`session.isEffective(Feature.CALL)`), as CALL-04 E1 already says. Same for every `sms/*`
  request with `Feature.SMS`.

### D8 — Clipboard ids (finding 1)

- Android rejects a `clipboard/push` (and `clipboard/cancel`, `clipboard/conflict`) whose `clip_id` or `transfer_id`
  is not a canonical UUIDv7 with `BAD_REQUEST`, as the schema already says; `ClipFiles` also checks that every file
  it builds stays inside its directory.

### D9 — SMS send limit (finding 12)

- Per pair: at most 10 `sms/send` per minute and 100 per day (rolling). Over the limit → `RATE_LIMITED` with
  `details.retry_after_ms`; the phone shows a notification "HandLive stopped sending messages from \<name>" once per
  day. New UI string key in `shared/strings/ui-strings.json` (en + vi).

### D10 — Share alias (finding 11)

- Intents that reach `ClipboardShareTarget` are handled only when the action is `ACTION_SEND`; the `source` and
  `mode` extras are honoured only from HandLive's own intents. No spec change.

### D11 — CI supply chain (the four OUTDATED-DEPENDENCY findings: apple, relay, android, shared)

- Every `uses:` in every workflow of the five repositories (hub `ci-docs.yml` included) is pinned to a full commit
  SHA with the tag in a comment. Every `actions/checkout` gets `persist-credentials: false`. The token is no longer
  put in a git URL: use `gh api` or `git -c http.extraheader=...`.

## Work order

1. Hub specs (00, 02, 03, 05, 06 as needed; EN + VI) and hub CI — controller or spec agent.
2. shared: revoke vector, schemas for the relay messages and `sms/send` error if they exist, UI string, CI.
3. relay, android, apple in parallel (one agent per repository).
4. Review of every branch (reviewer agents), fixes, then merge into `main` (shared first) once CI is green.

Reports: `plans/20260928-security-fixes/reports/`.

## Result

All 17 findings are fixed, reviewed (first review, fixes, a final verification round) and merged, CI green on `main`:
shared `5fc8a3f`, relay `cda13bf`, apple `6487c16`, android `41f905e`. Hub specs: `c9c42ff`…`68dc1f8`, `0f8bb82`,
`56a7c44`, `e885957`, `5aea806`; hub CI `ce5eb82`. Agent reports: `reports/specs.md`, `shared.md`, `relay.md`,
`android.md`, `apple.md` (each with its review-fix sections).

Changes the reviews added to the plan: the relay trusts a loopback proxy by default when it binds loopback and warns
on untrusted `X-Forwarded-For` (CONN-03 API 1 logic 4); pre-auth `UNSUPPORTED_VERSION`/`AUTH_FAILED` over the relay
keep the normal backoff (CONN-03 E9); the epoch dedup set closes the session with 4410 at 20,000 ids and kept acks
are bounded to 8 MiB (§0.10 `DEDUP_WINDOW`); only failures before the hello `mac` check count toward `CTL_IP_BLOCK`
and an established session clears the count.

## Open (not in this change)

- PAKE (CPace) for the PIN path: one offer still allows an offline guess within the window (02-pairing).
- `session/hello` has no replay cache: a replayed hello through the relay is not counted toward `CTL_IP_BLOCK`.
- The SMS-limit notice uses the `permission` channel, whose description is about permission suggestions.
- Relay: Redis Cluster would reject the two-key registration script (single Redis is the documented deployment);
  instances of the old and new version drop each other's `pair_revoked` bus messages during a rolling deploy.
- Apple: `ChannelInbox` has no buffer bound (needs a decision on the overflow behavior).
- Carrier NAT: 30 relay auth requests per minute per IPv4 address (about 200 devices) is accepted for now.
