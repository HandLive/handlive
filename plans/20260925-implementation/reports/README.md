English | [Tiếng Việt](README.vi.md)

# Agent reports

One file per task card, `phase-0N-<task code>.md` (for example `phase-01-A1.3.md`); spikes:
`phase-04-spike-d1.md`, `phase-05-spike-d6.md`. Contents: the work done,
**the list of commits (repository + hash + subject) for the task card — one commit per logical step, never bundled; a commit never spans two repositories**,
the paths created or changed, the test commands and their results (paste the real output),
measurements (if any), deviations from the docs and how they were handled, ending with:

```text
Status: DONE | DONE_WITH_CONCERNS | BLOCKED | NEEDS_CONTEXT
Summary: one or two sentences
Concerns/Blockers: optional
```

The hashes in the `phase-00-*` reports belong to the hub repository before the repository split and
before the history rewrite (2026-09-25, see `repo-split.md`); look the commits up by subject in the
`main` branch of each repository.
