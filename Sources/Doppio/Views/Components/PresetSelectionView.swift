import SwiftUI

/// Секция выбора длительности с полной локализацией
struct PresetSelectionView: View {
    @Bindable var state: DoppioState

    private let standardPresets: [KeepAwakePreset] = [
        .indefinite,
        .minutes15,
        .minutes30,
        .hour1,
        .hours2,
        .hours4
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(state.l10n.sectionTimer)
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(Color.secondary)
                .padding(.horizontal, 2)

            // Сетка из 6 основных пресетов (3x2)
            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 6),
                GridItem(.flexible(), spacing: 6),
                GridItem(.flexible(), spacing: 6)
            ], spacing: 6) {
                ForEach(standardPresets) { preset in
                    PresetButton(
                        title: preset.title(using: state.l10n),
                        isSelected: state.selectedPreset == preset,
                        isActive: state.isActive && state.selectedPreset == preset
                    ) {
                        withAnimation(.spring(response: 0.25, dampingFraction: 0.75)) {
                            state.selectedPreset = preset
                            state.activate(preset: preset)
                        }
                    }
                }
            }

            // Кнопка своего таймера
            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                    state.selectedPreset = .custom
                    state.activate(preset: .custom)
                }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "slider.horizontal.3")
                        .font(.system(size: 11))
                        .foregroundStyle(state.selectedPreset == .custom ? Color.orange : Color.secondary)

                    Text(state.l10n.presetCustom)
                        .font(.system(size: 11, weight: state.selectedPreset == .custom ? .semibold : .regular))
                        .foregroundStyle(state.selectedPreset == .custom ? Color.primary : Color.secondary)

                    Spacer()

                    Text(state.l10n.presetMinutes(state.customMinutes))
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundStyle(state.selectedPreset == .custom ? Color.orange : Color.secondary)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(state.selectedPreset == .custom ? Color.orange.opacity(0.12) : Color(nsColor: .controlBackgroundColor).opacity(0.6))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .stroke(state.selectedPreset == .custom ? Color.orange.opacity(0.4) : Color.primary.opacity(0.06), lineWidth: 0.5)
                        )
                )
            }
            .buttonStyle(.plain)

            // Слайдер выбора минут при выбранном Custom
            if state.selectedPreset == .custom {
                VStack(spacing: 4) {
                    HStack {
                        Text(state.l10n.presetMinutes(5))
                            .font(.system(size: 9))
                            .foregroundStyle(Color.secondary)
                        Spacer()
                        Text(state.l10n.presetHours(4))
                            .font(.system(size: 9))
                            .foregroundStyle(Color.secondary)
                    }

                    Slider(
                        value: Binding(
                            get: { Double(state.customMinutes) },
                            set: { newValue in
                                state.customMinutes = Int(newValue)
                                if state.isActive && state.selectedPreset == .custom {
                                    state.activate(preset: .custom)
                                }
                            }
                        ),
                        in: 5...240,
                        step: 5
                    )
                    .tint(Color.orange)
                    .controlSize(.small)
                }
                .padding(.horizontal, 6)
                .padding(.top, 2)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }
}

/// Кнопка стандартного пресета с комфортным размером для текста
private struct PresetButton: View {
    let title: String
    let isSelected: Bool
    let isActive: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 2) {
                Text(title)
                    .font(.system(size: 11, weight: isSelected ? .semibold : .medium))
                    .foregroundStyle(isSelected ? (isActive ? Color.orange : Color.primary) : Color.primary)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 7)
            .padding(.horizontal, 4)
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(isSelected ? (isActive ? Color.orange.opacity(0.14) : Color.primary.opacity(0.08)) : Color(nsColor: .controlBackgroundColor).opacity(0.6))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .stroke(isSelected ? (isActive ? Color.orange.opacity(0.4) : Color.primary.opacity(0.18)) : Color.primary.opacity(0.06), lineWidth: 0.5)
                    )
            )
        }
        .buttonStyle(.plain)
    }
}
