import SwiftUI

/// Разворачиваемая панель настроек Doppio
struct QuickSettingsPanel: View {
    @Bindable var state: DoppioState

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Divider()
                .padding(.vertical, 2)

            Text("ПАРАМЕТРЫ")
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(Color.secondary.opacity(0.8))
                .padding(.horizontal, 2)

            // Запуск при входе в систему
            Toggle(isOn: Binding(
                get: { state.isLaunchAtLogin },
                set: { _ in state.toggleLaunchAtLogin() }
            )) {
                Label("Запуск при входе в macOS", systemImage: "arrow.clockwise")
                    .font(.system(size: 11))
            }
            .toggleStyle(.switch)
            .controlSize(.mini)

            // Отображение таймера в Menu Bar
            Toggle(isOn: $state.showTimerInMenuBar) {
                Label("Таймер в строке меню", systemImage: "clock")
                    .font(.system(size: 11))
            }
            .toggleStyle(.switch)
            .controlSize(.mini)

            // Звуковые эффекты
            Toggle(isOn: $state.soundFeedbackEnabled) {
                Label("Звуковые эффекты", systemImage: "speaker.wave.2")
                    .font(.system(size: 11))
            }
            .toggleStyle(.switch)
            .controlSize(.mini)

            // Защита батареи
            VStack(alignment: .leading, spacing: 4) {
                Toggle(isOn: $state.batteryProtectionEnabled) {
                    Label("Защита батареи", systemImage: "bolt.shield")
                        .font(.system(size: 11))
                }
                .toggleStyle(.switch)
                .controlSize(.mini)

                if state.batteryProtectionEnabled {
                    HStack {
                        Text("Отключать при заряде ниже:")
                            .font(.system(size: 10))
                            .foregroundStyle(Color.secondary)

                        Spacer()

                        Text("\(state.batteryThreshold)%")
                            .font(.system(size: 10, weight: .bold, design: .rounded))
                            .foregroundStyle(Color.orange)
                    }
                    .padding(.leading, 22)

                    Slider(
                        value: Binding(
                            get: { Double(state.batteryThreshold) },
                            set: { state.batteryThreshold = Int($0) }
                        ),
                        in: 10...40,
                        step: 5
                    )
                    .tint(Color.orange)
                    .controlSize(.mini)
                    .padding(.leading, 22)
                }
            }
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Color.primary.opacity(0.025))
        )
    }
}
