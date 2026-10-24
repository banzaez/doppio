import Foundation

/// Источник активации сессии бодрствования
public enum SessionTriggerSource: Equatable, Sendable {
    /// Включено пользователем вручную через интерфейс или шорткат
    case manual
    /// Включено автоматически при запуске отслеживаемого приложения
    case appTrigger(bundleId: String, appName: String)
    /// Включено автоматически при подключении адаптера питания (AC)
    case acPower
    /// Включено автоматически при подключении внешнего дисплея
    case externalDisplay
}
