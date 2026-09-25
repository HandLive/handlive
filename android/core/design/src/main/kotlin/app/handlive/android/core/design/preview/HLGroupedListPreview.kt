package app.handlive.android.core.design.preview

import androidx.compose.runtime.Composable
import androidx.compose.ui.tooling.preview.Preview
import androidx.compose.ui.tooling.preview.PreviewParameter
import app.handlive.android.core.design.component.HLGroupedList
import app.handlive.android.core.design.theme.HandLiveAppearance
import app.handlive.android.core.design.theme.HandLiveTheme

/** Tab Cài đặt Android thu gọn; chữ lấy nguyên văn 2-patterns/04-cai-dat.md. */
@Composable
internal fun HLGroupedListPreviewGallery() {
    HLGroupedList {
        section(
            title = "Bảng nhớ tạm",
            footer = "Chỉ xóa nội dung nhận từ thiết bị khác, và chỉ khi bạn chưa sao chép gì mới.",
        ) {
            switchRow(title = "Đồng bộ bảng nhớ tạm", checked = true, onCheckedChange = {})
            switchRow(title = "Chặn nội dung nhạy cảm", checked = false, onCheckedChange = {})
            navigationRow(title = "Tự xóa bảng nhớ tạm đã nhận", value = "Sau 1 phút", onClick = {})
        }
        section(title = "Tin nhắn") {
            switchRow(
                title = "Tin nhắn SMS",
                checked = false,
                onCheckedChange = {},
                unavailableReason = "Thiếu quyền SMS trên điện thoại",
            )
            actionRow(title = "Đồng bộ lại toàn bộ SMS", onClick = {})
        }
        section(title = "Dữ liệu") {
            actionRow(title = "Xóa toàn bộ dữ liệu HandLive", onClick = {}, destructive = true)
        }
    }
}

@Preview(widthDp = 360, heightDp = 640)
@Composable
private fun HLGroupedListPreview(
    @PreviewParameter(HandLiveAppearancePreviewProvider::class) appearance: HandLiveAppearance,
) {
    HandLiveTheme(darkTheme = appearance.isDark, highContrast = appearance.isHighContrast) {
        HLGroupedListPreviewGallery()
    }
}
