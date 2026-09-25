package app.handlive.android.core.protocol.capability

import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

/** Tên `op` của `type = capability` (0.7.1). */
object CapabilityOp {
    const val HELLO = "hello"
    const val UPDATE = "update"
}

/**
 * `data` của `capability/hello` và `capability/update` (0.7.2) — luôn là ảnh chụp đầy đủ.
 * Tính năng nền tảng không có thì để `null` (vắng mặt trong `features`, coi là tắt).
 */
@Serializable
data class CapabilityData(
    val protocol: Int,
    @SerialName("app_version") val appVersion: String,
    val platform: String,
    @SerialName("os_version") val osVersion: String,
    val model: String,
    val features: CapabilityFeatures,
    @SerialName("permissions_missing") val permissionsMissing: List<String>? = null,
)

@Serializable
data class CapabilityFeatures(
    val clipboard: ClipboardFeature? = null,
    val sms: SmsFeature? = null,
    val call: CallFeature? = null,
    @SerialName("call_audio") val callAudio: CallAudioFeature? = null,
    val camera: CameraFeature? = null,
    val relay: RelayFeature? = null,
)

@Serializable
data class ClipboardFeature(
    val enabled: Boolean,
    @SerialName("auto_send") val autoSend: Boolean? = null,
    @SerialName("max_text_bytes") val maxTextBytes: Long? = null,
    @SerialName("max_image_bytes") val maxImageBytes: Long? = null,
    val mimes: List<String>? = null,
)

@Serializable
data class SmsFeature(
    val enabled: Boolean,
    @SerialName("can_send") val canSend: Boolean? = null,
    val sims: List<SimInfo>? = null,
    @SerialName("default_sub_id") val defaultSubId: Int? = null,
    val notify: Boolean? = null,
)

@Serializable
data class SimInfo(
    @SerialName("sub_id") val subId: Int,
    val slot: Int,
    val label: String,
)

@Serializable
data class CallFeature(
    val enabled: Boolean,
    @SerialName("can_answer") val canAnswer: Boolean? = null,
    @SerialName("can_end") val canEnd: Boolean? = null,
    @SerialName("caller_id") val callerId: Boolean? = null,
    val notify: Boolean? = null,
)

@Serializable
data class CallAudioFeature(
    val enabled: Boolean,
    @SerialName("bt_address") val btAddress: String? = null,
    @SerialName("hfp_connected") val hfpConnected: Boolean? = null,
    val consented: Boolean? = null,
    @SerialName("opus_fallback") val opusFallback: OpusFallback? = null,
)

/** `reason` ∈ {ok, disabled, android_10, shizuku_not_running, capture_silent, uplink_unsupported}. */
@Serializable
data class OpusFallback(
    val available: Boolean,
    val downlink: Boolean,
    val uplink: Boolean,
    val reason: String,
)

@Serializable
data class CameraFeature(
    val enabled: Boolean,
    val cameras: List<String>? = null,
    @SerialName("max_width") val maxWidth: Int? = null,
    @SerialName("max_height") val maxHeight: Int? = null,
    @SerialName("max_fps") val maxFps: Int? = null,
    val codecs: List<String>? = null,
)

@Serializable
data class RelayFeature(
    val enabled: Boolean,
)
