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
        window.setContentSize(NSSize(width: 360, height: 320))
        window.center()

        let controller = NSWindowController(window: window)
        self.windowController = controller

        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    /// Плавная анимация высоты окна под активную вкладку без пустых полей
    public func adjustWindowHeight(to targetContentHeight: CGFloat) {
        guard let window = windowController?.window else { return }
        let currentFrame = window.frame
        let titlebarHeight = window.frame.height - window.contentLayoutRect.height
        let targetTotalHeight = max(200, targetContentHeight + titlebarHeight)

        if abs(currentFrame.height - targetTotalHeight) > 3 {
            let newY = currentFrame.origin.y + (currentFrame.height - targetTotalHeight)
            let newFrame = NSRect(
                x: currentFrame.origin.x,
                y: newY,
                width: currentFrame.width,
                height: targetTotalHeight
            )
            NSAnimationContext.runAnimationGroup { context in
                context.duration = 0.22
                context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
                window.animator().setFrame(newFrame, display: true)
            }
        }
    }
}

/// Контейнер экрана настроек для отображения в стиле macOS Liquid Glass
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
        .frame(width: 360)
        .onPreferenceChange(SettingsContentHeightKey.self) { newHeight in
            guard newHeight > 50 else { return }
            // 8 pt top + 14 pt bottom + 26 pt tab bar + 10 pt spacing = ~58 pt overhead
            SettingsWindowManager.shared.adjustWindowHeight(to: newHeight + 58)
        }
    }
}
