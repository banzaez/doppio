import Foundation

/// Информация о питании и батарее
public struct BatteryInfo: Equatable, Sendable {
    public let percentage: Int
    public let isCharging: Bool
    public let isPluggedIn: Bool

    public init(percentage: Int, isCharging: Bool, isPluggedIn: Bool) {
        self.percentage = percentage
        self.isCharging = isCharging
        self.isPluggedIn = isPluggedIn
    }

    public var iconName: String {
        if isCharging {
            return "battery.100.bolt"
        }
        if percentage >= 80 {
            return "battery.100"
        } else if percentage >= 50 {
            return "battery.75"
        } else if percentage >= 25 {
            return "battery.50"
        } else {
            return "battery.25"
        }
    }

    public var description: String {
        if isCharging {
            return "\(percentage)% • Зарядка"
        } else if isPluggedIn {
            return "\(percentage)% • Сеть"
        } else {
            return "\(percentage)% • Батарея"
        }
    }
}
