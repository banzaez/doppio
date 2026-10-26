import Foundation

/// Изолированное хранилище пользовательских настроек Doppio поверх UserDefaults
@MainActor
public struct DoppioSettingsStore {
    private enum StorageKey: String {
        case assertionType
        case showTimerInMenuBar
        case menuBarDisplayStyle
        case quickToggleEnabled
        case notifyBeforeExpiry
        case batteryProtectionEnabled
        case batteryThreshold
        case customMinutes
        case appLanguage
        case appTriggersEnabled
        case targetAppsData
        case activateOnACPower
        case deactivateOnBattery
        case activateOnExternalDisplay
    }

    private let defaults: UserDefaults

    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    public var assertionType: SleepAssertionType {
        get {
            guard let raw = defaults.string(forKey: StorageKey.assertionType.rawValue),
                  let type = SleepAssertionType(rawValue: raw) else {
                return .systemOnly
            }
            return type
        }
        nonmutating set {
            defaults.set(newValue.rawValue, forKey: StorageKey.assertionType.rawValue)
        }
    }

    public var menuBarDisplayStyle: MenuBarDisplayStyle {
        get {
            guard let raw = defaults.string(forKey: StorageKey.menuBarDisplayStyle.rawValue),
                  let style = MenuBarDisplayStyle(rawValue: raw) else {
                return .standard
            }
            return style
        }
        nonmutating set {
            defaults.set(newValue.rawValue, forKey: StorageKey.menuBarDisplayStyle.rawValue)
        }
    }

    public var showTimerInMenuBar: Bool {
        get {
            defaults.object(forKey: StorageKey.showTimerInMenuBar.rawValue) != nil
                ? defaults.bool(forKey: StorageKey.showTimerInMenuBar.rawValue)
                : true
        }
        nonmutating set {
            defaults.set(newValue, forKey: StorageKey.showTimerInMenuBar.rawValue)
        }
    }

    public var quickToggleEnabled: Bool {
        get {
            defaults.object(forKey: StorageKey.quickToggleEnabled.rawValue) != nil
                ? defaults.bool(forKey: StorageKey.quickToggleEnabled.rawValue)
                : true
        }
        nonmutating set {
            defaults.set(newValue, forKey: StorageKey.quickToggleEnabled.rawValue)
        }
    }

    public var notifyBeforeExpiry: Bool {
        get {
            defaults.object(forKey: StorageKey.notifyBeforeExpiry.rawValue) != nil
                ? defaults.bool(forKey: StorageKey.notifyBeforeExpiry.rawValue)
                : true
        }
        nonmutating set {
            defaults.set(newValue, forKey: StorageKey.notifyBeforeExpiry.rawValue)
        }
    }

    public var appTriggersEnabled: Bool {
        get {
            defaults.object(forKey: StorageKey.appTriggersEnabled.rawValue) != nil
                ? defaults.bool(forKey: StorageKey.appTriggersEnabled.rawValue)
                : true
        }
        nonmutating set {
            defaults.set(newValue, forKey: StorageKey.appTriggersEnabled.rawValue)
        }
    }

    public var activateOnACPower: Bool {
        get {
            defaults.object(forKey: StorageKey.activateOnACPower.rawValue) != nil
                ? defaults.bool(forKey: StorageKey.activateOnACPower.rawValue)
                : false
        }
        nonmutating set {
            defaults.set(newValue, forKey: StorageKey.activateOnACPower.rawValue)
        }
    }

    public var deactivateOnBattery: Bool {
        get {
            defaults.object(forKey: StorageKey.deactivateOnBattery.rawValue) != nil
                ? defaults.bool(forKey: StorageKey.deactivateOnBattery.rawValue)
                : false
        }
        nonmutating set {
            defaults.set(newValue, forKey: StorageKey.deactivateOnBattery.rawValue)
        }
    }

    public var activateOnExternalDisplay: Bool {
        get {
            defaults.object(forKey: StorageKey.activateOnExternalDisplay.rawValue) != nil
                ? defaults.bool(forKey: StorageKey.activateOnExternalDisplay.rawValue)
                : false
        }
        nonmutating set {
            defaults.set(newValue, forKey: StorageKey.activateOnExternalDisplay.rawValue)
        }
    }

    public var targetApps: [TriggerApp] {
        get {
            guard let data = defaults.data(forKey: StorageKey.targetAppsData.rawValue),
                  let apps = try? JSONDecoder().decode([TriggerApp].self, from: data) else {
                return []
            }
            return apps
        }
        nonmutating set {
            if let data = try? JSONEncoder().encode(newValue) {
                defaults.set(data, forKey: StorageKey.targetAppsData.rawValue)
            }
        }
    }

    public var batteryProtectionEnabled: Bool {
        get {
            defaults.object(forKey: StorageKey.batteryProtectionEnabled.rawValue) != nil
                ? defaults.bool(forKey: StorageKey.batteryProtectionEnabled.rawValue)
                : true
        }
        nonmutating set {
            defaults.set(newValue, forKey: StorageKey.batteryProtectionEnabled.rawValue)
        }
    }

    public var batteryThreshold: Int {
        get {
            guard defaults.object(forKey: StorageKey.batteryThreshold.rawValue) != nil else {
                return 20
            }
            let threshold = defaults.integer(forKey: StorageKey.batteryThreshold.rawValue)
            return (5...50).contains(threshold) ? threshold : 20
        }
        nonmutating set {
            defaults.set(newValue, forKey: StorageKey.batteryThreshold.rawValue)
        }
    }

    public var customMinutes: Int {
        get {
            guard defaults.object(forKey: StorageKey.customMinutes.rawValue) != nil else {
                return 45
            }
            let minutes = defaults.integer(forKey: StorageKey.customMinutes.rawValue)
            return minutes > 0 ? minutes : 45
        }
        nonmutating set {
            defaults.set(newValue, forKey: StorageKey.customMinutes.rawValue)
        }
    }

    public var language: AppLanguage {
        get {
            guard let raw = defaults.string(forKey: StorageKey.appLanguage.rawValue),
                  let savedLang = AppLanguage(rawValue: raw) else {
                return .defaultLanguage
            }
            return savedLang
        }
        nonmutating set {
            defaults.set(newValue.rawValue, forKey: StorageKey.appLanguage.rawValue)
        }
    }
}
