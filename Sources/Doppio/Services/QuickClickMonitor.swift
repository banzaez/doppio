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
            return self.handleLocalMouseEvent(event)
        }

        globalEventMonitor = NSEvent.addGlobalMonitorForEvents(
            matching: [.rightMouseDown, .leftMouseDown]
        ) { [weak self] event in
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                self.handleGlobalMouseEvent(event)
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

    private func handleLocalMouseEvent(_ event: NSEvent) -> NSEvent? {
        guard isEventInsideStatusItem(event) else {
            return event
        }

        // Игнорируем отпускание правой кнопки мыши над иконкой
        if event.type == .rightMouseUp {
            return nil
        }

        let isRightClick = event.type == .rightMouseDown
        let isControlClick = event.type == .leftMouseDown && event.modifierFlags.contains(.control)

        // 1. Правый клик (или Control + клик) -> открываем/закрываем меню как по левой кнопке
        if isRightClick || isControlClick {
            toggleMenuBarWindowIfNeeded()
            return nil
        }

        // 2. Option + левый клик (⌥-клик) -> быстрое переключение бодрствования без открытия меню
        if isEnabled, event.type == .leftMouseDown, event.modifierFlags.contains(.option) {
            triggerQuickToggleIfNeeded()
            return nil
        }

        return event
    }

    private func handleGlobalMouseEvent(_ event: NSEvent) {
        guard isEventInsideStatusItem(event) else { return }

        let isRightClick = event.type == .rightMouseDown
        let isControlClick = event.type == .leftMouseDown && event.modifierFlags.contains(.control)

        if isRightClick || isControlClick {
            toggleMenuBarWindowIfNeeded()
            return
        }

        if isEnabled, event.type == .leftMouseDown, event.modifierFlags.contains(.option) {
            triggerQuickToggleIfNeeded()
        }
    }

    private func toggleMenuBarWindowIfNeeded() {
        let now = ProcessInfo.processInfo.systemUptime
        guard now - lastActionTime > 0.15 else { return }
        lastActionTime = now

        guard let statusItem = findMenuBarExtraStatusItem() else { return }

        let endSel = Selector(("_endExpandedInterfaceSession:animate:"))
        let reqSel = Selector(("_requestExpandedInterfaceSession"))

        if let session = statusItem.value(forKey: "expandedInterfaceSession"),
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
        let now = ProcessInfo.processInfo.systemUptime
        guard now - lastActionTime > 0.15 else { return }
        lastActionTime = now

        logger.info("Быстрое переключение по ⌥-клику")
        onQuickToggle?()
    }

    /// Находит системный экземпляр NSStatusItem (NSSceneStatusItem), принадлежащий MenuBarExtra
    private func findMenuBarExtraStatusItem() -> NSStatusItem? {
        for window in NSApplication.shared.windows where window.frame.origin.y >= 0 {
            let className = String(describing: type(of: window))
            guard className.contains("StatusBar"),
                  let statusItem = window.value(forKey: "statusItem") as? NSStatusItem else {
                continue
            }
            if statusItem.value(forKey: "expandedInterfaceDelegate") != nil {
                return statusItem
            }
        }
        for window in NSApplication.shared.windows where window.frame.origin.y >= 0 {
            let className = String(describing: type(of: window))
            if className.contains("StatusBar"),
               let statusItem = window.value(forKey: "statusItem") as? NSStatusItem {
                return statusItem
            }
        }
        return nil
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
