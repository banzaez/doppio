import Foundation

/// Режим предотвращения сна
public enum SleepAssertionType: String, CaseIterable, Sendable {
    case systemAndDisplay = "systemAndDisplay"
    case systemOnly = "systemOnly"

    public var title: String {
        switch self {
        case .systemAndDisplay: return "Экран и система"
        case .systemOnly: return "Только система"
        }
    }

    public var description: String {
        switch self {
        case .systemAndDisplay: return "Экран остаётся включённым, Mac не заснёт"
        case .systemOnly: return "Экран может гаснуть, но фон и задачи работают"
        }
    }

    public var iconName: String {
        switch self {
        case .systemAndDisplay: return "display"
        case .systemOnly: return "cpu"
        }
    }
}
