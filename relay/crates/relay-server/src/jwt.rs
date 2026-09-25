//! Device access tokens: JWT HS256, claims `sub`, `iat`, `exp`, `jti`,
//! lifetime 900 s (spec 0.6.4, CONN-03 API 3, `JWT_TTL` in 0.10).

use jsonwebtoken::errors::ErrorKind;
use jsonwebtoken::{Algorithm, DecodingKey, EncodingKey, Header, Validation, decode, encode};
use serde::{Deserialize, Serialize};
use uuid::Uuid;

use crate::error::ApiError;

/// `JWT_TTL` = 15 minutes.
pub const JWT_TTL_SECS: i64 = 900;
/// Minimum HS256 secret length accepted from configuration.
pub const MIN_SECRET_BYTES: usize = 32;

#[derive(Debug, Clone, Serialize, Deserialize, PartialEq, Eq)]
pub struct Claims {
    pub sub: String,
    pub iat: i64,
    pub exp: i64,
    pub jti: String,
}

#[derive(Clone)]
pub struct JwtKeys {
    encoding: EncodingKey,
    decoding: DecodingKey,
    validation: Validation,
}

impl JwtKeys {
    /// Build keys from the configured secret; rejects secrets under 32 bytes.
    pub fn from_secret(secret: &[u8]) -> Result<Self, String> {
        if secret.len() < MIN_SECRET_BYTES {
            return Err(format!(
                "JWT secret must be at least {MIN_SECRET_BYTES} bytes"
            ));
        }
        let mut validation = Validation::new(Algorithm::HS256);
        validation.leeway = 0;
        validation.validate_exp = true;
        validation.set_required_spec_claims(&["exp", "sub"]);
        Ok(Self {
            encoding: EncodingKey::from_secret(secret),
            decoding: DecodingKey::from_secret(secret),
            validation,
        })
    }

    /// Issue a token for `device_id` at `now_secs`. Returns (token, expires_in).
    pub fn issue(&self, device_id: &Uuid, now_secs: i64) -> Result<(String, i64), ApiError> {
        let claims = Claims {
            sub: device_id.hyphenated().to_string(),
            iat: now_secs,
            exp: now_secs + JWT_TTL_SECS,
            jti: Uuid::new_v4().hyphenated().to_string(),
        };
        let token = encode(&Header::new(Algorithm::HS256), &claims, &self.encoding)
            .map_err(|e| ApiError::internal("jwt encode", e))?;
        Ok((token, JWT_TTL_SECS))
    }

    /// Verify a token and return the device it was issued to.
    ///
    /// Expired → `TOKEN_EXPIRED`; any other defect (bad signature, wrong
    /// algorithm, malformed, `sub` not a uuid) → `SIGNATURE_INVALID`.
    pub fn verify(&self, token: &str) -> Result<Uuid, ApiError> {
        let data =
            decode::<Claims>(token, &self.decoding, &self.validation).map_err(|e| {
                match e.kind() {
                    ErrorKind::ExpiredSignature => ApiError::TokenExpired,
                    _ => ApiError::SignatureInvalid,
                }
            })?;
        Uuid::parse_str(&data.claims.sub).map_err(|_| ApiError::SignatureInvalid)
    }
}
