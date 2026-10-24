import Testing
import Foundation
import AppKit
import SwiftUI
@testable import Doppio

@Suite("Doppio Core Tests")
struct DoppioTests {

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

    @Test("Проверка локализации: Русский, Английский и Немецкий")
    func multiLanguageLocalization() {
        let en = L10n(language: .english)
        #expect(en.statusAwakeIndefinitely == "Awake indefinitely")
        #expect(en.presetIndefinite == "Indefinite")
        #expect(en.modeDisplayAndMac == "Screen & Mac")
        #expect(en.settingsTitle == "Settings")

        let ru = L10n(language: .russian)
        #expect(ru.statusAwakeIndefinitely == "Бодрствует бессрочно")
        #expect(ru.modeDisplayAndMac == "Экран и Mac")
        #expect(ru.settingsTitle == "Настройки")

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
        let testDefaults = UserDefaults(suiteName: "test-sleep-assertion-\(UUID().uuidString)")!
        let state = DoppioState(defaults: testDefaults)
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
        let testDefaults = UserDefaults(suiteName: "test-toggle-\(UUID().uuidString)")!
        let state = DoppioState(defaults: testDefaults)

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
        let state = DoppioState()

        // По умолчанию без таймера
        #expect(state.formattedRemainingTime == "∞")

        state.activate(preset: .hour1)
        #expect(state.formattedRemainingTime.contains(":"))
    }

    @Test("Проверка размеров всплывающего окна (предотвращение схлопывания в полосу)")
    @MainActor
    func popoverFittingDimensions() async {
        let state = DoppioState()
        let view = DoppioPopoverView(state: state)
        let hosting = NSHostingView(rootView: view)
        let size = hosting.fittingSize

        // Окно должно иметь ширину 320 и полноценную высоту меню (более 250pt, не 16pt!)
        #expect(size.width >= 310 && size.width <= 330)
        #expect(size.height >= 250)

        // При выборе своего таймера окно корректно вычисляет расширенную высоту
        state.selectedPreset = .custom
        let customView = DoppioPopoverView(state: state)
        let customHosting = NSHostingView(rootView: customView)
        let customSize = customHosting.fittingSize
        #expect(customSize.height >= size.height)
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

        let state = DoppioState()
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

    private final class MockBattery: BatteryMonitoring, @unchecked Sendable {
        var mockInfo: BatteryInfo?

        init(mockInfo: BatteryInfo?) {
            self.mockInfo = mockInfo
        }

        func fetchBatteryInfo() -> BatteryInfo? {
            mockInfo
        }
    }

    private final class MockLaunchAtLogin: LaunchAtLoginManaging, @unchecked Sendable {
        var isEnabled: Bool = false
        func setEnabled(_ enabled: Bool) -> Bool {
            self.isEnabled = enabled
            return true
        }
    }

    @Test("Проверка внедрения зависимостей и защиты батареи при разряде")
    @MainActor
    func dependencyInjectionAndBatteryProtection() async {
        let mockAssertion = MockSleepAssertion()
        let mockBattery = MockBattery(mockInfo: BatteryInfo(percentage: 80, isCharging: false, isPluggedIn: false))
        let mockLaunch = MockLaunchAtLogin()

        let state = DoppioState(
            assertionService: mockAssertion,
            batteryMonitor: mockBattery,
            launchAtLoginService: mockLaunch
        )

        state.batteryThreshold = 20
        state.batteryProtectionEnabled = true

        // Активируем бодрствование при нормальном заряде
        state.activate(preset: .indefinite)
        #expect(state.isActive)

        // Симулируем падение заряда аккумулятора ниже порога
        mockBattery.mockInfo = BatteryInfo(percentage: 15, isCharging: false, isPluggedIn: false)
        state.refreshBatteryInfo()

        #expect(!state.isActive)
        #expect(state.lastDeactivationReason == .batteryLow(percentage: 15))

        // Проверяем автозапуск через мок
        #expect(!state.isLaunchAtLogin)
        state.toggleLaunchAtLogin()
        #expect(state.isLaunchAtLogin)
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
            launchAtLoginService: mockLaunch
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
        let testDefaults = UserDefaults(suiteName: "test-styles-\(UUID().uuidString)")!
        let state = DoppioState(defaults: testDefaults)
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
        let state = DoppioState()
        let app1 = TriggerApp(bundleIdentifier: "com.apple.dt.Xcode", displayName: "Xcode")
        let app2 = TriggerApp(bundleIdentifier: "com.apple.FinalCut", displayName: "Final Cut Pro")

        state.addTargetApp(app1)
        state.addTargetApp(app2)

        #expect(state.targetApps.count >= 2)
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
        let state = DoppioState()
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
