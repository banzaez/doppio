import SwiftUI
import AppKit
import UniformTypeIdentifiers

/// Вкладки экрана настроек
enum SettingsTab: String, CaseIterable, Identifiable {
    case general
    case automation
    case about

    var id: String { rawValue }

    func title(using l10n: L10n) -> String {
        switch self {
        case .general: return l10n.tabGeneral
        case .automation: return l10n.tabAutomation
        case .about: return l10n.tabAbout
        }
    }

    var icon: String {
        switch self {
        case .general: return "gearshape"
        case .automation: return "bolt.badge.automatic"
        case .about: return "info.circle"
        }
    }
}

/// Экран настроек Doppio в стеклянном стиле macOS 2026 Liquid Glass (компактная адаптивная вёрстка)
struct SettingsView: View {
    @Bindable var state: DoppioState

    @State private var selectedTab: SettingsTab = .general
    @Namespace private var tabNamespace

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Стеклянная панель переключения вкладок macOS 27 Liquid Glass
            glassTabBar

            // Содержимое выбранной вкладки
            VStack(alignment: .leading, spacing: 12) {
                switch selectedTab {
                case .general:
                    generalSection
                    menuBarSection
                case .automation:
                    smartTriggersSection
                    batterySection
                case .about:
                    aboutSection
                }
            }
        }
    }

    private var glassTabBar: some View {
        HStack(spacing: 5) {
            ForEach(SettingsTab.allCases) { tab in
                let isSelected = selectedTab == tab

                Button {
                    withAnimation(.spring(response: 0.28, dampingFraction: 0.78)) {
                        selectedTab = tab
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: tab.icon)
                            .font(.system(size: 12.5))
                        Text(tab.title(using: state.l10n))
                            .font(.system(size: 13, weight: isSelected ? .semibold : .medium))
                            .lineLimit(1)
                    }
                    .foregroundStyle(isSelected ? Color.primary : Color.secondary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 32)
                    .contentShape(Rectangle())
                    .background {
                        if isSelected {
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .fill(Color.primary.opacity(0.10))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                                        .stroke(
                                            LinearGradient(
                                                colors: [
                                                    Color.white.opacity(0.28),
                                                    Color.white.opacity(0.08)
                                                ],
                                                startPoint: .top,
                                                endPoint: .bottom
                                            ),
                                            lineWidth: 0.5
                                        )
                                )
                                .shadow(color: Color.black.opacity(0.06), radius: 3, y: 1)
                                .matchedGeometryEffect(id: "SelectedSettingsTab", in: tabNamespace)
                        }
                    }
                }
                .buttonStyle(.plain)
            }
        }
        .padding(4)
        .background(
            RoundedRectangle(cornerRadius: 11, style: .continuous)
                .fill(Color.primary.opacity(0.04))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 11, style: .continuous)
                .stroke(Color.primary.opacity(0.06), lineWidth: 0.5)
        )
    }

    // MARK: - Секции интерфейса

    private var generalSection: some View {
        VStack(spacing: 10) {
            // Язык интерфейса
            HStack(spacing: 8) {
                Image(systemName: "globe")
                    .font(.system(size: 13))
                    .foregroundStyle(Color.secondary)
                    .frame(width: 20, alignment: .center)

                Text(state.l10n.settingsLanguage)
                    .font(.system(size: 13))
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
                        .font(.system(size: 12.5, weight: .medium))
                        .padding(.horizontal, 10)
                        .frame(height: 26)
                }
                .menuStyle(.borderlessButton)
                .buttonStyle(GlassButtonStyle(cornerRadius: 7))
            }
            .frame(height: 28)

            Divider()
                .padding(.vertical, 1)

            // Запуск при входе в систему
            settingToggleRow(
                title: state.l10n.settingsLaunchAtLogin,
                icon: "arrow.clockwise",
                isOn: Binding(
                    get: { state.isLaunchAtLogin },
                    set: { _ in state.toggleLaunchAtLogin() }
                )
            )

            Divider()
                .padding(.vertical, 1)

            // Длительность своего таймера
            HStack(spacing: 8) {
                Image(systemName: "timer")
                    .font(.system(size: 13))
                    .foregroundStyle(Color.secondary)
                    .frame(width: 20, alignment: .center)

                Text(state.l10n.presetCustom)
                    .font(.system(size: 13))
                    .foregroundStyle(Color.primary)
                    .lineLimit(1)

                Spacer(minLength: 4)

                HStack(spacing: 6) {
                    Button {
                        state.customMinutes = max(1, state.customMinutes - 5)
                    } label: {
                        Image(systemName: "minus")
                            .font(.system(size: 11, weight: .bold))
                            .frame(width: 24, height: 24)
                    }
                    .buttonStyle(GlassButtonStyle(cornerRadius: 6))

                    Text("\(state.customMinutes) \(state.l10n.minuteSuffix)")
                        .font(.system(size: 12.5, weight: .medium, design: .rounded))
                        .monospacedDigit()
                        .frame(minWidth: 56, alignment: .center)

                    Button {
                        state.customMinutes = min(720, state.customMinutes + 5)
                    } label: {
                        Image(systemName: "plus")
                            .font(.system(size: 11, weight: .bold))
                            .frame(width: 24, height: 24)
                    }
                    .buttonStyle(GlassButtonStyle(cornerRadius: 6))
                }
            }
            .frame(height: 28)

            Divider()
                .padding(.vertical, 1)

            // Режим бодрствования (Только Mac | Экран и Mac)
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 8) {
                    Image(systemName: "cup.and.saucer")
                        .font(.system(size: 13))
                        .foregroundStyle(Color.secondary)
                        .frame(width: 20, alignment: .center)

                    Text(state.l10n.sectionMode)
                        .font(.system(size: 13))
                        .foregroundStyle(Color.primary)
                        .lineLimit(1)
                }
                .help(state.assertionType.description(using: state.l10n))

                HStack(spacing: 6) {
                    ForEach(SleepAssertionType.allCases, id: \.self) { type in
                        let isSelected = state.assertionType == type
                        Button {
                            withAnimation(.easeInOut(duration: 0.16)) {
                                state.assertionType = type
                            }
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: type.iconName)
                                    .font(.system(size: 12))
                                Text(type.title(using: state.l10n))
                                    .font(.system(size: 12.5, weight: isSelected ? .bold : .medium))
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.85)
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 28)
                        }
                        .buttonStyle(GlassButtonStyle(isSelected: isSelected, isAccent: true, cornerRadius: 7))
                    }
                }
                .help(state.assertionType.description(using: state.l10n))
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .glassCard(cornerRadius: 10)
    }

    private var menuBarSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Заголовок и переключатель стилей в компактном блоке
            HStack(spacing: 8) {
                Image(systemName: "menubar.rectangle")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color.orange)
                    .frame(width: 20, alignment: .center)
                Text(state.l10n.menuBarStyleTitle)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color.primary)
                    .lineLimit(1)
            }
            .help(state.l10n.menuBarStyleDesc)

            // Переключатель стилей (Стандартный | Только иконка)
            HStack(spacing: 6) {
                ForEach(MenuBarDisplayStyle.allCases) { style in
                    let isSelected = state.menuBarDisplayStyle == style
                    Button {
                        withAnimation(.easeInOut(duration: 0.16)) {
                            state.menuBarDisplayStyle = style
                        }
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: style.iconName)
                                .font(.system(size: 12))
                            Text(style.title(using: state.l10n))
                                .font(.system(size: 12.5, weight: isSelected ? .bold : .medium))
                                .lineLimit(1)
                                .minimumScaleFactor(0.85)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 28)
                    }
                    .buttonStyle(GlassButtonStyle(isSelected: isSelected, isAccent: true, cornerRadius: 7))
                }
            }
            .help(state.l10n.menuBarStyleDesc)
            .padding(.top, 1)

            Divider()
                .padding(.vertical, 1)

            // Быстрый клик (Option / Right Click)
            settingToggleRow(
                title: state.l10n.settingsQuickToggle,
                icon: "hand.tap",
                isOn: $state.quickToggleEnabled,
                helpText: state.l10n.settingsQuickToggleDesc
            )

            Divider()
                .padding(.vertical, 1)

            // Уведомление за 1 минуту до сна с продлением
            settingToggleRow(
                title: state.l10n.settingsNotifyBeforeSleep,
                icon: "bell.badge",
                isOn: $state.notifyBeforeExpiry
            )
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .glassCard(cornerRadius: 10)
    }

    private var smartTriggersSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: "bolt.badge.automatic")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color.orange)
                    .frame(width: 20, alignment: .center)
                Text(state.l10n.settingsSmartTriggersSection)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color.primary)
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
                VStack(alignment: .leading, spacing: 6) {
                    if state.targetApps.isEmpty {
                        Text(state.l10n.settingsNoTargetApps)
                            .font(.system(size: 11.5, weight: .regular))
                            .foregroundStyle(Color.secondary.opacity(0.75))
                            .padding(.leading, 28)
                            .frame(height: 22)
                    } else if state.targetApps.count <= 3 {
                        targetAppsRows
                            .padding(.leading, 28)
                    } else {
                        // Явная высота (height: 96) гарантирует, что ScrollView не растянется внутри .fixedSize(vertical: true)
                        ScrollView(.vertical, showsIndicators: true) {
                            targetAppsRows
                        }
                        .frame(height: 96)
                        .padding(.leading, 28)
                    }
                }
                .padding(.vertical, 2)
            }

            Divider()
                .padding(.vertical, 1)

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
                    .padding(.vertical, 1)
            }

            // Внешний дисплей
            settingToggleRow(
                title: state.l10n.settingsExternalDisplayTrigger,
                icon: "display.2",
                isOn: $state.activateOnExternalDisplay
            )
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .glassCard(cornerRadius: 10)
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
            HStack(spacing: 5) {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 12))
                Text(state.l10n.settingsAddAppButton)
                    .font(.system(size: 12.5, weight: .medium))
                    .lineLimit(1)
            }
            .foregroundStyle(Color.orange)
            .padding(.horizontal, 10)
            .frame(height: 26)
        }
        .menuStyle(.borderlessButton)
        .buttonStyle(GlassButtonStyle(cornerRadius: 7))
    }

    private var targetAppsRows: some View {
        let runningBundles = state.runningBundleIdentifiers()
        return VStack(spacing: 4) {
            ForEach(state.targetApps) { app in
                HStack(spacing: 10) {
                    Image(nsImage: app.appIcon)
                        .resizable()
                        .interpolation(.high)
                        .frame(width: 18, height: 18)

                    Circle()
                        .fill(runningBundles.contains(app.bundleIdentifier) ? Color.green : Color.secondary.opacity(0.35))
                        .frame(width: 6, height: 6)

                    Text(app.displayName)
                        .font(.system(size: 12.5, weight: .medium))
                        .foregroundStyle(Color.primary)
                        .lineLimit(1)

                    Spacer(minLength: 4)

                    Button {
                        withAnimation(.easeInOut(duration: 0.16)) {
                            state.removeTargetApp(id: app.id)
                        }
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(Color.secondary)
                            .frame(width: 20, height: 20)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 10)
                .frame(height: 28)
                .background(
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(Color.primary.opacity(0.045))
                )
            }
        }
    }

    private var batterySection: some View {
        Group {
            if state.batteryInfo != nil {
                VStack(alignment: .leading, spacing: 10) {
                    settingToggleRow(
                        title: state.l10n.settingsBatteryProtection,
                        icon: "bolt.shield",
                        isOn: $state.batteryProtectionEnabled,
                        helpText: state.l10n.settingsBatteryThresholdDesc
                    )

                    if state.batteryProtectionEnabled {
                        HStack(spacing: 6) {
                            ForEach([10, 15, 20, 25, 30], id: \.self) { pct in
                                let isSelected = state.batteryThreshold == pct

                                Button {
                                    withAnimation(.easeInOut(duration: 0.16)) {
                                        state.batteryThreshold = pct
                                    }
                                } label: {
                                    Text("\(pct)%")
                                        .font(.system(size: 12.5, weight: isSelected ? .bold : .medium, design: .rounded))
                                        .foregroundStyle(isSelected ? Color.orange : Color.secondary)
                                        .frame(maxWidth: .infinity)
                                        .frame(height: 28)
                                }
                                .buttonStyle(GlassButtonStyle(
                                    isSelected: isSelected,
                                    isAccent: true,
                                    cornerRadius: 7
                                ))
                            }
                        }
                        .padding(.top, 2)
                    }
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .glassCard(cornerRadius: 10)
            } else {
                HStack(spacing: 8) {
                    Image(systemName: "desktopcomputer")
                        .font(.system(size: 13))
                        .foregroundStyle(Color.secondary)
                        .frame(width: 20, alignment: .center)

                    Text(state.l10n.desktopMacNoBattery)
                        .font(.system(size: 13))
                        .foregroundStyle(Color.secondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.85)

                    Spacer()
                }
                .frame(height: 28)
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .glassCard(cornerRadius: 10)
            }
        }
    }

    private var aboutSection: some View {
        VStack(spacing: 12) {
            // Карточка приложения
            VStack(spacing: 6) {
                Image(systemName: "cup.and.saucer.fill")
                    .font(.system(size: 38))
                    .foregroundStyle(Color.orange)
                    .symbolEffect(.bounce, value: state.isActive)

                Text("Doppio")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.primary)

                Text("v\(state.updateService.currentVersion) • macOS 2026")
                    .font(.system(size: 12, weight: .regular))
                    .foregroundStyle(Color.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .glassCard(cornerRadius: 10)

            // Блок обновлений
            updateCardView

            // Ссылка на GitHub и выход
            HStack(spacing: 10) {
                if let url = URL(string: "https://github.com/banzaez/doppio") {
                    Link(destination: url) {
                        HStack(spacing: 6) {
                            Image(systemName: "link")
                                .font(.system(size: 12))
                            Text("GitHub")
                                .font(.system(size: 12.5, weight: .medium))
                        }
                        .foregroundStyle(Color.primary.opacity(0.85))
                        .frame(maxWidth: .infinity)
                        .frame(height: 32)
                    }
                    .buttonStyle(GlassButtonStyle(cornerRadius: 8))
                }

                Button {
                    state.quitApplication()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "power")
                            .font(.system(size: 12, weight: .semibold))
                        Text(state.l10n.quitButton)
                            .font(.system(size: 12.5, weight: .medium))
                    }
                    .foregroundStyle(Color.red.opacity(0.9))
                    .frame(maxWidth: .infinity)
                    .frame(height: 32)
                }
                .buttonStyle(GlassButtonStyle(cornerRadius: 8))
            }
        }
    }

    private var updateCardView: some View {
        VStack(spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: "arrow.triangle.2.circlepath")
                    .font(.system(size: 13))
                    .foregroundStyle(Color.secondary)
                    .frame(width: 20, alignment: .center)

                Text(state.l10n.updateSectionTitle)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color.primary)

                Spacer()

                Button {
                    Task { @MainActor in
                        await state.updateService.checkForUpdates(isUserInitiated: true, l10n: state.l10n)
                    }
                } label: {
                    HStack(spacing: 5) {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 11.5))
                        Text(state.updateService.isChecking ? state.l10n.updateChecking : state.l10n.updateCheckButton)
                            .font(.system(size: 12, weight: .medium))
                    }
                    .foregroundStyle(Color.orange)
                    .padding(.horizontal, 10)
                    .frame(height: 26)
                }
                .buttonStyle(GlassButtonStyle(cornerRadius: 7))
                .disabled(state.updateService.isChecking)
            }

            Divider()
                .padding(.vertical, 1)

            settingToggleRow(
                title: state.l10n.updateAutoCheck,
                icon: "sparkles",
                isOn: $state.autoCheckUpdatesEnabled
            )
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 11)
        .glassCard(cornerRadius: 10)
    }

    private func settingToggleRow(
        title: String,
        icon: String,
        isOn: Binding<Bool>,
        helpText: String? = nil
    ) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 13))
                .foregroundStyle(Color.secondary)
                .frame(width: 20, alignment: .center)

            Text(title)
                .font(.system(size: 13))
                .foregroundStyle(Color.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.85)

            Spacer(minLength: 4)

            Toggle("", isOn: isOn)
                .toggleStyle(.switch)
                .controlSize(.small)
                .labelsHidden()
        }
        .frame(height: 28)
        .help(helpText ?? "")
    }

    // MARK: - Вспомогательные методы выбора приложений

    private func selectAppFromDisk() {
        NSApp.activate()
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
