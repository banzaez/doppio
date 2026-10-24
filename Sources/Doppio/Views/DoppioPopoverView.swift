import SwiftUI

/// Главное всплывающее окно Doppio из строки меню
struct DoppioPopoverView: View {
    @Bindable var state: DoppioState
    @State private var isSettingsExpanded: Bool = false

    var body: some View {
        VStack(spacing: 12) {
            // Верхняя плашка переключателя
            QuickToggleCard(state: state)

            // Прогресс таймера (если активен)
            CircularProgressTimerView(state: state)

            // Выбор длительности
            PresetSelectionView(state: state)

            // Выбор режима (экран + система / только система)
            SleepModeSelectorView(state: state)

            // Статус батареи
            BatteryStatusBadge(state: state)

            // Разворачиваемая панель настроек
            if isSettingsExpanded {
                QuickSettingsPanel(state: state)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }

            Divider()
                .padding(.vertical, 2)

            // Нижние действия
            FooterActionsView(
                state: state,
                isSettingsExpanded: $isSettingsExpanded
            )
        }
        .padding(14)
        .frame(width: 320)
        .background(Color(nsColor: .windowBackgroundColor))
        .onAppear {
            state.refreshBatteryInfo()
        }
    }
}
