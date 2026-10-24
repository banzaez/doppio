import SwiftUI
import AppKit

/// Нижняя панель действий (Настройки, автозапуск, выход)
struct FooterActionsView: View {
    @Bindable var state: DoppioState
    @Binding var isSettingsExpanded: Bool

    var body: some View {
        HStack {
            // Кнопка разворачивания быстрых настроек
            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                    isSettingsExpanded.toggle()
                }
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: isSettingsExpanded ? "chevron.up.circle.fill" : "gearshape")
                        .font(.system(size: 11))
                    Text(isSettingsExpanded ? "Скрыть опции" : "Настройки")
                        .font(.system(size: 11, weight: .medium))
                }
                .foregroundStyle(Color.secondary)
            }
            .buttonStyle(.plain)

            Spacer()

            // Кнопка выхода из приложения
            Button {
                state.deactivate(reason: "Завершение работы")
                NSApplication.shared.terminate(nil)
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "power")
                        .font(.system(size: 10, weight: .bold))
                    Text("Выход")
                        .font(.system(size: 11))
                }
                .foregroundStyle(Color.secondary.opacity(0.8))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 4)
    }
}
