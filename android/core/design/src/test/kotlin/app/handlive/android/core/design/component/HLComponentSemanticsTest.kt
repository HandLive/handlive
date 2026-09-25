package app.handlive.android.core.design.component

import androidx.compose.foundation.layout.Column
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.semantics.LiveRegionMode
import androidx.compose.ui.semantics.Role
import androidx.compose.ui.semantics.SemanticsProperties
import androidx.compose.ui.test.SemanticsMatcher
import androidx.compose.ui.test.assert
import androidx.compose.ui.test.assertIsEnabled
import androidx.compose.ui.test.assertIsNotEnabled
import androidx.compose.ui.test.hasText
import androidx.compose.ui.test.junit4.createComposeRule
import androidx.compose.ui.test.onNodeWithContentDescription
import androidx.compose.ui.test.onNodeWithText
import androidx.compose.ui.test.performClick
import app.handlive.android.core.design.theme.HandLiveTheme
import org.junit.Assert.assertEquals
import org.junit.Rule
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.Config

/** TalkBack đọc được nhãn, vai trò và trạng thái của thành phần (03-android.md, 08-kha-nang-tiep-can.md). */
@RunWith(RobolectricTestRunner::class)
@Config(sdk = [35])
class HLComponentSemanticsTest {
    @get:Rule
    val compose = createComposeRule()

    private fun hasRole(role: Role) = SemanticsMatcher.expectValue(SemanticsProperties.Role, role)

    private fun hasState(text: String) = SemanticsMatcher.expectValue(SemanticsProperties.StateDescription, text)

    @Test
    fun switchRowReadsTitleRoleAndStateAndTogglesFromWholeRow() {
        compose.setContent {
            HandLiveTheme(darkTheme = false, highContrast = false) {
                var checked by remember { mutableStateOf(false) }
                HLGroupedList {
                    section(title = "Bảng nhớ tạm") {
                        switchRow(title = "Đồng bộ bảng nhớ tạm", checked = checked, onCheckedChange = { checked = it })
                    }
                }
            }
        }
        val row = compose.onNodeWithText("Đồng bộ bảng nhớ tạm")
        row.assert(hasRole(Role.Switch)).assert(hasState("Tắt")).assertIsEnabled()
        row.performClick()
        row.assert(hasState("Bật"))
        compose.onNodeWithText("Bảng nhớ tạm").assert(SemanticsMatcher.keyIsDefined(SemanticsProperties.Heading))
    }

    @Test
    fun unavailableSwitchRowIsDisabledAndReadsReason() {
        compose.setContent {
            HandLiveTheme(darkTheme = true, highContrast = true) {
                HLGroupedList {
                    section {
                        switchRow(
                            title = "Tin nhắn SMS",
                            checked = false,
                            onCheckedChange = {},
                            unavailableReason = "Thiếu quyền SMS trên điện thoại",
                        )
                    }
                }
            }
        }
        compose
            .onNodeWithText("Tin nhắn SMS", substring = true)
            .assertIsNotEnabled()
            .assert(hasText("Thiếu quyền SMS trên điện thoại"))
    }

    @Test
    fun standaloneSwitchHasSwitchRoleAndSpokenState() {
        compose.setContent {
            HandLiveTheme(darkTheme = false, highContrast = false) {
                var checked by remember { mutableStateOf(true) }
                HLSwitch(checked = checked, onCheckedChange = { checked = it })
            }
        }
        val node = compose.onNode(hasRole(Role.Switch))
        node.assert(hasState("Bật"))
        node.performClick()
        node.assert(hasState("Tắt"))
    }

    @Test
    fun statusIndicatorReadsFullSentenceAsPoliteLiveRegion() {
        compose.setContent {
            HandLiveTheme(darkTheme = false, highContrast = false) {
                Column {
                    HLStatusIndicator(status = HLConnectionStatus.ConnectedWiFi, deviceName = "Pixel 8 của Lan")
                    HLStatusIndicator(status = HLConnectionStatus.PhoneOffline("14:05"), deviceName = "Pixel 8 của Lan")
                }
            }
        }
        compose
            .onNodeWithContentDescription("Đã kết nối qua Wi-Fi với Pixel 8 của Lan")
            .assert(SemanticsMatcher.expectValue(SemanticsProperties.LiveRegion, LiveRegionMode.Polite))
        compose.onNodeWithContentDescription("Điện thoại ngoại tuyến · lần cuối 14:05").assertExists()
    }

    @Test
    fun pillShowsShortLabelButReadsFullSentence() {
        compose.setContent {
            HandLiveTheme(darkTheme = true, highContrast = false) {
                HLStatusIndicator(
                    status = HLConnectionStatus.ConnectedWiFi,
                    deviceName = "Pixel 8 của Lan",
                    variant = HLStatusIndicatorVariant.Pill,
                )
            }
        }
        compose.onNodeWithContentDescription("Đã kết nối qua Wi-Fi với Pixel 8 của Lan").assertExists()
        // Nhãn ngắn chỉ để nhìn; TalkBack không đọc "LAN" mà đọc câu đầy đủ.
        compose.onNodeWithText("LAN", useUnmergedTree = true).assertExists()
        compose.onNodeWithText("LAN").assertDoesNotExist()
    }

    @Test
    fun buttonHasButtonRoleAndDisabledStateIsExposed() {
        var clicks = 0
        compose.setContent {
            HandLiveTheme(darkTheme = false, highContrast = true) {
                Column {
                    HLButton(text = "Ghép nối", onClick = { clicks++ })
                    HLButton(text = "Hủy ghép nối", onClick = {}, style = HLButtonStyle.Destructive, enabled = false)
                }
            }
        }
        compose.onNodeWithText("Ghép nối").assert(hasRole(Role.Button)).performClick()
        compose.runOnIdle { assertEquals(1, clicks) }
        compose.onNodeWithText("Hủy ghép nối").assertIsNotEnabled()
    }
}
