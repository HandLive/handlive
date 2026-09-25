//! Redis keys for auth (spec 0.9.4): `chal:<device_id>` (TTL 60 s) and
//! `rl:<device_id>:<group>:<minute>` (TTL 120 s).

use redis::AsyncCommands;
use redis::aio::ConnectionManager;
use uuid::Uuid;

use crate::challenge::CHALLENGE_TTL_SECS;

const RATE_LIMIT_TTL_SECS: i64 = 120;

pub fn challenge_key(device_id: &Uuid) -> String {
    format!("chal:{}", device_id.hyphenated())
}

pub fn rate_limit_key(device_id: &Uuid, group: &str, minute: i64) -> String {
    format!("rl:{}:{group}:{minute}", device_id.hyphenated())
}

/// Store (overwriting any previous) challenge as b64u text with TTL 60 s.
pub async fn put(
    conn: &mut ConnectionManager,
    device_id: &Uuid,
    challenge_b64u: &str,
) -> redis::RedisResult<()> {
    conn.set_ex(challenge_key(device_id), challenge_b64u, CHALLENGE_TTL_SECS)
        .await
}

/// Atomically read and delete the pending challenge (GETDEL).
pub async fn take(
    conn: &mut ConnectionManager,
    device_id: &Uuid,
) -> redis::RedisResult<Option<String>> {
    conn.get_del(challenge_key(device_id)).await
}

/// Increment a fixed-window counter and return its new value.
pub async fn incr_window(conn: &mut ConnectionManager, key: &str) -> redis::RedisResult<u64> {
    let (count, _): (u64, bool) = redis::pipe()
        .atomic()
        .incr(key, 1)
        .expire(key, RATE_LIMIT_TTL_SECS)
        .query_async(conn)
        .await?;
    Ok(count)
}
