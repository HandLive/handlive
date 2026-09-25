//! `HLAUTH1` / `HLREG1` message layout and Ed25519 verification.

mod common;

use common::{TestDevice, hex32};
use relay_server::device_identity::device_id_from_public_key;
use relay_server::error::ApiError;
use relay_server::signatures::{auth_message, registration_message, verify_device_signature};

fn hex64(s: &str) -> [u8; 64] {
    hex::decode(s).unwrap().try_into().unwrap()
}

/// RFC 8032 §7.1 TEST 1 and TEST 2 (same keys as `device-id.json`).
#[test]
fn rfc8032_signatures_verify() {
    let cases = [
        (
            "d75a980182b10ab7d54bfed3c964073a0ee172f3daa62325af021a68f707511a",
            "",
            "e5564300c360ac729086e2cc806e828a84877f1eb8e5d974d873e065224901555fb8821590a33bacc61e39701cf9b46bd25bf5f0595bbe24655141438e7a100b",
        ),
        (
            "3d4017c3e843895a92b70aa74d1b7ebc9c982ccf2ec4968cc0cd55f12af4660c",
            "72",
            "92a009a9f0d4cab8720e820b5f642540a2b27b5416503f8fb3762223ebdb69da085ac1e43e15996e458f3613d0f11d8c387b2eaeb4302aeeb00d291612bb0c00",
        ),
    ];
    for (public, msg, sig) in cases {
        let public = hex32(public);
        let id = device_id_from_public_key(&public);
        let msg = hex::decode(msg).unwrap();
        let mut sig = hex64(sig);
        assert_eq!(verify_device_signature(&id, &public, &msg, &sig), Ok(()));
        sig[10] ^= 0x40;
        assert_eq!(
            verify_device_signature(&id, &public, &msg, &sig),
            Err(ApiError::SignatureInvalid)
        );
    }
}

#[test]
fn auth_message_layout() {
    let device = TestDevice::random();
    let challenge = [0xabu8; 32];
    let msg = auth_message(&challenge, &device.device_id);
    assert_eq!(msg.len(), 7 + 32 + 16);
    assert_eq!(&msg[..7], b"HLAUTH1");
    assert_eq!(&msg[7..39], &challenge);
    assert_eq!(&msg[39..], device.device_id.as_bytes());
}

#[test]
fn registration_message_layout() {
    let device = TestDevice::random();
    let ts: i64 = 1_727_151_100_000;
    let msg = registration_message(&device.device_id, &device.public, "macos", ts);
    assert_eq!(msg.len(), 6 + 16 + 32 + 5 + 8);
    assert_eq!(&msg[..6], b"HLREG1");
    assert_eq!(&msg[6..22], device.device_id.as_bytes());
    assert_eq!(&msg[22..54], &device.public);
    assert_eq!(&msg[54..59], b"macos");
    assert_eq!(&msg[59..], &ts.to_be_bytes());
}

#[test]
fn auth_signature_accepts_owner_and_rejects_everything_else() {
    let device = TestDevice::random();
    let other = TestDevice::random();
    let challenge = [7u8; 32];
    let msg = auth_message(&challenge, &device.device_id);
    let sig = device.sign(&msg);
    assert_eq!(
        verify_device_signature(&device.device_id, &device.public, &msg, &sig),
        Ok(())
    );

    let invalid = Err(ApiError::SignatureInvalid);
    // Signed by another key.
    let foreign = other.sign(&msg);
    assert_eq!(
        verify_device_signature(&device.device_id, &device.public, &msg, &foreign),
        invalid
    );
    // device_id not derived from the presented key (C4).
    assert_eq!(
        verify_device_signature(&other.device_id, &device.public, &msg, &sig),
        invalid
    );
    // Signature over a different challenge.
    let other_msg = auth_message(&[8u8; 32], &device.device_id);
    assert_eq!(
        verify_device_signature(&device.device_id, &device.public, &other_msg, &sig),
        invalid
    );
    // Garbage signature bytes.
    assert_eq!(
        verify_device_signature(&device.device_id, &device.public, &msg, &[0u8; 64]),
        invalid
    );
}
