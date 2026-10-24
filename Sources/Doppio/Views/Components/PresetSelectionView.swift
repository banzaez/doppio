import SwiftUI

/// Секция выбора длительности в стеклянном стиле macOS 27 с адаптивным таймером
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

            // Сетка из 6 основных пресетов
            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 6),
                GridItem(.flexible(), spacing: 6),
                GridItem(.flexible(), spacing: 6)
            ], spacing: 6) {
                ForEach(standardPresets) { preset in
                    Button {
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

            // Блок «Свой таймер»: когда не выбран — компактная кнопка, когда выбран — интерактивная капсула
            if state.selectedPreset == .custom {
                customTimeCapsule
                    .transition(.opacity)
            } else {
                customTimerInactiveButton
                    .transition(.opacity)
            }
        }
    }

    /// Компактная кнопка выбора своего таймера в неактивном состоянии
    private var customTimerInactiveButton: some View {
        Button {
            withAnimation(.spring(response: 0.28, dampingFraction: 0.78)) {
                state.selectedPreset = .custom
                state.activate(preset: .custom)
            }
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "timer")
                    .font(.system(size: 12))
                    .foregroundStyle(Color.secondary)

                Text(state.l10n.presetCustom)
                    .font(.system(size: 11, weight: .regular))
                    .foregroundStyle(Color.primary)

                Spacer()

                Text(formattedCustomDuration)
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundStyle(Color.secondary)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(GlassButtonStyle(
            isSelected: false,
            cornerRadius: 9
        ))
    }

    /// Интерактивная капсула настройки своего времени
    private var customTimeCapsule: some View {
        VStack(spacing: 7) {
            HStack(spacing: 8) {
                // Кнопка уменьшения
                Button {
                    adjustCustomMinutes(by: -stepInterval)
                } label: {
                    Image(systemName: "minus")
                        .font(.system(size: 11, weight: .bold))
                        .frame(width: 24, height: 24)
                        .foregroundStyle(Color.primary)
                }
                .buttonStyle(GlassButtonStyle(cornerRadius: 12))

                Spacer()

                // Центральный дисплей
                HStack(spacing: 5) {
                    Image(systemName: "clock.badge.checkmark")
                        .font(.system(size: 11))
                        .foregroundStyle(Color.orange)

                    Text(formattedCustomDuration)
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(Color.primary)
                }

                Spacer()

                // Кнопка увеличения
                Button {
                    adjustCustomMinutes(by: stepInterval)
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 11, weight: .bold))
                        .frame(width: 24, height: 24)
                        .foregroundStyle(Color.primary)
                }
                .buttonStyle(GlassButtonStyle(cornerRadius: 12))
            }

            // Быстрые умные чипы
            HStack(spacing: 4) {
                quickJumpChip(title: "45м", minutes: 45)
                quickJumpChip(title: "90м", minutes: 90)
                quickJumpChip(title: "3ч", minutes: 180)
                quickJumpChip(title: "8ч", minutes: 480)
            }
        }
        .padding(8)
        .glassCard(cornerRadius: 11)
    }

    private func quickJumpChip(title: String, minutes: Int) -> some View {
        let isCurrent = state.customMinutes == minutes

        return Button {
            withAnimation(.spring(response: 0.22, dampingFraction: 0.75)) {
                state.customMinutes = minutes
                if state.isActive && state.selectedPreset == .custom {
                    state.activate(preset: .custom)
                }
            }
        } label: {
            Text(title)
                .font(.system(size: 10, weight: isCurrent ? .bold : .medium, design: .rounded))
                .foregroundStyle(isCurrent ? Color.orange : Color.secondary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 4)
        }
        .buttonStyle(GlassButtonStyle(
            isSelected: isCurrent,
            isAccent: true,
            cornerRadius: 7
        ))
    }

    private var stepInterval: Int {
        if state.customMinutes >= 60 {
            return 15
        } else {
            return 5
        }
    }

    private func adjustCustomMinutes(by delta: Int) {
        withAnimation(.spring(response: 0.2, dampingFraction: 0.75)) {
            let updated = max(5, min(720, state.customMinutes + delta))
            state.customMinutes = updated
            if state.isActive && state.selectedPreset == .custom {
                state.activate(preset: .custom)
            }
        }
    }

    private var formattedCustomDuration: String {
        let hours = state.customMinutes / 60
        let mins = state.customMinutes % 60

        let code = state.l10n.language.effectiveCode
        let isUk = code == "uk"
        let isCyrillic = ["ru", "uk"].contains(code)

        let hSuffix = isUk ? "год" : (isCyrillic ? "ч" : "h")
        let mSuffix = isUk ? "хв" : (isCyrillic ? "мин" : "m")

        if hours > 0 {
            if mins > 0 {
                return "\(hours) \(hSuffix) \(mins) \(mSuffix)"
            } else {
                return "\(hours) \(hSuffix)"
            }
        } else {
            return "\(mins) \(mSuffix)"
        }
    }
}
