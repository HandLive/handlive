"""Mẫu dương tự viết (giá trị thật, không placeholder) và mẫu âm sinh bằng cách làm hỏng mẫu dương.

Mỗi mẫu âm chỉ đổi một chỗ so với mẫu dương gốc, nên bị từ chối đúng vì lỗi đó.
"""

from __future__ import annotations

import base64
import copy

B64U_32 = base64.urlsafe_b64encode(bytes(range(32))).decode().rstrip("=")
UUID_V7 = "0192f3c1-7c1e-7a55-9d0b-3f4c2a1b9e10"
PAIR_ID = "3f2b1c4d-5e6f-4a7b-8c9d-0e1f2a3b4c5d"
DEVICE_C = "5b1f8c2e-9a4d-8e6f-a1b2-c3d4e5f60718"
DEVICE_S = "8c7d6e5f-4a3b-8c2d-9e1f-0a1b2c3d4e5f"
CIPHERTEXT = base64.b64encode(bytes(range(58))).decode()  # nonce(24) + ciphertext(18) + tag(16); 58 byte -> b64 kết thúc "=="

CAPABILITY_DATA = {
    "protocol": 1,
    "app_version": "1.0.0 (100)",
    "platform": "macos",
    "os_version": "15.1",
    "model": "Mac15,3",
    "features": {
        "clipboard": {"enabled": True, "auto_send": True, "max_text_bytes": 1048576,
                      "max_image_bytes": 10485760, "mimes": ["text/plain", "image/png"]},
        "call_audio": {"enabled": True, "consented": True, "bt_address": "A1:B2:C3:D4:E5:F6"},
        "camera": {"enabled": False},
        "relay": {"enabled": True},
    },
}

# (tên, schema, instance) — phải hợp lệ.
POSITIVE = [
    ("envelope session", "envelope", {"v": 1, "type": "session", "id": UUID_V7, "ts": 1727151000000, "payload": CIPHERTEXT}),
    ("payload chung", "payload", {"op": "push", "data": {}}),
    ("ack thành công", "ack", {"re": UUID_V7, "ok": True, "data": {}}),
    ("ack lỗi có details", "ack", {"re": UUID_V7, "ok": False,
                                  "error": {"code": "RATE_LIMITED", "message": "Chờ", "details": {"retry_after_ms": 500}}}),
    ("session/hello", "session-hello", {"op": "hello", "data": {"protocol": 1, "pair_id": PAIR_ID, "device_id": DEVICE_C,
                                                                "eph": B64U_32, "nonce": B64U_32, "mac": B64U_32}}),
    ("session/welcome", "session-welcome", {"op": "welcome", "data": {"device_id": DEVICE_S, "eph": B64U_32,
                                                                      "nonce": B64U_32, "mac": B64U_32}}),
    ("session/error UNSUPPORTED_VERSION", "session-error",
     {"op": "error", "data": {"code": "UNSUPPORTED_VERSION", "message": "Cần cập nhật", "min_protocol": 2}}),
    ("session/error AUTH_FAILED", "session-error", {"op": "error", "data": {"code": "AUTH_FAILED", "message": "Sai MAC"}}),
    ("session/rekey", "session-rekey", {"op": "rekey", "data": {"epoch": 1, "eph": B64U_32, "nonce": B64U_32}}),
    ("ack của session/rekey", "session-rekey#ack",
     {"re": UUID_V7, "ok": True, "data": {"epoch": 1, "eph": B64U_32, "nonce": B64U_32}}),
    ("session/bye", "session-bye", {"op": "bye", "data": {"reason": "shutdown"}}),
    ("capability/hello Mac", "capability-hello", {"op": "hello", "data": CAPABILITY_DATA}),
    ("capability/update Mac", "capability-update", {"op": "update", "data": CAPABILITY_DATA}),
]


def _mutate(schema_positive: str, fn):
    """Lấy bản sao sâu của mẫu dương theo tên và áp hàm sửa."""
    base = next(inst for name, _, inst in POSITIVE if name == schema_positive)
    inst = copy.deepcopy(base)
    fn(inst)
    return inst


def _set(path, value):
    def apply(inst):
        target = inst
        for key in path[:-1]:
            target = target[key]
        target[path[-1]] = value
    return apply


def _drop(path):
    def apply(inst):
        target = inst
        for key in path[:-1]:
            target = target[key]
        del target[path[-1]]
    return apply


# (tên, schema, mẫu dương gốc, hàm sửa) — phải bị từ chối.
NEGATIVE_SPECS = [
    ("envelope thiếu payload", "envelope", "envelope session", _drop(["payload"])),
    ("envelope v = 2", "envelope", "envelope session", _set(["v"], 2)),
    ("envelope v là chuỗi \"1\"", "envelope", "envelope session", _set(["v"], "1")),
    ("envelope type lạ", "envelope", "envelope session", _set(["type"], "notification")),
    ("envelope id chữ hoa", "envelope", "envelope session", _set(["id"], UUID_V7.upper())),
    ("envelope id không phải v7 (v4)", "envelope", "envelope session", _set(["id"], PAIR_ID)),
    ("envelope id không gạch", "envelope", "envelope session", _set(["id"], UUID_V7.replace("-", ""))),
    ("envelope ts âm", "envelope", "envelope session", _set(["ts"], -1)),
    ("envelope ts số thực", "envelope", "envelope session", _set(["ts"], 1727151000000.5)),
    ("envelope payload thiếu padding", "envelope", "envelope session", _set(["payload"], CIPHERTEXT.rstrip("="))),
    ("envelope payload là b64url", "envelope", "envelope session", _set(["payload"], "ab-_" * 4)),
    ("envelope thêm trường lạ", "envelope", "envelope session", _set(["to"], DEVICE_S)),
    ("payload thiếu data", "payload", "payload chung", _drop(["data"])),
    ("ack ok=true kèm error", "ack", "ack thành công",
     _set(["error"], {"code": "INTERNAL", "message": "x"})),
    ("ack thiếu re", "ack", "ack thành công", _drop(["re"])),
    ("ack lỗi mã lạ", "ack", "ack lỗi có details", _set(["error", "code"], "SMS_UNKNOWN_ERROR")),
    ("ack lỗi dùng mã relay HTTP", "ack", "ack lỗi có details", _set(["error", "code"], "TOKEN_EXPIRED")),
    ("ack lỗi thiếu message", "ack", "ack lỗi có details", _drop(["error", "message"])),
    ("session/hello thiếu mac", "session-hello", "session/hello", _drop(["data", "mac"])),
    ("session/hello eph 31 byte", "session-hello", "session/hello",
     _set(["data", "eph"], base64.urlsafe_b64encode(bytes(31)).decode().rstrip("="))),
    ("session/hello eph có padding", "session-hello", "session/hello", _set(["data", "eph"], B64U_32 + "=")),
    ("session/hello device_id không phải v8", "session-hello", "session/hello", _set(["data", "device_id"], UUID_V7)),
    ("session/hello op sai", "session-hello", "session/hello", _set(["op"], "welcome")),
    ("session/welcome thêm pair_id", "session-welcome", "session/welcome", _set(["data", "pair_id"], PAIR_ID)),
    ("session/error mã ngoài tập bắt tay", "session-error", "session/error AUTH_FAILED",
     _set(["data", "code"], "BAD_REQUEST")),
    ("session/error mã lạ", "session-error", "session/error AUTH_FAILED", _set(["data", "code"], "NOPE")),
    ("session/error min_protocol với AUTH_FAILED", "session-error", "session/error AUTH_FAILED",
     _set(["data", "min_protocol"], 2)),
    ("session/rekey thiếu epoch", "session-rekey", "session/rekey", _drop(["data", "epoch"])),
    ("ack rekey thiếu eph", "session-rekey#ack", "ack của session/rekey", _drop(["data", "eph"])),
    ("session/bye reason lạ", "session-bye", "session/bye", _set(["data", "reason"], "sleep")),
    ("capability tính năng lạ", "capability-hello", "capability/hello Mac",
     _set(["data", "features", "notifications"], {"enabled": True})),
    ("capability platform windows", "capability-hello", "capability/hello Mac", _set(["data", "platform"], "windows")),
    ("capability thiếu features", "capability-hello", "capability/hello Mac", _drop(["data", "features"])),
    ("capability feature thiếu enabled", "capability-hello", "capability/hello Mac",
     _drop(["data", "features", "relay", "enabled"])),
    ("capability opus_fallback reason lạ", "capability-hello", "capability/hello Mac",
     _set(["data", "features", "call_audio", "opus_fallback"],
          {"available": False, "downlink": False, "uplink": False, "reason": "unknown"})),
    ("capability/update mang op hello", "capability-update", "capability/update Mac", _set(["op"], "hello")),
]

NEGATIVE = [(name, schema, _mutate(base, fn)) for name, schema, base, fn in NEGATIVE_SPECS]
