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
    var showsHeader: Bool = true
    var onBack: (() -> Void)? = nil

    @State private var selectedTab: SettingsTab = .general
    @Namespace private var tabNamespace

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Заголовок с идеально центрированным названием и кнопкой Назад
            if showsHeader {
                headerView
                    .padding(.bottom, 2)
            }

            // Стеклянная панель переключения вкладок macOS 27 Liquid Glass
            glassTabBar

            // Содержимое выбранной вкладки
            VStack(alignment: .leading, spacing: 8) {
                switch selectedTab {
                case .general:
                    generalSection
                    menuBarSection
                case .automation:
                    smartTriggersSection
                    if state.batteryInfo != nil {
                        batterySection
                    }
                case .about:
                    aboutSection
                }
            }

            Spacer(minLength: 0)
        }
    }

    private var glassTabBar: some View {
        HStack(spacing: 4) {
            ForEach(SettingsTab.allCases) { tab in
                let isSelected = selectedTab == tab

                Button {
                    withAnimation(.spring(response: 0.28, dampingFraction: 0.78)) {
                        selectedTab = tab
                    }
                } label: {
                    HStack(spacing: 5) {
                        Image(systemName: tab.icon)
                            .font(.system(size: 10.5))
                        Text(tab.title(using: state.l10n))
                            .font(.system(size: 11, weight: isSelected ? .semibold : .medium))
                            .lineLimit(1)
                    }
                    .foregroundStyle(isSelected ? Color.primary : Color.secondary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 26)
                    .contentShape(Rectangle())
                    .background {
                        if isSelected {
                            RoundedRectangle(cornerRadius: 7, style: .continuous)
                                .fill(Color.primary.opacity(0.10))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 7, style: .continuous)
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
        .padding(3)
        .background(
            RoundedRectangle(cornerRadius: 9, style: .continuous)
                .fill(Color.primary.opacity(0.04))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 9, style: .continuous)
                .stroke(Color.primary.opacity(0.06), lineWidth: 0.5)
        )
    }

    // MARK: - Секции интерфейса

    private var headerView: some View {
        ZStack {
            Text(state.l10n.settingsTitle)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Color.primary)
                .lineLimit(1)

            HStack {
                if let onBack = onBack {
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
                }

                Spacer()
            }
        }
        .frame(height: 24)
    }

    private var generalSection: some View {
        VStack(spacing: 7) {
            // Язык интерфейса
            HStack(spacing: 8) {
                Image(systemName: "globe")
                    .font(.system(size: 11))
                    .foregroundStyle(Color.secondary)
                    .frame(width: 16, alignment: .center)

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
            .frame(height: 22)

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
                    .font(.system(size: 11))
                    .foregroundStyle(Color.secondary)
                    .frame(width: 16, alignment: .center)

                Text(state.l10n.presetCustom)
                    .font(.system(size: 11))
                    .foregroundStyle(Color.primary)
                    .lineLimit(1)

                Spacer(minLength: 4)

                HStack(spacing: 5) {
                    Button {
                        state.customMinutes = max(1, state.customMinutes - 5)
                    } label: {
                        Image(systemName: "minus")
                            .font(.system(size: 9, weight: .bold))
                            .frame(width: 18, height: 18)
                    }
                    .buttonStyle(GlassButtonStyle(cornerRadius: 5))

                    Text("\(state.customMinutes) \(state.l10n.minuteSuffix)")
                        .font(.system(size: 10.5, weight: .medium, design: .rounded))
                        .monospacedDigit()
                        .frame(minWidth: 46, alignment: .center)

                    Button {
                        state.customMinutes = min(720, state.customMinutes + 5)
                    } label: {
                        Image(systemName: "plus")
                            .font(.system(size: 9, weight: .bold))
                            .frame(width: 18, height: 18)
                    }
                    .buttonStyle(GlassButtonStyle(cornerRadius: 5))
                }
            }
            .frame(height: 22)
        }
        .padding(.horizontal, 11)
        .padding(.vertical, 9)
        .glassCard(cornerRadius: 8)
    }

    private var menuBarSection: some View {
        VStack(alignment: .leading, spacing: 7) {
            // Заголовок и переключатель стилей в компактном блоке
            HStack(spacing: 8) {
                Image(systemName: "menubar.rectangle")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Color.orange)
                    .frame(width: 16, alignment: .center)
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
                                .font(.system(size: 10))
                            Text(style.title(using: state.l10n))
                                .font(.system(size: 10.5, weight: isSelected ? .bold : .medium))
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
        .padding(.horizontal, 11)
        .padding(.vertical, 9)
        .glassCard(cornerRadius: 8)
    }

    private var smartTriggersSection: some View {
        VStack(alignment: .leading, spacing: 7) {
            HStack(spacing: 8) {
                Image(systemName: "bolt.badge.automatic")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Color.orange)
                    .frame(width: 16, alignment: .center)
                Text(state.l10n.settingsSmartTriggersSection)
                    .font(.system(size: 11, weight: .semibold))
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
                VStack(alignment: .leading, spacing: 4) {
                    if state.targetApps.isEmpty {
                        Text(state.l10n.settingsNoTargetApps)
                            .font(.system(size: 9.5, weight: .regular))
                            .foregroundStyle(Color.secondary.opacity(0.75))
                            .padding(.leading, 23)
                            .frame(height: 18)
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
                .padding(.vertical, 1)
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
        .padding(.horizontal, 11)
        .padding(.vertical, 9)
        .glassCard(cornerRadius: 8)
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
            HStack(spacing: 4) {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 10))
                Text(state.l10n.settingsAddAppButton)
                    .font(.system(size: 10.5, weight: .medium))
                    .lineLimit(1)
            }
            .foregroundStyle(Color.orange)
            .padding(.horizontal, 8)
            .frame(height: 20)
        }
        .menuStyle(.borderlessButton)
        .buttonStyle(GlassButtonStyle(cornerRadius: 6))
    }

    private var targetAppsRows: some View {
        VStack(spacing: 3) {
            ForEach(state.targetApps) { app in
                HStack(spacing: 8) {
                    Image(nsImage: app.appIcon)
                        .resizable()
                        .interpolation(.high)
                        .frame(width: 14, height: 14)

                    Circle()
                        .fill(state.isTargetAppRunning(app) ? Color.green : Color.secondary.opacity(0.35))
                        .frame(width: 5, height: 5)

                    Text(app.displayName)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(Color.primary)
                        .lineLimit(1)

                    Spacer(minLength: 4)

                    Button {
                        withAnimation(.easeInOut(duration: 0.16)) {
                            state.removeTargetApp(id: app.id)
                        }
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 8, weight: .bold))
                            .foregroundStyle(Color.secondary)
                            .frame(width: 16, height: 16)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 8)
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
                VStack(alignment: .leading, spacing: 7) {
                    settingToggleRow(
                        title: state.l10n.settingsBatteryProtection,
                        icon: "bolt.shield",
                        isOn: $state.batteryProtectionEnabled,
                        helpText: state.l10n.settingsBatteryThresholdDesc
                    )

                    if state.batteryProtectionEnabled {
                        HStack(spacing: 5) {
                            ForEach([10, 15, 20, 25, 30], id: \.self) { pct in
                                let isSelected = state.batteryThreshold == pct

                                Button {
                                    withAnimation(.easeInOut(duration: 0.16)) {
                                        state.batteryThreshold = pct
                                    }
                                } label: {
                                    Text("\(pct)%")
                                        .font(.system(size: 10.5, weight: isSelected ? .bold : .medium, design: .rounded))
                                        .foregroundStyle(isSelected ? Color.orange : Color.secondary)
                                        .frame(maxWidth: .infinity)
                                        .frame(height: 22)
                                }
                                .buttonStyle(GlassButtonStyle(
                                    isSelected: isSelected,
                                    isAccent: true,
                                    cornerRadius: 6
                                ))
                            }
                        }
                        .padding(.top, 2)
                    }
                }
                .padding(.horizontal, 11)
                .padding(.vertical, 9)
                .glassCard(cornerRadius: 8)
            } else {
                HStack(spacing: 8) {
                    Image(systemName: "desktopcomputer")
                        .font(.system(size: 11))
                        .foregroundStyle(Color.secondary)
                        .frame(width: 16, alignment: .center)

                    Text(state.l10n.desktopMacNoBattery)
                        .font(.system(size: 11))
                        .foregroundStyle(Color.secondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.85)

                    Spacer()
                }
                .frame(height: 22)
                .padding(.horizontal, 11)
                .padding(.vertical, 9)
                .glassCard(cornerRadius: 8)
            }
        }
    }

    private var aboutSection: some View {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.5.0"
        return VStack(spacing: 8) {
            // Карточка приложения
            VStack(spacing: 4) {
                Image(systemName: "cup.and.saucer.fill")
                    .font(.system(size: 32))
                    .foregroundStyle(Color.orange)
                    .symbolEffect(.bounce, value: state.isActive)

                Text("Doppio")
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.primary)

                Text("v\(version) • macOS 2026")
                    .font(.system(size: 10.5, weight: .regular))
                    .foregroundStyle(Color.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .glassCard(cornerRadius: 10)

            // Блок обновлений
            updateCardView

            // Ссылка на GitHub и выход
            HStack(spacing: 8) {
                if let url = URL(string: "https://github.com/banzaez/doppio") {
                    Link(destination: url) {
                        HStack(spacing: 5) {
                            Image(systemName: "link")
                                .font(.system(size: 10))
                            Text("GitHub")
                                .font(.system(size: 10.5, weight: .medium))
                        }
                        .foregroundStyle(Color.primary.opacity(0.85))
                        .frame(maxWidth: .infinity)
                        .frame(height: 26)
                    }
                    .buttonStyle(GlassButtonStyle(cornerRadius: 7))
                }

                Button {
                    state.quitApplication()
                } label: {
                    HStack(spacing: 5) {
                        Image(systemName: "power")
                            .font(.system(size: 10, weight: .semibold))
                        Text(state.l10n.quitButton)
                            .font(.system(size: 10.5, weight: .medium))
                    }
                    .foregroundStyle(Color.red.opacity(0.9))
                    .frame(maxWidth: .infinity)
                    .frame(height: 26)
                }
                .buttonStyle(GlassButtonStyle(cornerRadius: 7))
            }
        }
    }

    private var updateCardView: some View {
        VStack(spacing: 7) {
            HStack(spacing: 8) {
                Image(systemName: "arrow.triangle.2.circlepath")
                    .font(.system(size: 11))
                    .foregroundStyle(Color.secondary)
                    .frame(width: 16, alignment: .center)

                Text(state.l10n.updateSectionTitle)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Color.primary)

                Spacer()

                Button {
                    Task { @MainActor in
                        await AppUpdateService.shared.checkForUpdates(isUserInitiated: true, l10n: state.l10n)
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 9.5))
                        Text(state.l10n.updateCheckButton)
                            .font(.system(size: 10, weight: .medium))
                    }
                    .foregroundStyle(Color.orange)
                    .padding(.horizontal, 8)
                    .frame(height: 20)
                }
                .buttonStyle(GlassButtonStyle(cornerRadius: 6))
            }

            Divider()
                .padding(.vertical, 1)

            settingToggleRow(
                title: state.l10n.updateAutoCheck,
                icon: "sparkles",
                isOn: $state.autoCheckUpdatesEnabled
            )
        }
        .padding(.horizontal, 11)
        .padding(.vertical, 8)
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
                .font(.system(size: 11))
                .foregroundStyle(Color.secondary)
                .frame(width: 16, alignment: .center)

            Text(title)
                .font(.system(size: 11))
                .foregroundStyle(Color.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.85)

            Spacer(minLength: 4)

            Toggle("", isOn: isOn)
                .toggleStyle(.switch)
                .controlSize(.mini)
                .labelsHidden()
        }
        .frame(height: 22)
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

/// Ключ предпочтений для измерения высоты контента настроек
public struct SettingsContentHeightKey: PreferenceKey {
    public static let defaultValue: CGFloat = 0
    public static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        let next = nextValue()
        if next > 0 {
            value = next
        }
    }
}
