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
                    withAnimation(.easeInOut(duration: 0.18)) {
                        currentScreen = .main
                    }
                }
                .transition(.opacity)
            }
        }
        .padding(13)
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
            if newHeight > 80 {
                WindowAutoResizerBridge.shared.resizeWindow(toHeight: newHeight)
            }
        }
        .fixedSize(horizontal: false, vertical: true)
        .background(WindowAutoResizer())
        .onAppear {
            state.isPopoverVisible = true
            state.refreshBatteryInfo()
        }
        .onDisappear {
            state.isPopoverVisible = false
        }
    }

    @ViewBuilder
    private var mainScreenView: some View {
        VStack(spacing: 10) {
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
                withAnimation(.easeInOut(duration: 0.18)) {
                    currentScreen = .settings
                }
            }
        }
    }

    private func deactivationBannerView(reason: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: "info.circle.fill")
                .font(.system(size: 11))
                .foregroundStyle(Color.orange)

            Text(reason)
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(Color.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.85)

            Spacer(minLength: 4)

            Button {
                withAnimation(.easeInOut(duration: 0.18)) {
                    state.clearDeactivationReason()
                }
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 8, weight: .bold))
                    .foregroundStyle(Color.secondary)
                    .frame(width: 16, height: 16)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 10)
        .frame(height: 28)
        .glassCard(cornerRadius: 9)
        .transition(.opacity)
    }
}
