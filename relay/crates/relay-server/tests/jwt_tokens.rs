//! JWT HS256 issue/verify (spec 0.6.4: claims sub, iat, exp, jti; 900 s).

use jsonwebtoken::{Algorithm, DecodingKey, Validation, decode, decode_header};
use relay_server::b64u;
use relay_server::clock::now_ms;
use relay_server::error::ApiError;
use relay_server::jwt::{Claims, JWT_TTL_SECS, JwtKeys};
use uuid::Uuid;

const SECRET: &[u8] = b"unit-test-secret-not-used-anywhere-else-0123";

fn keys() -> JwtKeys {
    JwtKeys::from_secret(SECRET).unwrap()
}

fn now_secs() -> i64 {
    now_ms() / 1000
}

#[test]
fn issued_token_is_hs256_with_spec_claims() {
    let device_id = Uuid::new_v4();
    let now = now_secs();
    let (token, expires_in) = keys().issue(&device_id, now).unwrap();
    assert_eq!(expires_in, 900);
    assert_eq!(decode_header(&token).unwrap().alg, Algorithm::HS256);

    let claims = decode::<Claims>(
        &token,
        &DecodingKey::from_secret(SECRET),
        &Validation::new(Algorithm::HS256),
    )
    .unwrap()
    .claims;
    assert_eq!(claims.sub, device_id.to_string());
    assert_eq!(claims.iat, now);
    assert_eq!(claims.exp - claims.iat, JWT_TTL_SECS);
    assert!(Uuid::parse_str(&claims.jti).is_ok());
    assert_eq!(keys().verify(&token), Ok(device_id));
}

#[test]
fn every_token_gets_a_fresh_jti() {
    let id = Uuid::new_v4();
    let (a, _) = keys().issue(&id, now_secs()).unwrap();
    let (b, _) = keys().issue(&id, now_secs()).unwrap();
    assert_ne!(a, b);
}

#[test]
fn expired_token_is_token_expired() {
    let (token, _) = keys()
        .issue(&Uuid::new_v4(), now_secs() - JWT_TTL_SECS - 1)
        .unwrap();
    assert_eq!(keys().verify(&token), Err(ApiError::TokenExpired));
}

#[test]
fn forged_or_malformed_tokens_are_signature_invalid() {
    let id = Uuid::new_v4();
    let (token, _) = keys().issue(&id, now_secs()).unwrap();
    let invalid = Err(ApiError::SignatureInvalid);

    let other = JwtKeys::from_secret(b"another-secret-of-sufficient-length-xyz!").unwrap();
    assert_eq!(other.verify(&token), invalid);

    let mut tampered = token.clone();
    tampered.push('A');
    assert_eq!(keys().verify(&tampered), invalid);
    assert_eq!(keys().verify("not.a.jwt"), invalid);

    // `alg: none` with the same claims must never pass.
    let payload = token.split('.').nth(1).unwrap();
    let none_header = b64u::encode(br#"{"alg":"none","typ":"JWT"}"#);
    assert_eq!(keys().verify(&format!("{none_header}.{payload}.")), invalid);
}

#[test]
fn short_secret_is_rejected() {
    assert!(JwtKeys::from_secret(b"too-short").is_err());
}
