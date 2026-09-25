//! HTTP mapping of relay errors (spec 0.8.2) and bearer header parsing.

use actix_web::ResponseError;
use actix_web::body::to_bytes;
use actix_web::http::header::{HeaderValue, RETRY_AFTER};
use relay_server::auth_extractor::bearer_token;
use relay_server::error::ApiError;
use serde_json::Value;

#[actix_web::test]
async fn status_codes_and_body_follow_spec() {
    let cases = [
        (ApiError::BadRequest, 400, "BAD_REQUEST"),
        (ApiError::ChallengeExpired, 401, "CHALLENGE_EXPIRED"),
        (ApiError::SignatureInvalid, 401, "SIGNATURE_INVALID"),
        (ApiError::TokenExpired, 401, "TOKEN_EXPIRED"),
        (ApiError::DeviceNotFound, 404, "DEVICE_NOT_FOUND"),
        (ApiError::DeviceRevoked, 410, "DEVICE_REVOKED"),
        (ApiError::PayloadTooLarge, 413, "PAYLOAD_TOO_LARGE"),
        (
            ApiError::RateLimited {
                retry_after_secs: 17,
            },
            429,
            "RATE_LIMITED",
        ),
        (ApiError::Internal, 500, "INTERNAL"),
    ];
    for (err, status, code) in cases {
        let resp = err.error_response();
        assert_eq!(resp.status().as_u16(), status, "{code}");
        let body: Value =
            serde_json::from_slice(&to_bytes(resp.into_body()).await.unwrap()).unwrap();
        assert_eq!(body["error"]["code"], code);
        assert!(body["error"]["message"].is_string());
    }
}

#[test]
fn rate_limited_sets_retry_after() {
    let resp = ApiError::RateLimited {
        retry_after_secs: 17,
    }
    .error_response();
    assert_eq!(resp.headers().get(RETRY_AFTER).unwrap(), "17");
}

#[test]
fn bearer_header_parsing() {
    let ok = HeaderValue::from_static("Bearer abc.def.ghi");
    assert_eq!(bearer_token(Some(&ok)), Ok("abc.def.ghi"));
    let lower = HeaderValue::from_static("bearer abc");
    assert_eq!(bearer_token(Some(&lower)), Ok("abc"));
    for bad in ["Basic abc", "Bearer", "Bearer ", "abc"] {
        let value = HeaderValue::from_static(bad);
        assert_eq!(
            bearer_token(Some(&value)),
            Err(ApiError::SignatureInvalid),
            "{bad}"
        );
    }
    assert_eq!(bearer_token(None), Err(ApiError::SignatureInvalid));
}
