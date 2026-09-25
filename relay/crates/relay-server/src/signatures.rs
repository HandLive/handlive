//! Signed messages a device presents to the relay, and their verification.
//!
//! - Registration (CONN-03 API 1): `"HLREG1"` ‖ device_id(16) ‖ ik_sig_pub(32)
//!   ‖ UTF-8(platform) ‖ ts(int64 BE).
//! - Token (spec 0.6.4, CONN-03 API 3): `"HLAUTH1"` ‖ challenge(32 raw bytes)
//!   ‖ device_id(16).

use ed25519_dalek::{Signature, VerifyingKey};
use uuid::Uuid;

use crate::device_identity::matches_public_key;
use crate::error::ApiError;

pub const REGISTER_LABEL: &[u8] = b"HLREG1";
pub const AUTH_LABEL: &[u8] = b"HLAUTH1";

pub fn registration_message(
    device_id: &Uuid,
    ik_sig_pub: &[u8; 32],
    platform: &str,
    ts_ms: i64,
) -> Vec<u8> {
    let mut msg = Vec::with_capacity(REGISTER_LABEL.len() + 16 + 32 + platform.len() + 8);
    msg.extend_from_slice(REGISTER_LABEL);
    msg.extend_from_slice(device_id.as_bytes());
    msg.extend_from_slice(ik_sig_pub);
    msg.extend_from_slice(platform.as_bytes());
    msg.extend_from_slice(&ts_ms.to_be_bytes());
    msg
}

pub fn auth_message(challenge: &[u8; 32], device_id: &Uuid) -> Vec<u8> {
    let mut msg = Vec::with_capacity(AUTH_LABEL.len() + 32 + 16);
    msg.extend_from_slice(AUTH_LABEL);
    msg.extend_from_slice(challenge);
    msg.extend_from_slice(device_id.as_bytes());
    msg
}

/// Verify an Ed25519 signature made by the device that owns `device_id`.
///
/// Fails with `SIGNATURE_INVALID` when the key is not a valid point, the
/// `device_id` is not derived from the key (C4), or the signature does not
/// verify under strict rules (rejects malleable / small-order forms).
pub fn verify_device_signature(
    device_id: &Uuid,
    ik_sig_pub: &[u8; 32],
    message: &[u8],
    sig: &[u8; 64],
) -> Result<(), ApiError> {
    if !matches_public_key(device_id, ik_sig_pub) {
        return Err(ApiError::SignatureInvalid);
    }
    let key = VerifyingKey::from_bytes(ik_sig_pub).map_err(|_| ApiError::SignatureInvalid)?;
    let signature = Signature::from_bytes(sig);
    key.verify_strict(message, &signature)
        .map_err(|_| ApiError::SignatureInvalid)
}
