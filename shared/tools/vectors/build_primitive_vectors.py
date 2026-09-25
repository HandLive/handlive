"""Dựng các file vector nguyên thủy: xchacha20-poly1305, hchacha20, chacha20-poly1305, x25519, hkdf-sha256."""
from cryptography.hazmat.primitives.ciphers.aead import ChaCha20Poly1305

import rfc_source_values as R
from handlive_protocol_derivations import hkdf, hmac256, test_bytes, xchacha_seal
from hchacha20_reference import hchacha20, xchacha_to_chacha

H = bytes.fromhex
DRAFT = "draft-irtf-cfrg-xchacha-03"


def _flip_last(hex_str: str) -> str:
    b = bytearray(H(hex_str))
    b[-1] ^= 0x01
    return b.hex()


def _aead_negatives(v: dict) -> list[dict]:
    """Ba cách làm hỏng: tag sai, AAD sai, ciphertext sai — đều phải bị từ chối."""
    base = {k: v[k] for k in ("key", "nonce", "aad", "ciphertext", "tag")}
    return [
        {"name": f"{v['name']} / tag sai", "reason": "tag_mismatch", **base, "tag": _flip_last(v["tag"])},
        {"name": f"{v['name']} / AAD sai", "reason": "aad_mismatch", **base, "aad": v["aad"] + "00"},
        {"name": f"{v['name']} / ciphertext sai", "reason": "ciphertext_mismatch", **base,
         "ciphertext": _flip_last(v["ciphertext"]) if v["ciphertext"] else "00"},
    ]


def _xchacha_vector(name: str, source: str, key: bytes, nonce: bytes, aad: bytes, pt: bytes) -> dict:
    ct, tag = xchacha_seal(key, nonce, pt, aad)
    subkey, n12 = xchacha_to_chacha(key, nonce)
    return {"name": name, "source": source, "key": key.hex(), "nonce": nonce.hex(), "aad": aad.hex(),
            "plaintext": pt.hex(), "ciphertext": ct.hex(), "tag": tag.hex(),
            "hchacha20_subkey": subkey.hex(), "chacha20_nonce": n12.hex()}


def xchacha_file() -> dict:
    a = R.XCHACHA_A_3_1
    v1 = _xchacha_vector("draft A.3.1", f"{DRAFT} §A.3.1", H(a["key"]), H(a["nonce"]), H(a["aad"]), H(a["plaintext"]))
    assert (v1["ciphertext"], v1["tag"]) == (a["ciphertext"], a["tag"]), "libsodium lệch vector draft"
    v2 = _xchacha_vector("tự sinh: plaintext rỗng, AAD rỗng", "tự sinh (libsodium)",
                         test_bytes("xchacha v2 key", 32), test_bytes("xchacha v2 nonce", 24), b"", b"")
    v3 = _xchacha_vector("tự sinh: 3 khối + AAD kiểu envelope", "tự sinh (libsodium)",
                         test_bytes("xchacha v3 key", 32), test_bytes("xchacha v3 nonce", 24),
                         "1|clipboard|0192f3e8-1b2c-7d3e-8f40-5a6b7c8d9e0f|1727150160456".encode(),
                         test_bytes("xchacha v3 plaintext", 150))
    return {"description": "XChaCha20-Poly1305 (AEAD_XChaCha20_Poly1305). Kiểm theo hai cách: AEAD XChaCha trực tiếp "
                           "và HChaCha20(key, nonce[0:16]) + ChaCha20-Poly1305(subkey, 0x00000000 ‖ nonce[16:24]).",
            "source": f"{DRAFT} §A.3.1; vector tự sinh bằng libsodium",
            "vectors": [v1, v2, v3], "invalid_vectors": _aead_negatives(v1) + _aead_negatives(v3)[:1]}


def hchacha_file() -> dict:
    a = R.HCHACHA20_2_2_1
    assert hchacha20(H(a["key"]), H(a["nonce"])).hex() == a["subkey"]
    k3, n3 = test_bytes("hchacha v3 key", 32), test_bytes("hchacha v3 nonce", 16)
    xa = R.XCHACHA_A_3_1
    return {"description": "HChaCha20: (key 32 byte, nonce 16 byte) → subkey 32 byte.",
            "source": f"{DRAFT} §2.2.1; vector 2 dẫn từ input §A.3.1; vector 3 tự sinh",
            "vectors": [
                {"name": "draft §2.2.1", "source": f"{DRAFT} §2.2.1", **a},
                {"name": "draft A.3.1 key/nonce[0:16]", "source": f"dẫn từ {DRAFT} §A.3.1 (subkey tự tính)",
                 "key": xa["key"], "nonce": xa["nonce"][:32], "subkey": hchacha20(H(xa["key"]), H(xa["nonce"][:32])).hex()},
                {"name": "tự sinh", "source": "tự sinh", "key": k3.hex(), "nonce": n3.hex(), "subkey": hchacha20(k3, n3).hex()},
            ]}


def chacha_file() -> dict:
    vs = []
    for name, a in (("RFC 8439 §2.8.2", R.CHACHA_2_8_2), ("RFC 8439 §A.5", R.CHACHA_A_5)):
        out = ChaCha20Poly1305(H(a["key"])).encrypt(H(a["nonce"]), H(a["plaintext"]), H(a["aad"]))
        assert out.hex() == a["ciphertext"] + a["tag"]
        vs.append({"name": name, "source": name, **a})
    return {"description": "AEAD_ChaCha20_Poly1305 (nonce 12 byte) — đúng thứ CryptoKit ChaChaPoly dùng.",
            "source": "RFC 8439 §2.8.2, §A.5", "vectors": vs,
            "invalid_vectors": _aead_negatives(vs[0]) + _aead_negatives(vs[1])[:1]}


def x25519_file() -> dict:
    x = R.X25519_6_1
    vs = [{"name": f"RFC 7748 §5.2 #{i + 1}", "source": "RFC 7748 §5.2", "scalar": s, "u": u, "output": o}
          for i, (s, u, o) in enumerate(R.X25519_5_2)]
    vs += [
        {"name": "RFC 7748 §6.1 Alice pub", "source": "RFC 7748 §6.1", "scalar": x["alice_priv"], "u": R.X25519_BASE_U, "output": x["alice_pub"]},
        {"name": "RFC 7748 §6.1 Bob pub", "source": "RFC 7748 §6.1", "scalar": x["bob_priv"], "u": R.X25519_BASE_U, "output": x["bob_pub"]},
        {"name": "RFC 7748 §6.1 K (Alice)", "source": "RFC 7748 §6.1", "scalar": x["alice_priv"], "u": x["bob_pub"], "output": x["shared"]},
        {"name": "RFC 7748 §6.1 K (Bob)", "source": "RFC 7748 §6.1", "scalar": x["bob_priv"], "u": x["alice_pub"], "output": x["shared"]},
    ]
    return {"description": "X25519(scalar, u) → u-coordinate 32 byte (little endian, scalar được clamp theo RFC).",
            "source": "RFC 7748 §5.2, §6.1", "vectors": vs}


def hkdf_file() -> dict:
    vs = []
    for name, ikm, salt, info, length, prk, okm in R.HKDF_A:
        assert hmac256(H(salt) or bytes(32), H(ikm)).hex() == prk
        assert hkdf(H(ikm), H(info), length, H(salt)).hex() == okm
        vs.append({"name": name, "source": name, "ikm": ikm, "salt": salt, "info": info,
                   "length": length, "prk": prk, "okm": okm})
    return {"description": "HKDF-SHA256 (extract + expand). salt rỗng ≡ 32 byte 0 (RFC 5869 §2.2).",
            "source": "RFC 5869 §A.1–A.3", "vectors": vs}


def build() -> dict:
    return {"xchacha20-poly1305.json": xchacha_file(), "hchacha20.json": hchacha_file(),
            "chacha20-poly1305.json": chacha_file(), "x25519.json": x25519_file(), "hkdf-sha256.json": hkdf_file()}
