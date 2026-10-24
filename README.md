# ☕️ Doppio — Keep-Awake Menu Bar Utility for macOS

> Современная, эстетичная и легковесная утилита в строке меню macOS, предотвращающая засыпание Mac во время выполнения длительных задач, презентаций, компиляции кода или рендеринга.

---

## ✨ Ключевые возможности

- ⚡️ **Быстрое переключение в один клик**: большая интерактивная карточка в шапке окна для мгновенного старта или паузы.
- ⏱ **Удобные пресеты времени**:
  - `∞` Бессрочно
  - `15м`, `30м`, `1ч`, `2ч`, `4ч`
  - 🎛 **Свой таймер**: плавный слайдер выбора точного времени (от 5 до 240 минут).
- 🖥 **2 гибких режима предотвращения сна**:
  - **Экран и система**: дисплей не гаснет, экран блокировки не включается (идеально для чтения, вебинаров и презентаций).
  - **Только система**: экран может безопасно погаснуть (для сбережения дисплея/аккумулятора), но процессор, фоновые сетевые загрузки, компиляции и серверы не заснут.
- 📊 **Информативность и статус**:
  - Отображение оставшегося времени прямо в строке меню (например: `☕️ 45м`).
  - Кольцевой анимированный прогресс-бар с обратным отсчётом с точностью до секунды.
  - Мониторинг аккумулятора с индикацией источника питания (Сеть / Батарея / Зарядка).
- 🛡 **Умная защита батареи**:
  - Автоматическое отключение бодрствования при падении уровня заряда ниже порога (настраивается от 10% до 40%), чтобы Mac не сел в дороге.
- 🚀 **Современный автозапуск**:
  - Поддержка запуска при старте системы через нативный `SMAppService`.
- 🌐 **Мультиязычность и автоопределение языка**:
  - Полная поддержка **Української**, **English**, **Русского**, **Deutsch**, **Français**, **Español**.
  - Автоматическое определение языка системы при первом запуске (`Locale.preferredLanguages`).
  - Возможность ручного переключения языка интерфейса на лету в меню настроек.
- 🔔 **Звуковой отклик**:
  - Тонкие системные звуки при активации, завершении таймера или деактивации (можно отключить).

---

## 🏛 Архитектура и технологии (Стандарты 2026 года)

Приложение разработано строго по стандартам современного стека Swift & macOS:

1. **Swift 6 & Strict Concurrency**:
   - `SleepAssertionService` изолирован в виде **Swift Actor** — потокобезопасное управление дескрипторами `IOPMAssertionID` без race conditions.
   - Использование `ContinuousClock` и асинхронных задач `Task` для прецизионного таймера обратного отсчёта.
   - Полное соответствие требованиям `@Sendable` и `isolated deinit`.
2. **SwiftUI 2026 & Observation**:
   - Главная модель `DoppioState` построена на макросе `@Observable` (Observation framework) с изоляцией на `@MainActor`.
   - Использование нативного `MenuBarExtra` со стилем `.window`.
   - Активация режима агента `NSApplication.shared.setActivationPolicy(.accessory)` и `LSUIElement = true` в `Info.plist` — приложение живёт исключительно в строке меню и не засоряет Dock.
3. **IOKit Подсистемы**:
   - `IOKit.pwr_mgt`: создание и надёжный сброс утверждений `kIOPMAssertionTypePreventUserIdleDisplaySleep` и `kIOPMAssertionTypePreventUserIdleSystemSleep`.
   - `IOKit.ps`: нативный опрос состояния силовых контроллеров (`IOPSCopyPowerSourcesInfo`).
4. **ServiceManagement**:
   - `SMAppService.mainApp` — современный официальный API автозапуска без устаревших Helper-приложений и демонов.
5. **Swift Testing**:
   - Полное покрытие логики тестами через современный фреймворк `Testing` (`@Test`, `@Suite`, `#expect`).

---

## 🚀 Сборка и запуск

### Запуск готового приложения:
```bash
open Doppio.app
```

### Сборка из исходников:
```bash
./build_app.sh
```

### Разработка и тесты:
```bash
# Запуск через Swift CLI
swift run

# Запуск тестов
swift test
```

---

## 📂 Структура проекта

```
doppio/
├── Doppio.app/               # Готовый скомпилированный бандл macOS
├── Package.swift             # Конфигурация Swift Package Manager (Swift 6.4)
├── build_app.sh              # Скрипт сборки Release-бандла и ad-hoc подписи
├── Sources/
│   └── Doppio/
│       ├── DoppioApp.swift   # Точка входа SwiftUI @main
│       ├── Models/
│       │   ├── KeepAwakePreset.swift    # Пресеты длительности
│       │   ├── SleepAssertionType.swift # Режимы (экран+система / система)
│       │   └── BatteryInfo.swift        # Модель состояния питания
│       ├── Services/
│       │   ├── SleepAssertionService.swift # Swift Actor над IOKit
│       │   ├── BatteryMonitorService.swift # IOKit Power Sources
│       │   ├── LaunchAtLoginService.swift  # SMAppService автозапуск
│       │   └── NotificationSoundService.swift
│       ├── State/
│       │   └── DoppioState.swift           # @Observable MainActor ViewModel
│       └── Views/
│           ├── MenuBarLabelView.swift      # Иконка и бейдж в строке меню
│           ├── DoppioPopoverView.swift     # Главный плавающий интерфейс
│           └── Components/
│               ├── QuickToggleCard.swift   # Карточка быстрого включения
│               ├── PresetSelectionView.swift # Чипы пресетов и слайдер
│               ├── SleepModeSelectorView.swift # Переключатель режимов
│               ├── CircularProgressTimerView.swift # Кольцевой прогресс
│               ├── BatteryStatusBadge.swift # Индикатор батареи
│               ├── QuickSettingsPanel.swift # Разворачиваемые параметры
│               └── FooterActionsView.swift  # Выход и настройки
└── Tests/
    └── DoppioTests/
        └── DoppioTests.swift # Тесты Swift Testing
```
