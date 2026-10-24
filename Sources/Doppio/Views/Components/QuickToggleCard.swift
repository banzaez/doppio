import SwiftUI

/// Верхняя карточка быстрого переключения состояния Doppio
struct QuickToggleCard: View {
    @Bindable var state: DoppioState

    var body: some View {
        Button {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                state.toggle()
            }
        } label: {
            HStack(spacing: 14) {
                // Иконка чашки кофе с эффектом
                ZStack {
                    Circle()
                        .fill(state.isActive ? Color.orange.opacity(0.18) : Color.primary.opacity(0.06))
                        .frame(width: 44, height: 44)

                    Image(systemName: state.isActive ? "cup.and.saucer.fill" : "cup.and.saucer")
                        .font(.system(size: 22))
                        .foregroundStyle(state.isActive ? Color.orange : Color.secondary)
                        .symbolEffect(.bounce, value: state.isActive)
                }

                // Текстовая информация
                VStack(alignment: .leading, spacing: 3) {
                    HStack {
                        Text(state.isActive ? "Doppio бодрствует" : "Doppio выключен")
                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                            .foregroundStyle(Color.primary)

                        Spacer()

                        // Индикатор точки
                        Circle()
                            .fill(state.isActive ? Color.green : Color.secondary.opacity(0.4))
                            .frame(width: 8, height: 8)
                    }

                    Text(subtitleText)
                        .font(.system(size: 11))
                        .foregroundStyle(Color.secondary)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(state.isActive ? Color.orange.opacity(0.08) : Color.primary.opacity(0.03))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(state.isActive ? Color.orange.opacity(0.3) : Color.primary.opacity(0.06), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
    }

    private var subtitleText: String {
        if state.isActive {
            if let _ = state.remainingSeconds {
                return "Таймер: \(state.formattedRemainingTime) • Нажмите для отмены"
            } else {
                return "Бессрочно • Нажмите, чтобы усыпить"
            }
        } else {
            if let reason = state.lastDeactivationReason {
                return "\(reason) • Нажмите для старта"
            } else {
                return "Нажмите для предотвращения сна"
            }
        }
    }
}
