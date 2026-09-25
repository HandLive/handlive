-- Relay schema, spec 00-common-specs 0.9.4 (PostgreSQL 16).

-- Registered devices. device_id is self-certifying: UUIDv8 from SHA-256(ik_sig_pub).
CREATE TABLE devices (
  device_id      UUID        PRIMARY KEY,
  ik_sig_pub     BYTEA       NOT NULL UNIQUE CHECK (octet_length(ik_sig_pub) = 32),
  platform       TEXT        NOT NULL CHECK (platform IN ('android','macos','ios','ipados')),
  app_version    TEXT        NOT NULL,
  push_provider  TEXT        CHECK (push_provider IN ('fcm','apns','apns_sandbox')),
  push_token     TEXT,
  push_topic     TEXT,                                  -- bundle id for APNs
  created_at     TIMESTAMPTZ NOT NULL DEFAULT now(),
  last_seen_at   TIMESTAMPTZ NOT NULL DEFAULT now(),
  revoked_at     TIMESTAMPTZ
);

-- Attested pairs (device_a = Android, device_b = Mac/iOS).
CREATE TABLE pairs (
  pair_id        UUID        PRIMARY KEY,
  device_a       UUID        NOT NULL REFERENCES devices(device_id) ON DELETE CASCADE,
  device_b       UUID        NOT NULL REFERENCES devices(device_id) ON DELETE CASCADE,
  attestation    BYTEA       NOT NULL,
  sig_a          BYTEA       NOT NULL,
  sig_b          BYTEA       NOT NULL,
  created_at     TIMESTAMPTZ NOT NULL DEFAULT now(),
  revoked_at     TIMESTAMPTZ,
  revoked_by     UUID,
  CHECK (device_a <> device_b)
);
CREATE INDEX idx_pairs_device_a ON pairs (device_a) WHERE revoked_at IS NULL;
CREATE INDEX idx_pairs_device_b ON pairs (device_b) WHERE revoked_at IS NULL;

-- Minimal usage statistics keyed by device_hash, kept 30 days.
CREATE TABLE usage_daily (
  day            DATE        NOT NULL,
  device_hash    BYTEA       NOT NULL,
  envelopes      BIGINT      NOT NULL DEFAULT 0,
  bytes          BIGINT      NOT NULL DEFAULT 0,
  pushes         INTEGER     NOT NULL DEFAULT 0,
  PRIMARY KEY (day, device_hash)
);
