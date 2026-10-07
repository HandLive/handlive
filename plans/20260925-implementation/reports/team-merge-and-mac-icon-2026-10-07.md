# Merges and the Mac Liquid Glass icon (2026-10-07)

Owner, 12:50: "hãy tự merge luôn đi, ngoài ra làm luôn Liquid Glass cho mac" (merge them yourselves, and do Liquid
Glass for the Mac). The lead now merges PRs that passed the BA, Tester and Pentester review.

## Merges (merge commits, dependency order)

| Repo | PRs | `main` after | CI on `main` |
|------|-----|--------------|--------------|
| hub | #15 → #16 → #18 (base moved to `main`) → #17 | `766ad8f` | ci-docs green (37578474764) |
| android | #8 → #9 (base moved to `main`) | `a93b81b` | ci-android green (37578536324) |
| shared | #6 → #7 (base moved to `main`) | `1fb2b06` | ci-shared green (37578541202) |
| apple | #5 → #6 → #7 | `5f54b5d` | ci-apple green, 5 jobs (37578571059) |

Runs on the intermediate merge commits were cancelled by the workflows' concurrency; the head runs cover the final
code. Review of the merge task: all 11 merged in order, no open PR left in the five repositories, commit identities
clean (the merge commits carry the owner's GitHub account), no secret files, bench and e2e self-tests green on `main`.

## Mac Liquid Glass icon

- apple #8: one `AppIcon.icon` in `macOS/HandLive/Resources/` shared by both targets; `AppIcon.appiconset` removed
  (`actool` ignores it once a `.icon` exists); the Mac target asks for every `.icns` size
  (`ASSETCATALOG_COMPILER_STANDALONE_ICON_BEHAVIOR = all`). The owner accepted losing the compact mark at 16/32 pt.
- The first CI run failed both Mac app lanes: on `macos-15` (Xcode 26.3) `actool`'s AssetCatalogAgent crashed rendering
  the Mac `.icon` (missing system framework symbol), while the iOS lane rendered the same file. The macOS job of
  `ci-apple` and the `sign` job of `release-apple` now run on `macos-26` (Xcode 26.6): run 37579854640 green on all
  five jobs. The release `launch` check stays on `macos-15` so the app is still started on a macOS older than 26
  (review finding). Building the Mac app locally needs macOS 26 + Xcode 26 (apple README/CLAUDE, deployment guide).
- hub #19: the brand generator drops the icon-set path and writes the shared `.icon`; Mac previews at 16/32/128/512 pt;
  `brand-guidelines` 1.2 (en, vi) and `deployment-guide` updated.

## Risks

- `release-apple` runs only on a tag: `sign` on `macos-26` and `launch` on `macos-15` are unproven until the next tag.

## Unresolved questions

- Owner: should an app call ended `unknown` keep `answered_at`? Today `null`, like E10.

Status: DONE_WITH_CONCERNS
Summary: 11 PRs merged with green CI on every `main`; the Mac uses the Liquid Glass icon with macOS jobs on `macos-26`.
Concerns/Blockers: the release workflow's macOS jobs wait for the next tag to be proven.
