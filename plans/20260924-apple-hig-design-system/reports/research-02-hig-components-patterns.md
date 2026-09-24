# Research 02 — Apple HIG: Components & Patterns cho HandLive

- Ngày: 2026-09-24. Người viết: subagent research-02.
- Phạm vi: component + pattern HIG mà macOS app (menu bar app, macOS 13+) và iOS/iPadOS app (iOS 16+) cần. Foundations (color, typography, SF Symbols, app icons, materials chi tiết) chỉ trích phần ảnh hưởng trực tiếp tới component.
- Phương pháp: tải DocC render JSON `https://developer.apple.com/tutorials/data/design/human-interface-guidelines/<slug>.json` (72 trang) + trang What's new; khi HIG im lặng thì tra thêm DocC JSON tài liệu developer (`/tutorials/data/documentation/...`). Mọi nội dung là diễn giải, không trích nguyên văn.
- Ký hiệu: **[HIG]** = nội dung HIG; **[dev]** = tài liệu developer Apple (không phải HIG); **[Đề xuất]** = suy luận của người viết cho HandLive; **CHƯA XÁC MINH** = không tìm được nguồn xác nhận.
- Trang không tồn tại: `accessing-private-data` (404) → dùng `privacy#Requesting-permission`. `callkit` (404, HIG không còn trang CallKit).

---

## 0. Trạng thái HIG tại 2026-09-24

Nguồn: https://developer.apple.com/design/whats-new/ · https://developer.apple.com/design/human-interface-guidelines

Mốc chính (theo trang What's new + `customMetadata.alert-date` của từng trang):

| Ngày | Thay đổi liên quan HandLive |
|---|---|
| 2025-06-09 | Ra mắt Liquid Glass: materials, color, layout, toolbars (nhóm bar item, gộp navigation bar), buttons (style/content), search fields (search ở đáy trên iOS), menu bar trên iPadOS, windows (resize iPadOS) |
| 2025-07-28 | Tab bars, scroll edge effects, icon cho menu item |
| 2025-12-16 | Buttons, toolbars, tab bars, color: "Updated guidance for Liquid Glass"; Live Activities thêm macOS (menu bar) |
| 2026-03-24 | Sheets: quy tắc đặt nút Cancel/Done/Back |
| 2026-06-08 (WWDC26) | Design principles (tái giới thiệu), menus (icon menu item), sidebars (màu icon, adaptable sidebar), scroll views (scroll edge), search fields/searching (search tab iOS), tab bars (thuật ngữ), app icons, trang mới Snippets |
| 2026-09-09 | Trang mới **Designing for iPhone Duo** (iPhone gập), Layout cập nhật, Branding |
| 2026-09-17 | macOS 27 và iOS/iPadOS 27 UI Kit cho Figma (nguồn số đo chi tiết mà HIG không ghi) |

Ngày cập nhật của các trang dùng trong báo cáo: sheets 2026-03-24; menus, sidebars, tab-bars, search-fields, searching, scroll-views 2026-06-08; layout, designing-for-iphone-duo 2026-09-09; buttons, toolbars, color, live-activities 2025-12-16; materials 2025-09-09; the-menu-bar, windows, split-views, loading 2025-06-09; toggles 2024-03-29; alerts 2024-02-02; settings, onboarding, launching, controls 2024-06-10; modality, context-menus 2023-12-05; còn lại ≤ 2023 hoặc không ghi ngày (popovers, panels, action-sheets, pull-down-buttons, boxes, feedback, managing-notifications, dock-menus, token-fields).

---

## 1. Trả lời nhanh các câu hỏi (a)–(h)
Nguồn: URL ghi dưới từng mục (a)–(h); nhóm chính: https://developer.apple.com/design/human-interface-guidelines/components · https://developer.apple.com/design/human-interface-guidelines/patterns

### (a) Menu bar extra: menu hay popover/window, icon
Nguồn: https://developer.apple.com/design/human-interface-guidelines/the-menu-bar#Menu-bar-extras · https://developer.apple.com/documentation/swiftui/menubarextra

- [HIG] Click extra → hiện **menu**, không phải popover; chỉ dùng popover/window khi chức năng quá phức tạp cho menu.
- [HIG] Icon: ưu tiên SF Symbol hoặc interface icon tự vẽ; cả hai chỉ dùng đen + trong suốt (template) để hệ thống tô màu theo menu bar sáng/tối và trạng thái selected. **Menu bar cao 24 pt.** Kích thước glyph cụ thể: HIG không ghi → CHƯA XÁC MINH (dùng SF Symbol để hệ thống tự scale).
- [HIG] Người dùng, không phải app, quyết định có đặt extra lên menu bar (thường qua setting trong Settings window; có thể hỏi lúc setup).
- [HIG] Không dựa vào việc extra luôn hiện (hệ thống ẩn khi chật); cung cấp chức năng ở chỗ khác nữa (vd Dock menu).
- [dev] `MenuBarExtra` (macOS 13.0+); `.menuBarExtraStyle(.menu)` = `PullDownMenuBarExtraStyle`, `.window` = `WindowMenuBarExtraStyle` ("popover-like window"); `init(_:systemImage:isInserted:content:)` (macOS 13.0) cho binding hiện/ẩn; `init(_:image:isInserted:content:)` cần macOS 14.0. AppKit: `NSStatusBar`, `NSStatusItem` (`behavior` `.removalAllowed`, `isVisible`), `NSImage.isTemplate`.
- [dev] App **chỉ** có menu bar extra sẽ bị hệ thống terminate nếu người dùng gỡ extra khỏi menu bar; ẩn Dock icon bằng `LSUIElement = true`.
- [Đề xuất] HandLive dùng `.menu`: dòng trạng thái (item disabled) → nhóm toggle có checkmark → lệnh ("Gửi clipboard sang điện thoại", "Mở Tin nhắn") → "Settings…" (⌘,) → "Quit HandLive" (⌘Q). Không nhét điều khiển cuộc gọi hay preview camera vào popover của extra.

### (b) macOS: switch hay checkbox
Nguồn: https://developer.apple.com/design/human-interface-guidelines/toggles#macOS

- [HIG] **Switch** cho setting cần nhấn mạnh, nhất là bật/tắt cả một nhóm setting (switch nặng hình hơn checkbox).
- [HIG] Trong grouped form: dùng **mini switch** cho setting một dòng (cao bằng button/control khác → hàng đều); có phân cấp thì switch regular cho setting chính + mini switch cho setting phụ. API: `GroupedFormStyle`, `ControlSize`.
- [HIG] **Checkbox** khi cần phân cấp setting (căn lề leading + thụt lề), có trạng thái mixed khi các con khác nhau (`allowsMixedState`). Một setting on/off đơn lẻ: ưu tiên checkbox hơn một radio button.
- [HIG] Đã dùng checkbox thì đừng đổi sang switch.
- [HIG] Radio button: nhóm 2–5 lựa chọn loại trừ; > ~5 → pop-up button; xếp ngang thì khoảng cách đều theo nhãn dài nhất.
- [HIG] Switch/checkbox/radio chỉ ở window body, không ở window frame (toolbar, status bar).
- [HIG] iOS: switch chỉ dùng trong list row (không cần label); ngoài list → button kiểu toggle; màu mặc định xanh lá, chỉ đổi sang accent khi cần và đủ tương phản.
- [dev] `Toggle` + `.toggleStyle(.switch)` / `.checkbox` (macOS 10.15+), `.controlSize(.mini)`, `Form` + `.formStyle(.grouped)` (macOS 13.0+), `Picker` + `.pickerStyle(.radioGroup)` (macOS 10.15+), `NSSwitch`.

### (c) Button: kích thước, role, vị trí default/cancel/destructive
Nguồn: https://developer.apple.com/design/human-interface-guidelines/buttons · https://developer.apple.com/design/human-interface-guidelines/alerts#Buttons · https://developer.apple.com/design/human-interface-guidelines/sheets · https://developer.apple.com/design/human-interface-guidelines/accessibility#Mobility

- Kích thước [HIG]: vùng bấm ≥ **44x44 pt** (visionOS 60x60). Bảng accessibility: mặc định/tối thiểu iOS-iPadOS **44x44 / 28x28 pt**, macOS **28x28 / 20x20 pt**; padding ~**12 pt** quanh control có bezel, ~**24 pt** quanh control không bezel.
- Kích thước pt của push button macOS theo mini/small/regular/large: HIG không liệt kê → CHƯA XÁC MINH (lấy từ macOS 27 UI Kit). [dev] `ControlSize.extraLarge` (macOS 14.0+); Liquid Glass bổ sung tuỳ chọn extra-large cho control.
- Style [HIG]: button prominent (accent color làm nền) cho hành động khả dĩ nhất; tối đa **1–2 prominent/view**; phân biệt lựa chọn ưu tiên bằng style, không bằng size.
- Role [HIG]: Normal · Primary (default, phản hồi Return, view tạm có thể tự đóng khi Return) · Cancel · Destructive (system red). Không gán Primary cho nút destructive. [dev] SwiftUI `ButtonRole` `.destructive`, `.cancel` (iOS 15/macOS 12), `.confirm`, `.close` (26.0); `.keyboardShortcut(.defaultAction)` (Return), `.keyboardShortcut(.cancelAction)` (Esc).
- Alert [HIG]: ≤ **3 nút**; nút default ở **trailing** (hàng ngang) hoặc **trên cùng** (cột); Cancel ở leading/cuối; Cancel không bao giờ là default; muốn người dùng đọc kỹ → không đặt default; alert 1 nút là default → dùng "Done" chứ không "Cancel"; "OK" chỉ cho alert thuần thông tin; style destructive chỉ khi hành động phá dữ liệu mà người dùng **không** chủ động chọn (vd Empty Trash do người dùng chọn → không đỏ). Esc / ⌘. hủy alert.
- Sheet [HIG, 2026-03-24]: iOS/iPadOS sheet một view: Cancel ở leading của top toolbar, Done ở trailing; Done luôn đi cùng Cancel hoặc Back; không hiện cả Cancel + Done + Back. Flow nhiều bước: bước đầu Cancel + Done (inactive); bước giữa Back + Done (inactive); bước cuối Back + Done.
- Sheet macOS: trang Sheets không nêu vị trí nút. [HIG Modality] trên macOS người dùng tìm nút dismiss trong main content view → [Đề xuất] hàng nút đáy phải `[Cancel] [Default]` (default trailing như alert). CHƯA XÁC MINH trong HIG hiện hành về "đáy phải".
- Action sheet [HIG]: destructive ở **đầu**, Cancel ở **cuối**.
- Toolbar [HIG]: `.prominent` cho Done/Submit, chỉ **một** primary action, đặt trailing. [dev] UIKit `UIBarButtonItem.Style.prominent` (iOS 26.0); SwiftUI dùng `.buttonStyle(.glassProminent)` (26.0) — ánh xạ SwiftUI là suy luận, CHƯA XÁC MINH.

### (d) Settings window macOS
Nguồn: https://developer.apple.com/design/human-interface-guidelines/settings#macOS · https://developer.apple.com/design/human-interface-guidelines/the-menu-bar#App-menu

- [HIG] Mục "Settings…" trong App menu (sau About, cùng nhóm với mục cấu hình app); ⌘, mở Settings; không đặt nút settings trong toolbar cửa sổ.
- [HIG] Toolbar gồm các **pane**; toolbar không cho customize, luôn hiện, luôn chỉ báo pane đang active.
- [HIG] Title cửa sổ = tên pane đang xem; chỉ 1 pane → "*App Name* Settings" (→ "HandLive Settings").
- [HIG] **Dim** nút minimize và maximize (settings không cần nằm trong Dock; cửa sổ tự co theo pane).
- [HIG] Mở lại **pane xem gần nhất**.
- [HIG] Ít setting, default tốt; chỉ đặt setting chung ít đổi; option theo task để tại chỗ; không lặp lại system settings; có thể thêm nút mở System Settings.
- "Không có nút Apply, thay đổi có hiệu lực ngay": HIG hiện hành **không nêu** → CHƯA XÁC MINH (quy ước macOS cũ). [Đề xuất] vẫn áp dụng: control lưu ngay.
- [HIG] Help button (nếu có) ở góc dưới trái/phải của settings window/pane. Box title trong settings pane kết thúc bằng dấu hai chấm.
- [dev] `Settings` scene (macOS 11.0+); `SettingsLink`, `OpenSettingsAction` chỉ từ macOS 14.0 → macOS 13 cần đường mở khác (CHƯA XÁC MINH cách chính thống).

### (e) Notification: nội dung, interruption level, action
Nguồn: https://developer.apple.com/design/human-interface-guidelines/notifications · https://developer.apple.com/design/human-interface-guidelines/managing-notifications

- Nội dung [HIG]: title ngắn, title-style capitalization, không dấu chấm cuối; body câu hoàn chỉnh, sentence case, không tự cắt; không ghi tên/icon app (hệ thống tự hiện); có placeholder khi người dùng ẩn preview (`hiddenPreviewsBodyPlaceholder`, vd "Tin nhắn mới"); tránh thông tin nhạy cảm; âm thanh ngắn, riêng, không dùng âm thanh làm kênh duy nhất.
- Communication notification [HIG]: notification cho cuộc gọi/tin nhắn có giao diện riêng (avatar, tên nhóm thay icon app); hệ thống dùng **người gửi** để quyết định thời điểm giao (Focus). Cần SiriKit intent: `INSendMessageIntent` (tin nhắn), [dev] `INStartCallIntent` (cuộc gọi đến), cả hai conform `UNNotificationContentProviding`; bật capability Communication Notifications + khai báo `NSUserActivityTypes`.
- Interruption level [HIG] (cho noncommunication):

| Level | Vượt scheduled delivery | Xuyên Focus | Vượt công tắc Ring/Silent |
|---|---|---|---|
| Passive | Không | Không | Không |
| Active (mặc định) | Không | Không | Không |
| Time Sensitive | Có | Có | Không |
| Critical | Có | Có | Có (cần entitlement) |

- [HIG] Time Sensitive chỉ cho sự kiện **đang diễn ra hoặc trong vòng 1 giờ**; lần đầu hệ thống giải thích và cho người dùng tắt; không bao giờ dùng cho marketing. Critical cực hiếm (y tế, an toàn, cơ quan công quyền).
- Action [HIG]: detail view có tối đa **4 nút**; nhãn ngắn, title-case, mô tả kết quả, không chứa tên app; không có action chỉ để mở app; ưu tiên non-destructive (destructive có giao diện riêng); mỗi action nên có interface icon (SF Symbol) hiển thị bên trailing.
- Khác [HIG]: không gửi nhiều notification cho cùng một việc; không dùng notification để bảo người dùng làm task; lỗi → alert, không phải notification; khi app đang foreground → cập nhật UI kín đáo thay vì notification; badge chỉ đếm notification chưa đọc, cập nhật ngay, không vẽ badge giả.
- [dev] `UNNotificationInterruptionLevel` (iOS 15/macOS 12), `UNNotificationAction` options `.destructive`/`.foreground`/`.authenticationRequired`, `UNTextInputNotificationAction` (trả lời inline), `UNNotificationActionIcon` (iOS 15/macOS 12), `UNNotificationContent.updating(from:)` (iOS 15/macOS 12).

### (f) Xin quyền (permission)
Nguồn: https://developer.apple.com/design/human-interface-guidelines/privacy#Requesting-permission

- [HIG] Chỉ xin khi thật cần, lý tưởng là lúc người dùng dùng tính năng; tránh xin lúc launch trừ khi app không chạy được nếu thiếu.
- [HIG] Danh mục phải xin gồm: local network, Bluetooth peripherals, camera, microphone, messages/contacts…
- [HIG] Purpose string: một câu ngắn, hoàn chỉnh, cụ thể; sentence case; chủ động (không bị động); có dấu chấm; hiển thị sau tên app trong alert hệ thống. Ví dụ tốt: nêu cách + lý do dùng dữ liệu; ví dụ xấu: câu bị động mơ hồ, hoặc câu mệnh lệnh không lý do.
- [HIG] Pre-alert screen/window (tuỳ chọn, chỉ khi ngữ cảnh chưa đủ rõ): **đúng một nút**, tên kiểu "Continue"/"Next" (không dùng "Allow"), bấm là mở alert hệ thống; **không** có nút đóng/hủy/thoát — ngoại lệ duy nhất: cần để lấy **legal consent**.
- [HIG] Nếu app cần quyền trước khi hoạt động → có thể đưa vào onboarding để giải thích lợi ích.

### (g) Onboarding
Nguồn: https://developer.apple.com/design/human-interface-guidelines/onboarding · https://developer.apple.com/design/human-interface-guidelines/launching

- [HIG] Onboarding diễn ra sau launch, không thuộc launch; nhanh, vui, **tuỳ chọn**.
- [HIG] Dạy bằng tương tác; ưu tiên tip theo ngữ cảnh (TipKit) thay vì một flow dài.
- [HIG] Flow bắt buộc: ngắn, không bắt nhớ nhiều. Tutorial riêng: cho skip, skip rồi không hiện lại, nhưng tìm lại được (help/settings).
- [HIG] Chỉ nói về app, không dạy cách dùng hệ thống/thiết bị.
- [HIG] Splash screen nếu cần: ngắn, ở đầu onboarding. Không hiện licensing trong onboarding. Không để tải lớn chặn onboarding.
- [HIG] Hoãn setup không thiết yếu; default hợp lý. Xin quyền trong onboarding chỉ khi app cần để chạy; còn lại xin lúc dùng tính năng. Chưa hỏi rating/mua sớm.
- [HIG Launching] macOS không cần launch screen; khôi phục trạng thái trước khi mở lại (vị trí cửa sổ, cuộn).

### (h) Cảnh báo khẩn kiểu "cuộc gọi đến" trên macOS
Nguồn: https://developer.apple.com/design/human-interface-guidelines/notifications#Anatomy · https://developer.apple.com/design/human-interface-guidelines/panels · https://developer.apple.com/design/human-interface-guidelines/alerts · https://developer.apple.com/design/human-interface-guidelines/popovers · https://developer.apple.com/documentation/usernotifications/implementing-communication-notifications

HIG không có pattern "incoming call" riêng cho macOS. Tổng hợp:
- **Notification** [HIG]: là component duy nhất HIG nêu rõ cho "phone call or message" (communication notification: avatar, tên người gọi, Focus theo người gửi). Hoạt động khi app không active, có action (≤ 4), tôn trọng Focus/scheduled delivery. [dev] cuộc gọi đến → `INStartCallIntent` communication notification (macOS 12.0+).
- **Panel** [HIG]: bảng nổi chứa control bổ trợ cho cửa sổ/selection đang active; cần title bar (tiêu đề danh từ ngắn), control đơn giản, không nút minimize, không liệt kê trong Window menu, **ẩn khi app inactive**. Panel cuộc gọi luôn nổi trên mọi app/Space là **lệch** quy tắc ẩn-khi-inactive → là quyết định có chủ đích, cần giữ tối giản, non-activating (`NSWindow.StyleMask.nonactivatingPanel`, `hidesOnDeactivate = false` [dev]).
- **Alert** [HIG]: cho thông tin quan trọng cần hành động ngay, nhưng modal, ngắt task; dùng ít; không dùng khi app mới mở; lỗi → alert. `NSAlert` là modal của app → không hợp cho sự kiện nền đến từ app menu bar đang không active. [Đề xuất] không dùng NSAlert cho cuộc gọi.
- **Popover** [HIG]: tạm thời, dễ bị đóng nhầm, không dùng để cảnh báo → không dùng cho chuông cuộc gọi.
- **Live Activity** [HIG]: trên Mac chỉ hiện Live Activity khởi chạy từ iPhone (qua menu bar, mở iPhone Mirroring); [dev] ActivityKit không có trên macOS → không phải lựa chọn cho app Mac.
- [Đề xuất] Kết hợp: (1) communication notification + action "Trả lời"/"Từ chối" làm kênh báo chính, tôn trọng Focus; (2) panel nổi non-activating cho ringing (tuỳ chọn, đang là thiết kế CALL-01) và cho cuộc gọi đang diễn ra (mute/hold/keypad) — nhỏ, kéo được, tiêu đề "Cuộc gọi"; (3) kiểu thông báo Banner/Alert do người dùng chọn trong System Settings, app chỉ đọc được qua `UNNotificationSettings.alertStyle` [dev] → có thể gợi ý chọn "Alerts" để thông báo cuộc gọi không tự biến mất.

---

## 2. Liquid Glass — thay đổi áp lên component

Nguồn: https://developer.apple.com/design/human-interface-guidelines/materials#Liquid-Glass · https://developer.apple.com/design/human-interface-guidelines/color#Liquid-Glass-color · https://developer.apple.com/design/human-interface-guidelines/layout#Visual-hierarchy · https://developer.apple.com/design/human-interface-guidelines/scroll-views#Scroll-edge-effects · https://developer.apple.com/documentation/technologyoverviews/adopting-liquid-glass

**[HIG]**
- Liquid Glass = lớp chức năng (control, navigation: tab bar, sidebar, toolbar) nổi trên content layer. **Không dùng Liquid Glass trong content layer** (ngoại lệ: control tạm thời như slider/toggle hoá kính khi đang tương tác). Dùng hiệu ứng glass cho custom control **ít thôi**.
- 2 biến thể: `regular` (làm mờ + chỉnh độ sáng nền; đa số system component; dùng khi nhiều chữ: alert, sidebar, popover) và `clear` (rất trong, chỉ trên nền media giàu hình). Nền sáng dưới clear glass → thêm lớp dim đen **35%** opacity.
- Màu: glass không có màu riêng, lấy màu nội dung phía sau; có thể "nhuộm" cho nhấn mạnh (cách hệ thống làm prominent button). Tô màu **nền** cho primary action (vd Done), không tô chữ/symbol; không tô nền nhiều control; nội dung sặc sỡ → toolbar/tab bar đơn sắc. Custom color cần biến thể light/dark + increased contrast, kể cả app chỉ một appearance.
- Toolbar/tab bar nhỏ: glass tự chuyển sáng/tối theo nội dung bên dưới; symbol/text đơn sắc. Sidebar: glass đục hơn.
- Phân tách control với content bằng **scroll edge effect**, không dùng nền đặc/bán trong dưới control. Nền full-screen kéo dài dưới sidebar/toolbar/tab bar; dùng background extension effect nếu bị che (`backgroundExtensionEffect()`, `UIBackgroundExtensionView`).
- Scroll edge effect (2026-06-08): ưu tiên style `automatic` (đục hơn cho top toolbar nhiều control, text ngoài glass, pinned header); style soft phải test legibility; chỉ dùng khi có scroll view dưới element nổi; **một** scroll edge effect mỗi view (split view: mỗi pane một cái, cao bằng nhau). API: `ScrollEdgeEffectStyle`, `UIScrollEdgeEffect.Style`, `NSScrollEdgeEffectStyle`.
- Toolbar: control/header/footer chuẩn có bán kính góc **đồng tâm (concentric)** với góc bar; custom component cũng phải concentric. Giảm nền custom và control tô màu trong toolbar.

**[dev] (Adopting Liquid Glass, không phải HIG)**
- Component chuẩn SwiftUI/UIKit/AppKit tự nhận Liquid Glass khi build SDK mới; bỏ nền custom ở `NavigationStack`, `NavigationSplitView`, `toolbar(content:)`, `NSToolbar`, `NSSplitView`…
- Control bo tròn hơn (theo hình phần cứng), knob slider/toggle hoá kính khi tương tác, button morph thành menu/popover; có kích thước **extra-large**.
- Button style: SwiftUI `.glass`, `.glassProminent`, `.glass(_:)`; UIKit `UIButton.Configuration.glass()`, `.prominentGlass()`, `.clearGlass()`, `.prominentClearGlass()`; AppKit `NSButton.BezelStyle.glass` (macOS 26.0).
- Hình đồng tâm: `ConcentricRectangle`, `rect(corners:isUniform:)`; UIKit `cornerConfiguration`/`UICornerConfiguration`.
- Glass tuỳ biến: `glassEffect(_:in:)`, `GlassEffectContainer` (gộp để tối ưu + morph), UIKit `UIGlassEffect`, AppKit `NSGlassEffectView`.
- Toolbar: nhóm item; spacer cố định `ToolbarSpacer`/`fixed`, `UIBarButtonItem.fixedSpace(_:)`, `NSToolbarItem.Identifier.space`; không trộn text và icon trong cùng một nhóm nền; mọi icon phải có accessibility label; ẩn cả toolbar item (`hidden(_:)`), không chỉ ẩn view bên trong.
- Menu: dùng selector chuẩn (Cut/Copy/Paste…) để hệ thống tự gắn icon.
- Window bo góc lớn hơn; sheet bán kính góc lớn hơn, half sheet thụt khỏi mép; action sheet mọc từ control nguồn (phải set source).
- List/table/form: hàng cao hơn, padding lớn hơn; section header dùng title-style capitalization (không còn tự viết hoa toàn bộ) → dùng `Form` + `.formStyle(.grouped)`.
- Search tab: `Tab(role: .search)`; tab bar minimize: `.tabBarMinimizeBehavior(.onScrollDown)`.
- `UIDesignRequiresCompatibility` (tạm giữ giao diện cũ) **bị bỏ qua khi build cho iOS/iPadOS/macOS 27 trở lên** → build bằng SDK 27 là bắt buộc theo Liquid Glass.

---

## 3. macOS shell: menu bar, menu
Nguồn: https://developer.apple.com/design/human-interface-guidelines/menus-and-actions

### 3.1 The menu bar (App menu, Window menu, menu bar extra)
Nguồn: https://developer.apple.com/design/human-interface-guidelines/the-menu-bar (cập nhật 2025-06-09)

General / macOS:
- Thứ tự menu chuẩn: *AppName*, File, Edit, Format, View, menu riêng của app, Window, Help. Luôn hiện cùng bộ mục; mục không dùng được thì **disable**, không ẩn.
- Tên menu ngắn, ưu tiên một từ; nhiều từ thì title-style.
- App menu (thứ tự): About *AppName* (tên ngắn ≤ **16 ký tự**, không số phiên bản, tách riêng bằng separator) → Settings… → mục cấu hình riêng → Services → Hide *AppName* → Hide Others → Show All → Quit *AppName*.
- Edit menu có ích cả cho app không document (Undo/Redo/Cut/Copy/Paste/Delete/Select All…); dùng "Delete", không "Erase/Clear".
- Có View menu dù chỉ hỗ trợ một phần; mục show/hide phản ánh trạng thái hiện tại.
- Luôn có **Window menu** kể cả app một cửa sổ (Minimize, Zoom cho Full Keyboard Access); có thể có lệnh show/hide panel; không liệt kê panel trong danh sách cửa sổ.
- Mục dynamic (giữ Option…) không được là cách duy nhất; chỉ dùng một phím bổ trợ.
- Icon menu item: dùng icon giống hệ thống cho Copy/Share/Delete…; hỗ trợ shortcut chuẩn.

Menu bar extra: xem mục (a). Số liệu: menu bar cao **24 pt**.

iPadOS (guidance menu bar iPadOS thêm 2025-06-09): ẩn đến khi kéo từ mép trên; căn giữa; **không có menu bar extra**; *AppName* > Settings dành để mở trang app trong Settings hệ thống, settings nội bộ thì thêm mục riêng ngay dưới; mỗi tab có thể là mục trong View menu; gom submenu để tiết kiệm chiều dọc.

API [HIG]: `MenuBarExtra`, `CommandMenu`, `NSStatusBar`, `isAlternate`, `NSHelpManager`.

[Đề xuất HandLive] App LSUIElement không có menu bar riêng (xem §11) → mọi lệnh quan trọng phải có trong menu của extra hoặc ngay trong cửa sổ.

### 3.2 Menus
Nguồn: https://developer.apple.com/design/human-interface-guidelines/menus (cập nhật 2026-06-08)

- Nhãn: động từ cho hành động; title-style capitalization; bỏ mạo từ; mục chưa dùng được → dim (menu vẫn mở được); thêm dấu **…** khi cần thêm thông tin trước khi hoàn tất.
- Icon (2026-06-08): dùng **ít, có mục đích** (hành động phổ biến, vị trí file, **thiết bị đang kết nối**, nội dung người dùng); không có icon rõ nghĩa thì bỏ; trong một nhóm: **tất cả có icon hoặc không mục nào có**. Dùng Standard icons cho Copy/Paste…
- Tổ chức: mục quan trọng lên đầu; nhóm bằng separator; lệnh liên quan cùng nhóm.
- Submenu: dùng ít, sâu **1 cấp**; submenu > ~**5** mục → cân nhắc menu mới; submenu luôn mở được.
- Mục toggle: nhãn đổi theo trạng thái (Show X/Hide X) hoặc **checkmark** cho thuộc tính đang bật; thêm động từ nếu nhãn mơ hồ.
- iOS/iPadOS: layout small (4 icon hàng đầu), medium (3 icon + nhãn), large (mặc định) — `preferredElementSize`.
- API: `Menu` (SwiftUI), `NSMenu`, UIKit Menus and shortcuts.
- [Đề xuất HandLive] Menu extra: nhóm "thiết bị" có icon điện thoại (thiết bị kết nối được HIG khuyến khích có icon); các toggle "Đồng bộ clipboard", "Nhận SMS", "Thông báo cuộc gọi" dùng checkmark.

### 3.3 Context menus
Nguồn: https://developer.apple.com/design/human-interface-guidelines/context-menus (cập nhật 2023-12-05)

- Chỉ chứa lệnh liên quan nhất tới item; ngắn; hỗ trợ nhất quán khắp app; mọi lệnh cũng phải có ở UI chính/menu bar.
- **Ẩn** mục không dùng được (khác menu thường); macOS ngoại lệ Cut/Copy/Paste có thể hiện dim.
- Submenu 1 cấp; ≤ ~**3** nhóm; không hiện keyboard shortcut trong context menu.
- iOS/iPadOS: destructive (Delete/Remove) ở **cuối** và đánh dấu destructive; preview đồ hoạ; không vừa context menu vừa edit menu cho cùng item.
- API: `contextMenu(menuItems:)`, `UIContextMenuInteraction`, `popUpContextMenu(_:with:for:)`.
- [Đề xuất HandLive] Hội thoại SMS: context menu "Đánh dấu đã đọc", "Sao chép số", "Xoá hội thoại…" (cuối, destructive); trên iOS khớp với swipe action ([dev] top menu action nên khớp swipe action).

### 3.4 Dock menus
Nguồn: https://developer.apple.com/design/human-interface-guidelines/dock-menus

- Mục Dock menu cũng phải có ở chỗ khác; ưu tiên mục giá trị cao (danh sách cửa sổ, vài lệnh hữu ích khi app không frontmost). API `applicationDockMenu(_:)`.
- HandLive dùng `LSUIElement = YES` → không có Dock icon/Dock menu; HIG gợi ý Dock menu như kênh dự phòng cho menu bar extra → xem §11.

### 3.5 Controls (Control Center)
Nguồn: https://developer.apple.com/design/human-interface-guidelines/controls (mới 2024-06-10)

- Control = button hoặc toggle truy cập nhanh từ Control Center, Lock Screen, Action button; gồm symbol + title + value (tuỳ). HIG: hỗ trợ iOS, iPadOS, macOS ("không có lưu ý riêng cho macOS").
- Dành cho hành động có lợi nhất mà không cần mở app; cập nhật trạng thái sau tương tác/push; symbol mô tả hành vi (toggle cần symbol on + off), animate khi đổi trạng thái; tint theo brand; placeholder khi title/value thay đổi; ẩn thông tin nhạy cảm khi khoá; cần xác thực với hành động liên quan bảo mật.
- [dev] `ControlWidget`: iOS 18.0, macOS 26.0.
- [Đề xuất HandLive] Progressive enhancement: control "Gửi clipboard sang Android" (button) / "Đồng bộ clipboard" (toggle). Vị trí trên menu bar macOS: CHƯA XÁC MINH.

---

## 4. Cửa sổ & trình bày (presentation)
Nguồn: https://developer.apple.com/design/human-interface-guidelines/presentation

### 4.1 Windows
Nguồn: https://developer.apple.com/design/human-interface-guidelines/windows (cập nhật 2025-06-09)

- Primary window (điều hướng + nội dung chính) vs auxiliary window (một task, không điều hướng sang vùng khác, có nút đóng).
- Cửa sổ co giãn mượt; mở cửa sổ mới đúng lúc (không mặc định mở tràn lan), có thể cho "mở trong cửa sổ mới" qua context menu/File menu (`OpenWindowAction`).
- **Không tự vẽ window UI** (frame, nút điều khiển); dùng từ "window" với người dùng (không "scene").
- macOS: trạng thái main/key/inactive có giao diện khác — custom window phải theo; tránh thông tin/hành động quan trọng ở **bottom bar** (cửa sổ hay bị kéo khuất mép dưới).
- [dev] Liquid Glass: cửa sổ bo góc lớn hơn.
- API: `Windows`, `WindowGroup`, `NSWindow`, `UIWindow`.
- [Đề xuất HandLive] Messages window = primary; Settings = auxiliary; QR pairing = sheet trên Settings/onboarding; không đặt nút gửi SMS ở bottom bar của window (nhưng ô soạn tin trong content là bình thường).

### 4.2 Panels
Nguồn: https://developer.apple.com/design/human-interface-guidelines/panels

- Panel nổi trên cửa sổ, cung cấp control/thông tin bổ trợ cho cửa sổ/selection đang active; kém nổi bật hơn window.
- Ưu tiên control chỉnh đơn giản (slider, stepper), tránh gõ text/chọn item nhiều bước.
- Có title bar với tiêu đề ngắn (danh từ, title-style) để kéo; nhắc tới panel bằng tiêu đề, không gọi "panel".
- App active → đưa mọi panel lên trước; app **inactive → ẩn** mọi panel. Không nút minimize. Không liệt kê trong Window menu.
- HUD panel (tối, trong suốt): chỉ cho app media hoặc khi panel chuẩn che nội dung quan trọng, và khi hầu như không có control (trừ disclosure triangle); dùng ít màu; nhỏ; giữ một style khi đổi mode. API `hudWindow`.
- API: `NSPanel`; [dev] `isFloatingPanel`, `NSWindow.StyleMask.nonactivatingPanel`, `hidesOnDeactivate`.
- [Đề xuất HandLive] Panel cuộc gọi: tiêu đề "Cuộc gọi đến"/"Đang gọi"; panel chuẩn (không HUD, vì có nhiều button); không minimize; `hidesOnDeactivate = false` là **lệch HIG có chủ đích** (ghi rõ trong design system).

### 4.3 Popovers
Nguồn: https://developer.apple.com/design/human-interface-guidelines/popovers

- Cho lượng nhỏ thông tin/chức năng; tự đóng khi click ra ngoài hoặc chọn item; nút Close/Cancel/Done chỉ khi làm rõ (vd thoát có/không lưu); nhiều lựa chọn → giữ mở tới khi dismiss.
- **Luôn lưu** khi nonmodal popover tự đóng; chỉ bỏ dữ liệu khi bấm Cancel.
- Một popover mỗi lúc, không popover lồng; không gì phủ lên popover ngoài alert; mũi tên chỉ đúng nguồn; không quá to; đổi kích thước có animation.
- **Không dùng popover để cảnh báo** (dễ bỏ lỡ/đóng nhầm) → alert.
- iOS: tránh popover ở compact width → sheet.
- macOS: cho phép **detach** thành panel, giữ giao diện gần giống.
- API: `popover(isPresented:attachmentAnchor:arrowEdge:content:)`, `UIPopoverPresentationController`, `NSPopover`.

### 4.4 Sheets
Nguồn: https://developer.apple.com/design/human-interface-guidelines/sheets (cập nhật 2026-03-24)

General:
- Cho task phạm vi hẹp gắn với ngữ cảnh hiện tại. macOS sheet luôn **modal**; iOS/iPadOS có thể nonmodal.
- Nút: Cancel/Close (bỏ thay đổi), Done (hoàn tất/lưu), Back (bước trước trong flow, không để dismiss). Done phải đi kèm Cancel hoặc Back; không hiện cả 3.
- Task phức tạp/dài → cân nhắc thay sheet (macOS: cửa sổ riêng; iOS: full-screen modal cho video/ảnh/**camera view**/multistep).
- Một sheet mỗi lúc; sheet sinh sheet khác → đóng cái đầu trước.
iOS/iPadOS:
- Cancel leading, Done trailing ở top toolbar; flow nhiều bước xem §1(c).
- Detent: `large` (full), `medium` (~nửa); luôn có large; thêm medium cho progressive disclosure; compose (Messages/Mail) chỉ full height; có **grabber** khi resize được (`prefersGrabberVisible`); hỗ trợ **vuốt để đóng**, có thay đổi chưa lưu → action sheet xác nhận; iPad dùng page/form sheet.
macOS:
- Sheet dạng thẻ bo góc nổi trên cửa sổ cha (cửa sổ cha dim); kích thước mặc định hợp lý (cho resize nếu cần); vẫn cho tương tác với cửa sổ khác của app; cần nhập lặp lại + xem kết quả → dùng panel.
- [dev] Liquid Glass: bán kính góc lớn hơn; half sheet thụt khỏi mép, lên full thì đục hơn.
- API: `sheet(item:onDismiss:content:)`, `UISheetPresentationController` (`detents`), `presentAsSheet(_:)`.
- [Đề xuất HandLive] QR pairing sheet (Mac): kích thước cố định vừa QR + hướng dẫn, nút Cancel; khi ghép xong tự đóng. Consent sheet call audio: sheet modal với "Huỷ" + "Đồng ý" (default trailing, không destructive). iOS "Soạn tin": sheet large-only.

### 4.5 Alerts
Nguồn: https://developer.apple.com/design/human-interface-guidelines/alerts (cập nhật 2024-02-02)

- Dùng ít; không alert thuần thông tin (dùng indicator trong ngữ cảnh, vd Mail báo mất kết nối bằng indicator); không alert cho hành động phá huỷ thường gặp có thể undo; **không alert khi app vừa mở** (vd mất mạng → hiện dữ liệu cache + nhãn nhẹ).
- Nội dung: title, informative text (tuỳ), ≤ **3** nút; iOS/iPadOS/macOS có thể có text field; macOS thêm icon, accessory view, checkbox suppression, help button.
- Title: mô tả tình huống cụ thể, không "Error"/mã lỗi, không quá **2 dòng**; câu hoàn chỉnh → sentence case + dấu câu; mảnh câu → title-style, không dấu chấm. Informative text chỉ khi có giá trị. Không giải thích nút.
- Nút: 1–2 từ, động từ ("View All", "Reply", "Ignore"); "Cancel" luôn là tên nút huỷ; tránh "OK" làm default trừ alert thông tin; tránh "Yes/No". Vị trí/role: §1(c).
- iOS: lựa chọn liên quan hành động chủ động → action sheet; tránh alert phải cuộn.
- macOS: tự hiện app icon (thay được); cho suppress alert lặp; symbol cảnh báo `exclamationmark.triangle` dùng rất hạn chế.
- API: `alert(_:isPresented:actions:)`, `UIAlertController`, `NSAlert`; [dev] `beginSheetModal(for:completionHandler:)` (alert dạng sheet).
- [Đề xuất HandLive] Mất kết nối điện thoại: indicator trong menu extra/cửa sổ, **không** alert. Alert dành cho: huỷ ghép nối (không undo), lỗi không tự phục hồi.

### 4.6 Action sheets (confirmation dialog)
Nguồn: https://developer.apple.com/design/human-interface-guidelines/action-sheets

- Lựa chọn liên quan hành động người dùng **chủ động** làm (vd huỷ bản nháp: xoá hay lưu). Dùng ít; title 1 dòng; message chỉ khi cần.
- Cancel ở cuối (SwiftUI confirmation dialog tự có Cancel); destructive ở đầu, style destructive.
- iOS: dùng action sheet chứ không menu cho lựa chọn phát sinh từ hành động; không để cuộn.
- [dev] Liquid Glass: action sheet mọc từ control nguồn, phải set source (`confirmationDialog(_:isPresented:titleVisibility:presenting:actions:)`, `sourceView`/`sourceItem`).
- API: `confirmationDialog(_:isPresented:titleVisibility:actions:)` (iOS 16/macOS 13), `UIAlertController.Style.actionSheet`, `ButtonRole.destructive`.

### 4.7 Modality
Nguồn: https://developer.apple.com/design/human-interface-guidelines/modality (cập nhật 2023-12-05)

- Chỉ modal khi có lợi rõ; ngắn, đơn giản; tránh "app trong app" (nếu có subview: một đường đi duy nhất).
- Full-screen modal hợp cho video/ảnh/**camera view**/multistep.
- Luôn có cách dismiss rõ: iOS/iPadOS/watchOS → nút ở top toolbar hoặc vuốt xuống; **macOS/tvOS → nút trong main content view**.
- Xác nhận trước khi đóng nếu mất nội dung người dùng tạo; đặt title nêu task; một modal mỗi lúc; không bao giờ 2 alert cùng lúc (alert được phép nằm trên modal khác).
- [Đề xuất HandLive] Màn quét QR iOS: full-screen modal (camera view), nút Close/Cancel ở top toolbar.

---

## 5. Controls
Nguồn: https://developer.apple.com/design/human-interface-guidelines/selection-and-input · https://developer.apple.com/design/human-interface-guidelines/menus-and-actions · https://developer.apple.com/design/human-interface-guidelines/status · https://developer.apple.com/design/human-interface-guidelines/layout-and-organization

### 5.1 Buttons
Nguồn: https://developer.apple.com/design/human-interface-guidelines/buttons (cập nhật 2025-12-16)

General:
- 3 thuộc tính: style, content (symbol/text/cả hai), role. Hit region ≥ 44x44 pt; custom button phải có **pressed state**.
- Style/role/số prominent: §1(c). Không dùng màu label giống màu nền content layer (xem Liquid Glass color).
- Content: symbol quen thuộc cho hành động quen thuộc (`square.and.arrow.up` = share); text khi rõ hơn icon; text title-style, nên bắt đầu bằng động từ. macOS/visionOS: tooltip khi hover.
iOS/iPadOS:
- Button có thể hiện activity indicator + đổi nhãn khi hành động chưa xong ngay (vd "Checkout" → "Checking out…").
macOS (loại button riêng):
- **Push button** (chuẩn; text/symbol/icon/ảnh; có thể là default, có tint); flexible-height chỉ khi nội dung cao/2 dòng (`NSButton.BezelStyle.flexiblePush`); thêm dấu **…** khi push button mở window/view/app khác; hỗ trợ spring loading.
- **Square/gradient button**: chỉ symbol, gắn với view (thêm/xoá hàng), không dùng ở toolbar/status bar (`.smallSquare`).
- **Help button**: tròn, dấu "?"; tối đa 1/cửa sổ; mở đúng chủ đề; không đặt ở toolbar; vị trí:

| Loại view | Vị trí help button |
|---|---|
| Dialog có nút dismiss (OK/Cancel) | Góc dưới, đối diện nút dismiss, thẳng hàng |
| Dialog không có nút dismiss | Góc dưới trái hoặc phải |
| Settings window/pane | Góc dưới trái hoặc phải |

- **Image button**: trong view, không ở toolbar; padding ~**10 px** giữa ảnh và mép; nhãn (nếu có) nằm dưới.
- Liquid Glass: xem §2 (`.glass`, `.glassProminent`, `NSButton.BezelStyle.glass`, extra-large).
- API: `Button`, `UIButton`, `NSButton`.

### 5.2 Toggles
Nguồn: https://developer.apple.com/design/human-interface-guidelines/toggles (cập nhật 2024-03-29)

- Toggle chỉ cho hai trạng thái đối lập ảnh hưởng nội dung/view; hành động khác → component khác (vd pop-up).
- Nêu rõ toggle ảnh hưởng gì; khác biệt trạng thái phải rõ, **không chỉ dựa vào màu**.
- iOS và macOS: xem §1(b). API: `Toggle`, `ToggleStyle`, `UISwitch` (`changesSelectionAsPrimaryAction` cho button-toggle), `NSSwitch`, `NSButton.ButtonType.toggle`.
- [Đề xuất HandLive] Settings Mac: switch cho feature chính ("Đồng bộ clipboard", "Tin nhắn SMS", "Nghe gọi trên Mac", "Camera ảo"); mini switch/checkbox cho option phụ ("Tự xoá clipboard sau 60 s", "Đổ chuông trên Mac"). Panel cuộc gọi: Mute/Hold là **button-toggle** (không switch).

### 5.3 Segmented controls
Nguồn: https://developer.apple.com/design/human-interface-guidelines/segmented-controls

- Lựa chọn liên quan chặt ảnh hưởng object/state/view; hoặc nhóm hành động (momentary). Không trộn segment hành động với segment trạng thái.
- ≤ ~**5–7** segment ở giao diện rộng, ≤ ~**5** trên iPhone; segment rộng đều; text **hoặc** ảnh, không trộn; nhãn danh từ, title-style.
- iOS: chuyển giữa subview liên quan chặt; khu vực tách biệt hẳn → tab bar.
- macOS: có thể thêm text giới thiệu/nhãn dưới segment; tooltip mỗi segment; **đổi view trong main window → tab view**, segmented dùng ở toolbar/inspector.
- API: `.pickerStyle(.segmented)`, `UISegmentedControl`, `NSSegmentedControl` (`.momentary`).
- [Đề xuất HandLive] Camera: "Trước | Sau" = segmented (2 segment) hoặc radio.

### 5.4 Pop-up buttons
Nguồn: https://developer.apple.com/design/human-interface-guidelines/pop-up-buttons

- Danh sách **phẳng**, lựa chọn **loại trừ nhau**; cần action/đa chọn/submenu → pull-down.
- Default hữu ích; đoán được option khi chưa mở (label giới thiệu); hợp khi thiếu chỗ; có thể thêm mục Custom.
- iPadOS: trong popover/modal, pop-up thay disclosure indicator khi option ít.
- API: `MenuPickerStyle` / `.pickerStyle(.menu)`, `NSPopUpButton`, UIKit `changesSelectionAsPrimaryAction`.
- [Đề xuất HandLive] "Chất lượng camera: Tự động / 480p / 720p / 1080p" = pop-up, default "Tự động".

### 5.5 Pull-down buttons
Nguồn: https://developer.apple.com/design/human-interface-guidelines/pull-down-buttons

- Menu lệnh liên quan trực tiếp tới mục đích nút (Add…, Sort…). Không giấu mọi hành động chính trong một pull-down.
- Ít nhất **3** mục (1–2 mục → dùng button/toggle); title menu chỉ khi thêm nghĩa; mục destructive màu đỏ + xác nhận (action sheet iOS / popover iPadOS); icon khi có giá trị.
- iOS: More button (…) cho mục phụ, cân nhắc khả năng khám phá.
- API: `Menu`, `showsMenuAsPrimaryAction`, `NSPopUpButton.pullsDown`.
- [Đề xuất HandLive] "Từ chối kèm tin nhắn…" có thể là pull-down với ≥ 3 mẫu tin + "Tuỳ chỉnh…".

### 5.6 Pickers
Nguồn: https://developer.apple.com/design/human-interface-guidelines/pickers

- Cho danh sách vừa-dài; ngắn → pull-down/pop-up; rất dài → list/table. Giá trị có thứ tự đoán được; hiện tại chỗ, không chuyển view; phút cách đều chia hết 60 (vd 15).
- iOS date picker: compact / inline / wheels / automatic; mode date, time, date+time, countdown (tối đa 23 giờ 59 phút).
- macOS date picker: textual hoặc graphical (`NSDatePicker`).
- API: `Picker`, `DatePicker`, `UIDatePicker`, `UIPickerView`.

### 5.7 Text fields · Token fields · Text views
Nguồn: https://developer.apple.com/design/human-interface-guidelines/text-fields · https://developer.apple.com/design/human-interface-guidelines/token-fields · https://developer.apple.com/design/human-interface-guidelines/text-views

- Text field cho lượng nhỏ; nhiều → text view. Placeholder gợi ý + label riêng (placeholder biến mất khi gõ); secure field cho dữ liệu nhạy cảm (`SecureField`); kích thước theo lượng text; xếp dọc, rộng nhất quán; tab order hợp lý; validate đúng lúc; number formatter cho số; wrap/truncate phù hợp; expansion tooltip cho text bị cắt (macOS).
- iOS: Clear button ở trailing; leading chỉ mục đích, trailing chức năng thêm; bàn phím đúng loại. macOS: combo box khi cần text + danh sách.
- **Token field (chỉ macOS)**: chuyển text thành token (vd người nhận trong Mail); context menu cho token; thêm phím tạo token ngoài dấu phẩy (Return); chỉnh delay gợi ý. API `NSTokenField`.
- Text view: text dài/sửa được/định dạng; giữ dễ đọc, Dynamic Type; cho select/copy text hữu ích. API `TextEditor`/`Text`, `UITextView`, `NSTextView`.
- [Đề xuất HandLive] Soạn SMS mới trên Mac: ô người nhận = token field (gợi ý từ danh bạ đã đồng bộ); ô nội dung = text view nhiều dòng. SwiftUI không có token field thuần trên macOS 13 → cần bọc `NSTokenField` (CHƯA XÁC MINH có API SwiftUI tương đương).

### 5.8 Labels
Nguồn: https://developer.apple.com/design/human-interface-guidelines/labels

- Text tĩnh ngắn; ưu tiên font hệ thống (Dynamic Type); 4 màu label: `label`/`labelColor` (chính), `secondaryLabel`/`secondaryLabelColor` (phụ), `tertiaryLabel`/`tertiaryLabelColor` (mục không khả dụng), `quaternaryLabel`/`quaternaryLabelColor` (watermark).
- Cho **select/copy** label hữu ích (lỗi, địa chỉ, IP) → [Đề xuất] số điện thoại, mã thiết bị, IP trong trang thiết bị.
- API: `Label`, `Text`, `UILabel`, `NSTextField` (`isEditable = false`).

### 5.9 Progress indicators
Nguồn: https://developer.apple.com/design/human-interface-guidelines/progress-indicators

- Determinate (biết thời lượng) ưu tiên hơn indeterminate; tiến độ chính xác, đều; luôn chuyển động (đứng yên = treo); chuyển indeterminate → determinate khi được; **không** đổi từ spinner sang bar; mô tả ngữ cảnh cụ thể (tránh "loading", "authenticating" chung chung); vị trí nhất quán; cho Cancel (và Pause nếu huỷ gây mất tiến độ); huỷ gây mất dữ liệu → alert xác nhận.
- iOS: refresh control (kéo xuống) — vẫn phải tự cập nhật định kỳ; title chỉ khi có giá trị (vd lần cập nhật cuối).
- macOS: spinner cho tác vụ nền/chỗ hẹp (trong text field, cạnh button); thường **không gắn nhãn** cho spinner.
- API: `ProgressView`, `UIProgressView`, `UIActivityIndicatorView`, `UIRefreshControl`, `NSProgressIndicator`.
- [Đề xuất HandLive] Gửi ảnh clipboard 5 MB: bar determinate; đồng bộ SMS lần đầu: determinate theo trang nếu biết tổng, không thì spinner nhỏ cạnh tiêu đề sidebar.

### 5.10 Boxes · Disclosure controls
Nguồn: https://developer.apple.com/design/human-interface-guidelines/boxes · https://developer.apple.com/design/human-interface-guidelines/disclosure-controls

- Box: nhóm nội dung liên quan; nhỏ so với view chứa; không lồng box, dùng padding/alignment; title ngắn, sentence case, không dấu chấm — **trong settings pane thì thêm dấu hai chấm**; macOS title nằm trên box; iOS dùng secondary/tertiary background. API `GroupBox`, `NSBox`.
- Disclosure: ẩn chi tiết nâng cao; triangle (có label mô tả, vd "Advanced Options") và disclosure button (đặt gần nội dung, ≤ 1/view). API `DisclosureGroup` (iOS 14/macOS 11), `NSButton.BezelStyle.disclosure`, `.pushDisclosure`.
- [Đề xuất HandLive] Camera: "Tuỳ chọn nâng cao" (USB boost, bitrate) sau disclosure.

---

## 6. Điều hướng & cấu trúc
Nguồn: https://developer.apple.com/design/human-interface-guidelines/navigation-and-search · https://developer.apple.com/design/human-interface-guidelines/layout-and-organization

### 6.1 Sidebars
Nguồn: https://developer.apple.com/design/human-interface-guidelines/sidebars (cập nhật 2026-06-08)

- Sidebar nổi trong lớp Liquid Glass (iOS/iPadOS/macOS); cho nội dung kéo dài dưới sidebar hoặc dùng `backgroundExtensionEffect()`.
- Cho người dùng tuỳ biến nội dung; nhóm bằng disclosure khi nhiều; symbol quen thuộc (SF Symbols/custom symbol, không bitmap); cho ẩn/hiện sidebar (macOS: nút + lệnh Show/Hide Sidebar trong View menu), **không ẩn mặc định**; ≤ **2 cấp** phân cấp (sâu hơn → split view có content list); nhãn nhóm ngắn.
- Màu icon (2026-06-08): mặc định theo app accent color; macOS người dùng đổi system accent → icon sidebar phải theo; màu cố định chỉ dùng ít, có ý nghĩa.
- iOS/iPadOS: `sidebarAdaptable` (iOS 18/macOS 15) cho tab bar ↔ sidebar; chỉ sidebar → `NavigationSplitView`/`UISplitViewController`; ưu tiên tab bar trước.
- macOS: row height/text/glyph theo cỡ small/medium/large do người dùng chọn (General settings); tự ẩn/hiện khi cửa sổ co giãn; không đặt thông tin/hành động quan trọng ở **đáy** sidebar.
- API: `NavigationSplitView`, `.listStyle(.sidebar)`, `UICollectionLayoutListConfiguration`, `NSSplitViewController`.
- [Đề xuất HandLive] Messages Mac: sidebar = danh sách hội thoại (1 cấp) + search ở đầu sidebar; không đặt nút "Soạn tin" ở đáy sidebar (đặt ở toolbar).

### 6.2 Split views
Nguồn: https://developer.apple.com/design/human-interface-guidelines/split-views (cập nhật 2025-06-09)

- Highlight bền vững selection ở mỗi pane dẫn tới detail; cho kéo-thả giữa pane.
- iOS: dùng ở regular width, không compact. iPadOS: 2 hoặc 3 pane; tính cả width hẹp/trung gian.
- macOS: pane dọc/ngang; min/max hợp lý để divider không biến mất; cho ẩn pane + nhiều cách hiện lại (toolbar button, menu, shortcut); divider **thin = 1 pt** (ưu tiên).
- API: `NavigationSplitView` (iOS 16/macOS 13), `UISplitViewController`, `NSSplitViewController`, `HSplitView`/`VSplitView`, `NSSplitView.DividerStyle`; [dev] `inspector(isPresented:content:)` (iOS 17/macOS 14).

### 6.3 Tab bars (iOS/iPadOS)
Nguồn: https://developer.apple.com/design/human-interface-guidelines/tab-bars (cập nhật 2026-06-08)

- Tab bar để **điều hướng**, không chứa hành động (hành động → toolbar); luôn hiện khi chuyển section (trừ khi modal che); số tab vừa đủ; tránh overflow (More tab); **không disable/ẩn tab** khi nội dung trống — giải thích lý do trong tab.
- Nhãn tab một từ; SF Symbols, ưu tiên **filled**; badge (oval đỏ, số hoặc "!") chỉ cho thông tin quan trọng; không tô màu nhãn giống nền content.
- iOS: tab bar **nổi** trên nội dung ở đáy, nền Liquid Glass; có thể minimize khi cuộn nếu có accessory (`TabBarMinimizeBehavior`, `tabViewBottomAccessory(content:)` — iOS 26); **search tab** ở trailing (`Tab(role: .search)` [dev]).
- iPadOS: tab bar gần đỉnh; cố định (`tabBarOnly`) hoặc chuyển thành sidebar (`sidebarAdaptable`); cho tuỳ biến, mặc định ≤ **5** tab.
- Kích thước icon tab tự vẽ: xem Apple Design Resources → CHƯA XÁC MINH trong HIG.
- API: `TabView`, `TabViewBottomAccessoryPlacement`, `UITabBar`, `TabViewCustomization`, `UITab.Placement`.
- [Đề xuất HandLive iOS] Tab: "Clipboard", "Tin nhắn", "Cuộc gọi", "Cài đặt" (4 tab, luôn hiện; nếu tính năng tắt/không hỗ trợ thì empty state giải thích); badge "Tin nhắn" = số chưa đọc. `Tab`/`sidebarAdaptable` cần iOS 18 → iOS 16/17 dùng `TabView` cũ.

### 6.4 Tab views (macOS)
Nguồn: https://developer.apple.com/design/human-interface-guidelines/tab-views

- Các pane loại trừ nhau, nội dung liên quan; control trong pane chỉ tác động pane đó; nhãn danh từ, title-style; không dùng pop-up để chuyển tab (trừ khi quá nhiều); **≤ 6 tab**; inset tab view có lề window-body quanh.
- iOS/iPadOS: dùng segmented control thay thế. API `TabView`, `NSTabView`.

### 6.5 Toolbars
Nguồn: https://developer.apple.com/design/human-interface-guidelines/toolbars (cập nhật 2025-12-16)

General:
- Nội dung: title view, điều hướng (back/forward, search), hành động (button, menu). Chọn ít item; định nghĩa item nào vào overflow khi hẹp (macOS/iPadOS hệ thống tự thêm overflow menu — **không tự thêm**); More menu chỉ khi thật cần; iPadOS/macOS cho tuỳ biến toolbar.
- Giảm nền custom/tint; dùng `ScrollEdgeEffectStyle`; component chuẩn có góc concentric.
- Title: mỗi cửa sổ có title hữu ích; **không đặt tên app làm title**; < **15 ký tự**.
- Navigation: dùng Back/Close chuẩn (symbol, không chữ "Back"/"Close").
- Action: symbol thay text (trừ "Edit"…); symbol hệ thống **không viền**; `.prominent` cho Done/Submit, một primary ở trailing.
- Nhóm item: leading (back, sidebar toggle, title, document menu — không tuỳ biến), center (control thường dùng, tuỳ biến, tự vào overflow), trailing (item quan trọng, inspector, search, More, primary action — luôn hiện). Nhóm theo chức năng/tần suất; điều hướng và Done/Close/Save ở nhóm riêng; **≤ 3 nhóm**; tách action có text bằng fixed space.
iOS: chỉ item quan trọng nhất; large title chuyển thành title thường khi cuộn (`prefersLargeTitles`).
iPadOS: toolbar + tab bar cùng hàng ngang được.
macOS: toolbar trong frame, dưới hoặc gộp title bar; item không có bezel; **mọi toolbar item phải có lệnh tương ứng trong menu bar**.
API: `Toolbars`, `UIToolbar`, `NSToolbar`; [dev] `ToolbarItemGroup`, `ToolbarSpacer` (26.0).

### 6.6 Search fields · Searching
Nguồn: https://developer.apple.com/design/human-interface-guidelines/search-fields · https://developer.apple.com/design/human-interface-guidelines/searching (cập nhật 2026-06-08)

- Placeholder nêu phạm vi; tìm ngay khi gõ; gợi ý (recent/predictive); kết quả liên quan nhất trước; scope bar + token để lọc (mặc định phạm vi rộng); hiển thị rõ phạm vi hiện tại; cân nhắc riêng tư khi hiện lịch sử tìm kiếm, cho xoá.
- iOS: 3 vị trí — search tab (standard tab: trang landing; button appearance: mở bàn phím ngay), toolbar (ưu tiên **đáy** nếu có chỗ; đỉnh khi cần nhường nội dung đáy), inline (lọc trong một view, đặt trên list, có thể pin vào top toolbar khi cuộn).
- iPadOS/macOS: search ở **trailing toolbar** cho split view nhiều cột; **đầu sidebar** khi lọc sidebar; mục riêng trong sidebar/tab bar khi cần trang khám phá; iPad chỉ bàn phím ảo thì không tự focus.
- Spotlight: index nội dung app (`CSImportExtension`, Core Spotlight).
- API: `searchable(text:placement:prompt:)` (iOS 16/macOS 13), `searchSuggestions(_:)`, `UISearchBar`, `UISearchTextField`, `NSSearchField`.
- [Đề xuất HandLive] Messages Mac: search ở đầu sidebar (lọc hội thoại) hoặc trailing toolbar — chọn một, giữ nhất quán với iPad. iOS: search inline trên list hội thoại.

### 6.7 Lists and tables
Nguồn: https://developer.apple.com/design/human-interface-guidelines/lists-and-tables

- Ưu tiên text; cho sửa/sắp xếp khi hợp lý (iOS cần edit mode); feedback chọn: điều hướng → highlight bền, option → highlight ngắn rồi checkmark; text ngắn; cắt giữa khi cần giữ đầu-cuối; header cột danh từ.
- Style: grouped (iOS, header/footer), bordered + màu xen kẽ (macOS bảng lớn).
- iOS: info button chỉ để xem thêm, drill-down dùng disclosure indicator; không index khi có control ở trailing.
- macOS: click header để sort (click lại đảo chiều); cho resize cột; màu hàng xen kẽ cho bảng nhiều cột; dữ liệu phân cấp → outline view.
- [dev] Liquid Glass: hàng cao hơn, section bo góc lớn hơn, header title-style.
- API: `List`, `Table`, `ListStyle`, `UITableView`, `UIListContentConfiguration`, `NSTableView`.

### 6.8 Scroll views
Nguồn: https://developer.apple.com/design/human-interface-guidelines/scroll-views (cập nhật 2026-06-08)

- Giữ gesture/shortcut cuộn mặc định; cho thấy còn nội dung; không lồng scroll view cùng hướng; auto-scroll tối thiểu khi cần (vd tới tin nhắn mới/điểm chèn).
- Scroll edge effect: §2. macOS: scroll bar small/mini trong panel chật, mọi control trong panel cùng cỡ.
- API: `ScrollView`, `UIScrollView`, `NSScrollView`, `ScrollEdgeEffectStyle`, `NSScrollEdgeEffectStyle` (macOS 26.1).

---

## 7. Thông báo & system experiences
Nguồn: https://developer.apple.com/design/human-interface-guidelines/system-experiences

### 7.1 Notifications
Nguồn: https://developer.apple.com/design/human-interface-guidelines/notifications

Xem §1(e). Bổ sung:
- Kiểu hiện: banner/view trên Lock Screen, Home Screen, desktop; badge; mục trong Notification Center.
- Không mô phỏng badge bằng component tự vẽ; không dùng badge cho số liệu không phải notification.
- [HIG Playing audio] macOS: âm thanh notification trộn với audio khác theo mặc định.
- [Đề xuất HandLive]
  - SMS: communication notification (`INSendMessageIntent`, `conversationIdentifier` = thread), action "Trả lời" (`UNTextInputNotificationAction`) + "Đánh dấu đã đọc"; placeholder "Tin nhắn mới".
  - Cuộc gọi đến: `INStartCallIntent` + action "Trả lời" (Mac) / "Từ chối"; cuộc gọi nhỡ: notification thường với action "Nhắn tin" (không thêm action chỉ để mở app).
  - Clipboard nhạy cảm bị chặn đồng bộ: level **passive**, không lộ nội dung.
  - Mất kết nối: không notification lặp; indicator trong UI.

### 7.2 Managing notifications
Nguồn: https://developer.apple.com/design/human-interface-guidelines/managing-notifications

- Phải xin phép trước khi gửi notification; người dùng đổi trong Settings.
- Focus + delivery scheduling (summary); người dùng chọn người/app được xuyên Focus; notification vẫn có sẵn ngay kể cả khi alert bị Focus hoãn.
- Xác định loại: communication (cuộc gọi, tin nhắn → SiriKit intents) vs noncommunication (bắt buộc gán interruption level). Bảng level: §1(e).
- Đánh giá urgency trung thực; Time Sensitive chỉ cho việc trong khoảnh khắc (≤ 1 giờ); marketing: phải opt-in, không bao giờ Time Sensitive, phải có màn settings trong app để đổi lựa chọn.
- API: `UNNotificationInterruptionLevel`, `INSendMessageIntent`, `UNNotificationContentProviding`.

### 7.3 Live Activities (iOS, tuỳ chọn)
Nguồn: https://developer.apple.com/design/human-interface-guidelines/live-activities (cập nhật 2025-12-16)

- Cho sự kiện có **đầu và cuối**, ngắn-trung bình, **≤ 8 giờ**; thông tin quan trọng nhìn lướt; không quảng cáo; tránh thông tin nhạy cảm (tóm tắt vô hại, chi tiết trong app); logo không container, không dùng nguyên app icon; text đậm (medium trở lên).
- Phải hỗ trợ presentation: compact, minimal, expanded, Lock Screen (+ StandBy). Lề concentric (`ContainerRelativeShape`); Lock Screen lề chuẩn **14 pt**; Dynamic Island bán kính góc **44 pt**; animation tối đa **2 s**.
- Tương tác: tap mở đúng chỗ; tối đa một control đơn giản; cho tắt Live Activity trong app; chỉ cập nhật khi có nội dung mới; alert chỉ cho cập nhật thiết yếu; **kết thúc ngay** khi sự kiện xong; sau khi kết thúc còn tối đa **4 giờ** trên Lock Screen/menu bar Mac/Smart Stack; custom dismissal thường **15–30 phút**.
- Kích thước iOS (pt): màn 430x932 → compact 62.33x36.67, minimal 36.67–45x36.67, expanded/Lock Screen 408x84–160; màn 393x852 → compact 52.33x36.67, expanded/Lock Screen 371x84–160. macOS dùng số của iOS.
- macOS: Live Activity từ iPhone tự hiện trên menu bar Mac đã ghép (click → iPhone Mirroring). [dev] ActivityKit chỉ iOS/iPadOS 16.1+ (và Mac Catalyst) → app Mac native không tạo được.
- [Đề xuất HandLive] Có thể dùng trên iOS cho "Cuộc gọi đang diễn ra trên điện thoại" (tên, thời lượng; không control) — cần quyết định (§14).

---

## 8. Patterns
Nguồn: https://developer.apple.com/design/human-interface-guidelines/patterns

### 8.1 Onboarding
Nguồn: https://developer.apple.com/design/human-interface-guidelines/onboarding

Xem §1(g). [Đề xuất HandLive] Onboarding Mac/iOS (SET-03): chào mừng + quyền riêng tư ngắn → quyền thiết yếu (mạng cục bộ; thông báo với iOS) → ghép QR (tương tác thật = dạy bằng làm) → xong. Bluetooth/camera/micro chỉ xin khi bật tính năng (đúng HIG). Tip ngữ cảnh (TipKit, iOS 17/macOS 14) thay vì tutorial.

### 8.2 Launching
Nguồn: https://developer.apple.com/design/human-interface-guidelines/launching

- Launch tức thì; iOS/iPadOS có launch screen gần giống màn đầu, không text, không logo/quảng cáo; macOS không cần launch screen; splash (nếu có) đặt ở đầu onboarding; khôi phục trạng thái trước (cửa sổ, vị trí cuộn).
- iOS: launch theo hướng hiện tại của thiết bị.

### 8.3 Settings
Nguồn: https://developer.apple.com/design/human-interface-guidelines/settings

Xem §1(d). Bổ sung iOS:
- Settings chung ít đổi đặt trong app; option theo task đặt tại màn hình liên quan; chỉ đưa option **ít đổi nhất** vào app Settings hệ thống, có nút mở thẳng Settings hệ thống.
- iPadOS menu bar: *AppName* > Settings mở trang app trong Settings hệ thống (§3.1).
- [HIG Writing] Nhãn setting rõ, thực tế; mô tả khi bật (người dùng tự suy ra khi tắt).
- [Đề xuất HandLive Mac] Pane: "Chung", "Thiết bị", "Clipboard", "Tin nhắn", "Cuộc gọi", "Camera" (6 pane); title cửa sổ đổi theo pane; nhớ pane cuối; setting "Hiện HandLive trên thanh menu" để tôn trọng quy tắc menu bar extra.

### 8.4 Privacy — Requesting permission
Nguồn: https://developer.apple.com/design/human-interface-guidelines/privacy

Xem §1(f). Bổ sung:
- Chỉ xin dữ liệu thật cần; minh bạch cách dùng; xử lý trên thiết bị khi được; dùng bảo vệ hệ thống.
- Bảo vệ dữ liệu: tránh chỉ dựa vào password (passkeys, 2FA, Face ID/Touch ID qua `Local Authentication`); dữ liệu nhạy cảm → **Keychain**; không lưu mật khẩu/nội dung bảo mật dạng plain text; không tự chế cơ chế xác thực.
- macOS: ký **Developer ID** khi phân phối ngoài store; sandbox (bắt buộc với Mac App Store); không giả định ai đang đăng nhập (fast user switching).
- Location button (iOS) không liên quan HandLive.
- [Đề xuất HandLive] Purpose string mẫu (câu chủ động, có dấu chấm): mạng cục bộ (đã có trong SET-03); Bluetooth Mac: "HandLive kết nối Bluetooth với điện thoại của bạn để nghe và nói cuộc gọi trên Mac."; camera iOS: "HandLive dùng camera để quét mã QR ghép nối với điện thoại của bạn."; micro Mac (nếu cần cho AUDIO-02): "HandLive dùng micro để bạn nói trong cuộc gọi chuyển từ điện thoại."

### 8.5 Feedback
Nguồn: https://developer.apple.com/design/human-interface-guidelines/feedback

- Feedback đa kênh (màu, text, âm thanh, haptic) cho accessible; status tích hợp gần đối tượng (vd số chưa đọc trong toolbar); alert chỉ cho thông tin critical, có hành động; cảnh báo khi mất dữ liệu **không mong đợi và không đảo ngược** (không cảnh báo khi xoá là mục đích); xác nhận hoàn tất chỉ với việc đủ quan trọng; khi lệnh không thực hiện được → nói rõ lý do.
- [Đề xuất HandLive] Gửi clipboard thành công: feedback nhẹ (checkmark/animation symbol trong menu extra), không notification; thất bại: nói lý do + cách xử lý.

### 8.6 Loading
Nguồn: https://developer.apple.com/design/human-interface-guidelines/loading

- Hiện gì đó ngay (placeholder); cho làm việc khác khi đang tải; tải lâu → nội dung phụ (tips); nói rõ đang tải và mất bao lâu (progress indicator §5.9).
- [Đề xuất HandLive] Messages mở khi chưa đồng bộ: hiện dữ liệu cache (SQLCipher) + trạng thái đồng bộ nhỏ, không chặn toàn màn.

### 8.7 Entering data
Nguồn: https://developer.apple.com/design/human-interface-guidelines/entering-data

- Lấy từ hệ thống thay vì bắt nhập; nói rõ dữ liệu cần; secure field; **không điền sẵn password**; ưu tiên chọn thay gõ; cho **kéo-thả và dán**; validate động; nút Next/Continue chỉ bật khi đủ dữ liệu bắt buộc. macOS: expansion tooltip.
- [Đề xuất HandLive] PIN fallback 6 số: field số, validate ngay, nút "Ghép" chỉ bật khi đủ 6 số.

### 8.8 Offering help (tooltip, TipKit)
Nguồn: https://developer.apple.com/design/human-interface-guidelines/offering-help

- Help gắn đúng task hiện tại, dễ bỏ qua; không giải thích component chuẩn.
- Tip (TipKit): cho tính năng đơn giản (≤ 3 thao tác), 1–2 câu, hành động; quy tắc đối tượng; tần suất hợp lý (vd 1 lần/24 giờ); popover tip vs inline tip; có thể có nút dẫn tới settings.
- Tooltip macOS (`help(_:)`): chỉ mô tả control đang trỏ; bắt đầu bằng động từ; không lặp tên control; **60–75 ký tự** tối đa; sentence case; có thể đổi theo trạng thái.
- [Đề xuất HandLive] Nút icon-only trong panel cuộc gọi (Mute, Hold, Keypad) bắt buộc có tooltip + accessibility label.

### 8.9 Edit menus · Activity views (clipboard, share)
Nguồn: https://developer.apple.com/design/human-interface-guidelines/edit-menus · https://developer.apple.com/design/human-interface-guidelines/activity-views

- Edit menu: dùng menu hệ thống; hiện lệnh hợp ngữ cảnh (không Paste khi không có gì để dán); lệnh custom cạnh lệnh hệ thống; cho copy text tĩnh hữu ích (không copy nhãn control); hỗ trợ undo/redo; không làm control trùng chức năng edit menu.
- Standard icons [HIG Icons]: Copy `document.on.document`, Paste `document.on.clipboard`, Share `square.and.arrow.up`, Delete `trash`, Cancel/Close `xmark`, Done `checkmark`, Compose `square.and.pencil`, Search `magnifyingglass`, More `ellipsis`, Account `person.crop.circle`.
- Share sheet/extension (iOS): không nhân bản action hệ thống; icon custom trong vùng ~**70x70 px**; tiêu đề action ngắn, động từ, không tên công ty; share extension ít bước (lý tưởng 1 chạm); không modal chồng lên extension; tác vụ dài tiếp tục nền, trạng thái xem trong app; **không notify chỉ vì task xong**.
- [dev] iOS 16+: đọc pasteboard bằng code sẽ bật alert xin phép; `UIPasteControl`/`PasteButton` (iOS 16) dán không bị hỏi. HIG không có trang riêng cho paste button.
- [Đề xuất HandLive iOS] Nút "Dán & gửi" = `PasteButton`; share extension "Gửi tới điện thoại" (text/ảnh).

### 8.10 Playing audio (call audio Mac)
Nguồn: https://developer.apple.com/design/human-interface-guidelines/playing-audio

- Âm lượng hệ thống luôn quyết định cuối; cho đổi route (thiết bị ra) khi được; chọn audio category hợp (Play and record cho gọi thoại — iOS `AVAudioSession`); phản hồi audio control chỉ khi hợp ngữ cảnh; không định nghĩa lại audio control; xử lý interruption (vd VoIP không tự bật lại micro khi mở lại Smart Folio — riêng tư).
- macOS: âm thanh notification trộn với audio khác mặc định.
- [Đề xuất HandLive] Chuông trên Mac: tắt khi Focus (đã có E4), không tự bật lại micro sau interruption khi chưa có hành động người dùng.

### 8.11 Trang bỏ qua
Nguồn: https://developer.apple.com/design/human-interface-guidelines/going-full-screen · https://developer.apple.com/design/human-interface-guidelines/playing-video

- Going full screen: không liên quan (HandLive không có trải nghiệm full-screen); chỉ ghi nhận: app hỗ trợ full screen thì View menu có Enter/Exit Full Screen.
- Playing video: không liên quan (camera ảo là thiết bị nguồn cho app khác, không phải player). HIG **không có** trang cho virtual camera/CMIOExtension/system extension → không có hướng dẫn HIG cho CAM-01.
- accessing-private-data: 404.

---

## 9. Quy ước nền tảng
Nguồn: https://developer.apple.com/design/human-interface-guidelines/getting-started

### 9.1 Designing for macOS
Nguồn: https://developer.apple.com/design/human-interface-guidelines/designing-for-macos

- Màn lớn → nhiều nội dung, ít tầng lồng, **ít modal**; cho resize/ẩn/hiện/di chuyển cửa sổ, hỗ trợ full screen; **menu bar chứa mọi lệnh**; tận dụng input chính xác; phím tắt cho người dùng bàn phím; cho cá nhân hoá (toolbar, cửa sổ, màu, font).
- Phím tắt chuẩn [HIG Keyboards]: ⌘, (Settings), ⌘Q, ⌘W, ⌘H, ⌘M, ⌘N, ⌘F, ⌥⌘F (nhảy tới search field), Esc (huỷ), ⌘. (huỷ thao tác), ⌘? (Help menu).
- Layout macOS [HIG Layout]: không đặt control/thông tin quan trọng ở đáy cửa sổ; tránh vùng camera housing ở mép trên.

### 9.2 Designing for iOS / iPadOS
Nguồn: https://developer.apple.com/design/human-interface-guidelines/designing-for-ios · https://developer.apple.com/design/human-interface-guidelines/designing-for-ipados

- iOS: ít control trên màn, chi tiết phụ dễ khám phá; thích ứng orientation, Dark Mode, Dynamic Type; control quan trọng ở giữa/đáy (dễ với), vuốt để back/hành động trên row; dùng dữ liệu hệ thống (có phép) thay vì bắt nhập.
- iPadOS: ít modal và chuyển full-screen; kích thước theo khoảng cách nhìn + input; hỗ trợ touch/keyboard/trackpad/Pencil; thích ứng multitasking, windowed mode (HIG Windows 2025-06-09: cửa sổ resize tự do, window controls ở leading toolbar — dời button khỏi mép leading để không bị che).
- Layout [HIG Layout 2026-09-09]: quyết định theo **size class**, không theo loại thiết bị/hướng; giữ chức năng như nhau khi đổi size class; tôn trọng safe area; test bằng Device Hub (Xcode).

### 9.3 Designing for iPhone Duo (mới 2026-09-09)
Nguồn: https://developer.apple.com/design/human-interface-guidelines/designing-for-iphone-duo

- iPhone gập 2 màn (ngoài: rộng-thấp; trong: lớn); dùng component hệ thống + app resize được là tự thích ứng; vẫn là iPhone (quy tắc iOS áp dụng).
- Size class: compact width (màn ngoài), regular width (màn trong); không làm layout riêng cho từng tư thế; không fixed width.
- Nhất quán giữa 2 màn; màn trong có thể hiện thêm một cấp (vd Mail list + email cạnh nhau) → [Đề xuất] SMS: màn ngoài một cột, màn trong list + hội thoại (`NavigationSplitView`).
- **Toolbar/tab bar chuyển sang cạnh dọc** trên màn ngoài (và màn trong khi ngang): giữ thứ tự (Back/Close trên cùng, rồi prominent như Done); ưu tiên item hay dùng (`ToolbarItemVisibilityPriority`); mỗi toolbar item có **cả title và symbol**; hạn chế nút chỉ text; dùng overflow menu hệ thống (`ToolbarOverflowMenu`), dấu … chỉ cho overflow; nhóm bằng `ToolbarItemGroup` thay spacing tay; khi hẹp: app điều hướng → dồn toolbar vào overflow, app task → thu nhỏ tab bar (`ToolbarVerticalCompressionBehavior`).
- Reserved regions (camera ngoài, camera trong khi bật, vùng gập): alert/context menu/sheet tự tránh; custom dùng `ReservedRegion`; grid số cột chẵn; tránh đổi layout mạnh khi gập. Arrangement view (split/overlay): `ArrangementView`, `UIArrangementViewController`; không đặt navigation bên trong arrangement view.
- [dev] Availability: `ReservedRegion`, `ArrangementView`, `ToolbarVerticalCompressionBehavior` iOS **27.1 (beta)**; `ToolbarItemVisibilityPriority`, `ToolbarOverflowMenu` iOS 27.0.

---

## 10. Bảng số liệu tổng hợp

Nguồn: các trang ghi ở cột "Trang" (URL gốc `https://developer.apple.com/design/human-interface-guidelines/<slug>`)

| Thông số | Giá trị | Trang |
|---|---|---|
| Chiều cao menu bar macOS | 24 pt | the-menu-bar |
| Tên app trong About | ≤ 16 ký tự, không số phiên bản | the-menu-bar |
| Vùng bấm button | ≥ 44x44 pt (visionOS 60x60) | buttons |
| Control size mặc định / tối thiểu | iOS 44x44 / 28x28 pt; macOS 28x28 / 20x20 pt | accessibility |
| Padding quanh control | ~12 pt (có bezel), ~24 pt (không bezel) | accessibility |
| Cỡ chữ mặc định / tối thiểu | iOS 17 / 11 pt; macOS 13 / 10 pt | accessibility |
| Tương phản tối thiểu | ≤ 17 pt: 4.5:1; 18 pt: 3:1; chữ đậm: 3:1 | accessibility |
| Prominent button / view | 1–2 | buttons |
| Padding image button (macOS) | ~10 px | buttons |
| Nút trong alert | ≤ 3; title ≤ 2 dòng | alerts |
| Nút action trong notification | ≤ 4 | notifications |
| Time Sensitive | sự kiện đang diễn ra hoặc ≤ 1 giờ | managing-notifications |
| Segmented | ≤ ~5–7 (rộng), ≤ ~5 (iPhone) | segmented-controls |
| Radio group | 2–5; > ~5 → pop-up | toggles |
| Pull-down | ≥ 3 mục | pull-down-buttons |
| Submenu | 1 cấp; > ~5 mục → menu mới | menus |
| Context menu | ≤ ~3 nhóm | context-menus |
| Tab view (macOS) | ≤ 6 tab | tab-views |
| Tab bar iPad tuỳ biến | mặc định ≤ 5 tab | tab-bars |
| Toolbar | title < 15 ký tự; ≤ 3 nhóm; 1 primary action | toolbars |
| Sidebar | ≤ 2 cấp phân cấp | sidebars |
| Split view divider thin | 1 pt | split-views |
| Sheet detent | large = full, medium ≈ nửa | sheets |
| Tooltip | ≤ 60–75 ký tự | offering-help |
| Tip (TipKit) | tính năng ≤ 3 thao tác; 1–2 câu; vd 1 lần/24 giờ | offering-help |
| Icon activity custom | vùng ~70x70 px | activity-views |
| Clear Liquid Glass trên nền sáng | lớp dim 35% opacity | materials |
| Live Activity | ≤ 8 giờ; còn ≤ 4 giờ sau khi kết thúc; dismissal 15–30 phút; animation ≤ 2 s; lề Lock Screen 14 pt; Dynamic Island góc 44 pt | live-activities |
| Date picker phút | bước chia hết 60 | pickers |

---

## 11. Ánh xạ HandLive & điểm lệch so với detailed design hiện tại

Nguồn: https://developer.apple.com/design/human-interface-guidelines/privacy#Pre-alert-screens-windows-or-views · https://developer.apple.com/design/human-interface-guidelines/panels · https://developer.apple.com/design/human-interface-guidelines/the-menu-bar#Menu-bar-extras · https://developer.apple.com/documentation/appkit/nsapplication/activationpolicy-swift.enum/accessory · `docs/detailed-design/01-setup-settings.md`, `06-call-control.md`, `07-call-audio.md`

| # | Màn/đặc tả HandLive | HIG liên quan | Đánh giá |
|---|---|---|---|
| 1 | SET-03 trường 14: mỗi màn quyền có "Tiếp tục" + "Bỏ qua" | Pre-alert: đúng 1 nút ("Continue"/"Next"), không có nút đóng/huỷ trừ legal consent | **Lệch**: bỏ "Bỏ qua" ở màn giải thích quyền; người dùng từ chối trong alert hệ thống. "Bỏ qua" chỉ giữ cho bước không phải quyền |
| 2 | CALL-01: `NSPanel` nổi trên mọi Space, non-activating, hiện cả khi app không active | Panel: ẩn khi app inactive, là bổ trợ cho cửa sổ active | **Lệch có chủ đích**: ghi rõ ngoại lệ trong design system; giữ panel chuẩn, nhỏ, có title, không minimize, không vào Window menu |
| 3 | CALL-01 E4: Focus bật → panel vẫn hiện, chỉ tắt chuông | Managing notifications: tôn trọng Focus; communication notification để hệ thống lọc theo người gọi | Cần quyết định (§14) |
| 4 | Mac `LSUIElement = YES`, có Messages window + Settings | [dev] `.accessory`: không Dock, **không có menu bar**; HIG macOS: menu bar chứa mọi lệnh, Window/Edit menu, toolbar item phải có trong menu bar | **Rủi ro**: Messages window thiếu menu bar (Edit, Window, phím tắt) → cân nhắc chuyển activation policy sang regular khi mở cửa sổ chính (pattern phổ biến, CHƯA XÁC MINH trong HIG) |
| 5 | Menu bar extra luôn hiện | HIG: người dùng quyết định hiện extra; [dev] app chỉ-extra bị terminate khi gỡ extra | Thêm setting "Hiện trên thanh menu" (`isInserted`) + đường vào lại (mở app → hiện Settings) |
| 6 | iOS: notification cuộc gọi `time-sensitive` + action "Từ chối", không PushKit/CallKit | Time Sensitive hợp (sự kiện đang xảy ra); communication notification (`INStartCallIntent`) còn cho avatar + Focus theo người gọi; [dev] không dùng được PushKit nếu không dùng CallKit | Phù hợp; cân nhắc thêm communication notification |
| 7 | AUDIO-01: bản công bố với "Đồng ý" / "Huỷ", rồi mới xin Bluetooth | Legal consent được phép có nhiều nút; xin quyền đúng lúc dùng tính năng | Phù hợp; "Đồng ý" là default (không destructive), "Huỷ" là cancel |
| 8 | CALL-01 Mac: 4 nút "Trả lời", "Từ chối", "Từ chối kèm tin nhắn", "Bỏ qua" | 1–2 prominent/view; dấu … khi cần thêm input; pull-down ≥ 3 mục | "Trả lời" prominent; "Từ chối kèm tin nhắn…" có dấu …, có thể thành pull-down mẫu tin; "Bỏ qua" style thường |
| 9 | Camera: quality picker, toggles | Pop-up cho lựa chọn loại trừ, default hữu ích; switch cho feature chính | "Tự động" làm default; disclosure cho tuỳ chọn nâng cao |
| 10 | iOS clipboard | [dev] đọc pasteboard bằng code → alert hỏi (iOS 16+) | Dùng `PasteButton`/`UIPasteControl` cho thao tác dán chủ động |
| 11 | Empty state (chưa ghép, chưa có SMS) | [HIG Writing] màn trống có bước tiếp theo rõ + nút | Mỗi empty state có nút hành động ("Ghép điện thoại…") |
| 12 | Mất kết nối | Alerts: không alert thuần thông tin, không alert lúc mở app | Indicator trong menu extra/cửa sổ; không alert/notification lặp |

---

## 12. API & mức OS tối thiểu (đối chiếu macOS 13 / iOS 16)

Nguồn: https://developer.apple.com/documentation (DocC JSON từng symbol, tra 2026-09-24)

| API | Availability [dev] | Với min target HandLive |
|---|---|---|
| `MenuBarExtra`, `.menuBarExtraStyle(.menu/.window)`, `init(_:systemImage:isInserted:content:)` | macOS 13.0 | OK |
| `MenuBarExtra.init(_:image:isInserted:content:)` | macOS 14.0 | Cần `if #available` nếu dùng icon custom |
| `Settings` scene | macOS 11.0 | OK |
| `SettingsLink`, `OpenSettingsAction` | macOS 14.0 | Thiếu trên macOS 13 |
| `NavigationSplitView`, `Form` + `.formStyle(.grouped)`, `LabeledContent`, `searchable(text:placement:prompt:)`, `confirmationDialog` | iOS 16 / macOS 13 | OK |
| `Toggle` `.switch`/`.checkbox`, `Picker` `.radioGroup`/`.segmented`/`.menu`, `GroupBox`, `DisclosureGroup`, `help(_:)` | ≤ iOS 14 / macOS 11 | OK |
| `ControlSize.extraLarge` | iOS 17 / macOS 14 | Thiếu ở min target |
| `ContentUnavailableView`, `inspector(isPresented:content:)`, TipKit | iOS 17 / macOS 14 | Thiếu → tự dựng empty state/tip |
| `Tab`, `sidebarAdaptable` | iOS 18 / macOS 15 | Thiếu |
| `ControlWidget` | iOS 18 / macOS 26 | Progressive enhancement |
| `.glass`, `.glassProminent`, `Glass`, `glassEffect(_:in:)`, `GlassEffectContainer`, `ConcentricRectangle`, `backgroundExtensionEffect()`, `ScrollEdgeEffectStyle`, `scrollEdgeEffectStyle(_:for:)`, `TabBarMinimizeBehavior`, `ToolbarSpacer`, `ButtonRole.confirm`/`.close` | iOS 26 / macOS 26 (`tabViewBottomAccessory` chỉ iOS) | `if #available(…26…)` |
| `NSButton.BezelStyle.glass`, `NSGlassEffectView` | macOS 26.0 | idem |
| `NSScrollEdgeEffectStyle` | macOS 26.1 | idem |
| `UIBarButtonItem.Style.prominent` | iOS 26.0 | idem |
| `UIDesignRequiresCompatibility` | iOS/macOS 26; bị bỏ qua khi build cho 27+ | Không dựa vào để né Liquid Glass |
| `PasteButton`, `UIPasteControl`, `DataScannerViewController` | iOS 16 | OK |
| `UNNotificationInterruptionLevel`, `UNNotificationActionIcon`, `UNNotificationContent.updating(from:)`, `UNNotificationContentProviding` | iOS 15 / macOS 12 | OK |
| `UNTextInputNotificationAction`, `UNNotificationAction` options | iOS 10 / macOS 10.14 | OK |
| `INSendMessageIntent`, `INStartCallIntent` (conform `UNNotificationContentProviding`) | macOS 12 / iOS 10–13 | OK |
| `UNNotificationSettings.alertStyle` | iOS 10 / macOS 10.14 | OK (đọc kiểu Banner/Alert) |
| ActivityKit | iOS 16.1 (không có macOS) | iOS only |
| `SMAppService` | macOS 13.0 | OK |
| `NSStatusItem` `.removalAllowed`/`isVisible` | macOS 10.12 | OK |
| iPhone Duo: `ReservedRegion`, `ArrangementView`, `ToolbarVerticalCompressionBehavior` | iOS 27.1 (beta) | Tương lai |
| `ToolbarItemVisibilityPriority` | iOS 27.0 (docs ghi macOS 26.1) | Tương lai |
| `ToolbarOverflowMenu` | iOS 27.0 | Tương lai |

---

## 13. CHƯA XÁC MINH

Nguồn: tổng hợp từ các mục trên

1. Kích thước glyph icon menu bar extra (pt): HIG chỉ ghi menu bar cao 24 pt.
2. `MenuBarExtraStyle.automatic` resolve thành menu hay window (docs không nói).
3. Chiều cao pt của push button macOS theo từng `ControlSize`; bán kính góc cụ thể của control/sheet/window thời Liquid Glass (HIG không ghi số; xem macOS 27 / iOS 27 UI Kit).
4. Quy ước "Settings không có nút Apply, thay đổi có hiệu lực ngay": không có trong HIG hiện hành.
5. Vị trí hàng nút đáy phải trong sheet macOS: HIG chỉ nói nút dismiss nằm trong main content view + default ở trailing (của alert).
6. Cách mở Settings chính thống trên macOS 13 khi không có `SettingsLink`/`OpenSettingsAction`.
7. Khoá Info.plist `NSUserNotificationAlertStyle` có đặt mặc định kiểu "Alerts" cho `UNUserNotificationCenter` trên macOS 13+ không (không tìm thấy trang docs).
8. Tên entitlement chính xác: Time Sensitive (`com.apple.developer.usernotifications.time-sensitive`, đang dùng trong SET-03/CALL-01) và Communication Notifications — không tìm thấy trang docs entitlement qua DocC JSON (bài "Implementing communication notifications" chỉ nói "capability").
9. Phím tắt Edit (⌘C/⌘V…) trong app `.accessory`/`LSUIElement` khi không có menu bar hiển thị.
10. SwiftUI có token field cho macOS 13 hay phải bọc `NSTokenField`.
11. Control (ControlWidget) có đặt được lên menu bar macOS 26/27 không; HIG chỉ nêu Control Center/Lock Screen/Action button.
12. Ánh xạ SwiftUI của `.prominent` trong toolbar (HIG ghi `.prominent`; UIKit có `UIBarButtonItem.Style.prominent`; SwiftUI có thể là `.buttonStyle(.glassProminent)`).
13. Kích thước icon tab bar tự vẽ (HIG trỏ sang Apple Design Resources).

---

## 14. Câu hỏi mở

Nguồn: `CLAUDE.md`, `docs/design-guidelines.md`, `docs/detailed-design/*` đối chiếu với HIG

1. Focus trên Mac: panel cuộc gọi vẫn hiện khi Focus bật (CALL-01 E4) — giữ, hay chuyển kênh chính sang communication notification (`INStartCallIntent`) để hệ thống lọc theo người gọi được phép?
2. `LSUIElement = YES` nhưng có Messages window cần menu bar: chuyển activation policy động (regular khi có cửa sổ chính) hay chấp nhận thiếu menu bar?
3. Bỏ nút "Bỏ qua" trên màn giải thích quyền (SET-03 trường 14) để khớp quy tắc pre-alert của HIG?
4. `CLAUDE.md` còn ghi iOS dùng "APNs/PushKit"; detailed design đã chốt "không PushKit/CallKit" (khớp dev docs: PushKit bắt buộc CallKit) — cập nhật `CLAUDE.md`?
5. AUDIO-02 dùng micro Mac (AUVoiceProcessingIO) nhưng detailed design chưa thấy `NSMicrophoneUsageDescription` và bước xin quyền micro — cần bổ sung?
6. iOS có dùng Live Activity cho "cuộc gọi đang diễn ra trên điện thoại" không (HIG phù hợp: có đầu/cuối, ≤ 8 giờ; ActivityKit iOS 16.1+)?
7. Nâng min OS (macOS 14 / iOS 17 cho `SettingsLink`, TipKit, `ContentUnavailableView`; 26 cho Liquid Glass API) hay giữ macOS 13 / iOS 16 + fallback?
8. Hỗ trợ iPhone Duo ngay (API 27.1 đang beta) hay chỉ dựa vào size class + component chuẩn?
9. Có thêm Control (Control Center/Action button) "Gửi clipboard" trên iOS 18+/macOS 26+ không?
