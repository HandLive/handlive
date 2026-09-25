//! JWT extractor for endpoints that require `Authorization: Bearer <jwt>`.
//!
//! Spec 0.6.4 step 4: besides a valid, unexpired token, `sub` must still have
//! a row in `devices`; otherwise 404 `DEVICE_NOT_FOUND` even if the JWT is
//! still valid (device removed itself, SET-02).

use std::future::Future;
use std::pin::Pin;

use actix_web::dev::Payload;
use actix_web::http::header::{AUTHORIZATION, HeaderValue};
use actix_web::{FromRequest, HttpRequest, web};
use uuid::Uuid;

use crate::error::ApiError;
use crate::routes::auth::usable_key;
use crate::state::AppState;
use crate::store::devices;

/// A device authenticated by JWT and still registered on the relay.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub struct AuthenticatedDevice {
    pub device_id: Uuid,
}

/// Extract the token from an `Authorization: Bearer <token>` header.
/// A missing or malformed header counts as bad credentials (401).
pub fn bearer_token(header: Option<&HeaderValue>) -> Result<&str, ApiError> {
    let value = header
        .and_then(|h| h.to_str().ok())
        .ok_or(ApiError::SignatureInvalid)?;
    let (scheme, token) = value.split_once(' ').ok_or(ApiError::SignatureInvalid)?;
    if !scheme.eq_ignore_ascii_case("bearer") || token.trim().is_empty() {
        return Err(ApiError::SignatureInvalid);
    }
    Ok(token.trim())
}

impl FromRequest for AuthenticatedDevice {
    type Error = ApiError;
    type Future = Pin<Box<dyn Future<Output = Result<Self, Self::Error>>>>;

    fn from_request(req: &HttpRequest, _payload: &mut Payload) -> Self::Future {
        let state = req.app_data::<web::Data<AppState>>().cloned();
        let device_id = bearer_token(req.headers().get(AUTHORIZATION)).and_then(|token| {
            let state = state.as_ref().ok_or(ApiError::Internal)?;
            state.jwt.verify(token)
        });
        Box::pin(async move {
            let device_id = device_id?;
            let state = state.ok_or(ApiError::Internal)?;
            let found = devices::find_key(&state.db, device_id)
                .await
                .map_err(|e| ApiError::internal("devices lookup", e))?;
            usable_key(found)?;
            Ok(Self { device_id })
        })
    }
}
