//! HandLive cloud relay (Phase 0 scope): device registration, challenge/JWT
//! authentication and the PostgreSQL schema. Zero-knowledge: never decrypts
//! or logs payloads (spec 0.4.3, 0.6.5).

pub mod auth_extractor;
pub mod b64u;
pub mod challenge;
pub mod clock;
pub mod config;
pub mod device_identity;
pub mod error;
pub mod jwt;
pub mod routes;
pub mod signatures;
pub mod state;
pub mod store;

use actix_web::web;

/// Largest JSON body accepted on the auth/registration endpoints.
pub const MAX_JSON_BODY_BYTES: usize = 4 * 1024;

/// Embedded migrations from `relay/migrations`.
pub static MIGRATOR: sqlx::migrate::Migrator = sqlx::migrate!("../../migrations");

/// Register JSON limits/error mapping and all routes on an app.
pub fn configure(cfg: &mut web::ServiceConfig) {
    cfg.app_data(
        web::JsonConfig::default()
            .limit(MAX_JSON_BODY_BYTES)
            .error_handler(error::json_error_handler),
    )
    .configure(routes::configure);
}
