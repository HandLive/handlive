# Báo cáo A0.3 [android] — `core/design`: HandLiveTheme sinh từ tokens.json + thành phần Compose kiểu Apple

Ngày: 2026-09-25 · Nhánh: `feat/phase-00-khung` · Chưa commit.

## Việc đã làm

### Sinh mã từ tokens.json

- Task Gradle `:core:design:generateHandLiveTheme` nằm trong `android/buildSrc`. Chọn `buildSrc` vì
  không phải sửa `settings.gradle.kts`, và generator (khoảng 330 dòng Kotlin, đọc JSON bằng
  `groovy.json.JsonSlurper` có sẵn trong Gradle API) có chỗ riêng, không làm rối build script của
  module.
- **Mã sinh vào thư mục build, không commit** (`core/design/build/generated/source/handLiveTheme`).
  Nó được đăng ký qua
  `androidComponents.onVariants { sources.kotlin.addGeneratedSourceDirectory(...) }`. Lý do chọn
  cách này:
  1. Mỗi lần biên dịch đều sinh lại từ tokens.json, nên mã không thể lệch khỏi tokens.json và không
     cần thêm task kiểm "up-to-date".
  2. Khác bên Apple (M0.2 phải commit vì Xcode cần xcassets trên đĩa), Android không có công cụ nào
     đòi file có sẵn.
- tokens.json sai thì task ném `DesignTokenException` và build dừng. Các trường hợp sai:
  `color.themes` khác đúng 4 giao diện, thiếu giao diện, bí danh `{token}` trỏ tới token không có
  hoặc tạo vòng, hex sai dạng, đơn vị khác px/ms/em, họ chữ chưa có font Android, hai token trùng
  tên Kotlin.
- **Generator hiểu sai tokens.json → `check` đỏ.** Test JVM đọc tokens.json bằng một bộ đọc riêng
  (`TokensJsonOracle`, kotlinx.serialization), không dùng chung code với generator, rồi so với từng
  giá trị trong mã sinh. Đã thử: sửa tạm generator cho alpha mặc định thành `0xFE` → `check` đỏ với
  thông báo `Màu accent ở light: FF197934 ≠ FE197934`. Đã khôi phục.
- Cách hiểu tokens.json giống script Apple M0.2:
  - Màu chỉ có một giá trị thì dùng cho cả 4 giao diện. `{token}` là bí danh, được lần tới giá trị
    gốc. `#rrggbbaa` được hiểu là CSS, alpha ở cuối.
  - Kiểu chữ `mac-*` và `ios-*` chỉ cho Apple nên bị bỏ qua.
  - Shadow chưa sinh (xem điểm lệch 6).
- Mã sinh ra (package `app.handlive.android.core.design.theme`):
  - `HandLiveColors`: 68 token màu, có KDoc lấy từ `usage`, và 4 bảng `lightColors`, `darkColors`,
    `lightHighContrastColors`, `darkHighContrastColors`. Hàm `handLiveColors(appearance)` trả bảng
    theo giao diện.
  - `HandLiveTypography`: 11 kiểu `android-*` (đặt tên bỏ tiền tố: `body`, `headline` …), cộng
    `brandLargeTitle`, `brandTitle`, `wordmark`, `codePin`, `timer`.
    - Cỡ chữ và chiều cao dòng tính bằng sp, tracking tính bằng em.
    - Font: Inter cho `android-*` và `timer`; Be Vietnam Pro cho 3 kiểu thương hiệu; Roboto Mono cho `code-pin`.
    - `timer` có `fontFeatureSettings = "tnum"`.
  - `HandLiveSpacing`, `HandLiveRadius`, `HandLiveSizes` (Dp) và `HandLiveDurations`
    (`quickMillis`…).
  - Mỗi nhóm có thêm hàm `internal fun byTokenName()` để test đối chiếu theo tên token.

### Theme

- `HandLiveTheme(darkTheme = isSystemInDarkTheme(), highContrast = isSystemInHighContrast())` cấp
  màu, chữ và giao diện qua `CompositionLocal`. Thành phần đọc token qua `object HandLiveTheme`
  (`colors`, `typography`, `spacing`, `radius`, `sizes`, `appearance`).
- **Không dùng Material dynamic color, không dùng `MaterialTheme`.** `core:design` không phụ thuộc
  material3. Test quét cả mã viết tay lẫn mã sinh để tìm `dynamicLightColorScheme`,
  `dynamicDarkColorScheme` và `import androidx.compose.material`. `releaseRuntimeClasspath` không có
  material3; nó chỉ có trên classpath debug vì `ui-tooling` kéo theo để dựng preview.
- **Tương phản cao:** dùng `UiModeManager.getContrast()` ≥ 0.5 (API 34+). Theo dõi thay đổi bằng
  `UiModeManager.addContrastChangeListener(mainExecutor, …)` và gỡ listener trong `onDispose`. API
  29–33 luôn trả `false` vì hệ thống không có cài đặt này. Code ở `theme/SystemHighContrast.kt`.
- Font trong `res/font`, chỉ các weight mà token dùng:
  - `inter_regular`, `inter_medium`, `inter_semibold`: Inter 4.1 bản tĩnh, lấy từ release
    rsms/inter.
  - `be_vietnam_pro_semibold`, `be_vietnam_pro_bold`: lấy từ google/fonts, trùng byte với bản bên
    Apple.
  - `roboto_mono_variable`: google/fonts `ofl/robotomono`, chỉ có bản biến thiên. Dùng
    `FontVariation.weight(600)`.
  - Giấy phép OFL 1.1 ở `src/main/assets/licenses/{Inter,BeVietnamPro,RobotoMono}-OFL.txt`. Đặt
    trong assets vì `res/font` không nhận file .txt; assets được gộp vào APK, dùng được cho màn giấy
    phép mã nguồn mở.

### Thành phần (package `...core.design.component`)

- **`HLButton` + `HLButtonStyle`** (Prominent, Glass, Tinted, Plain, Destructive):
  - Hình capsule. Nút chính cao 50 dp, nút phụ 48 dp. Chữ `android-headline` (Inter 17 sp, 600).
  - Khi nhấn: màu tối đi 8% (lerp về đen), không có ripple (`indication = null`). Khi vô hiệu: alpha
    40%.
  - TalkBack: `Role.Button`, và đọc "đã tắt" khi vô hiệu.
- **`HLSwitch`**:
  - Kích thước 51×31 dp. Bật màu `system-green`, tắt màu `system-fill`, núm trắng. Núm trượt theo
    `duration-quick`; khi tắt hiệu ứng thì nhảy thẳng (`snap`).
  - Dùng riêng lẻ thì có `toggleable(Role.Switch)`, vùng chạm ≥ 48 dp.
  - Đặt trong dòng (`onCheckedChange = null`) thì cả dòng là vùng chạm.
  - TalkBack đọc `stateDescription` "Bật"/"Tắt".
- **`HLGroupedList`**: DSL
  `HLGroupedList { section(title, footer) { switchRow / navigationRow / actionRow / row } }` dựng
  trên `LazyColumn`.
  - Nền `system-grouped-background`. Nhóm nền `secondary-system-grouped-background`, bo
    `radius-sheet`. Dòng cao ≥ 56 dp.
  - Header 13 sp Semibold màu `secondary-label`, đánh dấu `heading()`. Có chú thích dưới nhóm và
    đường phân cách 1 px `separator`.
  - Dòng công tắc: cả dòng là vùng chạm (`Role.Switch`), có `stateDescription`, gộp nhãn với lý do.
    Khi có lý do chưa dùng được thì lý do hiện màu `text-orange` và công tắc bị vô hiệu.
  - Dòng hành động: chữ `accent`; dòng phá hủy chữ `destructive-text`.
  - Mũi tên của dòng điều hướng được vẽ tay, màu `tertiary-label`.
- **`HLStatusIndicator` + `HLConnectionStatus`** (8 trạng thái) + `HLStatusIndicatorVariant`
  (Inline, Pill):
  - Chữ lấy nguyên văn README, đặt trong `res/values/strings.xml`.
  - TalkBack đọc cả câu (`clearAndSetSemantics { contentDescription; liveRegion = Polite }`), ví dụ
    "Đã kết nối qua Wi-Fi với Pixel 8 của Lan". Tên thiết bị chỉ được đọc kèm ở 3 trạng thái đã kết
    nối, giống bản Apple.
  - Dạng viên hiện nhãn ngắn "LAN" nhưng vẫn đọc câu đầy đủ.
  - Chấm nhấp nháy theo `duration-pulse`, chỉ ở "Đang kết nối…" và "Đang phát camera". Chấm đứng yên
    khi `ValueAnimator.areAnimatorsEnabled()` là `false`.
  - Màu: ngoại tuyến xám, đỏ chỉ khi "Cần ghép nối lại".
- **`@Preview`**: mỗi thành phần có một preview dùng
  `@PreviewParameter(HandLiveAppearancePreviewProvider::class)`, tạo ra 4 bản tên "Sáng", "Tối",
  "Sáng · tương phản cao", "Tối · tương phản cao". Chuỗi trong preview lấy nguyên văn Button/README
  và 2-patterns/04-cai-dat.md.
- **Screenshot JVM** (Roborazzi 1.75.0 + Robolectric 4.17, `GraphicsMode.NATIVE`):
  - `HandLivePreviewScreenshotTest` dựng nội dung của cả 4 preview ở 4 giao diện. Chạy trong
    `check`, nên preview nào hỏng thì `check` đỏ.
  - `./gradlew :core:design:recordRoborazziDebug` ghi 16 ảnh ra
    `core/design/build/outputs/roborazzi/` (không commit).
  - Đã xem ảnh: Inter hiện đúng dấu tiếng Việt; màu 4 giao diện đúng; chữ trong dòng xuống hàng,
    không bị cắt.

### Phiên bản

| Thành phần | Trước | Sau | Ghi chú |
|---|---|---|---|
| Compose BOM | 2026.03.01 (Compose 1.10.6) | **2026.06.01 (Compose 1.11.4)** | Bản mới nhất chạy được với compileSdk 36. Xem điểm lệch 1 |
| activity-compose | 1.10.1 | **1.13.0** | Bản ổn định mới nhất |
| Robolectric | — | 4.17 | Chỉ dùng cho test |
| Roborazzi | — | 1.75.0 (plugin + `roborazzi-compose`) | Chỉ dùng cho test |
| compose `ui-test-junit4` / `ui-test-manifest` | — | theo BOM | test / debug |

`android/app/build.gradle.kts` không phải sửa.

## Đường dẫn tạo/sửa

- Tạo `android/buildSrc/`:
  - `build.gradle.kts`
  - `src/main/kotlin/app/handlive/buildlogic/designtokens/{DesignTokens,HandLiveThemeSourceWriter,GenerateHandLiveThemeTask}.kt`
- Sửa `android/core/design/build.gradle.kts`: thêm task sinh mã, đăng ký nguồn sinh, cấu hình test
  (đường dẫn `shared/`, `docs/`, khai báo input), thêm plugin roborazzi và các phụ thuộc test.
- Tạo trong `android/core/design/src/main/`:
  - `kotlin/.../theme/`: `HandLiveAppearance`, `HandLiveTheme`, `HandLiveFontFamilies`,
    `SystemHighContrast`.
  - `kotlin/.../component/`: `HLButton`, `HLButtonStyle`, `HLSwitch`, `HLGroupedList`,
    `HLGroupedListRows`, `HLStatusIndicator`, `HLStatusIndicatorVariant`, `HLConnectionStatus`,
    `MotionPreference`.
  - `kotlin/.../preview/`: `HandLiveAppearancePreviewProvider` (kèm `HandLivePreviewSurface`),
    `HLButtonPreview`, `HLSwitchPreview`, `HLGroupedListPreview`, `HLStatusIndicatorPreview`.
  - `res/font/*.ttf` (6 file, khoảng 1,7 MB), `res/values/strings.xml`, `assets/licenses/*-OFL.txt`.
- Tạo trong `android/core/design/src/test/kotlin/.../`:
  - `theme/`: `TokensJsonOracle`, `HandLiveColorTokenTest`, `HandLiveTypographyTokenTest`,
    `HandLiveMetricsTokenTest`.
  - `component/HLComponentSemanticsTest`.
  - `preview/HandLivePreviewScreenshotTest`.
- Sửa `android/gradle/libs.versions.toml`: chỉ các dòng `composeBom`, `activityCompose`, và thêm
  `robolectric`, `roborazzi`, `compose-ui-test-*`, `roborazzi-compose`, plugin `roborazzi`. Sửa bằng
  thay chuỗi cụ thể, không đụng các dòng Ktor.
- Không sửa `settings.gradle.kts`, `tokens.json`, `docs/`, `core/transport/**`.

## Test

20 test, 0 lỗi, 0 bỏ qua:

```
HLComponentSemanticsTest        tests=6  (Robolectric SDK 35: vai trò, stateDescription Bật/Tắt, bấm cả dòng, dòng vô hiệu kèm lý do, heading, live region, viên "LAN")
HandLivePreviewScreenshotTest   tests=2  (4 preview × 4 giao diện)
HandLiveColorTokenTest          tests=4  (68 màu × 4 giao diện đúng hex; bí danh; chọn giao diện; ngưỡng 0.5)
HandLiveMetricsTokenTest        tests=3  (spacing/radius/size dp, duration ms; không dynamic color/Material)
HandLiveTypographyTokenTest     tests=5  (khớp tokens.json; khớp bảng 03-kieu-chu.md (android-X = ios-X, thương hiệu, code-pin, timer); họ font; weight đóng gói = weight token dùng; OFL)
```

`cd android && ./gradlew :core:design:check` (phần cuối):

```
> Task :core:design:lint
> Task :core:design:testDebugUnitTest
> Task :core:design:test
> Task :core:design:finalizeTestRoborazziDebug SKIPPED
> Task :core:design:check
BUILD SUCCESSFUL in 37s
63 actionable tasks: 44 executed, 18 from cache, 1 up-to-date
Configuration cache entry stored.
```

`cd android && ./gradlew check --continue` (phần cuối):

```
> Task :core:design:check
> Task :core:protocol:detekt
> Task :core:transport:detekt UP-TO-DATE
> Task :core:crypto:check
> Task :core:protocol:check
> Task :core:transport:check
> Task :app:check
BUILD SUCCESSFUL in 15s
272 actionable tasks: 59 executed, 6 from cache, 207 up-to-date
```

Kết quả kiểm:

- Lint `core:design`: 0 lỗi, 1 cảnh báo `GradleDependency` (compileSdk 37 đã có).
- ktlint và detekt sạch. Không dùng baseline, không `@Suppress`. Có một
  `@OptIn(ExperimentalTextApi::class)` duy nhất, đặt đúng chỗ khai báo `robotoMono`.
- ktlint và detekt không quét mã sinh vì mã nằm ngoài source set. Dù vậy mã sinh đã viết theo kiểu
  `ktlint_official`.

## Điểm lệch với tài liệu và đề xuất

1. **Compose BOM không lên được bản mới nhất.**
   - BOM 2026.08.00 và 2026.09.00 (Compose 1.12.x) đòi compileSdk ≥ 37. `checkDebugAarMetadata` báo
     lỗi cho 13 thư viện.
   - Máy chỉ có `platforms;android-35` và `android-36`, và compileSdk 36 là do điều phối viên quyết.
     Vì vậy chọn **BOM 2026.06.01 (Compose 1.11.4)**, bản cao nhất chạy được với compileSdk 36.
   - Đề xuất: cài `platforms;android-37`, nâng compileSdk lên 37 cho mọi module (targetSdk vẫn 35),
     rồi nâng BOM lên 2026.09.00. Khi đó `FontVariation` có thể đã hết experimental.
2. **Nút Destructive.** Button/README ghi token `destructive-text` và `call-decline-fill`. Đã làm
   như `.bordered` + `role: .destructive` của Apple: chữ `destructive-text` trên nền kính
   (`glass-fill`/`glass-stroke`), vì nút đỏ đặc trông như nút chính, trong khi README không cho gán
   vai trò chính cho nút phá hủy. `call-decline-fill` để dành cho CallPanel. Kiểu Glass dùng chữ
   `label` vì README không nêu màu chữ. Cần duyệt.
3. **Token còn thiếu:**
   - Núm trắng của công tắc đang là `Color.White`. Đề xuất thêm token `switch-thumb`.
   - Bóng núm đang là elevation 1 dp, gần với `shadow-control`.
   - tokens.json chưa có trường tính năng OpenType: `timer` → `tnum` đang ghi cứng trong generator
     theo 03-kieu-chu.md. Đề xuất thêm trường `fontFeatures`, cùng với `relativeTo` và
     `emphasisWeight` mà M0.2 đã đề xuất.
   - Ô biểu tượng 30 dp / bo 8 dp: xem M0.2 điểm 2.
4. **Chưa có biểu tượng** (Material Symbols để sau Phase 0):
   - StatusIndicator dùng chấm màu cho cả 8 trạng thái. README muốn dùng biểu tượng `wifi`, `public`
     … cho các trạng thái không nhấp nháy.
   - GroupedList chưa có ô biểu tượng màu theo nhóm, và dòng lý do chưa có biểu tượng thông tin.
   - Mũi tên `chevron_right` được vẽ bằng Canvas.
   - Bổ sung khi đóng gói Material Symbols Rounded.
5. **Chưa làm (YAGNI Phase 0):**
   - Trạng thái "đang xử lý" của nút (nhãn tiến trình kèm vòng quay). foundation không có vòng quay,
     và material3 thì không dùng.
   - Nút "Cấp quyền" bấm được trong dòng lý do: `switchRow` hiện mới nhận chữ lý do.
   - **Chữ đậm hệ thống** (`Configuration.fontWeightAdjustment`, 03-kieu-chu.md): chưa xử lý. Chỉ
     đóng gói đúng các weight token dùng nên chưa tăng bậc weight được. Chưa kiểm Compose 1.11 có tự
     áp dụng hay không. Muốn làm đủ thì cần thêm Inter 700 và Be Vietnam Pro 800.
6. **Shadow tokens chưa sinh.** Giá trị là chuỗi CSS nhiều lớp (`0 8px 24px #…, …`), chưa có thành
   phần nào dùng. Sẽ sinh khi làm thanh tab kính hoặc HUD.
7. **Roboto Mono dùng bản biến thiên** (184 KB, chứa mọi weight), vì google/fonts không phát hành
   bản tĩnh. Làm vậy để không phải tự tạo bản tĩnh, tức là sửa font OFL. Weight 600 được chọn qua
   trục `wght`, test bảo đảm không có weight nào bị tô đậm giả.
8. **Kiểu chữ của StatusIndicator trên Android.** README không ghi. Đã chọn `android-subheadline`
   (15 sp), cả dạng dòng lẫn dạng viên. Cần duyệt.
9. **Test semantics chạy Robolectric SDK 35.** Robolectric 4.17 chưa rõ hỗ trợ SDK 36, nên nhánh
   `getContrast()` (API 34+) chưa có test tự động theo cài đặt hệ thống. Hiện chỉ test ánh xạ giao
   diện và ngưỡng.

## Câu hỏi còn mở

- Có nâng compileSdk lên 37 (cài `platforms;android-37`) để dùng Compose 1.12 không?
- Điểm lệch 2 (màu của Destructive và Glass) và điểm lệch 8 (kiểu chữ của StatusIndicator): chủ dự
  án duyệt?
- Có thêm token `switch-thumb` và trường `fontFeatures` vào tokens.json không?

```text
Status: DONE_WITH_CONCERNS
Summary: core/design có HandLiveTheme sinh từ tokens.json vào build/ (màu 68 token × 4 giao diện, chữ Inter/Be Vietnam Pro/Roboto Mono, khoảng cách, bo góc, kích thước, thời lượng), tương phản cao theo UiModeManager.getContrast(), 4 thành phần HL* có semantics TalkBack và @Preview 4 giao diện; 20 test xanh, :core:design:check và check toàn dự án xanh.
Concerns/Blockers: Compose BOM chỉ lên được 2026.06.01 (Compose 1.11.4) vì Compose 1.12 cần compileSdk 37; thiếu token núm công tắc và trường fontFeatures; chưa có biểu tượng Material Symbols; màu nút Destructive/Glass cần duyệt.
```
