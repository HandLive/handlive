# release-apple split into sign, launch and publish (2026-10-05)

Roadmap follow-up of `release-pipeline-2026-10-04.md` and `security-scan-beta2-2026-10-04.md` (owner item: split before adding the macOS secrets).

## Job graph

`sign` (matrix ios, macos) -> `launch` (needs sign) -> `publish` (needs sign, launch).

| Job | Runner | Environment | Permissions | Secrets context |
|---|---|---|---|---|
| sign | macos-15 | release | contents: read | yes: `HANDLIVE_REPOS_TOKEN` (checkout and tag lookup steps) and the 7 macOS secrets (each only in the env of its own step) |
| launch | macos-15 | none | `{}` | none (0 references, checked with awk over the job) |
| publish | ubuntu-latest | release | contents: write | none referenced; `github.token` for `gh` |

- sign: tag check, 3 checkouts, version check, SQLCipher + pinned XcodeGen, iOS IPA / Mac app, ad-hoc DMG or Developer ID sign + notarize + staple (moved verbatim), SHA-256 per file, upload `build-<platform>-<version>`. Nothing executes the built app.
- launch: downloads `build-*-<version>`, `shasum -c`, IPA `unzip -t` + `Payload/HandLive.app/Info.plist` present, mounts the Mac DMG read-only, copies the app, `codesign --verify`, runs it 10 s (same check as before, now the only place the app runs). No repo checkout.
- publish: downloads, requires the IPA, every file has a `.sha256` and matches (`sha256sum --check --strict`), uploads `apple-<version>`, attaches to the Release (attach logic unchanged, `publish`/`replace` inputs honoured).

Unchanged: artifact names (`build-<platform>-<version>`, `apple-<version>`), file names, `.sha256` per file, pinned XcodeGen and the workflow's own `fetch-xcodegen.sh` for older tags (7121ab1), concurrency group. `release-collect` reads Release assets only, so it is unaffected.

## When adding the seven secrets

1. Set them as environment secrets of `release` in handlive-apple (list in `docs/deployment-guide.md`, macOS). No workflow edit: the `macOS signing secrets` step counts them (all or none) and `sign` takes the Developer ID path (steps after the PLACEHOLDER marker, already present).
2. Output is then `HandLive-<version>-macos.dmg`; `launch` runs the notarized DMG's app.
3. Any new step that needs a secret goes inside `sign` between the marker and "Remove the release keychain"; never in `launch` or `publish`. Nothing in `sign` may run the built app.
4. Run once by hand (`publish=false`) on a tag to prove the signed path before a real tag: that path was moved, not re-run.

## Validation

- `actionlint` clean; awk check: 0 occurrences of "secrets" in the launch job.
- The jobs were not dispatched (per instructions): the signed (Developer ID) path and the launch DMG mount are untested on a runner. The Developer ID steps are unchanged text except `if:` guards (`matrix.platform == 'macos'`) and `VERSION` env.
- Hub: `check_bilingual_docs.py` pairs=74 problems=0.

## Behaviour changes to know

- `sign` now uses environment `release`, so `release-apple` runs only from tags `v*` and `main` (by hand too); before, the build job ran from any ref.
- A tag without a Mac DMG (v0.1.0-beta.1 style) publishes only the IPA: macOS leg uploads nothing (`if-no-files-found: ignore`), launch prints a notice.
- Publish runs on ubuntu instead of macOS (no Apple tool needed).

## Commits

| Repo | Branch | Hash | Message |
|---|---|---|---|
| apple | ci/release-apple-split-jobs | 6836366 | ci(apple): split release-apple into sign, launch and publish jobs |
| hub | docs/release-apple-split-jobs | bc5a9a9 | docs: describe the three release-apple jobs |

Not pushed, no PR. The unrelated `iOS/Info.plist` change in apple was left untouched.

## Unresolved questions

- `sign` builds third-party code (Swift packages, build phases) in a job whose environment holds the seven secrets; they are not in job env, but a malicious build phase could still reach the runner's secret store. Full isolation would need a fourth job (build without environment, then sign). Owner decision: accept or split further?
- Is restricting by-hand runs to `v*`/`main` acceptable, or should an unprotected branch variant exist for workflow testing?
