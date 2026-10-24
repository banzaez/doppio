import SwiftUI

/// Карточка переключателя в стиле Control Center macOS 27 / iOS 2026 с жидким стеклом
struct ControlCenterHeroCard: View {
    @Bindable var state: DoppioState

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                // Иконка в стиле macOS / iOS Control Center с мягким свечением
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
            .contentShape(Rectangle())
            .onTapGesture {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                    state.toggle()
                }
            }
        }
        .glassCard(cornerRadius: 14, isSelected: state.isActive, isAccent: true)
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
