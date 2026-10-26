import Foundation

/// Режим предотвращения сна (чистая доменная модель)
public enum SleepAssertionType: String, CaseIterable, Codable, Sendable {
    case systemOnly = "systemOnly"
    case systemAndDisplay = "systemAndDisplay"
}
