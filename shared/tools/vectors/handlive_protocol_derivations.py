"""Phép dẫn xuất giao thức HandLive dùng để SINH vector (00-common-specs 0.2, 0.5, 0.6).

Phía sinh dùng `cryptography` (HKDF, HMAC, X25519, Ed25519) và pynacl (XChaCha20-Poly1305).
Phía kiểm (verify_vectors.py) cài lại bằng hashlib/hmac + pynacl + HChaCha20 tự viết,
để hai đường không dùng chung mã.

Diễn giải định dạng đã chọn (ghi trong shared/test-vectors/README.md):
- uuid, eph, nonce trong chuỗi MAC (T1, T2, HLSTREAM1) ghép ở dạng BYTE thô: uuid 16 byte,
  eph 32 byte, nonce 32 byte — giống `T_offer` ở 02-pairing.
- HKDF không ghi salt → salt rỗng; `K_auth` L = 32.
"""
import base64
import hashlib
import hmac
import json
import struct
import uuid

from cryptography.hazmat.primitives import hashes
from cryptography.hazmat.primitives.asymmetric import ed25519, x25519
from cryptography.hazmat.primitives.kdf.hkdf import HKDF
from cryptography.hazmat.primitives.serialization import Encoding, PublicFormat
from nacl.bindings import crypto_aead_xchacha20poly1305_ietf_encrypt

RAW = (Encoding.Raw, PublicFormat.Raw)


def test_bytes(label: str, n: int) -> bytes:
    """Byte kiểm thử cố định, công khai: SHA-256("HL-TEST|" + label) nối tiếp cho đủ n byte."""
    out, i = b"", 0
    while len(out) < n:
        out += hashlib.sha256(f"HL-TEST|{label}|{i}".encode()).digest()
        i += 1
    return out[:n]


def b64(b: bytes) -> str:
    return base64.b64encode(b).decode()


def b64u(b: bytes) -> str:
    return base64.urlsafe_b64encode(b).rstrip(b"=").decode()


def uuid_bytes(u: str) -> bytes:
    return uuid.UUID(u).bytes


def compact_json(obj) -> str:
    """JSON gọn, giữ nguyên thứ tự khóa, UTF-8 (không escape \\u)."""
    return json.dumps(obj, separators=(",", ":"), ensure_ascii=False)


def hkdf(ikm: bytes, info: bytes, length: int, salt: bytes = b"") -> bytes:
    return HKDF(algorithm=hashes.SHA256(), length=length, salt=salt or None, info=info).derive(ikm)


def hmac256(key: bytes, msg: bytes) -> bytes:
    return hmac.new(key, msg, hashlib.sha256).digest()


def x25519_pub(priv: bytes) -> bytes:
    return x25519.X25519PrivateKey.from_private_bytes(priv).public_key().public_bytes(*RAW)


def x25519_dh(priv: bytes, pub: bytes) -> bytes:
    return x25519.X25519PrivateKey.from_private_bytes(priv).exchange(x25519.X25519PublicKey.from_public_bytes(pub))


def ed25519_pub(seed: bytes) -> bytes:
    return ed25519.Ed25519PrivateKey.from_private_bytes(seed).public_key().public_bytes(*RAW)


def device_id_from_pub(ik_sig_pub: bytes) -> str:
    """0.2: UUIDv8 = 16 byte đầu SHA-256(ik_sig_pub), version = 8, variant = 10."""
    b = bytearray(hashlib.sha256(ik_sig_pub).digest()[:16])
    b[6] = (b[6] & 0x0F) | 0x80
    b[8] = (b[8] & 0x3F) | 0x80
    return str(uuid.UUID(bytes=bytes(b)))


def pair_salt_input(dev_a: str, dev_b: str) -> bytes:
    """0.6.2: device_id nhỏ hơn ‖ lớn hơn, dạng 16 byte, so sánh byte không dấu."""
    x, y = sorted([uuid_bytes(dev_a), uuid_bytes(dev_b)])
    return x + y


def xchacha_seal(key: bytes, nonce: bytes, plaintext: bytes, aad: bytes) -> tuple[bytes, bytes]:
    out = crypto_aead_xchacha20poly1305_ietf_encrypt(plaintext, aad, nonce, key)
    return out[:-16], out[-16:]


def envelope_aad(v: int, typ: str, env_id: str, ts: int) -> str:
    return f"{v}|{typ}|{env_id}|{ts}"


def envelope_wire(v: int, typ: str, env_id: str, ts: int, payload_b64: str) -> str:
    return compact_json({"v": v, "type": typ, "id": env_id, "ts": ts, "payload": payload_b64})


def chunk_plaintext(transfer_id: str, index: int, data: bytes) -> tuple[str, bytes]:
    """0.5.1: hdr_len (uint16 BE) ‖ JSON header ‖ bytes của khối."""
    hdr = compact_json({"op": "chunk", "data": {"transfer_id": transfer_id, "index": index}})
    raw = hdr.encode()
    return hdr, struct.pack(">H", len(raw)) + raw + data


def hl_header(seq: int, ts: int, ver: int = 1) -> bytes:
    """0.5.2: magic 'HL' ‖ ver(1) ‖ seq uint32 BE ‖ ts uint32 BE — 11 byte, cũng là AAD."""
    return b"HL" + bytes([ver]) + struct.pack(">II", seq, ts)


def camera_plaintext(track: int, flags: int, pts_us: int, data: bytes) -> bytes:
    return bytes([track, flags]) + struct.pack(">q", pts_us) + data
