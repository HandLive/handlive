//! Harness for DB-backed tests: real AppState (PostgreSQL + Redis from env),
//! the production routes plus a test-only route guarded by the JWT extractor.

use actix_http::Request;
use actix_web::dev::{Service, ServiceResponse};
use actix_web::http::StatusCode;
use actix_web::{HttpResponse, test, web};
use relay_server::MIGRATOR;
use relay_server::auth_extractor::AuthenticatedDevice;
use relay_server::clock::now_ms;
use relay_server::config::Config;
use relay_server::state::AppState;
use serde_json::{Value, json};

use super::TestDevice;

/// Dummy HS256 key used only by the integration tests.
pub const TEST_JWT_SECRET: &str = "integration-test-secret-not-a-real-key-0123";

pub async fn state() -> web::Data<AppState> {
    let config = Config {
        database_url: std::env::var("DATABASE_URL").expect("DATABASE_URL"),
        redis_url: std::env::var("REDIS_URL").expect("REDIS_URL"),
        jwt_secret: TEST_JWT_SECRET.as_bytes().to_vec(),
        bind: String::new(),
    };
    let state = AppState::connect(&config).await.expect("connect");
    MIGRATOR.run(&state.db).await.expect("migrate");
    web::Data::new(state)
}

/// Test-only route that exercises the JWT extractor.
pub async fn whoami(device: AuthenticatedDevice) -> HttpResponse {
    HttpResponse::Ok().json(json!({ "device_id": device.device_id }))
}

/// Build the test service: production routes + `GET /test/whoami`.
macro_rules! app {
    ($state:expr) => {
        ::actix_web::test::init_service(
            ::actix_web::App::new()
                .app_data($state.clone())
                .configure(::relay_server::configure)
                .route(
                    "/test/whoami",
                    ::actix_web::web::get().to(crate::common::http_harness::whoami),
                ),
        )
        .await
    };
}
pub(crate) use app;

pub trait TestService:
    Service<Request, Response = ServiceResponse, Error = actix_web::Error>
{
}
impl<S> TestService for S where
    S: Service<Request, Response = ServiceResponse, Error = actix_web::Error>
{
}

pub async fn read(resp: ServiceResponse) -> (StatusCode, Value) {
    let status = resp.status();
    let bytes = test::read_body(resp).await;
    (
        status,
        serde_json::from_slice(&bytes).unwrap_or(Value::Null),
    )
}

pub async fn post(app: &impl TestService, path: &str, body: &Value) -> (StatusCode, Value) {
    let req = test::TestRequest::post()
        .uri(path)
        .set_json(body)
        .to_request();
    read(test::call_service(app, req).await).await
}

pub fn code(body: &Value) -> &str {
    body["error"]["code"].as_str().unwrap_or("")
}

pub async fn register(app: &impl TestService, device: &TestDevice) {
    let body = device.registration_body("macos", now_ms());
    let (status, _) = post(app, "/v1/devices", &body).await;
    assert_eq!(status, StatusCode::CREATED);
}

/// Challenge → token; returns the access token.
pub async fn login(app: &impl TestService, device: &TestDevice) -> String {
    let id = json!({ "device_id": device.device_id });
    let (status, chal) = post(app, "/v1/auth/challenge", &id).await;
    assert_eq!(status, StatusCode::OK);
    let body = device.token_body(chal["challenge"].as_str().unwrap());
    let (status, tok) = post(app, "/v1/auth/token", &body).await;
    assert_eq!(status, StatusCode::OK, "{tok}");
    tok["access_token"].as_str().unwrap().to_owned()
}

pub async fn whoami_with(app: &impl TestService, token: Option<&str>) -> (StatusCode, Value) {
    let mut req = test::TestRequest::get().uri("/test/whoami");
    if let Some(t) = token {
        req = req.insert_header(("Authorization", format!("Bearer {t}")));
    }
    read(test::call_service(app, req.to_request()).await).await
}
