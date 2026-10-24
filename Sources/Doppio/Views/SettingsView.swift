import SwiftUI
import AppKit
import UniformTypeIdentifiers

/// Экран настроек Doppio в стеклянном стиле macOS 2026 Liquid Glass
struct SettingsView: View {
    @Bindable var state: DoppioState
    let onBack: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Заголовок с кнопкой Назад
            headerView

            // Блок 1: Основные параметры (Язык интерфейса и Запуск при входе)
            generalSection

            // Блок 2: Строка меню (Компактный режим для MacBook Notch & Быстрый клик)
            menuBarSection

            // Блок 3: Умные триггеры автоматизации (App Triggers, AC Power, Display)
            smartTriggersSection

            // Блок 4: Защита аккумулятора
            batterySection

            // Блок 5: Выход из приложения
            quitSection

            // Подвал
            footerView
        }
    }

    // MARK: - Секции интерфейса

    private var headerView: some View {
        HStack {
            Button(action: onBack) {
                HStack(spacing: 4) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 11, weight: .bold))
                    Text(state.l10n.backButton)
                        .font(.system(size: 11, weight: .medium))
                }
                .foregroundStyle(Color.orange)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
            }
            .buttonStyle(GlassButtonStyle(cornerRadius: 8))

            Spacer()

            Text(state.l10n.settingsTitle)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Color.primary)

            Spacer()

            Color.clear
                .frame(width: 58, height: 24)
        }
        .padding(.bottom, 2)
    }

    private var generalSection: some View {
        VStack(spacing: 8) {
            // Язык интерфейса
            HStack(spacing: 8) {
                Image(systemName: "globe")
                    .font(.system(size: 12))
                    .foregroundStyle(Color.secondary)
                    .frame(width: 16)

                Text(state.l10n.settingsLanguage)
                    .font(.system(size: 11))
                    .foregroundStyle(Color.primary)

                Spacer()

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
                        .font(.system(size: 11, weight: .medium))
                        .padding(.horizontal, 9)
                        .padding(.vertical, 4)
                }
                .menuStyle(.borderlessButton)
                .buttonStyle(GlassButtonStyle(cornerRadius: 7))
            }

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
        .padding(10)
        .glassCard(cornerRadius: 13)
    }

    private var menuBarSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: "menubar.rectangle")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Color.orange)
                Text(state.l10n.menuBarStyleTitle)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Color.primary)
            }

            // Переключатель стилей (Стандартный | Только иконка)
            HStack(spacing: 5) {
                ForEach(MenuBarDisplayStyle.allCases) { style in
                    let isSelected = state.menuBarDisplayStyle == style
                    Button {
                        withAnimation(.spring(response: 0.2, dampingFraction: 0.8)) {
                            state.menuBarDisplayStyle = style
                        }
                    } label: {
                        HStack(spacing: 5) {
                            switch style {
                            case .standard:
                                Image(systemName: "cup.and.saucer.fill")
                                    .font(.system(size: 9.5))
                            case .iconOnly:
                                Image(systemName: "cup.and.saucer")
                                    .font(.system(size: 9.5))
                            }
                            Text(style.title(using: state.l10n))
                                .font(.system(size: 10, weight: isSelected ? .bold : .medium))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 5)
                    }
                    .buttonStyle(GlassButtonStyle(isSelected: isSelected, isAccent: true, cornerRadius: 7))
                }
            }

            Text(state.l10n.menuBarStyleDesc)
                .font(.system(size: 9.5))
                .foregroundStyle(Color.secondary)
                .padding(.bottom, 2)

            Divider()
                .padding(.horizontal, 2)

            // Быстрый клик (Option / Right Click)
            VStack(alignment: .leading, spacing: 3) {
                settingToggleRow(
                    title: state.l10n.settingsQuickToggle,
                    icon: "hand.tap",
                    isOn: $state.quickToggleEnabled
                )
                Text(state.l10n.settingsQuickToggleDesc)
                    .font(.system(size: 9.5))
                    .foregroundStyle(Color.secondary)
                    .padding(.leading, 24)
            }

            Divider()
                .padding(.horizontal, 2)

            // Уведомление за 1 минуту до сна с продлением
            settingToggleRow(
                title: state.l10n.settingsNotifyBeforeSleep,
                icon: "bell.badge",
                isOn: $state.notifyBeforeExpiry
            )
        }
        .padding(10)
        .glassCard(cornerRadius: 13)
    }

    private var smartTriggersSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: "bolt.badge.automatic")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Color.orange)
                Text(state.l10n.settingsSmartTriggersSection)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Color.primary)
            }

            // Тумблер триггеров приложений
            settingToggleRow(
                title: state.l10n.settingsAppTriggers,
                icon: "app.dashed",
                isOn: $state.appTriggersEnabled
            )

            if state.appTriggersEnabled {
                VStack(alignment: .leading, spacing: 6) {
                    Text(state.l10n.settingsAppTriggersDesc)
                        .font(.system(size: 9.5))
                        .foregroundStyle(Color.secondary)

                    // Список добавленных приложений
                    if state.targetApps.isEmpty {
                        Text(state.l10n.settingsNoTargetApps)
                            .font(.system(size: 10, weight: .regular))
                            .foregroundStyle(Color.secondary.opacity(0.7))
                            .padding(.vertical, 2)
                    } else {
                        VStack(spacing: 4) {
                            ForEach(state.targetApps) { app in
                                HStack(spacing: 6) {
                                    Circle()
                                        .fill(state.isTargetAppRunning(app) ? Color.green : Color.secondary.opacity(0.4))
                                        .frame(width: 6, height: 6)

                                    Text(app.displayName)
                                        .font(.system(size: 10.5, weight: .medium))
                                        .foregroundStyle(Color.primary)
                                        .lineLimit(1)

                                    Spacer()

                                    Button {
                                        withAnimation(.spring(response: 0.2, dampingFraction: 0.8)) {
                                            state.removeTargetApp(id: app.id)
                                        }
                                    } label: {
                                        Image(systemName: "xmark")
                                            .font(.system(size: 8, weight: .bold))
                                            .foregroundStyle(Color.secondary)
                                            .padding(3)
                                    }
                                    .buttonStyle(.plain)
                                }
                                .padding(.horizontal, 7)
                                .padding(.vertical, 3.5)
                                .background(Color.primary.opacity(0.04))
                                .cornerRadius(6)
                            }
                        }
                    }

                    // Кнопка добавления приложений
                    Menu {
                        let candidates = candidateRunningApps
                        if !candidates.isEmpty {
                            Section(state.l10n.settingsRunningAppsSection) {
                                ForEach(candidates) { app in
                                    Button {
                                        state.addTargetApp(app)
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
                        HStack(spacing: 4) {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 10))
                            Text(state.l10n.settingsAddAppButton)
                                .font(.system(size: 10, weight: .medium))
                        }
                        .foregroundStyle(Color.orange)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                    }
                    .menuStyle(.borderlessButton)
                    .buttonStyle(GlassButtonStyle(cornerRadius: 6))
                }
                .padding(.leading, 24)
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
        .padding(10)
        .glassCard(cornerRadius: 13)
    }


    private var batterySection: some View {
        Group {
            if state.batteryInfo != nil {
                VStack(alignment: .leading, spacing: 8) {
                    settingToggleRow(
                        title: state.l10n.settingsBatteryProtection,
                        icon: "bolt.shield",
                        isOn: $state.batteryProtectionEnabled
                    )

                    if state.batteryProtectionEnabled {
                        Divider()
                            .padding(.horizontal, 4)

                        VStack(alignment: .leading, spacing: 6) {
                            Text(state.l10n.settingsBatteryThresholdDesc)
                                .font(.system(size: 10))
                                .foregroundStyle(Color.secondary)

                            HStack(spacing: 6) {
                                ForEach([10, 15, 20, 25, 30], id: \.self) { pct in
                                    let isSelected = state.batteryThreshold == pct

                                    Button {
                                        withAnimation(.spring(response: 0.2, dampingFraction: 0.75)) {
                                            state.batteryThreshold = pct
                                        }
                                    } label: {
                                        Text("\(pct)%")
                                            .font(.system(size: 10, weight: isSelected ? .bold : .medium, design: .rounded))
                                            .foregroundStyle(isSelected ? Color.orange : Color.secondary)
                                            .frame(maxWidth: .infinity)
                                            .padding(.vertical, 4)
                                    }
                                    .buttonStyle(GlassButtonStyle(
                                        isSelected: isSelected,
                                        isAccent: true,
                                        cornerRadius: 6
                                    ))
                                }
                            }
                        }
                        .padding(.top, 2)
                    }
                }
                .padding(10)
                .glassCard(cornerRadius: 13)
            } else {
                HStack(spacing: 8) {
                    Image(systemName: "desktopcomputer")
                        .font(.system(size: 12))
                        .foregroundStyle(Color.secondary)
                        .frame(width: 16)

                    Text(state.l10n.desktopMacNoBattery)
                        .font(.system(size: 11))
                        .foregroundStyle(Color.secondary)

                    Spacer()
                }
                .padding(10)
                .glassCard(cornerRadius: 13)
            }
        }
    }

    private var quitSection: some View {
        Button {
            state.deactivate(reason: .quitApp)
            NSApplication.shared.terminate(nil)
        } label: {
            HStack(spacing: 5) {
                Image(systemName: "power")
                    .font(.system(size: 11, weight: .semibold))
                Text(state.l10n.quitButton)
                    .font(.system(size: 11, weight: .medium))
            }
            .foregroundStyle(Color.red.opacity(0.85))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 6)
        }
        .buttonStyle(GlassButtonStyle(cornerRadius: 10))
        .padding(.top, 2)
    }

    private var footerView: some View {
        HStack {
            Spacer()
            Text("Doppio v1.1.0")
                .font(.system(size: 10, weight: .regular, design: .rounded))
                .foregroundStyle(Color.secondary.opacity(0.6))
            Spacer()
        }
        .padding(.top, 2)
    }

    private func settingToggleRow(title: String, icon: String, isOn: Binding<Bool>) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 12))
                .foregroundStyle(Color.secondary)
                .frame(width: 16)

            Text(title)
                .font(.system(size: 11))
                .foregroundStyle(Color.primary)

            Spacer()

            Toggle("", isOn: isOn)
                .toggleStyle(.switch)
                .controlSize(.mini)
                .labelsHidden()
        }
    }

    // MARK: - Вспомогательные методы выбора приложений

    private var candidateRunningApps: [TriggerApp] {
        let existingIds = Set(state.targetApps.map(\.bundleIdentifier))
        return NSWorkspace.shared.runningApplications
            .filter { app in
                app.activationPolicy == .regular &&
                app.bundleIdentifier != nil &&
                app.bundleIdentifier != Bundle.main.bundleIdentifier &&
                !existingIds.contains(app.bundleIdentifier!)
            }
            .compactMap { app in
                guard let bundleId = app.bundleIdentifier else { return nil }
                let name = app.localizedName ?? bundleId
                return TriggerApp(bundleIdentifier: bundleId, displayName: name)
            }
    }

    private func selectAppFromDisk() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [UTType.application]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.directoryURL = URL(fileURLWithPath: "/Applications")

        if panel.runModal() == .OK, let url = panel.url {
            if let bundle = Bundle(url: url),
               let bundleId = bundle.bundleIdentifier {
                let name = bundle.infoDictionary?["CFBundleDisplayName"] as? String
                    ?? bundle.infoDictionary?["CFBundleName"] as? String
                    ?? url.deletingPathExtension().lastPathComponent
                state.addTargetApp(TriggerApp(bundleIdentifier: bundleId, displayName: name))
            }
        }
    }
}
