//! Runtime configuration from environment variables (see `relay/.env.example`).
//! Secrets are never read from files in the repository.

use std::env;

pub struct Config {
    pub database_url: String,
    pub redis_url: String,
    pub jwt_secret: Vec<u8>,
    pub bind: String,
}

impl Config {
    pub fn from_env() -> Result<Self, String> {
        Ok(Self {
            database_url: required("DATABASE_URL")?,
            redis_url: required("REDIS_URL")?,
            jwt_secret: required("RELAY_JWT_SECRET")?.into_bytes(),
            bind: env::var("RELAY_BIND").unwrap_or_else(|_| "127.0.0.1:8080".to_owned()),
        })
    }
}

fn required(name: &str) -> Result<String, String> {
    env::var(name).map_err(|_| format!("missing environment variable {name}"))
}
