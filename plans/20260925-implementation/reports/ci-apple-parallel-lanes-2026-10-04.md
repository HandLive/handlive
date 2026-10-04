# CI — ci-apple in four parallel lanes (2026-10-04)

Owner request: Apple CI too slow on GitHub; split the pipeline and run in parallel what can be. Owner choices: 4 lanes;
push a `feat/` branch to measure; then "handle every risk" the review raised.

## Before (run 37191346862, green, ~18 min, one macOS job)

| Step | Time |
|------|------|
| DerivedData cache restore + save (1.4 GB) | 56 s + 61 s |
| `xcodebuild test`, 11 packages serially, one DerivedData each | 10 min 27 s (test execution ~110 s) |
| dev client + HFP spike `swift build` | 70 s |
| Mac app + iOS app build | 1 min 49 s + 1 min 52 s |

Root causes, from the log:

- Each package recompiled its whole dependency graph: 2,869 Swift compile units for tests (GRDB 5 times).
- The DerivedData cache restored but never avoided a rebuild (fresh checkout → new mtimes); it only cost ~2 min.
- Both apps built for arm64 **and** x86_64 (457 + 457, 441 + 441 units).

## After

- `apple/Tools/make-test-scheme.sh` writes a shared scheme into the committed `HandLive.xcworkspace` (all, only,
  except; test targets read from `Packages/*/Package.swift`, so a new one lands in an `all`/`except` scheme by itself;
  generated schemes git-ignored). One `xcodebuild test` per lane builds shared packages once. `-only-testing` was
  measured and still builds every testable, hence per-lane schemes.
- Four matrix lanes on `macos-15`, `fail-fast: false`:

| Lane | Work |
|------|------|
| core | `HLTests-core`: HLProtocol, HLCrypto, HLTransport, HLAppCore tests (283 compile units) |
| features | `HLTests-features`: the other 9 test targets (649 units), then the Mac app (arm64) in the same DerivedData (5 units) |
| ios | iOS app + Notification Service Extension, simulator, arm64 |
| tools | package import check, SwiftLint, Mac app for Intel (x86_64), dev client, HFP spike |

- DerivedData cache removed.

## Risks handled (review findings and owner request "handle every risk")

| Risk | Handling |
|------|----------|
| Scheme script dropped a package's tests when `dump-package` failed (pipe hid the exit code) | dump-package runs outside the pipe under `set -e`; empty input fails; script `cd`s to the repo root; scheme names forced to the git-ignored `HLTests-` prefix. Verified with a failing `swift` shim (rc 1, no scheme written) |
| Shared products directory: an import outside a target's declared dependencies may compile depending on build order (per-package builds failed it for sure) | `Tools/check_package_imports.py` (tools lane): every import of a Packages/ThirdParty module must be in the target's dependency closure. 27 targets, 0 violations; injected violations caught with GitHub annotations |
| arm64-only app builds no longer compile x86_64 | tools lane builds the Mac app for x86_64 (523 units) |
| Push + same-repo PR runs = 8 macOS jobs > 5 concurrent (Free plan) | macOS lanes skip a PR whose head is a `main`/`feat/**` branch of this repo (the push run of the same commit covers it and shows on the PR); fork PRs and other branches still run; commit-policy still runs on PRs |
| Mac app build skipped when a feature test fails | `!cancelled()`: still a compile check |
| Reviewer tool memory untracked in the worktree (`Packages/.claude/`) | deleted |

Remaining, accepted: two different branches pushed at once still need 8 macOS jobs (3 queue a few minutes).

## Verification

- Local (fresh DerivedData): all 13 test bundles, 573 tests pass through the shared schemes; Mac app reuse 5 units;
  workspace scheme works without the generated `HandLive.xcodeproj`.
- `actionlint`, `shellcheck -s sh`: clean. Commit policy: clean.
- GitHub runs on `feat/ci-apple-parallel` (all green):

| Run | Content | Wall |
|-----|---------|------|
| 37197563078 | four lanes | 3 min 8 s (core 3:02, features 2:57, ios 2:38, tools 1:11) |
| 37198142932 | + script and docs fixes | 4 min 8 s (features 3:59 on a slower runner) |
| 37198443639 | + import check, Intel build, PR dedupe | 4 min 6 s (core 3:56, features 3:57, ios 2:15, tools 3:08: import check 11 s, Intel build 95 s) |

- Coverage parity confirmed by the reviewer per bundle against the old run (13 bundles, 573 tests).
- Lane times vary ±1 min between runs with runner speed (core `xcodebuild test` 151 s → 195 s on identical code);
  the run takes ~3–4 min against ~17–18 before.

## Commits (branch `feat/ci-apple-parallel`, pushed, not merged)

| Repo | Commit | Subject |
|------|--------|---------|
| apple | `17527b3` | build(apple): script for shared package test schemes in the workspace |
| apple | `a27cd0b` | ci(apple): four parallel lanes that build each package graph once |
| apple | `513d3a2` | fix(apple): test scheme script stops instead of dropping a package's tests |
| apple | `15d02f4` | ci(apple): build the Mac app even when a feature test fails |
| apple | `e4a40c6` | build(apple): check package imports against declared dependencies |
| apple | `dd88cbe` | ci(apple): import check, Intel Mac build, no duplicate pull request runs |
| hub | `36d7bc3` | docs: ci-apple runs four parallel lanes |
| hub | `4617bc6` | docs: ci-apple tools lane checks imports and builds for Intel |

## Unresolved questions

- Merge `feat/ci-apple-parallel` into `main` (apple + hub) when the owner says so.

Status: DONE
Summary: ci-apple runs in four parallel lanes (~3–4 min instead of ~17–18) with test coverage unchanged and the
coverage the per-package builds gave (import closure, x86_64) kept by the tools lane.
Concerns/Blockers: none.
