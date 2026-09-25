import SwiftUI

/// Ứng dụng menu bar HandLive (placeholder Phase 0). Biểu tượng thanh menu mở menu, không popover (C19).
/// Tính năng (kết nối, bảng nhớ tạm…) thêm từ Phase 1.
@main
struct HandLiveMacApp: App {
    var body: some Scene {
        MenuBarExtra("HandLive", systemImage: "iphone") {
            Text("Mất kết nối")
            Divider()
            Button("Thoát HandLive") {
                NSApplication.shared.terminate(nil)
            }
            .keyboardShortcut("q")
        }
        .menuBarExtraStyle(.menu)
    }
}
