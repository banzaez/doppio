import Foundation
import Observation
import AppKit
import os

/// Главная модель-координатор состояния приложения Doppio
/// Построена на основе Observation framework (@Observable) и Swift Concurrency (@MainActor)
@Observable
@MainActor
public final class DoppioState {
    // MARK: - Активное состояние сессии
    public private(set) var isActive: Bool = false
    public var selectedPreset: KeepAwakePreset = .indefinite

    public var customMinutes: Int {
        didSet {
            settingsStore.customMinutes = customMinutes
        }
    }

    public var assertionType: SleepAssertionType {
        didSet {
            settingsStore.assertionType = assertionType
            if isActive {
                updateAssertion(activate: true, type: assertionType)
            }
        }
    }

    /// Источник запуска текущей активной сессии
    public private(set) var activeTriggerSource: SessionTriggerSource = .manual

    // MARK: - Таймер и оптимизированный бейдж строки меню
    public private(set) var remainingSeconds: TimeInterval? = nil
    public private(set) var totalDurationSeconds: TimeInterval? = nil
    public private(set) var menuBarBadgeText: String? = nil

    private var sessionEndTime: Date? = nil
    private var hasSentExpiryNotification: Bool = false

    /// Открыто ли сейчас окно поповера (управляет адаптивной частотой тиков таймера для Zero Idle CPU)
    public var isPopoverVisible: Bool = false {
        didSet {
            guard isPopoverVisible != oldValue, let endTime = sessionEndTime, isActive else { return }
            syncRemainingTime(with: endTime)
            startCountdownLoop(targetEndTime: endTime)
        }
    }

    // MARK: - Настройки строки меню и быстрых действий
    public var menuBarDisplayStyle: MenuBarDisplayStyle {
        didSet {
            settingsStore.menuBarDisplayStyle = menuBarDisplayStyle
            updateMenuBarBadge()
        }
    }

    public var showTimerInMenuBar: Bool {
        didSet {
            settingsStore.showTimerInMenuBar = showTimerInMenuBar
            updateMenuBarBadge()
        }
    }

    public var quickToggleEnabled: Bool {
        didSet {
            settingsStore.quickToggleEnabled = quickToggleEnabled
            quickClickMonitor.isEnabled = quickToggleEnabled
        }
    }

    public var notifyBeforeExpiry: Bool {
        didSet {
            settingsStore.notifyBeforeExpiry = notifyBeforeExpiry
            if notifyBeforeExpiry {
                Task {
                    await notificationService.requestAuthorization()
                }
            }
        }
    }

    // MARK: - Умные триггеры
    public var appTriggersEnabled: Bool {
        didSet {
            settingsStore.appTriggersEnabled = appTriggersEnabled
            checkAppTriggersOnDemand()
        }
    }

    public var targetApps: [TriggerApp] {
        didSet {
            settingsStore.targetApps = targetApps
            checkAppTriggersOnDemand()
        }
    }

    public var activateOnACPower: Bool {
        didSet {
            settingsStore.activateOnACPower = activateOnACPower
            if activateOnACPower, let info = batteryInfo, info.isPluggedIn, !isActive {
                activateWithTrigger(.acPower)
            }
        }
    }

    public var deactivateOnBattery: Bool {
        didSet {
            settingsStore.deactivateOnBattery = deactivateOnBattery
        }
    }

    public var activateOnExternalDisplay: Bool {
        didSet {
            settingsStore.activateOnExternalDisplay = activateOnExternalDisplay
            if activateOnExternalDisplay, smartTriggerService.hasExternalDisplayConnected(), !isActive {
                activateWithTrigger(.externalDisplay)
            }
        }
    }

    // MARK: - Защита аккумулятора
    public var batteryProtectionEnabled: Bool {
        didSet {
            settingsStore.batteryProtectionEnabled = batteryProtectionEnabled
            if isActive && batteryProtectionEnabled {
                checkBatteryThreshold()
            }
        }
    }

    public var batteryThreshold: Int {
        didSet {
            settingsStore.batteryThreshold = batteryThreshold
            if isActive {
                checkBatteryThreshold()
            }
        }
    }

    public var isLaunchAtLogin: Bool = false

    // MARK: - Язык и локализация
    public var language: AppLanguage {
        didSet {
            settingsStore.language = language
            self.l10n = L10n(language: language)
            updateMenuBarBadge()
        }
    }
    public private(set) var l10n: L10n

    // MARK: - Питание и статус деактивации
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
    private let smartTriggerService: any SmartTriggerManaging
    private let quickClickMonitor: any QuickClickMonitoring
    private let settingsStore: DoppioSettingsStore
    private let logger = Logger(subsystem: "com.doppio.app", category: "DoppioState")

    private var timerTask: Task<Void, Never>?
    private var assertionTask: Task<Void, Never>?

    // MARK: - Инициализация
    public init(
        assertionService: any SleepAssertionManaging = SleepAssertionService(),
        batteryMonitor: any BatteryMonitoring = BatteryMonitorService(),
        launchAtLoginService: any LaunchAtLoginManaging = LaunchAtLoginService(),
        notificationService: any AppNotificationManaging = AppNotificationService.shared,
        smartTriggerService: (any SmartTriggerManaging)? = nil,
        quickClickMonitor: (any QuickClickMonitoring)? = nil,
        defaults: UserDefaults = .standard
    ) {
        let store = DoppioSettingsStore(defaults: defaults)
        self.settingsStore = store
        self.assertionService = assertionService
        self.batteryMonitor = batteryMonitor
        self.launchAtLoginService = launchAtLoginService
        self.notificationService = notificationService
        self.smartTriggerService = smartTriggerService ?? SmartTriggerService()
        self.quickClickMonitor = quickClickMonitor ?? QuickClickMonitor.shared

        // Прямая инициализация сохранённых настроек без вызова didSet и лишних записей на диск
        let savedLang = store.language
        self.language = savedLang
        self.l10n = L10n(language: savedLang)
        self.assertionType = store.assertionType
        self.menuBarDisplayStyle = store.menuBarDisplayStyle
        self.showTimerInMenuBar = store.showTimerInMenuBar
        self.quickToggleEnabled = store.quickToggleEnabled
        self.notifyBeforeExpiry = store.notifyBeforeExpiry
        self.appTriggersEnabled = store.appTriggersEnabled
        self.activateOnACPower = store.activateOnACPower
        self.deactivateOnBattery = store.deactivateOnBattery
        self.activateOnExternalDisplay = store.activateOnExternalDisplay
        self.targetApps = store.targetApps
        self.batteryProtectionEnabled = store.batteryProtectionEnabled
        self.batteryThreshold = store.batteryThreshold
        self.customMinutes = store.customMinutes

        self.isLaunchAtLogin = launchAtLoginService.isEnabled
        self.batteryInfo = batteryMonitor.fetchBatteryInfo()

        setupQuickClickMonitor()
        setupNotificationHandling()
        setupBatteryMonitoring()
        setupSmartTriggers()
        checkInitialTriggers()
    }

    isolated deinit {
        timerTask?.cancel()
        assertionTask?.cancel()
        batteryMonitor.stopMonitoring()
        smartTriggerService.stopMonitoring()
    }

    // MARK: - Настройка сервисов и обработчиков

    private func setupQuickClickMonitor() {
        quickClickMonitor.isEnabled = quickToggleEnabled
        quickClickMonitor.onQuickToggle = { [weak self] in
            self?.toggle()
        }
        if quickToggleEnabled {
            quickClickMonitor.startMonitoring()
        }
    }

    private func setupNotificationHandling() {
        notificationService.onActionReceived = { [weak self] action in
            guard let self = self else { return }
            switch action {
            case .extend15Minutes:
                self.extendSession(by: 15 * 60)
            case .makeIndefinite:
                self.activate(preset: .indefinite)
            }
        }
    }

    private func setupBatteryMonitoring() {
        batteryMonitor.startMonitoring { [weak self] in
            self?.refreshBatteryInfo()
        }
    }

    private func setupSmartTriggers() {
        smartTriggerService.onRequestActivation = { [weak self] source in
            self?.handleTriggerActivation(source)
        }
        smartTriggerService.onRequestDeactivation = { [weak self] reason in
            self?.handleTriggerDeactivation(reason)
        }
        smartTriggerService.startMonitoring()
    }

    private func checkInitialTriggers() {
        checkAppTriggersOnDemand()
        if activateOnACPower, let info = batteryInfo, info.isPluggedIn, !isActive {
            activateWithTrigger(.acPower)
        }
        smartTriggerService.checkCurrentState()
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
            updateMenuBarBadge()
            startCountdown(duration: newRemaining)
            logger.info("Сессия продлена на \(seconds) сек. Новое время: \(newRemaining) сек")
        }
    }

    /// Выключить бодрствование
    public func deactivate(reason: DeactivationReason = .sessionCompleted) {
        timerTask?.cancel()
        timerTask = nil
        sessionEndTime = nil

        Task {
            await notificationService.cancelPendingNotifications()
        }

        remainingSeconds = nil
        totalDurationSeconds = nil
        hasSentExpiryNotification = false
        isActive = false
        activeTriggerSource = .manual
        lastDeactivationReason = reason
        updateMenuBarBadge()

        updateAssertion(activate: false, type: assertionType)

        logger.info("Doppio деактивирован: \(reason.localized(using: self.l10n))")
    }

    /// Корректное завершение работы приложения с синхронным освобождением ресурсов
    public func quitApplication() {
        deactivate(reason: .quitApp)
        Task {
            await assertionService.release()
            NSApplication.shared.terminate(nil)
        }
    }

    /// Переключение автозапуска
    public func toggleLaunchAtLogin() {
        let newState = !isLaunchAtLogin
        let success = launchAtLoginService.setEnabled(newState)
        if success {
            self.isLaunchAtLogin = newState
        }
    }

    /// Принудительно обновить информацию о батарее и проверить триггеры питания
    public func refreshBatteryInfo() {
        let oldInfo = self.batteryInfo
        let newInfo = batteryMonitor.fetchBatteryInfo()
        self.batteryInfo = newInfo
        checkBatteryThreshold()

        if let newInfo = newInfo {
            let wasPluggedIn = oldInfo?.isPluggedIn ?? newInfo.isPluggedIn
            if !wasPluggedIn && newInfo.isPluggedIn {
                // Подключили провод питания
                if activateOnACPower && !isActive {
                    activateWithTrigger(.acPower)
                }
            } else if wasPluggedIn && !newInfo.isPluggedIn {
                // Отключили провод питания
                if deactivateOnBattery && isActive {
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

    public func addTargetApp(from url: URL) {
        guard let app = smartTriggerService.triggerApp(from: url) else { return }
        addTargetApp(app)
    }

    public func removeTargetApp(id: UUID) {
        targetApps.removeAll { $0.id == id }
    }

    public func isTargetAppRunning(_ app: TriggerApp) -> Bool {
        smartTriggerService.runningBundleIdentifiers().contains(app.bundleIdentifier)
    }

    public func candidateRunningApps() -> [TriggerApp] {
        let existingIds = Set(targetApps.map(\.bundleIdentifier))
        return smartTriggerService.candidateRunningApps(excluding: existingIds)
    }

    private func checkAppTriggersOnDemand() {
        guard appTriggersEnabled, !targetApps.isEmpty else { return }
        let runningBundles = smartTriggerService.runningBundleIdentifiers()
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
            let runningBundles = smartTriggerService.runningBundleIdentifiers()
            let anyStillRunning = targetApps.contains { runningBundles.contains($0.bundleIdentifier) }
            if !anyStillRunning {
                deactivate(reason: reason)
            }

        case .powerDisconnected:
            guard deactivateOnBattery else { return }
            if isActive {
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

    /// Форматированная строка оставшегося времени для отображения в UI поповера
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

    /// Прогресс оставшегося времени (0.0...1.0) для полосы прогресса в карточке Control Center
    public var timerProgress: Double? {
        guard isActive,
              let remaining = remainingSeconds,
              let total = totalDurationSeconds,
              total > 0 else {
            return nil
        }
        return min(max(remaining / total, 0.0), 1.0)
    }

    private func updateMenuBarBadge() {
        let computed = computeMenuBarBadgeText()
        if menuBarBadgeText != computed {
            menuBarBadgeText = computed
        }
    }

    private func computeMenuBarBadgeText() -> String? {
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
        sessionEndTime = nil

        self.isActive = true
        self.lastDeactivationReason = nil
        self.hasSentExpiryNotification = false
        self.totalDurationSeconds = duration
        self.remainingSeconds = duration
        updateMenuBarBadge()

        updateAssertion(activate: true, type: assertionType)

        if let duration = duration {
            startCountdown(duration: duration)
        }

        logger.info("Doppio активирован, режим: \(self.assertionType.rawValue), длительность: \(duration ?? 0) сек")
    }

    private func startCountdown(duration: TimeInterval) {
        let targetEndTime = Date().addingTimeInterval(duration)
        self.sessionEndTime = targetEndTime
        startCountdownLoop(targetEndTime: targetEndTime)
    }

    private func startCountdownLoop(targetEndTime: Date) {
        timerTask?.cancel()
        let clock = ContinuousClock()

        timerTask = Task { [weak self] in
            while !Task.isCancelled {
                guard let self = self else { break }

                let currentRemaining = targetEndTime.timeIntervalSinceNow
                if currentRemaining <= 0 {
                    self.remainingSeconds = 0
                    self.updateMenuBarBadge()
                    self.timerFinished()
                    break
                }

                let sleepSeconds = self.nextSleepInterval(for: currentRemaining)
                try? await clock.sleep(for: .milliseconds(Int(sleepSeconds * 1000)))
                if Task.isCancelled { break }

                self.syncRemainingTime(with: targetEndTime)
            }
        }
    }

    private func syncRemainingTime(with targetEndTime: Date) {
        let remaining = targetEndTime.timeIntervalSinceNow
        if remaining <= 0 {
            self.remainingSeconds = 0
            updateMenuBarBadge()
            timerFinished()
        } else {
            self.remainingSeconds = remaining
            updateMenuBarBadge()

            // Отправка уведомления за 60 секунд до окончания
            if notifyBeforeExpiry,
               !hasSentExpiryNotification,
               remaining <= 60 {
                hasSentExpiryNotification = true
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

    /// Адаптивный интервал сна таймера: 1 сек при открытом поповере, до 60 сек в фоне (Zero Idle CPU)
    private func nextSleepInterval(for remaining: TimeInterval) -> TimeInterval {
        if isPopoverVisible {
            return min(1.0, max(0.05, remaining))
        }

        var nextWakeup = remaining

        // Пробуждение к порогу уведомления (за 60 секунд до окончания)
        if notifyBeforeExpiry && !hasSentExpiryNotification && remaining > 60 {
            nextWakeup = min(nextWakeup, remaining - 60.0)
        }

        // Пробуждение к смене минуты в бейдже строки меню
        if menuBarDisplayStyle == .standard && showTimerInMenuBar {
            let secondsIntoCurrentMinute = remaining.truncatingRemainder(dividingBy: 60.0)
            let toNextMinute = secondsIntoCurrentMinute > 0.1 ? secondsIntoCurrentMinute : 60.0
            nextWakeup = min(nextWakeup, toNextMinute)
        }

        return max(0.1, min(nextWakeup, 60.0))
    }

    private func timerFinished() {
        deactivate(reason: .timerExpired)
    }

    // MARK: - Проверка порога батареи

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
