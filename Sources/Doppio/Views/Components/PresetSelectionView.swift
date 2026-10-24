import SwiftUI

/// Секция выбора пресетов длительности
struct PresetSelectionView: View {
    @Bindable var state: DoppioState

    private let presets: [KeepAwakePreset] = [
        .indefinite,
        .minutes15,
        .minutes30,
        .hour1,
        .hours2,
        .hours4,
        .custom
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("ДЛИТЕЛЬНОСТЬ")
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(Color.secondary.opacity(0.8))
                .padding(.horizontal, 2)

            // Сетка чипов пресетов
            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 6),
                GridItem(.flexible(), spacing: 6),
                GridItem(.flexible(), spacing: 6),
                GridItem(.flexible(), spacing: 6)
            ], spacing: 6) {
                ForEach(presets) { preset in
                    PresetChip(
                        preset: preset,
                        isSelected: state.selectedPreset == preset,
                        isActive: state.isActive && state.selectedPreset == preset
                    ) {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            state.selectedPreset = preset
                            state.activate(preset: preset)
                        }
                    }
                }
            }

            // Настройка своего таймера при выборе custom
            if state.selectedPreset == .custom {
                VStack(spacing: 6) {
                    HStack {
                        Text("Свой таймер:")
                            .font(.system(size: 11))
                            .foregroundStyle(Color.secondary)

                        Spacer()

                        Text("\(state.customMinutes) мин")
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                            .foregroundStyle(Color.orange)
                    }

                    HStack(spacing: 8) {
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
                    }
                }
                .padding(10)
                .background(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(Color.primary.opacity(0.04))
                )
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }
}

/// Отдельный чип пресета
private struct PresetChip: View {
    let preset: KeepAwakePreset
    let isSelected: Bool
    let isActive: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 2) {
                Text(preset.shortTitle)
                    .font(.system(size: 12, weight: isSelected ? .bold : .medium, design: .rounded))
                    .foregroundStyle(isSelected ? (isActive ? Color.orange : Color.primary) : Color.secondary)

                Text(preset.title)
                    .font(.system(size: 9))
                    .foregroundStyle(isSelected ? Color.primary : Color.secondary.opacity(0.7))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 6)
            .padding(.horizontal, 4)
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(isSelected ? (isActive ? Color.orange.opacity(0.14) : Color.primary.opacity(0.08)) : Color.primary.opacity(0.03))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .stroke(isSelected ? (isActive ? Color.orange.opacity(0.4) : Color.primary.opacity(0.15)) : Color.clear, lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
    }
}
