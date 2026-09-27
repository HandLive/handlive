# Phase 3 merge into main (2026-09-28)

The project owner asked to wrap up Phase 3 and move to the next phase. As with Phases 1 and 2, this deviates from plan
decision I3 ("merged into `main` once the measurable criteria are met"): the Phase 3 checks on real devices stay open
and must pass before the first release, with gates G1 and G2.

## Merges

Same procedure as Phase 2: a signed-off merge commit without fast forward, shared first. Checked before each merge:
`main` had no commits of its own since the branch point, and `git merge-tree` found no conflicts. After each merge the
tree was compared with the branch head that was green on CI, and they were identical.

| Repository | Merge commit | Commits merged | CI |
|------------|--------------|----------------|----|
| handlive-shared | `acb8c69` | 60 | green on `main` |
| handlive-apple | `d8a9c93` | 81 | green on `main` |
| handlive-android | not merged yet | 75 (head `cf567c8`, green on the branch) | — |
| handlive-relay | — | no Phase 3 change | — |

**handlive-android is waiting for the owner.** This session's permission settings refused the push of the Android
merge commit to `main`, so it was not made. The branch head `cf567c8` passed `gradlew check` on CI. To finish, from
the workspace root, the same procedure:

```sh
git -C android fetch origin
git -C android worktree add --detach /tmp/hl-merge-android origin/main
git -C /tmp/hl-merge-android merge --no-ff --signoff origin/feat/phase-03-calls -m "Merge branch 'feat/phase-03-calls'"
git -C /tmp/hl-merge-android push origin HEAD:main
git -C android worktree remove /tmp/hl-merge-android
```

Until then, Android's `main` is Phase 2 code while shared `main` already has the Phase 3 catalog and schemas; nothing
runs CI on Android `main` in between.

Last fixes before the merge (all found end to end, `phase-03-e2e-1.md`, `phase-03-android-e2e-fixes.md`):

- **apple:**
  - `50c6c17`: the connect timeout no longer cancels a connection that is already open.
  - `1d1464e`: the call panel is sized to its content on macOS 26.
  - `365bb4e`: echoes of a sent clip are ignored.
  - `18706f0`: an empty text is never sent.
  - `81a66d5` and `4b41bab`: an image file copied in Finder is sent as the image.
  - `34e2191`: the PIN search keeps retrying while the phone waits for the PIN.
- **android:**
  - `728b43f`: the phone does not rewrite content it holds.
  - `0cd3a61`…`c0d2d51`: the PIN pairing window fixes.
  - `9415777`: permissions are read again for each new session's capability.
  - `cf567c8`: the feature list opens after the first pairing.
- **shared:** `88da57a`, the harness returns to Devices after the feature list.
- **hub specs:**
  - `6b78fb2`: clip echoes.
  - `6961592`: Finder images and empty text.
  - `4091655`: the PIN window.
  - `a75df55`: the first pairing.

## Still open before the first release

1. **Gate G1** and **gate G2**, and the Phase 2 checks on real devices, a real relay, APNs and FCM
   (`phase-02-merge.md`).
2. **Phase 3 on real devices:**
   - calls on a Pixel and a Samsung: two SIMs, withheld callers, `acceptRingingCall`/`endCall` on OEM builds, and
     Android 10–11;
   - the targets: panel under 300 ms after `RINGING`, answer under 500 ms at the 95th percentile, and an iPhone
     decline in under 2 s through a real relay and APNs;
   - Focus on a real Mac, TalkBack and VoiceOver.
3. **End-to-end reruns on a quiet host:**
   - the PIN pairing fixes (asked for by the session that made them);
   - the capability after a late permission grant and the feature list after the first pairing;
   - the 4408 check on API 29.

   None of these was run on emulator-5580, since it holds the pairing the owner uses with the Mac test app.
4. **Proposals not yet in the specs:**
   - the Devices empty state names only the clipboard (PAIR-02 field 11);
   - "Keep HandLive Running" needs a reason sentence on other manufacturers (SET-01 fields 7–9);
   - a grace period before the call panel's "connection lost" line (CALL-03 E6);
   - resetting the reconnect backoff only after a stable session;
   - the bench start point for withheld callers (`phase-03-spec-sync-2.md`, question 1).
5. **Test machine:** the host's load (`fileproviderd`, the Synology Drive file provider, Spotlight, other builds)
   freezes the emulator for several seconds at a time. Timing results from this machine do not count.

## Next

Phase 4 (taking calls on the Mac) started on `feat/phase-04-call-audio` in handlive-apple, from `main` `d8a9c93`, with
the spike of gate G4:

- The probe `apple/Tools/HFPSpike` (`f1b5bff`, `45f81b5`, `12050ea`) is ready.
- The spike needs a real phone paired over Bluetooth and a real call (`phase-04-spike-d1.md`).
- No other Phase 4 task card starts before G4.
- handlive-android and handlive-shared get their `feat/phase-04-call-audio` branches when their cards start.

Status: DONE_WITH_CONCERNS
Summary: Phase 3 is merged into main in handlive-shared and handlive-apple; handlive-android is ready (green branch head, no conflicts) and waits for the owner to push its merge commit.
Concerns/Blockers: the Android merge push was refused by the session's permission settings; the Phase 3 real-device checks, gates G1 and G2 and the end-to-end reruns listed above are open.
