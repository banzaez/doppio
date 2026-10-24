import SwiftUI
import AppKit

/// Экран настроек Doppio в стеклянном стиле macOS 27
struct SettingsView: View {
    @Bindable var state: DoppioState
    let onBack: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Заголовок с кнопкой Назад
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

                // Кнопка закрытия
                Button {
                    state.deactivate(reason: "Завершение работы")
                    NSApplication.shared.terminate(nil)
                } label: {
                    Text(state.l10n.closeButton)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(Color.secondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                }
                .buttonStyle(GlassButtonStyle(cornerRadius: 8))
            }
            .padding(.bottom, 2)

            // Блок 1: Язык интерфейса
            VStack(spacing: 6) {
                HStack(spacing: 8) {
                    Image(systemName: "globe")
                        .font(.system(size: 12))
                        .foregroundStyle(Color.secondary)
                        .frame(width: 16)

                    Text(state.l10n.settingsLanguage)
                        .font(.system(size: 11))
                        .foregroundStyle(Color.primary)

                    Spacer()

                    Picker("", selection: $state.language) {
                        ForEach(AppLanguage.allCases) { lang in
                            Text(lang.displayName)
                                .tag(lang)
                        }
                    }
                    .pickerStyle(.menu)
                    .controlSize(.small)
                    .frame(maxWidth: 150)
                }
            }
            .padding(10)
            .glassCard(cornerRadius: 13)

            // Блок 2: Системные параметры
            VStack(spacing: 8) {
                settingToggleRow(
                    title: state.l10n.settingsLaunchAtLogin,
                    icon: "arrow.clockwise",
                    isOn: Binding(
                        get: { state.isLaunchAtLogin },
                        set: { _ in state.toggleLaunchAtLogin() }
                    )
                )

                Divider()
                    .padding(.horizontal, 4)

                settingToggleRow(
                    title: state.l10n.settingsTimerInMenuBar,
                    icon: "clock",
                    isOn: $state.showTimerInMenuBar
                )

                Divider()
                    .padding(.horizontal, 4)

                settingToggleRow(
                    title: state.l10n.settingsSound,
                    icon: "speaker.wave.2",
                    isOn: $state.soundFeedbackEnabled
                )
            }
            .padding(10)
            .glassCard(cornerRadius: 13)

            // Блок 3: Защита аккумулятора
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

                        HStack(spacing: 8) {
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

            // Подвал настроек с версией
            HStack {
                Text("Doppio v1.0.0 • macOS 27")
                    .font(.system(size: 10))
                    .foregroundStyle(Color.secondary.opacity(0.7))

                Spacer()
            }
            .padding(.horizontal, 4)
            .padding(.top, 2)
        }
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
}
