import SwiftUI

/// Нижняя строка навигации основного экрана Doppio со стеклянными кнопками macOS 27 / iOS 2026
struct FooterActionsView: View {
    @Bindable var state: DoppioState
    let onOpenSettings: () -> Void

    var body: some View {
        HStack(spacing: 8) {
            // Кнопка перехода в настройки со стеклянным стилем
            Button(action: onOpenSettings) {
                HStack(spacing: 5) {
                    Image(systemName: "gearshape")
                        .font(.system(size: 11))
                    Text(state.l10n.settingsTitle)
                        .font(.system(size: 11, weight: .medium))
                        .lineLimit(1)
                }
                .foregroundStyle(Color.secondary)
                .padding(.horizontal, 9)
                .frame(height: 24)
            }
            .buttonStyle(GlassButtonStyle(cornerRadius: 8))

            Spacer(minLength: 4)

            // Индикатор питания в стеклянной капсуле
            if let info = state.batteryInfo {
                HStack(spacing: 4) {
                    Image(systemName: info.iconName)
                        .font(.system(size: 10))
                        .foregroundStyle(info.statusColor(threshold: state.batteryThreshold))

                    Text("\(info.percentage)%")
                        .font(.system(size: 10, weight: .semibold, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(Color.secondary)
                }
                .padding(.horizontal, 8)
                .frame(height: 22)
                .glassCapsule(isAccent: info.percentage <= state.batteryThreshold)
                .help(info.description(using: state.l10n))
            }

            Spacer(minLength: 4)

            // Кнопка завершения работы приложения
            Button {
                state.quitApplication()
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "power")
                        .font(.system(size: 10, weight: .medium))
                    Text(state.l10n.closeButton)
                        .font(.system(size: 11, weight: .medium))
                        .lineLimit(1)
                }
                .foregroundStyle(Color.secondary)
                .padding(.horizontal, 9)
                .frame(height: 24)
            }
            .buttonStyle(GlassButtonStyle(cornerRadius: 8))
            .help(state.l10n.quitButton)
        }
        .padding(.horizontal, 2)
        .frame(height: 26)
    }
}
