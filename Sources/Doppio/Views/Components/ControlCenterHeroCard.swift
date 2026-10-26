import SwiftUI

/// Карточка переключателя в стиле Control Center macOS 27 / iOS 2026 с жидким стеклом и интегрированной полосой прогресса
struct ControlCenterHeroCard: View {
    @Bindable var state: DoppioState

    var body: some View {
        HStack(spacing: 12) {
            // Левая кликабельная область (иконка + статус)
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(
                            state.isActive
                                ? LinearGradient(
                                    colors: [Color.orange, Color.orange.opacity(0.85)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                                : LinearGradient(
                                    colors: [Color.primary.opacity(0.08), Color.primary.opacity(0.04)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                        )
                        .frame(width: 38, height: 38)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .stroke(
                                    state.isActive
                                        ? Color.white.opacity(0.35)
                                        : Color.white.opacity(0.12),
                                    lineWidth: 0.75
                                )
                        )
                        .shadow(
                            color: state.isActive ? Color.orange.opacity(0.40) : Color.clear,
                            radius: 6,
                            y: 2
                        )

                    Image(systemName: state.isActive ? "cup.and.saucer.fill" : "cup.and.saucer")
                        .font(.system(size: 19))
                        .foregroundStyle(state.isActive ? Color.white : Color.secondary)
                        .symbolEffect(.bounce, value: state.isActive)
                }

                // Заголовок, бейдж триггера и подзаголовок состояния
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text("Doppio")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(Color.primary)

                        if state.isActive,
                           let icon = state.activeTriggerSource.badgeIconName,
                           let badgeText = state.activeTriggerSource.badgeTitle(using: state.l10n) {
                            HStack(spacing: 3) {
                                Image(systemName: icon)
                                    .font(.system(size: 8.5, weight: .semibold))
                                Text(badgeText)
                                    .font(.system(size: 9.5, weight: .medium))
                                    .lineLimit(1)
                            }
                            .foregroundStyle(Color.orange)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 1.5)
                            .background(
                                Capsule(style: .continuous)
                                    .fill(Color.orange.opacity(0.15))
                            )
                            .transition(.opacity.combined(with: .scale(scale: 0.9)))
                        }
                    }

                    Text(statusSubtitle)
                        .font(.system(size: 11, weight: .regular, design: .rounded))
                        .monospacedDigit()
                        .contentTransition(.numericText())
                        .foregroundStyle(Color.secondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.85)
                }

                Spacer(minLength: 4)
            }
            .contentShape(Rectangle())
            .onTapGesture {
                withAnimation(.spring(response: 0.28, dampingFraction: 0.8)) {
                    state.toggle()
                }
            }

            // Нативный тумблер macOS
            Toggle("", isOn: Binding(
                get: { state.isActive },
                set: { _ in
                    withAnimation(.spring(response: 0.28, dampingFraction: 0.8)) {
                        state.toggle()
                    }
                }
            ))
            .toggleStyle(.switch)
            .controlSize(.regular)
            .labelsHidden()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .frame(height: 58)
        .overlay(alignment: .bottom) {
            // Интегрированная полоса прогресса по нижней кромке без изменения высоты карточки
            if let progress = state.timerProgress {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Rectangle()
                            .fill(Color.orange.opacity(0.12))
                        Rectangle()
                            .fill(
                                LinearGradient(
                                    colors: [Color.orange.opacity(0.75), Color.orange],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: max(0, geo.size.width * progress))
                            .animation(.linear(duration: 0.25), value: progress)
                    }
                }
                .frame(height: 2.5)
                .transition(.opacity)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .glassCard(cornerRadius: 14, isSelected: state.isActive, isAccent: true)
    }

    private var statusSubtitle: String {
        if state.isActive {
            if state.remainingSeconds != nil {
                return state.l10n.statusRemaining(state.formattedRemainingTime)
            } else {
                return state.l10n.statusAwakeIndefinitely
            }
        } else {
            return state.l10n.statusSleepAllowed
        }
    }
}
