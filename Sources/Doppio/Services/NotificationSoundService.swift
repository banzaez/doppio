import Foundation
import AppKit

/// Звуковые оповещения и тактильная обратная связь
public final class NotificationSoundService: Sendable {
    public static let shared = NotificationSoundService()

    private init() {}

    public func playActivateSound() {
        NSSound(named: "Tink")?.play()
    }

    public func playDeactivateSound() {
        NSSound(named: "Basso")?.play()
    }

    public func playCompletionSound() {
        NSSound(named: "Glass")?.play()
    }
}
