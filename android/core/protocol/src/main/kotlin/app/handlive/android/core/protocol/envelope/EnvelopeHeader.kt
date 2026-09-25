package app.handlive.android.core.protocol.envelope

/** Các trường không mã hóa của envelope (`v`, `type`, `id`, `ts`) — đồng thời là nguồn của AAD (0.5.1). */
data class EnvelopeHeader(
    val type: String,
    val id: String,
    val ts: Long,
    val v: Int = Envelope.VERSION,
) {
    fun aad(): ByteArray = Envelope.aadString(v, type, id, ts).toByteArray(Charsets.UTF_8)

    fun withPayload(payload: String): Envelope = Envelope(v, type, id, ts, payload)
}
