//! `POST /v1/devices` body validation (CONN-03 API 1) without a database.

mod common;

use common::TestDevice;
use relay_server::clock::now_ms;
use relay_server::error::ApiError;
use relay_server::routes::devices::{MAX_TS_SKEW_MS, RegisterRequest, verify_registration};
use serde_json::Value;

fn parse(body: Value) -> RegisterRequest {
    serde_json::from_value(body).unwrap()
}

#[test]
fn valid_registration_passes_for_every_platform() {
    let device = TestDevice::random();
    let now = now_ms();
    for platform in ["android", "macos", "ios", "ipados"] {
        let req = parse(device.registration_body(platform, now));
        assert_eq!(
            verify_registration(&req, now),
            Ok(device.public),
            "{platform}"
        );
    }
}

#[test]
fn skewed_timestamp_is_signature_invalid() {
    let device = TestDevice::random();
    let now = now_ms();
    let req = parse(device.registration_body("macos", now - MAX_TS_SKEW_MS - 1));
    assert_eq!(
        verify_registration(&req, now),
        Err(ApiError::SignatureInvalid)
    );
    let req = parse(device.registration_body("macos", now + MAX_TS_SKEW_MS));
    assert_eq!(verify_registration(&req, now), Ok(device.public));
}

#[test]
fn device_id_must_derive_from_key() {
    let device = TestDevice::random();
    let other = TestDevice::random();
    let now = now_ms();
    let mut body = device.registration_body("android", now);
    body["device_id"] = other.device_id.to_string().into();
    assert_eq!(
        verify_registration(&parse(body), now),
        Err(ApiError::SignatureInvalid)
    );
}

#[test]
fn signature_must_cover_the_fields() {
    let device = TestDevice::random();
    let now = now_ms();
    // Signed as macos, submitted as ios.
    let mut body = device.registration_body("macos", now);
    body["platform"] = "ios".into();
    assert_eq!(
        verify_registration(&parse(body), now),
        Err(ApiError::SignatureInvalid)
    );
    // Signed for one ts, submitted with another.
    let mut body = device.registration_body("macos", now);
    body["ts"] = (now + 1).into();
    assert_eq!(
        verify_registration(&parse(body), now),
        Err(ApiError::SignatureInvalid)
    );
}

#[test]
fn malformed_fields_are_bad_request() {
    let device = TestDevice::random();
    let now = now_ms();
    let cases: [(&str, Value); 5] = [
        ("platform", "windows".into()),
        ("app_version", "x".repeat(33).into()),
        ("app_version", "".into()),
        ("ik_sig_pub", "AAAA".into()),
        ("sig", "not base64url!".into()),
    ];
    for (field, value) in cases {
        let mut body = device.registration_body("macos", now);
        body[field] = value;
        assert_eq!(
            verify_registration(&parse(body), now),
            Err(ApiError::BadRequest),
            "{field}"
        );
    }
}
