package app.handlive.android.core.design.preview

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Row
import androidx.compose.runtime.Composable
import androidx.compose.ui.tooling.preview.Preview
import androidx.compose.ui.tooling.preview.PreviewParameter
import app.handlive.android.core.design.component.HLSwitch
import app.handlive.android.core.design.theme.HandLiveAppearance
import app.handlive.android.core.design.theme.HandLiveTheme

/** Bật, tắt và vô hiệu. */
@Composable
internal fun HLSwitchPreviewGallery() {
    Row(horizontalArrangement = Arrangement.spacedBy(HandLiveTheme.spacing.space8)) {
        HLSwitch(checked = true, onCheckedChange = {})
        HLSwitch(checked = false, onCheckedChange = {})
        HLSwitch(checked = true, onCheckedChange = {}, enabled = false)
        HLSwitch(checked = false, onCheckedChange = {}, enabled = false)
    }
}

@Preview
@Composable
private fun HLSwitchPreview(
    @PreviewParameter(HandLiveAppearancePreviewProvider::class) appearance: HandLiveAppearance,
) {
    HandLivePreviewSurface(appearance, background = { it.secondarySystemGroupedBackground }) {
        HLSwitchPreviewGallery()
    }
}
