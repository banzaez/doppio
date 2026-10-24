import SwiftUI

/// Статус батареи и питания
struct BatteryStatusBadge: View {
    @Bindable var state: DoppioState

    var body: some View {
        if let info = state.batteryInfo {
            HStack(spacing: 6) {
                Image(systemName: info.iconName)
                    .font(.system(size: 11))
                    .foregroundStyle(batteryColor(for: info))

                Text(info.description)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(Color.secondary)

                if state.batteryProtectionEnabled {
                    Text("• автостоп ≤ \(state.batteryThreshold)%")
                        .font(.system(size: 9))
                        .foregroundStyle(Color.secondary.opacity(0.7))
                }

                Spacer()
            }
            .padding(.horizontal, 4)
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
