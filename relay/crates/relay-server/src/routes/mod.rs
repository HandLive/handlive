//! HTTP routes implemented so far (spec 0.7.4).

pub mod auth;
pub mod devices;

use actix_web::web;

pub fn configure(cfg: &mut web::ServiceConfig) {
    cfg.service(
        web::scope("/v1")
            .route("/devices", web::post().to(devices::register))
            .route("/auth/challenge", web::post().to(auth::challenge))
            .route("/auth/token", web::post().to(auth::token)),
    );
}
