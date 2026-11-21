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
            window.title = state.l10n.settingsTitle
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        let container = SettingsWindowContainer(state: state)
        let hostingController = NSHostingController(rootView: container)
        hostingController.sizingOptions = [.preferredContentSize]

        let window = NSWindow(contentViewController: hostingController)
        window.title = state.l10n.settingsTitle
        window.styleMask = [.titled, .closable, .miniaturizable]
        window.titlebarAppearsTransparent = true
        window.isMovableByWindowBackground = true
        window.isReleasedWhenClosed = false
        let initialSize = hostingController.sizeThatFits(in: CGSize(width: 440, height: CGFloat.greatestFiniteMagnitude))
        window.setContentSize(NSSize(width: 440, height: max(260, initialSize.height)))
        window.center()

        let controller = NSWindowController(window: window)
        self.windowController = controller

        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    public func updateTitle(_ title: String) {
        windowController?.window?.title = title
    }
}

/// Контейнер экрана настроек для отображения в стиле macOS Liquid Glass с адаптивной высотой
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

            SettingsView(state: state)
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 18)
        }
        .frame(width: 440)
        .fixedSize(horizontal: false, vertical: true)
        .onChange(of: state.language) { _, _ in
            SettingsWindowManager.shared.updateTitle(state.l10n.settingsTitle)
        }
    }
}
