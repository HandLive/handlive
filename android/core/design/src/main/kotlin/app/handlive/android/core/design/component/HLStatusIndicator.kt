package app.handlive.android.core.design.component

import androidx.compose.animation.core.InfiniteRepeatableSpec
import androidx.compose.animation.core.RepeatMode
import androidx.compose.animation.core.animateFloat
import androidx.compose.animation.core.infiniteRepeatable
import androidx.compose.animation.core.rememberInfiniteTransition
import androidx.compose.animation.core.tween
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.BasicText
import androidx.compose.runtime.Composable
import androidx.compose.runtime.State
import androidx.compose.runtime.mutableFloatStateOf
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.semantics.LiveRegionMode
import androidx.compose.ui.semantics.clearAndSetSemantics
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.liveRegion
import app.handlive.android.core.design.R
import app.handlive.android.core.design.theme.HandLiveDurations
import app.handlive.android.core.design.theme.HandLiveTheme

/** Độ mờ thấp nhất của nhịp chấm (1 → 0.35 → 1 trong một chu kỳ `duration-pulse`), giống bản Apple. */
private const val PULSE_MIN_ALPHA = 0.35f

/**
 * Chỉ báo liên kết (`components/StatusIndicator/README.md`): chấm tô màu trạng thái luôn đi kèm chữ.
 * TalkBack đọc cả câu ("Đã kết nối qua Wi-Fi với Pixel 8 của Lan"); là live region lịch sự nên đổi trạng thái
 * được đọc mà không dời focus.
 *
 * Material Symbols chưa có ở Phase 0 nên mọi trạng thái dùng chấm; biểu tượng (`wifi`, `public`…) thêm sau.
 */
@Composable
fun HLStatusIndicator(
    status: HLConnectionStatus,
    modifier: Modifier = Modifier,
    deviceName: String? = null,
    variant: HLStatusIndicatorVariant = HLStatusIndicatorVariant.Inline,
) {
    val colors = HandLiveTheme.colors
    val spacing = HandLiveTheme.spacing
    val fullText = statusText(status)
    val spoken =
        if (deviceName.isNullOrBlank() || !status.readsDeviceName) {
            fullText
        } else {
            stringResource(R.string.hl_status_with_device, fullText, deviceName)
        }
    val isPill = variant == HLStatusIndicatorVariant.Pill
    val shownText =
        if (isPill && status == HLConnectionStatus.ConnectedWiFi) {
            stringResource(R.string.hl_status_connected_wifi_short)
        } else {
            fullText
        }

    Row(
        modifier =
            modifier
                .clearAndSetSemantics {
                    contentDescription = spoken
                    liveRegion = LiveRegionMode.Polite
                }.then(
                    if (isPill) {
                        Modifier
                            .background(colors.tertiarySystemFill, RoundedCornerShape(percent = 50))
                            .padding(horizontal = spacing.space8, vertical = spacing.space4)
                    } else {
                        Modifier
                    },
                ),
        horizontalArrangement = Arrangement.spacedBy(if (isPill) spacing.space4 else spacing.space8),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        StatusDot(color = status.tint(colors), pulses = status.pulses)
        BasicText(
            text = shownText,
            style =
                HandLiveTheme.typography.subheadline.copy(
                    color = if (isPill) colors.label else colors.secondaryLabel,
                ),
        )
    }
}

@Composable
private fun statusText(status: HLConnectionStatus): String =
    if (status is HLConnectionStatus.PhoneOffline && status.lastSeen != null) {
        stringResource(status.textRes, status.lastSeen)
    } else {
        stringResource(status.textRes)
    }

@Composable
private fun StatusDot(
    color: Color,
    pulses: Boolean,
) {
    // Đọc giá trị trong graphicsLayer để nhịp chỉ vẽ lại, không dựng lại cây.
    val alpha: State<Float> =
        if (pulses && rememberAnimationsEnabled()) {
            rememberInfiniteTransition(label = "HLStatusPulse").animateFloat(
                initialValue = 1f,
                targetValue = PULSE_MIN_ALPHA,
                animationSpec = pulseSpec,
                label = "HLStatusPulseAlpha",
            )
        } else {
            remember { mutableFloatStateOf(1f) }
        }
    Box(
        modifier =
            Modifier
                .size(HandLiveTheme.spacing.space8)
                .graphicsLayer { this.alpha = alpha.value }
                .background(color, CircleShape),
    )
}

/** Nửa chu kỳ mờ đi, nửa chu kỳ sáng lại: trọn một nhịp đúng `duration-pulse`. */
private val pulseSpec: InfiniteRepeatableSpec<Float> =
    infiniteRepeatable(tween(HandLiveDurations.pulseMillis / 2), RepeatMode.Reverse)
