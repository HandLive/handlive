package app.handlive.android.core.transport.capability

import app.handlive.android.core.protocol.capability.CallAudioFeature
import app.handlive.android.core.protocol.capability.CameraFeature
import app.handlive.android.core.protocol.capability.CapabilityFeatures
import app.handlive.android.core.transport.testing.LoopbackServerFixture.Companion.ANDROID_CAPABILITY
import app.handlive.android.core.transport.testing.LoopbackServerFixture.Companion.MAC_CAPABILITY
import org.junit.Assert.assertEquals
import org.junit.Test

/** Tính năng hiệu lực = bật ở cả hai phía và Android đủ quyền (0.7.2, CONN-01 API 7). */
class EffectiveFeaturesTest {
    @Test
    fun featureNeedsBothSidesEnabled() {
        val android = ANDROID_CAPABILITY.copy(permissionsMissing = emptyList())
        // Android: relay tắt; Mac: sms tắt → chỉ clipboard, call, camera.
        assertEquals(
            setOf(Feature.CLIPBOARD, Feature.CALL, Feature.CAMERA),
            EffectiveFeatures.compute(android, MAC_CAPABILITY),
        )
    }

    @Test
    fun featureAbsentOnPlatformCountsAsDisabled() {
        val android = ANDROID_CAPABILITY.copy(permissionsMissing = emptyList())
        val iphone = MAC_CAPABILITY.copy(platform = "ios", features = MAC_CAPABILITY.features.copy(camera = null))
        assertEquals(setOf(Feature.CLIPBOARD, Feature.CALL), EffectiveFeatures.compute(android, iphone))
    }

    @Test
    fun missingAndroidPermissionDisablesOnlyTheFeatureThatNeedsIt() {
        val bothOn =
            CapabilityFeatures(
                camera = CameraFeature(enabled = true),
                callAudio = CallAudioFeature(enabled = true),
            )
        val android = ANDROID_CAPABILITY.copy(features = bothOn, permissionsMissing = listOf("RECORD_AUDIO"))
        val mac = MAC_CAPABILITY.copy(features = bothOn)
        assertEquals(setOf(Feature.CALL_AUDIO), EffectiveFeatures.compute(android, mac))

        val fullName = android.copy(permissionsMissing = listOf("android.permission.BLUETOOTH_CONNECT"))
        assertEquals(setOf(Feature.CAMERA), EffectiveFeatures.compute(fullName, mac))
    }

    @Test
    fun peerPermissionsMissingIsIgnoredBecauseOnlyAndroidReportsIt() {
        val android = ANDROID_CAPABILITY.copy(permissionsMissing = emptyList())
        val mac = MAC_CAPABILITY.copy(permissionsMissing = listOf("CAMERA"))
        assertEquals(
            setOf(Feature.CLIPBOARD, Feature.CALL, Feature.CAMERA),
            EffectiveFeatures.compute(android, mac),
        )
    }
}
