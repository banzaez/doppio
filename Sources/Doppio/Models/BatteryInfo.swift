import Foundation

/// Информация о питании и батарее (чистая доменная модель)
public struct BatteryInfo: Equatable, Sendable {
    public let percentage: Int
    public let isCharging: Bool
    public let isPluggedIn: Bool

    public init(percentage: Int, isCharging: Bool, isPluggedIn: Bool) {
        self.percentage = percentage
        self.isCharging = isCharging
        self.isPluggedIn = isPluggedIn
    }
}
