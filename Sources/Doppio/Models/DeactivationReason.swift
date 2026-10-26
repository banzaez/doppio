import Foundation

/// Причина деактивации режима бодрствования (чистая доменная модель)
public enum DeactivationReason: Equatable, Sendable {
    case userDisabled
    case sessionCompleted
    case timerExpired
    case batteryLow(percentage: Int)
    case quitApp
    case appTerminated(appName: String)
    case powerDisconnected
    case externalDisplayDisconnected
}
