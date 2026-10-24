import SwiftUI

/// Лейбл приложения в строке меню macOS (Menu Bar)
struct MenuBarLabelView: View {
    @Bindable var state: DoppioState

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: state.isActive ? "cup.and.saucer.fill" : "cup.and.saucer")
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(state.isActive ? Color.orange : Color.primary)

            if let badge = state.menuBarBadgeText {
                Text(badge)
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .monospacedDigit()
            }
        }
    }
}
