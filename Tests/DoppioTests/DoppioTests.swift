import Testing
import Foundation
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
        #expect(l10n.quitButton == "Завершити Doppio")
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

    @Test("Проверка автоматического определения языка системы")
    func systemLanguageDetection() {
        let detected = AppLanguage.detectSystemLanguageCode()
        #expect(!detected.isEmpty)
        #expect(["en", "uk", "ru", "de", "fr", "es"].contains(detected))
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
        let state = DoppioState()

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
}
