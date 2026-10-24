import SwiftUI
import AppKit

/// Автоматический адаптер размера окна MenuBarExtra под размер содержимого SwiftUI
struct WindowAutoResizer: NSViewRepresentable {
    func makeNSView(context: Context) -> ResizerNSView {
        ResizerNSView()
    }

    func updateNSView(_ nsView: ResizerNSView, context: Context) {
        nsView.scheduleResize()
    }
}

final class ResizerNSView: NSView {
    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        scheduleResize()
    }

    func scheduleResize() {
        // Выполняем в следующем цикле runloop для завершения лейаута SwiftUI
        DispatchQueue.main.async { [weak self] in
            guard let self = self,
                  let window = self.window,
                  let contentView = window.contentView else {
                return
            }

            let fittingSize = contentView.fittingSize
            guard fittingSize.height > 80, fittingSize.width > 100 else {
                return
            }

            let currentFrame = window.frame
            let heightDifference = fittingSize.height - currentFrame.height

            // Если размер изменился более чем на 1px
            if abs(heightDifference) > 1.0 {
                var newFrame = currentFrame
                // Корректируем origin.y, так как в системе координат macOS 0 внизу
                // Это фиксирует верхнюю кромку окна прямо под статус-баром
                newFrame.origin.y -= heightDifference
                newFrame.size.height = fittingSize.height
                newFrame.size.width = fittingSize.width

                NSAnimationContext.runAnimationGroup { context in
                    context.duration = 0.2
                    context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
                    window.animator().setFrame(newFrame, display: true)
                }
            }
        }
    }
}
