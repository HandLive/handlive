//! Shared application state and connection setup.

use redis::aio::ConnectionManager;
use ring::rand::SystemRandom;
use sqlx::PgPool;
use sqlx::postgres::PgPoolOptions;

use crate::config::Config;
use crate::jwt::JwtKeys;

pub struct AppState {
    pub db: PgPool,
    pub redis: ConnectionManager,
    pub jwt: JwtKeys,
    pub rng: SystemRandom,
}

impl AppState {
    /// Connect to PostgreSQL and Redis. Does not run migrations.
    pub async fn connect(config: &Config) -> Result<Self, String> {
        let jwt = JwtKeys::from_secret(&config.jwt_secret)?;
        let db = PgPoolOptions::new()
            .max_connections(10)
            .connect(&config.database_url)
            .await
            .map_err(|e| format!("postgres connect: {e}"))?;
        let client = redis::Client::open(config.redis_url.as_str())
            .map_err(|e| format!("redis url: {e}"))?;
        let redis = ConnectionManager::new(client)
            .await
            .map_err(|e| format!("redis connect: {e}"))?;
        Ok(Self {
            db,
            redis,
            jwt,
            rng: SystemRandom::new(),
        })
    }
}
