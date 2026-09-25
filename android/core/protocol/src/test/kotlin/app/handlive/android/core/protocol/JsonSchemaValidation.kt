package app.handlive.android.core.protocol

import app.handlive.android.core.protocol.testing.SharedTestVectors
import com.networknt.schema.InputFormat
import com.networknt.schema.SchemaLocation
import com.networknt.schema.SchemaRegistry
import com.networknt.schema.SpecificationVersion
import org.junit.Assert.assertTrue

/**
 * Nạp cả thư mục shared/schemas vào registry trong bộ nhớ, khóa theo `$id` https://handlive.app/schemas/v1/<file>;
 * không tải gì qua mạng.
 */
object JsonSchemaValidation {
    private const val ID_PREFIX = "https://handlive.app/schemas/v1/"

    private val registry: SchemaRegistry by lazy {
        val schemas =
            SharedTestVectors.schemasDir
                .listFiles { file -> file.name.endsWith(".schema.json") }
                .orEmpty()
                .associate { ID_PREFIX + it.name to it.readText() }
        SchemaRegistry.withDefaultDialect(SpecificationVersion.DRAFT_2020_12) { builder ->
            builder.schemaLoader { loader -> loader.resourceLoaders { it.resources(schemas) } }
        }
    }

    /** [schemaRef] dạng `envelope.schema.json` hoặc `session-rekey.schema.json#/$defs/ack`. */
    fun errors(
        schemaRef: String,
        json: String,
    ): List<String> =
        registry
            .getSchema(SchemaLocation.of(ID_PREFIX + schemaRef))
            .validate(json, InputFormat.JSON)
            .map { it.toString() }

    fun assertValid(
        schemaRef: String,
        json: String,
    ) {
        val errors = errors(schemaRef, json)
        assertTrue("$schemaRef: $errors\n$json", errors.isEmpty())
    }
}
