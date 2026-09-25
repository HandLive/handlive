//! `POST /v1/auth/challenge` and `POST /v1/auth/token`
//! (spec 0.6.4, CONN-03 API 2–3).

use actix_web::{HttpResponse, web};
use serde::Deserialize;
use serde_json::json;
use uuid::Uuid;

use crate::b64u;
use crate::challenge::{self, CHALLENGE_RATE_PER_MINUTE, CHALLENGE_TTL_SECS};
use crate::clock::now_ms;
use crate::error::ApiError;
use crate::signatures::{auth_message, verify_device_signature};
use crate::state::AppState;
use crate::store::challenges;
use crate::store::devices::{self, DeviceKey};

#[derive(Debug, Deserialize)]
pub struct ChallengeRequest {
    pub device_id: Uuid,
}

#[derive(Debug, Deserialize)]
pub struct TokenRequest {
    pub device_id: Uuid,
    pub challenge: String,
    pub sig: String,
}

/// Map a `devices` lookup to the device public key or the spec error.
pub fn usable_key(found: Option<DeviceKey>) -> Result<[u8; 32], ApiError> {
    let key = found.ok_or(ApiError::DeviceNotFound)?;
    if key.revoked {
        return Err(ApiError::DeviceRevoked);
    }
    key.ik_sig_pub
        .try_into()
        .map_err(|_| ApiError::internal("devices row", "ik_sig_pub not 32 bytes"))
}

/// Token proof check, in spec order: consumed challenge must match, then the
/// device must be registered, then the `HLAUTH1` signature must verify.
pub fn check_token_proof(
    stored_challenge: Option<&str>,
    req: &TokenRequest,
    sig: &[u8; 64],
    found: Option<DeviceKey>,
) -> Result<(), ApiError> {
    let challenge = challenge::accept_presented(stored_challenge, &req.challenge)?;
    let ik_sig_pub = usable_key(found)?;
    let msg = auth_message(&challenge, &req.device_id);
    verify_device_signature(&req.device_id, &ik_sig_pub, &msg, sig)
}

pub async fn challenge(
    state: web::Data<AppState>,
    body: web::Json<ChallengeRequest>,
) -> Result<HttpResponse, ApiError> {
    let device_id = body.device_id;
    let found = devices::find_key(&state.db, device_id)
        .await
        .map_err(|e| ApiError::internal("devices lookup", e))?;
    usable_key(found)?;

    let now = now_ms();
    let mut redis = state.redis.clone();
    let key = challenges::rate_limit_key(&device_id, "chal", challenge::minute_window(now));
    let count = challenges::incr_window(&mut redis, &key)
        .await
        .map_err(|e| ApiError::internal("rate limit", e))?;
    challenge::rate_limit_decision(count, CHALLENGE_RATE_PER_MINUTE, now)?;

    let value = b64u::encode(&challenge::generate(&state.rng)?);
    challenges::put(&mut redis, &device_id, &value)
        .await
        .map_err(|e| ApiError::internal("challenge store", e))?;
    Ok(HttpResponse::Ok().json(json!({
        "challenge": value,
        "expires_at": now + (CHALLENGE_TTL_SECS as i64) * 1000,
    })))
}

pub async fn token(
    state: web::Data<AppState>,
    body: web::Json<TokenRequest>,
) -> Result<HttpResponse, ApiError> {
    let req = body.into_inner();
    let sig: [u8; 64] = b64u::decode_field(&req.sig)?;
    let mut redis = state.redis.clone();
    let stored = challenges::take(&mut redis, &req.device_id)
        .await
        .map_err(|e| ApiError::internal("challenge take", e))?;
    // Missing challenge short-circuits before touching the database.
    if stored.is_none() {
        return Err(ApiError::ChallengeExpired);
    }
    let found = devices::find_key(&state.db, req.device_id)
        .await
        .map_err(|e| ApiError::internal("devices lookup", e))?;
    check_token_proof(stored.as_deref(), &req, &sig, found)?;

    devices::touch_last_seen(&state.db, req.device_id)
        .await
        .map_err(|e| ApiError::internal("devices touch", e))?;
    let (access_token, expires_in) = state.jwt.issue(&req.device_id, now_ms() / 1000)?;
    Ok(HttpResponse::Ok().json(json!({
        "access_token": access_token,
        "expires_in": expires_in,
    })))
}
