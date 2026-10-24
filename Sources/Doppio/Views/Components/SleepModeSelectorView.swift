import SwiftUI

/// Переключатель режима сна с поддержкой мультиязычности
struct SleepModeSelectorView: View {
    @Bindable var state: DoppioState

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(state.l10n.sectionMode)
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(Color.secondary)
                .padding(.horizontal, 2)

            Picker(state.l10n.sectionMode, selection: $state.assertionType) {
                Label(state.assertionType == .systemAndDisplay ? state.assertionType.title(using: state.l10n) : SleepAssertionType.systemAndDisplay.title(using: state.l10n), systemImage: "display")
                    .tag(SleepAssertionType.systemAndDisplay)

                Label(state.assertionType == .systemOnly ? state.assertionType.title(using: state.l10n) : SleepAssertionType.systemOnly.title(using: state.l10n), systemImage: "cpu")
                    .tag(SleepAssertionType.systemOnly)
            }
            .pickerStyle(.segmented)
            .controlSize(.regular)
            .labelsHidden()

            Text(state.assertionType.description(using: state.l10n))
                .font(.system(size: 10))
                .foregroundStyle(Color.secondary.opacity(0.8))
                .padding(.horizontal, 2)
        }
    }
}
