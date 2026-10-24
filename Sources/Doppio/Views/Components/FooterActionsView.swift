import SwiftUI
import AppKit

/// Нижняя строка навигации основного экрана Doppio со стеклянными кнопками
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
                }
                .foregroundStyle(Color.secondary)
                .padding(.horizontal, 9)
                .padding(.vertical, 5)
            }
            .buttonStyle(GlassButtonStyle(cornerRadius: 8))

            Spacer()

            // Индикатор питания
            if let info = state.batteryInfo {
                HStack(spacing: 4) {
                    Image(systemName: info.iconName)
                        .font(.system(size: 10))
                        .foregroundStyle(info.isCharging ? Color.green : (info.percentage <= state.batteryThreshold ? Color.red : Color.secondary))

                    Text("\(info.percentage)%")
                        .font(.system(size: 10, weight: .medium, design: .rounded))
                        .foregroundStyle(Color.secondary)
                }
                .padding(.horizontal, 6)
                .padding(.vertical, 4)
                .background(
                    Capsule()
                        .fill(Color.primary.opacity(0.04))
                )
                .help(info.description(using: state.l10n))
            }

            Spacer()

            // Кнопка закрытия приложения с явной надписью «Закрыть»
            Button {
                state.deactivate(reason: "Завершение работы")
                NSApplication.shared.terminate(nil)
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "xmark.circle")
                        .font(.system(size: 10))
                    Text(state.l10n.closeButton)
                        .font(.system(size: 11, weight: .medium))
                }
                .foregroundStyle(Color.secondary)
                .padding(.horizontal, 9)
                .padding(.vertical, 5)
            }
            .buttonStyle(GlassButtonStyle(cornerRadius: 8))
        }
        .padding(.horizontal, 2)
    }
}
