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
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 12) {
                switch currentScreen {
                case .main:
                    mainScreenView
                        .transition(.asymmetric(
                            insertion: .opacity.combined(with: .move(edge: .leading)),
                            removal: .opacity.combined(with: .move(edge: .leading))
                        ))
                case .settings:
                    SettingsView(state: state) {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            currentScreen = .main
                        }
                    }
                    .transition(.asymmetric(
                        insertion: .opacity.combined(with: .move(edge: .trailing)),
                        removal: .opacity.combined(with: .move(edge: .trailing))
                    ))
                }
            }
            .padding(12)
        }
        .frame(width: 320)
        .background(.ultraThinMaterial)
        .onAppear {
            state.refreshBatteryInfo()
        }
    }

    @ViewBuilder
    private var mainScreenView: some View {
        VStack(spacing: 11) {
            // Верхний блок Control Center с тумблером
            ControlCenterHeroCard(state: state)

            // Сетка пресетов времени
            PresetSelectionView(state: state)

            // Нативный Segmented Control режима сна
            SleepModeSelectorView(state: state)

            Divider()
                .padding(.vertical, 1)

            // Нижняя панель действий
            FooterActionsView(state: state) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    currentScreen = .settings
                }
            }
        }
    }
}
