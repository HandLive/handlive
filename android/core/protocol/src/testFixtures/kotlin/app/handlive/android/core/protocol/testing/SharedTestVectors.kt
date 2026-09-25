package app.handlive.android.core.protocol.testing

import kotlinx.serialization.json.Json
import kotlinx.serialization.json.JsonElement
import kotlinx.serialization.json.JsonNull
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.boolean
import kotlinx.serialization.json.int
import kotlinx.serialization.json.jsonArray
import kotlinx.serialization.json.jsonObject
import kotlinx.serialization.json.jsonPrimitive
import kotlinx.serialization.json.long
import java.io.File

/**
 * Đọc `shared/` (test vector S0.1, schema S0.2) — thư mục do Gradle truyền qua system property `hl.shared.dir`.
 */
object SharedTestVectors {
    val sharedDir: File by lazy {
        val path = System.getProperty("hl.shared.dir") ?: error("system property hl.shared.dir is not set")
        File(path).also { check(it.isDirectory) { "shared dir not found: $it" } }
    }

    val vectorsDir: File get() = File(sharedDir, "test-vectors")

    val schemasDir: File get() = File(sharedDir, "schemas")

    fun file(name: String): JsonObject = Json.parseToJsonElement(File(vectorsDir, name).readText()).jsonObject

    /** Vector dương (`vectors`) của một file. */
    fun vectors(name: String): List<JsonObject> = file(name).objects("vectors")

    /** Vector âm (`invalid_vectors`) — thao tác phải thất bại. */
    fun invalidVectors(name: String): List<JsonObject> =
        file(name)["invalid_vectors"]?.jsonArray?.map { it.jsonObject }.orEmpty()
}

fun JsonObject.objects(key: String): List<JsonObject> = getValue(key).jsonArray.map { it.jsonObject }

fun JsonObject.str(key: String): String = getValue(key).jsonPrimitive.content

fun JsonObject.strOrNull(key: String): String? = get(key)?.takeUnless { it is JsonNull }?.jsonPrimitive?.content

fun JsonObject.hex(key: String): ByteArray = Hex.decode(str(key))

fun JsonObject.int(key: String): Int = getValue(key).jsonPrimitive.int

fun JsonObject.long(key: String): Long = getValue(key).jsonPrimitive.long

fun JsonObject.bool(key: String): Boolean = getValue(key).jsonPrimitive.boolean

fun JsonObject.element(key: String): JsonElement = getValue(key)

/** Hex chữ thường, không tiền tố — quy ước của `shared/test-vectors`. */
object Hex {
    private const val RADIX = 16
    private const val BYTE_MASK = 0xff

    fun decode(text: String): ByteArray {
        require(text.length % 2 == 0) { "odd hex length" }
        return ByteArray(text.length / 2) { i -> text.substring(i * 2, i * 2 + 2).toInt(RADIX).toByte() }
    }

    fun encode(bytes: ByteArray): String = bytes.joinToString("") { "%02x".format(it.toInt() and BYTE_MASK) }
}
