//! Challenge, token and JWT extractor against real PostgreSQL 16 + Redis 7.
//!
//! Ignored by default. Run with the dev services up (see relay/README.md):
//!   set -a && . ./.env.example && set +a && cargo test -- --ignored

mod common;

use actix_web::http::StatusCode;
use actix_web::test;
use common::TestDevice;
use common::http_harness::{TEST_JWT_SECRET, login, read, register, whoami_with};
use common::http_harness::{app, code, post, state};
use redis::AsyncCommands;
use relay_server::challenge::minute_window;
use relay_server::clock::now_ms;
use relay_server::jwt::JwtKeys;
use relay_server::store::challenges::{challenge_key, rate_limit_key};
use serde_json::json;

#[actix_web::test]
#[ignore = "needs PostgreSQL + Redis (docker compose)"]
async fn challenge_token_and_jwt_extractor() {
    let state = state().await;
    let app = app!(state);
    let device = TestDevice::random();

    let (status, err) = post(
        &app,
        "/v1/auth/challenge",
        &json!({ "device_id": device.device_id }),
    )
    .await;
    assert_eq!(
        (status, code(&err)),
        (StatusCode::NOT_FOUND, "DEVICE_NOT_FOUND")
    );

    register(&app, &device).await;
    let (status, chal) = post(
        &app,
        "/v1/auth/challenge",
        &json!({ "device_id": device.device_id }),
    )
    .await;
    assert_eq!(status, StatusCode::OK);
    let expires_at = chal["expires_at"].as_i64().unwrap();
    assert!((expires_at - now_ms() - 60_000).abs() < 2_000);
    let body = device.token_body(chal["challenge"].as_str().unwrap());
    let (status, tok) = post(&app, "/v1/auth/token", &body).await;
    assert_eq!(status, StatusCode::OK);
    assert_eq!(tok["expires_in"], 900);

    // Reusing the consumed challenge.
    let (status, err) = post(&app, "/v1/auth/token", &body).await;
    assert_eq!(
        (status, code(&err)),
        (StatusCode::UNAUTHORIZED, "CHALLENGE_EXPIRED")
    );

    let token = tok["access_token"].as_str().unwrap();
    let (status, me) = whoami_with(&app, Some(token)).await;
    assert_eq!(status, StatusCode::OK);
    assert_eq!(me["device_id"], device.device_id.to_string());
}

#[actix_web::test]
#[ignore = "needs PostgreSQL + Redis (docker compose)"]
async fn expired_challenge_and_wrong_signature() {
    let state = state().await;
    let app = app!(state);
    let device = TestDevice::random();
    register(&app, &device).await;
    let id = json!({ "device_id": device.device_id });

    // Let the Redis TTL lapse instead of waiting 60 s.
    let (_, chal) = post(&app, "/v1/auth/challenge", &id).await;
    let mut redis = state.redis.clone();
    let _: bool = redis
        .pexpire(challenge_key(&device.device_id), 1)
        .await
        .unwrap();
    tokio::time::sleep(std::time::Duration::from_millis(50)).await;
    let body = device.token_body(chal["challenge"].as_str().unwrap());
    let (status, err) = post(&app, "/v1/auth/token", &body).await;
    assert_eq!(
        (status, code(&err)),
        (StatusCode::UNAUTHORIZED, "CHALLENGE_EXPIRED")
    );

    // Signed by another key: rejected, and the challenge is consumed.
    let (_, chal) = post(&app, "/v1/auth/challenge", &id).await;
    let mut body = TestDevice::random().token_body(chal["challenge"].as_str().unwrap());
    body["device_id"] = device.device_id.to_string().into();
    let (status, err) = post(&app, "/v1/auth/token", &body).await;
    assert_eq!(
        (status, code(&err)),
        (StatusCode::UNAUTHORIZED, "SIGNATURE_INVALID")
    );
    let good = device.token_body(chal["challenge"].as_str().unwrap());
    let (status, err) = post(&app, "/v1/auth/token", &good).await;
    assert_eq!(
        (status, code(&err)),
        (StatusCode::UNAUTHORIZED, "CHALLENGE_EXPIRED")
    );
}

#[actix_web::test]
#[ignore = "needs PostgreSQL + Redis (docker compose)"]
async fn jwt_rejections() {
    let state = state().await;
    let app = app!(state);
    let device = TestDevice::random();
    register(&app, &device).await;

    let (status, err) = whoami_with(&app, None).await;
    assert_eq!(
        (status, code(&err)),
        (StatusCode::UNAUTHORIZED, "SIGNATURE_INVALID")
    );

    let keys = JwtKeys::from_secret(TEST_JWT_SECRET.as_bytes()).unwrap();
    let (expired, _) = keys
        .issue(&device.device_id, now_ms() / 1000 - 901)
        .unwrap();
    let (status, err) = whoami_with(&app, Some(&expired)).await;
    assert_eq!(
        (status, code(&err)),
        (StatusCode::UNAUTHORIZED, "TOKEN_EXPIRED")
    );

    // JWT still valid, but the device left the relay (spec 0.6.4 step 4).
    let token = login(&app, &device).await;
    sqlx::query("UPDATE devices SET revoked_at = now() WHERE device_id = $1")
        .bind(device.device_id)
        .execute(&state.db)
        .await
        .unwrap();
    let (status, err) = whoami_with(&app, Some(&token)).await;
    assert_eq!((status, code(&err)), (StatusCode::GONE, "DEVICE_REVOKED"));
    sqlx::query("DELETE FROM devices WHERE device_id = $1")
        .bind(device.device_id)
        .execute(&state.db)
        .await
        .unwrap();
    let (status, err) = whoami_with(&app, Some(&token)).await;
    assert_eq!(
        (status, code(&err)),
        (StatusCode::NOT_FOUND, "DEVICE_NOT_FOUND")
    );
}

#[actix_web::test]
#[ignore = "needs PostgreSQL + Redis (docker compose)"]
async fn rate_limit_and_body_errors() {
    let state = state().await;
    let app = app!(state);
    let device = TestDevice::random();
    register(&app, &device).await;

    // Fill the current (and next, in case the minute rolls over) window.
    let mut redis = state.redis.clone();
    let minute = minute_window(now_ms());
    for m in [minute, minute + 1] {
        let _: () = redis
            .set_ex(rate_limit_key(&device.device_id, "chal", m), 10, 120)
            .await
            .unwrap();
    }
    let req = test::TestRequest::post()
        .uri("/v1/auth/challenge")
        .set_json(json!({ "device_id": device.device_id }))
        .to_request();
    let resp = test::call_service(&app, req).await;
    assert_eq!(resp.status(), StatusCode::TOO_MANY_REQUESTS);
    let retry: u64 = resp
        .headers()
        .get("Retry-After")
        .unwrap()
        .to_str()
        .unwrap()
        .parse()
        .unwrap();
    assert!((1..=60).contains(&retry));

    let req = test::TestRequest::post()
        .uri("/v1/auth/token")
        .insert_header(("Content-Type", "application/json"))
        .set_payload("{not json")
        .to_request();
    let (status, err) = read(test::call_service(&app, req).await).await;
    assert_eq!(
        (status, code(&err)),
        (StatusCode::BAD_REQUEST, "BAD_REQUEST")
    );

    let big = json!({ "device_id": device.device_id, "challenge": "x".repeat(8192), "sig": "" });
    let (status, err) = post(&app, "/v1/auth/token", &big).await;
    assert_eq!(
        (status, code(&err)),
        (StatusCode::PAYLOAD_TOO_LARGE, "PAYLOAD_TOO_LARGE")
    );
}
