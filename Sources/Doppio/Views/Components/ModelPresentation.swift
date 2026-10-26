import AppKit
import Foundation
import SwiftUI

// MARK: - Презентационный слой и локализация доменных моделей

extension SessionTriggerSource {
    public var badgeIconName: String? {
        switch self {
        case .manual:
            return nil
        case .appTrigger:
            return "app.badge.checkmark"
        case .acPower:
            return "powerplug.fill"
        case .externalDisplay:
            return "display"
        }
    }

    public func badgeTitle(using l10n: L10n) -> String? {
        switch self {
        case .manual:
            return nil
        case .appTrigger(_, let appName):
            return appName
        case .acPower:
            return l10n.batteryAC
        case .externalDisplay:
            return "Display"
        }
    }
}

extension TriggerApp {
    @MainActor
    public var appIcon: NSImage {
        if let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleIdentifier) {
            let icon = NSWorkspace.shared.icon(forFile: url.path)
            icon.size = NSSize(width: 16, height: 16)
            return icon
        }
        return NSImage(systemSymbolName: "app.fill", accessibilityDescription: displayName) ?? NSImage()
    }
}

extension SleepAssertionType {
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

extension BatteryInfo {
    public var iconName: String {
        if isCharging {
            return "battery.100.bolt"
        }
        if percentage >= 80 {
            return "battery.100"
        } else if percentage >= 50 {
            return "battery.75"
        } else if percentage >= 25 {
            return "battery.50"
        } else {
            return "battery.25"
        }
    }

    public func description(using l10n: L10n) -> String {
        if isCharging {
            return "\(percentage)% • \(l10n.batteryCharging)"
        } else if isPluggedIn {
            return "\(percentage)% • \(l10n.batteryAC)"
        } else {
            return "\(percentage)% • \(l10n.batteryOnBattery)"
        }
    }

    public var description: String {
        description(using: L10n(language: .defaultLanguage))
    }

    public func statusColor(threshold: Int) -> Color {
        if isCharging {
            return .green
        }
        if percentage <= threshold {
            return .red
        }
        if percentage <= 40 {
            return .orange
        }
        return .secondary
    }
}

extension DeactivationReason {
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

extension MenuBarDisplayStyle {
    public func title(using l10n: L10n) -> String {
        switch self {
        case .standard:
            return l10n.menuBarStyleStandard
        case .iconOnly:
            return l10n.menuBarStyleIconOnly
        }
    }

    public var iconName: String {
        switch self {
        case .standard:
            return "cup.and.saucer.fill"
        case .iconOnly:
            return "cup.and.saucer"
        }
    }
}

extension KeepAwakePreset {
    public func title(using l10n: L10n) -> String {
        switch self {
        case .indefinite: return l10n.presetIndefinite
        case .minutes15: return l10n.presetMinutes(15)
        case .minutes30: return l10n.presetMinutes(30)
        case .hour1: return l10n.presetHours(1)
        case .hours2: return l10n.presetHours(2)
        case .hours4: return l10n.presetHours(4)
        case .custom: return l10n.presetCustom
        }
    }

    public var title: String {
        title(using: L10n(language: .defaultLanguage))
    }

    public var shortTitle: String {
        switch self {
        case .indefinite: return "∞"
        case .minutes15: return "15m"
        case .minutes30: return "30m"
        case .hour1: return "1h"
        case .hours2: return "2h"
        case .hours4: return "4h"
        case .custom: return "⏱"
        }
    }
}
