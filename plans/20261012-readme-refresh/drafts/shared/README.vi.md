[English](README.md) | Tiếng Việt

# handlive-shared

[![License: Apache-2.0](https://img.shields.io/badge/License-Apache_2.0-blue.svg)](LICENSE)

Lược đồ giao thức, test vector mật mã, design token và chuỗi bản địa hóa giao diện dùng chung cho hệ sinh thái HandLive. Kho này không chứa ứng dụng độc lập; các ứng dụng máy khách (Android, Apple) và relay phụ thuộc vào kho này qua đường dẫn `../shared`.

## Tổng quan

- **Nguồn chân lý duy nhất:** Tập trung các định dạng truyền tải, JSON schema (2020-12), test vector mật mã, design token và catalog chuỗi giao diện song ngữ (tiếng Anh và tiếng Việt) cho toàn bộ các nền tảng.
- **Bám sát đặc tả:** Được xây dựng trực tiếp từ [`docs/detailed-design/00-common-specs.md`](https://github.com/HandLive/handlive/blob/main/docs/detailed-design/00-common-specs.vi.md) và [`docs/design-system/`](https://github.com/HandLive/handlive/tree/main/docs/design-system) trong kho hub.
- **Kiểm tra tự động:** Bộ công cụ Python chuyên dụng xác thực test vector, kiểm tra tính hợp lệ của JSON schema với các ví dụ trong tài liệu hub, và thực thi các quy tắc bản địa hóa chuỗi giao diện nghiêm ngặt.

## Bối cảnh workspace

Kho lưu trữ này là một thành phần trong workspace HandLive:
- Kho hub [`handlive`](https://github.com/HandLive/handlive) (tài liệu, kế hoạch) là thư mục cha.
- Được clone cùng với [`handlive-android`](https://github.com/HandLive/handlive-android), [`handlive-apple`](https://github.com/HandLive/handlive-apple), và [`handlive-relay`](https://github.com/HandLive/handlive-relay).
- Clone toàn bộ workspace từ hub bằng lệnh `tools/workspace.sh clone <group-url>`. Xem [`CLAUDE.md`](CLAUDE.md) để biết quy trình làm việc trong workspace.

## Thành phần

| Thư mục | Nội dung | Tài liệu |
|---------|----------|----------|
| `test-vectors/` | 20 file vector (RFC và tự sinh, bao gồm `push-envelope.json` và `relay-frame.json`) cùng `envelope-roundtrip{,-apple}.json` liên nền tảng | [`test-vectors/README.vi.md`](test-vectors/README.vi.md) |
| `schemas/` | JSON Schema 2020-12: envelope, payload, ack, error, `session-*`, `capability-*`, `pair-*`, `ping-ping`, `clipboard-*`, `sms-*`, `call_event-*`, `call-notification`; khung `relay-*` và thân `relay-rest` của relay; thân `push` | [`schemas/README.vi.md`](schemas/README.vi.md) |
| `design-tokens/` | `tokens.json` (giống từng byte với `../docs/design-system/tokens.json`), `type-extras.json` | [`design-tokens/README.vi.md`](design-tokens/README.vi.md) |
| `strings/` | `ui-strings.json`: mọi chuỗi hiển thị bằng tiếng Anh và tiếng Việt, kèm JSON Schema | [`strings/README.vi.md`](strings/README.vi.md) |
| `tools/vectors/` | `generate_vectors.py` (`--check`), `verify_vectors.py` | [`tools/vectors/README.vi.md`](tools/vectors/README.vi.md) |
| `tools/schemas/` | `check_schemas.py` (schema cùng các ví dụ trong tài liệu hub; `HANDLIVE_DOCS_DIR`) | [`tools/schemas/README.vi.md`](tools/schemas/README.vi.md) |
| `tools/strings/` | `check_strings.py` (quy tắc catalog 0.12.5; `--docs`, `--self-test`) | [`strings/README.vi.md`](strings/README.vi.md) |
| `tools/bench/` | Độ trễ bảng nhớ tạm, thời gian kết nối lại, độ trễ SMS (thông báo, trả lời tới Đã gửi), độ trễ cuộc gọi (trạng thái, bảng thông báo, trả lời, từ chối từ thông báo iPhone, cuộc gọi nhỡ) từ log `HLBENCH/1`; thử tải relay (`relay_load.py`, 1.000 thiết bị giả); ma trận kiểm thử tay | [`tools/bench/README.vi.md`](tools/bench/README.vi.md) |
| `tools/e2e/` | Bộ kiểm thử đầu cuối: Mac giả lập tương tác với app Android thật trên máy ảo (ghép nối, bảng nhớ tạm, SMS, cuộc gọi), điều khiển qua adb; `self_test.py` chạy trong CI không cần máy ảo | [`tools/e2e/README.vi.md`](tools/e2e/README.vi.md) |
| `tools/e2e/relay_stack/` | Relay cùng PostgreSQL, Redis, TLS front cho máy ảo Android, APNs và FCM giả lập ghi lại mọi push; kiểm tra đăng ký, chuyển tiếp và phân phối | [`tools/e2e/relay_stack/README.vi.md`](tools/e2e/relay_stack/README.vi.md) |

## Yêu cầu

- **Python:** Python 3 (kèm module `venv` và `pip`) cho các bộ công cụ kiểm thử vector, schema và chuỗi giao diện

## Lệnh

```sh
python3 -m venv tools/.venv && tools/.venv/bin/pip install -r tools/vectors/requirements.txt -r tools/schemas/requirements.txt -r tools/strings/requirements.txt
tools/.venv/bin/python tools/vectors/verify_vectors.py          # phải in "0 lỗi"
tools/.venv/bin/python tools/vectors/generate_vectors.py --check # phải in "0 lệch"
tools/.venv/bin/python tools/schemas/check_schemas.py           # phải in "XANH"
tools/.venv/bin/python tools/strings/check_strings.py           # phải in "OK"
```

## Tài liệu và cộng đồng

- [Kiến trúc hệ thống](https://github.com/HandLive/handlive/blob/main/docs/system-architecture.vi.md) — Thiết kế hệ thống và mô hình bảo mật
- [Thiết kế chi tiết](https://github.com/HandLive/handlive/tree/main/docs/detailed-design) — Giao thức, định dạng và đặc tả kỹ thuật
- [Hướng dẫn triển khai](https://github.com/HandLive/handlive/blob/main/docs/deployment-guide.vi.md) — Đóng gói và phát hành ứng dụng
- [CONTRIBUTING](https://github.com/HandLive/.github/blob/main/CONTRIBUTING.vi.md) — Quy trình gửi PR, commit nhỏ và ký xác nhận DCO (`git commit -s`)
- [SECURITY](https://github.com/HandLive/.github/blob/main/SECURITY.vi.md) — Chính sách báo cáo lỗ hổng bảo mật
- [CODE_OF_CONDUCT](https://github.com/HandLive/.github/blob/main/CODE_OF_CONDUCT.vi.md) — Quy tắc ứng xử cộng đồng

## Giấy phép

Apache License 2.0 — xem [LICENSE](LICENSE).
