# Review: clipboard image item precedence (android) and phone → Mac image e2e (shared) — 2026-10-05

Read-only review. Diff 1: handlive-android `fix/clipboard-image-item-precedence` (ad46b80, 4f19dc8, 98c77a7 on `main`
a4b2fb7). Diff 2: handlive-shared `feat/e2e-phone-to-mac-image` (60724af … 4c655b2 on `main` 7254abe). Spec checked
against hub `docs/detailed-design/04-clipboard.md` (CLIP-01 API 2 logic 2, CLIP-03 API 1 logic 1, API 3/4, E10) and
its `.vi.md` twin (both carry the new wording: lines 276 and 796).

## Critical

None.

## Important

### I1 — Android: the second E3 flavour leaves no `clip_read_failed` line
`feature/clipboard/src/main/kotlin/app/handlive/android/feature/clipboard/module/LocalClipIntake.kt:91-93`.
`clip_read_failed` is emitted only from `ClipReader.copyImage` (stream open/copy). When the copy succeeds but
`AndroidImageNormalizer` returns `null` (`content == null` → `IMAGE_UNREADABLE`), nothing is logged; E1
(`clipSendImages = false`) also deletes silently. Scenario on the S25: the provider streams fine, ImageDecoder rejects
the bytes or the format → manual toast only, HLBENCH empty, the owner's debugging question stays open.
`tools/bench/README.md:64` claims E3 coverage. Fix: one `BenchLog.event(CLIP_READ_FAILED, "reason" to
"image_unreadable", "stage" to "normalize", "source" to read.source)` in that branch (add `stage` to the README row),
or narrow the README to copy-stage failures.

### I2 — Shared: an exception in `_auto_answer` now hides the event from scenarios
`tools/e2e/mac_session.py:259-266`. `_auto_answer` runs before `events.append`; `_receive_loop` (226-229) swallows any
exception from it. A push lacking `transfer.chunk_count`, `mime` or `kind` (KeyError in `_begin_incoming` /
`_add_chunk`), or `TransportClosed` from `send_ack`, now drops the push from `events`, so the scenario reports
"no clipboard/push in 30 s" instead of the schema violation already recorded. Before the reorder the event was
published first. Fix: wrap `_auto_answer(msg)` in `try/except Exception as exc: self.violations.append(f"auto answer
failed: {exc!r}")`, then append and notify unconditionally.

### I3 — Shared: `self_test.py` never exercises the fake Mac's answer path
`loopback` still covers Mac → phone text (`s.request("clipboard", "push", …)`, acked by the fake phone) — passes. It
has never sent a phone → Mac push, so `_auto_answer`'s text branch and the new `_begin_incoming` / `_add_chunk` /
`CLIP_CHECKSUM_MISMATCH` ack have zero self-test coverage; the only coverage is the emulator run. Add to `loopback`:
`phone.emit("clipboard", "push", {text…})` then assert `clip_id in s.applied_clips`; one 2-chunk transfer via
`phone.send(C.seal(k_s2c, "clipboard", C.chunk_plaintext(…)))` asserting `received_transfers[clip]["status"] ==
"applied"`; one corrupted chunk asserting the ack `CLIP_CHECKSUM_MISMATCH` with `details.transfer_id`.

## Minor

### M1 — Android: description MIME overrides a provider that says "not an image"
`ClipReader.kt:81-87`: `provided?.takeIf { it.startsWith(IMAGE) } ?: described`. When `getType` returns
`text/plain` but the `ClipDescription` lists an `image/*` type, the item is an image. Pre-existing for URI-only items
(DocumentsUI multi-file copy); new for an item with `text` + a text URI + such a description: text bytes copied as an
image → normalize fails → text dropped, "Couldn't read the image" on the manual path. Spec logic 1 says "or", so this
needs a spec decision: trust `getType` when non-null, fall back to the description only when the provider is silent.

### M2 — Android: `authority` of a raw non-`content://` URI is a copied fragment
`ClipReader.kt:46`. `ClipData.newRawUri` items may carry `https://host/…` next to text; with a description `image/*`
the branch logs `authority=host`. Debug builds only, but QC2 says content is never logged. Fix: log `uri.authority`
only when `uri.scheme == "content"`, else the scheme. In that case `openInputStream` fails → `IMAGE_UNREADABLE` and the
text beside it, sent before this change, is now dropped — spec-sanctioned by the new logic 2, noted only.

### M3 — Android: stale wording
`LocalRead.kt:16` KDoc of `PERMISSION_LOST` says "skipped silently"; `ClipReaderTest.aRevokedGrantIsSkippedSilently`
likewise. The manual path now shows E10's message. Update the KDoc; rename the test.

### M4 — Android: `provided` branch untested
Robolectric's `ShadowContentResolver.getType` returns `null` for the unregistered `com.example.photos` authority, so
every test takes the `described` fallback. Register a provider (`Robolectric.setupContentProvider`) returning
`image/jpeg` with a description `image/png` and assert `mime == "image/jpeg"` (provider wins).

### M5 — Shared: fake Mac vs CLIP-03 API 3/4 (harness simplifications, document in the module docstring)
`mac_session.py:301-344`. (a) Out-of-order or duplicate chunk ends in `CLIP_CHECKSUM_MISMATCH`; API 4 logic 2 says
`BAD_REQUEST` for the push — `in_order` exposes it, acceptable. (b) A second push while a transfer is open: both kept,
the old one never acked (API 3 logic 2: replace and ack `ignored`/`cancelled`) — the phone waits 10 s (E8) for the
superseded transfer. (c) No logic-1 pre-checks (size, chunk_size, chunk_count, `mimes`); `chunk_count = 0` completes
on the first chunk, no crash. (d) Mismatch ack carries `details.status` + `transfer_id`, not the `clip_id` of the
spec example; `error.schema.json` leaves `details` free and Android matches by `re` (`ClipSender.deliver`) — harmless.

### M6 — Shared: HTTP server hygiene
`scenario_clipboard.py:179-193`. `server.shutdown()` without `server_close()` leaves two listening sockets until GC;
bind `127.0.0.1` rather than `0.0.0.0` (the emulator reaches the host loopback at 10.0.2.2; all-interfaces exposes
the file on the LAN).

### M7 — Shared: wasted waits and the real-phone case
`_wait_transfer(s, clip_id, 30)` runs even when the push had no `transfer` (text path) — short-circuit on empty `tr`.
`10.0.2.2` is emulator-only: on a USB phone Chrome's error page still shows `x.png` in the URL bar, so three long
presses run before the SKIP (~25 s). Gate on the emulator serial or say so in the README.

### M8 — Shared: the SHA-256 assertion depends on Chrome passing the original bytes
Chromium's "Copy image" asks for `ContextMenuImageFormat.ORIGINAL` with a 2048 px cap; original PNG bytes pass through
only when no downscale or re-encode is needed (`chrome_render_frame_observer.cc`). Sides here are 316 px and 1000 px,
so the check should hold; a FAIL "announced sha256 differs" with matching `width/height` points at Chrome, not the
phone — the hint text already says so. Noted for the first run.

## Answers to the lead's questions

- **Legitimate text that flips to image / is dropped.** Only item 0 with both `text` and a URI typed `image/*` by
  the provider or the description. Chrome, Samsung Internet "Copy image" and Samsung Gallery: desired. Files app
  copying an image: URI only, already an image before the change. Gboard stickers use `commitContent`, not the
  clipboard; Keep copies plain text. Samsung Notes rich selection with an inline image is unverified: if the image URI
  sits on item 0 beside the text, the text is lost (item-0 rule, spec-sanctioned). Residual risks: M1, M2.
- **`authority` in a debug line.** Content authorities are app identifiers (`com.android.chrome.FileProvider`,
  `media`, `0@media`), not content or identity; QC2 holds. Exception: raw web URIs (M2).
- **`BenchLog.event` on the IO dispatcher.** Safe: `@Volatile enabled` + `Log.i`, no shared mutable state; disabled
  under Robolectric (`install` never called), so tests do not depend on it.
- **ktlint / detekt / Robolectric.** All changed Kotlin lines ≤ 120 characters (checked by character count; `awk
  length` misreports the em dash). No suppressions, `when` branch count unchanged. `ClipData.Item(CharSequence,
  String, Intent, Uri)` is public; the loop re-registers the stream per iteration; the `assertEquals(message, …)`
  overload is fine. Gap: M4.
- **Manual-path message vs "automatic stays silent".** `takeIf { manual }` keeps auto silent; `LocalClipSendTest`
  updated accordingly; `PERMISSION_LOST` appears nowhere else in tests (grep: `LocalRead.kt`, `LocalClipIntake.kt`,
  `ClipReader.kt`, the two tests). The Share target yields text only (`ClipboardReadActivity.kt:53-56`), so no
  image toast from `source = share`.
- **Receive-thread ordering.** No deadlock: `_auto_answer` → `send_ack` → `transport.send` runs without `_cond`;
  `send()` holds `_cond` only around the `_pending` insert; `wait`/`wait_ack` release it in `Condition.wait`;
  websockets' sync client serialises concurrent sends (main-thread chunks, receive-thread acks). `Inbound(len(events))`
  computed outside the lock is safe (single appender). Risk is I2, not a deadlock.
- **Cleanup and content.** Chrome force-stopped and HOME pressed in `finally`; shade closed on the normal paths.
  Printed details are size, chunk count, sha-match boolean, dimensions, source; `received_transfers[…]["blob"]` holds
  the bytes but nothing serialises it (`results.json` holds `StepResult` only).

## Verified by running

- `tools/.venv/bin/python tools/e2e/self_test.py` on `feat/e2e-phone-to-mac-image`: run 1 aborted with
  `TimeoutError: timed out while waiting for handshake response` inside `loopback` → `pairing.attempt` (LAN pairing
  transport, before any changed code runs; the host is known to be overloaded). Run 2: every line `ok`, `0 failed`.
  Pre-session flake, unrelated to the diff.
- Character-length scan of the five changed Kotlin files: none over 120.
- `grep PERMISSION_LOST` across handlive-android; `grep received_transfers|applied_clips|json.dump` across
  `tools/e2e`.
- Spec cross-read: `04-clipboard.md` 284–289, 812 (E10), 922–925, 968–1040 and the `.vi.md` twin 276, 796.
- Not run: Gradle, ktlint, detekt, the emulator.

## Recommended order

1. I2 (one try/except), I1 (one log line + README row), then I3 (self-test coverage) before merging the shared branch.
2. M2 and M3 with the android branch; M1 and M4 as a follow-up with a spec decision on logic 1.
3. M5–M8 when the e2e step is next touched.

Status: DONE_WITH_CONCERNS
Summary: Both diffs are correct for the stated change and match the updated spec; no blocker. Three important fixes:
the normalize-stage E3 is invisible to HLBENCH (the very thing the owner is debugging), the reordered receive thread
can hide a push when the auto-answer throws, and the fake Mac's answer path has no self-test coverage.
Concerns/Blockers: Samsung Notes behaviour with text + inline-image URI on item 0 is unverified on the S25 (owner /
samsung-clip-research); the `getType` vs description precedence (M1) needs a spec decision.
