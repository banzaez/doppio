import SwiftUI

/// Интерактивное отображение прогресса таймера
struct CircularProgressTimerView: View {
    @Bindable var state: DoppioState

    var body: some View {
        if state.isActive, let _ = state.remainingSeconds {
            HStack(spacing: 12) {
                // Кольцевой индикатор
                ZStack {
                    Circle()
                        .stroke(Color.primary.opacity(0.08), lineWidth: 3.5)
                        .frame(width: 32, height: 32)

                    Circle()
                        .trim(from: 0, to: state.timerProgress)
                        .stroke(
                            Color.orange,
                            style: StrokeStyle(lineWidth: 3.5, lineCap: .round)
                        )
                        .rotationEffect(.degrees(-90))
                        .frame(width: 32, height: 32)
                        .animation(.linear(duration: 0.95), value: state.timerProgress)

                    Image(systemName: "timer")
                        .font(.system(size: 11))
                        .foregroundStyle(Color.orange)
                }

                // Оставшееся время
                VStack(alignment: .leading, spacing: 2) {
                    Text("Осталось времени")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(Color.secondary)

                    Text(state.formattedRemainingTime)
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(Color.primary)
                }

                Spacer()

                // Кнопка сброса в бессрочный режим
                Button {
                    withAnimation {
                        state.activate(preset: .indefinite)
                    }
                } label: {
                    Text("В бессрочно")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(Color.orange)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(Color.orange.opacity(0.12))
                        )
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(Color.primary.opacity(0.03))
            )
            .transition(.opacity.combined(with: .scale(scale: 0.95)))
        }
    }
}
