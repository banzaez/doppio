import SwiftUI
import AppKit

/// Экран настроек Doppio с поддержкой мультиязычности и нативной локализацией macOS
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
                            .font(.system(size: 12, weight: .medium))
                    }
                    .foregroundStyle(Color.orange)
                }
                .buttonStyle(.plain)

                Spacer()

                Text(state.l10n.settingsTitle)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color.primary)

                Spacer()

                // Пустой блок для симметрии
                Color.clear
                    .frame(width: 44, height: 16)
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
                    .frame(maxWidth: 160)
                }
            }
            .padding(10)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(Color(nsColor: .controlBackgroundColor).opacity(0.8))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .stroke(Color.primary.opacity(0.08), lineWidth: 0.5)
                    )
            )

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
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(Color(nsColor: .controlBackgroundColor).opacity(0.8))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .stroke(Color.primary.opacity(0.08), lineWidth: 0.5)
                    )
            )

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

                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(state.l10n.settingsBatteryThresholdDesc)
                                .font(.system(size: 10))
                                .foregroundStyle(Color.secondary)

                            Spacer()

                            Text("\(state.batteryThreshold)%")
                                .font(.system(size: 11, weight: .bold, design: .rounded))
                                .foregroundStyle(Color.orange)
                        }

                        Slider(
                            value: Binding(
                                get: { Double(state.batteryThreshold) },
                                set: { state.batteryThreshold = Int($0) }
                            ),
                            in: 10...40,
                            step: 5
                        )
                        .tint(Color.orange)
                        .controlSize(.small)
                    }
                    .padding(.horizontal, 4)
                    .padding(.top, 2)
                }
            }
            .padding(10)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(Color(nsColor: .controlBackgroundColor).opacity(0.8))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .stroke(Color.primary.opacity(0.08), lineWidth: 0.5)
                    )
            )

            // Блок 4: Выход из приложения
            HStack {
                Text("Doppio v1.0.0")
                    .font(.system(size: 10))
                    .foregroundStyle(Color.secondary.opacity(0.7))

                Spacer()

                Button {
                    state.deactivate(reason: "Завершение работы")
                    NSApplication.shared.terminate(nil)
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "power")
                            .font(.system(size: 10, weight: .bold))
                        Text(state.l10n.quitButton)
                            .font(.system(size: 11, weight: .medium))
                    }
                    .foregroundStyle(Color.red.opacity(0.9))
                }
                .buttonStyle(.plain)
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
