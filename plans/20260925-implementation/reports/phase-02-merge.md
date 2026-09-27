# Phase 2 merge into main (2026-09-27)

The project owner asked to merge Phase 2 into `main` and start Phase 3. As with Phase 1, this deviates from
plan decision I3 ("merged into `main` once the measurable criteria are met"), which now records the exception:
gates G1 and G2 and the Phase 2 checks on real devices, a real relay, APNs and FCM stay open and must pass
before the first release.

## Merges

Each code repository merged `feat/phase-02-sms-ios-relay` into `main` with a signed-off merge commit (no fast
forward, so the phase boundary stays visible). Checked before merging: `main` had no commits of its own since the
branch point and `git merge-tree` found no conflicts, so every merge commit has exactly the tree of the branch
head that was green on CI (compared after each merge). The only shared change after a platform's last branch CI
run was catalog entries of other platforms (the Mac-only `common.view_instructions_ellipsis` and the iOS-only
`common.view_instructions`), which no Android or relay build reads.

| Repository | Merge commit | Commits merged | CI on `main` |
|------------|--------------|----------------|--------------|
| handlive-shared | cfcc012 | 41 | green; merged first, since the platform CIs check out shared `main` |
| handlive-relay | ee0532e | 42 | green |
| handlive-android | 9d349ab | 71 | green |
| handlive-apple | 3b1703b | 107 | green on the re-run; the first run failed one loopback test in HLTransport (`WebSocketIntegrationTests`, "Text and binary frames, ping/pong and a private close code…": the client saw the close without its code). The tree is the same as the green branch head, so the test is flaky; the Apple agent investigates and fixes it on `feat/phase-03-calls` |

The hub and `HandLive/.github` work on `main` directly. The `feat/phase-02-sms-ios-relay` branches stay on
GitHub for reference and can be deleted.

## Still open before the first release

1. **Gate G1** (Phase 1): the device matrix of `shared/tools/bench/README.md` on real phones and Macs.
2. **Gate G2**: the Play Console Permissions Declaration Form and the Data safety form
   (`docs/deployment-guide.md`); `READ_CALL_LOG` joins with Phase 3.
3. **Owner inputs**: the relay host and a backup certificate pin; the APNs `.p8` key; the Firebase project and
   service account; registering `app.handlive.ios`, its extension and the App Group; the user-assigned device name
   entitlement; a logo and an app icon.
4. **Phase 2 real-device checks**: two SIMs, the SMS latency targets, LAN ↔ relay switching, a push to a real
   iPhone in < 2 s, FCM wake-ups, the extension locked and unlocked and under 30 MB, TalkBack, VoiceOver, 200 %
   text and AX5 in both languages, Delete All on Android 10–15, the system setting names.
5. **Relay at scale**: a load test across two relay instances and a VPS run with TLS.

Details: `phase-02-summary.md`.

## Next

Phase 3 (call information and control) started on `feat/phase-03-calls` in handlive-shared, handlive-android
and handlive-apple, created from the merged `main` (`phase-03-cuoc-goi.md`, section "Branch and work order");
handlive-relay needs no change.

Status: DONE_WITH_CONCERNS
Summary: Phase 2 is merged into main in handlive-shared, handlive-relay, handlive-android and handlive-apple.
Concerns/Blockers: gates G1 and G2 and the Phase 2 checks on real devices, a real relay, APNs and FCM have not
run; they need real phones, Macs, an iPhone and the owner inputs above.
