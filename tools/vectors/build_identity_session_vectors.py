"""Dựng vector định danh và phiên: device-id, pair-prk, session-handshake, session-rekey, stream-keys.

Khóa mẫu: ik_sig = khóa Ed25519 của RFC 8032 §7.1, ik_dh = khóa Alice/Bob của RFC 7748 §6.1,
còn lại là test_bytes(label) — toàn giá trị công khai, không phải khóa thật.
"""
import hashlib

import rfc_source_values as R
from handlive_protocol_derivations import (b64, b64u, compact_json, device_id_from_pub, ed25519_pub, envelope_wire,
                                           hkdf, hmac256, pair_salt_input, test_bytes, uuid_bytes, x25519_dh, x25519_pub)

H = bytes.fromhex
SPEC = "docs/detailed-design/00-common-specs.md"
X = R.X25519_6_1
# (tên, pair_id, (ik_sig client, ik_dh client), (ik_sig android, ik_dh android), nhãn pairing_secret)
PAIRS = [
    ("cặp 1", "3f2b1c4d-5e6f-4a7b-8c9d-0e1f2a3b4c5d", (0, "alice"), (1, "bob"), "pairing_secret 1"),
    ("cặp 2", "9a8b7c6d-5e4f-4a3b-9c2d-1e0f2a3b4c5d", (2, "bob"), (0, "alice"), "pairing_secret 2"),
]
# (id, ts) của envelope hello/welcome cho từng cặp
HANDSHAKE_ENV = [
    (("0192f400-11aa-7b2c-9d3e-4f5a6b7c8d9e", 1727151000000), ("0192f400-11b4-7c3d-8e4f-5a6b7c8d9e0f", 1727151000041)),
    (("0192f410-2a3b-7c4d-9e5f-6a7b8c9d0e1f", 1727152000000), ("0192f410-2a45-7d5e-8f60-7b8c9d0e1f2a", 1727152000057)),
]
STREAMS = [  # (kênh, type envelope, session_id, chỉ số handshake, id/ts hello, id/ts welcome)
    ("camera", "camera", "0192f5a0-3c4d-7e8f-9a0b-1c2d3e4f5a6b", 0,
     ("0192f5a0-4a00-7b11-8c22-9d33ae44bf55", 1727151100000), ("0192f5a0-4a0c-7c22-9d33-ae44bf55c066", 1727151100012)),
    ("call-audio", "call_audio", "0192f5a2-7c1e-7a55-9d0b-3f4c2a1b9e10", 1,
     ("0192f5a2-8000-7a01-8b02-9c03ad04be05", 1727152100000), ("0192f5a2-8009-7b02-8c03-9d04ae05bf06", 1727152100009)),
]


def device_id_file() -> dict:
    vs = []
    for name, seed, pub in R.ED25519_8032:
        assert ed25519_pub(H(seed)).hex() == pub
        did = device_id_from_pub(H(pub))
        vs.append({"name": name, "ik_sig_seed": seed, "ik_sig_pub": pub, "sha256": hashlib.sha256(H(pub)).hexdigest(),
                   "device_id_bytes": uuid_bytes(did).hex(), "device_id": did})
    return {"description": "device_id = UUIDv8 từ 16 byte đầu SHA-256(ik_sig_pub): byte 6 = (b6 & 0x0f) | 0x80, "
                           "byte 8 = (b8 & 0x3f) | 0x80. ik_sig_seed là khóa bí mật Ed25519 32 byte (seed).",
            "source": f"{SPEC} 0.2; khóa từ RFC 8032 §7.1 TEST 1–3", "vectors": vs}


def _pair(p) -> dict:
    name, pair_id, (cs, cd), (as_, ad), ps_label = p
    c_pub, a_pub = H(R.ED25519_8032[cs][2]), H(R.ED25519_8032[as_][2])
    c_dh, a_dh = H(X[f"{cd}_priv"]), H(X[f"{ad}_priv"])
    c_id, a_id = device_id_from_pub(c_pub), device_id_from_pub(a_pub)
    shared = x25519_dh(c_dh, x25519_pub(a_dh))
    assert shared == x25519_dh(a_dh, x25519_pub(c_dh))
    secret = test_bytes(ps_label, 32)
    salt_in = pair_salt_input(c_id, a_id)
    salt = hashlib.sha256(salt_in).digest()
    info = b"handlive/v1/pair"
    return {"name": name, "pair_id": pair_id, "client_ik_sig_pub": c_pub.hex(), "client_device_id": c_id,
            "android_ik_sig_pub": a_pub.hex(), "android_device_id": a_id,
            "client_ik_dh_priv": c_dh.hex(), "client_ik_dh_pub": x25519_pub(c_dh).hex(),
            "android_ik_dh_priv": a_dh.hex(), "android_ik_dh_pub": x25519_pub(a_dh).hex(),
            "dh_shared": shared.hex(), "pairing_secret": secret.hex(), "ikm": (shared + secret).hex(),
            "client_id_is_smaller": uuid_bytes(c_id) < uuid_bytes(a_id),
            "salt_input": salt_in.hex(), "salt": salt.hex(), "info": info.decode(), "length": 32,
            "prk": hkdf(shared + secret, info, 32, salt).hex()}


def pair_prk_file(pairs) -> dict:
    assert pairs[0]["client_id_is_smaller"] != pairs[1]["client_id_is_smaller"], "cần cả hai thứ tự device_id"
    return {"description": "PRK = HKDF-SHA256(ikm = X25519(ik_dh mình, ik_dh đối phương) ‖ pairing_secret, "
                           "salt = SHA-256(device_id nhỏ hơn ‖ lớn hơn, 16 byte), info = \"handlive/v1/pair\", L = 32).",
            "source": f"{SPEC} 0.6.2; ik_dh từ RFC 7748 §6.1", "vectors": pairs}


def _handshake(i: int, pair: dict) -> dict:
    prk, pair_id, c_id, s_id = H(pair["prk"]), pair["pair_id"], pair["client_device_id"], pair["android_device_id"]
    k_auth = hkdf(prk, b"handlive/v1/session-auth", 32)
    ce, se = test_bytes(f"session {i + 1} eph client", 32), test_bytes(f"session {i + 1} eph server", 32)
    cn, sn = test_bytes(f"session {i + 1} nonce client", 32), test_bytes(f"session {i + 1} nonce server", 32)
    ce_pub, se_pub = x25519_pub(ce), x25519_pub(se)
    t1 = b"HL1|hello|" + uuid_bytes(pair_id) + uuid_bytes(c_id) + ce_pub + cn
    t2 = b"HL1|welcome|" + t1 + uuid_bytes(s_id) + se_pub + sn
    m1, m2 = hmac256(k_auth, t1), hmac256(k_auth, t2)
    shared = x25519_dh(ce, se_pub)
    assert shared == x25519_dh(se, ce_pub)
    secret = hkdf(shared + prk, b"handlive/v1/session", 64, hashlib.sha256(t2).digest())
    hello_pt = compact_json({"op": "hello", "data": {"protocol": 1, "pair_id": pair_id, "device_id": c_id,
                                                      "eph": b64u(ce_pub), "nonce": b64u(cn), "mac": b64u(m1)}})
    welcome_pt = compact_json({"op": "welcome", "data": {"device_id": s_id, "eph": b64u(se_pub),
                                                          "nonce": b64u(sn), "mac": b64u(m2)}})
    (hid, hts), (wid, wts) = HANDSHAKE_ENV[i]
    return {"name": f"bắt tay {pair['name']}", "prk": prk.hex(), "pair_id": pair_id, "client_device_id": c_id,
            "server_device_id": s_id, "k_auth": k_auth.hex(),
            "client_eph_priv": ce.hex(), "client_eph_pub": ce_pub.hex(), "client_nonce": cn.hex(),
            "t1": t1.hex(), "hello_mac": m1.hex(),
            "server_eph_priv": se.hex(), "server_eph_pub": se_pub.hex(), "server_nonce": sn.hex(),
            "t2": t2.hex(), "welcome_mac": m2.hex(),
            "eph_shared": shared.hex(), "secret_salt": hashlib.sha256(t2).hexdigest(), "secret": secret.hex(),
            "k_c2s": secret[:32].hex(), "k_s2c": secret[32:].hex(),
            "hello_plaintext": hello_pt, "hello_envelope": envelope_wire(1, "session", hid, hts, b64(hello_pt.encode())),
            "welcome_plaintext": welcome_pt,
            "welcome_envelope": envelope_wire(1, "session", wid, wts, b64(welcome_pt.encode()))}


def _mac_negatives(prefix: str, key: str, msg: str, mac: str) -> list[dict]:
    bad_msg = bytearray(H(msg)); bad_msg[-1] ^= 0x01
    bad_mac = bytearray(H(mac)); bad_mac[0] ^= 0x80
    return [{"name": f"{prefix} / mac sai", "reason": "mac_mismatch", "key": key, "message": msg, "mac": bad_mac.hex()},
            {"name": f"{prefix} / thông điệp bị sửa", "reason": "message_tampered", "key": key,
             "message": bad_msg.hex(), "mac": mac}]


def handshake_file(hs) -> dict:
    neg = _mac_negatives("hello cặp 1", hs[0]["k_auth"], hs[0]["t1"], hs[0]["hello_mac"])
    neg += _mac_negatives("welcome cặp 1", hs[0]["k_auth"], hs[0]["t2"], hs[0]["welcome_mac"])
    return {"description": "Bắt tay /v1/ctl. K_auth = HKDF(PRK, salt rỗng, info \"handlive/v1/session-auth\", L 32). "
                           "T1/T2 ghép BYTE thô (uuid 16 byte, eph 32, nonce 32). mac = HMAC-SHA256(K_auth, T). "
                           "secret = HKDF(X25519(eph) ‖ PRK, salt SHA-256(T2), info \"handlive/v1/session\", L 64).",
            "source": f"{SPEC} 0.6.3 bước 1–3, 0.5.1; 03-connectivity.md CONN-01 API 4–5", "vectors": hs,
            "invalid_vectors": neg}


def rekey_file(hs) -> tuple[dict, list]:
    vs, secret = [], H(hs[0]["secret"])
    for epoch, initiator in ((1, "client"), (2, "server")):
        ie, re_ = test_bytes(f"rekey {epoch} eph initiator", 32), test_bytes(f"rekey {epoch} eph responder", 32)
        inn, rn = test_bytes(f"rekey {epoch} nonce initiator", 32), test_bytes(f"rekey {epoch} nonce responder", 32)
        shared = x25519_dh(ie, x25519_pub(re_))
        salt_in = inn + rn
        new = hkdf(shared + secret, b"handlive/v1/rekey", 64, hashlib.sha256(salt_in).digest())
        req = compact_json({"op": "rekey", "data": {"epoch": epoch, "eph": b64u(x25519_pub(ie)), "nonce": b64u(inn)}})
        ack_data = compact_json({"epoch": epoch, "eph": b64u(x25519_pub(re_)), "nonce": b64u(rn)})
        vs.append({"name": f"rekey epoch {epoch} ({initiator} khởi tạo)", "epoch": epoch, "initiator": initiator,
                   "secret_old": secret.hex(), "initiator_eph_priv": ie.hex(), "initiator_eph_pub": x25519_pub(ie).hex(),
                   "initiator_nonce": inn.hex(), "responder_eph_priv": re_.hex(),
                   "responder_eph_pub": x25519_pub(re_).hex(), "responder_nonce": rn.hex(),
                   "eph_shared": shared.hex(), "ikm": (shared + secret).hex(), "salt_input": salt_in.hex(),
                   "salt": hashlib.sha256(salt_in).hexdigest(), "info": "handlive/v1/rekey", "length": 64,
                   "secret_new": new.hex(), "k_c2s": new[:32].hex(), "k_s2c": new[32:].hex(),
                   "request_plaintext": req, "ack_data": ack_data})
        secret = new
    return {"description": "Rekey: secret_new = HKDF(X25519(eph mới) ‖ secret_old (64 byte), "
                           "salt = SHA-256(nonce bên khởi tạo ‖ nonce bên nhận), info \"handlive/v1/rekey\", L 64). "
                           "k_c2s = 32 byte đầu, k_s2c = 32 byte sau (theo vai C/S, không theo bên khởi tạo). "
                           "secret_new thay secret cho lần rekey sau (epoch 2 nối từ epoch 1).",
            "source": f"{SPEC} 0.6.3 bước 6; 03-connectivity.md CONN-02 API 3", "vectors": vs}, vs


def stream_file(hs) -> dict:
    vs = []
    for channel, typ, sid, hi, (hid, hts), (wid, wts) in STREAMS:
        secret = H(hs[hi]["secret"])
        info = f"handlive/v1/stream/{channel}/{sid}".encode()
        ks = hkdf(secret, info, 96)
        k_auth = ks[:32]
        nc, ns = test_bytes(f"stream {channel} nonce_c", 32), test_bytes(f"stream {channel} nonce_s", 32)
        hmsg = b"HLSTREAM1|" + uuid_bytes(sid) + nc
        wmsg = b"HLSTREAM1|welcome|" + uuid_bytes(sid) + nc + ns
        hmac_, wmac = hmac256(k_auth, hmsg), hmac256(k_auth, wmsg)
        hpt = compact_json({"op": "stream_hello", "data": {"session_id": sid, "nonce": b64u(nc), "mac": b64u(hmac_)}})
        wpt = compact_json({"op": "stream_welcome", "data": {"session_id": sid, "nonce": b64u(ns), "mac": b64u(wmac)}})
        vs.append({"name": f"kênh {channel}", "channel": channel, "envelope_type": typ, "session_id": sid,
                   "secret": secret.hex(), "info": info.decode(), "length": 96, "k_stream": ks.hex(),
                   "k_auth": k_auth.hex(), "k_c2s": ks[32:64].hex(), "k_s2c": ks[64:].hex(),
                   "nonce_c": nc.hex(), "nonce_s": ns.hex(),
                   "hello_message": hmsg.hex(), "hello_mac": hmac_.hex(),
                   "welcome_message": wmsg.hex(), "welcome_mac": wmac.hex(),
                   "stream_hello_plaintext": hpt, "stream_hello_envelope": envelope_wire(1, typ, hid, hts, b64(hpt.encode())),
                   "stream_welcome_plaintext": wpt,
                   "stream_welcome_envelope": envelope_wire(1, typ, wid, wts, b64(wpt.encode()))})
    v = vs[0]
    neg = _mac_negatives("stream_hello camera", v["k_auth"], v["hello_message"], v["hello_mac"])
    swapped = (b"HLSTREAM1|welcome|" + uuid_bytes(v["session_id"]) + H(v["nonce_s"]) + H(v["nonce_c"])).hex()
    neg.append({"name": "stream_welcome camera / đảo thứ tự nonce", "reason": "message_tampered",
                "key": v["k_auth"], "message": swapped, "mac": v["welcome_mac"]})
    return {"description": "K_stream = HKDF(secret, salt rỗng, info \"handlive/v1/stream/<kênh>/<session_id 36 ký tự>\", L 96) "
                           "= k_auth ‖ k_c2s ‖ k_s2c. MAC hello = HMAC(k_auth, \"HLSTREAM1|\" ‖ session_id(16) ‖ nonce_c(32)); "
                           "welcome = HMAC(k_auth, \"HLSTREAM1|welcome|\" ‖ session_id(16) ‖ nonce_c ‖ nonce_s).",
            "source": f"{SPEC} 0.6.3 bước 7; 08-camera-mic.md CAM-02; 07-call-audio.md AUDIO-04",
            "vectors": vs, "invalid_vectors": neg}


def build() -> tuple[dict, dict]:
    pairs = [_pair(p) for p in PAIRS]
    hs = [_handshake(i, p) for i, p in enumerate(pairs)]
    rekey, _ = rekey_file(hs)
    streams = stream_file(hs)
    files = {"device-id.json": device_id_file(), "pair-prk.json": pair_prk_file(pairs),
             "session-handshake.json": handshake_file(hs), "session-rekey.json": rekey, "stream-keys.json": streams}
    return files, {"handshakes": hs, "streams": streams["vectors"]}
