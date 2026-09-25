package app.handlive.android.core.design.theme

import androidx.compose.ui.text.font.FontListFontFamily
import app.handlive.android.core.design.theme.TokensJsonOracle.int
import app.handlive.android.core.design.theme.TokensJsonOracle.number
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test
import java.io.File

class HandLiveTypographyTokenTest {
    private val generated = defaultHandLiveTypography.byTokenName()

    /** Kiểu chữ Android dùng: mọi kiểu trừ `mac-*`, `ios-*` (chỉ cho Apple). */
    private val androidStyles =
        TokensJsonOracle.textStyles.filterKeys { !it.startsWith("mac-") && !it.startsWith("ios-") }

    @Test
    fun everyAndroidTextStyleMatchesTokensJson() {
        assertEquals(androidStyles.keys, generated.keys)
        androidStyles.forEach { (name, token) ->
            val style = generated.getValue(name)
            assertEquals("$name fontSize (sp)", token.number("fontSize"), style.fontSize.value)
            assertEquals("$name lineHeight (sp)", token.number("lineHeight"), style.lineHeight.value)
            assertEquals("$name letterSpacing (em)", token.number("letterSpacing"), style.letterSpacing.value, 1e-6f)
            assertEquals("$name fontWeight", token.int("fontWeight"), style.fontWeight?.weight)
            assertTrue("$name phải tính bằng sp", style.fontSize.isSp && style.lineHeight.isSp)
        }
    }

    @Test
    fun androidScaleMatchesIosTableInTypographyDoc() {
        val doc = typographyDocRows()
        val androidNames = androidStyles.keys.filter { it.startsWith("android-") }
        assertEquals(11, androidNames.size)
        androidNames.forEach { name ->
            val (sizeLine, weight) = doc.getValue(name.replace("android-", "ios-"))
            val style = generated.getValue(name)
            assertEquals(name, sizeLine, "${style.fontSize.value.toInt()}/${style.lineHeight.value.toInt()}")
            assertEquals(name, weight, style.fontWeight?.weight)
        }
        listOf("brand-large-title", "brand-title", "wordmark", "code-pin", "timer").forEach { name ->
            val (sizeLine, weight) = doc.getValue(name)
            val style = generated.getValue(name)
            assertEquals(name, sizeLine, "${style.fontSize.value.toInt()}/${style.lineHeight.value.toInt()}")
            assertEquals(name, weight, style.fontWeight?.weight)
        }
    }

    @Test
    fun fontFamiliesFollowPlatformDoc() {
        androidStyles.keys.forEach { name ->
            val expected =
                when (name) {
                    "brand-large-title", "brand-title", "wordmark" -> HandLiveFontFamilies.beVietnamPro
                    "code-pin" -> HandLiveFontFamilies.robotoMono
                    else -> HandLiveFontFamilies.inter
                }
            assertEquals(name, expected, generated.getValue(name).fontFamily)
            assertEquals(name, if (name == "timer") "tnum" else null, generated.getValue(name).fontFeatureSettings)
        }
    }

    @Test
    fun bundledFontsAreExactlyTheWeightsTokensUse() {
        val used = generated.values.map { it.fontFamily!! to it.fontWeight!!.weight }.toSet()
        val families: List<FontListFontFamily> =
            listOf(HandLiveFontFamilies.inter, HandLiveFontFamilies.beVietnamPro, HandLiveFontFamilies.robotoMono)
                .map { it as FontListFontFamily }
        val bundled = families.flatMap { family -> family.fonts.map { font -> family to font.weight.weight } }.toSet()
        assertEquals("Mỗi weight token dùng có font thật, không đóng gói thừa", used, bundled)
        val fontFiles = mainSourceDir().resolve("res/font").list()!!.toSet()
        assertEquals(bundled.size, fontFiles.size)
    }

    @Test
    fun everyBundledFontShipsWithOflLicense() {
        val licenses = mainSourceDir().resolve("assets/licenses")
        listOf("Inter-OFL.txt", "BeVietnamPro-OFL.txt", "RobotoMono-OFL.txt").forEach {
            val text = licenses.resolve(it).readText()
            assertTrue(it, text.contains("SIL Open Font License, Version 1.1"))
        }
    }

    private fun mainSourceDir() = File(requireNotNull(System.getProperty("hl.main.source.dir")))

    /** Token → ("cỡ/dòng", weight) đọc từ các bảng của 03-kieu-chu.md. */
    private fun typographyDocRows(): Map<String, Pair<String, Int>> {
        val weights = mapOf("Regular" to 400, "Medium" to 500, "Semibold" to 600, "Bold" to 700, "Heavy" to 800)
        return TokensJsonOracle.docsDir
            .resolve("1-foundations/03-kieu-chu.md")
            .readLines()
            .mapNotNull { line ->
                val cells = line.split('|').map { it.trim() }
                val token = cells.getOrNull(1)?.let { Regex("^`([a-z0-9-]+)`$").matchEntire(it)?.groupValues?.get(1) }
                val sizeIndex = cells.indexOfFirst { Regex("^\\d+/\\d+$").matches(it) }
                if (token == null || sizeIndex < 0) return@mapNotNull null
                token to (cells[sizeIndex] to weights.getValue(cells[sizeIndex + 1]))
            }.toMap()
    }
}
