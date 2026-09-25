//! `POST /v1/devices` — register or refresh a device (CONN-03 API 1).
//! No JWT: the body is self-authenticated by an `HLREG1` signature.

use actix_web::{HttpResponse, web};
use serde::Deserialize;
use serde_json::json;
use uuid::Uuid;

use crate::b64u;
use crate::clock::now_ms;
use crate::error::ApiError;
use crate::signatures::{registration_message, verify_device_signature};
use crate::state::AppState;
use crate::store::devices::{self, NewDevice, UpsertOutcome};

/// Maximum clock skew between the device `ts` and the relay (5 minutes).
pub const MAX_TS_SKEW_MS: i64 = 5 * 60 * 1000;
pub const PLATFORMS: [&str; 4] = ["android", "macos", "ios", "ipados"];
/// `app_version` is `string(32)`: at most 32 code points.
pub const APP_VERSION_MAX_CHARS: usize = 32;

#[derive(Debug, Deserialize)]
pub struct RegisterRequest {
    pub device_id: Uuid,
    pub platform: String,
    pub app_version: String,
    pub ik_sig_pub: String,
    pub ts: i64,
    pub sig: String,
}

/// Validate shape, timestamp and signature of a registration.
/// Returns the decoded public key on success.
pub fn verify_registration(req: &RegisterRequest, now_ms: i64) -> Result<[u8; 32], ApiError> {
    let chars = req.app_version.chars().count();
    if !PLATFORMS.contains(&req.platform.as_str()) || chars == 0 || chars > APP_VERSION_MAX_CHARS {
        return Err(ApiError::BadRequest);
    }
    let ik_sig_pub: [u8; 32] = b64u::decode_field(&req.ik_sig_pub)?;
    let sig: [u8; 64] = b64u::decode_field(&req.sig)?;
    if (now_ms - req.ts).abs() > MAX_TS_SKEW_MS {
        return Err(ApiError::SignatureInvalid);
    }
    let msg = registration_message(&req.device_id, &ik_sig_pub, &req.platform, req.ts);
    verify_device_signature(&req.device_id, &ik_sig_pub, &msg, &sig)?;
    Ok(ik_sig_pub)
}

pub async fn register(
    state: web::Data<AppState>,
    body: web::Json<RegisterRequest>,
) -> Result<HttpResponse, ApiError> {
    let req = body.into_inner();
    let ik_sig_pub = verify_registration(&req, now_ms())?;
    let new = NewDevice {
        device_id: req.device_id,
        ik_sig_pub: &ik_sig_pub,
        platform: &req.platform,
        app_version: &req.app_version,
    };
    let outcome = devices::upsert(&state.db, &new)
        .await
        .map_err(|e| ApiError::internal("devices upsert", e))?;
    let (mut response, created_at_ms) = match outcome {
        UpsertOutcome::Created { created_at_ms } => (HttpResponse::Created(), created_at_ms),
        UpsertOutcome::Updated { created_at_ms } => (HttpResponse::Ok(), created_at_ms),
        UpsertOutcome::Rejected => return Err(rejection_reason(&state, req.device_id).await),
    };
    Ok(response.json(json!({
        "device_id": req.device_id.hyphenated().to_string(),
        "created_at": created_at_ms,
    })))
}

/// The upsert changed nothing: the row is revoked (410). A different key for
/// the same `device_id` cannot pass `verify_registration`, so that case only
/// signals a key mismatch (401).
async fn rejection_reason(state: &AppState, device_id: Uuid) -> ApiError {
    match devices::find_key(&state.db, device_id).await {
        Ok(Some(key)) if key.revoked => ApiError::DeviceRevoked,
        Ok(_) => ApiError::SignatureInvalid,
        Err(e) => ApiError::internal("devices lookup", e),
    }
}
