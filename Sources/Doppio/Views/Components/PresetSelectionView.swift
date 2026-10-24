import SwiftUI

/// Секция выбора длительности со стеклянными кнопками и фиксированной строкой своего ввода
struct PresetSelectionView: View {
    @Bindable var state: DoppioState
    @FocusState private var isMinutesFocused: Bool

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

            // Сетка из 6 основных пресетов в стиле стекла
            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 6),
                GridItem(.flexible(), spacing: 6),
                GridItem(.flexible(), spacing: 6)
            ], spacing: 6) {
                ForEach(standardPresets) { preset in
                    Button {
                        isMinutesFocused = false
                        withAnimation(.spring(response: 0.25, dampingFraction: 0.75)) {
                            state.selectedPreset = preset
                            state.activate(preset: preset)
                        }
                    } label: {
                        Text(preset.title(using: state.l10n))
                            .font(.system(size: 11, weight: state.selectedPreset == preset ? .semibold : .medium))
                            .foregroundStyle(state.selectedPreset == preset ? (state.isActive ? Color.orange : Color.primary) : Color.primary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 7)
                            .padding(.horizontal, 4)
                            .lineLimit(1)
                    }
                    .buttonStyle(GlassButtonStyle(
                        isSelected: state.selectedPreset == preset,
                        isAccent: state.isActive,
                        cornerRadius: 9
                    ))
                }
            }

            // Фиксированная стеклянная строка ввода своего времени (без раскрытия окна)
            customTimeRow
        }
    }

    /// Стеклянная строка своего времени с прямой печатью с клавиатуры и кнопками - / +
    private var customTimeRow: some View {
        let isSelected = state.selectedPreset == .custom

        return HStack(spacing: 6) {
            // Кнопка выбора пресета «Свой»
            Button {
                isMinutesFocused = false
                withAnimation(.spring(response: 0.25, dampingFraction: 0.75)) {
                    state.selectedPreset = .custom
                    state.activate(preset: .custom)
                }
            } label: {
                HStack(spacing: 5) {
                    Image(systemName: "timer")
                        .font(.system(size: 11))
                    Text(state.l10n.presetCustom)
                        .font(.system(size: 11, weight: isSelected ? .semibold : .regular))
                }
                .foregroundStyle(isSelected ? (state.isActive ? Color.orange : Color.primary) : Color.secondary)
            }
            .buttonStyle(.plain)

            Spacer()

            // Степпер и ввод с клавиатуры
            HStack(spacing: 5) {
                // Кнопка минус
                Button {
                    adjustCustomMinutes(by: -5)
                } label: {
                    Image(systemName: "minus")
                        .font(.system(size: 9, weight: .bold))
                        .frame(width: 20, height: 20)
                        .foregroundStyle(Color.primary)
                }
                .buttonStyle(GlassButtonStyle(cornerRadius: 10))

                // Поле ввода цифр с клавиатуры + суффикс минут
                HStack(spacing: 2) {
                    TextField(
                        "",
                        value: Binding(
                            get: { state.customMinutes },
                            set: { newValue in
                                state.customMinutes = max(1, min(720, newValue))
                                state.selectedPreset = .custom
                                if state.isActive {
                                    state.activate(preset: .custom)
                                }
                            }
                        ),
                        format: .number
                    )
                    .textFieldStyle(.plain)
                    .multilineTextAlignment(.center)
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .frame(width: 32)
                    .focused($isMinutesFocused)
                    .onSubmit {
                        state.selectedPreset = .custom
                        if state.isActive {
                            state.activate(preset: .custom)
                        }
                    }

                    Text(state.l10n.minuteSuffix)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(isSelected ? Color.orange : Color.secondary)
                }
                .padding(.horizontal, 5)
                .padding(.vertical, 2)
                .background(
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(Color.primary.opacity(isMinutesFocused ? 0.08 : 0.03))
                )

                // Кнопка плюс
                Button {
                    adjustCustomMinutes(by: 5)
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 9, weight: .bold))
                        .frame(width: 20, height: 20)
                        .foregroundStyle(Color.primary)
                }
                .buttonStyle(GlassButtonStyle(cornerRadius: 10))
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .frame(height: 34)
        .glassCard(cornerRadius: 9)
    }

    private func adjustCustomMinutes(by delta: Int) {
        withAnimation(.spring(response: 0.2, dampingFraction: 0.75)) {
            let updated = max(5, min(720, state.customMinutes + delta))
            state.customMinutes = updated
            state.selectedPreset = .custom
            if state.isActive {
                state.activate(preset: .custom)
            }
        }
    }
}
