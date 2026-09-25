package app.handlive.android.core.design.theme

import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.runtime.Composable
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.runtime.ReadOnlyComposable
import androidx.compose.runtime.staticCompositionLocalOf

private val LocalHandLiveAppearance = staticCompositionLocalOf { HandLiveAppearance.Light }
private val LocalHandLiveColors = staticCompositionLocalOf { lightColors }
private val LocalHandLiveTypography = staticCompositionLocalOf { defaultHandLiveTypography }

/**
 * Theme của HandLive trên Android: màu, chữ, khoảng cách, bo góc sinh từ tokens.json.
 * Không dùng Material dynamic color hay `MaterialTheme`, để màu trạng thái và màu nhấn giống Mac, iPhone.
 *
 * @param darkTheme giao diện Tối theo hệ thống; app không có công tắc riêng.
 * @param highContrast tương phản cao theo hệ thống (`UiModeManager.getContrast()` ≥ 0.5, Android 14+).
 */
@Composable
fun HandLiveTheme(
    darkTheme: Boolean = isSystemInDarkTheme(),
    highContrast: Boolean = isSystemInHighContrast(),
    content: @Composable () -> Unit,
) {
    val appearance = HandLiveAppearance.of(dark = darkTheme, highContrast = highContrast)
    CompositionLocalProvider(
        LocalHandLiveAppearance provides appearance,
        LocalHandLiveColors provides handLiveColors(appearance),
        LocalHandLiveTypography provides defaultHandLiveTypography,
        content = content,
    )
}

/** Điểm đọc token duy nhất cho thành phần `HL*`. */
object HandLiveTheme {
    val appearance: HandLiveAppearance
        @Composable @ReadOnlyComposable
        get() = LocalHandLiveAppearance.current

    val colors: HandLiveColors
        @Composable @ReadOnlyComposable
        get() = LocalHandLiveColors.current

    val typography: HandLiveTypography
        @Composable @ReadOnlyComposable
        get() = LocalHandLiveTypography.current

    val spacing: HandLiveSpacing get() = HandLiveSpacing
    val radius: HandLiveRadius get() = HandLiveRadius
    val sizes: HandLiveSizes get() = HandLiveSizes
}
