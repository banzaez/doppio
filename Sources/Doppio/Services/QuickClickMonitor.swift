import AppKit
import Foundation
import os

/// Протокол монитора нажатий на иконку в строке меню
@MainActor
public protocol QuickClickMonitoring: AnyObject {
    var isEnabled: Bool { get set }
    var statusItemScreenFrame: NSRect { get set }
    var onQuickToggle: (() -> Void)? { get set }
    func startMonitoring()
    func stopMonitoring()
}

extension QuickClickMonitoring {
    public var statusItemScreenFrame: NSRect {
        get { .zero }
        set {}
    }
}

/// Монитор кликов по иконке в строке меню:
/// - Правый клик (Right-Click / Control-Click) открывает/закрывает окно MenuBarExtra точно так же, как левый клик
/// - Option-клик (⌥ + Left-Click) мгновенно переключает режим бодрствования без открытия меню (если включено)
@MainActor
public final class QuickClickMonitor: QuickClickMonitoring {
    public static let shared = QuickClickMonitor()

    private let logger = Logger(subsystem: "com.doppio.app", category: "QuickClickMonitor")
    private var localEventMonitor: Any?
    private var globalEventMonitor: Any?
    private var lastActionTime: TimeInterval = 0

    /// Дополнительные экранные координаты кнопки Doppio (используются как fallback и в тестах)
    public var statusItemScreenFrame: NSRect = .zero

    /// Флаг включения быстрого переключения через ⌥-клик (Option-Click)
    public var isEnabled: Bool = true

    /// Действие быстрого переключения (при ⌥-клике)
    public var onQuickToggle: (() -> Void)?

    private init() {
        startMonitoring()
    }

    isolated deinit {
        stopMonitoring()
    }

    /// Запуск мониторов событий мыши для иконки в строке меню
    public func startMonitoring() {
        guard localEventMonitor == nil else { return }

        localEventMonitor = NSEvent.addLocalMonitorForEvents(
            matching: [.leftMouseDown, .rightMouseDown, .rightMouseUp]
        ) { [weak self] event in
            guard let self = self else { return event }
            return self.handleMouseEvent(event) ? nil : event
        }

        globalEventMonitor = NSEvent.addGlobalMonitorForEvents(
            matching: [.rightMouseDown, .leftMouseDown]
        ) { [weak self] event in
            // Быстрая фильтрация до создания Task для соблюдения Zero-Idle CPU
            let flags = event.modifierFlags
            let isRightOrCtrl = event.type == .rightMouseDown || (event.type == .leftMouseDown && flags.contains(.control))
            let isOptionLeft = event.type == .leftMouseDown && flags.contains(.option)
            guard isRightOrCtrl || isOptionLeft else { return }

            Task { @MainActor [weak self] in
                _ = self?.handleMouseEvent(event)
            }
        }

        logger.info("Монитор кликов строки меню запущен")
    }

    /// Остановка мониторов событий
    public func stopMonitoring() {
        if let local = localEventMonitor {
            NSEvent.removeMonitor(local)
            localEventMonitor = nil
        }
        if let global = globalEventMonitor {
            NSEvent.removeMonitor(global)
            globalEventMonitor = nil
        }
    }

    // MARK: - Обработка событий мыши

    private func handleMouseEvent(_ event: NSEvent) -> Bool {
        guard isEventInsideStatusItem(event) else {
            return false
        }

        // Игнорируем отпускание правой кнопки мыши над иконкой
        if event.type == .rightMouseUp {
            return true
        }

        let flags = event.modifierFlags
        let isRightOrCtrl = event.type == .rightMouseDown || (event.type == .leftMouseDown && flags.contains(.control))

        // 1. Правый клик (или Control + клик) -> открываем/закрываем меню как по левой кнопке
        if isRightOrCtrl {
            toggleMenuBarWindowIfNeeded()
            return true
        }

        // 2. Option + левый клик (⌥-клик) -> быстрое переключение бодрствования без открытия меню
        if isEnabled, event.type == .leftMouseDown, flags.contains(.option) {
            triggerQuickToggleIfNeeded()
            return true
        }

        return false
    }

    private func canPerformDebouncedAction() -> Bool {
        let now = ProcessInfo.processInfo.systemUptime
        guard now - lastActionTime > 0.15 else { return false }
        lastActionTime = now
        return true
    }

    private func toggleMenuBarWindowIfNeeded() {
        guard canPerformDebouncedAction(),
              let statusItem = findMenuBarExtraStatusItem() else { return }

        let endSel = NSSelectorFromString("_endExpandedInterfaceSession:animate:")
        let reqSel = NSSelectorFromString("_requestExpandedInterfaceSession")

        if let session = safeObject(from: statusItem, selectorName: "expandedInterfaceSession"),
           statusItem.responds(to: endSel) {
            _ = statusItem.perform(endSel, with: session, with: nil)
            logger.info("Окно меню закрыто по правому клику")
        } else if statusItem.responds(to: reqSel) {
            _ = statusItem.perform(reqSel)
            logger.info("Окно меню открыто по правому клику")
        } else if let button = statusItem.button {
            button.performClick(nil)
        }
    }

    private func triggerQuickToggleIfNeeded() {
        guard canPerformDebouncedAction() else { return }
        logger.info("Быстрое переключение по ⌥-клику")
        onQuickToggle?()
    }

    /// Безопасное получение свойства ObjC-объекта без риска NSUnknownKeyException
    private func safeObject(from target: NSObject, selectorName: String) -> AnyObject? {
        let selector = NSSelectorFromString(selectorName)
        guard target.responds(to: selector) else { return nil }
        return target.perform(selector)?.takeUnretainedValue()
    }

    /// Находит системный экземпляр NSStatusItem (NSSceneStatusItem), принадлежащий MenuBarExtra
    private func findMenuBarExtraStatusItem() -> NSStatusItem? {
        var fallbackItem: NSStatusItem?
        for window in NSApplication.shared.windows where window.frame.origin.y >= 0 {
            let className = String(describing: type(of: window))
            guard className.contains("StatusBar"),
                  let statusItem = safeObject(from: window, selectorName: "statusItem") as? NSStatusItem else {
                continue
            }
            if safeObject(from: statusItem, selectorName: "expandedInterfaceDelegate") != nil {
                return statusItem
            }
            if fallbackItem == nil {
                fallbackItem = statusItem
            }
        }
        return fallbackItem
    }

    /// Проверяет, пришёлся ли клик именно по иконке Doppio в системной строке меню (NSStatusBarWindow)
    private func isEventInsideStatusItem(_ event: NSEvent) -> Bool {
        if let eventWindow = event.window, eventWindow.frame.origin.y >= 0 {
            let className = String(describing: type(of: eventWindow))
            if className.contains("StatusBar") {
                return true
            }
        }

        let mouseLocation = NSEvent.mouseLocation
        for window in NSApplication.shared.windows where window.frame.origin.y >= 0 {
            let className = String(describing: type(of: window))
            if className.contains("StatusBar"), window.frame != .zero, window.frame.contains(mouseLocation) {
                return true
            }
        }

        if statusItemScreenFrame != .zero, statusItemScreenFrame.contains(mouseLocation) {
            return true
        }

        return false
    }
}
