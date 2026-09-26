English | [Tiếng Việt](02-pairing.vi.md)

# 2. Function group: Pairing and device management

> Shared references: [`00-common-specs.md`](00-common-specs.md) — components (0.1), identifiers (0.2),
> message frames (0.5), keys and pairing (0.6.1–0.6.2), error codes (0.8), schema (0.9).

## 2.1 PAIR-01 — Pair devices with a QR code (fallback: PIN)

### 2.1.1 General information

| Item | Content |
|-----|----------|
| Name | PAIR-01 — Pair devices with a QR code (fallback: PIN) |
| Description | Establishes a trust relationship between the Android phone and a Mac/iPhone/iPad: exchange the identity keys, derive the pair root key `PRK`, pin the phone's TLS certificate and store an attestation signed by both sides.<br>Mac/iOS shows the QR code, Android scans it.<br>When the QR code can't be scanned, a 6-digit PIN is used (LAN only).<br>From P2, if the two devices can't see each other on the LAN, the exchange goes through a rendezvous on the relay (QR only). |
| Actors | Primary: User (owns both devices). System: A-UI, A-SVC, M-APP or I-APP, R-API and R-KV (rendezvous, pair registration). |
| Preconditions | 1.<br>Android has completed SET-01 (with the camera permission for scanning the QR code) and A-SVC is running.<br>2.<br>Mac/iOS has completed SET-03 (local network permission).<br>3.<br>Both devices are on the same LAN; or (from P2) both have internet access and `relay.enabled = true`.<br>4.<br>Mac/iOS has no active pair yet.<br>5.<br>Android has fewer than 8 active pairs. |
| Postconditions | **Success:** both sides have a `paired_device` record with the same `pair_id`; `PRK` is in the key store; Mac/iOS pins `peer_tls_sha256`; the pair is registered with the relay if the relay is enabled (or marked as waiting for registration); CONN-01 starts automatically.<br>**Failure:** neither side stores anything; the `pairing_secret` or the PIN is wiped from memory. |
| Exceptions | E1 — The QR code is not a HandLive code or is malformed (`QR_INVALID`): Android shows "This QR code isn't a HandLive code."<br>E2 — The QR code has expired because Mac/iOS has refreshed it (`PAIRING_CLOSED`): Android shows "The QR code has changed. Scan the new code on your Mac or iPhone."<br>E3 — The devices don't find each other within 20 s and the relay is unavailable: Mac/iOS shows "Couldn't find the phone. Put both devices on the same Wi-Fi network and try again."<br>E4 — Wrong HMAC, signature or TLS binding; possibly a man-in-the-middle attack (`AUTH_FAILED`).<br>E5 — The user taps Cancel on Android.<br>E6 — Android already has 8 pairs: Android shows "This phone is already paired with 8 devices. Unpair one and try again."<br>E7 — Wrong PIN (`PIN_INVALID`); after 3 failed attempts Mac/iOS generates a new PIN.<br>E8 — Registering the pair with the relay fails: the pair still works on the LAN, `relay_registered = 0`, retry in the background.<br>E9 — Camera permission denied: Android shows "The camera isn't available. Use a PIN to pair." and switches to the PIN. |
| Special requirements | **Security:** `pairing_secret` is 256 bits, lives only 120 s, never leaves the device except through the QR code and is never logged; HMAC comparison is constant-time; the relay never sees `pairing_secret` and is not used for the PIN.<br>The PIN is the fallback path: an active attacker in the middle at the exact moment of pairing could guess the PIN offline — mitigated by Argon2id (t=3, m=64 MiB, p=4), a limit of 3 attempts and allowing it on the LAN only.<br>**Performance:** from scanning to "Paired" ≤ 5 s on the LAN, ≤ 8 s through the relay.<br>**Usability:** the QR code has enough contrast in both light and dark appearance; the instructions are readable with VoiceOver/TalkBack; QR recognition runs entirely on the device (bundled ML Kit). |

### 2.1.2 Screens

N/A — no approved wireframe yet.

### 2.1.3 Component details

| # | Field | Data type | Input/Output | Initial value | Description |
|---|--------|--------------|--------------|------------------|-------|
| 1 | Pairing QR code | string (URI) | Output | Generated when the pairing screen opens | Mac/iOS shows `handlive://pair?v=1&pk=…&ps=…&d=…[&rv=…]`; error correction level M; refreshes automatically after 120 s |
| 2 | Remaining validity | int32 (seconds) | Output | 120 | Countdown under the QR code; at 0 a new QR code is generated |
| 3 | Client device name | string(64) | Output | The device name (`Host.current().localizedName` / `UIDevice.current.name`) | Carried in the QR code (`d`) and shown on Android for confirmation |
| 4 | QR scanner | camera preview | Input | Back camera | Android scans with CameraX + ZXing core (no ML Kit, plan decision I8) |
| 5 | Pairing confirmation | enum{Pair\| Cancel} | Input | — | Android asks "Pair with \<client device name>?"; "Pair" is the default button, "Cancel" is on the left |
| 6 | PIN | string(6), digits only | Output (Mac/iOS), Input (Android) | Generated when "Use a PIN" is chosen | Fallback when the QR code can't be scanned<br>Hint on Android: "Type the 6-digit PIN shown on your Mac or iPhone." |
| 7 | PIN attempts left | int32 | Output | 3 | Shown on Android after a wrong entry: "{count} attempts left" ("1 attempt left") |
| 8 | Pairing status | enum{waiting_scan\| connecting\| verifying\| done\| failed} | Output | `waiting_scan` | Shown on both devices |
| 9 | Phone name | string(64) | Output | `Settings.Global.DEVICE_NAME` | Shown on Mac/iOS when pairing completes |
| 10 | Error message | string | Output | Empty | Text per E1–E9; failures without their own text (lost connection, internal error): "Pairing didn't finish. Try again." |

### 2.1.4 Business flow

```mermaid
flowchart TB
  subgraph ND["User"]
    U1["(1) Choose Add Phone on Mac/iOS"]
    U3["(3) Open Pair a Device on Android, scan the QR code"]
    U5["(5) Confirm pairing"]
    U12["(12) See Paired on both devices"]
  end
  subgraph HT["System"]
    S2["(2) Generate pairing_secret, show the QR code for 120 s"]
    D4{"(4) QR code valid and a pair slot left?"}
    S6["(6) Android opens the pairing window, advertises TXT pr"]
    D7{"(7) Found each other within 20 s?"}
    S8["(8) Open /v1/pair (LAN) or the relay rendezvous"]
    S9["(9) pair/hello and pair/offer"]
    D10{"(10) HMAC, device_id, TLS valid?"}
    S11["(11) pair/confirm and pair/done, store the pair, register with the relay"]
    X1(["End: show error"])
  end
  U1 --> S2 --> U3 --> D4
  D4 -- "Yes" --> U5
  D4 -- "No (E1, E2, E6)" --> X1
  U5 -- "Accept" --> S6 --> D7
  U5 -- "Cancel (E5)" --> X1
  D7 -- "LAN or relay" --> S8 --> S9 --> D10
  D7 -- "No (E3)" --> X1
  D10 -- "Valid" --> S11 --> U12
  D10 -- "Invalid (E4)" --> X1
```

| Step | Actor | Component | Description | Exceptions / Notes |
|------|----------|-----------|-------|--------------------|
| 1 | User | M-APP / I-APP | Chooses "Add Phone…" (on the first launch of the app or from PAIR-02). | An active pair already exists → ask to unpair the old one first (PAIR-03). |
| 2 | System | M-APP / I-APP | Loads or creates `ik_dh`, `ik_sig`; generates a 32-byte `pairing_secret` (`SecRandomCopyBytes`).<br>If the relay is enabled: generate a 16-byte `rv_id`, authenticate with the relay (0.6.4), send `rv_join`.<br>Builds the QR URI and draws the QR code (`CIFilter.qrCodeGenerator`).<br>Starts browsing mDNS for `_handlive._tcp`.<br>Sets a 120 s timer: discard the old secret, go back to step 2. | Relay error → the QR code has no `rv`; pairing on the LAN only. |
| 3 | User | A-UI | Opens "Pair a Device" and scans the QR code. | No camera permission → E9, switch to the PIN flow (A1). |
| 4 | System | A-UI | Checks the scheme `handlive`, the host `pair`, `v = 1`, that `pk` and `ps` decode to exactly 32 bytes, `d` ≤ 64 characters and `rv` (if present) is exactly 16 bytes. Checks that active pairs < 8. | Malformed → E1. 8 pairs already → E6. |
| 5 | User | A-UI | Chooses "Pair" or "Cancel" in the "Pair with \<d>?" dialog. | "Cancel" → E5. |
| 6 | System | A-SVC | Opens a 120 s pairing window: accepts connections on `/v1/pair`; re-registers the mDNS service with TXT `pr` = the first 8 lowercase hex digits of SHA-256 over the 32 decoded bytes of `pk`. If `rv` is present: connect to the relay and send `rv_join`. |  |
| 7 | System | M-APP / I-APP | Waits up to 20 s: an instance with a matching `pr` is found → go over the LAN; `rv_joined` arrives with `peer_present = true` → go through the relay. The LAN wins if both are available. | No path at all → E3. |
| 8 | System | M-APP / I-APP | LAN: open `wss://<ip>:<port>/v1/pair` and accept the self-signed certificate, but record the SHA-256 of the certificate seen. Relay: wrap the `pair` envelopes in `rv_msg`. |  |
| 9 | System | M-APP ↔ A-SVC | The client sends `pair/hello`. Android checks that `ik_dh_pub` equals the `pk` from the QR code, generates `nonce_s`, computes `K_pa` and returns a `pair/offer` with a `mac`. | `ik_dh_pub` differs from `pk` → `pair/error AUTH_FAILED` (E4). |
| 10 | System | M-APP / I-APP | Checks the offer's `mac`; checks that the Android `device_id` = UUIDv8(SHA-256(`ik_sig_pub`)); on the LAN checks that `tls_sha256` = the certificate of the current connection. | Mismatch → send `pair/error AUTH_FAILED`, close, show "Pairing isn't secure — try again" (E4). |
| 11 | System | M-APP ↔ A-SVC, R-API | The client computes `PRK`, generates `pair_id`, `created_at` and the attestation, signs `sig_c` and sends `pair/confirm`.<br>Android checks `mac`, `prk_check`, `device_id` and `sig_c`; signs `sig_s`; stores `paired_device`; returns `pair/done`.<br>The client checks `sig_s`, `prk_check`; stores `paired_device`, puts `PRK` in the Keychain and pins the certificate.<br>Both sides discard the secret; Android closes `/v1/pair`, drops TXT `pr` and adds the new pair's hint to TXT `h`.<br>If the relay is enabled, each side calls `POST /v1/pairs` (idempotent). | Relay error → E8, retry in the background when a network is available. |
| 12 | User | A-UI, M-APP / I-APP | Sees "Paired with \<name>" on both devices; the client moves on to CONN-01. |  |
| A1 | User | M-APP / I-APP | PIN flow: chooses "Can't Scan? Use a PIN". | LAN only. |
| A2 | System | M-APP / I-APP | Generates a 6-digit PIN (CSPRNG, uniformly distributed) and shows it for 120 s; browses mDNS for an instance with `pm = 1`. |  |
| A3 | User | A-UI | Chooses "Enter PIN", types the 6 digits and confirms the pairing. |  |
| A4 | System | A-SVC | Opens the pairing window with TXT `pm = 1`. The client connects to `/v1/pair` and sends `pair/hello` with `mode = "pin"`. Both sides use `K_pin` = Argon2id(PIN, `nonce_c` ‖ `nonce_s`) instead of `pairing_secret` in steps 9–11. |  |
| A5 | System | M-APP / I-APP | Checks the offer's `mac` with its own PIN. Wrong → `pair/error PIN_INVALID` with the number of attempts left; third failure → discard the PIN and generate a new one (E7). Correct → continue with steps 10–12. |  |

### 2.1.5 API/service specification

**List of calls**

| # | API/service | Channel | Direction | Used in step |
|---|-------------|------|-------|-------------|
| 1 | QR URI `handlive://pair` | Optical (QR) | Client → Android | 2, 3, 4 |
| 2 | `WS pair/hello` | `/v1/pair` or `rv_msg` | C→S | 9, A4 |
| 3 | `WS pair/offer` | Same as above | S→C | 9 |
| 4 | `WS pair/confirm` | Same as above | C→S | 11 |
| 5 | `WS pair/done` | Same as above | S→C | 11 |
| 6 | `WS pair/error` | Same as above | Both directions | 9, 10, A5 |
| 7 | Relay `rv_join` / `rv_joined` / `rv_msg` | `wss://{RELAY_HOST}/v1/relay` (text) | Device ↔ R-API | 2, 6, 7, 8 |
| 8 | `POST /v1/pairs` | Relay REST | Device → R-API | 11 |
| 9 | Operating system services: `NsdManager.registerService`, `NWBrowser`, ML Kit `BarcodeScanning`, `CIFilter.qrCodeGenerator`, Keychain `SecItemAdd` | Local | — | 2, 3, 6, 7, 11 |

Authentication strings shared by the APIs below:
- `K_pa` = HKDF-SHA256(ikm = `pairing_secret` (or `K_pin`), salt = `nonce_c` ‖ `nonce_s`, info =
  `"handlive/v1/pair-auth"`, L = 32).
- `T_offer` = `"HL1|offer|"` ‖ the fields in a fixed order: `device_id` C(16) ‖ `nonce_c` (32) ‖
  `ik_sig_pub` C(32) ‖ `ik_dh_pub` C(32) ‖ str(`name`C) ‖ `device_id` S(16) ‖ `nonce_s` (32) ‖
  `ik_sig_pub` S(32) ‖ `ik_dh_pub` S(32) ‖ `tls_sha256` (32) ‖ str(`name`S), where str(x) = uint16 BE
  length ‖ UTF-8.
- JSON is never used as signed or HMAC input (to avoid canonicalization differences between Kotlin
  and Swift).

#### API 1 — QR URI `handlive://pair`

- **URL:** `handlive://pair?v=1&pk=<b64u>&ps=<b64u>&d=<name, UTF-8 percent-encoded RFC 3986>[&rv=<b64u>]`
- **Method:** Show the QR code (Mac/iOS) → scan it with ML Kit (Android).
- **Request (parameters):**

| Parameter | Type | Required | Description |
|---------|------|----------|-------|
| `v` | int32 | Yes | Format version, `1` |
| `pk` | b64u (32 bytes) | Yes | The client's `ik_dh_pub` |
| `ps` | b64u (32 bytes) | Yes | `pairing_secret` |
| `d` | string(64) | Yes | Client device name |
| `rv` | b64u (16 bytes) | No | Relay rendezvous code (P2) |

- **Response:** N/A (no direct response; the result comes through API 2–6).
- **Example:**
  `handlive://pair?v=1&pk=q83vEjRWeJC7zN3u_wARIjNEVWZ3iJmqu8zd7v8AESI&ps=AAECAwQFBgcICQoLDA0ODxAREhMUFRYXGBkaGxwdHh8&d=MacBook%20c%E1%BB%A7a%20Lan&rv=Eh8kKS4zOD1CR0xRVltgZQ`
- **Business logic:**
  1. The URI string is ≤ 300 characters so the QR code stays at version ≤ 10 and scans well from a
     Retina screen.
  2. Android ignores unknown parameters (forward compatibility); it rejects the code only when a
     required parameter is missing, a length is wrong or `v` is not `1`.
  3. Every QR refresh creates a new `pairing_secret` and `rv_id`; the old secret is wiped from memory
     immediately.

#### API 2 — `WS pair/hello`

- **URL:** `wss://{android_host}:{port}/v1/pair` (LAN) or an envelope inside `rv_msg` over
  `wss://{RELAY_HOST}/v1/relay`
- **Method:** `WS pair/hello` (C→S), unencrypted payload (0.5.1); the response is `pair/offer`.
- **Request (`data`):**

| Field | Type | Required | Description |
|--------|------|----------|-------|
| `mode` | enum{qr\| pin} | Yes |  |
| `device_id` | uuid | Yes | The client's `device_id` |
| `nonce` | b64u (32 bytes) | Yes | Random `nonce_c` |
| `name` | string(64) | Yes | Client name |
| `platform` | enum{macos\| ios\| ipados} | Yes |  |
| `model` | string(64) | No | For example `Mac15,3`, `iPhone16,1` |
| `ik_sig_pub` | b64u (32 bytes) | Yes | The client's Ed25519 signing key |
| `ik_dh_pub` | b64u (32 bytes) | Yes | Must equal `pk` when `mode = qr` |

- **Response:** `WS pair/offer` (API 3) or `WS pair/error` (API 6).
- **Example (payload plaintext):**

```json
{"op":"hello","data":{"mode":"qr","device_id":"5b1f8c2e-9a4d-8e6f-a1b2-c3d4e5f60718","nonce":"xLwqX2J3v3mYqk9jR0l5b0Y4WmR2bUxHQ3N0RU9mZ1U","name":"MacBook của Lan","platform":"macos","model":"Mac15,3","ik_sig_pub":"7Kx9vQ2mTn4pL8rWz1YcHd6fJb3gSa5eUo0iVtNkQxA","ik_dh_pub":"q83vEjRWeJC7zN3u_wARIjNEVWZ3iJmqu8zd7v8AESI"}}
```

- **Business logic:**
  1. Accepted only while the pairing window is open; outside the window → `pair/error PAIRING_CLOSED`
     and close.
  2. `mode = qr`: `ik_dh_pub` must equal the scanned `pk`, otherwise → `AUTH_FAILED`. `mode = pin`:
     accepted only when the window is open in PIN mode and the connection comes from the LAN (not
     through the relay).
  3. Check `device_id` = UUIDv8(SHA-256(`ik_sig_pub`)); mismatch → `AUTH_FAILED`.
  4. A pairing window serves only one client: a second connection in the same window →
     `PAIRING_CLOSED`.

#### API 3 — `WS pair/offer`

- **URL:** same as API 2
- **Method:** `WS pair/offer` (S→C), unencrypted payload.
- **Request (`data`):**

| Field | Type | Required | Description |
|--------|------|----------|-------|
| `device_id` | uuid | Yes | The Android `device_id` |
| `nonce` | b64u (32 bytes) | Yes | `nonce_s` |
| `name` | string(64) | Yes | Phone name |
| `model` | string(64) | Yes | `Build.MODEL` |
| `os_version` | string | Yes | `Build.VERSION.RELEASE` |
| `ik_sig_pub` | b64u (32 bytes) | Yes |  |
| `ik_dh_pub` | b64u (32 bytes) | Yes |  |
| `tls_sha256` | b64u (32 bytes) | Yes | SHA-256 of A-SVC's TLS certificate (DER) |
| `mac` | b64u (32 bytes) | Yes | HMAC-SHA256(`K_pa`, `T_offer`) |

- **Response:** the client sends `pair/confirm` (API 4) or `pair/error` (API 6).
- **Example:**

```json
{"op":"offer","data":{"device_id":"8c7d6e5f-4a3b-8c2d-9e1f-0a1b2c3d4e5f","nonce":"n3Jz0b1QdX9pVw8yKq2mLc4tRe6uHs5aGf7iJk0oPlM","name":"Pixel của Lan","model":"Pixel 8","os_version":"15","ik_sig_pub":"Zm9vYmFyYmF6cXV4cXV1eHh5enp6MTIzNDU2Nzg5MDE","ik_dh_pub":"cXdlcnR5dWlvcGFzZGZnaGprbHp4Y3Zibm0xMjM0NTY","tls_sha256":"3q2-7wAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA","mac":"hM8Qe1vV0x3bKpZ9aLr2sT5wYc7uJd4nFg6iHk8oPqA"}}
```

- **Business logic:**
  1. Android sends the offer only after the API 2 checks have passed.
  2. `tls_sha256` is protected by `mac`, so even through the relay (where there is no direct TLS
     channel) the client pins the phone's real certificate.
  3. The client checks in this order: `mac` → `device_id` matches `ik_sig_pub` → (LAN) `tls_sha256`
     equals the certificate of the current connection. Any failed check → `AUTH_FAILED`, without
     revealing which check failed.

#### API 4 — `WS pair/confirm`

- **URL:** same as API 2
- **Method:** `WS pair/confirm` (C→S), unencrypted payload; the response is `pair/done`.
- **Request (`data`):**

| Field | Type | Required | Description |
|--------|------|----------|-------|
| `pair_id` | uuid | Yes | UUIDv4 generated by the client |
| `created_at` | timestamp | Yes | Time the pair was created (client clock) |
| `sig` | b64u (64 bytes) | Yes | Ed25519(client `ik_sig`, `attestation`) — the `attestation` structure is in 0.6.2 |
| `prk_check` | b64u (32 bytes) | Yes | HMAC-SHA256(`PRK`, `"HL1\|prk-check-c\|"` ‖ `pair_id`) |
| `mac` | b64u (32 bytes) | Yes | HMAC-SHA256(`K_pa`, `"HL1\|confirm\|"` ‖ `T_offer` ‖ `pair_id` ‖ `created_at` ‖ `sig`) — `pair_id` 16 bytes, `created_at` int64 BE, `sig` 64 raw bytes |

- **Response:** `WS pair/done` (API 5) or `WS pair/error` (API 6).
- **Example:**

```json
{"op":"confirm","data":{"pair_id":"3f2b1c4d-5e6f-4a7b-8c9d-0e1f2a3b4c5d","created_at":1727150003210,"sig":"<b64u 64 byte>","prk_check":"<b64u 32 byte>","mac":"<b64u 32 byte>"}}
```

- **Business logic:**
  1. Android checks `mac` first, then computes `PRK` itself (0.6.2) and compares `prk_check` — this
     catches any implementation mismatch between the two platforms early.
  2. Rebuild `attestation` from the data already held and verify `sig` with the client's
     `ik_sig_pub`.
  3. `|created_at − Android time| > 10 min` → still accepted (clocks may drift), but the value the
     client sent is used unchanged in `attestation`.
  4. Store the pair in one transaction: if a record with the same `peer_device_id` already exists
     (the client is pairing again), delete the old record, then insert the new one.

#### API 5 — `WS pair/done`

- **URL:** same as API 2
- **Method:** `WS pair/done` (S→C), unencrypted payload.
- **Request (`data`):**

| Field | Type | Required | Description |
|--------|------|----------|-------|
| `sig` | b64u (64 bytes) | Yes | Ed25519(Android `ik_sig`, `attestation`) |
| `prk_check` | b64u (32 bytes) | Yes | HMAC-SHA256(`PRK`, `"HL1\|prk-check-s\|"` ‖ `pair_id`) |
| `mac` | b64u (32 bytes) | Yes | HMAC-SHA256(`K_pa`, `"HL1\|done\|"` ‖ `pair_id` ‖ `sig`) — `pair_id` 16 bytes, `sig` 64 raw bytes |

- **Response:** N/A (end of the protocol; the client closes the connection with code 1000).
- **Example:**

```json
{"op":"done","data":{"sig":"<b64u 64 byte>","prk_check":"<b64u 32 byte>","mac":"<b64u 32 byte>"}}
```

- **Business logic:**
  1. The client checks `mac`, `prk_check`, `sig`; any failure → delete all temporary data and report
     E4 (Android, which has already stored the pair, cleans it up by itself when CONN-01 fails with
     `PAIR_UNKNOWN` on the client side — see the PAIR-03 cleanup step).
  2. All valid → the client stores `paired_device`, saves `PRK` in the Keychain (account =
     `pair_id`), and only then reports success to the user.

#### API 6 — `WS pair/error`

- **URL:** same as API 2
- **Method:** `WS pair/error` (both directions), unencrypted payload; the sender closes the
  connection right afterwards.
- **Request (`data`):**

| Field | Type | Required | Description |
|--------|------|----------|-------|
| `code` | enum{QR_INVALID\| PAIRING_CLOSED\| PIN_INVALID\| AUTH_FAILED\| INTERNAL} | Yes | Error code (0.8.1) |
| `message` | string | Yes | Short description that contains no sensitive data |
| `attempts_left` | int32 | Required with `PIN_INVALID`, absent with any other code | Number of attempts left, 0–3 |

- **Response:** N/A.
- **Example:**
  `{"op":"error","data":{"code":"PIN_INVALID","message":"PIN does not match","attempts_left":2}}`
- **Business logic:** With `AUTH_FAILED`, never reveal which check failed; the local log contains
  only the error code.

#### API 7 — Relay rendezvous `rv_join` / `rv_joined` / `rv_msg`

- **URL:** `wss://{RELAY_HOST}/v1/relay` (after JWT authentication — CONN-03)
- **Method:** relay control WS text frame (0.7.3).
- **Request:**

| op | Field | Type | Description |
|----|--------|------|-------|
| `rv_join` | `rv_id` | b64u (16 bytes) | Join the rendezvous |
| `rv_msg` | `rv_id` | b64u (16 bytes) |  |
| `rv_msg` | `env` | object | A `pair` envelope (API 2–6) |

- **Response:**

| op | Field | Type | Description |
|----|--------|------|-------|
| `rv_joined` | `rv_id` | b64u |  |
| `rv_joined` | `peer_present` | bool | Both members are present |
| `error` | `code` | string | `BAD_REQUEST` when the rendezvous already has 2 members or has expired |

- **Example:**

```json
{"op":"rv_join","rv_id":"Eh8kKS4zOD1CR0xRVltgZQ"}
{"op":"rv_joined","rv_id":"Eh8kKS4zOD1CR0xRVltgZQ","peer_present":true}
{"op":"rv_msg","rv_id":"Eh8kKS4zOD1CR0xRVltgZQ","env":{"v":1,"type":"pair","id":"01922229-8b68-78ac-815b-67de8e533f5d","ts":1727150001000,"payload":"eyJvcCI6ImhlbGxvIiwiZGF0YSI6eyJtb2RlIjoicXIiLCJkZXZpY2VfaWQiOiIyMWZlMzFkZi1hMTU0LTgyNjEtYTI2Yi1mODU0MDQ2ZmQyMjciLCJub25jZSI6ImZrUXp1OE5FM1ZxMU1Nd2FqWm44d0wyT0xSOU9haVZKbVF1dU9waV9UR2ciLCJuYW1lIjoiTWFjQm9vayBj4bunYSBMYW4iLCJwbGF0Zm9ybSI6Im1hY29zIiwibW9kZWwiOiJNYWMxNSwzIiwiaWtfc2lnX3B1YiI6IjExcVlBWUt4Q3JmVlNfN1R5V1FIT2c3aGN2UGFwaU1scndJYWFQY0hVUm8iLCJpa19kaF9wdWIiOiJoU0R3Q1lrd3AxUjBpMzNjdEQ3M1dnMl9PZzBtT0JyMDY2U3BqcXFiVG1vIn19"}}
```

- **Business logic:**
  1. A rendezvous lives 180 s and has at most 2 members; a third member is refused.
  2. When the second member joins, the relay sends `rv_joined` (`peer_present = true`) to both.
  3. The relay forwards `env` unchanged to the other member without reading its content; it only
     accepts `env.type = "pair"`.
  4. A `pair/hello` envelope with `mode = "pin"` through the rendezvous is blocked by the relay and
     also rejected by Android (the PIN is LAN-only).

#### API 8 — `POST /v1/pairs`

- **URL:** `https://{RELAY_HOST}/v1/pairs`
- **Method:** `POST`, header `Authorization: Bearer <jwt>`
- **Request:**

| Field | Type | Required | Description |
|--------|------|----------|-------|
| `pair_id` | uuid | Yes |  |
| `device_a` | uuid | Yes | Android |
| `device_b` | uuid | Yes | Mac/iOS |
| `created_at` | timestamp | Yes |  |
| `attestation` | b64u | Yes | Structure per 0.6.2 |
| `sig_a` | b64u (64 bytes) | Yes | Android's signature |
| `sig_b` | b64u (64 bytes) | Yes | The client's signature |

- **Response:**

| HTTP | Body | When |
|------|------|---------|
| 201 | `{"pair_id":"…","created_at":1727150003210}` | Created |
| 200 | Same as above | Already exists with identical data (repeated call) |
| 403 `NOT_PAIRED` | error | The caller is neither `device_a` nor `device_b` |
| 404 `DEVICE_NOT_FOUND` | error | One side has not registered its device yet → retry later |
| 409 `PAIR_EXISTS` | error | `pair_id` already exists with different data |
| 401 `SIGNATURE_INVALID` | error | One of the two signatures is invalid |

- **Example:**

```http
POST /v1/pairs HTTP/1.1
Host: relay.example.com
Authorization: Bearer eyJhbGciOiJIUzI1NiJ9.eyJzdWIiOiI1YjFmOGMyZS05YTRkLThlNmYtYTFiMi1jM2Q0ZTVmNjA3MTgifQ.sig
Content-Type: application/json

{"pair_id":"3f2b1c4d-5e6f-4a7b-8c9d-0e1f2a3b4c5d","device_a":"8c7d6e5f-4a3b-8c2d-9e1f-0a1b2c3d4e5f","device_b":"5b1f8c2e-9a4d-8e6f-a1b2-c3d4e5f60718","created_at":1727150003210,"attestation":"SExQQUlSMT8rHE1ebz9…","sig_a":"<b64u>","sig_b":"<b64u>"}
```

```json
{"pair_id":"3f2b1c4d-5e6f-4a7b-8c9d-0e1f2a3b4c5d","created_at":1727150003210}
```

- **Business logic:**
  1. The JWT's `sub` must be `device_a` or `device_b`.
  2. Both devices must exist and must not be deleted; `ik_sig_pub` is taken from `devices`.
  3. Parse `attestation` and match it against `pair_id`, `device_a`, `device_b`, `created_at` and the
     two public keys; verify `sig_a` and `sig_b`.
  4. Idempotent write: insert if absent; if present, compare `attestation` — identical → 200,
     different → 409.
  5. Success → the device sets `relay_registered = 1`.

#### Query

```sql
-- [Design] Android, step 4: count the active pairs (limit 8)
SELECT COUNT(*) AS active_pairs
FROM paired_device
WHERE revoked_at IS NULL;

-- [Design] Android, step 11 (one transaction): replace the same client's old pair, then insert the new pair
DELETE FROM paired_device WHERE peer_device_id = :peer_device_id;
INSERT INTO paired_device (pair_id, peer_device_id, peer_name, peer_platform, peer_model,
                           peer_ik_sig_pub, peer_ik_dh_pub, prk_enc, attestation,
                           sig_self, sig_peer, created_at)
VALUES (:pair_id, :peer_device_id, :peer_name, :peer_platform, :peer_model,
        :peer_ik_sig_pub, :peer_ik_dh_pub, :prk_enc, :attestation,
        :sig_self, :sig_peer, :created_at);

-- [Design] Mac/iOS, step 1: check whether an active pair already exists
SELECT pair_id, peer_name
FROM paired_device
WHERE revoked_at IS NULL
LIMIT 1;

-- [Design] Mac/iOS, step 11: store the pair (PRK is stored separately in the Keychain)
INSERT INTO paired_device (pair_id, peer_device_id, peer_name, peer_model, peer_ik_sig_pub,
                           peer_ik_dh_pub, peer_tls_sha256, attestation, sig_self, sig_peer,
                           last_host, last_port, created_at)
VALUES (:pair_id, :peer_device_id, :peer_name, :peer_model, :peer_ik_sig_pub,
        :peer_ik_dh_pub, :peer_tls_sha256, :attestation, :sig_self, :sig_peer,
        :last_host, :last_port, :created_at);

-- [Design] Relay, API 8: get the public keys of the two devices
SELECT device_id, ik_sig_pub
FROM devices
WHERE device_id IN ($1, $2) AND revoked_at IS NULL;

-- [Design] Relay, API 8: idempotent pair write
INSERT INTO pairs (pair_id, device_a, device_b, attestation, sig_a, sig_b, created_at)
VALUES ($1, $2, $3, $4, $5, $6, to_timestamp($7 / 1000.0))
ON CONFLICT (pair_id) DO NOTHING
RETURNING pair_id;

-- [Design] Relay, API 8: when the INSERT returns no row, compare with the existing record
SELECT device_a, device_b, attestation
FROM pairs
WHERE pair_id = $1;
```

```text
# [Design] Redis, API 7: pairing rendezvous
SADD    rv:<rv_id> <device_id>
EXPIRE  rv:<rv_id> 180
SCARD   rv:<rv_id>          # > 2 → refuse and SREM the member just added
SMEMBERS rv:<rv_id>         # find the other member to forward rv_msg to
```

---

## 2.2 PAIR-02 — View the device list and connection status

### 2.2.1 General information

| Item | Content |
|-----|----------|
| Name | PAIR-02 — View the device list and connection status |
| Description | Shows the paired devices with their live connection status, the channel in use (LAN, internet, USB), the last connection, the version, the active features and the permissions missing on the phone.<br>Android sees a list of up to 8 clients; Mac/iOS sees one phone.<br>From this screen the user goes to PAIR-01 (add), PAIR-03 (unpair) or SET-02 (options).<br>It also checks with the relay to detect pairs that were revoked from another device. |
| Actors | Primary: User. System: A-UI, A-SVC, M-APP / I-APP, R-API. |
| Preconditions | The app has completed initial setup (SET-01 or SET-03). |
| Postconditions | The list shown matches the local data and the current connection status; pairs revoked remotely (if detected) are cleaned up per PAIR-03. No other data changes. |
| Exceptions | E1 — No pairs yet: show the empty state and the "Add Device" button.<br>E2 — The relay is unreachable: show local data only, without a blocking error.<br>E3 — The relay reports a pair as revoked: clean up that pair (PAIR-03, flow B) and show "\<name> was unpaired from another device".<br>E4 — Database read error: show an error and allow a retry. |
| Special requirements | The status updates within ≤ 1 s after the connection changes (by observing the state stream, not by polling).<br>Keys, `pair_id` and full fingerprints are never shown; the "Security Code" is only the first 8 hex characters of SHA-256(`attestation`), so that the user can compare it between the two devices if they want to.<br>Readable with VoiceOver/TalkBack. |

### 2.2.2 Screens

N/A — no approved wireframe yet.

### 2.2.3 Component details

| # | Field | Data type | Input/Output | Initial value | Description |
|---|--------|--------------|--------------|------------------|-------|
| 1 | Device name | string(64) | Output | `peer_name` | The peer's name at pairing time |
| 2 | Device type | enum{android\| macos\| ios\| ipados} | Output | `peer_platform` or `android` | With an icon |
| 3 | Model | string(64) | Output | `peer_model` | Label "Model" |
| 4 | Connection status | enum{connected\| connecting\| peer_offline\| disconnected} | Output | Per 0.11 | "Connected via Wi-Fi" (or "over the internet", "via USB"), "Connecting…", "Phone offline", "Disconnected" |
| 5 | Connection channel | enum{lan\| relay\| usb} | Output | Empty when not connected | "LAN", "Internet", "USB" |
| 6 | Last connected | timestamp | Output | `last_seen_at` | Label "Last Connected"; shown as relative time ("2 minutes ago") |
| 7 | Peer app version | string | Output | From `capability.app_version` | Label "App Version"; warning if the protocol version differs |
| 8 | Active features | array<enum{clipboard\| sms\| call\| call_audio\| camera}> | Output | Intersection of the two capabilities | Each item carries a reason when it is inactive ("Off on Mac", "Missing SMS permission on the phone")<br>Label "Features" |
| 9 | Permissions missing on the phone | array\<string> | Output | `permissions_missing` | Mac/iOS only; select to see instructions |
| 10 | Security Code | string(8) | Output | First 8 lowercase hex characters of SHA-256(`attestation`) | Identical on both devices of the same pair; exists once pairing finishes (it depends on the `pair_id` and `created_at` of `pair/confirm`), shown on the pairing result and in the device details |
| 11 | "Add Device" button | action | Input | — | Opens PAIR-01; hidden on Mac/iOS when a pair already exists<br>Empty list on Android: "No Devices Yet" · "Pair a Mac, iPhone, or iPad to share the clipboard with this phone." |
| 12 | "Unpair" button | action | Input | — | Opens PAIR-03 |

### 2.2.4 Business flow

```mermaid
flowchart TB
  subgraph ND["User"]
    U1["(1) Open the Devices screen"]
    U6["(6) View details or choose an action"]
  end
  subgraph HT["System"]
    S2["(2) Read paired_device and the connection status"]
    D3{"(3) Any pair?"}
    S4["(4) Relay enabled and online: GET /v1/pairs"]
    D5{"(5) Any revoked pair?"}
    S5a["(5a) Clean up the pair per PAIR-03 flow B, tell the user"]
    S5b["(5b) Show the list, watch for status changes"]
    X1(["Show the empty state and the Add Device button"])
  end
  U1 --> S2 --> D3
  D3 -- "No (E1)" --> X1
  D3 -- "Yes" --> S4 --> D5
  D5 -- "Yes (E3)" --> S5a --> S5b
  D5 -- "No or relay error (E2)" --> S5b
  S5b --> U6
```

| Step | Actor | Component | Description | Exceptions / Notes |
|------|----------|-----------|-------|--------------------|
| 1 | User | A-UI / M-APP / I-APP | Opens "Devices" (Android: Devices tab; Mac: menu bar → Devices; iOS: Settings tab → Phone). |  |
| 2 | System | A-UI / M-APP / I-APP | Reads the active `paired_device` rows; gets the status from the connection manager (Android: the open sessions by `pair_id`; client: the 0.11 state machine) and the latest capability (`features_json`). | DB read error → E4. |
| 3 | System | Same as above | No pair → show the empty state. | E1. |
| 4 | System | A-SVC / M-APP / I-APP, R-API | If `relay.enabled` and the internet is available: call `GET /v1/pairs` (at most once every 60 s to avoid unnecessary calls). | Network error → E2, skip. |
| 5 | System | Same as above | Compares each local pair with the relay's result: a pair with a non-null `revoked_at` → 5a; none → 5b. | Relay error → E2, go to 5b. |
| 5a | System | Same as above | Cleans up the revoked pair per PAIR-03 flow B (delete the keys and synced data) and shows "\<name> was unpaired from another device". | E3. |
| 5b | System | Same as above | Shows the list and subscribes to connection status and capability changes so it updates within ≤ 1 s. |  |
| 6 | User | Same as above | Views a device's details; chooses "Add Device" (PAIR-01), "Unpair" (PAIR-03) or "Options" (SET-02). |  |

### 2.2.5 API/service specification

**List of calls**

| # | API/service | Channel | Direction | Used in step |
|---|-------------|------|-------|-------------|
| 1 | `GET /v1/pairs` | Relay REST | Device → R-API | 4 |
| 2 | Internal connection status stream (Kotlin `StateFlow`, Swift `AsyncStream`) | Local | — | 2, 5 |

The capability shown in fields 7–9 comes from the `capability/hello` and `capability/update` messages
already received in CONN-01 and SET-02; no new call is made.

#### API 1 — `GET /v1/pairs`

- **URL:** `https://{RELAY_HOST}/v1/pairs`
- **Method:** `GET`, header `Authorization: Bearer <jwt>`
- **Request:** no body. Optional query parameter `include_revoked` (bool, default `true`).
- **Response 200:**

| Field | Type | Description |
|--------|------|-------|
| `pairs` | array\<object> | The pairs the calling device is a member of |
| `pairs[].pair_id` | uuid |  |
| `pairs[].peer_device_id` | uuid | The other device |
| `pairs[].peer_platform` | enum{android\| macos\| ios\| ipados} |  |
| `pairs[].created_at` | timestamp |  |
| `pairs[].revoked_at` | timestamp \| null | Non-null means revoked |
| `pairs[].peer_online` | bool | The peer is connected to the relay (per presence) |

- **Example:**

```json
{"pairs":[{"pair_id":"3f2b1c4d-5e6f-4a7b-8c9d-0e1f2a3b4c5d","peer_device_id":"8c7d6e5f-4a3b-8c2d-9e1f-0a1b2c3d4e5f","peer_platform":"android","created_at":1727150003210,"revoked_at":null,"peer_online":true}]}
```

- **Business logic:**
  1. Only pairs in which the JWT's `sub` is `device_a` or `device_b` are returned.
  2. `peer_online` is read from the `presence:<peer_device_id>` key in Redis.
  3. A pair that exists on the device but **not** on the relay (as opposed to one that has
     `revoked_at`) is not treated as revoked. If `relay_registered = 1`, the peer has removed itself
     from the relay ("Remove Device from Server", SET-02) → set `relay_registered = 0`, keep the pair
     and use LAN/USB only. Every pair with `relay_registered = 0` retries `POST /v1/pairs` (PAIR-01
     API 8) when a network is available; a 404 `DEVICE_NOT_FOUND` response (the peer has not
     registered again yet) → retry after 24 h.

#### Query

```sql
-- [Design] Android, step 2: list of paired clients
SELECT pair_id, peer_device_id, peer_name, peer_platform, peer_model,
       features_json, attestation, last_seen_at
FROM paired_device
WHERE revoked_at IS NULL
ORDER BY COALESCE(last_seen_at, created_at) DESC;

-- [Design] Mac/iOS, step 2: the paired phone
SELECT pair_id, peer_device_id, peer_name, peer_model, features_json,
       attestation, last_seen_at, last_host
FROM paired_device
WHERE revoked_at IS NULL
LIMIT 1;

-- [Design] Relay, API 1
SELECT p.pair_id,
       CASE WHEN p.device_a = $1 THEN p.device_b ELSE p.device_a END AS peer_device_id,
       d.platform AS peer_platform,
       p.created_at, p.revoked_at
FROM pairs p
JOIN devices d ON d.device_id = CASE WHEN p.device_a = $1 THEN p.device_b ELSE p.device_a END
WHERE (p.device_a = $1 OR p.device_b = $1)
  AND ($2::boolean OR p.revoked_at IS NULL)
ORDER BY p.created_at DESC;
```

```text
# [Design] Redis, API 1: presence of each peer
MGET presence:<peer_device_id_1> presence:<peer_device_id_2> ...
```

---

## 2.3 PAIR-03 — Unpair a device (locally and remotely)

### 2.3.1 General information

| Item | Content |
|-----|----------|
| Name | PAIR-03 — Unpair a device (locally and remotely) |
| Description | Ends the trust relationship of a pair.<br>**Flow A (both are connected):** the initiator sends `pair/revoke`, the other side acknowledges, and both delete the keys and data.<br>**Flow B (the peer can't be reached, for example a lost device):** the initiator deletes locally and revokes on the relay; the peer cleans up by itself when it is back online (the relay sends `pair_revoked`, or Android returns `PAIR_UNKNOWN` on the LAN).<br>Synced data (SMS, call log) on Mac/iOS is deleted together with the pair. |
| Actors | Primary: User. System: A-UI, A-SVC, M-APP / I-APP, R-API, R-KV. |
| Preconditions | At least one active pair exists; the user is in PAIR-02. |
| Postconditions | **Initiator:** no `PRK`, pair record or synced data of the pair remains; Android removes the pair's hint from TXT `h`; the relay marks `revoked_at` (immediately or once a network is available).<br>**Peer:** cleans up in exactly the same way when it receives the revocation signal. The pair's `/v1/ctl` session is closed. |
| Exceptions | E1 — The user cancels in the confirmation dialog.<br>E2 — The peer does not answer with an `ack` within 10 s → switch to flow B.<br>E3 — The relay is unreachable → keep a "tombstone" record (`revoked_at` set, data and keys already deleted) and retry the revocation in the background whenever a network is available.<br>E4 — The pair was already revoked on the relay → treat it as success. |
| Special requirements | Security: delete `PRK` from Keychain/Keystore before reporting success; no undo (using the pair again requires a new pairing).<br>The confirmation dialog states clearly which data will be deleted.<br>Performance: flow A completes in ≤ 2 s.<br>A remote revocation takes effect on the relay as soon as the `POST` succeeds: the relay stops forwarding and pushing for that pair. |

### 2.3.2 Screens

N/A — no approved wireframe yet.

### 2.3.3 Component details

| # | Field | Data type | Input/Output | Initial value | Description |
|---|--------|--------------|--------------|------------------|-------|
| 1 | Device to unpair | string(64) | Output | Name of the device selected in PAIR-02 |  |
| 2 | Warning text | string | Output | "Unpairing deletes the security keys and the SMS messages and call history synced to \<client device>. This can't be undone." |  |
| 3 | Unpair confirmation | enum{Unpair\| Cancel} | Input | — | Mac: an alert shown as a sheet, "Unpair" is the default button (not red, because the user chose it deliberately), "Cancel" on the left; iPhone/iPad and Android: an action sheet with a red "Unpair" at the top and "Cancel" at the bottom |
| 4 | Result | enum{done\| done_pending_remote} | Output | — | `done`: both sides have cleaned up, shows "Unpaired"; `done_pending_remote`: cleaned up locally, the other device will clean up by itself when it reconnects, shows "Unpaired; \<device> will clean up when it reconnects" |
| 5 | Message on the peer | string | Output | — | "\<name> unpaired this device" |

### 2.3.4 Business flow

```mermaid
flowchart TB
  subgraph ND["User"]
    U1["(1) Choose Unpair"]
    U2["(2) Confirm in the dialog"]
    U10["(10) See the result"]
  end
  subgraph HT["System"]
    D3{"(3) Is there a /v1/ctl session?"}
    S4["(4) Send pair/revoke"]
    D5{"(5) ack received within 10 s?"}
    S6["(6) Peer deletes keys and data, closes the session"]
    S7["(7) Initiator deletes PRK and data, sets a tombstone"]
    S8["(8) POST /v1/pairs/id/revoke"]
    S9["(9) Relay sends pair_revoked to the peer if online, tombstone deleted"]
    X1(["End: nothing changes"])
  end
  U1 --> U2
  U2 -- "Cancel (E1)" --> X1
  U2 -- "Unpair" --> D3
  D3 -- "Yes" --> S4 --> D5
  D5 -- "Yes" --> S6 --> S7
  D5 -- "No (E2)" --> S7
  D3 -- "No (flow B)" --> S7
  S7 --> S8 --> S9 --> U10
```

| Step | Actor | Component | Description | Exceptions / Notes |
|------|----------|-----------|-------|--------------------|
| 1 | User | A-UI / M-APP / I-APP | In PAIR-02, chooses "Unpair" for a device. |  |
| 2 | User | Same as above | Reads the warning and chooses "Unpair". | "Cancel" → E1. |
| 3 | System | Same as above | Checks for the pair's `/v1/ctl` session (LAN, USB or relay). | None → flow B, go to step 7. |
| 4 | System | Same as above | Sends `pair/revoke` `{pair_id, reason: "user"}` (encrypted envelope). |  |
| 5 | System | Same as above | Waits up to 10 s for the `ack`. | Timeout → E2, flow B. |
| 6 | System | Peer device | Returns the `ack`, then cleans up on its side as in step 7; shows field 5; sends `session/bye` and closes with 1000. |  |
| 7 | System | Initiator | Deletes `PRK` (Keychain `SecItemDelete` / clears the `prk_enc` column), deletes the pair's synced data (client) and sets `revoked_at`; Android re-registers mDNS without the pair's hint. |  |
| 8 | System | Initiator, R-API | If the pair is registered with the relay: `POST /v1/pairs/{pair_id}/revoke`. | No network → E3, keep the tombstone, retry in the background. The relay reports it as already revoked → E4. |
| 9 | System | R-API, R-KV | The relay sets `revoked_at` and stops forwarding and pushing; if the peer is connected to the relay, it sends the `pair_revoked` op so the peer cleans up right away. The initiator deletes the tombstone record for good. | Peer offline: it receives `pair_revoked` when it connects to the relay, or sees the revocation through `GET /v1/pairs` (PAIR-02), or Android rejects its `session/hello` with `PAIR_UNKNOWN` on the LAN. |
| 10 | User | Same as above | Sees the result `done` or `done_pending_remote`. |  |

### 2.3.5 API/service specification

**List of calls**

| # | API/service | Channel | Direction | Used in step |
|---|-------------|------|-------|-------------|
| 1 | `WS pair/revoke` | `/v1/ctl` (LAN, USB or relay) | Both directions | 4, 5, 6 |
| 2 | `WS session/bye` | `/v1/ctl` | Both directions | 6 |
| 3 | `POST /v1/pairs/{pair_id}/revoke` | Relay REST | Device → R-API | 8 |
| 4 | Relay op `pair_revoked` | `wss://{RELAY_HOST}/v1/relay` (text) | R-API → device | 9 |
| 5 | Operating system services: `SecItemDelete` (Keychain), `NsdManager.unregisterService` + `registerService` | Local | — | 7 |

#### API 1 — `WS pair/revoke`

- **URL:** `wss://{android_host}:{port}/v1/ctl` or through the relay
- **Method:** `WS pair/revoke` (both directions), encrypted envelope, with ack.
- **Request (`data`):**

| Field | Type | Required | Description |
|--------|------|----------|-------|
| `pair_id` | uuid | Yes | Must match the pair of the current session |
| `reason` | enum{user\| reinstall\| limit} | Yes | `user`: the user's own choice; `reinstall`: the app data was deleted; `limit`: replacing an old pair when pairing a new one |

- **Response (`ack.data`):** `{}` when `ok = true`. Error: `BAD_REQUEST` if `pair_id` does not match
  the session.
- **Example:**

```json
{"op":"revoke","data":{"pair_id":"3f2b1c4d-5e6f-4a7b-8c9d-0e1f2a3b4c5d","reason":"user"}}
{"re":"0192f3d8-2b11-7c42-8e5a-6b7c8d9e0f12","ok":true,"data":{}}
```

- **Business logic:**
  1. The receiver returns the `ack` **before** deleting the keys (after deletion it can no longer
     encrypt).
  2. After the `ack`, the receiver cleans up its data, sends `session/bye` `{reason: "revoked"}` and
     closes with code 1000.
  3. Unpairing cannot be "refused": either side may unpair unilaterally.

#### API 2 — `WS session/bye`

- **URL:** same as API 1
- **Method:** `WS session/bye` (both directions), encrypted envelope, no ack.
- **Request (`data`):** `reason` — enum{revoked\|shutdown\|replaced\|update}.
- **Response:** N/A; the sender closes the WebSocket with code 1000.
- **Example:** `{"op":"bye","data":{"reason":"revoked"}}`
- **Business logic:** A receiver of `reason = revoked` cleans up the pair if it has not done so yet
  (in case `pair/revoke` was lost).

#### API 3 — `POST /v1/pairs/{pair_id}/revoke`

- **URL:** `https://{RELAY_HOST}/v1/pairs/{pair_id}/revoke`
- **Method:** `POST`, header `Authorization: Bearer <jwt>`
- **Request:**

| Field | Type | Required | Description |
|--------|------|----------|-------|
| `reason` | enum{user\| reinstall\| lost_device} | Yes | `lost_device` when the user chooses to unpair remotely while the peer is offline |

- **Response:**

| HTTP | Body | When |
|------|------|---------|
| 204 | — | Revoked successfully, or already revoked earlier (idempotent) |
| 403 `NOT_PAIRED` | error | The caller is not a member of the pair |
| 404 `DEVICE_NOT_FOUND` | error | `pair_id` does not exist → treated as success on the device side |

- **Example:**

```http
POST /v1/pairs/3f2b1c4d-5e6f-4a7b-8c9d-0e1f2a3b4c5d/revoke HTTP/1.1
Host: relay.example.com
Authorization: Bearer <jwt>
Content-Type: application/json

{"reason":"lost_device"}
```

- **Business logic:**
  1. Only a member of the pair can revoke it.
  2. Update `revoked_at`, `revoked_by`; if already revoked, change nothing and still return 204.
  3. Look up `presence:<peer>`; if the peer is online, publish `pair_revoked` on the `dev:<peer>`
     channel.
  4. From this moment the relay refuses every `to`/`from` frame between the two devices of the pair
     (`relay.error NOT_PAIRED`) and refuses `POST /v1/push` for the pair.

#### API 4 — Relay op `pair_revoked`

- **URL:** `wss://{RELAY_HOST}/v1/relay`
- **Method:** control WS text frame (R-API → device). Added to the 0.7.3 catalog.
- **Request:** `{"op":"pair_revoked","pair_id":"<uuid>","by":"<device_id>"}`
- **Response:** N/A.
- **Example:**
  `{"op":"pair_revoked","pair_id":"3f2b1c4d-5e6f-4a7b-8c9d-0e1f2a3b4c5d","by":"8c7d6e5f-4a3b-8c2d-9e1f-0a1b2c3d4e5f"}`
- **Business logic:**
  1. The receiving device cleans up the pair as in step 7 and shows field 5; a repeated message is
     ignored.
  2. Right after a device connects to the relay, the relay sends `pair_revoked` for every pair revoked
     within the last 30 days that the device is a member of, so that a device that was offline at
     revocation time still cleans up by itself.

#### Query

```sql
-- [Design] Android, step 7: set the tombstone and delete the key
UPDATE paired_device
SET revoked_at = :now, prk_enc = X'', features_json = '{}'
WHERE pair_id = :pair_id;

-- [Design] Android, step 9: delete for good once the relay has confirmed or if the pair was never registered with the relay
DELETE FROM paired_device
WHERE pair_id = :pair_id AND revoked_at IS NOT NULL;

-- [Design] Mac/iOS, step 7 (one transaction): delete the synced data and set the tombstone
DELETE FROM sms_message    WHERE pair_id = :pair_id;
DELETE FROM sms_thread     WHERE pair_id = :pair_id;
DELETE FROM sms_outbox     WHERE pair_id = :pair_id;
DELETE FROM call_log_entry WHERE pair_id = :pair_id;
DELETE FROM sync_cursor    WHERE pair_id = :pair_id;
UPDATE paired_device SET revoked_at = :now WHERE pair_id = :pair_id;

-- [Design] All platforms: find tombstones that still need revoking on the relay (runs when a network is available)
SELECT pair_id FROM paired_device
WHERE revoked_at IS NOT NULL AND relay_registered = 1;

-- [Design] Relay, API 3
UPDATE pairs
SET revoked_at = now(), revoked_by = $2
WHERE pair_id = $1
  AND (device_a = $2 OR device_b = $2)
  AND revoked_at IS NULL
RETURNING CASE WHEN device_a = $2 THEN device_b ELSE device_a END AS peer_device_id;

-- [Design] Relay, API 4: pairs of the device that just connected, revoked within the last 30 days
SELECT pair_id, revoked_by
FROM pairs
WHERE (device_a = $1 OR device_b = $1)
  AND revoked_at > now() - INTERVAL '30 days';
```

```text
# [Design] Redis, API 3: notify the peer if it is online
GET     presence:<peer_device_id>
PUBLISH dev:<peer_device_id> {"op":"pair_revoked","pair_id":"<pair_id>","by":"<device_id>"}
```
