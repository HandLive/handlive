package app.handlive.android.core.design.component

import android.animation.ValueAnimator
import androidx.compose.runtime.Composable
import androidx.compose.runtime.remember

/**
 * `false` khi người dùng tắt hiệu ứng (Tùy chọn cho nhà phát triển hoặc Hỗ trợ tiếp cận › Xóa ảnh động):
 * thành phần bỏ chuyển động, chỉ đổi trạng thái (03-android.md, mục Trợ năng).
 */
@Composable
internal fun rememberAnimationsEnabled(): Boolean = remember { ValueAnimator.areAnimatorsEnabled() }
