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

            Label("Doppio: \(subtitle)", systemImage: "cup.and.saucer.fill")

            if let triggerName = state.activeTriggerSource.badgeTitle(using: state.l10n) {
                Label(triggerName, systemImage: "bolt.fill")
            }

            Button {
                state.deactivate(reason: .userDisabled)
            } label: {
                Label(state.l10n.menuDeactivate, systemImage: "stop.circle")
            }

            // Быстрое продление активной сессии
            if state.remainingSeconds != nil {
                Menu {
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
                } label: {
                    Label(state.l10n.menuExtend, systemImage: "clock.badge.plus")
                }
            } else {
                Button {
                    state.customMinutes = 15
                    state.activate(preset: .custom)
                } label: {
                    Label(state.l10n.presetMinutes(15), systemImage: "timer")
                }
            }
        } else {
            Label(state.l10n.statusSleepAllowed, systemImage: "moon.zzz")

            if let reason = state.localizedDeactivationReason {
                Label(reason, systemImage: "info.circle")
            }

            Button {
                state.activate(preset: state.selectedPreset)
            } label: {
                Label("\(state.l10n.menuActivate) (\(state.selectedPreset.title(using: state.l10n)))", systemImage: "play.circle")
            }
        }
    }

    @ViewBuilder
    private var presetsSection: some View {
        ForEach(standardPresets) { preset in
            Toggle(preset.title(using: state.l10n), isOn: Binding(
                get: { state.isActive && state.selectedPreset == preset },
                set: { shouldBeActive in
                    if shouldBeActive {
                        state.selectedPreset = preset
                        state.activate(preset: preset)
                    } else {
                        state.deactivate(reason: .userDisabled)
                    }
                }
            ))
        }

        Menu {
            Toggle("\(state.l10n.menuActivate) (\(state.customMinutes) \(state.l10n.minuteSuffix))", isOn: Binding(
                get: { state.isActive && state.selectedPreset == .custom },
                set: { shouldBeActive in
                    if shouldBeActive {
                        state.activate(preset: .custom)
                    } else {
                        state.deactivate(reason: .userDisabled)
                    }
                }
            ))

            Divider()

            ForEach(customQuickMinutes, id: \.self) { mins in
                Toggle(formattedMinutesTitle(mins), isOn: Binding(
                    get: { state.isActive && state.selectedPreset == .custom && state.customMinutes == mins },
                    set: { _ in
                        state.customMinutes = mins
                        state.activate(preset: .custom)
                    }
                ))
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
        } label: {
            Label("\(state.l10n.presetCustom) (\(state.customMinutes) \(state.l10n.minuteSuffix))...", systemImage: "slider.horizontal.3")
        }
    }

    @ViewBuilder
    private var modeAndAppearanceSection: some View {
        Menu {
            ForEach(SleepAssertionType.allCases, id: \.self) { type in
                Toggle(type.title(using: state.l10n), isOn: Binding(
                    get: { state.assertionType == type },
                    set: { _ in state.assertionType = type }
                ))
            }
        } label: {
            Label("\(state.l10n.sectionMode): \(state.assertionType.title(using: state.l10n))", systemImage: "display")
        }

        Menu {
            ForEach(MenuBarDisplayStyle.allCases) { style in
                Toggle(style.title(using: state.l10n), isOn: Binding(
                    get: { state.menuBarDisplayStyle == style },
                    set: { _ in state.menuBarDisplayStyle = style }
                ))
            }
        } label: {
            Label("\(state.l10n.menuBarStyleTitle): \(state.menuBarDisplayStyle.title(using: state.l10n))", systemImage: "menubar.rectangle")
        }
    }

    @ViewBuilder
    private var smartTriggersAndBatterySection: some View {
        let isTriggerActive = state.appTriggersEnabled || state.activateOnACPower || state.activateOnExternalDisplay
        let triggersTitle = state.l10n.settingsSmartTriggersSection

        Menu {
            Toggle(state.l10n.settingsAppTriggers, isOn: $state.appTriggersEnabled)

            if state.appTriggersEnabled {
                Divider()

                if state.targetApps.isEmpty {
                    Text(state.l10n.settingsNoTargetApps)
                } else {
                    ForEach(state.targetApps) { app in
                        let isRunning = state.isTargetAppRunning(app)
                        Label {
                            Text(app.displayName + (isRunning ? " (\(state.l10n.menuRunning))" : ""))
                        } icon: {
                            Image(systemName: isRunning ? "circle.fill" : "circle")
                        }
                    }
                }

                Divider()

                let candidates = state.candidateRunningApps()
                if !candidates.isEmpty {
                    Menu {
                        ForEach(candidates) { app in
                            Button(app.displayName) {
                                state.addTargetApp(app)
                            }
                        }
                    } label: {
                        Label(state.l10n.menuAddRunningApp, systemImage: "plus.app")
                    }
                }
            }

            Divider()

            if state.batteryInfo != nil {
                Toggle(state.l10n.settingsAcPowerTrigger, isOn: $state.activateOnACPower)
                Toggle(state.l10n.settingsBatteryDeactivateTrigger, isOn: $state.deactivateOnBattery)
            }

            Toggle(state.l10n.settingsExternalDisplayTrigger, isOn: $state.activateOnExternalDisplay)
        } label: {
            Label(triggersTitle, systemImage: isTriggerActive ? "bolt.badge.automatic.fill" : "bolt.badge.automatic")
        }

        if state.batteryInfo != nil {
            let thresholdTitle = state.batteryProtectionEnabled
                ? "\(state.l10n.settingsBatteryProtection): \(state.batteryThreshold)%"
                : "\(state.l10n.settingsBatteryProtection): Выкл"

            Menu {
                Toggle(state.l10n.settingsBatteryProtection, isOn: $state.batteryProtectionEnabled)

                Divider()

                ForEach([10, 15, 20, 25, 30], id: \.self) { pct in
                    Toggle("\(pct)%", isOn: Binding(
                        get: { state.batteryThreshold == pct },
                        set: { _ in state.batteryThreshold = pct }
                    ))
                }
            } label: {
                Label(thresholdTitle, systemImage: state.batteryProtectionEnabled ? "shield.fill" : "shield")
            }
        }
    }

    @ViewBuilder
    private var systemActionsSection: some View {
        if let info = state.batteryInfo {
            let iconName = info.isPluggedIn ? "battery.100.bolt" : "battery.75"
            Label(info.description(using: state.l10n), systemImage: iconName)
        }

        Toggle(isOn: Binding(
            get: { state.isLaunchAtLogin },
            set: { _ in state.toggleLaunchAtLogin() }
        )) {
            Label(state.l10n.settingsLaunchAtLogin, systemImage: "arrow.clockwise")
        }

        Button {
            SettingsWindowManager.shared.show(state: state)
        } label: {
            Label(state.l10n.settingsTitle + "...", systemImage: "gearshape")
        }
        .keyboardShortcut(",", modifiers: .command)

        Divider()

        Button {
            state.quitApplication()
        } label: {
            Label(state.l10n.quitButton, systemImage: "power")
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
