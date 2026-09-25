package app.handlive.android.core.design.component

import androidx.annotation.StringRes
import androidx.compose.ui.graphics.Color
import app.handlive.android.core.design.R
import app.handlive.android.core.design.theme.HandLiveColors

/** Trạng thái liên kết giữa hai máy, theo bảng của `components/StatusIndicator/README.md`. */
sealed interface HLConnectionStatus {
    data object ConnectedWiFi : HLConnectionStatus

    data object ConnectedInternet : HLConnectionStatus

    data object Usb : HLConnectionStatus

    data object Connecting : HLConnectionStatus

    /** @param lastSeen giờ đã định dạng theo locale, ví dụ "14:05"; `null` khi chưa biết. */
    data class PhoneOffline(
        val lastSeen: String?,
    ) : HLConnectionStatus

    data object NetworkLost : HLConnectionStatus

    data object NeedsRepair : HLConnectionStatus

    data object CameraStreaming : HLConnectionStatus
}

/** Chữ hiển thị đầy đủ (không gồm tham số `lastSeen`). */
@get:StringRes
internal val HLConnectionStatus.textRes: Int
    get() =
        when (this) {
            HLConnectionStatus.ConnectedWiFi -> {
                R.string.hl_status_connected_wifi
            }

            HLConnectionStatus.ConnectedInternet -> {
                R.string.hl_status_connected_internet
            }

            HLConnectionStatus.Usb -> {
                R.string.hl_status_usb
            }

            HLConnectionStatus.Connecting -> {
                R.string.hl_status_connecting
            }

            is HLConnectionStatus.PhoneOffline -> {
                if (lastSeen == null) R.string.hl_status_phone_offline else R.string.hl_status_phone_offline_last_seen
            }

            HLConnectionStatus.NetworkLost -> {
                R.string.hl_status_network_lost
            }

            HLConnectionStatus.NeedsRepair -> {
                R.string.hl_status_needs_repair
            }

            HLConnectionStatus.CameraStreaming -> {
                R.string.hl_status_camera_streaming
            }
        }

/** Chỉ ba trạng thái đã kết nối mới đọc kèm tên thiết bị ("… với Pixel 8 của Lan"). */
internal val HLConnectionStatus.readsDeviceName: Boolean
    get() =
        this == HLConnectionStatus.ConnectedWiFi ||
            this == HLConnectionStatus.ConnectedInternet ||
            this == HLConnectionStatus.Usb

/** Chấm nhấp nháy theo `duration-pulse` chỉ cho "Đang kết nối…" và "Đang phát camera". */
internal val HLConnectionStatus.pulses: Boolean
    get() = this == HLConnectionStatus.Connecting || this == HLConnectionStatus.CameraStreaming

/** Ngoại tuyến là xám; đỏ chỉ khi người dùng phải làm gì đó. */
internal fun HLConnectionStatus.tint(colors: HandLiveColors): Color =
    when (this) {
        HLConnectionStatus.ConnectedWiFi,
        HLConnectionStatus.ConnectedInternet,
        HLConnectionStatus.Usb,
        HLConnectionStatus.CameraStreaming,
        -> colors.statusConnected

        HLConnectionStatus.Connecting -> colors.statusConnecting

        is HLConnectionStatus.PhoneOffline, HLConnectionStatus.NetworkLost -> colors.statusOffline

        HLConnectionStatus.NeedsRepair -> colors.statusError
    }
