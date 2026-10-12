English | [Tiếng Việt](README.vi.md)

# handlive-shared

[![License: Apache-2.0](https://img.shields.io/badge/License-Apache_2.0-blue.svg)](LICENSE)

Shared protocol schemas, cryptographic test vectors, design tokens, and UI localization strings for the HandLive ecosystem. This repository contains no standalone application; client apps (Android, Apple) and the relay depend on it via `../shared`.

## Overview

- **Single source of truth:** Centralizes wire formats, JSON schemas (2020-12), cryptographic test vectors, design tokens, and the bilingual UI string catalog across all platforms.
- **Specification alignment:** Built directly from [`docs/detailed-design/00-common-specs.md`](https://github.com/HandLive/handlive/blob/main/docs/detailed-design/00-common-specs.md) and [`docs/design-system/`](https://github.com/HandLive/handlive/tree/main/docs/design-system) in the hub repository.
- **Automated validation:** Dedicated Python toolchains verify test vectors, validate JSON schemas against hub documentation examples, and enforce strict UI localization rules.

## Workspace context

This repository is one component of the HandLive workspace:
- Hub repository [`handlive`](https://github.com/HandLive/handlive) (docs, plans) is the parent directory.
- Cloned alongside [`handlive-android`](https://github.com/HandLive/handlive-android), [`handlive-apple`](https://github.com/HandLive/handlive-apple), and [`handlive-relay`](https://github.com/HandLive/handlive-relay).
- Clone the full workspace from the hub using `tools/workspace.sh clone <group-url>`. See [`CLAUDE.md`](CLAUDE.md) for local workspace workflows.

## Components

| Folder | Contents | Docs |
|--------|----------|------|
| `test-vectors/` | 20 vector files (RFC and generated, including `push-envelope.json` and `relay-frame.json`) plus cross-platform `envelope-roundtrip{,-apple}.json` | [`test-vectors/README.md`](test-vectors/README.md) |
| `schemas/` | JSON Schema 2020-12: envelope, payload, ack, error, `session-*`, `capability-*`, `pair-*`, `ping-ping`, `clipboard-*`, `sms-*`, `call_event-*`, `call-notification`; relay `relay-*` frames and `relay-rest` bodies; `push` bodies | [`schemas/README.md`](schemas/README.md) |
| `design-tokens/` | `tokens.json` (byte-identical to `../docs/design-system/tokens.json`), `type-extras.json` | [`design-tokens/README.md`](design-tokens/README.md) |
| `strings/` | `ui-strings.json`: every user-facing string in English and Vietnamese, with its JSON Schema | [`strings/README.md`](strings/README.md) |
| `tools/vectors/` | `generate_vectors.py` (`--check`), `verify_vectors.py` | [`tools/vectors/README.md`](tools/vectors/README.md) |
| `tools/schemas/` | `check_schemas.py` (schemas plus examples in hub docs; `HANDLIVE_DOCS_DIR`) | [`tools/schemas/README.md`](tools/schemas/README.md) |
| `tools/strings/` | `check_strings.py` (catalog rules of 0.12.5; `--docs`, `--self-test`) | [`strings/README.md`](strings/README.md) |
| `tools/bench/` | Clipboard latency, reconnect time, SMS latency (notification, reply to Sent), call latency (state, panel, answer, decline from iPhone notification, missed calls) from `HLBENCH/1` logs; relay load test (`relay_load.py`, 1,000 simulated devices); manual test matrix | [`tools/bench/README.md`](tools/bench/README.md) |
| `tools/e2e/` | End-to-end harness: simulated Mac against real Android app on an emulator (pairing, clipboard, SMS, calls), driven via adb; `self_test.py` runs in CI without an emulator | [`tools/e2e/README.md`](tools/e2e/README.md) |
| `tools/e2e/relay_stack/` | Relay with PostgreSQL, Redis, TLS front for Android emulator, mock APNs and FCM recording every push; verifies registration, forwarding, and delivery | [`tools/e2e/relay_stack/README.md`](tools/e2e/relay_stack/README.md) |

## Requirements

- **Python:** Python 3 (with `venv` module and `pip`) for toolchains verifying vectors, schemas, and strings

## Commands

```sh
python3 -m venv tools/.venv && tools/.venv/bin/pip install -r tools/vectors/requirements.txt -r tools/schemas/requirements.txt -r tools/strings/requirements.txt
tools/.venv/bin/python tools/vectors/verify_vectors.py          # must print "0 lỗi" (0 errors)
tools/.venv/bin/python tools/vectors/generate_vectors.py --check # must print "0 lệch" (0 mismatches)
tools/.venv/bin/python tools/schemas/check_schemas.py           # must print "XANH" (green)
tools/.venv/bin/python tools/strings/check_strings.py           # must print "OK"
```

## Documentation and community

- [System Architecture](https://github.com/HandLive/handlive/blob/main/docs/system-architecture.md) — System design and security model
- [Detailed Design](https://github.com/HandLive/handlive/tree/main/docs/detailed-design) — Protocols, formats, and specifications
- [Deployment Guide](https://github.com/HandLive/handlive/blob/main/docs/deployment-guide.md) — Packaging and distribution guidelines
- [CONTRIBUTING](https://github.com/HandLive/.github/blob/main/CONTRIBUTING.md) — PR workflow, small commits, and DCO sign-off (`git commit -s`)
- [SECURITY](https://github.com/HandLive/.github/blob/main/SECURITY.md) — Vulnerability reporting policy
- [CODE_OF_CONDUCT](https://github.com/HandLive/.github/blob/main/CODE_OF_CONDUCT.md) — Community standards

## License

Apache License 2.0 — see [LICENSE](LICENSE).
