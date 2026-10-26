import SwiftUI
import AppKit
import UniformTypeIdentifiers

/// Экран настроек Doppio в стеклянном стиле macOS 2026 Liquid Glass (компактная адаптивная вёрстка)
struct SettingsView: View {
    @Bindable var state: DoppioState
    let onBack: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            // Заголовок с идеально центрированным названием и кнопкой Назад
            headerView

            // Блок 1: Основные параметры (Язык интерфейса и Запуск при входе)
            generalSection

            // Блок 2: Строка меню (Компактный режим для MacBook Notch, Быстрый клик, Уведомления)
            menuBarSection

            // Блок 3: Умные триггеры автоматизации (App Triggers, AC Power, Display)
            smartTriggersSection

            // Блок 4: Защита аккумулятора
            batterySection

            // Блок 5: Выход из приложения и версия
            bottomFooterSection
        }
    }

    // MARK: - Секции интерфейса

    private var headerView: some View {
        ZStack {
            Text(state.l10n.settingsTitle)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Color.primary)
                .lineLimit(1)

            HStack {
                Button(action: onBack) {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 10, weight: .bold))
                        Text(state.l10n.backButton)
                            .font(.system(size: 11, weight: .medium))
                            .lineLimit(1)
                    }
                    .foregroundStyle(Color.orange)
                    .padding(.horizontal, 8)
                    .frame(height: 22)
                }
                .buttonStyle(GlassButtonStyle(cornerRadius: 7))

                Spacer()
            }
        }
        .frame(height: 24)
    }

    private var generalSection: some View {
        VStack(spacing: 5) {
            // Язык интерфейса
            HStack(spacing: 8) {
                Image(systemName: "globe")
                    .font(.system(size: 11.5))
                    .foregroundStyle(Color.secondary)
                    .frame(width: 15)

                Text(state.l10n.settingsLanguage)
                    .font(.system(size: 11))
                    .foregroundStyle(Color.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)

                Spacer(minLength: 4)

                Menu {
                    ForEach(AppLanguage.allCases) { lang in
                        Button {
                            state.language = lang
                        } label: {
                            HStack {
                                Text(lang.displayName)
                                if state.language == lang {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                } label: {
                    Text(state.language.displayName)
                        .font(.system(size: 10.5, weight: .medium))
                        .padding(.horizontal, 8)
                        .frame(height: 20)
                }
                .menuStyle(.borderlessButton)
                .buttonStyle(GlassButtonStyle(cornerRadius: 6))
            }
            .frame(height: 20)

            Divider()
                .padding(.horizontal, 2)

            // Запуск при входе в систему
            settingToggleRow(
                title: state.l10n.settingsLaunchAtLogin,
                icon: "arrow.clockwise",
                isOn: Binding(
                    get: { state.isLaunchAtLogin },
                    set: { _ in state.toggleLaunchAtLogin() }
                )
            )
        }
        .padding(.horizontal, 9)
        .padding(.vertical, 7)
        .glassCard(cornerRadius: 11)
    }

    private var menuBarSection: some View {
        VStack(alignment: .leading, spacing: 5) {
            // Заголовок и переключатель стилей в компактном блоке
            HStack(spacing: 6) {
                Image(systemName: "menubar.rectangle")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Color.orange)
                    .frame(width: 15)
                Text(state.l10n.menuBarStyleTitle)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Color.primary)
                    .lineLimit(1)
            }
            .help(state.l10n.menuBarStyleDesc)

            // Переключатель стилей (Стандартный | Только иконка)
            HStack(spacing: 5) {
                ForEach(MenuBarDisplayStyle.allCases) { style in
                    let isSelected = state.menuBarDisplayStyle == style
                    Button {
                        withAnimation(.easeInOut(duration: 0.16)) {
                            state.menuBarDisplayStyle = style
                        }
                    } label: {
                        HStack(spacing: 5) {
                            Image(systemName: style.iconName)
                                .font(.system(size: 9.5))
                            Text(style.title(using: state.l10n))
                                .font(.system(size: 10, weight: isSelected ? .bold : .medium))
                                .lineLimit(1)
                                .minimumScaleFactor(0.85)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 22)
                    }
                    .buttonStyle(GlassButtonStyle(isSelected: isSelected, isAccent: true, cornerRadius: 6))
                }
            }
            .help(state.l10n.menuBarStyleDesc)

            Divider()
                .padding(.horizontal, 2)

            // Быстрый клик (Option / Right Click)
            settingToggleRow(
                title: state.l10n.settingsQuickToggle,
                icon: "hand.tap",
                isOn: $state.quickToggleEnabled,
                helpText: state.l10n.settingsQuickToggleDesc
            )

            Divider()
                .padding(.horizontal, 2)

            // Уведомление за 1 минуту до сна с продлением
            settingToggleRow(
                title: state.l10n.settingsNotifyBeforeSleep,
                icon: "bell.badge",
                isOn: $state.notifyBeforeExpiry
            )
        }
        .padding(.horizontal, 9)
        .padding(.vertical, 7)
        .glassCard(cornerRadius: 11)
    }

    private var smartTriggersSection: some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack(spacing: 6) {
                Image(systemName: "bolt.badge.automatic")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Color.orange)
                    .frame(width: 15)
                Text(state.l10n.settingsSmartTriggersSection)
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(Color.secondary)
                    .lineLimit(1)

                Spacer()

                // Кнопка добавления приложений прямо в шапке секции, когда триггеры включены
                if state.appTriggersEnabled {
                    addAppMenuButton
                }
            }

            // Тумблер триггеров приложений
            settingToggleRow(
                title: state.l10n.settingsAppTriggers,
                icon: "app.dashed",
                isOn: $state.appTriggersEnabled,
                helpText: state.l10n.settingsAppTriggersDesc
            )

            if state.appTriggersEnabled {
                VStack(alignment: .leading, spacing: 4) {
                    if state.targetApps.isEmpty {
                        Text(state.l10n.settingsNoTargetApps)
                            .font(.system(size: 9.5, weight: .regular))
                            .foregroundStyle(Color.secondary.opacity(0.75))
                            .padding(.leading, 23)
                            .frame(height: 16)
                    } else if state.targetApps.count <= 3 {
                        targetAppsRows
                            .padding(.leading, 23)
                    } else {
                        // Явная высота (height: 74) гарантирует, что ScrollView не растянется внутри .fixedSize(vertical: true)
                        ScrollView(.vertical, showsIndicators: true) {
                            targetAppsRows
                        }
                        .frame(height: 74)
                        .padding(.leading, 23)
                    }
                }
            }

            Divider()
                .padding(.horizontal, 2)

            // Питание от сети
            if state.batteryInfo != nil {
                settingToggleRow(
                    title: state.l10n.settingsAcPowerTrigger,
                    icon: "powercord",
                    isOn: $state.activateOnACPower
                )

                settingToggleRow(
                    title: state.l10n.settingsBatteryDeactivateTrigger,
                    icon: "battery.50",
                    isOn: $state.deactivateOnBattery
                )

                Divider()
                    .padding(.horizontal, 2)
            }

            // Внешний дисплей
            settingToggleRow(
                title: state.l10n.settingsExternalDisplayTrigger,
                icon: "display.2",
                isOn: $state.activateOnExternalDisplay
            )
        }
        .padding(.horizontal, 9)
        .padding(.vertical, 7)
        .glassCard(cornerRadius: 11)
    }

    private var addAppMenuButton: some View {
        Menu {
            let candidates = state.candidateRunningApps()
            if !candidates.isEmpty {
                Section(state.l10n.settingsRunningAppsSection) {
                    ForEach(candidates) { app in
                        Button {
                            withAnimation(.easeInOut(duration: 0.16)) {
                                state.addTargetApp(app)
                            }
                        } label: {
                            Text(app.displayName)
                        }
                    }
                }
            }

            Button {
                selectAppFromDisk()
            } label: {
                Label(state.l10n.settingsChooseFromDisk, systemImage: "folder")
            }
        } label: {
            HStack(spacing: 3) {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 9.5))
                Text(state.l10n.settingsAddAppButton)
                    .font(.system(size: 9.5, weight: .medium))
                    .lineLimit(1)
            }
            .foregroundStyle(Color.orange)
            .padding(.horizontal, 7)
            .frame(height: 19)
        }
        .menuStyle(.borderlessButton)
        .buttonStyle(GlassButtonStyle(cornerRadius: 5))
    }

    private var targetAppsRows: some View {
        VStack(spacing: 3) {
            ForEach(state.targetApps) { app in
                HStack(spacing: 6) {
                    Image(nsImage: app.appIcon)
                        .resizable()
                        .interpolation(.high)
                        .frame(width: 13, height: 13)

                    Circle()
                        .fill(state.isTargetAppRunning(app) ? Color.green : Color.secondary.opacity(0.35))
                        .frame(width: 5, height: 5)

                    Text(app.displayName)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(Color.primary)
                        .lineLimit(1)

                    Spacer(minLength: 4)

                    Button {
                        withAnimation(.easeInOut(duration: 0.16)) {
                            state.removeTargetApp(id: app.id)
                        }
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 7.5, weight: .bold))
                            .foregroundStyle(Color.secondary)
                            .frame(width: 15, height: 15)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 6)
                .frame(height: 22)
                .background(
                    RoundedRectangle(cornerRadius: 5, style: .continuous)
                        .fill(Color.primary.opacity(0.045))
                )
            }
        }
    }

    private var batterySection: some View {
        Group {
            if state.batteryInfo != nil {
                VStack(alignment: .leading, spacing: 5) {
                    settingToggleRow(
                        title: state.l10n.settingsBatteryProtection,
                        icon: "bolt.shield",
                        isOn: $state.batteryProtectionEnabled,
                        helpText: state.l10n.settingsBatteryThresholdDesc
                    )

                    if state.batteryProtectionEnabled {
                        HStack(spacing: 4) {
                            ForEach([10, 15, 20, 25, 30], id: \.self) { pct in
                                let isSelected = state.batteryThreshold == pct

                                Button {
                                    withAnimation(.easeInOut(duration: 0.16)) {
                                        state.batteryThreshold = pct
                                    }
                                } label: {
                                    Text("\(pct)%")
                                        .font(.system(size: 9.5, weight: isSelected ? .bold : .medium, design: .rounded))
                                        .foregroundStyle(isSelected ? Color.orange : Color.secondary)
                                        .frame(maxWidth: .infinity)
                                        .frame(height: 20)
                                }
                                .buttonStyle(GlassButtonStyle(
                                    isSelected: isSelected,
                                    isAccent: true,
                                    cornerRadius: 5
                                ))
                            }
                        }
                        .padding(.top, 1)
                    }
                }
                .padding(.horizontal, 9)
                .padding(.vertical, 7)
                .glassCard(cornerRadius: 11)
            } else {
                HStack(spacing: 8) {
                    Image(systemName: "desktopcomputer")
                        .font(.system(size: 11.5))
                        .foregroundStyle(Color.secondary)
                        .frame(width: 15)

                    Text(state.l10n.desktopMacNoBattery)
                        .font(.system(size: 10.5))
                        .foregroundStyle(Color.secondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.85)

                    Spacer()
                }
                .padding(.horizontal, 9)
                .padding(.vertical, 7)
                .glassCard(cornerRadius: 11)
            }
        }
    }

    private var bottomFooterSection: some View {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.1.0"
        return HStack(spacing: 10) {
            Text("Doppio v\(version)")
                .font(.system(size: 10, weight: .medium, design: .rounded))
                .foregroundStyle(Color.secondary.opacity(0.65))
                .padding(.leading, 4)

            Spacer()

            Button {
                state.quitApplication()
            } label: {
                HStack(spacing: 5) {
                    Image(systemName: "power")
                        .font(.system(size: 10, weight: .semibold))
                    Text(state.l10n.quitButton)
                        .font(.system(size: 10.5, weight: .medium))
                        .lineLimit(1)
                }
                .foregroundStyle(Color.red.opacity(0.88))
                .padding(.horizontal, 10)
                .frame(height: 24)
            }
            .buttonStyle(GlassButtonStyle(cornerRadius: 7))
        }
        .frame(height: 24)
    }

    private func settingToggleRow(
        title: String,
        icon: String,
        isOn: Binding<Bool>,
        helpText: String? = nil
    ) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 11))
                .foregroundStyle(Color.secondary)
                .frame(width: 15)

            Text(title)
                .font(.system(size: 10.5))
                .foregroundStyle(Color.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.85)

            Spacer(minLength: 4)

            Toggle("", isOn: isOn)
                .toggleStyle(.switch)
                .controlSize(.mini)
                .labelsHidden()
        }
        .frame(height: 17)
        .help(helpText ?? "")
    }

    // MARK: - Вспомогательные методы выбора приложений

    private func selectAppFromDisk() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [UTType.application]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.directoryURL = URL(fileURLWithPath: "/Applications")

        if panel.runModal() == .OK, let url = panel.url {
            withAnimation(.easeInOut(duration: 0.16)) {
                state.addTargetApp(from: url)
            }
        }
    }
}
