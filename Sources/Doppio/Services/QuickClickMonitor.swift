import AppKit
import Foundation
import os

/// Протокол монитора быстрых нажатий на иконку в строке меню
@MainActor
public protocol QuickClickMonitoring: AnyObject {
    var isEnabled: Bool { get set }
    var onQuickToggle: (() -> Void)? { get set }
    func startMonitoring()
    func stopMonitoring()
}

/// Монитор быстрых нажатий на иконку в строке меню (Option-Click / Right-Click)
@MainActor
public final class QuickClickMonitor: QuickClickMonitoring {
    public static let shared = QuickClickMonitor()

    private let logger = Logger(subsystem: "com.doppio.app", category: "QuickClickMonitor")
    private var eventMonitor: Any?

    /// Экранные координаты кнопки Doppio в строке меню
    public var statusItemScreenFrame: NSRect = .zero

    /// Флаг включения опции быстрого переключения (автоматически включает/выключает перехват событий)
    public var isEnabled: Bool = true {
        didSet {
            if isEnabled {
                startMonitoring()
            } else {
                stopMonitoring()
            }
        }
    }

    /// Действие быстрого переключения
    public var onQuickToggle: (() -> Void)?

    private init() {}

    isolated deinit {
        stopMonitoring()
    }

    /// Запуск локального монитора событий мыши (только когда функция активна)
    public func startMonitoring() {
        guard isEnabled, eventMonitor == nil else { return }

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

                // Закрываем поповер через мост управления окном
                Task { @MainActor in
                    WindowAutoResizerBridge.shared.closeWindow()
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
            logger.info("Монитор быстрых кликов остановлен")
        }
    }
}
