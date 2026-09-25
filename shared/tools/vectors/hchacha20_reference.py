"""HChaCha20 thuần Python (draft-irtf-cfrg-xchacha-03 §2.2) — bản tham chiếu, giống cách Apple tự cài.

Đúng/sai của bản này được kiểm bằng vector §2.2.1 và bằng việc ghép
HChaCha20 + ChaCha20-Poly1305 (cryptography) phải ra đúng byte của libsodium XChaCha20-Poly1305.
"""
import struct

_MASK = 0xFFFFFFFF


def _rotl(v: int, c: int) -> int:
    return ((v << c) & _MASK) | (v >> (32 - c))


def _quarter(s: list[int], a: int, b: int, c: int, d: int) -> None:
    s[a] = (s[a] + s[b]) & _MASK; s[d] = _rotl(s[d] ^ s[a], 16)
    s[c] = (s[c] + s[d]) & _MASK; s[b] = _rotl(s[b] ^ s[c], 12)
    s[a] = (s[a] + s[b]) & _MASK; s[d] = _rotl(s[d] ^ s[a], 8)
    s[c] = (s[c] + s[d]) & _MASK; s[b] = _rotl(s[b] ^ s[c], 7)


def hchacha20(key: bytes, nonce16: bytes) -> bytes:
    """Trả subkey 32 byte = hàng đầu (0..3) ‖ hàng cuối (12..15) sau 20 vòng, little endian."""
    assert len(key) == 32 and len(nonce16) == 16
    s = [0x61707865, 0x3320646E, 0x79622D32, 0x6B206574]
    s += list(struct.unpack("<8I", key)) + list(struct.unpack("<4I", nonce16))
    for _ in range(10):
        _quarter(s, 0, 4, 8, 12); _quarter(s, 1, 5, 9, 13); _quarter(s, 2, 6, 10, 14); _quarter(s, 3, 7, 11, 15)
        _quarter(s, 0, 5, 10, 15); _quarter(s, 1, 6, 11, 12); _quarter(s, 2, 7, 8, 13); _quarter(s, 3, 4, 9, 14)
    return struct.pack("<8I", *(s[0:4] + s[12:16]))


def xchacha_to_chacha(key: bytes, nonce24: bytes) -> tuple[bytes, bytes]:
    """Đổi (key, nonce 24) → (subkey, nonce 12 = 0x00000000 ‖ nonce24[16:24]) cho ChaCha20-Poly1305."""
    return hchacha20(key, nonce24[:16]), b"\x00\x00\x00\x00" + nonce24[16:]
