package app.handlive.android.core.design.preview

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.runtime.Composable
import androidx.compose.ui.tooling.preview.Preview
import androidx.compose.ui.tooling.preview.PreviewParameter
import app.handlive.android.core.design.component.HLConnectionStatus
import app.handlive.android.core.design.component.HLStatusIndicator
import app.handlive.android.core.design.component.HLStatusIndicatorVariant
import app.handlive.android.core.design.theme.HandLiveAppearance
import app.handlive.android.core.design.theme.HandLiveTheme

/** Đủ tám trạng thái của StatusIndicator/README.md và dạng viên. */
@Composable
internal fun HLStatusIndicatorPreviewGallery() {
    val statuses =
        listOf(
            HLConnectionStatus.ConnectedWiFi,
            HLConnectionStatus.ConnectedInternet,
            HLConnectionStatus.Usb,
            HLConnectionStatus.Connecting,
            HLConnectionStatus.PhoneOffline(lastSeen = "14:05"),
            HLConnectionStatus.NetworkLost,
            HLConnectionStatus.NeedsRepair,
            HLConnectionStatus.CameraStreaming,
        )
    Column(verticalArrangement = Arrangement.spacedBy(HandLiveTheme.spacing.space8)) {
        statuses.forEach { HLStatusIndicator(status = it, deviceName = "Pixel 8 của Lan") }
        HLStatusIndicator(
            status = HLConnectionStatus.ConnectedWiFi,
            deviceName = "Pixel 8 của Lan",
            variant = HLStatusIndicatorVariant.Pill,
        )
    }
}

@Preview(widthDp = 360)
@Composable
private fun HLStatusIndicatorPreview(
    @PreviewParameter(HandLiveAppearancePreviewProvider::class) appearance: HandLiveAppearance,
) {
    HandLivePreviewSurface(appearance) { HLStatusIndicatorPreviewGallery() }
}
