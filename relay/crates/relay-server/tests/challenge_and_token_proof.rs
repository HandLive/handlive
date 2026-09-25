//! Challenge rules and the `/v1/auth/token` proof check without Redis/Postgres.

mod common;

use common::TestDevice;
use relay_server::b64u;
use relay_server::challenge::{accept_presented, generate, minute_window, rate_limit_decision};
use relay_server::error::ApiError;
use relay_server::routes::auth::{TokenRequest, check_token_proof, usable_key};
use relay_server::signatures::auth_message;
use relay_server::store::devices::DeviceKey;
use ring::rand::SystemRandom;

fn registered(device: &TestDevice) -> Option<DeviceKey> {
    Some(DeviceKey {
        ik_sig_pub: device.public.to_vec(),
        revoked: false,
    })
}

fn signed_request(device: &TestDevice, challenge: &[u8; 32]) -> (TokenRequest, [u8; 64]) {
    let sig = device.sign(&auth_message(challenge, &device.device_id));
    let req = TokenRequest {
        device_id: device.device_id,
        challenge: b64u::encode(challenge),
        sig: b64u::encode(&sig),
    };
    (req, sig)
}

#[test]
fn generated_challenges_are_32_random_bytes() {
    let rng = SystemRandom::new();
    let a = generate(&rng).unwrap();
    let b = generate(&rng).unwrap();
    assert_ne!(a, b);
    assert_eq!(b64u::encode(&a).len(), 43); // b64u of 32 bytes, no padding
}

#[test]
fn presented_challenge_must_equal_the_stored_one() {
    let stored = b64u::encode(&[1u8; 32]);
    assert_eq!(accept_presented(Some(&stored), &stored), Ok([1u8; 32]));
    let expired = Err(ApiError::ChallengeExpired);
    // Expired, already used (GETDEL returned nothing) or never issued.
    assert_eq!(accept_presented(None, &stored), expired);
    assert_eq!(
        accept_presented(Some(&stored), &b64u::encode(&[2u8; 32])),
        expired
    );
    assert_eq!(accept_presented(Some(&stored), "not*b64u"), expired);
    assert_eq!(
        accept_presented(Some(&stored), &b64u::encode(&[1u8; 31])),
        expired
    );
}

#[test]
fn token_proof_happy_path() {
    let device = TestDevice::random();
    let challenge = [9u8; 32];
    let (req, sig) = signed_request(&device, &challenge);
    let stored = b64u::encode(&challenge);
    assert_eq!(
        check_token_proof(Some(&stored), &req, &sig, registered(&device)),
        Ok(())
    );
}

#[test]
fn token_proof_error_codes() {
    let device = TestDevice::random();
    let challenge = [9u8; 32];
    let (req, sig) = signed_request(&device, &challenge);
    let stored = b64u::encode(&challenge);

    // Expired challenge wins even when the signature is also wrong.
    assert_eq!(
        check_token_proof(None, &req, &[0u8; 64], registered(&device)),
        Err(ApiError::ChallengeExpired)
    );
    assert_eq!(
        check_token_proof(Some(&stored), &req, &sig, None),
        Err(ApiError::DeviceNotFound)
    );
    let revoked = Some(DeviceKey {
        ik_sig_pub: device.public.to_vec(),
        revoked: true,
    });
    assert_eq!(
        check_token_proof(Some(&stored), &req, &sig, revoked),
        Err(ApiError::DeviceRevoked)
    );

    let mut bad_sig = sig;
    bad_sig[0] ^= 1;
    assert_eq!(
        check_token_proof(Some(&stored), &req, &bad_sig, registered(&device)),
        Err(ApiError::SignatureInvalid)
    );
    // Registered key belongs to someone else (device_id does not derive from it).
    let other = TestDevice::random();
    assert_eq!(
        check_token_proof(Some(&stored), &req, &sig, registered(&other)),
        Err(ApiError::SignatureInvalid)
    );
}

#[test]
fn usable_key_maps_lookup_results() {
    let device = TestDevice::random();
    assert_eq!(usable_key(registered(&device)), Ok(device.public));
    assert_eq!(usable_key(None), Err(ApiError::DeviceNotFound));
}

#[test]
fn challenge_rate_limit_is_ten_per_minute() {
    let start_of_minute = 1_727_151_060_000_i64; // multiple of 60 000
    assert_eq!(minute_window(start_of_minute), start_of_minute / 60_000);
    assert_eq!(rate_limit_decision(10, 10, start_of_minute), Ok(()));
    assert_eq!(
        rate_limit_decision(11, 10, start_of_minute),
        Err(ApiError::RateLimited {
            retry_after_secs: 60
        })
    );
    assert_eq!(
        rate_limit_decision(11, 10, start_of_minute + 59_500),
        Err(ApiError::RateLimited {
            retry_after_secs: 1
        })
    );
}
