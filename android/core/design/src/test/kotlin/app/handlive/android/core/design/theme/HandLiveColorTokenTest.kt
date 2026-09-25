package app.handlive.android.core.design.theme

import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.toArgb
import org.junit.Assert.assertEquals
import org.junit.Test

class HandLiveColorTokenTest {
    private val appearanceByTheme =
        mapOf(
            "light" to HandLiveAppearance.Light,
            "dark" to HandLiveAppearance.Dark,
            "light-hc" to HandLiveAppearance.LightHighContrast,
            "dark-hc" to HandLiveAppearance.DarkHighContrast,
        )

    @Test
    fun tokensDeclareExactlyFourAppearances() {
        assertEquals(listOf("light", "dark", "light-hc", "dark-hc"), TokensJsonOracle.themeIds)
        assertEquals(HandLiveAppearance.entries.toSet(), appearanceByTheme.values.toSet())
    }

    @Test
    fun everyColorTokenHasFourVariantsWithExactHex() {
        val expected = TokensJsonOracle.colors
        appearanceByTheme.forEach { (theme, appearance) ->
            val generated = handLiveColors(appearance).byTokenName()
            assertEquals("Bộ tên màu ở $theme", expected.keys, generated.keys)
            expected.forEach { (name, byTheme) ->
                val want = byTheme.getValue(theme)
                val got = generated.getValue(name).toArgb().toLong() and 0xFFFFFFFFL
                assertEquals("Màu $name ở $theme: ${"%08X".format(want)} ≠ ${"%08X".format(got)}", want, got)
            }
        }
    }

    @Test
    fun aliasesResolveToTheirTargetInEveryAppearance() {
        HandLiveAppearance.entries.forEach {
            val colors = handLiveColors(it)
            assertEquals(colors.systemGreen, colors.statusConnected)
            assertEquals(colors.accentFill, colors.bubbleOutgoing)
            assertEquals(colors.textRed, colors.destructiveText)
        }
    }

    @Test
    fun appearanceFollowsDarkAndHighContrast() {
        assertEquals(HandLiveAppearance.Light, HandLiveAppearance.of(dark = false, highContrast = false))
        assertEquals(HandLiveAppearance.Dark, HandLiveAppearance.of(dark = true, highContrast = false))
        assertEquals(HandLiveAppearance.LightHighContrast, HandLiveAppearance.of(dark = false, highContrast = true))
        assertEquals(HandLiveAppearance.DarkHighContrast, HandLiveAppearance.of(dark = true, highContrast = true))
        assertEquals(Color(0xFF146B2E), handLiveColors(HandLiveAppearance.LightHighContrast).accent)
        assertEquals(0.5f, HIGH_CONTRAST_THRESHOLD)
    }
}
