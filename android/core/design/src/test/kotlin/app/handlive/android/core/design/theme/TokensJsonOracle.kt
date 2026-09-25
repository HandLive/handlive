package app.handlive.android.core.design.theme

import kotlinx.serialization.json.Json
import kotlinx.serialization.json.JsonElement
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.JsonPrimitive
import kotlinx.serialization.json.int
import kotlinx.serialization.json.jsonArray
import kotlinx.serialization.json.jsonObject
import kotlinx.serialization.json.jsonPrimitive
import java.io.File

/**
 * Đọc shared/design-tokens/tokens.json độc lập với generator trong buildSrc, làm "đáp án" cho test:
 * generator hiểu sai hay mã sinh lệch tokens.json thì test đỏ và `check` thất bại.
 */
object TokensJsonOracle {
    val sharedDir = File(requireNotNull(System.getProperty("hl.shared.dir")) { "Thiếu -Dhl.shared.dir" })
    val docsDir = File(requireNotNull(System.getProperty("hl.docs.dir")) { "Thiếu -Dhl.docs.dir" })

    val root: JsonObject by lazy {
        Json.parseToJsonElement(sharedDir.resolve("design-tokens/tokens.json").readText()).jsonObject
    }

    val themeIds: List<String> by lazy {
        root.obj("color")["themes"]!!.jsonArray.map { it.jsonObject.string("id") }
    }

    /** Tên màu → (id giao diện → ARGB), đã lần bí danh `{token}`. */
    val colors: Map<String, Map<String, Long>> by lazy {
        val raw =
            root.obj("color")["tokens"]!!.jsonArray.associate {
                it.jsonObject.string("name") to
                    it.jsonObject["value"]!!
            }

        fun resolve(
            name: String,
            theme: String,
        ): Long {
            val value = raw.getValue(name)
            val literal = if (value is JsonPrimitive) value.content else value.jsonObject.string(theme)
            val alias = Regex("^\\{(.+)}$").matchEntire(literal)
            return if (alias != null) resolve(alias.groupValues[1], theme) else argb(literal)
        }
        raw.keys.associateWith { name -> themeIds.associateWith { resolve(name, it) } }
    }

    /** Mọi kiểu chữ trong tokens.json, theo tên. */
    val textStyles: Map<String, JsonObject> by lazy {
        root
            .obj("type")["groups"]!!
            .jsonArray
            .flatMap { it.jsonObject["styles"]!!.jsonArray }
            .associate { it.jsonObject.string("name") to it.jsonObject }
    }

    /** Họ token đơn trị (`spacing`, `radius`, `size`, `duration`): tên → số (bỏ đơn vị). */
    fun scalars(family: String): Map<String, Int> =
        root.obj(family)["tokens"]!!.jsonArray.associate {
            val value = it.jsonObject.string("value")
            it.jsonObject.string("name") to value.removeSuffix("px").removeSuffix("ms").toInt()
        }

    fun JsonObject.string(key: String): String = this[key]!!.jsonPrimitive.content

    fun JsonObject.int(key: String): Int = this[key]!!.jsonPrimitive.int

    /** "34px" → 34.0; "-0.010em" → -0.010. */
    fun JsonObject.number(key: String): Float =
        string(key)
            .removeSuffix("px")
            .removeSuffix("em")
            .toFloat()

    private fun JsonObject.obj(key: String): JsonObject = (this[key] as JsonElement).jsonObject

    /** "#rrggbb" hoặc "#rrggbbaa" (alpha cuối, kiểu CSS) → 0xAARRGGBB. */
    fun argb(hex: String): Long {
        require(Regex("^#[0-9a-fA-F]{6}([0-9a-fA-F]{2})?$").matches(hex)) { "Hex lạ: $hex" }
        val alpha = if (hex.length == 9) hex.substring(7, 9).toLong(16) else 0xFF
        return (alpha shl 24) or hex.substring(1, 7).toLong(16)
    }
}
