# E2E: phone -> Mac image (CLIP-03), emulator-5580, 2026-10-05

## Built (repo handlive-shared, branch `feat/e2e-phone-to-mac-image`, not pushed)
- `tools/e2e/mac_session.py`: the fake Mac now accepts a chunked `clipboard/push` from the phone like M-APP: collects the binary chunks, checks order, size and SHA-256 (base64url), acks `applied`, or `CLIP_CHECKSUM_MISMATCH` with `details.transfer_id`. Result kept in `received_transfers[clip_id]` (size, sha256, chunks, in_order, width, height, source, status). Text behaviour unchanged.
- `tools/e2e/scenario_clipboard.py`: step "PNG image phone -> Mac through the notification button" at 0.3 MB and 3 MB. A host HTTP server serves the PNG at `10.0.2.2`; Chrome opens it (first-run sheets dismissed by text), long-press, "Copy image", HOME, shade, Send Clipboard. Asserts kind=image, mime=image/png, transfer present, source=manual, announced SHA-256 == served PNG, width/height, chunks in order and complete, SHA-256 of received bytes, and the phone's `HLBENCH ev=clip_read kind=image` for that clip. Driving failures give SKIP with the reason, never a crash.
- README.md / README.vi.md rows for `clipboard`. `self_test.py`: 0 failed.

## Run output (new steps)
```
PASS [clipboard] CLIP-03 phone -> Mac, CLIP-01 API 1/3: PNG image 0.3 MB phone -> Mac through the notification button - 9501 ms - size=300042 B chunks=5 sha256_match=True 316x316 source=manual
PASS [clipboard] CLIP-03 phone -> Mac, CLIP-01 API 1/3: PNG image 3.0 MB phone -> Mac through the notification button - 10127 ms - size=3001978 B chunks=46 sha256_match=True 1000x1000 source=manual
clipboard: PASS 17, SKIP 1   (only skip: Accessibility auto-send, as before)
```
All earlier steps PASS, no schema violation, no crash/ANR.

## Latencies
- Step total (~9.5 s / ~10.1 s) is dominated by opening the shade and finding the button, not by the transfer.
- Phone HLBENCH: clip_read -> ack_received(applied) = 0.34 s for 300 kB, 1.52 s for 3 MB (clip_read 01:36:40.732 -> ack 01:36:41.074; 01:37:02.770 -> 01:37:04.287).

## Evidence
- On API 35 emulator, current `main` APK: Chrome "Copy image" -> notification Send Clipboard -> image reaches the Mac byte-exact (SHA-256 equal to the served PNG, so no re-encode), chunked in order, acked applied. The phone -> Mac image path via the manual button works, 300 kB to 3 MB.
- Not covered, so the owner's "image copy fails" on real devices is NOT reproduced here: automatic send via Accessibility (copy_detected path), Samsung/One UI clipboard (Samsung may hand the app a different ClipData/URI form or block background reads), images from other apps (content URI permissions), JPEG/WebP sources (Chrome served PNG; a re-encode path is not exercised), >3 MB images. Chrome-copied images arrive as a content:// URI; this works here.
- Suggested next: same step with a JPEG/WebP source, and the real-device run with `adb logcat -s HLBENCH` to see whether `clip_read kind=image` appears at all (read failure) or only `clip_sent` is missing (send failure).

## Commits (handlive-shared)
- 60724af test(shared): fake Mac receives chunked clipboard pushes from the phone
- b03b6e3 test(shared): e2e step for the phone to Mac image through Chrome Copy image and the Send Clipboard button
- 680f361 docs(shared): e2e README rows for the phone to Mac image step

## Unresolved
- Real-device failure cause unknown; needs device logcat.
