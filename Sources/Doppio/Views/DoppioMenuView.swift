import SwiftUI

/// Премиальное классическое выпадающее меню macOS (NSMenu) в нативном системном стекле
struct DoppioMenuView: View {
    @Bindable var state: DoppioState

    private let customQuickMinutes = [5, 10, 20, 45, 90, 180, 480, 720]

    var body: some View {
        // 1. Статус сессии, оставшееся время и быстрое управление
        statusSection

        Divider()

        // 2. Пресеты длительности в 1 клик с системными галочками
        presetsSection

        Divider()

        // 3. Режим бодрствования (Только Mac / Экран и Mac)
        modeSection

        Divider()

        // 4. Системные действия: Обновления, Настройки и Выход
        systemActionsSection
    }

    // MARK: - Секции меню

    @ViewBuilder
    private var statusSection: some View {
        if state.isActive {
            Label("Doppio: \(state.statusSubtitle)", systemImage: "cup.and.saucer.fill")

            if let triggerName = state.activeTriggerSource.badgeTitle(using: state.l10n) {
                Label(triggerName, systemImage: "bolt.fill")
            }

            if let info = state.batteryInfo {
                Label(info.description(using: state.l10n), systemImage: info.iconName)
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
                    Button("+\(state.l10n.presetHours(1))") {
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
                    state.activate(preset: .minutes15)
                } label: {
                    Label(state.l10n.presetMinutes(15), systemImage: "timer")
                }
            }
        } else {
            Label(state.statusSubtitle, systemImage: "moon.zzz")

            if let info = state.batteryInfo {
                Label(info.description(using: state.l10n), systemImage: info.iconName)
            }

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
        ForEach(KeepAwakePreset.standardPresets) { preset in
            Toggle(preset.title(using: state.l10n), isOn: Binding(
                get: { state.isActive && state.selectedPreset == preset },
                set: { shouldBeActive in
                    if shouldBeActive {
                        state.activate(preset: preset)
                    } else {
                        state.deactivate(reason: .userDisabled)
                    }
                }
            ))
        }

        Menu {
            ForEach(customQuickMinutes, id: \.self) { mins in
                Toggle(state.l10n.formattedCustomMinutes(mins), isOn: Binding(
                    get: { state.isActive && state.selectedPreset == .custom && state.customMinutes == mins },
                    set: { shouldBeActive in
                        if shouldBeActive {
                            state.customMinutes = mins
                            state.activate(preset: .custom)
                        } else {
                            state.deactivate(reason: .userDisabled)
                        }
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
                ? "\(state.l10n.presetCustom) (\(state.l10n.formattedCustomMinutes(state.customMinutes)))..."
                : "\(state.l10n.presetCustom)..."
            Label(title, systemImage: "slider.horizontal.3")
        }
    }

    @ViewBuilder
    private var modeSection: some View {
        Section(state.l10n.sectionMode) {
            ForEach(SleepAssertionType.allCases, id: \.self) { type in
                Toggle(isOn: Binding(
                    get: { state.assertionType == type },
                    set: { isSelected in
                        if isSelected {
                            state.assertionType = type
                        }
                    }
                )) {
                    Label(type.title(using: state.l10n), systemImage: type.iconName)
                }
            }
        }
    }

    @ViewBuilder
    private var systemActionsSection: some View {
        Button {
            Task { @MainActor in
                await state.updateService.checkForUpdates(isUserInitiated: true, l10n: state.l10n)
            }
        } label: {
            Label(state.l10n.menuCheckUpdates, systemImage: "arrow.triangle.2.circlepath")
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

    @MainActor
    private func promptForCustomMinutes() {
        let alert = NSAlert()
        alert.messageText = state.l10n.presetCustom
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
}
