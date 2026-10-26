import SwiftUI

/// Секция выбора длительности со стеклянными кнопками и фиксированной строкой своего ввода
struct PresetSelectionView: View {
    @Bindable var state: DoppioState
    @FocusState private var isMinutesFocused: Bool
    @State private var localMinutes: Int = 45

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
                .lineLimit(1)

            // Сетка из 6 основных пресетов в стиле жидкого стекла macOS 27 / iOS 2026
            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 6),
                GridItem(.flexible(), spacing: 6),
                GridItem(.flexible(), spacing: 6)
            ], spacing: 6) {
                ForEach(standardPresets) { preset in
                    Button {
                        isMinutesFocused = false
                        withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                            state.selectedPreset = preset
                            state.activate(preset: preset)
                        }
                    } label: {
                        Text(preset.title(using: state.l10n))
                            .font(.system(size: 11, weight: state.selectedPreset == preset ? .semibold : .medium))
                            .foregroundStyle(state.selectedPreset == preset ? (state.isActive ? Color.orange : Color.primary) : Color.primary)
                            .frame(maxWidth: .infinity)
                            .frame(height: 28)
                            .padding(.horizontal, 4)
                            .lineLimit(1)
                            .minimumScaleFactor(0.85)
                    }
                    .buttonStyle(GlassButtonStyle(
                        isSelected: state.selectedPreset == preset,
                        isAccent: state.isActive,
                        cornerRadius: 9
                    ))
                }
            }

            // Фиксированная стеклянная строка ввода своего времени
            customTimeRow
        }
        .onAppear {
            localMinutes = state.customMinutes
            isMinutesFocused = false
            Task { @MainActor in
                isMinutesFocused = false
            }
        }
        .onChange(of: state.customMinutes) { _, newValue in
            localMinutes = newValue
        }
    }

    /// Стеклянная строка своего времени с прямой печатью с клавиатуры и кнопками - / +
    private var customTimeRow: some View {
        let isSelected = state.selectedPreset == .custom

        return HStack(spacing: 6) {
            // Кликабельная левая область выбора и запуска пресета «Свой таймер»
            Button {
                isMinutesFocused = false
                activateCustomPreset()
            } label: {
                HStack(spacing: 5) {
                    Image(systemName: "timer")
                        .font(.system(size: 11))
                    Text(state.l10n.presetCustom)
                        .font(.system(size: 11, weight: isSelected ? .semibold : .regular))
                        .lineLimit(1)
                        .minimumScaleFactor(0.85)
                    Spacer(minLength: 4)
                }
                .foregroundStyle(isSelected ? (state.isActive ? Color.orange : Color.primary) : Color.secondary)
                .frame(maxHeight: .infinity)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

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
                        value: $localMinutes,
                        format: .number
                    )
                    .textFieldStyle(.plain)
                    .multilineTextAlignment(.center)
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .frame(width: 32)
                    .focused($isMinutesFocused)
                    .onSubmit {
                        activateCustomPreset()
                    }
                    .onChange(of: isMinutesFocused) { _, focused in
                        if !focused {
                            commitMinutesSilently()
                        }
                    }

                    Text(state.l10n.minuteSuffix)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(isSelected ? Color.orange : Color.secondary)
                        .lineLimit(1)
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
        .frame(height: 34)
        .glassCard(cornerRadius: 9, isSelected: isSelected, isAccent: state.isActive)
    }

    private func commitMinutesSilently() {
        let clamped = max(1, min(720, localMinutes))
        localMinutes = clamped
        state.customMinutes = clamped
    }

    private func activateCustomPreset() {
        isMinutesFocused = false
        withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
            let clamped = max(1, min(720, localMinutes))
            localMinutes = clamped
            state.customMinutes = clamped
            state.activate(preset: .custom)
        }
    }

    private func adjustCustomMinutes(by delta: Int) {
        isMinutesFocused = false
        withAnimation(.spring(response: 0.2, dampingFraction: 0.8)) {
            let current = state.customMinutes
            let next: Int
            if delta < 0 && current <= 5 {
                next = 1
            } else if delta > 0 && current == 1 {
                next = 5
            } else {
                next = max(1, min(720, current + delta))
            }
            localMinutes = next
            state.customMinutes = next
            state.activate(preset: .custom)
        }
    }
}
