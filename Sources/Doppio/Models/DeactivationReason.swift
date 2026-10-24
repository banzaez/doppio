import Foundation

/// Причина деактивации режима бодрствования
public enum DeactivationReason: Equatable, Sendable {
    case userDisabled
    case sessionCompleted
    case timerExpired
    case batteryLow(percentage: Int)
    case quitApp
    case appTerminated(appName: String)
    case powerDisconnected
    case externalDisplayDisconnected

    public func localized(using l10n: L10n) -> String {
        switch self {
        case .userDisabled:
            return l10n.reasonUserDisabled
        case .sessionCompleted:
            return l10n.reasonSessionCompleted
        case .timerExpired:
            return l10n.reasonTimerExpired
        case .batteryLow(let pct):
            return l10n.reasonBatteryLow(pct)
        case .quitApp:
            return l10n.reasonQuitApp
        case .appTerminated(let appName):
            return l10n.reasonAppTerminated(appName)
        case .powerDisconnected:
            return l10n.reasonPowerDisconnected
        case .externalDisplayDisconnected:
            return l10n.reasonExternalDisplayDisconnected
        }
    }
}
