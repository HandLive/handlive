package app.handlive.android.core.design.component

import androidx.compose.animation.core.animateDpAsState
import androidx.compose.animation.core.snap
import androidx.compose.animation.core.tween
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.offset
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.sizeIn
import androidx.compose.foundation.selection.toggleable
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.alpha
import androidx.compose.ui.draw.shadow
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.semantics.Role
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.semantics.stateDescription
import androidx.compose.ui.unit.IntOffset
import androidx.compose.ui.unit.dp
import app.handlive.android.core.design.R
import app.handlive.android.core.design.theme.HandLiveDurations
import app.handlive.android.core.design.theme.HandLiveTheme

private val TrackWidth = 51.dp
private val TrackHeight = 31.dp
private val ThumbInset = 2.dp
private val ThumbSize = TrackHeight - ThumbInset * 2
private const val DISABLED_ALPHA = 0.4f

/**
 * Công tắc kiểu iOS 51×31 dp (`components/Toggle/README.md`): bật `system-green`, tắt `system-fill`, núm trắng.
 * Trạng thái thể hiện bằng cả màu và vị trí núm; TalkBack đọc "Bật"/"Tắt" (`stateDescription`).
 *
 * @param onCheckedChange `null` khi cả dòng là vùng chạm (xem [HLGroupedListScope]); khi đó công tắc chỉ để nhìn
 *   và semantics nằm ở dòng. Khác `null` thì công tắc tự là control, vùng chạm ≥ 48 dp.
 */
@Composable
fun HLSwitch(
    checked: Boolean,
    onCheckedChange: ((Boolean) -> Unit)?,
    modifier: Modifier = Modifier,
    enabled: Boolean = true,
) {
    val stateText = switchStateDescription(checked)
    val interactive =
        if (onCheckedChange == null) {
            Modifier
        } else {
            Modifier
                .sizeIn(minWidth = HandLiveTheme.sizes.hitAndroid, minHeight = HandLiveTheme.sizes.hitAndroid)
                .toggleable(value = checked, enabled = enabled, role = Role.Switch, onValueChange = onCheckedChange)
                .semantics { stateDescription = stateText }
        }
    Box(modifier = modifier.then(interactive), contentAlignment = Alignment.Center) {
        HLSwitchTrack(checked = checked, enabled = enabled)
    }
}

/** "Bật" hoặc "Tắt" cho TalkBack (08-kha-nang-tiep-can.md, 03-android.md). */
@Composable
internal fun switchStateDescription(checked: Boolean): String =
    stringResource(if (checked) R.string.hl_switch_state_on else R.string.hl_switch_state_off)

@Composable
private fun HLSwitchTrack(
    checked: Boolean,
    enabled: Boolean,
) {
    val colors = HandLiveTheme.colors
    val animationsEnabled = rememberAnimationsEnabled()
    val thumbOffset by animateDpAsState(
        targetValue = if (checked) TrackWidth - ThumbSize - ThumbInset * 2 else 0.dp,
        animationSpec = if (animationsEnabled) tween(HandLiveDurations.quickMillis) else snap(),
        label = "HLSwitchThumb",
    )
    Box(
        modifier =
            Modifier
                .alpha(if (enabled) 1f else DISABLED_ALPHA)
                .size(TrackWidth, TrackHeight)
                .background(if (checked) colors.systemGreen else colors.systemFill, RoundedCornerShape(percent = 50))
                .padding(ThumbInset),
        contentAlignment = Alignment.CenterStart,
    ) {
        Box(
            modifier =
                Modifier
                    .offset { IntOffset(thumbOffset.roundToPx(), 0) }
                    .size(ThumbSize)
                    .shadow(elevation = 1.dp, shape = CircleShape)
                    // Núm trắng ở mọi giao diện như iOS; tokens.json chưa có token riêng cho núm.
                    .background(Color.White, CircleShape),
        )
    }
}
