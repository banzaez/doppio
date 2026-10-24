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

/// Мост управления адаптивным размером окна поповера строки меню
@MainActor
final class WindowAutoResizerBridge {
    static let shared = WindowAutoResizerBridge()

    private weak var currentWindow: NSWindow?
    private var lastTargetHeight: CGFloat = 0

    private init() {}

    func register(window: NSWindow) {
        self.currentWindow = window
        if lastTargetHeight > 80 {
            applyResize(toHeight: lastTargetHeight)
        }
    }

    func resizeWindow(toHeight targetHeight: CGFloat) {
        self.lastTargetHeight = targetHeight
        applyResize(toHeight: targetHeight)
    }

    private func applyResize(toHeight targetHeight: CGFloat) {
        guard let window = currentWindow, targetHeight > 80 else { return }

        let currentFrame = window.frame
        let heightDifference = targetHeight - currentFrame.height

        // Выполняем анимацию изменения размера, если разница ощутима (> 1pt)
        if abs(heightDifference) > 1.0 {
            var newFrame = currentFrame
            // В macOS y = 0 находится внизу экрана.
            // Чтобы верхняя кромка окна оставалась зафиксирована прямо под статус-баром,
            // корректируем origin.y на разницу высоты:
            newFrame.origin.y -= heightDifference
            newFrame.size.height = targetHeight
            newFrame.size.width = max(currentFrame.width, 320)

            NSAnimationContext.runAnimationGroup { context in
                context.duration = 0.22
                context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
                window.animator().setFrame(newFrame, display: true)
            }
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
        // Предотвращаем автоматический захват фокуса текстовым полем при открытии поповера
        DispatchQueue.main.async {
            window.makeFirstResponder(nil)
        }
    }
}
