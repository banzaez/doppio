import SwiftUI

/// Премиальное классическое выпадающее меню macOS (NSMenu) в нативном системном стекле
struct DoppioMenuView: View {
    @Bindable var state: DoppioState

    private let standardPresets: [KeepAwakePreset] = [
        .indefinite,
        .minutes15,
        .minutes30,
        .hour1,
        .hours2,
        .hours4
    ]

    private let customQuickMinutes = [5, 10, 20, 45, 60, 90, 120, 180]

    var body: some View {
        // 1. Статус сессии, оставшееся время и быстрое управление
        statusSection

        Divider()

        // 2. Пресеты длительности в 1 клик с системными галочками
        presetsSection

        Divider()

        // 3. Режим сна и стиль отображения в строке меню
        modeAndAppearanceSection

        Divider()

        // 4. Умные триггеры автоматизации и батарея
        smartTriggersAndBatterySection

        Divider()

        // 5. Системные действия: Настройки и Выход
        systemActionsSection
    }

    // MARK: - Секции меню

    @ViewBuilder
    private var statusSection: some View {
        if state.isActive {
            let subtitle = state.remainingSeconds != nil
                ? state.l10n.statusRemaining(state.formattedRemainingTime)
                : state.l10n.statusAwakeIndefinitely

            Text("☕️ Doppio: \(subtitle)")

            if let triggerName = state.activeTriggerSource.badgeTitle(using: state.l10n) {
                Text("   ⚡️ \(triggerName)")
            }

            Button(state.l10n.menuDeactivate) {
                state.deactivate(reason: .userDisabled)
            }

            // Быстрое продление активной сессии
            if state.remainingSeconds != nil {
                Menu(state.l10n.menuExtend) {
                    Button("+15 \(state.l10n.minuteSuffix)") {
                        state.extendSession(by: 15 * 60)
                    }
                    Button("+30 \(state.l10n.minuteSuffix)") {
                        state.extendSession(by: 30 * 60)
                    }
                    Button("+1 \(state.l10n.presetHours(1))") {
                        state.extendSession(by: 60 * 60)
                    }
                    Divider()
                    Button(state.l10n.menuMakeIndefinite) {
                        state.activate(preset: .indefinite)
                    }
                }
            } else {
                Button("⏱ \(state.l10n.presetMinutes(15))") {
                    state.customMinutes = 15
                    state.activate(preset: .custom)
                }
            }
        } else {
            Text("💤 " + state.l10n.statusSleepAllowed)

            if let reason = state.localizedDeactivationReason {
                Text("   ℹ️ \(reason)")
            }

            Button("\(state.l10n.menuActivate) (\(state.selectedPreset.title(using: state.l10n)))") {
                state.activate(preset: state.selectedPreset)
            }
        }
    }

    @ViewBuilder
    private var presetsSection: some View {
        ForEach(standardPresets) { preset in
            Button {
                state.selectedPreset = preset
                state.activate(preset: preset)
            } label: {
                HStack {
                    Text(preset.title(using: state.l10n))
                    if state.isActive && state.selectedPreset == preset {
                        Image(systemName: "checkmark")
                    }
                }
            }
        }

        Menu("\(state.l10n.presetCustom) (\(state.customMinutes) \(state.l10n.minuteSuffix))...") {
            Button("\(state.l10n.menuActivate) (\(state.customMinutes) \(state.l10n.minuteSuffix))") {
                state.activate(preset: .custom)
            }

            Divider()

            ForEach(customQuickMinutes, id: \.self) { mins in
                Button(formattedMinutesTitle(mins)) {
                    state.customMinutes = mins
                    state.activate(preset: .custom)
                }
            }

            Divider()

            Button("+15 \(state.l10n.minuteSuffix)") {
                state.customMinutes = min(720, state.customMinutes + 15)
                state.activate(preset: .custom)
            }

            Button("-15 \(state.l10n.minuteSuffix)") {
                state.customMinutes = max(1, state.customMinutes - 15)
                state.activate(preset: .custom)
            }
        }
    }

    @ViewBuilder
    private var modeAndAppearanceSection: some View {
        Menu("\(state.l10n.sectionMode): \(state.assertionType.title(using: state.l10n))") {
            ForEach(SleepAssertionType.allCases, id: \.self) { type in
                Button {
                    state.assertionType = type
                } label: {
                    HStack {
                        Text(type.title(using: state.l10n))
                        if state.assertionType == type {
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
        }

        Menu("\(state.l10n.menuBarStyleTitle): \(state.menuBarDisplayStyle.title(using: state.l10n))") {
            ForEach(MenuBarDisplayStyle.allCases) { style in
                Button {
                    state.menuBarDisplayStyle = style
                } label: {
                    HStack {
                        Text(style.title(using: state.l10n))
                        if state.menuBarDisplayStyle == style {
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var smartTriggersAndBatterySection: some View {
        let isTriggerActive = state.appTriggersEnabled || state.activateOnACPower || state.activateOnExternalDisplay
        let triggersTitle = isTriggerActive
            ? "\(state.l10n.settingsSmartTriggersSection) (⚡️)"
            : state.l10n.settingsSmartTriggersSection

        Menu(triggersTitle) {
            Toggle(state.l10n.settingsAppTriggers, isOn: $state.appTriggersEnabled)

            if state.appTriggersEnabled {
                Divider()

                if state.targetApps.isEmpty {
                    Text(state.l10n.settingsNoTargetApps)
                } else {
                    ForEach(state.targetApps) { app in
                        let isRunning = state.isTargetAppRunning(app)
                        HStack {
                            Text((isRunning ? "🟢 " : "⚪️ ") + app.displayName)
                            if isRunning {
                                Text("(\(state.l10n.menuRunning))")
                            }
                        }
                    }
                }

                Divider()

                let candidates = state.candidateRunningApps()
                if !candidates.isEmpty {
                    Menu(state.l10n.menuAddRunningApp) {
                        ForEach(candidates) { app in
                            Button(app.displayName) {
                                state.addTargetApp(app)
                            }
                        }
                    }
                }
            }

            Divider()

            if state.batteryInfo != nil {
                Toggle(state.l10n.settingsAcPowerTrigger, isOn: $state.activateOnACPower)
                Toggle(state.l10n.settingsBatteryDeactivateTrigger, isOn: $state.deactivateOnBattery)
            }

            Toggle(state.l10n.settingsExternalDisplayTrigger, isOn: $state.activateOnExternalDisplay)
        }

        if state.batteryInfo != nil {
            let thresholdTitle = state.batteryProtectionEnabled
                ? "\(state.l10n.settingsBatteryProtection): \(state.batteryThreshold)%"
                : "\(state.l10n.settingsBatteryProtection): Выкл"

            Menu(thresholdTitle) {
                Toggle(state.l10n.settingsBatteryProtection, isOn: $state.batteryProtectionEnabled)

                Divider()

                ForEach([10, 15, 20, 25, 30], id: \.self) { pct in
                    Button {
                        state.batteryThreshold = pct
                    } label: {
                        HStack {
                            Text("\(pct)%")
                            if state.batteryThreshold == pct {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var systemActionsSection: some View {
        if let info = state.batteryInfo {
            Text("🔋 " + info.description(using: state.l10n))
        }

        Toggle(state.l10n.settingsLaunchAtLogin, isOn: Binding(
            get: { state.isLaunchAtLogin },
            set: { _ in state.toggleLaunchAtLogin() }
        ))

        Button(state.l10n.settingsTitle + "...") {
            SettingsWindowManager.shared.show(state: state)
        }
        .keyboardShortcut(",", modifiers: .command)

        Divider()

        Button(state.l10n.quitButton) {
            state.quitApplication()
        }
        .keyboardShortcut("q", modifiers: .command)
    }

    private func formattedMinutesTitle(_ mins: Int) -> String {
        if mins >= 60 {
            let hours = mins / 60
            let rem = mins % 60
            if rem == 0 {
                return state.l10n.presetHours(hours)
            } else {
                return "\(hours) ч \(rem) мин"
            }
        }
        return "\(mins) \(state.l10n.minuteSuffix)"
    }
}
