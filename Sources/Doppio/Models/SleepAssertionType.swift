import Foundation

/// Режим предотвращения сна
public enum SleepAssertionType: String, CaseIterable, Sendable {
    case systemAndDisplay = "systemAndDisplay"
    case systemOnly = "systemOnly"

    public func title(using l10n: L10n) -> String {
        switch self {
        case .systemAndDisplay: return l10n.modeDisplayAndMac
        case .systemOnly: return l10n.modeMacOnly
        }
    }

    public func description(using l10n: L10n) -> String {
        switch self {
        case .systemAndDisplay: return l10n.modeDisplayDesc
        case .systemOnly: return l10n.modeMacOnlyDesc
        }
    }

    public var title: String {
        title(using: L10n(language: .system))
    }

    public var description: String {
        description(using: L10n(language: .system))
    }

    public var iconName: String {
        switch self {
        case .systemAndDisplay: return "display"
        case .systemOnly: return "cpu"
        }
    }
}
