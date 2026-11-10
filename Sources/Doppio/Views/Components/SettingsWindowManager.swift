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
        window.styleMask = [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView]
        window.titlebarAppearsTransparent = true
        window.titleVisibility = .hidden
        window.isOpaque = false
        window.backgroundColor = .clear
        window.hasShadow = true
        window.isMovableByWindowBackground = true
        window.isReleasedWhenClosed = false
        window.minSize = NSSize(width: 360, height: 320)
        window.setContentSize(NSSize(width: 380, height: 390))
        window.center()

        let controller = NSWindowController(window: window)
        self.windowController = controller

        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}

/// Контейнер экрана настроек для отображения в стиле macOS 27 Liquid Glass
public struct SettingsWindowContainer: View {
    @Bindable var state: DoppioState

    public init(state: DoppioState) {
        self.state = state
    }

    public var body: some View {
        ZStack {
            // Нативное системное стекло Control Center (Liquid Glass) с размытием фона за окном
            VisualEffectBackground(material: .popover, blendingMode: .behindWindow)
                .ignoresSafeArea()

            // Спекулярный стеклянный градиент по контуру окна macOS 27
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.35),
                            Color.white.opacity(0.12),
                            Color.primary.opacity(0.08)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 0.75
                )
                .ignoresSafeArea()
                .allowsHitTesting(false)

            VStack(spacing: 0) {
                // Интегрированная стеклянная шапка с заголовком и отступом под светофор кнопок macOS
                HStack {
                    Spacer()
                        .frame(width: 60)

                    Text(state.l10n.settingsTitle)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Color.primary)
                        .lineLimit(1)

                    Spacer()
                        .frame(width: 60)
                }
                .frame(height: 28)
                .padding(.top, 8)
                .padding(.bottom, 6)

                SettingsView(state: state, showsHeader: false)
                    .padding(.horizontal, 18)
                    .padding(.bottom, 16)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .frame(minWidth: 360, minHeight: 320)
    }
}
