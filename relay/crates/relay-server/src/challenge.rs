//! Auth challenge rules (spec 0.6.4 step 1, CONN-03 API 2–3).
//!
//! Storage lives in Redis (`chal:<device_id>`, TTL 60 s, read with GETDEL);
//! this module holds the pure rules so they are testable without Redis.

use ring::rand::{SecureRandom, SystemRandom};
use subtle::ConstantTimeEq;

use crate::b64u;
use crate::error::ApiError;

/// `CHALLENGE_TTL` (spec 0.10).
pub const CHALLENGE_TTL_SECS: u64 = 60;
/// Challenge requests allowed per device per minute (CONN-03 API 2).
pub const CHALLENGE_RATE_PER_MINUTE: u64 = 10;

/// Fresh 32-byte random challenge.
pub fn generate(rng: &SystemRandom) -> Result<[u8; 32], ApiError> {
    let mut challenge = [0u8; 32];
    rng.fill(&mut challenge)
        .map_err(|_| ApiError::internal("challenge rng", "SystemRandom failed"))?;
    Ok(challenge)
}

/// Check the challenge a device presents against the one taken from storage.
///
/// `stored` is what GETDEL returned: `None` means it expired, was already used
/// or never existed. Any mismatch is also `CHALLENGE_EXPIRED` — the stored
/// value is consumed either way, so the device must request a new one.
pub fn accept_presented(stored: Option<&str>, presented_b64u: &str) -> Result<[u8; 32], ApiError> {
    let stored = stored.ok_or(ApiError::ChallengeExpired)?;
    let stored: [u8; 32] = b64u::decode_fixed(stored).ok_or(ApiError::ChallengeExpired)?;
    let presented: [u8; 32] =
        b64u::decode_fixed(presented_b64u).ok_or(ApiError::ChallengeExpired)?;
    if bool::from(stored.ct_eq(&presented)) {
        Ok(stored)
    } else {
        Err(ApiError::ChallengeExpired)
    }
}

/// Fixed-window rate limit decision for `rl:<device_id>:<group>:<minute>`.
///
/// `count` is the counter value after INCR. Returns the `Retry-After`
/// seconds (until the window ends) when over the limit.
pub fn rate_limit_decision(count: u64, limit: u64, now_ms: i64) -> Result<(), ApiError> {
    if count <= limit {
        return Ok(());
    }
    let into_minute_ms = now_ms.rem_euclid(60_000) as u64;
    let retry_after_secs = (60_000 - into_minute_ms).div_ceil(1000).max(1);
    Err(ApiError::RateLimited { retry_after_secs })
}

/// Current fixed window index (Unix minute) for rate-limit keys.
pub fn minute_window(now_ms: i64) -> i64 {
    now_ms.div_euclid(60_000)
}
