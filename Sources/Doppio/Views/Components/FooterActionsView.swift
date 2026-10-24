import SwiftUI
import AppKit

/// Нижняя строка навигации основного экрана Doppio
struct FooterActionsView: View {
    @Bindable var state: DoppioState
    let onOpenSettings: () -> Void

    var body: some View {
        HStack {
            // Кнопка перехода в настройки
            Button(action: onOpenSettings) {
                HStack(spacing: 5) {
                    Image(systemName: "gearshape")
                        .font(.system(size: 11))
                    Text(state.l10n.settingsTitle)
                        .font(.system(size: 11, weight: .medium))
                }
                .foregroundStyle(Color.secondary)
            }
            .buttonStyle(.plain)

            Spacer()

            // Индикатор питания
            if let info = state.batteryInfo {
                HStack(spacing: 5) {
                    Image(systemName: info.iconName)
                        .font(.system(size: 11))
                        .foregroundStyle(info.isCharging ? Color.green : (info.percentage <= state.batteryThreshold ? Color.red : Color.secondary))

                    Text("\(info.percentage)%")
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundStyle(Color.secondary)
                }
                .help(info.description(using: state.l10n))
            }

            Spacer()

            // Кнопка быстрого выхода
            Button {
                state.deactivate(reason: "Завершение работы")
                NSApplication.shared.terminate(nil)
            } label: {
                Image(systemName: "power")
                    .font(.system(size: 11))
                    .foregroundStyle(Color.secondary.opacity(0.8))
            }
            .buttonStyle(.plain)
            .help(state.l10n.quitButton)
        }
        .padding(.horizontal, 4)
    }
}
