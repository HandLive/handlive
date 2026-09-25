package app.handlive.android.core.design.theme

/**
 * Bốn giao diện của design system, khớp `color.themes` trong tokens.json (`light`, `dark`, `light-hc`, `dark-hc`).
 * Tối theo `isSystemInDarkTheme()`; tương phản cao theo [isSystemInHighContrast].
 */
enum class HandLiveAppearance(
    val isDark: Boolean,
    val isHighContrast: Boolean,
) {
    Light(isDark = false, isHighContrast = false),
    Dark(isDark = true, isHighContrast = false),
    LightHighContrast(isDark = false, isHighContrast = true),
    DarkHighContrast(isDark = true, isHighContrast = true),
    ;

    companion object {
        fun of(
            dark: Boolean,
            highContrast: Boolean,
        ): HandLiveAppearance = entries.first { it.isDark == dark && it.isHighContrast == highContrast }
    }
}
