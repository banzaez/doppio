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

    public func description(using l10n: L10n) -> String {
        if isCharging {
            return "\(percentage)% • \(l10n.batteryCharging)"
        } else if isPluggedIn {
            return "\(percentage)% • \(l10n.batteryAC)"
        } else {
            return "\(percentage)% • \(l10n.batteryOnBattery)"
        }
    }

    public var description: String {
        description(using: L10n(language: .defaultLanguage))
    }
}
