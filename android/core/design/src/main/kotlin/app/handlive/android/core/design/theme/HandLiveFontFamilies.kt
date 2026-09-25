package app.handlive.android.core.design.theme

import androidx.compose.ui.text.ExperimentalTextApi
import androidx.compose.ui.text.font.Font
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.FontVariation
import androidx.compose.ui.text.font.FontWeight
import app.handlive.android.core.design.R

/**
 * Font đóng gói trong `res/font` (giấy phép OFL ở `assets/licenses/`), chỉ các weight mà tokens.json dùng,
 * để không có weight nào bị tô đậm giả. Test `HandLiveTypographyTokenTest` kiểm điều này.
 */
object HandLiveFontFamilies {
    /** Chữ giao diện (`android-*`, `timer`): Inter 4.1 bản tĩnh. */
    val inter =
        FontFamily(
            Font(R.font.inter_regular, FontWeight.Normal),
            Font(R.font.inter_medium, FontWeight.Medium),
            Font(R.font.inter_semibold, FontWeight.SemiBold),
        )

    /** Chữ thương hiệu (`brand-large-title`, `brand-title`, `wordmark`). */
    val beVietnamPro =
        FontFamily(
            Font(R.font.be_vietnam_pro_semibold, FontWeight.SemiBold),
            Font(R.font.be_vietnam_pro_bold, FontWeight.Bold),
        )

    /**
     * Mã PIN (`code-pin`): google/fonts chỉ phát hành Roboto Mono dạng biến thiên, đặt trục `wght` = 600.
     * `FontVariation` còn thử nghiệm ở Compose 1.11; dùng file gốc để không phải tự tạo bản tĩnh (sửa font OFL).
     */
    @OptIn(ExperimentalTextApi::class)
    val robotoMono =
        FontFamily(
            Font(
                R.font.roboto_mono_variable,
                FontWeight.SemiBold,
                variationSettings = FontVariation.Settings(FontVariation.weight(FontWeight.SemiBold.weight)),
            ),
        )
}
