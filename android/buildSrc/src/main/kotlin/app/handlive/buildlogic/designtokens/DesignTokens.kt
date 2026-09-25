package app.handlive.buildlogic.designtokens

import groovy.json.JsonSlurper
import java.io.File

/** Bốn giao diện Android dùng, đúng thứ tự `color.themes` của tokens.json. */
val THEME_IDS = listOf("light", "dark", "light-hc", "dark-hc")

/** Màu ARGB 32 bit của một token ở từng giao diện (đã lần hết bí danh `{token}`). */
data class ColorToken(val name: String, val usage: String, val argbByTheme: Map<String, Long>)

/** Kiểu chữ Android: cỡ và dòng tính bằng sp, tracking tính bằng em. */
data class TextStyleToken(
    val name: String,
    val fontFamily: String,
    val fontWeight: Int,
    val fontSizeSp: Int,
    val lineHeightSp: Int,
    val letterSpacingEm: String,
    val fontFeatureSettings: String?,
)

/** Token đơn trị (khoảng cách, bo góc, kích thước tính bằng dp; thời lượng tính bằng ms). */
data class ScalarToken(val name: String, val value: Int)

data class DesignTokens(
    val colors: List<ColorToken>,
    val textStyles: List<TextStyleToken>,
    val spacing: List<ScalarToken>,
    val radius: List<ScalarToken>,
    val size: List<ScalarToken>,
    val duration: List<ScalarToken>,
)

/** Lỗi dữ liệu token: task sinh mã dừng và build thất bại, không bao giờ sinh mã từ dữ liệu sai. */
class DesignTokenException(message: String) : RuntimeException(message)

/**
 * Đọc tokens.json theo cách hiểu chung với script Apple (M0.2):
 * màu một giá trị dùng cho cả 4 giao diện, `{token}` là bí danh; kiểu chữ `mac-*`, `ios-*` chỉ cho Apple.
 */
object DesignTokensParser {
    /** Họ chữ trong tokens.json → font đóng gói trên Android. `system` chỉ có `timer`: Android không có SF. */
    private val ANDROID_FONT_FAMILY = mapOf(
        "android" to "inter",
        "system" to "inter",
        "brand" to "beVietnamPro",
        "mono" to "robotoMono",
    )

    /** tokens.json chưa có trường tính năng OpenType; 03-kieu-chu.md quy định `timer` bật `tnum`. */
    private val FONT_FEATURES = mapOf("timer" to "tnum")

    private val APPLE_ONLY_PREFIXES = listOf("mac-", "ios-")
    private val HEX = Regex("^#([0-9a-fA-F]{6}|[0-9a-fA-F]{8})$")
    private val ALIAS = Regex("^\\{([a-z0-9-]+)}$")

    fun parse(file: File): DesignTokens {
        val root = JsonSlurper().parse(file).asMap("gốc")
        val color = root.req("color").asMap("color")
        val themeIds = color.req("themes").asList("color.themes").map { it.asMap("theme").req("id") }
        check(themeIds == THEME_IDS) { "color.themes phải đúng $THEME_IDS, đang là $themeIds" }
        return DesignTokens(
            colors = parseColors(color.req("tokens").asList("color.tokens")),
            textStyles = parseTextStyles(root.req("type").asMap("type")),
            spacing = parseScalars(root, "spacing", "px"),
            radius = parseScalars(root, "radius", "px"),
            size = parseScalars(root, "size", "px"),
            duration = parseScalars(root, "duration", "ms"),
        )
    }

    private fun parseColors(tokens: List<Any?>): List<ColorToken> {
        val raw = LinkedHashMap<String, Any?>()
        val usages = HashMap<String, String>()
        tokens.forEach {
            val token = it.asMap("color token")
            val name = token.req("name") as String
            check(raw.put(name, token.req("value")) == null) { "Màu trùng tên: $name" }
            usages[name] = token["usage"] as? String ?: ""
        }

        fun resolve(name: String, theme: String, seen: List<String>): Long {
            check(name !in seen) { "Bí danh vòng: ${(seen + name).joinToString(" → ")}" }
            val value = raw[name] ?: throw DesignTokenException("Bí danh trỏ tới màu không có: {$name}")
            val literal = when (value) {
                is String -> value
                is Map<*, *> -> value[theme] as? String ?: throw DesignTokenException("Màu $name thiếu giao diện $theme")
                else -> throw DesignTokenException("Màu $name có giá trị không hiểu: $value")
            }
            ALIAS.matchEntire(literal)?.let { return resolve(it.groupValues[1], theme, seen + name) }
            return parseHex(name, literal)
        }
        return raw.keys.map { name ->
            ColorToken(name, usages.getValue(name), THEME_IDS.associateWith { resolve(name, it, emptyList()) })
        }
    }

    private fun parseHex(name: String, literal: String): Long {
        check(HEX.matches(literal)) { "Màu $name không phải #rrggbb hoặc #rrggbbaa: $literal" }
        val rgb = literal.substring(1, 7).toLong(16)
        val alpha = if (literal.length == 9) literal.substring(7, 9).toLong(16) else 0xFF
        return (alpha shl 24) or rgb
    }

    private fun parseTextStyles(type: Map<String, Any?>): List<TextStyleToken> =
        type.req("groups").asList("type.groups")
            .flatMap { it.asMap("group").req("styles").asList("styles") }
            .map { it.asMap("style") }
            .filter { style -> APPLE_ONLY_PREFIXES.none { (style.req("name") as String).startsWith(it) } }
            .map { style ->
                val name = style.req("name") as String
                val family = style.req("family") as String
                TextStyleToken(
                    name = name,
                    fontFamily = ANDROID_FONT_FAMILY[family]
                        ?: throw DesignTokenException("Kiểu chữ $name dùng họ chưa có font Android: $family"),
                    fontWeight = (style.req("fontWeight") as Number).toInt(),
                    fontSizeSp = unit(name, style.req("fontSize"), "px"),
                    lineHeightSp = unit(name, style.req("lineHeight"), "px"),
                    letterSpacingEm = letterSpacing(name, style.req("letterSpacing") as String),
                    fontFeatureSettings = FONT_FEATURES[name],
                )
            }

    private fun letterSpacing(name: String, value: String): String {
        check(Regex("^-?\\d+(\\.\\d+)?em$").matches(value)) { "letterSpacing của $name phải tính bằng em: $value" }
        return value.removeSuffix("em")
    }

    private fun parseScalars(root: Map<String, Any?>, family: String, suffix: String): List<ScalarToken> =
        root.req(family).asMap(family).req("tokens").asList("$family.tokens").map {
            val token = it.asMap(family)
            val name = token.req("name") as String
            ScalarToken(name, unit(name, token.req("value"), suffix))
        }

    private fun unit(name: String, value: Any?, suffix: String): Int {
        val text = value as? String ?: throw DesignTokenException("$name: giá trị phải là chuỗi, đang là $value")
        check(Regex("^\\d+$suffix$").matches(text)) { "$name: giá trị phải là số nguyên + $suffix, đang là $text" }
        return text.removeSuffix(suffix).toInt()
    }

    private fun check(condition: Boolean, message: () -> String) {
        if (!condition) throw DesignTokenException(message())
    }

    private fun Map<String, Any?>.req(key: String): Any =
        this[key] ?: throw DesignTokenException("Thiếu trường \"$key\" trong ${keys.joinToString()}")

    private fun Any?.asMap(what: String): Map<String, Any?> =
        (this as? Map<*, *>)?.entries?.associate { (key, value) -> key.toString() to value }
            ?: throw DesignTokenException("$what phải là object JSON")

    private fun Any?.asList(what: String): List<Any?> =
        this as? List<Any?> ?: throw DesignTokenException("$what phải là mảng JSON")
}
