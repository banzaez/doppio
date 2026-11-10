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

        // 3. Системные действия: Настройки и Выход
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
    private var systemActionsSection: some View {
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
