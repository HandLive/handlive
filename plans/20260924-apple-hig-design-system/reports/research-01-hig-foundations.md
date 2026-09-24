# Research 01 — Apple HIG Foundations (trạng thái 24/09/2026)

**Phạm vi:** dữ kiện chính xác từ Apple Human Interface Guidelines (HIG) để dựng lại design system HandLive (app menu bar macOS, app iOS/iPadOS, app Android đi kèm) "theo chuẩn của Apple". Trọng tâm: Foundations + các trang thành phần cần cho số liệu macOS/iOS.

**Phương pháp:** trang HIG là JS app → đọc DocC render JSON `https://developer.apple.com/tutorials/data/design/human-interface-guidelines/<slug>.json` (nội dung `primaryContentSections`, bảng, change log). Trang HTML (What's new, Resources, Fonts, SF Symbols, Icon Composer) đọc bằng curl. Tài liệu developer (`/tutorials/data/documentation/...json`) chỉ dùng để xác nhận tên API và phiên bản OS. Giá trị màu = alt text của swatch trên trang Color; mã hex và tỉ lệ tương phản do tự tính, Apple không công bố.

**Quy ước:** `CHƯA XÁC MINH` = không có trên nguồn chính thức hiện tại, hoặc chỉ có nguồn thứ cấp. Mọi đoạn đều là diễn giải, không trích nguyên văn.

---

## 0. Tóm tắt nhanh

Nguồn: tổng hợp các mục bên dưới.

- Ngôn ngữ thiết kế hiện hành vẫn là **Liquid Glass** (ra mắt 9/6/2025). WWDC26 (8/6/2026) chỉ tinh chỉnh: trang Design principles được đưa trở lại, Icon Composer 2, SF Symbols bản mới, màu icon sidebar, scroll edge effect, icon cho menu item. Chưa thấy ngôn ngữ thiết kế nào thay Liquid Glass.
- Mốc mới nhất: 9/9/2026 có trang mới **Designing for iPhone Duo** (iPhone gập, 2 màn hình). Trang Layout được "cập nhật theo best practice": **bảng thông số thiết bị và margin đã bị gỡ khỏi trang**. Trang Branding tinh chỉnh cách dùng brand color. Ngày 17–18/9/2026 ra UI Kit iOS/iPadOS 27 và macOS 27 cho Figma, cùng bezel cho iPhone Duo và iPhone 18.
- Bảng system colors là **một bảng chung cho mọi nền tảng**, có 4 biến thể (Default light/dark, Increased contrast light/dark). Theo change log, giá trị màu đổi ngày 9/6/2025.
- Liquid Glass là **lớp chức năng** (control, navigation) nổi trên lớp nội dung. **Không dùng Liquid Glass trong content layer.** Có 2 variant `regular` và `clear`. Chỉ tô màu cho primary action hoặc chỉ báo trạng thái.
- Cỡ chữ mặc định/tối thiểu: iOS 17/11 pt, macOS 13/10 pt. macOS không có Dynamic Type. Emphasized weight được thêm vào bảng ngày 16/12/2025.
- Kích thước control: iOS 44x44 pt (tối thiểu 28x28), macOS 28x28 pt (tối thiểu 20x20). Tương phản: chữ ≤17 pt cần 4.5:1; chữ 18 pt hoặc chữ đậm cần 3:1.
- App icon: làm bằng Icon Composer, nhiều lớp, 1024x1024 px (iOS/iPadOS/macOS), có 6 appearance.
- **Giấy phép:** SF Pro, SF Symbols và Apple Design Resources chỉ dùng cho giao diện chạy trên hệ điều hành của Apple → **app Android của HandLive không được dùng**.
- API Liquid Glass (`glassEffect`, `ConcentricRectangle`, `backgroundExtensionEffect`, `NSGlassEffectView`) chỉ có **từ iOS/macOS 26**. HandLive hỗ trợ macOS 13+ và iOS 16+ nên cần phương án dự phòng.

---

## 1. Cấu trúc HIG

Nguồn: https://developer.apple.com/design/human-interface-guidelines/ (+ `/getting-started`, `/foundations`, `/patterns`, `/components`, `/inputs`, `/technologies`)

Trang chủ HIG có 3 khối:
- **Design fundamentals:** design-principles, designing-for-iphone-duo, designing-for-ios.
- **Foundations of design:** accessibility, app-icons, color, layout, materials, typography.
- **New and updated:** designing-for-iphone-duo, apple-in-app-purchase, layout, branding, shareplay, siri.

Ngôn ngữ hỗ trợ: en-US, zh-CN, ja-JP, ko-KR.

| Section | Số trang | Trang — `slug` |
|---|---|---|
| Getting started | 9 | Design principles `design-principles`, Designing for iOS `designing-for-ios`, Designing for iPadOS `designing-for-ipados`, Designing for macOS `designing-for-macos`, Designing for tvOS `designing-for-tvos`, Designing for visionOS `designing-for-visionos`, Designing for watchOS `designing-for-watchos`, Designing for games `designing-for-games`, Designing for iPhone Duo `designing-for-iphone-duo` |
| Foundations | 18 | Accessibility `accessibility`, App icons `app-icons`, Branding `branding`, Color `color`, Dark Mode `dark-mode`, Icons `icons`, Images `images`, Immersive experiences `immersive-experiences`, Inclusion `inclusion`, Layout `layout`, Materials `materials`, Motion `motion`, Privacy `privacy`, Right to left `right-to-left`, SF Symbols `sf-symbols`, Spatial layout `spatial-layout`, Typography `typography`, Writing `writing` |
| Patterns | 25 | Charting data `charting-data`, Collaboration and sharing `collaboration-and-sharing`, Drag and drop `drag-and-drop`, Entering data `entering-data`, Feedback `feedback`, File management `file-management`, Going full screen `going-full-screen`, Launching `launching`, Live-viewing apps `live-viewing-apps`, Loading `loading`, Managing accounts `managing-accounts`, Managing notifications `managing-notifications`, Modality `modality`, Multitasking `multitasking`, Offering help `offering-help`, Onboarding `onboarding`, Playing audio `playing-audio`, Playing haptics `playing-haptics`, Playing video `playing-video`, Printing `printing`, Ratings and reviews `ratings-and-reviews`, Searching `searching`, Settings `settings`, Undo and redo `undo-and-redo`, Workouts `workouts` |
| Components › Content | 4 | Charts `charts`, Image views `image-views`, Text views `text-views`, Web views `web-views` |
| Components › Layout and organization | 10 | Boxes `boxes`, Collections `collections`, Column views `column-views`, Disclosure controls `disclosure-controls`, Labels `labels`, Lists and tables `lists-and-tables`, Lockups `lockups`, Outline views `outline-views`, Split views `split-views`, Tab views `tab-views` |
| Components › Menus and actions | 12 | Activity views `activity-views`, Buttons `buttons`, Context menus `context-menus`, Dock menus `dock-menus`, Edit menus `edit-menus`, Home Screen quick actions `home-screen-quick-actions`, Menus `menus`, Ornaments `ornaments`, Pop-up buttons `pop-up-buttons`, Pull-down buttons `pull-down-buttons`, The menu bar `the-menu-bar`, Toolbars `toolbars` |
| Components › Navigation and search | 5 | Path controls `path-controls`, Search fields `search-fields`, Sidebars `sidebars`, Tab bars `tab-bars`, Token fields `token-fields` |
| Components › Presentation | 8 | Action sheets `action-sheets`, Alerts `alerts`, Page controls `page-controls`, Panels `panels`, Popovers `popovers`, Scroll views `scroll-views`, Sheets `sheets`, Windows `windows` |
| Components › Selection and input | 11 | Color wells `color-wells`, Combo boxes `combo-boxes`, Digit entry views `digit-entry-views`, Image wells `image-wells`, Pickers `pickers`, Segmented controls `segmented-controls`, Sliders `sliders`, Steppers `steppers`, Text fields `text-fields`, Toggles `toggles`, Virtual keyboards `virtual-keyboards` |
| Components › Status | 4 | Activity rings `activity-rings`, Gauges `gauges`, Progress indicators `progress-indicators`, Rating indicators `rating-indicators` |
| Components › System experiences | 10 | App Shortcuts `app-shortcuts`, Complications `complications`, Controls `controls`, Live Activities `live-activities`, Notifications `notifications`, Snippets `snippets`, Status bars `status-bars`, Top Shelf `top-shelf`, Watch faces `watch-faces`, Widgets `widgets` |
| Inputs | 13 | Action button `action-button`, Apple Pencil and Scribble `apple-pencil-and-scribble`, Camera Control `camera-control`, Digital Crown `digital-crown`, Eyes `eyes`, Focus and selection `focus-and-selection`, Game controls `game-controls`, Gestures `gestures`, Gyroscope and accelerometer `gyro-and-accelerometer`, Keyboards `keyboards`, Nearby interactions `nearby-interactions`, Pointing devices `pointing-devices`, Remotes `remotes` |
| Technologies | 29 | AirPlay `airplay`, Always On `always-on`, App Clips `app-clips`, Apple In-App Purchase `apple-in-app-purchase`, Apple Pay `apple-pay`, Augmented reality `augmented-reality`, CareKit `carekit`, CarPlay `carplay`, Game Center `game-center`, Generative AI `generative-ai`, HealthKit `healthkit`, HomeKit `homekit`, iCloud `icloud`, ID Verifier `id-verifier`, iMessage apps and stickers `imessage-apps-and-stickers`, Live Photos `live-photos`, Mac Catalyst `mac-catalyst`, Machine learning `machine-learning`, Maps `maps`, NFC `nfc`, Photo editing `photo-editing`, ResearchKit `researchkit`, SharePlay `shareplay`, ShazamKit `shazamkit`, Sign in with Apple `sign-in-with-apple`, Siri `siri`, Tap to Pay on iPhone `tap-to-pay-on-iphone`, VoiceOver `voiceover`, Wallet `wallet` |

Ghi chú: Components có 8 nhóm, tổng 64 trang. Link `spatial-interactions` trên trang Designing for iOS trả về 404 (link hỏng).

---

## 2. What's new 2025–2026

Nguồn: https://developer.apple.com/design/whats-new/ (+ change log trên từng trang HIG)

| Ngày | Loại | Mục | Thay đổi (tóm tắt) |
|---|---|---|---|
| 18/9/2026 | Resources | Product bezels | Thêm bezel cho iPhone Duo và các mẫu iPhone 18 |
| 17/9/2026 | Resources | UI Kit iOS & iPadOS 27, macOS 27 (Figma) | Cập nhật component, system colors, app icons |
| 17/9/2026 | Guidance | Apple In-App Purchase | Đổi tên (rebrand), tinh chỉnh hướng dẫn |
| 9/9/2026 | Guidance + Video | **Designing for iPhone Duo** (trang mới) | Tư thế thiết bị, layout động trên 2 màn hình, toolbar/tab bar theo trục dọc. Kèm Tech Talk "Design for iPhone Duo" |
| 9/9/2026 | Guidance | Layout | Cập nhật theo best practice hiện hành (bảng Specifications không còn trên trang) |
| 9/9/2026 | Guidance | Branding | Tinh chỉnh cách dùng brand color |
| 9/9/2026 | Guidance | SharePlay | Sắp xếp lại, mở rộng phần visionOS, thêm custom templates |
| 23/6/2026 | Resources | UI Kit Figma iOS/iPadOS 27, macOS 27 | Bản cập nhật |
| 8/6/2026 (WWDC26) | Resources | Icon Composer 2 beta; SF Symbols 8 beta; Pass Designer; UI Kit Sketch iOS/iPadOS 27, macOS 27 | Công cụ mới |
| 8/6/2026 | Guidance | **Design principles** | Đưa trở lại bộ nguyên tắc thiết kế |
| 8/6/2026 | Guidance | Siri; **Snippets** (trang mới); App Shortcuts | Siri AI; app schemas |
| 8/6/2026 | Guidance | Menus; Sidebars; Scroll views; App icons | Icon cho menu item; màu icon sidebar và adaptable sidebar; scroll edge effect; tinh chỉnh Liquid Glass cho icon |
| 8/6/2026 | Guidance | Search fields; Searching; Tab bars | Đổi thuật ngữ; search dạng tab trên iOS; cập nhật hình minh hoạ |
| 8/6/2026 | Guidance | Generative AI; Machine learning; Apple Pay; Wallet | Cho người dùng tinh chỉnh kết quả, phản hồi khi đang sinh nội dung; Wallet theo iOS 27 và Pass Designer |
| 8/6/2026 | Video | Principles of great design (wwdc2026/250); Design intuitive search experiences (wwdc2026/292) | |
| 24/3/2026 | Guidance | Sheets; Scroll views | Vị trí nút trong sheet; Look to Scroll (visionOS) |
| 16/12/2025 | Guidance | Color, Buttons, Toolbars, Tab bars | Cập nhật hướng dẫn Liquid Glass |
| 16/12/2025 | Guidance | Typography; Writing | Thêm emphasized weight vào bảng Dynamic Type; language patterns, đại từ sở hữu |
| 16/12/2025 | Guidance | Widgets; Live Activities; Menus; Images; Apple Pay | Live Activities có thêm macOS và CarPlay; breakthrough effect (visionOS); spatial photos |
| 12/9/2025 | Resources | Product bezels | Dòng iPhone 17, Apple Watch Series 11, Ultra 3 |
| 9/9/2025 | Guidance | Materials; Motion; Layout | Cập nhật Liquid Glass; thông số iPhone 17/Air/17 Pro/17 Pro Max, Watch SE 3/S11/Ultra 3 |
| 20/8/2025 | Resources | Design kit Figma visionOS, watchOS | |
| 28/7/2025 | Guidance | Tab bars; Scroll views; Menus; SF Symbols | Liquid Glass; scroll edge effect; icon cho menu item; Draw animation và gradient (SF Symbols 7) |
| 9/6/2025 (WWDC25) | Resources | UI Kit Sketch iOS/iPadOS 26 và macOS 26 (dựng lại từ đầu, có Liquid Glass); Icon Composer; SF Symbols 7 beta (hơn 6,900 symbol) | |
| 9/6/2025 | Guidance | App icons; Materials; Color; Layout | Icon nhiều lớp; Liquid Glass; **giá trị system color mới** |
| 9/6/2025 | Guidance | Toolbars; Icons; Buttons; Search fields; Searching; Sidebars; Split views; The menu bar; Multitasking; Windows; Virtual keyboards | Gom nhóm bar item, gộp navigation bar vào Toolbars; bảng standard icons; menu bar trên iPadOS; cửa sổ resize được trên iPadOS |
| 9/6/2025 | Guidance | Accessibility; **Generative AI** (trang mới); Games; Game Center; Immersive; App Clips; iCloud; Loading; Going full screen | Assistive Access, Switch Control, Accessibility Nutrition Labels |
| 9/6/2025 | Video | Meet Liquid Glass (wwdc2025/219), Get to know the new design system (356), Say hello to the new look of app icons (220), Create icons with Icon Composer (361), Design foundations from idea to interface (359), Elevate the design of your iPad app (208) | |
| 7/3/2025 | Guidance | Accessibility; Typography; **VoiceOver** (trang mới); Layout | Viết lại Accessibility; Dynamic Type chuyển sang Typography; thông số iPhone 16e, iPad 11", iPad Air 11"/13" |
| 17/1/2025 | Guidance | Tap to Pay, Wallet, Widgets, App Shortcuts | |

Video WWDC26 được link từ các trang Foundations: Communicate your brand identity on iOS (wwdc2026/251), Craft clear names for features and labels in your app (wwdc2026/290), Refine accessibility for custom controls (wwdc2026/220), Meet Trust Insights (wwdc2026/379).

### 2.1 Trạng thái công cụ và tài nguyên (24/9/2026)

Nguồn: https://developer.apple.com/design/resources/ · https://developer.apple.com/sf-symbols/ · https://developer.apple.com/icon-composer/ · https://developer.apple.com/design/

| Tài nguyên | Trạng thái |
|---|---|
| UI Kit iOS 27 & iPadOS 27 | Figma, Sketch. Kèm App Icon Template (Figma, Sketch, Photoshop/Illustrator) |
| UI Kit macOS 27 | Figma, Sketch |
| watchOS 26, visionOS 26 | Figma, Sketch |
| tvOS 18 | Sketch |
| SF Symbols | Hơn 7,000 symbol, 9 weight, 3 scale, bản địa hoá cho hơn 20 hệ chữ; cần macOS Sonoma trở lên. Nút tải ghi "SF Symbols 27" (`SF-Symbols-27.dmg`), nhưng What's new ngày 8/6/2026 gọi là "SF Symbols 8 beta" → tên chính thức CHƯA XÁC MINH. Symbol mới dùng được trên iOS/iPadOS/macOS/watchOS/tvOS/visionOS 27 |
| Icon Composer (bản 2) | Trang sản phẩm ghi cần macOS Tahoe 26.4 trở lên; trang Resources ghi macOS Sequoia trở lên → mâu thuẫn |
| Fonts | SF Pro, SF Compact, SF Mono, New York, SF Arabic/Armenian/Georgian/Hebrew (file .dmg) |
| Khác | Pass Designer (beta), Reality Composer Pro (beta), Parallax Previewer, product bezels (iPhone Duo, iPhone 18, MacBook Neo, …) |

---

## 3. Design principles và đặc điểm nền tảng

Nguồn: https://developer.apple.com/design/human-interface-guidelines/design-principles · https://developer.apple.com/design/human-interface-guidelines/designing-for-macos · https://developer.apple.com/design/human-interface-guidelines/designing-for-ios · https://developer.apple.com/design/human-interface-guidelines/designing-for-ipados · https://developer.apple.com/design/human-interface-guidelines/designing-for-iphone-duo

### 3.1 Design principles (trang đưa trở lại 8/6/2026)

Nguồn: https://developer.apple.com/design/human-interface-guidelines/design-principles

| Nguyên tắc | Ý chính (diễn giải) |
|---|---|
| Purpose | Làm điều có ý nghĩa: tạo giá trị, tập trung vào tính năng cốt lõi, tìm cách giải quyết mới |
| Agency | Để người dùng làm theo cách của họ: không cản đường, tự do khám phá (luồng hướng dẫn phải bỏ qua được), dễ hoàn tác và sửa sai |
| Responsibility | Hành động vì lợi ích người dùng: minh bạch khi xin quyền và thu thập dữ liệu, chỉ thu cái cần, dự phòng lạm dụng |
| Familiarity | Dựa trên điều người dùng đã biết: khái niệm quen thuộc, hình ảnh và tương tác nhất quán, phản hồi rõ ràng |
| Flexibility | Thích ứng nhiều bối cảnh: thiết kế cho mọi người (accessibility ngay từ đầu), giữ ngữ cảnh khi đổi nền tảng, hỗ trợ nhiều cách nhập, chăm chút từng nền tảng như nhau |
| Simplicity | Rõ ràng, trực tiếp: chỉ giữ cái cần thiết (đơn giản không có nghĩa là tối giản), câu chữ súc tích, phân cấp rõ |
| Craft | Chăm từng chi tiết: đặt chuẩn chất lượng cao, thử nghiệm và lặp lại, bám theo khả năng mới của nền tảng |
| Delight | Mang tính người: xác định cảm xúc muốn tạo, tạo khoảnh khắc đặc trưng, không nhầm delight với trang trí |

### 3.2 Designing for macOS / iOS / iPadOS

Nguồn: https://developer.apple.com/design/human-interface-guidelines/designing-for-macos · https://developer.apple.com/design/human-interface-guidelines/designing-for-ios · https://developer.apple.com/design/human-interface-guidelines/designing-for-ipados

| Đặc điểm | macOS | iOS | iPadOS |
|---|---|---|---|
| Màn hình | Lớn, độ phân giải cao, có thể thêm màn hình (kể cả iPad) | Cỡ vừa, độ phân giải cao | Lớn, độ phân giải cao |
| Khoảng cách nhìn | ~1–3 ft | ≤1–2 ft | thường ≤~3 ft |
| Cách nhập | Bàn phím, thiết bị trỏ, game controller, Siri | Multi-Touch, bàn phím ảo, giọng nói, gyro/accelerometer | Multi-Touch, bàn phím, trackpad, Apple Pencil, giọng nói |
| Tính năng hệ thống | Menu bar, quản lý file, full screen, Dock menu | Widgets, Home Screen quick actions, Spotlight, Shortcuts, Activity views | Multitasking, Widgets, Drag and drop |
| Best practice | Tận dụng màn hình lớn để giảm cấp lồng và modal; cửa sổ resize/ẩn/di chuyển được, hỗ trợ full screen; mọi lệnh có trong menu bar; nhập chính xác; keyboard shortcut; cho tuỳ biến toolbar, cửa sổ, màu, font | Ít control trên màn hình; thích ứng orientation, Dark Mode, Dynamic Type; control đặt ở giữa hoặc dưới cho dễ với; swipe để back và thao tác trên dòng; dùng dữ liệu hệ thống khi được phép | Đưa nội dung lên trước, ít modal và chuyển cảnh full-screen; cỡ và mật độ theo khoảng cách nhìn và cách nhập; kết hợp nhiều cách nhập; thích ứng multitasking và chạy được trên macOS |

### 3.3 Designing for iPhone Duo (trang mới 9/9/2026)

Nguồn: https://developer.apple.com/design/human-interface-guidelines/designing-for-iphone-duo

- iPhone gập có 2 màn hình (outer, inner), mỗi màn hình một camera trước, bản lề ở giữa, nhiều tư thế cầm và đặt (pose). Hướng dẫn Designing for iOS vẫn áp dụng.
- Màn hình ngoài rộng và thấp hơn iPhone thường, nên hệ thống **đưa Dynamic Island, status bar, toolbar và tab bar ra cạnh bên (trục dọc)**. Màn hình trong ở tư thế dọc vẫn giữ bar ngang.
- Dùng size class: compact width cho màn hình ngoài, regular width cho màn hình trong. Không làm layout riêng cho từng pose. Tránh chiều rộng cố định. Xem trước bằng Device Hub trong Xcode.
- Reserved regions (vùng nội dung phải tránh): camera ngoài (luôn có, mở rộng thành Dynamic Island khi có Live Activity), camera trong (chỉ khi đang bật), vùng gập (khi mở dở). API: `ReservedRegion` (SwiftUI), `UIView.ReservedRegion` (UIKit).
- Arrangement view (kiểu split/overlay): `ArrangementView` (SwiftUI), `UIArrangementViewController` (UIKit). Đặt navigation bên ngoài arrangement view. Grid nên dùng số cột chẵn.
- Toolbar trên trục dọc: trên cùng là Back/Close, rồi đến prominent action (Done). Item tràn từ dưới lên; chỉnh thứ tự bằng `ToolbarItemVisibilityPriority` / `UIBarButtonItemVisibilityPriority`. Mỗi item cần cả title lẫn symbol. Hạn chế nút chữ. Không override vị trí bar mặc định. Dùng overflow menu của hệ thống (ellipsis chỉ dành cho overflow). Nhóm item bằng `ToolbarItemGroup` thay vì chèn khoảng trống thủ công.

---

## 4. Color

Nguồn: https://developer.apple.com/design/human-interface-guidelines/color (change log mới nhất 16/12/2025; giá trị màu cập nhật 9/6/2025)

### 4.1 Best practices

Nguồn: https://developer.apple.com/design/human-interface-guidelines/color#Best-practices · https://developer.apple.com/design/human-interface-guidelines/color#System-colors

- Mỗi màu chỉ mang một nghĩa (vd brand color đã dùng cho nút borderless thì không dùng cho chữ không tương tác).
- Mọi màu phải ổn ở light, dark và increased contrast. Màu custom cần biến thể light + dark, và mỗi biến thể có thêm bản increased contrast. **App chỉ có một appearance vẫn phải khai báo cả màu light và dark** để Liquid Glass thích ứng.
- Kiểm tra dưới nhiều điều kiện ánh sáng và trên nhiều thiết bị (True Tone, `UIWhitePointAdaptivityStyle`; đổi profile P3/sRGB trên Mac).
- Lưu ý artwork và translucency làm lệch màu lân cận.
- Nếu cho người dùng chọn màu, dùng color picker của hệ thống (`ColorPicker`).
- **Không hard-code giá trị system color**: giá trị có thể đổi giữa các bản phát hành; dùng API `Color`/`UIColor`/`NSColor`.
- Không định nghĩa lại nghĩa của dynamic color (vd không dùng `separator` làm màu chữ, không dùng `secondaryLabel` làm màu nền).

### 4.2 System colors (một bảng chung cho mọi nền tảng)

Nguồn: https://developer.apple.com/design/human-interface-guidelines/color#Specifications (swatch alt text; hex + tương phản tự tính)

| Name | SwiftUI API | Default (light) | Default (dark) | Increased contrast (light) | Increased contrast (dark) |
|---|---|---|---|---|---|
| Red | `red` | 255,56,60 `#FF383C` | 255,66,69 `#FF4245` | 233,21,45 `#E9152D` | 255,97,101 `#FF6165` |
| Orange | `orange` | 255,141,40 `#FF8D28` | 255,146,48 `#FF9230` | 197,83,0 `#C55300` | 255,160,86 `#FFA056` |
| Yellow | `yellow` | 255,204,0 `#FFCC00` | 255,214,0 `#FFD600` | 161,106,0 `#A16A00` | 254,223,67 `#FEDF43` |
| Green | `green` | 52,199,89 `#34C759` | 48,209,88 `#30D158` | 0,137,50 `#008932` | 74,217,104 `#4AD968` |
| Mint | `mint` | 0,200,179 `#00C8B3` | 0,218,195 `#00DAC3` | 0,133,117 `#008575` | 84,223,203 `#54DFCB` |
| Teal | `teal` | 0,195,208 `#00C3D0` | 0,210,224 `#00D2E0` | 0,129,152 `#008198` | 59,221,236 `#3BDDEC` |
| Cyan | `cyan` | 0,192,232 `#00C0E8` | 60,211,254 `#3CD3FE` | 0,126,174 `#007EAE` | 109,217,255 `#6DD9FF` |
| Blue | `blue` | 0,136,255 `#0088FF` | 0,145,255 `#0091FF` | 30,110,244 `#1E6EF4` | 92,184,255 `#5CB8FF` |
| Indigo | `indigo` | 97,85,245 `#6155F5` | 109,124,255 `#6D7CFF` | 86,74,222 `#564ADE` | 167,170,255 `#A7AAFF` |
| Purple | `purple` | 203,48,224 `#CB30E0` | 219,52,242 `#DB34F2` | 176,47,194 `#B02FC2` | 234,141,255 `#EA8DFF` |
| Pink | `pink` | 255,45,85 `#FF2D55` | 255,55,95 `#FF375F` | 231,18,77 `#E7124D` | 255,138,196 `#FF8AC4` |
| Brown | `brown` | 172,127,94 `#AC7F5E` | 183,138,102 `#B78A66` | 149,109,81 `#956D51` | 219,166,121 `#DBA679` |

- visionOS dùng giá trị Default (dark).
- Trang hiện dùng **một bảng chung, không tách theo nền tảng**; chỉ bảng gray (4.3) là riêng cho iOS/iPadOS. Chưa đối chiếu cấu trúc và giá trị trước 9/6/2025 → CHƯA XÁC MINH.
- API UIKit/AppKit tương ứng: `systemRed`, `systemOrange`, … `systemBrown` (xem UIKit/AppKit "Standard colors").

**Tương phản tự tính (WCAG 2.x), chưa phải số Apple công bố.** Giả định nền trắng `#FFFFFF` cho light và nền đen `#000000` cho dark; giá trị thật của `systemBackground` CHƯA XÁC MINH. Tương phản là đối xứng: chữ trắng trên nền màu có cùng tỉ lệ với màu đó trên nền trắng.

| Color | Light / trắng | Dark / đen | IC light / trắng | IC dark / đen |
|---|---|---|---|---|
| Red | 3.57 | 6.12 | 4.56 | 7.15 |
| Orange | 2.31 | 9.41 | 4.55 | 10.41 |
| Yellow | 1.51 | 14.87 | 4.59 | 15.85 |
| Green | 2.22 | 10.39 | 4.54 | 11.42 |
| Mint | 2.12 | 11.82 | 4.55 | 12.79 |
| Teal | 2.16 | 11.30 | 4.57 | 12.74 |
| Cyan | 2.16 | 11.94 | 4.57 | 13.02 |
| Blue | 3.52 | 6.49 | 4.57 | 9.76 |
| Indigo | 5.09 | 5.98 | 6.12 | 9.84 |
| Purple | 4.17 | 5.79 | 5.21 | 9.75 |
| Pink | 3.65 | 5.96 | 4.57 | 9.68 |
| Brown | 3.53 | 6.84 | 4.58 | 9.74 |

Nhận xét: mọi biến thể **Increased contrast (light)** đều đạt khoảng 4.5:1 trên nền trắng. Ở light mặc định, chỉ Indigo đạt 4.5:1 khi dùng làm màu chữ nhỏ.

### 4.3 iOS, iPadOS system gray colors

Nguồn: https://developer.apple.com/design/human-interface-guidelines/color#iOS-iPadOS-system-gray-colors · https://developer.apple.com/documentation/appkit/standard-colors

| Name | UIKit API | Default (light) | Default (dark) | Increased contrast (light) | Increased contrast (dark) |
|---|---|---|---|---|---|
| Gray | `systemGray` | 142,142,147 `#8E8E93` | 142,142,147 `#8E8E93` | 108,108,112 `#6C6C70` | 174,174,178 `#AEAEB2` |
| Gray (2) | `systemGray2` | 174,174,178 `#AEAEB2` | 99,99,102 `#636366` | 142,142,147 `#8E8E93` | 124,124,128 `#7C7C80` |
| Gray (3) | `systemGray3` | 199,199,204 `#C7C7CC` | 72,72,74 `#48484A` | 174,174,178 `#AEAEB2` | 84,84,86 `#545456` |
| Gray (4) | `systemGray4` | 209,209,214 `#D1D1D6` | 58,58,60 `#3A3A3C` | 188,188,192 `#BCBCC0` | 68,68,70 `#444446` |
| Gray (5) | `systemGray5` | 229,229,234 `#E5E5EA` | 44,44,46 `#2C2C2E` | 216,216,220 `#D8D8DC` | 54,54,56 `#363638` |
| Gray (6) | `systemGray6` | 242,242,247 `#F2F2F7` | 28,28,30 `#1C1C1E` | 235,235,240 `#EBEBF0` | 36,36,38 `#242426` |

- SwiftUI `gray` tương đương `systemGray`.
- AppKit chỉ có `systemGray`, không có `systemGray2`–`systemGray6` (nguồn: tài liệu AppKit "Standard colors").

### 4.4 Dynamic system colors — iOS, iPadOS

Nguồn: https://developer.apple.com/design/human-interface-guidelines/color#iOS-iPadOS · https://developer.apple.com/documentation/uikit/ui-element-colors

- **Background:** 2 bộ.
  - System: `systemBackground`, `secondarySystemBackground`, `tertiarySystemBackground`.
  - Grouped (dùng cho grouped table view): `systemGroupedBackground`, `secondarySystemGroupedBackground`, `tertiarySystemGroupedBackground`.
  - Primary dùng cho view tổng thể, secondary cho nhóm bên trong, tertiary cho nhóm bên trong secondary.
- **Foreground** (bảng trong HIG):

| Color | Dùng cho | UIKit API |
|---|---|---|
| Label | Chữ nội dung chính | `label` |
| Secondary label | Chữ nội dung phụ | `secondaryLabel` |
| Tertiary label | Chữ cấp ba | `tertiaryLabel` |
| Quaternary label | Chữ cấp bốn | `quaternaryLabel` |
| Placeholder text | Placeholder trong control/text view | `placeholderText` |
| Separator | Đường phân cách, nhìn xuyên được phần dưới | `separator` |
| Opaque separator | Đường phân cách đặc | `opaqueSeparator` |
| Link | Chữ là link | `link` |

- **Fill:** `systemFill`, `secondarySystemFill`, `tertiarySystemFill`, `quaternarySystemFill`. Có trong tài liệu UIKit nhưng HIG không liệt kê.
- **Giá trị RGBA của label, fill, background, separator: HIG không công bố → CHƯA XÁC MINH.** Nên lấy từ UI Kit Figma iOS 27 hoặc đọc lúc chạy.

### 4.5 Dynamic system colors — macOS (AppKit)

Nguồn: https://developer.apple.com/design/human-interface-guidelines/color#macOS · https://developer.apple.com/documentation/appkit/ui-element-colors

HIG liệt kê 35 màu (xem được trong bảng Developer của Color panel):

| Nhóm | API (`NSColor`) | Dùng cho |
|---|---|---|
| Label/Text | `labelColor`, `secondaryLabelColor`, `tertiaryLabelColor`, `quaternaryLabelColor` | Chữ cấp 1→4 (quaternary: chữ mờ như watermark) |
| Label/Text | `textColor`, `textBackgroundColor`, `placeholderTextColor`, `headerTextColor`, `windowFrameTextColor` | Chữ tài liệu và nền của nó; placeholder; tiêu đề cột bảng; chữ trên title bar |
| Control | `controlAccentColor` | Accent người dùng chọn trong System Settings |
| Control | `controlColor`, `controlBackgroundColor`, `controlTextColor`, `disabledControlTextColor`, `currentControlTint` | Bề mặt control; nền phần tử lớn (browser, table); chữ control bật/tắt; tint hệ thống |
| Selection | `selectedContentBackgroundColor`, `unemphasizedSelectedContentBackgroundColor` | Nền nội dung đang chọn khi cửa sổ là key / non-key |
| Selection | `selectedTextBackgroundColor`, `selectedTextColor`, `unemphasizedSelectedTextBackgroundColor`, `unemphasizedSelectedTextColor` | Chữ đang chọn khi cửa sổ là key / non-key |
| Selection | `selectedControlColor`, `selectedControlTextColor`, `alternateSelectedControlTextColor`, `selectedMenuItemTextColor` | Control đang chọn; chữ trên dòng đang chọn trong list/table; chữ menu item đang chọn |
| Content/Window | `windowBackgroundColor`, `underPageBackgroundColor`, `alternatingContentBackgroundColors`, `gridColor`, `separatorColor`, `linkColor` | Nền cửa sổ; nền phía sau tài liệu; nền xen kẽ dòng/cột; đường lưới; đường phân cách; link |
| Khác | `findHighlightColor`, `keyboardFocusIndicatorColor`, `highlightColor`, `shadowColor` | Chỉ báo Find; focus ring bàn phím; nguồn sáng ảo; bóng ảo |

- Tài liệu AppKit còn có nhóm Fill (`systemFill`, `secondarySystemFill`, `tertiarySystemFill`, `quaternarySystemFill`, `quinarySystemFill`), `quinaryLabel` và `textInsertionPointColor`. HIG không nhắc.
- Giá trị số: không có trong HIG → CHƯA XÁC MINH.

### 4.6 macOS — accent color

Nguồn: https://developer.apple.com/design/human-interface-guidelines/color#App-accent-colors · https://developer.apple.com/design/human-interface-guidelines/sidebars · https://developer.apple.com/design/human-interface-guidelines/dark-mode#macOS

- Từ macOS 11, app có thể khai báo accent color cho button, selection highlight và sidebar icon. Accent này **chỉ được áp dụng khi người dùng để Accent color là Multicolor** (HIG ghi vị trí là General > Accent color).
- Nếu người dùng chọn màu khác Multicolor, màu đó thay accent của app. Ngoại lệ: sidebar icon dùng **fixed color** (có mang nghĩa) thì không bị thay.
- Cập nhật 8/6/2026: icon sidebar mặc định dùng accent color. Người dùng đổi accent thì mong mọi icon đổi theo. Fixed color chỉ dùng rất tiết chế (vd icon VIP của Mail màu vàng).
- Chọn accent Graphite → **desktop tinting** (nền cửa sổ nhuốm màu hình nền). Component custom ở trạng thái trung tính (có nền hoặc bezel) nên có chút transparency; không thêm transparency khi component đang mang màu.
- `controlAccentColor` = accent người dùng chọn.

### 4.7 Liquid Glass color

Nguồn: https://developer.apple.com/design/human-interface-guidelines/color#Liquid-Glass-color

- Mặc định Liquid Glass không có màu, nó lấy màu từ nội dung phía sau. Có thể tô màu một số element (giống kính màu); hệ thống dùng cách này cho prominent button. Symbol và chữ trên kính cũng có thể mang màu.
- Element nhỏ (toolbar, tab bar) tự chuyển light/dark theo nội dung bên dưới; symbol và chữ mặc định đơn sắc (tối khi nền sáng, sáng khi nền tối). Element lớn (sidebar) đục hơn để giữ khả năng đọc.
- **Tô màu tiết chế:** chỉ cho chỉ báo trạng thái hoặc primary action. Muốn nhấn mạnh primary action thì **tô nền, không tô symbol/chữ** (vd nút Done lấy accent làm nền). Không tô nền nhiều control cùng lúc.
- Nền app nhiều màu → toolbar/tab bar nên đơn sắc, hoặc chọn accent khác biệt đủ rõ. App có nội dung chủ yếu đơn sắc → dùng brand color làm accent là hợp lý.
- Tránh để màu trong content layer trùng tông với control nằm trên. Trạng thái nghỉ (đầu trang cuộn) phải luôn dễ đọc.
- Liên quan (buttons, toolbars):
  - Mỗi view chỉ 1–2 prominent button (nền được tô accent). Dùng **style chứ không dùng size** để phân biệt lựa chọn ưu tiên.
  - Không gán role primary cho hành động destructive. Role destructive dùng system red.
  - Trong toolbar, `.prominent` chỉ dùng cho một action chính (Done, Submit), đặt ở trailing.
  - Hạn chế tô nền toolbar và tô màu control.

### 4.8 Màu hoà nhập, đỏ/xanh lá và mù màu

Nguồn: https://developer.apple.com/design/human-interface-guidelines/color#Inclusive-color · https://developer.apple.com/design/human-interface-guidelines/accessibility · https://developer.apple.com/design/human-interface-guidelines/inclusion

- Không chỉ dựa vào màu để phân biệt đối tượng, báo tương tác hay truyền thông tin quan trọng. Thêm nhãn chữ hoặc hình dạng glyph.
- Người mù màu khó phân biệt cặp **đỏ–xanh lá** và **xanh dương–cam**. Ví dụ đúng của HIG: hình tròn xanh lá có checkmark bên cạnh hình bát giác đỏ có X. Nên cho tuỳ biến bảng màu (chart, nhân vật).
- Nghĩa văn hoá: đỏ là nguy hiểm ở nơi này, tích cực ở nơi khác. Ví dụ Stocks: giá tăng tô xanh lá ở bản tiếng Anh, tô đỏ ở bản tiếng Trung. Màu trắng có thể gắn với tang lễ hoặc với tinh khiết, tuỳ nơi.
- Role destructive của button dùng system red (buttons).

### 4.9 Color management

Nguồn: https://developer.apple.com/design/human-interface-guidelines/color#Color-management · https://developer.apple.com/design/human-interface-guidelines/app-icons#Specifications

- sRGB cho màu chính xác trên đa số màn hình. Wide color dùng Display P3, 16 bit/kênh, xuất PNG; cần màn hình wide color để thiết kế.
- Khi cần, dùng asset catalog để có biến thể ảnh và màu riêng theo color space.
- Gắn color profile vào mọi ảnh.
- App icon hỗ trợ sRGB, Gray Gamma 2.2, Display P3 (Display P3 không áp dụng cho visionOS).

---

## 5. Typography

Nguồn: https://developer.apple.com/design/human-interface-guidelines/typography (mới nhất 16/12/2025) · https://developer.apple.com/fonts/

### 5.1 Font hệ thống

Nguồn: https://developer.apple.com/design/human-interface-guidelines/typography#Using-system-fonts · https://developer.apple.com/fonts/ · https://developer.apple.com/documentation/swiftui/font/design

| Family | Đặc điểm | Dùng ở đâu |
|---|---|---|
| SF Pro | Sans serif. 9 weight (Ultralight → Black) + italic; 4 width (gồm Condensed, Expanded); có bản rounded; variable optical size; hơn 150 ngôn ngữ (Latin, Greek, Cyrillic) | System font iOS, iPadOS, macOS, tvOS, visionOS |
| SF Compact | Sans, tối ưu cho cỡ nhỏ và cột hẹp; có rounded | System font watchOS; complications dùng SF Compact Rounded |
| SF Mono | Monospaced, 6 weight, Latin/Greek/Cyrillic | Căn thẳng hàng và cột (Xcode) |
| New York (NY) | Serif, 6 weight, variable optical size, Latin/Greek/Cyrillic | Dùng được trên iOS/iPadOS/tvOS/watchOS. **macOS: chỉ cho app Mac Catalyst** (theo HIG). visionOS phải tự chỉ định text style |
| SF Arabic / Armenian / Georgian / Hebrew | Mở rộng theo hệ chữ; 9 weight, rounded, variable optical size | Dàn trang đa ngữ |

- SF và NY có dạng variable font. Hệ thống dùng **dynamic optical sizes** (gộp Text và Display thành một thiết kế liên tục), nên không cần chọn optical size riêng, trừ khi công cụ thiết kế không hỗ trợ variable font.
- SF Symbols có weight tương đương font để khớp weight với chữ bên cạnh.
- **Không nhúng file system font vào app.** Gọi qua `Font.Design`: `.default` (SF), `.serif` (NY). API còn có `.rounded`, `.monospaced`.

### 5.2 Cỡ chữ mặc định và tối thiểu

Nguồn: https://developer.apple.com/design/human-interface-guidelines/typography#Ensuring-legibility · https://developer.apple.com/design/human-interface-guidelines/accessibility#Vision

| Nền tảng | Mặc định | Tối thiểu |
|---|---|---|
| iOS, iPadOS | 17 pt | 11 pt |
| macOS | 13 pt | 10 pt |
| tvOS | 29 pt | 23 pt |
| visionOS | 17 pt | 12 pt |
| watchOS | 16 pt | 12 pt |

- Tránh weight nhẹ (Ultralight, Thin, Light), nhất là ở cỡ nhỏ; ưu tiên Regular, Medium, Semibold, Bold. Font custom mảnh thì dùng cỡ lớn hơn mức khuyến nghị.
- Ngưỡng này áp dụng cho cả font hệ thống lẫn font custom.

### 5.3 iOS/iPadOS Dynamic Type — cỡ Large (mặc định)

Nguồn: https://developer.apple.com/design/human-interface-guidelines/typography#iOS-iPadOS-Dynamic-Type-sizes

| Style | Weight | Size (pt) | Leading (pt) | Emphasized weight |
|---|---|---|---|---|
| Large Title | Regular | 34 | 41 | Bold |
| Title 1 | Regular | 28 | 34 | Bold |
| Title 2 | Regular | 22 | 28 | Bold |
| Title 3 | Regular | 20 | 25 | Semibold |
| Headline | Semibold | 17 | 22 | Semibold |
| Body | Regular | 17 | 22 | Semibold |
| Callout | Regular | 16 | 21 | Semibold |
| Subhead | Regular | 15 | 20 | Semibold |
| Footnote | Regular | 13 | 18 | Semibold |
| Caption 1 | Regular | 12 | 16 | Semibold |
| Caption 2 | Regular | 11 | 13 | Semibold |

Point size tính theo ảnh 144 ppi (@2x) và 216 ppi (@3x).

### 5.4 Dynamic Type từ xSmall đến AX5 (size/leading, pt)

Nguồn: https://developer.apple.com/design/human-interface-guidelines/typography#iOS-iPadOS-Dynamic-Type-sizes · https://developer.apple.com/design/human-interface-guidelines/typography#iOS-iPadOS-larger-accessibility-type-sizes

Weight không đổi theo cỡ: Headline là Semibold, các style khác là Regular. Emphasized: Large Title, Title 1, Title 2 → Bold; các style còn lại → Semibold. Cột `Large*` là mặc định.

| Style | xSmall | Small | Medium | Large* | xLarge | xxLarge | xxxLarge | AX1 | AX2 | AX3 | AX4 | AX5 |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| Large Title | 31/38 | 32/39 | 33/40 | 34/41 | 36/43 | 38/46 | 40/48 | 44/52 | 48/57 | 52/61 | 56/66 | 60/70 |
| Title 1 | 25/31 | 26/32 | 27/33 | 28/34 | 30/37 | 32/39 | 34/41 | 38/46 | 43/51 | 48/57 | 53/62 | 58/68 |
| Title 2 | 19/24 | 20/25 | 21/26 | 22/28 | 24/30 | 26/32 | 28/34 | 34/41 | 39/47 | 44/52 | 50/59 | 56/66 |
| Title 3 | 17/22 | 18/23 | 19/24 | 20/25 | 22/28 | 24/30 | 26/32 | 31/38 | 37/44 | 43/51 | 49/58 | 55/65 |
| Headline | 14/19 | 15/20 | 16/21 | 17/22 | 19/24 | 21/26 | 23/29 | 28/34 | 33/40 | 40/48 | 47/56 | 53/62 |
| **Body** | **14/19** | **15/20** | **16/21** | **17/22** | **19/24** | **21/26** | **23/29** | **28/34** | **33/40** | **40/48** | **47/56** | **53/62** |
| Callout | 13/18 | 14/19 | 15/20 | 16/21 | 18/23 | 20/25 | 22/28 | 26/32 | 32/39 | 38/46 | 44/52 | 51/60 |
| Subhead | 12/16 | 13/18 | 14/19 | 15/20 | 17/22 | 19/24 | 21/28 | 25/31 | 30/37 | 36/43 | 42/50 | 49/58 |
| Footnote | 12/16 | 12/16 | 12/16 | 13/18 | 15/20 | 17/22 | 19/24 | 23/29 | 27/33 | 33/40 | 38/46 | 44/52 |
| Caption 1 | 11/13 | 11/13 | 11/13 | 12/16 | 14/19 | 16/21 | 18/23 | 22/28 | 26/32 | 32/39 | 37/44 | 43/51 |
| Caption 2 | 11/13 | 11/13 | 11/13 | 11/13 | 13/18 | 15/20 | 17/22 | 20/25 | 24/30 | 29/35 | 34/41 | 40/48 |

### 5.5 macOS built-in text styles (không có Dynamic Type)

Nguồn: https://developer.apple.com/design/human-interface-guidelines/typography#macOS-built-in-text-styles

| Text style | Weight | Size (pt) | Line height (pt) | Emphasized weight |
|---|---|---|---|---|
| Large Title | Regular | 26 | 32 | Bold |
| Title 1 | Regular | 22 | 26 | Bold |
| Title 2 | Regular | 17 | 22 | Bold |
| Title 3 | Regular | 15 | 20 | Semibold |
| Headline | **Bold** | 13 | 16 | **Heavy** |
| Body | Regular | 13 | 16 | Semibold |
| Callout | Regular | 12 | 15 | Semibold |
| Subheadline | Regular | 11 | 14 | Semibold |
| Footnote | Regular | 10 | 13 | Semibold |
| Caption 1 | Regular | 10 | 13 | Medium |
| Caption 2 | Medium | 10 | 13 | Semibold |

Point size tính theo ảnh 144 ppi (@2x).

### 5.6 macOS — dynamic system font variants (để chữ khớp control chuẩn)

Nguồn: https://developer.apple.com/design/human-interface-guidelines/typography#macOS

| Variant | API (`NSFont`) |
|---|---|
| Control content | `controlContentFont(ofSize:)` |
| Label | `labelFont(ofSize:)` |
| Menu | `menuFont(ofSize:)` |
| Menu bar | `menuBarFont(ofSize:)` |
| Message | `messageFont(ofSize:)` |
| Palette | `paletteFont(ofSize:)` |
| Title | `titleBarFont(ofSize:)` |
| Tool tips | `toolTipsFont(ofSize:)` |
| Document text (user) | `userFont(ofSize:)` |
| Monospaced document text | `userFixedPitchFont(ofSize:)` |
| Bold system font | `boldSystemFont(ofSize:)` |
| System font | `systemFont(ofSize:)` |

### 5.7 Tracking

Nguồn: https://developer.apple.com/design/human-interface-guidelines/typography#Tracking-values

- Khi app chạy, system font **tự điều chỉnh tracking theo từng cỡ**. Chỉ cần chỉnh tracking thủ công khi dựng mockup.
- Bảng SF Pro dùng chung cho iOS/iPadOS/visionOS. macOS và tvOS có cùng giá trị 1/1000 em. Riêng bảng macOS ở 52 pt và 53 pt bị đảo giá trị theo point (+0.31 và +0.33) so với iOS, nhiều khả năng là lỗi của bảng → nên dùng đơn vị em.

| Size (pt) | 10 | 11 | 12 | 13 | 15 | 16 | 17 | 20 | 22 | 26 | 28 | 34 |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| Tracking (1/1000 em) | +12 | +6 | 0 | −6 | −16 | −20 | −26 | −23 | −12 | +8 | +14 | +12 |
| Tracking (pt) | +0.12 | +0.06 | 0.0 | −0.08 | −0.23 | −0.31 | −0.43 | −0.45 | −0.26 | +0.22 | +0.38 | +0.40 |

Đây là trích một phần. Bảng đầy đủ SF Pro 6–96 pt, SF Pro Rounded, New York (6–260 pt), SF Compact và SF Compact Rounded có trên trang.

### 5.8 Hierarchy, font custom, Dynamic Type

Nguồn: https://developer.apple.com/design/human-interface-guidelines/typography#Conveying-hierarchy · https://developer.apple.com/design/human-interface-guidelines/typography#Using-custom-fonts · https://developer.apple.com/design/human-interface-guidelines/typography#Supporting-Dynamic-Type · https://developer.apple.com/design/human-interface-guidelines/branding

- Dùng weight, size và màu để thể hiện hierarchy; giữ hierarchy khi người dùng đổi cỡ chữ; dùng ít typeface.
- Khi chữ to lên, ưu tiên nội dung quan trọng (vd tiêu đề tab không cần to theo).
- Symbolic traits: bold (tạo thêm một cấp); leading loose (đoạn dài, cột rộng) hoặc tight (nơi hẹp chiều cao); từ 3 dòng trở lên thì tránh tight leading. Emphasized dùng `bold()` (SwiftUI) hoặc `traitBold` (UIKit); weight có thể là medium, semibold, bold hoặc heavy.
- Font custom: phải dễ đọc, theo ngưỡng cỡ tối thiểu, **và phải hỗ trợ Dynamic Type cùng Bold Text** như system font. Branding: font thương hiệu hợp với headline/subheading; body và caption nên dùng system font.
- Dynamic Type (iOS, iPadOS, tvOS, visionOS, watchOS):
  - Layout phải chịu được mọi cỡ (bật Larger Accessibility Text Sizes để test).
  - Icon mang nghĩa phải to theo chữ (SF Symbols tự to theo).
  - Hạn chế cắt chữ: ở cỡ AX lớn nhất nên hiện được lượng chữ tương đương cỡ chuẩn lớn nhất.
  - Chuyển sang layout xếp chồng khi cỡ lớn; giảm số cột (`isAccessibilityCategory`).
  - Giữ phần tử chính ở đầu màn hình.
- Accessibility: cho phép phóng chữ **ít nhất 200%** (watchOS 140%).

---

## 6. Layout

Nguồn: https://developer.apple.com/design/human-interface-guidelines/layout (cập nhật 9/9/2026)

### 6.1 Nguyên tắc

Nguồn: https://developer.apple.com/design/human-interface-guidelines/layout#Visual-hierarchy · https://developer.apple.com/design/human-interface-guidelines/layout#Adaptability · https://developer.apple.com/design/human-interface-guidelines/layout#Guides-and-safe-areas

- **Visual hierarchy:** sắp theo mức quan trọng (trên xuống dưới, leading → trailing). Căn lề giúp dễ quét, thụt lề thể hiện cấp con. Nhóm bằng khoảng trống, container hoặc separator. Dùng progressive disclosure.
- **Tách control khỏi nội dung:** control dùng Liquid Glass. **Không đặt nền màu đặc hoặc bán trong suốt dưới control**; dùng scroll edge effect. Nội dung nền full-screen phải kéo dài xuống dưới sidebar, toolbar, tab bar. Background extension effect lật và blur ảnh để lấp phần dưới sidebar/inspector (`backgroundExtensionEffect()`, `UIBackgroundExtensionView`, `NSBackgroundExtensionView`).
- **Adaptability:** size class, cỡ màn hình, orientation, Dynamic Island, màn hình ngoài, Display Zoom, cửa sổ resize được (iPad, Mac), đổi cỡ chữ, locale (RTL, định dạng, độ dài chữ).
- Quyết định layout theo **size class**, không theo loại thiết bị hay orientation. Giữ nguyên chức năng khi đổi size class (chỉ thay lượng hiển thị; có thể đổi tab bar thành sidebar). Giữ idiom quen thuộc của nền tảng khi resize.
- Tôn trọng safe area, margin, layout guide (`UILayoutGuide`, `NSLayoutGuide`, `SafeAreaRegions`). Test cỡ lớn nhất và nhỏ nhất, localization, cỡ chữ trong **Device Hub** (Xcode), kể cả iPhone Mirroring trên Mac.
- Ảnh nền: scale để lấp đầy, không đổi tỉ lệ khung hình.

### 6.2 Số liệu

Nguồn: các trang ghi ở cột "Nguồn" (tiền tố https://developer.apple.com/design/human-interface-guidelines/)

| Mục | Giá trị | Nguồn |
|---|---|---|
| Hit region tối thiểu của button | 44x44 pt (visionOS 60x60 pt) | buttons |
| Padding quanh element có bezel | ~12 pt | accessibility, pointing-devices |
| Padding quanh element không bezel | ~24 pt (tính từ mép nhìn thấy) | accessibility, pointing-devices |
| Padding cho image button (macOS) | ~10 px | buttons |
| Chiều cao menu bar macOS | 24 pt | the-menu-bar |
| Tiêu đề window/toolbar | dưới 15 ký tự | toolbars |
| Số nhóm trong toolbar | tối đa ~3 | toolbars |
| Số cấp trong sidebar | ≤2 | sidebars |
| Submenu | 1 cấp; hơn ~5 item thì tách thành menu mới | menus |
| Tên app trong mục About | ≤16 ký tự | the-menu-bar |
| Alert | ≤3 button; tiêu đề ≤2 dòng | alerts |
| Lớp dim sau clear glass | 35% opacity (khi nội dung phía sau sáng) | materials |
| Tab bar iPadOS (khi cho tuỳ biến) | mặc định ≤5 tab | tab-bars |
| Margin Live Activity trên Lock Screen | 14 pt (tham khảo) | live-activities |
| tvOS safe area | 60 pt trên/dưới, 80 pt hai bên | layout |
| visionOS | tâm các button cách nhau ≥60 pt; window mặc định 1280x720 pt | layout, buttons, windows |
| **Margin iOS/macOS, bảng kích thước màn hình** | **Không còn trong HIG.** Trang Layout (9/9/2026) đã bỏ Specifications; trang iPhone Duo trỏ sang Apple Design Resources → CHƯA XÁC MINH. Đọc từ `layoutMargins`, `readableContentGuide` hoặc UI Kit | layout, designing-for-iphone-duo |
| Kích thước icon cho tab bar và sidebar | HIG trỏ sang Apple Design Resources → CHƯA XÁC MINH | tab-bars, sidebars |

### 6.3 Concentricity (đồng tâm)

Nguồn: https://developer.apple.com/design/human-interface-guidelines/toolbars · https://developer.apple.com/design/human-interface-guidelines/app-icons · https://developer.apple.com/documentation/technologyoverviews/adopting-liquid-glass

- Button, text field, header, footer chuẩn trong toolbar có góc bo đồng tâm với góc bar. Component custom cũng phải như vậy.
- Góc bo app icon do hệ thống tạo, khớp độ cong của UI và bezel thiết bị.
- Tài liệu developer "Adopting Liquid Glass" (không phải HIG):
  - Hình dạng phần cứng quyết định độ cong của control, sheet, popover, window. Dùng `ConcentricRectangle` và `rect(corners:isUniform:)` (SwiftUI), `UICornerConfiguration` và `cornerConfiguration` (UIKit).
  - Sheet có góc bo lớn hơn; half sheet thụt vào khỏi mép màn hình.
  - List/table/form có dòng cao hơn, section bo góc lớn hơn; **section header dùng title-style, không còn ALL CAPS**.
  - Control có thêm cỡ extra-large.
- Số radius cụ thể: HIG không nêu → CHƯA XÁC MINH.

### 6.4 macOS: cửa sổ, popover, panel, sheet, settings, menu bar extra

Nguồn: https://developer.apple.com/design/human-interface-guidelines/layout#macOS · https://developer.apple.com/design/human-interface-guidelines/windows · https://developer.apple.com/design/human-interface-guidelines/popovers · https://developer.apple.com/design/human-interface-guidelines/panels · https://developer.apple.com/design/human-interface-guidelines/sheets · https://developer.apple.com/design/human-interface-guidelines/settings · https://developer.apple.com/design/human-interface-guidelines/the-menu-bar

- **Layout:** không đặt control hay thông tin quan trọng ở đáy cửa sổ (người dùng hay kéo đáy cửa sổ ra khỏi màn hình). Không đặt nội dung sau vùng camera (`NSPrefersDisplaySafeAreaCompatibilityMode`).
- **Window:** gồm frame (có window controls, toolbar) và body. Có 3 trạng thái: main, key, inactive. Key window có nút đóng/thu nhỏ/phóng to màu; inactive thì không có vibrancy. Không tự vẽ window chrome. Cửa sổ custom phải theo appearance hệ thống. Bottom bar chỉ chứa thông tin nhỏ. Gọi là "window" khi nói với người dùng.
- **Popover:**
  - Chỉ chứa ít thông tin hoặc chức năng; mũi tên trỏ đúng phần tử mở ra nó.
  - Chỉ thêm Close/Cancel/Done khi cần làm rõ. **Tự lưu khi popover nonmodal đóng.**
  - Mỗi lúc một popover, không popover chồng popover. Không cho view khác phủ lên (trừ alert). Không làm quá to; animate khi đổi cỡ. Không dùng popover để cảnh báo.
  - macOS cho phép kéo popover thành panel (detach).
- **Panel (chỉ macOS):**
  - Nổi trên các cửa sổ, dùng cho inspector hoặc điều chỉnh nhanh; ưu tiên slider/stepper hơn ô nhập chữ.
  - Title bar ngắn, là danh từ, title-style.
  - **Hiện khi app active, ẩn khi app inactive.** Không nằm trong danh sách cửa sổ của Window menu. Thường tắt nút minimize.
  - HUD style (tối, trong suốt) chỉ dùng cho app media hoặc khi panel chuẩn che mất nội dung.
- **Sheet (macOS):** modal, làm mờ cửa sổ cha, cỡ mặc định hợp lý; vẫn cho tương tác với cửa sổ khác của app.
- **Settings:**
  - Mở bằng Settings… trong App menu (⌘,); **không đặt nút settings trên toolbar**.
  - Làm mờ nút minimize/maximize. Toolbar không cho tuỳ biến và luôn chỉ pane đang mở.
  - Tiêu đề theo pane; nếu chỉ một pane thì "App Name Settings". Mở lại pane xem gần nhất.
- **Menu bar extra:**
  - Dùng icon hoặc SF Symbol dạng template (đen + trong suốt; hệ thống tô màu cho menu bar sáng/tối và khi được chọn). Menu bar cao 24 pt.
  - **Khi click thì mở menu, không mở popover**, trừ khi chức năng quá phức tạp cho một menu.
  - **Để người dùng quyết định có hiện extra hay không** (qua setting; có thể hỏi lúc setup).
  - Không phụ thuộc vào việc extra đang hiện (hệ thống có thể ẩn bớt khi chật). Cung cấp đường vào khác, vd Dock menu. API: `MenuBarExtra` (macOS 13+), `NSStatusBar`.
- **Menu bar (app):**
  - Thứ tự menu: *YourAppName*, File, Edit, Format, View, menu riêng của app, Window, Help.
  - Luôn hiện đủ item: disable chứ không ẩn. Có Window menu kể cả khi app chỉ có một cửa sổ (Minimize, Zoom).
  - **Mọi toolbar item phải có lệnh tương ứng trong menu bar.** Toolbar item trên macOS không có bezel.

---

## 7. Accessibility

Nguồn: https://developer.apple.com/design/human-interface-guidelines/accessibility (mới nhất 9/6/2025) · https://developer.apple.com/design/human-interface-guidelines/voiceover · https://developer.apple.com/design/human-interface-guidelines/typography#Supporting-Dynamic-Type

- Giao diện accessible có 3 tính chất: Intuitive, Perceivable, Adaptable.
- Công cụ: Accessibility Inspector. App Store có Accessibility Nutrition Labels để khai báo mức hỗ trợ.

### 7.1 Kích thước control

Nguồn: https://developer.apple.com/design/human-interface-guidelines/accessibility#Mobility

| Nền tảng | Mặc định | Tối thiểu |
|---|---|---|
| iOS, iPadOS | 44x44 pt | 28x28 pt |
| macOS | 28x28 pt | 20x20 pt |
| tvOS | 66x66 pt | 56x56 pt |
| visionOS | 60x60 pt | 28x28 pt |
| watchOS | 44x44 pt | 28x28 pt |

Khoảng cách giữa các control quan trọng ngang kích thước: ~12 pt quanh element có bezel, ~24 pt quanh element không bezel.

### 7.2 Tương phản chữ (Accessibility Inspector dùng WCAG Level AA)

Nguồn: https://developer.apple.com/design/human-interface-guidelines/accessibility#Vision · https://developer.apple.com/design/human-interface-guidelines/dark-mode#Dark-Mode-colors

| Cỡ chữ | Weight | Tỉ lệ tối thiểu |
|---|---|---|
| Đến 17 pt | Mọi weight | 4.5:1 |
| 18 pt (trang ghi "18 pts") | Mọi weight | 3:1 |
| Mọi cỡ | Bold | 3:1 |

- HIG nhắc cả WCAG và APCA như thước đo.
- Nếu mặc định chưa đạt, ít nhất phải có bảng màu tương phản cao khi bật Increase Contrast. Kiểm tra cả light lẫn dark.
- Dark Mode (dark-mode): tối thiểu 4.5:1; màu custom nên nhắm **7:1**, nhất là chữ nhỏ.

### 7.3 Setting hệ thống ↔ hướng dẫn ↔ API

Nguồn: https://developer.apple.com/design/human-interface-guidelines/accessibility · https://developer.apple.com/design/human-interface-guidelines/dark-mode · https://developer.apple.com/design/human-interface-guidelines/materials · https://developer.apple.com/design/human-interface-guidelines/typography · https://developer.apple.com/documentation/swiftui/environmentvalues · https://developer.apple.com/documentation/appkit/nsworkspace

| Setting | HIG yêu cầu | API (SwiftUI / AppKit) |
|---|---|---|
| Increase Contrast | Có bảng màu tương phản cao hơn. System color có sẵn biến thể; màu custom cần biến thể IC cho light và dark | `colorSchemeContrast` / `NSWorkspace.accessibilityDisplayShouldIncreaseContrast` |
| Reduce Transparency | Kiểm tra độ dễ đọc trong Dark Mode khi bật IC và RT (riêng và chung). Liquid Glass đổi appearance theo setting | `accessibilityReduceTransparency` / `accessibilityDisplayShouldReduceTransparency` |
| Reduce Motion | Giảm animation tự động và lặp lại (zoom, scale, chuyển động ở vùng ngoại vi). Siết spring để bớt nảy; animation bám theo gesture; không animate chiều sâu trục z; thay chuyển cảnh x/y/z bằng fade; không animate vào/ra khỏi blur | `accessibilityReduceMotion` / `accessibilityDisplayShouldReduceMotion` |
| Differentiate Without Color | **HIG không nêu tên setting này.** Nội dung tương ứng: "truyền thông tin bằng hơn một mình màu" (hình dạng, icon, chữ) | `accessibilityDifferentiateWithoutColor` / `accessibilityDisplayShouldDifferentiateWithoutColor` (tài liệu developer) |
| Bold Text | System font tự hỗ trợ; font custom phải tự làm | `legibilityWeight` (theo setting Bold Text — tài liệu SwiftUI) |
| Larger Text / Dynamic Type | Phóng được ≥200% (watchOS 140%); layout thích ứng. macOS không có Dynamic Type | `dynamicTypeSize` |
| Dim Flashing Lights | App phát video phải tôn trọng setting này | Media Accessibility "Flashing lights" |
| Assistive Access (iOS, iPadOS) | Giữ chức năng cốt lõi, bỏ luồng phụ; mỗi màn hình một tương tác; **xác nhận hai lần** hành động khó hoàn tác | Assistive Access |

### 7.4 VoiceOver

Nguồn: https://developer.apple.com/design/human-interface-guidelines/voiceover (trang mới 7/3/2025)

- Có nhãn thay thế cho mọi phần tử giao diện chính và mọi element custom; cập nhật nhãn khi nội dung đổi.
- Mô tả ảnh có nghĩa; ẩn ảnh trang trí (`accessibilityHidden(_:)`). Chart/infographic phải truy cập đầy đủ.
- Tiêu đề và heading rõ ràng. Khai báo nhóm, thứ tự, liên kết giữa phần tử (`shouldGroupAccessibilityChildren`). Báo khi nội dung hoặc layout đổi (`AccessibilityNotification`). Hỗ trợ rotor.
- Toolbar icon luôn có accessibility label (Adopting Liquid Glass).

### 7.5 Các nhóm khác

Nguồn: https://developer.apple.com/design/human-interface-guidelines/accessibility#Hearing · https://developer.apple.com/design/human-interface-guidelines/accessibility#Mobility · https://developer.apple.com/design/human-interface-guidelines/accessibility#Speech · https://developer.apple.com/design/human-interface-guidelines/accessibility#Cognitive

- **Thính giác:** captions, subtitles, audio descriptions, transcripts. Âm báo đi kèm haptics; tín hiệu âm thanh đi kèm tín hiệu hình.
- **Vận động:** gesture đơn giản; luôn có cách thay gesture (vd nút xoá bên cạnh swipe-to-delete). Hỗ trợ Voice Control, Siri/Shortcuts, AssistiveTouch, Full Keyboard Access, Pointer Control, Switch Control.
- **Lời nói:** dùng được chỉ với bàn phím; không override shortcut hệ thống.
- **Nhận thức:** thao tác đơn giản, quen thuộc. **Hạn chế UI tự đóng theo giờ**, ưu tiên đóng bằng hành động rõ ràng. Có nút điều khiển audio/video tự phát. Cẩn thận animation nhanh hoặc nhấp nháy.

---

## 8. Materials

Nguồn: https://developer.apple.com/design/human-interface-guidelines/materials (mới nhất 9/9/2025)

### 8.1 Liquid Glass

Nguồn: https://developer.apple.com/design/human-interface-guidelines/materials#Liquid-Glass · https://developer.apple.com/design/human-interface-guidelines/scroll-views#Scroll-edge-effects · https://developer.apple.com/documentation/technologyoverviews/adopting-liquid-glass · https://developer.apple.com/documentation/swiftui/glass

- Có hai loại material: **Liquid Glass** (lớp chức năng cho control và navigation) và **standard materials** (phân tách bên trong content layer).
- Liquid Glass tạo một lớp chức năng tách biệt, nổi trên nội dung, cho nội dung cuộn và lộ ra bên dưới mà control vẫn dễ đọc.
- **Không dùng Liquid Glass trong content layer**; nền app dùng standard materials. Ngoại lệ: control có phần tương tác tạm thời (slider, toggle) sẽ chuyển sang Liquid Glass khi đang được kích hoạt.
- **Dùng tiết chế:** component chuẩn tự có Liquid Glass. Chỉ áp cho control custom quan trọng nhất (`glassEffect(_:in:)`, xem "Applying Liquid Glass to custom views").
- Appearance thay đổi theo setting: người dùng có thể chọn **"preferred look" cho Liquid Glass** trong Settings; Reduce Transparency và Increase Contrast cũng làm đổi appearance.

| Variant | Đặc tính | Dùng khi |
|---|---|---|
| `regular` | Làm mờ (blur) và chỉnh độ sáng nội dung phía sau để giữ chữ dễ đọc; scroll edge effect làm mờ thêm. Đa số component hệ thống dùng variant này | Nền phía sau có thể gây khó đọc; component nhiều chữ (alert, sidebar, popover) |
| `clear` | Rất trong suốt, ưu tiên cho thấy nội dung phía sau | **Chỉ dùng trên nền nhiều hình ảnh** (ảnh, video). Nội dung sáng thì thêm lớp dim tối **35% opacity**. Không cần dim nếu nền đủ tối hoặc dùng control phát media của AVKit (đã có dim sẵn) |

- API (tài liệu developer, **chỉ từ iOS/iPadOS/macOS/tvOS/watchOS 26.0**):
  - SwiftUI: `glassEffect(_:in:)`; `Glass` (`regular`, `clear`, `identity`, `tint(_:)`, `interactive(_:)`); `GlassEffectContainer` (gộp để tối ưu và morph); button style `.glass`, `.glassProminent`.
  - UIKit: `UIGlassEffect`; `UIButton.Configuration` `glass()`, `prominentGlass()`, `clearGlass()`, `prominentClearGlass()`.
  - AppKit: `NSGlassEffectView`, `NSButton.BezelStyle.glass`.
  - Muốn giữ giao diện cũ khi build bằng SDK mới: khoá Info.plist `UIDesignRequiresCompatibility`.
- Motion: Liquid Glass phản hồi mạnh với touch, dịu hơn với trackpad (motion).
- Scroll edge effect (iOS, iPadOS, macOS): ưu tiên style `automatic` (ngoài ra có `hard`, `soft`). Chỉ dùng khi scroll view nằm sau element nổi. Mỗi view một effect; trong split view, mỗi pane một effect và cùng chiều cao (scroll-views, cập nhật 8/6/2026). API: `ScrollEdgeEffectStyle`, `UIScrollEdgeEffect.Style`, `NSScrollEdgeEffectStyle`; bar custom dùng `safeAreaBar(...)`.

### 8.2 Standard materials

Nguồn: https://developer.apple.com/design/human-interface-guidelines/materials#Standard-materials · https://developer.apple.com/documentation/swiftui/material · https://developer.apple.com/documentation/appkit/nsvisualeffectview/material-swift.enum

- Dùng blur, vibrancy, blending mode để tạo cấu trúc trong nội dung bên dưới Liquid Glass.
- Chọn material theo ngữ nghĩa và mục đích dùng, không theo màu nhìn thấy. **Luôn dùng vibrant color trên material.**
- Material dày (đục) cho tương phản tốt với chữ và chi tiết mảnh; material mỏng giúp giữ ngữ cảnh.

| Nền tảng | Material | Ghi chú |
|---|---|---|
| iOS, iPadOS (HIG) | `ultraThin`, `thin`, `regular` (mặc định), `thick` | Dùng trong content layer |
| SwiftUI `Material` (tài liệu developer) | + `ultraThick`, `bar` | HIG không có hướng dẫn riêng cho `bar`/chrome → CHƯA XÁC MINH. `Material` có từ iOS 15 / macOS 12 |
| tvOS | `ultraThin` (view full-screen, light), `thin` (overlay, light), `regular` (overlay), `thick` (overlay, dark) | |
| macOS | `NSVisualEffectView.Material`: `titlebar`, `selection`, `menu`, `popover`, `sidebar`, `headerView`, `sheet`, `windowBackground`, `hudWindow`, `fullScreenUI`, `toolTip`, `contentBackground`, `underWindowBackground`, `underPageBackground` (deprecated: `appearanceBased`, `light`, `dark`, `mediumLight`, `ultraDark`) | Tên lấy từ tài liệu AppKit; HIG chỉ nói macOS có nhiều material theo mục đích và bản vibrant của mọi system color |

### 8.3 Vibrancy (iOS, iPadOS)

Nguồn: https://developer.apple.com/design/human-interface-guidelines/materials#iOS-iPadOS

| Loại | Level (cao → thấp) | Ghi chú |
|---|---|---|
| Label | `UIVibrancyEffectStyle.label` (mặc định), `.secondaryLabel`, `.tertiaryLabel`, `.quaternaryLabel` | Không dùng quaternary trên `thin`/`ultraThin` (tương phản quá thấp) |
| Fill | `.fill` (mặc định), `.secondaryFill`, `.tertiaryFill` | Dùng được trên mọi material |
| Separator | `.separator` (một level duy nhất) | Dùng được trên mọi material |

### 8.4 macOS

Nguồn: https://developer.apple.com/design/human-interface-guidelines/materials#macOS · https://developer.apple.com/design/human-interface-guidelines/windows#macOS-window-states

- Tự quyết định chỗ nào cho vibrancy trong view và control custom; test trong nhiều bối cảnh.
- Blending mode: `behindWindow` hoặc `withinWindow` (`NSVisualEffectView.BlendingMode`).
- Cửa sổ inactive không có vibrancy (windows).

---

## 9. Dark Mode

Nguồn: https://developer.apple.com/design/human-interface-guidelines/dark-mode (mới nhất 6/8/2024)

- **Không làm setting appearance riêng trong app.** Người dùng phải chỉnh nhiều nơi và có thể nghĩ app bị lỗi.
- Phải đẹp ở cả hai mode và ở chế độ Auto (có thể đổi mode khi app đang chạy). Kiểm tra với Increase Contrast và Reduce Transparency.
- Hiếm khi: chỉ dùng dark (app xem media immersive, vd Stocks).
- Màu dark **không phải** là màu light đảo ngược: nền mờ hơn, foreground sáng hơn. Dùng semantic color. Màu custom khai báo bằng Color Set trong asset catalog với biến thể sáng và tối. Không hard-code.
- Tương phản tối thiểu 4.5:1; màu custom nên 7:1. Làm dịu nền trắng trong ảnh nội dung để không bị "phát sáng".
- Icon: dùng SF Symbols. Khi cần, làm icon riêng cho light và dark (vd thêm viền). Kiểm tra ảnh full-color ở cả hai mode.
- Dùng label color hệ thống (4 cấp) và text view hệ thống.
- **iOS/iPadOS:** nền có hai bộ, *base* (tối hơn, lùi ra sau) và *elevated* (sáng hơn, nổi lên). Hệ thống tự đổi base sang elevated cho popover, modal sheet, multitasking → nên dùng system background.
- **macOS:** desktop tinting khi chọn accent Graphite (xem 4.6).
- visionOS và watchOS không có Dark Mode.

---

## 10. Icons và SF Symbols

Nguồn: https://developer.apple.com/design/human-interface-guidelines/icons (6/2025) · https://developer.apple.com/design/human-interface-guidelines/sf-symbols (28/7/2025) · https://developer.apple.com/sf-symbols/

### 10.1 Interface icon

Nguồn: https://developer.apple.com/design/human-interface-guidelines/icons · https://developer.apple.com/design/human-interface-guidelines/menus#Icons

- Hình đơn giản, dễ nhận. Nhất quán về kích thước, mức chi tiết, nét (weight) và phối cảnh. Weight khớp với chữ bên cạnh.
- Thêm padding vào asset để căn giữa theo thị giác (optical centering).
- Không cần bản selected-state cho icon trong toolbar, tab bar, button chuẩn.
- Hình người trung tính về giới. Chỉ đưa chữ vào icon khi thật cần: phải localize, và có bản lật cho RTL.
- **Dùng vector PDF hoặc SVG.** PNG phải xuất nhiều cỡ.
- Có alt text (accessibility label).
- **Không vẽ lại phần cứng Apple.** Nếu cần thì chỉ dùng ảnh từ Apple Design Resources hoặc SF Symbol sản phẩm.
- **Standard icons** (bảng từ 9/6/2025, dùng cho menu, toolbar, button):

| Hành động | Symbol |
|---|---|
| Cut / **Copy** / **Paste** | `scissors` / `document.on.document` / `document.on.clipboard` |
| Done, Save / Cancel, Close | `checkmark` / `xmark` |
| Delete / Undo / Redo | `trash` / `arrow.uturn.backward` / `arrow.uturn.forward` |
| Compose / Duplicate / Rename | `square.and.pencil` / `plus.square.on.square` / `pencil` |
| Move to, Folder / Attach / Add / More | `folder` / `paperclip` / `plus` / `ellipsis` |
| Select / Deselect | `checkmark.circle` / `xmark` |
| Search / Find (…Replace, Next, Previous, Use Selection) / Filter | `magnifyingglass` / `text.page.badge.magnifyingglass` / `line.3.horizontal.decrease` |
| Share, Export / Print | `square.and.arrow.up` / `printer` |
| Account, User, Profile | `person.crop.circle` |
| Like / Dislike | `hand.thumbsup` / `hand.thumbsdown` |
| Alarm / Archive / Calendar | `alarm` / `archivebox` / `calendar` |
| Text formatting | `textformat.superscript`, `textformat.subscript`, `bold`, `italic`, `underline`, `text.alignleft`, `text.aligncenter`, `text.justify`, `text.alignright` |
| Layer ordering | `square.3.layers.3d.top.filled`, `square.3.layers.3d.bottom.filled`, `square.2.layers.3d.top.filled`, `square.2.layers.3d.bottom.filled` |

- Menu item icon (cập nhật 8/6/2026): dùng tiết chế và có mục đích. Trong một nhóm, hoặc mọi item có icon, hoặc không item nào có. Không có icon rõ nghĩa thì bỏ icon.
- **macOS document icon:** gồm ảnh nền, ảnh ở giữa và chữ (hệ thống tự viết hoa toàn bộ). Không đặt thứ quan trọng ở góc trên phải (góc gấp).

| Thành phần | Kích thước @1x (px) | @2x | Ghi chú |
|---|---|---|---|
| Ảnh nền (background fill) | 512, 256, 128, 32, 16 | gấp đôi (1024 … 32) | Icon có thể hiện nhỏ tới 16x16 px; bớt chi tiết ở cỡ nhỏ |
| Ảnh ở giữa (center image) | 256, 128, 32, 16 | gấp đôi | Rộng bằng ½ canvas; margin ~10%, nội dung chiếm ~80% (vd 205x205 trong 256x256) |
- **Kích thước icon cho toolbar và sidebar trên macOS:** HIG hiện chỉ nói chiều cao dòng, chữ và glyph của sidebar phụ thuộc cỡ small/medium/large (người dùng chọn ở General settings). **Không có số px → CHƯA XÁC MINH** (tra UI Kit macOS 27).

### 10.2 SF Symbols

Nguồn: https://developer.apple.com/design/human-interface-guidelines/sf-symbols · https://developer.apple.com/sf-symbols/

| Khía cạnh | Chi tiết |
|---|---|
| Rendering mode (4) | **Monochrome** (một màu cho mọi layer); **Hierarchical** (một màu, opacity khác nhau theo cấp layer); **Palette** (≥2 màu, mỗi layer một màu); **Multicolor** (màu nội tại, vd `leaf` màu xanh lá, `trash.slash` màu đỏ). Có chế độ tự động theo mode ưa dùng của symbol. Dùng system color để tự thích ứng accessibility, vibrancy, Dark Mode |
| Gradient | Từ SF Symbols 7: gradient tuyến tính sinh từ một màu gốc; dùng được với mọi mode, cả symbol custom; đẹp nhất ở cỡ lớn |
| Variable color | Thể hiện giá trị đổi theo thời gian (dung lượng, cường độ) theo ngưỡng 0–100%. Layer có thể không tham gia. **Không dùng để thể hiện chiều sâu** (dùng Hierarchical). Có thêm Variable Draw (theo trang sản phẩm) |
| Weight | 9 weight, Ultralight → Black, khớp weight của SF |
| Scale | 3 scale: small, medium (mặc định), large, tính theo cap height của SF. API: `imageScale(_:)`, `UIImage.SymbolScale`, `NSImage.SymbolConfiguration` |
| Design variant | Outline (phổ biến nhất, hợp toolbar/list), fill (nhấn mạnh; tab bar iOS và swipe action), slash (không khả dụng), enclosed (tròn/vuông, dễ đọc ở cỡ nhỏ). View thường tự chọn variant (tab bar iOS dùng fill, toolbar dùng outline). Có biến thể theo ngôn ngữ và hệ chữ |
| Animation | Appear, Disappear, Bounce, Scale, Pulse, Variable color (cumulative/iterative; open/closed loop), Replace (down-up, up-up, off-up), **Magic Replace** (mặc định cho Replace), Wiggle, Breathe, Rotate (có tuỳ chọn By Layer), **Draw On / Draw Off** (SF Symbols 7+). Dùng tiết chế, có mục đích, hợp giọng điệu app. Animation cần SF Symbols 5+ (motion) |
| Custom symbol | Xuất template rồi sửa bằng công cụ vector. Annotate màu hoặc cấp layer. Negative side margin đặt tên theo mẫu `left-margin-Regular-M`. Vẽ hình nguyên khối + erase layer để animation đúng. Dùng component library cho enclosure và badge. Có alt text. Test mọi preset animation |
| Hạn chế | **Không dùng symbol, hoặc hình dễ gây nhầm với symbol, trong app icon, logo hay bất kỳ mục đích thương hiệu nào.** Symbol thể hiện sản phẩm/tính năng Apple (đánh dấu Info trong app) chỉ được hiển thị, không được sửa |

---

## 11. App icons

Nguồn: https://developer.apple.com/design/human-interface-guidelines/app-icons (mới nhất 8/6/2026) · https://developer.apple.com/icon-composer/

| Nền tảng | Khung thiết kế | Hình sau mask | Kích thước | Kiểu | Appearance |
|---|---|---|---|---|---|
| iOS, iPadOS, macOS | Vuông | Rounded rectangle (vuông) | 1024x1024 px | Layered | Default, dark, clear light, clear dark, tinted light, tinted dark |
| tvOS | Chữ nhật ngang | Rounded rectangle (chữ nhật) | 800x480 px | Layered (parallax) | N/A |
| visionOS | Vuông | Tròn | 1024x1024 px | Layered (3D) | N/A |
| watchOS | Vuông | Tròn | 1088x1088 px | Layered | N/A |

- **Layer:** iOS/iPadOS/macOS/watchOS có 1 background layer + ≥1 foreground layer, nhận thuộc tính Liquid Glass (specular highlight, refraction, translucency). Hiệu ứng tự đổi theo cỡ và có thể khác giữa các bản OS. tvOS có 2–5 layer; visionOS có background + 1–2 layer.
- **Icon Composer:** có trong Xcode hoặc tải riêng. Dùng để đặt background (màu đặc hoặc gradient, thường không cần nhập ảnh nền), chỉnh vị trí foreground, hiệu ứng, **annotate appearance Default, Dark, Mono**, xem trước theo nhiều bản OS, rồi xuất sang Xcode. Bản 2 (2026) có: refraction theo từng layer; specular highlight kiểu mới (inside/outside/auto); **góc sáng dọc chiếu từ trên xuống**; file cũ nhập vào tự render bằng material mới; grid dùng chung cho các nền tảng; xuất bản phẳng cho marketing.
- **Quy tắc thiết kế:**
  - Mép foreground rõ, không feather. Đa dạng opacity cho có chiều sâu. Nếu nhập ảnh nền riêng thì ảnh phải full-bleed và đục.
  - Layer ưu tiên vector (SVG/PDF), chữ chuyển sang outline; mesh gradient và raster dùng PNG.
  - **Cung cấp layer vuông chưa mask** (tự mask sẵn làm hỏng highlight). Nội dung chính đặt giữa; dùng grid trong Apple Design Resources.
  - Đơn giản, ít hình; hình đặc chồng lên nhau tốt hơn đường viền. Chữ chỉ khi thiết yếu (không "Watch"/"Play"/"New"). Ưu tiên minh hoạ hơn ảnh chụp. Không chép UI hay screenshot. Tránh nét quá mảnh và góc nhọn. **Không dùng hình phần cứng Apple.**
  - Để hệ thống lo hiệu ứng: không tự thêm specular, drop shadow, bevel, blur, glow. Nhóm layer để áp hiệu ứng theo nhóm.
- **Appearance:**
  - iOS/iPadOS/macOS cho người dùng chọn default, dark, clear hoặc tinted. Variant không cung cấp thì hệ thống tự sinh.
  - Giữ đặc điểm nhận dạng như nhau ở mọi variant. Lấy icon light làm gốc cho bản dark; nền màu cho tương phản tốt nhất ở dark.
  - Alternate icon trên iOS/iPadOS phải có đủ biến thể dark, clear, tinted, và đều qua App Review.
- Icon hình dạng bất thường sẽ được hệ thống đặt lên nền mặc định (Adopting Liquid Glass). watchOS: tránh nền đen.

---

## 12. Motion

Nguồn: https://developer.apple.com/design/human-interface-guidelines/motion (mới nhất 9/9/2025)

- Component hệ thống đã có sẵn motion và tự điều chỉnh theo accessibility và cách nhập.
- Motion phải có mục đích, không thêm cho vui. **Motion là tuỳ chọn**: không phải cách duy nhất để truyền thông tin; bổ sung haptics và âm thanh.
- Feedback thực tế, khớp gesture (mở bằng kéo xuống thì không đóng bằng kéo ngang). Animation feedback ngắn gọn và chính xác.
- Không thêm motion cho tương tác lặp lại thường xuyên. **Cho phép huỷ, không bắt chờ animation.** Cân nhắc animated symbol (SF Symbols 5+).
- Game: 30–60 fps ổn định; cho chọn chế độ hiệu năng/pin.
- Reduce Motion: xem 7.3.

---

## 13. Writing

Nguồn: https://developer.apple.com/design/human-interface-guidelines/writing (mới nhất 16/12/2025) + alerts, buttons, menus, the-menu-bar, notifications, privacy, panels, segmented-controls, lists-and-tables, widgets, toolbars, settings

### 13.1 Voice và tone

Nguồn: https://developer.apple.com/design/human-interface-guidelines/writing#Getting-started

- Xác định **voice** theo đối tượng người dùng (vd app ngân hàng: tin cậy, ổn định; game: hào hứng). Lập danh sách thuật ngữ chung và dùng nhất quán.
- **Tone** đổi theo ngữ cảnh (vd phát hiện té ngã: nghiêm túc; đạt kỷ lục: vui).
- Rõ ràng, ít chữ, đọc to để kiểm tra. Viết cho mọi người: ngôn ngữ đơn giản, tránh thuật ngữ chuyên môn và từ phân biệt giới; tính trước localization.

### 13.2 Best practices

Nguồn: https://developer.apple.com/design/human-interface-guidelines/writing#Best-practices

- Thông tin quan trọng nhất đặt trước. Hướng hành động: nhãn nút và link dùng **động từ** ("Send" tốt hơn "Let's do it!"), tránh "Click here".
- Tạo language pattern nhất quán. Luồng nhiều bước: bắt đầu bằng "Get Started", giữa dùng "Continue" hoặc "Next" (chọn một, dùng nhất quán), kết thúc bằng "Done".
- Hạn chế đại từ sở hữu ("Favorites" thay vì "Your Favorites"). **Tránh "we"** ("Unable to load content" thay vì "We're having trouble…").
- Dùng đúng từ theo thiết bị: *tap* cho màn hình cảm ứng, *click* cho chuột.
- Empty state luôn có bước tiếp theo (nút hoặc link), không chứa thông tin quan trọng.
- **Error message:** đặt sát chỗ lỗi, không đổ lỗi, nói cách sửa ("Choose a password with at least 8 characters"), không dùng "oops"/"uh-oh".
- Chọn đúng kênh: notification, alert hay action sheet.
- Nhãn setting rõ ràng; mô tả tác dụng khi bật. Dẫn tới setting bằng link hoặc nút, không mô tả đường đi.
- Text field có hint/placeholder ("name@example.com"); lỗi hiện ngay cạnh field; không viết kiểu máy móc như "Invalid name".

### 13.3 Quy tắc viết hoa

Nguồn: https://developer.apple.com/design/human-interface-guidelines/writing · https://developer.apple.com/design/human-interface-guidelines/buttons#Content · https://developer.apple.com/design/human-interface-guidelines/alerts · https://developer.apple.com/design/human-interface-guidelines/menus#Labels · https://developer.apple.com/design/human-interface-guidelines/the-menu-bar · https://developer.apple.com/design/human-interface-guidelines/panels · https://developer.apple.com/design/human-interface-guidelines/segmented-controls · https://developer.apple.com/design/human-interface-guidelines/lists-and-tables · https://developer.apple.com/design/human-interface-guidelines/notifications · https://developer.apple.com/design/human-interface-guidelines/privacy · https://developer.apple.com/design/human-interface-guidelines/widgets · https://developer.apple.com/design/human-interface-guidelines/toolbars#Titles · https://developer.apple.com/design/human-interface-guidelines/settings#macOS · https://developer.apple.com/documentation/technologyoverviews/adopting-liquid-glass

HIG **không tách quy tắc viết hoa theo nền tảng**; quy tắc gắn với loại thành phần. Writing: chọn một kiểu cho mỗi loại element và dùng nhất quán (title case trang trọng hơn, sentence case thân mật hơn).

| Thành phần | Kiểu | Ghi chú |
|---|---|---|
| Nhãn button | Title-style | Nên bắt đầu bằng động từ ("Add to Cart") |
| Nút trong alert | Title-style, không dấu câu cuối | 1–2 từ; luôn dùng "Cancel" để huỷ; "OK" chỉ cho alert thông tin; tránh "Yes"/"No"; nút mặc định ở trailing hoặc trên cùng |
| Tiêu đề alert | Câu hoàn chỉnh → sentence-style + dấu câu; cụm từ → title-style, không dấu câu | ≤2 dòng; không dùng tiêu đề chung chung kiểu "Error" |
| Nội dung alert | Sentence-style, câu hoàn chỉnh | Chỉ thêm khi có giá trị |
| Menu item | Title-style | Bỏ mạo từ (a/an/the); thêm "…" khi cần nhập thêm |
| Tiêu đề menu trên menu bar | Ưu tiên một từ; nhiều từ thì title-style | |
| Tiêu đề panel | Danh từ, title-style | "Fonts", "Colors", "Inspector" |
| Segmented control | Danh từ, title-style | |
| Tiêu đề cột bảng | Danh từ, title-style, không dấu câu | |
| Section header list/form | Title-style (không còn ALL CAPS) | Theo tài liệu "Adopting Liquid Glass" |
| Tiêu đề notification | Title-style, không dấu câu | Không chèn tên app |
| Nội dung notification | Sentence case, câu hoàn chỉnh | Placeholder khi ẩn preview: sentence-style |
| Purpose string (xin quyền) | Sentence case, câu chủ động, có dấu chấm | |
| Mô tả widget | Sentence-style | |
| Push button mở cửa sổ khác (macOS) | Thêm dấu "…" ở cuối | |
| Tiêu đề window/toolbar | Dưới 15 ký tự | Không dùng tên app làm tiêu đề |
| Cửa sổ settings một pane | "*App Name* Settings" | |

---

## 14. Branding

Nguồn: https://developer.apple.com/design/human-interface-guidelines/branding (cập nhật 9/9/2026)

- Giữ voice và tone của thương hiệu trong mọi câu chữ.
- **Dùng accent color tiết chế:** hạn chế trên control. Chỉ dùng cho primary action hoặc chỉ báo trạng thái (badge chưa đọc, icon tab đang chọn). **Muốn thể hiện thương hiệu bằng màu thì đưa màu vào content layer**, nơi nó cuộn bên dưới control Liquid Glass và được kính "bắt" màu.
- Font riêng: phải dễ đọc ở mọi cỡ, hỗ trợ Bold Text và Dynamic Type. Font thương hiệu cho headline, system font cho body.
- Thể hiện thương hiệu qua component quen thuộc; nếu tuỳ biến thì giữ nguyên cỡ, vị trí và hành vi.
- Thương hiệu nhường chỗ cho nội dung. Dùng pattern chuẩn nhất quán. Không rải logo khắp app. **Không dùng launch screen để làm thương hiệu** (dùng màn hình welcome/onboarding).
- **Tuân thủ trademark của Apple:** không đưa trademark Apple vào tên app hoặc hình ảnh.

---

## 15. Privacy và Inclusion

Nguồn: https://developer.apple.com/design/human-interface-guidelines/privacy (6/2023) · https://developer.apple.com/design/human-interface-guidelines/inclusion

### 15.1 Privacy

Nguồn: https://developer.apple.com/design/human-interface-guidelines/privacy

- Phải khai báo privacy details trên App Store (App Store Connect).
- Chỉ xin dữ liệu thật sự cần; minh bạch về cách dùng; xử lý trên thiết bị khi có thể; dùng cơ chế bảo vệ của hệ thống.
- **Cần xin quyền cho:**
  - Dữ liệu cá nhân (vị trí, sức khoẻ, tài chính, danh bạ, …).
  - Nội dung người dùng (email, **tin nhắn**, lịch, danh bạ, audio/video/ảnh, …).
  - Tài nguyên được bảo vệ (**Bluetooth peripheral**, home automation, Wi-Fi, **local network**).
  - **Camera và microphone**.
  - ARKit (visionOS); advertising identifier.
- **Xin quyền khi thật sự cần**, không xin lúc mở app trừ khi app không chạy được nếu thiếu quyền.
- **Purpose string:** câu ngắn, hoàn chỉnh, chủ động, cụ thể, sentence case, có dấu chấm. Ví dụ đúng: mô tả rõ app ghi âm ban đêm để phát hiện ngáy. Ví dụ sai: "cần micro để trải nghiệm tốt hơn".
- **Màn hình trước alert (pre-alert):** chỉ một nút, tên "Continue" hoặc "Next" (không dùng "Allow"). Không có nút đóng/huỷ để né alert.
- **Tracking:** màn hình gây hiểu lầm (tặng thưởng, giả dạng alert, ảnh chụp alert, chú thích chỉ vào nút) sẽ bị App Review từ chối.
- **Location button** (iOS, iPadOS, watchOS): cấp quyền một lần; chỉ tuỳ biến được title, glyph, màu, bo góc.
- **Bảo vệ dữ liệu:** passkeys hoặc 2FA; Face ID/Touch ID/Optic ID; lưu dữ liệu nhạy cảm trong keychain; không lưu mật khẩu dạng plain text; không tự chế cơ chế xác thực.
- **macOS:** ký Developer ID khi phân phối ngoài App Store; sandbox (bắt buộc với Mac App Store); không giả định ai đang đăng nhập (fast user switching).

### 15.2 Inclusion

Nguồn: https://developer.apple.com/design/human-interface-guidelines/inclusion

- Inclusive by design: dùng sự thấu cảm; không chỉ tránh gây phản cảm mà phải chủ động chào đón.
- **Ngôn ngữ:**
  - Gọi người dùng là *you/your*, tránh "the user".
  - *We/our* chỉ dùng cho công ty hoặc phần mềm.
  - Định nghĩa thuật ngữ trước khi dùng. Tránh thành ngữ, tiếng lóng. Cân nhắc kỹ trước khi dùng hài hước.
- **Dễ tiếp cận:** UI rõ ràng; onboarding bỏ qua được.
- **Giới tính:**
  - Tránh nhắc giới tính khi không cần.
  - Symbol người trung tính giới: `person.crop.circle`, `person.3.fill`, `figure.wave`.
  - Nếu phải hỏi giới tính, có lựa chọn *nonbinary*, *self-identify*, *decline to state*.
- **Đa dạng, tránh khuôn mẫu:** thể hiện đa dạng con người; bối cảnh gần gũi; câu hỏi bảo mật dựa trên trải nghiệm phổ quát.
- **Khuyết tật:** là một dải phổ, có loại tạm thời và theo tình huống. Viết theo lối người trước, khuyết tật sau (people-first).
- **Ngôn ngữ và vùng:** i18n và localization; SF Symbols hỗ trợ glyph theo ngôn ngữ và RTL; nghĩa của màu khác nhau theo văn hoá.

---

## 16. Giấy phép: SF font, SF Symbols, Apple Design Resources trên nền tảng không phải Apple

Nguồn:
- https://developer.apple.com/support/downloads/terms/apple-design-resources/Apple-Design-Resources-License-20230621-English.pdf
- https://developer.apple.com/design/human-interface-guidelines/sf-symbols
- https://developer.apple.com/fonts/
- https://developer.apple.com/forums/thread/739523
- https://developer.apple.com/forums/thread/727961

| Tài nguyên | Hạn chế (diễn giải) | Mức xác minh |
|---|---|---|
| **Apple Design Resources** (UI kit, template, …) | Chỉ để làm mock-up UI cho phần mềm chạy **duy nhất** trên macOS, iOS, watchOS, tvOS, visionOS. **Cấm** dùng làm mock-up cho phần mềm chạy trên hệ điều hành không phải Apple. Cấm nhúng vào phần mềm hay sản phẩm. Cấm dùng tạo tài liệu, artwork, nội dung web ngoài phạm vi cho phép. Phải báo các hạn chế này cho bên nhận mock-up | **Đã xác minh**: PDF LYL142, ngày 06/21/2023, trên developer.apple.com. Giấy phép này cũng ghi font San Francisco có giấy phép riêng |
| **Font San Francisco** (SF Pro, SF Compact, SF Mono, …); New York tải riêng (`NY.dmg`), giấy phép của nó CHƯA XÁC MINH | Giấy phép riêng nằm trong .dmg. Theo nội dung được dẫn lại trên Apple Developer Forums: chỉ để làm mock-up UI cho phần mềm chạy trên iOS, iPadOS, macOS, tvOS; không cho hệ điều hành khác; không nhúng; không dùng cho tài liệu, artwork, web; yêu cầu là Apple Developer đã đăng ký | Văn bản trong .dmg **chưa đọc trực tiếp** (không tải file) → **CHƯA XÁC MINH** bản hiện hành |
| **SF Symbols** | HIG yêu cầu tuân thủ terms và nêu rõ: **cấm dùng symbol, hoặc hình dễ gây nhầm, trong app icon, logo, mục đích thương hiệu**. Symbol về sản phẩm Apple không được sửa. Giấy phép trong app (được dẫn lại trên forum, 10/2023): chỉ để làm UI cho phần mềm chạy trên iOS, iPadOS, macOS, tvOS, watchOS | Phần HIG **đã xác minh**; phạm vi nền tảng trong giấy phép **CHƯA XÁC MINH** bản 2026 |
| Font hệ thống trên nền tảng Apple | Gọi qua API (`Font.Design`), không nhúng file font vào app | HIG typography, đã xác minh |

**Kết luận cho app Android:** không dùng SF Pro, SF Compact, SF Mono, New York hay SF Symbols. Không làm mock-up Android từ UI Kit của Apple. Nên dùng chung **token ngữ nghĩa** (vai trò màu, thang khoảng cách, vai trò chữ) giữa các nền tảng, không dùng chung tài sản của Apple. Gợi ý thay thế (ngoài phạm vi HIG, chưa kiểm giấy phép trong phiên này): font hệ thống Android (Roboto hoặc font OEM) và bộ Material Symbols.

---

## 17. Hàm ý cho design system HandLive

Nguồn: tổng hợp từ các mục trên, đối chiếu `plans/20260924-apple-hig-design-system/plan.md` (DS1–DS3) và `CLAUDE.md`.

1. **Màu:**
   - Dùng semantic/dynamic color cho nền, chữ, separator.
   - Brand color custom cần 4 biến thể: light, dark, IC light, IC dark.
   - Không hard-code giá trị system color.
   - Brand color đặt ở content layer. Chỉ một primary action được tô màu trên Liquid Glass.
2. **Màu mệnh Hỏa (DS3) có thể đụng nghĩa hệ thống:**
   - Đỏ là màu của role destructive và badge.
   - Cặp đỏ–xanh lá khó phân biệt với người mù màu.
   - Nếu accent là đỏ hoặc hồng, cần cách phân biệt thêm cho hành động xoá (icon, nhãn chữ).
   - Nếu dùng màu làm chữ nhỏ trên nền sáng thì nên lấy biến thể IC (theo bảng tự tính, ≈4.5:1).
3. **Liquid Glass và OS cũ:**
   - Liquid Glass chỉ có từ OS 26.
   - Với macOS 13–15 và iOS 16–18, dùng standard materials (`Material`, `NSVisualEffectView`) làm phương án dự phòng.
   - Tránh tự vẽ nền cho bar.
4. **Menu bar macOS:**
   - Dùng `MenuBarExtra` (macOS 13+) với template symbol; menu bar cao 24 pt.
   - HIG ưu tiên mở **menu**. Popover chỉ hợp lý khi chức năng phức tạp (lịch sử clipboard, SMS).
   - Để người dùng bật/tắt extra; có đường vào khác (cửa sổ app, Dock menu).
5. **Panel cuộc gọi nổi (Phase 3):** HIG yêu cầu panel ẩn khi app inactive và có title bar. Điều này mâu thuẫn với cuộc gọi đến khi app không active. Tránh UI tự đóng theo giờ (accessibility). Xem xét dùng notification loại communication hoặc Time Sensitive.
6. **Notification SMS/cuộc gọi:**
   - Dùng loại *communication* (avatar người gửi, không chèn tên app; cần SiriKit intent).
   - Loại noncommunication dùng interruption level Passive, Active, Time Sensitive hoặc Critical (Critical cần entitlement).
   - Nguồn: https://developer.apple.com/design/human-interface-guidelines/managing-notifications
7. **Icon:**
   - Dùng standard icon cho clipboard (`document.on.document` để copy, `document.on.clipboard` để paste).
   - Không dùng SF Symbol trong app icon hay logo.
   - Không vẽ phần cứng Apple.
8. **App icon:** làm bằng Icon Composer, nhiều lớp; đủ 6 appearance trên iOS/iPadOS/macOS; layer vuông chưa mask.
9. **Chữ:**
   - iOS dùng text style Dynamic Type, phóng được ≥200%.
   - macOS dùng bảng cố định (Body 13 pt).
   - UI tiếng Việt: xem câu hỏi về viết hoa ở cuối.
10. **Accessibility:**
    - Control: iOS ≥44 pt, macOS ≥28 pt (tối thiểu 20 pt).
    - Tương phản: 4.5:1, hoặc 3:1 cho chữ ≥18 pt hay chữ đậm.
    - Tôn trọng Reduce Motion, Reduce Transparency, Increase Contrast.
    - Có nhãn VoiceOver.
11. **Privacy:** xin quyền đúng lúc cần: Bluetooth (HFP), Local Network (mDNS/WebSocket), Notifications, Camera và Mic (Phase 5), Contacts (chỉ khi tra tên người gửi SMS bằng danh bạ trên máy Apple). Purpose string theo mục 15.1. Màn hình pre-alert chỉ có một nút "Continue".
12. **iOS:** app phải resize được và dùng size class; component chuẩn sẽ tự thích ứng iPhone Duo (bar dọc, reserved regions).
13. **Dark Mode:** không làm công tắc giao diện riêng trong app.

---

## Câu hỏi chưa giải quyết

Nguồn: các mục 2.1, 4.4, 6.2, 6.3, 6.4, 13.3, 16, 17 của báo cáo này.

1. Tên chính thức của bản SF Symbols hiện hành là "SF Symbols 8" (What's new 8/6/2026) hay "SF Symbols 27" (nút tải `SF-Symbols-27.dmg`)?
2. Yêu cầu hệ điều hành cho Icon Composer 2: macOS Tahoe 26.4+ (trang sản phẩm) hay macOS Sequoia+ (trang Resources)?
3. Margin, safe area, kích thước màn hình và kích thước icon cho toolbar, sidebar, tab bar đã bị gỡ khỏi HIG. Có chấp nhận lấy từ UI Kit Figma macOS 27 / iOS 27 không? Việc dùng UI Kit bị ràng buộc bởi giấy phép Apple Design Resources, chỉ cho mock-up của app Apple.
4. Chưa đọc giấy phép SF Pro và SF Symbols bản hiện hành (nằm trong .dmg). Việc này cần tải file; chưa được phép tải.
5. Giá trị RGBA của semantic color (label, fill, background, separator) và của `systemBackground`: HIG không công bố. Lấy từ UI Kit hay đọc lúc chạy?
6. App macOS chỉ sống ở menu bar mâu thuẫn với các hướng dẫn "để người dùng quyết định có hiện extra", "menu thay vì popover" và "có đường vào khác". Chốt UX nào: có thêm cửa sổ app hoặc Dock icon không?
7. Panel cuộc gọi nổi mâu thuẫn với hướng dẫn "ẩn panel khi app inactive". Chấp nhận lệch HIG hay đổi sang notification kèm cửa sổ riêng?
8. Quy tắc viết hoa của HIG dựa trên Apple Style Guide tiếng Anh (title-style). UI tiếng Việt nên dùng sentence case cho mọi thành phần hay mô phỏng title-style?
9. Brand color theo DS3 (đỏ, cam, hồng, tím, xanh lá) nên chọn trùng system color (để có sẵn 4 biến thể) hay dùng màu custom (tự định nghĩa đủ 4 biến thể)? Đặc biệt đỏ, vì trùng role destructive.
10. HIG không đưa số radius cho concentric shape. Trên OS < 26 (không có `ConcentricRectangle`), dùng radius cố định bao nhiêu?
