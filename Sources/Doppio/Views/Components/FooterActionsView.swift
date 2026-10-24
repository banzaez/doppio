import SwiftUI
import AppKit

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
                }
                .foregroundStyle(Color.secondary)
                .padding(.horizontal, 9)
                .padding(.vertical, 5)
            }
            .buttonStyle(GlassButtonStyle(cornerRadius: 8))

            Spacer()

            // Индикатор питания в стеклянной капсуле
            if let info = state.batteryInfo {
                HStack(spacing: 4) {
                    Image(systemName: info.iconName)
                        .font(.system(size: 10))
                        .foregroundStyle(batteryColor(for: info))

                    Text("\(info.percentage)%")
                        .font(.system(size: 10, weight: .semibold, design: .rounded))
                        .foregroundStyle(Color.secondary)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .glassCapsule(isAccent: info.percentage <= state.batteryThreshold)
                .help(info.description(using: state.l10n))
            }

            Spacer()

            // Кнопка закрытия приложения с явной надписью «Закрыть»
            Button {
                state.deactivate(reason: .quitApp)
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

    private func batteryColor(for info: BatteryInfo) -> Color {
        if info.isCharging {
            return .green
        }
        if info.percentage <= state.batteryThreshold {
            return .red
        }
        if info.percentage <= 40 {
            return .orange
        }
        return .secondary
    }
}
