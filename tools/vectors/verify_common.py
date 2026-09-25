"""Hàm dùng chung cho verify_vectors.py — cài ĐỘC LẬP với phía sinh.

- HKDF/HMAC/SHA-256: thư viện chuẩn hashlib + hmac (phía sinh dùng `cryptography`).
- X25519, Ed25519, XChaCha20-Poly1305: libsodium qua pynacl (phía sinh dùng `cryptography` cho X25519/Ed25519).
- XChaCha20-Poly1305 còn được kiểm theo đường Apple: HChaCha20 thuần Python + ChaCha20-Poly1305 của `cryptography`.
"""
import base64
import hashlib
import hmac

from cryptography.exceptions import InvalidTag
from cryptography.hazmat.primitives.ciphers.aead import ChaCha20Poly1305
from nacl.bindings import crypto_aead_xchacha20poly1305_ietf_decrypt, crypto_scalarmult
from nacl.exceptions import CryptoError
from nacl.signing import SigningKey

from hchacha20_reference import xchacha_to_chacha

H = bytes.fromhex


class Checker:
    """Đếm số phép kiểm và gom lỗi để in cuối cùng."""

    def __init__(self):
        self.count, self.failures = 0, []

    def eq(self, where: str, got, want) -> None:
        self.count += 1
        if got != want:
            self.failures.append(f"{where}: được {got!r}, cần {want!r}")

    def true(self, where: str, cond: bool) -> None:
        self.eq(where, bool(cond), True)


def sha256(b: bytes) -> bytes:
    return hashlib.sha256(b).digest()


def hmac256(key: bytes, msg: bytes) -> bytes:
    return hmac.new(key, msg, hashlib.sha256).digest()


def hkdf_extract(salt: bytes, ikm: bytes) -> bytes:
    return hmac256(salt or bytes(32), ikm)


def hkdf(ikm: bytes, info: bytes, length: int, salt: bytes = b"") -> bytes:
    prk, okm, t, i = hkdf_extract(salt, ikm), b"", b"", 1
    while len(okm) < length:
        t = hmac256(prk, t + info + bytes([i]))
        okm, i = okm + t, i + 1
    return okm[:length]


def x25519(scalar: bytes, u: bytes) -> bytes:
    return crypto_scalarmult(scalar, u)


def x25519_base(scalar: bytes) -> bytes:
    return crypto_scalarmult(scalar, b"\x09" + bytes(31))


def ed25519_pub(seed: bytes) -> bytes:
    return bytes(SigningKey(seed).verify_key)


def b64u(b: bytes) -> str:
    return base64.urlsafe_b64encode(b).rstrip(b"=").decode()


def b64u_decode(s: str) -> bytes:
    assert "=" not in s and "+" not in s and "/" not in s, "b64u phải không padding, bảng chữ URL"
    return base64.urlsafe_b64decode(s + "=" * (-len(s) % 4))


def b64_decode_strict(s: str) -> bytes:
    """b64 chuẩn có padding (RFC 4648 §4) — từ chối bảng chữ URL và thiếu padding."""
    return base64.b64decode(s, validate=True)


def uuid16(u: str) -> bytes:
    assert len(u) == 36 and u == u.lower(), "uuid phải 36 ký tự thường"
    return H(u.replace("-", ""))


def uuid_str(b: bytes) -> str:
    h = b.hex()
    return f"{h[:8]}-{h[8:12]}-{h[12:16]}-{h[16:20]}-{h[20:]}"


def xchacha_open_both(key: bytes, nonce: bytes, aad: bytes, ct: bytes, tag: bytes):
    """Mở bằng libsodium VÀ bằng HChaCha20 + ChaCha20-Poly1305. Trả (pt_sodium, pt_apple); None nếu bị từ chối."""
    try:
        a = crypto_aead_xchacha20poly1305_ietf_decrypt(ct + tag, aad, nonce, key)
    except CryptoError:
        a = None
    subkey, n12 = xchacha_to_chacha(key, nonce)
    try:
        b = ChaCha20Poly1305(subkey).decrypt(n12, ct + tag, aad)
    except InvalidTag:
        b = None
    return a, b


def xchacha_seal_apple(key: bytes, nonce: bytes, pt: bytes, aad: bytes) -> bytes:
    subkey, n12 = xchacha_to_chacha(key, nonce)
    return ChaCha20Poly1305(subkey).encrypt(n12, pt, aad)
