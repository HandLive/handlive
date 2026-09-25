"""Dựng vector khung tin: envelope, ack, clipboard-chunk, hl-frame (00-common-specs 0.5.1, 0.5.2).

Khóa lấy từ vector bắt tay/stream (cặp 1) để nối chuỗi; mỗi vector vẫn ghi đủ khóa hex nên đọc độc lập được.
"""
import base64
import json

from handlive_protocol_derivations import (b64, camera_plaintext, chunk_plaintext, compact_json, envelope_aad,
                                           envelope_wire, hl_header, test_bytes, xchacha_seal)

H = bytes.fromhex
SPEC = "docs/detailed-design/00-common-specs.md"
PUSH_MAC = {"op": "push", "data": {"clip_id": "0192f3e8-1b2c-7d3e-8f40-5a6b7c8d9e0f", "kind": "text", "mime": "text/plain",
                                   "text": "https://example.com/tai-lieu/bao-cao-quy-3", "sensitive": False,
                                   "origin_ts": 1727150160456, "source": "mac",
                                   "origin_device_id": "5b1f8c2e-9a4d-8e6f-a1b2-c3d4e5f60718"}}
PUSH_ANDROID = {"op": "push", "data": {"clip_id": "0192f3e0-5a21-7b3c-9d4e-1f2a3b4c5d6e", "kind": "text",
                                       "mime": "text/plain", "text": "Mã đơn hàng: HL-240917-0042", "sensitive": False,
                                       "origin_ts": 1727150100123, "source": "auto",
                                       "origin_device_id": "8c7d6e5f-4a3b-8c2d-9e1f-0a1b2c3d4e5f"}}
SMS_SEND = {"op": "send", "data": {"local_id": "0192f3e2-4b5c-7d6e-9f70-8a9b0c1d2e3f", "thread_id": 42,
                                   "addresses": ["+84900000123"], "body": "Ok, 3h mình có mặt", "sub_id": 1}}


def encrypted_envelope(name, direction, key_hex, key_source, typ, env_id, ts, plaintext: bytes, text: bool = True):
    aad = envelope_aad(1, typ, env_id, ts)
    nonce = test_bytes(f"envelope nonce {env_id}", 24)
    ct, tag = xchacha_seal(H(key_hex), nonce, plaintext, aad.encode())
    payload = b64(nonce + ct + tag)
    v = {"name": name, "encrypted": True, "direction": direction, "key": key_hex, "key_source": key_source,
         "v": 1, "type": typ, "id": env_id, "ts": ts, "aad": aad, "aad_hex": aad.encode().hex()}
    v.update({"plaintext": plaintext.decode()} if text else {"plaintext_hex": plaintext.hex()})
    v.update({"nonce": nonce.hex(), "ciphertext": ct.hex(), "tag": tag.hex(), "payload_b64": payload,
              "envelope": envelope_wire(1, typ, env_id, ts, payload)})
    return v


def plain_envelope(name, direction, wire: str, plaintext: str) -> dict:
    env = json.loads(wire)
    assert base64.b64decode(env["payload"]).decode() == plaintext
    return {"name": name, "encrypted": False, "direction": direction, "key": None, "key_source": None,
            "v": env["v"], "type": env["type"], "id": env["id"], "ts": env["ts"], "aad": None, "aad_hex": None,
            "plaintext": plaintext, "nonce": None, "ciphertext": None, "tag": None,
            "payload_b64": env["payload"], "envelope": wire}


def envelope_negatives(v: dict) -> list[dict]:
    env = json.loads(v["envelope"])
    raw = bytearray(base64.b64decode(env["payload"]))
    raw[-1] ^= 0x01
    out = [("tag sai", "tag_mismatch", {**env, "payload": b64(bytes(raw))}),
           ("ts bị sửa (AAD sai)", "aad_mismatch", {**env, "ts": env["ts"] + 1}),
           ("type bị sửa (AAD sai)", "aad_mismatch", {**env, "type": "sms"}),
           ("payload ngắn hơn 40 byte", "payload_too_short", {**env, "payload": b64(bytes(raw[:39]))})]
    return [{"name": f"{v['name']} / {n}", "reason": r, "key": v["key"], "envelope": compact_json(e)} for n, r, e in out]


def envelope_file(ctx) -> dict:
    h1, st = ctx["handshakes"][0], ctx["streams"][0]
    vs = [
        encrypted_envelope("clipboard push Mac→Android", "c2s", h1["k_c2s"], "session-handshake cặp 1 k_c2s",
                           "clipboard", "0192f3e8-1b2c-7d3f-8a01-5a6b7c8d9e10", 1727150160460,
                           compact_json(PUSH_MAC).encode()),
        encrypted_envelope("clipboard push Android→Mac (tiếng Việt)", "s2c", h1["k_s2c"], "session-handshake cặp 1 k_s2c",
                           "clipboard", "0192f3e0-5a22-7c4d-8e5f-6a7b8c9d0e1f", 1727150100130,
                           compact_json(PUSH_ANDROID).encode()),
        encrypted_envelope("sms send Mac→Android", "c2s", h1["k_c2s"], "session-handshake cặp 1 k_c2s",
                           "sms", "0192f3e2-4b5d-7e6f-8a70-9b0c1d2e3f40", 1727150170000,
                           compact_json(SMS_SEND).encode()),
        plain_envelope("session hello (chưa mã hóa)", "c2s", h1["hello_envelope"], h1["hello_plaintext"]),
        plain_envelope("camera stream_hello (chưa mã hóa)", "c2s", st["stream_hello_envelope"], st["stream_hello_plaintext"]),
    ]
    return {"description": "Envelope JSON: payload = b64(nonce(24) ‖ ciphertext ‖ tag(16)) của XChaCha20-Poly1305, "
                           "AAD = UTF-8 \"<v>|<type>|<id>|<ts>\". Tin bắt tay: payload = b64(JSON chưa mã hóa).",
            "source": f"{SPEC} 0.5.1; plaintext mẫu từ 04-clipboard.md, 05-sms.md", "vectors": vs,
            "invalid_vectors": envelope_negatives(vs[0]) + envelope_negatives(vs[1])[:1]}


def ack_file(ctx) -> dict:
    h1 = ctx["handshakes"][0]
    ok = {"re": "0192f4a0-1b2c-7d3e-8f40-5a6b7c8d9e0f", "ok": True, "data": {"seq": 42, "server_ts": 1727151030000}}
    ok_empty = {"re": "0192f3e8-1b2c-7d3f-8a01-5a6b7c8d9e10", "ok": True, "data": {}}
    err = {"re": "0192f3e2-4b5d-7e6f-8a70-9b0c1d2e3f40", "ok": False,
           "error": {"code": "SMS_NO_SERVICE", "message": "Không có sóng", "details": {}}}
    vs = []
    for name, body, eid, ts in (("ack ok ping", ok, "0192f4a0-1b40-7e4f-9051-6b7c8d9e0f10", 1727151030002),
                                ("ack ok data rỗng (clipboard push)", ok_empty, "0192f3e8-1c00-7a11-8b22-9c33ad44be55", 1727150160470),
                                ("ack lỗi SMS_NO_SERVICE", err, "0192f3e2-4c00-7b12-8c23-9d34ae45bf56", 1727150170300)):
        v = encrypted_envelope(name, "s2c", h1["k_s2c"], "session-handshake cặp 1 k_s2c", "ack", eid, ts,
                               compact_json(body).encode())
        vs.append({**v, "re": body["re"], "ok": body["ok"]})
    return {"description": "Envelope type = ack (mã hóa như envelope thường). Plaintext {re, ok, data} hoặc "
                           "{re, ok:false, error:{code, message, details}}.",
            "source": f"{SPEC} 0.5.1, 0.8.1; 03-connectivity.md CONN-02 API 2", "vectors": vs,
            "invalid_vectors": envelope_negatives(vs[2])[:2]}


def chunk_file(ctx) -> dict:
    h1 = ctx["handshakes"][0]
    tid = "0192f3f1-2c3e-7a10-9b20-c30d40e50f60"
    datas = [bytes.fromhex("89504e470d0a1a0a0000000d49484452") + test_bytes("chunk 0 data", 48),
             test_bytes("chunk 1 data", 13)]
    vs = []
    for idx, (data, eid, ts) in enumerate(zip(datas, ("0192f3f1-2c40-7c21-9d32-e43f54a65b76", "0192f3f1-2c41-7d32-8e43-f54a65b76c87"),
                                              (1727150200470, 1727150200475))):
        hdr, pt = chunk_plaintext(tid, idx, data)
        v = encrypted_envelope(f"chunk index {idx}", "c2s", h1["k_c2s"], "session-handshake cặp 1 k_c2s",
                               "clipboard", eid, ts, pt, text=False)
        vs.append({**v, "transfer_id": tid, "index": idx, "header_json": hdr, "hdr_len": len(hdr.encode()),
                   "chunk_data": data.hex()})
    return {"description": "clipboard op chunk: plaintext NHỊ PHÂN = hdr_len (uint16 BE) ‖ JSON header UTF-8 ‖ byte khối; "
                           "mã hóa như envelope thường. Khối trong vector ngắn hơn CHUNK_SIZE cho gọn.",
            "source": f"{SPEC} 0.5.1; 04-clipboard.md CLIP-03 API 4", "vectors": vs,
            "invalid_vectors": envelope_negatives(vs[0])[:2]}


def hl_file(ctx) -> dict:
    cam, aud = ctx["streams"]
    opus = lambda label, n: bytes([0x78]) + test_bytes(label, n - 1)  # noqa: E731 — gói Opus giả, byte TOC 0x78
    h264 = bytes.fromhex("0000000167") + test_bytes("h264 sps", 11) + bytes.fromhex("0000000168") + test_bytes("h264 pps", 4) \
        + bytes.fromhex("0000000165") + test_bytes("h264 idr", 40)
    specs = [  # (tên, kênh, chiều, khóa, seq, ts, plaintext, trường camera)
        ("call-audio Android→Mac seq 0", "call-audio", "s2c", aud, 0, 0, opus("opus 0", 40), None),
        ("call-audio Mac→Android seq 1", "call-audio", "c2s", aud, 1, 20, opus("opus 1", 33), None),
        ("camera video keyframe + SPS/PPS", "camera", "s2c", cam, 7, 233, None, (0x01, 0x03, 233333, h264)),
        ("camera audio Opus", "camera", "s2c", cam, 4294967295, 4294967295, None, (0x02, 0x00, 240000, opus("cam opus", 20))),
    ]
    vs = []
    for name, ch, d, st, seq, ts, pt, cam_fields in specs:
        if cam_fields:
            pt = camera_plaintext(*cam_fields)
        hdr = hl_header(seq, ts)
        nonce = test_bytes(f"hl nonce {name}", 24)
        key = st[f"k_{d}"]
        ct, tag = xchacha_seal(H(key), nonce, pt, hdr)
        v = {"name": name, "channel": ch, "direction": d, "key": key, "key_source": f"stream-keys kênh {ch} k_{d}",
             "seq": seq, "ts": ts, "header": hdr.hex(), "plaintext": pt.hex()}
        if cam_fields:
            v.update(zip(("track", "flags", "pts_us", "data"), (*cam_fields[:3], cam_fields[3].hex())))
        v.update({"nonce": nonce.hex(), "ciphertext": ct.hex(), "tag": tag.hex(),
                  "encrypted_part": (nonce + ct + tag).hex(), "frame": (hdr + nonce + ct + tag).hex()})
        vs.append(v)
    f0 = bytearray(H(vs[0]["frame"]))
    seq_bad = bytes(f0[:6]) + bytes([f0[6] ^ 0x01]) + bytes(f0[7:])
    tag_bad = bytes(f0[:-1]) + bytes([f0[-1] ^ 0x01])
    neg = [{"name": f"{vs[0]['name']} / seq bị sửa (AAD sai)", "reason": "aad_mismatch", "key": vs[0]["key"], "frame": seq_bad.hex()},
           {"name": f"{vs[0]['name']} / tag sai", "reason": "tag_mismatch", "key": vs[0]["key"], "frame": tag_bad.hex()}]
    return {"description": "Khung nhị phân HL: 'HL' ‖ ver 0x01 ‖ seq uint32 BE ‖ ts uint32 BE ‖ nonce(24) ‖ ciphertext ‖ tag(16); "
                           "AAD = 11 byte đầu. Camera plaintext = track(1) ‖ flags(1) ‖ pts_us int64 BE ‖ dữ liệu.",
            "source": f"{SPEC} 0.5.2", "vectors": vs, "invalid_vectors": neg}


def build(ctx) -> dict:
    return {"envelope.json": envelope_file(ctx), "ack.json": ack_file(ctx),
            "clipboard-chunk.json": chunk_file(ctx), "hl-frame.json": hl_file(ctx)}
