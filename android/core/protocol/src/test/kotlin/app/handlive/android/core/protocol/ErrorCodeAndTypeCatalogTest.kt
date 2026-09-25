package app.handlive.android.core.protocol

import app.handlive.android.core.protocol.envelope.MessageType
import app.handlive.android.core.protocol.testing.SharedTestVectors
import kotlinx.serialization.json.Json
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.jsonArray
import kotlinx.serialization.json.jsonObject
import kotlinx.serialization.json.jsonPrimitive
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Test
import java.io.File

/** Enum trong mã phải trùng đúng danh mục của schema S0.2 (sinh từ 0.7.1, 0.8.1). */
class ErrorCodeAndTypeCatalogTest {
    private fun schemaEnum(
        file: String,
        def: String,
    ): List<String> {
        val schema = Json.parseToJsonElement(File(SharedTestVectors.schemasDir, file).readText()) as JsonObject
        val defs = schema.getValue("\$defs").jsonObject
        return defs
            .getValue(def)
            .jsonObject
            .getValue("enum")
            .jsonArray
            .map { it.jsonPrimitive.content }
    }

    @Test
    fun errorCodesMatchSchemaInOrder() {
        assertEquals(schemaEnum("error.schema.json", "code"), ErrorCode.entries.map { it.name })
    }

    @Test
    fun messageTypesMatchSchemaInOrder() {
        assertEquals(schemaEnum("envelope.schema.json", "type"), MessageType.entries.map { it.wire })
    }

    @Test
    fun unknownWireValuesMapToNull() {
        assertNull(ErrorCode.fromWire("NOT_A_CODE"))
        assertNull(MessageType.fromWire("notification"))
        assertEquals(ErrorCode.SMS_NO_SERVICE, ErrorCode.fromWire("SMS_NO_SERVICE"))
    }
}
