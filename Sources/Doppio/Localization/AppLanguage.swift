import Foundation

/// Поддерживаемые языки интерфейса Doppio
public enum AppLanguage: String, CaseIterable, Identifiable, Sendable {
    case system = "system"
    case english = "en"
    case ukrainian = "uk"
    case russian = "ru"
    case german = "de"
    case french = "fr"
    case spanish = "es"

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .system:
            return Self.systemDisplayTitle()
        case .english:
            return "English"
        case .ukrainian:
            return "Українська"
        case .russian:
            return "Русский"
        case .german:
            return "Deutsch"
        case .french:
            return "Français"
        case .spanish:
            return "Español"
        }
    }

    /// Отображение системного языка с указанием автоопределённого языка
    private static func systemDisplayTitle() -> String {
        let detected = detectSystemLanguageCode()
        let name: String
        switch detected {
        case "uk": name = "Українська"
        case "ru": name = "Русский"
        case "de": name = "Deutsch"
        case "fr": name = "Français"
        case "es": name = "Español"
        default: name = "English"
        }
        return "Авто: \(name)"
    }

    /// Код эффективного языка для словаря локализации
    public var effectiveCode: String {
        if self == .system {
            return Self.detectSystemLanguageCode()
        }
        return self.rawValue
    }

    /// Определение языка системы macOS из preferredLanguages
    public static func detectSystemLanguageCode() -> String {
        for lang in Locale.preferredLanguages {
            let lower = lang.lowercased()
            if lower.hasPrefix("uk") { return "uk" }
            if lower.hasPrefix("ru") { return "ru" }
            if lower.hasPrefix("de") { return "de" }
            if lower.hasPrefix("fr") { return "fr" }
            if lower.hasPrefix("es") { return "es" }
            if lower.hasPrefix("en") { return "en" }
        }
        return "en"
    }
}
