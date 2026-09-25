//! Self-certifying `device_id` (spec 0.2, README C4).
//!
//! `device_id` = UUIDv8 built from the first 16 bytes of SHA-256(`ik_sig_pub`)
//! with the version nibble set to 8 and the variant bits set to `10`.

use ring::digest::{SHA256, digest};
use uuid::Uuid;

/// Derive the `device_id` for an Ed25519 public key.
pub fn device_id_from_public_key(ik_sig_pub: &[u8; 32]) -> Uuid {
    let hash = digest(&SHA256, ik_sig_pub);
    let mut bytes = [0u8; 16];
    bytes.copy_from_slice(&hash.as_ref()[..16]);
    bytes[6] = (bytes[6] & 0x0f) | 0x80;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;
    Uuid::from_bytes(bytes)
}

/// True when `device_id` is exactly the one derived from `ik_sig_pub`.
pub fn matches_public_key(device_id: &Uuid, ik_sig_pub: &[u8; 32]) -> bool {
    device_id_from_public_key(ik_sig_pub) == *device_id
}
