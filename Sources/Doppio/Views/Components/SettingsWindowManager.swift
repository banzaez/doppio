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
        window.titlebarAppearsTransparent = true
        window.isMovableByWindowBackground = true
        window.isReleasedWhenClosed = false
        window.setContentSize(NSSize(width: 360, height: 355))
        window.center()

        let controller = NSWindowController(window: window)
        self.windowController = controller

        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}

/// Контейнер экрана настроек для отображения в стиле macOS Liquid Glass с фиксированным размером
public struct SettingsWindowContainer: View {
    @Bindable var state: DoppioState

    public init(state: DoppioState) {
        self.state = state
    }

    public var body: some View {
        ZStack {
            // Нативное системное стекло с размытием фона за окном
            VisualEffectBackground(material: .underWindowBackground, blendingMode: .behindWindow)
                .ignoresSafeArea()

            SettingsView(state: state, showsHeader: false)
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 14)
        }
        .frame(width: 360, height: 355)
    }
}
