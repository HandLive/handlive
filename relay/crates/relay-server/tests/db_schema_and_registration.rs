//! Schema and `POST /v1/devices` against real PostgreSQL 16 + Redis 7.
//!
//! Ignored by default. Run with the dev services up (see relay/README.md):
//!   set -a && . ./.env.example && set +a && cargo test -- --ignored

mod common;

use actix_web::http::StatusCode;
use common::TestDevice;
use common::http_harness::{app, code, post, state};
use relay_server::clock::now_ms;

#[actix_web::test]
#[ignore = "needs PostgreSQL + Redis (docker compose)"]
async fn schema_matches_spec_tables_and_indexes() {
    let state = state().await;
    let tables: Vec<(String,)> = sqlx::query_as(
        "SELECT table_name::text FROM information_schema.tables
         WHERE table_schema = 'public' AND table_name <> '_sqlx_migrations' ORDER BY 1",
    )
    .fetch_all(&state.db)
    .await
    .unwrap();
    let tables: Vec<_> = tables.into_iter().map(|t| t.0).collect();
    assert_eq!(tables, ["devices", "pairs", "usage_daily"]);
    let (count,): (i64,) = sqlx::query_as(
        "SELECT count(*) FROM pg_indexes WHERE indexname IN ('idx_pairs_device_a','idx_pairs_device_b')",
    )
    .fetch_one(&state.db)
    .await
    .unwrap();
    assert_eq!(count, 2);
}

#[actix_web::test]
#[ignore = "needs PostgreSQL + Redis (docker compose)"]
async fn register_then_refresh() {
    let state = state().await;
    let app = app!(state);
    let device = TestDevice::random();
    let body = device.registration_body("macos", now_ms());
    let (status, first) = post(&app, "/v1/devices", &body).await;
    assert_eq!(status, StatusCode::CREATED);
    assert_eq!(first["device_id"], device.device_id.to_string());
    let (status, second) = post(
        &app,
        "/v1/devices",
        &device.registration_body("macos", now_ms()),
    )
    .await;
    assert_eq!(status, StatusCode::OK);
    assert_eq!(first["created_at"], second["created_at"]);

    let mut forged = device.registration_body("macos", now_ms());
    forged["device_id"] = TestDevice::random().device_id.to_string().into();
    let (status, err) = post(&app, "/v1/devices", &forged).await;
    assert_eq!(
        (status, code(&err)),
        (StatusCode::UNAUTHORIZED, "SIGNATURE_INVALID")
    );

    sqlx::query("UPDATE devices SET revoked_at = now() WHERE device_id = $1")
        .bind(device.device_id)
        .execute(&state.db)
        .await
        .unwrap();
    let (status, err) = post(
        &app,
        "/v1/devices",
        &device.registration_body("macos", now_ms()),
    )
    .await;
    assert_eq!((status, code(&err)), (StatusCode::GONE, "DEVICE_REVOKED"));
}
