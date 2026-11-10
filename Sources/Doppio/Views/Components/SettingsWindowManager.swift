import SwiftUI
import AppKit

/// Менеджер нативного окна настроек macOS для выпадающего меню Doppio
@MainActor
public final class SettingsWindowManager {
    public static let shared = SettingsWindowManager()

    private var windowController: NSWindowController?

    private init() {}

    public func show(state: DoppioState) {
        if let controller = windowController, let window = controller.window {
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        let container = SettingsWindowContainer(state: state)
        let hostingController = NSHostingController(rootView: container)

        let window = NSWindow(contentViewController: hostingController)
        window.title = state.l10n.settingsTitle
        window.styleMask = [.titled, .closable, .miniaturizable]
        window.titlebarAppearsTransparent = false
        window.isReleasedWhenClosed = false
        window.setContentSize(NSSize(width: 360, height: 690))
        window.center()

        let controller = NSWindowController(window: window)
        self.windowController = controller

        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}

/// Контейнер экрана настроек для отображения в стандартном окне macOS
public struct SettingsWindowContainer: View {
    @Bindable var state: DoppioState

    public init(state: DoppioState) {
        self.state = state
    }

    public var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            SettingsView(state: state, showsHeader: false)
                .padding(.horizontal, 18)
                .padding(.vertical, 16)
                .frame(width: 360)
        }
        .frame(width: 360, height: 690)
    }
}
