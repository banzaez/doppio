import Foundation
import Observation
import AppKit
import os

/// Главная модель состояния приложения Doppio
/// Построена на основе Observation framework (@Observable) и Swift Concurrency (@MainActor)
@Observable
@MainActor
public final class DoppioState {
    // MARK: - Ключи UserDefaults
    private enum StorageKey: String {
        case assertionType
        case showTimerInMenuBar
        case menuBarDisplayStyle
        case quickToggleEnabled
        case notifyBeforeExpiry
        case batteryProtectionEnabled
        case batteryThreshold
        case customMinutes
        case appLanguage
        case appTriggersEnabled
        case targetAppsData
        case activateOnACPower
        case deactivateOnBattery
        case activateOnExternalDisplay
    }

    // MARK: - Активное состояние
    public private(set) var isActive: Bool = false
    public var selectedPreset: KeepAwakePreset = .indefinite
    public var customMinutes: Int = 45 {
        didSet {
            defaults.set(customMinutes, forKey: StorageKey.customMinutes.rawValue)
        }
    }
    public var assertionType: SleepAssertionType = .systemOnly {
        didSet {
            defaults.set(assertionType.rawValue, forKey: StorageKey.assertionType.rawValue)
            if isActive {
                updateAssertion(activate: true, type: assertionType)
            }
        }
    }

    /// Источник запуска текущей активной сессии
    public private(set) var activeTriggerSource: SessionTriggerSource = .manual

    // MARK: - Таймер
    public private(set) var remainingSeconds: TimeInterval? = nil
    public private(set) var totalDurationSeconds: TimeInterval? = nil
    private var hasSentExpiryNotification: Bool = false

    // MARK: - Настройки строки меню и быстрых действий
    public var menuBarDisplayStyle: MenuBarDisplayStyle = .standard {
        didSet {
            defaults.set(menuBarDisplayStyle.rawValue, forKey: StorageKey.menuBarDisplayStyle.rawValue)
        }
    }

    public var showTimerInMenuBar: Bool = true {
        didSet {
            defaults.set(showTimerInMenuBar, forKey: StorageKey.showTimerInMenuBar.rawValue)
        }
    }

    public var quickToggleEnabled: Bool = true {
        didSet {
            defaults.set(quickToggleEnabled, forKey: StorageKey.quickToggleEnabled.rawValue)
            QuickClickMonitor.shared.isEnabled = quickToggleEnabled
        }
    }

    public var notifyBeforeExpiry: Bool = true {
        didSet {
            defaults.set(notifyBeforeExpiry, forKey: StorageKey.notifyBeforeExpiry.rawValue)
            if notifyBeforeExpiry {
                Task {
                    await notificationService.requestAuthorization()
                }
            }
        }
    }

    // MARK: - Умные триггеры
    public var appTriggersEnabled: Bool = true {
        didSet {
            defaults.set(appTriggersEnabled, forKey: StorageKey.appTriggersEnabled.rawValue)
            checkAppTriggersOnDemand()
        }
    }

    public var targetApps: [TriggerApp] = [] {
        didSet {
            saveTargetApps()
            checkAppTriggersOnDemand()
        }
    }

    public var activateOnACPower: Bool = false {
        didSet {
            defaults.set(activateOnACPower, forKey: StorageKey.activateOnACPower.rawValue)
            if activateOnACPower, let info = batteryInfo, info.isPluggedIn, !isActive {
                activateWithTrigger(.acPower)
            }
        }
    }

    public var deactivateOnBattery: Bool = false {
        didSet {
            defaults.set(deactivateOnBattery, forKey: StorageKey.deactivateOnBattery.rawValue)
        }
    }

    public var activateOnExternalDisplay: Bool = false {
        didSet {
            defaults.set(activateOnExternalDisplay, forKey: StorageKey.activateOnExternalDisplay.rawValue)
            if activateOnExternalDisplay, NSScreen.screens.count > 1, !isActive {
                activateWithTrigger(.externalDisplay)
            }
        }
    }

    // MARK: - Защита аккумулятора
    public var batteryProtectionEnabled: Bool = true {
        didSet {
            defaults.set(batteryProtectionEnabled, forKey: StorageKey.batteryProtectionEnabled.rawValue)
            if isActive {
                if batteryProtectionEnabled {
                    startBatteryMonitoring()
                    checkBatteryThreshold()
                } else {
                    stopBatteryMonitoring()
                }
            }
        }
    }

    public var batteryThreshold: Int = 20 {
        didSet {
            defaults.set(batteryThreshold, forKey: StorageKey.batteryThreshold.rawValue)
            if isActive {
                checkBatteryThreshold()
            }
        }
    }

    public var isLaunchAtLogin: Bool = false

    // MARK: - Язык и локализация
    public var language: AppLanguage = .defaultLanguage {
        didSet {
            defaults.set(language.rawValue, forKey: StorageKey.appLanguage.rawValue)
            self.l10n = L10n(language: language)
        }
    }
    public private(set) var l10n: L10n = L10n(language: .defaultLanguage)

    // MARK: - Питание
    public private(set) var batteryInfo: BatteryInfo? = nil
    public private(set) var lastDeactivationReason: DeactivationReason? = nil

    public var localizedDeactivationReason: String? {
        lastDeactivationReason?.localized(using: l10n)
    }

    public func clearDeactivationReason() {
        lastDeactivationReason = nil
    }

    // MARK: - Зависимости (Dependency Injection)
    private let assertionService: any SleepAssertionManaging
    private let batteryMonitor: any BatteryMonitoring
    private let launchAtLoginService: any LaunchAtLoginManaging
    private let notificationService: any AppNotificationManaging
    private let smartTriggerService: (any SmartTriggerManaging)?
    private let defaults: UserDefaults
    private let logger = Logger(subsystem: "com.doppio.app", category: "DoppioState")

    private var timerTask: Task<Void, Never>?
    private var batteryCheckTask: Task<Void, Never>?
    private var assertionTask: Task<Void, Never>?

    // MARK: - Инициализация
    public init(
        assertionService: any SleepAssertionManaging = SleepAssertionService(),
        batteryMonitor: any BatteryMonitoring = BatteryMonitorService(),
        launchAtLoginService: any LaunchAtLoginManaging = LaunchAtLoginService(),
        notificationService: any AppNotificationManaging = AppNotificationService.shared,
        smartTriggerService: (any SmartTriggerManaging)? = nil,
        defaults: UserDefaults = .standard
    ) {
        self.assertionService = assertionService
        self.batteryMonitor = batteryMonitor
        self.launchAtLoginService = launchAtLoginService
        self.notificationService = notificationService
        self.defaults = defaults

        let triggerService = smartTriggerService ?? SmartTriggerService()
        self.smartTriggerService = triggerService

        loadPersistedSettings()
        refreshBatteryInfo()
        self.isLaunchAtLogin = launchAtLoginService.isEnabled

        setupQuickClickMonitor()
        setupNotificationHandling()
        setupSmartTriggers(service: triggerService)
    }

    isolated deinit {
        timerTask?.cancel()
        batteryCheckTask?.cancel()
        assertionTask?.cancel()
    }

    // MARK: - Настройка сервисов и обработчиков

    private func setupQuickClickMonitor() {
        QuickClickMonitor.shared.isEnabled = quickToggleEnabled
        QuickClickMonitor.shared.onQuickToggle = { [weak self] in
            self?.toggle()
        }
        QuickClickMonitor.shared.startMonitoring()
    }

    private func setupNotificationHandling() {
        if let appNotifService = notificationService as? AppNotificationService {
            appNotifService.onActionReceived = { [weak self] action in
                guard let self = self else { return }
                switch action {
                case .extend15Minutes:
                    self.extendSession(by: 15 * 60)
                case .makeIndefinite:
                    self.activate(preset: .indefinite)
                }
            }
        }
    }

    private func setupSmartTriggers(service: any SmartTriggerManaging) {
        if let concreteService = service as? SmartTriggerService {
            concreteService.onRequestActivation = { [weak self] source in
                self?.handleTriggerActivation(source)
            }
            concreteService.onRequestDeactivation = { [weak self] reason in
                self?.handleTriggerDeactivation(reason)
            }
            concreteService.startMonitoring()
            concreteService.checkCurrentState()
        }
    }

    // MARK: - Загрузка сохранённых настроек
    private func loadPersistedSettings() {
        let defaults = self.defaults

        if let rawType = defaults.string(forKey: StorageKey.assertionType.rawValue),
           let type = SleepAssertionType(rawValue: rawType) {
            self.assertionType = type
        } else {
            self.assertionType = .systemOnly
        }

        if let rawStyle = defaults.string(forKey: StorageKey.menuBarDisplayStyle.rawValue),
           let style = MenuBarDisplayStyle(rawValue: rawStyle) {
            self.menuBarDisplayStyle = style
        } else {
            self.menuBarDisplayStyle = .standard
        }

        if defaults.object(forKey: StorageKey.showTimerInMenuBar.rawValue) != nil {
            self.showTimerInMenuBar = defaults.bool(forKey: StorageKey.showTimerInMenuBar.rawValue)
        }

        if defaults.object(forKey: StorageKey.quickToggleEnabled.rawValue) != nil {
            self.quickToggleEnabled = defaults.bool(forKey: StorageKey.quickToggleEnabled.rawValue)
        }

        if defaults.object(forKey: StorageKey.notifyBeforeExpiry.rawValue) != nil {
            self.notifyBeforeExpiry = defaults.bool(forKey: StorageKey.notifyBeforeExpiry.rawValue)
        }

        if defaults.object(forKey: StorageKey.appTriggersEnabled.rawValue) != nil {
            self.appTriggersEnabled = defaults.bool(forKey: StorageKey.appTriggersEnabled.rawValue)
        }

        if defaults.object(forKey: StorageKey.activateOnACPower.rawValue) != nil {
            self.activateOnACPower = defaults.bool(forKey: StorageKey.activateOnACPower.rawValue)
        }

        if defaults.object(forKey: StorageKey.deactivateOnBattery.rawValue) != nil {
            self.deactivateOnBattery = defaults.bool(forKey: StorageKey.deactivateOnBattery.rawValue)
        }

        if defaults.object(forKey: StorageKey.activateOnExternalDisplay.rawValue) != nil {
            self.activateOnExternalDisplay = defaults.bool(forKey: StorageKey.activateOnExternalDisplay.rawValue)
        }

        if let data = defaults.data(forKey: StorageKey.targetAppsData.rawValue),
           let apps = try? JSONDecoder().decode([TriggerApp].self, from: data) {
            self.targetApps = apps
        }

        if defaults.object(forKey: StorageKey.batteryProtectionEnabled.rawValue) != nil {
            self.batteryProtectionEnabled = defaults.bool(forKey: StorageKey.batteryProtectionEnabled.rawValue)
        }

        if defaults.object(forKey: StorageKey.batteryThreshold.rawValue) != nil {
            let threshold = defaults.integer(forKey: StorageKey.batteryThreshold.rawValue)
            if threshold >= 5 && threshold <= 50 {
                self.batteryThreshold = threshold
            }
        }

        if defaults.object(forKey: StorageKey.customMinutes.rawValue) != nil {
            let minutes = defaults.integer(forKey: StorageKey.customMinutes.rawValue)
            if minutes > 0 {
                self.customMinutes = minutes
            }
        }

        if let rawLang = defaults.string(forKey: StorageKey.appLanguage.rawValue),
           let savedLang = AppLanguage(rawValue: rawLang) {
            self.language = savedLang
        } else {
            self.language = .defaultLanguage
        }
        self.l10n = L10n(language: self.language)
    }

    private func saveTargetApps() {
        if let data = try? JSONEncoder().encode(targetApps) {
            defaults.set(data, forKey: StorageKey.targetAppsData.rawValue)
        }
    }

    // MARK: - Публичные действия

    /// Быстрое переключение бодрствования
    public func toggle() {
        if isActive {
            deactivate(reason: .userDisabled)
        } else {
            activate(preset: selectedPreset)
        }
    }

    /// Включить бодрствование с пресетом вручную
    public func activate(preset: KeepAwakePreset) {
        self.activeTriggerSource = .manual
        self.selectedPreset = preset
        let duration: TimeInterval?

        switch preset {
        case .custom:
            duration = TimeInterval(customMinutes * 60)
        default:
            duration = preset.duration
        }

        startActiveSession(duration: duration)
    }

    /// Активация по умному триггеру
    public func activateWithTrigger(_ source: SessionTriggerSource) {
        self.activeTriggerSource = source
        self.selectedPreset = .indefinite
        startActiveSession(duration: nil)
    }

    /// Продлить текущую сессию на указанное количество секунд
    public func extendSession(by seconds: TimeInterval) {
        guard isActive else {
            activate(preset: .custom)
            return
        }

        hasSentExpiryNotification = false

        if let remaining = remainingSeconds {
            let newRemaining = remaining + seconds
            let newTotal = (totalDurationSeconds ?? remaining) + seconds
            self.remainingSeconds = newRemaining
            self.totalDurationSeconds = newTotal
            startCountdown(duration: newRemaining)
            logger.info("Сессия продлена на \(seconds) сек. Новое время: \(newRemaining) сек")
        }
    }

    /// Выключить бодрствование
    public func deactivate(reason: DeactivationReason = .sessionCompleted) {
        timerTask?.cancel()
        timerTask = nil
        stopBatteryMonitoring()

        Task {
            await notificationService.cancelPendingNotifications()
        }

        remainingSeconds = nil
        totalDurationSeconds = nil
        hasSentExpiryNotification = false
        isActive = false
        activeTriggerSource = .manual
        lastDeactivationReason = reason

        updateAssertion(activate: false, type: assertionType)

        logger.info("Doppio деактивирован: \(reason.localized(using: self.l10n))")
    }

    /// Обратная совместимость для строковых причин
    public func deactivate(reason: String) {
        deactivate(reason: .sessionCompleted)
    }

    /// Переключение автозапуска
    public func toggleLaunchAtLogin() {
        let newState = !isLaunchAtLogin
        let success = launchAtLoginService.setEnabled(newState)
        if success {
            self.isLaunchAtLogin = newState
        }
    }

    /// Принудительно обновить информацию о батарее
    public func refreshBatteryInfo() {
        let oldInfo = self.batteryInfo
        self.batteryInfo = batteryMonitor.fetchBatteryInfo()
        checkBatteryThreshold()

        if let newInfo = self.batteryInfo, let old = oldInfo {
            if !old.isPluggedIn && newInfo.isPluggedIn {
                // Подключили провод питания
                if activateOnACPower && !isActive {
                    activateWithTrigger(.acPower)
                }
            } else if old.isPluggedIn && !newInfo.isPluggedIn {
                // Отключили провод питания
                if deactivateOnBattery && isActive && activeTriggerSource == .acPower {
                    deactivate(reason: .powerDisconnected)
                }
            }
        }
    }

    // MARK: - Управление целевыми приложениями (App Triggers)

    public func addTargetApp(_ app: TriggerApp) {
        guard !targetApps.contains(where: { $0.bundleIdentifier == app.bundleIdentifier }) else { return }
        targetApps.append(app)
    }

    public func removeTargetApp(id: UUID) {
        targetApps.removeAll { $0.id == id }
    }

    public func isTargetAppRunning(_ app: TriggerApp) -> Bool {
        NSWorkspace.shared.runningApplications.contains { $0.bundleIdentifier == app.bundleIdentifier }
    }

    private func checkAppTriggersOnDemand() {
        guard appTriggersEnabled else { return }
        let runningBundles = Set(NSWorkspace.shared.runningApplications.compactMap(\.bundleIdentifier))
        if let matched = targetApps.first(where: { runningBundles.contains($0.bundleIdentifier) }) {
            if !isActive {
                activateWithTrigger(.appTrigger(bundleId: matched.bundleIdentifier, appName: matched.displayName))
            }
        }
    }

    // MARK: - Обработка умных триггеров

    private func handleTriggerActivation(_ source: SessionTriggerSource) {
        switch source {
        case .appTrigger(let bundleId, let appName):
            guard appTriggersEnabled else { return }
            guard targetApps.contains(where: { $0.bundleIdentifier == bundleId }) else { return }
            if !isActive {
                activateWithTrigger(.appTrigger(bundleId: bundleId, appName: appName))
            }

        case .acPower:
            guard activateOnACPower else { return }
            if !isActive {
                activateWithTrigger(.acPower)
            }

        case .externalDisplay:
            guard activateOnExternalDisplay else { return }
            if !isActive {
                activateWithTrigger(.externalDisplay)
            }

        case .manual:
            break
        }
    }

    private func handleTriggerDeactivation(_ reason: DeactivationReason) {
        switch reason {
        case .appTerminated:
            guard appTriggersEnabled else { return }
            guard case .appTrigger = activeTriggerSource else { return }
            let runningBundles = Set(NSWorkspace.shared.runningApplications.compactMap(\.bundleIdentifier))
            let anyStillRunning = targetApps.contains { runningBundles.contains($0.bundleIdentifier) }
            if !anyStillRunning {
                deactivate(reason: reason)
            }

        case .powerDisconnected:
            guard deactivateOnBattery else { return }
            if isActive && activeTriggerSource == .acPower {
                deactivate(reason: reason)
            }

        case .externalDisplayDisconnected:
            if isActive && activeTriggerSource == .externalDisplay {
                deactivate(reason: reason)
            }

        default:
            break
        }
    }

    // MARK: - Вспомогательные вычисляемые свойства

    /// Форматированная строка оставшегося времени для отображения в UI
    public var formattedRemainingTime: String {
        guard let remaining = remainingSeconds, remaining > 0 else {
            return "∞"
        }

        let hours = Int(remaining) / 3600
        let minutes = (Int(remaining) % 3600) / 60
        let seconds = Int(remaining) % 60

        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%02d:%02d", minutes, seconds)
        }
    }

    /// Короткая строка для меню-бара (например, "45м", "45хв", "45m")
    public var menuBarBadgeText: String? {
        guard isActive,
              menuBarDisplayStyle == .standard,
              showTimerInMenuBar,
              let remaining = remainingSeconds,
              remaining > 0 else {
            return nil
        }

        let hours = Int(remaining) / 3600
        let minutes = (Int(remaining) % 3600) / 60
        return l10n.menuBarBadgeText(hours: hours, minutes: minutes)
    }

    /// Процент оставшегося времени для кольцевого прогресс-бара
    public var timerProgress: Double {
        guard let remaining = remainingSeconds,
              let total = totalDurationSeconds,
              total > 0 else {
            return 1.0
        }
        return min(max(remaining / total, 0.0), 1.0)
    }

    // MARK: - Управление состоянием ассершена (Race Condition Prevention)

    private func updateAssertion(activate: Bool, type: SleepAssertionType) {
        assertionTask?.cancel()
        assertionTask = Task { [assertionService] in
            if activate {
                await assertionService.activate(type: type, reason: "Doppio Keep-Awake Session")
            } else {
                await assertionService.release()
            }
        }
    }

    // MARK: - Внутренняя логика сессии

    private func startActiveSession(duration: TimeInterval?) {
        // Проверка батареи перед запуском
        if batteryProtectionEnabled,
           let info = batteryInfo,
           !info.isPluggedIn && !info.isCharging,
           info.percentage <= batteryThreshold {
            lastDeactivationReason = .batteryLow(percentage: info.percentage)
            return
        }

        timerTask?.cancel()
        timerTask = nil

        self.isActive = true
        self.lastDeactivationReason = nil
        self.hasSentExpiryNotification = false
        self.totalDurationSeconds = duration
        self.remainingSeconds = duration

        updateAssertion(activate: true, type: assertionType)
        startBatteryMonitoring()

        if let duration = duration {
            startCountdown(duration: duration)
        }

        logger.info("Doppio активирован, режим: \(self.assertionType.rawValue), длительность: \(duration ?? 0) сек")
    }

    private func startCountdown(duration: TimeInterval) {
        let clock = ContinuousClock()
        let targetEndTime = Date().addingTimeInterval(duration)

        timerTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await clock.sleep(for: .seconds(1))
                if Task.isCancelled { break }

                guard let self = self else { break }

                let remaining = targetEndTime.timeIntervalSince(Date())
                if remaining <= 0 {
                    self.remainingSeconds = 0
                    self.timerFinished()
                    break
                } else {
                    self.remainingSeconds = remaining

                    // Отправка уведомления за 60 секунд до окончания
                    if self.notifyBeforeExpiry,
                       !self.hasSentExpiryNotification,
                       remaining <= 60 {
                        self.hasSentExpiryNotification = true
                        Task { [weak self] in
                            guard let self = self else { return }
                            await self.notificationService.schedulePreExpiryNotification(
                                title: self.l10n.notificationSessionEndingTitle,
                                body: self.l10n.notificationSessionEndingBody,
                                l10n: self.l10n
                            )
                        }
                    }
                }
            }
        }
    }

    private func timerFinished() {
        deactivate(reason: .timerExpired)
    }

    // MARK: - Энергоэффективный мониторинг батареи

    private func startBatteryMonitoring() {
        guard batteryProtectionEnabled else { return }
        stopBatteryMonitoring()

        let clock = ContinuousClock()
        batteryCheckTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await clock.sleep(for: .seconds(30))
                if Task.isCancelled { break }

                guard let self = self else { break }
                self.refreshBatteryInfo()
            }
        }
    }

    private func stopBatteryMonitoring() {
        batteryCheckTask?.cancel()
        batteryCheckTask = nil
    }

    private func checkBatteryThreshold() {
        guard isActive,
              batteryProtectionEnabled,
              let info = batteryInfo,
              !info.isPluggedIn && !info.isCharging else {
            return
        }

        if info.percentage <= batteryThreshold {
            deactivate(reason: .batteryLow(percentage: info.percentage))
        }
    }
}
