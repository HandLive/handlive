//! Relay HTTP errors (spec 0.8.2) rendered as
//! `{"error":{"code":"<CODE>","message":"<text>"}}` (spec 0.4.3).
//!
//! Only the error code and a fixed message are ever logged or returned;
//! request bodies are never echoed (zero-knowledge relay, spec 0.6.5).

use actix_web::http::StatusCode;
use actix_web::http::header::RETRY_AFTER;
use actix_web::{HttpResponse, ResponseError};
use serde_json::json;
use std::fmt;

#[derive(Debug, Clone, PartialEq, Eq)]
pub enum ApiError {
    /// 400 — malformed body or field.
    BadRequest,
    /// 401 — challenge expired, already used, or never issued.
    ChallengeExpired,
    /// 401 — bad signature, `device_id` not derived from the key, skewed `ts`,
    /// or an unusable JWT.
    SignatureInvalid,
    /// 401 — JWT past its `exp`.
    TokenExpired,
    /// 404 — device not registered (or removed itself from the relay).
    DeviceNotFound,
    /// 410 — device row exists but is revoked.
    DeviceRevoked,
    /// 413 — body over the configured limit.
    PayloadTooLarge,
    /// 429 — rate limit hit; value is the `Retry-After` in seconds.
    RateLimited { retry_after_secs: u64 },
    /// 500 — unexpected failure (database, Redis). Code from spec 0.8.1.
    Internal,
}

impl ApiError {
    pub fn code(&self) -> &'static str {
        match self {
            Self::BadRequest => "BAD_REQUEST",
            Self::ChallengeExpired => "CHALLENGE_EXPIRED",
            Self::SignatureInvalid => "SIGNATURE_INVALID",
            Self::TokenExpired => "TOKEN_EXPIRED",
            Self::DeviceNotFound => "DEVICE_NOT_FOUND",
            Self::DeviceRevoked => "DEVICE_REVOKED",
            Self::PayloadTooLarge => "PAYLOAD_TOO_LARGE",
            Self::RateLimited { .. } => "RATE_LIMITED",
            Self::Internal => "INTERNAL",
        }
    }

    fn message(&self) -> &'static str {
        match self {
            Self::BadRequest => "Malformed request body",
            Self::ChallengeExpired => "Challenge expired or already used",
            Self::SignatureInvalid => "Invalid signature or credentials",
            Self::TokenExpired => "Access token expired",
            Self::DeviceNotFound => "Device not registered",
            Self::DeviceRevoked => "Device has been removed",
            Self::PayloadTooLarge => "Request body too large",
            Self::RateLimited { .. } => "Too many requests",
            Self::Internal => "Internal error",
        }
    }

    /// Map an infrastructure failure to `INTERNAL`, logging only its category.
    pub fn internal(context: &'static str, err: impl fmt::Display) -> Self {
        log::error!("internal error in {context}: {err}");
        Self::Internal
    }
}

impl fmt::Display for ApiError {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        f.write_str(self.code())
    }
}

impl ResponseError for ApiError {
    fn status_code(&self) -> StatusCode {
        match self {
            Self::BadRequest => StatusCode::BAD_REQUEST,
            Self::ChallengeExpired | Self::SignatureInvalid | Self::TokenExpired => {
                StatusCode::UNAUTHORIZED
            }
            Self::DeviceNotFound => StatusCode::NOT_FOUND,
            Self::DeviceRevoked => StatusCode::GONE,
            Self::PayloadTooLarge => StatusCode::PAYLOAD_TOO_LARGE,
            Self::RateLimited { .. } => StatusCode::TOO_MANY_REQUESTS,
            Self::Internal => StatusCode::INTERNAL_SERVER_ERROR,
        }
    }

    fn error_response(&self) -> HttpResponse {
        let mut builder = HttpResponse::build(self.status_code());
        if let Self::RateLimited { retry_after_secs } = self {
            builder.insert_header((RETRY_AFTER, retry_after_secs.to_string()));
        }
        builder.json(json!({ "error": { "code": self.code(), "message": self.message() } }))
    }
}

/// JSON extractor errors: oversize → 413, anything else → 400.
pub fn json_error_handler(
    err: actix_web::error::JsonPayloadError,
    _req: &actix_web::HttpRequest,
) -> actix_web::Error {
    use actix_web::error::JsonPayloadError;
    match err {
        JsonPayloadError::Overflow { .. } | JsonPayloadError::OverflowKnownLength { .. } => {
            ApiError::PayloadTooLarge.into()
        }
        _ => ApiError::BadRequest.into(),
    }
}
