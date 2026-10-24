import SwiftUI

/// Главное всплывающее окно Doppio в строке меню в стиле macOS 27 / iOS 2026 Liquid Glass
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
                    withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                        currentScreen = .main
                    }
                }
                .transition(.opacity)
            }
        }
        .padding(14)
        .frame(width: 320)
        .background(
            GeometryReader { proxy in
                Color.clear.preference(
                    key: PopoverContentHeightKey.self,
                    value: proxy.size.height
                )
            }
        )
        .onPreferenceChange(PopoverContentHeightKey.self) { newHeight in
            if newHeight > 50 {
                WindowAutoResizerBridge.shared.resizeWindow(toHeight: newHeight)
            }
        }
        .fixedSize(horizontal: false, vertical: true)
        .background(WindowAutoResizer())
        .onAppear {
            state.refreshBatteryInfo()
        }
    }

    @ViewBuilder
    private var mainScreenView: some View {
        VStack(spacing: 11) {
            // Верхний стеклянный блок Control Center с тумблером и интегрированной полосой прогресса
            ControlCenterHeroCard(state: state)

            // Баннер последней причины деактивации (например, автостоп по батарее)
            if let reason = state.localizedDeactivationReason, !state.isActive {
                deactivationBannerView(reason: reason)
            }

            // Сетка стеклянных пресетов времени и строка ввода своего времени
            PresetSelectionView(state: state)

            // Стеклянный переключатель режима сна
            SleepModeSelectorView(state: state)

            Divider()
                .padding(.vertical, 1)

            // Нижняя строка действий
            FooterActionsView(state: state) {
                withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                    currentScreen = .settings
                }
            }
        }
    }

    private func deactivationBannerView(reason: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: "info.circle")
                .font(.system(size: 11))
                .foregroundStyle(Color.orange)

            Text(reason)
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(Color.secondary)
                .lineLimit(1)

            Spacer()

            Button {
                withAnimation(.spring(response: 0.2, dampingFraction: 0.8)) {
                    state.clearDeactivationReason()
                }
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 8, weight: .bold))
                    .foregroundStyle(Color.secondary)
                    .padding(3)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .glassCard(cornerRadius: 9)
        .transition(.opacity.combined(with: .scale(scale: 0.96)))
    }
}
