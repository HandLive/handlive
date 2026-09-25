package app.handlive.android.core.design.component

import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.interaction.MutableInteractionSource
import androidx.compose.foundation.interaction.collectIsPressedAsState
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.sizeIn
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.BasicText
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.alpha
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.lerp
import androidx.compose.ui.semantics.Role
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import app.handlive.android.core.design.theme.HandLiveColors
import app.handlive.android.core.design.theme.HandLiveTheme

/** Nhấn thì tối đi 8%, không gợn sóng (Button/README.md, mục Trạng thái). */
private const val PRESSED_DARKEN_FRACTION = 0.08f

/** Vô hiệu: độ mờ 40%; màn gọi phải có dòng lý do gần nút. */
private const val DISABLED_ALPHA = 0.4f

private val ProminentHeight: Dp = 50.dp

/**
 * Nút capsule kiểu Apple: chữ Inter 17 sp Semibold (`android-headline`), cao 50 dp (chính) hoặc 48 dp (phụ).
 * TalkBack đọc nhãn kèm vai trò Nút; vô hiệu thì đọc "đã tắt".
 *
 * @param text nhãn bắt đầu bằng động từ, sentence case, ví dụ "Ghép nối", "Gửi bảng nhớ tạm".
 */
@Composable
fun HLButton(
    text: String,
    onClick: () -> Unit,
    modifier: Modifier = Modifier,
    style: HLButtonStyle = HLButtonStyle.Prominent,
    enabled: Boolean = true,
) {
    val colors = HandLiveTheme.colors
    val interactionSource = remember { MutableInteractionSource() }
    val pressed by interactionSource.collectIsPressedAsState()
    val palette = style.palette(colors)
    val shape = RoundedCornerShape(percent = 50)
    val container = palette.container?.let { if (pressed) it.darkened() else it }
    val content = if (pressed && container == null) palette.content.darkened() else palette.content
    val minHeight = if (style == HLButtonStyle.Prominent) ProminentHeight else HandLiveTheme.sizes.hitAndroid

    Box(
        modifier =
            modifier
                .alpha(if (enabled) 1f else DISABLED_ALPHA)
                .sizeIn(
                    minWidth = HandLiveTheme.sizes.hitAndroid,
                    minHeight = minHeight,
                ).then(if (container != null) Modifier.background(container, shape) else Modifier)
                .then(palette.border?.let { Modifier.border(BorderStroke(1.dp, it), shape) } ?: Modifier)
                .clickable(
                    interactionSource = interactionSource,
                    indication = null,
                    enabled = enabled,
                    role = Role.Button,
                    onClick = onClick,
                ).padding(horizontal = HandLiveTheme.spacing.space20, vertical = HandLiveTheme.spacing.space12),
        contentAlignment = Alignment.Center,
    ) {
        BasicText(
            text = text,
            style = HandLiveTheme.typography.headline.copy(color = content, textAlign = TextAlign.Center),
        )
    }
}

private class HLButtonPalette(
    val container: Color?,
    val content: Color,
    val border: Color? = null,
)

private fun HLButtonStyle.palette(colors: HandLiveColors): HLButtonPalette =
    when (this) {
        HLButtonStyle.Prominent -> HLButtonPalette(colors.accentFill, colors.onAccent)
        HLButtonStyle.Glass -> HLButtonPalette(colors.glassFill, colors.label, colors.glassStroke)
        HLButtonStyle.Tinted -> HLButtonPalette(colors.accentTint, colors.accent)
        HLButtonStyle.Plain -> HLButtonPalette(null, colors.accent)
        HLButtonStyle.Destructive -> HLButtonPalette(colors.glassFill, colors.destructiveText, colors.glassStroke)
    }

private fun Color.darkened(): Color = lerp(this, Color.Black.copy(alpha = alpha), PRESSED_DARKEN_FRACTION)
