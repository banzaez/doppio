import Foundation
import IOKit.ps
import os

/// Протокол мониторинга питания и батареи
@MainActor
public protocol BatteryMonitoring: AnyObject {
    func fetchBatteryInfo() -> BatteryInfo?
    func startMonitoring(onChange: @escaping @MainActor () -> Void)
    func stopMonitoring()
}

extension BatteryMonitoring {
    public func startMonitoring(onChange: @escaping @MainActor () -> Void) {}
    public func stopMonitoring() {}
}

/// Сервис событийного мониторинга состояния батареи и питания через IOKit (без поллинга)
@MainActor
public final class BatteryMonitorService: BatteryMonitoring {
    private let logger = Logger(subsystem: "com.doppio.app", category: "BatteryMonitor")
    private var runLoopSource: CFRunLoopSource?
    private var onChangeHandler: (@MainActor () -> Void)?

    nonisolated public init() {}

    isolated deinit {
        stopMonitoring()
    }

    /// Запуск нативного событийного наблюдения IOKit за источниками питания (Zero Idle CPU)
    public func startMonitoring(onChange: @escaping @MainActor () -> Void) {
        stopMonitoring()
        self.onChangeHandler = onChange

        let context = Unmanaged.passUnretained(self).toOpaque()
        let callback: IOPowerSourceCallbackType = { context in
            guard let context else { return }
            let service = Unmanaged<BatteryMonitorService>.fromOpaque(context).takeUnretainedValue()
            Task { @MainActor in
                service.onChangeHandler?()
            }
        }

        if let source = IOPSNotificationCreateRunLoopSource(callback, context)?.takeRetainedValue() {
            CFRunLoopAddSource(CFRunLoopGetMain(), source, .commonModes)
            self.runLoopSource = source
            logger.info("Событийный мониторинг питания IOKit запущен")
        }
    }

    /// Остановка наблюдения за питанием
    public func stopMonitoring() {
        if let source = runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetMain(), source, .commonModes)
            runLoopSource = nil
        }
        onChangeHandler = nil
    }

    /// Получить актуальные данные о батарее
    nonisolated public func fetchBatteryInfo() -> BatteryInfo? {
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
