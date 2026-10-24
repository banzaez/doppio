import SwiftUI
import AppKit

/// Точка входа в приложение Doppio (SwiftUI 2026 App Lifecycle)
@main
struct DoppioApp: App {
    @State private var state = DoppioState()

    init() {
        // Запуск как вспомогательного агента строки меню (без иконки в Dock)
        NSApplication.shared.setActivationPolicy(.accessory)
    }

    var body: some Scene {
        MenuBarExtra {
            DoppioPopoverView(state: state)
        } label: {
            MenuBarLabelView(state: state)
        }
        .menuBarExtraStyle(.window)
    }
}
