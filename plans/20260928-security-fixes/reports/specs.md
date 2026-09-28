# Spec changes for the security fixes (D1–D11, hub)

Date: 2026-09-28 · Branch: hub `main` (not pushed) · Plan: `plans/20260928-security-fixes/plan.md`

EN and VI files changed together in each commit. Checks: `validate_design_docs.py` problems=0,
`check_bilingual_docs.py` problems=0, `apple_diacritics.py` dry run on every changed `.vi.md` = 0 words.

## Commits (hub)

| Hash | Message |
|------|---------|
| `c9c42ff` | docs(design): add signed revocation, epoch-wide dedup and new limits to the common specs |
| `9a1c86a` | docs(design): act on relay revocations only with the peer's signature and harden the pairing window |
| `3833ae8` | docs(design): limit phone admission and relay auth, keep relay pair errors to backoff |
| `91837ac` | docs(design): check SMS and calls per session and cap sms/send per pair |
| `371a428` | docs: describe the new relay limits in the deployment guide |
| `68dc1f8` | ci: pin actions to commit SHAs and keep the token out of git URLs |

## Sections changed per decision

- **D1 dedup:** 00 §0.5.1 rule 2 (per-direction set of ids of the key epoch, previous epoch kept while its keys
  are accepted, record only after decrypt, LAN = relay); 00 §0.10 `DEDUP_WINDOW`; 03 CONN-02 API 3 logic 4.
  CONN-05 does not exist.
- **D2 signed revocation:** 00 §0.6.2 new `HLREVOKE1` byte format (49 bytes signed); §0.7.3 `pair_revoked`
  `{pair_id, by, revoked_at, sig}`; §0.7.4 revoke body, `DELETE /v1/devices/me` body, `GET /v1/pairs` fields;
  §0.8.1 `PAIR_UNKNOWN`/`PAIR_REVOKED` handling (LAN vs relay); §0.9.4 `pairs.revoke_sig` column (+ comments on
  `revoked_at`/`revoked_by`), `revoked_notice` element `<pair_id>|<by>|<revoked_at>|<sig>`; §0.10
  `REVOKE_CLOCK_SKEW` ±10 min; §0.11 relay pre-auth error → `Backoff`. 01 SET-02 A2, API 2 (body, 400, logic 3
  and 5, examples, Redis), API 5. 02 PAIR-02 E3, step 5, API 1 fields + logic 4 + query; PAIR-03 description,
  steps 8–9, API 3 (request table, 400, logic 2–5, example), API 4 (fields, logic 1), queries, Redis.
  03 CONN-01 E4 (LAN only), CONN-03 new E9 (relay pre-auth `PAIR_UNKNOWN|PAIR_REVOKED` → `Backoff`), API 4
  text.
- **D3 relay auth:** 00 §0.6.4 step 1, §0.9.4 keys `chal:<device_id>:<challenge>`, `rl:ip:<ip>:auth:<minute>`,
  `rl:<device_id>:<ip>:chal:<minute>`, §0.10 `RELAY_AUTH_LIMIT`; 03 CONN-03 API 2, API 3 (+429), Redis block.
- **D4 registration:** 00 §0.9.4 `rl:ip:` /64 note + `rl:reg:<hour>`, §0.10 `RELAY_REG_IP_LIMIT`,
  `RELAY_MAX_REGISTRATIONS_PER_HOUR` (1,000); 03 CONN-03 API 1 (429 row, logic 3, logic 4 startup warning);
  `docs/deployment-guide(.vi).md` Limits bullet.
- **D5 phone admission:** 00 §0.8.3 4429, §0.10 `CTL_PREAUTH_LIMIT`, `CTL_IP_BLOCK`, `PAIR_CONN_LIMIT`;
  03 CONN-01 API 3 logic 2, API 4 logic 2; 02 PAIR-01 API 2 logic 5 (`/v1/pair`: 4 total / 2 per IP → 4429;
  `pair/hello` 8 KiB cap → close 4400).
- **D6 pairing window:** 02 PAIR-01 E2, E7, special requirements (residual offline-guess risk, PAKE/CPace as
  open decision), step A4 (phone counts 3 offers per PIN, PIN expired after the third), API 2 logic 4 (an
  unclaimed connection never closes the window), API 6 `attempts_left` (ignored by the phone); 00 §0.10
  `PIN_MAX_ATTEMPTS` note.
- **D7 per-session features:** 05 group rules (every `sms/*`), SMS-04 step 6 + error table; 06 group rules,
  CALL-02 API 1 error table, CALL-03 API errors, CALL-04 `log_sync` errors. Wording: `FEATURE_DISABLED` when
  the feature is off on Android or on the requesting client (calls: or `READ_PHONE_STATE` missing, matching
  CALL-04 E1); a missing permission keeps `PERMISSION_MISSING`.
- **D9 SMS limit:** 00 §0.8.1 `RATE_LIMITED` row, §0.10 `SMS_SEND_LIMIT`; 05 SMS-04 E11, special requirements,
  field 12, step 6, error table row `RATE_LIMITED` (checked last, after SIM), logic 8 (duplicates not counted,
  notification once per pair per day). The client shows the existing field 8 text "Sending limit reached. Try
  again later." — no new client string.
- **D11 hub CI:** `.github/workflows/ci-docs.yml`: `actions/checkout@fbc6f3992d24b796d5a048ff273f7fcc4a7b6c09 # v5.1.0`
  (3×, each with `persist-credentials: false`), `actions/setup-python@ece7cb06caefa5fff74198d8649806c4678c61a1 # v6.3.0`;
  branch lookup now `gh api repos/<owner>/<repo>/branches/<branch>` with `GH_TOKEN` (tested against a
  `feat/...` branch name with a slash).

## New UI text (key `sms.send_rate_limited_body`, Android only, SMS-04 field 12)

- en: `HandLive stopped sending messages from {device_name} for now. Too many were sent in a short time.`
- vi: `HandLive tạm dừng gửi tin nhắn từ {device_name}. Có quá nhiều tin nhắn được gửi trong thời gian ngắn.`
- Spec says: at most once per pair per day; channel `permission`. The shared catalog had no
  `sms.send_rate_limited_body` entry when I checked (`shared` on `fix/security-scan-findings`); the controller
  aligns if the shared agent wrote other wording.

## Notes for platform agents

- `POST /v1/pairs/{pair_id}/revoke` keeps `reason` as an optional, unsigned, unstored field (clients may still
  send it); `revoked_at` + `sig` are required.
- `DELETE /v1/devices/me?revoke_pairs=true`: relay needs one statement per unrevoked pair it holds; statements
  for unknown pairs are ignored. Clients sign for every local pair and every unrevoked pair from `GET /v1/pairs`.
- The pending `chal:<device_id>:*` keys are no longer deleted on `DELETE /v1/devices/me`; they expire (60 s) and
  `/auth/token` fails anyway without a device row.
- A retry of a revoke after E3 signs a fresh statement (current time), so the ±10 min window never blocks it.

Status: DONE_WITH_CONCERNS
Summary: D1–D7, D9 and D11 are written into the hub specs (00, 01, 02, 03, 05, 06, deployment guide; EN + VI) and ci-docs.yml is pinned and hardened, in 6 signed-off commits on hub `main`, not pushed.
Concerns/Blockers: (1) the SMS limit notification uses Android channel `permission`, whose description is about permission suggestions; a dedicated channel would need two more UI strings; (2) 01-setup-settings and deployment-guide were edited too (needed for the `DELETE /v1/devices/me` body and the relay limits) though not listed in the task; (3) constant names `CTL_PREAUTH_LIMIT`, `CTL_IP_BLOCK`, `PAIR_CONN_LIMIT`, `RELAY_AUTH_LIMIT`, `RELAY_REG_IP_LIMIT`, `REVOKE_CLOCK_SKEW`, `SMS_SEND_LIMIT` and the Redis key names are spec labels I chose; only `RELAY_MAX_REGISTRATIONS_PER_HOUR` came from the plan.
