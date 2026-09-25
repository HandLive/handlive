# Phase 1 — A1.5 [android]: Localization (0.12.2–0.12.3)

Card A1.5 of `phase-01-bang-nho-tam-mvp.md`. Repository handlive-android, branch `feat/phase-01-clipboard`, pushed; CI green. One catalog commit in handlive-shared (below), taken under the workspace lock.

## What was done

- **Generator** in `buildSrc` (`app.handlive.buildlogic.strings`): `UiStringCatalogParser` reads `../shared/strings/ui-strings.json` and re-checks what would make Android resources wrong (every language present, placeholders declared, CLDR plurals with an `int` `count`, resource-name collisions); `AndroidStringResourceWriter` writes `values/strings.xml` (English, default) and `values-vi/strings.xml`: key `.` → `_`, plurals → `<plurals>`, `{name}` → `%1$s`/`%1$d` in `args` order, `\`, `'`, `"`, line breaks and a leading `@`/`?` escaped, XML-escaped, a literal `%` doubled when the string has arguments (a string without arguments keeps `%` and gets `formatted="false"`), the catalog comment above each entry. Only strings whose `platforms` contain `android` are generated.
- **Module `core/strings`** owns the generated resources: task `:core:strings:generateStringResources` writes into `build/generated/res/uiStrings` and is registered with `variant.sources.res.addGeneratedSourceDirectory` — regenerated at every build, never committed. Every UI module reads `app.handlive.android.core.strings.R` (`core:design` exposes it with `api`).
- **App wiring:** `res/xml/locales_config.xml` (en, vi) + `android:localeConfig`; `androidResources.localeFilters` = en, vi (plus `en-rXA`, `ar-rXB` so the debug pseudo-locales survive); `isPseudoLocalesEnabled = true` for debug; the manifest label comes from the catalog (`common_app_name`); `MainActivity` is an `AppCompatActivity`; AppCompat 1.8.0 with `AppLocalesMetadataHolderService` (`autoStoreLocales`) keeps the in-app choice on Android 10–12.
- **SET-02 field 32 logic:** `AppLanguageSetting` — System/English/Tiếng Việt (each label in its own language, `settings.language_*`), `apply()` via `AppCompatDelegate.setApplicationLocales`, `usesSystemPage` on Android 13+ with `systemPageIntent()` = `Settings.ACTION_APP_LOCALE_SETTINGS` for this package. The Settings row that uses it is part of A1.4.
- **Lint:** root `lint.xml` makes `HardcodedText`, `SetTextI18n`, `MissingTranslation`, `ExtraTranslation`, `MissingQuantity` errors for every module (checked: a temporary `android:text="Hello"` layout failed `:app:lintDebug`); the app lints with `checkDependencies = true`.
- **Source guard** (`UiTextSourceGuardTest`): fails when any module declares its own `<string>`/`<plurals>` resource or passes a text literal with letters to a UI text API in main sources (Compose `Text`/`BasicText`/`HLButton`, `text =`, `title =`, `contentDescription =`, notification texts, toasts…). Lint cannot do this for Compose.
- **Existing strings moved:** the app's `app_name` → `common.app_name`; `core/design` switch states → `common.on`/`common.off`; status texts → `status.*`; the composed "%1$s với %2$s" sentence → `status.connected_wifi_to` / `connected_internet_to` / `connected_usb_to`; the pill label → `status.channel_lan`; design previews use catalog texts (preview-provider names are developer labels `light`, `dark`, `light-hc`, `dark-hc`). Both hand-written `strings.xml` files are gone.

## Catalog change (handlive-shared, `feat/phase-01-clipboard`, under `.locks/shared`)

| Hash | Subject |
|------|---------|
| c3ac31a | feat(shared): add Android strings for pairing errors, unpairing and status reading |

Android-only keys (so Apple's committed String Catalogs stay unchanged): `common.app_name`, `status.connected_internet_to`, `status.connected_usb_to`, `error.qr_invalid`, `error.pairing_closed`, `pairing.limit_reached`, `pairing.pin_attempts_left` (plural), `pairing.camera_denied`, `pairing.unpaired`, `pairing.unpaired_pending`; `status.connected_wifi_to` gained `android`. Texts are the proposals of the S1.2 report (comment "Proposed text"); the controller has since put them into the specs. `check_strings.py`: 179 strings, 0 errors, 0 warnings; `--self-test` 83 passed. **Shared change: the Apple agent does not need to regenerate (no macos/ios entry changed).**

## Commits (handlive-android)

| Hash | Subject |
|------|---------|
| c59260c | feat(android): generate string resources from the UI string catalog |
| 570d82f | test(android): match generated strings to the catalog and guard UI text |
| fa6be1d | refactor(android): take design system texts from the string catalog |
| 6ead2c9 | feat(android): localize the app in English and Vietnamese |

## Files

Created: `buildSrc/src/main/kotlin/app/handlive/buildlogic/strings/{UiStringCatalog,AndroidStringResourceWriter,GenerateStringResourcesTask}.kt`, `core/strings/**` (module, manifest, `GeneratedStringsMatchCatalogTest`, `UiTextSourceGuardTest`), `app/src/main/res/xml/locales_config.xml`, `app/src/main/kotlin/app/handlive/android/settings/AppLanguage.kt`, `app/src/test/.../AppLanguageSettingTest.kt`, `lint.xml`.
Changed: `settings.gradle.kts`, `gradle/libs.versions.toml` (AppCompat), `app/build.gradle.kts`, `app/src/main/AndroidManifest.xml`, `MainActivity.kt`, `core/design/build.gradle.kts`, `HLConnectionStatus.kt`, `HLStatusIndicator.kt`, `HLSwitch.kt`, the four preview files, `HLComponentSemanticsTest.kt`.
Deleted: `app/src/main/res/values/strings.xml`, `core/design/src/main/res/values/strings.xml`.

## Tests (real output)

```text
$ ./gradlew :core:strings:check :core:design:check :app:check
BUILD SUCCESSFUL
GeneratedStringsMatchCatalogTest tests=3  (Robolectric: every Android string and plural resolves to the catalog
  text in en and vi with arguments substituted; 1 → "one", 5 → "other"; nothing outside the catalog is generated)
UiTextSourceGuardTest tests=2
AppLanguageSettingTest tests=3  (locale mapping; Android 12 in-app choice kept; Android 13 system page intent
  "package:app.handlive.android")
HLComponentSemanticsTest tests=7 (runs in vi: "Đã kết nối qua Wi-Fi với Pixel 8 của Lan", "Mất kết nối";
  one test in en: "Connected via Wi-Fi to Pixel 8", switch state "On")
$ ./gradlew check → BUILD SUCCESSFUL (all modules)
```

## Spec deviations and proposals

1. **Lint cannot see generated resource directories**, so `MissingTranslation`/`ExtraTranslation` never fire on catalog strings (checked with a deliberately untranslated string, in the module and with `checkDependencies`). The guarantee comes from the generator (both languages or the build fails), `GeneratedStringsMatchCatalogTest`, and the source guard that forbids hand-written string resources. The lint rules stay on for any future hand-written resource.
2. **StatusIndicator on Android** keeps only the states a phone shows: connected via Wi-Fi / internet / USB, connecting, disconnected. "Phone offline", "Needs to be paired again" (client-side states) and "Camera live" (Phase 5, no key yet) are not part of the Android component. The USB text follows 0.11 ("Connected via USB") as the catalog does, not the design system's "Using USB".
3. **A `double` argument** (allowed by the schema, unused) is generated as `%n$s`: numbers are formatted by the caller (0.12.3).
4. The English texts of the new keys are proposals written before the English specs; the controller reports they are now in the specs.

## Pending manual checks

- Switch en ↔ vi on a device: Android 13+ through the system per-app language page (HandLive must list English and Tiếng Việt), Android 10–12 through the in-app choice (after A1.4), and `adb shell cmd locale set-app-locales app.handlive.android --locales vi`; the whole UI and the service notification change language.
- Pseudo-locales `en-XA` and `ar-XB` on the debug build: no clipping, no hard-coded text, RTL mirroring.

```text
Status: DONE
Summary: The catalog generates Android resources at build time in core:strings (en default, vi), with locales_config, localeFilters, debug pseudo-locales, AppCompat per-app language for Android 10–12 and the system page on 13+, lint errors for hard-coded/untranslated text plus a source guard, and every existing string moved to catalog keys.
Concerns/Blockers: lint's MissingTranslation cannot inspect generated resources (covered by tests instead).
```
