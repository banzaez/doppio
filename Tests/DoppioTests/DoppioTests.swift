import Testing
import Foundation
import AppKit
import SwiftUI
@testable import Doppio

@Suite("Doppio Core Tests")
struct DoppioTests {

    private func makeTestDefaults() -> UserDefaults {
        UserDefaults(suiteName: "com.doppio.tests.\(UUID().uuidString)")!
    }

    @Test("Проверка длительностей пресетов")
    func presetDurations() {
        #expect(KeepAwakePreset.indefinite.duration == nil)
        #expect(KeepAwakePreset.minutes15.duration == 15 * 60.0)
        #expect(KeepAwakePreset.minutes30.duration == 30 * 60.0)
        #expect(KeepAwakePreset.hour1.duration == 60 * 60.0)
        #expect(KeepAwakePreset.hours2.duration == 2 * 60 * 60.0)
        #expect(KeepAwakePreset.hours4.duration == 4 * 60 * 60.0)
        #expect(KeepAwakePreset.custom.duration == nil)
    }

    @Test("Проверка модели батареи")
    func batteryInfoFormatting() {
        let charging = BatteryInfo(percentage: 85, isCharging: true, isPluggedIn: true)
        #expect(charging.iconName == "battery.100.bolt")

        let onBattery = BatteryInfo(percentage: 45, isCharging: false, isPluggedIn: false)
        #expect(onBattery.iconName == "battery.50")

        let plugged = BatteryInfo(percentage: 100, isCharging: false, isPluggedIn: true)
        #expect(plugged.iconName == "battery.100")
    }

    @Test("Проверка локализации: Украинский язык")
    func ukrainianLocalization() {
        let l10n = L10n(language: .ukrainian)
        #expect(l10n.statusAwakeIndefinitely == "Бадьорий безстроково")
        #expect(l10n.presetIndefinite == "Безстроково")
        #expect(l10n.modeDisplayAndMac == "Екран і Mac")
        #expect(l10n.modeMacOnly == "Тільки Mac")
        #expect(l10n.settingsTitle == "Налаштування")
        #expect(l10n.backButton == "Назад")
        #expect(l10n.closeButton == "Закрити")
        #expect(l10n.quitButton == "Закрити Doppio")
        #expect(l10n.settingsLaunchAtLogin == "Запуск під час входу в систему")
    }

    @Test("Проверка локализации: Русский, Английский и Немецкий + плюрализация часов")
    func multiLanguageLocalization() {
        let en = L10n(language: .english)
        #expect(en.statusAwakeIndefinitely == "Awake indefinitely")
        #expect(en.presetIndefinite == "Indefinite")
        #expect(en.modeDisplayAndMac == "Screen & Mac")
        #expect(en.settingsTitle == "Settings")
        #expect(en.presetHours(1) == "1 hour")
        #expect(en.presetHours(5) == "5 hours")

        let ru = L10n(language: .russian)
        #expect(ru.statusAwakeIndefinitely == "Бодрствует бессрочно")
        #expect(ru.modeDisplayAndMac == "Экран и Mac")
        #expect(ru.settingsTitle == "Настройки")
        #expect(ru.presetHours(1) == "1 час")
        #expect(ru.presetHours(2) == "2 часа")
        #expect(ru.presetHours(5) == "5 часов")

        let de = L10n(language: .german)
        #expect(de.statusAwakeIndefinitely == "Dauerhaft aktiv")
        #expect(de.settingsTitle == "Einstellungen")
    }

    @Test("Проверка автоматического определения языка системы по умолчанию")
    func systemLanguageDetection() {
        let detected = AppLanguage.detectSystemLanguageCode()
        #expect(!detected.isEmpty)
        #expect(["en", "uk", "ru", "de", "fr", "es"].contains(detected))
        let defaultLang = AppLanguage.defaultLanguage
        #expect(AppLanguage.allCases.contains(defaultLang))
    }

    @Test("Проверка правильной алфавитной сортировки языков")
    func languageSortingOrder() {
        let expectedOrder: [AppLanguage] = [.german, .english, .spanish, .french, .russian, .ukrainian]
        #expect(AppLanguage.allCases == expectedOrder)
        #expect(AppLanguage.allCases.map(\.displayName) == ["Deutsch", "English", "Español", "Français", "Русский", "Українська"])
    }

    @Test("Проверка порядка режимов и значения по умолчанию")
    @MainActor
    func sleepAssertionTypeOrderAndDefault() {
        #expect(SleepAssertionType.allCases == [.systemOnly, .systemAndDisplay])
        let state = DoppioState(defaults: makeTestDefaults())
        #expect(state.assertionType == .systemOnly)
    }

    @Test("Проверка IOKit SleepAssertionService")
    func sleepAssertionServiceLifeCycle() async {
        let service = SleepAssertionService()

        #expect(await !service.isHoldingAssertion)

        let success = await service.activate(type: .systemOnly, reason: "Unit Test")
        #expect(success)
        #expect(await service.isHoldingAssertion)
        #expect(await service.activeType == .systemOnly)

        // Переключение на другой тип
        let switched = await service.activate(type: .systemAndDisplay, reason: "Unit Test 2")
        #expect(switched)
        #expect(await service.isHoldingAssertion)
        #expect(await service.activeType == .systemAndDisplay)

        // Освобождение
        await service.release()
        #expect(await !service.isHoldingAssertion)
        #expect(await service.activeType == nil)
    }

    @Test("Проверка переключения DoppioState и языка")
    @MainActor
    func doppioStateToggleAndActivation() async {
        let state = DoppioState(defaults: makeTestDefaults())

        #expect(!state.isActive)
        #expect(state.remainingSeconds == nil)

        // Смена языка на украинский
        state.language = .ukrainian
        #expect(state.l10n.presetIndefinite == "Безстроково")

        // Активация на 15 минут
        state.activate(preset: .minutes15)
        #expect(state.isActive)
        #expect(state.selectedPreset == .minutes15)
        #expect(state.totalDurationSeconds == 15 * 60.0)
        #expect(state.remainingSeconds != nil)
        #expect(state.menuBarBadgeText != nil)

        // Быстрое переключение (выключение)
        state.toggle()
        #expect(!state.isActive)
        #expect(state.remainingSeconds == nil)
        #expect(state.menuBarBadgeText == nil)
    }

    @Test("Проверка форматирования времени")
    @MainActor
    func formattingTime() async {
        let state = DoppioState(defaults: makeTestDefaults())

        // По умолчанию без таймера
        #expect(state.formattedRemainingTime == "∞")

        state.activate(preset: .hour1)
        #expect(state.formattedRemainingTime.contains(":"))
    }

    @Test("Проверка размеров всплывающего окна и экрана настроек (адаптивность и отсутствие переполнения)")
    @MainActor
    func popoverFittingDimensions() async {
        let state = DoppioState(defaults: makeTestDefaults())
        let view = DoppioPopoverView(state: state)
        let hosting = NSHostingView(rootView: view)
        let size = hosting.fittingSize

        // Окно должно иметь ширину 320 и полноценную высоту меню (более 250pt, не 16pt!)
        #expect(size.width >= 310 && size.width <= 330)
        #expect(size.height >= 250 && size.height <= 380)

        // При активации таймера с полосой прогресса и бейджем триггера высота карточки остаётся неизменной (не скачет!)
        state.activate(preset: .minutes30)
        let activeHosting = NSHostingView(rootView: DoppioPopoverView(state: state))
        #expect(abs(activeHosting.fittingSize.height - size.height) < 1.0)

        // Проверяем экран настроек с 6 добавленными приложениями — благодаря адаптивному ScrollView высота компактна и влезает на любой экран
        for i in 1...6 {
            state.addTargetApp(TriggerApp(bundleIdentifier: "com.test.app\(i)", displayName: "Application \(i)"))
        }
        let settingsHosting = NSHostingView(rootView: SettingsView(state: state, onBack: {}).frame(width: 294))
        let settingsSize = settingsHosting.fittingSize
        #expect(settingsSize.height >= 300 && settingsSize.height <= 560)
    }

    @Test("Проверка причин деактивации и локализации")
    @MainActor
    func deactivationReasonsLocalization() async {
        let en = L10n(language: .english)
        let ru = L10n(language: .russian)
        let uk = L10n(language: .ukrainian)

        let reasonTimer = DeactivationReason.timerExpired
        #expect(reasonTimer.localized(using: en) == "Timer expired")
        #expect(reasonTimer.localized(using: ru) == "Время таймера истекло")
        #expect(reasonTimer.localized(using: uk) == "Час таймера вичерпано")

        let reasonBattery = DeactivationReason.batteryLow(percentage: 15)
        #expect(reasonBattery.localized(using: en) == "Low battery (15%)")
        #expect(reasonBattery.localized(using: ru) == "Низкий заряд батареи (15%)")
        #expect(reasonBattery.localized(using: uk) == "Низький заряд батареї (15%)")

        let state = DoppioState(defaults: makeTestDefaults())
        state.deactivate(reason: .timerExpired)
        #expect(state.lastDeactivationReason == .timerExpired)
        #expect(state.localizedDeactivationReason != nil)

        state.clearDeactivationReason()
        #expect(state.lastDeactivationReason == nil)
        #expect(state.localizedDeactivationReason == nil)
    }

    // MARK: - Mocks & Dependency Injection Tests

    private actor MockSleepAssertion: SleepAssertionManaging {
        var isHoldingAssertion: Bool = false
        var activeType: SleepAssertionType? = nil

        func activate(type: SleepAssertionType, reason: String) async -> Bool {
            self.isHoldingAssertion = true
            self.activeType = type
            return true
        }

        func release() async {
            self.isHoldingAssertion = false
            self.activeType = nil
        }
    }

    @MainActor
    private final class MockBattery: BatteryMonitoring {
        var mockInfo: BatteryInfo?
        var onChange: (@MainActor () -> Void)?

        init(mockInfo: BatteryInfo?) {
            self.mockInfo = mockInfo
        }

        func fetchBatteryInfo() -> BatteryInfo? {
            mockInfo
        }

        func startMonitoring(onChange: @escaping @MainActor () -> Void) {
            self.onChange = onChange
        }

        func stopMonitoring() {
            self.onChange = nil
        }
    }

    @MainActor
    private final class MockLaunchAtLogin: LaunchAtLoginManaging {
        var isEnabled: Bool = false
        func setEnabled(_ enabled: Bool) -> Bool {
            self.isEnabled = enabled
            return true
        }
    }

    @MainActor
    private final class MockSmartTrigger: SmartTriggerManaging {
        var onRequestActivation: (@MainActor (SessionTriggerSource) -> Void)?
        var onRequestDeactivation: (@MainActor (DeactivationReason) -> Void)?
        var externalDisplayConnected: Bool = false
        var runningBundles: Set<String> = []

        func startMonitoring() {}
        func stopMonitoring() {}
        func checkCurrentState() {
            if externalDisplayConnected {
                onRequestActivation?(.externalDisplay)
            }
        }
        func hasExternalDisplayConnected() -> Bool { externalDisplayConnected }
        func runningBundleIdentifiers() -> Set<String> { runningBundles }
        func candidateRunningApps(excluding existingBundleIds: Set<String>) -> [TriggerApp] { [] }
        func triggerApp(from url: URL) -> TriggerApp? { nil }
    }

    @MainActor
    private final class MockNotificationService: AppNotificationManaging {
        var onActionReceived: (@MainActor (NotificationPreExpiryAction) -> Void)?
        func requestAuthorization() async -> Bool { true }
        func schedulePreExpiryNotification(title: String, body: String, l10n: L10n) async {}
        func cancelPendingNotifications() async {}
    }

    @MainActor
    private final class MockQuickClickMonitor: QuickClickMonitoring {
        var isEnabled: Bool = true
        var onQuickToggle: (() -> Void)?
        func startMonitoring() {}
        func stopMonitoring() {}
    }

    @Test("Проверка внедрения зависимостей, защиты батареи и событийного триггера питания")
    @MainActor
    func dependencyInjectionAndBatteryProtection() async {
        let mockAssertion = MockSleepAssertion()
        let mockBattery = MockBattery(mockInfo: BatteryInfo(percentage: 80, isCharging: false, isPluggedIn: false))
        let mockLaunch = MockLaunchAtLogin()
        let mockTrigger = MockSmartTrigger()
        let mockNotif = MockNotificationService()
        let mockQuickClick = MockQuickClickMonitor()

        let state = DoppioState(
            assertionService: mockAssertion,
            batteryMonitor: mockBattery,
            launchAtLoginService: mockLaunch,
            notificationService: mockNotif,
            smartTriggerService: mockTrigger,
            quickClickMonitor: mockQuickClick,
            defaults: makeTestDefaults()
        )

        state.batteryThreshold = 20
        state.batteryProtectionEnabled = true
        state.activateOnACPower = true
        state.deactivateOnBattery = true

        // Симулируем подключение адаптера питания через событийный коллбэк IOKit
        mockBattery.mockInfo = BatteryInfo(percentage: 80, isCharging: true, isPluggedIn: true)
        mockBattery.onChange?()

        #expect(state.isActive)
        #expect(state.activeTriggerSource == .acPower)

        // Симулируем отключение адаптера питания
        mockBattery.mockInfo = BatteryInfo(percentage: 80, isCharging: false, isPluggedIn: false)
        mockBattery.onChange?()

        #expect(!state.isActive)
        #expect(state.lastDeactivationReason == .powerDisconnected)

        // Активируем вручную и симулируем разряд батареи ниже порога
        state.activate(preset: .indefinite)
        #expect(state.isActive)

        mockBattery.mockInfo = BatteryInfo(percentage: 15, isCharging: false, isPluggedIn: false)
        mockBattery.onChange?()

        #expect(!state.isActive)
        #expect(state.lastDeactivationReason == .batteryLow(percentage: 15))

        // Проверяем автозапуск через мок
        #expect(!state.isLaunchAtLogin)
        state.toggleLaunchAtLogin()
        #expect(state.isLaunchAtLogin)
    }

    @Test("Проверка протокольных коллбэков уведомлений и умных триггеров без downcasting")
    @MainActor
    func notificationAndSmartTriggerProtocolCallbacks() {
        let mockAssertion = MockSleepAssertion()
        let mockBattery = MockBattery(mockInfo: nil)
        let mockLaunch = MockLaunchAtLogin()
        let mockTrigger = MockSmartTrigger()
        let mockNotif = MockNotificationService()
        let mockQuickClick = MockQuickClickMonitor()

        let state = DoppioState(
            assertionService: mockAssertion,
            batteryMonitor: mockBattery,
            launchAtLoginService: mockLaunch,
            notificationService: mockNotif,
            smartTriggerService: mockTrigger,
            quickClickMonitor: mockQuickClick,
            defaults: makeTestDefaults()
        )

        // Тестируем быстрый клик через мок
        mockQuickClick.onQuickToggle?()
        #expect(state.isActive)
        mockQuickClick.onQuickToggle?()
        #expect(!state.isActive)

        // Тестируем активацию и деактивацию через внешний монитор
        state.activateOnExternalDisplay = true
        mockTrigger.externalDisplayConnected = true
        mockTrigger.onRequestActivation?(.externalDisplay)
        #expect(state.isActive)
        #expect(state.activeTriggerSource == .externalDisplay)

        mockTrigger.externalDisplayConnected = false
        mockTrigger.onRequestDeactivation?(.externalDisplayDisconnected)
        #expect(!state.isActive)
        #expect(state.lastDeactivationReason == .externalDisplayDisconnected)

        // Тестируем коллбэк от уведомления (перевод в бессрочный режим)
        state.activate(preset: .minutes15)
        #expect(state.remainingSeconds != nil)
        mockNotif.onActionReceived?(.makeIndefinite)
        #expect(state.isActive)
        #expect(state.selectedPreset == .indefinite)
        #expect(state.remainingSeconds == nil)
    }

    @Test("Проверка поведения на настольном Mac (без аккумулятора)")
    @MainActor
    func desktopMacBehavior() async {
        let mockAssertion = MockSleepAssertion()
        let mockBattery = MockBattery(mockInfo: nil) // Desktop Mac (Mac mini, Mac Studio, Mac Pro)
        let mockLaunch = MockLaunchAtLogin()

        let state = DoppioState(
            assertionService: mockAssertion,
            batteryMonitor: mockBattery,
            launchAtLoginService: mockLaunch,
            defaults: makeTestDefaults()
        )

        #expect(state.batteryInfo == nil)

        // Активация должна беспрепятственно работать на Desktop Mac
        state.activate(preset: .minutes30)
        #expect(state.isActive)
        state.deactivate()
        #expect(!state.isActive)
    }

    @Test("Проверка режимов строки меню (MenuBarDisplayStyle) и бейджа")
    @MainActor
    func menuBarDisplayStylesAndBadge() {
        let state = DoppioState(defaults: makeTestDefaults())
        state.activate(preset: .minutes30)
        #expect(state.isActive)

        // 1. Стандартный режим
        state.menuBarDisplayStyle = .standard
        state.showTimerInMenuBar = true
        #expect(state.menuBarBadgeText != nil)

        // 2. Только иконка: бейдж времени должен скрываться
        state.menuBarDisplayStyle = .iconOnly
        #expect(state.menuBarBadgeText == nil)

        // Проверка локализованных названий стилей
        let l10n = L10n(language: .english)
        #expect(MenuBarDisplayStyle.standard.title(using: l10n) == "Standard")
        #expect(MenuBarDisplayStyle.iconOnly.title(using: l10n) == "Icon only")
    }

    @Test("Проверка управления целевыми приложениями (App Triggers)")
    @MainActor
    func smartTriggersAppManagement() {
        let state = DoppioState(defaults: makeTestDefaults())
        let app1 = TriggerApp(bundleIdentifier: "com.apple.dt.Xcode", displayName: "Xcode")
        let app2 = TriggerApp(bundleIdentifier: "com.apple.FinalCut", displayName: "Final Cut Pro")

        state.addTargetApp(app1)
        state.addTargetApp(app2)

        #expect(state.targetApps.count == 2)
        #expect(state.targetApps.contains(where: { $0.bundleIdentifier == "com.apple.dt.Xcode" }))

        // Проверка активации по триггеру приложения
        state.activateWithTrigger(.appTrigger(bundleId: app1.bundleIdentifier, appName: app1.displayName))
        #expect(state.isActive)
        #expect(state.activeTriggerSource == .appTrigger(bundleId: app1.bundleIdentifier, appName: app1.displayName))

        // Удаление приложения
        state.removeTargetApp(id: app1.id)
        #expect(!state.targetApps.contains(where: { $0.id == app1.id }))

        state.deactivate(reason: .appTerminated(appName: app1.displayName))
        #expect(!state.isActive)
        #expect(state.lastDeactivationReason == .appTerminated(appName: "Xcode"))
    }

    @Test("Проверка продления сессии и причин деактивации триггеров")
    @MainActor
    func sessionExtensionAndTriggerReasons() {
        let state = DoppioState(defaults: makeTestDefaults())
        state.activate(preset: .minutes15)
        #expect(state.isActive)

        let initialRemaining = state.remainingSeconds ?? 0
        state.extendSession(by: 900) // +15 минут
        let newRemaining = state.remainingSeconds ?? 0
        #expect(newRemaining >= initialRemaining + 890)

        // Проверка локализации новых причин деактивации
        let ru = L10n(language: .russian)
        let en = L10n(language: .english)
        let uk = L10n(language: .ukrainian)

        let reasonApp = DeactivationReason.appTerminated(appName: "Xcode")
        #expect(reasonApp.localized(using: ru) == "Закрыто: Xcode")
        #expect(reasonApp.localized(using: en) == "Closed: Xcode")
        #expect(reasonApp.localized(using: uk) == "Закрито: Xcode")

        let reasonPower = DeactivationReason.powerDisconnected
        #expect(reasonPower.localized(using: ru) == "Отключено питание от сети")
        #expect(reasonPower.localized(using: en) == "AC power disconnected")

        let reasonDisplay = DeactivationReason.externalDisplayDisconnected
        #expect(reasonDisplay.localized(using: ru) == "Внешний дисплей отключен")
        #expect(reasonDisplay.localized(using: en) == "External display disconnected")
    }
}
