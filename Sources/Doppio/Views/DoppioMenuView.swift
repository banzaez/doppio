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

    private let customQuickMinutes = [5, 10, 20, 45, 90, 180, 480, 720]

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

            Button {
                promptForCustomMinutes()
            } label: {
                Label(state.l10n.customTimerExactTime, systemImage: "clock")
            }
        } label: {
            let title = state.selectedPreset == .custom
                ? "\(state.l10n.presetCustom) (\(formattedMinutesTitle(state.customMinutes)))..."
                : "\(state.l10n.presetCustom)..."
            Label(title, systemImage: "slider.horizontal.3")
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

    @MainActor
    private func promptForCustomMinutes() {
        let alert = NSAlert()
        alert.messageText = state.l10n.customTimerPromptTitle
        alert.informativeText = state.l10n.customTimerPromptMessage
        alert.alertStyle = .informational
        alert.addButton(withTitle: state.l10n.menuActivate)
        alert.addButton(withTitle: state.l10n.cancelButton)

        let input = NSTextField(frame: NSRect(x: 0, y: 0, width: 200, height: 24))
        input.stringValue = "\(state.customMinutes)"
        alert.accessoryView = input

        NSApp.activate(ignoringOtherApps: true)
        let response = alert.runModal()
        if response == .alertFirstButtonReturn {
            let text = input.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
            if let mins = Int(text), mins >= 1 {
                state.customMinutes = min(720, mins)
                state.activate(preset: .custom)
            }
        }
    }

    private func formattedMinutesTitle(_ mins: Int) -> String {
        switch mins {
        case 90:
            switch state.l10n.code {
            case "uk": return "1.5 години (90 хв)"
            case "ru": return "1.5 часа (90 мин)"
            case "de": return "1,5 Stunden (90 Min)"
            case "fr": return "1,5 heure (90 min)"
            case "es": return "1,5 horas (90 min)"
            default:   return "1.5 hours (90 min)"
            }
        case 180:
            return state.l10n.presetHours(3)
        case 480:
            switch state.l10n.code {
            case "uk": return "8 годин (робочий день)"
            case "ru": return "8 часов (рабочий день)"
            case "de": return "8 Stunden (Arbeitstag)"
            case "fr": return "8 heures (journée)"
            case "es": return "8 horas (jornada)"
            default:   return "8 hours (workday)"
            }
        case 720:
            return state.l10n.presetHours(12)
        default:
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
}
