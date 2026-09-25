package app.handlive.android.core.design.theme

import android.app.UiModeManager
import android.os.Build
import androidx.annotation.RequiresApi
import androidx.compose.runtime.Composable
import androidx.compose.runtime.DisposableEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableFloatStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.platform.LocalContext

/** Ngưỡng của 02-che-do-toi.md: mức tương phản hệ thống từ 0.5 trở lên thì dùng bộ màu `-hc`. */
const val HIGH_CONTRAST_THRESHOLD = 0.5f

/**
 * Cài đặt "Độ tương phản" của hệ thống đang ở mức cao: `UiModeManager.getContrast()` ≥ 0.5 (Android 14+, API 34),
 * theo dõi thay đổi bằng `UiModeManager.addContrastChangeListener`. Android 10–13 không có cài đặt này nên trả `false`.
 */
@Composable
fun isSystemInHighContrast(): Boolean =
    Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE && systemContrastLevel() >= HIGH_CONTRAST_THRESHOLD

/** Mức tương phản hệ thống (−1…1) và theo dõi thay đổi; không có `UiModeManager` thì coi là mức chuẩn 0. */
@RequiresApi(Build.VERSION_CODES.UPSIDE_DOWN_CAKE)
@Composable
private fun systemContrastLevel(): Float {
    val context = LocalContext.current
    val uiModeManager = remember(context) { context.getSystemService(UiModeManager::class.java) }
    var contrast by remember(uiModeManager) { mutableFloatStateOf(uiModeManager?.contrast ?: 0f) }
    DisposableEffect(uiModeManager) {
        if (uiModeManager == null) return@DisposableEffect onDispose {}
        val listener = UiModeManager.ContrastChangeListener { contrast = it }
        uiModeManager.addContrastChangeListener(context.mainExecutor, listener)
        onDispose { uiModeManager.removeContrastChangeListener(listener) }
    }
    return contrast
}
