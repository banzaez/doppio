import SwiftUI
import AppKit

/// Вспомогательное представление для отслеживания абсолютных экранных координат иконки в строке меню
struct StatusItemFrameTrackerView: NSViewRepresentable {
    func makeNSView(context: Context) -> TrackerNSView {
        TrackerNSView()
    }

    func updateNSView(_ nsView: TrackerNSView, context: Context) {
        nsView.updateFrame()
    }

    final class TrackerNSView: NSView {
        override func viewDidMoveToWindow() {
            super.viewDidMoveToWindow()
            updateFrame()
        }

        override func layout() {
            super.layout()
            updateFrame()
        }

        func updateFrame() {
            guard let window = self.window else { return }
            QuickClickMonitor.shared.statusItemScreenFrame = window.frame
        }
    }
}
