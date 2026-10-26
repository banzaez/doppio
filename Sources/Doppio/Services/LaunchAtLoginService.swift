import Foundation
import ServiceManagement
import os

/// Протокол сервиса автозапуска
@MainActor
public protocol LaunchAtLoginManaging: AnyObject {
    var isEnabled: Bool { get }
    @discardableResult
    func setEnabled(_ enabled: Bool) -> Bool
}

/// Сервис автозапуска при входе в систему (SMAppService)
@MainActor
public final class LaunchAtLoginService: LaunchAtLoginManaging {
    private let logger = Logger(subsystem: "com.doppio.app", category: "LaunchAtLogin")

    public init() {}

    /// Включён ли автозапуск
    public var isEnabled: Bool {
        SMAppService.mainApp.status == .enabled
    }

    /// Переключить автозапуск
    @discardableResult
    public func setEnabled(_ enabled: Bool) -> Bool {
        do {
            if enabled {
                if SMAppService.mainApp.status != .enabled {
                    try SMAppService.mainApp.register()
                    logger.info("Автозапуск успешно зарегистрирован")
                }
            } else {
                if SMAppService.mainApp.status == .enabled {
                    try SMAppService.mainApp.unregister()
                    logger.info("Автозапуск отменён")
                }
            }
            return true
        } catch {
            logger.error("Ошибка изменения статуса автозапуска: \(error.localizedDescription)")
            return false
        }
    }
}
