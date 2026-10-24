import SwiftUI

/// Выбор режима предотвращения сна (Экран + система или Только система)
struct SleepModeSelectorView: View {
    @Bindable var state: DoppioState

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("РЕЖИМ БОДРСТВОВАНИЯ")
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(Color.secondary.opacity(0.8))
                .padding(.horizontal, 2)

            HStack(spacing: 8) {
                ForEach(SleepAssertionType.allCases, id: \.self) { type in
                    let isSelected = state.assertionType == type

                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            state.assertionType = type
                        }
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: type.iconName)
                                .font(.system(size: 12))
                                .foregroundStyle(isSelected ? Color.orange : Color.secondary)

                            VStack(alignment: .leading, spacing: 1) {
                                Text(type.title)
                                    .font(.system(size: 11, weight: isSelected ? .semibold : .medium))
                                    .foregroundStyle(isSelected ? Color.primary : Color.secondary)

                                Text(type == .systemAndDisplay ? "Экран светит" : "Экран гаснет")
                                    .font(.system(size: 9))
                                    .foregroundStyle(Color.secondary.opacity(0.8))
                            }
                            Spacer()
                        }
                        .padding(.vertical, 7)
                        .padding(.horizontal, 10)
                        .frame(maxWidth: .infinity)
                        .background(
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .fill(isSelected ? Color.orange.opacity(0.1) : Color.primary.opacity(0.03))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                                        .stroke(isSelected ? Color.orange.opacity(0.35) : Color.primary.opacity(0.06), lineWidth: 1)
                                )
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}
