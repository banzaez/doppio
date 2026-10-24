import SwiftUI

/// Статус батареи и питания в стиле macOS 27 / iOS 2026 Liquid Glass
struct BatteryStatusBadge: View {
    @Bindable var state: DoppioState

    var body: some View {
        if let info = state.batteryInfo {
            HStack(spacing: 6) {
                Image(systemName: info.iconName)
                    .font(.system(size: 11))
                    .foregroundStyle(batteryColor(for: info))

                Text(info.description(using: state.l10n))
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(Color.secondary)

                if state.batteryProtectionEnabled {
                    Text("• \(state.l10n.batteryThresholdNote) ≤ \(state.batteryThreshold)%")
                        .font(.system(size: 9))
                        .foregroundStyle(Color.secondary.opacity(0.7))
                }

                Spacer()
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .glassCard(cornerRadius: 8)
        }
    }

    private func batteryColor(for info: BatteryInfo) -> Color {
        if info.isCharging {
            return .green
        }
        if info.percentage <= state.batteryThreshold {
            return .red
        }
        if info.percentage <= 40 {
            return .orange
        }
        return .secondary
    }
}
