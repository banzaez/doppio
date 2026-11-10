import SwiftUI
import AppKit

/// Ключ предпочтения для точного динамического замера высоты содержимого SwiftUI
struct PopoverContentHeightKey: PreferenceKey {
    static let defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        let next = nextValue()
        if next > 0 {
            value = next
        }
    }
}

/// Мост управления адаптивным размером окна поповера строки меню (без скачков и выхода за границы экрана)
@MainActor
final class WindowAutoResizerBridge {
    static let shared = WindowAutoResizerBridge()

    private weak var currentWindow: NSWindow?
    private var lastTargetHeight: CGFloat = 0
    private var notificationTokens: [NSObjectProtocol] = []

    var onWindowClosed: (@MainActor () -> Void)?
    var onWindowOpened: (@MainActor () -> Void)?

    private init() {}

    func register(window: NSWindow) {
        if self.currentWindow === window {
            return
        }
        removeObservers()
        self.currentWindow = window
        window.isOpaque = false
        window.backgroundColor = .clear
        window.hasShadow = true
        window.invalidateShadow()

        let center = NotificationCenter.default

        let resignToken = center.addObserver(
            forName: NSWindow.didResignKeyNotification,
            object: window,
            queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated {
                self?.onWindowClosed?()
            }
        }

        let occlusionToken = center.addObserver(
            forName: NSWindow.didChangeOcclusionStateNotification,
            object: window,
            queue: .main
        ) { [weak self, weak window] _ in
            MainActor.assumeIsolated {
                guard let window = window else { return }
                if !window.occlusionState.contains(.visible) {
                    self?.onWindowClosed?()
                } else if window.isKeyWindow {
                    self?.onWindowOpened?()
                }
            }
        }

        let becomeKeyToken = center.addObserver(
            forName: NSWindow.didBecomeKeyNotification,
            object: window,
            queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated {
                self?.onWindowOpened?()
            }
        }

        notificationTokens = [resignToken, occlusionToken, becomeKeyToken]

        if lastTargetHeight > 80 {
            applyResize(toHeight: lastTargetHeight, animated: false)
        }
    }

    private func removeObservers() {
        for token in notificationTokens {
            NotificationCenter.default.removeObserver(token)
        }
        notificationTokens.removeAll()
    }

    func resizeWindow(toHeight targetHeight: CGFloat) {
        let roundedHeight = ceil(targetHeight)
        guard abs(roundedHeight - lastTargetHeight) >= 1.0 else { return }
        self.lastTargetHeight = roundedHeight
        applyResize(toHeight: roundedHeight, animated: true)
    }

    func closeWindow() {
        onWindowClosed?()
        if let window = currentWindow {
            window.orderOut(nil)
        } else {
            for window in NSApplication.shared.windows where window.level == .popUpMenu || window.level == .statusBar {
                window.orderOut(nil)
            }
        }
    }

    private func applyResize(toHeight rawHeight: CGFloat, animated: Bool) {
        guard let window = currentWindow, rawHeight > 80 else { return }

        let maxAllowedHeight = (window.screen ?? NSScreen.main).map { $0.visibleFrame.height - 24 } ?? 720
        let targetHeight = min(rawHeight, maxAllowedHeight)

        let currentFrame = window.frame
        let heightDifference = targetHeight - currentFrame.height

        guard abs(heightDifference) >= 1.0 else { return }

        var newFrame = currentFrame
        // В macOS y = 0 находится внизу экрана.
        // Чтобы верхняя кромка окна оставалась строго зафиксирована под статус-баром,
        // смещаем origin.y ровно на разницу высоты:
        newFrame.origin.y -= heightDifference
        newFrame.size.height = targetHeight
        newFrame.size.width = 320

        if animated && window.isVisible {
            NSAnimationContext.runAnimationGroup({ context in
                context.duration = 0.18
                context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
                window.animator().setFrame(newFrame, display: true)
            }, completionHandler: {
                MainActor.assumeIsolated {
                    window.invalidateShadow()
                }
            })
        } else {
            window.setFrame(newFrame, display: true)
            window.invalidateShadow()
        }
    }
}

/// NSViewRepresentable для отслеживания родительского окна MenuBarExtra
struct WindowAutoResizer: NSViewRepresentable {
    func makeNSView(context: Context) -> ResizerNSView {
        ResizerNSView()
    }

    func updateNSView(_ nsView: ResizerNSView, context: Context) {
        nsView.syncWindow()
    }
}

final class ResizerNSView: NSView {
    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        syncWindow()
    }

    func syncWindow() {
        guard let window = self.window else { return }
        WindowAutoResizerBridge.shared.register(window: window)
    }
}
