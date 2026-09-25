"""Kiểm vector khung tin: envelope, ack, clipboard-chunk, hl-frame — giải mã theo cả hai đường XChaCha20-Poly1305."""
import json
import struct

from verify_common import H, b64_decode_strict, xchacha_open_both, xchacha_seal_apple

HANDSHAKE_OPS = {("session", "hello"), ("session", "welcome"), ("session", "error"),
                 ("camera", "stream_hello"), ("camera", "stream_welcome"),
                 ("call_audio", "stream_hello"), ("call_audio", "stream_welcome")}
MIN_PAYLOAD = 24 + 16


def _known_keys(all_docs) -> dict:
    keys = {}
    for i, h in enumerate(all_docs["session-handshake.json"]["vectors"]):
        keys[f"session-handshake cặp {i + 1} k_c2s"], keys[f"session-handshake cặp {i + 1} k_s2c"] = h["k_c2s"], h["k_s2c"]
    for s in all_docs["stream-keys.json"]["vectors"]:
        keys[f"stream-keys kênh {s['channel']} k_c2s"], keys[f"stream-keys kênh {s['channel']} k_s2c"] = s["k_c2s"], s["k_s2c"]
    return keys


def open_envelope(key: bytes, wire: str):
    """Giải mã envelope như bên nhận thật: AAD dựng từ chính các trường của envelope. Trả (sodium, apple)."""
    env = json.loads(wire)
    raw = b64_decode_strict(env["payload"])
    if len(raw) < MIN_PAYLOAD:
        return None, None
    aad = f"{env['v']}|{env['type']}|{env['id']}|{env['ts']}".encode()
    return xchacha_open_both(key, raw[:24], aad, raw[24:-16], raw[-16:])


def check_envelope_vector(c, n, v, keys):
    env = json.loads(v["envelope"])
    c.eq(f"{n} trường envelope", (env["v"], env["type"], env["id"], env["ts"], env["payload"]),
         (v["v"], v["type"], v["id"], v["ts"], v["payload_b64"]))
    c.eq(f"{n} thứ tự khóa envelope", list(env), ["v", "type", "id", "ts", "payload"])
    raw = b64_decode_strict(env["payload"])
    if not v["encrypted"]:
        body = json.loads(raw.decode())
        c.eq(f"{n} payload = b64(JSON)", raw.decode(), v["plaintext"])
        c.true(f"{n} là tin bắt tay", (env["type"], body["op"]) in HANDSHAKE_OPS)
        return None
    c.eq(f"{n} khóa khớp {v['key_source']}", keys.get(v["key_source"]), v["key"])
    aad = f"{v['v']}|{v['type']}|{v['id']}|{v['ts']}"
    c.eq(f"{n} aad", (aad, aad.encode().hex()), (v["aad"], v["aad_hex"]))
    c.eq(f"{n} tách payload", (raw[:24].hex(), raw[24:-16].hex(), raw[-16:].hex()), (v["nonce"], v["ciphertext"], v["tag"]))
    pt = v["plaintext"].encode() if "plaintext" in v else H(v["plaintext_hex"])
    c.eq(f"{n} giải mã hai đường", open_envelope(H(v["key"]), v["envelope"]), (pt, pt))
    c.eq(f"{n} mã hóa kiểu Apple", xchacha_seal_apple(H(v["key"]), raw[:24], pt, aad.encode()), raw[24:])
    return pt


def check_envelope_negatives(c, fname, doc):
    for v in doc["invalid_vectors"]:
        c.eq(f"{fname}/{v['name']} phải bị từ chối", open_envelope(H(v["key"]), v["envelope"]), (None, None))


def check_envelope(c, doc, all_docs):
    keys = _known_keys(all_docs)
    for v in doc["vectors"]:
        pt = check_envelope_vector(c, f"envelope/{v['name']}", v, keys)
        if pt is not None:
            c.true(f"envelope/{v['name']} plaintext có op, data", set(json.loads(pt)) == {"op", "data"})
    c.true("envelope có cả vector mã hóa và chưa mã hóa", {v["encrypted"] for v in doc["vectors"]} == {True, False})
    check_envelope_negatives(c, "envelope", doc)


def check_ack(c, doc, all_docs):
    keys = _known_keys(all_docs)
    for v in doc["vectors"]:
        n = f"ack/{v['name']}"
        body = json.loads(check_envelope_vector(c, n, v, keys))
        c.eq(f"{n} type", v["type"], "ack")
        c.eq(f"{n} re/ok", (body["re"], body["ok"]), (v["re"], v["ok"]))
        c.true(f"{n} data hoặc error", ("data" in body) if body["ok"] else {"code", "message", "details"} <= set(body["error"]))
    c.true("ack có cả ok và lỗi", {v["ok"] for v in doc["vectors"]} == {True, False})
    check_envelope_negatives(c, "ack", doc)


def check_chunk(c, doc, all_docs):
    keys = _known_keys(all_docs)
    for v in doc["vectors"]:
        n = f"clipboard-chunk/{v['name']}"
        pt = check_envelope_vector(c, n, v, keys)
        (hdr_len,) = struct.unpack(">H", pt[:2])
        hdr = pt[2:2 + hdr_len].decode()
        c.eq(f"{n} byte đầu 0x00", pt[0], 0)
        c.eq(f"{n} hdr_len/header", (hdr_len, hdr), (v["hdr_len"], v["header_json"]))
        body = json.loads(hdr)
        c.eq(f"{n} header", (body["op"], body["data"]["transfer_id"], body["data"]["index"]),
             ("chunk", v["transfer_id"], v["index"]))
        c.eq(f"{n} dữ liệu khối", pt[2 + hdr_len:].hex(), v["chunk_data"])
    check_envelope_negatives(c, "clipboard-chunk", doc)


def open_frame(key: bytes, frame: bytes):
    if len(frame) < 11 + MIN_PAYLOAD or frame[:3] != b"HL\x01":
        return None, None
    return xchacha_open_both(key, frame[11:35], frame[:11], frame[35:-16], frame[-16:])


def check_hl(c, doc, all_docs):
    keys = _known_keys(all_docs)
    for v in doc["vectors"]:
        n = f"hl-frame/{v['name']}"
        frame, key, pt = H(v["frame"]), H(v["key"]), H(v["plaintext"])
        c.eq(f"{n} khóa khớp {v['key_source']}", keys.get(v["key_source"]), v["key"])
        c.eq(f"{n} header", frame[:11].hex(), v["header"])
        c.eq(f"{n} magic/ver/seq/ts", (frame[:2], frame[2], *struct.unpack(">II", frame[3:11])), (b"HL", 1, v["seq"], v["ts"]))
        c.eq(f"{n} encrypted_part", frame[11:].hex(), v["encrypted_part"])
        c.eq(f"{n} tách", (frame[11:35].hex(), frame[35:-16].hex(), frame[-16:].hex()), (v["nonce"], v["ciphertext"], v["tag"]))
        c.eq(f"{n} giải mã hai đường", open_frame(key, frame), (pt, pt))
        c.eq(f"{n} mã hóa kiểu Apple", xchacha_seal_apple(key, frame[11:35], pt, frame[:11]), frame[35:])
        if v["channel"] == "camera":
            c.eq(f"{n} camera plaintext", (pt[0], pt[1], struct.unpack(">q", pt[2:10])[0], pt[10:].hex()),
                 (v["track"], v["flags"], v["pts_us"], v["data"]))
    for v in doc["invalid_vectors"]:
        c.eq(f"hl-frame/{v['name']} phải bị từ chối", open_frame(H(v["key"]), H(v["frame"])), (None, None))


CHECKS = {"envelope.json": check_envelope, "ack.json": check_ack,
          "clipboard-chunk.json": check_chunk, "hl-frame.json": check_hl}
