package app.handlive.buildlogic.designtokens

/**
 * Dựng mã Kotlin của `HandLiveTheme` từ [DesignTokens]. Mã ra đã theo ktlint_official để đọc được khi gỡ lỗi.
 * Mỗi file còn có `byTokenName()` (internal) để test đối chiếu từng token với tokens.json.
 */
class HandLiveThemeSourceWriter(private val packageName: String) {
    private val header =
        "// Mã sinh từ shared/design-tokens/tokens.json bởi task :core:design:generateHandLiveTheme. Không sửa tay.\n"

    /** Tên hằng của enum `HandLiveAppearance` (viết tay) theo id giao diện trong tokens.json. */
    private val appearanceByTheme = mapOf(
        "light" to "Light",
        "dark" to "Dark",
        "light-hc" to "LightHighContrast",
        "dark-hc" to "DarkHighContrast",
    )

    fun files(tokens: DesignTokens): Map<String, String> = mapOf(
        "HandLiveColors.kt" to colors(tokens.colors),
        "HandLiveTypography.kt" to typography(tokens.textStyles),
        "HandLiveMetrics.kt" to metrics(tokens),
    )

    private fun colors(colors: List<ColorToken>): String = buildString {
        append(prelude("androidx.compose.runtime.Immutable", "androidx.compose.ui.graphics.Color"))
        append("/** Màu HandLive của một giao diện; mỗi thuộc tính là một token màu (hex là màu thật trên Android). */\n")
        append("@Immutable\nclass HandLiveColors internal constructor(\n")
        colors.forEach { append("    /** ${kdoc(it.usage)} */\n    val ${identifier(it.name)}: Color,\n") }
        append(")\n")
        THEME_IDS.forEach { theme ->
            append("\ninternal val ${colorsValue(theme)} =\n    HandLiveColors(\n")
            colors.forEach {
                append("        ${identifier(it.name)} = Color(0x${"%08X".format(it.argbByTheme.getValue(theme))}),\n")
            }
            append("    )\n")
        }
        append("\n/** Bảng màu theo giao diện; không có màu động Material. */\n")
        append("fun handLiveColors(appearance: HandLiveAppearance): HandLiveColors =\n    when (appearance) {\n")
        THEME_IDS.forEach {
            append("        HandLiveAppearance.${appearanceByTheme.getValue(it)} -> ${colorsValue(it)}\n")
        }
        append("    }\n")
        append(byTokenName("HandLiveColors.byTokenName", "Color", colors.map { it.name to identifier(it.name) }))
    }

    private fun typography(styles: List<TextStyleToken>): String = buildString {
        append(
            prelude(
                "androidx.compose.runtime.Immutable",
                "androidx.compose.ui.text.TextStyle",
                "androidx.compose.ui.text.font.FontWeight",
                "androidx.compose.ui.unit.em",
                "androidx.compose.ui.unit.sp",
            ),
        )
        append("/** Bộ chữ riêng của HandLive (không dùng thang chữ Material); cỡ và dòng tính bằng sp. */\n")
        append("@Immutable\nclass HandLiveTypography internal constructor(\n")
        styles.forEach { append("    val ${textIdentifier(it.name)}: TextStyle,\n") }
        append(")\n\ninternal val defaultHandLiveTypography =\n    HandLiveTypography(\n")
        styles.forEach { style ->
            append("        ${textIdentifier(style.name)} =\n            TextStyle(\n")
            append("                fontFamily = HandLiveFontFamilies.${style.fontFamily},\n")
            append("                fontWeight = FontWeight(${style.fontWeight}),\n")
            append("                fontSize = ${style.fontSizeSp}.sp,\n")
            append("                lineHeight = ${style.lineHeightSp}.sp,\n")
            val em = style.letterSpacingEm
            append("                letterSpacing = ${if (em.startsWith("-")) "($em)" else em}.em,\n")
            style.fontFeatureSettings?.let { append("                fontFeatureSettings = \"$it\",\n") }
            append("            ),\n")
        }
        append("    )\n")
        val entries = styles.map { it.name to textIdentifier(it.name) }
        append(byTokenName("HandLiveTypography.byTokenName", "TextStyle", entries))
    }

    private fun metrics(tokens: DesignTokens): String = buildString {
        append(prelude("androidx.compose.ui.unit.Dp", "androidx.compose.ui.unit.dp"))
        append(dpObject("HandLiveSpacing", "Khoảng cách, lưới 4 dp.", "", tokens.spacing))
        append("\n")
        append(dpObject("HandLiveRadius", "Bán kính bo góc.", "radius-", tokens.radius))
        append("\n")
        append(dpObject("HandLiveSizes", "Kích thước tối thiểu và cỡ cố định.", "size-", tokens.size))
        append("\n/** Thời lượng chuyển động (mili giây); tắt hiệu ứng thì bỏ chuyển động, giữ đổi trạng thái. */\n")
        append("object HandLiveDurations {\n")
        tokens.duration.forEach {
            append("    const val ${identifier(it.name.removePrefix("duration-"))}Millis: Int = ${it.value}\n")
        }
        append("}\n")
        val entries = tokens.duration.map { it.name to identifier(it.name.removePrefix("duration-")) + "Millis" }
        append(byTokenName("HandLiveDurations.byTokenName", "Int", entries))
    }

    private fun dpObject(name: String, doc: String, prefix: String, tokens: List<ScalarToken>) = buildString {
        append("/** $doc */\nobject $name {\n")
        tokens.forEach { append("    val ${identifier(it.name.removePrefix(prefix))}: Dp = ${it.value}.dp\n") }
        append("}\n")
        append(byTokenName("$name.byTokenName", "Dp", tokens.map { it.name to identifier(it.name.removePrefix(prefix)) }))
    }

    private fun byTokenName(receiverAndName: String, type: String, entries: List<Pair<String, String>>) = buildString {
        val names = entries.map { it.second }
        if (names.toSet().size != names.size) throw DesignTokenException("Hai token trùng tên Kotlin: $names")
        append("\n/** Tên token trong tokens.json → giá trị, để test đối chiếu. */\n")
        append("internal fun $receiverAndName(): Map<String, $type> =\n    mapOf(\n")
        entries.forEach { (token, property) -> append("        \"$token\" to $property,\n") }
        append("    )\n")
    }

    private fun prelude(vararg imports: String) = buildString {
        append(header).append("package ").append(packageName).append("\n\n")
        imports.sorted().forEach { append("import ").append(it).append("\n") }
        append("\n")
    }

    private fun colorsValue(theme: String) = appearanceByTheme.getValue(theme).replaceFirstChar(Char::lowercaseChar) + "Colors"

    /** `android-large-title` → `largeTitle`; kiểu chữ thương hiệu, mã và giờ giữ nguyên tên. */
    private fun textIdentifier(name: String) = identifier(name.removePrefix("android-"))

    private fun identifier(name: String): String {
        val parts = name.split('-')
        val result = parts.first() + parts.drop(1).joinToString("") { it.replaceFirstChar(Char::uppercaseChar) }
        if (!Regex("^[a-z][A-Za-z0-9]*$").matches(result)) throw DesignTokenException("Tên token không hợp lệ: $name")
        return result
    }

    private fun kdoc(text: String) = text.replace("*/", "* /").replace("\n", " ")
}
