import SwiftUI

/// Переключатель режима сна в виде нативного Segmented Control macOS 27
struct SleepModeSelectorView: View {
    @Bindable var state: DoppioState

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("РЕЖИМ БОДРСТВОВАНИЯ")
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(Color.secondary)
                .padding(.horizontal, 2)

            Picker("Режим бодрствования", selection: $state.assertionType) {
                Label("Экран и Mac", systemImage: "display")
                    .tag(SleepAssertionType.systemAndDisplay)

                Label("Только Mac", systemImage: "cpu")
                    .tag(SleepAssertionType.systemOnly)
            }
            .pickerStyle(.segmented)
            .controlSize(.regular)
            .labelsHidden()

            Text(state.assertionType == .systemAndDisplay ? "Дисплей не погаснет, блокировка не включится" : "Дисплей может спать, фоновые задачи продолжат работу")
                .font(.system(size: 10))
                .foregroundStyle(Color.secondary.opacity(0.8))
                .padding(.horizontal, 2)
        }
    }
}
