# Release v0.1.0-beta.3 (2026-10-07)

Owner, 13:35: "em hãy merge rồi release beta luôn đi" (merge, then release the beta). Every PR was already merged;
the team cut `v0.1.0-beta.3` with the beta.2 procedure (`docs/deployment-guide.md`, Cutting a release).

## Steps

| Step | Outcome |
|------|---------|
| Security scan `v0.1.0-beta.2..main` (Khoa, Quân) | 0 critical, 0 high; 1 medium fixed before the tag; 1 low deferred (android#13, details private until fixed); 1 low fixed (environment `release` of handlive-apple limited to `main` and `v*` through the API) — `security-scan-beta3-2026-10-07.md` |
| Medium fix: clipboard HTML sanitizer in linear time | shared #8 `dffa1a2` (reference + 3 vectors), apple #10 `43ba458`, android #12 `bbf2ce9`; output byte-identical (150 044 inputs fuzzed across Python, Swift, Kotlin), timing tests ~1 MiB within 5 s, red on the old code. The first guard decided by the lead ("no `>` left") missed the unclosed-quote pattern Khoa found; the fix precomputes each tag end right to left |
| Versions and changelogs | android #10 `1a02f42` (`versionCode 4`, `0.1.0-beta.3`), apple #9 `e4e05c3` (build 3 of 0.1.0), shared changelog in #8, hub #21 `8ac6d0e` (changelog en/vi, README Latest release, website Get the Beta and badge) |
| Tags (annotated, `Hồ Xuân Dũng <me@hxd.vn>`) | hub `8ac6d0e`, shared `dffa1a2` first, then relay `cda13bf`, android `1a02f42`, apple `e4e05c3`; `main` CI green on each before tagging |
| Workflows | `release-android` 37586536810 (build, sign + publish); `release-apple` 37586543045 (`sign` iOS and macOS on `macos-26`, `launch` on `macos-15`, `publish`); hub `release-collect` 37586505166: all green |
| Releases | pre-releases on all five repositories; hub notes list the files and highlights; shared and relay point at the hub's Release |

## File checks (downloaded from the releases)

| File | Check |
|------|-------|
| `HandLive-0.1.0-beta.3-android-foss.apk` | SHA-256 OK; `apksigner`: `CN=Ho Xuan Dung, O=HandLive, C=VN`, cert SHA-256 `bddc9efc…a0f9`; `versionCode 4`, `versionName 0.1.0-beta.3` |
| `HandLive-0.1.0-beta.3-ios-unsigned.ipa` | SHA-256 OK; `CFBundleShortVersionString 0.1.0`, `CFBundleVersion 3` |
| `HandLive-0.1.0-beta.3-macos-unsigned.dmg` | SHA-256 OK; app `0.1.0` (3), `CFBundleIconName AppIcon`, signature ad hoc, universal (`x86_64 arm64`) |

The hub's Release holds the six files (each with its `.sha256`), the same sizes as the platform Releases.

## Notes

- The download of the IPA and DMG was cut twice by the network on this machine; resumed downloads matched the checksums.
- The website is not deployed; its Get the Beta and badge point at the beta.3 Release in the repository.

## Unresolved questions

- None for the release. Open product question: whether an app call ended `unknown` keeps `answered_at`.

Status: DONE
Summary: `v0.1.0-beta.3` is tagged on all five repositories and released with a signed APK, an IPA and an ad hoc Mac
DMG on the hub's Release, after a security scan whose medium finding was fixed and reviewed before the tag.
Concerns/Blockers: none.
