import AppKit
import CoreGraphics
import Foundation
import os

/// Протокол управления умными триггерами и системным окружением (процессы, экраны)
@MainActor
public protocol SmartTriggerManaging: AnyObject {
    var onRequestActivation: (@MainActor (SessionTriggerSource) -> Void)? { get set }
    var onRequestDeactivation: (@MainActor (DeactivationReason) -> Void)? { get set }

    func startMonitoring()
    func stopMonitoring()
    func checkCurrentState()

    /// Проверить, подключён ли хотя бы один внешний монитор (включая режим закрытой крышки Clamshell)
    func hasExternalDisplayConnected() -> Bool

    /// Набор Bundle ID всех запущенных в данный момент приложений
    func runningBundleIdentifiers() -> Set<String>

    /// Список запущенных пользовательских приложений для выбора в качестве триггера
    func candidateRunningApps(excluding existingBundleIds: Set<String>) -> [TriggerApp]

    /// Извлечь модель TriggerApp из URL бандла на диске (.app)
    func triggerApp(from url: URL) -> TriggerApp?
}

/// Сервис умных триггеров на базе Swift 6 Structured Concurrency (AsyncSequence уведомлений)
@MainActor
public final class SmartTriggerService: SmartTriggerManaging {
    private let logger = Logger(subsystem: "com.doppio.app", category: "SmartTriggerService")

    private var monitoringTask: Task<Void, Never>?

    public var onRequestActivation: (@MainActor (SessionTriggerSource) -> Void)?
    public var onRequestDeactivation: (@MainActor (DeactivationReason) -> Void)?

    public init() {}

    isolated deinit {
        stopMonitoring()
    }

    /// Запуск асинхронного прослушивания системных событий через Structured Concurrency
    public func startMonitoring() {
        stopMonitoring()

        monitoringTask = Task { [weak self] in
            await withTaskGroup(of: Void.self) { group in
                // 1. Поток событий запуска приложений
                group.addTask { [weak self] in
                    await Self.observeWorkspaceNotifications(
                        named: NSWorkspace.didLaunchApplicationNotification
                    ) { [weak self] bundleId, appName in
                        self?.handleAppLaunched(bundleId: bundleId, appName: appName)
                    }
                }

                // 2. Поток событий завершения приложений
                group.addTask { [weak self] in
                    await Self.observeWorkspaceNotifications(
                        named: NSWorkspace.didTerminateApplicationNotification
                    ) { [weak self] bundleId, appName in
                        self?.handleAppTerminated(bundleId: bundleId, appName: appName)
                    }
                }

                // 3. Поток событий изменения конфигурации дисплеев
                group.addTask { [weak self] in
                    await Self.observeScreenNotifications { [weak self] in
                        self?.handleScreensChanged()
                    }
                }
            }
        }

        logger.info("Мониторинг умных триггеров (Structured Concurrency) запущен")
    }

    nonisolated private static func observeWorkspaceNotifications(
        named name: Notification.Name,
        onEvent: @escaping @MainActor @Sendable (String, String) -> Void
    ) async {
        let wsCenter = NSWorkspace.shared.notificationCenter
        for await notif in wsCenter.notifications(named: name) {
            if Task.isCancelled { break }
            let app = notif.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication
            if let bundleId = app?.bundleIdentifier {
                let appName = app?.localizedName ?? bundleId
                await onEvent(bundleId, appName)
            }
        }
    }

    nonisolated private static func observeScreenNotifications(
        onEvent: @escaping @MainActor @Sendable () -> Void
    ) async {
        let defaultCenter = NotificationCenter.default
        for await _ in defaultCenter.notifications(named: NSApplication.didChangeScreenParametersNotification) {
            if Task.isCancelled { break }
            await onEvent()
        }
    }

    /// Остановка прослушивания событий
    public func stopMonitoring() {
        monitoringTask?.cancel()
        monitoringTask = nil
    }

    /// Первичная проверка текущего состояния (при старте приложения)
    public func checkCurrentState() {
        handleScreensChanged()
    }

    // MARK: - Запросы к системному окружению

    public func hasExternalDisplayConnected() -> Bool {
        for screen in NSScreen.screens {
            if let screenNumber = screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? NSNumber {
                let displayID = CGDirectDisplayID(screenNumber.uint32Value)
                if CGDisplayIsBuiltin(displayID) == 0 {
                    return true
                }
            }
        }
        return NSScreen.screens.count > 1
    }

    public func runningBundleIdentifiers() -> Set<String> {
        Set(NSWorkspace.shared.runningApplications.compactMap(\.bundleIdentifier))
    }

    public func candidateRunningApps(excluding existingBundleIds: Set<String>) -> [TriggerApp] {
        NSWorkspace.shared.runningApplications
            .filter { app in
                guard app.activationPolicy == .regular,
                      let bundleId = app.bundleIdentifier,
                      bundleId != Bundle.main.bundleIdentifier,
                      !existingBundleIds.contains(bundleId) else {
                    return false
                }
                return true
            }
            .compactMap { app in
                guard let bundleId = app.bundleIdentifier else { return nil }
                let name = app.localizedName ?? bundleId
                return TriggerApp(bundleIdentifier: bundleId, displayName: name)
            }
    }

    public func triggerApp(from url: URL) -> TriggerApp? {
        guard let bundle = Bundle(url: url),
              let bundleId = bundle.bundleIdentifier else {
            return nil
        }
        let name = bundle.infoDictionary?["CFBundleDisplayName"] as? String
            ?? bundle.infoDictionary?["CFBundleName"] as? String
            ?? url.deletingPathExtension().lastPathComponent
        return TriggerApp(bundleIdentifier: bundleId, displayName: name)
    }

    // MARK: - Обработчики событий

    private func handleAppLaunched(bundleId: String, appName: String) {
        onRequestActivation?(.appTrigger(bundleId: bundleId, appName: appName))
    }

    private func handleAppTerminated(bundleId: String, appName: String) {
        onRequestDeactivation?(.appTerminated(appName: appName))
    }

    private func handleScreensChanged() {
        if hasExternalDisplayConnected() {
            onRequestActivation?(.externalDisplay)
        } else {
            onRequestDeactivation?(.externalDisplayDisconnected)
        }
    }
}
