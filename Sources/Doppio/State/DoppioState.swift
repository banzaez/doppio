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
            guard customMinutes != oldValue else { return }
            settingsStore.customMinutes = customMinutes
            if isActive && selectedPreset == .custom {
                activate(preset: .custom)
            }
        }
    }

    public var assertionType: SleepAssertionType {
        didSet {
            guard assertionType != oldValue else { return }
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

    /// Открыто ли сейчас окно UI (управляет адаптивной частотой тиков таймера для Zero Idle CPU)
    public var isPopoverVisible: Bool = false {
        didSet {
            guard isPopoverVisible != oldValue else { return }
            timerController.isPopoverVisible = isPopoverVisible
            if isActive {
                timerController.resyncIfNeeded()
            }
        }
    }

    // MARK: - Настройки строки меню и быстрых действий
    public var menuBarDisplayStyle: MenuBarDisplayStyle {
        didSet {
            guard menuBarDisplayStyle != oldValue else { return }
            settingsStore.menuBarDisplayStyle = menuBarDisplayStyle
            syncTimerControllerBadgeConfig()
            updateMenuBarBadge()
        }
    }

    public var showTimerInMenuBar: Bool {
        didSet {
            guard showTimerInMenuBar != oldValue else { return }
            settingsStore.showTimerInMenuBar = showTimerInMenuBar
            syncTimerControllerBadgeConfig()
            updateMenuBarBadge()
        }
    }

    public var quickToggleEnabled: Bool {
        didSet {
            guard quickToggleEnabled != oldValue else { return }
            settingsStore.quickToggleEnabled = quickToggleEnabled
            quickClickMonitor.isEnabled = quickToggleEnabled
        }
    }

    public var notifyBeforeExpiry: Bool {
        didSet {
            guard notifyBeforeExpiry != oldValue else { return }
            settingsStore.notifyBeforeExpiry = notifyBeforeExpiry
            timerController.notifyBeforeExpiry = notifyBeforeExpiry
            if notifyBeforeExpiry {
                Task {
                    await notificationService.requestAuthorization()
                }
            }
            if isActive {
                timerController.resyncIfNeeded()
            }
        }
    }

    // MARK: - Умные триггеры
    public var appTriggersEnabled: Bool {
        didSet {
            guard appTriggersEnabled != oldValue else { return }
            settingsStore.appTriggersEnabled = appTriggersEnabled
            if appTriggersEnabled {
                checkAppTriggersOnDemand()
            } else if isActive, case .appTrigger = activeTriggerSource {
                deactivate(reason: .userDisabled)
            }
        }
    }

    public var targetApps: [TriggerApp] {
        didSet {
            guard targetApps != oldValue else { return }
            settingsStore.targetApps = targetApps
            if isActive, case .appTrigger = activeTriggerSource {
                let runningBundles = smartTriggerService.runningBundleIdentifiers()
                let anyStillRunning = targetApps.contains { runningBundles.contains($0.bundleIdentifier) }
                if !anyStillRunning {
                    deactivate(reason: .userDisabled)
                    return
                }
            }
            checkAppTriggersOnDemand()
        }
    }

    public var activateOnACPower: Bool {
        didSet {
            guard activateOnACPower != oldValue else { return }
            settingsStore.activateOnACPower = activateOnACPower
            if activateOnACPower, let info = batteryInfo, info.isPluggedIn, !isActive {
                activateWithTrigger(.acPower)
            }
        }
    }

    public var deactivateOnBattery: Bool {
        didSet {
            guard deactivateOnBattery != oldValue else { return }
            settingsStore.deactivateOnBattery = deactivateOnBattery
        }
    }

    public var activateOnExternalDisplay: Bool {
        didSet {
            guard activateOnExternalDisplay != oldValue else { return }
            settingsStore.activateOnExternalDisplay = activateOnExternalDisplay
            if activateOnExternalDisplay {
                if smartTriggerService.hasExternalDisplayConnected(), !isActive {
                    activateWithTrigger(.externalDisplay)
                }
            } else if isActive && activeTriggerSource == .externalDisplay {
                deactivate(reason: .userDisabled)
            }
        }
    }

    // MARK: - Защита аккумулятора
    public var batteryProtectionEnabled: Bool {
        didSet {
            guard batteryProtectionEnabled != oldValue else { return }
            settingsStore.batteryProtectionEnabled = batteryProtectionEnabled
            if isActive && batteryProtectionEnabled {
                checkBatteryThreshold()
            }
        }
    }

    public var batteryThreshold: Int {
        didSet {
            guard batteryThreshold != oldValue else { return }
            settingsStore.batteryThreshold = batteryThreshold
            if isActive {
                checkBatteryThreshold()
            }
        }
    }

    public var isLaunchAtLogin: Bool = false

    // MARK: - Автообновления
    public var autoCheckUpdatesEnabled: Bool {
        didSet {
            guard autoCheckUpdatesEnabled != oldValue else { return }
            settingsStore.autoCheckUpdatesEnabled = autoCheckUpdatesEnabled
            updateService.setAutoCheckEnabled(autoCheckUpdatesEnabled)
        }
    }

    // MARK: - Язык и локализация
    public var language: AppLanguage {
        didSet {
            guard language != oldValue else { return }
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
    public let updateService: any AppUpdateManaging
    private let settingsStore: DoppioSettingsStore
    private let timerController = SessionTimerController()
    private let logger = Logger(subsystem: "com.doppio.app", category: "DoppioState")

    private var assertionTask: Task<Void, Never>?

    // MARK: - Инициализация
    public init(
        assertionService: any SleepAssertionManaging = SleepAssertionService(),
        batteryMonitor: any BatteryMonitoring = BatteryMonitorService(),
        launchAtLoginService: any LaunchAtLoginManaging = LaunchAtLoginService(),
        notificationService: any AppNotificationManaging = AppNotificationService.shared,
        smartTriggerService: (any SmartTriggerManaging)? = nil,
        quickClickMonitor: (any QuickClickMonitoring)? = nil,
        updateService: (any AppUpdateManaging)? = nil,
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
        let resolvedUpdateService = updateService ?? AppUpdateService.shared
        self.updateService = resolvedUpdateService

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
        self.autoCheckUpdatesEnabled = store.autoCheckUpdatesEnabled
        resolvedUpdateService.setAutoCheckEnabled(store.autoCheckUpdatesEnabled)

        self.isLaunchAtLogin = launchAtLoginService.isEnabled
        self.batteryInfo = batteryMonitor.fetchBatteryInfo()

        setupTimerController()
        setupQuickClickMonitor()
        setupNotificationHandling()
        setupBatteryMonitoring()
        setupSmartTriggers()
        checkInitialTriggers()

        if Bundle.main.bundleIdentifier != nil, store.autoCheckUpdatesEnabled {
            let lastCheck = store.lastUpdateCheckTime ?? .distantPast
            if Date().timeIntervalSince(lastCheck) > 24 * 3600 {
                store.lastUpdateCheckTime = Date()
                Task { @MainActor [resolvedUpdateService] in
                    try? await Task.sleep(for: .seconds(3))
                    await resolvedUpdateService.checkForUpdates(isUserInitiated: false, l10n: nil)
                }
            }
        }
    }

    isolated deinit {
        timerController.stop()
        assertionTask?.cancel()
        batteryMonitor.stopMonitoring()
        smartTriggerService.stopMonitoring()
    }

    // MARK: - Настройка сервисов и обработчиков

    private func setupTimerController() {
        timerController.notifyBeforeExpiry = notifyBeforeExpiry
        syncTimerControllerBadgeConfig()

        timerController.onTick = { [weak self] remaining in
            guard let self = self else { return }
            self.remainingSeconds = remaining
            self.updateMenuBarBadge()
        }

        timerController.onPreExpiryThresholdReached = { [weak self] in
            guard let self = self else { return }
            Task { [weak self] in
                guard let self = self else { return }
                await self.notificationService.schedulePreExpiryNotification(
                    title: self.l10n.notificationSessionEndingTitle,
                    body: self.l10n.notificationSessionEndingBody,
                    l10n: self.l10n
                )
            }
        }

        timerController.onExpired = { [weak self] in
            guard let self = self else { return }
            self.remainingSeconds = 0
            self.updateMenuBarBadge()
            self.deactivate(reason: .timerExpired)
        }
    }

    private func syncTimerControllerBadgeConfig() {
        timerController.showMinuteBadgeInMenuBar = (menuBarDisplayStyle == .standard && showTimerInMenuBar)
    }

    private func setupQuickClickMonitor() {
        quickClickMonitor.isEnabled = quickToggleEnabled
        quickClickMonitor.onQuickToggle = { [weak self] in
            self?.toggle()
        }
        quickClickMonitor.startMonitoring()
    }

    /// Обновить координаты иконки строки меню через протокол монитора кликов
    public func updateStatusItemFrame(_ frame: NSRect) {
        quickClickMonitor.statusItemScreenFrame = frame
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
        smartTriggerService.onSystemDidWake = { [weak self] in
            self?.handleSystemWake()
        }
        smartTriggerService.startMonitoring()
    }

    private func handleSystemWake() {
        refreshBatteryInfo()
        checkAppTriggersOnDemand()
        smartTriggerService.checkCurrentState()
        if isActive {
            timerController.resyncIfNeeded()
            updateAssertion(activate: true, type: assertionType)
        }
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

        if let remaining = remainingSeconds {
            let newRemaining = remaining + seconds
            let newTotal = (totalDurationSeconds ?? remaining) + seconds
            self.remainingSeconds = newRemaining
            self.totalDurationSeconds = newTotal
            updateMenuBarBadge()
            timerController.restart(duration: newRemaining)
            logger.info("Сессия продлена на \(seconds) сек. Новое время: \(newRemaining) сек")
        }
    }

    /// Выключить бодрствование
    public func deactivate(reason: DeactivationReason = .sessionCompleted) {
        resetSessionState(reason: reason)

        Task {
            await notificationService.cancelPendingNotifications()
        }

        updateAssertion(activate: false, type: assertionType)
    }

    /// Корректное завершение работы приложения с синхронным освобождением ресурсов
    public func quitApplication() {
        assertionTask?.cancel()
        assertionTask = nil
        resetSessionState(reason: .quitApp)

        Task {
            await notificationService.cancelPendingNotifications()
            await assertionService.release()
            NSApplication.shared.terminate(nil)
        }
    }

    private func resetSessionState(reason: DeactivationReason) {
        timerController.stop()
        remainingSeconds = nil
        totalDurationSeconds = nil
        isActive = false
        activeTriggerSource = .manual
        lastDeactivationReason = reason
        updateMenuBarBadge()
        logger.info("Doppio деактивирован: \(reason.localized(using: self.l10n))")
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

    public func runningBundleIdentifiers() -> Set<String> {
        smartTriggerService.runningBundleIdentifiers()
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

        case .externalDisplay:
            guard activateOnExternalDisplay else { return }
            if !isActive {
                activateWithTrigger(.externalDisplay)
            }

        case .manual, .acPower:
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

        case .externalDisplayDisconnected:
            if isActive && activeTriggerSource == .externalDisplay {
                deactivate(reason: reason)
            }

        default:
            break
        }
    }

    // MARK: - Вспомогательные вычисляемые свойства

    /// Локализованная строка текущего статуса сессии для меню и UI
    public var statusSubtitle: String {
        if isActive {
            if remainingSeconds != nil {
                return l10n.statusRemaining(formattedRemainingTime)
            } else {
                return l10n.statusAwakeIndefinitely
            }
        } else {
            return l10n.statusSleepAllowed
        }
    }

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

        timerController.stop()

        self.isActive = true
        self.lastDeactivationReason = nil
        self.totalDurationSeconds = duration
        self.remainingSeconds = duration
        updateMenuBarBadge()

        updateAssertion(activate: true, type: assertionType)

        if let duration = duration {
            timerController.start(duration: duration)
        }

        logger.info("Doppio активирован, режим: \(self.assertionType.rawValue), длительность: \(duration ?? 0) сек")
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
