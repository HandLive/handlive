package app.handlive.android.core.protocol

import app.handlive.android.core.protocol.capability.CallAudioFeature
import app.handlive.android.core.protocol.capability.CallFeature
import app.handlive.android.core.protocol.capability.CameraFeature
import app.handlive.android.core.protocol.capability.CapabilityData
import app.handlive.android.core.protocol.capability.CapabilityFeatures
import app.handlive.android.core.protocol.capability.CapabilityOp
import app.handlive.android.core.protocol.capability.ClipboardFeature
import app.handlive.android.core.protocol.capability.OpusFallback
import app.handlive.android.core.protocol.capability.RelayFeature
import app.handlive.android.core.protocol.capability.SimInfo
import app.handlive.android.core.protocol.capability.SmsFeature
import app.handlive.android.core.protocol.session.PROTOCOL_VERSION

/** Ảnh chụp capability mẫu theo ví dụ 0.7.2 (Android đầy đủ; Mac, iPhone rút gọn). */
object CapabilitySamples {
    private val android =
        CapabilityData(
            protocol = PROTOCOL_VERSION,
            appVersion = "1.0.0 (100)",
            platform = "android",
            osVersion = "15",
            model = "Pixel 8",
            features =
                CapabilityFeatures(
                    clipboard =
                        ClipboardFeature(
                            enabled = true,
                            autoSend = true,
                            maxTextBytes = 1_048_576,
                            maxImageBytes = 10_485_760,
                            mimes = listOf("text/plain", "image/png", "image/jpeg"),
                        ),
                    sms =
                        SmsFeature(
                            enabled = true,
                            canSend = true,
                            sims = listOf(SimInfo(1, 0, "SIM 1")),
                            defaultSubId = 1,
                        ),
                    call = CallFeature(enabled = true, canAnswer = true, canEnd = true, callerId = true),
                    callAudio =
                        CallAudioFeature(
                            enabled = false,
                            hfpConnected = false,
                            opusFallback = OpusFallback(false, false, false, "shizuku_not_running"),
                        ),
                    camera = CameraFeature(true, listOf("front", "back"), 1920, 1080, 30, listOf("h264")),
                    relay = RelayFeature(enabled = true),
                ),
            permissionsMissing = listOf("READ_CALL_LOG"),
        )

    private val mac =
        CapabilityData(
            protocol = PROTOCOL_VERSION,
            appVersion = "1.0.0 (100)",
            platform = "macos",
            osVersion = "15.1",
            model = "MacBookPro18,3",
            features =
                CapabilityFeatures(
                    clipboard = ClipboardFeature(enabled = true, autoSend = true),
                    callAudio = CallAudioFeature(enabled = true, btAddress = "A1:B2:C3:D4:E5:F6", consented = true),
                    relay = RelayFeature(enabled = false),
                ),
        )

    private val iphone =
        CapabilityData(
            protocol = PROTOCOL_VERSION,
            appVersion = "1.0.0 (100)",
            platform = "ios",
            osVersion = "18.0",
            model = "iPhone15,2",
            features =
                CapabilityFeatures(
                    sms = SmsFeature(enabled = true, notify = true),
                    call = CallFeature(enabled = true, notify = false),
                ),
        )

    fun all(): List<Pair<String, CapabilityData>> =
        listOf(
            CapabilityOp.HELLO to android,
            CapabilityOp.UPDATE to android.copy(features = android.features.copy(camera = null)),
            CapabilityOp.HELLO to mac,
            CapabilityOp.UPDATE to iphone,
        )
}
