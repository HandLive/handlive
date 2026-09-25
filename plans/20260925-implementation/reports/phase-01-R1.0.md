# Phase 1 — R1.0: relay signature checks against the shared vectors

Relay part of S1.1: tests in `crates/relay-server/tests/` that load `../shared/test-vectors/relay-auth.json` and `ed25519.json` (handlive-shared `feat/phase-01-clipboard`, commits ea38d2a and f30c1cd, report `phase-01-S1.1.md`) and run the relay's own registration and token verification against them. Branch `feat/phase-01-clipboard` of handlive-relay, pushed; CI `ci-relay` green (run 36157163156, with handlive-shared resolved to `feat/phase-01-clipboard`).

## What was done

- **`crates/relay-server/tests/shared_signature_vectors.rs`** (6 tests), through the same pure functions the routes call:
  - `ed25519_rfc8032_vectors_sign_and_verify` — RFC 8032 §7.1 TEST 1–3: `ed25519_dalek` re-derives the public key from the seed and reproduces each signature; `verify_device_signature` accepts it.
  - `ed25519_invalid_vectors_are_rejected` — the six negative vectors (tampered message, R or S, wrong key, S + L, 63 bytes) return `SIGNATURE_INVALID` (or cannot be 64 bytes, for `signature_length`).
  - `relay_auth_registrations_are_accepted` — each `HLREG1` request parses into `RegisterRequest`, `registration_message` gives the vector's `message`, the seed reproduces `sig`, and `verify_registration` (clock at the request's `ts`) returns the key; platforms macos, android and ios are all covered.
  - `relay_auth_token_proofs_are_accepted` — each `HLAUTH1` request parses into `TokenRequest`, `auth_message` gives the vector's `message`, and `check_token_proof` with the issued challenge and the stored key succeeds.
  - `relay_auth_invalid_requests_are_rejected` — all ten negative requests fail as the routes would answer: 400 `BAD_REQUEST` for the 63-byte signature (the route's `b64u::decode_field`), 401 `SIGNATURE_INVALID` for tampered ts/platform/challenge, a device_id not derived from the key, a swapped label, a wrong key and S + L; the set of `reason` values is asserted so new kinds of negative vectors are noticed.
  - `relay_auth_keys_match_device_id_vectors` — every key/device_id pair of `relay-auth.json` is one of `device-id.json`.
- **CI fix** (`.github/workflows/ci-relay.yml`): since 61ed04b on `main`, both jobs failed at their first step because the branch-resolution step inherited `working-directory: relay` before the checkout creates `relay/` (main's run 36151520985 failed the same way). The step now runs in the workspace root; the first push of this branch failed for that reason (run 36156847624), the second is green.

No relay source changed: the existing `verify_device_signature` (strict Ed25519, device_id derived from the key), `verify_registration` and `check_token_proof` already agree with every vector.

## Commits (handlive-relay, branch `feat/phase-01-clipboard`)

| Hash | Subject |
|------|---------|
| 7219a3f | test(relay): check registration and token signatures against the shared vectors |
| 61c37f2 | ci: resolve the matching branches before relay/ exists |

## Files

Created: `relay/crates/relay-server/tests/shared_signature_vectors.rs`. Changed: `relay/.github/workflows/ci-relay.yml`.

## Tests (real output, from `relay/`)

```text
$ export PATH=/opt/homebrew/opt/rustup/bin:$PATH; cargo fmt --check && cargo clippy --all-targets -- -D warnings && cargo test
    Finished `dev` profile [unoptimized + debuginfo] target(s) in 1.37s
     Running tests/challenge_and_token_proof.rs  → test result: ok. 6 passed; 0 failed
     Running tests/db_auth_and_jwt.rs            → test result: ok. 0 passed; 0 failed; 4 ignored
     Running tests/db_schema_and_registration.rs → test result: ok. 0 passed; 0 failed; 2 ignored
     Running tests/device_identity_vectors.rs    → test result: ok. 3 passed; 0 failed
     Running tests/error_responses.rs            → test result: ok. 3 passed; 0 failed
     Running tests/jwt_tokens.rs                 → test result: ok. 5 passed; 0 failed
     Running tests/registration_validation.rs    → test result: ok. 5 passed; 0 failed
     Running tests/shared_signature_vectors.rs   → test result: ok. 6 passed; 0 failed
     Running tests/signature_verification.rs     → test result: ok. 4 passed; 0 failed

$ gh run list -R HandLive/handlive-relay --branch feat/phase-01-clipboard
completed success ci: resolve the matching branches before relay/ exists              ci-relay feat/phase-01-clipboard push 36157163156
completed failure test(relay): check registration and token signatures against the…  ci-relay feat/phase-01-clipboard push 36156847624
```

CI log of run 36157163156: `hub → main, handlive-shared → feat/phase-01-clipboard`; `tests/shared_signature_vectors.rs … test result: ok. 6 passed`; the integration job (PostgreSQL 16 + Redis 7, `cargo test -- --ignored`) passed too.

## Spec deviations and proposals

- `main` of handlive-relay still has the broken workflow until this branch merges; any other `feat/**` branch of the relay fails CI the same way until it picks up 61c37f2.
- The workspace `Cargo.toml` says `license = "UNLICENSED"` while the repository is Apache-2.0 (`LICENSE`, code-standards); proposal: `license = "Apache-2.0"` (not changed here, out of this card's scope).

## Pending manual checks

None.

Status: DONE
Summary: The relay's registration and token verification pass every positive vector and reject every negative vector of relay-auth.json and ed25519.json (6 new tests); a CI workflow bug from main that failed every run was fixed, and ci-relay is green on feat/phase-01-clipboard.
Concerns/Blockers: none.
