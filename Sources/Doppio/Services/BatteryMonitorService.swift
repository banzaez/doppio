import Foundation
import IOKit.ps
import os

/// Сервис мониторинга состояния батареи и питания
public final class BatteryMonitorService: Sendable {
    private let logger = Logger(subsystem: "com.doppio.app", category: "BatteryMonitor")

    public init() {}

    /// Получить актуальные данные о батарее
    public func fetchBatteryInfo() -> BatteryInfo? {
        guard let snapshot = IOPSCopyPowerSourcesInfo()?.takeRetainedValue(),
              let sources = IOPSCopyPowerSourcesList(snapshot)?.takeRetainedValue() as? [CFTypeRef] else {
            return nil
        }

        for source in sources {
            guard let description = IOPSGetPowerSourceDescription(snapshot, source)?.takeUnretainedValue() as? [String: Any] else {
                continue
            }

            let type = description[kIOPSTypeKey as String] as? String
            guard type == (kIOPSInternalBatteryType as String) else {
                continue
            }

            let current = description[kIOPSCurrentCapacityKey as String] as? Int ?? 0
            let max = description[kIOPSMaxCapacityKey as String] as? Int ?? 100
            let isCharging = description[kIOPSIsChargingKey as String] as? Bool ?? false
            let powerState = description[kIOPSPowerSourceStateKey as String] as? String
            let isPluggedIn = powerState == (kIOPSACPowerValue as String)

            let percentage = max > 0 ? Int((Double(current) / Double(max)) * 100) : current

            return BatteryInfo(
                percentage: percentage,
                isCharging: isCharging,
                isPluggedIn: isPluggedIn
            )
        }

        // Если устройство без внутренней батареи (Mac mini, Mac Studio, Mac Pro, iMac)
        return nil
    }
}
