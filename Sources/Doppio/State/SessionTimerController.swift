import Foundation

/// Изолированный контроллер монотонного таймера сессии (ContinuousClock + Zero-Idle CPU)
/// Не зависит от сдвигов системных часов (NTP / часовые пояса) и адаптирует частоту пробуждений
@MainActor
public final class SessionTimerController {
    private let clock = ContinuousClock()
    private var deadline: ContinuousClock.Instant?
    private var timerTask: Task<Void, Never>?
    private var hasSentExpiryNotification: Bool = false

    public var isPopoverVisible: Bool = false
    public var notifyBeforeExpiry: Bool = true
    public var showMinuteBadgeInMenuBar: Bool = true

    public var onTick: ((TimeInterval) -> Void)?
    public var onPreExpiryThresholdReached: (() -> Void)?
    public var onExpired: (() -> Void)?

    public init() {}

    isolated deinit {
        timerTask?.cancel()
    }

    public var isRunning: Bool {
        deadline != nil
    }

    /// Запуск нового отсчёта на указанную длительность
    public func start(duration: TimeInterval) {
        let targetDeadline = clock.now.advanced(by: .milliseconds(Int(duration * 1000)))
        self.deadline = targetDeadline
        self.hasSentExpiryNotification = false
        startCountdownLoop(targetDeadline: targetDeadline)
    }

    /// Продление или перезапуск с новым временем (сбрасывает флаг уведомления о скором завершении)
    public func restart(duration: TimeInterval) {
        self.hasSentExpiryNotification = false
        let targetDeadline = clock.now.advanced(by: .milliseconds(Int(duration * 1000)))
        self.deadline = targetDeadline
        startCountdownLoop(targetDeadline: targetDeadline)
    }

    /// Остановка таймера
    public func stop() {
        timerTask?.cancel()
        timerTask = nil
        deadline = nil
        hasSentExpiryNotification = false
    }

    /// Мгновенная синхронизация оставшегося времени и перезапуск цикла ожидания
    /// Вызывается при открытии/закрытии поповера, смене настроек бейджа или пробуждении Mac из сна
    public func resyncIfNeeded() {
        guard let targetDeadline = deadline else { return }
        syncRemainingTime(with: targetDeadline)
        if deadline != nil {
            startCountdownLoop(targetDeadline: targetDeadline)
        }
    }

    /// Вычисление адаптивного интервала сна: 1 сек при открытом поповере, до 60 сек в фоне (Zero Idle CPU)
    public func nextSleepInterval(for remaining: TimeInterval) -> TimeInterval {
        if isPopoverVisible {
            return min(1.0, max(0.05, remaining))
        }

        var nextWakeup = remaining

        // Пробуждение ровно к порогу уведомления (за 60 секунд до окончания)
        if notifyBeforeExpiry && !hasSentExpiryNotification && remaining > 60 {
            nextWakeup = min(nextWakeup, remaining - 60.0)
        }

        // Пробуждение к смене минуты в бейдже строки меню
        if showMinuteBadgeInMenuBar {
            let secondsIntoCurrentMinute = remaining.truncatingRemainder(dividingBy: 60.0)
            let toNextMinute = secondsIntoCurrentMinute > 0.1 ? secondsIntoCurrentMinute : 60.0
            nextWakeup = min(nextWakeup, toNextMinute)
        }

        return max(0.1, min(nextWakeup, 60.0))
    }

    // MARK: - Внутренний цикл

    private func remainingSeconds(until targetDeadline: ContinuousClock.Instant) -> TimeInterval {
        let duration = clock.now.duration(to: targetDeadline)
        return Double(duration.components.seconds) + Double(duration.components.attoseconds) / 1e18
    }

    private func startCountdownLoop(targetDeadline: ContinuousClock.Instant) {
        timerTask?.cancel()

        timerTask = Task { [weak self, clock] in
            while !Task.isCancelled {
                guard let self = self else { break }

                let currentRemaining = self.remainingSeconds(until: targetDeadline)
                if currentRemaining <= 0 {
                    self.stop()
                    self.onExpired?()
                    break
                }

                let sleepSeconds = self.nextSleepInterval(for: currentRemaining)
                try? await clock.sleep(for: .milliseconds(Int(sleepSeconds * 1000)))
                if Task.isCancelled { break }

                self.syncRemainingTime(with: targetDeadline)
            }
        }
    }

    private func syncRemainingTime(with targetDeadline: ContinuousClock.Instant) {
        let remaining = remainingSeconds(until: targetDeadline)
        if remaining <= 0 {
            stop()
            onExpired?()
        } else {
            onTick?(remaining)

            if notifyBeforeExpiry,
               !hasSentExpiryNotification,
               remaining <= 60 {
                hasSentExpiryNotification = true
                onPreExpiryThresholdReached?()
            }
        }
    }
}
