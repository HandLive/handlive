package app.handlive.android.core.design.component

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.LazyListScope
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.BasicText
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.semantics.heading
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.font.FontWeight
import app.handlive.android.core.design.theme.HandLiveTheme

@DslMarker
annotation class HLGroupedListDsl

/**
 * Danh sách nhóm kiểu Cài đặt của iPhone (`components/GroupedList/README.md`), dựng bằng `LazyColumn`:
 * `HLGroupedList { section(title, footer) { switchRow(...) } }`.
 * Nền `system-grouped-background`; nhóm `secondary-system-grouped-background` bo `radius-sheet`; dòng ≥ 56 dp.
 */
@Composable
fun HLGroupedList(
    modifier: Modifier = Modifier,
    contentPadding: PaddingValues = PaddingValues(vertical = HandLiveTheme.spacing.space16),
    content: HLGroupedListScope.() -> Unit,
) {
    LazyColumn(
        modifier = modifier.background(HandLiveTheme.colors.systemGroupedBackground),
        contentPadding = contentPadding,
        verticalArrangement = Arrangement.spacedBy(HandLiveTheme.spacing.space24),
    ) {
        HLGroupedListScope(this).content()
    }
}

/** Phạm vi khai báo nhóm của [HLGroupedList]. */
@HLGroupedListDsl
class HLGroupedListScope internal constructor(
    private val lazyListScope: LazyListScope,
) {
    /**
     * Một nhóm bo góc. [title] sentence case, không viết hoa toàn bộ; [footer] là câu hoàn chỉnh nói hệ quả.
     * Nhóm có hành động phá hủy luôn đặt cuối danh sách.
     */
    fun section(
        title: String? = null,
        footer: String? = null,
        key: Any? = null,
        rows: HLGroupedSectionScope.() -> Unit,
    ) {
        val sectionRows = HLGroupedSectionScope().apply(rows).rows.toList()
        lazyListScope.item(key = key) { HLGroupedSection(title = title, footer = footer, rows = sectionRows) }
    }
}

/** Phạm vi khai báo dòng trong một nhóm; mỗi dòng là một vùng chạm. */
@HLGroupedListDsl
class HLGroupedSectionScope internal constructor() {
    internal val rows = mutableListOf<@Composable () -> Unit>()

    /** Dòng tự dựng; nên bọc nội dung trong [HLGroupedRow] để giữ cao ≥ 56 dp và lề chuẩn. */
    fun row(content: @Composable () -> Unit) {
        rows += content
    }

    /** Dòng mở màn con: tiêu đề, giá trị `secondary-label` bên phải, mũi tên `tertiary-label`. */
    fun navigationRow(
        title: String,
        onClick: () -> Unit,
        value: String? = null,
    ) = row { HLNavigationRow(title = title, value = value, onClick = onClick) }

    /**
     * Dòng công tắc; cả dòng là vùng chạm (`Role.Switch`). [unavailableReason] khác `null` thì công tắc vô hiệu
     * và lý do hiện dưới tiêu đề màu `text-orange`, ví dụ "Thiếu quyền SMS trên điện thoại".
     */
    fun switchRow(
        title: String,
        checked: Boolean,
        onCheckedChange: (Boolean) -> Unit,
        unavailableReason: String? = null,
    ) = row {
        HLSwitchRow(
            title = title,
            checked = checked,
            onCheckedChange = onCheckedChange,
            unavailableReason = unavailableReason,
        )
    }

    /** Dòng hành động: chữ `accent`; [destructive] thì chữ `destructive-text` và luôn hỏi xác nhận bằng Alert. */
    fun actionRow(
        title: String,
        onClick: () -> Unit,
        destructive: Boolean = false,
    ) = row { HLActionRow(title = title, destructive = destructive, onClick = onClick) }
}

@Composable
private fun HLGroupedSection(
    title: String?,
    footer: String?,
    rows: List<@Composable () -> Unit>,
) {
    val colors = HandLiveTheme.colors
    val spacing = HandLiveTheme.spacing
    val captionStyle = HandLiveTheme.typography.footnote.copy(color = colors.secondaryLabel)
    Column(modifier = Modifier.fillMaxWidth().padding(horizontal = spacing.marginCompact)) {
        if (title != null) {
            BasicText(
                text = title,
                style = captionStyle.copy(fontWeight = FontWeight.SemiBold),
                modifier =
                    Modifier
                        .padding(start = spacing.space16, end = spacing.space16, bottom = spacing.space8)
                        .semantics { heading() },
            )
        }
        Column(
            modifier =
                Modifier
                    .fillMaxWidth()
                    .clip(RoundedCornerShape(HandLiveTheme.radius.sheet))
                    .background(colors.secondarySystemGroupedBackground),
        ) {
            rows.forEachIndexed { index, row ->
                if (index > 0) RowSeparator()
                row()
            }
        }
        if (footer != null) {
            BasicText(
                text = footer,
                style = captionStyle,
                modifier = Modifier.padding(start = spacing.space16, end = spacing.space16, top = spacing.space8),
            )
        }
    }
}

/** Đường phân cách một điểm ảnh, thụt theo lề chữ như iOS. */
@Composable
private fun RowSeparator() {
    val hairline = with(LocalDensity.current) { 1.toDp() }
    Box(
        modifier =
            Modifier
                .padding(start = HandLiveTheme.spacing.space16)
                .fillMaxWidth()
                .height(hairline)
                .background(HandLiveTheme.colors.separator),
    )
}
