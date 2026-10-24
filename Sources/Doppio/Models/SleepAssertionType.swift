import Foundation

/// Режим предотвращения сна
public enum SleepAssertionType: String, CaseIterable, Sendable {
    case systemOnly = "systemOnly"
    case systemAndDisplay = "systemAndDisplay"

    public func title(using l10n: L10n) -> String {
        switch self {
        case .systemOnly: return l10n.modeMacOnly
        case .systemAndDisplay: return l10n.modeDisplayAndMac
        }
    }

    public func description(using l10n: L10n) -> String {
        switch self {
        case .systemOnly: return l10n.modeMacOnlyDesc
        case .systemAndDisplay: return l10n.modeDisplayDesc
        }
    }

    public var title: String {
        title(using: L10n(language: .defaultLanguage))
    }

    public var description: String {
        description(using: L10n(language: .defaultLanguage))
    }

    public var iconName: String {
        switch self {
        case .systemOnly: return "cpu"
        case .systemAndDisplay: return "display"
        }
    }
}
