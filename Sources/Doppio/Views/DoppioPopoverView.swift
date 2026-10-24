import SwiftUI

/// Главное всплывающее окно Doppio в строке меню
struct DoppioPopoverView: View {
    @Bindable var state: DoppioState

    enum Screen {
        case main
        case settings
    }

    @State private var currentScreen: Screen = .main

    var body: some View {
        VStack(spacing: 0) {
            switch currentScreen {
            case .main:
                mainScreenView
                    .transition(.opacity)
            case .settings:
                SettingsView(state: state) {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        currentScreen = .main
                    }
                }
                .transition(.opacity)
            }
        }
        .padding(14)
        .frame(width: 320)
        .fixedSize(horizontal: false, vertical: true)
        .background(WindowAutoResizer())
        .onAppear {
            state.refreshBatteryInfo()
        }
    }

    @ViewBuilder
    private var mainScreenView: some View {
        VStack(spacing: 12) {
            // Верхний стеклянный блок Control Center с тумблером
            ControlCenterHeroCard(state: state)

            // Сетка стеклянных пресетов времени и фиксированная строка своего времени
            PresetSelectionView(state: state)

            // Стеклянный переключатель режима сна
            SleepModeSelectorView(state: state)

            Divider()
                .padding(.vertical, 1)

            // Нижняя строка действий
            FooterActionsView(state: state) {
                withAnimation(.easeInOut(duration: 0.2)) {
                    currentScreen = .settings
                }
            }
        }
    }
}
