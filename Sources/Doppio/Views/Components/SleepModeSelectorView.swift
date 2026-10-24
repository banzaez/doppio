import SwiftUI

/// Переключатель режима сна в полностью стеклянном стиле macOS 27 / iOS 2026 Liquid Glass
struct SleepModeSelectorView: View {
    @Bindable var state: DoppioState

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(state.l10n.sectionMode)
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(Color.secondary)
                .padding(.horizontal, 2)

            // Стеклянный переключатель из двух сегментов в едином треке
            HStack(spacing: 4) {
                ForEach(SleepAssertionType.allCases, id: \.self) { type in
                    let isSelected = state.assertionType == type

                    Button {
                        withAnimation(.spring(response: 0.25, dampingFraction: 0.75)) {
                            state.assertionType = type
                        }
                    } label: {
                        HStack(spacing: 5) {
                            Image(systemName: type.iconName)
                                .font(.system(size: 11))
                            Text(type.title(using: state.l10n))
                                .font(.system(size: 11, weight: isSelected ? .semibold : .medium))
                        }
                        .foregroundStyle(isSelected ? (state.isActive ? Color.orange : Color.primary) : Color.secondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                    }
                    .buttonStyle(GlassButtonStyle(
                        isSelected: isSelected,
                        isAccent: state.isActive,
                        cornerRadius: 8
                    ))
                }
            }
            .glassSegmentTrack(cornerRadius: 10)

            Text(state.assertionType.description(using: state.l10n))
                .font(.system(size: 10))
                .foregroundStyle(Color.secondary.opacity(0.8))
                .padding(.horizontal, 2)
        }
    }
}
