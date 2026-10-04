# Shared repo: clipboard HTML (2026-10-05)

Repo handlive-shared, branch `feat/clipboard-html` (not pushed).

## Changes
- `schemas/clipboard-push.schema.json`: optional `html` (string); `allOf`: `html` requires `text`, forbids `transfer`, forces `kind = text`. `additionalProperties: false` kept. `schemas/README*.md` row updated.
- Samples (`tools/schemas/sample_messages_sms.py`): 1 positive (text with html), 4 negative (html+transfer, html on image, html without text, html as number). `sample_messages.py` Mac capability mimes gain `text/html`.
- `tools/e2e/fake_mac.py` capability lists `text/html`. `mac_session.py` needed no change: inbound `data` (with `html`) is recorded as is and a text push with `html` is auto-answered as text. Fake phone `PHONE_CAPABILITY` left as is (it is the phone side, no html).
- `tools/vectors/verify_clipboard_html_checks.py` + hook in `verify_vectors.py`: re-runs the reference sanitizer on all 30 cases, checks rules, fixed point (output re-sanitized is unchanged).
- `tools/e2e/scenario_clipboard.py`: `push_text(html=)`; steps (a) text+html applied then Send Clipboard returns sanitized html with unchanged text, (b) html+transfer BAD_REQUEST, (c) html on image BAD_REQUEST; each SKIPs with "the phone does not list text/html".
- `tools/e2e/self_test.py`: Mac to phone and phone to Mac pushes with html.
- READMEs en + vi: e2e clipboard row, test-vectors, tools/vectors (builder + checker).

## Checks
- `generate_vectors.py --check`: 22 files, 0 diff (no vector regenerated; none carried a capability).
- `verify_vectors.py`: 1654 checks, 0 errors (clipboard-html.json: 30 cases, 64 checks).
- `check_schemas.py`: XANH, 305 negative samples rejected; hub docs examples pass (hub checkout is on `main`, no html example there yet).
- `bench/self_test.py`: 68 passed, 0 failed. `e2e/self_test.py`: 0 failed.

## e2e `setup clipboard` (emulator-5580, app-foss-debug-html.apk)
setup: PASS 27, INFO 1. clipboard: PASS 21, SKIP 1 (Accessibility auto path, expected).
- PASS Mac to phone text with html: ack applied (251 ms)
- PASS phone to Mac: returned html = `<p>Hello <b>e2e</b> <img src="https://example.com/x.png" alt="x"></p>` (equals sanitized form), text unchanged
- PASS html+transfer: BAD_REQUEST; PASS html on image: BAD_REQUEST
- PASS no schema violation, no crash/ANR.

## Commits (shared)
03a8294 schema, 1098a27 fake Mac capability, e427660 verify checker, 7d064fa schemas README, 5580476 e2e steps + self_test + README, e63c63a vectors READMEs.

## Deviations
- Sanitizer test input contains no sanitization change (expected output equals input apart from attribute order already src, alt); the phone-side re-sanitize is therefore only weakly proven by step (a). Not changed per instructions.
- Verifier re-runs the same reference code (not independent), as requested.

Status: DONE
Summary: Schema, samples, fake Mac, verifier, e2e steps, READMEs done and committed; all checks green and e2e clipboard passes against the html APK.
