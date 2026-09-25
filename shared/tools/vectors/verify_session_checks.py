"""Kiểm vector định danh và phiên: device-id, pair-prk, session-handshake, session-rekey, stream-keys.

Mọi giá trị được tính lại từ input trong file bằng hashlib/hmac + libsodium, và kiểm chuỗi liên kết giữa các file.
"""
import hmac
import json

from verify_common import (H, b64_decode_strict, b64u, b64u_decode, ed25519_pub, hkdf, hmac256, sha256, uuid16,
                           uuid_str, x25519, x25519_base)


def device_id(ik_sig_pub: bytes) -> str:
    b = bytearray(sha256(ik_sig_pub)[:16])
    b[6] = (b[6] & 0x0F) | 0x80
    b[8] = (b[8] & 0x3F) | 0x80
    return uuid_str(bytes(b))


def check_device_id(c, doc, _all):
    for v in doc["vectors"]:
        n = f"device-id/{v['name']}"
        pub = H(v["ik_sig_pub"])
        c.eq(f"{n} ik_sig_pub từ seed", ed25519_pub(H(v["ik_sig_seed"])), pub)
        c.eq(f"{n} sha256", sha256(pub).hex(), v["sha256"])
        c.eq(f"{n} device_id", device_id(pub), v["device_id"])
        c.eq(f"{n} device_id_bytes", uuid16(v["device_id"]).hex(), v["device_id_bytes"])
        c.true(f"{n} version 8 / variant 10", v["device_id"][14] == "8" and v["device_id"][19] in "89ab")


def check_pair_prk(c, doc, _all):
    orders = set()
    for v in doc["vectors"]:
        n = f"pair-prk/{v['name']}"
        cid, aid = v["client_device_id"], v["android_device_id"]
        c.eq(f"{n} client device_id", device_id(H(v["client_ik_sig_pub"])), cid)
        c.eq(f"{n} android device_id", device_id(H(v["android_ik_sig_pub"])), aid)
        c.eq(f"{n} client ik_dh_pub", x25519_base(H(v["client_ik_dh_priv"])).hex(), v["client_ik_dh_pub"])
        c.eq(f"{n} android ik_dh_pub", x25519_base(H(v["android_ik_dh_priv"])).hex(), v["android_ik_dh_pub"])
        shared = x25519(H(v["client_ik_dh_priv"]), H(v["android_ik_dh_pub"]))
        c.eq(f"{n} dh phía client", shared.hex(), v["dh_shared"])
        c.eq(f"{n} dh phía android", x25519(H(v["android_ik_dh_priv"]), H(v["client_ik_dh_pub"])).hex(), v["dh_shared"])
        c.eq(f"{n} ikm", (shared + H(v["pairing_secret"])).hex(), v["ikm"])
        smaller = uuid16(cid) < uuid16(aid)
        orders.add(smaller)
        c.eq(f"{n} client_id_is_smaller", smaller, v["client_id_is_smaller"])
        c.eq(f"{n} salt_input", b"".join(sorted([uuid16(cid), uuid16(aid)])).hex(), v["salt_input"])
        c.eq(f"{n} salt", sha256(H(v["salt_input"])).hex(), v["salt"])
        c.eq(f"{n} prk", hkdf(H(v["ikm"]), v["info"].encode(), v["length"], H(v["salt"])).hex(), v["prk"])
    c.eq("pair-prk có cả hai thứ tự device_id", orders, {True, False})


def _hs_payload(c, n, wire, plaintext, op):
    env = json.loads(wire)
    c.eq(f"{n} envelope v/type", (env["v"], env["type"]), (1, "session"))
    c.eq(f"{n} payload b64 = plaintext", b64_decode_strict(env["payload"]).decode(), plaintext)
    body = json.loads(plaintext)
    c.eq(f"{n} op", body["op"], op)
    return body["data"]


def check_handshake(c, doc, all_docs):
    prk_by_pair = {p["pair_id"]: p for p in all_docs["pair-prk.json"]["vectors"]}
    for v in doc["vectors"]:
        n = f"session-handshake/{v['name']}"
        pair = prk_by_pair[v["pair_id"]]
        c.eq(f"{n} prk khớp pair-prk", v["prk"], pair["prk"])
        c.eq(f"{n} device_id khớp pair-prk", (v["client_device_id"], v["server_device_id"]),
             (pair["client_device_id"], pair["android_device_id"]))
        prk, k_auth = H(v["prk"]), hkdf(H(v["prk"]), b"handlive/v1/session-auth", 32)
        c.eq(f"{n} k_auth", k_auth.hex(), v["k_auth"])
        ce_pub, se_pub = x25519_base(H(v["client_eph_priv"])), x25519_base(H(v["server_eph_priv"]))
        c.eq(f"{n} eph pub", (ce_pub.hex(), se_pub.hex()), (v["client_eph_pub"], v["server_eph_pub"]))
        t1 = b"HL1|hello|" + uuid16(v["pair_id"]) + uuid16(v["client_device_id"]) + ce_pub + H(v["client_nonce"])
        t2 = b"HL1|welcome|" + t1 + uuid16(v["server_device_id"]) + se_pub + H(v["server_nonce"])
        c.eq(f"{n} T1", t1.hex(), v["t1"])
        c.eq(f"{n} T2", t2.hex(), v["t2"])
        c.eq(f"{n} hello mac", hmac256(k_auth, t1).hex(), v["hello_mac"])
        c.eq(f"{n} welcome mac", hmac256(k_auth, t2).hex(), v["welcome_mac"])
        shared = x25519(H(v["client_eph_priv"]), se_pub)
        c.eq(f"{n} eph_shared hai phía", (shared.hex(), x25519(H(v["server_eph_priv"]), ce_pub).hex()),
             (v["eph_shared"], v["eph_shared"]))
        c.eq(f"{n} secret_salt", sha256(t2).hex(), v["secret_salt"])
        secret = hkdf(shared + prk, b"handlive/v1/session", 64, sha256(t2))
        c.eq(f"{n} secret", secret.hex(), v["secret"])
        c.eq(f"{n} k_c2s/k_s2c", (secret[:32].hex(), secret[32:].hex()), (v["k_c2s"], v["k_s2c"]))
        d = _hs_payload(c, f"{n} hello", v["hello_envelope"], v["hello_plaintext"], "hello")
        c.eq(f"{n} hello data", (d["protocol"], d["pair_id"], d["device_id"], b64u_decode(d["eph"]),
                                 b64u_decode(d["nonce"]), b64u_decode(d["mac"]).hex()),
             (1, v["pair_id"], v["client_device_id"], ce_pub, H(v["client_nonce"]), v["hello_mac"]))
        d = _hs_payload(c, f"{n} welcome", v["welcome_envelope"], v["welcome_plaintext"], "welcome")
        c.eq(f"{n} welcome data", (d["device_id"], b64u_decode(d["eph"]), b64u_decode(d["nonce"]), b64u_decode(d["mac"]).hex()),
             (v["server_device_id"], se_pub, H(v["server_nonce"]), v["welcome_mac"]))
    check_mac_negatives(c, "session-handshake", doc)


def check_mac_negatives(c, fname, doc):
    for v in doc["invalid_vectors"]:
        ok = hmac.compare_digest(hmac256(H(v["key"]), H(v["message"])), H(v["mac"]))
        c.eq(f"{fname}/{v['name']} phải bị từ chối", ok, False)


def check_rekey(c, doc, all_docs):
    prev = all_docs["session-handshake.json"]["vectors"][0]["secret"]
    for v in doc["vectors"]:
        n = f"session-rekey/{v['name']}"
        c.eq(f"{n} secret_old nối chuỗi", v["secret_old"], prev)
        ie_pub, re_pub = x25519_base(H(v["initiator_eph_priv"])), x25519_base(H(v["responder_eph_priv"]))
        c.eq(f"{n} eph pub", (ie_pub.hex(), re_pub.hex()), (v["initiator_eph_pub"], v["responder_eph_pub"]))
        shared = x25519(H(v["initiator_eph_priv"]), re_pub)
        c.eq(f"{n} eph_shared hai phía", (shared.hex(), x25519(H(v["responder_eph_priv"]), ie_pub).hex()),
             (v["eph_shared"], v["eph_shared"]))
        c.eq(f"{n} ikm", (shared + H(v["secret_old"])).hex(), v["ikm"])
        salt_in = H(v["initiator_nonce"]) + H(v["responder_nonce"])
        c.eq(f"{n} salt", (salt_in.hex(), sha256(salt_in).hex()), (v["salt_input"], v["salt"]))
        new = hkdf(H(v["ikm"]), v["info"].encode(), 64, sha256(salt_in))
        c.eq(f"{n} secret_new", new.hex(), v["secret_new"])
        c.eq(f"{n} k_c2s/k_s2c", (new[:32].hex(), new[32:].hex()), (v["k_c2s"], v["k_s2c"]))
        req, ack = json.loads(v["request_plaintext"]), json.loads(v["ack_data"])
        c.eq(f"{n} request", (req["op"], req["data"]["epoch"], req["data"]["eph"], req["data"]["nonce"]),
             ("rekey", v["epoch"], b64u(ie_pub), b64u(H(v["initiator_nonce"]))))
        c.eq(f"{n} ack data", (ack["epoch"], ack["eph"], ack["nonce"]), (v["epoch"], b64u(re_pub), b64u(H(v["responder_nonce"]))))
        prev = v["secret_new"]


def check_stream(c, doc, all_docs):
    secrets = {h["secret"] for h in all_docs["session-handshake.json"]["vectors"]}
    for v in doc["vectors"]:
        n = f"stream-keys/{v['name']}"
        c.true(f"{n} secret lấy từ session-handshake", v["secret"] in secrets)
        c.eq(f"{n} info", v["info"], f"handlive/v1/stream/{v['channel']}/{v['session_id']}")
        ks = hkdf(H(v["secret"]), v["info"].encode(), 96)
        c.eq(f"{n} k_stream", ks.hex(), v["k_stream"])
        c.eq(f"{n} tách khóa", (ks[:32].hex(), ks[32:64].hex(), ks[64:].hex()), (v["k_auth"], v["k_c2s"], v["k_s2c"]))
        sid, nc, ns = uuid16(v["session_id"]), H(v["nonce_c"]), H(v["nonce_s"])
        hmsg, wmsg = b"HLSTREAM1|" + sid + nc, b"HLSTREAM1|welcome|" + sid + nc + ns
        c.eq(f"{n} thông điệp", (hmsg.hex(), wmsg.hex()), (v["hello_message"], v["welcome_message"]))
        c.eq(f"{n} mac", (hmac256(ks[:32], hmsg).hex(), hmac256(ks[:32], wmsg).hex()), (v["hello_mac"], v["welcome_mac"]))
        for kind, op, nonce, mac in (("hello", "stream_hello", nc, v["hello_mac"]), ("welcome", "stream_welcome", ns, v["welcome_mac"])):
            env = json.loads(v[f"stream_{kind}_envelope"])
            c.eq(f"{n} {kind} envelope type", (env["v"], env["type"]), (1, v["envelope_type"]))
            body = json.loads(b64_decode_strict(env["payload"]).decode())
            c.eq(f"{n} {kind} plaintext", json.dumps(body, separators=(",", ":"), ensure_ascii=False), v[f"stream_{kind}_plaintext"])
            c.eq(f"{n} {kind} data", (body["op"], body["data"]["session_id"], b64u_decode(body["data"]["nonce"]),
                                      b64u_decode(body["data"]["mac"]).hex()), (op, v["session_id"], nonce, mac))
    check_mac_negatives(c, "stream-keys", doc)


CHECKS = {"device-id.json": check_device_id, "pair-prk.json": check_pair_prk,
          "session-handshake.json": check_handshake, "session-rekey.json": check_rekey, "stream-keys.json": check_stream}
