# macOS

HandLive trên Mac là app thanh menu, mở cửa sổ khi cần. Mục này quy định cấu trúc app, cách chuyển giữa chế độ chỉ-thanh-menu và chế độ có Dock, thanh menu của app, phím tắt, Liquid Glass và API theo phiên bản (macOS 13 trở lên).

Nguồn HIG: https://developer.apple.com/design/human-interface-guidelines/designing-for-macos · https://developer.apple.com/design/human-interface-guidelines/the-menu-bar · https://developer.apple.com/design/human-interface-guidelines/windows · https://developer.apple.com/design/human-interface-guidelines/panels

## Cấu trúc

| Bề mặt | Loại | API | Nội dung |
|---|---|---|---|
| Biểu tượng thanh menu | Menu bar extra | `MenuBarExtra` + `.menuBarExtraStyle(.menu)` | `MenuBarMenu`: trạng thái, lệnh nhanh, Cài đặt, Thoát |
| Tin nhắn | Cửa sổ chính | `Window` + `NavigationSplitView` | Thanh bên: ô tìm kiếm, mục "Cuộc gọi" (nhật ký CALL-04), danh sách `ThreadRow`; cột phải: `MessageBubble` và ô soạn |
| Xem trước camera | Cửa sổ phụ | `Window` | `CameraPreview` |
| Cài đặt | Cửa sổ phụ | `Settings` | Sáu pane (mục Cài đặt) |
| Chào mừng | Cửa sổ phụ, cố định cỡ | `Window` | `Onboarding` |
| Ghép nối, công bố, hướng dẫn gỡ lỗi USB | Sheet | `sheet(isPresented:onDismiss:content:)` | `PairingCard`, `ConsentSheet`, wizard CAM-04 |
| Cuộc gọi | Panel (ngoại lệ) | `NSPanel` `.nonactivatingPanel`, `level = .floating`, `collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]`, `hidesOnDeactivate = false` | `CallPanel` |

Nút "Tin nhắn mới" nằm trên toolbar cửa sổ Tin nhắn, không ở đáy thanh bên. Không đặt thông tin hay nút quan trọng ở đáy cửa sổ.

## Chế độ kích hoạt

| Khi | Chế độ | Người dùng thấy |
|---|---|---|
| Chỉ có biểu tượng thanh menu (khởi động, `LSUIElement = YES`) | `.accessory` | Không Dock, không thanh menu của app |
| Mở cửa sổ Tin nhắn hoặc Xem trước camera | `.regular` | Biểu tượng Dock, thanh menu HandLive, Dock menu |
| Người dùng tắt "Hiện HandLive trên thanh menu" | `.regular`, giữ luôn | Dock là lối vào chính |
| Đóng hết hai cửa sổ trên và biểu tượng thanh menu đang hiện | Về `.accessory` | — |

- Chuyển bằng `NSApp.setActivationPolicy(_:)` rồi kích hoạt app để cửa sổ ra trước.
- Cửa sổ Cài đặt và Chào mừng không đổi chế độ. Ở `.accessory` không có thanh menu, nên hai cửa sổ này tự nhận ⌘W và Esc (kiểm trên máy thật).
- Mở lại HandLive từ Finder, Launchpad hay Spotlight khi app đang chạy (`applicationShouldHandleReopen(_:hasVisibleWindows:)`): mở cửa sổ Tin nhắn, chưa ghép nối thì mở cửa sổ Chào mừng.
- Biểu tượng hiện theo cài đặt "Hiện HandLive trên thanh menu" (`isInserted`, mặc định bật). Hệ thống có thể giấu bớt biểu tượng khi thanh menu chật, nên mọi lệnh của `MenuBarMenu` cũng có ở nơi khác.

## Thanh menu của app (chế độ `.regular`)

| Menu | Mục của HandLive (ngoài mục chuẩn do hệ thống tạo và dịch) |
|---|---|
| HandLive | "Cài đặt…" ⌘, · "Ghép điện thoại…" · "Thoát HandLive" ⌘Q |
| Tệp | "Tin nhắn mới" ⌘N · "Đóng" ⌘W |
| Sửa | Mục chuẩn (Hoàn tác, Cắt, Sao chép, Dán…) · "Gửi bảng nhớ tạm sang điện thoại" · Tìm ⌘F (đưa con trỏ vào ô tìm kiếm đầu thanh bên) |
| Xem | Hiện hoặc ẩn thanh bên (nhãn theo trạng thái) · Vào toàn màn hình |
| Cửa sổ | Thu nhỏ ⌘M · Thu phóng · "Tin nhắn" · "Xem trước camera" · Đưa tất cả ra trước |
| Trợ giúp | "Trợ giúp HandLive" |

Mục chưa dùng được thì mờ, không ẩn; mọi nút toolbar đều có lệnh ở đây.

Dock menu (`applicationDockMenu(_:)`): "Tin nhắn mới", "Gửi bảng nhớ tạm sang điện thoại", "Xem trước camera", cùng danh sách cửa sổ của hệ thống.

## Phím tắt

| Phím | Tác dụng |
|---|---|
| ⌘, | Mở Cài đặt |
| ⌘N | Tin nhắn mới |
| ⌘W | Đóng cửa sổ; Xem trước camera đóng mà không dừng camera khi app họp đang dùng |
| ⌘Q | Thoát HandLive |
| ⌘F | Tìm hội thoại |
| Return · ⇧Return | Gửi tin · xuống dòng trong ô soạn |
| Return · Esc · ⌘⌫ | Trả lời · Bỏ qua (đóng panel, tắt chuông trên Mac, không từ chối) · Từ chối — trong `CallPanel` |
| 0–9, *, # | Bấm số khi bàn phím của `CallPanel` đang mở (CALL-03 trường 7) |

`CallPanel` không tự lấy focus của app người dùng đang gõ; phím của panel chỉ có tác dụng sau khi người dùng bấm vào panel.

## Liquid Glass và bản cũ

- Build bằng SDK 27: menu, toolbar, thanh bên, sheet tự thành kính trên macOS 26+; không dùng `UIDesignRequiresCompatibility` để né.
- Chỉ tự áp kính cho `CallPanel` (`NSGlassEffectView`) và HUD `Feedback`. Control tự dựng dùng `ConcentricRectangle` (26+).
- macOS 13–15: `NSVisualEffectView` `.popover` cho `CallPanel`, `.hudWindow` cho HUD; góc bo theo token `radius-control-mac`, `radius-panel` (mục Vật liệu).

## Control

- Mỗi cửa sổ hoặc sheet một nút nổi bật ở cạnh phải hàng nút (`.borderedProminent`, 26+ `.glassProminent`) với `.keyboardShortcut(.defaultAction)`; nút khác là push button thường; "Hủy" bên trái với `.cancelAction`.
- Nút mở cửa sổ, sheet hoặc alert có "…": "Ghép điện thoại…", "Chi tiết…", "Hủy ghép nối…", "Từ chối kèm tin nhắn…".
- Switch và checkbox chỉ trong thân cửa sổ, không trên toolbar; trong menu dùng dấu kiểm.
- Nút chỉ có biểu tượng có tooltip `help(_:)`, bắt đầu bằng động từ, 60–75 ký tự trở xuống.
- AccentColor là `accent`; người dùng chọn màu nhấn khác Multicolor thì control theo màu đó. Màu mang nghĩa (`call-accept-fill`, `call-decline-fill`, trạng thái) không đổi theo màu nhấn.

## Thông báo, Tập trung, đăng nhập, khôi phục

- Mac không nhận push: thông báo cục bộ `UNUserNotificationCenter`; tin nhắn, cuộc gọi là thông báo liên lạc (`INSendMessageIntent`, `INStartCallIntent`), cần capability Communication Notifications và `NSUserActivityTypes` (mục Thông báo).
- Tập trung: `INFocusStatusCenter` (entitlement `com.apple.developer.focus-status`, khóa `NSFocusStatusUsageDescription`). Tập trung đang bật thì không panel, không chuông; cuộc gọi vẫn có trong `MenuBarMenu`. Chưa đọc được trạng thái Tập trung thì vẫn hiện panel nhưng không đổ chuông.
- Không hiện hai lớp cho một cuộc gọi: khi `CallPanel` đang hiện, thông báo cuộc gọi gửi ở mức passive (vào Trung tâm thông báo, không banner, không âm); khi không hiện panel (Tập trung), thông báo ở mức time-sensitive để hệ thống quyết định theo người gọi và cài đặt Tập trung. Trả lời từ thông báo thì mở `CallPanel` ở trạng thái đang gọi.
- Mở khi đăng nhập: `SMAppService.mainApp.register()` / `unregister()`, trạng thái luôn đọc từ `status`; `.requiresApproval` thì nút mở `SMAppService.openSystemSettingsLoginItems()`.
- Mac không có launch screen. Mở lại thì khôi phục khung cửa sổ, hội thoại đang chọn, vị trí cuộn; Cài đặt mở lại pane cuối.

## API theo phiên bản

| API | Từ | Trên macOS 13 |
|---|---|---|
| `MenuBarExtra(_:systemImage:isInserted:content:)`, `Window`, `NavigationSplitView`, `Form` `.grouped`, `SMAppService` | 13 | Dùng được |
| `MenuBarExtra(_:image:isInserted:content:)` | 14 | `if #available` |
| `SettingsLink`, `OpenSettingsAction` | 14 | Cần đường mở Cài đặt riêng, chưa có API chính thức |
| `.contentTransition(.symbolEffect(.replace))`, TipKit, `ContentUnavailableView` | 14 | Đổi biểu tượng không hiệu ứng; tự dựng trạng thái trống |
| Quyền mạng cục bộ | 15 | Không hỏi |
| `NSPasteboard.accessBehavior` | 15.4 | Không có quyền dán |
| `glassEffect(_:in:)`, `.glassProminent`, `NSGlassEffectView`, `ConcentricRectangle` | 26 | Vật liệu chuẩn |

## Điểm lệch

- Lệch có chủ đích: `CallPanel` nổi trên mọi Space và không ẩn khi app không active (quyết định 10).
- Giữ menu Tệp như app Tin nhắn của Apple ("Tin nhắn mới", "Đóng") dù HandLive không xử lý tệp, để ⌘N và ⌘W nằm đúng chỗ người dùng tìm.
- Đã đồng bộ với tài liệu chi tiết (25/09/2026): SET-03 (bước 6, Yêu cầu đặc biệt) mô tả đổi activation policy `.accessory` ↔ `.regular`; SET-02 trường 31 `mac.menu_bar_extra`.
- Đã đồng bộ với tài liệu chi tiết (25/09/2026): CALL-04 trường 1 đặt nhật ký ở thanh bên cửa sổ Tin nhắn; CAM-03 dùng menu con Camera trong `MenuBarMenu` và cửa sổ Xem trước camera.
- Tài liệu chi tiết viết "Huỷ"; ở đây viết kiểu Apple "Hủy".

## Nên và không nên

| Nên | Không nên |
|---|---|
| Đưa mọi lệnh vào thanh menu của app và Dock menu | Dựa vào việc biểu tượng thanh menu luôn hiện |
| Dùng cửa sổ, sheet, control của hệ thống | Tự vẽ khung cửa sổ, nút đóng hay thu nhỏ |
