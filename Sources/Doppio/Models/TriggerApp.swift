import Foundation

/// Описание целевого приложения для умного автозапуска бодрствования (App Trigger)
public struct TriggerApp: Identifiable, Codable, Hashable, Sendable {
    public var id: UUID
    public var bundleIdentifier: String
    public var displayName: String

    public init(id: UUID = UUID(), bundleIdentifier: String, displayName: String) {
        self.id = id
        self.bundleIdentifier = bundleIdentifier
        self.displayName = displayName
    }
}
