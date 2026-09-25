"""Kiểm vector nguyên thủy bằng thư viện độc lập: xchacha20-poly1305, hchacha20, chacha20-poly1305, x25519, hkdf-sha256."""
from cryptography.exceptions import InvalidTag
from cryptography.hazmat.primitives.ciphers.aead import ChaCha20Poly1305
from nacl.bindings import (crypto_aead_chacha20poly1305_ietf_decrypt, crypto_aead_chacha20poly1305_ietf_encrypt,
                           crypto_aead_xchacha20poly1305_ietf_encrypt)
from nacl.exceptions import CryptoError

from hchacha20_reference import hchacha20, xchacha_to_chacha
from verify_common import H, hkdf, hkdf_extract, x25519, xchacha_open_both, xchacha_seal_apple


def check_xchacha(c, doc):
    for v in doc["vectors"]:
        n = f"xchacha20-poly1305/{v['name']}"
        key, nonce, aad, pt = H(v["key"]), H(v["nonce"]), H(v["aad"]), H(v["plaintext"])
        ct, tag = H(v["ciphertext"]), H(v["tag"])
        sodium, apple = xchacha_open_both(key, nonce, aad, ct, tag)
        c.eq(f"{n} mở bằng libsodium", sodium, pt)
        c.eq(f"{n} mở bằng HChaCha20+ChaCha20-Poly1305", apple, pt)
        c.eq(f"{n} mã hóa libsodium", crypto_aead_xchacha20poly1305_ietf_encrypt(pt, aad, nonce, key), ct + tag)
        c.eq(f"{n} mã hóa kiểu Apple", xchacha_seal_apple(key, nonce, pt, aad), ct + tag)
        subkey, n12 = xchacha_to_chacha(key, nonce)
        c.eq(f"{n} subkey", subkey.hex(), v["hchacha20_subkey"])
        c.eq(f"{n} nonce 12", n12.hex(), v["chacha20_nonce"])
    for v in doc["invalid_vectors"]:
        res = xchacha_open_both(H(v["key"]), H(v["nonce"]), H(v["aad"]), H(v["ciphertext"]), H(v["tag"]))
        c.eq(f"xchacha20-poly1305/{v['name']} phải bị từ chối (cả hai đường)", res, (None, None))


def check_hchacha(c, doc):
    for v in doc["vectors"]:
        n = f"hchacha20/{v['name']}"
        key, nonce16, subkey = H(v["key"]), H(v["nonce"]), H(v["subkey"])
        c.eq(f"{n} bản tham chiếu", hchacha20(key, nonce16), subkey)
        # Kiểm độc lập với bản tham chiếu: libsodium XChaCha(key, nonce16 ‖ 0^8) phải bằng ChaCha20-Poly1305(subkey, 0^12).
        probe = b"HandLive HChaCha20 probe"
        want = crypto_aead_xchacha20poly1305_ietf_encrypt(probe, b"", nonce16 + bytes(8), key)
        c.eq(f"{n} khớp libsodium", ChaCha20Poly1305(subkey).encrypt(bytes(12), probe, b""), want)


def _chacha_open(key, nonce, aad, data):
    try:
        a = ChaCha20Poly1305(key).decrypt(nonce, data, aad)
    except InvalidTag:
        a = None
    try:
        b = crypto_aead_chacha20poly1305_ietf_decrypt(data, aad, nonce, key)
    except CryptoError:
        b = None
    return a, b


def check_chacha(c, doc):
    for v in doc["vectors"]:
        n = f"chacha20-poly1305/{v['name']}"
        key, nonce, aad, pt = H(v["key"]), H(v["nonce"]), H(v["aad"]), H(v["plaintext"])
        want = H(v["ciphertext"]) + H(v["tag"])
        c.eq(f"{n} mã hóa (cryptography)", ChaCha20Poly1305(key).encrypt(nonce, pt, aad), want)
        c.eq(f"{n} mã hóa (libsodium)", crypto_aead_chacha20poly1305_ietf_encrypt(pt, aad, nonce, key), want)
        c.eq(f"{n} giải mã", _chacha_open(key, nonce, aad, want), (pt, pt))
    for v in doc["invalid_vectors"]:
        res = _chacha_open(H(v["key"]), H(v["nonce"]), H(v["aad"]), H(v["ciphertext"]) + H(v["tag"]))
        c.eq(f"chacha20-poly1305/{v['name']} phải bị từ chối", res, (None, None))


def check_x25519(c, doc):
    for v in doc["vectors"]:
        c.eq(f"x25519/{v['name']}", x25519(H(v["scalar"]), H(v["u"])).hex(), v["output"])


def check_hkdf(c, doc):
    for v in doc["vectors"]:
        n = f"hkdf-sha256/{v['name']}"
        c.eq(f"{n} PRK", hkdf_extract(H(v["salt"]), H(v["ikm"])).hex(), v["prk"])
        c.eq(f"{n} OKM", hkdf(H(v["ikm"]), H(v["info"]), v["length"], H(v["salt"])).hex(), v["okm"])


CHECKS = {"xchacha20-poly1305.json": check_xchacha, "hchacha20.json": check_hchacha,
          "chacha20-poly1305.json": check_chacha, "x25519.json": check_x25519, "hkdf-sha256.json": check_hkdf}
