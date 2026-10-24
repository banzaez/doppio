import AppKit
import Foundation
import os

/// Монитор быстрых нажатий на иконку в строке меню (Option-Click / Right-Click)
@MainActor
public final class QuickClickMonitor {
    public static let shared = QuickClickMonitor()

    private let logger = Logger(subsystem: "com.doppio.app", category: "QuickClickMonitor")
    private var eventMonitor: Any?

    /// Экранные координаты кнопки Doppio в строке меню
    public var statusItemScreenFrame: NSRect = .zero

    /// Флаг включения опции быстрого переключения
    public var isEnabled: Bool = true

    /// Действие быстрого переключения
    public var onQuickToggle: (() -> Void)?

    private init() {}

    isolated deinit {
        if let monitor = eventMonitor {
            NSEvent.removeMonitor(monitor)
        }
    }

    /// Запуск локального монитора событий мыши
    public func startMonitoring() {
        guard eventMonitor == nil else { return }

        eventMonitor = NSEvent.addLocalMonitorForEvents(
            matching: [.leftMouseDown, .rightMouseDown]
        ) { [weak self] event in
            guard let self = self, self.isEnabled else { return event }

            let mouseLocation = NSEvent.mouseLocation
            let frame = self.statusItemScreenFrame

            // Проверяем, произошел ли клик внутри области иконки Doppio
            guard frame != .zero, frame.contains(mouseLocation) else {
                return event
            }

            let isOptionHeld = event.modifierFlags.contains(.option)
            let isRightClick = event.type == .rightMouseDown

            if isOptionHeld || isRightClick {
                self.logger.info("Обнаружен быстрый клик (Option: \(isOptionHeld), RightClick: \(isRightClick))")
                self.onQuickToggle?()

                // Закрываем возможно открывшийся поповер MenuBarExtra
                DispatchQueue.main.async {
                    for window in NSApplication.shared.windows {
                        let className = window.className
                        if className.contains("Popover") || className.contains("MenuBarExtra") {
                            window.orderOut(nil)
                        }
                    }
                }

                // Поглощаем событие, чтобы стандартный клик не разворачивал окно
                return nil
            }

            return event
        }

        logger.info("Монитор быстрых кликов запущен")
    }

    /// Остановка монитора событий
    public func stopMonitoring() {
        if let monitor = eventMonitor {
            NSEvent.removeMonitor(monitor)
            eventMonitor = nil
        }
    }
}
