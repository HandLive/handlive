//! Relay server entry point: read config, connect, migrate, serve.

use actix_web::{App, HttpServer, middleware::Logger, web};
use relay_server::{MIGRATOR, config::Config, configure, state::AppState};

#[actix_web::main]
async fn main() -> std::io::Result<()> {
    env_logger::init_from_env(env_logger::Env::default().default_filter_or("info"));
    let config = Config::from_env().map_err(std::io::Error::other)?;
    let state = AppState::connect(&config)
        .await
        .map_err(std::io::Error::other)?;
    MIGRATOR
        .run(&state.db)
        .await
        .map_err(|e| std::io::Error::other(format!("migrations: {e}")))?;
    log::info!("migrations applied; listening on {}", config.bind);

    let state = web::Data::new(state);
    HttpServer::new(move || {
        App::new()
            .app_data(state.clone())
            // Path, status, response size and latency only: no query, no body.
            .wrap(Logger::new("%U %s %b %Dms"))
            .configure(configure)
    })
    .bind(&config.bind)?
    .run()
    .await
}
