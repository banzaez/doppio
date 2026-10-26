import SwiftUI

/// Переключатель режима сна в полностью стеклянном стиле macOS 27 / iOS 2026 Liquid Glass
struct SleepModeSelectorView: View {
    @Bindable var state: DoppioState
    @Namespace private var modeSegmentNamespace

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(state.l10n.sectionMode)
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(Color.secondary)
                .padding(.horizontal, 2)
                .lineLimit(1)

            // Стеклянный переключатель из двух сегментов с плавным перетеканием капсулы выбора
            HStack(spacing: 4) {
                ForEach(SleepAssertionType.allCases, id: \.self) { type in
                    let isSelected = state.assertionType == type

                    Button {
                        withAnimation(.spring(response: 0.26, dampingFraction: 0.8)) {
                            state.assertionType = type
                        }
                    } label: {
                        HStack(spacing: 5) {
                            Image(systemName: type.iconName)
                                .font(.system(size: 11))
                            Text(type.title(using: state.l10n))
                                .font(.system(size: 11, weight: isSelected ? .semibold : .medium))
                                .lineLimit(1)
                                .minimumScaleFactor(0.85)
                        }
                        .foregroundStyle(isSelected ? (state.isActive ? Color.orange : Color.primary) : Color.secondary)
                        .frame(maxWidth: .infinity)
                        .frame(height: 26)
                        .contentShape(Rectangle())
                        .background {
                            if isSelected {
                                RoundedRectangle(cornerRadius: 7, style: .continuous)
                                    .fill(
                                        state.isActive
                                            ? Color.orange.opacity(0.20)
                                            : Color.primary.opacity(0.11)
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 7, style: .continuous)
                                            .stroke(
                                                state.isActive
                                                    ? Color.orange.opacity(0.55)
                                                    : Color.white.opacity(0.22),
                                                lineWidth: 0.75
                                            )
                                    )
                                    .shadow(
                                        color: state.isActive ? Color.orange.opacity(0.18) : Color.black.opacity(0.05),
                                        radius: 4,
                                        y: 1
                                    )
                                    .matchedGeometryEffect(id: "SelectedSleepMode", in: modeSegmentNamespace)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
            .glassSegmentTrack(cornerRadius: 10)

            Text(state.assertionType.description(using: state.l10n))
                .font(.system(size: 10))
                .foregroundStyle(Color.secondary.opacity(0.8))
                .padding(.horizontal, 2)
                .lineLimit(1)
                .minimumScaleFactor(0.85)
                .frame(height: 13, alignment: .leading)
        }
    }
}
