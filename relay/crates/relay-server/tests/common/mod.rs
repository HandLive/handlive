//! Helpers shared by the test binaries: test devices and vector loading.
#![allow(dead_code, unused_imports, unused_macros)]

pub mod http_harness;

use ed25519_dalek::{Signer, SigningKey};
use relay_server::b64u;
use relay_server::device_identity::device_id_from_public_key;
use relay_server::signatures::{auth_message, registration_message};
use ring::rand::{SecureRandom, SystemRandom};
use serde_json::{Value, json};
use uuid::Uuid;

/// A device identity (`ik_sig`) as a client would hold it.
pub struct TestDevice {
    pub key: SigningKey,
    pub public: [u8; 32],
    pub device_id: Uuid,
}

impl TestDevice {
    pub fn from_seed(seed: [u8; 32]) -> Self {
        let key = SigningKey::from_bytes(&seed);
        let public = key.verifying_key().to_bytes();
        Self {
            device_id: device_id_from_public_key(&public),
            key,
            public,
        }
    }

    pub fn random() -> Self {
        let mut seed = [0u8; 32];
        SystemRandom::new().fill(&mut seed).expect("rng");
        Self::from_seed(seed)
    }

    pub fn sign(&self, msg: &[u8]) -> [u8; 64] {
        self.key.sign(msg).to_bytes()
    }

    /// Body for `POST /v1/devices`.
    pub fn registration_body(&self, platform: &str, ts: i64) -> Value {
        let msg = registration_message(&self.device_id, &self.public, platform, ts);
        json!({
            "device_id": self.device_id.hyphenated().to_string(),
            "platform": platform,
            "app_version": "1.0.0 (100)",
            "ik_sig_pub": b64u::encode(&self.public),
            "ts": ts,
            "sig": b64u::encode(&self.sign(&msg)),
        })
    }

    /// Body for `POST /v1/auth/token` answering `challenge_b64u`.
    pub fn token_body(&self, challenge_b64u: &str) -> Value {
        let challenge: [u8; 32] = b64u::decode_fixed(challenge_b64u).expect("challenge");
        let sig = self.sign(&auth_message(&challenge, &self.device_id));
        json!({
            "device_id": self.device_id.hyphenated().to_string(),
            "challenge": challenge_b64u,
            "sig": b64u::encode(&sig),
        })
    }
}

pub fn hex32(s: &str) -> [u8; 32] {
    hex::decode(s).expect("hex").try_into().expect("32 bytes")
}

/// Load `shared/test-vectors/<name>` from the repository root.
pub fn load_vectors(name: &str) -> Value {
    let path = format!(
        "{}/../../../shared/test-vectors/{name}",
        env!("CARGO_MANIFEST_DIR")
    );
    let text = std::fs::read_to_string(&path).unwrap_or_else(|e| panic!("read {path}: {e}"));
    serde_json::from_str(&text).expect("vector json")
}
