package app.handlive.android.core.design.preview

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.tooling.preview.Preview
import androidx.compose.ui.tooling.preview.PreviewParameter
import app.handlive.android.core.design.component.HLButton
import app.handlive.android.core.design.component.HLButtonStyle
import app.handlive.android.core.design.theme.HandLiveAppearance
import app.handlive.android.core.design.theme.HandLiveTheme

/** Đủ năm kiểu nút; nhãn lấy nguyên văn Button/README.md và 04-cai-dat.md. */
@Composable
internal fun HLButtonPreviewGallery() {
    Column(verticalArrangement = Arrangement.spacedBy(HandLiveTheme.spacing.space12)) {
        HLButton(text = "Ghép nối", onClick = {}, modifier = Modifier.fillMaxWidth())
        HLButton(text = "Gửi bảng nhớ tạm", onClick = {}, style = HLButtonStyle.Glass)
        HLButton(text = "Mở cài đặt", onClick = {}, style = HLButtonStyle.Tinted)
        HLButton(text = "Cài đặt…", onClick = {}, style = HLButtonStyle.Plain)
        HLButton(text = "Hủy ghép nối", onClick = {}, style = HLButtonStyle.Destructive)
        HLButton(text = "Ghép nối", onClick = {}, enabled = false)
    }
}

@Preview(widthDp = 360)
@Composable
private fun HLButtonPreview(
    @PreviewParameter(HandLiveAppearancePreviewProvider::class) appearance: HandLiveAppearance,
) {
    HandLivePreviewSurface(appearance) { HLButtonPreviewGallery() }
}
