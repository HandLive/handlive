# Báo cáo T0.1 [test] — CI GitHub Actions

Ngày: 2026-09-25 · Nhánh: `feat/phase-00-khung` · Chưa commit.

## Việc đã làm

Bốn workflow trong `.github/workflows/`. Chung cho cả bốn:
- Kích hoạt khi `push` hoặc `pull_request` vào `main` và `feat/**`.
- Lọc theo đường dẫn: thư mục nền tảng, `shared/**` và chính file workflow.
- `permissions: contents: read`.
- `concurrency: ${{ github.workflow }}-${{ github.ref }}` với `cancel-in-progress: true`.
- Action ghim theo major version.
- Không dùng secret nào. Giá trị môi trường đều là giá trị giả của CI.

| File | Runner | Job / bước |
|------|--------|------------|
| `ci-android.yml` | `ubuntu-latest` | `actions/setup-java@v5` (temurin 21); `android-actions/setup-android@v3` (`platform-tools platforms;android-36`, chấp nhận license để AGP tự tải build-tools); `gradle/actions/setup-gradle@v5` (cache `~/.gradle`, kiểm checksum wrapper; chỉ ghi cache trên `main`/`feat/*`); `cd android && ./gradlew check --stacktrace` (test + Android Lint + ktlint + detekt); khi lỗi thì upload `android/**/build/reports/` và `build/test-results/` (giữ 7 ngày) |
| `ci-apple.yml` | `macos-15` + `maxim-lobanov/setup-xcode@v1` (`latest-stable`) | In phiên bản Xcode/Swift; `actions/cache@v4` cho DerivedData (khóa = hash `apple/Packages/*/Package.swift` + `apple/project.yml`); `xcodebuild test -scheme <Pkg> -destination 'platform=macOS'` chạy trong từng thư mục `apple/Packages/{HLProtocol,HLCrypto,HLTransport,HLDesignSystem}`; `brew install xcodegen swiftlint`; `swiftlint lint --strict` (trong `apple/`); `xcodegen generate` + `xcodebuild -list`; `xcodebuild build -project apple/HandLive.xcodeproj -scheme HandLive -destination 'generic/platform=macOS' CODE_SIGNING_ALLOWED=NO`.<br>Không đặt `HL_SWIFT_TESTING_PACKAGE` |
| `ci-relay.yml` | `ubuntu-latest` | Job `lint-test`: `dtolnay/rust-toolchain@stable` (clippy, rustfmt), `Swatinem/rust-cache@v2` (`workspaces: relay`), `cargo fmt --check`, `cargo clippy --all-targets -- -D warnings`, `cargo test`.<br>Job `integration`: service `postgres:16-alpine` + `redis:7-alpine` có healthcheck, cổng host 55432/56379 như `docker-compose.yml`, env giống `.env.example` (`RELAY_JWT_SECRET` là chuỗi giả ghi rõ "ci-only-placeholder-not-a-secret"), `cargo test -- --ignored` |
| `ci-shared.yml` | `ubuntu-latest` | `actions/setup-python@v6` (3.14, cache pip theo 2 file requirements); cài `tools/vectors/requirements.txt` + `tools/schemas/requirements.txt` (đã ghim phiên bản); `verify_vectors.py`, `generate_vectors.py --check`, `check_schemas.py`, `validate_design_docs.py` |

### Quyết định

1. **Tách `ci-shared.yml`, không gộp vào `ci-relay`.** Bốn script này kiểm `shared/` và
   `docs/detailed-design/`, không liên quan relay. Nếu đặt trong `ci-relay`, sửa tài liệu
   (`docs/detailed-design/**`) hay `tools/**` sẽ không kích hoạt được, vì bộ lọc đường dẫn của relay
   không phủ các thư mục đó. Mở rộng bộ lọc thì mỗi lần sửa tài liệu lại chạy luôn cargo. Tách riêng
   thì workflow nhẹ (Python, khoảng 1 phút) và có bộ lọc riêng: `shared/**`, `tools/**`,
   `docs/detailed-design/**` (`check_schemas.py` đọc ví dụ trong `docs/detailed-design/`).
2. **Test Apple: `xcodebuild test` chạy trong thư mục package, không dùng `swift test` hay `-workspace`.**
   - Chọn `xcodebuild` vì thẻ việc ghi `xcodebuild test`. Nó cũng chắc chắn biên dịch asset catalog
     của HLDesignSystem (actool) và các khối `#Preview`: đây chính là phần M0.2 chưa kiểm được tại
     máy.
   - Chạy trong thư mục package vì không phụ thuộc vào `.xcodeproj` sinh ra. Package chỉ có một
     product trùng tên nên xcodebuild tự sinh scheme `<Pkg>` kèm test target.
   - Bốn package chạy nối tiếp trong một job (vòng lặp có `::group::`), mỗi package có
     `-derivedDataPath` riêng nằm dưới thư mục được cache.
3. **Có workflow Android mà `shared/**
   ` không kích hoạt?** Không có. Test của cả ba nền tảng đều đọc ` shared/test-vectors` hoặc
   `shared/schemas`, và relay đọc `device-id.json`. Vì vậy `shared/**` kích hoạt cả bốn workflow.
4. **Android dùng `./gradlew check`** chứ không `test lint` như dòng T0.1 trong phase-00. Theo báo
   cáo A0.1, `check` = test + lint + ktlintCheck + detekt, bao trọn `test lint`.

## Đường dẫn tạo/sửa

- Tạo: `.github/workflows/ci-android.yml`, `.github/workflows/ci-apple.yml`,
  `.github/workflows/ci-relay.yml`, `.github/workflows/ci-shared.yml`
- Tạo: báo cáo này. Không sửa file nào khác.
- Phụ: `xcodegen generate` sinh lại `apple/HandLive.xcodeproj`. Thư mục này nằm trong `.gitignore`,
  không ảnh hưởng gì.

## Lệnh test và kết quả (đầu ra thật)

```
$ actionlint --version
1.7.12
$ actionlint .github/workflows/*.yml; echo "actionlint exit=$?"
actionlint exit=0
```

Relay (rustc 1.98.1, tương đương job `lint-test`):

```
$ cd relay && cargo fmt --check && echo FMT_OK && cargo clippy --all-targets -- -D warnings && cargo test
FMT_OK
    Finished `dev` profile [unoptimized + debuginfo] target(s) in 0.77s
     Running tests/challenge_and_token_proof.rs
test result: ok. 6 passed; 0 failed; 0 ignored; 0 measured; 0 filtered out; finished in 0.00s
     Running tests/db_auth_and_jwt.rs
test result: ok. 0 passed; 0 failed; 4 ignored; 0 measured; 0 filtered out; finished in 0.00s
     Running tests/db_schema_and_registration.rs
test result: ok. 0 passed; 0 failed; 2 ignored; 0 measured; 0 filtered out; finished in 0.00s
     Running tests/device_identity_vectors.rs
test result: ok. 3 passed; 0 failed; 0 ignored; 0 measured; 0 filtered out; finished in 0.00s
     Running tests/error_responses.rs
test result: ok. 3 passed; 0 failed; 0 ignored; 0 measured; 0 filtered out; finished in 0.00s
     Running tests/jwt_tokens.rs
test result: ok. 5 passed; 0 failed; 0 ignored; 0 measured; 0 filtered out; finished in 0.00s
     Running tests/registration_validation.rs
test result: ok. 5 passed; 0 failed; 0 ignored; 0 measured; 0 filtered out; finished in 0.00s
     Running tests/signature_verification.rs
test result: ok. 4 passed; 0 failed; 0 ignored; 0 measured; 0 filtered out; finished in 0.00s
```

Relay tích hợp (tương đương job `integration`; tại máy dùng docker compose thay service container):

```
$ cd relay && docker compose up -d --wait && set -a && . ./.env.example && set +a && cargo test -- --ignored; docker compose down -v
 Container handlive-relay-dev-redis-1 Healthy
 Container handlive-relay-dev-postgres-1 Healthy
     Running tests/db_auth_and_jwt.rs
test rate_limit_and_body_errors ... ok
test challenge_token_and_jwt_extractor ... ok
test jwt_rejections ... ok
test expired_challenge_and_wrong_signature ... ok
test result: ok. 4 passed; 0 failed; 0 ignored; 0 measured; 0 filtered out; finished in 0.27s
     Running tests/db_schema_and_registration.rs
test schema_matches_spec_tables_and_indexes ... ok
test register_then_refresh ... ok
test result: ok. 2 passed; 0 failed; 0 ignored; 0 measured; 0 filtered out; finished in 0.14s
 Volume handlive-relay-dev_pgdata Removed
 Network handlive-relay-dev_default Removed
```

shared/ + tài liệu (`tools/.venv/bin/python`, Python 3.14.7, tương đương `ci-shared.yml`):

```
$ python tools/vectors/verify_vectors.py
OK  stream-keys.json            2 vector,  3 vector âm,  27 phép kiểm
OK  x25519.json                 6 vector,  0 vector âm,   6 phép kiểm
OK  xchacha20-poly1305.json     3 vector,  4 vector âm,  22 phép kiểm
Tổng: 360 phép kiểm, 0 lỗi                                    (exit=0)
$ python tools/vectors/generate_vectors.py --check
THỪA (không do script sinh): envelope-roundtrip-apple.json
THỪA (không do script sinh): envelope-roundtrip.json
check: 14 file, 0 lệch                                        (exit=0)
$ python tools/schemas/check_schemas.py
  payload bắt tay giải từ envelope: 1
  mẫu dương tự viết: 13
  mẫu âm bị từ chối: 36
  XANH: mọi kiểm tra đạt                                      (exit=0)
$ python tools/docs/validate_design_docs.py
files=8 leaves=33 problems=0                                  (exit=0)
```

Dòng "THỪA" chỉ là thông tin: hai file roundtrip do Android và Apple ghi, script không sinh. Lệnh
vẫn exit 0.

Apple (chỉ phần chạy được với Command Line Tools):

```
$ cd apple && xcodegen generate
⚙️  Writing project...
Created project at /Users/hxd/HandLive/apple/HandLive.xcodeproj
$ TOOLCHAIN_DIR=/Library/Developer/CommandLineTools swiftlint lint --strict
Done linting! Found 0 violations, 0 serious in 63 files.      (exit=0)
```

Ba lỗi `swiftlint --strict` ghi trong báo cáo M0.1 đã hết.

## Phần chỉ xác nhận được khi đẩy lên GitHub

Kho không có remote nên chưa run workflow nào thật. Chưa kiểm được:

1. **Android**: `./gradlew check` trên runner. Theo yêu cầu, không chạy Gradle tại máy; điều phối
   viên tự chạy. Cũng chưa kiểm việc `setup-android` cài `platforms;android-36` và AGP 9.4.1 tự tải
   build-tools trên `ubuntu-latest`.
2. **Apple**: toàn bộ `xcodebuild`, vì máy không có Xcode:
   - `xcodebuild test` cho 4 package, gồm asset catalog, `#Preview` và Testing đi kèm Xcode khi
     không có `HL_SWIFT_TESTING_PACKAGE`.
   - Build app `HandLive`.
   - Phiên bản Xcode mà `latest-stable` chọn trên `macos-15`.
   - **Rủi ro cụ thể:** `project.yml` không khai báo `schemes:`, và `xcodegen generate` không sinh
     file `.xcscheme` nào (đã kiểm: `find apple/HandLive.xcodeproj -name '*.xcscheme'` trả rỗng).
     Bước build dựa vào việc xcodebuild tự tạo scheme `HandLive` từ target, nên đã thêm
     `xcodebuild -list` để thấy scheme trong log. Nếu CI báo không có scheme `HandLive`, cần thêm
     `scheme: {}` cho target `HandLive` trong `apple/project.yml` (thẻ này không được sửa file đó).
   - `swiftlint` trên runner chạy với toolchain Xcode thay vì CLT. Luật giống nhau, nhưng phiên bản
     brew có thể khác 0.65.1.
3. **Relay**: service container của GitHub (cổng 55432/56379, healthcheck) và cache
   `Swatinem/rust-cache`. Lệnh cargo đã xanh tại máy.
4. **Cache**: hiệu quả của cache (hit/miss) và việc `setup-gradle` chỉ ghi cache trên `main`
   /`feat/*`.
5. **Tiêu chí G0 "Ba workflow xanh trên nhánh `feat/phase-00-khung`"**: chỉ đánh dấu được khi có
   remote và đẩy nhánh lên.

## Điểm lệch với tài liệu và cách xử lý

| # | Chỗ | Làm | Đề xuất |
|---|-----|-----|---------|
| 1 | Dòng T0.1 trong phase-00 ghi Android `./gradlew test lint` | Dùng `./gradlew check` (bao trọn, thêm ktlint + detekt) | Sửa dòng T0.1 thành `./gradlew check` |
| 2 | Thẻ chỉ nêu ba workflow | Thêm `ci-shared.yml` cho `shared/` + tài liệu (lý do ở Quyết định 1) | Ghi thêm vào T0.1 / cổng G0 |
| 3 | `apple/README.md` gợi ý `xcodebuild test -workspace apple/HandLive.xcworkspace -scheme HLCrypto` | CI chạy `xcodebuild test -scheme <Pkg>` trong thư mục package (không cần `xcodegen` trước khi test) | Có thể thêm lệnh này vào README |
| 4 | `docs/deployment-guide.md` chưa có phần CI | Không sửa (ngoài phạm vi được phép) | Thêm mục ngắn liệt kê 4 workflow khi cập nhật tài liệu |

Gợi ý (chưa làm, vì không có trong thẻ): nhánh iOS của các package (`#if os(iOS)`) chưa được biên
dịch ở đâu. Sau này có thể thêm bước
`xcodebuild build -scheme <Pkg> -destination 'generic/platform=iOS'` vào `ci-apple.yml`.

## Câu hỏi còn mở

- Bao giờ có remote GitHub để chạy thật và đánh dấu G0?
- Có muốn bật branch protection bắt buộc 4 check này trên `main` không?

```text
Status: DONE_WITH_CONCERNS
Summary: Đã viết 4 workflow (android, apple, relay, shared), actionlint sạch. Mọi lệnh tương đương chạy được tại máy đều xanh: relay fmt/clippy/test + 6 test tích hợp, 4 script tools/, xcodegen + swiftlint --strict (0 vi phạm).
Concerns/Blockers: Không có remote nên chưa run workflow nào thật. Chưa kiểm được Gradle (điều phối viên chạy) và mọi bước xcodebuild (máy không có Xcode). Scheme `HandLive` dựa vào việc xcodebuild tự tạo scheme vì project.yml không khai báo schemes.
```
