import Foundation
import Observation
import os

/// Главная модель состояния приложения Doppio
/// Построена на основе Observation framework (@Observable) и Swift Concurrency (@MainActor)
@Observable
@MainActor
public final class DoppioState {
    // MARK: - Активное состояние
    public private(set) var isActive: Bool = false
    public var selectedPreset: KeepAwakePreset = .indefinite
    public var customMinutes: Int = 45 {
        didSet {
            UserDefaults.standard.set(customMinutes, forKey: "customMinutes")
        }
    }
    public var assertionType: SleepAssertionType = .systemAndDisplay {
        didSet {
            UserDefaults.standard.set(assertionType.rawValue, forKey: "assertionType")
            if isActive {
                Task {
                    await assertionService.activate(type: assertionType)
                }
            }
        }
    }

    // MARK: - Таймер
    public private(set) var remainingSeconds: TimeInterval? = nil
    public private(set) var totalDurationSeconds: TimeInterval? = nil

    // MARK: - Настройки
    public var showTimerInMenuBar: Bool = true {
        didSet {
            UserDefaults.standard.set(showTimerInMenuBar, forKey: "showTimerInMenuBar")
        }
    }

    public var batteryProtectionEnabled: Bool = true {
        didSet {
            UserDefaults.standard.set(batteryProtectionEnabled, forKey: "batteryProtectionEnabled")
        }
    }

    public var batteryThreshold: Int = 20 {
        didSet {
            UserDefaults.standard.set(batteryThreshold, forKey: "batteryThreshold")
        }
    }

    public var soundFeedbackEnabled: Bool = true {
        didSet {
            UserDefaults.standard.set(soundFeedbackEnabled, forKey: "soundFeedbackEnabled")
        }
    }

    public var isLaunchAtLogin: Bool = false

    // MARK: - Язык и локализация
    public var language: AppLanguage = .system {
        didSet {
            UserDefaults.standard.set(language.rawValue, forKey: "appLanguage")
            self.l10n = L10n(language: language)
        }
    }
    public private(set) var l10n: L10n = L10n(language: .system)

    // MARK: - Питание
    public private(set) var batteryInfo: BatteryInfo? = nil
    public private(set) var lastDeactivationReason: String? = nil

    // MARK: - Зависимости
    private let assertionService = SleepAssertionService()
    private let batteryMonitor = BatteryMonitorService()
    private let launchAtLoginService = LaunchAtLoginService()
    private let soundService = NotificationSoundService.shared
    private let logger = Logger(subsystem: "com.doppio.app", category: "DoppioState")

    private var timerTask: Task<Void, Never>?
    private var batteryCheckTask: Task<Void, Never>?

    // MARK: - Инициализация
    public init() {
        loadPersistedSettings()
        refreshBatteryInfo()
        self.isLaunchAtLogin = launchAtLoginService.isEnabled

        startBatteryMonitoring()
    }

    isolated deinit {
        timerTask?.cancel()
        batteryCheckTask?.cancel()
    }

    // MARK: - Загрузка сохранённых настроек
    private func loadPersistedSettings() {
        let defaults = UserDefaults.standard

        if let rawType = defaults.string(forKey: "assertionType"),
           let type = SleepAssertionType(rawValue: rawType) {
            self.assertionType = type
        }

        if defaults.object(forKey: "showTimerInMenuBar") != nil {
            self.showTimerInMenuBar = defaults.bool(forKey: "showTimerInMenuBar")
        }

        if defaults.object(forKey: "batteryProtectionEnabled") != nil {
            self.batteryProtectionEnabled = defaults.bool(forKey: "batteryProtectionEnabled")
        }

        if defaults.object(forKey: "batteryThreshold") != nil {
            let threshold = defaults.integer(forKey: "batteryThreshold")
            if threshold >= 5 && threshold <= 50 {
                self.batteryThreshold = threshold
            }
        }

        if defaults.object(forKey: "soundFeedbackEnabled") != nil {
            self.soundFeedbackEnabled = defaults.bool(forKey: "soundFeedbackEnabled")
        }

        if defaults.object(forKey: "customMinutes") != nil {
            let minutes = defaults.integer(forKey: "customMinutes")
            if minutes > 0 {
                self.customMinutes = minutes
            }
        }

        if let rawLang = defaults.string(forKey: "appLanguage"),
           let savedLang = AppLanguage(rawValue: rawLang) {
            self.language = savedLang
        } else {
            self.language = .system
        }
        self.l10n = L10n(language: self.language)
    }

    // MARK: - Публичные действия

    /// Быстрое переключение бодрствования
    public func toggle() {
        if isActive {
            deactivate(reason: "Отключено пользователем")
        } else {
            activate(preset: selectedPreset)
        }
    }

    /// Включить бодрствование с пресетом
    public func activate(preset: KeepAwakePreset) {
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

    /// Выключить бодрствование
    public func deactivate(reason: String = "Сессия завершена") {
        timerTask?.cancel()
        timerTask = nil

        remainingSeconds = nil
        totalDurationSeconds = nil
        isActive = false
        lastDeactivationReason = reason

        Task {
            await assertionService.release()
        }

        if soundFeedbackEnabled {
            soundService.playDeactivateSound()
        }

        logger.info("Doppio деактивирован: \(reason)")
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
        self.batteryInfo = batteryMonitor.fetchBatteryInfo()
        checkBatteryThreshold()
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
        guard isActive, showTimerInMenuBar, let remaining = remainingSeconds, remaining > 0 else {
            return nil
        }

        let hours = Int(remaining) / 3600
        let minutes = (Int(remaining) % 3600) / 60

        let code = l10n.language.effectiveCode
        let hSuffix = code == "uk" ? "г" : (code == "ru" ? "ч" : "h")
        let mSuffix = code == "uk" ? "хв" : (code == "ru" ? "м" : "m")

        if hours > 0 {
            return "\(hours)\(hSuffix)\(minutes > 0 ? " \(minutes)\(mSuffix)" : "")"
        } else if minutes > 0 {
            return "\(minutes)\(mSuffix)"
        } else {
            return "<1\(mSuffix)"
        }
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

    // MARK: - Внутренняя логика сессии

    private func startActiveSession(duration: TimeInterval?) {
        // Проверка батареи перед запуском
        if batteryProtectionEnabled,
           let info = batteryInfo,
           !info.isPluggedIn && !info.isCharging,
           info.percentage <= batteryThreshold {
            lastDeactivationReason = "Низкий заряд батареи (\(info.percentage)%)"
            return
        }

        timerTask?.cancel()
        timerTask = nil

        self.isActive = true
        self.lastDeactivationReason = nil
        self.totalDurationSeconds = duration
        self.remainingSeconds = duration

        Task {
            await assertionService.activate(type: assertionType)
        }

        if soundFeedbackEnabled {
            soundService.playActivateSound()
        }

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
                }
            }
        }
    }

    private func timerFinished() {
        deactivate(reason: "Время таймера истекло")
        if soundFeedbackEnabled {
            soundService.playCompletionSound()
        }
    }

    // MARK: - Мониторинг батареи

    private func startBatteryMonitoring() {
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

    private func checkBatteryThreshold() {
        guard isActive,
              batteryProtectionEnabled,
              let info = batteryInfo,
              !info.isPluggedIn && !info.isCharging else {
            return
        }

        if info.percentage <= batteryThreshold {
            deactivate(reason: "Батарея разряжена до \(info.percentage)%")
        }
    }
}
