package app.handlive.android.core.protocol.envelope

import kotlinx.serialization.Serializable
import kotlinx.serialization.json.JsonObject

/** Plaintext chung của payload (0.5.1): `{op, data}`; `data` tùy theo thao tác. */
@Serializable
data class Payload(
    val op: String,
    val data: JsonObject,
)

/** Plaintext `{op, data}` với `data` có kiểu, dùng cho các thao tác đã mô hình hóa (session, capability…). */
@Serializable
data class OpPayload<T>(
    val op: String,
    val data: T,
)
