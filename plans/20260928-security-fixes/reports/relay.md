# relay: security scan fixes (D2, D3, D4, D11)

Repo `handlive-relay`, branch `fix/security-scan-findings` from `origin/main` (`ee0532e`), pushed. `shared/` stayed on
`fix/security-scan-findings` (`fa0a96e`).

## Changes

### D3: relay auth cannot lock a device out
- `limits.rs`:
  - `ip_bucket()`: an IPv4 address as is. An IPv6 address counts as its /64 (`2001:db8:a:b::/64`). An IPv4-mapped IPv6 address counts as the IPv4 one.
  - `rl:ip:<ip>:auth:<minute>`: 30 calls a minute per IP, for challenge and token together.
  - `rl:<device_id>:<ip>:chal:<minute>`: 10 challenges a minute per device and IP.
  - `request_ip()`: `X-Forwarded-For` counts only from a trusted proxy, as before.
- `POST /v1/auth/challenge`, in order: the per-IP limit, then the (device, IP) quota, then the database lookup (404/410), then the new challenge.
- `POST /v1/auth/token`: the per-IP limit comes first. It then does `GETDEL chal:<device_id>:<challenge>` on the echoed challenge. A challenge that is not valid 32-byte b64u gets `CHALLENGE_EXPIRED` without a Redis call.
- Each challenge has its own key with TTL 60 s. A new challenge never replaces a pending one. `DELETE /v1/devices/me` no longer deletes challenge keys; they expire (spec SET-02 logic 5).
- The key's value is the challenge's b64u, not `1` as in the spec's Redis illustration. This keeps the constant-time comparison in `accept_presented`. The key already comes from the presented challenge, so this changes nothing on the wire.

### D4: registration limits
- `rl:ip:<ip>:reg:<hour>` counts IPv6 per /64.
- New relay-wide counter `rl:reg:<hour>`, capped by `RELAY_MAX_REGISTRATIONS_PER_HOUR` (setting `max_registrations_per_hour`, default 1000). Over the cap → 429 `RATE_LIMITED` with `Retry-After` until the end of the hour.
  - Refreshing an existing device counts toward neither limit.
  - The global cap applies even when the client IP is unknown.
- `config::proxy_warning()`: `main` logs a warning when `RELAY_TRUSTED_PROXIES` is empty and `RELAY_BIND` is not loopback. `localhost:port` counts as loopback; any other host name gets the warning.
- README (en/vi) and `.env.example` document the new variable.
  - The load-test note says to raise the cap above the number of simulated devices.
  - `shared/tools/bench/relay_load.py` uses one IPv4 10.x.y.z per device, so the /64 rule does not affect it.

### D2: signed revocation
- New migration `20260928000000_signed_revocation.sql` adds `pairs.revoke_sig BYTEA CHECK (octet_length = 64)`. `revoked_at` and `revoked_by` already existed.
- `signatures::revoke_message()`: `"HLREVOKE1"` ‖ pair_id ‖ by ‖ revoked_at (u64 BE), 49 bytes.
- New module `revocation.rs`:
  - `verify_statement()` returns 400 `BAD_REQUEST` if `revoked_at` or `sig` is missing, if `sig` is not 64-byte b64u, if `revoked_at` is negative or more than 600,000 ms from the relay clock (±10 min, inclusive), or if the signature fails strict Ed25519 verification with the caller's stored key. `by` is always the JWT subject.
  - `verify_revocations()` handles the DELETE body:
    - every unrevoked pair the relay holds needs exactly one valid statement;
    - statements for pairs the relay does not hold are ignored;
    - two statements for the same `pair_id` → 400 (the spec does not cover this case).
- `POST /v1/pairs/{pair_id}/revoke` takes the body `{revoked_at, sig, reason?}`. `reason` is optional; when present it must be one of the enum values, and it is neither signed nor stored.
  - Order: REST limit → path → reason → membership (404/403) → statement (400) → store.
  - The UPDATE stores the signed `revoked_at` as a timestamp and returns ms exactly. It also stores `revoked_by` and `revoke_sig`.
  - If the pair is already revoked, the first statement stays and the call returns 204.
- `DELETE /v1/devices/me?revoke_pairs=true` takes the body `{revocations: [...]}`, with a 64 KiB JSON limit on this resource.
  - The unrevoked pairs are read with `FOR UPDATE` and checked in the same transaction. On failure the transaction rolls back and nothing is deleted (400).
  - With `revoke_pairs=false` the body is ignored.
  - With `revoke_pairs=true` a body is required: a missing body is 400, even when the device has no pairs.
- The statement reaches every place a revocation goes:
  - `BusMessage::PairRevoked(RevokeStatement)`: bus layout pair_id ‖ by ‖ revoked_at i64 BE ‖ sig, 104 bytes. The old 32-byte form is dropped.
  - `revoked_notice` members use `<pair_id>|<by>|<revoked_at>|<sig b64u>`. Old `pair|by` members are skipped.
  - `pair_revoked` is sent as `{op, pair_id, by, revoked_at, sig}`.
  - `GET /v1/pairs` always carries `revoked_by` and `revoke_sig`, both null for pairs that are not revoked, as in the spec's example.
- Replay on reconnect (`recently_revoked`) leaves out rows that have no statement (revoked before this change). The schema requires `sig`, and clients would ignore those rows anyway.
- README (en/vi) describes the bodies.

### D11: CI
- `.github/workflows/ci-relay.yml` pins every action to a commit SHA:
  - `actions/checkout@fbc6f399… # v5.1.0` (×5, each with `persist-credentials: false`);
  - `dtolnay/rust-toolchain@6bed0761d98439e5a578e2877258200ad565ba87 # stable`, with `toolchain: stable` set explicitly;
  - `Swatinem/rust-cache@6323deb102c322ba6fcbdcafc7e3dddab59af2b6 # v2.9.2`.
- I looked up the SHAs with `git ls-remote`. For the annotated tag I used the dereferenced commit.
- The branch lookup now uses `gh api repos/<owner>/<repo>/git/matching-refs/heads/<branch>`, as ci-shared does. The token is no longer in a git URL.

## Commits (handlive-relay, `fix/security-scan-findings`)
- `dc16e77` fix(relay): limit auth calls per client IP and keep every pending challenge
- `c4eefc8` fix(relay): count IPv6 registrations per /64 and cap them relay-wide
- `e868e9f` feat(relay): add the HLREVOKE1 statement check and the revoke_sig column
- `9417377` fix(relay): revoke pairs only with the member's signed statement
- `5145569` docs(relay): describe the signed revoke bodies
- `fd72f4a` ci(relay): pin actions to commit SHAs and keep the token out of git URLs

## Tests
- New `tests/shared_revoke_vectors.rs` (no services), checked against `revoke.json`:
  - the 3 valid vectors: message bytes, signature from the seed, `verify_statement` of `revoke_request`, `verify_revocations` of `revocation`, the `pair_revoked` frame, and a bus round trip;
  - the 6 relay negatives → `BAD_REQUEST`;
  - the skew boundary (±600,000 ms accepted, +1 refused), and the DELETE matching rules.
- Unit tests: IPv6 /64 buckets, every new Redis key form, the startup warning cases, the default cap, and the bus decoder dropping the old 33-byte message.
- Integration tests (ignored by default; they need PostgreSQL + Redis):
  - D3:
    - two pending challenges both redeem;
    - the per-IP cap covers a neighbour in the same /64 and the token endpoint, and returns 429 before the 404 of an unknown device;
    - the challenge quota is per (device, IP).
  - D4:
    - the per-IP limit in a random /64 per run, with a neighbour address counted together;
    - the global cap: with cap 0 a new device gets 429 while a known device refreshes with 200.
  - D2:
    - the revoke endpoint refuses 8 bad bodies with 400 and changes nothing;
    - a stored statement is exact in the list and in the DB;
    - a DELETE with a missing or bad statement deletes nothing (6 cases);
    - notice member format, `pair_revoked` frames live, on reconnect, from a notice and across instances;
    - a legacy row is not replayed;
    - schema checks for `pair-revoke-request` (with and without `reason`), `devices-delete-request`, `pairs-list-response` after a revocation, and every `pair_revoked` frame;
    - log privacy with the statement's sig and pair id on the list of forbidden strings.
  - Test harness: `test_settings()` also sets `max_registrations_per_hour` to `u64::MAX`, because every test registration increments the relay-wide counter in the shared Redis.
- Local runs:
  - `cargo fmt --check` and `cargo clippy --all-targets -- -D warnings` are clean;
  - `cargo test -- --include-ignored` against docker compose passes: 35 test binaries green.
  - One run showed a failure in `relay_ws_forwarding::text_and_binary_frames_reach_the_paired_peer` (presence ordering). It passed 3 reruns out of 3. This code was not changed, and the host is known to be overloaded.

## CI
- ci-relay does not trigger on `fix/**`, so I started it by hand. Run 36371236971 **passed** on head `fd72f4a`: the fmt + clippy + test job and the integration job (PostgreSQL 16 + Redis 7). It resolved handlive-shared → `fix/security-scan-findings` and hub → `main`.
- The commit-policy job is skipped on `workflow_dispatch`, as designed. It will run on the PR or push to `main`.

## For other agents
- No changes in `shared/`.
- Clients must send `{revoked_at, sig}` on revoke and `{revocations: [...]}` on `DELETE …?revoke_pairs=true`. The DELETE body is required even when the device has no pairs; `{"revocations": []}` is enough.
- Clients must handle `pair_revoked` with `revoked_at` and `sig`, and `GET /v1/pairs` with `revoked_by` and `revoke_sig`, which are always present and null for pairs that are not revoked.

## Unresolved questions
- Duplicate `pair_id` in `revocations[]` → 400. The spec is silent here; should duplicates be allowed instead?
- `DELETE ?revoke_pairs=true` without a body → 400, even for a device with no pairs. The spec says the body is `{revocations: [...]}`, so this is strict but consistent.
- The Redis value of `chal:<device_id>:<challenge>` is the challenge itself, not `1` (see D3 above).
- During a rolling deploy, old instances publish 32-byte `PairRevoked` bus messages that new instances drop, and the reverse also happens. Nothing is released yet, so I did not add a compatibility path.

## Review fixes (hub spec 0f8bb82)

1. **Local proxy trusted by default (MAJOR).**
   - `config::effective_trusted_proxies()`: when `RELAY_TRUSTED_PROXIES` is empty and `RELAY_BIND` is loopback (`127.x`, `::1`, `localhost:<port>`), `127.0.0.1` and `::1` are trusted. An explicit list always wins.
   - `limits::request_ip()` logs a warning at most once a minute (`OnceAMinute`, lock-free) when a peer that is not trusted sends `X-Forwarded-For`. The line carries no address.
   - The startup warning for an empty list with a non-loopback bind stays.
   - README (en/vi) and `.env.example` updated.
2. **IPv4-mapped normalization (MINOR).**
   - `client_ip()` maps the peer, every `X-Forwarded-For` hop and each trusted entry with `to_canonical()` before comparing, and returns the normalized address.
   - `parse_ip_list()` normalizes at parse time.
   - New test `ipv4_mapped_addresses_compare_as_ipv4`.
3. **Device row lock (MINOR).**
   - `delete_with_peers` begins with `SELECT 1 FROM devices WHERE device_id = $1 FOR UPDATE`.
   - New integration test: a pair insert left uncommitted while the delete runs. The delete now waits and the check sees the pair; before the fix it saw nothing and the cascade removed the pair.
4. **Registration cap before the per-IP counter (MINOR).**
   - One Redis Lua script checks the relay-wide cap first, then the per-IP limit, and increments both only when both have room.
   - A refused request counts nowhere, so a client over its own limit also cannot use up relay-wide slots.
   - The test asserts that the IP's counter stays 0 after a cap refusal.
5. **CI (NIT).** The branch is URL-encoded with `jq -rn --arg b … '$b|@uri'` for the path and compared through `jq --arg r`, never spliced into a filter. The unused `hub` lookup is gone; only handlive-shared is resolved. Tested locally against an existing branch, `main` and a missing branch.

Also a test-only fix: `shared_schemas` failed once in a full local run because the frame read right after the revoke was not yet `pair_revoked` (frames through Redis can arrive out of order on a loaded host). The test now reads until `pair_revoked` arrives. 12 reruns after that were green.

Skipped as agreed:
- the extra `find_key` round trip on revoke;
- compatibility of the bus message during a rolling deploy (nothing is released).

Commits (handlive-relay):
- `93d598b` fix(relay): compare client addresses with IPv4-mapped IPv6 as IPv4
- `6f0a7a0` fix(relay): trust a local proxy by default and report ignored X-Forwarded-For
- `04a722e` fix(relay): check the registration cap before counting against the client
- `c11d0c5` fix(relay): lock the device row before reading the pairs it deletes
- `9104fe2` ci(relay): pass the branch name to jq as data and drop the unused hub lookup
- `7b2004e` test(relay): wait for pair_revoked in the schema check instead of taking the next frame

Checks:
- Locally: fmt and clippy are clean, and `cargo test -- --include-ignored` passes (only the order-dependent schema failure above, now fixed).
- CI run 36372270441 **passed** on head `7b2004e`: both jobs, with shared → `fix/security-scan-findings`.

Status: DONE
Summary: Review fixes 1–5 applied (local proxy trusted by default + throttled X-Forwarded-For warning, IPv4-mapped normalization, device row lock, cap checked before the per-IP counter, jq --arg in CI); CI run 36372270441 is green on 7b2004e. Earlier: D3 (per-IP auth limit, a quota per device and IP, one key per challenge), D4 (IPv6 counted per /64, relay-wide registration cap, proxy warning), D2 (signed HLREVOKE1 revocation checked, stored, forwarded and listed; migration adds revoke_sig) and D11 (pinned actions, no persisted credentials, no token in URLs) are in 6 signed-off commits on handlive-relay `fix/security-scan-findings`, pushed; CI run 36371236971 is green.
Concerns/Blockers: none blocking. See the unresolved questions (duplicate statements, a body required with revoke_pairs=true, the challenge value in Redis).
