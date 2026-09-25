package app.handlive.android.core.design.preview

import android.animation.ValueAnimator
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.width
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import app.handlive.android.core.design.theme.HandLiveAppearance
import app.handlive.android.core.design.theme.HandLiveTheme
import com.github.takahirom.roborazzi.captureRoboImage
import org.junit.After
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.Config
import org.robolectric.annotation.GraphicsMode

/**
 * Dựng nội dung của mọi `@Preview` ở cả bốn giao diện trên JVM (Robolectric), nên preview hỏng thì `check` đỏ.
 * `./gradlew :core:design:recordRoborazziDebug` ghi ảnh ra `core/design/build/outputs/roborazzi/` (không commit).
 */
@RunWith(RobolectricTestRunner::class)
@Config(sdk = [35])
@GraphicsMode(GraphicsMode.Mode.NATIVE)
class HandLivePreviewScreenshotTest {
    /** Tắt hiệu ứng như cài đặt "Xóa ảnh động": chấm nhấp nháy đứng yên, ảnh chụp ổn định và không chờ vô hạn. */
    @Before
    fun disableAnimators() = setAnimatorDurationScale(0f)

    @After
    fun restoreAnimators() = setAnimatorDurationScale(1f)

    /** `ValueAnimator.setDurationScale` là API ẩn (hệ thống gọi khi đổi cài đặt), nên gọi qua reflection. */
    private fun setAnimatorDurationScale(scale: Float) {
        ValueAnimator::class.java.getMethod("setDurationScale", Float::class.javaPrimitiveType).invoke(null, scale)
    }

    private val galleries: Map<String, @Composable () -> Unit> =
        mapOf(
            "HLButton" to { HLButtonPreviewGallery() },
            "HLSwitch" to { HLSwitchPreviewGallery() },
            "HLStatusIndicator" to { HLStatusIndicatorPreviewGallery() },
        )

    @Test
    fun componentPreviewsRenderInEveryAppearance() {
        HandLiveAppearance.entries.forEach { appearance ->
            galleries.forEach { (name, gallery) ->
                captureRoboImage("build/outputs/roborazzi/$name-${appearance.name}.png") {
                    HandLivePreviewSurface(appearance) { gallery() }
                }
            }
        }
    }

    @Test
    fun groupedListPreviewRendersInEveryAppearance() {
        HandLiveAppearance.entries.forEach { appearance ->
            captureRoboImage("build/outputs/roborazzi/HLGroupedList-${appearance.name}.png") {
                HandLiveTheme(darkTheme = appearance.isDark, highContrast = appearance.isHighContrast) {
                    Box(Modifier.width(360.dp)) { HLGroupedListPreviewGallery() }
                }
            }
        }
    }
}
