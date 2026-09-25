//! Base64url without padding (spec 0.3 `b64u`, RFC 4648 §5).

use base64::Engine;
use base64::engine::general_purpose::URL_SAFE_NO_PAD;

use crate::error::ApiError;

pub fn encode(bytes: &[u8]) -> String {
    URL_SAFE_NO_PAD.encode(bytes)
}

/// Decode a b64u field into exactly `N` bytes.
///
/// Returns `None` when the text is not valid b64u or has the wrong length, so
/// callers can choose the error code that fits the field.
pub fn decode_fixed<const N: usize>(text: &str) -> Option<[u8; N]> {
    let bytes = URL_SAFE_NO_PAD.decode(text).ok()?;
    bytes.try_into().ok()
}

/// Decode a b64u field of fixed length, treating any failure as `BAD_REQUEST`.
pub fn decode_field<const N: usize>(text: &str) -> Result<[u8; N], ApiError> {
    decode_fixed(text).ok_or(ApiError::BadRequest)
}
