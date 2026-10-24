import SwiftUI

/// Карточка переключателя в стиле Control Center macOS 27 с жидким стеклом
struct ControlCenterHeroCard: View {
    @Bindable var state: DoppioState

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                // Иконка в стиле macOS Control Center
                ZStack {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(state.isActive ? Color.orange : Color.primary.opacity(0.08))
                        .frame(width: 38, height: 38)
                        .shadow(color: state.isActive ? Color.orange.opacity(0.4) : Color.clear, radius: 4, y: 1.5)

                    Image(systemName: state.isActive ? "cup.and.saucer.fill" : "cup.and.saucer")
                        .font(.system(size: 19))
                        .foregroundStyle(state.isActive ? Color.white : Color.secondary)
                        .symbolEffect(.bounce, value: state.isActive)
                }

                // Заголовок и подзаголовок состояния
                VStack(alignment: .leading, spacing: 2) {
                    Text("Doppio")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Color.primary)

                    Text(statusSubtitle)
                        .font(.system(size: 11))
                        .foregroundStyle(Color.secondary)
                        .lineLimit(1)
                }

                Spacer()

                // Нативный тумблер macOS
                Toggle("", isOn: Binding(
                    get: { state.isActive },
                    set: { _ in
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
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

            // Интегрированный прогресс-бар таймера
            if state.isActive, let _ = state.remainingSeconds {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Rectangle()
                            .fill(Color.primary.opacity(0.06))
                            .frame(height: 3)

                        Rectangle()
                            .fill(Color.orange)
                            .frame(width: geo.size.width * CGFloat(state.timerProgress), height: 3)
                            .animation(.linear(duration: 0.95), value: state.timerProgress)
                    }
                }
                .frame(height: 3)
            }
        }
        .glassCard(cornerRadius: 14)
    }

    private var statusSubtitle: String {
        if state.isActive {
            if let _ = state.remainingSeconds {
                return state.l10n.statusRemaining(state.formattedRemainingTime)
            } else {
                return state.l10n.statusAwakeIndefinitely
            }
        } else {
            return state.l10n.statusSleepAllowed
        }
    }
}
