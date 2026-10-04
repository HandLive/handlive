# CI diagnosis — Apple "never builds" (hangs ~90 min) + CALL-05 ErrorCode failure (2026-10-03)

Investigation of `/ck-debug`: why Apple CI does not complete, and whether tests are just slow.

## Executive summary

Apple CI has **two distinct problems**; Android CI is healthy.

1. **(Main blocker) The `xcodebuild test (every package)` step hangs in the `HLTransport` package.** One of its
   real-network tests (Bonjour / loopback socket: `PairingSearchTests` / `PairingExchangeTests`) blocks forever in the
   CI runner, with **no per-test timeout**, so the step never finishes and the job is killed by its own
   `timeout-minutes: 90` — reported as `cancelled` at ~5400–5550 s. This is **not** "tests are slow": HLProtocol,
   HLCrypto and most of HLTransport finish in seconds; one test never returns. Pre-existing (seen 2026-09-29/30) and
   **still present now** (the 2026-10-03 dispatch `37090324415` hung ~90 min on the same step).

2. **(Resolved) The CALL-05 push run failed on an ErrorCode test**, not a hang: the Swift `ErrorCode` enum has
   `CALL_APP_ACTION_UNAVAILABLE` but the `shared`/`docs` checkout the run used did not yet, so
   `PrimitiveEncodingTests` ("ErrorCode đúng bảng 0.8.1…") failed in ~0.3 s and the step ended (run `37089237678`,
   ~203 s). Cross-repo ordering: Apple was tested before the `shared` contract reached the ref Apple CI checks out.
   Now that `shared@main` (af3629f) and hub docs include the code, the next dispatch passed HLProtocol (it reached —
   and hung in — HLTransport), so this one is cleared.

## Technical analysis

- `.github/workflows/ci-apple.yml`: job `timeout-minutes: 90` (line 54). Step "xcodebuild test (every package)"
  loops `HLProtocol HLCrypto HLTransport HLDesignSystem HLLocalization HLAppCore HLSMS HLSMSUI HLCalls HLMacUI
  HLiOSUI`, running `xcodebuild test -scheme <pkg> -destination 'platform=macOS'` per package. **No**
  `-test-timeouts-enabled` / `-default-test-execution-time-allowance`, so a stuck test is never force-failed.
- Old hung run `36674959195`: every step < 1 min except `xcodebuild test (every package)` = **5342 s, cancelled**.
  Its last test markers (05:50:07–05:50:15): "WebSocket over TLS 1.3 on loopback" and "PAIR-01 handshake vectors"
  suites passed, then **~85 min of silence** → the next HLTransport suite hangs.
- `HLTransport` tests using real networking: `PairingSearchTests`, `PairingExchangeTests`, `TLSTestServer`
  (NWListener/NWBrowser/NWConnection, `_handlive._tcp` Bonjour). A Bonjour browse/advertise or socket wait that never
  resolves in the CI sandbox (no mDNS responder) blocks indefinitely. The 2026-10-01 handoff already named
  "PairingSearchTests hang in HLTransport" as pre-existing.
- Not a compile error (CI compiled and ran tests) and not the local `_TestingInternals` issue (that was local `swift
  test`).

## Recommendations (fix is out of scope for this investigation — hand to /ck:fix)

1. **Stop the hang from eating the whole job**: add test timeouts to the step, e.g.
   `xcodebuild test … -test-timeouts-enabled YES -default-test-execution-time-allowance 120 -maximum-test-execution-time-allowance 300`.
   A stuck test then fails that package in minutes instead of hanging 90 min.
2. **Fix the hanging test(s)**: make `PairingSearchTests` / `PairingExchangeTests` not depend on live Bonjour/mDNS —
   inject a fake browser/listener (the codebase already has `FakePairingPhone`, `InMemoryChannel`), or gate the
   real-network cases behind an env flag skipped in CI (`.enabled(if: ProcessInfo…["HL_NET_TESTS"] != nil)`), or wrap
   the await in a bounded `withTimeout`.
3. **Avoid the cross-repo ErrorCode failure in future**: when a `shared` contract changes, land `shared` on `main`
   first, then start Apple/Android CI by hand (already the documented order) — or pin Apple CI to the PR's matching
   `shared` branch.
4. Lower-priority: the `commit-policy` job passes; the earlier swiftlint debt (`HLMacUI/AppModel.swift` length,
   `HLTransport/PairingSearch.swift`) is a separate `--strict` lint failure, only reached after the test step, so it is
   currently masked by the hang.

## Evidence

- `gh run list --repo HandLive/handlive-apple`: dispatch runs `cancelled` at 5437/5427/5523/5551 s; push CALL-05 run
  `37089237678` `failure` 203 s; dispatch `37090324415` (2026-10-03) `in_progress` ~90 min on the test step.
- `gh run view 37089237678 --log-failed`: `PrimitiveEncodingTests.swift:78` ErrorCode expectation failed —
  `CALL_APP_ACTION_UNAVAILABLE` present in the enum, absent from the spec codes the run read.
- `gh run view 36674959195 --json jobs`: `xcodebuild test (every package)` cancelled after 5342 s; all other steps
  < 60 s.
- `ci-apple.yml` lines 54, 124–137 (job timeout; per-package xcodebuild loop, no test timeout).

## Open questions

- Exact hanging test name: narrowed to HLTransport real-network suites (`PairingSearchTests` /
  `PairingExchangeTests`); confirm by running that package locally with `-test-timeouts-enabled YES` or checking the
  cancelled run's `::group::xcodebuild test HLTransport` tail.
- Android CI is green now (dispatch `37090322025` success, 450 s); no action needed unless the `shared` contract
  re-run surfaces a vector mismatch.

Status: DONE
Summary: Apple CI never completes because an HLTransport real-network test hangs and the 90-min job timeout kills the
run; the CALL-05 ErrorCode failure was a cross-repo ordering issue now resolved by shared@main. Android CI is healthy.
Concerns/Blockers: the hang is still live (2026-10-03 dispatch hung); needs the test-timeout + fake-network fix before
Apple CI can go green.
