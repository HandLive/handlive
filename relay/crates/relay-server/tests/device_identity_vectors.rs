//! `device_id` derivation against `shared/test-vectors/device-id.json` (spec 0.2, C4).

mod common;

use common::{TestDevice, hex32, load_vectors};
use relay_server::device_identity::{device_id_from_public_key, matches_public_key};
use uuid::Uuid;

#[test]
fn device_id_matches_shared_vectors() {
    let file = load_vectors("device-id.json");
    let vectors = file["vectors"].as_array().expect("vectors");
    assert!(vectors.len() >= 2);
    for v in vectors {
        let name = v["name"].as_str().unwrap();
        let public = hex32(v["ik_sig_pub"].as_str().unwrap());
        let id = device_id_from_public_key(&public);
        assert_eq!(
            id.hyphenated().to_string(),
            v["device_id"].as_str().unwrap(),
            "{name}"
        );
        assert_eq!(
            hex::encode(id.as_bytes()),
            v["device_id_bytes"].as_str().unwrap(),
            "{name}"
        );
        assert_eq!(id.get_version_num(), 8, "{name}");
        assert_eq!(id.get_variant(), uuid::Variant::RFC4122, "{name}");
        assert!(matches_public_key(&id, &public), "{name}");
    }
}

#[test]
fn seed_in_vectors_yields_the_listed_public_key() {
    let file = load_vectors("device-id.json");
    for v in file["vectors"].as_array().unwrap() {
        let device = TestDevice::from_seed(hex32(v["ik_sig_seed"].as_str().unwrap()));
        assert_eq!(
            hex::encode(device.public),
            v["ik_sig_pub"].as_str().unwrap()
        );
        assert_eq!(
            device.device_id.to_string(),
            v["device_id"].as_str().unwrap()
        );
    }
}

#[test]
fn device_id_of_another_key_does_not_match() {
    let a = TestDevice::random();
    let b = TestDevice::random();
    assert!(!matches_public_key(&a.device_id, &b.public));
    let mut flipped = a.public;
    flipped[0] ^= 0x01;
    assert!(!matches_public_key(&a.device_id, &flipped));
    assert!(!matches_public_key(&Uuid::nil(), &a.public));
}
