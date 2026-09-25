package app.handlive.android.core.design.theme

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Test
import java.io.File

class HandLiveMetricsTokenTest {
    @Test
    fun spacingRadiusAndSizesMatchTokensJsonInDp() {
        mapOf(
            "spacing" to HandLiveSpacing.byTokenName(),
            "radius" to HandLiveRadius.byTokenName(),
            "size" to HandLiveSizes.byTokenName(),
        ).forEach { (family, generated) ->
            val expected = TokensJsonOracle.scalars(family)
            assertEquals(family, expected.keys, generated.keys)
            expected.forEach { (name, value) -> assertEquals(name, value.toFloat(), generated.getValue(name).value) }
        }
    }

    @Test
    fun durationsMatchTokensJsonInMillis() {
        assertEquals(TokensJsonOracle.scalars("duration"), HandLiveDurations.byTokenName())
    }

    /**
     * 03-android.md: không dùng Material dynamic color, không lấy màu hay chữ từ `MaterialTheme`.
     * Quét cả mã viết tay lẫn mã sinh. material3 chỉ có trên classpath debug (ui-tooling kéo theo để dựng preview),
     * không có trên classpath release.
     */
    @Test
    fun themeNeverUsesMaterialDynamicColor() {
        val forbidden = listOf("dynamicLightColorScheme", "dynamicDarkColorScheme", "import androidx.compose.material")
        val sources =
            listOf("hl.main.source.dir", "hl.generated.source.dir")
                .map { File(requireNotNull(System.getProperty(it)) { "Thiếu -D$it" }) }
                .flatMap { dir -> dir.walkTopDown().filter { it.extension == "kt" }.toList() }
        assertFalse("Không thấy mã nguồn để quét", sources.isEmpty())
        sources.forEach { file ->
            val text = file.readText()
            forbidden.forEach { assertFalse("${file.name} tham chiếu $it", text.contains(it)) }
        }
    }
}
