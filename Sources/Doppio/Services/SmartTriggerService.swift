import AppKit
import Foundation
import os

/// Протокол управления умными триггерами
@MainActor
public protocol SmartTriggerManaging: AnyObject {
    func startMonitoring()
    func stopMonitoring()
    func checkCurrentState()
}

/// Сервис умных триггеров (автозапуск по приложениям, питанию и мониторам)
@MainActor
public final class SmartTriggerService: SmartTriggerManaging {
    private let logger = Logger(subsystem: "com.doppio.app", category: "SmartTriggerService")

    private var launchObserver: (any NSObjectProtocol)?
    private var terminateObserver: (any NSObjectProtocol)?
    private var screenObserver: (any NSObjectProtocol)?

    public var onRequestActivation: (@MainActor (SessionTriggerSource) -> Void)?
    public var onRequestDeactivation: (@MainActor (DeactivationReason) -> Void)?
    public var shouldDeactivateForTrigger: (@MainActor (SessionTriggerSource) -> Bool)?

    public init() {}

    isolated deinit {
        if let obs = launchObserver { NotificationCenter.default.removeObserver(obs) }
        if let obs = terminateObserver { NotificationCenter.default.removeObserver(obs) }
        if let obs = screenObserver { NotificationCenter.default.removeObserver(obs) }
    }

    /// Запуск прослушивания событий системы
    public func startMonitoring() {
        stopMonitoring()

        let wsCenter = NSWorkspace.shared.notificationCenter

        // 1. Запуск приложения
        launchObserver = wsCenter.addObserver(
            forName: NSWorkspace.didLaunchApplicationNotification,
            object: nil,
            queue: .main
        ) { [weak self] notif in
            let app = notif.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication
            let bundleId = app?.bundleIdentifier
            let appName = app?.localizedName ?? bundleId

            if let bundleId = bundleId {
                let name = appName ?? bundleId
                Task { @MainActor [weak self] in
                    self?.handleAppLaunched(bundleId: bundleId, appName: name)
                }
            }
        }

        // 2. Закрытие приложения
        terminateObserver = wsCenter.addObserver(
            forName: NSWorkspace.didTerminateApplicationNotification,
            object: nil,
            queue: .main
        ) { [weak self] notif in
            let app = notif.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication
            let bundleId = app?.bundleIdentifier
            let appName = app?.localizedName ?? bundleId

            if let bundleId = bundleId {
                let name = appName ?? bundleId
                Task { @MainActor [weak self] in
                    self?.handleAppTerminated(bundleId: bundleId, appName: name)
                }
            }
        }

        // 3. Подключение / отключение экранов
        screenObserver = NotificationCenter.default.addObserver(
            forName: NSApplication.didChangeScreenParametersNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.handleScreensChanged()
            }
        }

        logger.info("Мониторинг умных триггеров запущен")
    }

    /// Остановка прослушивания событий
    public func stopMonitoring() {
        if let obs = launchObserver {
            NSWorkspace.shared.notificationCenter.removeObserver(obs)
            launchObserver = nil
        }
        if let obs = terminateObserver {
            NSWorkspace.shared.notificationCenter.removeObserver(obs)
            terminateObserver = nil
        }
        if let obs = screenObserver {
            NotificationCenter.default.removeObserver(obs)
            screenObserver = nil
        }
    }

    /// Первичная проверка текущего состояния (при старте приложения)
    public func checkCurrentState() {
        // Проверка внешних мониторов
        handleScreensChanged()
    }

    // MARK: - Обработчики событий

    private func handleAppLaunched(bundleId: String, appName: String) {
        onRequestActivation?(.appTrigger(bundleId: bundleId, appName: appName))
    }

    private func handleAppTerminated(bundleId: String, appName: String) {
        onRequestDeactivation?(.appTerminated(appName: appName))
    }

    private func handleScreensChanged() {
        let externalConnected = NSScreen.screens.count > 1
        if externalConnected {
            onRequestActivation?(.externalDisplay)
        } else {
            onRequestDeactivation?(.externalDisplayDisconnected)
        }
    }

    /// Уведомление об изменении источника питания от BatteryMonitor
    public func handlePowerSourceChanged(isPluggedIn: Bool) {
        if isPluggedIn {
            onRequestActivation?(.acPower)
        } else {
            onRequestDeactivation?(.powerDisconnected)
        }
    }
}
