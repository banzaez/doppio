import Foundation

/// Пресеты длительности режима бодрствования (чистая доменная модель)
public enum KeepAwakePreset: Equatable, Hashable, Identifiable, CaseIterable, Sendable {
    case indefinite
    case minutes15
    case minutes30
    case hour1
    case hours2
    case hours4
    case custom

    public var id: String {
        switch self {
        case .indefinite: return "indefinite"
        case .minutes15: return "15m"
        case .minutes30: return "30m"
        case .hour1: return "1h"
        case .hours2: return "2h"
        case .hours4: return "4h"
        case .custom: return "custom"
        }
    }

    public var duration: TimeInterval? {
        switch self {
        case .indefinite: return nil
        case .minutes15: return 15 * 60
        case .minutes30: return 30 * 60
        case .hour1: return 60 * 60
        case .hours2: return 2 * 60 * 60
        case .hours4: return 4 * 60 * 60
        case .custom: return nil
        }
    }
}
