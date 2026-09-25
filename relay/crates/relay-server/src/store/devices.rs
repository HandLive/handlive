//! `devices` table access (spec 0.9.4; queries from CONN-03 "Query").

use sqlx::{PgPool, Row};
use uuid::Uuid;

/// Row data needed to authenticate a device.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct DeviceKey {
    pub ik_sig_pub: Vec<u8>,
    pub revoked: bool,
}

/// Result of a registration upsert.
#[derive(Debug, Clone, PartialEq, Eq)]
pub enum UpsertOutcome {
    Created {
        created_at_ms: i64,
    },
    Updated {
        created_at_ms: i64,
    },
    /// Row exists but is revoked (or holds another key): nothing changed.
    Rejected,
}

pub struct NewDevice<'a> {
    pub device_id: Uuid,
    pub ik_sig_pub: &'a [u8; 32],
    pub platform: &'a str,
    pub app_version: &'a str,
}

/// Register or refresh a device. `ik_sig_pub` of a `device_id` never changes.
pub async fn upsert(pool: &PgPool, device: &NewDevice<'_>) -> Result<UpsertOutcome, sqlx::Error> {
    let row = sqlx::query(
        "INSERT INTO devices (device_id, ik_sig_pub, platform, app_version)
         VALUES ($1, $2, $3, $4)
         ON CONFLICT (device_id) DO UPDATE
         SET app_version = EXCLUDED.app_version, last_seen_at = now()
         WHERE devices.revoked_at IS NULL AND devices.ik_sig_pub = EXCLUDED.ik_sig_pub
         RETURNING (extract(epoch FROM created_at) * 1000)::bigint AS created_at_ms,
                   (xmax = 0) AS inserted",
    )
    .bind(device.device_id)
    .bind(&device.ik_sig_pub[..])
    .bind(device.platform)
    .bind(device.app_version)
    .fetch_optional(pool)
    .await?;

    Ok(match row {
        None => UpsertOutcome::Rejected,
        Some(row) => {
            let created_at_ms: i64 = row.try_get("created_at_ms")?;
            if row.try_get::<bool, _>("inserted")? {
                UpsertOutcome::Created { created_at_ms }
            } else {
                UpsertOutcome::Updated { created_at_ms }
            }
        }
    })
}

/// Public key and revocation state, or `None` if the device is not registered.
pub async fn find_key(pool: &PgPool, device_id: Uuid) -> Result<Option<DeviceKey>, sqlx::Error> {
    let row = sqlx::query(
        "SELECT ik_sig_pub, revoked_at IS NOT NULL AS revoked FROM devices WHERE device_id = $1",
    )
    .bind(device_id)
    .fetch_optional(pool)
    .await?;
    row.map(|r| {
        Ok(DeviceKey {
            ik_sig_pub: r.try_get("ik_sig_pub")?,
            revoked: r.try_get("revoked")?,
        })
    })
    .transpose()
}

pub async fn touch_last_seen(pool: &PgPool, device_id: Uuid) -> Result<(), sqlx::Error> {
    sqlx::query("UPDATE devices SET last_seen_at = now() WHERE device_id = $1")
        .bind(device_id)
        .execute(pool)
        .await?;
    Ok(())
}
