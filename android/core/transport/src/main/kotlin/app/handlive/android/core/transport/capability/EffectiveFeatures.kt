package app.handlive.android.core.transport.capability

import app.handlive.android.core.protocol.capability.CapabilityData
import app.handlive.android.core.protocol.capability.CapabilityFeatures

/**
 * Tính năng trong `capability.features` (0.7.2) và quyền Android mà thiếu thì tính năng không hiệu lực
 * (CONN-01 API 7, bảng quyền). Quyền chỉ hạ một thuộc tính con (`can_send`, `caller_id`…) không nằm ở đây.
 */
enum class Feature(
    val wire: String,
    val requiredAndroidPermissions: Set<String>,
) {
    CLIPBOARD("clipboard", emptySet()),
    SMS("sms", setOf("READ_SMS")),
    CALL("call", setOf("READ_PHONE_STATE")),
    CALL_AUDIO("call_audio", setOf("BLUETOOTH_CONNECT")),
    CAMERA("camera", setOf("CAMERA", "RECORD_AUDIO")),
    RELAY("relay", emptySet()),
    ;

    /** `features.<tên>.enabled`; tính năng vắng mặt (nền tảng không có) coi là tắt (0.7.2). */
    fun enabledIn(features: CapabilityFeatures): Boolean =
        when (this) {
            CLIPBOARD -> features.clipboard?.enabled
            SMS -> features.sms?.enabled
            CALL -> features.call?.enabled
            CALL_AUDIO -> features.callAudio?.enabled
            CAMERA -> features.camera?.enabled
            RELAY -> features.relay?.enabled
        } == true
}

/** Tính năng hiệu lực F = bật ở cả hai phía **và** Android không thiếu quyền cần cho F (0.7.2, CONN-01 API 7). */
object EffectiveFeatures {
    fun compute(
        android: CapabilityData,
        peer: CapabilityData,
    ): Set<Feature> {
        val missing =
            android.permissionsMissing
                .orEmpty()
                .map(::shortPermissionName)
                .toSet()
        return Feature.entries
            .filter { it.enabledIn(android.features) && it.enabledIn(peer.features) }
            .filter { feature -> feature.requiredAndroidPermissions.none { it in missing } }
            .toSet()
    }

    /** Chấp nhận cả `READ_SMS` lẫn `android.permission.READ_SMS` trong `permissions_missing`. */
    private fun shortPermissionName(permission: String): String = permission.substringAfterLast('.')
}
